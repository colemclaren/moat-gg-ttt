ITEM.Name = 'Wanwood Egg Of Zomg'
ITEM.ID = 9077
ITEM.Description = 'A special cosmetic egg from the 2018 Easter event! Right click while in loadout to customize position/size.'
ITEM.Rarity = 8
ITEM.Collection = 'Easter 2018 Collection'
ITEM.Model = 'models/roblox_assets/wanwood_egg_of_zomg.mdl'
ITEM.Attachment = 'eyes'
function ITEM:ModifyClientsideModel(pl, mdl, pos, ang)
	mdl:SetModelScale(0.675)
	pos = pos + (ang:Forward() * -2.7972412109375) + (ang:Right() * 0.00634765625) +  (ang:Up() * 1.4794616699219)
	
	return mdl, pos, ang
end