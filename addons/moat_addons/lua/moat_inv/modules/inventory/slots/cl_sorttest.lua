function MOAT_INV:SortTest()
    local function sort(tbl, empty)
        local function value(item)
            -- slotid is from 0 to 10
            local itemid_max = 100000
            local slot_max = 11
            local tier_max = 10

            local itemid_mult = 1
            local tier_mult   = itemid_max * itemid_mult
            local slot_mult   = tier_mult * tier_max

            return item.tier * tier_mult + (slot_max - item.slot) * slot_mult + item.itemid * itemid_mult
        end
        table.sort(tbl, function(item1, item2)
            local v1, v2 = value(item1), value(item2)
            if (v1 == v2) then
                if (item1.w and item2.w) then
                    return item1.w > item2.w
                else
                    return not not item1.w
                end
            end
            return v1 > v2
        end)
    end

    self:SortSlots(sort, function(tbl)
        self:GetOurSlots(function(max, items)
            local needed = {}
            local slotwep = {}
            for id in pairs(items.c) do
                needed[id] = true
            end
            for i, item in ipairs(tbl) do
                assert(item.id, "No item id")
                if (item.id == 0) then
                    continue
                end
                assert(needed[item.id], "Duplicate or nonexisting item")
                assert(items.s[item.slotid] == item.id, "Item slot mismatch")
                slotwep[i] = item.id
                needed[item.id] = nil
            end
            local it = table.Copy(items)
            for slot, id in pairs(slotwep) do
                -- since we don't update sql we don't need a callback
                local from, to = it.c[id], slot
                if (from == to) then
                    continue
                end
                m_SwapInventorySlots(M_INV_SLOT[from], to, nil, true)

                local fid, tid = it.s[from], it.s[to]
                it.s[to], it.s[from] = fid, tid
                it.c[fid] = to
                if (tid ~= 0) then
                    it.c[tid] = from
                end
            end
            self:MassSwapInventory(slotwep, function()
                -- internals updated, modify memes
                print "done"
            end)
        end)
    end)
end