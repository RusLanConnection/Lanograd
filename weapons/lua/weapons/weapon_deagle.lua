SWEP.Base = 'salat_base' -- base

SWEP.PrintName 				= ".357 Magnum"
SWEP.Author 				= "Homigrad"
SWEP.Instructions			= "Револьвер под калибр .357 Magnum"
SWEP.Category 				= "Оружие"
SWEP.WepSelectIcon			= "pwb2/vgui/weapons/matebahomeprotection"

SWEP.Spawnable 				= true
SWEP.AdminOnly 				= false

------------------------------------------

SWEP.Primary.ClipSize		= 6
SWEP.Primary.DefaultClip	= 6
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= ".357 Magnum"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 35
SWEP.Primary.Spread = 0
SWEP.Primary.Sound = "hndg_sw686/revolver_fire_01.wav"
SWEP.Primary.SoundFar = "snd_jack_hmcd_smp_far.wav"
SWEP.Primary.Force = 105/40
SWEP.ReloadTime = 2
SWEP.ShootWait = 0.7

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

------------------------------------------

SWEP.Weight					= 5
SWEP.AutoSwitchTo			= false
SWEP.AutoSwitchFrom			= false

SWEP.HoldType = "revolver"
SWEP.revolver = true

------------------------------------------

SWEP.Slot					= 2
SWEP.SlotPos				= 1
SWEP.DrawAmmo				= true
SWEP.DrawCrosshair			= false

SWEP.ViewModel				= "models/weapons/w_357.mdl"
SWEP.WorldModel				= "models/weapons/w_357.mdl"

function SWEP:ApplyEyeSpray()
    self.eyeSpray = self.eyeSpray - Angle(2,math.Rand(-0.5,0.5),0)
end

local function rolldrum(ply)
    local wep = ply:GetActiveWeapon()
    
    if not IsValid(ply) or not IsValid(wep) or wep:GetClass() != "weapon_deagle" then return end

    if wep:Clip1() > 0 then
        wep.tries = math.random(math.max(7 - wep:Clip1(),1))
        ply:EmitSound("weapons/357/357_spin1.wav",65)

        if CLIENT then
            net.Start("hg_rolldrum")
            net.WriteEntity(wep)
            net.WriteInt(wep.tries,4)
            net.SendToServer()
        else
            net.Start("hg_rolldrum")
            net.WriteEntity(wep)
            net.WriteInt(wep.tries,4)
            net.Send(ply)
        end
    else
        wep.AmmoChek = 3
		if timer.Exists("reload"..wep:EntIndex()) or wep:Clip1() >= wep:GetMaxClip1() or ply:GetAmmoCount( wep:GetPrimaryAmmoType() ) <= 0 then return nil end
		if wep.Owner:IsSprinting() then return nil end
		if ( wep.NextShot > CurTime() ) then return end
		ply:SetAnimation(PLAYER_RELOAD)
		wep:EmitSound(wep.ReloadSound,60,100,0.8,CHAN_AUTO)
		timer.Create( "reload"..wep:EntIndex(), wep.ReloadTime, 1, function()
			if IsValid(wep) and IsValid(wep.Owner) and wep.Owner:GetActiveWeapon()==wep then
				wep:SetClip1(1)
				ply:SetAmmo(ply:GetAmmoCount( wep:GetPrimaryAmmoType() ) - 1, wep:GetPrimaryAmmoType())
				wep.AmmoChek = 5

                wep.tries = math.random(1,7)

                if CLIENT then
                    net.Start("hg_rolldrum")
                    net.WriteEntity(wep)
                    net.WriteInt(wep.tries,4)
                    net.SendToServer()
                else
                    net.Start("hg_rolldrum")
                    net.WriteEntity(wep)
                    net.WriteInt(wep.tries,4)
                    net.Send(ply)
                end

                timer.Simple(0.7, function()
                    ply:EmitSound("weapons/357/357_spin1.wav",65)
                end)
			end
		end)
    end
end

function SWEP:RollDrum()
    rolldrum(self:GetOwner())
end

concommand.Add("hg_rolldrum",rolldrum)

if SERVER then
    util.AddNetworkString("hg_rolldrum")

    net.Receive("hg_rolldrum",function(len,ply)
        local wep = net.ReadEntity()

        wep.tries = net.ReadInt(4)
        ply:EmitSound("weapons/357/357_spin1.wav",65)
        --ply:ChatPrint(tostring(wep.tries)..(CLIENT and " client" or " server"))
    end)
else
    net.Receive("hg_rolldrum",function(len)
        local ply = LocalPlayer()

        local wep = net.ReadEntity()
        wep.tries = net.ReadInt(4)
        --ply:ChatPrint(tostring(wep.tries)..(CLIENT and " client" or " server"))
    end)
end

if SERVER then
    util.AddNetworkString("real_bul")

    function SWEP:Deploy()
        self:SetHoldType("normal")
        
        self:GetOwner():EmitSound("snd_jack_hmcd_pistoldraw.wav", 65, 100, 1, CHAN_AUTO)
    
        self.NextShot = CurTime() + 0.5
    
        self:SetHoldType( self.HoldType )

        self.tries = self.tries or math.random(math.max(7 - self:Clip1(),1))

        net.Start("real_bul")
        net.WriteEntity(self)
        net.WriteInt(self.tries,4)
        net.Send(self:GetOwner())
    end
else
    function SWEP:Deploy()
        self:SetHoldType("normal")
    
        self.NextShot = CurTime() + 0.5
    
        self:SetHoldType( self.HoldType )
    end

    net.Receive("real_bul",function(len)
        net.ReadEntity().tries = net.ReadInt(4)
    end)
end

function SWEP:CanFireBullet()
    if not IsFirstTimePredicted() then return end

    self.tries = self.tries or 1--math.ceil(util.SharedRandom("huy"..tostring(CurTime()),1,math.max(6 - self:Clip1(),1)))
    self.tries = self.tries - 1
    --self:GetOwner():ChatPrint(tostring(self.tries)..(CLIENT and " client" or " server"))

    return (self.tries <= 0)
end

SWEP.OffsetVec = Vector(8,5,1)

SWEP.dwsPos = Vector(15,15,5)
SWEP.dwsItemPos = Vector(3,0,2)

SWEP.vbwPos = Vector(6.2,4.5,-4)

SWEP.addPos = Vector(0,-1,-0.5)
SWEP.addAng = Angle(0.2,-0.1,0)