SWEP.Base = "weapon_base"

SWEP.PrintName = "База Гаранаты"
SWEP.Author = "sadsalat"
SWEP.Purpose = "Бах Бам Бум, Бадабум!"

SWEP.Slot = 4
SWEP.SlotPos = 0
SWEP.Spawnable = false

SWEP.ViewModel = "models/pwb/weapons/w_f1.mdl"
SWEP.WorldModel = "models/pwb/weapons/w_f1.mdl"

SWEP.Granade = ""

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.Armed = false 
SWEP.ArmedEnt = nil
SWEP.DoNotArm = false 

SWEP.DrawWeaponSelection = DrawWeaponSelection
SWEP.OverridePaintIcon = OverridePaintIcon

function TrownGranade(ply,force,granade)
    local grenarm = ply:GetActiveWeapon().ArmedEnt

    if ply:GetActiveWeapon().Armed then
        grenarm:SetParent()
        grenarm:SetNoDraw(false)
        grenarm:SetPos(ply:GetShootPos() +ply:GetAimVector()*10)
	    grenarm:SetAngles(ply:EyeAngles()+Angle(45,45,0))
	    grenarm:SetOwner(ply)
	    grenarm:SetPhysicsAttacker(ply)
        grenarm:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        local phys = grenarm:GetPhysicsObject()              
	    if not IsValid(phys) then grenarm:Remove() return end                         
	    phys:SetVelocity(ply:GetVelocity() + ply:GetAimVector() * force)
	    phys:AddAngleVelocity(VectorRand() * force/2)
    else
        local granade = ents.Create(granade)
        granade:SetPos(ply:GetShootPos() +ply:GetAimVector()*10)
	    granade:SetAngles(ply:EyeAngles()+Angle(45,45,0))
	    granade:SetOwner(ply)
	    granade:SetPhysicsAttacker(ply)
        granade:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	    granade:Spawn()       
	    granade:Arm()
	    local phys = granade:GetPhysicsObject()              
	    if not IsValid(phys) then granade:Remove() return end                         
	    phys:SetVelocity(ply:GetVelocity() + ply:GetAimVector() * force)
	    phys:AddAngleVelocity(VectorRand() * force/2)
    end
end

function SWEP:Deploy()
    self:SetHoldType( "melee" )
end

function SWEP:PrimaryAttack()
    if SERVER then    
        TrownGranade(self:GetOwner(),750,self.Granade)
        self:Remove()
        self:GetOwner():SelectWeapon("weapon_hands")
    elseif CLIENT then
    end
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
    self:EmitSound("weapons/m67/handling/m67_throw_01.wav")
end

function SWEP:SecondaryAttack()
    if SERVER then
        TrownGranade(self:GetOwner(),250,self.Granade)
        self:Remove()
        self:GetOwner():SelectWeapon("weapon_hands")
    elseif CLIENT then
    end
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
    self:EmitSound("weapons/m67/handling/m67_throw_01.wav")
end

function SWEP:Reload()
    if SERVER then
        if self.Armed then return end
        if self.DoNotArm then return end

        local ply = self:GetOwner()
        local granade = ents.Create(self.Granade)

        granade:SetPos(ply:GetShootPos() + ply:GetAimVector() )
	    granade:SetOwner(ply)
	    granade:SetPhysicsAttacker(ply)
        granade:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
        granade:SetNoDraw(true)
	    granade:Spawn()

        granade:SetParent(ply)

	    granade:Arm()

        self.ArmedEnt = granade
        self.Armed = true
    end
end

function SWEP:OnDrop()
    if SERVER then
        local grenarm

        if not self.Armed then
            granade = ents.Create(self.Granade)
            grenarm = granade
        else
            grenarm = self.ArmedEnt
            grenarm:SetParent()
        end
        
        local ply = self:GetOwner()
        --local force = 15

        grenarm:SetNoDraw(false)
        --grenarm:SetPos(ply:GetShootPos() + ply:GetAimVector() * 10)
	    --grenarm:SetAngles(ply:EyeAngles()+Angle(45,45,0))
	    grenarm:SetOwner(ply)
	    --grenarm:SetPhysicsAttacker(ply)
        grenarm:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        --[[local phys = grenarm:GetPhysicsObject()              
	    if not IsValid(phys) then grenarm:Remove() return end                         
	    phys:SetVelocity(ply:GetVelocity() + ply:GetAimVector() * force)
	    phys:AddAngleVelocity(VectorRand() * force/2)]]
    end
end