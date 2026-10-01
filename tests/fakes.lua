-- The game the tests play in: a level 60 character on WoW: Forever with some
-- gear, bags, a cursor that moves items like the real one, and the Blizzard
-- frames Outfitter attaches to. Values Forever hides from addons are secrets.

local W = W
local env = W.env
local F = W.Fakes

----------------------------------------
-- Client
----------------------------------------
F.WOW_PROJECT_ID = 1
F.WOW_PROJECT_MAINLINE = 1
F.WOW_PROJECT_CLASSIC = 2
F.LE_EXPANSION_CLASSIC = 0
F.LE_EXPANSION_BURNING_CRUSADE = 1
F.LE_EXPANSION_WRATH_OF_THE_LICH_KING = 2
F.LE_EXPANSION_CATACLYSM = 3
F.LE_EXPANSION_MISTS_OF_PANDARIA = 4
F.LE_EXPANSION_WARLORDS_OF_DRAENOR = 5
F.LE_EXPANSION_LEGION = 6
F.LE_EXPANSION_BATTLE_FOR_AZEROTH = 7
F.LE_EXPANSION_SHADOWLANDS = 8
F.LE_EXPANSION_DRAGONFLIGHT = 9
F.LE_EXPANSION_WAR_WITHIN = 10
F.LE_EXPANSION_MIDNIGHT = 11
-- What Forever reports here isn't known; the tests run with both
F.LE_EXPANSION_LEVEL_CURRENT = W.expansionLevel or 0

function F.GetBuildInfo() return "1.60.1", "70124", "Sep 30 2026", 16001, "", "", 16001 end
function F.GetTime() return W.time end
function F.GetServerTime() return math.floor(W.time) end
function F.debugprofilestop() return W.time * 1000 end
function F.GetLocale() return "enUS" end
function F.GetRealmName() return "Forever" end
function F.GetNormalizedRealmName() return "Forever" end
function F.GetCurrentRegion() return 1 end
function F.InCombatLockdown() return W.combat end
function F.IsLoggedIn() return W.loggedIn or false end
function F.UnitAffectingCombat() return W.combat end
function F.issecretvalue(v) return W.IsSecret(v) end
function F.canaccessvalue(v) return not W.IsSecret(v) end
function F.canaccesssecrets() return not W.combat end
function F.geterrorhandler() return function(m) table.insert(W.errors, tostring(m)) end end
function F.seterrorhandler() end
function F.debugstack() return "" end
function F.securecall(fn, ...) if type(fn) == "string" then fn = env[fn] end return fn(...) end
function F.issecure() return true end
function F.securecallfunction(fn, ...) return fn(...) end
function F.getglobal(name) return env[name] end
function F.setglobal(name, value) env[name] = value end
function F.wipe(t) for k in pairs(t) do t[k] = nil end return t end
table.wipe = F.wipe
function F.tContains(t, v) for _, x in pairs(t) do if x == v then return true end end return false end
function F.strtrim(s, chars)
	chars = chars or " \t\r\n"
	local pattern = "[" .. chars:gsub("[%]%^%-]", "%%%0") .. "]"
	return (s:gsub("^" .. pattern .. "+", ""):gsub(pattern .. "+$", ""))
end
function F.strsplit(delimiter, text, pieces)
	local result = {}
	local start = 1
	while true do
		if pieces and #result == pieces - 1 then break end
		local i, j = text:find("[" .. delimiter .. "]", start)
		if not i then break end
		table.insert(result, text:sub(start, i - 1))
		start = j + 1
	end
	table.insert(result, text:sub(start))
	return unpack(result)
end
function F.strjoin(delimiter, ...) return table.concat({ ... }, delimiter) end
function F.strconcat(...) return table.concat({ ... }) end
function F.tostringall(...) local t = {} for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end return unpack(t) end
function F.CopyTable(t) local c = {} for k, v in pairs(t) do c[k] = type(v) == "table" and F.CopyTable(v) or v end return c end
function F.Mixin(object, ...)
	for i = 1, select("#", ...) do
		for k, v in pairs((select(i, ...))) do object[k] = v end
	end
	return object
end
function F.CreateFromMixins(...) return F.Mixin({}, ...) end
function F.hooksecurefunc(tableOrName, name, hook)
	local tbl = env
	if type(tableOrName) == "table" then tbl = tableOrName else name, hook = tableOrName, name end
	local original = tbl[name]
	assert(type(original) == "function", "hooksecurefunc: no function " .. tostring(name))
	rawset(tbl, name, function(...)
		local results = { original(...) }
		hook(...)
		return unpack(results)
	end)
end

F.C_Timer = {
	After = function(seconds, fn) table.insert(W.timers, { at = W.time + seconds, fn = fn }) end,
	NewTimer = function(seconds, fn)
		local timer = { at = W.time + seconds, fn = fn }
		timer.Cancel = function(t) t.cancelled = true end
		table.insert(W.timers, timer)
		return timer
	end,
	NewTicker = function(seconds, fn)
		local ticker = { Cancel = function(t) t.cancelled = true end }
		local function Schedule()
			table.insert(W.timers, { at = W.time + seconds, fn = function() if not ticker.cancelled then fn(ticker) Schedule() end end })
		end
		Schedule()
		return ticker
	end,
}

F.C_AddOns = {
	GetAddOnMetadata = function(addon, field)
		assert(addon == W.addonName, "metadata asked for addon " .. tostring(addon))
		for line in io.lines(W.addonName .. ".toc") do
			local key, value = line:gsub("\r", ""):match("^## ([%w%-]+): (.*)$")
			if key == field then return value end
		end
	end,
	IsAddOnLoaded = function(addon) return addon == W.addonName end,
	GetAddOnInfo = function(addon) return addon, addon, "", true, "INSECURE", false end,
	GetNumAddOns = function() return 1 end,
	LoadAddOn = function() return false, "MISSING" end,
	GetAddOnEnableState = function() return 2 end,
}

