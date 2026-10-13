-- Every language Outfitter ships has the strings Outfitter Forever added, and the window
-- builds without errors in each. Run by tests/run.lua.

local failures = 0
local function Check(condition, message)
	if not condition then
		failures = failures + 1
		print("FAIL [locales] " .. message)
	end
	return condition
end

-- The strings the port added (or, for the tab, changed from upstream's "Outfitter")
local KEYS = { "cOutfitterTabTitle", "cLookOutfitScripts", "cLookOutfitScriptsDescription", "cLookTooltips",
	"cLookQuickAccess", "cOpenCharacterWindow", "cMoveUp", "cMoveDown", "cSortByName", "cSidebarTab",
	"cSidebarTabOnDescription", "cSidebarTabOffDescription", "cSidebarTabTip", "cCombatWait", "cLookAutomation",
	"cLookHotkeyMessagesDescription", "cLookTooltipInfoDescription", "cLookItemComparisons", "cLookItemComparisonsDescription",
	"cLookMinimapButtonDescription", "cLookOutfitBarDescription", "cLookBarSettings", "cLookBarSettingsDescription",
	"cLookSidebarTabDescription", "cLookDisplayTab", "cLookSize", "cLookWindowSize", "cLookWindowSizeDescription", "cLookTextSize", "cLookTextSizeDescription",
	"cLookColors", "cLookColorsDescription", "cLookColorDefault",
	"cLookColorContrast", "cLookColorBlue", "cLookColorLight", 
	"cLookReset", "cLookResetDescription", "cLookPageSize", "cLookPageColors", "cLookFont", "cLookFontDescription",
	"cLookFontDefault", "cLookTypeSize", "cLookRightClick", "cLookRightClickDescription", "cLookRightClickOpen",
	"cLookRightClickMenu", "cLookRightClickSwap", "cLookSwapFirst", "cLookSwapSecond", "cLookSwapNotSet", "cLookTipOpen",
	"cLookTipMenu", "cLookTipSwap", "cLookTipSwapNotSet", "cLookOwnColors", "cLookOwnColorDescription",
	"cLookHexDescription", "cLookColorBackground", "cLookColorPanels", "cLookColorText", "cLookColorHeadings", "cLookColorButtons",
	"cLookColorHighlight" }

-- The option cards: the bottom of the last one, measured from the window's top
local function CardsBottom(W, O)
	O:ShowPanel(2)
	W.Tick(0.2)
	local cards = W.env.OutfitterFrame.Look.Cards
	local last = cards[#cards]
	local point = last.__points[1]
	local y = point[#point] -- SetPoint("TOPLEFT", x, y)
	local height = W.env.OutfitterFrame:GetHeight()
	O:ShowPanel(1)
	W.Tick(0.2)
	return -y + last:GetHeight(), cards[3]:GetHeight(), height
end

local function Session(locale)
	_G.W = nil
	local W = dofile("tests/wow.lua")
	W.expansionLevel, W.projectId = 0, 18
	dofile("tests/fakes.lua")
	W.Fakes.GetLocale = function() return locale end
	W.LoadToc("OutfitterForever.toc")
	W.Fire("ADDON_LOADED", W.addonName)
	W.Fire("VARIABLES_LOADED")
	W.loggedIn = true
	W.Fire("PLAYER_LOGIN")
	W.Fire("PLAYER_ENTERING_WORLD", true, false)
	W.Tick(3)
	W.PlayerTogglesCharacter()
	W.Tick(1)
	local O = W.env.Outfitter
	O:ShowPanel(2)
	W.Tick(0.5)
	O:ShowPanel(1)
	W.Tick(0.5)
	return W, O
end

-- Words that are the same as in English
local SAME = { deDE = { cOutfitterTabTitle = true, cLookTooltips = true, cLookColorText = true } }

local englishW, english = Session("enUS")
local englishBottom, englishCard3 = CardsBottom(englishW, english)
-- 344: the window's height in Outfitter.xml, less a 4 px margin (the gap between cards)
Check(englishBottom <= 344 - 4, "enUS: the option cards fit in the window as it is (" .. englishBottom .. ")")
for _, locale in ipairs({ "deDE", "frFR", "zhCN", "zhTW", "koKR", "ruRU" }) do
	local W, O = Session(locale)
	for _, key in ipairs(KEYS) do
		local text = O[key]
		Check(type(text) == "string" and text ~= "" and (text ~= english[key] or (SAME[locale] or {})[key]),
			locale .. " translates " .. key)
	end
	local _, placeholders = tostring(O.cOpenCharacterWindow):gsub("%%s", "")
	Check(placeholders == 1, locale .. ": cOpenCharacterWindow keeps its one %s for the key")
	Check(tostring(O.cCombatWait):sub(1, 2) == "%s", locale .. ": cCombatWait starts with the outfit's name (%s)")
	Check(O.cOutfitterTabTitle ~= "Outfitter", locale .. ": the first tab is named for outfits, not \"Outfitter\"")
	-- Long option names wrap onto a second line (the French Equipment Manager tab
	-- does) instead of being cut off, and the cards still fit in the window
	-- (in longer languages the window grows on the Options tab to fit them)
	local bottom, card3, height = CardsBottom(W, O)
	Check(bottom <= height, locale .. ": the option cards fit in the window (" .. bottom .. " of " .. height .. ")")
	local _, swapNames = tostring(O.cLookTipSwap):gsub("%%s", "")
	Check(swapNames == 1, locale .. ": cLookTipSwap keeps its one %s for the outfit")
	if locale == "frFR" then
		Check(card3 > englishCard3, "frFR: the long Equipment Manager tab option takes two lines")
	end
	for _, message in ipairs(W.errors) do Check(false, locale .. ": Lua error: " .. message:sub(1, 300)) end
end

return failures
