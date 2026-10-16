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
	if state.name then -- another character on the same account
		local name = state.name
		local unitName = W.Fakes.UnitName
		W.Fakes.UnitName = function(unit) if unit == "player" then return name, nil end return unitName(unit) end
	end
	W.equipped, W.bags = state.equipped, state.bags
	W.LoadToc("OutfitterForever.toc")
	if state.settings then
		rawset(env, "gOutfitter_Settings", state.settings)
	end
	if state.global then
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
	W.Fire("PLAYER_LOGOUT")
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

----------------------------------------
-- The Display tab: sizes and colours are saved for the account and come back after a
-- reload; a new colour style is used from the next session on
----------------------------------------
local function OpenWindow(S)
	S.W.PlayerTogglesCharacter()
	S.W.Tick(1)
	if not S.env.OutfitterFrame:IsShown() then S.O:ToggleOutfitterFrame() end
	S.W.Tick(0.5)
end
local function ShownOutfitRow(S)
	for index = 0, S.O.cMaxDisplayedItems - 1 do
		local item = S.env["OutfitterItem" .. index]
		if item:IsShown() and not item.isCategory and item:GetOutfit() then return item end
	end
end
state = Session(NewCharacter(), function(S)
	OpenWindow(S)
	local look = S.env.OutfitterFrame.Look
	look.ShowDisplay()
	S.W.Tick(0.2)
	look.Swatches[2]:Click()        -- High contrast
	look.TextSize.Box:SetText("130")
	look.TextSize.Box:GetScript("OnEnterPressed")(look.TextSize.Box)
	look.WindowSize.Slider:SetValue(130)
	look.WindowSize.Slider:GetScript("OnMouseUp")(look.WindowSize.Slider)
	local saved = S.env.gOutfitter_GlobalSettings.Display
	Check(saved.Colors == "contrast" and saved.TextSize == 130 and saved.Scale == 130, "the Display choices are saved for the account")
	Check(S.O.Theme.C.win[1] == 0, "High contrast shows at once")
	look.OwnColors.headings.Hex:SetText("#40C0FF")
	look.OwnColors.headings.Hex:GetScript("OnEnterPressed")(look.OwnColors.headings.Hex)
	Check(S.env.OutfitterFrame:GetScale() == 1.3, "the window size changes straight away")
end)
state = Session(state, function(S)
	OpenWindow(S)
	local C, look = S.O.Theme.C, S.env.OutfitterFrame.Look
	Check(C.win[1] == 0 and C.title[1] == 1 and C.edge[1] == 1, "after a reload the window is in High contrast")
	Check(look.Fill.__color[1] == 0 and look.Fill.__color[2] == 0, "and painted that way")
	local orange = C.orange
	Check(math.abs(orange[1] - 0x40 / 255) < 0.002 and math.abs(orange[3] - 1) < 0.002, "your own heading color is kept too")
	Check(S.env.OutfitterFrame:GetScale() == 1.3, "it keeps its size")
	local row = ShownOutfitRow(S)
	local size = row and select(2, S.env[row:GetName() .. "OutfitName"]:GetFont())
	Check(size and math.abs(size - 12 * 1.3) < 0.01, "and its text size (" .. tostring(size) .. ")")
	-- Light colours: the game's gold outfit names are made dark on the light panel.
	-- And 1.5.0 saved the text size as a word.
	S.env.gOutfitter_GlobalSettings.Display.Colors = "light"
	S.env.gOutfitter_GlobalSettings.Display.TextSize = "large"
end)
state = Session(state, function(S)
	OpenWindow(S)
	local C = S.O.Theme.C
	local row = ShownOutfitRow(S)
	local r, g, b
	if row then r, g, b = S.env[row:GetName() .. "OutfitName"]:GetTextColor() end
	Check(C.win[1] > 0.8 and r == C.title[1] and g == C.title[2] and b == C.title[3],
		"Light colours: outfit names are dark (" .. tostring(r) .. ", " .. tostring(g) .. ", " .. tostring(b) .. ")")
	local look = S.env.OutfitterFrame.Look
	local textSize = row and select(2, S.env[row:GetName() .. "OutfitName"]:GetFont())
	Check(textSize and math.abs(textSize - 12 * 1.15) < 0.01, "1.5.0's Large text is 115% (" .. tostring(textSize) .. ")")
	Check(not look.Header.text.OFKeep or select(1, look.Header.text:GetTextColor()) == C.gold[1], "the header's text stays gold")
	look.ShowDisplay()
	look.DisplayReset:Click()
	Check(next(S.env.gOutfitter_GlobalSettings.Display) == nil, "Reset clears the Display settings")
	Check(S.env.OutfitterFrame:GetScale() == 1, "and the window is its normal size")
	local size = row and select(2, S.env[row:GetName() .. "OutfitName"]:GetFont())
	Check(size == 12, "with normal text")
end)