function F.GetCVar(name) return W.cvars[name] end
function F.SetCVar(name, value) W.cvars[name] = tostring(value) end
function F.GetCVarBool(name) return W.cvars[name] == "1" end
F.C_CVar = { GetCVar = F.GetCVar, SetCVar = F.SetCVar, GetCVarBool = F.GetCVarBool, RegisterCVar = function() end,
	GetCVarDefault = function() return nil end }

F.SOUNDKIT = setmetatable({}, { __index = function() return 1 end })
function F.PlaySound() return true end
function F.PlaySoundFile() return true end

local function EnumTable(name)
	local n = 0
	return setmetatable({}, { __index = function(t, key) n = n + 1 rawset(t, key, 900 + n) return 900 + n end })
end
F.Enum = setmetatable({
	SpellBookSpellBank = { Player = 0, Pet = 1 },
	TooltipDataType = { Item = 0, Spell = 1, Unit = 2 },
	ItemClass = { Weapon = 2, Armor = 4, Container = 1, Consumable = 0, Projectile = 6, Quiver = 11 },
	PlayerInteractionType = { Banker = 8, Merchant = 5, GuildBanker = 10, VoidStorageBanker = 26, Transmogrifier = 32, ItemUpgrade = 33, MailInfo = 17 },
	BagIndex = { Backpack = 0, Bag_1 = 1, Bag_2 = 2, Bag_3 = 3, Bag_4 = 4, Bank = -1, ReagentBag = 5 },
	ItemQuality = { Poor = 0, Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Artifact = 6, Heirloom = 7 },
	SeasonID = { SeasonOfDiscovery = 2 },
}, { __index = function(t, key) local e = EnumTable(key) rawset(t, key, e) return e end })

local function Color(r, g, b, a)
	local c = { r = r, g = g, b = b, a = a or 1 }
	c.GetRGB = function(self) return self.r, self.g, self.b end
	c.GetRGBA = function(self) return self.r, self.g, self.b, self.a end
	c.GenerateHexColor = function(self) return string.format("ff%02x%02x%02x", self.r * 255, self.g * 255, self.b * 255) end
	c.GenerateHexColorMarkup = function(self) return "|c" .. self:GenerateHexColor() end
	c.WrapTextInColorCode = function(self, text) return "|c" .. self:GenerateHexColor() .. text .. "|r" end
	c.colorStr = c:GenerateHexColor()
	c.hex = "|c" .. c.colorStr
	return c
end
F.CreateColor = Color
F.NORMAL_FONT_COLOR = Color(1, 0.82, 0)
F.HIGHLIGHT_FONT_COLOR = Color(1, 1, 1)
F.GRAY_FONT_COLOR = Color(0.5, 0.5, 0.5)
F.RED_FONT_COLOR = Color(1, 0.1, 0.1)
F.GREEN_FONT_COLOR = Color(0.1, 1, 0.1)
F.NORMAL_FONT_COLOR_CODE = "|cffffd200"
F.HIGHLIGHT_FONT_COLOR_CODE = "|cffffffff"
F.GRAY_FONT_COLOR_CODE = "|cff808080"
F.RED_FONT_COLOR_CODE = "|cffff2020"
F.GREEN_FONT_COLOR_CODE = "|cff20ff20"
F.FONT_COLOR_CODE_CLOSE = "|r"
F.ITEM_QUALITY_COLORS = {}
for q = 0, 8 do
	local c = Color(0.5 + q * 0.05, 0.5, 0.5)
	c.color = c
	F.ITEM_QUALITY_COLORS[q] = c
end
F.LOCALIZED_CLASS_NAMES_MALE = { WARRIOR = "Warrior", HUNTER = "Hunter", DRUID = "Druid", ROGUE = "Rogue", PRIEST = "Priest", MAGE = "Mage", WARLOCK = "Warlock", PALADIN = "Paladin", SHAMAN = "Shaman" }
F.LOCALIZED_CLASS_NAMES_FEMALE = F.LOCALIZED_CLASS_NAMES_MALE

-- Numbers Blizzard's UI defines
F.NUM_BAG_SLOTS = 4
F.NUM_TOTAL_EQUIPPED_BAG_SLOTS = 4
F.NUM_BANKBAGSLOTS = 6
F.NUM_CHAT_WINDOWS = 10
F.INVSLOT_FIRST_EQUIPPED = 1
F.INVSLOT_LAST_EQUIPPED = 19
F.MAX_EQUIPMENT_SETS_PER_PLAYER = 10
F.MAX_SKILLLINE_TABS = 8
F.BOOKTYPE_SPELL = "spell"
F.ITEM_INVENTORY_LOCATION_PLAYER = 0x00100000
F.ITEM_INVENTORY_LOCATION_BAGS = 0x00200000
F.ITEM_INVENTORY_LOCATION_BANK = 0x00400000
F.ITEM_INVENTORY_BANK_BAG_OFFSET = 4
F.ITEM_INVENTORY_BAG_BIT_OFFSET = 8
F.EQUIPMENTFLYOUT_PLACEINBAGS_LOCATION = 0xFFFFFFFF
F.INV_MISC_QUESTIONMARK = 134400

F.StaticPopupDialogs = {}
F.UISpecialFrames = {}
F.SlashCmdList = {}
F.UIMenus = {}
W.popups = {}
function F.StaticPopup_Show(which, ...) table.insert(W.popups, which) return W.NewFrame("Frame", nil, nil) end
function F.StaticPopup_Hide() end

