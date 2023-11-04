local vecZero = Vector(0,0,0)
local angZero = Angle(0,0,0)
SWEP.Base = 'weapon_base' -- base

SWEP.PrintName 				= "salat_base"
SWEP.Author 				= "Homigrad"
SWEP.Instructions			= ""
SWEP.Category 				= "Other"
SWEP.WepSelectIcon			= ""

SWEP.Spawnable 				= false
SWEP.AdminOnly 				= false

------------------------------------------

SWEP.Primary.ClipSize		= 50
SWEP.Primary.DefaultClip	= 0
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "pistol"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 100
SWEP.Primary.Spread = 0
SWEP.Primary.Sound = "weapons/fiveseven/fiveseven-1.wav"
SWEP.Primary.SoundFar = "m9/m9_dist.wav"
SWEP.Primary.Force = 0
SWEP.ReloadTime = 2
SWEP.ShootWait = 0.12
SWEP.NextShot = 0
SWEP.Sight = false
SWEP.ReloadSound = ""
SWEP.TwoHands = false




SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.CSMuzzleFlashes = true

------------------------------------------

SWEP.Weight					= 5
SWEP.AutoSwitchTo			= false
SWEP.AutoSwitchFrom			= false

SWEP.HoldType = ""
SWEP.revolver = false
SWEP.shotgun = false

------------------------------------------

SWEP.DrawWeaponSelection = function(...) DrawWeaponSelection(...) end
SWEP.vbw = true
SWEP.vbwPos = false
SWEP.vbwAng = false
SWEP.Suppressed = false

local hg_show_hitposmuzzle = CreateClientConVar("hg_show_hitposmuzzle","0",false,false,"huy",0,1)


hook.Add("HUDPaint","admin_hitpos",function()
	if hg_show_hitposmuzzle:GetBool() and LocalPlayer():IsAdmin() then
		local wep = LocalPlayer():GetActiveWeapon()
		if not IsValid(wep) then return end

		local att = wep:LookupAttachment("muzzle")
		if not att then return end

		local att = wep:GetAttachment(att)
		if not att then return end

		local shootOrigin = att.Pos
		local vec = vecZero
		vec:Set(wep.addPos)
		vec:Rotate(att.Ang)
		shootOrigin:Add(vec)
	
		local shootAngles = att.Ang
		local ang = angZero
		ang:Set(wep.addAng)
		shootAngles:Add(ang)

		local tr = util.QuickTrace(shootOrigin,shootAngles:Forward() * 1000,LocalPlayer())
		local hit = tr.HitPos:ToScreen()
		
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawRect(hit.x - 2.5,hit.y - 2.5,5,5)
	end
end)

