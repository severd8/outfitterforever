-- Baganator (a bag addon) can give each equipment set its own group in the bag.
-- It reads the game's Equipment Manager sets itself, so outfits stored on the
-- server already get a group. Its hook for Outfitter waits for an addon called
-- "Outfitter", which this one isn't ("OutfitterForever"), so Outfitter Forever
-- tells Baganator about its other outfits through Baganator's public API:
--
--   Baganator.API.RegisterItemSetSource(label, id, getItemSetInfo, getAllSetNames)
--     getItemSetInfo(itemLocation, guid, itemLink) -> { { name = , iconTexture = }, ... } or nil
--     getAllSetNames() -> { name, ... }
--   Baganator.API.RequestItemButtonsRefresh()
--
-- Nothing here runs unless Baganator is installed.

Outfitter.Baganator =
{
	Names = {},     -- names of the outfits Baganator is told about, in list order
	ByCode = {},    -- item ID -> the outfits that have an item with that ID
	Signature = "", -- what was last reported, to tell when it changes
	Registered = false,
}

local function GetAPI()
	local vBaganator = _G["Baganator"]

	if type(vBaganator) ~= "table" or type(vBaganator.API) ~= "table"
	or type(vBaganator.API.RegisterItemSetSource) ~= "function" then
		return nil
	end

	return vBaganator.API
end

-- Rebuilds the lists from the outfits. Outfits stored on the server are left
-- out: they're Equipment Manager sets, which Baganator already groups, and
-- reporting them here too would give two groups with the same name.
function Outfitter.Baganator:Rebuild()
	local vNames = {}
	local vByCode = {}
	local vParts = {}

	if Outfitter.Settings and Outfitter.Settings.Outfits then
		for _, vCategoryID in ipairs(Outfitter.cCategoryOrder) do
			local vOutfits = Outfitter.Settings.Outfits[vCategoryID]

			for _, vOutfit in ipairs(vOutfits or {}) do
				local vName = vOutfit.GetName and vOutfit:GetName()
				local vItems = vOutfit.GetItems and vOutfit:GetItems()

				if not vOutfit.StoredInEM and type(vName) == "string" and vName ~= "" then
					table.insert(vNames, vName)
					table.insert(vParts, vName)

					local vCodes = {}

					for _, vItem in pairs(vItems or {}) do
						local vCode = type(vItem) == "table" and tonumber(vItem.Code)

						if vCode and vCode ~= 0 then
							-- Outfitter treats a few items as the same item under another ID
							local vAlias = Outfitter.cItemAliases and Outfitter.cItemAliases[vCode]

							for _, vID in ipairs({vCode, vAlias}) do
								if not vByCode[vID] then
									vByCode[vID] = {}
								end

								table.insert(vByCode[vID], vOutfit)
							end

							table.insert(vCodes, vCode)
						end
					end

					table.sort(vCodes)
					table.insert(vParts, table.concat(vCodes, ","))
				end
			end
		end
	end

	self.Names = vNames
	self.ByCode = vByCode

	-- Only make Baganator redraw the bags when something it shows has changed
	local vSignature = table.concat(vParts, "|")

	if vSignature ~= self.Signature then
		self.Signature = vSignature

		local vAPI = GetAPI()

		if vAPI and self.Registered and type(vAPI.RequestItemButtonsRefresh) == "function" then
			vAPI.RequestItemButtonsRefresh()
		end
	end
end

-- The outfits an item belongs to, as Baganator wants them
function Outfitter.Baganator:GetItemSets(pItemLink)
	if type(pItemLink) ~= "string" then
		return nil
	end

	local vCode = tonumber(pItemLink:match("item:(%d+)"))
	local vOutfits = vCode and self.ByCode[vCode]

	if not vOutfits then
		return nil
	end

	-- Another item with the same ID (a different random enchantment, say) isn't
	-- the outfit's item, so ask the outfit about this one
	local vItemInfo = Outfitter:GetItemInfoFromLink(pItemLink)

	if not vItemInfo then
		return nil
	end

	local vResult = {}

	for _, vOutfit in ipairs(vOutfits) do
		if vOutfit:OutfitUsesItem(vItemInfo) then
			table.insert(vResult,
			{
				name = vOutfit:GetName(),
				iconTexture = Outfitter.OutfitBar:GetOutfitTexture(vOutfit),
			})
		end
	end

	if #vResult == 0 then
		return nil
	end

	return vResult
end

function Outfitter.Baganator:Register()
	if self.Registered then
		return true
	end

	local vAPI = GetAPI()

	if not vAPI then
		return false
	end

	-- Baganator calls these while it draws the bags, so an error in here must
	-- not get out: it would break the bag window
	vAPI.RegisterItemSetSource(Outfitter.cTitle, "outfitter_forever", function (pLocation, pGUID, pItemLink)
		local vSucceeded, vResult = pcall(self.GetItemSets, self, pItemLink)

		if vSucceeded then
			return vResult
		end
	end, function ()
		return self.Names
	end)

	self.Registered = true

	local function Update()
		self:Rebuild()
	end

	Outfitter:RegisterOutfitEvent("OUTFITTER_INIT", Update)
	Outfitter:RegisterOutfitEvent("ADD_OUTFIT", Update)
	Outfitter:RegisterOutfitEvent("DELETE_OUTFIT", Update)
	Outfitter:RegisterOutfitEvent("EDIT_OUTFIT", Update)
	Outfitter:RegisterOutfitEvent("DID_RENAME_OUTFIT", Update)

	if Outfitter:IsInitialized() then
		self:Rebuild()
	end

	return true
end

-- Baganator normally loads first (it's an optional dependency in the .toc).
-- If it isn't there yet, wait for it.
if not Outfitter.Baganator:Register() then
	local vWatcher = CreateFrame("Frame")

	vWatcher:RegisterEvent("ADDON_LOADED")
	vWatcher:SetScript("OnEvent", function (pFrame, pEvent, pAddonName)
		if pAddonName == "Baganator" and Outfitter.Baganator:Register() then
			pFrame:UnregisterEvent("ADDON_LOADED")
		end
	end)
end
