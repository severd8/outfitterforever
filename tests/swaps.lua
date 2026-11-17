-- Outfits that move an item between the two ring slots, the two trinket slots or the two
-- hands. Two outfits often share a ring in different slots: a player's Normal outfit wore
-- rings A and B, their Holy outfit B (in the other slot) and C, and half the switches left
-- the wrong rings on, which were then kept as gear put on by hand. Run by tests/run.lua, with
-- items moving at once and with every move waiting for the server (as in the game, where
-- nothing moves until it answers and the items stay locked until then).

local failures = 0
local tag = ""
local function Check(condition, message)
	if not condition then
		failures = failures + 1
		print("FAIL [swaps" .. tag .. "] " .. message)
	end
	return condition
end

local L, R, S = 1101, 1102, 1103 -- rings
local T1, T2, T3 = 1111, 1112, 1113 -- trinkets
local M1, M2, M3 = 1121, 1122, 1123 -- one-handers
local ITEMS = {
	[L] = { "Loop of Sacrifice", "INVTYPE_FINGER", "Armor", "Miscellaneous", 4, 0, 2, 28 },
	[R] = { "Runemender's Seal", "INVTYPE_FINGER", "Armor", "Miscellaneous", 4, 0, 3, 32 },
	[S] = { "Solid Gold Band", "INVTYPE_FINGER", "Armor", "Miscellaneous", 4, 0, 2, 36 },
	[T1] = { "Satchel of Potions", "INVTYPE_TRINKET", "Armor", "Miscellaneous", 4, 0, 2, 33 },
	[T2] = { "Orb of Souls", "INVTYPE_TRINKET", "Armor", "Miscellaneous", 4, 0, 2, 30 },
	[T3] = { "Mark of the Chosen", "INVTYPE_TRINKET", "Armor", "Miscellaneous", 4, 0, 2, 20 },
	[M1] = { "Stout Battlehammer", "INVTYPE_WEAPON", "Weapon", "One-Handed Maces", 2, 4, 3, 30 },
	[M2] = { "Wolfsbane", "INVTYPE_WEAPON", "Weapon", "One-Handed Axes", 2, 0, 2, 30 },
	[M3] = { "Keen Machete", "INVTYPE_WEAPON", "Weapon", "Daggers", 2, 15, 2, 20 },
}
local SLOT_IDS = { Finger0Slot = 11, Finger1Slot = 12, Trinket0Slot = 13, Trinket1Slot = 14, MainHandSlot = 16, SecondaryHandSlot = 17 }

local function Session(serverDelay)
	_G.W = nil
	local W = dofile("tests/wow.lua")
	W.expansionLevel, W.projectId = 0, 18
	dofile("tests/fakes.lua")
	for id, info in pairs(ITEMS) do W.itemDB[id] = info end
	W.equipped = { [1] = 1001, [5] = 1003, [8] = 1005, [11] = L, [12] = R, [13] = T1, [14] = T2, [16] = M1, [17] = M2 }
	W.bags = { [0] = { [1] = { id = S, count = 1 }, [2] = { id = T3, count = 1 }, [3] = { id = M3, count = 1 } } }
	W.LoadToc("OutfitterForever.toc")
	W.Fire("ADDON_LOADED", W.addonName)
	W.Fire("VARIABLES_LOADED")
	W.loggedIn = true
	W.Fire("PLAYER_LOGIN")
	W.Fire("PLAYER_ENTERING_WORLD", true, false)
	W.Fire("BAG_UPDATE", 0)
	W.Fire("UNIT_INVENTORY_CHANGED", "player")
	W.Tick(5)
	local O = W.env.Outfitter
	W.serverDelay = serverDelay
	return W, O
end

-- A complete outfit: what's worn, with `changes` (slot name = item ID, false = empty)
local function MakeOutfit(W, O, name, changes)
	local outfit = O:GetInventoryOutfit(name)
	for slotName, id in pairs(changes) do
		outfit:AddItem(slotName, id and O:GetItemInfoFromLink(W.ItemLink(id)) or nil)
	end
	O:AddOutfit(outfit)
	return outfit
end

local function Codes(outfit)
	local codes = {}
	for slotName in pairs(SLOT_IDS) do
		local item = outfit:GetItem(slotName)
		codes[slotName] = item and item.Code or "none"
	end
	return codes
end

