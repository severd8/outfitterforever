-- Outfitter Forever: the shared look (Theme.lua) on Outfitter's window.
-- A restyle only: everything here changes how the window looks, never what it
-- does. Outfitter's own frames, scripts and saved settings are untouched; their
-- art is hidden and flat pieces in the shared colours are drawn instead.

local _, Outfitter = ...
local T = Outfitter.Theme
local C = T.C

-- Chat lines start with the logo and name, as in every addon with this look
Outfitter.ChatPrefix = T.CHAT_PREFIX .. ": "

local ARROW = "Interface\\Buttons\\Arrow-Down-Up"

---------------------------------------------------------------------------
-- Display settings (the Display tab): window size, text size and colours, for
-- players who need things bigger or clearer. Saved for the whole account in
-- gOutfitter_GlobalSettings.Display: Scale and TextSize (percent), Font (a font
-- file, nil for the game's own), Colors.
---------------------------------------------------------------------------
local SCALE_MIN, SCALE_MAX = 50, 200
local TEXT_MIN, TEXT_MAX = 80, 200
-- 1.5.0 saved the text size as a word
local OLD_TEXT_SIZES = { large = 115, larger = 130 }
local COLOR_KEYS = { "default", "contrast", "blue", "light" }

-- Each colour style replaces the shared colours (Theme.lua's C) for this addon
-- only. hover: an option's label under the mouse; select: the selected outfit's
-- row; menu: the menus' panel (the Light style keeps menus dark, since the
-- menu library draws its text white); darkText: Blizzard's white, grey and gold
-- text in the window is made dark (Light).
local PRESETS = {
	contrast = {
		win = { 0, 0, 0, 0.98 }, side = { 0, 0, 0, 1 }, card = { 0.06, 0.06, 0.06, 1 }, field = { 0, 0, 0, 1 },
		line = { 0.6, 0.6, 0.6, 1 }, edge = { 1, 1, 1, 1 }, fieldEdge = { 0.85, 0.85, 0.85, 1 },
		red = { 0.2, 0.2, 0.2, 1 }, redHi = { 0.38, 0.38, 0.38, 1 }, btnEdge = { 1, 1, 1, 1 },
		offTrack = { 0.35, 0.35, 0.35, 1 }, onTrack = { 0.6, 0.48, 0, 1 }, gold = { 1, 0.92, 0.2, 1 },
		grey = { 0.75, 0.75, 0.75, 1 }, orange = { 1, 0.85, 0.2 }, muted = { 1, 1, 1 }, title = { 1, 1, 1 },
		version = { 1, 0.92, 0.2 }, tabOn = { 0.22, 0.22, 0.22, 1 }, accent = { 1, 0.85, 0, 1 }, fill = { 1, 0.85, 0, 1 },
		select = { 1, 0.85, 0, 0.3 },
	},
	blue = {
		win = { 0.055, 0.063, 0.085, 0.98 }, side = { 0.04, 0.047, 0.063, 1 }, card = { 0.075, 0.09, 0.12, 1 },
		field = { 0.043, 0.05, 0.07, 1 }, line = { 0.12, 0.16, 0.23, 1 }, edge = { 0.23, 0.3, 0.42, 1 },
		fieldEdge = { 0.2, 0.27, 0.38, 1 }, red = { 0.09, 0.23, 0.42, 1 }, redHi = { 0.14, 0.33, 0.58, 1 },
		btnEdge = { 0.45, 0.58, 0.75, 1 }, offTrack = { 0.18, 0.2, 0.25, 1 }, onTrack = { 0.11, 0.37, 0.66, 1 },
		grey = { 0.5, 0.54, 0.6, 1 }, orange = { 0.5, 0.77, 1 }, muted = { 0.77, 0.81, 0.87 },
		title = { 0.91, 0.93, 0.97 }, version = { 0.6, 0.75, 0.95 }, tabOn = { 0.07, 0.16, 0.29, 1 },
		accent = { 0.29, 0.64, 1, 1 }, fill = { 0.15, 0.45, 0.8, 1 },
	},
	light = {
		win = { 0.91, 0.886, 0.816, 0.98 }, side = { 0.85, 0.81, 0.72, 1 }, card = { 0.95, 0.93, 0.87, 1 },
		field = { 1, 0.98, 0.94, 1 }, line = { 0.72, 0.67, 0.55, 1 }, edge = { 0.48, 0.39, 0.25, 1 },
		fieldEdge = { 0.55, 0.47, 0.33, 1 }, red = { 0.45, 0.12, 0.06, 1 }, redHi = { 0.6, 0.18, 0.09, 1 },
		btnEdge = { 0.48, 0.39, 0.25, 1 }, offTrack = { 0.7, 0.65, 0.56, 1 }, onTrack = { 0.72, 0.2, 0.11, 1 },
		grey = { 0.4, 0.37, 0.33, 1 }, orange = { 0.6, 0.29, 0.06 }, muted = { 0.23, 0.2, 0.15 },
		title = { 0.1, 0.08, 0.06 }, version = { 0.95, 0.85, 0.6 }, tabOn = { 0.45, 0.12, 0.06, 1 },
		accent = { 0.72, 0.2, 0.11, 1 }, fill = { 0.72, 0.2, 0.11, 1 },
		hover = { 0.6, 0.18, 0.09 }, select = { 0.72, 0.2, 0.11, 0.22 }, menu = { 0.07, 0.063, 0.063, 0.97 },
		darkText = true,
	},
}

-- What each style's swatch on the Display tab shows (fixed: C changes with the style)
local SWATCHES = {
	default = { 0.35, 0.075, 0.047 }, contrast = { 0, 0, 0 }, blue = { 0.09, 0.23, 0.42 }, light = { 0.91, 0.886, 0.816 },
}

local function DisplaySettings()
	if type(gOutfitter_GlobalSettings) ~= "table" then return {} end
	gOutfitter_GlobalSettings.Display = gOutfitter_GlobalSettings.Display or {}
	return gOutfitter_GlobalSettings.Display
end

local function TextPercent()
	local size = DisplaySettings().TextSize
	return OLD_TEXT_SIZES[size] or tonumber(size) or 100
end
local function WindowScale() return (tonumber(DisplaySettings().Scale) or 100) / 100 end
local function TextScale() return TextPercent() / 100 end

-- The fonts to pick from: those LibSharedMedia knows (other addons add theirs),
-- else the game's own four, which have only Western letters
local GAME_FONTS = {
	{ "Friz Quadrata", "Fonts\\FRIZQT__.TTF" }, { "Arial Narrow", "Fonts\\ARIALN.TTF" },
	{ "Skurri", "Fonts\\skurri.ttf" }, { "Morpheus", "Fonts\\MORPHEUS.ttf" },
}
local WESTERN = { enUS = true, enGB = true, deDE = true, frFR = true, esES = true, esMX = true, itIT = true, ptBR = true }
local function FontChoices()
	local fonts = {}
	local media = LibStub and LibStub("LibSharedMedia-3.0", true)
	if media then
		for _, name in ipairs(media:List("font") or {}) do
			local file = media:Fetch("font", name)
			if file then fonts[#fonts + 1] = { name, file } end
		end
	elseif WESTERN[GetLocale()] then
		for _, font in ipairs(GAME_FONTS) do fonts[#fonts + 1] = font end
	end
	return fonts
end

-- The colours in use: chosen at login (repainting everything that's already
-- drawn would mean redrawing the whole window, so a new choice waits for a reload)
local appliedColors = "default"
local function ApplyColors()
	local key = DisplaySettings().Colors
	local preset = PRESETS[key]
	if not preset then return end
	appliedColors = key
	for name, value in pairs(preset) do
		local current = C[name]
		if type(current) == "table" and type(value) == "table" then
			for i, v in ipairs(value) do current[i] = v end
		else
			C[name] = value
		end
	end
end

-- Text in the chosen size: each font string and edit box keeps its original
-- font and size, and gets that size times the factor
local function SizeText(region, factor)
	if not region or not region.SetFont or not region.GetFont then return end
	local base = region.OFTextBase
	if not base then
		if factor == 1 and not DisplaySettings().Font then return end
		local font, size, flags = region:GetFont()
		if not font or not size then return end
		base = { font, size, flags }
		region.OFTextBase = base
	end
	region:SetFont(DisplaySettings().Font or base[1], base[2] * factor, base[3] or "")
end

local function SizeTextIn(frame, factor)
	if not frame then return end
	factor = factor or TextScale()
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == "FontString" then SizeText(region, factor) end
	end
	if frame:GetObjectType() == "EditBox" then SizeText(frame, factor) end
	for _, child in ipairs({ frame:GetChildren() }) do SizeTextIn(child, factor) end
end

-- Light colours: the game's white, grey and gold text would be faint on the
-- light panels, so it's made dark. Text on the dark header, tabs and buttons is
-- marked OFKeep and left alone.
local function DarkText(region)
	if not C.darkText or not region or region.OFKeep or not region.GetTextColor then return end
	local r, g, b = region:GetTextColor()
	if not r then return end
	local color
	if r > 0.85 and g > 0.85 and b > 0.85 then
		color = C.title
	elseif r > 0.9 and g > 0.7 and g < 0.9 and b < 0.25 then
		color = C.title
	elseif math.abs(r - g) < 0.06 and math.abs(g - b) < 0.06 and r > 0.4 and r < 0.75 then
		color = C.muted
	end
	if color then region:SetTextColor(color[1], color[2], color[3]) end
end

local function DarkTextIn(frame)
	if not C.darkText or not frame then return end
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == "FontString" then DarkText(region) end
	end
	if frame:GetObjectType() == "EditBox" then DarkText(frame) end
	for _, child in ipairs({ frame:GetChildren() }) do DarkTextIn(child) end
end

-- A dialog in the chosen window size, text size and colours
local function DisplayDialog(dialog)
	if not dialog then return end
	dialog:SetScale(WindowScale())
	SizeTextIn(dialog)
	DarkTextIn(dialog)
end

---------------------------------------------------------------------------
-- Small pieces
---------------------------------------------------------------------------
local function Fade(region)
	if region then region:SetAlpha(0) end
end

-- A flat box of the given size centred on a frame, drawn with the frame's own
-- textures (so whatever the frame draws on top, like a check, stays on top)
local function Box(frame, size, fill, edge)
	local half = size / 2
	local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
	bg:SetSize(size, size)
	bg:SetPoint("CENTER")
	bg:SetColorTexture(unpack(fill))
	local edges = {
		{ size, 1, 0, half - 0.5 }, { size, 1, 0, 0.5 - half },
		{ 1, size, 0.5 - half, 0 }, { 1, size, half - 0.5, 0 },
	}
	for _, e in ipairs(edges) do
		local t = frame:CreateTexture(nil, "BORDER")
		t:SetSize(e[1], e[2])
		t:SetPoint("CENTER", e[3], e[4])
		t:SetColorTexture(unpack(edge))
	end
	return bg
end

-- An existing button made flat: its art faded out, a flat fill and edge behind
-- its text, brighter on hover. What it does is unchanged.
local function Flatten(button, fill, hover, edge)
	for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }) do
		Fade(button[get](button))
	end
	for _, key in ipairs({ "Left", "Middle", "Right", "LeftTexture", "MiddleTexture", "RightTexture", "HighlightTexture" }) do
		if type(button[key]) == "table" then Fade(button[key]) end
	end
	local bg = T.Fill(button, fill)
	T.Border(button, edge or C.btnEdge)
	button:HookScript("OnEnter", function() bg:SetColorTexture(unpack(hover)) end)
	button:HookScript("OnLeave", function() bg:SetColorTexture(unpack(fill)) end)
	local fs = button.GetFontString and button:GetFontString() or button.Text
	if fs then
		fs:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
		fs.OFKeep = true
	end
	return bg
end

-- A flat button from the shared look, its text kept as is in Light colours
local function FlatButton(parent, text, width, height)
	local button = T.FlatButton(parent, text, width, height)
	local fs = button:GetFontString()
	if fs then fs.OFKeep = true end
	return button
end

-- The header strip from the shared look, its text kept as is in Light colours
local function HeaderStrip(header, text)
	T.HeaderStrip(header, text)
	header.text.OFKeep = true
	return header
end

-- The small gold arrow that opens a menu, on a menu button's own textures
local function ArrowButton(button)
	for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture" }) do
		local t = button[get](button)
		if t then
			t:SetTexture(ARROW)
			t:ClearAllPoints()
			t:SetSize(10, 10)
			t:SetPoint("CENTER")
			t:SetVertexColor(C.orange[1], C.orange[2], C.orange[3])
		end
	end
	local disabled = button:GetDisabledTexture()
	if disabled then disabled:SetVertexColor(C.grey[1], C.grey[2], C.grey[3]) end
end

-- A scroll bar with only a thin gold thumb left showing
local function FlatScrollBar(scrollBar)
	if not scrollBar then return end
	local thumb = scrollBar:GetThumbTexture()
	for _, region in ipairs({ scrollBar:GetRegions() }) do
		if region ~= thumb and region:GetObjectType() == "Texture" then region:SetAlpha(0) end
	end
	if thumb then
		thumb:SetColorTexture(unpack(C.btnEdge))
		thumb:SetSize(6, 40)
	end
	Fade(scrollBar.ScrollUpButton)
	Fade(scrollBar.ScrollDownButton)
end

-- What an outfit's script is called, for the line beside its name
local function ScriptName(outfit)
	if outfit.ScriptID then
		local preset = Outfitter:GetPresetScriptByID(outfit.ScriptID)
		return preset and preset.Name
	elseif outfit.Script then
		return Outfitter.cCustomScript
	end
end

---------------------------------------------------------------------------
-- Rows of the outfit list. These run inside Outfitter's own list code, after
-- it has drawn a row, so they're hooked here, before Outfitter.xml builds the
-- rows from _ListItem.
---------------------------------------------------------------------------
hooksecurefunc(Outfitter._ListItem, "SetToOutfit", function(self, outfit)
	local look = self.Look
	if not look then return end
	DarkText(_G[self:GetName() .. "OutfitName"])
	_G[self:GetName() .. "OutfitScriptIcon"]:Hide()
	local name = ScriptName(outfit)
	if not name then
		look.Script:Hide()
		return
	end
	local nameField = _G[self:GetName() .. "OutfitName"]
	local width = math.min(nameField:GetStringWidth() or 0, nameField:GetWidth() or 133)
	look.Script:ClearAllPoints()
	look.Script:SetPoint("LEFT", nameField, "LEFT", width + 6, 0)
	look.Script:SetPoint("RIGHT", nameField, "RIGHT", 14, 0)
	look.Script:SetText(name)
	local off = Outfitter.Settings.Options.DisableAutoSwitch or outfit.Disabled
	local color = off and C.offTrack or C.grey
	look.Script:SetTextColor(color[1], color[2], color[3])
	look.Script:Show()
end)

-- Light colours: outfit names (gold, white under the mouse) made dark
hooksecurefunc(Outfitter._ListItem, "SetTextColor", function(self)
	if not self.Look then return end
	DarkText(_G[self:GetName() .. (self.isCategory and "CategoryName" or "OutfitName")])
end)

local function PaintCategory(self)
	local nameField = _G[self:GetName() .. "CategoryName"]
	nameField:SetTextColor(C.orange[1], C.orange[2], C.orange[3])
end

hooksecurefunc(Outfitter._ListItem, "SetToCategory", function(self, categoryID)
	if not self.Look then return end
	local nameField = _G[self:GetName() .. "CategoryName"]
	nameField:SetText((nameField:GetText() or ""):upper())
	PaintCategory(self)
	-- A gold arrow: down when the category is open, right when it's folded
	local expand = _G[self:GetName() .. "CategoryExpand"]
	local arrow = expand:GetNormalTexture()
	if arrow then
		arrow:SetTexture(ARROW)
		arrow:ClearAllPoints()
		arrow:SetSize(10, 10)
		arrow:SetPoint("CENTER")
		arrow:SetVertexColor(C.orange[1], C.orange[2], C.orange[3])
		arrow:SetRotation(Outfitter.Collapsed[categoryID] and math.pi / 2 or 0)
	end
end)

-- Leaving a category row puts its name back in orange (Outfitter makes it white)
hooksecurefunc(Outfitter._ListItem, "OnLeave", function(self)
	if self.Look and self.isCategory then PaintCategory(self) end
end)

local function StyleRow(item)
	local name = item:GetName()
	item.Look = {}

	-- Worn checkbox: a flat box with the gold check
	local check = _G[name .. "OutfitSelected"]
	Fade(check:GetNormalTexture())
	Fade(check:GetPushedTexture())
	Box(check, 14, C.field, C.fieldEdge)
	local tick = check:GetCheckedTexture()
	if tick then
		tick:ClearAllPoints()
		tick:SetSize(20, 20)
		tick:SetPoint("CENTER", 1, 1)
	end

	-- The script's name, in grey after the outfit's name, instead of the gear icon
	local script = _G[name .. "Outfit"]:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	script:SetJustifyH("LEFT")
	script:SetWordWrap(false)
	script:Hide()
	item.Look.Script = script

	-- The menu button: a flat field with the gold arrow
	local menu = _G[name .. "OutfitMenu"]
	Box(menu, 16, C.field, C.fieldEdge)
	if menu.Button then
		ArrowButton(menu.Button)
		menu.Button:ClearAllPoints()
		menu.Button:SetPoint("CENTER")
		menu.Button:SetSize(16, 16)
		if menu.Button.HighlightTexture then menu.Button.HighlightTexture:SetAlpha(0.35) end
	end

	-- Category rows: orange capitals
	_G[name .. "CategoryName"]:SetFontObject(GameFontNormalSmall)
	local expand = _G[name .. "CategoryExpand"]
	Fade(expand:GetHighlightTexture())
end

---------------------------------------------------------------------------
-- Tabs at the top, under the header bar
---------------------------------------------------------------------------
local TAB_H = 24

-- Flat tabs under a header bar. choose(index) is what clicking a tab does;
-- without a width the tabs share the frame's width.
local function MakeTabs(frame, header, labels, choose, width)
	local tabs = {}
	width = width or (frame:GetWidth() or 256) / #labels
	for index, label in ipairs(labels) do
		local tab = CreateFrame("Button", nil, frame)
		tab:SetSize(width, TAB_H)
		tab:SetPoint("TOPLEFT", header, "BOTTOMLEFT", (index - 1) * width, 0)
		tab.bg = T.Fill(tab, C.side)
		tab.bar = tab:CreateTexture(nil, "ARTWORK")
		tab.bar:SetPoint("BOTTOMLEFT")
		tab.bar:SetPoint("BOTTOMRIGHT")
		tab.bar:SetHeight(2)
		tab.bar:SetColorTexture(unpack(C.accent))
		tab.text = T.Text(tab, label, #labels > 2 and "GameFontNormalSmall" or "GameFontNormal")
		tab.text:SetPoint("LEFT", 3, 0)
		tab.text:SetPoint("RIGHT", -3, 0)
		tab.text:SetJustifyH("CENTER")
		tab.text:SetWordWrap(false)
		tab.text.OFKeep = true
		tab:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
			choose(index)
		end)
		tab:SetScript("OnEnter", function(self)
			if not self.on then self.bg:SetColorTexture(unpack(C.card)) end
		end)
		tab:SetScript("OnLeave", function(self)
			if not self.on then self.bg:SetColorTexture(unpack(C.side)) end
		end)
		tabs[index] = tab
	end
	-- A line under the tabs
	local line = frame:CreateTexture(nil, "BORDER")
	line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -TAB_H)
	line:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -TAB_H)
	line:SetHeight(1)
	line:SetColorTexture(unpack(C.line))

	function tabs.Paint(current)
		for index, tab in ipairs(tabs) do
			tab.on = index == current
			tab.bg:SetColorTexture(unpack(tab.on and C.tabOn or C.side))
			tab.bar:SetShown(tab.on)
			local color = tab.on and C.gold or C.muted
			tab.text:SetTextColor(color[1], color[2], color[3])
		end
	end
	return tabs