----------------------------------------
-- Player
----------------------------------------
W.player = W.player or { class = "WARRIOR", className = "Warrior", classID = 1, spec = 1, form = 0, level = 60 }

function F.UnitName(unit)
	if unit == "player" then return "Tester", nil end
	if unit == "target" then return W.target end
	return nil
end
function F.UnitClass(unit) return W.player.className, W.player.class, W.player.classID end
function F.UnitClassBase(unit) return W.player.class, W.player.classID end
function F.UnitRace() return "Human", "Human", 1 end
function F.UnitLevel() return W.player.level end
function F.UnitSex() return 2 end
function F.UnitFactionGroup() return "Alliance", "Alliance" end
function F.UnitGUID(unit) return unit == "player" and "Player-1-00000001" or nil end
function F.UnitIsUnit(a, b) return a == b end
function F.UnitExists(unit) return unit == "player" or (unit == "target" and W.target ~= nil) end
function F.UnitIsDeadOrGhost() return false end
function F.UnitIsDead() return false end
function F.UnitIsGhost() return false end
function F.UnitOnTaxi() return false end
function F.UnitIsPVP() return false end
function F.UnitInBattleground() return nil end
function F.UnitInRaid() return nil end
function F.UnitInParty() return false end
function F.IsInGroup() return false end
function F.IsInRaid() return false end
function F.IsMounted() return W.mounted or false end
function F.IsSwimming() return W.swimming or false end
function F.IsSubmerged() return W.swimming or false end
function F.IsFlying() return false end
function F.IsFalling() return false end
function F.IsResting() return false end
function F.IsStealthed() return false end
function F.IsInInstance() return W.instance ~= nil, W.instance or "none" end
function F.GetInstanceInfo() return "Elwynn Forest", W.instance or "none", 0, "", 5, 0, false, 0, 0 end
function F.GetRealZoneText() return "Elwynn Forest" end
function F.GetZoneText() return "Elwynn Forest" end
function F.GetSubZoneText() return "" end
function F.GetMinimapZoneText() return "Goldshire" end
function F.GetZonePVPInfo() return "friendly" end
function F.IsShiftKeyDown() return false end
function F.IsControlKeyDown() return false end
function F.IsAltKeyDown() return false end
function F.IsModifierKeyDown() return false end
function F.IsModifiedClick() return false end
function F.GetCursorPosition() return 500, 500 end
function F.GetScreenWidth() return 1920 end
function F.GetScreenHeight() return 1080 end
function F.GetMouseFoci() return {} end
function F.GetMoney() return 100000 end
function F.InRepairMode() return false end

-- Hidden from addons on Forever
function F.UnitHealth(unit) return W.secretHealthAndMana and W.Secret(2500) or 2500 end
function F.UnitHealthMax(unit) return 3000 end
function F.UnitPower(unit) return W.secretHealthAndMana and W.Secret(500) or 500 end
function F.UnitPowerMax(unit) return 1000 end -- your own maximums stay readable on Forever
function F.UnitPowerType(unit) return W.player.class == "WARRIOR" and 1 or 0, "RAGE" end
function F.UnitStat(unit, index) return 100, 100, 0, 0 end
function F.UnitArmor() return 3000, 3000, 3000, 0, 0 end
function F.GetDodgeChance() return 5 end
function F.GetParryChance() return 5 end
function F.GetBlockChance() return 5 end
function F.GetCombatRating() return 0 end
function F.GetCombatRatingBonus() return 0 end

-- Stances
local FORMS = {
	WARRIOR = { { 132349, 2457 }, { 132341, 71 }, { 132275, 2458 } },
	DRUID = { { 132276, 5487 }, { 132115, 768 }, { 132144, 783 } },
}
function F.GetNumShapeshiftForms() return #(FORMS[W.player.class] or {}) end
function F.GetShapeshiftForm() return W.player.form end
function F.GetShapeshiftFormInfo(index)
	local form = (FORMS[W.player.class] or {})[index]
	if not form then return nil end
	return form[1], W.player.form == index, true, form[2]
end
function F.GetShapeshiftFormID() return nil end

-- Specializations are talent trees on Forever
local SPECS = { WARRIOR = { "Arms", "Fury", "Protection" }, DRUID = { "Balance", "Feral Combat", "Restoration" }, HUNTER = { "Beast Mastery", "Marksmanship", "Survival" } }
F.C_SpecializationInfo = {
	GetSpecialization = function() return W.player.spec end,
	GetSpecializationInfo = function(index)
		local name = (SPECS[W.player.class] or {})[index]
		if not name then return 0, nil end
		return 9000 + index, name, "", 130000 + index, "DAMAGER", 1, 0
	end,
	GetActiveSpecGroup = function() return 1 end,
	GetNumSpecializationsForClassID = function() return 3 end,
	IsInitialized = function() return true end,
}
function F.GetNumSpecializations() return 3 end
function F.GetSpecializationInfoForClassID(classID, index)
	local name = (SPECS[W.player.class] or {})[index]
	if not name then return nil end
	return 9000 + index, name, "", 130000 + index, "DAMAGER", true, true
end

-- Auras: Forever throws instead of answering in combat
W.auras = W.auras or {}
local function AuraCheck()
	if W.combat then error("Auras cannot be accessed when secret while tainted by 'OutfitterForever'", 3) end
