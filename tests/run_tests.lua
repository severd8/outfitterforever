-- The scenarios. Loaded fresh for each expansion level by tests/run.lua.
local expansionLevel = ...

-- Each run gets a clean client
_G.W = nil
local W = dofile("tests/wow.lua")
W.expansionLevel = expansionLevel
dofile("tests/fakes.lua")
local env = W.env

local failures = 0
local currentStep = "start"
local function Fail(message)
	failures = failures + 1
	print(string.format("FAIL [LE %d] %s: %s", expansionLevel, currentStep, message))
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
env.ToggleCharacter("PaperDollFrame")
O:ToggleOutfitterFrame()
W.Tick(1)
Check(env.OutfitterFrame:IsVisible(), "Outfitter window is open")
for panel = 1, 3 do
	O:ShowPanel(panel)
	W.Tick(0.2)
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
W.SafeCall(env.GameTooltip_ShowCompareItem, env.GameTooltip)
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
Step("Blizzard's globals are left alone")
for name in pairs(W.replacedBlizzardGlobals) do
	Fail("the addon replaced Blizzard's " .. name)
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