end

-- The big title each panel had under the header ("Outfitter Forever", "Options")
local function HideTitles(panel, ...)
	local titles = {}
	for i = 1, select("#", ...) do titles[select(i, ...)] = true end
	for _, region in ipairs({ panel:GetRegions() }) do
		if region:GetObjectType() == "FontString" and titles[region:GetText()] then
			region:Hide()
		end
	end
end

---------------------------------------------------------------------------
-- Options: on/off switches in three cards
---------------------------------------------------------------------------
local ROW_H = 22

local function MakeSwitch(check)
	for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture",
		"GetCheckedTexture", "GetDisabledCheckedTexture", "GetDisabledTexture" }) do
		Fade(check[get](check))
	end
	check:SetSize(30, 16)
	local track = check:CreateTexture(nil, "BACKGROUND", nil, -8)
	track:SetAllPoints()
	local knob = check:CreateTexture(nil, "ARTWORK")
	knob:SetSize(12, 12)
	local function Paint()
		local on = check:GetChecked()
		track:SetColorTexture(unpack(on and C.onTrack or C.offTrack))
		knob:SetColorTexture(unpack(on and C.gold or C.grey))
		knob:ClearAllPoints()
		knob:SetPoint("LEFT", check, "LEFT", on and 16 or 2, 0)
	end
	hooksecurefunc(check, "SetChecked", Paint)
	check:HookScript("OnClick", Paint)
	Paint()

	local label = _G[check:GetName() .. "Text"] or check.Text
	if label then
		label:ClearAllPoints()
		label:SetPoint("LEFT", check, "RIGHT", 8, 0)
		label:SetFontObject(GameFontHighlightSmall)
		label:SetTextColor(C.title[1], C.title[2], C.title[3])
		label:SetJustifyH("LEFT")
		label:SetWidth(180)
		label:SetWordWrap(false)
		-- The label is part of the switch: clicking it flips the switch too
		check:SetHitRectInsets(0, -188, -4, -4)
	end