-- Copy from another character (since 1.8.0): each character's outfits are saved
-- account-wide, and another character copies the ones picked
state = Session(state, function(S)
	local saved = S.env.gOutfitter_GlobalSettings.Characters
	local mine = saved and saved["Tester-Forever"]
	Check(mine and mine.Name == "Tester" and mine.ClassFile == "WARRIOR", "this character's outfits are saved account-wide")
	local fishing = S.O:NewEmptyOutfit("Fishing")
	fishing:AddItem("HeadSlot", S.O:GetItemInfoFromLink(S.W.ItemLink(1001)))
	fishing:SetIcon(134000)
	S.O:AddOutfit(fishing)
	S.O:SetOutfitBindingIndex(fishing, 2)
end)
Check(state.global.Characters["Tester-Forever"] ~= nil, "they're saved at logout")
local alt = NewCharacter()
alt.settings, alt.global, alt.name = nil, state.global, "Alter"
alt = Session(alt, function(S)
	OpenWindow(S)
	local button = S.O.CopyFromButton
	Check(button and button:IsVisible(), "a Copy from... button beside New Outfit")
	if button then
		-- An icon button with its name in the tooltip, clear of the scripts switch's label
		-- (1.8.0's named button covered it)
		Check(button:GetWidth() <= 24 and button.icon and button.icon:GetTexture() ~= nil, "Copy from... is an icon button")
		button:GetScript("OnEnter")(button)
		local lines = S.env.GameTooltip.__lines or {}
		Check(lines[1] == S.O.cCopyFrom, "its tooltip names it (got " .. tostring(lines[1]) .. ")")
		button:GetScript("OnLeave")(button)
		local scripts = S.env.OutfitterFrame.Look.Scripts
		local anchored = false
		for _, point in ipairs(scripts.label.__points) do if point[2] == button then anchored = true end end
		Check(anchored and 256 - 7 - S.env.OutfitterNewButton:GetWidth() - 6 - button:GetWidth() - 4 - 44 >= 70,
			"the footer's buttons leave the scripts switch's label room (70 wide), and it ends at the icon")
	end
	local others = S.O:GetOtherCharacters()
	Check(#others == 1 and others[1].Key == "Tester-Forever", "the other character is listed, not this one (" .. #others .. ")")
	if not button then return end
	button:Click()
	S.W.Tick(0.5)
	local dialog = S.env.OutfitterForeverCopyDialog
	Check(dialog and dialog:IsShown() and dialog.Key == "Tester-Forever", "it opens on the other character")
	if not (dialog and dialog.Key) then return end
	local fishingRow, normalRow
	for _, row in ipairs(dialog.Rows) do
		if row:IsShown() and row.outfit and row.outfit.Name == "Fishing" then fishingRow = row end
		if row:IsShown() and row.outfit and row.outfit.Name ~= "Fishing" and not normalRow then normalRow = row end
	end
	Check(fishingRow and fishingRow.switch:IsOn(), "with its outfits, all picked")
	Check(normalRow ~= nil, "including its other outfits")
	-- Untick all but Fishing
	for _, row in ipairs(dialog.Rows) do
		if row:IsShown() and row.outfit and row ~= fishingRow then row:Click() end
	end
	Check(dialog.Count == 1 and dialog.CopyButton:GetText() == string.format(S.O.cCopyFromCopy, 1), "the Copy button counts the picks")
	-- This character has a Fishing outfit too: the copy is "Fishing 2"
	S.O:AddOutfit(S.O:NewEmptyOutfit("Fishing"))
	dialog.CopyButton:Click()
	S.W.Tick(0.5)
	Check(not dialog:IsShown(), "Copy closes the dialog")
	local copy = S.O:FindOutfitByName("Fishing 2")
	Check(copy and copy:GetItem("HeadSlot") and copy:GetItem("HeadSlot").Code == 1001, "the copy keeps its gear, under a new name")
	Check(copy and copy:GetIcon() == 134000, "and its icon")
	Check(copy and copy.BindingIndex == nil, "but not the other character's key binding")
	Check(S.O:FindOutfitByName("Fishing") ~= copy, "this character's own Fishing outfit is left as it was")
end)
Check(alt.global.Characters["Alter-Forever"] and alt.global.Characters["Tester-Forever"], "both characters are saved")

return failures
