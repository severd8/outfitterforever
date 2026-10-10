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
	if fs then fs:SetTextColor(C.gold[1], C.gold[2], C.gold[3]) end
	return bg
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
		tab.text = T.Text(tab, label, "GameFontNormal")
		tab.text:SetPoint("CENTER")
		tab.text:SetJustifyH("CENTER")
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
local ROW_H = 24

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

local function StyleOptions(look)
	local panel = OutfitterOptionsFrame
	HideTitles(panel, Outfitter.cOptionsTitle, "Outfitter_cOptionsTitle")
	local cards = {
		{ Outfitter.cOutfitterTabTitle, { "OutfitterAutoSwitch", "OutfitterShowHotkeyMessages" } },
		{ Outfitter.cLookTooltips, { "OutfitterTooltipInfo", "OutfitterItemComparisons" } },
		{ Outfitter.cLookQuickAccess, { "OutfitterShowMinimapButton", "OutfitterShowOutfitBar", "OutfitterUseSidebarTab" } },
	}
	local y = -(24 + TAB_H + 8)
	local width = (panel:GetWidth() or 256) - 16
	look.Cards = {}
	for index, info in ipairs(cards) do
		local rows = #info[2]
		local card = T.Card(panel, info[1], 8, y, width, 30 + rows * ROW_H)
		card:SetFrameLevel(panel:GetFrameLevel())
		for row, checkName in ipairs(info[2]) do
			local check = _G[checkName]
			if checkName == "OutfitterAutoSwitch" and check then
				-- Outfitter's box is "Disable all outfit scripts" (ticked = off). It's
				-- replaced by a switch that reads like the footer's: on = scripts run.
				check:Hide()
				local switch = ScriptsSwitch(card)
				switch:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -26 - (row - 1) * ROW_H)
				switch:SetFrameLevel(card:GetFrameLevel() + 2)
				switch.label = T.Text(switch, Outfitter.cLookOutfitScripts, "GameFontHighlightSmall", C.title)
				switch.label:SetPoint("LEFT", switch, "RIGHT", 8, 0)
				switch:SetHitRectInsets(0, -188, -4, -4)
				look.OptionsScripts = switch
			elseif check then
				MakeSwitch(check)
				check:ClearAllPoints()
				check:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -26 - (row - 1) * ROW_H)
				check:SetFrameLevel(card:GetFrameLevel() + 2)
			end
		end
		card.rows = rows
		look.Cards[index] = card
		y = y - (30 + rows * ROW_H) - 6
	end
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
-- The whole window. Called once, after the original code has built its frame art.
---------------------------------------------------------------------------
function Outfitter:ApplyLook()
	local frame = OutfitterFrame
	if not frame or frame.Look then return end
	local look = {}
	frame.Look = look

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
	T.HeaderStrip(header, OutfitterFrameTitle:GetText())
	header:FitLogo(24)
	OutfitterFrameTitle:Hide()
	look.Header = header

	-- A flat X in the header instead of the game's round close button
	local close = T.FlatButton(header, "X", 18, 18)
	close:SetPoint("RIGHT", -3, 0)
	close:SetScript("OnClick", function() frame:Hide() end)
	header.text:SetPoint("RIGHT", close, "LEFT", -4, 0)
	OutfitterCloseButton:Hide()
	look.Close = close

	-- Outfits / Options tabs under the header, in place of the game's tabs below the window
	look.Tabs = MakeTabs(frame, header, { self.cOutfitterTabTitle, self.cOptionsTabTitle },
		function(index) Outfitter:ShowPanel(index) end)
	for index = 1, #look.Tabs do
		local old = _G["OutfitterFrameTab" .. index]
		if old then old:Hide() end
	end
	look.Tabs.Paint(self.CurrentPanel)
	hooksecurefunc(self, "ShowPanel", function(_, index) look.Tabs.Paint(index) end)

	-- Outfits panel
	HideTitles(OutfitterMainFrame, self.cTitle, "Outfitter_cTitle")
	for index = 0, (self.cMaxDisplayedItems or 14) - 1 do
		local item = _G["OutfitterItem" .. index]
		if item then StyleRow(item) end
	end

	-- The selected outfit: a dark red row with a red bar at its left
	local highlight = OutfitterMainFrameHighlight
	highlight:SetColorTexture(C.redHi[1], C.redHi[2], C.redHi[3], 0.28)
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

	-- Keep the switches and the selected row's bar in step with Outfitter's own updates
	local function Refresh()
		if not self.Settings then return end
		scripts:SetOn(not self.Settings.Options.DisableAutoSwitch)
		if look.OptionsScripts then look.OptionsScripts:SetOn(scripts:IsOn()) end
		bar:SetShown(highlight:IsShown())
		local sidebar = look.Cards[3]
		if sidebar then
			local rows = (OutfitterUseSidebarTab and OutfitterUseSidebarTab:IsShown()) and sidebar.rows or sidebar.rows - 1
			sidebar:SetHeight(30 + rows * ROW_H)
		end
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
	T.HeaderStrip(header, dialog.Title and dialog.Title:GetText())
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
	T.HeaderStrip(header, title:GetText())
	header:FitLogo(22)
	title:Hide()
	hooksecurefunc(title, "SetText", function(_, text) header.text:SetText(text) end)
	if dialog.CloseButton then dialog.CloseButton:Hide() end
	local close = T.FlatButton(header, "X", 18, 18)
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
	for _, key in ipairs({ "SlotArt", "SlotBackground", "Border", "NormalTexture", "FloatingBG" }) do
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
hooksecurefunc(Outfitter.OutfitBar._SettingsDialog, "ShowDialog", function(self)
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
	T.HeaderStrip(header, title:GetText())
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

hooksecurefunc(Outfitter.OutfitBar._ChooseIconDialog, "Open", StyleIconDialog)

---------------------------------------------------------------------------
-- Outfitter's menus (its own copy of LibDropdown): a flat dark panel with a
-- thin gold edge, a dark red row under the mouse, gold checks and arrows.
-- The library calls these as it sets up each menu and each line.
---------------------------------------------------------------------------
local Dropdown = LibStub("LibDropdownMC-1.0")

function Dropdown.StyleFrame(frame)
	if frame.NineSlice then frame.NineSlice:Hide() end
	if frame.SetBackdrop and not frame.NineSlice then frame:SetBackdrop(nil) end
	if not frame.Look then
		frame.Look = { Fill = T.Fill(frame, { C.win[1], C.win[2], C.win[3], 0.97 }), Edges = T.Border(frame, C.btnEdge) }
	end
end

function Dropdown.StyleButton(button)
	local highlight = button:GetHighlightTexture()
	if highlight then
		highlight:SetColorTexture(C.redHi[1], C.redHi[2], C.redHi[3], 0.35)
		highlight:SetBlendMode("BLEND")
	end
	if button.check then button.check:SetVertexColor(C.gold[1], C.gold[2], C.gold[3]) end
	if button.expand then button.expand:SetVertexColor(C.orange[1], C.orange[2], C.orange[3]) end
end
