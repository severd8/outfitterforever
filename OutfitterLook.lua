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

-- The colours as Theme.lua sets them, kept so a style or your own colours can
-- be applied (and taken off) at any time. Every entry of C stays the same
-- table: what's painted keeps a reference to it (see Paint) and is repainted
-- from it. hover, select and menu are the look's own (see PRESETS).
local DEFAULTS = {}
for name, value in pairs(C) do
	if type(value) == "table" then DEFAULTS[name] = { unpack(value) } end
end
C.hover = { unpack(C.gold) }
C.select = { C.redHi[1], C.redHi[2], C.redHi[3], 0.28 }
C.menu = { C.win[1], C.win[2], C.win[3], 0.97 }
C.header = { unpack(C.red) } -- the header bars (their own colour since 1.7.0, not the buttons')
for _, name in ipairs({ "hover", "select", "menu", "header" }) do DEFAULTS[name] = { unpack(C[name]) } end

local function SetColor(name, value)
	local color = C[name]
	color[1], color[2], color[3] = value[1], value[2], value[3]
	if value[4] then color[4] = value[4] end
end

local function Mix(a, b, amount)
	return { a[1] + (b[1] - a[1]) * amount, a[2] + (b[2] - a[2]) * amount, a[3] + (b[3] - a[3]) * amount }
end
local WHITE = { 1, 1, 1 }

-- Your own colours (the Colors page): six, each with the shades made from it
local CUSTOM_KEYS = { "background", "panels", "header", "text", "headings", "buttons", "highlight" }
local CUSTOM = {
	background = function(c)
		SetColor("win", c)
		SetColor("side", Mix(c, { 0, 0, 0 }, 0.3))
		SetColor("field", Mix(c, { 0, 0, 0 }, 0.2))
		SetColor("menu", c)
	end,
	panels = function(c)
		SetColor("card", c)
		SetColor("line", Mix(c, WHITE, 0.1))
	end,
	text = function(c)
		SetColor("title", c)
		SetColor("muted", Mix(c, C.win, 0.2))
		SetColor("grey", Mix(c, C.win, 0.45))
		SetColor("offTrack", Mix(c, C.win, 0.75))
	end,
	header = function(c) SetColor("header", c) end,
	headings = function(c) SetColor("orange", c) end,
	buttons = function(c)
		SetColor("red", c)
		SetColor("redHi", Mix(c, WHITE, 0.18))
		SetColor("onTrack", c)
		SetColor("tabOn", Mix(c, C.win, 0.5))
		SetColor("select", Mix(c, WHITE, 0.18))
	end,
	highlight = function(c)
		for _, name in ipairs({ "gold", "hover", "accent", "fill", "version" }) do SetColor(name, c) end
		-- every button and switch is edged in it, so a button stays visible even
		-- in the colour of what's behind it
		SetColor("btnEdge", c)
		SetColor("edge", Mix(c, C.win, 0.5))
		SetColor("fieldEdge", Mix(c, C.win, 0.6))
	end,
}

-- "#RRGGBB" (or without the #) to a colour, and back
local function FromHex(text)
	local hex = type(text) == "string" and text:match("^%s*#?(%x%x%x%x%x%x)%s*$")
	if not hex then return nil end
	return { tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255 }
end
local function ToHex(color)
	return string.format("#%02X%02X%02X", math.floor(color[1] * 255 + 0.5), math.floor(color[2] * 255 + 0.5),
		math.floor(color[3] * 255 + 0.5))
end

-- The colours in use: the defaults, then the chosen style, then your own colours
local appliedColors = "default"
local function ApplyColors()
	for name, value in pairs(DEFAULTS) do SetColor(name, value) end
	C.darkText = nil
	local key = DisplaySettings().Colors
	local preset = PRESETS[key]
	appliedColors = preset and key or "default"
	if preset then
		for name, value in pairs(preset) do
			if name == "darkText" then
				C.darkText = value
			elseif C[name] then
				SetColor(name, value)
			end
		end
		if not preset.hover then SetColor("hover", C.gold) end
		if not preset.select then SetColor("select", { C.redHi[1], C.redHi[2], C.redHi[3], 0.28 }) end
		if not preset.menu then SetColor("menu", { C.win[1], C.win[2], C.win[3], 0.97 }) end
		if not preset.header then SetColor("header", C.red) end
	end
	local custom = DisplaySettings().Custom or {}
	for _, slot in ipairs(CUSTOM_KEYS) do
		local color = FromHex(custom[slot])
		if color then CUSTOM[slot](color) end
	end
end

---------------------------------------------------------------------------
-- Painting that can be redone: every colour the look sets goes through Paint
-- (textures), Ink (text) or Tint (vertex colour), which remember which of the
-- shared colours it was. Repaint() sets them all again from the colours as
-- they are now, so a new colour style or your own colours show at once.
---------------------------------------------------------------------------
local painted = setmetatable({}, { __mode = "k" })
local inked = setmetatable({}, { __mode = "k" })
local tinted = setmetatable({}, { __mode = "k" })
local repainters = {}

local function Paint(texture, color, alpha)
	if not texture then return end
	painted[texture] = { color, alpha }
	texture:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
	return texture
end

local function Ink(region, color)
	if not region then return end
	inked[region] = color
	region:SetTextColor(color[1], color[2], color[3])
end

local function Tint(texture, color)
	if not texture then return end
	tinted[texture] = color
	texture:SetVertexColor(color[1], color[2], color[3])
end

-- Something that paints itself by its state (a switch, a tab row): run again on Repaint
local function OnRepaint(func) repainters[#repainters + 1] = func end

local function Repaint()
	for texture, p in pairs(painted) do
		local color = p[1]
		texture:SetColorTexture(color[1], color[2], color[3], p[2] or color[4] or 1)
	end
	for region, color in pairs(inked) do region:SetTextColor(color[1], color[2], color[3]) end
	for texture, color in pairs(tinted) do texture:SetVertexColor(color[1], color[2], color[3]) end
	for _, func in ipairs(repainters) do func() end
end

-- Edges one screen pixel thick. A 1-unit line at a window size or UI scale
-- other than 100% falls on part of a pixel, and the game rounds some sides to
-- a pixel and others to none (a player saw half-thin edges at 90%). So each
-- edge is sized to a pixel at its own scale, and again when the scale changes
-- (FitEdges). Without the screen's size, the edges just aren't snapped.
local edgeList = setmetatable({}, { __mode = "k" })

local function PixelSize(region)
	if not GetPhysicalScreenSize then return nil end
	local _, height = GetPhysicalScreenSize()
	local scale = region:GetEffectiveScale()
	if not height or height <= 0 or not scale or scale <= 0 then return nil end
	return 768 / height / scale
end

local function FitEdge(texture, horizontal)
	local pixel = PixelSize(texture)
	if pixel then
		if horizontal then texture:SetHeight(pixel) else texture:SetWidth(pixel) end
	else
		texture:SetSnapToPixelGrid(false)
		texture:SetTexelSnappingBias(0)
	end
end

local function Edge(texture, horizontal)
	edgeList[texture] = horizontal and true or false
	FitEdge(texture, horizontal)
	return texture
end

local function FitEdges()
	for texture, horizontal in pairs(edgeList) do FitEdge(texture, horizontal) end
end

-- An edge laid along its frame's top or bottom (both its points on one side)
local function Horizontal(texture)
	local first, second = texture:GetPoint(1), texture:GetPoint(2)
	return first and second and first:sub(1, 3) == second:sub(1, 3)
end

-- The shared look's pieces, with their colours remembered. Theme.lua stays as
-- it is (it's shared with the other Forever addons): its pieces are painted,
-- then their parts are found by draw layer and painted again here.
local function Fill(frame, color, layer, sub, alpha)
	local texture = T.Fill(frame, color, layer, sub)
	return Paint(texture, color, alpha)
end

local function Border(frame, color)
	local edges = T.Border(frame, color)
	for index, edge in ipairs(edges) do
		Paint(edge, color)
		Edge(edge, index <= 2) -- top, bottom, left, right
	end
	return edges
end

local function Text(parent, text, template, color, size)
	local fs = T.Text(parent, text, template, color, size)
	if color then Ink(fs, color) end
	return fs
end

local function PaintParts(frame, fill, edge)
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == "Texture" and not painted[region] then
			local layer = region:GetDrawLayer()
			if layer == "BACKGROUND" and fill then Paint(region, fill)
			elseif layer == "BORDER" and edge then
				Paint(region, edge)
				Edge(region, Horizontal(region))
			end
		end
	end
end

local function Card(parent, title, x, y, w, h)
	local card = T.Card(parent, title, x, y, w, h)
	PaintParts(card, C.card, C.line)
	Ink(card.title, C.orange)
	card.title.OFHeading = true
	return card
end

local function EditBox(parent, width)
	local box = T.EditBox(parent, width)
	PaintParts(box, C.field, C.fieldEdge)
	return box
end

local function SwitchWidget(parent)
	local switch = T.SwitchWidget(parent)
	Border(switch, C.btnEdge)
	OnRepaint(function() switch:SetOn(switch:IsOn()) end)
	return switch
end

local function MenuArrow(button, inset)
	local arrow = T.MenuArrow(button, inset)
	Tint(arrow, C.orange)
	return arrow
end

-- Text in the chosen size: each font string and edit box keeps its original
-- font and size, and gets that size times the factor
-- Headings (header bars, card titles, tabs, categories: marked OFHeading) can
-- have a font of their own. Outline and shadow are for all text.
local function SizeText(region, factor)
	if not region or not region.SetFont or not region.GetFont then return end
	local settings = DisplaySettings()
	local base = region.OFTextBase
	if not base then
		if factor == 1 and not settings.Font and not settings.HeadingFont and not settings.Outline and not settings.Shadow then
			return
		end
		local font, size, flags = region:GetFont()
		if not font or not size then return end
		base = { font, size, flags }
		if region.GetShadowOffset then
			local x, y = region:GetShadowOffset()
			if x then base.shadow = { x, y } end
		end
		region.OFTextBase = base
	end
	local font = region.OFHeading and settings.HeadingFont or settings.Font or base[1]
	local size, flags = base[2] * factor, settings.Outline or base[3] or ""
	-- A font the game won't use leaves the text blank (a player saw it in the
	-- font field): the text keeps its own font then
	if not region:SetFont(font, size, flags) then
		region:SetFont(base[1], size, flags)
	end
	-- A font that's still loading can leave the text blank until it's set again
	if region:GetObjectType() == "FontString" then
		local text = region:GetText()
		if text and text ~= "" then
			region:SetText("")
			region:SetText(text)
		end
	end
	if region.SetShadowOffset then
		if settings.Shadow then
			region:SetShadowOffset(1, -1)
			region:SetShadowColor(0, 0, 0, 1)
		elseif base.shadow then
			region:SetShadowOffset(base.shadow[1], base.shadow[2])
		end
	end
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
	if color then
		region.OFOrigColor = region.OFOrigColor or { r, g, b }
		Ink(region, color)
	end
end

-- Leaving Light colours: the darkened text gets its own colour back
local function UndarkText()
	for region in pairs(inked) do
		local color = region.OFOrigColor
		if color then
			inked[region] = nil
			region.OFOrigColor = nil
			region:SetTextColor(color[1], color[2], color[3])
		end
	end
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
	FitEdges()
end

-- The game's UI scale or screen size changed: every edge to a pixel again
local scaleWatch = CreateFrame("Frame")
scaleWatch:RegisterEvent("UI_SCALE_CHANGED")
scaleWatch:RegisterEvent("DISPLAY_SIZE_CHANGED")
scaleWatch:SetScript("OnEvent", function() FitEdges() end)

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
	Paint(bg, fill)
	local edges = {
		{ size, 1, 0, half - 0.5 }, { size, 1, 0, 0.5 - half },
		{ 1, size, 0.5 - half, 0 }, { 1, size, half - 0.5, 0 },
	}
	for _, e in ipairs(edges) do
		local t = frame:CreateTexture(nil, "BORDER")
		t:SetSize(e[1], e[2])
		t:SetPoint("CENTER", e[3], e[4])
		Paint(t, edge)
		Edge(t, e[2] == 1)
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
	local bg = Fill(button, fill)
	Border(button, edge or C.btnEdge)
	button:HookScript("OnEnter", function() Paint(bg, hover) end)
	button:HookScript("OnLeave", function() Paint(bg, fill) end)
	local fs = button.GetFontString and button:GetFontString() or button.Text
	if fs then
		Ink(fs, C.gold)
		fs.OFKeep = true
	end
	return bg
end

-- A flat button from the shared look, its text kept as is in Light colours
local function FlatButton(parent, text, width, height)
	local button = T.FlatButton(parent, text, width, height)
	Paint(button.bg, C.red)
	PaintParts(button, nil, C.btnEdge)
	local fs = button:GetFontString()
	if fs then
		Ink(fs, C.gold)
		fs.OFKeep = true
	end
	return button
end

-- The header strip from the shared look, its text kept as is in Light colours
local function HeaderStrip(header, text)
	T.HeaderStrip(header, text)
	Paint(header.bg, C.header)
	PaintParts(header, nil, C.edge)
	Ink(header.text, C.gold)
	header.text.OFKeep = true
	header.text.OFHeading = true
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
			Tint(t, C.orange)
		end
	end
	local disabled = button:GetDisabledTexture()
	if disabled then Tint(disabled, C.grey) end
end

-- A scroll bar with only a thin gold thumb left showing
local function FlatScrollBar(scrollBar)
	if not scrollBar then return end
	local thumb = scrollBar:GetThumbTexture()
	for _, region in ipairs({ scrollBar:GetRegions() }) do
		if region ~= thumb and region:GetObjectType() == "Texture" then region:SetAlpha(0) end
	end
	if thumb then
		Paint(thumb, C.btnEdge)
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
	Ink(look.Script, color)
	look.Script:Show()
end)

-- Light colours: outfit names (gold, white under the mouse) made dark
hooksecurefunc(Outfitter._ListItem, "SetTextColor", function(self)
	if not self.Look then return end
	DarkText(_G[self:GetName() .. (self.isCategory and "CategoryName" or "OutfitName")])
end)

local function PaintCategory(self)
	local nameField = _G[self:GetName() .. "CategoryName"]
	Ink(nameField, C.orange)
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
		Tint(arrow, C.orange)
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
	_G[name .. "CategoryName"].OFHeading = true
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
	-- inside the window's 1-pixel edge, which the tabs used to cover at both ends
	width = width or ((frame:GetWidth() or 256) - 2) / #labels
	for index, label in ipairs(labels) do
		local tab = CreateFrame("Button", nil, frame)
		tab:SetSize(width, TAB_H)
		tab:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 1 + (index - 1) * width, 0)
		tab.bg = Fill(tab, C.side)
		tab.bar = tab:CreateTexture(nil, "ARTWORK")
		tab.bar:SetPoint("BOTTOMLEFT")
		tab.bar:SetPoint("BOTTOMRIGHT")
		tab.bar:SetHeight(2)
		Paint(tab.bar, C.accent)
		tab.text = Text(tab, label, #labels > 2 and "GameFontNormalSmall" or "GameFontNormal")
		tab.text:SetPoint("LEFT", 3, 0)
		tab.text:SetPoint("RIGHT", -3, 0)
		tab.text:SetJustifyH("CENTER")
		tab.text:SetWordWrap(false)
		tab.text.OFKeep = true
		tab.text.OFHeading = true
		tab:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
			choose(index)
		end)
		tab:SetScript("OnEnter", function(self)
			if not self.on then Paint(self.bg, C.card) end
		end)
		tab:SetScript("OnLeave", function(self)
			if not self.on then Paint(self.bg, C.side) end
		end)
		tabs[index] = tab
	end
	-- A line under the tabs
	local line = frame:CreateTexture(nil, "BORDER")
	line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -TAB_H)
	line:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -TAB_H)
	line:SetHeight(1)
	Edge(line, true)
	Paint(line, C.line)

	-- A new colour style: the lit tab painted again
	OnRepaint(function()
		for index, tab in ipairs(tabs) do
			if tab.on then tabs.Paint(index) return end
		end
	end)
	function tabs.Paint(current)
		for index, tab in ipairs(tabs) do
			tab.on = index == current
			Paint(tab.bg, tab.on and C.tabOn or C.side)
			tab.bar:SetShown(tab.on)
			local color = tab.on and C.gold or C.muted
			Ink(tab.text, color)
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
	Border(check, C.btnEdge)
	local track = check:CreateTexture(nil, "BACKGROUND", nil, -8)
	track:SetAllPoints()
	local knob = check:CreateTexture(nil, "ARTWORK")
	knob:SetSize(12, 12)
	local function PaintSwitch()
		local on = check:GetChecked()
		Paint(track, on and C.onTrack or C.offTrack)
		Paint(knob, on and C.gold or C.grey)
		knob:ClearAllPoints()
		knob:SetPoint("LEFT", check, "LEFT", on and 16 or 2, 0)
	end
	hooksecurefunc(check, "SetChecked", PaintSwitch)
	check:HookScript("OnClick", PaintSwitch)
	PaintSwitch()

	local label = _G[check:GetName() .. "Text"] or check.Text
	if label then
		label:ClearAllPoints()
		label:SetPoint("LEFT", check, "RIGHT", 8, 0)
		label:SetFontObject(GameFontHighlightSmall)
		Ink(label, C.title)
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
	local switch = SwitchWidget(parent)
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
		local color = on and C.hover or C.title
		Ink(label, color)
	end