local function Describe(W)
	local parts = {}
	for _, slotName in ipairs({ "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot" }) do
		local id = W.equipped[SLOT_IDS[slotName]]
		parts[#parts + 1] = slotName .. "=" .. (id and W.itemDB[id][1] or "empty")
	end
	return table.concat(parts, ", ")
end

local function Stack(O)
	local names = {}
	for _, outfit in ipairs(O.OutfitStack.Outfits) do names[#names + 1] = outfit:GetName() or "(temporary)" end
	return table.concat(names, " > ")
end

-- Wears each outfit in turn, three times round, and checks the gear after each
local function Scenario(name, slots, first, second)
	for _, serverDelay in ipairs({ 0, 0.25 }) do
		do
			tag = " " .. name .. (serverDelay > 0 and ", moves wait for the server" or ", moves at once")
			local W, O = Session(serverDelay)
			local outfits = { MakeOutfit(W, O, "First", first), MakeOutfit(W, O, "Second", second) }
			local saved = { Codes(outfits[1]), Codes(outfits[2]) }
			local wants = { first, second }
			local ok = true
			for round = 1, 6 do
				local index = round % 2 == 1 and 2 or 1
				local outfit = outfits[index]
				W.uiErrors = {}
				O:WearOutfit(outfit)
				for _ = 1, 60 do W.Tick(0.1) end -- in small steps, so events come as the moves land
				for _, slotName in ipairs(slots) do
					local want = wants[index][slotName]
					if want == nil then want = outfit:GetItem(slotName).Code end
					local has = W.equipped[SLOT_IDS[slotName]]
					ok = Check((has or false) == (want ~= 0 and want or false),
						string.format("switch %d to %s: %s has %s, the outfit has %s (%s)", round, outfit:GetName(), slotName,
							has and W.itemDB[has][1] or "nothing", want and want ~= 0 and W.itemDB[want][1] or "nothing", Describe(W))) and ok
				end
				ok = Check(O.OutfitStack:GetTemporaryOutfit() == nil and #O.OutfitStack.Outfits == 1,
					string.format("switch %d to %s: nothing is taken for gear put on by hand (stack: %s)", round, outfit:GetName(), Stack(O))) and ok
				for which = 1, 2 do
					local now = Codes(outfits[which])
					for slotName, code in pairs(saved[which]) do
						ok = Check(now[slotName] == code, string.format("switch %d to %s: outfit %s still has its %s (%s, now %s)",
							round, outfit:GetName(), outfits[which]:GetName(), slotName, tostring(code), tostring(now[slotName]))) and ok
					end
				end
				for _, message in ipairs(W.uiErrors) do
					ok = Check(false, string.format("switch %d to %s: error %q", round, outfit:GetName(), message)) and ok
				end
				for _, message in ipairs(W.errors) do
					ok = Check(false, "Lua error: " .. tostring(message)) and ok
				end
				W.errors = {}
				if not ok then break end -- the first wrong switch is the one that tells
			end
		end
	end
	tag = ""
end

-- The player's outfits: one ring in both, in different slots, and a ring from the bags
Scenario("rings, one shared in the other slot", { "Finger0Slot", "Finger1Slot" },
	{ Finger0Slot = L, Finger1Slot = R }, { Finger0Slot = R, Finger1Slot = S })
-- Each ring goes to the other slot
Scenario("rings, swapped", { "Finger0Slot", "Finger1Slot" },
	{ Finger0Slot = L, Finger1Slot = R }, { Finger0Slot = R, Finger1Slot = L })
-- The first ring slot's ring moves over and a ring from the bags takes its place
Scenario("rings, the first one moves over", { "Finger0Slot", "Finger1Slot" },
	{ Finger0Slot = L, Finger1Slot = R }, { Finger0Slot = S, Finger1Slot = L })
-- A ring moves over and its old slot is emptied
Scenario("rings, one moves and the other slot empties", { "Finger0Slot", "Finger1Slot" },
	{ Finger0Slot = L, Finger1Slot = R }, { Finger0Slot = R, Finger1Slot = false })
Scenario("trinkets, one shared in the other slot", { "Trinket0Slot", "Trinket1Slot" },
	{ Trinket0Slot = T1, Trinket1Slot = T2 }, { Trinket0Slot = T2, Trinket1Slot = T3 })
Scenario("one-handers, the off-hand moves to the main hand", { "MainHandSlot", "SecondaryHandSlot" },
	{ MainHandSlot = M1, SecondaryHandSlot = M2 }, { MainHandSlot = M2, SecondaryHandSlot = M3 })
Scenario("one-handers, swapped", { "MainHandSlot", "SecondaryHandSlot" },
	{ MainHandSlot = M1, SecondaryHandSlot = M2 }, { MainHandSlot = M2, SecondaryHandSlot = M1 })

return failures
