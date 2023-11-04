hook.Add("Move","move.speed",function(ply,movedata)
    if ply:Alive() then
		ply.speeed = movedata:GetVelocity():Length()
    end
end)

local CurTime = CurTime
local time
local player_GetAll = player.GetAll
local tbl

local hook_Run = hook.Run

hook.Add("Think", "homigrad-player-thinker", function(ply)
	tbl = player_GetAll()
	time = CurTime()

	for i = 1, #tbl do
		hook_Run("Player Think", tbl[i], time)
	end
end)

hook.Add("PlayerInitialSpawn","homigrad-addcallback",function(ply)
	ply:AddCallback("PhysicsCollide",function(phys,data)
		hook_Run("Player Collide",ply,data.HitEntity,data)
	end)
end)

hook.Add("PlayerSpawn","homigrad-stamina",function(ply)
	if PLYSPAWN_OVERRIDE then return end
	ply.stamina = 100
	ply.staminaNext = 0
	ply.adrenaline = 0
	ply.adrenalineNeed = 0
end)

util.AddNetworkString("info_adrenaline")
util.AddNetworkString("info_staminamul")

hook.Add("Player Think","saystamina",function(ply,time)
	if ply:HasGodMode() or not ply:Alive() or (ply.staminaNext or time) > time then return end
	ply.staminaNext = time + 1

	ply.adrenaline = math.max(ply.adrenaline - 0.05,0)

	local ent = ply:GetNWEntity("Ragdoll")
	local ent = ply.fake and IsValid(ent) and ent or ply

	if ply.stamina < 60 and ply:WaterLevel() <= 2 and not ply.heartstop then
		ent:EmitSound("snds_jack_hmcd_breathing/m" .. math.random(1,6) .. ".wav",60,100,0.6,CHAN_AUTO)
	end

	if ply.stamina < 100 and not ply:IsSprinting() and ply:WaterLevel() <= 2  then
		ply.stamina = ply.stamina + 3 + (ply.hungryregen / 2)
		ply:SetNWInt("stamina",ply.stamina)
	end

	if ply:GetMoveType() == MOVETYPE_WALK and ply:IsSprinting() and ply.speeed > 1 then
		ply.stamina = ply.stamina - 1 * ply.speeed / 50
	end

	if ply:WaterLevel() == 3 then
		ply.stamina = ply.stamina - 2
	end
	
	if ply.stamina < 20 and ent:WaterLevel() == 3 then
		ply.o2 = math.max((ply.o2 or 1) - 0.2,-3)
		
		if not ply.Otrub then
			ent:EmitSound( "Player.DrownContinue", 40,100, 0.6, CHAN_AUTO )
		end

		--[[if ply:Health() <= 0 then
			ply.KillReason = "water"
			ply:Kill()

			return
		end--]]
	end

	ply.stamina = math.Clamp(ply.stamina,0,100)

	net.Start("info_adrenaline")
	net.WriteFloat(ply.adrenaline)
	net.Send(ply)

	local k = math.Clamp(ply.stamina / 100,0,1) * 0.6
	k = k + ply.adrenaline / 4
	k = math.Clamp(k,0,1) * (ply.painlosing > 1 and 1 or ply.LeftLeg) * (ply.painlosing > 1 and 1 or ply.RightLeg) * math.max(ply:Health() / 150,0.2)
	
	net.Start("info_staminamul")
	net.WriteFloat(k)
	net.Send(ply)

	ply.staminamul = k
end)

hook.Add("PlayerFootstep","CustomFootstep1",function(ply,pos,foot,sound,volume,rf)
	if ply:IsSprinting() then
		if foot == 0 then
			if ply.LeftLeg < 1 then
				ply.pain = ply.pain + 25
				if ply.firstTimeNotifiedLeftLeg then
					ply:ChatPrint("Вы чувствуете невыносимую боль от бега на сломанной левой ноге. ")
					ply.firstTimeNotifiedLeftLeg = false
				end
			end
		end

		if foot == 1 then
			if ply.RightLeg < 1 then
				ply.pain = ply.pain + 25
				if ply.firstTimeNotifiedRightLeg then
					ply:ChatPrint("Вы чувствуете невыносимую боль от бега на сломанной правой ноге. ")
					ply.firstTimeNotifiedRightLeg = false
				end
			end
		end
	end
end)


--[[local function ApplySuppressionEffect(at, hit, start)
	bruh = start or at:EyePos()
	bruhh = hit

	for _,v in ipairs(player.GetAll()) do
		local distance, sup_point = util.DistanceToLine( bruh, bruhh, v:GetPos() )

		if v:IsPlayer() and v:Alive() and distance < 70 and !(v == at) then
			v.adrenaline = math.min(v.adrenaline + 0.1,2)

			v:SetNWInt("EffectAMT", math.Clamp(v:GetNWInt("EffectAMT"), 0, 1) + 0.05 * (suppression_buildupspeed:GetFloat()))

			v:ViewPunch( Angle( math.Rand(-1, 1) * (v:GetNWInt("EffectAMT")) * (suppression_viewpunch_intensity:GetFloat()), math.Rand(-1, 1) * (v:GetNWInt("EffectAMT")) * (suppression_viewpunch_intensity:GetFloat()), math.Rand(-1, 1) * (v:GetNWInt("EffectAMT")) * (suppression_viewpunch_intensity:GetFloat()) ) ) 

			print("lol")
			timer.Remove(v:Name() .. "blurreset")

			timer.Create(v:Name() .. "blurreset", 4, 1, function()
				for i=1,(v:GetNWInt("EffectAMT") / 0.05) + 1 do
					timer.Simple(0.1 * i, function()
						v:SetNWInt("EffectAMT", math.Clamp(v:GetNWInt("EffectAMT") - 0.1, 0, 100000))
					end)
				end 
			end) --end timer function
		end 
	end 
end


hook.Add("EntityFireBullets", "SharpenWhenShotNear", function(ent, bul)
	local oldcb = bul.Callback
	bul.Callback = function( at, tr, dm )
		if oldcb then 
			oldcb( at, tr, dm ) 
		end
		if SERVER then
			ApplySuppressionEffect(at, tr.HitPos, tr.StartPos)
		end
	end
end)]]