end

-- The two "Outfit scripts" switches (footer and Options) do the same thing:
-- on means outfits with a script change by themselves
local function ScriptsSwitchClick(switch)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	Outfitter:SetAutoSwitch(not switch:IsOn())
	switch:SetOn(not Outfitter.Settings.Options.DisableAutoSwitch)
end

local function ScriptsSwitch(parent)
	local switch = T.SwitchWidget(parent)
	switch:SetScript("OnClick", ScriptsSwitchClick)
	T.Tooltip(switch, Outfitter.cLookOutfitScripts, Outfitter.cLookOutfitScriptsDescription)
	return switch
end

-- Option labels wrap to a second line rather than being cut off (long in some
-- languages); each extra line makes its row this much taller
local LABEL_W, LINE_H = 180, 11

-- Hovering a row turns its label gold
local function HoverLabel(widget, label)
	function widget:SetHover(on)
		local color = on and (C.hover or C.gold) or C.title
		label:SetTextColor(color[1], color[2], color[3])
	end
end

-- A field that opens one of Outfitter's own menus to pick from (the game's
-- newer menus aren't on Forever). choices() returns { key, label } pairs.
local function MenuField(parent, width, choices, get, set)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(width, 20)
	T.Fill(b, C.field)
	T.Border(b, C.fieldEdge)
	local text = T.Text(b, "", "GameFontHighlightSmall", C.title)
	text:SetPoint("LEFT", 6, 0)
	text:SetPoint("RIGHT", -18, 0)
	text:SetWordWrap(false)
	T.MenuArrow(b, 6)
	b.text = text
	function b.Refresh()
		local current = get()
		for _, choice in ipairs(choices()) do
			if choice[1] == current then text:SetText(choice[2]) return end
		end
		text:SetText(choices()[1] and choices()[1][2] or "")
	end
	local function Close()
		if b.menu then
			b.menu:Hide()
			b.menu = nil
		end
	end
	b:SetScript("OnClick", function()
		if b.menu then Close() return end
		local items = Outfitter:New(Outfitter.UIElementsLib._DropDownMenuItems, function()
			Outfitter.SchedulerLib:ScheduleTask(0.1, Close)
		end)
		for _, choice in ipairs(choices()) do
			items:AddToggle(choice[2], function() return get() == choice[1] end, function()
				set(choice[1])
				b.Refresh()
			end)
		end
		b.menu = Outfitter:New(Outfitter.UIElementsLib._DropDownMenu)
		b.menu:Show(items, "TOPLEFT", b, "BOTTOMLEFT", 0, -2)
	end)
	b:HookScript("OnHide", Close)
	return b
end

-- Lays the option rows and cards out from the top: a hidden row takes no room
-- and a two-line label makes its row taller. Clicks reach as far as the label's text.
local function LayoutOptions(look)
	local y = look.CardsTop
	local lineH = LINE_H * TextScale()
	for _, card in ipairs(look.Cards) do
		local rowY = -24
		for _, row in ipairs(card.rows) do
			if row.field then
				-- A label over a menu field, the card's full width
				local width = LABEL_W + 36
				row.label:SetWidth(width)
				local lines = math.min(3, math.max(1, math.ceil(row.label:GetUnboundedStringWidth() / width)))
				local height = lines * lineH + 4 + 20 + 6
				row.widget:ClearAllPoints()
				row.widget:SetPoint("TOPLEFT", card, "TOPLEFT", 12, rowY + 3)
				row.widget:SetSize(width, height)
				rowY = rowY - height
			elseif row.widget:IsShown() then
				local width = LABEL_W - (row.extra or 0)
				row.label:SetWidth(width)
				local full = row.label:GetUnboundedStringWidth()
				local lines = math.min(3, math.max(1, math.ceil(full / width)))
				local height = ROW_H + (lines - 1) * lineH
				row.widget:ClearAllPoints()
				row.widget:SetPoint("TOPLEFT", card, "TOPLEFT", 12, rowY - (lines - 1) * lineH / 2)
				row.widget:SetHitRectInsets(0, -(8 + math.min(full, width)), -4, -4)
				rowY = rowY - height
			end
		end
		card:ClearAllPoints()
		card:SetPoint("TOPLEFT", 8, y)
		card:SetHeight(-rowY + 2)
		y = y + rowY - 2 - 4
	end
	-- Bigger text can need more room than the window has: on the Options tab
	-- the window grows to fit (and goes back to its size on the other tabs)
	if OutfitterOptionsFrame:IsShown() and look.BaseHeight then
		OutfitterFrame:SetHeight(math.max(look.BaseHeight, -y))
	end
end

