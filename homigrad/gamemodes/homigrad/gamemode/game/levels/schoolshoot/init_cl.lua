schoolshoot.GetTeamName = tdm.GetTeamName

local colorSpec = ScoreboardSpec
function schoolshoot.Scoreboard_Status(ply)
	local lply = LocalPlayer()
	if not lply:Alive() or lply:Team() == 1002 then return true end

	return "Неизвестно",colorSpec
end

local green = Color(0,125,0)
local white = Color(255,255,255)

local roundSound = "https://cdn.discordapp.com/attachments/1019645092614635550/1167050008110039060/Forster_The_People_-_Pumped_up_Kick.mp3?ex=654cb704&is=653a4204&hm=a6a65b1e6d79b459cbb480d24792b6c41a8d2babd31cca786264fa7da33e6ddb&"

local playsound = false
function schoolshoot.StartRoundCL()
    playsound = true
end

function schoolshoot.HUDPaint_RoundLeft(white2,time)
	local time = math.Round(roundTimeStart + roundTime - CurTime())
	local acurcetime = string.FormattedTime(time,"%02i:%02i")
	local lply = LocalPlayer()
	local name,color = schoolshoot.GetTeamName(lply)

	local startRound = roundTimeStart + 7 - CurTime()
    if startRound > 0 and lply:Alive() then
        if playsound then
            playsound = false
            sound.PlayURL(roundSound,"mono noblock",function(snd) 
                snd:SetVolume( 0.3 )
            end)
        end
        lply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),0.5,0.5)

        draw.DrawText( "Вы " .. name, "HomigradFontBig", ScrW() / 2, ScrH() / 2, Color( color.r,color.g,color.b,math.Clamp(startRound - 0.5,0,1) * 255 ), TEXT_ALIGN_CENTER )
        draw.DrawText( "Активный стрелок", "HomigradFontBig", ScrW() / 2, ScrH() / 8, Color( 155,55,55,math.Clamp(startRound - 0.5,0,1) * 255 ), TEXT_ALIGN_CENTER )

        if lply:Team() == 1 then
            draw.DrawText( "Ваша задача убить всех до прибытия Спецназа", "HomigradFontBig", ScrW() / 2, ScrH() / 1.2, Color( 155,55,55,math.Clamp(startRound - 0.5,0,1) * 255 ), TEXT_ALIGN_CENTER )
        else
            draw.DrawText( "В здании активный стрелок, вам нужно выжить и сбежать по приезду Спецназа", "HomigradFontBig", ScrW() / 2, ScrH() / 1.2, Color( 55,155,55,math.Clamp(startRound - 0.5,0,1) * 255 ), TEXT_ALIGN_CENTER )
		end
        return
    end

	if time > 0 then
		draw.SimpleText("До прибытия полиции : ","HomigradFont",ScrW() / 2 - 200,ScrH()-25,white,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
		draw.SimpleText(acurcetime,"HomigradFont",ScrW() / 2 + 200,ScrH()-25,white,TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
	end
	green.a = white2.a


	if lply:Team() == 3 or lply:Team() == 2 or not lply:Alive() and schoolshoot.police then
		local list = SpawnPointsList.spawnpoints_ss_exit
		--local list = ReadDataMap("spawnpoints_ss_exit")
		if list then
			for i,point in pairs(list[3]) do
				point = ReadPoint(point)
				local pos = point[1]:ToScreen()
				draw.SimpleText("EXIT","ChatFont",pos.x,pos.y,green,TEXT_ALIGN_CENTER)
			end

			draw.SimpleText("Нажми TAB чтобы снова увидеть это.","HomigradFont",ScrW() / 2,ScrH() - 100,white2,TEXT_ALIGN_CENTER)
		else
			draw.SimpleText("Попроси админа поставить эвакуационные точки для школьников...","HomigradFont",ScrW() / 2,ScrH() - 100,white2,TEXT_ALIGN_CENTER)
		end
	end
end

function schoolshoot.PlayerClientSpawn()
	if LocalPlayer():Team() ~= 3 then return end

	showRoundInfo = CurTime() + 10
end