end

-- A field that opens a list to pick from: the look's own list, which scrolls
-- (mouse wheel or the thin bar) when there are more than LIST_ROWS choices, and
-- stays on the screen. choices() returns { key, label } pairs.
local LIST_ROW, LIST_ROWS = 18, 10
local function MenuField(parent, width, choices, get, set)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(width, 20)
	Fill(b, C.field)
	Border(b, C.fieldEdge)
	local text = Text(b, "", "GameFontHighlightSmall", C.title)
	text:SetPoint("LEFT", 6, 0)
	text:SetPoint("RIGHT", -18, 0)
	text:SetWordWrap(false)
	MenuArrow(b, 6)
	b.text = text
	function b.Refresh()
		local current = get()
		for _, choice in ipairs(choices()) do
			if choice[1] == current then text:SetText(choice[2]) return end
		end
		text:SetText(choices()[1] and choices()[1][2] or "")
	end

	local list
	local function Close()
		if list then list:Hide() end
	end
	b.Close = Close
	local function Build()
		list = CreateFrame("Frame", nil, b)
		list:SetFrameStrata("DIALOG")
		list:SetClampedToScreen(true)
		list:EnableMouse(true)
		Fill(list, C.menu)
		Border(list, C.btnEdge)
		local scroll = T.ScrollArea(list, LIST_ROWS * LIST_ROW)
		scroll:ClearAllPoints()
		scroll:SetPoint("TOPLEFT", 3, -3)
		scroll:SetPoint("BOTTOMRIGHT", -12, 3)
		scroll.bar:ClearAllPoints()
		scroll.bar:SetPoint("TOPRIGHT", -3, -3)
		scroll.bar:SetPoint("BOTTOMRIGHT", -3, 3)
		PaintParts(scroll.bar, C.offTrack)
		Paint(scroll.bar:GetThumbTexture(), C.btnEdge)
		list.scroll, list.rows = scroll, {}
		b.list = list
	end
	local function Row(index)
		local row = list.rows[index]
		if row then return row end
		row = CreateFrame("Button", nil, list.scroll.child)
		row:SetHeight(LIST_ROW)
		row:SetPoint("TOPLEFT", 0, -(index - 1) * LIST_ROW)
		row:SetPoint("RIGHT", list.scroll.child, "RIGHT")
		local hover = row:CreateTexture(nil, "HIGHLIGHT")
		hover:SetAllPoints()
		Paint(hover, C.redHi, 0.35)
		row.text = Text(row, "", "GameFontHighlightSmall", C.title)
		row.text:SetPoint("LEFT", 6, 0)
		row.text:SetPoint("RIGHT", -4, 0)
		row.text:SetWordWrap(false)
		row:SetScript("OnClick", function(self)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			set(self.key)
			b.Refresh()
			Close()
		end)
		list.rows[index] = row
		return row
	end
	b:SetScript("OnClick", function()
		if list and list:IsShown() then Close() return end
		if not list then Build() end
		local items, current = choices(), get()
		for index, choice in ipairs(items) do
			local row = Row(index)
			row.key = choice[1]
			row.text:SetText(choice[2])
			Ink(row.text, choice[1] == current and C.gold or C.title)
			row:Show()
		end
		for index = #items + 1, #list.rows do list.rows[index]:Hide() end
		local shown = math.min(#items, LIST_ROWS)
		list:SetSize(width, shown * LIST_ROW + 6)
		list:ClearAllPoints()
		list:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -2)
		list.scroll.child:SetWidth(width - 18)
		list.scroll:SetContent(width - 18, #items * LIST_ROW)
		SizeTextIn(list)
		list:Show()
		FitEdges()
	end)
	b:HookScript("OnHide", Close)
	return b
end

-- A row of choices, one lit: the two pages, the color styles
local function Choices(parent, keys, labels, get, set)
	local row = {}
	for index, key in ipairs(keys) do
		local b = CreateFrame("Button", nil, parent)
		b.bg = Fill(b, C.field)
		b.edges = Border(b, C.line)
		b.text = Text(b, labels[index], "GameFontHighlightSmall")
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
			Paint(b.bg, on and C.tabOn or C.field)
			for _, edge in ipairs(b.edges) do Paint(edge, on and C.btnEdge or C.line) end
			local color = on and C.gold or (C.darkText and C.title or C.muted)
			Ink(b.text, color)
		end
	end
	return row
end

-- Lays the option rows out in each card: a hidden row takes no room and a
-- two-line label makes its row taller. Clicks reach as far as the label's
-- text. Since 1.8.0 the cards are pages (Automation, Tooltips, Quick access),
-- one showing at a time under the page buttons, as on the Display tab.
local function LayoutOptions(look)
	local y = look.CardsTop
	local bottom = y
	local lineH = LINE_H * TextScale()
	for index, card in ipairs(look.Cards) do
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
		local shown = index == (look.OptionsPage or 1)
		card:SetShown(shown)
		if shown then bottom = y + rowY - 2 - 4 end
	end
	-- Bigger text can need more room than the window has: on the Options tab
	-- the window grows to fit (and goes back to its size on the other tabs)
	if OutfitterOptionsFrame:IsShown() and look.BaseHeight then
		OutfitterFrame:SetHeight(math.max(look.BaseHeight, -bottom))
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
			{ "OpenWithCharacter" },
			{ "RightClick" } } },
	}
	-- The page buttons, then the cards under them
	local top = -(24 + TAB_H + 6)
	look.CardsTop = top - 26
	local width = (panel:GetWidth() or 256) - 16
	look.Cards = {}
	for index, info in ipairs(cards) do
		local card = Card(panel, info[1], 8, 0, width, ROW_H)
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
				switch.label = Text(switch, Outfitter.cLookOutfitScripts, "GameFontHighlightSmall", C.title)
				switch.label:SetPoint("LEFT", switch, "RIGHT", 8, 0)
				switch.label:SetJustifyH("LEFT")
				look.OptionsScripts = switch
				row = { widget = switch, label = switch.label }
			elseif checkName == "OpenWithCharacter" then
				-- Outfitter opens whenever you open the character window (it can't
				-- open that window itself, see Outfitter:CharacterWindowShown)
				local switch = SwitchWidget(card)
				switch:SetFrameLevel(card:GetFrameLevel() + 2)
				switch:SetScript("OnClick", function(self)
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
					Outfitter.Settings.Options.OpenWithCharacter = not self:IsOn() or nil
					self:SetOn(Outfitter.Settings.Options.OpenWithCharacter)
				end)
				T.Tooltip(switch, Outfitter.cLookOpenWithCharacter, Outfitter.cLookOpenWithCharacterDescription)
				switch.label = Text(switch, Outfitter.cLookOpenWithCharacter, "GameFontHighlightSmall", C.title)
				switch.label:SetPoint("LEFT", switch, "RIGHT", 8, 0)
				switch.label:SetJustifyH("LEFT")
				look.OpenWithCharacter = switch
				row = { widget = switch, label = switch.label }
			elseif checkName == "RightClick" then
				-- What right-click on the minimap button or broker does
				-- (Outfitter:RightClickAction): a label over a menu field
				local box = CreateFrame("Frame", nil, card)
				box:SetFrameLevel(card:GetFrameLevel() + 2)
				local label = Text(box, Outfitter.cLookRightClick, "GameFontHighlightSmall", C.title)
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

	-- One page at a time: Automation, Tooltips, Quick access
	look.OptionsPage = 1
	local pages = Choices(panel, { 1, 2, 3 }, { Outfitter.cLookAutomation, Outfitter.cLookTooltips, Outfitter.cLookQuickAccess },
		function() return look.OptionsPage end,
		function(index)
			look.OptionsPage = index
			LayoutOptions(look)
		end)
	local third = (width - 8) / 3
	for index, b in ipairs(pages) do
		b:SetSize(third, 20)
		b:SetPoint("TOPLEFT", panel, "TOPLEFT", 8 + (index - 1) * (third + 4), top)
	end
	pages.Paint()
	look.OptionsSwitch = pages

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
		if button then Flatten(button, C.red, C.redHi) end
	end
