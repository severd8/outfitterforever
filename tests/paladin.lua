-- A paladin with outfits switched by the Has Buff script on their auras
-- (Devotion Aura and Retribution Aura). Run by tests/run.lua.

local failures = 0
local function Check(condition, message)
	if not condition then
		failures = failures + 1
		print("FAIL [paladin] " .. message)
	end
	return condition
end

_G.W = nil
local W = dofile("tests/wow.lua")
W.expansionLevel, W.projectId = 0, 18
dofile("tests/fakes.lua")
local env = W.env
W.player.class, W.player.className, W.player.classID = "PALADIN", "Paladin", 2
W.equipped = { [1] = 1001, [5] = 1003, [8] = 1005, [16] = 1008, [17] = 1009 }
W.bags = { [0] = { [1] = { id = 1007, count = 1 } } }

W.LoadToc("OutfitterForever.toc")
W.Fire("ADDON_LOADED", W.addonName)
W.Fire("VARIABLES_LOADED")
W.loggedIn = true
W.Fire("PLAYER_LOGIN")
W.Fire("PLAYER_ENTERING_WORLD", true, false)
W.Fire("BAG_UPDATE", 0)
W.Fire("UNIT_INVENTORY_CHANGED", "player")
W.Tick(5)
local O = env.Outfitter

local DEVOTION = { name = "Devotion Aura", icon = 135893, spellId = 465 }
local RETRIBUTION = { name = "Retribution Aura", icon = 135873, spellId = 7294 }
local CRUSADER = { name = "Seal of the Crusader", icon = 135924, spellId = 21082 }

local function Aura(...)
	W.auras = { ... }
	W.Fire("UNIT_AURA", "player")
	W.Tick(3)
end
local function Weapons()
	return tostring(W.equipped[16]) .. "/" .. tostring(W.equipped[17])
end
local function HasBuffOutfit(outfit, buffName)
	O:AddOutfit(outfit)
	O:SetScriptID(outfit, "HAS_BUFF")
	outfit.ScriptSettings = { buffName = buffName }
	O:SetScriptEnabled(outfit, true)
	O:ActivateScript(outfit)
	return outfit
end

-- Weapons only: sword and shield for Devotion, the two-hander for Retribution
local function WeaponOutfit(name, mainHand, offHand)
	local outfit = O:NewEmptyOutfit(name)
	outfit:AddItem("MainHandSlot", O:GetItemInfoFromLink(W.ItemLink(mainHand)))
	outfit:AddItem("SecondaryHandSlot", offHand and O:GetItemInfoFromLink(W.ItemLink(offHand)) or nil)
	return outfit
end
Aura(DEVOTION)
local tank = HasBuffOutfit(WeaponOutfit("Tank weapons", 1008, 1009), "Devotion Aura")
local ret = HasBuffOutfit(WeaponOutfit("Ret weapons", 1007), "Retribution Aura")
Check(tank.CategoryID ~= "Complete", "weapon outfits aren't Complete outfits (" .. tostring(tank.CategoryID) .. ")")
W.Tick(3)
Aura(RETRIBUTION)
Check(W.equipped[16] == 1007, "Retribution Aura puts the two-hander on (weapons " .. Weapons() .. ")")
Aura(DEVOTION)
Check(W.equipped[16] == 1008 and W.equipped[17] == 1009, "Devotion Aura puts sword and shield back (weapons " .. Weapons() .. ")")
Aura(RETRIBUTION)
Check(W.equipped[16] == 1007, "and Retribution again (weapons " .. Weapons() .. ")")

-- The same with a Retribution outfit that has only the main hand in it
O:SetScriptEnabled(ret, false) O:DeactivateScript(ret) O:RemoveOutfit(ret)
Aura(DEVOTION)
local retMainOnly = O:NewEmptyOutfit("Ret main hand")
retMainOnly:AddItem("MainHandSlot", O:GetItemInfoFromLink(W.ItemLink(1007)))
HasBuffOutfit(retMainOnly, "Retribution Aura")
Aura(RETRIBUTION)
Check(W.equipped[16] == 1007, "a main-hand-only outfit: Retribution puts the two-hander on (weapons " .. Weapons() .. ")")
Aura(DEVOTION)
Check(W.equipped[16] == 1008 and W.equipped[17] == 1009, "and Devotion puts sword and shield back (weapons " .. Weapons() .. ")")
O:SetScriptEnabled(retMainOnly, false) O:DeactivateScript(retMainOnly) O:RemoveOutfit(retMainOnly)


