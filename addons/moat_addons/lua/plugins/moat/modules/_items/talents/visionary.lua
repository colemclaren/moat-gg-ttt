
TALENT.ID = 81
TALENT.Name = "Visionary"
TALENT.NameColor = Color(255, 255, 0)
TALENT.Description = "After killing a player, you have a %s_^ chance to see players within %s^ feet through walls for %s seconds"
TALENT.Tier = 2
TALENT.LevelRequired = {min = 15, max = 20}

TALENT.Modifications = {}
TALENT.Modifications[1] = {min = 10, max = 40}	-- Chance to trigger
TALENT.Modifications[2] = {min = 10, max = 100}	-- Player distance
TALENT.Modifications[3] = {min = 3 , max = 10}	-- Effect duration

TALENT.Melee = true
TALENT.NotUnique = true

function TALENT:OnPlayerDeath(vic, inf, att, talent_mods)
	if (GetRoundState() ~= ROUND_ACTIVE) then return end

	local chance = self.Modifications[1].min + ((self.Modifications[1].max - self.Modifications[1].min) * talent_mods[1])
	if (chance > math.random() * 100) then
		local feet = self.Modifications[2].min + ((self.Modifications[2].max - self.Modifications[2].min) * talent_mods[2])
		local secs = self.Modifications[3].min + ((self.Modifications[3].max - self.Modifications[3].min) * talent_mods[3])

		net.Start("Moat.Talents.Visionary")
			net.WriteDouble(secs)
			net.WriteDouble(feet)
		net.Send(att)
	end
end