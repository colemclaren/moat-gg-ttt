print("talents loaded")

local plyMeta = FindMetaTable('Player')

function m_ApplyTalentsToWeapon(weapontbl, talent_tbl)
    local wep = weapontbl
    local talent_enum = talent_tbl.e
    local talent_mods = talent_tbl.m or {}
    local talent_servertbl = m_GetTalentFromEnumWithFunctions(talent_enum)

    if (talent_servertbl.ModifyWeapon) then
        talent_servertbl:ModifyWeapon(wep, talent_mods)
    end
end

function m_ApplyTalentMods(weapontbl, loadout_table)
    local wep = weapontbl
    local itemtbl = table.Copy(loadout_table)
    local weapon_lvl = wep.level

    for k, v in ipairs(wep.Talents) do
        if (weapon_lvl >= v.l) then
            m_ApplyTalentsToWeapon(wep, v)
        end
    end
end

-- Frozen Talent --

util.AddNetworkString('moatFrozenNotification')
util.AddNetworkString('moatFrozenShake')
util.AddNetworkString("FrozenPlayer")

local frozen_players = 0

function plyMeta:moatFreeze(length, speed, delay)
	local timerNameSlow, timerNameDamage = 'moatFreezeTimer_'..self:SteamID64(), 'moatFreezeDamageTimer_'..self:SteamID64()
	local freezeFunction, freezeDamageFunction = function()
        self.moatFrozen = false
        self:SetNWFloat("moatFrozenSpeed", 0)
        self:SetNWBool('moatFrozen', false)
        frozen_players = frozen_players - 1

        net.Start("FrozenPlayer")
        net.WriteUInt(frozen_players, 8)
        net.Broadcast()

        if (timer.Exists(timerNameDamage)) then timer.Remove(timerNameDamage) end 
    end, function() 
        if (self:canBeMoatFrozen()) then 
            self:TakeDamage(2, self.frozenInfo[att], self.frozenInfo[infl]) 
        else
            timer.Remove(timerNameDamage)
        end
    end
	
	if (self:canBeMoatFrozen()) then
		self.moatFrozen = true
        self:SetNWFloat("moatFrozenSpeed", speed)
		self:SetNWBool('moatFrozen', true)
		
		if (timer.Exists(timerNameSlow)) then
			timer.Adjust(timerNameSlow, length, 1, freezeFunction)
			timer.Adjust(timerNameDamage, delay, 0, freezeDamageFunction)

            net.Start("moat.dot.adjust")
            net.WriteString(tostring("frost" .. self:EntIndex()))
            net.WriteUInt(length, 16)
            net.Send(self)
		else
			timer.Create(timerNameSlow, length, 1, freezeFunction)
			timer.Create(timerNameDamage, delay, 0, freezeDamageFunction)

            net.Start("moat.dot.init")
            net.WriteString("Frostbitten")
            net.WriteUInt(length, 16)
            net.WriteString("icon16/weather_snow.png")
            net.WriteColor(Color(200, 200, 200))
            net.WriteString(tostring("frost" .. self:EntIndex()))
            net.Send(self)

            frozen_players = frozen_players + 1
            
            net.Start("FrozenPlayer")
            net.WriteUInt(frozen_players, 8)
            net.Broadcast()
		end
		
		net.Start('moatFrozenNotification')
		net.Send(self)
		
		net.Start('moatFrozenShake')
			net.WriteInt(length, 32)
		net.Send(self)
	end
end

-------------------

function m_ApplyTalentsToWeaponOnDeath(vic, inf, att, talent_tbl)
    local talent_enum = talent_tbl.e
    local talent_mods = talent_tbl.m or {}
    local talent_servertbl = m_GetTalentFromEnumWithFunctions(talent_enum)

    if (talent_servertbl.OnPlayerDeath) then
        talent_servertbl:OnPlayerDeath(vic, inf, att, talent_mods)
    end
end

hook.Add("PlayerDeath", "moat_ApplyDeathTalents", function(vic, inf, att)
    if (not vic:IsValid() or not (att and att:IsValid() and att:IsPlayer())) then return end
    if (not inf:IsValid() or not (inf and inf:IsValid())) then return end
    if (not inf:IsWeapon()) then inf = att:GetActiveWeapon() end
    if (not inf.Talents) then return end

    local weapon_lvl = inf.level

    for k, v in ipairs(inf.Talents) do
        if (weapon_lvl >= v.l) then
            m_ApplyTalentsToWeaponOnDeath(vic, inf, att, v)
        end
    end
end)

