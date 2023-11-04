table.insert(LevelList,"wick")
wick = wick or {}
wick.Name = "John Wick"

wick.red = {"Наемник",Color(125,125,125),
    models = tdm.models
}

wick.teamEncoder = {
    [1] = "red"
}

wick.RoundRandomDefalut = 1
wick.CanRandomNext = false

local playsound = false
if SERVER then
    util.AddNetworkString("roundType2")
else
    net.Receive("roundType2",function(len)
        playsound = true
    end)
end

function wick.StartRound(data)
    team.SetColor(1,wick.red[2])

    game.CleanUpMap(false)

    if SERVER then
        net.Start("roundType2")
        net.Broadcast()
    end

    if CLIENT then

        return
    end

    return wick.StartRoundSV()
end

if SERVER then return end

local red,blue = Color(200,0,10),Color(75,75,255)
local gray = Color(122,122,122,255)
function wick.GetTeamName(ply)
    if ply.roleT then return "John Wick",red end

    local teamID = ply:Team()
    if teamID == 1 then
        return "Наемник",ScoreboardSpec
    end
end

local black = Color(0,0,0,255)

net.Receive("homicide_roleget2",function()
    for i,ply in ipairs(player.GetAll()) do ply.roleT = nil end
    local role = net.ReadTable()

    for i,ply in pairs(role[1]) do ply.roleT = true end
end)

function wick.HUDPaint_Spectate(spec)
    local name,color = wick.GetTeamName(spec)
    draw.SimpleText(name,"HomigradFontBig",ScrW() / 2,ScrH() - 150,color,TEXT_ALIGN_CENTER)
end

function wick.Scoreboard_Status(ply)
    local lply = LocalPlayer()

    return true
    --if not lply:Alive() or lply:Team() == 1002 then return true end

    --return "Неизвестно",ScoreboardSpec
end

local red,blue = Color(200,0,10),Color(75,75,255)

local roundSound = {
    "https://cdn.discordapp.com/attachments/1019645092614635550/1161751620648964096/Le_Castle_Vania_-_John_Wick_Mode.mp3?ex=6542ab02&is=65303602&hm=914aa8ad5130b0b4f19277018a24f2332e4264dafc6b5664cb77b7852f8e78d6&",
    "https://cdn.discordapp.com/attachments/1019645092614635550/1161751693394976832/Le_Castle_Vania_-_Shots_Fired.mp3?ex=6542ab14&is=65303614&hm=2109415aefdaff4e8d91fe6e2462c64580258c53fa5ea891f9e3225fd7b36b09&",
}


function wick.HUDPaint_RoundLeft(white2)
    local lply = LocalPlayer()
    local name,color = wick.GetTeamName(lply)

    local startRound = roundTimeStart + 7 - CurTime()
    if startRound > 0 and lply:Alive() then
        if playsound then
            playsound = false
            sound.PlayURL(table.Random(roundSound),"mono noblock",function(snd) 
                snd:SetVolume( 0.8 )
            end)
        end
        lply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),3,0.5)

        draw.DrawText( "Вы " .. name, "HomigradFontBig", ScrW() / 2, ScrH() / 2, Color( color.r,color.g,color.b,math.Clamp(startRound - 0.5,0,1) * 255 ), TEXT_ALIGN_CENTER )
        draw.DrawText( "John Wick", "HomigradFontBig", ScrW() / 2, ScrH() / 8, Color( 55,55,155,math.Clamp(startRound - 0.5,0,1) * 255 ), TEXT_ALIGN_CENTER )

        if lply.roleT then
            draw.DrawText( "Вы - Джон Уик, разберитесь со всеми наемниками.", "HomigradFontBig", ScrW() / 2, ScrH() / 1.2, Color( 155,55,55,math.Clamp(startRound - 0.5,0,1) * 255 ), TEXT_ALIGN_CENTER )
        else
            draw.DrawText( "Нейтрализуйте Джона Уика", "HomigradFontBig", ScrW() / 2, ScrH() / 1.2, Color( 55,55,55,math.Clamp(startRound - 0.5,0,1) * 255 ), TEXT_ALIGN_CENTER )
        end
        return
    end

    local lply_pos = lply:GetPos()


    for i,ply in ipairs(player.GetAll()) do
        local color = ply.roleT and red
        if not color or ply == lply or not ply:Alive() then continue end

        local pos = ply:GetPos() + ply:OBBCenter()
        local dis = lply_pos:Distance(pos)
        if dis < 500 then continue end

        local pos = pos:ToScreen()
        if not pos.visible then continue end

        color.a = 255 * (dis / 2500)

        draw.SimpleText(ply.roleT and "Джон Уик" or "","HomigradFont",pos.x,pos.y,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
    
    --[[for i,ply in ipairs(player.GetAll()) do
        local color = ply.roleT and red
        if not color or ply == lply or not ply:Alive() then continue end

        local pos = ply:GetPos() + ply:OBBCenter()
        local dis = lply_pos:Distance(pos)
        if dis > 500 then continue end

        local pos = pos:ToScreen()
        if not pos.visible then continue end

        color.a = 255 * (0 - dis / 2500)

        draw.SimpleText(ply.roleT and "Джон Уик" or "","HomigradFont",pos.x,pos.y,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end]]
end