end
-- An aura with harmful = true is a debuff
local function AuraList(harmful)
	local list = {}
	for _, aura in ipairs(W.auras) do
		if (aura.harmful or false) == harmful then list[#list + 1] = aura end
	end
	return list
end
local function IsHarmfulFilter(filter) return type(filter) == "string" and filter:find("HARMFUL") ~= nil end
F.C_UnitAuras = {
	GetBuffDataByIndex = function(unit, index) AuraCheck() return unit == "player" and AuraList(false)[index] or nil end,
	GetAuraDataByIndex = function(unit, index, filter) AuraCheck() return unit == "player" and AuraList(IsHarmfulFilter(filter))[index] or nil end,
	GetAuraDataBySpellName = function(unit, name, filter)
		AuraCheck()
		for _, aura in ipairs(AuraList(IsHarmfulFilter(filter))) do if aura.name == name then return aura end end
		return nil
	end,
	GetPlayerAuraBySpellID = function(id)
		AuraCheck()
		for _, aura in ipairs(W.auras) do if aura.spellId == id then return aura end end
	end,
}

----------------------------------------
-- Items
----------------------------------------
-- id = { name, equipLoc, type, subtype, classID, subclassID, quality, level }
W.itemDB = {
	[1001] = { "Lion Helm", "INVTYPE_HEAD", "Armor", "Plate", 4, 4, 3, 55 },
	[1002] = { "Fishing Hat", "INVTYPE_HEAD", "Armor", "Cloth", 4, 1, 1, 20 },
	[1003] = { "Plate Chest", "INVTYPE_CHEST", "Armor", "Plate", 4, 4, 3, 58 },
	[1004] = { "Tuxedo Shirt", "INVTYPE_ROBE", "Armor", "Cloth", 4, 1, 1, 10 },
	[1005] = { "Iron Boots", "INVTYPE_FEET", "Armor", "Plate", 4, 4, 2, 50 },
	[1006] = { "Riding Boots", "INVTYPE_FEET", "Armor", "Leather", 4, 2, 2, 30 },
	[1007] = { "Big Sword", "INVTYPE_2HWEAPON", "Weapon", "Two-Handed Swords", 2, 8, 3, 60 },
	[1008] = { "Short Sword", "INVTYPE_WEAPON", "Weapon", "One-Handed Swords", 2, 7, 2, 50 },
	[1009] = { "Tower Shield", "INVTYPE_SHIELD", "Armor", "Shields", 4, 6, 3, 58 },
	[1010] = { "Long Bow", "INVTYPE_RANGED", "Weapon", "Bows", 2, 2, 2, 55 },
	[1011] = { "Fishing Pole", "INVTYPE_2HWEAPON", "Weapon", "Fishing Poles", 2, 20, 1, 1 },
	[1012] = { "Band of Might", "INVTYPE_FINGER", "Armor", "Miscellaneous", 4, 0, 3, 60 },
	[1013] = { "Ring of Luck", "INVTYPE_FINGER", "Armor", "Miscellaneous", 4, 0, 2, 40 },
	[1014] = { "Lucky Charm", "INVTYPE_TRINKET", "Armor", "Miscellaneous", 4, 0, 3, 55 },
	[1015] = { "Wand of Sparks", "INVTYPE_RANGEDRIGHT", "Weapon", "Wands", 2, 19, 2, 40 },
	[1016] = { "Heavy Linen Bandage", "", "Consumable", "Bandage", 0, 7, 1, 1 },
}
function W.ItemLink(id)
	local item = W.itemDB[id]
	if not item then return nil end
	return string.format("|cff1eff00|Hitem:%d::::::::60:::::::::|h[%s]|h|r", id, item[1])
end
function W.ItemIDFromLink(link)
	if type(link) == "number" then return link end
	if type(link) ~= "string" then return nil end
	return tonumber(link:match("item:(%d+)"))
end
local function ItemID(item)
	if type(item) == "number" then return item end
	if type(item) == "string" then
		local id = W.ItemIDFromLink(item)
		if id then return id end
		for itemID, info in pairs(W.itemDB) do
			if info[1] == item then return itemID end
		end
	end
	return nil
end

F.C_Item = {
	GetItemInfo = function(item)
		local id = ItemID(item)
		local info = id and W.itemDB[id]
		if not info then return nil end
		return info[1], W.ItemLink(id), info[7], info[8], 1, info[3], info[4], info[2] == "" and 20 or 1, info[2], 133000 + id, 100, info[5], info[6]
	end,
	GetItemInfoInstant = function(item)
		local id = ItemID(item)
		local info = id and W.itemDB[id]
		if not info then return nil end
		return id, info[3], info[4], info[2], 133000 + id, info[5], info[6]
	end,
	GetItemNameByID = function(id) return W.itemDB[id] and W.itemDB[id][1] end,
	GetItemIconByID = function(id) return 133000 + id end,
	GetItemIDForItemInfo = function(item) return ItemID(item) end,
	GetItemGem = function() return nil end,
	GetItemFamily = function() return 0 end,
	GetItemCount = function() return 1 end,
	GetItemQualityColor = function(quality) local c = F.ITEM_QUALITY_COLORS[quality] return c.r, c.g, c.b, c.colorStr end,
	GetItemStats = function() return {} end,
	IsEquippableItem = function(item) local id = ItemID(item) return id and W.itemDB[id] and W.itemDB[id][2] ~= "" end,
	GetItemCooldown = function() return 0, 0, 1 end,
	GetItemSpell = function() return nil end,
	RequestLoadItemDataByID = function() end,
	DoesItemExistByID = function(id) return W.itemDB[id] ~= nil end,
	IsItemDataCachedByID = function() return true end,
	GetItemLink = function() return nil end,
	GetItemUniqueness = function() return nil end,
	GetDetailedItemLevelInfo = function(item) local id = ItemID(item) return id and W.itemDB[id][8] end,
	GetCurrentItemLevel = function() return 50 end,
	DoesItemExist = function(location) return W.LocationItem(location) ~= nil end,
	GetItemID = function(location) return W.LocationItem(location) end,
	GetItemLocation = function() return nil end,
	IsBound = function() return true end,
	IsLocked = function(location) return W.cursor ~= nil and W.cursor.from.slot == location.loc.slot and W.cursor.from.bag == location.loc.bag end,
	GetItemQuality = function(location) local id = W.LocationItem(location) return id and W.itemDB[id][7] end,
}

-- Equipment and bags
local SLOTS = {
	AmmoSlot = 0, HeadSlot = 1, NeckSlot = 2, ShoulderSlot = 3, ShirtSlot = 4, ChestSlot = 5, WaistSlot = 6, LegsSlot = 7,
	FeetSlot = 8, WristSlot = 9, HandsSlot = 10, Finger0Slot = 11, Finger1Slot = 12, Trinket0Slot = 13, Trinket1Slot = 14,
	BackSlot = 15, MainHandSlot = 16, SecondaryHandSlot = 17, RangedSlot = 18, TabardSlot = 19,
	Bag0Slot = 31, Bag1Slot = 32, Bag2Slot = 33, Bag3Slot = 34,
}
W.SLOTS = SLOTS
local FITS = {
	INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_BODY = { 4 }, INVTYPE_CHEST = { 5 },
	INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 },
	INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
	INVTYPE_WEAPON = { 16, 17 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_WEAPONOFFHAND = { 17 },
	INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 }, INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 },
	INVTYPE_THROWN = { 18 }, INVTYPE_RELIC = { 18 }, INVTYPE_TABARD = { 19 },
}
local function Fits(id, slot)
	local info = W.itemDB[id]
	for _, s in ipairs(FITS[info and info[2] or ""] or {}) do
		if s == slot then return true end
	end
	return false
