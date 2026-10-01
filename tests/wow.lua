-- A fake WoW: Forever client for running Outfitter Forever outside the game.
--
-- The addon runs in its own global table (W.env). Reading a global goes through
-- the Forever API lists in tests/forever_api.lua (made from the Forever 1.60.1
-- client's API documentation and its Blizzard UI source):
--   * a function the tests fake (below) returns the fake
--   * any other Forever API function returns a stand-in that does nothing
--   * a C_ namespace returns a table that errors on functions Forever lacks
--   * a Blizzard frame from Forever's UI returns a stand-in frame
--   * anything else is nil, as in the game, so calling a removed API
--     (GetSpellInfo, GetTalentInfo, ...) fails here the same way it would there
-- Frame methods are checked against Forever's widget API the same way.

local API = dofile("tests/forever_api.lua")
local XML = dofile("tests/xml.lua")

local W = {
	time = 1000,
	combat = false,
	errors = {},      -- Lua errors the addon raised (through geterrorhandler)
	printed = {},     -- chat output
	unstubbed = {},   -- Forever API functions called that have no fake here
	fakeNotOnForever = {}, -- fakes the addon used that Forever doesn't have
	frames = {},      -- every frame, in creation order
	cvars = { equipmentManager = "1", autoLootDefault = "0", nameplateShowEnemies = "1", autointeract = "0" },
	secretHealthAndMana = true, -- Forever hides your own health and mana from addons
}
_G.W = W

local env = {}
W.env = env
env._G = env

----------------------------------------
-- Secret values
----------------------------------------
local SecretMT = {}
local function Boom() error("attempted to use a secret value", 2) end
SecretMT.__add, SecretMT.__sub, SecretMT.__mul, SecretMT.__div, SecretMT.__mod, SecretMT.__pow = Boom, Boom, Boom, Boom, Boom, Boom
SecretMT.__lt, SecretMT.__le, SecretMT.__concat, SecretMT.__unm, SecretMT.__len = Boom, Boom, Boom, Boom, Boom
SecretMT.__index = function() Boom() end
SecretMT.__tostring = function() return "<secret>" end
function W.Secret(v) return setmetatable({ value = v }, SecretMT) end
function W.IsSecret(v) return type(v) == "table" and getmetatable(v) == SecretMT end

----------------------------------------
-- Errors and output
----------------------------------------
local function ErrorHandler(message)
	table.insert(W.errors, tostring(message) .. "\n" .. debug.traceback("", 2))
end

local function Log(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[#parts + 1] = tostring((select(i, ...)))
	end
	table.insert(W.printed, table.concat(parts, " "))
end

-- Runs addon code the way the client runs a script handler: errors go to the
-- error handler instead of stopping the caller
local function SafeCall(fn, ...)
	local n, args = select("#", ...), { ... }
	return xpcall(function() return fn(unpack(args, 1, n)) end, function(m) ErrorHandler(m) return m end)
end
W.SafeCall = SafeCall

----------------------------------------
-- Frames
----------------------------------------
local Frame = {}        -- methods every fake widget has
local FrameMT = {}

local KnownTemplates = {} -- XML templates the addon defines

local function IsFrameObject(t)
	return type(t) == "table" and rawget(t, "__isframe")
end
W.IsFrameObject = IsFrameObject

FrameMT.__index = function(self, key)
	local method = Frame[key]
	if method then return method end
	local mixed = rawget(self, "__mixin") and self.__mixin[key]
	if mixed ~= nil then return mixed end
	if type(key) == "string" and API.methods[key] then
		-- A real widget method this fake doesn't model: do nothing
		return function() return nil end
	end
	return nil
end

local function NewFrame(objectType, name, parent, template, id)
	local frame = setmetatable({
		__isframe = true,
		__type = objectType,
		__name = name,
		__parent = parent,
		__template = template,
		__shown = true,
		__scripts = {},
		__events = {},
		__points = {},
		__children = {},
		__regions = {},
		__attributes = {},
		__width = 100, __height = 20,
		__level = parent and (parent.__level or 0) + 1 or 1,
		__id = id or 0,
		__enabled = true,
	}, FrameMT)
	if parent and IsFrameObject(parent) then
		table.insert(parent.__children, frame)
	end
	if name then
		rawset(env, name, frame)
	end
	table.insert(W.frames, frame)
	-- Tooltips have numbered text lines the client makes
	if objectType == "GameTooltip" and name then
		for i = 1, 30 do
			for _, side in ipairs({ "Left", "Right" }) do
				local line = setmetatable({ __isframe = true, __type = "FontString", __name = name .. "Text" .. side .. i,
					__parent = frame, __shown = true, __scripts = {}, __events = {}, __points = {}, __children = {},
					__regions = {}, __attributes = {}, __width = 100, __height = 12, __level = 1, __id = 0, __enabled = true }, FrameMT)
				rawset(env, line.__name, line)
			end
		end
	end
	return frame
end
W.NewFrame = NewFrame

local function ResolveName(name, parent)
	if name and name:find("$parent", 1, true) then
		-- $parent is the nearest ancestor that has a name
		while parent and not parent.__name do parent = parent.__parent end
		local parentName = parent and parent.__name or ""
		name = name:gsub("%$parent", parentName)
	end
	return name
end

function Frame:GetName() return self.__name end
function Frame:GetDebugName() return self.__name or "<anon>" end
function Frame:GetParent() return self.__parent end
function Frame:SetParent(parent)
	if self.__parent and self.__parent.__children then
		for i, child in ipairs(self.__parent.__children) do
			if child == self then table.remove(self.__parent.__children, i) break end
		end
	end
	self.__parent = parent
	if parent and parent.__children then table.insert(parent.__children, self) end
end
function Frame:GetObjectType() return self.__type end
function Frame:IsObjectType(t) return self.__type == t or t == "Frame" or t == "Region" or t == "Object" end
function Frame:IsForbidden() return false end
function Frame:IsProtected() return false end

function Frame:Show()
	local wasVisible = self:IsVisible()
	self.__shown = true
	if not wasVisible and self:IsVisible() then
		W.FireShow(self)
	end
end
function Frame:Hide()
	local wasVisible = self:IsVisible()
	self.__shown = false
	if wasVisible then
		W.FireHide(self)
	end
end
function Frame:SetShown(shown) if shown then self:Show() else self:Hide() end end
function Frame:IsShown() return self.__shown end
function Frame:IsVisible()
	local frame = self
	while frame do
		if not frame.__shown then return false end
		frame = frame.__parent
		if frame == env.UIParent then return frame.__shown end
	end
	return true
end

function W.FireShow(frame)
	if frame.__scripts.OnShow then SafeCall(frame.__scripts.OnShow, frame) end
	for _, child in ipairs(frame.__children) do
		if child.__shown and child.__isframe then W.FireShow(child) end
	end
end
function W.FireHide(frame)
	if frame.__scripts.OnHide then SafeCall(frame.__scripts.OnHide, frame) end
	for _, child in ipairs(frame.__children) do
		if child.__shown and child.__isframe then W.FireHide(child) end
	end
end

local ScriptTypes = {
	OnLoad = true, OnShow = true, OnHide = true, OnEvent = true, OnUpdate = true, OnClick = true,
	PreClick = true, PostClick = true, OnEnter = true, OnLeave = true, OnMouseDown = true, OnMouseUp = true,
	OnMouseWheel = true, OnDragStart = true, OnDragStop = true, OnReceiveDrag = true, OnValueChanged = true,
	OnTextChanged = true, OnEnterPressed = true, OnEscapePressed = true, OnTabPressed = true, OnSpacePressed = true,
	OnEditFocusGained = true, OnEditFocusLost = true, OnCursorChanged = true, OnSizeChanged = true,
	OnVerticalScroll = true, OnHorizontalScroll = true, OnScrollRangeChanged = true, OnTooltipSetItem = true,
	OnTooltipCleared = true, OnTooltipSetUnit = true, OnTooltipSetSpell = true, OnAttributeChanged = true,
	OnChar = true, OnKeyDown = true, OnKeyUp = true, OnDoubleClick = true, OnEnable = true, OnDisable = true,
	OnHyperlinkClick = true, OnHyperlinkEnter = true, OnHyperlinkLeave = true, OnArrowPressed = true,
	OnInputLanguageChanged = true, OnMinMaxChanged = true, OnCharComposition = true,
}
local function CheckScriptType(scriptType)
	if not ScriptTypes[scriptType] then
		error("unknown script type " .. tostring(scriptType), 3)
	end
end
function Frame:SetScript(scriptType, fn)
	CheckScriptType(scriptType)
	-- Setting a script on one of Blizzard's frames taints it (HookScript doesn't)
	if self.__blizzard and W.addonLoaded then
		W.replacedBlizzardScripts[tostring(self.__name) .. ":" .. scriptType] = true
	end
	self.__scripts[scriptType] = fn
end
function Frame:GetScript(scriptType) return self.__scripts[scriptType] end
function Frame:HasScript(scriptType) return ScriptTypes[scriptType] == true end
function Frame:HookScript(scriptType, fn)
	CheckScriptType(scriptType)
	local old = self.__scripts[scriptType]
	self.__scripts[scriptType] = function(...)
		if old then old(...) end
		return fn(...)
	end
	return true
end

local function CheckEvent(event)
	if not API.events[event] then
		error("Attempt to register unknown event \"" .. tostring(event) .. "\"", 3)
	end
end
function Frame:RegisterEvent(event) CheckEvent(event) self.__events[event] = true return true end
function Frame:RegisterUnitEvent(event) CheckEvent(event) self.__events[event] = true return true end
function Frame:UnregisterEvent(event) CheckEvent(event) self.__events[event] = nil end
function Frame:UnregisterAllEvents() self.__events = {} end
function Frame:RegisterAllEvents() self.__allEvents = true end
function Frame:IsEventRegistered(event) return self.__events[event] == true end

function Frame:SetPoint(point, relativeTo, relativePoint, x, y)
	if type(relativeTo) == "string" then
		local name = relativeTo
		relativeTo = env[name]
		if relativeTo == nil then
			W.Warn("SetPoint: no frame named " .. name)
		end
	end
	table.insert(self.__points, { point, relativeTo, relativePoint, x, y })
end
function Frame:ClearAllPoints() self.__points = {} end
function Frame:SetAllPoints(relativeTo) self.__points = { { "TOPLEFT", relativeTo }, { "BOTTOMRIGHT", relativeTo } } end
function Frame:GetNumPoints() return #self.__points end
function Frame:GetPoint(index)
	local p = self.__points[index or 1]
	if p then return p[1], p[2], p[3] or p[1], p[4] or 0, p[5] or 0 end
end
function Frame:GetPointByName(point)
	for _, p in ipairs(self.__points) do
		if p[1] == point then return p[1], p[2], p[3] or p[1], p[4] or 0, p[5] or 0 end
	end
end
function Frame:SetSize(w, h) self.__width, self.__height = w, h end
function Frame:SetWidth(w) self.__width = w end
function Frame:SetHeight(h) self.__height = h end
function Frame:GetWidth() return self.__width end
function Frame:GetHeight() return self.__height end
function Frame:GetSize() return self.__width, self.__height end
function Frame:GetRect() return 100, 100, self.__width, self.__height end
function Frame:GetLeft() return 100 end
function Frame:GetRight() return 100 + self.__width end
function Frame:GetTop() return 500 end
function Frame:GetBottom() return 500 - self.__height end
function Frame:GetCenter() return 100 + self.__width / 2, 500 - self.__height / 2 end
function Frame:GetScale() return 1 end
function Frame:GetEffectiveScale() return 1 end
function Frame:GetAlpha() return self.__alpha or 1 end
function Frame:SetAlpha(alpha) self.__alpha = alpha end
function Frame:GetFrameLevel() return self.__level end
function Frame:SetFrameLevel(level) self.__level = level end
function Frame:GetFrameStrata() return self.__strata or "MEDIUM" end
function Frame:SetFrameStrata(strata) self.__strata = strata end
function Frame:GetID() return self.__id end
function Frame:SetID(id) self.__id = id end
function Frame:IsMouseOver() return false end
function Frame:IsMovable() return self.__movable or false end
function Frame:SetMovable(movable) self.__movable = movable end
function Frame:IsMouseEnabled() return self.__mouse or false end
function Frame:EnableMouse(enabled) self.__mouse = enabled end
function Frame:GetChildren() return unpack(self.__children) end
function Frame:GetNumChildren() return #self.__children end
function Frame:GetRegions() return unpack(self.__regions) end
function Frame:GetNumRegions() return #self.__regions end

function Frame:SetAttribute(key, value) self.__attributes[key] = value end
function Frame:GetAttribute(key) return self.__attributes[key] end

function Frame:Enable() self.__enabled = true end
function Frame:Disable() self.__enabled = false end
function Frame:SetEnabled(enabled) self.__enabled = enabled and true or false end
function Frame:IsEnabled() return self.__enabled end

function Frame:SetText(text)
	if text ~= nil and type(text) ~= "string" and type(text) ~= "number" and not W.IsSecret(text) then
		error("SetText: bad argument (" .. type(text) .. ")", 2)
	end
	self.__text = text
	if self.__fontString then self.__fontString.__text = text end
end
function Frame:SetFormattedText(format, ...) self:SetText(string.format(format, ...)) end
function Frame:GetText() return self.__text end
function Frame:GetStringWidth() return #(tostring(self.__text or "")) * 6 end
function Frame:GetUnboundedStringWidth() return self:GetStringWidth() end
function Frame:GetStringHeight() return 12 end
function Frame:GetTextWidth() return self:GetStringWidth() end
function Frame:GetNumLetters() return #(tostring(self.__text or "")) end
function Frame:GetFont() return "Fonts\\FRIZQT__.TTF", 12, "" end
function Frame:GetFontObject() return self.__fontObject end
function Frame:SetFontObject(font) self.__fontObject = font end
function Frame:SetTextColor(r, g, b, a) self.__textColor = { r, g, b, a } end
function Frame:GetTextColor() local c = self.__textColor or { 1, 1, 1, 1 } return c[1], c[2], c[3], c[4] end
function Frame:SetVertexColor(r, g, b, a) self.__vertexColor = { r, g, b, a } end
function Frame:GetVertexColor() local c = self.__vertexColor or { 1, 1, 1, 1 } return c[1], c[2], c[3], c[4] end

function Frame:SetChecked(checked) self.__checked = checked and true or false end
function Frame:GetChecked() return self.__checked or false end
function Frame:Click(button, down)
	if not self.__enabled then return end
	local fn = self.__scripts.PreClick
	if fn then SafeCall(fn, self, button or "LeftButton", down) end
	if self.__type == "CheckButton" then self.__checked = not self.__checked end
	fn = self.__scripts.OnClick
	if fn then SafeCall(fn, self, button or "LeftButton", down) end
	fn = self.__scripts.PostClick
	if fn then SafeCall(fn, self, button or "LeftButton", down) end
end

function Frame:SetMinMaxValues(min, max) self.__min, self.__max = min, max end
function Frame:GetMinMaxValues() return self.__min or 0, self.__max or 1 end
function Frame:SetValue(value)
	self.__value = value
	if self.__scripts.OnValueChanged then SafeCall(self.__scripts.OnValueChanged, self, value, false) end
end
function Frame:GetValue() return self.__value or 0 end
function Frame:SetValueStep(step) self.__step = step end
function Frame:GetValueStep() return self.__step or 1 end

local function NewRegion(parent, objectType, name, layer)
	local region = NewFrame(objectType, ResolveName(name, parent), parent)
	region.__layer = layer
	-- Regions aren't children
	for i, child in ipairs(parent.__children) do
		if child == region then table.remove(parent.__children, i) break end
	end
	table.insert(parent.__regions, region)
	return region
end
function Frame:CreateTexture(name, layer) return NewRegion(self, "Texture", name, layer) end
function Frame:CreateMaskTexture(name, layer) return NewRegion(self, "MaskTexture", name, layer) end
function Frame:CreateLine(name, layer) return NewRegion(self, "Line", name, layer) end
function Frame:CreateFontString(name, layer, template)
	local fs = NewRegion(self, "FontString", name, layer)
	fs.__fontObject = template
	return fs
end
function Frame:CreateAnimationGroup(name)
	local group = NewRegion(self, "AnimationGroup", name)
	group.CreateAnimation = function(g, kind, animName) return NewRegion(g, kind or "Animation", animName) end
	group.Play = function(g) g.__playing = true end
	group.Stop = function(g) g.__playing = false end
	group.IsPlaying = function(g) return g.__playing or false end
	return group
end

function Frame:SetTexture(texture) self.__texture = texture return true end
function Frame:GetTexture() return self.__texture end
function Frame:GetTextureFileID() return type(self.__texture) == "number" and self.__texture or nil end
function Frame:GetTextureFilePath() return self.__texture end
function Frame:SetAtlas(atlas) self.__atlas = atlas return true end
function Frame:GetAtlas() return self.__atlas end
function Frame:SetTexCoord(...) self.__texCoord = { ... } end
function Frame:GetTexCoord() return unpack(self.__texCoord or { 0, 0, 0, 1, 1, 0, 1, 1 }) end
function Frame:SetDesaturated(desaturated) self.__desaturated = desaturated end
function Frame:IsDesaturated() return self.__desaturated or false end

local function ButtonTexture(self, key, texture)
	if texture == nil then
		return self[key]
	end
	if type(texture) == "table" then
		self[key] = texture
	else
		self[key] = self[key] or self:CreateTexture()
		self[key]:SetTexture(texture)
	end
end
function Frame:SetNormalTexture(t) ButtonTexture(self, "__normalTexture", t) end
function Frame:GetNormalTexture() return self.__normalTexture end
function Frame:SetPushedTexture(t) ButtonTexture(self, "__pushedTexture", t) end
function Frame:GetPushedTexture() return self.__pushedTexture end
function Frame:SetHighlightTexture(t) ButtonTexture(self, "__highlightTexture", t) end
function Frame:GetHighlightTexture() return self.__highlightTexture end
function Frame:SetDisabledTexture(t) ButtonTexture(self, "__disabledTexture", t) end
function Frame:GetDisabledTexture() return self.__disabledTexture end
function Frame:SetCheckedTexture(t) ButtonTexture(self, "__checkedTexture", t) end
function Frame:GetCheckedTexture() return self.__checkedTexture end
function Frame:SetDisabledCheckedTexture(t) ButtonTexture(self, "__disabledCheckedTexture", t) end
function Frame:GetDisabledCheckedTexture() return self.__disabledCheckedTexture end
function Frame:GetFontString()
	if not self.__fontString then
		self.__fontString = self:CreateFontString(self.__name and (self.__name .. "Text") or nil)
	end
	return self.__fontString
end
function Frame:SetFontString(fs) self.__fontString = fs end

-- Edit boxes
function Frame:SetFocus() self.__focus = true end
function Frame:ClearFocus() self.__focus = false end
function Frame:HasFocus() return self.__focus or false end
function Frame:GetNumber() return tonumber(self.__text) or 0 end
function Frame:SetNumber(n) self.__text = tostring(n) end
function Frame:GetCursorPosition() return 0 end
function Frame:IsMultiLine() return self.__multiLine or false end
function Frame:SetMultiLine(multi) self.__multiLine = multi end
function Frame:GetMaxLetters() return 255 end
function Frame:IsNumeric() return false end

-- Scroll frames
function Frame:SetScrollChild(child) self.__scrollChild = child end
function Frame:GetScrollChild() return self.__scrollChild end
function Frame:GetVerticalScroll() return self.__vscroll or 0 end
function Frame:SetVerticalScroll(v) self.__vscroll = v end
function Frame:GetVerticalScrollRange() return 0 end
function Frame:GetHorizontalScroll() return 0 end
function Frame:GetHorizontalScrollRange() return 0 end

-- Tooltips
function Frame:SetOwner(owner, anchor) self.__owner = owner self.__lines = {} self.__item = nil end
function Frame:GetOwner() return self.__owner end
function Frame:IsOwned(owner) return self.__owner == owner end
function Frame:ClearLines() self.__lines = {} self.__item = nil end
function Frame:AddLine(text) self.__lines = self.__lines or {} table.insert(self.__lines, text) end
function Frame:AddDoubleLine(left, right) self.__lines = self.__lines or {} table.insert(self.__lines, tostring(left) .. "\t" .. tostring(right)) end
function Frame:NumLines() return #(self.__lines or {}) end
function Frame:SetHyperlink(link) self.__item = link self.__shown = true end
function Frame:SetInventoryItem(unit, slot)
	local id = W.equipped[slot]
	self.__item = id and W.ItemLink(id) or nil
	self.__shown = id ~= nil
	return id ~= nil, false, 0
end
function Frame:SetBagItem(bag, slot)
	local stack = W.bags[bag] and W.bags[bag][slot]
	self.__item = stack and W.ItemLink(stack.id) or nil
	self.__shown = stack ~= nil
	return false, 0
end
function Frame:GetItem()
	if not self.__item then return nil end
	local name = self.__item:match("%[(.-)%]")
	return name, self.__item, W.ItemIDFromLink(self.__item)
end
function Frame:SetUnitBuff() self.__shown = false end
function Frame:SetUnitAura() self.__shown = false end
function Frame:SetBackdrop(backdrop) self.__backdrop = backdrop end
function Frame:GetBackdrop() return self.__backdrop end
function Frame:GetBackdropColor() return 0, 0, 0, 1 end
function Frame:GetBackdropBorderColor() return 1, 1, 1, 1 end
function Frame:SetBackdropColor() end
function Frame:SetBackdropBorderColor() end
function Frame:ApplyBackdrop() end

----------------------------------------
-- Frame names and templates
----------------------------------------
local function KnownTemplate(name)
	return KnownTemplates[name] or API.ui_templates[name] or API.template_parts[name]
end

-- The named pieces Blizzard templates create ($parentText, .Text, ...), from
-- Forever's UI source
local AddTemplateParts
local function AddParts(frame, template)
	local info = API.template_parts[template]
	if not info then return end
	AddTemplateParts(frame, info.inherits)
	if info.hidden then frame.__shown = false end
	for _, part in ipairs(info.parts) do
		local name = part.suffix and frame.__name and (frame.__name .. part.suffix) or nil
		local piece = name and rawget(env, name)
		if not piece then
			if part.type == "Texture" or part.type == "FontString" then
				piece = NewRegion(frame, part.type, name)
			else
				piece = NewFrame(part.type, name, frame)
				AddTemplateParts(piece, part.inherits)
			end
		end
		local hidden = part.hidden
		for inherited in (part.inherits or ""):gmatch("[^,%s]+") do
			local info = API.template_parts[inherited]
			if info and info.hidden then hidden = true end
		end
		if hidden then piece.__shown = false end
		if part.anchor then
			local relativeTo = part.anchor[2] and ResolveName(part.anchor[2], frame) or nil
			table.insert(piece.__points, { part.anchor[1], relativeTo and (rawget(env, relativeTo) or frame) or frame, part.anchor[3] })
		end
		if part.key then rawset(frame, part.key, piece) end
		if part.type == "FontString" and (part.suffix == "Text" or part.key == "Text") then
			frame.__fontString = piece
		end
	end
end
AddTemplateParts = function(frame, templates)
	for template in (templates or ""):gmatch("[^,%s]+") do
		AddParts(frame, template)
	end
end

----------------------------------------
-- XML
----------------------------------------
local ScriptArgs = {
	OnClick = "self, button, down", PreClick = "self, button, down", PostClick = "self, button, down",
	OnEvent = "self, event, ...", OnUpdate = "self, elapsed", OnEnter = "self, motion", OnLeave = "self, motion",
	OnMouseDown = "self, button", OnMouseUp = "self, button, upInside", OnMouseWheel = "self, delta",
	OnValueChanged = "self, value, userInput", OnTextChanged = "self, userInput", OnSizeChanged = "self, width, height",
	OnVerticalScroll = "self, offset", OnHorizontalScroll = "self, offset", OnDragStart = "self, button",
	OnCursorChanged = "self, x, y, w, h", OnKeyDown = "self, key", OnKeyUp = "self, key", OnChar = "self, text",
	OnHyperlinkClick = "self, link, text, button", OnAttributeChanged = "self, name, value",
}

local function CompileScript(code, frameName, scriptType, fileName)
	local args = ScriptArgs[scriptType] or "self, ..."
	local source = "return function(" .. args .. ") " .. code .. "\nend"
	local chunk, message = loadstring(source, fileName .. ":" .. tostring(frameName) .. ":" .. scriptType)
	if not chunk then
		error(message)
	end
	setfenv(chunk, env)
	return chunk()
end

local XmlFrameTypes = {
	Frame = true, Button = true, CheckButton = true, ScrollFrame = true, EditBox = true, Slider = true,
	StatusBar = true, GameTooltip = true, Cooldown = true, Model = true, PlayerModel = true, ItemButton = true,
	MessageFrame = true, ScrollingMessageFrame = true, SimpleHTML = true, ColorSelect = true, DropdownButton = true,
}

local LayoutTags = {
	Size = true, Anchors = true, Anchor = true, Offset = true, AbsDimension = true, TexCoords = true, Color = true,
	TextInsets = true, Shadow = true, Gradient = true, HitRectInsets = true, ResizeBounds = true, AbsInset = true,
	RelDimension = true, FontHeight = true, Inset = true, KeyValues = true, KeyValue = true, Backdrop = true,
	EdgeSize = true, TileSize = true, BackgroundInsets = true, Animations = true, PushedTextOffset = true,
	Attributes = true, Attribute = true, MaxResize = true, MinResize = true,
}

local BuildNode -- forward

local function ApplyFrameNode(frame, node, fileName, onLoads, isTemplate)
	-- Templates first
	for template in (node.attr.inherits or ""):gmatch("[^,%s]+") do
		local own = KnownTemplates[template]
		if own then
			ApplyFrameNode(frame, own, fileName, onLoads, true)
		elseif not KnownTemplate(template) then
			error(string.format("%s: %s inherits unknown template %s", fileName, tostring(frame.__name), template))
		end
	end
	AddTemplateParts(frame, node.attr.inherits)

	local attr = node.attr
	if attr.hidden == "true" then frame.__shown = false elseif attr.hidden == "false" then frame.__shown = true end
	if attr.id then frame.__id = tonumber(attr.id) end
	if attr.text then
		local text = env[attr.text]
		frame.__text = type(text) == "string" and text or attr.text
		frame:GetFontString().__text = frame.__text
	end
	if attr.enableMouse == "true" then frame.__mouse = true end
	if attr.movable == "true" then frame.__movable = true end
	if attr.parentKey and frame.__parent then frame.__parent[attr.parentKey] = frame end

	for _, child in ipairs(node.children) do
		local tag = child.tag
		if tag == "Frames" then
			for _, sub in ipairs(child.children) do
				BuildNode(sub, frame, fileName, onLoads)
			end
		elseif tag == "Layers" then
			for _, layer in ipairs(child.children) do
				for _, region in ipairs(layer.children) do
					BuildNode(region, frame, fileName, onLoads, layer.attr.level)
				end
			end
		elseif tag == "Scripts" then
			for _, script in ipairs(child.children) do
				CheckScriptType(script.tag)
				local fn
				if script.attr["function"] then
					local name = script.attr["function"]
					fn = function(...) return env[name](...) end
				elseif script.attr.method then
					local method = script.attr.method
					fn = function(self, ...) return self[method](self, ...) end
				else
					fn = CompileScript(script.text or "", frame.__name, script.tag, fileName)
				end
				local inherit = script.attr.inherit
				local old = frame.__scripts[script.tag]
				if inherit == "prepend" and old then
					local new = fn
					fn = function(...) new(...) return old(...) end
				elseif inherit == "append" and old then
					local new = fn
					fn = function(...) old(...) return new(...) end
				end
				frame.__scripts[script.tag] = fn
			end
		elseif tag == "Anchors" then
			for _, anchor in ipairs(child.children) do
				local relativeTo = anchor.attr.relativeTo
				if relativeTo and not isTemplate then
					relativeTo = ResolveName(relativeTo, frame.__parent)
					if env[relativeTo] == nil then
						W.Warn(string.format("%s: %s is anchored to %s, which doesn't exist", fileName, tostring(frame.__name), relativeTo))
					end
				end
				table.insert(frame.__points, { anchor.attr.point, relativeTo })
			end
		elseif tag == "NormalTexture" or tag == "PushedTexture" or tag == "HighlightTexture" or tag == "DisabledTexture"
			or tag == "CheckedTexture" or tag == "DisabledCheckedTexture" or tag == "ThumbTexture" then
			local texture = NewRegion(frame, "Texture", child.attr.name)
			texture.__texture = child.attr.file
			frame["__" .. tag:sub(1, 1):lower() .. tag:sub(2)] = texture
		elseif tag == "ButtonText" or tag == "FontString" then
			local fs = NewRegion(frame, "FontString", child.attr.name)
			frame.__fontString = fs
		elseif tag == "ScrollChild" then
			for _, sub in ipairs(child.children) do
				frame.__scrollChild = BuildNode(sub, frame, fileName, onLoads)
			end
		elseif tag == "NormalFont" or tag == "HighlightFont" or tag == "DisabledFont" then
			-- font objects
		elseif not LayoutTags[tag] then
			W.Warn(fileName .. ": unhandled XML element <" .. tag .. "> in " .. tostring(frame.__name))
		end
	end
end

BuildNode = function(node, parent, fileName, onLoads, layer)
	local tag = node.tag
	local attr = node.attr
	if attr.virtual == "true" then
		if attr.name then KnownTemplates[attr.name] = node end
		return
	end
	if tag == "Texture" or tag == "FontString" or tag == "Line" or tag == "MaskTexture" then
		local region = NewRegion(parent, tag, attr.name, layer)
		if attr.file then region.__texture = attr.file end
		if attr.text then
			local text = env[attr.text]
			region.__text = type(text) == "string" and text or attr.text
		end
		if attr.hidden == "true" then region.__shown = false end
		if attr.parentKey then parent[attr.parentKey] = region end
		for template in (attr.inherits or ""):gmatch("[^,%s]+") do
			if not KnownTemplate(template) and not env[template] then
				error(string.format("%s: %s inherits unknown template %s", fileName, tostring(attr.name), template))
			end
		end
		return region
	end
	if tag == "Font" then
		if attr.name then env[attr.name] = NewFrame("Font", attr.name) end
		return
	end
	if not XmlFrameTypes[tag] then
		W.Warn(fileName .. ": unhandled XML element <" .. tag .. ">")
		return
	end
	if attr.parent then
		parent = env[attr.parent]
		if parent == nil then
			error(fileName .. ": parent " .. attr.parent .. " doesn't exist")
		end
	end
	local objectType = tag == "ItemButton" and "Button" or tag
	local frame = NewFrame(objectType, ResolveName(attr.name, parent), parent, attr.inherits)
	local myOnLoads = {}
	ApplyFrameNode(frame, node, fileName, myOnLoads)
	-- Children's OnLoad runs before the parent's
	for _, fn in ipairs(myOnLoads) do table.insert(onLoads, fn) end
	if frame.__scripts.OnLoad then
		table.insert(onLoads, function() SafeCall(frame.__scripts.OnLoad, frame) end)
	end
	return frame
end

-- CreateFrame, with the addon's own XML templates and Forever's Blizzard ones
function W.CreateFrame(objectType, name, parent, templates, id)
	if type(objectType) ~= "string" then error("CreateFrame: bad frame type", 2) end
	for template in (templates or ""):gmatch("[^,%s]+") do
		if not KnownTemplate(template) then
			error("CreateFrame: Couldn't find inherited node \"" .. template .. "\"", 2)
		end
	end
	local frame = NewFrame(objectType, name, parent, templates, id)
	local onLoads = {}
	for template in (templates or ""):gmatch("[^,%s]+") do
		local own = KnownTemplates[template]
		if own then
			ApplyFrameNode(frame, own, "CreateFrame", onLoads, true)
			if frame.__scripts.OnLoad then
				table.insert(onLoads, function() SafeCall(frame.__scripts.OnLoad, frame) end)
			end
		end
	end
	AddTemplateParts(frame, templates)
	for _, fn in ipairs(onLoads) do fn() end
	return frame
end

function W.LoadXML(path)
	local tree = XML.ParseFile(path)
	local ui = tree.children[1]
	local onLoads = {}
	for _, node in ipairs(ui.children) do
		if node.tag == "Script" then
			W.LoadLua(node.attr.file)
		elseif node.tag == "Include" then
			W.LoadXML(node.attr.file)
		else
			BuildNode(node, nil, path, onLoads)
		end
	end
	for _, fn in ipairs(onLoads) do fn() end
end

----------------------------------------
-- Globals
----------------------------------------
W.warnings = {}
function W.Warn(message)
	W.warnings[message] = true
end

local Fakes = {}  -- functions and tables the tests fake
W.Fakes = Fakes

local LuaGlobals = {
	"assert", "error", "ipairs", "next", "pairs", "pcall", "print", "rawequal", "rawget", "rawset", "select",
	"setmetatable", "getmetatable", "tonumber", "tostring", "type", "unpack", "xpcall", "loadstring", "getfenv",
	"setfenv", "string", "table", "math", "coroutine", "collectgarbage", "gcinfo",
}

local WowLuaAliases = {
	strfind = string.find, strlower = string.lower, strupper = string.upper, strsub = string.sub, strlen = string.len,
	strrep = string.rep, strbyte = string.byte, strchar = string.char, strmatch = string.match, gsub = string.gsub,
	gmatch = string.gmatch, format = string.format, strformat = string.format, tinsert = table.insert,
	tremove = table.remove, sort = table.sort, tconcat = table.concat, floor = math.floor, ceil = math.ceil,
	abs = math.abs, max = math.max, min = math.min, mod = math.fmod, sqrt = math.sqrt, random = math.random,
	date = os.date, time = os.time,
}

local function MakeNamespace(name)
	local fns = API.namespaces[name]
	local fakes = Fakes[name] or {}
	for key in pairs(fakes) do
		if not fns[key] and not (getmetatable(fakes) or {}).__index then
			error("tests fake " .. name .. "." .. key .. ", which Forever doesn't have")
		end
	end
	return setmetatable({}, {
		__index = function(_, key)
			if fakes[key] then return fakes[key] end
			if fns[key] then
				return function(...)
					W.unstubbed[name .. "." .. key] = true
					return nil
				end
			end
			return nil
		end,
		__newindex = function(_, key)
			error("the addon wrote " .. name .. "." .. tostring(key))
		end,
	})
end

local namespaces = {}
setmetatable(env, {
	__index = function(_, name)
		if type(name) == "string" and API.namespaces[name] then
			namespaces[name] = namespaces[name] or MakeNamespace(name)
			return namespaces[name]
		end
		local fake = Fakes[name]
		if fake ~= nil then
			-- A fake function must stand for something Forever really has
			if type(fake) == "function" and type(name) == "string" and not (API.globals[name] or API.ui_funcs[name]) then
				W.fakeNotOnForever[name] = true
			end
			return fake
		end
		if WowLuaAliases[name] then return WowLuaAliases[name] end
		if type(name) ~= "string" then return nil end
		if API.namespaces[name] then
			namespaces[name] = namespaces[name] or MakeNamespace(name)
			return namespaces[name]
		end
		if API.globals[name] or API.ui_funcs[name] then
			return function()
				W.unstubbed[name] = true
				return nil
			end
		end
		if API.ui_frames[name] then
			local frame = NewFrame("Frame", name, env.UIParent)
			frame.__blizzard = true
			return frame
		end
		if API.ui_globals[name] then
			W.Warn("the addon read Blizzard's " .. name .. ", which the tests don't fake")
			return nil
		end
		-- Global strings (HEADSLOT, OKAY, ...) read as their own name
		if name:match("^[A-Z][A-Z0-9_]+$") and W.globalStrings[name] then
			return W.globalStrings[name]
		end
		if name:match("^[A-Z][A-Z0-9_]+$") and not name:match("^LE_") and not name:match("^NUM_")
			and not name:match("^MAX_") and not name:match("^INVSLOT_") and not name:match("^WOW_PROJECT") then
			return name
		end
		return nil
	end,
	-- Replacing one of Blizzard's globals taints Blizzard's code that uses it
	__newindex = function(t, name, value)
		if type(name) == "string" and (Fakes[name] ~= nil or API.globals[name] or API.ui_funcs[name]
			or API.ui_frames[name] or API.ui_globals[name] or API.namespaces[name]) then
			W.replacedBlizzardGlobals[name] = true
		end
		rawset(t, name, value)
	end,
})
W.replacedBlizzardGlobals = {}
W.replacedBlizzardScripts = {}
W.globalStrings = {}
for _, name in ipairs(LuaGlobals) do
	rawset(env, name, _G[name])
end
rawset(env, "print", Log)
-- Code compiled by the addon (Outfitter's outfit scripts) sees the game's globals
rawset(env, "loadstring", function(source, chunkName)
	local chunk, message = loadstring(source, chunkName)
	if chunk then setfenv(chunk, env) end
	return chunk, message
end)
rawset(env, "bit", { band = function(a, b) local r, p = 0, 1 while a > 0 and b > 0 do if a % 2 == 1 and b % 2 == 1 then r = r + p end a, b, p = math.floor(a / 2), math.floor(b / 2), p * 2 end return r end,
	bor = function(a, b) local r, p = 0, 1 while a > 0 or b > 0 do if a % 2 == 1 or b % 2 == 1 then r = r + p end a, b, p = math.floor(a / 2), math.floor(b / 2), p * 2 end return r end,
	lshift = function(a, n) return a * 2 ^ n end, rshift = function(a, n) return math.floor(a / 2 ^ n) end })

----------------------------------------
-- Loading the addon
----------------------------------------
W.addonName = "OutfitterForever"
W.addonTable = {}

function W.LoadLua(path)
	local chunk, message = loadfile(path)
	if not chunk then error(message) end
	setfenv(chunk, env)
	local ok, err = SafeCall(chunk, W.addonName, W.addonTable)
	return ok
end

function W.LoadToc(path)
	-- Frames that exist before the addon loads are Blizzard's
	for _, frame in ipairs(W.frames) do frame.__blizzard = true end
	W.addonLoaded = true
	for line in io.lines(path) do
		line = line:gsub("\r", "")
		if line ~= "" and not line:match("^#") then
			if line:match("%.lua$") then
				W.LoadLua(line)
			elseif line:match("%.xml$") then
				local ok, err = pcall(W.LoadXML, line)
				if not ok then ErrorHandler(err) end
			end
		end
	end
	-- Bindings.xml loads automatically
end

----------------------------------------
-- Events and time
----------------------------------------
function W.Fire(event, ...)
	assert(API.events[event], "test fired unknown event " .. event)
	for _, frame in ipairs(W.frames) do
		if (frame.__events[event] or frame.__allEvents) and frame.__scripts.OnEvent then
			SafeCall(frame.__scripts.OnEvent, frame, event, ...)
		end
	end
end

function W.Tick(seconds, step)
	step = step or 0.1
	local elapsed = 0
	while elapsed < seconds do
		W.time = W.time + step
		elapsed = elapsed + step
		local timers = W.timers
		W.timers = {}
		for _, timer in ipairs(timers) do
			if timer.at <= W.time then
				if not timer.cancelled then SafeCall(timer.fn, timer) end
			else
				table.insert(W.timers, timer)
			end
		end
		for _, frame in ipairs(W.frames) do
			local onUpdate = frame.__scripts.OnUpdate
			if onUpdate and frame:IsVisible() then
				SafeCall(onUpdate, frame, step)
			end
		end
	end
end
W.timers = {}

return W