function SWEP:DrawHUD()
	show = math.Clamp(self.AmmoChek or 0,0,1)
	self.AmmoChek = Lerp(2*FrameTime(),self.AmmoChek or 0,0)
	color_gray = Color(225,215,125,190*show)
	color_gray1 = Color(225,215,125,255*show)
	if show > 0 then
	local ply = LocalPlayer()
	local ammo,ammobag = self:GetMaxClip1(), self:Clip1()
	if ammobag > ammo - 1 then
		text = "Полон"
	elseif ammobag > ammo - ammo/3 then
		text = "~Почти полон"
	elseif ammobag > ammo/3 then
		text = "~Половина"
	elseif ammobag >= 1 then
		text = "~Почти пуст"
	elseif ammobag < 1 then
		text = "Пуст"
	end

	local ammomags = ply:GetAmmoCount( self:GetPrimaryAmmoType() )

	if oldclip != ammobag then
		randomx = math.random(0, 5)
		randomy = math.random(0, 5)
		timer.Simple(0.15, function()
			oldclip = ammobag
		end)
	else
		randomx = 0
		randomy = 0
	end

	if oldmag != ammomags then
		randomxmag = math.random(0, 5)
		randomymag = math.random(0, 5)
		timer.Simple(0.35, function()
			oldmag = ammomags
		end)
	else
		randomxmag = 0
		randomymag = 0
	end

	local hand = ply:GetAttachment(ply:LookupAttachment("anim_attachment_rh"))
	local textpos = (hand.Pos+hand.Ang:Forward()*7+hand.Ang:Up()*5+hand.Ang:Right()*-1):ToScreen()
	if self.revolver then
		draw.DrawText( "Барабан | "..ammobag, "HomigradFontBig", textpos.x+randomx, textpos.y+randomy, color_gray1, TEXT_ALIGN_RIGHT )
		draw.DrawText( "Пуль | "..ammomags, "HomigradFontBig", textpos.x+randomxmag, textpos.y+25+randomymag, color_gray, TEXT_ALIGN_RIGHT )
	elseif self.shotgun then
		draw.DrawText( "Магазин | "..text, "HomigradFontBig", textpos.x+randomx, textpos.y+randomy, color_gray1, TEXT_ALIGN_RIGHT )
		draw.DrawText( "Патрон | "..ammomags, "HomigradFontBig", textpos.x+randomxmag, textpos.y+25+randomymag, color_gray, TEXT_ALIGN_RIGHT )
	else
		draw.DrawText( "Магазин | "..text, "HomigradFontBig", textpos.x+randomx, textpos.y+randomy, color_gray1, TEXT_ALIGN_RIGHT )
		draw.DrawText( "Магазинов | "..math.Round(ammomags/ammo), "HomigradFontBig", textpos.x+5+randomxmag, textpos.y+25+randomymag, color_gray, TEXT_ALIGN_RIGHT )
	end
	end
end

function SWEP:DrawWorldModel()
    self:DrawModel()
end
local pos = Vector(0,0,0)

function SWEP:BulletCallbackFunc(dmgAmt,ply,tr,dmg,tracer,hard,multi)
	
	if tr.MatType == MAT_FLESH then
		util.Decal("Impact.Flesh",tr.HitPos+tr.HitNormal,tr.HitPos-tr.HitNormal)
		local vPoint = tr.HitPos
		local effectdata = EffectData()
		effectdata:SetOrigin( vPoint )
	end

	if self.NumBullet or 1>1 then return end
	if tr.HitSky then return end
	if hard then self:RicochetOrPenetrate(tr) end


end

function SWEP:RicochetOrPenetrate(initialTrace)

	local AVec, IPos, TNorm, SMul = initialTrace.Normal, initialTrace.HitPos, initialTrace.HitNormal, HMCD_SurfaceHardness[initialTrace.MatType]
	if not(SMul)then SMul=.5 end
	local ApproachAngle=-math.deg(math.asin(TNorm:DotProduct(AVec)))
	local MaxRicAngle=60*SMul
	if(ApproachAngle<(MaxRicAngle*.25))then -- ping whiiiizzzz
		sound.Play("snd_jack_hmcd_ricochet_"..math.random(1,2)..".wav",IPos,70,math.random(90,100))
		local NewVec=AVec:Angle()
		NewVec:RotateAroundAxis(TNorm,180)
		NewVec=NewVec:Forward()
		self:FireBullets({
			Attacker=self:GetOwner(),
			Damage=self.Primary.Damage*.85,
			Force=self.Primary.Damage/15,
			Num=1,
			Tracer=1,
			TracerName="Tracer",
			Dir=-NewVec,
			Spread=Vector(0,0,0),
			Src=IPos+TNorm
		})
	end
end

homigrad_weapons = homigrad_weapons or {}

function SWEP:Initialize()
	homigrad_weapons[self] = true

	self.lerpClose = 0

	if self.shotgun then
		self:SetWeaponHoldType("ar2")
	end

	if self.HoldType == "revolver" then
		self.ShootWait = self.ShootWait * 2
	else
		self.ShootWait = self.ShootWait * 1.84
	end

	if self.HoldType == "shotgun" then
		self.ReloadTime = self.ReloadTime * 1.2
	end
	
	timer.Simple(0, function()
		self:SetNWEntity( "OldOwner", self:GetOwner() )
	end)
