SWEP.Base                   = "medkit"

SWEP.PrintName 				= "Телефон"
SWEP.Author 				= "Homigrad"
SWEP.Instructions			= "Лучше звоните копам"
SWEP.Category 				= "Разное"

SWEP.Spawnable 				= true
SWEP.AdminOnly 				= false

SWEP.Slot					= 0
SWEP.SlotPos				= 3
SWEP.DrawAmmo				= true
SWEP.DrawCrosshair			= false

SWEP.ViewModel				= "models/lt_c/tech/cellphone.mdl"
SWEP.WorldModel				= "models/lt_c/tech/cellphone.mdl"

SWEP.ViewBack = true
SWEP.ForceSlot1 = true

SWEP.DrawWeaponSelection = DrawWeaponSelection
SWEP.OverridePaintIcon = OverridePaintIcon

SWEP.dwsPos = Vector(10,10,7)
SWEP.dwsItemPos = Vector(0,3,0)

SWEP.dwmARight = 130
SWEP.dwmAForward = 60
SWEP.dwmForward = 3
SWEP.dwmRight = 1


function SWEP:PrimaryAttack() 
end

if SERVER then
	function SWEP:Initialize()
		self:SetHoldType("slam")
		self:SetSkin(2)
	end

    function SWEP:Deploy()
        
    end

    function SWEP:Holster()
        return true
    end

    function SWEP:PrimaryAttack() 
		if self:GetOwner():KeyDown(IN_SPEED) and self:GetOwner():KeyDown(IN_FORWARD) then return end

		self:GetOwner():SetAnimation(PLAYER_ATTACK1)
		self:SetNextPrimaryFire(CurTime()+10)

		self:GetOwner():EmitSound("snd_jack_hmcd_phone_dial.wav", 75, 100, 1, CHAN_AUTO )

		timer.Simple(.7,function()
			if IsValid(self) and IsValid(self:GetOwner()) then
				self:GetOwner():EmitSound( "snd_jack_hmcd_phone_voice.wav", 75, 100, 1, CHAN_AUTO )
			end
		end)
		timer.Simple(2,function()
			if IsValid(self:GetOwner()) and self:GetOwner():Alive() then
				if self:GetOwner().roleT then
					self:GetOwner():ChatPrint("Ты притворяешься, что вызываешь полицию.")
				else
					roundTime = math.max(roundTime * 0.6, 0)

					if roundTime > 60 then
						self:GetOwner():ChatPrint("Помощь приедет через "..math.ceil(roundTime/60).." минут.")
					else
						self:GetOwner():ChatPrint("Помощь приедет через "..math.ceil(roundTime).." секунд.")
					end
				end
			end
		end)
		timer.Simple(4,function()
			if IsValid(self) then
				for k,ply in pairs(PlayersInGame())do
					if ply.roleT then
						ply:ChatPrint("Кто-то вызвал полицию!")
					end
				end
				self:Remove()
			end
		end)
	end

    function SWEP:SecondaryAttack()
    end

	function SWEP:Think()
	end

elseif CLIENT then
    function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
        if !IsValid(DrawModel) then
            DrawModel = ClientsideModel( self.WorldModel, RENDER_GROUP_OPAQUE_ENTITY );
            DrawModel:SetNoDraw( true );
        else
            DrawModel:SetModel( self.WorldModel )

            local vec = Vector(55,55,55)
            local ang = Vector(-48,-48,-48):Angle()

            cam.Start3D( vec, ang, 20, x, y+35, wide, tall, 5, 4096 )
                cam.IgnoreZ( true )
                render.SuppressEngineLighting( true )

                render.SetLightingOrigin( self:GetPos() )
                render.ResetModelLighting( 50/255, 50/255, 50/255 )
                render.SetColorModulation( 1, 1, 1 )
                render.SetBlend( 255 )

                render.SetModelLighting( 4, 1, 1, 1 )

                DrawModel:SetRenderAngles( Angle( 0, RealTime() * 30 % 360, 0 ) )
                DrawModel:DrawModel()
				DrawModel:SetSkin(2)
                DrawModel:SetRenderAngles()

                render.SetColorModulation( 1, 1, 1 )
                render.SetBlend( 1 )
                render.SuppressEngineLighting( false )
                cam.IgnoreZ( false )
            cam.End3D()
        end

        self:PrintWeaponInfo( x + wide + 20, y + tall * 0.95, alpha )
    end

	function SWEP:Initialize()
	end

	function SWEP:Draw()
	end
end