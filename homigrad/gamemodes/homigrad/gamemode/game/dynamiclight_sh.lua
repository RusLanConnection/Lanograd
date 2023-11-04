
function CreateDynamicLight(hitPosition)
    if SERVER then
        local color = GetConVar("dynamic_light_color"):GetString() 
        local brightness = GetConVarNumber("dynamic_light_brightness") or 2 
        local distance = GetConVarNumber("dynamic_light_distance") or 300 
        
        local light = ents.Create("light_dynamic") 
        if not IsValid(light) then return end 
        
        light:SetKeyValue("_light", color) 
        light:SetKeyValue("brightness", brightness) 
        light:SetKeyValue("distance", distance) 
        light:SetPos(hitPosition) 
        light:Spawn() 
        light:Fire("TurnOn", "", 0) 
        
        timer.Simple(0.1, function() 
            if IsValid(light) then
                light:Fire("TurnOff", "", 0) 
                light:Remove() 
            end
        end)
    end
end


CreateConVar("dynamic_light_color", "255 165 0", FCVAR_ARCHIVE, "Dynamic light color")
CreateConVar("dynamic_light_brightness", "2", FCVAR_ARCHIVE, "Dynamic light brightness")
CreateConVar("dynamic_light_distance", "300", FCVAR_ARCHIVE, "Dynamic light distance")


local penMult = 0.5
local dmgMult = 0.3

local doShotguns = 1
local doAlive = false

local compatMW = 1

local STEP_SIZE = 4

local function runCallback(attacker, tr, dmginfo)
	local ent = tr.Entity

	if not tr.Hit or tr.StartSolid then
		return
	end

	if not doAlive and ent:IsPlayer() or ent:IsNPC() or ent:IsRagdoll() or ent.IsArmor then
		return
	end

	local surf = util.GetSurfaceData(tr.SurfaceProps)
	local mat = surf and surf.density / 1000 or 1

	local dist = (dmginfo:GetDamage() / mat) * penMult

	local start = tr.HitPos
	local dir = tr.Normal

	local trace
	local hit = false

	for i = STEP_SIZE, dist + STEP_SIZE, STEP_SIZE do
		local endPos = start + dir * i

		local contents = util.PointContents(endPos)

		if bit.band(contents, MASK_SHOT) == 0 or bit.band(contents, CONTENTS_HITBOX) == CONTENTS_HITBOX then
			trace = util.TraceLine({
				start = endPos,
				endpos = endPos - dir * STEP_SIZE,
				mask = bit.bor(MASK_SHOT, CONTENTS_HITBOX),
			})

			if trace.StartSolid and bit.band(trace.SurfaceFlags, SURF_HITBOX) == SURF_HITBOX then
				trace = util.TraceLine({
					start = endPos,
					endpos = endPos - dir * STEP_SIZE,
					mask = MASK_SHOT,
					filter = trace.Entity
				})
			end

			if trace.HitPos == endPos - dir * STEP_SIZE then
				trace = util.TraceLine({
					start = endPos + dir * ent:BoundingRadius(),
					endpos = endPos,
					mask = bit.bor(MASK_SHOT, CONTENTS_HITBOX),
					filter = function(hent)
						return hent == ent
					end,
					ignoreworld = true
				})
			end

			hit = true

			break
		end
	end

	if hit then
		local finalDist = start:Distance(trace.HitPos)
		local ratio = 1 - (finalDist / dist)

		local damage = dmginfo:GetDamage() * ratio * dmgMult

		if damage <= 1 then
			return
		end

		local effect = EffectData()

		effect:SetEntity(trace.Entity)
		effect:SetOrigin(trace.HitPos)
		effect:SetStart(trace.StartPos)
		effect:SetSurfaceProp(trace.SurfaceProps)
		effect:SetDamageType(dmginfo:GetDamageType())
		effect:SetHitBox(trace.HitBox)

		util.Effect("Impact", effect, false)

		local ignore = ent:IsRagdoll() and ent or NULL

		attacker:FireBullets({
			Num = 1,
			Src = trace.HitPos + dir,
			Dir = dir,
			Damage = damage,
			Spread = vector_origin,
			Tracer = 0,
			IgnoreEntity = ignore
		})
	end
end

local biasMin, biasMax = GetConVar("ai_shot_bias_min"), GetConVar("ai_shot_bias_max")

local function getSpread(dir, vec)
	local right = dir:Angle():Right()
	local up = dir:Angle():Up()

	local x, y, z
	local bias = 1

	local min, max = biasMin:GetFloat(), biasMax:GetFloat()

	local shotBias = ((max - min) * bias) + min
	local flatness = math.abs(bias) * 0.5

	repeat
		x = math.Rand(-1, 1) * flatness + math.Rand(-1, 1) * (1 - flatness)
		y = math.Rand(-1, 1) * flatness + math.Rand(-1, 1) * (1 - flatness)

		if shotBias < 0 then
			x = x >= 0 and 1 - x or -1 - x
			y = y >= 0 and 1 - y or -1 - y
		end

		z = x * x + y * y
	until z <= 1

	return (dir + x * vec.x * right + y * vec.y * up):GetNormalized()
end

local function ApplySuppressionEffect(at, hit, start)
	bruh = start or at:EyePos()
	bruhh = hit

	for _,v in ipairs(player.GetAll()) do
		local distance, sup_point = util.DistanceToLine( bruh, bruhh, v:GetPos() )

		if v:IsPlayer() and v:Alive() and distance < 70 and !(v == at) then
			v.adrenaline = math.min(v.adrenaline + 0.1,2)
		end 
	end 
end

hook.Add("EntityFireBullets", "CreateDynamicLightOnBulletFire", function(ent, data)
    local tr = util.TraceLine({start = data.Src, endpos = data.Src + data.Dir * data.Distance, filter = ent})
    
    if tr.Hit then
        CreateDynamicLight(tr.HitPos)
    end

	

    if data.Callback then
        local oldCallback = data.Callback

        data.Callback = function(attacker, tr, dmginfo)
            oldCallback(attacker, tr, dmginfo)
            runCallback(attacker, tr, dmginfo)

			ApplySuppressionEffect(attacker, tr.HitPos, tr.StartPos)
        end
    else
        data.Callback = runCallback
    end

    return true
end)