local function StyleOptions(look)
	local panel = OutfitterOptionsFrame
	HideTitles(panel, Outfitter.cOptionsTitle, "Outfitter_cOptionsTitle")
	local cards = {
		{ Outfitter.cLookAutomation, {
			{ "OutfitterAutoSwitch" },
			{ "OutfitterShowHotkeyMessages", Outfitter.cShowHotkeyMessages, Outfitter.cLookHotkeyMessagesDescription } } },
		{ Outfitter.cLookTooltips, {
			{ "OutfitterTooltipInfo", Outfitter.cTooltipInfo, Outfitter.cLookTooltipInfoDescription },
			{ "OutfitterItemComparisons", Outfitter.cLookItemComparisons, Outfitter.cLookItemComparisonsDescription } } },
		{ Outfitter.cLookQuickAccess, {
			{ "OutfitterShowMinimapButton", Outfitter.cShowMinimapButton, Outfitter.cLookMinimapButtonDescription },
			{ "OutfitterShowOutfitBar", Outfitter.cShowOutfitBar, Outfitter.cLookOutfitBarDescription },
			{ "OutfitterUseSidebarTab", Outfitter.cSidebarTab, Outfitter.cLookSidebarTabDescription },
			{ "RightClick" } } },
	}
	look.CardsTop = -(24 + TAB_H + 6)
	local width = (panel:GetWidth() or 256) - 16
	look.Cards = {}
	for index, info in ipairs(cards) do
		local card = T.Card(panel, info[1], 8, 0, width, ROW_H)
		card:SetFrameLevel(panel:GetFrameLevel())
		card.rows = {}
		for _, option in ipairs(info[2]) do
			local checkName, text, description = option[1], option[2], option[3]
			local check = _G[checkName]
			local row
			if checkName == "OutfitterAutoSwitch" and check then
				-- Outfitter's box is "Disable all outfit scripts" (ticked = off). It's
				-- replaced by a switch that reads like the footer's: on = scripts run.
				check:Hide()
				local switch = ScriptsSwitch(card)
				switch:SetFrameLevel(card:GetFrameLevel() + 2)
				switch.label = T.Text(switch, Outfitter.cLookOutfitScripts, "GameFontHighlightSmall", C.title)
				switch.label:SetPoint("LEFT", switch, "RIGHT", 8, 0)
				switch.label:SetJustifyH("LEFT")
				look.OptionsScripts = switch
				row = { widget = switch, label = switch.label }
			elseif checkName == "RightClick" then
				-- What right-click on the minimap button or broker does
				-- (Outfitter:RightClickAction): a label over a menu field
				local box = CreateFrame("Frame", nil, card)
				box:SetFrameLevel(card:GetFrameLevel() + 2)
				local label = T.Text(box, Outfitter.cLookRightClick, "GameFontHighlightSmall", C.title)
				label:SetPoint("TOPLEFT")
				local field = MenuField(box, LABEL_W + 36,
					function()
						return { { "open", Outfitter.cLookRightClickOpen }, { "menu", Outfitter.cLookRightClickMenu },
							{ "swap", Outfitter.cLookRightClickSwap } }
					end,
					function() return Outfitter:RightClickAction() end,
					function(action) Outfitter:SetRightClickAction(action) end)
				field:SetPoint("BOTTOMLEFT", 0, 6)
				T.Tooltip(field, Outfitter.cLookRightClick, Outfitter.cLookRightClickDescription)
				look.RightClick = field
				row = { widget = box, label = label, field = field }
			elseif check then
				MakeSwitch(check)
				check:SetFrameLevel(card:GetFrameLevel() + 2)
				row = { widget = check, label = _G[checkName .. "Text"] }
				row.label:SetText(text)
				-- One tooltip for every switch, always shown, saying what the option does
				T.Tooltip(check, text, description)
			end
			if row then
				row.label:SetWordWrap(true)
				if not row.field then HoverLabel(row.widget, row.label) end
				table.insert(card.rows, row)
			end
		end
		look.Cards[index] = card
	end

	-- The outfit bar's own settings (also on a right-click on the bar's handle)
	local barRow = look.Cards[3].rows[2]
	if barRow and Outfitter.OutfitBar then
		local settings = FlatButton(look.Cards[3], Outfitter.cLookBarSettings, 1, 16)
		local text = settings:GetFontString()
		text:SetFontObject(GameFontHighlightSmall)
		settings:SetWidth(math.ceil(text:GetStringWidth()) + 12)
		-- At the card's right edge, level with the switch
		settings:SetPoint("LEFT", barRow.widget, "LEFT", width - 22 - settings:GetWidth(), 0)
		settings:SetFrameLevel(look.Cards[3]:GetFrameLevel() + 2)
		settings:SetScript("OnClick", function() Outfitter.OutfitBar:DragBar_OnClick("RightButton") end)
		T.Tooltip(settings, Outfitter.cLookBarSettings, Outfitter.cLookBarSettingsDescription)
		barRow.extra = settings:GetWidth() + 6
		look.BarSettings = settings
	end

	panel:HookScript("OnShow", function() LayoutOptions(look) end)
	LayoutOptions(look)
end

---------------------------------------------------------------------------
-- The checkboxes Outfitter puts on your character's slots
---------------------------------------------------------------------------
local function StyleSlotEnables()
	for _, slot in ipairs(Outfitter.cSlotNames or {}) do
		local check = _G["OutfitterEnable" .. slot]
		if check then
			Fade(check:GetNormalTexture())
			Fade(check:GetPushedTexture())
			Box(check, 14, C.field, C.btnEdge)
		end
	end
	for _, name in ipairs({ "OutfitterEnableAll", "OutfitterEnableNone" }) do
		local button = _G[name]
		if button then Flatten(button, C.card, C.line, C.edge) end
	end
end

---------------------------------------------------------------------------
-- The Display tab: window size, text size and colours
---------------------------------------------------------------------------
local RELOAD = ReloadUI or (C_UI and C_UI.Reload)

-- The window, the open dialogs and (as they open) the menus in the chosen
-- window size and text size
local function ApplyDisplay(look)
	local frame = OutfitterFrame
	frame:SetScale(WindowScale())
	SizeTextIn(frame)
	for _, dialog in ipairs({ Outfitter.NameOutfitDialog, OutfitterEditScriptDialog, OutfitterChooseIconDialog,
		Outfitter.OutfitBar and Outfitter.OutfitBar.SettingsDialog }) do
		if dialog and dialog.Look then DisplayDialog(dialog) end
	end
	LayoutOptions(look)
end

-- A row of choices, one lit: the two pages, the color styles
local function Choices(parent, keys, labels, get, set)
	local row = {}
	for index, key in ipairs(keys) do
		local b = CreateFrame("Button", nil, parent)
		b.bg = T.Fill(b, C.field)
		b.edges = T.Border(b, C.line)
		b.text = T.Text(b, labels[index], "GameFontHighlightSmall")
		b.text:SetPoint("LEFT", 2, 0)
		b.text:SetPoint("RIGHT", -2, 0)
		b.text:SetJustifyH("CENTER")
		b.text:SetWordWrap(false)
		b.text.OFKeep = true
		b.key = key
		b:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			set(key)
			row.Paint()
		end)
		row[index] = b
	end
	function row.Paint()
		for _, b in ipairs(row) do
			local on = get() == b.key
			b.bg:SetColorTexture(unpack(on and C.tabOn or C.field))
			for _, edge in ipairs(b.edges) do edge:SetColorTexture(unpack(on and C.btnEdge or C.line)) end
			local color = on and C.gold or (C.darkText and C.title or C.muted)
			b.text:SetTextColor(color[1], color[2], color[3])
		end
	end
	return row
end

-- A number you can slide or type. The slider moves in whole steps; the box
-- takes any number in range (two decimals, like 90.55) when you press Enter.
-- apply() runs when the slider is let go or Enter is pressed.
local function SizeControl(parent, y, width, label, description, min, max, get, save, apply)
	local title = T.Text(parent, label, "GameFontHighlightSmall", C.title)
	title:SetPoint("TOPLEFT", 12, y)
	local box = T.EditBox(parent, 56)
	box:SetHeight(18)
	box:SetPoint("TOPRIGHT", parent, "TOPLEFT", 12 + width, y + 3)
	box:SetJustifyH("RIGHT")
	local slider = CreateFrame("Slider", nil, parent)
	slider:SetOrientation("HORIZONTAL")
	slider:SetSize(width, 14)
	slider:SetPoint("TOPLEFT", 12, y - 18)
	slider:SetHitRectInsets(0, 0, -6, -6)
	local track = slider:CreateTexture(nil, "BACKGROUND")
	track:SetHeight(4)
	track:SetPoint("LEFT")
	track:SetPoint("RIGHT")
	track:SetColorTexture(unpack(C.offTrack))
	local thumb = slider:CreateTexture(nil, "OVERLAY")
	thumb:SetSize(8, 14)
	thumb:SetColorTexture(unpack(C.gold))
	slider:SetThumbTexture(thumb)
	local fill = slider:CreateTexture(nil, "ARTWORK")
	fill:SetHeight(4)
	fill:SetPoint("LEFT", track, "LEFT")
	fill:SetPoint("RIGHT", thumb, "CENTER")
	fill:SetColorTexture(unpack(C.fill))
	slider:SetMinMaxValues(min, max)
	slider:SetValueStep(1)

	local control = { Slider = slider, Box = box, Title = title }
	local syncing
	local function Show(value)
		box:SetText(value == math.floor(value) and string.format("%d", value) or string.format("%.2f", value))
	end
	function control.Refresh()
		syncing = true
		slider:SetValue(get())
		syncing = false
		Show(get())
	end
	slider:SetScript("OnValueChanged", function(_, value)
		if syncing then return end
		value = math.floor(value + 0.5)
		save(value)
		Show(value)
	end)
	-- The window changes size when the mouse lets go: changing it while
	-- dragging would move the slider under the mouse
	slider:HookScript("OnMouseUp", function() apply() end)
	box:SetScript("OnEnterPressed", function(self)
		local value = tonumber((self:GetText() or ""):gsub(",", "."):match("[%d%.]+") or "")
		if value then
			value = math.floor(math.max(min, math.min(max, value)) * 100 + 0.5) / 100
			save(value)
			apply()
		end
		control.Refresh()
		self:ClearFocus()
	end)
	box:SetScript("OnEscapePressed", function(self)
		control.Refresh()
		self:ClearFocus()
	end)
	T.Tooltip(slider, label, description)
	T.Tooltip(box, label, description .. "\n" .. Outfitter.cLookTypeSize)
	return control
