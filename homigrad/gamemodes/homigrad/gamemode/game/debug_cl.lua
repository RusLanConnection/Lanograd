
local hg_drawfakehull = CreateClientConVar("hg_drawfakehull","0",false,false)
local hg_drawlootspaw = CreateClientConVar("hg_drawlootspaw","0",false,false)

hook.Add("PostDrawOpaqueRenderables","DrawFakeSpawn",function()
    if not hg_drawfakehull:GetBool() then return end
    for k, ply in ipairs( player.GetAll() ) do
    
	    if ply:GetNWBool("fake") then

            if not IsValid(ply:GetNWEntity("Ragdoll")) then return end

	    	local rag = ply:GetNWEntity("Ragdoll")
	    	local pos = rag:GetPos()

            local mins = Vector( -10, -10, 0 )
	        local maxs = Vector( 10, 10, 32 )

	    	local trace = {
                start = pos + Vector(0,0,-5),
                endpos = pos + Vector(0,0,-15),
                mins = mins,
                maxs = maxs,
                filter = function(ent)
                    if ent:IsRagdoll() or ent:GetCollisionGroup() == COLLISION_GROUP_WEAPON or ent:IsPlayer() then
                        return ent
                    end
                end,
            }

            local trhull = util.TraceHull(trace)

	    	render.DrawWireframeBox( trhull.HitPos, Angle( 0, 0, 0 ), mins, maxs, Color( 255, 255, 255 ), true )
	    end
    end
end)

--[[hook.Add("PostDrawTranslucentRenderables","DrawLoot",function()
	if not hg_drawlootspaw:GetBool() then return end

	render.SetColorMaterial()

	for name,info in pairs(spawns) do
		local color = info[2]
		ebalgmod.r = color.r
		ebalgmod.g = color.g
		ebalgmod.b = color.b
		ebalgmod.a = 25

		for i,point in pairs(info[3]) do
			point = ReadPoint(point)

			local dis = point[3] or 6
			render.DrawWireframeSphere(point[1],dis,16,16,ebalgmod)
		end
	end
end)]]