end

W.equipped = W.equipped or {}
W.bags = W.bags or {}
W.bagSizes = { [0] = 16, [1] = 16, [2] = 0, [3] = 0, [4] = 0 }
W.pendingEvents = {}
W.uiErrors = {}

local function QueueEvent(event, ...)
	table.insert(W.pendingEvents, { event, ... })
end
local function FlushEvents()
	local events = W.pendingEvents
	W.pendingEvents = {}
	for _, e in ipairs(events) do W.Fire(unpack(e)) end
end
W.FlushEvents = FlushEvents
local oldTick = W.Tick
function W.Tick(seconds, step)
	FlushEvents()
	oldTick(seconds, step)
	FlushEvents()
end

local function Get(loc)
	if loc.slot then return W.equipped[loc.slot] end
	local stack = W.bags[loc.bag] and W.bags[loc.bag][loc.bagSlot]
	return stack and stack.id
end
local function Set(loc, id)
	if loc.slot then
		W.equipped[loc.slot] = id
		QueueEvent("PLAYER_EQUIPMENT_CHANGED", loc.slot, id == nil)
		QueueEvent("UNIT_INVENTORY_CHANGED", "player")
	else
		W.bags[loc.bag] = W.bags[loc.bag] or {}
		W.bags[loc.bag][loc.bagSlot] = id and { id = id, count = 1 } or nil
		QueueEvent("BAG_UPDATE", loc.bag)
		QueueEvent("BAG_UPDATE_DELAYED")
	end
end
local function UIError(message)
	table.insert(W.uiErrors, message)
end
local function CanEquipNow(slot)
	if W.combat and slot ~= 16 and slot ~= 17 and slot ~= 18 then
		UIError("You can't change armor in combat")
		return false
	end
	return true
end

W.cursor = nil
local function Drop(target)
	local from = W.cursor.from
	local moving = Get(from)
	local displaced = Get(target)
	if target.slot then
		if not Fits(moving, target.slot) then UIError("That item doesn't go in that slot") return false end
		if not CanEquipNow(target.slot) then return false end
	end
	if displaced and from.slot then
		if not Fits(displaced, from.slot) then UIError("That item doesn't go in that slot") return false end
	end
	if from.slot and not CanEquipNow(from.slot) then return false end
	Set(target, moving)
	Set(from, displaced)
	-- A two-hander pushes the off-hand into the bags
	if target.slot == 16 and W.itemDB[moving][2] == "INVTYPE_2HWEAPON" and W.equipped[17] then
		local free = W.FreeBagSlot()
		if not free then UIError("Inventory is full.") else Set(free, W.equipped[17]) Set({ slot = 17 }, nil) end
	end
	W.cursor = nil
	return true
end

function W.FreeBagSlot()
	for bag = 0, 4 do
		for bagSlot = 1, W.bagSizes[bag] do
			if not (W.bags[bag] and W.bags[bag][bagSlot]) then return { bag = bag, bagSlot = bagSlot } end
		end
	end
end

local function Pickup(loc)
	if W.cursor then
		if W.cursor.from.slot == loc.slot and W.cursor.from.bag == loc.bag and W.cursor.from.bagSlot == loc.bagSlot then
			W.cursor = nil -- put it back
			return
		end
		Drop(loc)
	elseif Get(loc) then
		W.cursor = { from = loc }
	end
end

function F.PickupInventoryItem(slot) Pickup({ slot = slot }) end
function F.EquipCursorItem(slot) if W.cursor then Drop({ slot = slot }) end end
function F.ClearCursor() W.cursor = nil end
function F.ResetCursor() end
function F.CursorHasItem() return W.cursor ~= nil end
function F.GetCursorInfo()
	if not W.cursor then return nil end
	local id = Get(W.cursor.from)
	return "item", id, W.ItemLink(id)