end

local function StyleDisplay(look)
	local frame = OutfitterFrame
	local panel = CreateFrame("Frame", nil, frame)
	panel:SetAllPoints()
	panel:Hide()
	look.Display = panel
	local width = (frame:GetWidth() or 256) - 16
	local inner = width - 24
	local top = -(24 + TAB_H + 6)

	-- Two pages: Size and text, Colors
	local pages = { CreateFrame("Frame", nil, panel), CreateFrame("Frame", nil, panel) }
	for _, page in ipairs(pages) do page:SetAllPoints() end
	look.DisplayPage = look.DisplayPage or 1
	local switch = Choices(panel, { 1, 2 }, { Outfitter.cLookPageSize, Outfitter.cLookPageColors },
		function() return look.DisplayPage end,
		function(index)
			look.DisplayPage = index
			for i, page in ipairs(pages) do page:SetShown(i == index) end
		end)
	local half = (width - 4) / 2
	for index, b in ipairs(switch) do
		b:SetSize(half, 20)
		b:SetPoint("TOPLEFT", panel, "TOPLEFT", 8 + (index - 1) * (half + 4), top)
	end
	look.DisplaySwitch, look.DisplayPages = switch, pages
	top = top - 26

	-- Page 1: the window's size (with its dialogs and menus), the text's size and font
	local size = T.Card(pages[1], Outfitter.cLookSize, 8, top, width, 106)
	look.WindowSize = SizeControl(size, -26, inner, Outfitter.cLookWindowSize, Outfitter.cLookWindowSizeDescription,
		SCALE_MIN, SCALE_MAX,
		function() return tonumber(DisplaySettings().Scale) or 100 end,
		function(value) DisplaySettings().Scale = value ~= 100 and value or nil end,
		function() ApplyDisplay(look) end)
	look.TextSize = SizeControl(size, -66, inner, Outfitter.cLookTextSize, Outfitter.cLookTextSizeDescription,
		TEXT_MIN, TEXT_MAX, TextPercent,
		function(value) DisplaySettings().TextSize = value ~= 100 and value or nil end,
		function() ApplyDisplay(look) end)

	local fontCard = T.Card(pages[1], Outfitter.cLookFont, 8, top - 106 - 4, width, 54)
	local font = MenuField(fontCard, inner,
		function()
			local list = { { false, Outfitter.cLookFontDefault } }
			for _, choice in ipairs(FontChoices()) do list[#list + 1] = { choice[2], choice[1] } end
			return list
		end,
		function() return DisplaySettings().Font or false end,
		function(file)
			DisplaySettings().Font = file or nil
			ApplyDisplay(look)
		end)
	font:SetPoint("TOPLEFT", fontCard, "TOPLEFT", 12, -26)
	T.Tooltip(font, Outfitter.cLookFont, Outfitter.cLookFontDescription)
	look.Font = font

	-- Page 2: the color styles, used from the next reload
	local colors = T.Card(pages[2], Outfitter.cLookColors, 8, top, width, 126)
	local names = { Outfitter.cLookColorDefault, Outfitter.cLookColorContrast, Outfitter.cLookColorBlue, Outfitter.cLookColorLight }
	local reloadNote = T.Text(colors, "", "GameFontHighlightSmall", C.muted)
	reloadNote:SetPoint("TOPLEFT", 12, -88)
	reloadNote:SetWidth(inner - 84)
	reloadNote:SetWordWrap(true)
	local reload = FlatButton(colors, Outfitter.cLookReload, 78, 20)
	reload:SetPoint("TOPRIGHT", colors, "TOPRIGHT", -12, -86)
	reload:SetScript("OnClick", function() if RELOAD then RELOAD() end end)
	look.Reload, look.ReloadNote = reload, reloadNote
	local swatches
	local function PaintColors()
		local chosen = DisplaySettings().Colors or "default"
		for _, b in ipairs(swatches) do
			for _, edge in ipairs(b.edges) do
				edge:SetColorTexture(unpack(b.key == chosen and C.gold or C.line))
			end
		end
		local waiting = chosen ~= appliedColors
		reloadNote:SetText(waiting and (RELOAD and Outfitter.cLookReloadNote or Outfitter.cLookReloadTyped) or "")
		reload:SetShown(waiting and RELOAD ~= nil)
	end
	swatches = Choices(colors, COLOR_KEYS, names,
		function() return DisplaySettings().Colors or "default" end,
		function(key) DisplaySettings().Colors = key ~= "default" and key or nil end)
	-- Two by two, wide enough for the names
	local swatchW = (inner - 4) / 2
	for index, b in ipairs(swatches) do
		b:SetSize(swatchW, 24)
		b:SetPoint("TOPLEFT", colors, "TOPLEFT", 12 + ((index - 1) % 2) * (swatchW + 4), -26 - math.floor((index - 1) / 2) * 28)
		local sample = SWATCHES[b.key]
		b.bg:SetColorTexture(sample[1], sample[2], sample[3], 1)
		-- light text on the dark swatches, dark on the light one
		local dark = b.key == "light"
		b.text:SetTextColor(dark and 0.1 or 1, dark and 0.08 or 1, dark and 0.06 or 1)
		T.Tooltip(b, names[index], Outfitter.cLookColorsDescription)
	end
	-- The swatches show their own colors, not Choices' lit/unlit ones
	function swatches.Paint() PaintColors() end
	look.Swatches = swatches

	-- Back to how it was (both pages)
	local reset = FlatButton(panel, Outfitter.cLookReset, 78, 22)
	reset:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 8)
	reset:SetScript("OnClick", function()
		local settings = DisplaySettings()
		settings.Scale, settings.TextSize, settings.Font, settings.Colors = nil, nil, nil, nil
		look.WindowSize.Refresh()
		look.TextSize.Refresh()
		font.Refresh()
		PaintColors()
		ApplyDisplay(look)
	end)
	T.Tooltip(reset, Outfitter.cLookReset, Outfitter.cLookResetDescription)
	look.DisplayReset = reset

	panel:SetScript("OnShow", function()
		look.WindowSize.Refresh()
		look.TextSize.Refresh()
		font.Refresh()
		PaintColors()
		switch.Paint()
		for i, page in ipairs(pages) do page:SetShown(i == look.DisplayPage) end
	end)
end

