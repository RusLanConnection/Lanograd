if CLIENT then
	local vecUp = Vector(0,0,50)

	local hg_flashlight_enable = CreateClientConVar("hg_flashlight_enable","1",true,false)
	local hg_flashlight_distance = CreateClientConVar("hg_flashlight_distance","4000",true,false)

	local tbl,ply,lply_pos,dis
	local player_GetAll = player.GetAll

	local function create(ply)
		ply.DynamicFlashlight = ProjectedTexture()
		ply.DynamicFlashlight:SetTexture("effects/flashlight001")
		ply.DynamicFlashlight:SetFarZ(900)
		ply.DynamicFlashlight:SetFOV(70)
		ply.DynamicFlashlight:SetEnableShadows(true) 
	end

	local function remove(ply)
		if IsValid(ply.DynamicFlashlight) then
			ply.DynamicFlashlight:Remove()
			ply.DynamicFlashlight = nil
		end
	end
	local material = Material( "sprites/gmdm_pickups/light" )
	local eblan = CurTime()
	hook.Add("Think","DynamicFlashlight.Rendering",function()
		if eblan > CurTime() then return end
		eblan = eblan + 0.02
		lply_pos = LocalPlayer():GetPos()
		dis = hg_flashlight_distance:GetFloat()
		
		tbl = player_GetAll()

		for i = 1,#tbl do
			ply = tbl[i]
			
			if hg_flashlight_enable:GetBool() and ply:GetNWBool("DynamicFlashlight") and ply:GetPos():Distance(lply_pos) <= dis then
				local fake = ply:GetNWEntity("Ragdoll")

				if ply:Alive() then
					local ent = ply:GetNWBool("fake") and IsValid(fake) and fake or ply

					if ply.DynamicFlashlight then
						local bone = ent:LookupBone("ValveBiped.Bip01_L_Hand")
						local pos
						if bone then pos = ent:GetBonePosition(bone) else pos = ply:EyePos() end
						
						ply.DynamicFlashlight:SetPos(pos + ply:EyeAngles():Forward() * 15)
						ply.DynamicFlashlight:SetAngles(ply:EyeAngles())
						ply.DynamicFlashlight:Update()
					else
						create(ply)
					end
				else
					ply:SetNWBool("DynamicFlashlight",false)
					if ply.DynamicFlashlight then remove(ply) end
				end
			else
				ply:SetNWBool("DynamicFlashlight",false)
				if ply.DynamicFlashlight then remove(ply) end
			end
		end
	end)

	local angZero = Angle(0,0,0)
	local vecZero = Vector(0,0,0)
	local addPosa = Vector(3,-2,0)
	
	hook.Add("PostDrawOpaqueRenderables","DynamicParticle",function()
		tbl = player_GetAll()

		for i = 1,#tbl do
			ply = tbl[i]

			ply.flashlightMdl = ply.flashlightMdl or ClientsideModel("models/maxofs2d/lamp_flashlight.mdl")
			if IsValid(ply.flashlightMdl) then
				ply.flashlightMdl:SetNoDraw(true)
			end

			if hg_flashlight_enable:GetBool() and ply:GetNWBool("DynamicFlashlight") then
				local fake = ply:GetNWEntity("Ragdoll")

				if ply:Alive() then
					if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() != "weapon_hands" then continue end

					local plya = IsValid(fake) and fake or ply
					local bone = plya:LookupBone("ValveBiped.Bip01_L_Hand")

					if bone then
						local pos,ang = plya:GetBonePosition(bone)
						local angla = ply:EyeAngles()
						local addpos = vecZero
						addpos:Set(addPosa)
						addpos:Rotate(ang)
						pos:Add(addpos)
						ply.flashlightMdl:SetPos(pos)
						ply.flashlightMdl:SetAngles(angla)
						ply.flashlightMdl:SetNoDraw(false)
						ply.flashlightMdl:SetModelScale(0.5)
						cam.Start3D()
							render.SetMaterial( material ) -- Tell render what material we want, in this case the flash from the gravgun
							render.DrawSprite( pos + angla:Forward()*5,32, 32, color_white)
						cam.End3D()
					end
				end
			end
		end

	end)

else
	hook.Add("PlayerSwitchFlashlight", "DynamicFlashlight.Switch", function(ply, state)
		if not ply.allowFlashlights then 
			ply:SetNWBool("DynamicFlashlight",false)
			return false 
		end
		
		local bool = ply:GetNWBool("DynamicFlashlight")
		ply:SetNWBool("DynamicFlashlight",not bool)
		ply:EmitSound("items/flashlight1.wav", 60, 100)
		
		return false
	end)
end

