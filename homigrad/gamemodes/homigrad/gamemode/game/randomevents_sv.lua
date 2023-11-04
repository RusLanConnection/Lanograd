local PlayerMeta = FindMetaTable("Player")

function PlayerMeta:InvoluntaryEvent()
	if self.roleT and roundActiveName == "homicide" then return end

    local Ma 
    local Fe

	local MaSound = {
		"snd_jack_hmcd_cough_male.wav",
		"snd_jack_hmcd_sneeze_male.wav",
		"snd_jack_hmcd_burp.wav",
		"snd_jack_hmcd_fart.wav"
	}

	local FeSound = {
		"snd_jack_hmcd_cough_female.wav",
		"snd_jack_hmcd_sneeze_female.wav",
		"snd_jack_hmcd_burp.wav",
		"snd_jack_hmcd_fart.wav"
	}

	Fe = string.find(self:GetModel(), "female") and true or false

	if Fe then
		self:EmitSound(table.Random(FeSound),75,100)
	else
		self:EmitSound(table.Random(MaSound),75,100)
	end

end

hook.Add( "PlayerSpawn", "RandomIvent", function(ply)
	if not timer.Exists(ply:EntIndex() .. " RandomIvent") then
		timer.Create(ply:EntIndex() .. " RandomIvent", 5, 0, function()
			if not IsValid(ply) or ply:GetNWEntity("HeSpectateOn",true) then 
				timer.Remove(ply:EntIndex() .. " RandomIvent")
				return 
			end

			local random = math.random(1, 100)

			if random <= 5 then
				ply:InvoluntaryEvent()
			end
		end)
	end
end)