end

function SWEP:PrePrimaryAttack()
end

function SWEP:CanFireBullet()
	return true
end

if SERVER then
	util.AddNetworkString("huysound")
end

if CLIENT then
	net.Receive("huysound",function(len)
		local pos = net.ReadVector()
		local sound = net.ReadString()
		local farsound = net.ReadString() or "m9/m9_dist.wav"
		local ent = net.ReadEntity()
		local supressed = net.ReadBool()

		if ent == LocalPlayer() then return end

		local dist = LocalPlayer():EyePos():Distance(pos)
		if ent:IsValid() and dist < 1100 then
			ent:EmitSound(sound, supressed and 60 or 125,math.random(100,120),1,CHAN_WEAPON,0,0)
		elseif ent:IsValid() then
			if not supressed then
				ent:EmitSound(farsound, 125,math.random(100,120),1,CHAN_WEAPON,0,0)
			end 
		end
	end)
end

function SWEP:PrimaryAttack()
	self.ShootNext = self.NextShot or NextShot

	if not self:IsScope() then return end

	if not IsFirstTimePredicted() then return end

	if self.NextShot > CurTime() then return end
	if timer.Exists("reload"..self:EntIndex()) then return end


	local canfire = self:CanFireBullet()
	--self:GetOwner():ChatPrint(tostring(canfire)..(CLIENT and " client" or " server"))
	if self:Clip1() <= 0 or not canfire and self.NextShot < CurTime() then
		if SERVER then
			sound.Play("snd_jack_hmcd_click.wav",self:GetPos(),65,100)
		end
		self.NextShot = CurTime() + self.ShootWait
		self.AmmoChek = 3
		return
	end

	if self.isClose or not self:GetOwner():IsNPC() and self:GetOwner():IsSprinting() then return end

	local ply = self:GetOwner() -- а ну да
	self.NextShot = CurTime() + self.ShootWait
	
	if SERVER then
		net.Start("huysound")
		net.WriteVector(self:GetPos())
		net.WriteString(self.Primary.Sound)
		net.WriteString(self.Primary.SoundFar)
		net.WriteEntity(self:GetOwner())
		net.WriteBool(self.Supressed)
		net.Broadcast()
	else
		self:EmitSound(self.Primary.Sound,511,math.random(100,120),1,CHAN_VOICE_BASE,0,0)
	end
	
	local dmg = self.Primary.Damage--self.TwoHands and self.Primary.Damage * 2 or self.Primary.Damage
    self:FireBullet(dmg, 1, 5)
	

	if SERVER and not ply:IsNPC() then
		if ply.RightArm < 1 then
			ply.pain = ply.pain + self.Primary.Damage / 30 * (self.NumBullet or 1)
		end

		if ply.LeftArm < 1 and self.TwoHands then
			ply.pain = ply.pain + self.Primary.Damage / 30 * (self.NumBullet or 1)
		end
	end

	if CLIENT and ply == LocalPlayer() then
		self.ZazhimYaycami = math.min(self.ZazhimYaycami + 2,self.Primary.ClipSize)
	end
	
	if CLIENT and (self:GetOwner() != LocalPlayer()) then
		self:GetOwner():SetAnimation(PLAYER_ATTACK1)
	end
	
	self.lastShoot = CurTime()
	self:SetNWFloat("LastShoot",CurTime())

	if CLIENT and ply == LocalPlayer() then
		self.eyeSpray = self.eyeSpray or Angle(0,0,0)
		
		local func = self.ApplyEyeSpray
		if func then
			func(self)
		else
			self.eyeSpray:Add(Angle(math.Rand(-0.9,0.5) * self.Primary.Damage / 30 * math.max((self.ZazhimYaycami / self.Primary.ClipSize),0.2),math.Rand(-0.5,0.5) * self.Primary.Damage / 30 * math.max((self.ZazhimYaycami / self.Primary.ClipSize),0.2),0))
		end
	end