end
function F.PutItemInBackpack() if W.cursor then local free = W.FreeBagSlot() if free then Drop(free) end end end
function F.PutItemInBag(invSlot)
	if not W.cursor then return end
	local bag = invSlot - 30
	for bagSlot = 1, W.bagSizes[bag] or 0 do
		if not (W.bags[bag] and W.bags[bag][bagSlot]) then Drop({ bag = bag, bagSlot = bagSlot }) return end
	end
end
function F.EquipItemByName(item, slot)
	local id = ItemID(item)
	for bag = 0, 4 do
		for bagSlot, stack in pairs(W.bags[bag] or {}) do
			if stack.id == id then
				W.cursor = { from = { bag = bag, bagSlot = bagSlot } }
				local target = slot or FITS[W.itemDB[id][2]][1]
				if not Drop({ slot = target }) then W.cursor = nil end
				return
			end
		end
	end
end

function F.GetInventorySlotInfo(name)
	local id = SLOTS[name]
	if not id then error("Invalid inventory slot in GetInventorySlotInfo", 2) end
	return id, 136500 + id, false
end
function F.GetInventoryItemLink(unit, slot) return W.equipped[slot] and W.ItemLink(W.equipped[slot]) end
function F.GetInventoryItemID(unit, slot) return W.equipped[slot] end
function F.GetInventoryItemTexture(unit, slot) return W.equipped[slot] and 133000 + W.equipped[slot] end
function F.GetInventoryItemQuality(unit, slot) return W.equipped[slot] and W.itemDB[W.equipped[slot]][7] end
function F.GetInventoryItemCount(unit, slot) return W.equipped[slot] and 1 or 0 end
function F.GetInventoryItemDurability(slot) if W.equipped[slot] then return 50, 100 end end
function F.GetInventoryItemCooldown() return 0, 0, 0 end
function F.GetInventoryItemBroken() return false end
function F.GetInventoryItemsForSlot(slot, result)
	for bag = 0, 4 do
		for bagSlot, stack in pairs(W.bags[bag] or {}) do
			if Fits(stack.id, slot) then result[bag * 100 + bagSlot] = stack.id end
		end
	end
	return result
end
function F.UnitHasRelicSlot() return false end

F.C_Container = {
	GetContainerNumSlots = function(bag) return W.bagSizes[bag] or 0 end,
	GetContainerNumFreeSlots = function(bag)
		local free = 0
		for bagSlot = 1, W.bagSizes[bag] or 0 do
			if not (W.bags[bag] and W.bags[bag][bagSlot]) then free = free + 1 end
		end
		return free, 0
	end,
	GetContainerItemLink = function(bag, bagSlot)
		local stack = W.bags[bag] and W.bags[bag][bagSlot]
		return stack and W.ItemLink(stack.id)
	end,
	GetContainerItemID = function(bag, bagSlot)
		local stack = W.bags[bag] and W.bags[bag][bagSlot]
		return stack and stack.id
	end,
	GetContainerItemInfo = function(bag, bagSlot)
		local stack = W.bags[bag] and W.bags[bag][bagSlot]
		if not stack then return nil end
		local locked = W.cursor and W.cursor.from.bag == bag and W.cursor.from.bagSlot == bagSlot
		return { iconFileID = 133000 + stack.id, stackCount = stack.count, isLocked = locked or false, quality = W.itemDB[stack.id][7],
			isReadable = false, hasLoot = false, hyperlink = W.ItemLink(stack.id), isFiltered = false, hasNoValue = false,
			itemID = stack.id, isBound = true }
	end,
	PickupContainerItem = function(bag, bagSlot) Pickup({ bag = bag, bagSlot = bagSlot }) end,
	UseContainerItem = function(bag, bagSlot)
		local stack = W.bags[bag] and W.bags[bag][bagSlot]
		if not stack then return end
		local fits = FITS[W.itemDB[stack.id][2]]
		if not fits then return end
		W.cursor = { from = { bag = bag, bagSlot = bagSlot } }
		if not Drop({ slot = fits[1] }) then W.cursor = nil end
	end,
	GetContainerItemCooldown = function() return 0, 0, 0 end,
	GetItemCooldown = function() return 0, 0, 0 end,
	ContainerIDToInventoryID = function(bag) return 30 + bag end,
	ShowContainerSellCursor = function() end,
	GetBagName = function(bag) return bag == 0 and "Backpack" or "Bag" end,
	GetBagSlotFlag = function() return false end,
	SortBags = function() end,
}

F.C_EquipmentSet = {
	GetEquipmentSetIDs = function() return {} end,
	GetNumEquipmentSets = function() return 0 end,
	CanUseEquipmentSets = function() return true end,
	GetEquipmentSetInfo = function() return nil end,
	GetEquipmentSetID = function() return nil end,
	GetItemLocations = function() return nil end,
	GetIgnoredSlots = function() return {} end,
	GetItemIDs = function() return {} end,
	ClearIgnoredSlotsForSave = function() end,
	IgnoreSlotForSave = function() end,
	UnignoreSlotForSave = function() end,
}