---------------------------------------------------------------------------
-- The whole window. Called once, after the original code has built its frame art.
---------------------------------------------------------------------------
function Outfitter:ApplyLook()
	local frame = OutfitterFrame
	if not frame or frame.Look then return end
	local look = {}
	frame.Look = look
	-- The colour style first: everything below is painted in it
	ApplyColors()
	look.BaseHeight = frame:GetHeight()

	-- The original stone frame art goes; a flat dark panel takes its place.
	-- These are the frame's own textures, so they stay behind everything in it.
	for _, piece in pairs(frame.Background or {}) do piece:Hide() end
	look.Fill = T.Fill(frame, C.win)
	look.Edges = T.Border(frame, C.edge)

	-- Header bar: logo, then the name and version
	local header = CreateFrame("Frame", nil, frame)
	header:SetPoint("TOPLEFT")
	header:SetPoint("TOPRIGHT")
	header:SetHeight(24)
	HeaderStrip(header, OutfitterFrameTitle:GetText())
	header:FitLogo(24)
	OutfitterFrameTitle:Hide()
	look.Header = header

	-- A flat X in the header instead of the game's round close button
	local close = FlatButton(header, "X", 18, 18)
	close:SetPoint("RIGHT", -3, 0)
	close:SetScript("OnClick", function() frame:Hide() end)
	header.text:SetPoint("RIGHT", close, "LEFT", -4, 0)
	OutfitterCloseButton:Hide()
	look.Close = close

	-- Outfits / Options tabs under the header, in place of the game's tabs below the window
	-- The Display tab is the look's own panel: Outfitter's panel is put away
	-- (HidePanel) while it shows, and showing one of Outfitter's puts it away
	local function ShowDisplay()
		if self.CurrentPanel > 0 then self:HidePanel(self.CurrentPanel) end
		frame:SetHeight(look.BaseHeight)
		look.Display:Show()
		look.Tabs.Paint(3)
	end
	look.Tabs = MakeTabs(frame, header, { self.cOutfitterTabTitle, self.cOptionsTabTitle, self.cLookDisplayTab },
		function(index)
			if index == 3 then ShowDisplay() else Outfitter:ShowPanel(index) end
		end)
	for index = 1, #look.Tabs do
		local old = _G["OutfitterFrameTab" .. index]
		if old then old:Hide() end
	end
	look.Tabs.Paint(self.CurrentPanel)
	hooksecurefunc(self, "ShowPanel", function(_, index)
		look.Display:Hide()
		if index ~= 2 then frame:SetHeight(look.BaseHeight) end
		look.Tabs.Paint(index)
	end)
	look.ShowDisplay = ShowDisplay

	-- Outfits panel
	HideTitles(OutfitterMainFrame, self.cTitle, "Outfitter_cTitle")
	for index = 0, (self.cMaxDisplayedItems or 14) - 1 do
		local item = _G["OutfitterItem" .. index]
		if item then StyleRow(item) end
	end

	-- The selected outfit: a dark red row with a red bar at its left
	local highlight = OutfitterMainFrameHighlight
	local selected = C.select or { C.redHi[1], C.redHi[2], C.redHi[3], 0.28 }
	highlight:SetColorTexture(selected[1], selected[2], selected[3], selected[4])
	highlight:SetBlendMode("BLEND")
	local bar = OutfitterMainFrame:CreateTexture(nil, "OVERLAY")
	bar:SetPoint("TOPLEFT", highlight, "TOPLEFT")
	bar:SetPoint("BOTTOMLEFT", highlight, "BOTTOMLEFT")
	bar:SetWidth(2)
	bar:SetColorTexture(unpack(C.accent))
	look.SelectedBar = bar

	-- The outfit list's scroll track: flat and dark like the panel, a thin gold thumb
	local track = OutfitterMainFrameScrollbarTrench
	for _, part in ipairs({ "Top", "Middle", "Bottom" }) do
		_G[track:GetName() .. part]:Hide()
	end
	look.Track = T.Fill(track, C.side)
	T.Border(track, C.line)
	local rail = track:CreateTexture(nil, "BORDER")
	rail:SetPoint("TOP", 0, -6)
	rail:SetPoint("BOTTOM", 0, 6)
	rail:SetWidth(6)
	rail:SetColorTexture(unpack(C.offTrack))
	FlatScrollBar(OutfitterMainFrameScrollFrameScrollBar)

	-- Footer: the outfit scripts switch, and New Outfit as a flat red button
	OutfitterMainFrameButtonBarBackground:Hide()
	local footer = OutfitterMainFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
	footer:SetPoint("BOTTOMLEFT", 1, 1)
	footer:SetPoint("BOTTOMRIGHT", -1, 1)
	footer:SetHeight(32)
	footer:SetColorTexture(unpack(C.side))
	local footerLine = OutfitterMainFrame:CreateTexture(nil, "BORDER")
	footerLine:SetPoint("BOTTOMLEFT", footer, "TOPLEFT")
	footerLine:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT")
	footerLine:SetHeight(1)
	footerLine:SetColorTexture(unpack(C.line))
	Flatten(OutfitterNewButton, C.red, C.redHi)

	local scripts = ScriptsSwitch(OutfitterMainFrame)
	scripts:SetPoint("BOTTOMLEFT", 8, 10)
	scripts.label = T.Text(scripts, self.cLookOutfitScripts, "GameFontHighlightSmall", C.muted)
	scripts.label:SetPoint("LEFT", scripts, "RIGHT", 6, 0)
	scripts:SetHitRectInsets(0, -80, -4, -4)
	look.Scripts = scripts

	-- Options panel
	StyleOptions(look)

	-- Slot checkboxes on the character
	StyleSlotEnables()

	-- Display tab, and the window in the chosen sizes (and, for Light, dark text)
	StyleDisplay(look)
	ApplyDisplay(look)
	DarkTextIn(frame)

	-- Keep the switches and the selected row's bar in step with Outfitter's own updates
	local function Refresh()
		if not self.Settings then return end
		scripts:SetOn(not self.Settings.Options.DisableAutoSwitch)
		if look.OptionsScripts then look.OptionsScripts:SetOn(scripts:IsOn()) end
		if look.RightClick then look.RightClick.Refresh() end
		bar:SetShown(highlight:IsShown())
		-- The Equipment Manager tab's row is hidden when there's no tab
		LayoutOptions(look)
	end
	hooksecurefunc(self, "Update", Refresh)
	Refresh()
end

---------------------------------------------------------------------------
-- The New Outfit / Rename dialog: same panel, header bar, cards and flat controls
---------------------------------------------------------------------------
local function StyleSection(section)
	if not section then return end
	if section.SetBackdrop then section:SetBackdrop(nil) end
	T.Fill(section, C.card)
	T.Border(section, C.line)
	if section.Title then
		section.Title:SetFontObject(GameFontNormalSmall)
		section.Title:SetTextColor(C.orange[1], C.orange[2], C.orange[3])
		section.Title:SetText((section.Title:GetText() or ""):upper())
	end
end

local function StyleField(field)
	if not field then return end
	Fade(field.LeftTexture)
	Fade(field.MiddleTexture)
	Fade(field.RightTexture)
	T.Fill(field, C.field)
	T.Border(field, C.fieldEdge)
	if field.Title then field.Title:SetTextColor(C.muted[1], C.muted[2], C.muted[3]) end
end

function Outfitter:StyleDialog(dialog)
	if not dialog or dialog.Look then return end
	dialog.Look = {}
	if dialog.SetBackdrop then dialog:SetBackdrop(nil) end
	T.Fill(dialog, C.win)
	T.Border(dialog, C.edge)

	local header = CreateFrame("Frame", nil, dialog)
	header:SetPoint("TOPLEFT")
	header:SetPoint("TOPRIGHT")
	header:SetHeight(22)
	HeaderStrip(header, dialog.Title and dialog.Title:GetText())
	header:FitLogo(22)
	dialog.Look.Header = header
	if dialog.Title then
		dialog.Title:Hide()
		hooksecurefunc(dialog.Title, "SetText", function(_, text) header.text:SetText(text) end)
	end
	if dialog.TitleBackground then dialog.TitleBackground:Hide() end

	if dialog.DoneButton then Flatten(dialog.DoneButton, C.red, C.redHi) end
	if dialog.CancelButton then Flatten(dialog.CancelButton, C.card, C.line, C.edge) end
	for _, key in ipairs({ "InfoSection", "BuildSection", "StatsSection" }) do
		StyleSection(dialog[key])
	end
	StyleField(dialog.Name)
	if dialog.Name then dialog.Name:SetTextInsets(6, 6, 0, 0) end
	local menu = dialog.ScriptMenu
	if menu then
		StyleField(menu)
		if menu.Button then ArrowButton(menu.Button) end
		if menu.Text then
			menu.Text:SetJustifyH("LEFT")
			menu.Text:SetPoint("LEFT", menu, "LEFT", 6, 0)
		end
	end
end

hooksecurefunc(Outfitter, "OpenNameOutfitDialog", function(self)
	self:StyleDialog(self.NameOutfitDialog)
	DisplayDialog(self.NameOutfitDialog)
end)

---------------------------------------------------------------------------
-- The Edit Script dialog: header bar, flat tabs under it, flat fields and buttons
---------------------------------------------------------------------------
-- Outfitter's text boxes (OutfitterInputFrameTemplate): a flat field instead of the border art
local function StyleInput(frame)
	if not frame or frame.Look then return end
	frame.Look = true
	local name = frame:GetName()
	for _, part in ipairs({ "TopLeft", "TopRight", "BottomLeft", "BottomRight", "Left", "Right", "Top", "Bottom", "Center" }) do
		Fade(_G[name .. part])
	end
	T.Fill(frame, C.field)
	T.Border(frame, C.fieldEdge)
	local label = _G[name .. "Label"]
	if label then label:SetTextColor(C.muted[1], C.muted[2], C.muted[3]) end
	FlatScrollBar(_G[name .. "ScrollBar"] or frame.ScrollBar)
	local zoneButton = _G[name .. "ZoneButton"]
	if zoneButton then Flatten(zoneButton, C.card, C.line, C.edge) end
end