end

function SWEP:Reload()

	self.AmmoChek = 3

	if timer.Exists("reload"..self:EntIndex())  or self:Clip1()>=self:GetMaxClip1() or self:GetOwner():GetAmmoCount( self:GetPrimaryAmmoType() )<=0 then return nil end
	if self:GetOwner():IsSprinting() then return nil end
	if ( self.NextShot > CurTime() ) then return end
	if self:IsScope() then return end
	
	self:SetWeaponHoldType(self.HoldType)

	self:GetOwner():SetAnimation(PLAYER_RELOAD)
	self:EmitSound(self.ReloadSound,60,100,0.8,CHAN_AUTO)
	timer.Create( "reload"..self:EntIndex(), self.ReloadTime, 1, function()
		if IsValid(self) and IsValid(self:GetOwner()) and self:GetOwner():GetActiveWeapon()==self then
			local oldclip = self:Clip1()
			self:SetClip1(math.Clamp(self:Clip1()+self:GetOwner():GetAmmoCount( self:GetPrimaryAmmoType() ),0,self:GetMaxClip1()))
			local needed = self:Clip1()-oldclip
			self:GetOwner():SetAmmo(self:GetOwner():GetAmmoCount( self:GetPrimaryAmmoType() )-needed, self:GetPrimaryAmmoType())
			self.AmmoChek = 5
		end
	end)
end

Sound("snd_jack_hmcd_lightning.wav")

SWEP.addPos = Vector(0,0,0)
SWEP.addAng = Angle(0,0,0)

if SERVER then
	util.AddNetworkString("shoot_huy")
else
	net.Receive("shoot_huy",function(len)
		local tr = net.ReadTable()
		--snd_jack_hmcd_bc_1.wav

		local dist,vec,dist2 = util.DistanceToLine(tr.StartPos,tr.HitPos,EyePos())
		if dist < 128 and dist2 > 128 then
			EmitSound("snd_jack_hmcd_bc_"..tostring(math.random(1,7))..".wav", vec, 1, CHAN_WEAPON, 1, 75, 0, 100)
		end
	end)
end

