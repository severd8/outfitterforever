-- Scenarios that span a /reload (or logging out and in): what Outfitter saves has to bring
-- the next session back to the gear you were wearing. Run by tests/run.lua.
-- Each session is a fresh fake client; between sessions the saved settings are copied the
-- way the game writes them out (plain data: no metatables, no functions).

local failures = 0
local function Check(condition, message)
	if not condition then
		failures = failures + 1
		print("FAIL [reload] " .. message)
	end
	return condition
end

local function Plain(value, seen)
	if type(value) == "function" or type(value) == "userdata" then return nil end
	if type(value) ~= "table" then return value end
	seen = seen or {}
	if seen[value] then return seen[value] end
	local copy = {}
	seen[value] = copy
	for k, v in pairs(value) do
		if type(k) == "string" or type(k) == "number" then copy[k] = Plain(v, seen) end
	end
	return copy
end

-- A level 5 warrior. `state` carries one session's gear, bags and saved settings to the next.
local function Session(state, play)
	_G.W = nil
	local W = dofile("tests/wow.lua")
	W.expansionLevel, W.projectId = 0, 18
	dofile("tests/fakes.lua")
	local env = W.env
	W.player.level = 5
	W.equipped, W.bags = state.equipped, state.bags
	W.LoadToc("OutfitterForever.toc")
	if state.settings then
		rawset(env, "gOutfitter_Settings", state.settings)
		rawset(env, "gOutfitter_GlobalSettings", state.global)
	end
	W.Fire("ADDON_LOADED", W.addonName)
	W.Fire("VARIABLES_LOADED")
	W.loggedIn = true
	W.Fire("PLAYER_LOGIN")
	W.Fire("PLAYER_ENTERING_WORLD", true, false)
	W.Fire("BAG_UPDATE", 0)
	W.Fire("UNIT_INVENTORY_CHANGED", "player")
	W.Tick(5)
	local O = env.Outfitter
	local S = { W = W, env = env, O = O }
	function S.gear()
		local worn = {}
		for slot = 0, 19 do
			if W.equipped[slot] then worn[#worn + 1] = slot .. "=" .. W.equipped[slot] end
		end
		return table.concat(worn, " ")
	end
	function S.stack()
		local names = {}
		for _, outfit in ipairs(O.OutfitStack.Outfits) do names[#names + 1] = outfit:GetName() or "(yours)" end
		return table.concat(names, " > ")
	end
	function S.saved()
		local names, last = {}, 0
		for key in pairs(env.gOutfitter_Settings.LastOutfitStack) do
			if type(key) == "number" and key > last then last = key end
		end
		for index = 1, last do
			local entry = env.gOutfitter_Settings.LastOutfitStack[index]
			names[#names + 1] = entry == nil and "(gap)" or entry.Name or "(yours)"
		end
		return table.concat(names, " > ")
	end
	-- The player puts on the item in a bag slot
	function S.equip(bagSlot, inventorySlot)
		env.C_Container.PickupContainerItem(0, bagSlot)
		env.PickupInventoryItem(inventorySlot)
		W.Fire("PLAYER_EQUIPMENT_CHANGED", inventorySlot, false)
		W.Fire("UNIT_INVENTORY_CHANGED", "player")
		W.Fire("BAG_UPDATE", 0)
		W.Tick(3)
	end
	-- Something automatic changes outfits: the Battle Stance outfit goes on
	function S.stanceChange()
		local battle = O:GetOutfitByScriptID("Battle")
		Check(battle ~= nil, "a Battle Stance outfit exists")
		if battle then O:WearOutfit(battle) end
		W.Tick(10)
	end
	play(S)
	for _, message in ipairs(W.errors) do Check(false, "Lua error: " .. message:sub(1, 300)) end
	for _, message in ipairs(W.printed or {}) do
		Check(not tostring(message):find("Can't find item", 1, true), "Outfitter looked for an item it shouldn't want: " .. tostring(message))
	end
	return { equipped = W.equipped, bags = W.bags, settings = Plain(env.gOutfitter_Settings),
		global = Plain(env.gOutfitter_GlobalSettings) }
end

-- Starter gear: chest piece, boots, sword and shield. In the bags: a helm, better boots,
-- a ring and a trinket.
local function NewCharacter()
	return {
		equipped = { [5] = 1003, [8] = 1005, [16] = 1008, [17] = 1009 },
		bags = { [0] = { [1] = { id = 1001, count = 1 }, [2] = { id = 1006, count = 1 }, [3] = { id = 1012, count = 1 },
			[4] = { id = 1014, count = 1 } } },
	}
end
local STARTER = "5=1003 8=1005 16=1008 17=1009"
local GEARED = "1=1001 5=1003 8=1006 11=1012 16=1008 17=1009"   -- helm and ring on, boots swapped

----------------------------------------
-- A new character puts on gear as it levels, then reloads
----------------------------------------
local state = Session(NewCharacter(), function(S)
	Check(S.gear() == STARTER, "starts in starter gear (" .. S.gear() .. ")")
	Check(S.stack() == "Normal", "a new character wears Normal, once (" .. S.stack() .. ")")
	Check(S.saved() == "Normal", "and that's what is saved (" .. S.saved() .. ")")
	S.equip(1, 1)    -- a helm, in a slot that was empty
	S.equip(3, 11)   -- a ring, in a slot that was empty
	S.equip(2, 8)    -- better boots
	Check(S.gear() == GEARED, "the new gear is on (" .. S.gear() .. ")")
	Check(S.stack() == "Normal > (yours)", "what you put on yourself sits on top of Normal (" .. S.stack() .. ")")
	Check(S.saved() == "Normal > (yours)", "and is saved in the same place, with no gap (" .. S.saved() .. ")")
end)
state = Session(state, function(S)
	Check(S.gear() == GEARED, "after a reload you're wearing the same (" .. S.gear() .. ")")
	Check(S.stack() == "Normal > (yours)", "and Outfitter remembers what you put on (" .. S.stack() .. ")")
	S.stanceChange()
	Check(S.gear() == GEARED, "an automatic outfit change doesn't take any of it off (" .. S.gear() .. ")")
	Check(S.saved() == S.stack(), "saved and worn stacks agree (" .. S.saved() .. " / " .. S.stack() .. ")")
end)
-- And again, with the stance outfit now in the stack
state = Session(state, function(S)
	Check(S.gear() == GEARED, "a second reload: still the same (" .. S.gear() .. ")")
	S.stanceChange()
	Check(S.gear() == GEARED, "and it stays on (" .. S.gear() .. ")")
	Check(S.saved() == S.stack(), "saved and worn stacks agree (" .. S.saved() .. " / " .. S.stack() .. ")")
end)

----------------------------------------
-- Settings saved by 1.2.1, where what you put on yourself was lost: the stack says
-- Normal (starter gear), and you're wearing more
----------------------------------------
local broken = Session(NewCharacter(), function() end)
broken.equipped = { [1] = 1001, [5] = 1003, [8] = 1006, [11] = 1012, [16] = 1008, [17] = 1009 }
broken.bags = { [0] = { [4] = { id = 1014, count = 1 } } }   -- the old boots were sold
broken.settings.LastOutfitStack = { { Name = "Normal" } }
Session(broken, function(S)
	Check(S.gear() == GEARED, "(logged in wearing the new gear)")
	Check(S.stack() == "Normal > (yours)", "what you're wearing beyond Normal is taken as yours (" .. S.stack() .. ")")
	S.stanceChange()
	Check(S.gear() == GEARED, "nothing comes off, and the boots you sold aren't looked for (" .. S.gear() .. ")")
end)

-- The same, saved with a gap: gear from some earlier session was written past the end of
-- the saved stack. There's no telling how old it is, so it's dropped; what you have on
-- now is what counts.
local gapped = Session(NewCharacter(), function() end)
gapped.equipped = { [1] = 1001, [5] = 1003, [8] = 1005, [16] = 1008, [17] = 1009 }   -- the helm is on
gapped.bags = { [0] = { [2] = { id = 1006, count = 1 }, [3] = { id = 1012, count = 1 }, [4] = { id = 1014, count = 1 } } }
do
	-- (items as Outfitter saves them: Normal's own boots, changed into the helm and the ring)
	local boots
	for _, outfit in ipairs(gapped.settings.Outfits.Complete) do
		if outfit.Name == "Normal" then boots = outfit.Items.FeetSlot end
	end
	local helm, ring = Plain(boots), Plain(boots)
	helm.Code, helm.Name, helm.Link = 1001, "Lion Helm", nil
	ring.Code, ring.Name, ring.Link = 1012, "Band of Might", nil
	-- (written the way the game writes a list with a gap: entry, nil, entry)
	gapped.settings.LastOutfitStack = { { Name = "Normal" }, nil, { Items = { HeadSlot = helm, Finger0Slot = ring } } }
end
Session(gapped, function(S)
	Check(S.stack() == "Normal > (yours)", "the helm you have on is yours (" .. S.stack() .. ")")
	Check(S.saved() == "Normal > (yours)", "and the saved stack has no gap any more (" .. S.saved() .. ")")
	S.stanceChange()
	Check(S.W.equipped[1] == 1001, "the helm stays on")
	Check(S.W.equipped[11] == nil, "the ring from the old entry, which you aren't wearing, isn't put on")
end)

-- Putting gear on above and below an automatic outfit, then that outfit coming off: the
-- two lots of your own gear become one, in the saved stack as well
state = Session(NewCharacter(), function(S)
	S.equip(1, 1)
	S.stanceChange()
	S.equip(3, 11)
	Check(S.stack() == "Normal > (yours) > Warrior: Battle Stance > (yours)", "your gear below and above the stance outfit (" .. S.stack() .. ")")
	Check(S.saved() == S.stack(), "saved the same (" .. S.saved() .. ")")
	S.O:RemoveOutfit(S.O:GetOutfitByScriptID("Battle"))
	S.W.Tick(10)
	Check(S.stack() == "Normal > (yours)", "the stance outfit comes off: one lot of your gear (" .. S.stack() .. ")")
	Check(S.saved() == "Normal > (yours)", "in the saved stack too (" .. S.saved() .. ")")
	Check(S.W.equipped[1] == 1001 and S.W.equipped[11] == 1012, "helm and ring still on")
end)
Session(state, function(S)
	Check(S.stack() == "Normal > (yours)", "after a reload (" .. S.stack() .. ")")
	S.stanceChange()
	Check(S.W.equipped[1] == 1001 and S.W.equipped[11] == 1012, "helm and ring stay on")
end)

----------------------------------------
-- An empty slot at login isn't written down as "nothing here"
----------------------------------------
local bare = Session(NewCharacter(), function() end)
bare.equipped = { [5] = 1003, [16] = 1008, [17] = 1009 }   -- no boots on: they're in the bags
bare.bags = { [0] = { [1] = { id = 1005, count = 1 } } }
Session(bare, function(S)
	Check(S.stack() == "Normal", "a missing item isn't taken as a choice of yours (" .. S.stack() .. ")")
	S.stanceChange()
	Check(S.W.equipped[8] == 1005, "Normal's boots go back on at the next change")
end)

----------------------------------------
-- Outfits you pick still do what they say after a reload
----------------------------------------
state = Session(NewCharacter(), function(S)
	S.equip(1, 1)
	local suit = S.O:FindOutfitByName(S.O.cNakedOutfit)
	Check(suit ~= nil, "the Birthday Suit exists")
	if suit then S.O:WearOutfit(suit) end
	S.W.Tick(10)
	Check(S.gear() == "", "the Birthday Suit takes everything off (" .. S.gear() .. ")")
end)
Session(state, function(S)
	Check(S.gear() == "", "still bare after a reload (" .. S.gear() .. ")")
	Check(S.stack() == S.O.cNakedOutfit, "wearing just the Birthday Suit (" .. S.stack() .. ")")
	local normal = S.O:FindOutfitByName(S.O.cNormalOutfit)
	S.O:WearOutfit(normal)
	S.W.Tick(10)
	Check(S.gear() == STARTER, "and Normal puts the starter gear back on (" .. S.gear() .. ")")
end)

return failures
