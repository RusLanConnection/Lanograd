include("shared.lua")

function SWEP:Cuff(ent)

    local bone = ent:LookupBone("ValveBiped.Bip01_L_Hand")
    local bone2 = ent:LookupBone("ValveBiped.Bip01_R_Hand")
    local ent1,ent2

    if bone then
        ent1 = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(bone))
        ent2 = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(bone2))

        ent1:SetPos(ent2:GetPos())
    end

    for i = 1,15 do constraint.Rope(ent,ent,5,7,Vector(0,0,0),Vector(0,0,0),2,0,0,0,"cable/rope.vmt",false,Color(255,255,255)) end

    self:Remove()
end

local constraint_FindConstraint = constraint.FindConstraint

local ent
function PlayerIsCuffs(ply)
	if not ply:Alive() then return end

	ent = ply:GetNWEntity("Ragdoll")
	if not IsValid(ent) then return end

	return constraint_FindConstraint(ent,"Rope")
end