function m_ApplyTalentsToWeaponDuringDamage(dmginfo, victim, attacker, talent_tbl)
    local talent_enum = talent_tbl.e
    local talent_mods = talent_tbl.m or {}
    local talent_servertbl = m_GetTalentFromEnumWithFunctions(talent_enum)

    if (talent_servertbl.OnPlayerHit) then
        talent_servertbl:OnPlayerHit(victim, attacker, dmginfo, talent_mods)
    end
end

function m_ApplyTalentsToWeaponScalingDamage(dmginfo, victim, attacker, hitgroup, talent_tbl)
    local talent_enum = talent_tbl.e
    local talent_mods = talent_tbl.m or {}
    local talent_servertbl = m_GetTalentFromEnumWithFunctions(talent_enum)

    if (talent_servertbl.ScalePlayerDamage) then
        talent_servertbl:ScalePlayerDamage(victim, attacker, dmginfo, hitgroup, talent_mods)
    end
end

hook.Add("EntityTakeDamage", "moat_ApplyDamageMods", function(ent, dmginfo)
    if (not ent:IsValid() or not ent:IsPlayer()) then return end
    local attacker = dmginfo:GetAttacker()
    if (not attacker:IsValid() or not attacker:IsPlayer() or not dmginfo:IsBulletDamage()) then return end
    local weapon_tbl = attacker:GetActiveWeapon()
    if (not weapon_tbl.Talents) then return end
    local weapon_lvl = weapon_tbl.level

    for k, v in ipairs(weapon_tbl.Talents) do
        if (weapon_lvl >= v.l) then
            m_ApplyTalentsToWeaponDuringDamage(dmginfo, ent, attacker, v)
        end
    end
end)

function m_ApplyTalentsToWeaponDuringSwitch(ply, wep, talent_tbl, isto)
    local talent_enum = talent_tbl.e
    local talent_mods = talent_tbl.m or {}
    local talent_servertbl = m_GetTalentFromEnumWithFunctions(talent_enum)

    if (talent_servertbl.OnWeaponSwitch) then
        talent_servertbl:OnWeaponSwitch(ply, wep, isto, talent_mods)
    end
end

hook.Add("PlayerSwitchWeapon", "moat_ApplySwitchMods", function(ply, oldw, neww)
    if (oldw:IsValid() and oldw.Talents) then
        local weapon_lvl = oldw.level

        for k, v in ipairs(oldw.Talents) do
            if (weapon_lvl >= v.l) then
                m_ApplyTalentsToWeaponDuringSwitch(ply, oldw, v, false)
            end
        end
    end

    if (neww:IsValid() and neww.Talents) then
        local weapon_lvl = neww.level

        for k, v in ipairs(neww.Talents) do
            if (weapon_lvl >= v.l) then
                m_ApplyTalentsToWeaponDuringSwitch(ply, neww, v, true)
            end
        end
    end
end)

hook.Add("ScalePlayerDamage", "moat_ApplyScaleDamageMods", function(ply, hitgroup, dmginfo)
    if (not IsValid(ply) or not ply:IsValid()) then return end
    local attacker = dmginfo:GetAttacker()
    if (not attacker:IsValid() or not attacker:IsPlayer() or not dmginfo:IsBulletDamage() or dmginfo:GetDamage() == 0) then return end
    local weapon_tbl = attacker:GetActiveWeapon()
    if (not weapon_tbl.Talents) then return end
    local weapon_lvl = weapon_tbl.level

    for k, v in ipairs(weapon_tbl.Talents) do
        if (weapon_lvl >= v.l) then
            m_ApplyTalentsToWeaponScalingDamage(dmginfo, ply, attacker, hitgroup, v)
        end
    end
end)

function m_ApplyTalentsToWeaponOnFire(attacker, dmginfo, talent_tbl)
    local talent_enum = talent_tbl.e
    local talent_mods = talent_tbl.m or {}
    local talent_servertbl = m_GetTalentFromEnumWithFunctions(talent_enum)

    if (talent_servertbl.OnWeaponFired) then
        return talent_servertbl:OnWeaponFired(attacker, dmginfo, talent_mods)
    end

    return true
end

