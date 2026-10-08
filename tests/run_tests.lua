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
Check(O.LDB.DataObj.icon == logo, "the data broker icon is the logo too")
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
O:WearOutfit(fishing)
W.Tick(1)
Check(W.equipped[1] == 1001, "armor isn't changed in combat")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Tick(3)
Check(W.equipped[1] == 1002, "the outfit goes on after combat (head has " .. tostring(W.equipped[1]) .. ")")
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
	for index, card in ipairs(look.Cards or {}) do
		Check(card:IsVisible(), "option card " .. index .. " shows")
	end
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

	-- The scripts switch in the footer turns all outfit scripts off and on
	Check(look.Scripts:IsOn() == not O.Settings.Options.DisableAutoSwitch, "the scripts switch shows the setting")
	look.Scripts:Click()
	Check(O.Settings.Options.DisableAutoSwitch and not look.Scripts:IsOn(), "switching it off stops outfit scripts")
	look.Scripts:Click()
	Check(not O.Settings.Options.DisableAutoSwitch and look.Scripts:IsOn(), "switching it on runs them again")

	-- Options has the same switch, reading the same way (on = scripts run), not
	-- Outfitter's "Disable all outfit scripts" box, which was on when they were off
	O:ShowPanel(2)
	W.Tick(0.2)
	local optionsScripts = look.OptionsScripts
	Check(optionsScripts and optionsScripts:IsVisible(), "Options has an Outfit scripts switch")
	Check(not env.OutfitterAutoSwitch:IsVisible(), "instead of the Disable all outfit scripts box")
	if optionsScripts then
		Check(optionsScripts.label:GetText() == O.cLookOutfitScripts, "named like the footer's")
		Check(optionsScripts:IsOn() and not O.Settings.Options.DisableAutoSwitch, "on while scripts run")
		optionsScripts:Click()
		W.Tick(0.1)
		Check(O.Settings.Options.DisableAutoSwitch and not optionsScripts:IsOn(), "switching it off stops outfit scripts")
		Check(not look.Scripts:IsOn(), "and the footer's switch follows")
		look.Scripts:Click()
		W.Tick(0.1)
		Check(not O.Settings.Options.DisableAutoSwitch and optionsScripts:IsOn(), "the footer's switch turns it back on")
	end
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
			Check(not tab:IsShown(), "the tab is gone, uncovering the game's Equipment Manager tab")
			Check(env.OutfitterButton:IsShown(), "and the small button is back")
			W.PlayerTogglesCharacter()
			W.PlayerTogglesCharacter()
			Check(not tab:IsShown() and env.OutfitterButton:IsShown(), "it stays that way")
			O:ToggleOutfitterFrame()
			O:ShowPanel(2)
			W.Tick(0.2)
			Check(not box:GetChecked(), "the checkbox shows it's off")
			box:Click()
			Check(O.Settings.Options.DisableSidebarTab == false, "ticking it again is saved")
			Check(tab:IsVisible() and not env.OutfitterButton:IsShown(), "and the tab is back")
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
