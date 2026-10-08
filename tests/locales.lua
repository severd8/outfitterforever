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
	"cSidebarTabOnDescription", "cSidebarTabOffDescription", "cSidebarTabTip" }

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
local SAME = { deDE = { cOutfitterTabTitle = true, cLookTooltips = true } }

local _, english = Session("enUS")
for _, locale in ipairs({ "deDE", "frFR", "zhCN", "zhTW", "koKR", "ruRU" }) do
	local W, O = Session(locale)
	for _, key in ipairs(KEYS) do
		local text = O[key]
		Check(type(text) == "string" and text ~= "" and (text ~= english[key] or (SAME[locale] or {})[key]),
			locale .. " translates " .. key)
	end
	local _, placeholders = tostring(O.cOpenCharacterWindow):gsub("%%s", "")
	Check(placeholders == 1, locale .. ": cOpenCharacterWindow keeps its one %s for the key")
	Check(O.cOutfitterTabTitle ~= "Outfitter", locale .. ": the first tab is named for outfits, not \"Outfitter\"")
	for _, message in ipairs(W.errors) do Check(false, locale .. ": Lua error: " .. message:sub(1, 300)) end
end

return failures
