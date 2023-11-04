local value,gg

if CLIENT then
	value = 1

	net.Receive("info_staminamul",function()
		value = net.ReadFloat()
	end)

    --[[local startTime = CurTime() -- время начала изменения
    local endTime = startTime + transitionTime -- время окончания изменения

    hook.Add("Think", "SmoothSensitivity", function()
        local t = (CurTime() - startTime) / (endTime - startTime) -- текущий прогресс изменения (от 0 до 1)
        t = math.Clamp(t, 0, 1) -- ограничиваем прогресс от 0 до 1

        local newSensitivity = Lerp(t, currentSensitivity, targetSensitivity) -- интерполируем значение чувствительности

        input.SetMouseSensitivity(newSensitivity) -- устанавливаем новое значение чувствительности мыши

        if t >= 1 then
            hook.Remove("Think", "SmoothSensitivity") -- удаляем хук, когда изменение завершено
        end
    end)]]

	hook.Add("AdjustMouseSensitivity", "CoolStamina",function()
        local ply = LocalPlayer()

        if ply:Alive() then
            local mul = 1

            mul = mul * math.Clamp( ( (blood * .5 + 50) / 100 ), .01, 1)

            if not IsValid(ply:GetNWEntity("Ragdoll")) and ply:GetMoveType() == MOVETYPE_WALK and ply:IsSprinting() and ply:GetVelocity():Length2DSqr() > 1 then
                return mul * 0.2 
            end

            if ply:GetNWInt("stamina") <= 60 then
                return mul * 0.3
            end

            if ply:GetActiveWeapon():GetNWBool("IsScope") then
                return mul * 0.7
            end
            
            return mul
        end

        return 1
    end)
end

local jmod
if CLIENT then
	hook.Add("Move","homigrad",function(ply,mv)
		gg(ply,mv,value)
	end)
else
	hook.Add("Move","homigrad",function(ply,mv)
		gg(ply,mv,(ply.staminamul or 1))
	end)
end


gg = function(ply,mv,value)
    value = mv:GetMaxSpeed() * value

    ply:SetWalkSpeed(Lerp((mv:GetForwardSpeed() > 1) and 0.03 or 1,ply:GetWalkSpeed(),(mv:GetForwardSpeed() > 1) and 200 or ply:GetSlowWalkSpeed()))
    ply:SetRunSpeed(Lerp((ply:IsSprinting() and mv:GetForwardSpeed() > 1) and 0.03 or 1,ply:GetRunSpeed(),(ply:IsSprinting() and mv:GetForwardSpeed() > 1) and 450 or ply:GetWalkSpeed()))

    mv:SetMaxSpeed(value)
    mv:SetMaxClientSpeed(value)

    local value = ply.EZarmor
    value = value and ply.EZarmor.speedfrac

    if value and value ~= 1 then
        value = mv:GetMaxSpeed() * math.max(value,0.75)
        mv:SetMaxSpeed(value)
        mv:SetMaxClientSpeed(value)
    end
end

hook.Remove("Move","JMOD_ARMOR_MOVE")