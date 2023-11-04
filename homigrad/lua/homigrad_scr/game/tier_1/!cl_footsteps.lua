local FootSteps = {}
if FootStepsG then
	FootSteps = FootStepsG
end
FootStepsG = FootSteps

local footMat = Material( "thieves/footprint" )
-- local CircleMat = Material( "Decals/burn02a" )
local maxDistance = 512
local function renderfoot()
	cam.Start3D(EyePos(), EyeAngles())
	render.SetMaterial( footMat )
	local pos = EyePos()
	local lifeTime = 40
	for k, footstep in pairs(FootSteps) do
		if footstep.curtime + lifeTime > CurTime() then
			if (footstep.pos - EyePos()):LengthSqr() < maxDistance then
				local FSCol,Ambient=footstep.col,render.GetLightColor(footstep.pos)
				FSCol=Color(FSCol.r*Ambient.x,FSCol.g*Ambient.y,FSCol.b*Ambient.z,200)
				render.DrawQuadEasy( footstep.pos + footstep.normal * 0.01, footstep.normal, 10, 20, FSCol, footstep.angle ) 
			end
		else
			FootSteps[k] = nil
		end
	end
	cam.End3D()
end

function DrawFootprints()
	renderfoot()
end

function AddFootstep(ply, pos, ang)
	if(ply==LocalPlayer())then return end -- don't confuse the murderer
	ang.p = 0
	ang.r = 0
	local fpos = pos
	if ply.LastFoot then
		fpos = fpos + ang:Right() * 5
	else
		fpos = fpos + ang:Right() * -5
	end
	ply.LastFoot = !ply.LastFoot

	local trace = {}
	trace.start = fpos
	trace.endpos = trace.start + Vector(0,0,-10)
	trace.filter = ply
	local tr = util.TraceLine(trace)

	if tr.Hit then

		local tbl = {}
		tbl.pos = tr.HitPos
		tbl.plypos = fpos
		tbl.foot = foot
		tbl.curtime = CurTime()
		tbl.angle = ang.y
		tbl.normal = tr.HitNormal
		local col = ply:GetPlayerColor()
		tbl.col = Color(col.x * 255, col.y * 255, col.z * 255)
		table.insert(FootSteps, tbl)
	end
end

function FootStepsFootstep(ply, pos, foot, sound, volume, filter)

	if ply != LocalPlayer() then return end

	if !CanSeeFootsteps() then return end

	AddFootstep(ply, pos, ply:GetAimVector():Angle())
end

function CanSeeFootsteps()
	if LocalPlayer().Murderer && LocalPlayer():Alive() then return true end
	return false
end

function ClearFootsteps()
	table.Empty(FootSteps)
end

net.Receive("add_footstep", function ()
	local ply = net.ReadEntity()
	local pos = net.ReadVector()
	local ang = net.ReadAngle()

	if !IsValid(ply) then return end

	if ply == LocalPlayer() then return end

	if !CanSeeFootsteps() then return end

	AddFootstep(ply, pos, ang)
end)

net.Receive("clear_footsteps", function ()
	ClearFootsteps()
end)

hook.Add( "PlayerFootstep", "CL_MurderFootStep", function( ply, pos, foot, sound, volume, filter )
	FootStepsFootstep(ply, pos, foot, sound, volume, filter)
end )

hook.Add( "PostDrawTranslucentRenderables", "DrawFootprints", function( bDepth, bSkybox )
	DrawFootprints()
end )