F.C_Spell = {
	GetSpellInfo = function(id) return { name = "Spell " .. tostring(id), iconID = 136000, spellID = id } end,
	GetSpellTexture = function(id) return 136000 end,
	GetSpellName = function(id) return "Spell " .. tostring(id) end,
	IsSpellUsable = function() return true end,
	DoesSpellExist = function() return true end,
}
F.C_SpellBook = {
	GetNumSpellBookSkillLines = function() return 2 end,
	GetSpellBookSkillLineInfo = function(index) return { name = "Line" .. index, iconID = 135000 + index, itemIndexOffset = (index - 1) * 3, numSpellBookItems = 3, isGuild = false, shouldHide = false } end,
	GetSpellBookItemTexture = function(index) return 136100 + index end,
	GetSpellBookItemName = function(index) return "Spell" .. index end,
	GetSpellBookItemInfo = function(index) return { name = "Spell" .. index, spellID = 100 + index } end,
	IsSpellKnown = function() return true end,
}
function F.GetProfessions() return nil end
function F.GetMacroIcons(t) return t end
function F.GetMacroItemIcons(t) return t end
function F.GetLooseMacroIcons() end
function F.GetLooseMacroItemIcons() end

F.C_QuestLog = {
	IsOnQuest = function(id) return W.quests and W.quests[id] ~= nil end,
	IsComplete = function(id) return W.quests and W.quests[id] == "complete" end,
	GetNumQuestLogEntries = function() return 0, 0 end,
}
F.C_Map = {
	GetBestMapForUnit = function() return 1429 end,
	GetMapInfo = function(id) return { name = "Map " .. tostring(id), mapID = id } end,
	GetPlayerMapPosition = function() return nil end,
}
F.C_PvP = { IsWarModeDesired = function() return false end, IsPVPMap = function() return false end, IsBattleground = function() return false end, IsArena = function() return false end }
F.C_MountJournal = { GetNumMounts = function() return 0 end, GetNumDisplayedMounts = function() return 0 end, GetMountIDs = function() return {} end }
F.C_PetJournal = { GetNumPets = function() return 0, 0 end, GetSummonedPetGUID = function() return nil end }
-- Minimap tracking: Forever returns a table per entry
W.tracking = {
	{ name = "Find Herbs", texture = 133939, active = false, type = "spell", subType = -1, spellID = 2383 },
	{ name = "Find Fish", texture = 133888, active = false, type = "spell", subType = -1, spellID = 43308 },
}
F.C_Minimap = {
	GetNumTrackingTypes = function() return #W.tracking end,
	GetTrackingInfo = function(index)
		local t = W.tracking[index]
		if not t then return nil end
		return { name = t.name, texture = t.texture, active = t.active, type = t.type, subType = t.subType, spellID = t.spellID }
	end,
	SetTracking = function(index, on)
		assert(W.tracking[index], "SetTracking: bad index " .. tostring(index))
		W.tracking[index].active = on and true or false
	end,
}
-- The open trade skill window (C_TradeSkillUI.GetBaseProfessionInfo)
W.tradeSkill = nil
F.C_TradeSkillUI = {
	GetBaseProfessionInfo = function()
		return W.tradeSkill or { professionID = 0, sourceCounter = 0, professionName = "", expansionName = "",
			skillLevel = 0, maxSkillLevel = 0, skillModifier = 0, isPrimaryProfession = false }
	end,
}
F.PROFESSIONS_COOKING = "Cooking"
-- Helm and cloak display
W.showHelm, W.showCloak = true, true
function F.ShowHelm(on) W.showHelm = on and true or false end
function F.ShowCloak(on) W.showCloak = on and true or false end
F.C_TooltipInfo = setmetatable({}, { __index = function() return function() return { lines = {} } end end })
F.C_Calendar = { GetDate = function() return { year = 2026, month = 10, monthDay = 1, weekday = 5 } end }
function F.GetNumCompanions() return 0 end
function F.GetNumTitles() return 0 end
function F.GetCurrentTitle() return 0 end
function F.IsTitleKnown() return false end

-- Item locations
local LocationMethods = {}
function LocationMethods:IsValid() return Get(self.loc) ~= nil end
function LocationMethods:IsEquipmentSlot() return self.loc.slot ~= nil end
function LocationMethods:IsBagAndSlot() return self.loc.bag ~= nil end
function LocationMethods:GetEquipmentSlot() return self.loc.slot end
function LocationMethods:GetBagAndSlot() return self.loc.bag, self.loc.bagSlot end
function LocationMethods:HasAnyLocation() return true end
function LocationMethods:Clear() self.loc = {} end
local function NewLocation(loc) return setmetatable({ loc = loc }, { __index = LocationMethods }) end
F.ItemLocation = {
	CreateFromEquipmentSlot = function(_, slot) return NewLocation({ slot = slot }) end,
	CreateFromBagAndSlot = function(_, bag, bagSlot) return NewLocation({ bag = bag, bagSlot = bagSlot }) end,
	CreateEmpty = function() return NewLocation({}) end,
}
W.LocationItem = function(location) return Get(location.loc) end

-- Blizzard mixins
F.BackdropTemplateMixin = {}
F.TooltipBackdropTemplateMixin = {}

-- Tooltips
F.TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) W.tooltipPostCalls = W.tooltipPostCalls or {} table.insert(W.tooltipPostCalls, fn) end }
F.TooltipUtil = { GetDisplayedItem = function(tooltip) return tooltip:GetItem() end, ShouldDoItemComparison = function() return true end }

-- Blizzard UI helpers the addon calls for values
function F.FauxScrollFrame_GetOffset(frame) return frame.offset or 0 end
function F.FauxScrollFrame_Update(frame, numItems, numToDisplay) return numItems > numToDisplay end
function F.FauxScrollFrame_OnVerticalScroll(frame, value, itemHeight, update) frame.offset = math.floor(value / itemHeight + 0.5) if update then update(frame) end end
function F.FauxScrollFrame_SetOffset(frame, offset) frame.offset = offset end
function F.GetCoinTextureString(copper) return tostring(copper) .. "c" end
function F.SecureCmdOptionParse(options) return (options:match("^([^;]*)")) end
function F.ToggleCharacter(tab)
	if env.CharacterFrame:IsShown() and env[tab]:IsShown() then
		env.CharacterFrame:Hide()
	else
		env.CharacterFrame:Show()
		env.PaperDollFrame:Show()
	end