hook.Add("EntityFireBullets", "moat_ApplyFireMods", function(ent, dmginfo)
    if (not ent:IsValid() or not ent:IsPlayer()) then return end
    local weapon_tbl = ent:GetActiveWeapon()
    if (not weapon_tbl.Talents) then return end
    local weapon_lvl = weapon_tbl.level

    for k, v in ipairs(weapon_tbl.Talents) do
        if (weapon_lvl >= v.l) then

            local talent_enum = v.e
            local talent_mods = v.m or {}
            local talent_servertbl = m_GetTalentFromEnumWithFunctions(talent_enum)

            if (talent_servertbl.OnWeaponFired) then
                if (talent_servertbl:OnWeaponFired(attacker, dmginfo, talent_mods)) then
                    return true
                end
            end
        end
    end
end)

function m_UpdateItemLevel(weapon_tbl, attacker, exp_to_add)
    local unique_item_id = weapon_tbl.UniqueItemID
    local inv_item = {}

    for i = 1, attacker:GetNWInt("MOAT_MAX_INVENTORY_SLOTS") do
        if (MOAT_INVS[attacker]["slot" .. i] and MOAT_INVS[attacker]["slot" .. i].c) then
            if (MOAT_INVS[attacker]["slot" .. i].c == unique_item_id) then
                inv_item = MOAT_INVS[attacker]["slot" .. i]
            end
        end
    end

    for i = 1, 10 do
        if (MOAT_INVS[attacker]["l_slot" .. i] and MOAT_INVS[attacker]["l_slot" .. i].c) then
            if (MOAT_INVS[attacker]["l_slot" .. i].c == unique_item_id) then
                inv_item = MOAT_INVS[attacker]["l_slot" .. i]
            end
        end
    end

    local cur_exp = inv_item.s.x
    local cur_lvl = inv_item.s.l

    if ((cur_exp + exp_to_add) >= (cur_lvl * 100)) then
        inv_item.s.l = cur_lvl + 1
        inv_item.s.x = math.Round((cur_exp + exp_to_add) - (cur_lvl * 100))

        if (inv_item.s.l % 2 == 0) then
            local crates = m_GetActiveCrates()
            local crate = crates[math.random(1, #crates)].Name

            attacker:m_DropInventoryItem(crate, "hide_chat_obtained", false, false)
        end
    else
        if ((cur_exp + exp_to_add) < 0) then
            inv_item.s.x = 0
        else
            inv_item.s.x = math.Round(cur_exp + exp_to_add)
        end
    end

    net.Start("MOAT_UPDATE_EXP")
    net.WriteString(tostring(unique_item_id))
    net.WriteDouble(inv_item.s.l)
    net.WriteDouble(inv_item.s.x)
    net.Send(attacker)

    m_SaveInventory(attacker)
end

XP_MULTIPYER = 2

hook.Add("PlayerDeath", "moat_updateWeaponLevels", function(victim, inflictor, attacker)
    if (not attacker:IsValid() or not attacker:IsPlayer() or MOAT_MINIGAME_OCCURING) then return end
    local wep_used = attacker:GetActiveWeapon()

    if (IsValid(inflictor) and inflictor.MaxHoldTime) then
        wep_used = inflictor
    end

    if (wep_used.Talents and wep_used.PrimaryOwner == attacker) then
        local exp_to_add = 0

        local vic_killer = victim:GetRole() == ROLE_TRAITOR or victim:GetRole() == ROLE_KILLER
        local att_killer = attacker:GetRole() == ROLE_TRAITOR or attacker:GetRole() == ROLE_KILLER

        if (victim:GetRole() == attacker:GetRole()) then
            exp_to_add = -35
        elseif (vic_killer and attacker:GetDetective()) then
            exp_to_add = 75
        elseif (vic_killer and (victim.GetBasicRole and victim:GetBasicRole() or victim:GetRole()) == ROLE_INNOCENT) then
            exp_to_add = 50
        elseif (att_killer and not vic_killer) then
            exp_to_add = 35
        end

        if (exp_to_add ~= 0 and GetRoundState() == ROUND_ACTIVE) then
            m_UpdateItemLevel(wep_used, attacker, (exp_to_add * XP_MULTIPYER) * attacker.ExtraXP)
        end
    end
end)

concommand.Add("moat_hermes_boots_toggle", function(pl)
    if (IsValid(pl)) then
        local herm = pl:GetInfo("moat_hermes_boots")

        if (herm == "1") then
            pl:ConCommand("moat_hermes_boots 0")
        else
            pl:ConCommand("moat_hermes_boots 1")
        end
    end
end)