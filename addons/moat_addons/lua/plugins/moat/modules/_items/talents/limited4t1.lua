
TALENT.ID = 31
TALENT.Name = "Wildcard: Tier 1"
TALENT.NameEffect = "enchanted"
TALENT.NameColor = Color(0, 255,0)
TALENT.Description = "When this talent is unlocked, it will morph into a different talent every round"
TALENT.Tier = 1
TALENT.LevelRequired = {min = 5, max = 10}

TALENT.Modifications = {}

TALENT.Melee = false
TALENT.NotUnique = false

util.AddNetworkString("weapon.UpdateTalents")

wildcard_prep_cache = {}

hook.Add("TTTBeginRound","ClearWildcard",function()
    timer.Simple(5,function()
        wildcard_prep_cache = {}
    end)
end)

local tier = 1
local id = TALENT.ID
function wildcard_t1(weapon,talent_mods)
    local talents = table.Copy(MOAT_TALENTS)

    local active = weapon.Talents[tier].l <= weapon.level
    if (not active) then return end


    for k,v in pairs(talents) do 
        if v.Tier ~= tier or v.ID == id or (v.ID == 154) then 
            talents[k] = nil 
        end 
    end

    local talent, tk = table.Random(talents)

    local t = {
        e = talent.ID,
        l = weapon.Talents[tier].l,
        m = {}
    }

    for k,v in pairs(talent.Modifications) do
        t.m[k] = math.Round(math.Rand(0, 1), 2)
    end

    local wep = weapon.Weapon
    if GetRoundState() == ROUND_PREP then 
        if wildcard_prep_cache[wep:GetOwner()] and wildcard_prep_cache[wep:GetOwner()][tier] and wildcard_prep_cache[wep:GetOwner()][tier][wep:GetClass()] then
            talent = talents[wildcard_prep_cache[wep:GetOwner()][tier][wep:GetClass()][1]]
            t = wildcard_prep_cache[wep:GetOwner()][tier][wep:GetClass()][2]
        end
        if not wildcard_prep_cache[wep:GetOwner()] then
            wildcard_prep_cache[wep:GetOwner()] = {}
        end
        if not wildcard_prep_cache[wep:GetOwner()][tier] then
            wildcard_prep_cache[wep:GetOwner()][tier] = {}
        end
        wildcard_prep_cache[wep:GetOwner()][tier][wep:GetClass()] = {tk,t}
    else
        if wildcard_prep_cache[wep:GetOwner()] then
            if wildcard_prep_cache[wep:GetOwner()][tier] then
                if wildcard_prep_cache[wep:GetOwner()][tier][wep:GetClass()] then
                    talent = talents[wildcard_prep_cache[wep:GetOwner()][tier][wep:GetClass()][1]]
                    t = wildcard_prep_cache[wep:GetOwner()][tier][wep:GetClass()][2]
                end
            end
        end
    end


    weapon.Weapon.Talents[tier] = t
    weapon.Weapon.ItemStats.t[tier] = t
    weapon.Weapon.ItemStats.Talents[tier] = talent

    if loadout_weapon_indexes[weapon.Weapon:EntIndex()] then
        loadout_weapon_indexes[weapon.Weapon:EntIndex()].info.Talents[tier] = t
        loadout_weapon_indexes[weapon.Weapon:EntIndex()].info.t[tier] = t
        loadout_weapon_indexes[weapon.Weapon:EntIndex()].info.Talents[tier] = talent
    end


    m_ApplyTalentsToWeapon(weapon.Weapon,t)

    for k,v in pairs(talent) do
        if isfunction(v) then talent[k] = nil end
    end

    timer.Simple(1,function()
        net.Start("weapon.UpdateTalents")
        net.WriteEntity(weapon.Weapon)
        net.WriteInt(tier,8)
        net.WriteTable(talent)
        net.WriteTable(t)
        net.Broadcast()
    end)

    -- PrintTable(talents)

    -- for i = 1, table.Count(talents_chosen) do
    --     local talent_tbl = talents_chosen[i]
    --     dropped_item.t[i] = {}
    --     dropped_item.t[i].e = talent_tbl.ID
    --     dropped_item.t[i].l = math.random(talent_tbl.LevelRequired.min, talent_tbl.LevelRequired.max)
    --     dropped_item.t[i].m = {}

    --     for k, v in ipairs(talent_tbl.Modifications) do
    --         dropped_item.t[i].m[k] = math.Round(math.Rand(0, 1), 2)
    --     end
    -- end
end

function TALENT:ModifyWeapon( weapon, talent_mods )
    timer.Simple(1,function()
        wildcard_t1(weapon,talent_mods)
    end)
end