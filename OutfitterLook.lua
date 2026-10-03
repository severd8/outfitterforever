-- Outfitter Forever: the shared look (Theme.lua) on Outfitter's window.
-- A restyle only: the dark panel, the red header bar with the logo, and the
-- text. Outfitter's layout, outfit list and controls are the original addon's
-- and are left as they are.

local _, Outfitter = ...
local T = Outfitter.Theme
local C = T.C

-- Chat lines start with the logo and name, as in every addon with this look
Outfitter.ChatPrefix = T.CHAT_PREFIX .. ": "

-- Called once, after the original code has built the window's frame art
function Outfitter:ApplyLook()
	local frame = OutfitterFrame
	if not frame or frame.Look then return end
	frame.Look = {}

	-- The original stone frame art goes; a flat dark panel takes its place.
	-- These are the frame's own textures, so they stay behind everything in it.
	for _, piece in pairs(frame.Background or {}) do piece:Hide() end
	frame.Look.Fill = T.Fill(frame, C.win)
	frame.Look.Edges = T.Border(frame, C.edge)

	-- Header bar: logo, then the name and version
	local header = CreateFrame("Frame", nil, frame)
	header:SetPoint("TOPLEFT")
	header:SetPoint("TOPRIGHT")
	header:SetHeight(24)
	T.HeaderStrip(header, OutfitterFrameTitle:GetText())
	header:FitLogo(24)
	OutfitterFrameTitle:Hide()
	frame.Look.Header = header

	-- A flat X in the header instead of the game's round close button
	local close = T.FlatButton(header, "X", 18, 18)
	close:SetPoint("RIGHT", -3, 0)
	close:SetScript("OnClick", function() frame:Hide() end)
	header.text:SetPoint("RIGHT", close, "LEFT", -4, 0)
	OutfitterCloseButton:Hide()
	frame.Look.Close = close
end