end

---------------------------------------------------------------------------
-- The Display tab: window size, text size and colours
---------------------------------------------------------------------------

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
	FitEdges()
end

-- After a font change: again a moment later, when the game has loaded the
-- font (text given a font that's still loading stays blank: a player saw the
-- font field empty while the list, drawn later, showed the font)
local function ApplyDisplaySoon(look)
	ApplyDisplay(look)
	for _, delay in ipairs({ 0.3, 1.5 }) do
		Outfitter.SchedulerLib:ScheduleTask(delay, function() ApplyDisplay(look) end)
	end
end

-- The colours, straight away: the style and your own colours into C, then
-- everything painted again. Light's dark text is put on, or taken off, and the
-- outfit list redrawn (its rows paint themselves).
local function ApplyTheme(look)
	ApplyColors()
	if not C.darkText then UndarkText() end
	Repaint()
	if C.darkText then
		DarkTextIn(OutfitterFrame)
		for _, dialog in ipairs({ Outfitter.NameOutfitDialog, OutfitterEditScriptDialog, OutfitterChooseIconDialog,
			Outfitter.OutfitBar and Outfitter.OutfitBar.SettingsDialog }) do
			if dialog and dialog.Look then DarkTextIn(dialog) end
		end
	end
	if Outfitter.Settings then Outfitter:Update(true) end
