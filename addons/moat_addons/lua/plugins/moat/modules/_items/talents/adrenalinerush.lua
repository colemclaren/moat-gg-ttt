
TALENT.ID = 8
TALENT.Name = "Adrenaline Rush"
TALENT.NameColor = Color( 255, 0, 0 )
TALENT.Description = "Damage is increased by %s_^ for %s seconds after killing with this weapon"
TALENT.Tier = 1
TALENT.LevelRequired = { min = 5, max = 10 }

TALENT.Modifications = {}
TALENT.Modifications[1] = { min = 5, max = 15 } -- Percent damage is increased by
TALENT.Modifications[2] = { min = 3, max = 7 }	-- Damage time

TALENT.Melee = true
TALENT.NotUnique = true

function TALENT:OnPlayerDeath(victim, _, attacker, talent_mods)
	if (GetRoundState() ~= ROUND_ACTIVE or MOAT_ACTIVE_BOSS) then return end

	status.Inflict("Adrenaline Rush", {
		Player = attacker,
		Weapon = attacker:GetActiveWeapon(),
		Time = self.Modifications[2].min + ((self.Modifications[2].max - self.Modifications[2].min) * talent_mods[2]),
		Percent = 1 + ((self.Modifications[1].min + ((self.Modifications[1].max - self.Modifications[1].min) * talent_mods[1])) / 100)
	})
end


local STATUS = status.Create "Adrenaline Rush"
function STATUS:Invoke(data)
	self:CreateEffect "Damaging":Invoke(data, data.Time, data.Player)
end

local EFFECT = STATUS:CreateEffect "Damaging"
EFFECT.Message = "Damaging"
EFFECT.Color = TALENT.NameColor
EFFECT.Material = "icon16/anchor.png"
function EFFECT:Init(data)
	local curWeapon = data.Weapon.Primary
	
	if (not curWeapon.BaseDamage) then
		curWeapon.BaseDamage = curWeapon.Damage
	end

	curWeapon.AdrenalineStacks = (curWeapon.AdrenalineStacks or 0) + 1
	curWeapon.Damage = curWeapon.BaseDamage + (curWeapon.AdrenalineStacks * data.Percent)

	self:SetEndCallback(self.Callback)	-- If we force the effect to end earlier, it can clean up properly.
	self:CreateTimer(data.Time, 1, function() end, data)
end

function EFFECT:Callback(data)
	if (not IsValid(data.Weapon)) then return end

	local curWeapon = data.Weapon.Primary
	
	curWeapon.AdrenalineStacks = math.max(curWeapon.AdrenalineStacks - 1, 0)
	curWeapon.Damage = curWeapon.BaseDamage + (curWeapon.AdrenalineStacks * data.Percent)
end
