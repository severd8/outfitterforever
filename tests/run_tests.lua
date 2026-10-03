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
Step("options and the outfit bar")
O:ShowPanel(2)
W.Tick(0.2)
for _, frame in ipairs(W.frames) do
	local name = frame.__name
	if name and frame.__type == "CheckButton" and name:match("^Outfitter") and frame:IsVisible() and not name:match("^OutfitterEnable") then
		frame:Click()
		W.Tick(0.1)
		frame:Click()
	end
end
O:ShowPanel(1)
W.Tick(0.5)

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
