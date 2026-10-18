-- The scenarios. Loaded fresh for each expansion level by tests/run.lua.
local expansionLevel, projectId = ...

-- Each run gets a clean client
_G.W = nil
local W = dofile("tests/wow.lua")
W.expansionLevel = expansionLevel
W.projectId = projectId
dofile("tests/fakes.lua")
local env = W.env

local failures = 0
local currentStep = "start"
local function Fail(message)
	failures = failures + 1
	print(string.format("FAIL [LE %d, project %d] %s: %s", expansionLevel, projectId or 18, currentStep, message))
end
local function Check(condition, message)
	if not condition then Fail(message) end
	return condition
end
local reportedErrors = 0
local function NoErrors()
	for i = reportedErrors + 1, #W.errors do
		Fail("Lua error: " .. W.errors[i])
	end
	reportedErrors = #W.errors
	W.uiErrors = {}
end
local function Step(name)
	NoErrors()
	currentStep = name
end

----------------------------------------
-- A warrior with gear on and spares in the bags
----------------------------------------
W.equipped = { [1] = 1001, [5] = 1003, [8] = 1005, [11] = 1012, [13] = 1014, [16] = 1008, [17] = 1009, [18] = 1010 }
W.bags = {
	[0] = { [1] = { id = 1002, count = 1 }, [2] = { id = 1004, count = 1 }, [3] = { id = 1006, count = 1 },
		[4] = { id = 1007, count = 1 }, [5] = { id = 1011, count = 1 }, [6] = { id = 1013, count = 1 },
		[7] = { id = 1015, count = 1 }, [8] = { id = 1016, count = 20 } },
}

-- Baganator, a bag addon that groups gear by equipment set. It's there before
-- Outfitter loads in half the runs, and loads after it in the other half.
local baganator = { sources = {}, refreshes = 0 }
local function InstallBaganator()
	rawset(env, "Baganator", { API = {
		RegisterItemSetSource = function(label, id, getItemSetInfo, getAllSetNames)
			assert(type(label) == "string" and type(id) == "string" and type(getItemSetInfo) == "function"
				and (getAllSetNames == nil or type(getAllSetNames) == "function"), "bad arguments to RegisterItemSetSource")
			table.insert(baganator.sources, { label = label, id = id, get = getItemSetInfo, names = getAllSetNames })
		end,
		RequestItemButtonsRefresh = function() baganator.refreshes = baganator.refreshes + 1 end,
	} })
end
local baganatorFirst = projectId == 1
if baganatorFirst then InstallBaganator() end

Step("load the addon")
W.LoadToc("OutfitterForever.toc")
NoErrors()
Check(env.Outfitter ~= nil, "Outfitter global exists")
Check(env.Outfitter.IsForever == true, "detected Forever")
Check(env.Outfitter.IsMainline == true, "Forever is a Mainline client")
Check(env.Outfitter.IsRetail == false, "Forever isn't retail gameplay")

Step("log in")
W.Fire("ADDON_LOADED", W.addonName)
W.Fire("VARIABLES_LOADED")
W.loggedIn = true
W.Fire("PLAYER_LOGIN")
W.Fire("PLAYER_ENTERING_WORLD", true, false)
W.Fire("BAG_UPDATE", 0)
W.Fire("UNIT_INVENTORY_CHANGED", "player")
W.Tick(3)
Check(env.Outfitter.Initialized, "Outfitter initialized")
Check(env.Outfitter.cSlotIDs and env.Outfitter.cSlotIDs.RangedSlot == 18, "the ranged slot is managed")
Check(env.Outfitter.cInvTypeToSlotName.INVTYPE_RANGED.SlotName == "RangedSlot", "bows go in the ranged slot")

local O = env.Outfitter

----------------------------------------
Step("the button and window sit beside Forever's character window")
local function AnchoredTo(frame, target)
	for _, point in ipairs(frame.__points) do
		if point[2] == target then return true end
	end
	return false
end
Check(AnchoredTo(env.OutfitterButton, env.CharacterFrame.RightPaneToggleButton), "Outfitter button sits by the stats pane arrow")
Check(AnchoredTo(env.OutfitterFrame, env.CharacterFrameModeTab1), "Outfitter window opens right of the character tabs")
Check(env.OutfitterEnableRangedSlot ~= nil, "the ranged slot has an outfit checkbox")
Check(env.OutfitterEnableRangedSlot and env.OutfitterEnableRangedSlot.SlotName == "RangedSlot", "the checkbox is for the ranged slot")

----------------------------------------
Step("open the character window and Outfitter")
W.PlayerTogglesCharacter()
O:ToggleOutfitterFrame()
W.Tick(1)
Check(env.OutfitterFrame:IsVisible(), "Outfitter window is open")
for panel = 1, 2 do
	O:ShowPanel(panel)
	W.Tick(0.2)
end