end
function F.ShowUIPanel(frame) frame:Show() end
function F.HideUIPanel(frame) frame:Hide() end

----------------------------------------
-- Blizzard frames Outfitter uses (Forever's character window)
----------------------------------------
F.CreateFrame = W.CreateFrame
local New = W.NewFrame
F.UIParent = New("Frame", "UIParent")
F.WorldFrame = New("Frame", "WorldFrame")
F.Minimap = New("Minimap", "Minimap", F.UIParent)
F.MinimapBackdrop = New("Frame", "MinimapBackdrop", F.Minimap)
F.GameTooltip = New("GameTooltip", "GameTooltip", F.UIParent)
F.GameTooltip.__shown = false
F.GameTooltip.NineSlice = New("Frame", nil, F.GameTooltip)
F.ItemRefTooltip = New("GameTooltip", "ItemRefTooltip", F.UIParent)
F.ShoppingTooltip1 = New("GameTooltip", "ShoppingTooltip1", F.UIParent)
F.ShoppingTooltip2 = New("GameTooltip", "ShoppingTooltip2", F.UIParent)
F.GameTooltip.shoppingTooltips = { F.ShoppingTooltip1, F.ShoppingTooltip2 }
F.ItemRefTooltip.shoppingTooltips = { F.ShoppingTooltip1, F.ShoppingTooltip2 }
F.UIErrorsFrame = New("MessageFrame", "UIErrorsFrame", F.UIParent)
F.UIErrorsFrame.AddMessage = function(self, message) table.insert(W.uiErrors, message) end
F.DEFAULT_CHAT_FRAME = New("ScrollingMessageFrame", "ChatFrame1", F.UIParent)
F.DEFAULT_CHAT_FRAME.AddMessage = function(self, message) table.insert(W.printed, message) end
F.ChatFrame1 = F.DEFAULT_CHAT_FRAME
F.ChatFrame1Tab = New("Button", "ChatFrame1Tab", F.ChatFrame1)
F.ChatFrame1Tab.__text = "General"
F.ChatFrameUtil = { OpenChat = function() end, ForEachChatFrame = function(fn) fn(F.ChatFrame1) end }
F.MerchantFrame = New("Frame", "MerchantFrame", F.UIParent)
F.MerchantFrame.__shown = false
F.StackSplitFrame = New("Frame", "StackSplitFrame", F.UIParent)
F.ColorPickerFrame = New("Frame", "ColorPickerFrame", F.UIParent)
F.EquipmentFlyoutFrame = New("Frame", "EquipmentFlyoutFrame", F.UIParent)
F.EquipmentFlyoutFrame.__shown = false
for _, font in ipairs({ "GameFontNormal", "GameFontNormalSmall", "GameFontNormalLarge", "GameFontHighlight", "GameFontHighlightSmall",
	"GameFontHighlightLarge", "GameFontDisable", "GameFontDisableSmall", "GameFontGreen", "GameFontRed", "GameFontWhite",
	"ChatFontNormal", "NumberFontNormal", "GameFontNormalHuge", "GameFontHighlightSmallLeft", "GameFontNormalLeft",
	"GameFontHighlightLeft", "GameFontNormalSmallLeft", "GameFontDisableLeft", "SystemFont_Small", "GameTooltipText",
	"GameTooltipHeaderText", "GameFontBlack", "GameFontBlackSmall", "GameFontNormalMed3", "GameFontHighlightMedium",
	"QuestFont", "ItemTextFontNormal", "GameFontDarkGraySmall" }) do
	F[font] = New("Font", font)
end

F.CharacterFrame = New("Frame", "CharacterFrame", F.UIParent)
F.CharacterFrame.__shown = false
F.CharacterFrame.__width = 631
F.CharacterFrame.LeftPaneHost = New("Frame", "CharacterFrameLeftPaneHost", F.CharacterFrame)
F.CharacterFrame.RightPaneHost = New("Frame", "CharacterFrameRightPaneHost", F.CharacterFrame)
F.CharacterFrame.RightPaneToggleButton = New("Button", "CharacterFrameRightPaneToggleButton", F.CharacterFrame)
F.CharacterFrame.ModeTabs = New("Frame", "CharacterFrameModeTabs", F.CharacterFrame)
F.CharacterFrameModeTab1 = New("Frame", "CharacterFrameModeTab1", F.CharacterFrame.ModeTabs)
F.PaperDollFrame = New("Frame", "PaperDollFrame", F.CharacterFrame)
F.PaperDollItemsFrame = New("Frame", "PaperDollItemsFrame", F.PaperDollFrame)
F.PaperDollItemsFrame.flyoutSettings = {
	getItemsFunc = function(slot, items) return F.GetInventoryItemsForSlot(slot, items) end,
	postGetItemsFunc = function(button, items, count) return count end,
}
F.PaperDollSidebarTabs = New("Frame", "PaperDollSidebarTabs", F.CharacterFrame)
F.CharacterLevelText = New("FontString", "CharacterLevelText", F.PaperDollFrame)
F.CharacterModelScene = New("ModelScene", "CharacterModelScene", F.PaperDollFrame)
for name, id in pairs(SLOTS) do
	if id >= 0 and id <= 19 then
		local button = New("Button", "Character" .. name, F.PaperDollItemsFrame, nil, id)
		button.popoutButton = New("Button", nil, button)
		F["Character" .. name] = button
	end
end
