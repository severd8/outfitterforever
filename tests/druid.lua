-- A druid with Bear and Cat form outfits and a Healing outfit with no script
-- (issue #13). Run by tests/run.lua.

local failures = 0
local function Check(condition, message)
	if not condition then
		failures = failures + 1
		print("FAIL [druid] " .. message)
	end
	return condition
end

_G.W = nil
local W = dofile("tests/wow.lua")
W.expansionLevel, W.projectId = 0, 18
dofile("tests/fakes.lua")
local env = W.env
W.player.class, W.player.className, W.player.classID = "DRUID", "Druid", 11
W.equipped = { [1] = 1001, [5] = 1003, [8] = 1005, [16] = 1008 }
W.bags = { [0] = { [1] = { id = 1002, count = 1 }, [2] = { id = 1006, count = 1 }, [3] = { id = 1011, count = 1 } } }

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

local function MakeOutfit(name, items, scriptID)
	local outfit = O:GetInventoryOutfit(name) -- every slot, so it's a Complete outfit
	for slotName, itemID in pairs(items) do
		outfit:AddItem(slotName, O:GetItemInfoFromLink(W.ItemLink(itemID)))
	end
	O:AddOutfit(outfit)
	if scriptID then
		O:SetScriptID(outfit, scriptID)
		O:SetScriptEnabled(outfit, true)
		O:ActivateScript(outfit)
	end
	return outfit
end
local function Form(index)
	W.player.form = index
	W.Fire("UPDATE_SHAPESHIFT_FORM")
	W.Fire("UNIT_AURA", "player")
	W.Tick(3)
end

-- The player's setup: helm for Bear, riding boots for Cat, the hat and boots for Healing
local bear = MakeOutfit("1. Bear", { HeadSlot = 1001, FeetSlot = 1005, MainHandSlot = 1008 }, "Bear")
local cat = MakeOutfit("2. Cat", { HeadSlot = 1001, FeetSlot = 1006, MainHandSlot = 1008 }, "Cat")
local healing = MakeOutfit("3. Healing", { HeadSlot = 1002, FeetSlot = 1006, MainHandSlot = 1011 })
Check(bear.CategoryID == "Complete" and healing.CategoryID == "Complete", "the outfits are Complete outfits")
Check(not O:GetScript(healing), "Healing has no script")

-- They put on Healing once, then go Bear
O:WearOutfit(healing)
W.Tick(3)
Check(W.equipped[1] == 1002, "Healing is on (head has " .. tostring(W.equipped[1]) .. ")")
Form(1)
Check(O:WearingOutfit(bear) and W.equipped[1] == 1001, "Bear Form puts on the Bear outfit (head has " .. tostring(W.equipped[1]) .. ")")

-- A loading screen (Hearthstone, Moonglade) or anything else that refreshes talents
-- fires PLAYER_TALENT_UPDATE without a spec change, while still a bear
W.Fire("PLAYER_TALENT_UPDATE")
W.Tick(3)
Check(O:WearingOutfit(bear), "still a bear after a talent update: Bear stays on")
Check(not O:WearingOutfit(healing) and W.equipped[1] == 1001,
	"and Healing doesn't come back by itself (head has " .. tostring(W.equipped[1]) .. ")")

W.Fire("PLAYER_ENTERING_WORLD", false, false)
W.Fire("PLAYER_TALENT_UPDATE")
W.Tick(5)
Check(O:WearingOutfit(bear) and not O:WearingOutfit(healing), "a loading screen as a bear keeps Bear on")

-- Cat Form, then a talent update as a cat
Form(2)
Check(O:WearingOutfit(cat) and W.equipped[8] == 1006, "Cat Form puts on the Cat outfit")
W.Fire("PLAYER_TALENT_UPDATE")
W.Tick(3)
Check(O:WearingOutfit(cat) and not O:WearingOutfit(healing), "a talent update as a cat keeps Cat on")

-- Back to caster form: a Complete form outfit stays on (as it always has, unless
-- "Allow Complete outfits to unequip" is ticked), and a talent update doesn't
-- swap it for Healing either
Form(0)
W.Fire("PLAYER_TALENT_UPDATE")
W.Tick(3)
Check(O:WearingOutfit(cat) and not O:WearingOutfit(healing), "a talent update in caster form doesn't put Healing on")

-- With "Allow Complete outfits to unequip" ticked, leaving the form still takes it off
Form(2)
cat.ScriptSettings.UnequipComplete = true
Form(0)
Check(not O:WearingOutfit(cat), "leaving Cat Form takes Cat off when Complete outfits may unequip")

for _, message in ipairs(W.errors) do Check(false, "Lua error: " .. message:sub(1, 300)) end
return failures