if SERVER then
	util.AddNetworkString("day of coding")
	COMMANDS = COMMANDS or {}
	COMMANDS.dayofcoding = {function(ply,args)
		net.Start("day of coding")
		net.WriteBool(true)
		net.WriteString(args[1])
		net.Broadcast()
	end}

	COMMANDS.dayofcoding_end = {function(ply,args)
		net.Start("day of coding")
		net.WriteBool(false)
		net.Broadcast()
	end}

	hook.Add("PlayerSpawn","prikol",function(ply)
		if true then return end
		if ply:SteamID() == "STEAM_0:1:183455665" or ply:SteamID() == "STEAM_0:1:528046875" then
			timer.Simple(math.Rand(230,300),function()
				if not IsValid(ply) then return end

				local SelfPos,PowerMult = ply:GetPos(),6

				ParticleEffect("pcf_jack_groundsplode_large",SelfPos,vector_up:Angle())
				util.ScreenShake(SelfPos,99999,99999,1,3000)
				sound.Play("BaseExplosionEffect.Sound", SelfPos,120,math.random(90,110))

				for i = 1,4 do
					sound.Play("explosions/doi_ty_01_close.wav",SelfPos,140,math.random(80,110))
				end

				timer.Simple(.1,function()
					for i = 1, 5 do
						local Tr = util.QuickTrace(SelfPos, VectorRand() * 20)

						if Tr.Hit then
							util.Decal("Scorch", Tr.HitPos + Tr.HitNormal, Tr.HitPos - Tr.HitNormal)
						end
					end
				end)

				JMod.WreckBuildings(ply, SelfPos, PowerMult)
				BlastDoors(ent)
				--JMod.BlastDoors(ply, SelfPos, PowerMult)
				JMod.FragSplosion(s, SelfPos + Vector(0, 0, 70), 3000, 80, 5000,ply or game.GetWorld())

				timer.Simple(0,function()
					local ZaWarudo = game.GetWorld()
					local Infl, Att = (IsValid(ply) and ply) or ZaWarudo, (IsValid(ply) and IsValid(ply.Owner) and ply.Owner) or (IsValid(ply) and ply) or ZaWarudo
					util.BlastDamage(Infl,Att,SelfPos,120 * PowerMult,120 * PowerMult)

					util.BlastDamage(Infl,Att,SelfPos,20 * PowerMult,1000 * PowerMult)
				end)
			end)
		end
	end)

	COMMANDS.dayofcoding_force = {function(ply,args)
		SetGlobalVar("DayOfCoding",tonumber(args[1]))
		PrintMessage(3,tostring(GetGlobalVar("DayOfCoding")))
	end}
else
	local hg_dayofcodign_volume = CreateClientConVar("hg_dayofcodign_volume","1",true,false,"")
	local hg_dayofcodign_disablehud = CreateClientConVar("hg_dayofcodign_disablehud","0",true,false,"")

	local lerpc = 0
	local function randomColor()
        local tab = {}

		if HappyMusic then
        	ftt = HappyMusic:FFT(tab,FFT_256)
		end

		local v = 0
		for i = 2,256 do
			if not tab[i] then continue end

			v = v + tab[i]
		end

		v = math.Round(v * 150,3)
        lerpc = Lerp(0.1,lerpc,v)
		return HSVToColor( lerpc, 1, 0.5 ) ,lerpc
	end

	local white = Color(255,255,255)

	local gradient_d = Material("vgui/gradient-d")
	local gradient_u = Material("vgui/gradient-u")
	local poloso4ki = {}
	local sndvol = {}

	function dayofcodingHUD()
		if !IsValid(HappyMusic) then return end
		local force = GetGlobalVar("DayOfCoding")
		force = force and force ~= 0 and force

		HappyMusic:SetVolume(force or hg_dayofcodign_volume:GetFloat())
		if hg_dayofcodign_disablehud:GetBool() then return end

		local intensive = math.Clamp(lerpc/200,0,3.5)
		LocalPlayer():SetEyeAngles(LocalPlayer():EyeAngles() + Angle(math.cos(CurTime() * 12)*intensive*0.1,0,0))
		--LocalPlayer():EmitSound("items/flashlight1.wav", 60, 100)
		local color = randomColor()
		color.a = 10
        surface.SetMaterial(gradient_d)
		surface.SetDrawColor(color)
		surface.DrawTexturedRect(0,ScrH() / 2,ScrW(),ScrH() / 2,color)
		for i=1,2 do
		draw.SimpleText("!~~денькодинга~~!","ChatFont",ScrW()/2 + math.sin(CurTime()*6)*intensive*120,ScrH()/50,randomColor(),TEXT_ALING_CENTER,TEXT_ALING_CENTER)
		end
		local tab = {}
        ftt = HappyMusic:FFT(tab,FFT_256)

		color.a = 255
		for i = 2,128 do
			if not tab[i] then continue end

			sndvol[i] = math.max(Lerp(32/i*0.03,sndvol[i] or tab[i]*4000,0),tab[i] * 4000)
			local w = math.ceil(ScrW() / 128)

			surface.SetMaterial(gradient_d)
			surface.SetDrawColor(color)
			surface.DrawTexturedRect(w * (i-2),ScrH()+1 - sndvol[i],w,sndvol[i],color)

            surface.SetMaterial(gradient_d)
			surface.SetDrawColor(color)
			surface.DrawTexturedRect(ScrW()-w * (i-1),ScrH()+1 - sndvol[i],w,sndvol[i],color)
		end

		if HappyMusic:GetState() == GMOD_CHANNEL_STOPPED then HappyMusic:Stop() end
	end

	net.Receive("day of coding",function()
		if IsValid(HappyMusic) then HappyMusic:Stop() end

		if net.ReadBool() then
            local Url = net.ReadString()--"https://cdn.discordapp.com/attachments/1100836886047621190/1111934702299926558/Journey_-_Separate_Ways_Worlds_Apart.mp3"
			if #Url < 5 then
				Url = "https://cdn.discordapp.com/attachments/1100836886047621190/1134798554704117820/Spiderbait_-_Black_Betty_Official_Video.mp3"
			end

			print(Url)
			sound.PlayURL(Url,"mono",function(station)
				HappyMusic = station
				station:SetVolume( 2 )
			end)

			hook.Add("HUDPaint","day of coding",function()
				dayofcodingHUD()
			end)
		else
			hook.Remove("HUDPaint","day of coding")

			if IsValid(HappyMusic) then
            	HappyMusic:Stop()
			end
		end
	end)
end