function SWEP:FireBullet(dmg, numbul, spread)
	if self:Clip1() <= 0 then return end
	if timer.Exists("reload"..self:EntIndex()) then return nil end
	
	local ply = self:GetOwner()

	ply:LagCompensation(true)

	local obj = self:LookupAttachment("muzzle")
	local Attachment = self:GetOwner():GetActiveWeapon():GetAttachment(obj)

	local cone = self.Primary.Cone

	local shootOrigin = Attachment.Pos
	local vec = vecZero
	vec:Set(self.addPos)
	vec:Rotate(Attachment.Ang)
	shootOrigin:Add(vec)

	local shootAngles = Attachment.Ang
	local ang = angZero
	ang:Set(self.addAng)
	shootAngles:Add(ang)

	local shootDir = shootAngles:Forward()

	local npc = ply:IsNPC() and ply:GetShootPos() or shootOrigin
	local npcdir = ply:IsNPC() and ply:GetAimVector() or shootDir
	local bullet = {
		Num 			= self.NumBullet or 1,
		Src 			= npc,
		Dir 			= npcdir,
		Spread 			= Vector(cone,cone,0),
		Force			= self.Primary.Force / 40,
		Damage			= self.Primary.Damage * 4,
		AmmoType     	= self.Primary.Ammo,
		Attacker 		= ply,
		Tracer       	= 1,
		TracerName   	= "Tracer",
		IgnoreEntity 	= not ply:IsNPC() and ply:GetVehicle() or ply,

		Callback = function(ply,tr,dmgInfo)
			ply:GetActiveWeapon():BulletCallbackFunc(self.Primary.Damage,ply,tr,self.Primary.Damage,false,true,false)
			--dmgInfo:SetDamageForce(dmgInfo:GetDamageForce())
	
			if self.Primary.Ammo == "buckshot" then
				local k = math.max(1 - tr.StartPos:Distance(tr.HitPos) / 750,0)
	
				dmgInfo:ScaleDamage(k)
			end
			
			if SERVER then
				net.Start("shoot_huy")
					net.WriteTable(tr)
				net.Broadcast()
			end
		end,
	}



	if SERVER then self:TakePrimaryAmmo(1) end

	if not ply:GetNWBool("Suiciding") then
		if SERVER then
			timer.Simple(0, function()
				ply:FireBullets(bullet)
			end)
		end
		self:SetLastShootTime()
	else
		if SERVER then
			ply.KillReason = "killyourself"

			--self:GetOwner():FireBullets(bullet)
			local dmgInfo = DamageInfo()
			dmgInfo:SetAttacker(ply)
			dmgInfo:SetInflictor(self)
			dmgInfo:SetDamage(bullet.Damage * 4 * (self.NumBullet or 1))
			dmgInfo:SetDamageType(DMG_BULLET)
			dmgInfo:SetDamageForce(shootDir * 1024)
			dmgInfo:SetDamagePosition(ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Head1")))
			ply:TakeDamageInfo(dmgInfo)

			ply.LastDMGInfo = dmgInfo
			ply.LastHitBoneName = "ValveBiped.Bip01_Head1"

		end
	end

	ply:LagCompensation(false)

	local effectdata = EffectData()
	effectdata:SetOrigin(shootOrigin)
	effectdata:SetAngles(shootAngles)
	effectdata:SetScale(self:IsScope() and 0.1 or 1)
	effectdata:SetNormal(shootDir)
	util.Effect("MuzzleEffect",effectdata)

	if self:GetOwner():IsNPC() then
		self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	end
end

local mul = 1
local FrameTime,TickInterval = FrameTime,engine.TickInterval

hook.Add("Think","Mul lerp",function()
	mul = FrameTime() / TickInterval()
end)

local Lerp,LerpVector,LerpAngle = Lerp,LerpVector,LerpAngle
local math_min = math.min

function LerpFT(lerp,source,set)
	return Lerp(math_min(lerp * mul,1),source,set)
end

function LerpVectorFT(lerp,source,set)
	return LerpVector(math_min(lerp * mul,1),source,set)
end

function LerpAngleFT(lerp,source,set)
	return LerpAngle(math_min(lerp * mul,1),source,set)
end

local pairs,IsValid = pairs,IsValid

hook.Add("Think","weapons-sadsalat",function()
	for wep in pairs(homigrad_weapons) do
		if not IsValid(wep) then homigrad_weapons[wep] = nil continue end

		local owner = wep:GetOwner()
		if not IsValid(owner) or (owner:IsPlayer() and not owner:Alive()) or owner:GetActiveWeapon() ~= wep then continue end--wtf i dont know

		if wep.Step then wep:Step() end
	end
end)

function SWEP:Think()
	
end

local timer_Exists = timer.Exists

function SWEP:IsLocal()
	return CLIENT and self:GetOwner() == LocalPlayer()
end

function SWEP:IsReloaded()
	return timer_Exists("reload"..self:EntIndex())
end

function SWEP:IsScope()
	local ply = self:GetOwner()
	if ply:IsNPC() then return end

	if self:IsLocal() or SERVER then
		return not ply:IsSprinting() and ply:KeyDown(IN_ATTACK2) and not self:IsReloaded()
	else
		return self:GetNWBool("IsScope")
	end
end

if SERVER then
	concommand.Add("suicide",function(ply)
		if not ply:Alive() then return end
		ply.suiciding = not ply.suiciding
		ply:SetNWBool("Suiciding",ply.suiciding)
	end)
end

hook.Add("PlayerDeath","suciding",function(ply)
	ply.suiciding = false
	ply:SetNWBool("Suiciding",false)
end)

local util_QuickTrace = util.QuickTrace
local math_Clamp = math.Clamp
local closeAng = Angle(0,0,0)

local angZero = Angle(0,0,0)
local angSuicide = Angle(160,30,90)
local angSuicide2 = Angle(160,30,90)
local angSuicide3 = Angle(60,-30,90)
local forearm,clavicle,hand = Angle(0,0,0),Angle(0,0,0),Angle(0,0,0)

hook.Add("HUDShouldDraw","ScopeSelectfix",function(name)
    if name == "CHudWeaponSelection" then 
		if LocalPlayer():GetActiveWeapon():GetNWBool("IsScope") then
			return false 
		else
			return true
		end
	end
end)

function SWEP:Step()
	local ply = self:GetOwner()
	local isLocal = self:IsLocal()

	if not IsValid(ply) or ply:IsNPC() or IsValid(ply:GetNWEntity("Ragdoll")) then return end

	if isLocal then
		self.eyeSpray = self.eyeSpray or Angle(0,0,0)
		
		ply:SetEyeAngles(ply:EyeAngles() + self.eyeSpray)
		
		self.eyeSpray = LerpAngleFT(0.5,self.eyeSpray,Angle(0,0,0))

		self.ZazhimYaycami = math.max((self.ZazhimYaycami or 0) - 0.1,0)
	end

	if SERVER then
		ply:SetNWInt("RightArm",ply.RightArm)
		ply:SetNWInt("LeftArm",ply.LeftArm)
	end

	local t = {}

	if not self.TwoHands then
		t.start = ply:GetShootPos() + ply:GetAngles():Right()*2.5 --+ Angle(0,ply:GetAngles().y,ply:GetAngles().z):Forward() * 10
	else
		t.start = ply:GetShootPos() + ply:GetAngles():Right()*7 --+ Angle(0,ply:GetAngles().y,ply:GetAngles().z):Forward() * 10
	end

	t.endpos = t.start + Angle(0,ply:GetAngles().y,ply:GetAngles().z):Forward() * 100
	t.filter = player.GetAll(),ply:GetNWEntity("Armor")
	local tr = util.TraceLine(t)
	self.dist = (tr.HitPos - t.start):Length()

	if not ply:IsSprinting() then
		local scope = self:IsScope()
		if SERVER then self:SetNWBool("IsScope",scope) end

		if isLocal then
			--self.eyeSpray = self.eyeSpray + Angle(math.Rand(-0.03,0.03),math.Rand(-0.03,0.03),math.Rand(-0.03,0.03))
			if (ply:GetNWInt("LeftArm") < 1 or ply:GetNWInt("RightArm") < 1) then
				local p = 0.3 - math.min((painlosing or 0),0.3)
				self.eyeSpray = self.eyeSpray + Angle(math.Rand(-p,p),math.Rand(-p,p),math.Rand(-p,p))
			end
		end

		if isLocal or SERVER then
			local head = ply:LookupBone("ValveBiped.Bip01_L_Hand")

			if head then
				local pos,ang = ply:GetBonePosition(head)
				pos[3] = pos[3] + 5
				ang:RotateAroundAxis(ang:Up(),-90)

				local dir = ang:Forward() * 1000
				local tr = util_QuickTrace(pos,dir,ply)
				local dist = pos:DistToSqr(tr.HitPos)

				self.isClose = self.dist <= 35 and not self:IsReloaded()
				
				if SERVER then self:SetNWBool("isClose",self.isClose) end
			end
		else
			self.isClose = self:GetNWBool("isClose")
		end
		hand:Set(angZero)
		if not self.isClose and not ply:IsSprinting() then
			if not ply:GetNWBool("Suiciding") then
				self:SetWeaponHoldType(self.HoldType)
				hand:Set(angZero)
				forearm:Set(angZero)
			elseif not self.TwoHands and ply:GetNWBool("Suiciding") then
				self:SetWeaponHoldType("normal")
				forearm:Set(angSuicide2)
				hand:Set(angSuicide3)
			elseif ply:GetNWBool("Suiciding") then
				self:SetWeaponHoldType("normal")
				hand:Set(angSuicide)
			end

			if self:IsScope() then
				if self.shotgun then
					self:SetWeaponHoldType("ar2")
				end
			end
		end

		if not self:IsScope() and not timer.Exists("reload"..self:EntIndex()) then
			self.isClose = true

			if self.shotgun then
				self:SetWeaponHoldType("ar2")
			end
		end
	else
		self.isClose = true
		--[[if not self.TwoHands then
			self:SetWeaponHoldType("normal")
		else
			self:SetWeaponHoldType("passive")
		end--]]
	end
	self.lerpClose = LerpFT(0.1,self.lerpClose,(self.isClose and 1) or 0)

	local eyeangles = (-ply:GetEyeTrace().HitPos + ply:EyePos()):Angle()
	eyeangles:RotateAroundAxis(eyeangles:Up(),180)
	
	if ((CLIENT and isLocal) or SERVER) then
		if not ply:GetNWBool("Suiciding") and not ply:IsSprinting() then
			local numbr = self.TwoHands and 50 or 80
			if eyeangles[1] > numbr then
				hand[1] = hand[1] - (eyeangles[1] - numbr)
			end

			if eyeangles[1] < -numbr then
				hand[1] = hand[1] - (eyeangles[1] + numbr)
			end
		end
	end

	clavicle:Set(angZero)
	closeAng[3] = -40 * self.lerpClose--(-60 + math_Clamp(ply:EyeAngles()[1],0,60)) * self.lerpClose
	clavicle:Add(closeAng)

	if not ply:LookupBone("ValveBiped.Bip01_R_Forearm") then return end--;c

	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Forearm"),forearm,false)
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Clavicle"),clavicle,false)
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Hand"),hand,false)

	--ply:ManipulateBonePosition(ply:LookupBone("ValveBiped.Bip01_R_Upperarm"),upperarm_pos,false)
	--ply:ManipulateBonePosition(ply:LookupBone("ValveBiped.Bip01_R_Clavicle"),clavicle_pos,false)
end

function SWEP:Holster( wep )
	--if not IsFirstTimePredicted() then return end
	local ply = self:GetOwner()

	if not ply:LookupBone("ValveBiped.Bip01_R_Forearm") then return end--;c

	timer.Simple(0.1, function()
		ply:ManipulateBoneAngles( ply:LookupBone( "ValveBiped.Bip01_R_Hand" ), Angle( 0,0,0 ) )
		ply:ManipulateBoneAngles( ply:LookupBone( "ValveBiped.Bip01_R_Forearm" ), Angle( 0,0,0 ))
		ply:ManipulateBoneAngles( ply:LookupBone( "ValveBiped.Bip01_R_Clavicle" ),Angle( 0,0,0 ))
	end)

	return true
end

function SWEP:SecondaryAttack() return end

function SWEP:Deploy()
	self:SetHoldType("normal")
	if SERVER then
		self:GetOwner():EmitSound("snd_jack_hmcd_pistoldraw.wav", 65,(self.TwoHands and 100) or (!self.TwoHands and 110), 1, CHAN_AUTO)
	end

	self.NextShot = CurTime() + 0.5

	self:SetHoldType( self.HoldType )
end

function SWEP:OnDrop()
end

function SWEP:OwnerChanged()
	local ply = self:GetNWEntity("OldOwner")

	if not IsValid(ply) then return end

	timer.Simple(0.1, function()
		ply:ManipulateBoneAngles( ply:LookupBone( "ValveBiped.Bip01_R_Hand" ), Angle( 0,0,0 ) )
		ply:ManipulateBoneAngles( ply:LookupBone( "ValveBiped.Bip01_R_Forearm" ), Angle( 0,0,0 ))
		ply:ManipulateBoneAngles( ply:LookupBone( "ValveBiped.Bip01_R_Clavicle" ),Angle( 0,0,0 ))
	end)
end



function SWEP:OnRemove()
end

function SWEP:ShouldDropOnDie()
	return false
end