O:SetScriptEnabled(tank, false) O:SetScriptEnabled(ret, false)
O:DeactivateScript(tank) O:DeactivateScript(ret)
O:RemoveOutfit(tank) O:RemoveOutfit(ret)
W.Tick(3)

-- Complete outfits: the same armor, different weapons
local function CompleteOutfit(name, mainHand, offHand)
	W.equipped[16], W.equipped[17] = 1008, 1009
	local outfit = O:GetInventoryOutfit(name)
	outfit:AddItem("MainHandSlot", O:GetItemInfoFromLink(W.ItemLink(mainHand)))
	outfit:AddItem("SecondaryHandSlot", offHand and O:GetItemInfoFromLink(W.ItemLink(offHand)) or nil)
	return outfit
end
W.equipped[16], W.equipped[17] = 1008, 1009
W.bags = { [0] = { [1] = { id = 1007, count = 1 } } }
W.Fire("BAG_UPDATE", 0) W.Tick(3)
Aura(DEVOTION)
local tankSet = HasBuffOutfit(CompleteOutfit("Tank set", 1008, 1009), "Devotion Aura")
local retSet = HasBuffOutfit(CompleteOutfit("Ret set", 1007), "Retribution Aura")
Check(retSet.CategoryID == "Complete", "full sets are Complete outfits")
Aura(DEVOTION)
Check(W.equipped[16] == 1008 and W.equipped[17] == 1009, "Devotion: sword and shield (weapons " .. Weapons() .. ")")
Aura(RETRIBUTION)
Check(W.equipped[16] == 1007 and O:WearingOutfit(retSet), "Retribution: two-hander (weapons " .. Weapons() .. ")")

-- Into combat, then an ability: Seal of the Crusader
W.aurasHiddenInCombat = true
local equipChanges = 0
W.combat = true
W.Fire("PLAYER_REGEN_DISABLED")
W.Tick(1)
for i = 1, 5 do
	W.Fire("UNIT_SPELLCAST_SENT", "player", "Mob", "cast" .. i, 21082)
	W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast" .. i, 21082)
	W.auras = { RETRIBUTION, CRUSADER }
	W.Fire("UNIT_AURA", "player", { isFullUpdate = false })
	W.Tick(1)
	if W.equipped[16] ~= 1007 then equipChanges = equipChanges + 1 end
end
Check(equipChanges == 0 and W.equipped[16] == 1007, "using abilities in combat keeps the two-hander on (" .. equipChanges .. " changes, weapons " .. Weapons() .. ")")
Check(O:WearingOutfit(retSet) and not O:WearingOutfit(tankSet), "and the Ret set stays the outfit worn")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Tick(3)
Check(W.equipped[16] == 1007, "still the two-hander after combat (weapons " .. Weapons() .. ")")

-- Switching aura in combat can't be seen, so the outfit follows when combat ends
W.combat = true
W.Fire("PLAYER_REGEN_DISABLED")
Aura(DEVOTION, CRUSADER)
Check(O:WearingOutfit(retSet), "an aura switched in combat changes nothing yet")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Tick(3)
Check(O:WearingOutfit(tankSet) and W.equipped[16] == 1008 and W.equipped[17] == 1009,
	"and the Devotion set goes on when combat ends (weapons " .. Weapons() .. ")")

-- The same when auras throw in combat instead of hiding
W.aurasHiddenInCombat = false
W.combat = true
W.Fire("PLAYER_REGEN_DISABLED")
Aura(RETRIBUTION, CRUSADER)
Check(O:WearingOutfit(tankSet), "auras that throw in combat change nothing either")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Tick(3)
Check(O:WearingOutfit(retSet) and W.equipped[16] == 1007, "and Ret goes on when combat ends (weapons " .. Weapons() .. ")")

for _, message in ipairs(W.errors) do Check(false, "Lua error: " .. message:sub(1, 300)) end
return failures