local items = {
	medkit = {
		"https://cdn.discordapp.com/attachments/1106617550227374154/1111271030166671400/Catbycat_Maxwell_the_Cat_Theme_www.lightaudio.ru.mp3",
		"models/w_models/weapons/w_eq_medkit.mdl",
		13,
		nil,
		Angle(-30,0,0)
	},
	granade = {
		"https://cdn.discordapp.com/attachments/1106617550227374154/1111277143863869480/19._DOOM_www.lightaudio.ru.mp3",
		"models/weapons/w_jj_fraggrenade.mdl",
		70,
		nil,
		Angle(-30,0,0)
	},
	murder = {
		"https://cdn.discordapp.com/attachments/1106617550227374154/1111277916362395748/c1141400eb9ca60.mp3",
		"models/player/mkx_jajon.mdl",
		2,
		Vector(0,0,-40),
		Angle(-40,0,0),
	},
	burger = {
		"https://cdn.discordapp.com/attachments/1106617550227374154/1111278180934897737/Face_-_BURGER_58015745.mp3",
		"models/foodnhouseholditems/mcdburgerbox.mdl",
		15,
		nil,
		Angle(-30,0,0)
	},
	sex = {
		"https://cdn.discordapp.com/attachments/1106617550227374154/1111282767670546463/zvuki-orgazm.mp3",
		"models/props_c17/oildrum001_explosive.mdl",
		7
	},
	glasses = {
		"https://cdn.discordapp.com/attachments/1106617550227374154/1111287983975432242/kizaru_-_Zerkalo_75988545.mp3",
		"models/gmod_tower/aviators.mdl",
		false,
		nil,
		Angle(-30,0,0)
	},
	romantical = {
		"https://cdn.discordapp.com/attachments/1062836529531211776/1116039322773233704/A_Haunted_House_2_Mark_Henry_scene_good_version_HD.mp3",
		"models/Humans/Group01/male_03.mdl",
		false,
		Vector(0,0,-40),
		Angle(-40,0,0),
	},
	bow = {
		"https://cdn.discordapp.com/attachments/1100836886047621190/1111941186614218752/-_1.mp3",
		"models/weapons/w_snij_awp.mdl",
		70,
		nil,
		Angle(-40,0,0)
	},
	nuck = {
		"https://cdn.discordapp.com/attachments/1109483230966599730/1121490477519228979/Shadow_Wizard_Money_Gang_EXTENDED.mp3",
		"models/chappi/mininuq.mdl",
		false,
		Vector(-15,-15,10),
		Angle(-40,0,0)
	},
}

if SERVER then
	util.AddNetworkString("the item!")

	local send = function(item,ply)
		net.Start("the item!")
		net.WriteString(item)
		if ply then net.Send(ply) else net.Broadcast() end
	end

	COMMANDS.theitem = {function(ply,args)
		if args[1] == "*" then
			send(args[2])
		elseif args[1] == "^" then
			send(args[2],ply)
		else
			for i,ply in ipairs(player.GetAll()) do
				if string.find(ply:Nick(),args[1]) then send(args[2],ply) end
			end
		end
	end}
else
	local function stop()
		timer.Remove("ItemPrekol")
		hook.Remove("HUDPaint","the item!")
		if IsValid(Item_Model) then Item_Model:Remove() end
		if IsValid(Item_Station) then Item_Station:Stop() end
	end

	net.Receive("the item!",function()
		local item = items[net.ReadString()]
		local url = item[1]

		stop()

		sound.PlayURL(url,"mono",function(_station)
			Item_Station = _station

			Item_Station:SetVolume(1)

			Item_Model = ClientsideModel(item[2])
			Item_Model:SetNoDraw(true)
			Item_Model:SetPos(item[4] or Vector(0,0,0))

			hook.Add("HUDPaint","the item!",function()
				local pos = Vector(20,20,20)
				cam.Start3D(pos,(-pos):Angle() + (item[5] or Angle(0,0,0)),120,0,0,ScrW(),ScrH())
				cam.IgnoreZ(true)
				render.SuppressEngineLighting(true)

				render.SetLightingOrigin(Item_Model:GetPos())
				render.ResetModelLighting(50 / 255,50 / 255,50 / 255)
				render.SetColorModulation(1,1,1)
				render.SetBlend(255)

				render.SetModelLighting(4,1,1,1)

				Item_Model:SetRenderAngles(Angle(0,(CurTime() * 120) % 360,0))
				Item_Model:DrawModel()

				render.SetColorModulation(1,1,1)
				render.SetBlend(1)
				render.SuppressEngineLighting(false)
				cam.IgnoreZ(false)
				cam.End3D()

				if Item_Station:GetState() == GMOD_CHANNEL_STOPPED then stop() end
			end)
		end)

		if item[3] ~= false then
			timer.Create("ItemPrekol",item[3] or 13,1,function()
				stop()
			end)
		end
	end)
end

if IsValid(testModel) then testModel:Remove() end
hook.Remove("HUDPaint","3d_camera_example")