end


-- A small button that puts one setting back to its default
local RESET_ICON = "Interface\\Buttons\\UI-RefreshButton"
local function ResetButton(parent, onClick)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(16, 16)
	Fill(b, C.red)
	Border(b, C.btnEdge)
	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT", 2, -2)
	icon:SetPoint("BOTTOMRIGHT", -2, 2)
	icon:SetTexture(RESET_ICON)
	b:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		onClick()
	end)
	T.Tooltip(b, Outfitter.cLookResetOne, Outfitter.cLookResetOneDescription)
	return b
end

-- A number you can slide or type. The slider moves in whole steps; the box
-- takes any number in range (two decimals, like 90.55) when you press Enter.
-- apply() runs when the slider is let go, Enter is pressed or it's reset.
local function SizeControl(parent, y, width, label, description, min, max, get, save, apply)
	local title = Text(parent, label, "GameFontHighlightSmall", C.title)
	title:SetPoint("TOPLEFT", 12, y)
	local box = EditBox(parent, 56)
	box:SetHeight(18)
	box:SetPoint("TOPRIGHT", parent, "TOPLEFT", 12 + width - 20, y + 3)
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
	Paint(track, C.offTrack)
	local thumb = slider:CreateTexture(nil, "OVERLAY")
	thumb:SetSize(8, 14)
	Paint(thumb, C.gold)
	slider:SetThumbTexture(thumb)
	local fill = slider:CreateTexture(nil, "ARTWORK")
	fill:SetHeight(4)
	fill:SetPoint("LEFT", track, "LEFT")
	fill:SetPoint("RIGHT", thumb, "CENTER")
	Paint(fill, C.fill)
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
	control.Reset = ResetButton(parent, function()
		save(100)
		control.Refresh()
		apply()
	end)
	control.Reset:SetPoint("LEFT", box, "RIGHT", 4, 0)
	T.Tooltip(slider, label, description)
	T.Tooltip(box, label, description .. "\n" .. Outfitter.cLookTypeSize)
	return control
