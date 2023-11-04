
AddCSLuaFile()

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Slot = 5
SWEP.SlotPos = 3

function SWEP:Initialize()
	--wat
end


function SWEP:DrawWorldModel()	
	self:DrawModel()
end


SWEP.Base="weapon_base"

SWEP.ViewModel = "models/props_c17/SuitCase_Passenger_Physics.mdl"
SWEP.WorldModel = "models/props_c17/SuitCase_Passenger_Physics.mdl"

SWEP.PrintName = "Костюм маньяка"
SWEP.Category = "Примочки убийцы" 
SWEP.Instructions	= ""
SWEP.Author			= ""
SWEP.Contact		= ""
SWEP.Purpose		= ""

SWEP.Weight	= 3
SWEP.AutoSwitchTo		= true
SWEP.AutoSwitchFrom		= false

SWEP.DrawWeaponSelection = DrawWeaponSelection
SWEP.OverridePaintIcon = OverridePaintIcon

SWEP.CommandDroppable=false

SWEP.Spawnable			= true
SWEP.AdminOnly			= false

SWEP.Primary.Delay			= 0.5
SWEP.Primary.Recoil			= 3
SWEP.Primary.Damage			= 120
SWEP.Primary.NumShots		= 1	
SWEP.Primary.Cone			= 0.04
SWEP.Primary.ClipSize		= -1
SWEP.Primary.Force			= 900
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic   	= true
SWEP.Primary.Ammo         	= "none"

SWEP.Secondary.Delay		= 0.9
SWEP.Secondary.Recoil		= 0
SWEP.Secondary.Damage		= 0
SWEP.Secondary.NumShots		= 1
SWEP.Secondary.Cone			= 0
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic   	= false
SWEP.Secondary.Ammo         = "none"

local PlayerMeta = FindMetaTable("Player")

function PlayerMeta:HideIdentity()
	if self.IdentityHidden then return end

	self.TrueIdentity={
		plyName = self:GetNWString("Nickname"),
		plyModel = self:GetModel(),
		plyColor = self:GetPlayerColor(),
		plyCloth = self.ClothingType
	}

	if homicide.roundType == 1 then 
		self:SetNWString("Nickname", "Предатель")
		--self:SetNWString("CustomName", "Предатель")
		self:SetModel("models/player/phoenix.mdl")
		self:SetPlayerColor(Vector(0, 0, 0))
	else
		self:SetNWString("Nickname", "Убийца")
		--self:SetNWString("CustomName", "Убийца")
		self:SetModel("models/player/corpse1.mdl")
		self:SetPlayerColor(Vector(1, 0, 0))
	end

	sound.Play("snd_jack_hmcd_disguise.wav",self:GetPos(),65,110)
	self.IdentityHidden=true
end

function PlayerMeta:ShowIdentity()
	if not self.IdentityHidden then return end

	sound.Play("snd_jack_hmcd_disguise.wav",self:GetPos(),65,90)

	self:SetNWString("Nickname", self.TrueIdentity.plyName)
	self:SetModel(self.TrueIdentity.plyModel)
	self:SetPlayerColor(self.TrueIdentity.plyColor)
	SetCloth(self, self.TrueIdentity.plyCloth)

	self.TrueIdentity=nil
	self.IdentityHidden=false
end

function SWEP:Initialize()
	self:SetHoldType("normal")
end

function SWEP:PrimaryAttack()
	if self:GetOwner():KeyDown(IN_SPEED) and self:GetOwner():KeyDown(IN_FORWARD) then return end

	self:GetOwner():SetAnimation(PLAYER_ATTACK1)
	if SERVER then
		self:GetOwner():HideIdentity()
	end
	self:SetNextPrimaryFire(CurTime()+1)
	self:SetNextSecondaryFire(CurTime()+1)
end

function SWEP:Deploy()
	self:SetNextPrimaryFire(CurTime()+1)
	self:SetNextSecondaryFire(CurTime()+1)
	self.DownAmt=20
	return true
end

function SWEP:SecondaryAttack()
	if self:GetOwner():KeyDown(IN_SPEED) and self:GetOwner():KeyDown(IN_FORWARD) then return end

	self:GetOwner():SetAnimation(PLAYER_ATTACK1)

	if SERVER then
		self:GetOwner():ShowIdentity()
	end

	self:SetNextPrimaryFire(CurTime()+1)
	self:SetNextSecondaryFire(CurTime()+1)
end

function SWEP:Think()
	--
end

function SWEP:Reload()
	--
end

function SWEP:OnDrop()
	--self:GetOwner():DropWeapon1(self:GetOwner():GetActiveWeapon())
end

if CLIENT then
    local model = GDrawWorldModel or ClientsideModel(SWEP.WorldModel,RENDER_GROUP_OPAQUE_ENTITY)
    GDrawWorldModel = model
    model:SetNoDraw(true)

    SWEP.dwmModeScale = 0.5
    SWEP.dwmForward = 5
    SWEP.dwmRight = 0
    SWEP.dwmUp = 0

    SWEP.dwmAUp = 0
    SWEP.dwmARight = 90
    SWEP.dwmAForward = 0
    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()
        if not IsValid(owner) then
            self:DrawModel()

            return
        end

        local Pos,Ang = owner:GetBonePosition(owner:LookupBone("ValveBiped.Bip01_R_Hand"))
        if not Pos then return end

        model:SetModel(self.WorldModel)
        model:SetSkin(not self.bloodinside and 1 or 0)

        Pos:Add(Ang:Forward() * self.dwmForward)
        Pos:Add(Ang:Right() * self.dwmRight)
        Pos:Add(Ang:Up() * self.dwmUp)

        model:SetPos(Pos)

        Ang:RotateAroundAxis(Ang:Up(),self.dwmAUp)
        Ang:RotateAroundAxis(Ang:Right(),self.dwmARight)
        Ang:RotateAroundAxis(Ang:Forward(),self.dwmAForward)
        model:SetAngles(Ang)

        model:SetModelScale(1)

        model:DrawModel()
    end
end

hook.Add("PostPlayerDeath", "ResetMurderName", function(ply)
	ply:SetNWString("Nickname",ply:Name())
end)