AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")
include("weps.lua")


function ENT:Initialize()
	self:SetUseType( SIMPLE_USE )
	local ply = self:GetOwner()

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()

	if(IsValid(phys))then
		phys:Wake()
		--phys:SetMass(150)
	end

	self:GetOwner().wep = self

	timer.Simple(0, function()

		local wep = weapons.Get(self.curweapon)

		if wep.HoldType == "melee" or "knife" then 
			self.NextHit = 0
			self:SetCollisionGroup(COLLISION_GROUP_NONE)
		else
			self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		end

	end)
end

function ENT:Use(taker)

	local ply = self:GetOwner()
	local phys = self:GetPhysicsObject()
	local rag = self.rag
	
	local lootInfo = IsValid(ply) and ply.Info or IsValid(self.rag) and self.rag.Info

	if not ply.Otrub and not rag.deadbody then return end
	
	if taker:HasWeapon(self.curweapon) then
		if lootInfo then
			taker:GiveAmmo(lootInfo.Weapons[self.curweapon].Clip1, lootInfo.Weapons[self.curweapon].AmmoType)
			lootInfo.Weapons[self.curweapon].Clip1 = 0
		else
			taker:GiveAmmo(self.Clip, self.AmmoType)
			self.Clip = 0
		end
	else
		--taker.slots = taker.slots or {}
		--if not taker.slots[weapons.Get(self.curweapon).TwoHands and 3 or 2] then
			self:Remove()
			taker:Give(self.curweapon, true):SetClip1(lootInfo and lootInfo.Weapons[self.curweapon].Clip1 or self.Clip or 0)
			if lootInfo then lootInfo.Weapons[self.curweapon] = nil end
			if IsValid(ply) and ply:Alive() then ply:StripWeapon(ply.curweapon) SavePlyInfo(ply) end
		--end
	end

	if self.Clip == 0 then
		if self:IsPlayerHolding() then
			taker:DropObject()
		else
			taker:PickupObject(self)
		end
	end
end

function ENT:PhysicsCollide( data, phys )
	local wep = weapons.Get(self.curweapon)



	if (not data.HitEntity == self.rag) and CurTime() > self.NextHit and data.Speed > 70 and data.HitEntity and (wep.HoldType == "melee" or "knife") then 
		local dmginfo = DamageInfo()
		dmginfo:SetDamageType( wep.DamageType or DMG_SLASH)
		dmginfo:SetAttacker( self:GetOwner() )
		dmginfo:SetInflictor( self )
		dmginfo:SetDamagePosition( data.HitPos )
		dmginfo:SetDamageForce( data.HitEntity:GetForward() * wep.Primary.Force )
		dmginfo:SetDamage( math.Clamp(wep.Primary.Damage * (data.Speed / 80), 0, wep.Primary.Damage) )
		data.HitEntity:TakeDamageInfo( dmginfo )

		self.NextHit = CurTime() + 1
		print(math.Clamp(wep.Primary.Damage * (data.Speed / 80), 0, wep.Primary.Damage))
	end
end