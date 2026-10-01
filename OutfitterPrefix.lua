----------------------------------------
-- Outfitter Copyright 2009-2018 John Stephen
-- All rights reserved, unauthorized redistribution is prohibited
----------------------------------------

local _
_, Outfitter = ...

Outfitter.DebugColorCode = "|cff99ffcc"
Outfitter.AddonPath = "Interface\\Addons\\"..select(1, ...).."\\"
Outfitter.UIElementsLibTexturePath = Outfitter.AddonPath
Outfitter.Debug = {}

--

Outfitter.LibBabbleSubZone = LibStub("LibBabble-SubZone-3.0")
Outfitter.LibBabbleInventory = LibStub("LibBabble-Inventory-3.0")
Outfitter.LibTipHooker = LibStub("LibTipHooker-1.1")
Outfitter.LBF = LibStub("LibButtonFacade", true)
Outfitter.LibDropdown = LibStub("LibDropdownMC-1.0")

Outfitter.LBI = Outfitter.LibBabbleInventory:GetLookupTable()
Outfitter.LSZ = Outfitter.LibBabbleSubZone:GetLookupTable()

-- Outfitter versions of globals
Outfitter.NUM_TOTAL_EQUIPPED_BAG_SLOTS = _G["NUM_TOTAL_EQUIPPED_BAG_SLOTS"] or NUM_BAG_SLOTS

----------------------------------------
-- WoW: Forever
----------------------------------------
-- Forever runs the modern (Mainline) client and UI, so WOW_PROJECT_ID reports
-- Mainline, but the game itself is classic: ranged slot, three warrior stances,
-- talent trees as specializations. Its interface number is 1xxxx (16001).

Outfitter.AddonName = select(1, ...)
Outfitter.IsForever = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and (select(4, GetBuildInfo()) or 0) < 20000

-- Some values are hidden from addons on Forever (your own mana and health, for
-- example). Comparing or doing math on one throws an error, so check first.
function Outfitter.IsSecret(pValue)
	return issecretvalue ~= nil and issecretvalue(pValue) == true
end

-- The player's specialization (talent tree) index, or nil if it isn't available
function Outfitter:GetSpecialization()
	local vGetSpecialization = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or _G["GetSpecialization"]
	if not vGetSpecialization then
		return nil
	end
	local vSucceeded, vIndex = pcall(vGetSpecialization)
	if not vSucceeded or Outfitter.IsSecret(vIndex) then
		return nil
	end
	return vIndex
end

-- Same returns as GetSpecializationInfo (specID, name, ...)
function Outfitter:GetSpecializationInfo(pIndex)
	local vGetSpecializationInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or _G["GetSpecializationInfo"]
	if not vGetSpecializationInfo or not pIndex then
		return nil
	end
	return vGetSpecializationInfo(pIndex)
end