----------------------------------------
Step("it's Outfitter Forever everywhere, and there's no About tab")
Check(O.cTitle == "Outfitter Forever", "the name is Outfitter Forever (is " .. tostring(O.cTitle) .. ")")
Check(env.OutfitterFrameTitle:GetText() == "Outfitter Forever " .. tostring(O.cVersion), "window title (is " .. tostring(env.OutfitterFrameTitle:GetText()) .. ")")
Check(env.BINDING_HEADER_OUTFITTER_TITLE == "Outfitter Forever", "keybindings group")
Check(env.OutfitterFrameTab1 ~= nil and env.OutfitterFrameTab2 ~= nil, "Outfits and Options tabs")
Check(env.OutfitterFrameTab3 == nil, "no third tab")
Check(env.OutfitterAboutFrame == nil, "no About panel")
Check(#O.cPanelFrames == 2, "two panels")
Check(O.cAboutTitle == nil and O._AboutView == nil, "the About code is gone")
do
	local printedBefore = #W.printed
	O:NoteMessage("hello")
	local said = tostring(W.printed[#W.printed])
	Check(#W.printed > printedBefore
		and said:find("|TInterface\\AddOns\\OutfitterForever\\Textures\\Logo:0|t |cffe8a040Outfitter Forever|r: ", 1, true) == 1,
		"chat messages start with the logo and Outfitter Forever (said: " .. said .. ")")
	O:ErrorMessage("oops")
	said = tostring(W.printed[#W.printed])
	Check(said:find("[ERROR]", 1, true) ~= nil and said:find("Outfitter Forever|r: ", 1, true) ~= nil and said:find("oops", 1, true) ~= nil,
		"an error line keeps its [ERROR] mark (said: " .. said .. ")")
end

----------------------------------------
Step("the window has the shared look: dark panel, red header bar with the logo")
do
	local frame, look = env.OutfitterFrame, env.OutfitterFrame.Look
	Check(look ~= nil, "the look was applied")
	if look then
		local header = look.Header
		Check(header:IsVisible(), "the header bar shows with the window")
		Check(header.logo:GetTexture() == "Interface\\AddOns\\OutfitterForever\\Textures\\Logo", "the header bar has the logo")
		Check(header.text:GetText() == "Outfitter Forever " .. tostring(O.cVersion), "then the name and version (is " .. tostring(header.text:GetText()) .. ")")
		Check(not env.OutfitterFrameTitle:IsShown(), "the old title is hidden (the header shows it)")
		Check(not env.OutfitterCloseButton:IsShown(), "the game's round close button is hidden")
		for name, piece in pairs(frame.Background) do
			Check(not piece:IsShown(), "the original frame art is hidden (" .. tostring(name) .. ")")
		end
		Check(look.Fill:IsShown(), "a flat panel is behind the window")
		for _, part in ipairs({ "Top", "Middle", "Bottom" }) do
			Check(not env["OutfitterMainFrameScrollbarTrench" .. part]:IsShown(), "the scroll track's stone art is hidden (" .. part .. ")")
		end
		Check(look.Track and look.Track:IsShown() and look.Track:GetParent() == env.OutfitterMainFrameScrollbarTrench,
			"the scroll track is a flat strip instead")
		-- The X closes Outfitter's window only; the character window is the player's to close
		look.Close:Click()
		Check(not frame:IsShown(), "the X in the header closes Outfitter")
		Check(env.CharacterFrame:IsShown(), "and leaves the character window open")
		O:ToggleOutfitterFrame()
		W.Tick(0.2)
		Check(frame:IsVisible(), "Outfitter opens again")
		Check(header:IsVisible() and not env.OutfitterCloseButton:IsShown() and not env.OutfitterFrameTitle:IsShown(),
			"with the same look")
		O:ApplyLook()
		Check(frame.Look == look, "applying the look twice changes nothing")
	end
end
NoErrors()
local logo = "Interface\\AddOns\\OutfitterForever\\Textures\\Logo"
Check(env.OutfitterMinimapButton.CurrentOutfitTexture:GetTexture() == logo,
	"the minimap button shows the Outfitter Forever logo (shows " .. tostring(env.OutfitterMinimapButton.CurrentOutfitTexture:GetTexture()) .. ")")
Check(env.OutfitterMinimapButton:GetNormalTexture() == nil, "with no other art under it")
O:UpdateCurrentOutfitIcon()
W.Tick(0.5)
Check(env.OutfitterMinimapButton.CurrentOutfitTexture:GetTexture() == logo, "and keeps showing it whatever outfit is on")
do
	-- The data broker shows the worn outfit's icon (the logo when none is worn)
	local _, worn = O:GetCurrentOutfitInfo()
	local expected = worn and O.OutfitBar:GetOutfitTexture(worn) or logo
	Check(O.LDB.DataObj.icon == expected, "the data broker icon is the worn outfit's icon (" .. tostring(O.LDB.DataObj.icon) .. ")")
end
O:ShowPanel(1)
O:Update(true)
W.Tick(0.5)

----------------------------------------
-- Outfits made of specific items
local function MakeOutfit(name, items)
	local outfit = O:NewEmptyOutfit(name)
	for slotName, itemID in pairs(items) do
		outfit:AddItem(slotName, itemID and O:GetItemInfoFromLink(W.ItemLink(itemID)) or nil)
	end
	O:AddOutfit(outfit)
	return outfit
end

Step("save the current gear as an outfit")
local battle = O:GetInventoryOutfit("Battle Gear")
O:AddOutfit(battle)
Check(battle:GetItem("RangedSlot") and battle:GetItem("RangedSlot").Code == 1010, "the bow is part of the outfit")
Check(battle:GetItem("HeadSlot") and battle:GetItem("HeadSlot").Code == 1001, "the helm is part of the outfit")

Step("wear a fishing outfit")
local fishing = MakeOutfit("Fishing", { HeadSlot = 1002, MainHandSlot = 1011, FeetSlot = 1006 })
O:WearOutfit(fishing)
W.Tick(3)
Check(W.equipped[1] == 1002, "fishing hat on (head has " .. tostring(W.equipped[1]) .. ")")
Check(W.equipped[16] == 1011, "fishing pole in hand (main hand has " .. tostring(W.equipped[16]) .. ")")
do
	local _, worn = O:GetCurrentOutfitInfo()
	Check(worn == fishing and O.LDB.DataObj.icon == O.OutfitBar:GetOutfitTexture(fishing) and O.LDB.DataObj.icon ~= logo,
		"the data broker switches to the fishing outfit's icon (" .. tostring(O.LDB.DataObj.icon) .. ")")
	Check(O.LDB.DataObj.text == fishing:GetName(), "and its name")
	Check(env.OutfitterMinimapButton.CurrentOutfitTexture:GetTexture() == logo, "the minimap button keeps the logo")
end
Check(W.equipped[8] == 1006, "riding boots on")
Check(W.equipped[17] == nil, "shield put away for the two-hander")
Check(W.equipped[18] == 1010, "bow left alone")
Check(W.equipped[5] == 1003, "chest left alone")

Step("take the fishing outfit off")
O:RemoveOutfit(fishing)
W.Tick(3)
Check(W.equipped[1] == 1001, "helm back on (head has " .. tostring(W.equipped[1]) .. ")")
Check(W.equipped[16] == 1008 and W.equipped[17] == 1009, "sword and shield back")
Check(W.equipped[8] == 1005, "boots back")

Step("an outfit can swap the ranged slot")
local wand = MakeOutfit("Wand", { RangedSlot = 1015 })
O:WearOutfit(wand)
W.Tick(3)
Check(W.equipped[18] == 1015, "wand in the ranged slot (has " .. tostring(W.equipped[18]) .. ")")
O:RemoveOutfit(wand)
W.Tick(3)
Check(W.equipped[18] == 1010, "bow back in the ranged slot (has " .. tostring(W.equipped[18]) .. ")")

Step("an outfit can change the ammo, which stays in the bags")
Check(O.cSlotIDs.AmmoSlot == 0 and O.cInvTypeToSlotName.INVTYPE_AMMO.SlotName == "AmmoSlot", "the ammo slot is managed")
Check(env.OutfitterEnableAmmoSlot and env.OutfitterEnableAmmoSlot.SlotName == "AmmoSlot", "the ammo slot has an outfit checkbox")
do
	local arrows, shot = W.FreeBagSlot()
	W.bags[arrows.bag] = W.bags[arrows.bag] or {}
	W.bags[arrows.bag][arrows.bagSlot] = { id = 1017, count = 200 }
	shot = W.FreeBagSlot()
	W.bags[shot.bag] = W.bags[shot.bag] or {}
	W.bags[shot.bag][shot.bagSlot] = { id = 1018, count = 200 }
	W.equipped[0] = 1017
	W.Fire("BAG_UPDATE", 0)
	W.Fire("UNIT_INVENTORY_CHANGED", "player")
	W.Tick(3)
	local gun = MakeOutfit("Bullets", { AmmoSlot = 1018 })
	O:WearOutfit(gun)
	W.Tick(3)
	Check(W.equipped[0] == 1018, "bullets in the ammo slot (has " .. tostring(W.equipped[0]) .. ")")
	Check(W.bags[shot.bag][shot.bagSlot] and W.bags[shot.bag][shot.bagSlot].id == 1018, "the bullets stay in the bags")
	Check(W.bags[arrows.bag][arrows.bagSlot] and W.bags[arrows.bag][arrows.bagSlot].id == 1017, "the arrows stay in the bags")
	O:RemoveOutfit(gun)
	W.Tick(3)
	Check(W.equipped[0] == 1017, "arrows back in the ammo slot (has " .. tostring(W.equipped[0]) .. ")")
	local naked = MakeOutfit("No ammo", { AmmoSlot = false })
	naked:AddItem("AmmoSlot", nil)
	O:WearOutfit(naked)
	W.Tick(3)
	Check(W.equipped[0] == 1017, "an outfit with an empty ammo slot leaves the ammo alone")
	O:RemoveOutfit(naked)
	W.Tick(3)
	Check(#W.uiErrors == 0 or not tostring(W.uiErrors[#W.uiErrors]):find("Ammo"), "no ammo errors (" .. tostring(W.uiErrors[#W.uiErrors]) .. ")")
	O:DeleteOutfit(gun)
	O:DeleteOutfit(naked)
	W.Tick(1)
end

Step("wear the saved outfit")
O:WearOutfit(fishing)
W.Tick(3)
O:WearOutfit(battle)
W.Tick(3)
Check(W.equipped[1] == 1001 and W.equipped[16] == 1008 and W.equipped[17] == 1009 and W.equipped[18] == 1010, "back in battle gear")

----------------------------------------
Step("combat: no errors from hidden auras, health and mana")
W.combat = true
W.Fire("PLAYER_REGEN_DISABLED")
W.auras = { { name = "Battle Shout", icon = 132333, spellId = 6673 } }
W.Fire("UNIT_AURA", "player")
W.Fire("UNIT_HEALTH", "player")
W.Fire("UNIT_MANA", "player")
W.Fire("UNIT_SPELLCAST_SENT", "player", "Heroic Strike")
W.Fire("UNIT_MANA", "player")
W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Heroic Strike")
W.Tick(1)
local function CombatNotes()
	local count = 0
	for _, line in ipairs(W.printed) do
		if tostring(line):find((O.cCombatWait:gsub("^%%s", "")), 1, true) then count = count + 1 end
	end
	return count
end
local function BrokerTooltipHas(text)
	O:ShowBrokerTooltip(env.UIParent)
	for _, line in ipairs(env.GameTooltip.__lines or {}) do
		if line == text then return true end
	end
	return false
end
local function ListWatch(outfit)
	O.DisplayIsDirty = true
	O:Update(false)
	for index = 0, O.cMaxDisplayedItems - 1 do
		local row = env["OutfitterItem" .. index]
		if row and row:IsShown() and row.Look and row.Look.Wait.Outfit == outfit then
			return row.Look.Wait:IsShown()
		end
	end
end
local notesBefore = CombatNotes()
local printedBefore = #W.printed
O:WearOutfit(fishing)
W.Tick(1)
Check(W.equipped[1] == 1001, "armor isn't changed in combat")
Check(W.equipped[16] == 1011, "but weapons are: the fishing pole is in hand at once (main hand has " .. tostring(W.equipped[16]) .. ")")
Check(W.equipped[17] == nil, "and the game put the shield away for the two-hander")
Check(#W.printed == printedBefore, "nothing is said in chat (" .. tostring(W.printed[#W.printed]) .. ")")
Check(O:OutfitWaitsForCombat(fishing), "the outfit waits for combat to end")
Check(BrokerTooltipHas(string.format(O.cCombatWait, fishing:GetName())), "the broker's tooltip says the outfit's gear changes when combat ends")
env.OutfitterFrame:Show()
W.Tick(0.2)
Check(ListWatch(fishing) == true, "the outfit list shows a pocket watch on the waiting outfit")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Tick(3)
Check(W.equipped[1] == 1002, "the outfit goes on after combat (head has " .. tostring(W.equipped[1]) .. ")")
Check(ListWatch(fishing) == false, "and the pocket watch goes")
Check(not BrokerTooltipHas(string.format(O.cCombatWait, fishing:GetName())), "and so does the tooltip line")
Check(CombatNotes() == notesBefore, "never a chat line")
-- Back from a two-hander to sword and shield in combat: both come out of the bags
-- (the game won't let an addon pick up what you're wearing in combat)
do
	W.combat = true
	W.Fire("PLAYER_REGEN_DISABLED")
	O:WearOutfit(battle)
	W.Tick(1)
	Check(W.equipped[16] == 1008 and W.equipped[17] == 1009,
		"sword and shield go on in combat (hands have " .. tostring(W.equipped[16]) .. ", " .. tostring(W.equipped[17]) .. ")")
	Check(W.equipped[1] == 1002, "the hat stays on until combat ends")
	W.combat = false
	W.Fire("PLAYER_REGEN_ENABLED")
	W.Tick(3)
	Check(W.equipped[1] == 1001, "then the helm goes on")
end
-- An outfit of only weapons doesn't wait, so nothing is said
do
	local blade = MakeOutfit("Blade", { MainHandSlot = 1008 })
	W.combat = true
	W.Fire("PLAYER_REGEN_DISABLED")
	local notes = CombatNotes()
	O:WearOutfit(blade)
	W.Tick(1)
	Check(W.equipped[16] == 1008, "a weapons-only outfit goes on in combat (main hand has " .. tostring(W.equipped[16]) .. ")")
	Check(CombatNotes() == notes, "with no chat line")
	O:RemoveOutfit(blade)
	W.Tick(1)
	W.combat = false
	W.Fire("PLAYER_REGEN_ENABLED")
	W.Tick(3)
	O:DeleteOutfit(blade)
	W.Tick(1)
end
-- Scripts (stances, forms) change outfits in every fight: they say nothing
W.combat = true
W.Fire("PLAYER_REGEN_DISABLED")
O:RemoveOutfit(fishing, true)
O:WearOutfit(fishing, nil, true)
W.Tick(1)
Check(CombatNotes() == notesBefore, "an outfit a script changes in combat gets no chat line")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Tick(3)
O:WearOutfit(battle)
W.Tick(3)

----------------------------------------
Step("warrior stance outfits use the three classic stances")
local defensive = O:GetOutfitByScriptID("Defensive")
Check(defensive ~= nil, "a Defensive Stance outfit exists")
if defensive then
	defensive:AddItem("MainHandSlot", O:GetItemInfoFromLink(W.ItemLink(1008)))
	defensive:AddItem("HeadSlot", O:GetItemInfoFromLink(W.ItemLink(1002)))
	O:SetScriptEnabled(defensive, true)
	O:ActivateScript(defensive)
	W.Tick(1)
	W.player.form = 2
	W.Fire("UPDATE_SHAPESHIFT_FORM")
	W.Fire("UNIT_AURA", "player")
	W.Tick(3)
	Check(W.equipped[1] == 1002, "Defensive Stance (form 2) puts on its outfit (head has " .. tostring(W.equipped[1]) .. ")")
	W.player.form = 1
	W.Fire("UPDATE_SHAPESHIFT_FORM")
	W.Fire("UNIT_AURA", "player")
	W.Tick(3)
	Check(W.equipped[1] == 1001, "Battle Stance (form 1) takes it off")
end

----------------------------------------
Step("a script with a broken $SETTING line gets a message, not a Lua error")
do
	local broken = {
		{ "-- $SETTING Foo={label=\"Foo\"}", "a setting with no type" },
		{ "-- $SETTING Foo={type=5, label=\"Foo\"}", "a setting whose type isn't text" },
		{ "-- $SETTING Foo=5", "a setting that's a number" },
		{ "-- $SETTING Foo=nil+1", "a setting that throws when it's read" },
	}
	for _, case in ipairs(broken) do
		local errorsBefore = #W.errors
		local ok, fields, message = W.SafeCall(O.ParseScriptFields, O, "-- $EVENTS TIMER\n" .. case[1] .. "\n")
		Check(ok and #W.errors == errorsBefore, case[2] .. ": no Lua error")
		Check(fields == nil and type(message) == "string" and message ~= "", case[2] .. ": a message saying what's wrong (" .. tostring(message) .. ")")
		reportedErrors = #W.errors
	end
	-- Good settings still parse
	local fields = O:ParseScriptFields("-- $SETTING Loot={type=\"boolean\", label=\"Auto loot\"}\n-- $SETTING Bar=\"number\"\n")
	Check(fields and fields.Inputs and #fields.Inputs == 2, "good settings still parse")
	-- An outfit with a broken script doesn't stop the others' scripts from starting
	local bad = MakeOutfit("Broken settings", { HeadSlot = 1002 })
	bad.Script = "-- $EVENTS TIMER\n-- $SETTING Foo=nil+1\n"
	local errorsBefore = #W.errors
	W.SafeCall(O.ActivateScript, O, bad)
	Check(#W.errors == errorsBefore, "activating it is no Lua error")
	local said = tostring(W.printed[#W.printed - 1]) .. " / " .. tostring(W.printed[#W.printed])
	Check(said:find("Broken settings", 1, true) ~= nil and said:find("nil value", 1, true) ~= nil,
		"and chat says which outfit's script didn't start, and why (" .. said .. ")")
	O:DeleteOutfit(bad)
	reportedErrors = #W.errors
end

----------------------------------------
Step("scripts that read hidden values don't error")
local lowHealth = MakeOutfit("Low Health", { HeadSlot = 1002 })
O:SetScriptID(lowHealth, "LOW_HEALTH")
lowHealth.ScriptSettings = { Health = 1000, Mana = 100 }
O:SetScriptEnabled(lowHealth, true)
O:ActivateScript(lowHealth)
W.Fire("UNIT_HEALTH", "player")
W.Fire("UNIT_MANA", "player")
W.Tick(1)
Check(W.equipped[1] == 1001, "nothing changes when health is hidden")

local hasBuff = MakeOutfit("Buffed", { FeetSlot = 1006 })
O:SetScriptID(hasBuff, "HAS_BUFF")
hasBuff.ScriptSettings = { buffName = "Battle Shout" }
O:SetScriptEnabled(hasBuff, true)
O:ActivateScript(hasBuff)
W.combat = true
W.Fire("UNIT_AURA", "player")
W.Tick(1)
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Fire("UNIT_AURA", "player")
W.Tick(3)
Check(W.equipped[8] == 1006, "Has Buff outfit goes on out of combat (feet have " .. tostring(W.equipped[8]) .. ")")
W.auras = {}
W.Fire("UNIT_AURA", "player")
W.Tick(3)

local onTarget = MakeOutfit("Target", { FeetSlot = 1006 })
O:SetScriptID(onTarget, "EQUIP_ON_TARGET")
onTarget.ScriptSettings = { targetName = "Hogger" }
O:SetScriptEnabled(onTarget, true)
O:ActivateScript(onTarget)
W.target = nil
W.Fire("PLAYER_TARGET_CHANGED")
W.target = W.Secret("Hogger")
W.Fire("PLAYER_TARGET_CHANGED")
W.target = "Hogger"
W.Fire("PLAYER_TARGET_CHANGED")
W.Tick(3)
Check(W.equipped[8] == 1006, "Equip on target works with a readable name")

local function StopScript(outfit)
	O:SetScriptEnabled(outfit, false)
	O:RemoveOutfit(outfit)
	W.Tick(3)
end
StopScript(onTarget)
StopScript(hasBuff)
StopScript(lowHealth)
W.target = nil

----------------------------------------
Step("aura outfits keep their state when auras can't be read")
W.auras = { { name = "Battle Shout", icon = 132333, spellId = 6673 } }
O:SetScriptEnabled(hasBuff, true)
O:ActivateScript(hasBuff)
W.Fire("UNIT_AURA", "player")
W.Tick(3)
Check(W.equipped[8] == 1006, "Has Buff outfit on (feet have " .. tostring(W.equipped[8]) .. ")")
W.combat = true
W.Fire("PLAYER_REGEN_DISABLED")
W.Fire("UNIT_AURA", "player")
W.Tick(1)
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Tick(3)
Check(W.equipped[8] == 1006, "Has Buff outfit stays on through combat (feet have " .. tostring(W.equipped[8]) .. ")")
W.auras = {}
W.Fire("UNIT_AURA", "player")
W.Tick(3)
Check(W.equipped[8] == 1005, "Has Buff outfit comes off when the buff ends (feet have " .. tostring(W.equipped[8]) .. ")")
StopScript(hasBuff)

local hasDebuff = MakeOutfit("Debuffed", { FeetSlot = 1006 })
O:SetScriptID(hasDebuff, "HAS_DEBUFF")
hasDebuff.ScriptSettings = { debuffName = "Hamstring" }
O:SetScriptEnabled(hasDebuff, true)
O:ActivateScript(hasDebuff)
W.auras = { { name = "Hamstring", icon = 132316, spellId = 1715 } } -- a buff with that name doesn't count
W.Fire("UNIT_AURA", "player")
W.Tick(3)
Check(W.equipped[8] == 1005, "Has Debuff ignores buffs")
W.auras = { { name = "Hamstring", icon = 132316, spellId = 1715, harmful = true } }
W.Fire("UNIT_AURA", "player")
W.Tick(3)
Check(W.equipped[8] == 1006, "Has Debuff outfit on with the debuff (feet have " .. tostring(W.equipped[8]) .. ")")
W.auras = {}
W.Fire("UNIT_AURA", "player")
W.Tick(3)
Check(W.equipped[8] == 1005, "Has Debuff outfit off when it ends")
StopScript(hasDebuff)

----------------------------------------
Step("dining with hidden health")
local dining = MakeOutfit("Dining", { HeadSlot = 1002 })
O:SetScriptID(dining, "Dining")
O:SetScriptEnabled(dining, true)
O:ActivateScript(dining)
Check(O.IsSecret(env.UnitHealth("player")), "the test client hides your health")
W.auras = { { name = "Food", icon = 134062, spellId = 433 } }
W.Fire("UNIT_AURA", "player")
W.Fire("UNIT_HEALTH", "player")
W.Tick(3)
Check(W.equipped[1] == 1002, "Dining outfit on while eating (head has " .. tostring(W.equipped[1]) .. ")")
-- Buffs can't be read in combat; the outfit keeps its last state
W.combat = true
W.Fire("PLAYER_REGEN_DISABLED")
W.Fire("UNIT_AURA", "player")
W.Tick(3) -- Outfitter re-reads auras 2 seconds after a change in combat
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Tick(3)
Check(W.equipped[1] == 1002, "a buff outfit stays on through combat (head has " .. tostring(W.equipped[1]) .. ")")
W.auras = {}
W.Fire("UNIT_AURA", "player")
W.Tick(3)
Check(W.equipped[1] == 1001, "Dining outfit off when the food buff ends")
StopScript(dining)

----------------------------------------
Step("cooking, fish tracking and helm display")
local cooking = MakeOutfit("Chef", { HeadSlot = 1002 })
O:SetScriptID(cooking, "COOKING")
O:SetScriptEnabled(cooking, true)
O:ActivateScript(cooking)
W.tradeSkill = { professionID = 185, sourceCounter = 0, professionName = "Cooking", expansionName = "", skillLevel = 100,
	maxSkillLevel = 150, skillModifier = 0, isPrimaryProfession = false }
W.Fire("TRADE_SKILL_SHOW")
W.Tick(3)
Check(W.equipped[1] == 1002, "chef's hat on with the Cooking window (head has " .. tostring(W.equipped[1]) .. ")")
W.Fire("TRADE_SKILL_CLOSE")
W.Tick(3)
Check(W.equipped[1] == 1001, "chef's hat off when it closes")
W.tradeSkill = { professionID = 164, sourceCounter = 0, professionName = "Blacksmithing", expansionName = "", skillLevel = 100,
	maxSkillLevel = 150, skillModifier = 0, isPrimaryProfession = true }
W.Fire("TRADE_SKILL_SHOW")
W.Tick(3)
Check(W.equipped[1] == 1001, "other trade skills leave it alone")
W.Fire("TRADE_SKILL_CLOSE")
W.tradeSkill = nil
StopScript(cooking)

local fisher = MakeOutfit("Angler", { MainHandSlot = 1011 })
O:SetScriptID(fisher, "Fishing")
O:SetScriptEnabled(fisher, true)
O:ActivateScript(fisher)
O:WearOutfit(fisher)
W.Tick(3)
Check(W.tracking[2].active == true, "Find Fish is turned on with the fishing outfit")
O:RemoveOutfit(fisher)
W.Tick(3)
Check(W.tracking[2].active == false, "Find Fish goes back off")
StopScript(fisher)

local bareHead = MakeOutfit("Bare head", { HeadSlot = 1002 })
bareHead.ShowHelm = false
O:WearOutfit(bareHead)
W.Tick(3)
Check(W.showHelm == false, "an outfit can hide the helm")
O:RemoveOutfit(bareHead)
W.Tick(3)
O:DeleteOutfit(bareHead)
W.Tick(1)

----------------------------------------
Step("menus and dialogs open")
O:OpenUI()
W.Tick(0.5)
O:ShowPanel(2)
W.Tick(0.2)
O:ShowPanel(1)
if O.OpenEditScriptDialog then
	O:OpenEditScriptDialog(defensive)
	W.Tick(0.5)
end

----------------------------------------
Step("slash commands")
O:WearOutfit(battle)
W.Tick(3)
env.SlashCmdList.OUTFITTER("wear Fishing")
W.Tick(3)
Check(W.equipped[1] == 1002, "/outfitter wear Fishing")
env.SlashCmdList.OUTFITTER("unwear Fishing")
W.Tick(3)
Check(W.equipped[1] == 1001, "/outfitter unwear Fishing")
env.SlashCmdList.OUTFITTER("toggle Wand")
W.Tick(3)
Check(W.equipped[18] == 1015, "/outfitter toggle Wand puts it on")
env.SlashCmdList.OUTFITTER("toggle Wand")
W.Tick(3)
Check(W.equipped[18] == 1010, "/outfitter toggle Wand takes it off")
env.SlashCmdList.OUTFITTER("")
env.SlashCmdList.OUTFITTER("help")
W.Tick(0.5)

----------------------------------------
Step("minimap button menu")
Check(env.OutfitterMinimapButton ~= nil, "minimap button exists")
if env.OutfitterMinimapButton then
	local onMouseUp = env.OutfitterMinimapButton:GetScript("OnMouseUp") or env.OutfitterMinimapButton:GetScript("OnClick")
	Check(onMouseUp ~= nil, "minimap button responds to clicks")
	if onMouseUp then
		W.SafeCall(onMouseUp, env.OutfitterMinimapButton, "LeftButton")
		W.Tick(0.5)
		W.SafeCall(onMouseUp, env.OutfitterMinimapButton, "LeftButton")
		W.SafeCall(onMouseUp, env.OutfitterMinimapButton, "RightButton")
		W.Tick(0.5)
	end
end

----------------------------------------
Step("item tooltips list the outfits that use the item")
Check(W.tooltipPostCalls ~= nil and #W.tooltipPostCalls > 0, "tooltip hook installed")
for _, hook in ipairs(W.tooltipPostCalls or {}) do
	env.GameTooltip:SetOwner(env.UIParent, "ANCHOR_NONE")
	env.GameTooltip:SetBagItem(0, 1)
	W.SafeCall(hook, env.GameTooltip, { type = 0, id = 1001 })
	env.GameTooltip:SetOwner(env.UIParent, "ANCHOR_NONE")
	env.GameTooltip:SetInventoryItem("player", 1)
	W.SafeCall(hook, env.GameTooltip, { type = 0, id = 1001 })
end
env.GameTooltip:SetOwner(env.UIParent, "ANCHOR_NONE")
env.GameTooltip:SetBagItem(0, 3)
env.GameTooltip:Show()
env.ShoppingTooltip1:SetInventoryItem("player", 8)
W.globalStrings.EQUIPMENT_SETS = "Equipment Sets: |cFFFFFFFF%s|r"
env.ShoppingTooltip2:ClearLines()
env.ShoppingTooltip2:Hide()
W.SafeCall(env.GameTooltip_ShowCompareItem, env.GameTooltip)
do
	-- The comparison tooltip shows the boots you're wearing: it lists the outfits that
	-- use those boots, not the outfits that use the item under the mouse
	local function Lines(tooltip) return table.concat(tooltip.__lines or {}, " / ") end
	Check(battle:GetItem("FeetSlot") and battle:GetItem("FeetSlot").Code == 1005, "(Battle Gear uses the worn boots)")
	Check(Lines(env.ShoppingTooltip1):find("Battle Gear", 1, true) ~= nil,
		"the comparison tooltip lists the outfits using the worn item (lines: " .. Lines(env.ShoppingTooltip1) .. ")")
	Check(Lines(env.ShoppingTooltip2) == "" and not env.ShoppingTooltip2:IsShown(),
		"a comparison tooltip the game isn't showing is left alone (lines: " .. Lines(env.ShoppingTooltip2) .. ")")
end
env.GameTooltip:Hide()
W.Tick(0.5)

----------------------------------------
Step("riding, swimming and the spirit outfit")
local riding = MakeOutfit("Mount", { FeetSlot = 1006 })
O:SetScriptID(riding, "Riding")
if riding then
	O:SetScriptEnabled(riding, true)
	O:ActivateScript(riding)
	W.mounted = true
	W.Fire("UNIT_AURA", "player")
	W.Fire("PLAYER_MOUNT_DISPLAY_CHANGED")
	W.Tick(3)
	Check(W.equipped[8] == 1006, "riding boots on while mounted (feet have " .. tostring(W.equipped[8]) .. ")")
	W.mounted = false
	W.Fire("UNIT_AURA", "player")
	W.Fire("PLAYER_MOUNT_DISPLAY_CHANGED")
	W.Tick(3)
	Check(W.equipped[8] == 1005, "riding boots off after dismounting")
else
	Fail("no Riding outfit")
end
W.swimming = true
W.Tick(2)
W.swimming = false
W.Tick(2)
W.Fire("UNIT_SPELLCAST_SENT", "player", "Frostbolt")
W.Fire("UNIT_MANA", "player")
W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Frostbolt")
W.Tick(6)

----------------------------------------
Step("the restyled window: tabs on top, flat rows, switches")
do
	local look = env.OutfitterFrame.Look
	if not env.OutfitterFrame:IsShown() then O:ToggleOutfitterFrame() end
	W.Tick(0.5)
	Check(env.OutfitterFrame:IsVisible(), "Outfitter is open")
	O:ShowPanel(1)
	O:Update(true)
	W.Tick(0.2)
	Check(look.Tabs and look.Tabs[1].on and not look.Tabs[2].on, "the Outfits tab is lit")
	Check(not env.OutfitterFrameTab1:IsShown() and not env.OutfitterFrameTab2:IsShown(), "the game's tabs under the window are hidden")
	look.Tabs[2]:Click()
	W.Tick(0.2)
	Check(env.OutfitterOptionsFrame:IsShown() and look.Tabs[2].on and not look.Tabs[1].on, "the Options tab opens the options")
	-- The cards are pages: one shows at a time, picked with the buttons on top
	for index, card in ipairs(look.Cards or {}) do
		look.OptionsSwitch[index]:Click()
		local others = true
		for other, otherCard in ipairs(look.Cards) do
			if other ~= index and otherCard:IsVisible() then others = false end
		end
		Check(card:IsVisible() and others and look.OptionsSwitch[index].bg.__color[1] ~= look.OptionsSwitch[index % 3 + 1].bg.__color[1] or false,
			"option page " .. index .. " shows on its own, its button lit")
	end
	-- Each page shows only its own options: Outfitter's boxes sit on the Options
	-- panel, so a hidden page's switches would draw over the page that shows
	local pageSwitches = { { env.OutfitterShowHotkeyMessages }, { env.OutfitterTooltipInfo, env.OutfitterItemComparisons },
		{ env.OutfitterShowMinimapButton, env.OutfitterShowOutfitBar, env.OutfitterUseSidebarTab } }
	for index in ipairs(pageSwitches) do
		look.OptionsSwitch[index]:Click()
		local only = true
		for page, switches in ipairs(pageSwitches) do
			for _, switch in ipairs(switches) do
				if switch:IsVisible() ~= (page == index) then only = false end
			end
		end
		Check(only, "option page " .. index .. " shows its own switches and no other page's")
	end
	-- The page buttons and cards are as wide as the window (the hidden Options
	-- panel has no width of its own in game)
	local optionsWidth = env.OutfitterFrame:GetWidth() - 16
	Check(math.abs(look.Cards[1]:GetWidth() - optionsWidth) < 1
		and math.abs(look.OptionsSwitch[1]:GetWidth() - (optionsWidth - 8) / 3) < 1,
		"the option pages and their buttons are the window's width (got " .. tostring(look.Cards[1]:GetWidth()) .. ")")
	look.OptionsSwitch[1]:Click()
	Check(AnchoredTo(look.OptionsScripts, look.Cards[1]) and AnchoredTo(env.OutfitterShowHotkeyMessages, look.Cards[1])
		and AnchoredTo(env.OutfitterTooltipInfo, look.Cards[2])
		and AnchoredTo(env.OutfitterShowOutfitBar, look.Cards[3]), "each option sits in its card")
	Check(env.OutfitterShowHotkeyMessages:GetWidth() == 30, "options are on/off switches")
	look.Tabs[1]:Click()
	W.Tick(0.2)
	Check(env.OutfitterMainFrame:IsShown(), "the Outfits tab brings the list back")

	-- Rows: a script's name beside the outfit's, category names in capitals
	local scriptRow, plainRow, categoryRow
	for index = 0, O.cMaxDisplayedItems - 1 do
		local item = env["OutfitterItem" .. index]
		local outfit = item:IsShown() and not item.isCategory and not item.isOutfitItem and item:GetOutfit()
		if item:IsShown() and item.isCategory then
			categoryRow = categoryRow or item
		elseif outfit and outfit.ScriptID and O:GetPresetScriptByID(outfit.ScriptID) then
			scriptRow = scriptRow or item
		elseif outfit and not outfit.ScriptID and not outfit.Script then
			plainRow = plainRow or item
		end
	end
	local preset = scriptRow and O:GetPresetScriptByID(scriptRow:GetOutfit().ScriptID)
	Check(scriptRow and scriptRow.Look.Script:IsShown() and scriptRow.Look.Script:GetText() == preset.Name,
		"an outfit with a script shows the script's name (shows " .. tostring(scriptRow and scriptRow.Look.Script:GetText()) .. ")")
	Check(scriptRow and not env[scriptRow:GetName() .. "OutfitScriptIcon"]:IsShown(), "in place of the gear icon")
	Check(plainRow and not plainRow.Look.Script:IsShown(), "an outfit without a script shows no script name")
	local categoryName = categoryRow and env[categoryRow:GetName() .. "CategoryName"]:GetText()
	Check(categoryName and categoryName == categoryName:upper(), "category names are in capitals (" .. tostring(categoryName) .. ")")

	-- The Outfit scripts switch is in Options only (1.8.1 had a second one in the footer)
	Check(look.Scripts == nil, "the Outfits tab's footer has no Outfit scripts switch")

	-- Options has the switch, reading on = scripts run, not Outfitter's "Disable
	-- all outfit scripts" box, which was on when they were off
	O:ShowPanel(2)
	W.Tick(0.2)
	local optionsScripts = look.OptionsScripts
	Check(optionsScripts and optionsScripts:IsVisible(), "Options has an Outfit scripts switch")
	Check(not env.OutfitterAutoSwitch:IsVisible(), "instead of the Disable all outfit scripts box")
	if optionsScripts then
		Check(optionsScripts.label:GetText() == O.cLookOutfitScripts, "named Outfit scripts")
		Check(optionsScripts:IsOn() and not O.Settings.Options.DisableAutoSwitch, "on while scripts run")
		optionsScripts:Click()
		W.Tick(0.1)
		Check(O.Settings.Options.DisableAutoSwitch and not optionsScripts:IsOn(), "switching it off stops outfit scripts")
		optionsScripts:Click()
		W.Tick(0.1)
		Check(not O.Settings.Options.DisableAutoSwitch and optionsScripts:IsOn(), "switching it on runs them again")
	end

	-- Every option has the same tooltip: its name and what it does, shown even with
	-- the game's enhanced tooltips off, and the same whether it's on or off
	local savedUber = W.cvars.UberTooltips
	W.cvars.UberTooltips = "0"
	local options = {
		{ optionsScripts, O.cLookOutfitScripts, O.cLookOutfitScriptsDescription },
		{ env.OutfitterShowHotkeyMessages, O.cShowHotkeyMessages, O.cLookHotkeyMessagesDescription },
		{ env.OutfitterTooltipInfo, O.cTooltipInfo, O.cLookTooltipInfoDescription },
		{ env.OutfitterItemComparisons, O.cLookItemComparisons, O.cLookItemComparisonsDescription },
		{ env.OutfitterShowMinimapButton, O.cShowMinimapButton, O.cLookMinimapButtonDescription },
		{ env.OutfitterShowOutfitBar, O.cShowOutfitBar, O.cLookOutfitBarDescription },
		{ env.OutfitterUseSidebarTab, O.cSidebarTab, O.cLookSidebarTabDescription },
	}
	local function TooltipFor(widget)
		widget:GetScript("OnEnter")(widget)
		local lines = env.GameTooltip.__lines or {}
		local label = widget.label or env[widget:GetName() .. "Text"]
		local r, g, b = label:GetTextColor()
		local hover = { r, g, b }
		widget:GetScript("OnLeave")(widget)
		r, g, b = label:GetTextColor()
		return lines[1], lines[2], hover, { r, g, b }, label
	end
	for _, option in ipairs(options) do
		local widget, title, body = option[1], option[2], option[3]
		local name = tostring(title)
		Check(type(body) == "string" and body ~= "", name .. ": has a description")
		local first, second, hover, after, label = TooltipFor(widget)
		Check(first == title and second == body, name .. ": the tooltip shows its name and description with enhanced tooltips off (got "
			.. tostring(first) .. " / " .. tostring(second) .. ")")
		widget:Click()
		W.Tick(0.1)
		local first2, second2 = TooltipFor(widget)
		Check(first2 == first and second2 == second, name .. ": the tooltip doesn't change when the option does")
		widget:Click()
		W.Tick(0.1)
		Check(label:GetText() == title, name .. ": the label is the option's name")
		Check(hover[1] == 1 and hover[2] == 0.82 and hover[3] == 0, name .. ": its label turns gold on hover")
		Check(not (after[1] == 1 and after[2] == 0.82 and after[3] == 0), name .. ": and back when the mouse leaves")
		-- Clicks reach the end of the label's text, not empty space past it
		local _, right = widget:GetHitRectInsets()
		local textWidth = math.min(label:GetUnboundedStringWidth(), label:GetWidth())
		Check(right == -(8 + textWidth), name .. ": the clickable area ends with the label (" .. tostring(right) .. ")")
	end
	W.cvars.UberTooltips = savedUber

	-- The first card is named for what's in it, not after the Outfits tab
	Check(look.Cards[1].title:GetText() == O.cLookAutomation:upper(), "the first card is Automation")
	Check(look.Cards[1].title:GetText() ~= O.cOutfitterTabTitle:upper(), "not Outfits, the tab's name")

	-- The outfit bar's settings, from a button beside its switch
	look.OptionsSwitch[3]:Click() -- the Quick access page
	local barSettings = look.BarSettings
	Check(barSettings and barSettings:IsVisible() and AnchoredTo(barSettings, env.OutfitterShowOutfitBar),
		"Options has a button for the outfit bar's settings, by its switch")
	if barSettings then
		barSettings:Click()
		W.Tick(0.1)
		local dialog = O.OutfitBar.SettingsDialog
		Check(dialog and dialog:IsShown(), "it opens the outfit bar's settings")
		barSettings:Click()
		W.Tick(0.1)
		Check(dialog and not dialog:IsShown(), "and closes them")
		Check(env.OutfitterShowOutfitBarText:GetWidth() < 180,
			"the outfit bar's label makes room for the button")
	end

	-- Without the Equipment Manager tab its row goes, and the card shrinks to fit
	local card3 = look.Cards[3]:GetHeight()
	local sidebarTab = O.SidebarTab
	O.SidebarTab = nil
	O:Update(false)
	Check(not env.OutfitterUseSidebarTab:IsShown() and look.Cards[3]:GetHeight() == card3 - 22,
		"no Equipment Manager tab: its row is hidden and the card is a row shorter")
	O.SidebarTab = sidebarTab
	O:Update(false)
	Check(env.OutfitterUseSidebarTab:IsShown() and look.Cards[3]:GetHeight() == card3, "and back when there is one")
	O:ShowPanel(1)
	W.Tick(0.2)

	-- The New Outfit dialog gets the header bar with its title
	O:OpenNameOutfitDialog(nil)
	local dialog = O.NameOutfitDialog
	Check(dialog.Look and dialog.Look.Header.text:GetText() == O.cNewOutfit, "the New Outfit dialog has the header bar and its title")
	dialog:Cancel()
	W.Tick(0.2)

	-- The Edit Script dialog (outfit menu > script settings) has the same look
	O.OutfitMenuActions.SCRIPT_SETTINGS(O, fisher)
	W.Tick(0.2)
	local editor = env.OutfitterEditScriptDialog
	local editorLook = editor.Look
	Check(editor:IsShown() and editorLook ~= nil, "the Edit Script dialog opens restyled")
	if editorLook then
		Check(editorLook.Header.text:GetText() == env.OutfitterEditScriptDialogTitle:GetText()
			and not env.OutfitterEditScriptDialogTitle:IsShown(), "its title is in the header bar")
		Check(editor.CloseButton and not editor.CloseButton:IsShown() and editorLook.Close:IsShown(), "with a flat X")
		local artShown = 0
		for _, region in ipairs({ editor:GetRegions() }) do
			if region:GetObjectType() == "Texture" and region:IsShown() and region:GetTexture() ~= nil then
				artShown = artShown + 1
			end
		end
		Check(artShown == 0, "none of the old frame art shows (" .. artShown .. " textures)")
		Check(not env.OutfitterEditScriptDialogTab1:IsShown() and not env.OutfitterEditScriptDialogTab2:IsShown(),
			"the game's tabs below the dialog are hidden")
		Check(editorLook.Tabs[1].on and not editorLook.Tabs[2].on, "flat tabs on top, Settings lit")
		local function Flat(button)
			local art = 0
			for _, piece in ipairs({ button:GetNormalTexture() or false, button.Left or false, button.Middle or false, button.Right or false }) do
				if piece and piece:GetAlpha() > 0 then art = art + 1 end
			end
			return art == 0
		end
		Check(Flat(env.OutfitterEditScriptDialogDoneButton) and Flat(env.OutfitterEditScriptDialogCancelButton), "Done and Cancel are flat buttons")
		-- The Fishing script's settings: a yes/no setting is a switch, a number a flat field
		local switch, field
		for frameType, frames in pairs(editor.FrameCache) do
			for _, frame in ipairs(frames) do
				if frame:IsShown() and frameType == "Checkbox" then switch = frame end
				if frame:IsShown() and frameType == "EditBox" then field = frame end
			end
		end
		Check(switch and switch:GetWidth() == 30, "a yes/no setting is an on/off switch")
		Check(field and env[field:GetName() .. "Center"]:GetAlpha() == 0, "a number setting is a flat field")
		editorLook.Tabs[2]:Click()
		W.Tick(0.2)
		Check(env.OutfitterEditScriptDialogSource:IsShown() and editorLook.Tabs[2].on and not editorLook.Tabs[1].on,
			"the Source tab shows the script")
		Check(env.OutfitterEditScriptDialogSourceScriptCenter:GetAlpha() == 0, "in a flat field")
		editorLook.Tabs[1]:Click()
		W.Tick(0.2)
		Check(env.OutfitterEditScriptDialogSettings:IsShown() and editorLook.Tabs[1].on, "and back to Settings")
		env.OutfitterEditScriptDialogCancelButton:Click()
		W.Tick(0.2)
		Check(not editor:IsShown(), "Cancel closes it")
	end
end

----------------------------------------
Step("options and the outfit bar")
O:ShowPanel(2)
W.Tick(0.2)
for _, frame in ipairs(W.frames) do
	local name = frame.__name
	if name and frame.__type == "CheckButton" and name:match("^Outfitter") and frame:IsVisible() and not name:match("^OutfitterEnable")
		and name ~= "OutfitterSidebarTab" then
		frame:Click()
		W.Tick(0.1)
		frame:Click()
	end
end
O:ShowPanel(1)
W.Tick(0.5)

----------------------------------------
Step("the outfit bar, its dialogs and the menus have the shared look")
do
	-- The bar and the icon picker are built when Outfitter starts; that used to stop
	-- with an error printed in chat
	for _, line in ipairs(W.printed) do
		Check(not tostring(line):find("Error dispatching event", 1, true), "no error while Outfitter starts: " .. tostring(line))
	end
	O.OutfitBar:Show()
	W.Tick(0.5)
	local bar = O.OutfitBar.Bars[1]
	Check(bar and bar.Look ~= nil, "the outfit bar is restyled")
	if bar and bar.Look then
		local stone = 0
		for _, texture in ipairs(bar.BackgroundTextures) do
			if texture:IsShown() then stone = stone + 1 end
		end
		Check(stone == 0, "none of the stone background shows (" .. stone .. ")")
		Check(bar.Look.Fill:IsShown(), "a flat panel instead")
		local button = bar.Buttons[1]
		Check(button.Look and (button:GetNormalTexture() == nil or button:GetNormalTexture():GetAlpha() == 0), "its buttons are flat")
		-- The buttons sit apart: each is narrower than the step to the next
		local style = O.Style.ButtonBar
		Check(button:GetWidth() == style.ButtonWidth and button:GetWidth() < style.BackgroundWidth,
			"buttons are " .. tostring(button:GetWidth()) .. " wide on a " .. style.BackgroundWidth .. " grid")
		-- The hover light covers the button exactly
		local light = button:GetHighlightTexture()
		if light then
			local p1, r1 = light:GetPoint(1)
			local p2, r2 = light:GetPoint(2)
			Check(light:GetNumPoints() == 2 and p1 == "TOPLEFT" and r1 == button and p2 == "BOTTOMRIGHT" and r2 == button,
				"the hover light lines up with the button")
		end
		-- The outfit you wear has a bright gold edge (not a red wash); the others don't
		Check(button.WornEdges and (button:GetCheckedTexture() == nil or button:GetCheckedTexture():GetAlpha() == 0),
			"worn is shown by a gold edge, not the check art")
		if button.WornEdges then
			button:SetChecked(true)
			Check(button.WornEdges[1]:IsShown(), "the gold edge shows on the outfit you wear")
			Check(button.WornBadge and button.WornBadge:IsShown(), "with a gold check badge in the corner")
			if button.WornTick then
				local badgeLayer, badgeSub = button.WornBadge:GetDrawLayer()
				local tickLayer, tickSub = button.WornTick:GetDrawLayer()
				Check(button.WornTick:IsShown() and tickLayer == badgeLayer and tickSub > badgeSub,
					"the check draws on top of the badge (sub-layers " .. tostring(tickSub) .. " over " .. tostring(badgeSub) .. ")")
			end
			button:SetChecked(false)
			Check(not button.WornEdges[1]:IsShown() and not (button.WornBadge and button.WornBadge:IsShown()), "and not on the others")
		end
		local _, _, _, x1 = bar.Buttons[1]:GetPoint(1)
		local second = bar.NumColumns > 1 and bar.Buttons[2]
		if second then
			local _, _, _, x2 = second:GetPoint(1)
			Check(x2 - x1 == style.BackgroundWidth, "the next button is one grid step along (" .. tostring(x2 - x1) .. ")")
		end
		bar:ShowBackground(false)
		Check(not bar.Look.Fill:IsShown() and stone == 0, "Hide background hides the flat panel")
		bar:ShowBackground(true)
		Check(bar.Look.Fill:IsShown(), "and shows it again")
	end
	local drag = O.OutfitBar.DragBar1
	Check(drag and drag.DragTexture:GetTexture() == nil, "the drag handle is a flat bar, not the grip art")

	-- Its settings (right-click a drag handle)
	O.OutfitBar:DragBar_OnClick("RightButton")
	W.Tick(0.2)
	local settings = O.OutfitBar.SettingsDialog
	Check(settings and settings:IsShown() and settings.Look, "the bar's settings are restyled")
	if settings and settings.Look then
		Check(settings.VerticalCheckbutton:GetWidth() == 30, "with switches")
		-- One row each: Lock under Vertical, Hide background under Lock, apart
		local _, under1, _, _, gap1 = settings.LockPositionCheckbutton:GetPoint(1)
		local _, under2, _, _, gap2 = settings.HideBackgroundCheckbutton:GetPoint(1)
		Check(under1 == settings.VerticalCheckbutton and under2 == settings.LockPositionCheckbutton and gap1 < 0 and gap2 < 0,
			"the switches are stacked a row apart, not on top of each other")
		settings.VerticalCheckbutton:Click()
		W.Tick(0.2)
		settings.VerticalCheckbutton:Click()
		W.Tick(0.2)
	end
	O.OutfitBar:DragBar_OnClick("RightButton")
	W.Tick(0.2)

	-- The icon picker (outfit menu > choose icon)
	local picker = env.OutfitterChooseIconDialog
	-- In game the icon area is 270 x 260 and upstream fits 6 columns of 45-wide
	-- icons in it, forgetting the gaps between them (reported in 1.4.0)
	local area = picker.Widgets.ScrollFrame
	area:SetSize(270, 260)
	picker.NumColumns, picker.NumRows = 6, 5
	while #picker.IconButtons < 30 do table.insert(picker.IconButtons, picker:NewIconButton()) end
	for _, button in ipairs(picker.IconButtons) do button:SetSize(45, 45) end
	O.OutfitMenuActions.OUTFITBAR_CHOOSEICON(O, fishing)
	W.Tick(0.2)
	local fits = true
	for _, button in ipairs(picker.IconButtons) do
		local _, relativeTo, _, x, y = button:GetPoint(1)
		if relativeTo ~= area or x + button:GetWidth() > 270 or -y + button:GetHeight() > 260 then fits = false end
	end
	Check(fits, "every icon in the icon picker fits inside its area")
	Check(picker:IsShown() and picker.Look and picker.Look.Header.text:GetText() == env.OutfitterChooseIconDialogTitle:GetText(),
		"the icon picker has the header bar with its title")
	if picker.Look then
		Check(env.OutfitterChooseIconDialogOKButton:GetFontString() == nil
			or select(1, env.OutfitterChooseIconDialogOKButton:GetFontString():GetTextColor()) == env.Outfitter.Theme.C.gold[1],
			"flat OK button")
		Check(picker.IconButtons[1] and picker.IconButtons[1].Look, "flat icon buttons")
		-- The template's flyout arrow (a yellow triangle once the icon is clicked) never shows
		for _, button in ipairs({ picker.IconButtons[1], O.OutfitBar.Bars[1] and O.OutfitBar.Bars[1].Buttons[1] or false }) do
			if button then
				Check(not button.Arrow or button.Arrow:GetAlpha() == 0, "no flyout arrow on an icon button")
				Check(not button.BorderShadow or button.BorderShadow:GetAlpha() == 0, "nor its border shadow")
			end
		end
	end
	env.OutfitterChooseIconDialogCancelButton:Click()
	W.Tick(0.2)
	Check(not picker:IsShown(), "Cancel closes the icon picker")

	-- The buttons show what each outfit will do (since 1.8.0)
	local function ButtonFor(outfit)
		for _, eachBar in ipairs(O.OutfitBar.Bars or {}) do
			for _, each in ipairs(eachBar.Buttons or {}) do
				if each.Outfit == outfit and each:IsShown() then return each end
			end
		end
	end
	O:SetOutfitBindingIndex(fishing, 1)
	W.bindings.OUTFITTER_OUTFIT1 = "SHIFT-3"
	W.Fire("UPDATE_BINDINGS")
	W.Tick(0.5)
	local fishingButton = ButtonFor(fishing)
	Check(fishingButton and fishingButton.States, "an outfit bar button for the fishing outfit, with its states")
	if fishingButton and fishingButton.States then
		local states = fishingButton.States
		Check(states.Key:IsShown() and states.Key:GetText() == "S-3", "its key binding shows, short (" .. tostring(states.Key:GetText()) .. ")")
		Check(not states.Wait:IsShown(), "it isn't waiting for combat")
		Check(not states.MissingEdges[1]:IsShown(), "nor missing gear")
		O.OutfitBar:DragBar_OnClick("RightButton")
		W.Tick(0.2)
		Check(settings.ShowKeysCheckbutton and settings.ShowKeysCheckbutton:GetChecked(), "the bar's settings have Show key bindings, on")
		local _, under = settings.ShowKeysCheckbutton:GetPoint(1)
		Check(under == settings.HideBackgroundCheckbutton, "on a row of its own, under Hide background")
		settings.ShowKeysCheckbutton:Click()
		W.Tick(0.5)
		Check(O.Settings.OutfitBar.HideKeys and not states.Key:IsShown(), "turning it off hides the key")
		settings.ShowKeysCheckbutton:Click()
		W.Tick(0.5)
		Check(not O.Settings.OutfitBar.HideKeys and states.Key:IsShown(), "and on shows it again")
		O.OutfitBar:DragBar_OnClick("RightButton")
		W.Tick(0.2)

		-- Waiting for combat: a pulsing edge and the pocket watch, until combat ends
		W.combat = true
		W.Fire("PLAYER_REGEN_DISABLED")
		O:WearOutfit(fishing)
		W.Tick(1)
		Check(states.Wait:IsShown() and states.Pulse:IsPlaying(), "an outfit whose armor waits for combat pulses")
		Check(states.Watch:GetTexture() == "Interface\\Icons\\INV_Misc_PocketWatch_01", "with the pocket watch")
		W.combat = false
		W.Fire("PLAYER_REGEN_ENABLED")
		W.Tick(3)
		Check(not states.Wait:IsShown() and not states.Pulse:IsPlaying(), "and stops once combat ends")
		O:WearOutfit(battle)
		W.Tick(3)
	end
	O:SetOutfitBindingIndex(fishing, nil)
	W.bindings.OUTFITTER_OUTFIT1 = nil

	-- Missing gear: a red edge and a red wash on the icon
	local lost = MakeOutfit("Lost", { HeadSlot = 1019 })
	O.OutfitBar:ChangedOutfits()
	W.Tick(0.5)
	local lostButton = ButtonFor(lost)
	Check(lostButton and lostButton.States and lostButton.States.MissingEdges[1]:IsShown(), "an outfit with missing gear has a red edge")
	if lostButton then
		local r, g = unpack(lostButton.Widgets.Icon.__vertexColor or {})
		Check(r == 1 and g and g < 0.5, "and a red icon")
	end
	O:DeleteOutfit(lost)
	W.Tick(0.5)
	O.OutfitBar:Hide()
	W.Tick(0.2)

	-- The outfit menu
	O:ShowOutfitMenuAtCursor(fishing)
	W.Tick(0.2)
	local menuFrame = O.outfitMenu and O.outfitMenu.menuFrame
	Check(menuFrame and menuFrame.Look and menuFrame.Look.Fill:IsShown(), "the outfit menu is a flat panel")
	if menuFrame then
		Check(not menuFrame.NineSlice or not menuFrame.NineSlice:IsShown(), "without the tooltip border")
		local line = menuFrame.buttons and menuFrame.buttons[2]
		local highlight = line and line:GetHighlightTexture()
		Check(highlight and highlight:GetTexture() == nil, "a line under the mouse gets a flat highlight")
	end
	O:HideOutfitMenu()
	W.Tick(0.5)
end

----------------------------------------
Step("the Equipment Manager tab opens Outfitter")
do
	if not env.CharacterFrame:IsShown() then W.PlayerTogglesCharacter() end
	W.PlayerCollapsesStatsPane(false)
	local tab = env.OutfitterSidebarTab
	Check(tab ~= nil, "Outfitter has its own tab button")
	if tab then
		Check(tab == O.SidebarTab, "it's the one Outfitter keeps")
		Check(tab:GetParent() == env.PaperDollSidebarTabs, "it belongs to the tab strip, so it shows and hides with it")
		Check(AnchoredTo(tab, env.PaperDollSidebarTab2), "it covers the Equipment Manager tab")
		Check(tab:GetFrameLevel() > env.PaperDollSidebarTab2:GetFrameLevel(), "and sits above it, so it takes the clicks")
		Check(tab.Icon and tostring(tab.Icon:GetTexture()):find("Textures\\Tab", 1, true), "it shows Outfitter's icon")
		Check(tab.Ring and tab.Ring:GetAtlas() == "UI-Character-Info-StatTab", "inside the same ring as the game's tabs")

		if not O:IsOpen() then O:ToggleOutfitterFrame() end
		Check(tab:IsVisible(), "the tab is showing with the stats pane open")
		Check(not env.OutfitterButton:IsShown(), "the small button is hidden while the tab is there")
		Check(tab:GetChecked() and tab.Selected:IsShown(), "the tab is lit while Outfitter is open")

		tab:Click()
		Check(not O:IsOpen(), "clicking the tab closes Outfitter")
		Check(not tab:GetChecked() and not tab.Selected:IsShown(), "and the tab goes dark")
		tab:Click()
		Check(O:IsOpen(), "clicking it again opens Outfitter")
		Check(tab:GetChecked() and tab.Selected:IsShown(), "and the tab lights up")
		Check(W.equipmentManagerClicks == nil, "the game's Equipment Manager tab was never clicked")

		env.OutfitterFrame:Hide()
		Check(not tab:GetChecked(), "closing Outfitter another way also darkens the tab")
		env.OutfitterFrame:Show()
		Check(tab:GetChecked(), "and opening it another way lights it")

		-- Stats pane collapsed: the strip of tabs is gone, so the small button is back
		W.PlayerCollapsesStatsPane(true)
		Check(not tab:IsVisible(), "no tab while the stats pane is collapsed")
		Check(env.OutfitterButton:IsShown() and env.OutfitterButton:IsVisible(), "the small button stands in")
		W.PlayerCollapsesStatsPane(false)
		Check(tab:IsVisible() and not env.OutfitterButton:IsShown(), "and steps aside when the pane opens again")

		-- The character window closing and opening again
		W.PlayerTogglesCharacter()
		W.PlayerTogglesCharacter()
		Check(tab:IsVisible() and not env.OutfitterButton:IsShown(), "still the tab after reopening the character window")
		Check(not tab:GetChecked(), "and it isn't lit, because Outfitter is closed")
		O:ToggleOutfitterFrame()

		-- The option
		O:ShowPanel(2)
		W.Tick(0.2)
		local box = env.OutfitterUseSidebarTab
		Check(box ~= nil and box:IsVisible(), "Options has a checkbox for it")
		Check(box and box:GetChecked(), "ticked to start with")
		if box then
			box:Click()
			Check(O.Settings.Options.DisableSidebarTab == true, "unticking it is saved")
			Check(env.gOutfitter_Settings.Options.DisableSidebarTab == true, "in this character's settings")
			-- Off: the Equipment Manager tab is the game's again, and Outfitter's
			-- tab sits beside the game's tabs, with the small button too
			local function Beside() return tab:IsVisible() and AnchoredTo(tab, env.PaperDollSidebarTab1) and not AnchoredTo(tab, env.PaperDollSidebarTab2) end
			Check(Beside(), "the tab moves beside the game's tabs, uncovering the Equipment Manager tab")
			Check(env.OutfitterButton:IsShown(), "and the small button is there too")
			W.PlayerTogglesCharacter()
			W.PlayerTogglesCharacter()
			Check(Beside() and env.OutfitterButton:IsShown(), "it stays that way")
			tab:Click()
			Check(O:IsOpen(), "the tab beside the others opens Outfitter")
			O:ShowPanel(2)
			W.Tick(0.2)
			Check(not box:GetChecked(), "the checkbox shows it's off")
			box:Click()
			Check(O.Settings.Options.DisableSidebarTab == false, "ticking it again is saved")
			Check(tab:IsVisible() and AnchoredTo(tab, env.PaperDollSidebarTab2) and not env.OutfitterButton:IsShown(),
				"and the tab is back over the Equipment Manager's")
			Check(tab:GetChecked(), "lit, since Outfitter is open")
		end
		O:ShowPanel(1)
		W.Tick(0.5)
	end
end

----------------------------------------
Step("outfits can be moved up and down, and the order is kept")
do
	local function Names(category)
		local names = {}
		for _, outfit in ipairs(O.Settings.Outfits[category]) do names[#names + 1] = outfit.Name end
		return table.concat(names, ",")
	end
	-- A menu that just records what's put in it
	local function Menu(outfit)
		local items = {}
		local menu = setmetatable({}, { __index = function() return function() end end })
		function menu:AddFunction(title, func, disabled) items[title] = { func = func, disabled = disabled and true or false } end
		O:AddOutfitMenu(menu, outfit)
		return items
	end

	local quill = MakeOutfit("Quill", { Trinket0Slot = 1014 })
	local anvil = MakeOutfit("Anvil", { Trinket0Slot = 1014 })
	local mason = MakeOutfit("Mason", { Trinket0Slot = 1014 })
	local category = O:FindOutfit(quill)
	Check(category == O:FindOutfit(anvil) and category == O:FindOutfit(mason), "the three test outfits are in one list")
	-- Only look at these three: the list has other outfits from earlier steps
	local function Mine()
		local names = {}
		for _, outfit in ipairs(O.Settings.Outfits[category]) do
			if outfit == quill or outfit == anvil or outfit == mason then names[#names + 1] = outfit.Name end
		end
		return table.concat(names, ",")
	end
	O:SortOutfits()
	Check(Mine() == "Anvil,Mason,Quill", "by name to start with (is " .. Mine() .. ")")
	Check(anvil.Order == nil and quill.Order == nil, "and nothing is numbered until something is moved")

	local items = Menu(mason)
	Check(items[O.cMoveUp] and items[O.cMoveDown], "the outfit's menu has Move up and Move down")
	Check(items[O.cSortByName] == nil, "and no Sort by name while the list is by name already")

	-- Saving what you're wearing into the outfit is near the top, once, not down under Rebuild
	do
		local order = {}
		local menu = setmetatable({}, { __index = function() return function() end end })
		function menu:AddFunction(title) order[#order + 1] = title end
		function menu:AddCategoryTitle(title) order[#order + 1] = "#" .. tostring(title) end
		O:AddOutfitMenu(menu, mason)
		local at, count, rebuild = nil, 0, nil
		for index, title in ipairs(order) do
			if title == O.cSetCurrentItems then at, count = at or index, count + 1 end
			if title == "#" .. O.cRebuild then rebuild = index end
		end
		Check(count == 1, "Update to current items is in the outfit menu once (" .. count .. ")")
		Check(at == 3 and order[2] == env.PET_RENAME and order[4] == O.cMoveUp,
			"right after Rename, before Move up (" .. table.concat(order, " | ", 1, math.min(#order, 5)) .. ")")
		Check(rebuild and at < rebuild, "above the Rebuild section")
	end

	-- Put the three at the bottom of the list in a known order to test the ends
	local before = Names(category)
	items[O.cMoveUp].func()
	W.Tick(0.2)
	local index = select(1, O:GetOutfitPlace(mason))
	Check(Names(category) ~= before, "Move up changes the list")
	Check(O.Settings.Outfits[category][index] == mason, "the outfit is where the list says")
	Check(O.Settings.Outfits[category][index + 1].Name ~= nil and before:find(O.Settings.Outfits[category][index + 1].Name .. ",Mason", 1, true),
		"it swapped places with the one above (was " .. before .. ", is " .. Names(category) .. ")")
	for position, outfit in ipairs(O.Settings.Outfits[category]) do
		if outfit.Order ~= position then Fail(outfit.Name .. " has place " .. tostring(outfit.Order) .. " at " .. position) end
	end
	Check(env.gOutfitter_Settings.Outfits[category][index] == mason and mason.Order == index, "the place is saved with the outfit, per character")

	items = Menu(mason)
	Check(items[O.cSortByName] ~= nil, "Sort by name is offered once the list has its own order")
	items[O.cMoveDown].func()
	W.Tick(0.2)
	Check(Names(category) == before, "Move down puts it back (is " .. Names(category) .. ")")

	-- The ends
	local count = #O.Settings.Outfits[category]
	for _ = 1, 50 do if not O:MoveOutfit(quill, 1) then break end end
	Check(select(1, O:GetOutfitPlace(quill)) == count, "an outfit can be moved all the way down")
	items = Menu(quill)
	Check(items[O.cMoveDown].disabled and not items[O.cMoveUp].disabled, "Move down is greyed out at the bottom")
	local atBottom = Names(category)
	Check(O:MoveOutfit(quill, 1) == false and Names(category) == atBottom, "and does nothing there")
	for _ = 1, 50 do if not O:MoveOutfit(anvil, -1) then break end end
	Check(select(1, O:GetOutfitPlace(anvil)) == 1, "and all the way up")
	items = Menu(anvil)
	Check(items[O.cMoveUp].disabled and not items[O.cMoveDown].disabled, "Move up is greyed out at the top")

	-- The order holds when the window redraws, and new outfits go to the end
	local ordered = Names(category)
	O.DisplayIsDirty = true
	O:Update(true)
	W.Tick(0.5)
	Check(Names(category) == ordered, "redrawing the list doesn't put it back in name order")
	local bell = MakeOutfit("Bell", { Trinket0Slot = 1014 })
	O.DisplayIsDirty = true
	O:Update(true)
	Check(Names(category) == ordered .. ",Bell", "a new outfit goes to the end (is " .. Names(category) .. ")")
	Check(bell.Order == count + 1, "and gets the next place")
	O:DeleteOutfit(bell)
	O:SortOutfits()
	Check(Names(category) == ordered, "deleting one leaves the rest in order")
	for position, outfit in ipairs(O.Settings.Outfits[category]) do
		if outfit.Order ~= position then Fail("after a delete, " .. outfit.Name .. " has place " .. tostring(outfit.Order) .. " at " .. position) end
	end

	-- The outfit bar and minimap menu read the same list
	Check(O:GetOutfitsByCategoryID(category)[1] == anvil, "the outfit bar and minimap menu see the new order")

	-- Other lists are untouched
	for other, outfits in pairs(O.Settings.Outfits) do
		if other ~= category then
			for _, outfit in ipairs(outfits) do
				if outfit.Order ~= nil then Fail(outfit.Name .. " in " .. other .. " was numbered too") end
			end
		end
	end

	-- A saved place that isn't a number is ignored
	mason.Order = "first"
	O:SortOutfits()
	Check(type(mason.Order) == "number", "a bad saved place is repaired")

	-- Back to names
	Menu(mason)[O.cSortByName].func()
	W.Tick(0.2)
	Check(Mine() == "Anvil,Mason,Quill", "Sort by name puts the list back in name order (is " .. Mine() .. ")")
	for _, outfit in ipairs(O.Settings.Outfits[category]) do
		if outfit.Order ~= nil then Fail(outfit.Name .. " still has a place after Sort by name") end
	end
	O:DeleteOutfit(quill)
	O:DeleteOutfit(anvil)
	O:DeleteOutfit(mason)
	W.Tick(0.5)
end

----------------------------------------
Step("Baganator is told which outfit each item belongs to")
do
	if not baganatorFirst then
		Check(#baganator.sources == 0, "nothing is registered while Baganator isn't there")
		W.Fire("ADDON_LOADED", "SomeOtherAddon")
		Check(#baganator.sources == 0, "another addon loading doesn't register anything")
		InstallBaganator()
		W.Fire("ADDON_LOADED", "Baganator")
	end
	Check(#baganator.sources == 1, "Outfitter registers with Baganator once (" .. #baganator.sources .. ")")
	W.Fire("ADDON_LOADED", "Baganator")
	Check(#baganator.sources == 1, "and not again")
	local source = baganator.sources[1]
	if source then
		local function Has(list, name)
			for _, entry in ipairs(list or {}) do
				if entry == name or (type(entry) == "table" and entry.name == name) then return true end
			end
			return false
		end
		local function Sets(itemID) return source.get(nil, "Item-1-0-" .. itemID, W.ItemLink(itemID)) end

		Check(source.label == "Outfitter Forever" and source.id == "outfitter_forever", "under its own name")
		Check(source.names ~= nil, "it can list its outfits")

		-- Every outfit, in the order of Outfitter's list
		local expected = {}
		for _, category in ipairs(O.cCategoryOrder) do
			for _, outfit in ipairs(O.Settings.Outfits[category] or {}) do expected[#expected + 1] = outfit.Name end
		end
		Check(table.concat(source.names(), ",") == table.concat(expected, ","), "the outfits are listed in Outfitter's order")
		Check(Has(source.names(), "Fishing") and Has(source.names(), "Battle Gear"), "Fishing and Battle Gear are among them")

		-- Items
		-- (an earlier step made a second fishing outfit, so the pole is in more than one)
		local sets = Sets(1011)
		local poleOutfits = sets and #sets or 0
		Check(Has(sets, "Fishing"), "the fishing pole belongs to Fishing")
		Check(sets and sets[1].iconTexture ~= nil, "with an icon for the bag")
		for _, entry in ipairs(sets or {}) do
			local outfit = O:FindOutfitByName(entry.name)
			Check(outfit and outfit:GetItem("MainHandSlot") and outfit:GetItem("MainHandSlot").Code == 1011,
				entry.name .. " really has the pole")
		end
		Check(Has(Sets(1001), "Battle Gear"), "the helm belongs to Battle Gear")
		Check(Sets(1016) == nil, "a bandage belongs to nothing")
		Check(source.get(nil, nil, nil) == nil, "no link, no answer")
		Check(source.get(nil, "x", "|cff0070dd|Hbattlepet:39:1:3:158:10:12:0|h[Pet]|h|r") == nil, "a link that isn't an item is ignored")
		Check(source.get(nil, "x", 12345) == nil, "and so is a link that isn't text")

		-- An item in two outfits is reported for both
		local before = baganator.refreshes
		local pair = MakeOutfit("Bag Pair", { MainHandSlot = 1011, FingerSlot = nil })
		Check(baganator.refreshes == before + 1, "a new outfit makes Baganator redraw the bags")
		Check(Has(source.names(), "Bag Pair"), "and it's listed")
		sets = Sets(1011)
		Check(sets and #sets == poleOutfits + 1 and Has(sets, "Fishing") and Has(sets, "Bag Pair"), "the pole is now in the new outfit as well")

		-- Nothing changed: no redraw
		before = baganator.refreshes
		O:OutfitSettingsChanged(pair)
		Check(baganator.refreshes == before, "a change that doesn't touch names or items doesn't redraw the bags")

		-- Changing the outfit's items
		pair:AddItem("HeadSlot", O:GetItemInfoFromLink(W.ItemLink(1002)))
		O:OutfitSettingsChanged(pair)
		Check(baganator.refreshes == before + 1, "adding an item redraws the bags")
		Check(Has(Sets(1002), "Bag Pair"), "and the item belongs to the outfit")

		-- Renaming
		before = baganator.refreshes
		pair:SetName("Bag Duo")
		O:DispatchOutfitEvent("DID_RENAME_OUTFIT", pair, "Bag Pair", "Bag Duo")
		Check(baganator.refreshes == before + 1, "renaming redraws the bags")
		Check(Has(source.names(), "Bag Duo") and not Has(source.names(), "Bag Pair"), "under the new name")
		Check(Has(Sets(1011), "Bag Duo"), "for its items too")

		-- Moving it in the list changes the order Baganator gets
		local order = table.concat(source.names(), ",")
		if O:MoveOutfit(pair, -1) then
			Check(table.concat(source.names(), ",") ~= order, "Move up changes the order of the groups")
			O:SortOutfitsByName(O:FindOutfit(pair))
		end

		-- Another item with the same ID that the outfit doesn't mean
		local uses = pair.OutfitUsesItem
		pair.OutfitUsesItem = function() return false end
		Check(not Has(Sets(1002), "Bag Duo"), "an item the outfit doesn't use isn't reported, even with the same ID")
		pair.OutfitUsesItem = uses

		-- Outfits stored on the server are Equipment Manager sets: Baganator has those already
		before = baganator.refreshes
		pair.StoredInEM = true
		O:OutfitSettingsChanged(pair)
		Check(not Has(source.names(), "Bag Duo"), "an outfit stored on the server is left to Baganator's own Equipment Manager groups")
		Check(not Has(Sets(1002), "Bag Duo"), "and so are its items")
		Check(baganator.refreshes == before + 1, "the bags are redrawn when that changes")
		pair.StoredInEM = nil
		O:OutfitSettingsChanged(pair)
		Check(Has(source.names(), "Bag Duo"), "and it's back when it's stored locally again")

		-- An error inside Outfitter must not reach Baganator's bag drawing
		local real = O.GetItemInfoFromLink
		O.GetItemInfoFromLink = function() error("boom") end
		local ok, result = pcall(Sets, 1011)
		O.GetItemInfoFromLink = real
		Check(ok and result == nil, "an error in Outfitter gives Baganator no answer instead of breaking the bags")

		-- Deleting
		before = baganator.refreshes
		O:DeleteOutfit(pair)
		Check(baganator.refreshes == before + 1, "deleting redraws the bags")
		Check(not Has(source.names(), "Bag Duo"), "and the outfit is gone from the list")
		sets = Sets(1011)
		Check(sets and #sets == poleOutfits and Has(sets, "Fishing") and not Has(sets, "Bag Duo"), "the pole is back to the outfits it was in")
		Check(Sets(1002) == nil or not Has(Sets(1002), "Bag Duo"), "and the hat isn't in the deleted outfit")
		W.Tick(0.5)
	end
end

----------------------------------------
Step("the Outfits and Options panels have a plain background")
do
	Check(env.OutfitterMainFrameBackground == nil, "no logo behind the outfit list")
	Check(env.OutfitterOptionsFrameBackground == nil, "no logo behind the options")
	for _, file in ipairs({ "Outfitter.xml", "Outfitter.lua", "OutfitterLook.lua" }) do
		local handle = assert(io.open(file, "rb"))
		local source = handle:read("*a")
		handle:close()
		Check(not source:find("LogoLarge", 1, true), file .. " doesn't use the large logo")
	end
	Check(io.open("Textures/LogoLarge.tga", "rb") == nil, "the large logo isn't shipped any more")
	Check(env.OutfitterFrame.Look and env.OutfitterFrame.Look.Fill ~= nil, "the panel still has its solid fill")

	-- The tab's icon: 64x64, 32-bit, uncompressed, rows stored bottom-up, and opaque
	local handle = io.open("Textures/Tab.tga", "rb")
	Check(handle ~= nil, "the tab icon is shipped")
	if handle then
		local data = handle:read("*a")
		handle:close()
		Check(data:byte(3) == 2 and data:byte(17) == 32, "it's an uncompressed 32-bit TGA")
		Check(data:byte(13) + data:byte(14) * 256 == 64 and data:byte(15) + data:byte(16) * 256 == 64, "64 by 64")
		Check(data:byte(18) % 64 < 32, "rows stored bottom-up, like the game expects")
		Check(#data >= 18 + 64 * 64 * 4, "all the pixels are there")
		local opaque = true
		for pixel = 0, 64 * 64 - 1 do
			if data:byte(18 + pixel * 4 + 4) ~= 255 then opaque = false break end
		end
		Check(opaque, "no see-through pixels, so the Equipment Manager's icon can't show through")
	end
end

----------------------------------------
Step("bags and bank events")
W.Fire("BAG_UPDATE", 0)
W.Fire("BAG_UPDATE_DELAYED")
W.Fire("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", env.Enum.PlayerInteractionType.Banker)
W.Tick(1)
W.Fire("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", env.Enum.PlayerInteractionType.Banker)
W.Fire("ZONE_CHANGED_NEW_AREA")
W.Fire("PLAYER_TALENT_UPDATE")
W.Fire("ACTIVE_TALENT_GROUP_CHANGED", 1, 1)
W.Tick(1)

----------------------------------------
Step("Escape closes Outfitter's dialogs")
local function PressEscape()
	-- What Blizzard's CloseSpecialWindows does
	local found
	for _, name in pairs(env.UISpecialFrames) do
		local frame = env[name]
		if frame and frame:IsShown() then
			frame:Hide()
			found = true
		end
	end
	return found
end
O:OpenNameOutfitDialog(nil)
W.Tick(0.2)
Check(O.NameOutfitDialog and O.NameOutfitDialog:IsShown(), "the new outfit dialog opens")
Check(PressEscape(), "Escape finds something to close")
Check(O.NameOutfitDialog and not O.NameOutfitDialog:IsShown(), "Escape closes the new outfit dialog")
Check(not PressEscape(), "nothing left for Escape to close")
O:OpenNameOutfitDialog(nil)
O.NameOutfitDialog:Cancel()
Check(not PressEscape(), "a cancelled dialog leaves nothing for Escape")

----------------------------------------
Step("error paths say what's wrong instead of breaking")
do
	local function Said(text)
		local last = tostring(W.printed[#W.printed])
		return last:find(text, 1, true) ~= nil, last
	end
	-- A menu click whose outfit can't be found
	local orphan = { GetParent = function() return { GetParent = function() return { GetOutfit = function() return nil end } end } end }
	W.SafeCall(O.OutfitItemSelected, orphan, { name = "Rename" })
	Check(Said("Outfit for menu item Rename not found"), "a menu item without its outfit is reported (said: " .. select(2, Said("")) .. ")")
	W.SafeCall(O.OutfitItemSelected, orphan, "DELETE")
	Check(Said("Outfit for menu item DELETE not found"), "also when the item is just its action (said: " .. select(2, Said("")) .. ")")
	-- A frame class that names a widget which doesn't exist
	local frame = env.CreateFrame("Frame", "OutfitterTestWidgetFrame", env.UIParent)
	W.SafeCall(O.InitializeFrame, frame, { Widgets = { "NoSuchWidget" } })
	Check(Said("Couldn't find global OutfitterTestWidgetFrameNoSuchWidget"), "a missing widget is reported (said: " .. select(2, Said("")) .. ")")
	-- A stat item without a slot or a stat
	W.SafeCall(O.AddOutfitStatItem, O, {}, nil, { Name = "Test Helm" }, "Stamina", 5)
	Check(Said("SlotName is nil for Test Helm"), "a stat item without a slot names the item (said: " .. select(2, Said("")) .. ")")
	W.SafeCall(O.AddOutfitStatItem, O, {}, "HeadSlot", { Name = "Test Helm" }, nil, 5)
	Check(Said("Stat is nil for Test Helm"), "a stat item without a stat names the item (said: " .. select(2, Said("")) .. ")")
	-- The link of a worn item, looked up by its slot (the "bags are full" message uses it)
	Check(O:GetItemLocationLink({ SlotName = "HeadSlot" }) == env.GetInventoryItemLink("player", 1),
		"a worn item's link is found from its slot (got " .. tostring(O:GetItemLocationLink({ SlotName = "HeadSlot" })) .. ")")
end
NoErrors()

----------------------------------------
Step("an error during a gear change doesn't leave sound effects off")
do
	-- Outfitter mutes sound effects while it swaps gear (unless equip sounds are on)
	-- and the game saves that setting, so it must come back whatever happens
	local sounds = O.Settings.EnableEquipSounds
	O.Settings.EnableEquipSounds = nil
	W.cvars.Sound_EnableSFX = "1"
	local mutedDuringSwap
	local realEquip = W.Fakes.EquipCursorItem
	W.Fakes.EquipCursorItem = function(...) mutedDuringSwap = W.cvars.Sound_EnableSFX == "0" return realEquip(...) end
	O:WearOutfit(fishing)
	W.Tick(1)
	Check(mutedDuringSwap == true, "sound effects are muted during a swap")
	Check(W.cvars.Sound_EnableSFX == "1", "and back on after it")
	O:RemoveOutfit(fishing)
	W.Tick(1)
	NoErrors()
	-- The game refuses an equip part way through
	W.Fakes.EquipCursorItem = function() error("the game refused that") end
	local errorsBefore = #W.errors
	O:WearOutfit(fishing)
	W.Tick(1)
	Check(#W.errors > errorsBefore and tostring(W.errors[#W.errors]):find("the game refused that", 1, true) ~= nil,
		"the error is still reported")
	Check(W.cvars.Sound_EnableSFX == "1", "sound effects are back on after an error (Sound_EnableSFX is " .. tostring(W.cvars.Sound_EnableSFX) .. ")")
	reportedErrors = #W.errors   -- that error was the point
	W.Fakes.EquipCursorItem = realEquip
	env.ClearCursor()
	O:RemoveOutfit(fishing)
	W.Tick(1)
	O.Settings.EnableEquipSounds = sounds
end
NoErrors()

----------------------------------------
Step("the icon picker lists the icons of what you're wearing")
do
	local set = O.OutfitBar.TextureSets.Inventory
	set:Activate()
	local listed = {}
	for index = 1, set:GetNumTextures() do listed[set:GetIndexedTexture(index)] = true end
	Check(listed[env.GetInventoryItemTexture("player", 1)], "the helm's icon is offered")
	Check(listed[env.GetInventoryItemTexture("player", 16)], "the weapon's icon is offered")
	local bagItem = env.C_Container.GetContainerItemInfo(0, 1)
	Check(bagItem and listed[bagItem.iconFileID], "and the icons of the items in the bags")
	set:Deactivate()
end
NoErrors()

----------------------------------------
Step("Blizzard's globals are left alone, and the addon makes no stray globals")
for name in pairs(W.replacedBlizzardGlobals) do
	Fail("the addon replaced Blizzard's " .. name)
end
do
	-- Exercise the code that used to leave globals behind
	O:WearOutfitByName("Battle Gear")
	W.Tick(1)
	W.SafeCall(O.FindAndAddItemsToOutfit, O, O:NewEmptyOutfit("stray test"), nil, {}, O:GetInventoryCache())
	W.SafeCall(O.CreateEmptySpecialOccasionOutfit, O, nil, "Battle Gear")
	W.SafeCall(O.DebugStack, O)
	-- The UTF-8 library puts utf8reverse in the string table, where any addon can call it
	local _, reversed = W.SafeCall(env.string.utf8reverse, "a\226\130\172b")
	Check(reversed == "b\226\130\172a", "string.utf8reverse reverses text with a three-byte character (got " .. tostring(reversed) .. ")")
	-- A global with a name of the addon's own is fine: frames from the XML, saved
	-- variables, slash commands, key binding names and the libraries it ships.
	-- Anything else is a variable that was meant to be local (and "_" is the worst:
	-- Blizzard's own code uses it too).
	local own = { "^Outfitter", "^gOutfitter_", "^BINDING_", "^SLASH_", "^MC2UIElementsLib", "^BACKDROP_OUTFITTER_",
		"^LibStub$", "^utf8_", "^tern$" }
	local stray = {}
	for name in pairs(W.addonGlobals) do
		local mine = false
		for _, pattern in ipairs(own) do mine = mine or name:match(pattern) ~= nil end
		if not mine then stray[#stray + 1] = name end
	end
	table.sort(stray)
	Check(#stray == 0, "stray globals: " .. table.concat(stray, ", "))
end

-- Every texture of ours that the addon points at is in the folder
for _, file in ipairs({ "OutfitterForever.toc", "Outfitter.xml", "OutfitterBar.xml", "Outfitter.lua", "OutfitterLDB.lua",
		"OutfitterMinimapButton.lua", "OutfitterBar.lua", "OutfitterUITools.lua" }) do
	local text = io.open(file):read("*a")
	for path in text:gmatch("[Ii]nterface[\\/]+[Aa]dd[Oo]ns[\\/]+OutfitterForever[\\/]+([%w_%-\\/]+)") do
		path = path:gsub("\\\\", "/"):gsub("\\", "/")
		local found = io.open(path .. ".tga") or io.open(path .. ".blp")
		Check(found ~= nil, file .. " uses " .. path .. ", which isn't in the addon")
		if found then found:close() end
	end
end

-- Upstream's user manual and revision history describe Outfitter, not this port: they're
-- left out of the download, and nothing the addon loads may point into that folder
do
	local pkgmeta = io.open(".pkgmeta"):read("*a")
	Check(pkgmeta:find("\n  %- Documentation\n") ~= nil, ".pkgmeta leaves the Documentation folder out of the download")
	for _, file in ipairs({ "OutfitterForever.toc", "Outfitter.xml", "OutfitterBar.xml", "Outfitter.lua", "OutfitterLook.lua" }) do
		local text = io.open(file):read("*a")
		Check(not text:find("OutfitterForever[\\/]+Documentation"), file .. " points into the Documentation folder")
	end
end

----------------------------------------
Step("Outfitter never opens or closes the character window itself")
-- On Forever that's a Lua error in Blizzard's player frame code (and taints it),
-- so only the player opens the window; Outfitter opens with it.
local function LastPrinted() return tostring(W.printed[#W.printed] or "") end
if env.CharacterFrame:IsShown() then W.PlayerTogglesCharacter() end
env.OutfitterFrame:Hide()
W.Tick(0.2)
Check(not env.CharacterFrame:IsShown(), "character window closed")
local printedBefore = #W.printed
O:OpenUI()   -- "Open Outfitter" in the minimap menu, or the keybinding
W.Tick(0.2)
Check(not env.CharacterFrame:IsShown(), "Open Outfitter leaves the character window closed")
Check(not env.OutfitterFrame:IsVisible(), "and Outfitter isn't showing yet")
Check(#W.printed > printedBefore and LastPrinted():find("character window (C)", 1, true) ~= nil,
	"it says to open the character window, with the key for it (said: " .. LastPrinted() .. ")")
W.PlayerTogglesCharacter()
W.Tick(0.2)
Check(env.OutfitterFrame:IsVisible(), "Outfitter opens when you open the character window")
O:ToggleUI(true)   -- right-click on the minimap button
W.Tick(0.2)
Check(not env.OutfitterFrame:IsVisible(), "right-click closes Outfitter")
Check(env.CharacterFrame:IsShown(), "and leaves the character window open")
O:ToggleUI(true)
W.Tick(0.2)
Check(env.OutfitterFrame:IsVisible(), "right-click again opens Outfitter (the character window is open)")
env.OutfitterFrame:Hide()
W.PlayerTogglesCharacter()
W.Tick(0.2)
env.Outfitter_OnAddonCompartmentClick("OutfitterForever", "LeftButton")
W.Tick(0.2)
Check(not env.CharacterFrame:IsShown(), "the addon list button leaves the character window closed too")
W.PlayerTogglesCharacter()
W.Tick(0.2)
Check(env.OutfitterFrame:IsVisible(), "and Outfitter opens with it")
-- Asked a while ago and never opened the window: it doesn't pop open later
env.OutfitterFrame:Hide()
W.PlayerTogglesCharacter()
O:OpenUI()
W.Tick(90)
W.PlayerTogglesCharacter()
W.Tick(0.2)
Check(not env.OutfitterFrame:IsVisible(), "an old request doesn't open Outfitter out of the blue")
W.PlayerTogglesCharacter()
W.Tick(0.2)
NoErrors()

----------------------------------------
Step("right-click on the minimap button and broker")
-- Asked for by players: right-click can open Outfitter (it only prints a reminder
-- while the character window is closed), show the outfit menu, or swap between
-- two outfits picked in their menus
do
	local look = env.OutfitterFrame.Look
	local field = look.RightClick
	-- A stand-in for a menu that records what's added to it
	local function Recorder()
		local record = { functions = {}, toggles = {} }
		return setmetatable(record, { __index = function(_, key)
			return function(self, text, a, b)
				if key == "AddFunction" then record.functions[text] = a end
				if key == "AddToggle" then record.toggles[text] = { get = a, set = b } end
				return self
			end
		end })
	end
	local function MenuHasOpen()
		local items = Recorder()
		O:GetMinimapDropdownItems(items)
		return items.functions[O.cOpenOutfitter] ~= nil
	end
	local function TooltipSays(text)
		O:ShowBrokerTooltip(env.UIParent)
		for _, line in ipairs(env.GameTooltip.__lines or {}) do
			if line == text then return true end
		end
		return false
	end
	local minimapClick = env.OutfitterMinimapButton:GetScript("OnMouseUp") or env.OutfitterMinimapButton:GetScript("OnClick")
	local function RightClick() W.SafeCall(minimapClick, env.OutfitterMinimapButton, "RightButton") W.Tick(0.2) end
	if env.CharacterFrame:IsShown() then W.PlayerTogglesCharacter() end
	env.OutfitterFrame:Hide()
	W.Tick(0.2)

	-- Open (the default)
	Check(field and AnchoredTo(field:GetParent(), look.Cards[3]), "Options has the choice, in Quick access")
	field.Refresh()
	Check(O:RightClickAction() == "open" and field.text:GetText() == O.cLookRightClickOpen, "it opens Outfitter to start with")
	Check(TooltipSays(O.cLookTipOpen), "and the tooltip says so")
	Check(MenuHasOpen(), "the menu has Open Outfitter Forever")
	local printed = #W.printed
	RightClick()
	Check(#W.printed > printed, "with the character window closed it prints the reminder")
	O.OpenWithCharacterWindow = nil

	-- 1.4.2's switch, turned off, reads as the menu
	O.Settings.Options.DisableOpenShortcuts = true
	field.Refresh()
	Check(O:RightClickAction() == "menu" and field.text:GetText() == O.cLookRightClickMenu, "1.4.2's switch turned off means the menu")

	-- The menu field opens a menu, and closes it again
	field:Click()
	Check(field.list and field.list:IsShown(), "the choice opens a list")
	field:Click()
	Check(not field.list:IsShown(), "and closes it")

	-- Menu
	O:SetRightClickAction("menu")
	Check(O.Settings.Options.RightClick == "menu" and O.Settings.Options.DisableOpenShortcuts == nil, "picking the menu is saved")
	printed = #W.printed
	O.LDB:OnClick(nil, "RightButton")
	W.Tick(0.2)
	Check(O.LDB.dropDownMenu ~= nil and #W.printed == printed, "right-click on the broker shows the outfit menu")
	O.LDB:HideMenu()
	Check(not MenuHasOpen(), "and the menu leaves Open Outfitter Forever out while the character window is closed")
	Check(TooltipSays(O.cLookTipMenu), "the tooltip says right-click is the menu")

	-- Swap two outfits
	O:SetRightClickAction("swap")
	printed = #W.printed
	RightClick()
	Check(#W.printed > printed and tostring(W.printed[#W.printed]):find(O.cLookSwapNotSet, 1, true),
		"swap with no outfits picked says how to pick them")
	Check(TooltipSays(O.cLookTipSwapNotSet), "and so does the tooltip")
	local function Pick(outfit, label)
		local menu = Recorder()
		O:AddOutfitMenu(menu, outfit)
		local toggle = menu.toggles[label]
		Check(toggle ~= nil, "the outfit menu has " .. label)
		if toggle then toggle.set() end
		return toggle
	end
	Pick(battle, O.cLookSwapFirst)
	Pick(fishing, O.cLookSwapSecond)
	Check(battle.SwapSlot == 1 and fishing.SwapSlot == 2, "picking them is saved with the outfits")
	local first = Pick(fishing, O.cLookSwapFirst)
	Check(fishing.SwapSlot == 1 and battle.SwapSlot == nil, "an outfit can only be one of them: picking another first replaces it")
	Pick(battle, O.cLookSwapFirst)
	Pick(fishing, O.cLookSwapSecond)
	O:WearOutfit(battle)
	W.Tick(3)
	Check(TooltipSays(string.format(O.cLookTipSwap, fishing:GetName())), "wearing the first, the tooltip names the second")
	local errors = #W.uiErrors
	RightClick()
	W.Tick(3)
	Check(O:WearingOutfit(fishing), "right-click puts on the second outfit")
	Check(#W.uiErrors > errors, "with the message a key binding shows")
	O.LDB:OnClick(nil, "RightButton")
	W.Tick(3)
	Check(O:WearingOutfit(battle) and not O:WearingOutfit(fishing),
		"right-click on the broker puts the first back on, and the second (an accessory) comes off")
	Check(first and first.get() == false, "the menu shows which one is which")

	-- Back to the default for the rest
	O:SetRightClickAction("open")
	Check(O.Settings.Options.RightClick == nil, "open is the default, saved as nothing")
end
NoErrors()

----------------------------------------
Step("the Display tab: window size, text size and colors")
do
	local look = env.OutfitterFrame.Look
	if not env.CharacterFrame:IsShown() then W.PlayerTogglesCharacter() end
	if not env.OutfitterFrame:IsShown() then O:ToggleOutfitterFrame() end
	W.Tick(0.5)
	look.Tabs[3]:Click()
	W.Tick(0.2)
	Check(look.Display:IsVisible() and look.Tabs[3].on and not look.Tabs[1].on and not look.Tabs[2].on, "the Display tab opens and is lit")
	Check(not env.OutfitterMainFrame:IsShown() and not env.OutfitterOptionsFrame:IsShown(), "in place of Outfits and Options")

	-- A bigger window, and its dialogs and menus
	Check(look.DisplayPages[1]:IsVisible() and not look.DisplayPages[2]:IsVisible(), "it opens on Size and text")
	local windowSize = look.WindowSize
	windowSize.Slider:SetValue(150)
	Check(env.OutfitterFrame:GetScale() == 1, "the window doesn't change size while the slider is dragged")
	Check(windowSize.Box:GetText() == "150", "the box follows the slider")
	windowSize.Slider:GetScript("OnMouseUp")(windowSize.Slider)
	Check(env.OutfitterFrame:GetScale() == 1.5, "it does when the mouse lets go")
	-- Typed: any size in range, to two decimals, on Enter
	windowSize.Box:SetText("90.555")
	windowSize.Box:GetScript("OnEnterPressed")(windowSize.Box)
	Check(math.abs(env.OutfitterFrame:GetScale() - 0.9056) < 0.0001 and windowSize.Box:GetText() == "90.56",
		"typing 90.555 and Enter makes it 90.56% (" .. tostring(windowSize.Box:GetText()) .. ")")
	windowSize.Box:SetText("90,5")
	windowSize.Box:GetScript("OnEnterPressed")(windowSize.Box)
	Check(math.abs(env.OutfitterFrame:GetScale() - 0.905) < 0.0001, "a comma works as the decimal point")
	windowSize.Box:SetText("900")
	windowSize.Box:GetScript("OnEnterPressed")(windowSize.Box)
	Check(env.OutfitterFrame:GetScale() == 2 and windowSize.Box:GetText() == "200", "too big is the biggest size")
	windowSize.Box:SetText("big")
	windowSize.Box:GetScript("OnEnterPressed")(windowSize.Box)
	Check(env.OutfitterFrame:GetScale() == 2 and windowSize.Box:GetText() == "200", "something that isn't a number changes nothing")
	windowSize.Box:SetText("150")
	windowSize.Box:GetScript("OnEnterPressed")(windowSize.Box)
	O:OpenNameOutfitDialog(nil)
	W.Tick(0.2)
	Check(O.NameOutfitDialog:GetScale() == 1.5, "dialogs open at that size")
	O.NameOutfitDialog:Cancel()
	W.Tick(0.2)
	local Dropdown = env.LibStub("LibDropdownMC-1.0")
	local menu = env.CreateFrame("Frame")
	menu:SetScale(0.9)
	Dropdown.StyleFrame(menu)
	Check(math.abs(menu:GetScale() - 0.9 * 1.5) < 0.001, "and menus, on top of the tooltip size the menu library gives them")

	-- Bigger text
	local name = env.OutfitterItem0OutfitName
	local base = select(2, name:GetFont())
	look.TextSize.Box:SetText("130")
	look.TextSize.Box:GetScript("OnEnterPressed")(look.TextSize.Box)
	Check(math.abs(select(2, name:GetFont()) - base * 1.3) < 0.01, "130% text makes the window's text bigger")
	-- A font from the menu, in the window and the menus
	local font = look.Font
	Check(font.text:GetText() == O.cLookFontDefault, "the font is the game's to start with")
	font:Click()
	Check(font.list and font.list:IsShown(), "the font field opens a list")
	font:Click()
	env.gOutfitter_GlobalSettings.Display.Font = "Fonts\\MORPHEUS.ttf"
	look.TextSize.Box:GetScript("OnEnterPressed")(look.TextSize.Box)
	Check(name:GetFont() == "Fonts\\MORPHEUS.ttf", "a chosen font is used in the window")
	font.Refresh()
	Check(font.text:GetText() == "Morpheus", "and named in the field")
	local line = Dropdown.StyleButton and env.CreateFrame("Button")
	if line then
		line.text = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		Dropdown.StyleButton(line)
		Check(math.abs(select(2, line.text:GetFont()) - 12 * 1.3) < 0.01 and line.text:GetFont() == "Fonts\\MORPHEUS.ttf",
			"and the menus' text, in that font")
	end
	-- Options with bigger text: the window grows to fit the cards, and goes back after
	look.Tabs[2]:Click()
	W.Tick(0.2)
	look.OptionsSwitch[3]:Click() -- the longest page
	local last = look.Cards[#look.Cards]
	local point = last.__points[1]
	local bottom = -point[#point] + last:GetHeight()
	Check(bottom <= env.OutfitterFrame:GetHeight(), "Options with Larger text fits in the window ("
		.. bottom .. " of " .. tostring(env.OutfitterFrame:GetHeight()) .. ")")
	look.Tabs[1]:Click()
	W.Tick(0.2)
	Check(env.OutfitterFrame:GetHeight() == look.BaseHeight, "the Outfits tab is the window's own height")

	-- Color styles and your own colors show at once
	look.Tabs[3]:Click()
	W.Tick(0.2)
	look.DisplaySwitch[2]:Click()
	Check(look.DisplayPages[2]:IsVisible() and not look.DisplayPages[1]:IsVisible(), "the Colors page")
	local cardInner = (env.OutfitterFrame:GetWidth() or 256) - 16 - 24
	Check(math.abs(look.Swatches[2]:GetWidth() - (cardInner - 4) / 2) < 1, "the styles are two by two, each half the card wide")
	local C = O.Theme.C
	local defaultWin = { unpack(C.win) }
	local function Near(color, r, g, b) return math.abs(color[1] - r) < 0.002 and math.abs(color[2] - g) < 0.002 and math.abs(color[3] - b) < 0.002 end
	look.Swatches[3]:Click()
	Check(env.gOutfitter_GlobalSettings.Display.Colors == "blue", "picking Blue is saved")
	Check(Near(C.win, 0.055, 0.063, 0.085) and Near(look.Fill.__color, 0.055, 0.063, 0.085), "and the window turns blue at once")
	Check(Near(look.Header.bg.__color, 0.09, 0.23, 0.42), "its header too")
	Check(Near(look.Cards[1].title.__textColor or { 0, 0, 0 }, 0.5, 0.77, 1), "and the Options cards' titles")

	-- Your own colors, typed
	local own = look.OwnColors
	Check(own.background.Hex:GetText() == "#0E1016", "each own color shows the code in use (" .. tostring(own.background.Hex:GetText()) .. ")")
	own.background.Hex:SetText("203040")
	own.background.Hex:GetScript("OnEnterPressed")(own.background.Hex)
	Check(env.gOutfitter_GlobalSettings.Display.Custom.background == "#203040", "a typed code is saved")
	Check(Near(look.Fill.__color, 0x20 / 255, 0x30 / 255, 0x40 / 255), "and the window's background is that color at once")
	Check(own.background.Hex:GetText() == "#203040", "the box shows it with its #")
	own.background.Hex:SetText("zz")
	own.background.Hex:GetScript("OnEnterPressed")(own.background.Hex)
	Check(own.background.Hex:GetText() == "#203040" and Near(look.Fill.__color, 0x20 / 255, 0x30 / 255, 0x40 / 255),
		"something that isn't a color code changes nothing")
	own.buttons.Hex:SetText("#00FF00")
	own.buttons.Hex:GetScript("OnEnterPressed")(own.buttons.Hex)
	Check(Near(look.Close.bg.__color, 0, 1, 0), "buttons take the buttons color")
	own.text.Hex:SetText("#FFFF00")
	own.text.Hex:GetScript("OnEnterPressed")(own.text.Hex)
	Check(Near(look.Cards[1].rows[2].label.__textColor, 1, 1, 0), "option names take the text color")
	-- Right-click a swatch: back to the style's color
	own.background.Chip:GetScript("OnClick")(own.background.Chip, "RightButton")
	Check(env.gOutfitter_GlobalSettings.Display.Custom.background == nil and Near(look.Fill.__color, 0.055, 0.063, 0.085),
		"right-clicking a color goes back to the style's")
	-- Left-click without the game's color wheel (this client has none) puts you in the box
	own.headings.Chip:GetScript("OnClick")(own.headings.Chip, "LeftButton")
	Check(own.headings.Hex:HasFocus(), "clicking a color without a color wheel puts you in its box")
	own.headings.Hex:ClearFocus()

	-- Light, live: the game's gold outfit names turn dark, and back
	own.text.Chip:GetScript("OnClick")(own.text.Chip, "RightButton")
	look.Swatches[4]:Click()
	O:Update(true)
	local row
	for index = 0, O.cMaxDisplayedItems - 1 do
		local item = env["OutfitterItem" .. index]
		if item:IsShown() and not item.isCategory and item:GetOutfit() then row = item break end
	end
	local nameField = row and env[row:GetName() .. "OutfitName"]
	local r = nameField and nameField:GetTextColor()
	Check(r and r == C.title[1] and C.title[1] < 0.5, "Light: outfit names are dark at once")
	look.Swatches[1]:Click()
	O:Update(true)
	r = nameField and nameField:GetTextColor()
	Check(r and r > 0.5, "back to Default: they're light again")
	Check(next(env.gOutfitter_GlobalSettings.Display.Custom or {}) ~= nil, "your own colors stay through a style change")

	-- Reset
	look.DisplayReset:Click()
	Check(env.OutfitterFrame:GetScale() == 1 and select(2, name:GetFont()) == base and name:GetFont() ~= "Fonts\\MORPHEUS.ttf",
		"Reset puts the size, text and font back")
	Check(next(env.gOutfitter_GlobalSettings.Display) == nil, "and clears the saved choices")
	Check(Near(C.win, defaultWin[1], defaultWin[2], defaultWin[3]) and Near(look.Fill.__color, defaultWin[1], defaultWin[2], defaultWin[3]),
		"and the colors are the default ones again")
	look.Tabs[1]:Click()
	W.Tick(0.2)
	Check(not look.Display:IsShown() and env.OutfitterMainFrame:IsShown(), "the Outfits tab puts the Display tab away")
end
NoErrors()

----------------------------------------
Step("player feedback on 1.6: tooltip, reopening, fonts, colors, resets")
do
	local look = env.OutfitterFrame.Look
	local C = O.Theme.C
	local function Near(color, r, g, b) return math.abs(color[1] - r) < 0.002 and math.abs(color[2] - g) < 0.002 and math.abs(color[3] - b) < 0.002 end

	-- The broker's tooltip goes where the game puts tooltips (tooltip addons move it)
	env.GameTooltip.__defaultAnchor = nil
	O:ShowBrokerTooltip(env.UIParent)
	Check(env.GameTooltip.__defaultAnchor == env.UIParent, "the broker's tooltip uses the game's tooltip spot")

	-- Another tab of the character window, then back: Outfitter opens again
	if not env.CharacterFrame:IsShown() then W.PlayerTogglesCharacter() end
	if not env.OutfitterFrame:IsShown() then O:ToggleOutfitterFrame() end
	W.Tick(0.2)
	Check(O:IsOpen(), "Outfitter is open")
	env.PaperDollFrame:Hide() -- Reputation, say
	W.Tick(0.2)
	Check(not O:IsOpen(), "it closes with the character sheet")
	env.PaperDollFrame:Show()
	W.Tick(0.2)
	Check(O:IsOpen(), "and opens again when you're back on the sheet")
	-- Closed by you, it stays closed
	env.OutfitterFrame:Hide()
	env.PaperDollFrame:Hide()
	env.PaperDollFrame:Show()
	W.Tick(0.2)
	Check(not O:IsOpen(), "closed by you, it stays closed after another tab")
	-- Closing the whole window doesn't bring it back either
	O:ToggleOutfitterFrame()
	W.PlayerTogglesCharacter()
	W.PlayerTogglesCharacter()
	W.Tick(0.2)
	Check(not O:IsOpen(), "closing the character window doesn't open it next time")

	-- Open with the character window (an option)
	local openWith = look.OpenWithCharacter
	Check(openWith and AnchoredTo(openWith, look.Cards[3]) and not openWith:IsOn(), "Options has Open with the character window, off")
	openWith:Click()
	Check(O.Settings.Options.OpenWithCharacter == true and openWith:IsOn(), "switching it on is saved")
	W.PlayerTogglesCharacter()
	W.PlayerTogglesCharacter()
	W.Tick(0.2)
	Check(O:IsOpen(), "now Outfitter opens with the character window")
	openWith:Click()
	Check(O.Settings.Options.OpenWithCharacter == nil, "and off again")

	-- A long font list scrolls instead of running off the screen
	local media = env.LibStub:NewLibrary("LibSharedMedia-3.0", 1)
	local names = {}
	for i = 1, 25 do names[i] = string.format("Font %02d", i) end
	function media:List() return names end
	function media:Fetch(_, name) return "Fonts\\" .. name:gsub(" ", "") .. ".ttf" end
	look.Tabs[3]:Click()
	look.DisplaySwitch[2]:Click()
	W.Tick(0.2)
	local font = look.Font
	font:Click()
	local list = font.list
	Check(list and list:IsShown() and #list.rows == 26, "the font list has every font (" .. tostring(list and #list.rows) .. ")")
	Check(list and list:GetHeight() <= 10 * 18 + 6 and list.scroll.bar:IsShown(), "it shows ten at a time and scrolls")
	list.rows[20]:Click()
	Check(env.gOutfitter_GlobalSettings.Display.Font == "Fonts\\Font19.ttf" and not list:IsShown(), "picking one uses it and closes the list")
	local name = env.OutfitterItem0OutfitName
	Check(name:GetFont() == "Fonts\\Font19.ttf", "the window's text is in it")
	-- A font the game won't use: the text keeps its own instead of going blank
	local before = name:GetFont()
	env.gOutfitter_GlobalSettings.Display.Font = "Fonts\\Missing.ttf"
	look.TextSize.Box:GetScript("OnEnterPressed")(look.TextSize.Box)
	W.Tick(2)
	Check(name:GetFont() ~= nil and name:GetFont() ~= "Fonts\\Missing.ttf", "a font the game refuses leaves the text in its own font")
	Check(font.text:GetText() ~= nil, "and the font field still shows text")
	env.gOutfitter_GlobalSettings.Display.Font = "Fonts\\Font19.ttf"
	look.TextSize.Box:GetScript("OnEnterPressed")(look.TextSize.Box)
	W.Tick(2)
	-- A heading font of its own
	look.HeadingFont:Click()
	look.HeadingFont.list.rows[3]:Click()
	local category
	for index = 0, O.cMaxDisplayedItems - 1 do
		local item = env["OutfitterItem" .. index]
		if item:IsShown() and item.isCategory then category = env[item:GetName() .. "CategoryName"] break end
	end
	Check(category and category:GetFont() == "Fonts\\Font02.ttf" and name:GetFont() == "Fonts\\Font19.ttf",
		"headings take the heading font, the rest the font")
	Check(look.Header.text:GetFont() == "Fonts\\Font02.ttf", "the header bar is a heading")
	-- Outline
	look.Outline:Click()
	look.Outline.list.rows[3]:Click()
	Check(select(3, name:GetFont()) == "THICKOUTLINE", "a thick outline")
	-- Shadow
	look.Shadow:Click()
	Check(env.gOutfitter_GlobalSettings.Display.Shadow == true and look.Shadow:IsOn(), "the text shadow switch is saved")
	look.Shadow:Click()
	Check(env.gOutfitter_GlobalSettings.Display.Shadow == nil, "and off again")
	-- Each has its own reset
	look.Font.Reset:Click()
	Check(env.gOutfitter_GlobalSettings.Display.Font == nil and name:GetFont() ~= "Fonts\\Font19.ttf", "the font's reset button")
	Check(env.gOutfitter_GlobalSettings.Display.HeadingFont == "Fonts\\Font02.ttf", "leaves the heading font alone")
	look.HeadingFont.Reset:Click()
	look.Outline.Reset:Click()
	Check(env.gOutfitter_GlobalSettings.Display.Outline == nil and select(3, name:GetFont()) ~= "THICKOUTLINE", "the outline's reset button")
	look.DisplaySwitch[1]:Click()
	look.WindowSize.Box:SetText("120")
	look.WindowSize.Box:GetScript("OnEnterPressed")(look.WindowSize.Box)
	look.TextSize.Box:SetText("120")
	look.TextSize.Box:GetScript("OnEnterPressed")(look.TextSize.Box)
	look.WindowSize.Reset:Click()
	Check(env.gOutfitter_GlobalSettings.Display.Scale == nil and env.OutfitterFrame:GetScale() == 1
		and env.gOutfitter_GlobalSettings.Display.TextSize == 120, "the window size's reset button leaves the text size alone")
	look.TextSize.Reset:Click()
	Check(env.gOutfitter_GlobalSettings.Display.TextSize == nil, "the text size's reset button")

	-- Colors: the header has its own color; buttons and switches are edged in the highlight
	look.DisplaySwitch[3]:Click()
	local own = look.OwnColors
	own.buttons.Hex:SetText("#000000")
	own.buttons.Hex:GetScript("OnEnterPressed")(own.buttons.Hex)
	Check(Near(look.Close.bg.__color, 0, 0, 0) and not Near(look.Header.bg.__color, 0, 0, 0),
		"the buttons color doesn't change the header bar")
	own.header.Hex:SetText("#203040")
	own.header.Hex:GetScript("OnEnterPressed")(own.header.Hex)
	Check(Near(look.Header.bg.__color, 0x20 / 255, 0x30 / 255, 0x40 / 255), "the header has a color of its own")
	own.highlight.Hex:SetText("#FF8000")
	own.highlight.Hex:GetScript("OnEnterPressed")(own.highlight.Hex)
	local edged = 0
	for _, region in ipairs({ env.OutfitterShowOutfitBar:GetRegions() }) do
		if region:GetDrawLayer() == "BORDER" and region.__color and Near(region.__color, 1, 0x80 / 255, 0) then edged = edged + 1 end
	end
	Check(edged == 4, "switches are edged in the highlight color (" .. edged .. " edges)")
	own.header.Reset:Click()
	Check(env.gOutfitter_GlobalSettings.Display.Custom.header == nil, "each color has a reset button")
	look.DisplayReset:Click()
	Check(next(env.gOutfitter_GlobalSettings.Display) == nil, "Reset puts everything back")
	look.Tabs[1]:Click()
	W.Tick(0.2)

	-- The tabs sit inside the window's edge (they covered it at both ends)
	local frameWidth = env.OutfitterFrame:GetWidth() or 256
	local _, _, _, firstX = look.Tabs[1]:GetPoint(1)
	local _, _, _, lastX = look.Tabs[#look.Tabs]:GetPoint(1)
	Check(firstX == 1 and math.abs(lastX + look.Tabs[#look.Tabs]:GetWidth() - (frameWidth - 1)) < 0.01,
		"the tabs leave the window's edge showing on both sides")
	-- Edges are a whole screen pixel on every side (this client can't tell the
	-- screen's size, so they aren't snapped to the pixel grid)
	local unsnapped = 0
	for _, edge in ipairs(look.Edges) do
		if edge.__snap == false then unsnapped = unsnapped + 1 end
	end
	Check(unsnapped == 4, "the window's four edges are drawn the same on every side")
	-- On a real screen the edge is one screen pixel, and the tabs and the line
	-- under them sit exactly one pixel in: 1 unit is nearly 2 pixels on a 1440p
	-- screen, which left a dark gap between the edge and the tabs (1.8.1)
	rawset(env, "GetPhysicalScreenSize", function() return 2560, 1440 end)
	W.Fire("UI_SCALE_CHANGED")
	local pixel = 768 / 1440 / env.OutfitterFrame:GetEffectiveScale()
	local _, _, _, insetX = look.Tabs[1]:GetPoint(1)
	local _, _, _, endX = look.Tabs[#look.Tabs]:GetPoint(1)
	Check(math.abs(insetX - pixel) < 0.0001, "the first tab starts one screen pixel in (at " .. tostring(insetX) .. ")")
	Check(math.abs(endX + look.Tabs[#look.Tabs]:GetWidth() - (frameWidth - pixel)) < 0.0001,
		"and the last ends one screen pixel in")
	Check(math.abs(look.Edges[3]:GetWidth() - pixel) < 0.0001, "the edge beside them is that one pixel")
	rawset(env, "GetPhysicalScreenSize", nil)
	W.Fire("UI_SCALE_CHANGED")
end
NoErrors()

----------------------------------------
Step("a tooltip line with no text (another addon blanked it)")
-- Reported with Remove Sell Price NG, which empties the sell price line:
-- reading the item's tooltip was a Lua error that stopped Outfitter
do
	local info = setmetatable({}, { __index = O._ItemInfo })
	local ok, message = pcall(info.ParseTooltipLine, info, nil, { r = 1, g = 1, b = 1 })
	Check(ok, "a line with no text is skipped (" .. tostring(message) .. ")")
	info:ParseTooltipLine(env.ITEM_BIND_ON_EQUIP, { r = 1, g = 1, b = 1 })
	Check(info.BoE == true, "the other lines are still read")
end
NoErrors()

for name in pairs(W.replacedBlizzardScripts) do
	Fail("the addon set (instead of hooking) the script " .. name .. " on Blizzard's frame")
end
for name in pairs(W.fakeNotOnForever) do
	Fail("the addon used " .. name .. ", which the tests fake but Forever doesn't have")
end

local missing = {}
for name in pairs(W.unstubbed) do missing[#missing + 1] = name end
table.sort(missing)
print("[LE " .. expansionLevel .. "] Forever API called without a fake: " .. table.concat(missing, ", "))
local warnings = {}
for message in pairs(W.warnings) do warnings[#warnings + 1] = message end
table.sort(warnings)
for _, message in ipairs(warnings) do print("[LE " .. expansionLevel .. "] warning: " .. message) end

NoErrors()
return failures