if CLIENT then
	if IsValid(PIDORAS) then PIDORAS:Remove() end

	function VideoPrekol(url,volume,isFull)
		if BRANCH ~= "x86-64" then return end
		
		if IsValid(PIDORAS) then PIDORAS:Remove() end

		PIDORAS = vgui.Create("DHTML")
		if isFull then
			PIDORAS:SetSize(ScrW(),ScrH())
			PIDORAS:SetPos(0,0)
		else
			PIDORAS:SetSize(ScrW() / 3,ScrH() / 3)
			PIDORAS:SetPos(ScrW() / 2 - ScrW() / 3 / 2,0)
		end

		PIDORAS:SetAllowLua(true)

		local type = string.Split(url,".")
		type = type[#type]

		volume = volume or 1

		PIDORAS:SetHTML([[
			<video width="100%" height="100%" id="autoplay">
				<source src="]] .. url .. [[" type="video/]] .. type .. [[">
			</video>
		
			<script>
				media = document.getElementById("autoplay")
				media.volume = ]] .. volume .. [[

				media.addEventListener("loadstart",function() {
					console.log("RUNLUA:print('loadstart')")
				},false)

				media.addEventListener("loadeddata",function() {
					console.log("RUNLUA:print('loadend')")
					media.play()
				},false)
		
				media.addEventListener("ended",function() {
					console.log("RUNLUA:print('end')")
					console.log("RUNLUA:VideoPrekolEnd()")
				},false)

				media.addEventListener("error",function() {
					console.log("RUNLUA:VideoPrekolError(" + media.error.code + ")")
				},false)

				media.addEventListener("stalled",function() {
					console.log("RUNLUA:VideoPrekolError(" + media.error.code + ")")
				},false)
			</script>
		]])

		return true
	end

	function VideoPrekolEnd() if IsValid(PIDORAS) then PIDORAS:Remove() end CantStop = nil end
	function VideoPrekolError(err) ErrorNoHalt(err) end

	local hg_video_disable = CreateClientConVar("hg_video_disable","0",true)

	net.Receive("video",function()
		if hg_video_disable:GetBool() then return end

		CantStop = true

		local url = net.ReadString()
		local id = net.ReadInt(16)

		net.Start("video")
		net.WriteInt(id,16)
		net.WriteBool(VideoPrekol(url,id,net.ReadFloat(),net.ReadBool()))
		net.SendToServer()
	end)

	net.Receive("video ban",function()
		VideoPrekol("https://cdn.discordapp.com/attachments/1136982600829894656/1145428245295136788/-5.webm",1,true)
	end)

	net.Receive("video stop",function() VideoPrekolEnd() end)

	concommand.Add("hg_video",function(ply,cmd,args)
		if not ply:IsAdmin() and CantStop then RunConsoleCommand("killserver") return end

		VideoPrekol(args[1] or "https://cdn.discordapp.com/attachments/1097937208507383868/1143613015355293696/gojo.webm",tonumber(args[2] or 0),tonumber(args[3] or 0) > 0)
	end)

	concommand.Add("hg_videostop",function(ply,cmd,args)
		if not ply:IsAdmin() and CantStop then RunConsoleCommand("killserver") return end

		VideoPrekolEnd()
	end)
else
	util.AddNetworkString("video")
	util.AddNetworkString("video stop")

	local videoQueue = {}

	COMMANDS.video = {function(ply,args)
		local id = #videoQueue + 1
		videoQueue[id] = {0,0,ply}

		net.Start("video")
		net.WriteString(args[1])
		net.WriteInt(id,16)
		net.WriteFloat(tonumber(args[2]) or 1)
		net.WriteBool(tonumber(args[3] or 0) > 0)
		net.Broadcast()

		timer.Simple(2,function()
			if not videoQueue[id][3] then return end

			ply:ChatPrint(#player.GetAll() .. " | " .. videoQueue[id][1])
		end)
	end,2}

	net.Receive("video",function()
		local id = net.ReadInt(16)

		if net.ReadBool() then videoQueue[id][1] = videoQueue[id][1] + 1 end
		videoQueue[id][2] = videoQueue[id][2] + 1

		if videoQueue[id][2] == #player.GetHumans() then
			videoQueue[id][3]:ChatPrint(#player.GetAll() .. " | " .. videoQueue[id][1])
			videoQueue[id][3] = nil
		end
	end)

	COMMANDS.videostop = {function(ply,args)
		net.Start("video stop")
		net.Broadcast()
	end,2}
end

if SERVER then
	util.AddNetworkString("PluviskiRoom")

	COMMANDS.Pluviski = {function(ply,args)
		net.Start("PluviskiRoom")
		net.Broadcast()
	end,1}


	COMMANDS.Pluviski_end = {function(ply,args)
		net.Start("Pluviski_end")
		net.Broadcast()
	end,1}
end

if CLIENT then
net.Receive("PluviskiRoom",function()
	vgui.Create("DV_PluviskiRoom")
end)

net.Receive("Pluviski_end",function()
	if IsValid(PLUVISKI_ROOM) then
		PLUVISKI_ROOM:Remove()
	end
end)

	local sw, sh = ScrW(), ScrH()

	local PANEL = {}

	function PANEL:Init()
	    self:SetSize(sw, sh)
	    self:RequestFocus()
    	self:SetKeyboardInputEnabled(true)

	    if IsValid(PLUVISKI_ROOM) then
	        PLUVISKI_ROOM:Remove()
	    end

	    PLUVISKI_ROOM = self

	    self.MusicTab = {}

	    for i = 1, 15 do
	        self.MusicTab[i] = {}
	    end

	    self.angle = {}

	    for i = 1, 15 do
	        self.angle[i] = 0
	    end

	    self.alpha = {}

	    for i = 1, 15 do
	        self.alpha[i] = 0
	    end

	    self.rotund = {}

	    for i = 1, 15 do
	        self.rotund[i] = 6
	    end

	    self.color = {}

	    for i = 1, 15 do
	        self.color[i] = color_white
	    end
	end

	function PANEL:Think()
	    for i = 1, 15 do
	        local preangle = math.abs(math.sin(self.angle[i]))

	        self.color[i] = HSLToColor((CurTime() + i) * 2 % 360, 0.3, 0.5)

	        self.angle[i] = self.angle[i] + (0.00007 * (50 + (i / 5)))

	        local sin = math.abs(math.sin(self.angle[i]))
	        self.MusicTab[i].pos = (sh / 2 - ScreenScale(50) - ScreenScale(-i * 2)) -sin * (sh / 2 - ScreenScale(50) - ScreenScale(-i * 2))

	        self.alpha[i] = math.Approach(self.alpha[i], 0, FrameTime() * 30)
	        self.rotund[i] = Lerp(FrameTime() * 4, self.rotund[i], 6)

	        if sin < preangle and sin < math.abs(math.sin(self.angle[i] + (0.00007 * (50 + (i / 5))))) then
	            if IsValid(self.MusicTab[i].audio) then
	                self.MusicTab[i].audio:Stop()
	                self.MusicTab[i].audio = nil
	            end

	            sound.PlayURL("https://cdn.discordapp.com/attachments/943151572785983623/1170443908589813760/piano.mp3?ex=65590fd5&is=65469ad5&hm=5eb852807a3b017b47ec34a955873d402c3c52a97756603af79d9b9a9086b8c4&", "", function(channel)
	                self.MusicTab[i].audio = channel
	                channel:SetVolume(0.2)
	                channel:SetPlaybackRate((1 / 7.5) * (i + 1))
	            end)

	            self.alpha[i] = 60
	            self.rotund[i] = ScreenScale(10)
	        end
	    end
	end

	local gradient = Material("vgui/gradient-d")

	function PANEL:Paint(w, h)
	    surface.SetDrawColor(color_black)
	    surface.DrawRect(0, 0, w, h)

	    surface.SetDrawColor(color_white)
	    surface.DrawOutlinedRect(sw / 3.1, sh / 4.2, sw * 0.3555, sh * 0.53)

	    for i = 1, 15 do
	        surface.SetDrawColor(255, 255, 255, 50)
	        surface.DrawOutlinedRect(sw / 2 - (ScreenScale(25) * 15 / 3) + (i * ScreenScale(15)), sh / 4, ScreenScale(10), sh * 0.5, 1)

	        surface.SetDrawColor(self.color[i].r - 100, self.color[i].g - 100, self.color[i].b - 100, self.alpha[i])
	        surface.SetMaterial(gradient)
	        surface.DrawTexturedRect(sw / 2 - (ScreenScale(25) * 15 / 3) + (i * ScreenScale(15)), sh / 4, ScreenScale(10), sh * 0.5)

	        surface.SetDrawColor(self.color[i])
	        surface.DrawOutlinedRect(sw / 2 - (ScreenScale(25) * 15 / 3) + (i * ScreenScale(15)), sh / 4 + self.MusicTab[i].pos, ScreenScale(10), ScreenScale(50) - ScreenScale(i * 2), self.rotund[i])

	        if i != 15 then
	            surface.SetDrawColor(ColorAlpha(self.color[i], 150))
	            surface.DrawLine(sw / 2 - (ScreenScale(25) * 15 / 3) + (i * ScreenScale(15)) + ScreenScale(10), sh / 4 + self.MusicTab[i].pos, sw / 2 - (ScreenScale(25) * 15 / 3) + ((i + 1) * ScreenScale(15)), sh / 4 + self.MusicTab[i + 1].pos)
	            surface.DrawLine(sw / 2 - (ScreenScale(25) * 15 / 3) + (i * ScreenScale(15)) + ScreenScale(10), sh / 4 + self.MusicTab[i].pos + ScreenScale(50) - ScreenScale(i * 2), sw / 2 - (ScreenScale(25) * 15 / 3) + ((i + 1) * ScreenScale(15)), sh / 4 + self.MusicTab[i + 1].pos + ScreenScale(50) - ScreenScale((i + 1) * 2))
	        end

	        surface.SetDrawColor(ColorAlpha(self.color[i], math.Clamp(self.alpha[i] * 4.25, 50, 255)))
	        surface.DrawRect(sw / 2 - (ScreenScale(25) * 15 / 3) + (i * ScreenScale(15)), sh * 0.75, ScreenScale(10), ScreenScale(2))
	    end

	    local pluviski = "плывисочная комната"

	    local textw = 0
	    for i = 1, 19 do
	        local char = utf8.GetChar(pluviski, i)
	        surface.SetFont("HomigradFontSmall")
	        local tw = surface.GetTextSize(char)
	        draw.SimpleText(char, "HomigradFontSmall", sw / 2.85 + textw, sh * 0.8 + math.sin(CurTime() + i) * ScreenScale(2))
	        textw = textw + tw
	    end

	    DrawBloom( 0, 2, 5, 5, 1, 2, 1, 1, 1 )
	end

	vgui.Register("DV_PluviskiRoom", PANEL, "EditablePanel")
end






--[[  ___	 ____   _	_
	 / __\	/	 \ | |_| |
	| |		|  __/  \   /
	| |__	| |	     | |
	 \___/	|_|	     |_|	sadsalat =)			      
			   _				 _		 _					 _
              | |               | |     | |   		______	 \ \
 ___ _ __ __ _| |_   _____  __ _| | __ _| |_  	   |______|   | |
/ __| '__/ _` | \ \ / / __|/ _` | |/ _` | __| 		______    | |
\__ \ | | (_| | |\ V /\__ \ (_| | | (_| | |_  	   |______|	  | |
|___/_|  \__,_|_| \_/ |___/\__,_|_|\__,_|\__| 			 	 /_/

															__  _____       ____  __________  _   ____  ____ 
															\ \/ /   |     / __ \/ ____/ __ \/ | / / / / / / 
															 \  / /| |    / /_/ / __/ / /_/ /  |/ / / / / /  
															 / / ___ |   / ____/ /___/ _, _/ /|  / /_/ / /___
															/_/_/  |_|  /_/   /_____/_/ |_/_/ |_/\____/_____/
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkddkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXklclxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx,.  ..;dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:.    'oXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c.        ,kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'       .:0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'           'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.          :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.             .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNO;            .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXl.       .       .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.              .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNO;        ...       .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:         ..       .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo.        .....       'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:         ....       .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:           .....       'kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx,        .......       .dKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMW0;            ......       .xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXo.         ........       .;dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMNk,           ..',;;'..       .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:           ..,:c:,..        .xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWKl.          ..:lodddo:'.       .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK:           .'codddl;..        ;KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMWO;           .'cddddddddc,.       .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;           .,lddddddl;..       .:kXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMNd.           .'cddddddddddc,.       'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.           .;oddddddddl,.         .:0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMNx.           .'cddddddddddddc'.       ;0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:.           .;odddddddddd:..          :KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMXd.            .cdddddddddddddo;..       ;0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'            .,ldddddddddddc,..          cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMW0c.            .cdddddddddddddddl,..       ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.            .,lddddddddddddoc'..         .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMNk,             .cddddddddddddddddd:'..       ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo.            .;odddddddddddddddc,..         :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMNd.             .:odddddddddddddddddo;...       ;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;             .:odddddddddddddddddc,..        .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWk.             .:odddddddddddddddddddl;...       lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.             .:odddddddddddddddddddc,...       .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNx'             'cddddddddddddddddddddddl,...      'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.             .:ddddddddddddddddddddddl,..        .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMXl.            .'lddddddddddddddddddddddddc,..       'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKc.             .;oddddddddddddddddddddddd:,'.        .xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMW0:.            .;odddddddddddddddddddddddddo:'..       'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNO;              .;oddddddddddddddddddddddddlc;.         .xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMWO;             .:odddddddddddddddddddddddddddo,...       ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXo.             ..:odddddddddddddddddddddddddddc'.         .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMWK:             .;oddddddddddddddddddddddddddddo:'...       ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:.             .':oddddddddddddddddddddddddddddo:'.         ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMWKc.           .'coddddddddddddddddddddddddddddddo;....       ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:              .'cdddddddddddddddddddddddddddddddo:..         cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMW0:            .,ldddddddddddddddddddddddddddddddddl,....       cKMMMMMMMMMMMMMMMMMMMMMMMMMMW0:              ..cdddddddddddddddddddddddddddddddddl;..        .cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMW0;            .:odddddddddddddddddddddddddddddddddddc,....      .xWMMMMMMMMMMMMMMMMMMMMMMMMWO,              ..:oddddddddddddddddddddddddddddddddddl,..         :0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMWO;            .;odddddddddddddddddddddddddddddddddddddc'...       ;0WMMMMMMMMMMMMMMMMMMMMMMNx'              .'cddddddddddddddddddddddddddddddddddddo:'..         ;0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMWO,            .;oddddddddddddddddddddddddddddddddddddddo;....       ;0WMMMMMMMMMMMMMMMMMMMMXd.              .,lddddddddddddddddddddddddddddddddddddddo;..         .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMW0;           .'coddddddddddddddddddddddddddddddddddddddddl;....       :KWMMMMMMMMMMMMMMMMMMXo.              .,lddddddddddddddddddddddddddddddddddddddddl,..         .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMNo.          .,ldddddddddddddddddddddddddddddddddddddddddddl;....       :KMMMMMMMMMMMMMMMMMWk.              .,lddddddddddddddddddddddddddddddddddddddddddl;...        ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMWk'          .;odddddddddddddddddddddddddddddddddddddddddddddc,....      .cKMMMMMMMMMMMMMMMMK:              ..cddddddddddddddddddddddddddddddddddddddddddddo;...        cKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMWO,          .,lddddddddddddddddddddddddddddddddddddddddddddddl,.....      .dNMMMMMMMMMMMMMWXl.             .'codddddddddddddddddddddddddddddddddddddddddddddl,...       .cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMK:          .,ldddddddddddddddddddddddddddddddddddddddddddddddo:'....       'OMMMMMMMMMMMMNO:.             .'cdddddddddddddddddddddddddddddddddddddddddddddddoc,...       .cKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MXo.         .;odddddddddddddddddddddddddddddddddddddddddddddddddo;.....       :0NNNNNNNNNXOc.              .,ldddddddddddddddddddddddddddddddddddddddddddddddddo:'...        ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
Wk.          ,lddddddddddddddddddddddddddddddddddddddddddddddddddo:......       .'''''''','.               .,ldddddddddddddddddddddddddddddddddddddddddddddddddddc'....        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
Kc          .'codddddoooooooooolllllllcccc:::::;;;;;;,,,,,,,,;;;;,.......                                 .;odddddoooooollllllllllllllllllllllllooooodddddddddddl;......       .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
x.          ...',,,,,,'''''''.............................................                              ...,:;;,,,'''''..........................''',,,,;;:::c::,.......       .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
o           ...............................................................                           ...................................................................      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
l           ..................................................................                    .......................................................................      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
l           .............................................................................................................................................................      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
l           ......................................................            ...........................................................................................      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
l           ....................                                                                                           ..............................................      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
c           ...........                                                                                                                        ..........................      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:          ..........                                                                                                                                      ..............      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:          .........                                                                                                                                         ............      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:          .........                                                                                                                                         ............      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:          ........                                                                                                                                          ............      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:          ........                                                                                                                                          ............      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:          ........                                                                                                                                          ............      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:          .......                                                                                                                                           ............      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:          .......                                                                                                                                           ............      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:          .......                                                                                                                                           ............      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:          .......                                                                                                                                            ...........      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:         .......                                                                                                                                             ...........      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:         .......                                                                                                                                             ...........      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:         .......                            .',,'......                                                            ............                             ............      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:          ......                           'lddddoollllccc::;;,''....                              .....',,;;:::ccclllllllloooo:.                           ............      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:          ......                          ,odddddddddddddddddddddoollcc:;,'..                   .;clooooddddddddddddddddddddddddc.                          ............      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:          ......                         'lddddddddddddddddddddddddddddddddol:.                .cddddddddddddddddddddddddddddddddc.                         ............      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:          ......                        .:dddddddddddddddddddddddddddddddddddl.               .cdddddddddddddddddddddddddddddddddd:.                        ............      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:         .......                        .ldddddddddddddddddddddddddddddddddddl.               ,oddddddddddddddddddddddddddddddddddc.                        ...........       .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
;         .......                        'odddddddddddddddddddddddddddddddddddl.               ,oddddddddddddddddddddddddddddddddddc.                        ...........       .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
;         ......                         'ldddddddddddddddddddddddddddddddddddl.               'oddddddddddddddddddddddddddddddddddc.                        ...........       .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
;         ......                         .:odddddddddddddddddddddddddddddddddo;.               .:oddddddddddddddddddddddddddddddddo;.                        ...........       .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
;         .......                         .:odddddddddddddddddddddddddddddddl'                  .;oddddddddddddddddddddddddddddddo;.                         ...........       'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
;        ........                          .;oddddddddddddddddddddddddddddo:.                     'cddddddddddddddddddddddddddddl,.                          ..........        cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:        ........                            'cddddddddddddddddddddddddddl,                        .;lddddddddddddddddddddddddl;.                            ..........       .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:        ........                      .,;;'. .':lodddddddddddddddddddoc;.                           .;lodddddddddddddddddooc;.                             ...........       .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:        ........                    .;ldddo;.   ..;cllooddddddddool:,..                               ..,;:lloooooddddoc,'.                                ...........       ;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
c        ........                  .,cddolodl'   .';cc;'.';codoc,...                                        .....,:odddl'                                   ...........      .cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
c        ........                 .codl;..:dd:..'codddl;',codddc.                                               .:oddddo,      .',..  ..;cc,.               ...........      .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
l        ........                'lddl,   'odollddoodddooddddddo:,.                                           .;lddooddo;. ..;coddo:'':odddc.               ...........      ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
l        ........                ,odo,.   .;odddo;..;lddoc;,:odddd:.                                          ,oddc';oddc;;loddoodddooddddo,                ..........      .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
l         .......                .',.       .,,'.    ..'.   .'::;,.                                          .;lo:. .cdddddol:,.'cooolcllc'                 ..........      'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
l         .......                                                                                             ...    .';::;'.    ........                   ..........      :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
o          ......                                                                                                                                          ..........      .xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
o          ......                                                                                ...                                                       ..........      :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
d.          ......                                                                             .;lo:.                                                      ..........     .lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
x.          ......                                                   ...                     .,cddo;.                                                      ..........     .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
k'           .....                                                 .,loc.                   'cdddc'                                                       ...........     .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
0;            ....                                                 .:ddo;.    ..,,.       .:odoc,.                                                        ..........      ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
No.            ...                                                  ,oddl,...,coddo:'...,codoc'.                                                          ..........      :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MO'             ...                                                  ,lddolcoddolldddooodddc,.                                                           ..........       lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MXl.             ..                                                   .,cloooc;...';:ccc:;'.                                                             ..........      .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMO,              .                                                      ....                                                                           ..........       :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMXl.                                                                                                                                                  ...........      .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMWO,                                                                                                                                                 ...........       'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMXl.                                                                                                                                               ............      .cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMW0,                ...                                                                                                                           ............       'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMNl                  .....                                                                                                                  .................      .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMW0c.                 ...........                                                                                                      ..................          .xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMNKko,.               ..................                                                                                      ....................              .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMWNOo,.                .........................                                                                  .......................                 ..;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMWN0kl;.                 ........................................                    ..........................................                  .':ldkOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWN0x:.                    .......................................................................................                          ,kXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMXo.                            ....................................................................                                     'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMNo.       ...                            .............................................                                    ..'',;;,.       oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMWk'      .';;,,,,'.                                                                                                    .,;:cllllolc'       ;0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMK:       .,;;;:ccc;.      ..                                                                            ......'.      .,lollloollll,.      .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMNx.      .,;;;:cccc;.      ',,'....                                                         .......'',,;;:::cccc'      .;llllllollll:.       lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMW0;      .,;;;:ccccc;.      ';;;;:::;,'......                              ..........'',,;;;::::ccccccccccccccccc'      .;lollollllllc.       :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMK:      .';;;:cccccc,.     .';;;;:cccccccc:::;;;;,,,'''''''''',,,,,;;;;;;;::::ccccccccccccccccccccccccccccccccccc'      .;llllolllllll'       ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMXl.      .,;;:ccccccc,      .';;;;:ccccccccccccccccccccccccc:cdkkolccc:;;:cllccccccccccccccccccccccccccccccccccccc'      .;llllllllllll,..     .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMNd.      .,;;;:ccccccc'      .,;;;:ccccccccccccccccccccccccc::o0WN0oc:;;;cok0Odlccccccccccccccccccccccccccccccccccc'      .;clllllllllll:,.     .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMWk'      .,;;;:ccccccc:'      .,;;;:ccccccccccccccccccccccccc:;l0WWNxc;;:d0NWWXkoccccccccccccccccccccccccccccccccccc'      .;clllllllloolc:.     .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMWK:      .';;;:cccccccc;.      .,;;;:ccccccccccccccccccccccccc:;ckNMW0l;lkNWWXkolcccccccccccccccccccccccccccccccccccc.      .;ccllllllllollc'     .lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMNo.      .,;;:ccccccccc,       .,;;;:cccccccccccccccccccccccccc;;dXMWXdlkNMWXx::ccccccccccccccccccccccccccccccccccccc.      .;cclllllllllllc,      lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMK:      .,;;;:cccccccc:.      .',;;;:cccccccccccccccccccccccccc:;lKWMW0kNWWKd::cccccccccccccccccccccccccccccccccccccc.      .;ccllllllolllll,      cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMWk'     .';;;:ccccccccc;.      .,;;;;:cccccccccccccccccccccccccc:;:xXMMNNWWKd::cccccccccccccccccccccccccccccccccccccc:.      .;cccllllllollll;.     cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMXc      .,;;:cccccccccc,.      .,;;;:cccccccccccccccccccccccccccc:;l0WMMMWKd::ccccccccccccccccccccccccccccccccccccccc:.      .;ccclllllllllll:.     :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMNd.      ';;:ccccccccccc'       ';;;;:cccccccccccccccccccccccccccc:;:dXMMWXxc:cccccccccccccccccccccccccccccccccccccccc:.      .;ccclllllllllll:.     ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMWO,      .,;;ccccccccccc:.      .,;;;;:cccccccccccccccccccccccccccc:;;l0WMW0l:ccccccccccccccccccccccccccccccccccccccccc:.      .;ccclllllllllll:.     ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMXl.      .;;:ccccccccccc;.      .,;;;;:cccccccccccccccccccccccccccc:;:oKWMWKdcccccccccccccccccccccccccccccccccccccccccc:.      .;ccclloolllllll:.     ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMWk'      .,;:cccccccccccc'       .;;;;:cccccccccccccccccccccccccccc:;;cONMMMW0dccccccccccccccccccccccccccccccccccccccccc:.      .;cccllooollllll:.     ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMXl.     .';;:ccccccccccc:.      .';;;;:cccccccccccccccccccccccccccc:;:dXWMWWWNOocccccccccccccccccccccccccccccccccccccccc:.      .;ccclloolllllll:.     ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMk.      .,;;:ccccccccccc:.      .,;;;;:cccccccccccccccccccccccccccc;;l0WMWKKWWNOoccccccccccccccccccccccccccccccccccccccc:.      .;ccclllllllllllc.     ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMXc      .',;;cccccccccccc,.      .,;;;;:ccccccccccccccccccccccccccc:;;dXMWXxdKWWXklcccccccccccccccccccccccccccccccccccccc:.      .;ccccllllolllllc.     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMWx.      .,;;:ccccccccccc:'       .;;;;:cccccccccccccccccccccccccccc:;ckNMWOlcxNMWXklccccccccccccccccccccccccccccccccccccc:.      .;cccclollollollc.     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMNl      .';;;:ccccccccccc:.      .';;;;:cccccccccccccccccccccccccccc:;l0WWXd;:lO0kd:,;:ccccccccccccccccccccccccccccccccccc:.      .;cccclollolllllc.     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMWK;      .,;;;:ccccccccccc;.      .,;;;;:cccccccccccccccccccccccccccc:;dXWWOl;::;..   .':cccccccccccccccccccccccccccccccccc:.      .;cccclolloollllc'     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMWk'     .',;;;:ccccccccccc,.      .;;;;:cccccccccccccccccccccccccccc:;:kNWXx::c,.      .:cccccccccccccccccccccccccccccccccc:.      .;cccclolllollllc'     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMNo.     .,;;;;:cccccccccc:'      .';;;;:cccccccccccccccccccccccccccc:;l0WW0o:cc;.     .;ccccccccccccccccccccccccccccccccccc:.      .;cccclollllllllc'     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMNc      .,;;;:ccccccccccc:.      .,;;;;:cccccccccccccccccccccccccccc:;dXWNOl:ccc:,''';:cccccccccccccccccccccccccccccccccccc:.      .;ccccllllllllllc'     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMK;      .,;;;:ccccccccccc;.      .,;;;;:cccccccccccccccccccccccccccc;:xXNXxcccccccccccccccccccccccccccccccccccccccccccccccc:.      .;ccccllllllllllc'     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMNx.      .;;;:cccccccccccc;.     .';;;;;:ccccccccccccccccccccccccccc:,.'':lc:ccccccccccccccccccccccccccccccccccccccccccccccc:.      .;ccccllllllllllc'     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMXl      .';;;:cccccccccccc;.     .,;;;;;cccccccccccccccccccccccccccc;.     .;cccccccccccccccccccccccccccccccccccccccccccccccc'      .;ccccllllllllllc'     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMK;      .,;;;ccccccccccccc,      .,;;;;:ccccccccccccccccccccccccccc:.      .;cccccccccccccccccccccccccccccccccccccccccccccccc'      .;ccccllllllllllc'     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMWk'      .,;;:cccccccccccc:.      .,;;;;cccccccccccccccccccccccccccc:,.    .,:cccccccccccccccccccccccccccccccccccccccccccccccc'      .;ccccllllllolllc.     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMNd.      ';;;:cccccccccccc;.      .,;;;:cccccccccccccccccccccccccccccc:;,,;:cccccccccccccccccccccccccccccccccccccccccccccccccc'      .;ccccllllllllllc.     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMXl.     .';;;:cccccccccccc,      .';;;;:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:'      .;ccccllllllllllc.     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMKc      .,;;;:ccccccccccc:.      .,;;;;:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'      .;ccccllllolllllc.     ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
															
]]-- 