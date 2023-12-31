util.AddNetworkString("add_footstep")
util.AddNetworkString("clear_footsteps")

function FootstepsOnFootstep(ply, pos, foot, sound, volume, filter)
	net.Start("add_footstep")
	net.WriteEntity(ply)
	net.WriteVector(pos)
	net.WriteAngle(ply:GetAimVector():Angle())
	local tab = {}
	for k, ply in pairs(player.GetAll()) do
		if CanSeeFootsteps(ply) then
			table.insert(tab, ply)
		end
	end
	net.Send(tab)
end

function CanSeeFootsteps(ply)
	if ply.roleT and roundActiveName == "homicide" then return true end
	return false
end

function ClearAllFootsteps()
	net.Start("clear_footsteps")
	net.Broadcast()
end

hook.Add( "PlayerFootstep", "SV_MurderFootStep", function( ply, pos, foot, sound, volume, filter )
	FootstepsOnFootstep(ply, pos, foot, sound, volume, filter)
end )