-- The controls a script's settings ask for, made as the Settings tab is shown
local function StyleSettingsFields(dialog)
	for frameType, frames in pairs(dialog.FrameCache or {}) do
		for _, frame in ipairs(frames) do
			if frameType == "Checkbox" then
				if not frame.Look then
					frame.Look = true
					MakeSwitch(frame)
				end
			else
				StyleInput(frame)
			end
		end
	end
end

function Outfitter:StyleScriptDialog(dialog)
	if not dialog or dialog.Look then return end
	local look = {}
	dialog.Look = look
	local name = dialog:GetName()

	-- The portrait frame art, the mail icon and the button bar go; a flat panel instead
	for _, region in ipairs({ dialog:GetRegions() }) do
		if region:GetObjectType() == "Texture" then region:Hide() end
	end
	T.Fill(dialog, C.win)
	T.Border(dialog, C.edge)

	-- Header bar with the dialog's title, and a flat X (it saves, like the old one)
	local header = CreateFrame("Frame", nil, dialog)
	header:SetPoint("TOPLEFT")
	header:SetPoint("TOPRIGHT")
	header:SetHeight(22)
	local title = dialog.Widgets.Title
	HeaderStrip(header, title:GetText())
	header:FitLogo(22)
	title:Hide()
	hooksecurefunc(title, "SetText", function(_, text) header.text:SetText(text) end)
	if dialog.CloseButton then dialog.CloseButton:Hide() end
	local close = FlatButton(header, "X", 18, 18)
	close:SetPoint("RIGHT", -3, 0)
	close:SetScript("OnClick", function() dialog:Done() end)
	header.text:SetPoint("RIGHT", close, "LEFT", -4, 0)
	look.Header, look.Close = header, close

	-- Settings / Source tabs under the header, in place of the game's tabs below the dialog
	look.Tabs = MakeTabs(dialog, header, { self.cSettings, self.cSource },
		function(index) dialog:SetPanelIndex(index) end, 110)
	for index = 1, 2 do
		local old = _G[name .. "Tab" .. index]
		if old then old:Hide() end
	end
	look.Tabs.Paint(dialog.selectedTab)

	-- The preset script menu, moved down below the tabs
	local menu = dialog.Widgets.PresetScript
	if menu then
		StyleField(menu)
		if menu.Button then ArrowButton(menu.Button) end
		if menu.Text then
			menu.Text:SetJustifyH("LEFT")
			menu.Text:SetPoint("LEFT", menu, "LEFT", 6, 0)
		end
		menu:ClearAllPoints()
		menu:SetPoint("TOPLEFT", dialog, "TOPLEFT", 330, -54)
	end

	-- The script's text box and its status line
	StyleInput(_G[name .. "SourceScript"])
	local statusLabel = _G[name .. "SourceStatusLabel"]
	if statusLabel then statusLabel:SetTextColor(C.muted[1], C.muted[2], C.muted[3]) end
	local description = dialog.Widgets.SettingsDescription
	if description then description:SetTextColor(C.title[1], C.title[2], C.title[3]) end

	-- Footer: a flat strip with Done (red) and Cancel
	local footer = dialog:CreateTexture(nil, "BACKGROUND", nil, -7)
	footer:SetPoint("BOTTOMLEFT", 1, 1)
	footer:SetPoint("BOTTOMRIGHT", -1, 1)
	footer:SetHeight(34)
	footer:SetColorTexture(unpack(C.side))
	local footerLine = dialog:CreateTexture(nil, "BORDER")
	footerLine:SetPoint("BOTTOMLEFT", footer, "TOPLEFT")
	footerLine:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT")
	footerLine:SetHeight(1)
	footerLine:SetColorTexture(unpack(C.line))
	Flatten(_G[name .. "DoneButton"], C.red, C.redHi)
	Flatten(_G[name .. "CancelButton"], C.card, C.line, C.edge)

	StyleSettingsFields(dialog)
end

-- Outfitter.xml copies _EditScriptDialog's methods into the dialog as it builds it,
-- so these hooks are set here, before that
hooksecurefunc(Outfitter._EditScriptDialog, "Open", function(self)
	Outfitter:StyleScriptDialog(self)
	StyleSettingsFields(self)
	DisplayDialog(self)
end)

hooksecurefunc(Outfitter._EditScriptDialog, "ConstructSettingsFields", function(self)
	if self.Look then StyleSettingsFields(self) end
end)

hooksecurefunc(Outfitter._EditScriptDialog, "SetPanelIndex", function(self, index)
	if self.Look then self.Look.Tabs.Paint(index) end
end)