end

-- The Display tab is taller than the window: it grows to this while it shows
local DISPLAY_HEIGHT = 366

local function StyleDisplay(look)
	local frame = OutfitterFrame
	local panel = CreateFrame("Frame", nil, frame)
	panel:SetAllPoints()
	panel:Hide()
	look.Display = panel
	look.DisplayHeight = DISPLAY_HEIGHT
	local width = (frame:GetWidth() or 256) - 16
	local inner = width - 24
	local top = -(24 + TAB_H + 6)

	-- Three pages: Size, Fonts, Colors
	local pages = { CreateFrame("Frame", nil, panel), CreateFrame("Frame", nil, panel), CreateFrame("Frame", nil, panel) }
	for _, page in ipairs(pages) do page:SetAllPoints() end
	look.DisplayPage = look.DisplayPage or 1
	local switch = Choices(panel, { 1, 2, 3 }, { Outfitter.cLookPageSize, Outfitter.cLookPageFonts, Outfitter.cLookPageColors },
		function() return look.DisplayPage end,
		function(index)
			look.DisplayPage = index
			for i, page in ipairs(pages) do page:SetShown(i == index) end
		end)
	local third = (width - 8) / 3
	for index, b in ipairs(switch) do
		b:SetSize(third, 20)
		b:SetPoint("TOPLEFT", panel, "TOPLEFT", 8 + (index - 1) * (third + 4), top)
	end
	look.DisplaySwitch, look.DisplayPages = switch, pages
	top = top - 26

	-- Page 1: the window's size (with its dialogs and menus) and the text's
	local size = Card(pages[1], Outfitter.cLookSize, 8, top, width, 106)
	look.WindowSize = SizeControl(size, -26, inner, Outfitter.cLookWindowSize, Outfitter.cLookWindowSizeDescription,
		SCALE_MIN, SCALE_MAX,
		function() return tonumber(DisplaySettings().Scale) or 100 end,
		function(value) DisplaySettings().Scale = value ~= 100 and value or nil end,
		function() ApplyDisplay(look) end)
	look.TextSize = SizeControl(size, -66, inner, Outfitter.cLookTextSize, Outfitter.cLookTextSizeDescription,
		TEXT_MIN, TEXT_MAX, TextPercent,
		function(value) DisplaySettings().TextSize = value ~= 100 and value or nil end,
		function() ApplyDisplay(look) end)

	-- Page 2: fonts. Each row: a label over a field, and its reset button.
	local fonts = Card(pages[2], Outfitter.cLookPageFonts, 8, top, width, 26 + 3 * 40 + 26)
	local fieldW = inner - 20
	local fontRows = {}
	local function FontRow(index, label, description, choices, key)
		local y = -26 - (index - 1) * 40
		local title = Text(fonts, label, "GameFontHighlightSmall", C.title)
		title:SetPoint("TOPLEFT", 12, y)
		local field = MenuField(fonts, fieldW, choices,
			function() return DisplaySettings()[key] or false end,
			function(value)
				DisplaySettings()[key] = value or nil
				ApplyDisplaySoon(look)
			end)
		field:SetPoint("TOPLEFT", fonts, "TOPLEFT", 12, y - 14)
		T.Tooltip(field, label, description)
		field.Reset = ResetButton(fonts, function()
			DisplaySettings()[key] = nil
			field.Refresh()
			ApplyDisplaySoon(look)
		end)
		field.Reset:SetPoint("LEFT", field, "RIGHT", 4, 0)
		fontRows[#fontRows + 1] = field
		return field
	end
	local function FontChoiceList()
		local list = { { false, Outfitter.cLookFontDefault } }
		for _, choice in ipairs(FontChoices()) do list[#list + 1] = { choice[2], choice[1] } end
		return list
	end
	look.Font = FontRow(1, Outfitter.cLookFont, Outfitter.cLookFontDescription, FontChoiceList, "Font")
	look.HeadingFont = FontRow(2, Outfitter.cLookHeadingFont, Outfitter.cLookHeadingFontDescription, FontChoiceList, "HeadingFont")
	look.Outline = FontRow(3, Outfitter.cLookOutline, Outfitter.cLookOutlineDescription, function()
		return { { false, Outfitter.cLookOutlineNone }, { "OUTLINE", Outfitter.cLookOutlineThin },
			{ "THICKOUTLINE", Outfitter.cLookOutlineThick }, { "MONOCHROME", Outfitter.cLookOutlineMono },
			{ "OUTLINE,MONOCHROME", Outfitter.cLookOutlineMonoOutline } }
	end, "Outline")
	-- The shadow: a switch
	local shadow = SwitchWidget(fonts)
	shadow:SetPoint("TOPLEFT", fonts, "TOPLEFT", 12, -26 - 3 * 40)
	shadow:SetFrameLevel(fonts:GetFrameLevel() + 2)
	shadow.label = Text(shadow, Outfitter.cLookShadow, "GameFontHighlightSmall", C.title)
	shadow.label:SetPoint("LEFT", shadow, "RIGHT", 8, 0)
	shadow:SetHitRectInsets(0, -(8 + math.ceil(shadow.label:GetStringWidth() or 0)), -4, -4)
	shadow:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		DisplaySettings().Shadow = not self:IsOn() or nil
		self:SetOn(DisplaySettings().Shadow)
		ApplyDisplay(look)
	end)
	T.Tooltip(shadow, Outfitter.cLookShadow, Outfitter.cLookShadowDescription)
	look.Shadow = shadow

	-- Page 3: the color styles, and your own colors on top; both show at once
	local colors = Card(pages[3], Outfitter.cLookColors, 8, top, width, 88)
	local names = { Outfitter.cLookColorDefault, Outfitter.cLookColorContrast, Outfitter.cLookColorBlue, Outfitter.cLookColorLight }
	local swatches
	local function PaintColors()
		local chosen = DisplaySettings().Colors or "default"
		for _, b in ipairs(swatches) do
			for _, edge in ipairs(b.edges) do
				Paint(edge, b.key == chosen and C.gold or C.line)
			end
		end
	end
	swatches = Choices(colors, COLOR_KEYS, names,
		function() return DisplaySettings().Colors or "default" end,
		function(key)
			DisplaySettings().Colors = key ~= "default" and key or nil
			ApplyTheme(look)
		end)
	-- Two by two, wide enough for the names
	local swatchW = (inner - 4) / 2
	for index, b in ipairs(swatches) do
		b:SetSize(swatchW, 24)
		b:SetPoint("TOPLEFT", colors, "TOPLEFT", 12 + ((index - 1) % 2) * (swatchW + 4), -26 - math.floor((index - 1) / 2) * 28)
		-- Each style's button shows that style, whatever colors are in use
		local sample = SWATCHES[b.key]
		painted[b.bg] = nil
		b.bg:SetColorTexture(sample[1], sample[2], sample[3], 1)
		local dark = b.key == "light"
		b.text:SetTextColor(dark and 0.1 or 1, dark and 0.08 or 1, dark and 0.06 or 1)
		T.Tooltip(b, names[index], Outfitter.cLookColorsDescription)
	end
	-- The style buttons show their own colors, not Choices' lit/unlit ones
	function swatches.Paint() PaintColors() end
	look.Swatches = swatches

	-- Your own colors: a swatch (click for the game's color wheel, right-click
	-- for the style's color again), a hex code (Enter to use it), a reset button
	local own = Card(pages[3], Outfitter.cLookOwnColors, 8, top - 88 - 4, width, 26 + #CUSTOM_KEYS * 18 + 4)
	local ownNames = {
		background = Outfitter.cLookColorBackground, panels = Outfitter.cLookColorPanels, header = Outfitter.cLookColorHeader,
		text = Outfitter.cLookColorText, headings = Outfitter.cLookColorHeadings, buttons = Outfitter.cLookColorButtons,
		highlight = Outfitter.cLookColorHighlight,
	}
	-- What each one shows: the colour in use for it
	local shows = { background = C.win, panels = C.card, header = C.header, text = C.title, headings = C.orange,
		buttons = C.red, highlight = C.gold }
	local rows = {}
	local function Custom()
		local settings = DisplaySettings()
		settings.Custom = settings.Custom or {}
		return settings.Custom
	end
	local function SetCustom(slot, hex)
		Custom()[slot] = hex
		if next(Custom()) == nil then DisplaySettings().Custom = nil end
		ApplyTheme(look)
	end
	for index, slot in ipairs(CUSTOM_KEYS) do
		local y = -26 - (index - 1) * 18
		local chip = CreateFrame("Button", nil, own)
		chip:SetSize(22, 14)
		chip:SetPoint("TOPLEFT", own, "TOPLEFT", 12, y)
		chip:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		chip.color = Fill(chip, shows[slot])
		Border(chip, C.btnEdge)
		local label = Text(own, ownNames[slot], "GameFontHighlightSmall", C.title)
		label:SetPoint("LEFT", chip, "RIGHT", 8, 0)
		local hex = EditBox(own, 66)
		hex:SetHeight(16)
		hex:SetPoint("TOPRIGHT", own, "TOPLEFT", 12 + inner - 20, y + 1)
		hex:SetMaxLetters(7)
		local row = { Chip = chip, Hex = hex, Label = label }
		function row.Refresh() hex:SetText(ToHex(shows[slot])) end
		hex:SetScript("OnEnterPressed", function(self)
			if FromHex(self:GetText()) then
				SetCustom(slot, ToHex(FromHex(self:GetText())))
			end
			row.Refresh()
			self:ClearFocus()
		end)
		hex:SetScript("OnEscapePressed", function(self)
			row.Refresh()
			self:ClearFocus()
		end)
		chip:SetScript("OnClick", function(_, button)
			if button == "RightButton" then
				SetCustom(slot, nil)
				return
			end
			local picker = ColorPickerFrame
			if picker and picker.SetupColorPickerAndShow then
				local before = Custom()[slot]
				local start = shows[slot]
				picker:SetupColorPickerAndShow({
					r = start[1], g = start[2], b = start[3], hasOpacity = false,
					swatchFunc = function()
						local r, g, b = picker:GetColorRGB()
						SetCustom(slot, ToHex({ r, g, b }))
					end,
					cancelFunc = function() SetCustom(slot, before) end,
				})
			else
				-- No color wheel on this client: type the code instead
				hex:SetFocus()
				hex:HighlightText()
			end
		end)
		row.Reset = ResetButton(own, function() SetCustom(slot, nil) end)
		row.Reset:SetPoint("LEFT", hex, "RIGHT", 4, 0)
		T.Tooltip(chip, ownNames[slot], Outfitter.cLookOwnColorDescription)
		T.Tooltip(hex, ownNames[slot], Outfitter.cLookHexDescription)
		rows[slot] = row
	end
	look.OwnColors = rows
	OnRepaint(function() for _, row in pairs(rows) do row.Refresh() end end)

	-- Everything back to how it was (every page)
	local reset = FlatButton(panel, Outfitter.cLookReset, 78, 22)
	reset:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 8)
	reset:SetScript("OnClick", function()
		local settings = DisplaySettings()
		for _, key in ipairs({ "Scale", "TextSize", "Font", "HeadingFont", "Outline", "Shadow", "Colors", "Custom" }) do
			settings[key] = nil
		end
		look.WindowSize.Refresh()
		look.TextSize.Refresh()
		for _, field in ipairs(fontRows) do field.Refresh() end
		shadow:SetOn(false)
		ApplyDisplay(look)
		ApplyTheme(look)
	end)
	T.Tooltip(reset, Outfitter.cLookReset, Outfitter.cLookResetDescription)
	look.DisplayReset = reset

	panel:SetScript("OnShow", function()
		look.WindowSize.Refresh()
		look.TextSize.Refresh()
		for _, field in ipairs(fontRows) do field.Refresh() end
		shadow:SetOn(DisplaySettings().Shadow)
		PaintColors()
		for _, row in pairs(rows) do row.Refresh() end
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
	look.Fill = Fill(frame, C.win)
	look.Edges = Border(frame, C.edge)

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
		frame:SetHeight(math.max(look.BaseHeight, look.DisplayHeight or 0))
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
	Paint(highlight, C.select)
	highlight:SetBlendMode("BLEND")
	local bar = OutfitterMainFrame:CreateTexture(nil, "OVERLAY")
	bar:SetPoint("TOPLEFT", highlight, "TOPLEFT")
	bar:SetPoint("BOTTOMLEFT", highlight, "BOTTOMLEFT")
	bar:SetWidth(2)
	Paint(bar, C.accent)
	look.SelectedBar = bar

	-- The outfit list's scroll track: flat and dark like the panel, a thin gold thumb
	local track = OutfitterMainFrameScrollbarTrench
	for _, part in ipairs({ "Top", "Middle", "Bottom" }) do
		_G[track:GetName() .. part]:Hide()
	end
	look.Track = Fill(track, C.side)
	Border(track, C.line)
	local rail = track:CreateTexture(nil, "BORDER")
	rail:SetPoint("TOP", 0, -6)
	rail:SetPoint("BOTTOM", 0, 6)
	rail:SetWidth(6)
	Paint(rail, C.offTrack)
	FlatScrollBar(OutfitterMainFrameScrollFrameScrollBar)

	-- Footer: the outfit scripts switch, and New Outfit as a flat red button
	OutfitterMainFrameButtonBarBackground:Hide()
	local footer = OutfitterMainFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
	footer:SetPoint("BOTTOMLEFT", 1, 1)
	footer:SetPoint("BOTTOMRIGHT", -1, 1)
	footer:SetHeight(32)
	Paint(footer, C.side)
	local footerLine = OutfitterMainFrame:CreateTexture(nil, "BORDER")
	footerLine:SetPoint("BOTTOMLEFT", footer, "TOPLEFT")
	footerLine:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT")
	footerLine:SetHeight(1)
	Edge(footerLine, true)
	Paint(footerLine, C.line)
	Flatten(OutfitterNewButton, C.red, C.redHi)

	local scripts = ScriptsSwitch(OutfitterMainFrame)
	scripts:SetPoint("BOTTOMLEFT", 8, 10)
	scripts.label = Text(scripts, self.cLookOutfitScripts, "GameFontHighlightSmall", C.muted)
	scripts.label:SetPoint("LEFT", scripts, "RIGHT", 6, 0)
	scripts:SetHitRectInsets(0, -80, -4, -4)
	look.Scripts = scripts

	-- Options panel
	StyleOptions(look)

	-- Slot checkboxes on the character
	StyleSlotEnables()

	-- Display tab, and the window in the chosen sizes (and, for Light, dark text)
	StyleDisplay(look)
	ApplyDisplaySoon(look)
	DarkTextIn(frame)

	-- Keep the switches and the selected row's bar in step with Outfitter's own updates
	local function Refresh()
		if not self.Settings then return end
		scripts:SetOn(not self.Settings.Options.DisableAutoSwitch)
		if look.OptionsScripts then look.OptionsScripts:SetOn(scripts:IsOn()) end
		if look.RightClick then look.RightClick.Refresh() end
		if look.OpenWithCharacter then look.OpenWithCharacter:SetOn(self.Settings.Options.OpenWithCharacter) end
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
	Fill(section, C.card)
	Border(section, C.line)
	if section.Title then
		section.Title:SetFontObject(GameFontNormalSmall)
		Ink(section.Title, C.orange)
		section.Title.OFHeading = true
		section.Title:SetText((section.Title:GetText() or ""):upper())
	end
end

local function StyleField(field)
	if not field then return end
	Fade(field.LeftTexture)
	Fade(field.MiddleTexture)
	Fade(field.RightTexture)
	Fill(field, C.field)
	Border(field, C.fieldEdge)
	if field.Title then Ink(field.Title, C.muted) end
end

function Outfitter:StyleDialog(dialog)
	if not dialog or dialog.Look then return end
	dialog.Look = {}
	if dialog.SetBackdrop then dialog:SetBackdrop(nil) end
	Fill(dialog, C.win)
	Border(dialog, C.edge)

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
	if dialog.CancelButton then Flatten(dialog.CancelButton, C.red, C.redHi) end
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
	Fill(frame, C.field)
	Border(frame, C.fieldEdge)
	local label = _G[name .. "Label"]
	if label then Ink(label, C.muted) end
	FlatScrollBar(_G[name .. "ScrollBar"] or frame.ScrollBar)
	local zoneButton = _G[name .. "ZoneButton"]
	if zoneButton then Flatten(zoneButton, C.red, C.redHi) end
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
	Fill(dialog, C.win)
	Border(dialog, C.edge)

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
	if statusLabel then Ink(statusLabel, C.muted) end
	local description = dialog.Widgets.SettingsDescription
	if description then Ink(description, C.title) end

	-- Footer: a flat strip with Done (red) and Cancel
	local footer = dialog:CreateTexture(nil, "BACKGROUND", nil, -7)
	footer:SetPoint("BOTTOMLEFT", 1, 1)
	footer:SetPoint("BOTTOMRIGHT", -1, 1)
	footer:SetHeight(34)
	Paint(footer, C.side)
	local footerLine = dialog:CreateTexture(nil, "BORDER")
	footerLine:SetPoint("BOTTOMLEFT", footer, "TOPLEFT")
	footerLine:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT")
	footerLine:SetHeight(1)
	Edge(footerLine, true)
	Paint(footerLine, C.line)
	Flatten(_G[name .. "DoneButton"], C.red, C.redHi)
	Flatten(_G[name .. "CancelButton"], C.red, C.redHi)

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
	Fill(button, C.field)
	Border(button, C.btnEdge)
	-- Worn (checked): a bright gold edge, 2 wide, in place of the template's check art,
	Fade(button:GetCheckedTexture())
	local worn = {}
	for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
		local edge = button:CreateTexture(nil, "OVERLAY", nil, 7)
		Paint(edge, C.gold)
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
	Paint(badge, C.gold)
	local tick = button:CreateTexture(nil, "OVERLAY", nil, 7)
	tick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	tick:SetSize(16, 16)
	tick:SetPoint("CENTER", badge, "CENTER", 1, 0)
	Tint(tick, C.win)
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
		bar.Look = { Fill = Fill(bar, C.win, nil, nil, 0.9), Edges = Border(bar, C.btnEdge) }
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
	Paint(texture, C.btnEdge, 0.9)
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
	Paint(track, C.offTrack)
	local thumb = slider:GetThumbTexture()
	if thumb then
		Paint(thumb, C.gold)
		thumb:SetSize(8, 14)
	end
	for _, key in ipairs({ "Text", "Low", "High" }) do
		local label = slider[key] or _G[slider:GetName() .. key]
		if label then Ink(label, C.muted) end
	end
	if slider.Text then Ink(slider.Text, C.title) end
end

-- The bar's settings (right-click a drag handle): flat panel, switches, flat sliders
local function StyleBarSettings(self)
	if self.Look then return end
	self.Look = true
	self:SetBackdrop(nil)
	Fill(self, C.win)
	Border(self, C.btnEdge)
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
	Fill(dialog, C.win)
	Border(dialog, C.edge)

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
		Fill(filter, C.field)
		Border(filter, C.fieldEdge)
		filter:SetTextInsets(6, 6, 0, 0)
	end
	FlatScrollBar(_G[name .. "ScrollFrameScrollBar"])
	Flatten(_G[name .. "OKButton"], C.red, C.redHi)
	Flatten(_G[name .. "CancelButton"], C.red, C.redHi)
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
	if frame.Look then
		for _, edge in ipairs(frame.Look.Edges) do FitEdge(edge, edgeList[edge]) end
	else
		frame.Look = { Fill = Fill(frame, C.menu), Edges = Border(frame, C.btnEdge) }
	end
end

function Dropdown.StyleButton(button)
	local highlight = button:GetHighlightTexture()
	if highlight then
		Paint(highlight, C.redHi, 0.35)
		highlight:SetBlendMode("BLEND")
	end
	if button.text then SizeText(button.text, TextScale()) end
	if button.check then Tint(button.check, C.gold) end
	if button.expand then Tint(button.expand, C.orange) end
end