---------------------------------------------------------------------------
-- The outfit bar: a flat dark panel with a thin gold edge, flat icon buttons,
-- thin gold drag handles, and its two dialogs in the same look
---------------------------------------------------------------------------
-- An icon button (ActionButtonTemplate): the slot art goes, the icon fills it
-- with a gold edge; worn is a dark red wash, hover a light one
local function StyleIconButton(button)
	if not button or button.Look then return end
	button.Look = true
	Fade(button:GetNormalTexture())
	Fade(button:GetPushedTexture())
	-- Arrow / BorderShadow: the template's flyout arrow. ActionButtonTemplate's OnLoad replaces the
	-- flyout's, so the arrow is never sized or hidden, and pressing the button draws it as a big
	-- yellow triangle over the icon
	for _, key in ipairs({ "SlotArt", "SlotBackground", "Border", "NormalTexture", "FloatingBG", "Arrow", "BorderShadow" }) do
		if type(button[key]) == "table" and button[key].SetAlpha then Fade(button[key]) end
	end
	local icon = button.icon or button.Icon or _G[button:GetName() .. "Icon"]
	if icon then
		if button.IconMask and icon.RemoveMaskTexture then icon:RemoveMaskTexture(button.IconMask) end
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
	T.Fill(button, C.field)
	T.Border(button, C.btnEdge)
	-- Worn (checked): a bright gold edge, 2 wide, in place of the template's check art,
	Fade(button:GetCheckedTexture())
	local worn = {}
	for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
		local edge = button:CreateTexture(nil, "OVERLAY", nil, 7)
		edge:SetColorTexture(unpack(C.gold))
		if side == "TOP" or side == "BOTTOM" then
			edge:SetPoint(side .. "LEFT")
			edge:SetPoint(side .. "RIGHT")
			edge:SetHeight(2)
		else
			edge:SetPoint("TOP" .. side)
			edge:SetPoint("BOTTOM" .. side)
			edge:SetWidth(2)
		end
		worn[#worn + 1] = edge
	end
	-- and a gold check badge in the bottom right corner
	-- (the badge one sub-layer under the check, so the check always draws on top)
	local badge = button:CreateTexture(nil, "OVERLAY", nil, 6)
	badge:SetSize(12, 12)
	badge:SetPoint("BOTTOMRIGHT")
	badge:SetColorTexture(unpack(C.gold))
	local tick = button:CreateTexture(nil, "OVERLAY", nil, 7)
	tick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	tick:SetSize(16, 16)
	tick:SetPoint("CENTER", badge, "CENTER", 1, 0)
	tick:SetVertexColor(C.win[1], C.win[2], C.win[3])
	button.WornTick = tick
	worn[#worn + 1] = badge
	worn[#worn + 1] = tick
	button.WornEdges = worn
	button.WornBadge = badge
	local function PaintWorn()
		local on = button:GetChecked() and true or false
		for _, edge in ipairs(worn) do edge:SetShown(on) end
	end
	hooksecurefunc(button, "SetChecked", PaintWorn)
	button:HookScript("OnClick", PaintWorn)
	PaintWorn()
	-- The template gives the hover light its own size and anchors; it covers the
	-- button exactly instead, so it lines up when the bar makes the button smaller
	local highlight = button:GetHighlightTexture()
	if highlight then
		highlight:SetColorTexture(1, 1, 1, 0.15)
		highlight:SetBlendMode("BLEND")
		highlight:ClearAllPoints()
		highlight:SetAllPoints(button)
	end
end

-- The bar: upstream's stone background is always hidden; "Hide background"
-- hides the flat panel instead
local function StyleBar(bar)
	if not bar.Look then
		bar.Look = { Fill = T.Fill(bar, { C.win[1], C.win[2], C.win[3], 0.9 }), Edges = T.Border(bar, C.btnEdge) }
	end
	for _, texture in ipairs(bar.BackgroundTextures or {}) do texture:Hide() end
	local show = not bar.HideBackground
	bar.Look.Fill:SetShown(show)
	for _, edge in ipairs(bar.Look.Edges) do edge:SetShown(show) end
	for _, button in ipairs(bar.Buttons or {}) do StyleIconButton(button) end

	-- Upstream's buttons are wider (47) than their spacing (42); the stone art hid
	-- the overlap. Keep the bar's size and grid, and centre a smaller button in
	-- each cell so they sit apart.
	local style = Outfitter.Style.ButtonBar
	local size = style.ButtonWidth
	local left = (style.BackgroundWidth0 + style.BackgroundWidthN - size) / 2
	local top = (style.BackgroundHeight0 + style.BackgroundHeightN - size) / 2
	local index = 1
	for row = 1, bar.NumRows or 0 do
		for column = 1, bar.NumColumns or 0 do
			local button = bar.Buttons[index]
			if button then
				button:SetSize(size, size)
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", bar, "TOPLEFT",
					left + (column - 1) * style.BackgroundWidth, -(top + (row - 1) * style.BackgroundHeight))
			end
			index = index + 1
		end
	end
end

-- Outfitter.xml / OutfitterBar.lua copy these methods into the frames as they
-- make them, so the hooks are set here, before that
hooksecurefunc(Outfitter._ButtonBar, "SetDimensions", StyleBar)
hooksecurefunc(Outfitter._ButtonBar, "ShowBackground", StyleBar)

-- Drag handles: a thin gold bar in place of the grip art
hooksecurefunc(Outfitter.OutfitBar._DragBar, "SetVerticalOrientation", function(self, vertical)
	local texture = self.DragTexture
	texture:SetTexCoord(0, 1, 0, 1)
	texture:SetColorTexture(C.btnEdge[1], C.btnEdge[2], C.btnEdge[3], 0.9)
	if vertical then texture:SetHeight(4) else texture:SetWidth(4) end
end)

-- A slider (OptionsSliderTemplate): a thin dark track and a gold thumb
local function StyleSlider(slider)
	if not slider or slider.Look then return end
	slider.Look = true
	if slider.NineSlice then slider.NineSlice:Hide() end
	if slider.SetBackdrop then slider:SetBackdrop(nil) end
	local track = slider:CreateTexture(nil, "BACKGROUND")
	track:SetPoint("LEFT", 4, 0)
	track:SetPoint("RIGHT", -4, 0)
	track:SetHeight(4)
	track:SetColorTexture(unpack(C.offTrack))
	local thumb = slider:GetThumbTexture()
	if thumb then
		thumb:SetColorTexture(unpack(C.gold))
		thumb:SetSize(8, 14)
	end
	for _, key in ipairs({ "Text", "Low", "High" }) do
		local label = slider[key] or _G[slider:GetName() .. key]
		if label then label:SetTextColor(C.muted[1], C.muted[2], C.muted[3]) end
	end
	if slider.Text then slider.Text:SetTextColor(C.title[1], C.title[2], C.title[3]) end
end

-- The bar's settings (right-click a drag handle): flat panel, switches, flat sliders
local function StyleBarSettings(self)
	if self.Look then return end
	self.Look = true
	self:SetBackdrop(nil)
	T.Fill(self, C.win)
	T.Border(self, C.btnEdge)
	for _, key in ipairs({ "SizeSlider", "AlphaSlider", "CombatAlphaSlider" }) do StyleSlider(self[key]) end
	-- Upstream stacked its checkboxes overlapping (they were 24 high, 7 apart);
	-- the switches get a row each, under the sliders
	local previous
	for _, key in ipairs({ "VerticalCheckbutton", "LockPositionCheckbutton", "HideBackgroundCheckbutton" }) do
		local check = self[key]
		if check then
			MakeSwitch(check)
			-- the dialog is narrow: shorter labels than in Options
			local label = check.Text or _G[check:GetName() .. "Text"]
			if label then label:SetWidth(120) end
			check:SetHitRectInsets(0, -128, -4, -4)
			check:ClearAllPoints()
			if previous then
				check:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -8)
			else
				check:SetPoint("TOPLEFT", self, "TOPLEFT", 14, -166)
			end
			previous = check
		end
	end
	self:SetHeight(166 + 3 * 16 + 2 * 8 + 14)
end

hooksecurefunc(Outfitter.OutfitBar._SettingsDialog, "ShowDialog", function(self)
	StyleBarSettings(self)
	-- ShowDialog put it under the mouse; at another size the same spot needs
	-- the offset in the dialog's own scale
	local point, relativeTo, relativePoint, x, y = self:GetPoint(1)
	DisplayDialog(self)
	local scale = self:GetScale()
	if point and x and y and scale ~= 1 then
		self:ClearAllPoints()
		self:SetPoint(point, relativeTo, relativePoint, x / scale, y / scale)
	end
end)

-- The icon picker: header bar with its title, flat fields, buttons and icons
local function StyleIconDialog(dialog)
	if dialog.Look then return end
	local look = {}
	dialog.Look = look
	local name = dialog:GetName()
	dialog:SetBackdrop(nil)
	for _, child in ipairs({ dialog:GetChildren() }) do
		-- the frame art (OutfitterDialogFrameTemplate)
		if child.backdropInfo and not child:GetName() then
			child:SetBackdrop(nil)
			child:Hide()
		end
	end
	T.Fill(dialog, C.win)
	T.Border(dialog, C.edge)

	local header = CreateFrame("Frame", nil, dialog)
	header:SetPoint("TOPLEFT")
	header:SetPoint("TOPRIGHT")
	header:SetHeight(22)
	local title = dialog.Widgets.Title
	HeaderStrip(header, title:GetText())
	header:FitLogo(22)
	title:SetAlpha(0) -- it stays as the anchor for the fields below it
	hooksecurefunc(title, "SetText", function(_, text) header.text:SetText(text) end)
	look.Header = header

	local menu = dialog.Widgets.IconSetMenu
	if menu then
		StyleField(menu)
		if menu.Button then ArrowButton(menu.Button) end
		if menu.Text then
			menu.Text:SetJustifyH("LEFT")
			menu.Text:SetPoint("LEFT", menu, "LEFT", 6, 0)
		end
	end
	local filter = dialog.Widgets.FilterEditBox
	if filter then
		for _, region in ipairs({ filter:GetRegions() }) do
			if region:GetObjectType() == "Texture" then region:Hide() end
		end
		T.Fill(filter, C.field)
		T.Border(filter, C.fieldEdge)
		filter:SetTextInsets(6, 6, 0, 0)
	end
	FlatScrollBar(_G[name .. "ScrollFrameScrollBar"])
	Flatten(_G[name .. "OKButton"], C.red, C.redHi)
	Flatten(_G[name .. "CancelButton"], C.card, C.line, C.edge)
	for _, button in ipairs(dialog.IconButtons or {}) do StyleIconButton(button) end
end

-- Upstream counts how many icons fit across by the icon's width alone, then puts
-- 10 px between them, so with 45-wide icons it makes 6 columns in a 270-wide
-- area and the last one sticks out on the right (reported in 1.4.0). Keep its
-- rows and columns and size the icons so the grid fits.
local ICON_GAP = 8
local function LayoutIconButtons(dialog)
	local area = dialog.Widgets.ScrollFrame
	local columns, rows = dialog.NumColumns or 1, dialog.NumRows or 1
	local width, height = area:GetWidth() or 0, area:GetHeight() or 0
	local size = math.floor(math.min((width - (columns - 1) * ICON_GAP) / columns,
		(height - (rows - 1) * ICON_GAP) / rows))
	if size < 16 then return end
	for index, button in ipairs(dialog.IconButtons or {}) do
		StyleIconButton(button)
		local column, row = (index - 1) % columns, math.floor((index - 1) / columns)
		button:SetSize(size, size)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", area, "TOPLEFT", column * (size + ICON_GAP), -row * (size + ICON_GAP))
	end
end

hooksecurefunc(Outfitter.OutfitBar._ChooseIconDialog, "Open", StyleIconDialog)
hooksecurefunc(Outfitter.OutfitBar._ChooseIconDialog, "Open", LayoutIconButtons)
hooksecurefunc(Outfitter.OutfitBar._ChooseIconDialog, "Open", DisplayDialog)

---------------------------------------------------------------------------
-- Outfitter's menus (its own copy of LibDropdown): a flat dark panel with a
-- thin gold edge, a dark red row under the mouse, gold checks and arrows.
-- The library calls these as it sets up each menu and each line.
---------------------------------------------------------------------------
local Dropdown = LibStub("LibDropdownMC-1.0")

function Dropdown.StyleFrame(frame)
	-- The library has just set the menu to the tooltip's size; the window size applies on top
	frame:SetScale(frame:GetScale() * WindowScale())
	if frame.NineSlice then frame.NineSlice:Hide() end
	if frame.SetBackdrop and not frame.NineSlice then frame:SetBackdrop(nil) end
	if not frame.Look then
		local menu = C.menu or { C.win[1], C.win[2], C.win[3], 0.97 }
		frame.Look = { Fill = T.Fill(frame, menu), Edges = T.Border(frame, C.btnEdge) }
	end
end

function Dropdown.StyleButton(button)
	local highlight = button:GetHighlightTexture()
	if highlight then
		highlight:SetColorTexture(C.redHi[1], C.redHi[2], C.redHi[3], 0.35)
		highlight:SetBlendMode("BLEND")
	end
	if button.text then SizeText(button.text, TextScale()) end
	if button.check then button.check:SetVertexColor(C.gold[1], C.gold[2], C.gold[3]) end
	if button.expand then button.expand:SetVertexColor(C.orange[1], C.orange[2], C.orange[3]) end
end
