------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3
------------------------------------------------------------------------------------------------------------------------
local libFilters = LibFilters3

local tos = tostring

--Helper variables of ESO
local iigpm = IsInGamepadPreferredMode
local SHINV = SHARED_INVENTORY

--Helper variables of the library
local constants   =                         libFilters.constants
local mapping     =                         libFilters.mapping

local kbc         =                         constants.keyboard
local gpc         =                         constants.gamepad

local bagIdToInventory =                    mapping.bagIdToInventory

--Debugging
local debugFunctions = libFilters.debugFunctions
local dd = debugFunctions.dd

if libFilters.debug then dd("LIBRARY HELPER FILE - START") end


------------------------------------------------------------------------------------------------------------------------
--Local LibFilters speed-up variables and references
------------------------------------------------------------------------------------------------------------------------
--Keyboard
--local inventories =                         kbc.inventories
local playerInv =                           kbc.playerInv
local store =                               kbc.store
local vendorBuyBack =                       kbc.vendorBuyBack
local vendorRepair =                        kbc.vendorRepair
local quickslots  =                         kbc.quickslots
local smithing =                            kbc.smithing
local smithingResearchPanel =               smithing.researchPanel
local researchChooseItemDialog =            kbc.researchChooseItemDialog
local universalDeconstructPanel =           kbc.universalDeconstructPanel
local retrait =                             kbc.retrait

--Gamepad
local invBackpack_GP =                      gpc.invBackpack_GP
local vendorRepair_GP =                     gpc.vendorRepair_GP
local vendorBuy_GP =                        gpc.vendorBuy_GP
local vendorSell_GP =                       gpc.vendorSell_GP
local vendorBuyBack_GP =                    gpc.vendorBuyBack_GP
local fenceSell_GP =                        gpc.invFenceSell_GP
local fenceLaunder_GP =                     gpc.invFenceLaunder_GP
local storeWindowComponents_GP =            gpc.store_GP.components

local smithing_GP =                         gpc.smithing_GP
local universalDeconstructPanel_GP =        gpc.universalDeconstructPanel_GP
local companionEquipment_GP =               gpc.companionEquipment_GP

--local enchantingModeToFilterType = mapping.enchantingModeToFilterType
--local LF_ConstantToAdditionalFilterControlSceneFragmentUserdata = mapping.LF_ConstantToAdditionalFilterControlSceneFragmentUserdata
--local getCurrentFilterTypeForInventory = libFilters.GetCurrentFilterTypeForInventory


------------------------------------------------------------------------------------------------------------------------
--Local variables for the helpers
------------------------------------------------------------------------------------------------------------------------
local helpers = {}
--local defaultLibFiltersAttributeToStoreTheFilterType = constants.defaultAttributeToStoreTheFilterType --.LibFilters3_filterType
local defaultLibFiltersAttributeToStoreTheHorizontalScrollbarFilters = constants.defaultLibFiltersAttributeToStoreTheHorizontalScrollbarFilters --"LibFilters3_HorizontalScrollbarFilters"
local defaultOriginalFilterAttributeAtLayoutData = constants.defaultAttributeToAddFilterFunctions --.additionalFilter


------------------------------------------------------------------------------------------------------------------------
--Local functions for the helpers
------------------------------------------------------------------------------------------------------------------------
--Locals for .additionalFilters checks
local function doesAdditionalFilterFuncExist(objectVar)
    return (objectVar and objectVar[defaultOriginalFilterAttributeAtLayoutData] and type(objectVar[defaultOriginalFilterAttributeAtLayoutData]) == "function") or false
end

--Check for .additionalFilter in an object and run it on the slotItem now
local function checkAndRundAdditionalFilters(objectVar, slotItem, resultIfNoAdditionalFilter)
	if resultIfNoAdditionalFilter == nil then resultIfNoAdditionalFilter = true end

    if doesAdditionalFilterFuncExist(objectVar) then
		if resultIfNoAdditionalFilter then
			resultIfNoAdditionalFilter = objectVar[defaultOriginalFilterAttributeAtLayoutData](slotItem)
		end
    end
	return resultIfNoAdditionalFilter
end

--Check for .additionalFilter in an object and run it on the bagId and slotIndex now
local function checkAndRundAdditionalFiltersBag(objectVar, bagId, slotIndex, resultIfNoAdditionalFilter)
	if resultIfNoAdditionalFilter == nil then resultIfNoAdditionalFilter = true end

    if doesAdditionalFilterFuncExist(objectVar) then
		if resultIfNoAdditionalFilter then
			resultIfNoAdditionalFilter = objectVar[defaultOriginalFilterAttributeAtLayoutData](bagId, slotIndex)
		end
    end
	return resultIfNoAdditionalFilter
end


------------------------------------------------------------------------------------------------------------------------
--Locals "original" functions of ZOs vanilla code
------------------------------------------------------------------------------------------------------------------------

--Original function at:
--smithingextraction_ or smithingimprovement_shared.lua
--[[
    function ZO_SharedSmithingExtraction_DoesItemPassFilter(bagId, slotIndex, filterType)
        return ZO_CraftingUtils_GetSmithingFilterFromItem(bagId, slotIndex) == filterType
    end

    function ZO_SharedSmithingImprovement_DoesItemPassFilter(bagId, slotIndex, filterType)
        return ZO_CraftingUtils_GetSmithingFilterFromItem(bagId, slotIndex) == filterType
    end
]]
--->used for LF_RETRAIT, LF_SMITHING_REFINE, LF_JEWELRY_REFINE, LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT, LF_SMITHING_IMPROVEMENT, LF_JEWELRY_IMPROVEMENT
-----> As we overwrite ZO_SharedSmithingExtraction_DoesItemPassFilter and ZO_SharedSmithingImprovement_DoesItemPassFilter with the helpers we need a local replacement!
local doesRetraitItemItemPassFilterOriginal =               ZO_RetraitStation_DoesItemPassFilter
local doesSmithingItemPassFilterOriginal =                  ZO_SharedSmithingExtraction_DoesItemPassFilter
local doesImprovementItemPassFilterOriginal             =   ZO_SharedSmithingImprovement_DoesItemPassFilter
local doesUniversalDeconstructionItemPassFilterOriginal =   ZO_UniversalDeconstructionPanel_Shared.DoesItemPassFilter


--Original function at:
--smithingresearch_shared.lua
--[[
    local function DoesNotBlockResearch(bagId, slotIndex)
        return not IsItemPlayerLocked(bagId, slotIndex) and GetItemTraitInformation(bagId, slotIndex) ~= ITEM_TRAIT_INFORMATION_RETRAITED and GetItemTraitInformation(bagId, slotIndex) ~= ITEM_TRAIT_INFORMATION_RECONSTRUCTED
    end
]]
-->Used for LF_SMITHING_RESEARCH, LF_JEWELRY_RESEARCH, LF_SMITHING_RESEARCH_DIALOG, LF_JEWELRY_RESEARCH_DIALOG
local function DoesNotBlockResearch(bagId, slotIndex)
    local disallowedItemTraits = {
        [ITEM_TRAIT_INFORMATION_RETRAITED] = true,
        [ITEM_TRAIT_INFORMATION_RECONSTRUCTED] = true,
    }
    return not IsItemPlayerLocked(bagId, slotIndex) and not disallowedItemTraits[GetItemTraitInformation(bagId, slotIndex)]
end


------------------------------------------------------------------------------------------------------------------------
--Locals for keyboard helpers
------------------------------------------------------------------------------------------------------------------------
--Vendor repair - LF_VENDOR_REPAIR
local DATA_TYPE_REPAIR_ITEM = 1
--Called from REPAIR_WINDOW:UpdateList()
-->See \esoui\ingame\repair\repairwindow.lua
local function GatherDamagedEquipmentFromBag_Keyboard(bagId, dataTable)
    for slotIndex in ZO_IterateBagSlots(bagId) do
        if TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("storeTextSearch", BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, bagId, slotIndex) then
            local condition = GetItemCondition(bagId, slotIndex)
            if condition < 100 and not IsItemStolen(bagId, slotIndex) then
                local icon, stackCount, _, _, _, _, _, functionalQuality, displayQuality = GetItemInfo(bagId, slotIndex)
                if stackCount > 0 then
                    local repairCost = GetItemRepairCost(bagId, slotIndex)
                    if repairCost > 0 then
                        local name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bagId, slotIndex))
                        local data =
                        {
                            bagId = bagId,
                            slotIndex = slotIndex,
                            name = name,
                            icon = icon,
                            stackCount = stackCount,
                            functionalQuality = functionalQuality,
                            displayQuality = displayQuality,
                            -- quality is deprecated, included here for addon backwards compatibility
                            quality = displayQuality,
                            condition = condition,
                            repairCost = repairCost
                        }
                        --Original result was true, so add the LibFilters filterFunctions now
                        if checkAndRundAdditionalFilters(vendorRepair, data, true) == true then     -- Added by LibFilters
                            dataTable[#dataTable + 1] = ZO_ScrollList_CreateDataEntry(DATA_TYPE_REPAIR_ITEM, data)
                        end
                    end
                end
            end
        end
    end
end

--Smithing research - LF_SMITHING_RESEARCH
--Always use SMITHING.researchPanel as self, even in gamepad mode, so registered filter functions
--will be read from .additionalFilter (Gamepad mode Smithing researchPanel uses the same base as keyboard!)
-- Our filter function to insert LibFilter filter callback function (.additionalFilter at SMITHING.researchPanel.inventory)
local function smithingResearchPredicate(bagId, slotIndex)
    local result = DoesNotBlockResearch(bagId, slotIndex)
    return checkAndRundAdditionalFiltersBag(smithingResearchPanel, bagId, slotIndex, result)
end

--Smithing research dialog - LF_SMITHING_RESEARCH_DIALOG
local function doesItemPassResearchDialogFilter(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
    return CanItemBeSmithingTraitResearched(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
            and DoesNotBlockResearch(bagId, slotIndex)
end

--Universal deconstruction, added with API101033 Ascending Tide
--Mapping variables
local detectUniversalDeconstructionPanelActiveTab = libFilters.DetectUniversalDeconstructionPanelActiveTab
local filterTypeToFilterBase                      = mapping.universalDeconFilterTypeToFilterBase
--Update local ref variables
universalDeconstructPanel = universalDeconstructPanel or kbc.universalDeconstructPanel
universalDeconstructPanel_GP = universalDeconstructPanel_GP or gpc.universalDeconstructPanel_GP

--Workaround for GamePad mode where ZOs did not create the function GetCurrentFilter "yet"
-->2023-08-31, Should have been implemented by ZOs properly meanwhile
--[[
if not universalDeconstructPanel_GP.inventory.GetCurrentFilter then
    function universalDeconstructPanel_GP.inventory.GetCurrentFilter()
        return universalDeconstructPanel_GP.currentFilterData or ZO_GetUniversalDeconstructionFilterType("all")
    end
end
]]



------------------------------------------------------------------------------------------------------------------------
--Locals for gamepad Vendor/Fence
--> See \esoui\ingame\storewindow\gamepad\storewindow_gamepad_util.lua
------------------------------------------------------------------------------------------------------------------------
local STORE_WEAPON_GROUP = 1
local STORE_HEAVY_ARMOR_GROUP = 2
local STORE_MEDIUM_ARMOR_GROUP = 3
local STORE_LIGHT_ARMOR_GROUP = 4
local STORE_JEWELRY_GROUP = 5
local STORE_SUPPLIES_GROUP = 6
local STORE_MATERIALS_GROUP = 7
local STORE_QUICKSLOTS_GROUP = 8
local STORE_COLLECTIBLE_GROUP = 9
local STORE_QUEST_ITEMS_GROUP = 10
local STORE_ANTIQUITY_LEADS_GROUP = 11
local STORE_OTHER_GROUP = 12

local function GetItemStoreGroup(itemData)
    if itemData.entryType == STORE_ENTRY_TYPE_COLLECTIBLE then
        return STORE_COLLECTIBLE_GROUP
    elseif itemData.entryType == STORE_ENTRY_TYPE_QUEST_ITEM then
        return STORE_QUEST_ITEMS_GROUP
    elseif itemData.entryType == STORE_ENTRY_TYPE_ANTIQUITY_LEAD then
        return STORE_ANTIQUITY_LEADS_GROUP
    elseif itemData.equipType == EQUIP_TYPE_RING or itemData.equipType== EQUIP_TYPE_NECK then
        return STORE_JEWELRY_GROUP
    elseif itemData.itemType == ITEMTYPE_WEAPON or itemData.displayFilter == ITEMFILTERTYPE_WEAPONS then
        return STORE_WEAPON_GROUP
    elseif itemData.itemType == ITEMTYPE_ARMOR or itemData.displayFilter == ITEMFILTERTYPE_ARMOR then
        local armorType
        if itemData.bagId and itemData.slotIndex then
            armorType = GetItemArmorType(itemData.bagId, itemData.slotIndex)
        else
            armorType = GetItemLinkArmorType(itemData.itemLink)
        end
        if armorType == ARMORTYPE_HEAVY then
            return STORE_HEAVY_ARMOR_GROUP
        elseif armorType == ARMORTYPE_MEDIUM then
            return STORE_MEDIUM_ARMOR_GROUP
        elseif armorType == ARMORTYPE_LIGHT then
            return STORE_LIGHT_ARMOR_GROUP
        end
    elseif ZO_InventoryUtils_DoesNewItemMatchSupplies(itemData) then
        return STORE_SUPPLIES_GROUP
    elseif ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, ITEMFILTERTYPE_CRAFTING) then
        return STORE_MATERIALS_GROUP
    elseif ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, ITEMFILTERTYPE_QUICKSLOT) then
        return STORE_QUICKSLOTS_GROUP
    end
    return STORE_OTHER_GROUP
end

local function GetBestItemCategoryDescription(itemData)
    if itemData.storeGroup == STORE_COLLECTIBLE_GROUP then
        local collectibleCategory = GetCollectibleCategoryTypeFromLink(itemData.itemLink)
        return GetString("SI_COLLECTIBLECATEGORYTYPE", collectibleCategory)
    elseif itemData.storeGroup == STORE_QUEST_ITEMS_GROUP then
        return GetString(SI_ITEM_FORMAT_STR_QUEST_ITEM)
    elseif itemData.storeGroup == STORE_ANTIQUITY_LEADS_GROUP then
        return GetString(SI_GAMEPAD_VENDOR_ANTIQUITY_LEAD_GROUP_HEADER)
    else
        return ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription(itemData)
    end
end

local function GetBestSellItemCategoryDescription(itemData)
    local traitType = GetItemTrait(itemData.bagId, itemData.slotIndex)
    if traitType == ITEM_TRAIT_TYPE_WEAPON_ORNATE or traitType == ITEM_TRAIT_TYPE_ARMOR_ORNATE or traitType == ITEM_TRAIT_TYPE_JEWELRY_ORNATE then
        return GetString("SI_ITEMTRAITTYPE", traitType)
    else
        return GetBestItemCategoryDescription(itemData)
    end
end

local function IsStolenItemSellable(itemData)
    return itemData.sellPrice > 0
end

-- optFilterFunction is an optional additional check to make when gathering all the stolen items
-- ... are bag ids to get items from
local function GetStolenItems(optFilterFunction, ...)
    local function IsStolenItem(itemData)
        local isStolen = itemData.stolen
        if optFilterFunction then
            return isStolen and optFilterFunction(itemData)
        else
            return isStolen
        end
    end
    local items = SHINV:GenerateFullSlotData(IsStolenItem, ...)
    local unequippedItems = {}
    --- Setup sort filter
    for _, itemData in ipairs(items) do
        itemData.isEquipped =                   false
        itemData.meetsRequirementsToBuy =       true
        itemData.meetsRequirementsToEquip =     itemData.meetsUsageRequirements
        itemData.storeGroup =                   GetItemStoreGroup(itemData)
        itemData.bestGamepadItemCategoryName =  GetBestItemCategoryDescription(itemData)
        table.insert(unequippedItems, itemData)
    end
    return unequippedItems
end

--Gamepad mode - Vendor repair LF_VENDOR_REPAIR
--Called from local function GetRepairItems(searchContext)
--> See \esoui\ingame\storewindow\gamepad\storewindow_gamepad_util.lua
local function GatherDamagedEquipmentFromBag_Gamepad(searchContext, bagId, itemTable)
    local bagSlots = GetBagSize(bagId)
    for slotIndex = 0, bagSlots - 1 do
        if searchContext and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults(searchContext, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, bagId, slotIndex) then
            local condition = GetItemCondition(bagId, slotIndex)
            if condition < 100 and not IsItemStolen(bagId, slotIndex) then
                local _, stackCount = GetItemInfo(bagId, slotIndex)
                if stackCount > 0 then
                    local repairCost = GetItemRepairCost(bagId, slotIndex)
                    if repairCost > 0 then
                        local damagedItem = SHINV:GenerateSingleSlotData(bagId, slotIndex)

                        --Original result was true, so add the LibFilters filterFunctions now
                        if checkAndRundAdditionalFilters(vendorRepair_GP, damagedItem, true) == true then -- Added by LibFilters
                            damagedItem.condition = condition
                            damagedItem.repairCost = repairCost
                            damagedItem.invalidPrice = repairCost > GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
                            damagedItem.isEquippedInCurrentCategory = damagedItem.bagId == BAG_WORN
                            damagedItem.storeGroup = GetItemStoreGroup(damagedItem)
                            damagedItem.bestGamepadItemCategoryName = GetBestItemCategoryDescription(damagedItem)
                            table.insert(itemTable, damagedItem)
                        end
                    end
                end
            end
        end
    end
end


------------------------------------------------------------------------------------------------------------------------
--The helpers: Overwritten/changed ZOs vanilla code for the different LibFilters LF_* filterTypes. Most of them will
--check for the existance of an entry .additionalFilter and run the filters together with vanilla code filters then.
--Some vanilla filters like the inventories of player, bank, guild bank deposits already use .additionalFilter them-
--selves in the ZOs code and we did just hook it to add our own functions in addition. See file LibFilters-3.0.lua,
--function libFilters:HookAdditionalFilter(LF_* constant) and runFilters()
--
-- version: The version of the helper. Used to check if another same helper is already installed and overwrite it with
-- a newer version
-- filterTypes: A table containing the gamepad (true) and keyboard (false) entries of LF_* filterType constants that
-- this helper function belongs to (overwrites)
-- locations: A table with controls or other "locations" where the helper will be overwriting vanilla code. If the helper
--           is just a global function then the location will be _G (the global overall table). In other cases it will be
--           the object variable where the function/helper needs to be overwritten (Only overwrit the "objects", no "class"!
--           e.g. do not overwrite ZO_Smithing class, but overwrite SMITHING object! Else you might destroy every other
--           established filter function and addons using filters, or even vanilla code.)
-- helper: The helper's lua code, of the function/etc. which will be overwriting the vanilla code at the locations
------------------------------------------------------------------------------------------------------------------------



------------------------------------------------------------------------------------------------------------------------
 -- -v- KEYBOARD ONLY helpers
---------------------------------------------------------------------------------------------------------------------------
--enable LF_VENDOR_BUY
-->See \esoui\ingame\storewindow\keyboard\storewindow_keyboard.lua
helpers["STORE_WINDOW:ShouldAddItemToList"] = {
    version = 3,
    filterTypes = {
        [true] = {},
        [false]={LF_VENDOR_BUY}
    },
    locations = {
        [1] = store,
    },
    helper = {
        funcName = "ShouldAddItemToList",
        func = function(self, itemData)
            --Original result was not build yet, we assume it is true, so add the LibFilters filterFunctions now
            local result = checkAndRundAdditionalFilters(self, itemData, true)

            if self.currentFilter == ITEMFILTERTYPE_ALL then return result and true end

            for i = 1, #itemData.filterData do
                if itemData.filterData[i] == self.currentFilter then
                    return result and true
                end
            end

            return false
        end,
    },
}


--enable LF_VENDOR_BUYBACK
-->See \esoui\ingame\storewindow\keyboard\buyback_keyboard.lua
local DATA_TYPE_BUY_BACK_ITEM = 1

helpers["BUY_BACK_WINDOW:UpdateList"] = {
    version = 3,
    filterTypes = {
        [true] = {},
        [false]={LF_VENDOR_BUYBACK}
    },
    locations = {
        [1] = vendorBuyBack,
    },
    helper = {
        funcName = "UpdateList",
        func = function(self)
            if not self.control:IsControlHidden() then
                ZO_ScrollList_Clear(self.list)
                ZO_ScrollList_ResetToTop(self.list)

                local scrollData = ZO_ScrollList_GetDataList(self.list)

                for entryIndex = 1, GetNumBuybackItems() do
                    if not TEXT_SEARCH_MANAGER or
                        (TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("storeTextSearch", BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, BAG_BUYBACK, entryIndex)) then
                        local icon, name, stack, price, functionalQuality, meetsRequirements, displayQuality = GetBuybackItemInfo(entryIndex)
                        if stack > 0 then
                            local buybackData = {
                                slotIndex = entryIndex,
                                icon = icon,
                                name = name,
                                stack = stack,
                                price = price,
                                functionalQuality = functionalQuality,
                                displayQuality = displayQuality,
                                -- quality is deprecated, included here for addon backwards compatibility
                                quality = displayQuality,
                                meetsRequirements = meetsRequirements,
                                stackBuyPrice = stack * price,
                            }
                            --Original result was true, so add the LibFilters filterFunctions now
                            local result = checkAndRundAdditionalFilters(self, buybackData, true)
                            if result == true then
                                scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(DATA_TYPE_BUY_BACK_ITEM, buybackData)
                            end
                        end
                    end
                end

                self:ApplySort()
            end
        end,
    },
}


--enable LF_VENDOR_REPAIR
-->See \esoui\ingame\repair\repairwindow.lua
helpers["REPAIR_WINDOW:UpdateList"] = {
    version = 5,
    filterTypes = {
        [true] = {},
        [false]={LF_VENDOR_REPAIR}
    },
    locations = {
        [1] = vendorRepair,
    },
    helper = {
        funcName = "UpdateList",
        func = function(self)
            if not self.control:IsControlHidden() then
                ZO_ScrollList_Clear(self.list)
                ZO_ScrollList_ResetToTop(self.list)

                local scrollData = ZO_ScrollList_GetDataList(self.list)

                GatherDamagedEquipmentFromBag_Keyboard(BAG_WORN, scrollData)
                GatherDamagedEquipmentFromBag_Keyboard(BAG_BACKPACK, scrollData)

                self:ApplySort()
            end
        end,
    },
}


--enable LF_QUICKSLOT
-->Will only be executed for normal inventory items but NOT for the collectible items in the quickslot filters
-->Since API101034: QUICKSLOT_WINDOW is gone and was replaced by QUICKSLOT_KEYBOARD
--> See \esoui\ingame\quickslot\keyboard\quickslot_keyboard.lua
helpers["QUICKSLOT_KEYBOARD:ShouldAddItemToList"] = {
    filterTypes = {
        [true] = {},
        [false]={LF_QUICKSLOT}
    },
    version = 6,
    locations = {
        [1] = quickslots,
    },
    helper = {
        funcName = "ShouldAddItemToList",
        func = function(self, itemData)
            local result = ZO_IsElementInNumericallyIndexedTable(itemData.filterData, ITEMFILTERTYPE_QUICKSLOT) and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("quickslotTextSearch", BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, itemData.bagId, itemData.slotIndex)
            --Original result was determined, so add the LibFilters filterFunctions now
            return checkAndRundAdditionalFilters(self, itemData, result)
        end,
    },
}


-->Will only be executed for quest related inventory items but NOT for the normal inventory or collectible items in the quickslot filters
--> See \esoui\ingame\quickslot\keyboard\quickslot_keyboard.lua
helpers["QUICKSLOT_KEYBOARD:ShouldAddQuestItemToList"] = {
    version = 4,
    filterTypes = {
        [true] = {},
        [false]={LF_QUICKSLOT}
    },
    locations = {
        [1] = quickslots,
    },
    helper = {
        funcName = "ShouldAddQuestItemToList",
        func = function(self, questItemData)
            local result = ZO_IsElementInNumericallyIndexedTable(questItemData.filterData, ITEMFILTERTYPE_QUEST_QUICKSLOT) and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("quickslotTextSearch", BACKGROUND_LIST_FILTER_TARGET_QUEST_ITEM_ID, questItemData.questItemId)
            --Original result was determined, so add the LibFilters filterFunctions now
            return checkAndRundAdditionalFilters(self, questItemData, result)
        end,
    },
}


-->Will only be executed for the collectible items in the quickslot filters, but no inventory items
local DATA_TYPE_COLLECTIBLE_ITEM = 2
--> See \esoui\ingame\quickslot\keyboard\quickslot_keyboard.lua
helpers["QUICKSLOT_KEYBOARD:AppendCollectiblesData"] = {
    version = 4,
    filterTypes = {
        [true] = {},
        [false]={LF_QUICKSLOT}
    },
    locations = {
        [1] = quickslots,
    },
    helper = {
        funcName = "AppendCollectiblesData",
        func = function(self, scrollData, collectibleCategoryData)
            local dataObjects
            if collectibleCategoryData then
                dataObjects = collectibleCategoryData:GetAllCollectibleDataObjects({ ZO_CollectibleData.IsUnlocked, ZO_CollectibleData.IsValidForPlayer, ZO_CollectibleData.IsSlottable })
            else
                dataObjects = ZO_COLLECTIBLE_DATA_MANAGER:GetAllCollectibleDataObjects({ ZO_CollectibleCategoryData.IsStandardCategory }, { ZO_CollectibleData.IsUnlocked, ZO_CollectibleData.IsValidForPlayer, ZO_CollectibleData.IsSlottable })
            end

            local libFiltersQuickslotCollectiblesFilterFunc
            if doesAdditionalFilterFuncExist(self) then
                libFiltersQuickslotCollectiblesFilterFunc = self[defaultOriginalFilterAttributeAtLayoutData] --.additionalFilter
            end
            for i, collectibleData in ipairs(dataObjects) do
                collectibleData.searchData =
                {
                    type = ZO_TEXT_SEARCH_TYPE_COLLECTIBLE,
                    collectibleId = collectibleData.collectibleId,
                }
                local result = (not libFiltersQuickslotCollectiblesFilterFunc and true) or (libFiltersQuickslotCollectiblesFilterFunc and libFiltersQuickslotCollectiblesFilterFunc(collectibleData))
                --Original result was determined from .additionalFilter registered functions, or if no filterFunction existed: true
                if result == true and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("quickslotTextSearch", BACKGROUND_LIST_FILTER_TARGET_COLLECTIBLE_ID, collectibleData.collectibleId) then
                    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_TYPE_COLLECTIBLE_ITEM, collectibleData))
                end
            end
        end,
    },
}
------------------------------------------------------------------------------------------------------------------------
 -- -^- KEYBOARD ONLY helpers
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
 -- -v- KEYBOARD and GAMEPAD - shared helpers
------------------------------------------------------------------------------------------------------------------------
--enable LF_ENCHANTING_CREATION/LF_ENCHANTING_EXTRACTION
-->See \esoui\ingame\crafting\sharedenchanting.lua
-- IsJustaGhost: using GAMEPAD_ENCHANTING_CREATION_SCENE/GAMEPAD_ENCHANTING_EXTRACTION_SCENE exclusively
-- I've used the gamepad scenes here since they were already set to be filters and required less changing,
-- they also are both available in keyboard and gamepad mode, for ENCHANTING_CREATION/ENCHANTING_EXTRACTION
helpers["ZO_Enchanting_DoesEnchantingItemPassFilter"] = {
    version = 2,
    filterTypes = {
        [true] = {LF_ENCHANTING_CREATION, LF_ENCHANTING_EXTRACTION},
        [false]={LF_ENCHANTING_CREATION, LF_ENCHANTING_EXTRACTION}
    },
    locations = {
        [1] = _G
    },
    helper = {
        funcName = "ZO_Enchanting_DoesEnchantingItemPassFilter",
        func = function(bagId, slotIndex, filterType, questFilterChecked, questRunes)
			local usedInCraftingType, craftingSubItemType, runeType = GetItemCraftingInfo(bagId, slotIndex)

			if filterType == ENCHANTING_EXTRACTION_FILTER then
				local result = craftingSubItemType == ITEMTYPE_GLYPH_WEAPON or craftingSubItemType == ITEMTYPE_GLYPH_ARMOR or craftingSubItemType == ITEMTYPE_GLYPH_JEWELRY
                --Original result was determined, so add the LibFilters filterFunctions now
				return checkAndRundAdditionalFiltersBag(GAMEPAD_ENCHANTING_EXTRACTION_SCENE, bagId, slotIndex, result)
			elseif filterType == ENCHANTING_NO_FILTER or filterType == runeType then
                local result = true
                if questFilterChecked then
                    local itemId = GetItemId(bagId, slotIndex)
                    if questRunes.potency == itemId or questRunes.essence == itemId or questRunes.aspect == itemId then
                        result = DoesPlayerHaveRunesForEnchanting(questRunes.aspect, questRunes.essence, questRunes.potency)
                    else
                        result = false
                    end
                else
                    result = runeType == ENCHANTING_RUNE_ASPECT or runeType == ENCHANTING_RUNE_ESSENCE or runeType == ENCHANTING_RUNE_POTENCY
                end
                --Original result was determined, so add the LibFilters filterFunctions now
                return checkAndRundAdditionalFiltersBag(GAMEPAD_ENCHANTING_CREATION_SCENE, bagId, slotIndex, result)
			end
			return false
        end,
    }
}

--enable LF_ALCHEMY_CREATION
-->See \esoui\ingame\crafting\sharedalchemy.lua
-- Using ALCHEMY_SCENE exclusively, in keyboard and gamepad mode
helpers["ZO_Alchemy_DoesAlchemyItemPassFilter"] = {
    version = 3,
    filterTypes = {
        [true] = {LF_ALCHEMY_CREATION},
        [false]={LF_ALCHEMY_CREATION}
    },
    locations = {
        [1] = _G
    },
    helper = {
        funcName = "ZO_Alchemy_DoesAlchemyItemPassFilter",
        func = function(bagId, slotIndex, filterType, isQuestFilterChecked, questInfo)
            local result = true
            if isQuestFilterChecked then
                --If no there is no valid combination at all, then everything fails the filter
                if not questInfo.validCombinationFound then
                    return false
                end
                local itemId = GetItemId(bagId, slotIndex)
                --If this item does not match any solvents or reagents that are quest related, then it does not pass the filter
                if (not questInfo.reagents or questInfo.reagents[itemId] == nil) and (not questInfo.solvent or questInfo.solvent.itemId ~= itemId) then
                    return false
                end
            end

            if filterType == nil then
                result = true
            else
                local _, craftingSubItemType = GetItemCraftingInfo(bagId, slotIndex)

                if type(filterType) == "function" then
                    result = filterType(craftingSubItemType)
                else
                    result = filterType == craftingSubItemType
                end
            end

            --Original result was determined, so add the LibFilters filterFunctions now
            return checkAndRundAdditionalFiltersBag(ALCHEMY_SCENE, bagId, slotIndex, result)
        end,
    }
}


--enable LF_SMITHING_RESEARCH/LF_JEWELRY_RESEARCH -- since API 100023 Summerset
--ZO_SharedSmithingResearch:Refresh()
--> See \esoui\ingame\crafting\smithingresearch_shared.lua
local libFiltersResearchLineLabel


helpers["SMITHING/SMITHING_GAMEPAD.researchPanel:Refresh"] = {
    version = 8,
    filterTypes = {
        [true] = {LF_SMITHING_RESEARCH, LF_JEWELRY_RESEARCH},
        [false]= {LF_SMITHING_RESEARCH, LF_JEWELRY_RESEARCH}
    },
    locations = {
        [1] = smithing.researchPanel,
        [2] = smithing_GP.researchPanel, --Added with API 101032 The Deadlands 2021-10-06
    },
    helper = {
        funcName = "Refresh",
        func = function(self)
            --v- Added by LibFilters - 1 -v-
            if iigpm or (self.panelContent and self.panelContent == ZO_GamepadSmithingTopLevelMaskResearch) then
                -- if Gamepad researchPanel has not been initialized yet, stop.
                if not self.researchLineList then
                    return
                end
            end
            --^- Added by LibFilters - 1 -^-


            -- -v- Begin original function, ZO_SharedSmithingResearch:Refresh() -v-
            self.dirty = false

            self.researchLineList:Clear()
            local craftingType = GetCraftingInteractionType()

            local numCurrentlyResearching = 0

            local virtualInventoryList = playerInv:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, smithingResearchPredicate) --DoesNotBlockResearch
            if self.savedVars.includeBankedItemsChecked then
                playerInv:GenerateListOfVirtualStackedItems(INVENTORY_BANK, smithingResearchPredicate, virtualInventoryList) -- DoesNotBlockResearch
            end


            --v- Added by LibFilters - 2 -v-
                local lSmithingResearchPanel = self
                local fromIterator
                local toIterator
                local skipTable
                local isCurrentlyResearching = {}

                --Get the from, to and skipTable values for the research Line index loop below in order to filter the research line horizontal scroll list
                --and only show some of the entries (filtered by the skipList entries)
                if lSmithingResearchPanel ~= nil then
                    local addonAddedFiltersForHorizontalScrollBar = lSmithingResearchPanel[defaultLibFiltersAttributeToStoreTheHorizontalScrollbarFilters] --"LibFilters3_HorizontalScrollbarFilters"
                    if addonAddedFiltersForHorizontalScrollBar ~= nil then
                        fromIterator =  addonAddedFiltersForHorizontalScrollBar.from
                        toIterator =    addonAddedFiltersForHorizontalScrollBar.to
                        skipTable =     addonAddedFiltersForHorizontalScrollBar.skipTable
                    end
                end
                local numResearchLines = GetNumSmithingResearchLines(craftingType)
                if fromIterator == nil then
                    fromIterator = 1
                end
                if toIterator == nil then
                    toIterator = numResearchLines
                end
            --^- Added by LibFilters - 2 -^-


            -- -v- Go on with original function, ZO_SharedSmithingResearch:Refresh() -v-
            for researchLineIndex = fromIterator, toIterator do                             --Changed to use LibFilters start and end indices here!
                local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
                if numTraits > 0 then
                    local researchingTraitIndex, areAllTraitsKnown = self:FindResearchingTraitIndex(craftingType, researchLineIndex, numTraits)
                    if researchingTraitIndex then
                        numCurrentlyResearching = numCurrentlyResearching + 1

                        isCurrentlyResearching[researchLineIndex] = true                                   --Added by LibFilters (for the currently researching filters)
                    end

                    --Skip any entry in the researchLine (by their index)?
                    if not skipTable or (skipTable ~= nil and skipTable[researchLineIndex] == nil) then    --Added by LibFilters
                        local expectedTypeFilter = ZO_CraftingUtils_GetSmithingFilterFromTrait(GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, 1))
                        if expectedTypeFilter == self.typeFilter then
                            local itemTraitCounts = self:GenerateResearchTraitCounts(virtualInventoryList, craftingType, researchLineIndex, numTraits)
                            local data = { craftingType = craftingType, researchLineIndex = researchLineIndex, name = name, icon = icon, numTraits = numTraits, timeRequiredForNextResearchSecs = timeRequiredForNextResearchSecs, researchingTraitIndex = researchingTraitIndex, areAllTraitsKnown = areAllTraitsKnown, itemTraitCounts = itemTraitCounts }
                            self.researchLineList:AddEntry(data)
                        end
                    end                                                                                     --Added by LibFilters
                end
            end

            self.researchLineList:Commit()

            local maxResearchable = GetMaxSimultaneousSmithingResearch(craftingType)
            if numCurrentlyResearching >= maxResearchable then
                self.atMaxResearchLimit = true
            else
                self.atMaxResearchLimit = false
            end

            self:RefreshCurrentResearchStatusDisplay(numCurrentlyResearching, maxResearchable)

            if self.activeRow then
                self:OnResearchRowActivate(self.activeRow)
            end
            -- -^- End of original function, ZO_SharedSmithingResearch:Refresh()  -^-


            --v- Added by LibFilters - 3 -v-
                --LibFilters 3: If all items are filtered now: Hide the currently shown item label and the trait list
                --Other approach: Check if the horizontal scroll list got no entries.
                local allItemsFiltered = (#self.researchLineList.list == 0 and true) or false

                local researchTimerHidden = true
                if allItemsFiltered then
                    researchTimerHidden = true
                else
                    if numCurrentlyResearching > 0 and isCurrentlyResearching[self.researchLineIndex] == true then
                        researchTimerHidden = false
                    end
                end
                self.timer.control:SetHidden(researchTimerHidden)
                local selfControl = self.control
                GetControl(selfControl, "TraitContainer"):SetHidden(allItemsFiltered)

                if allItemsFiltered == true then
                    if libFiltersResearchLineLabel == nil then
                        libFiltersResearchLineLabel = CreateControl("LibFiltersResearchLineInfoLabel", selfControl, CT_LABEL)
                        libFiltersResearchLineLabel:SetFont("ZoFontGameSmall")
                    end
                    libFiltersResearchLineLabel:SetParent(selfControl)
                    libFiltersResearchLineLabel:SetDimensionConstraints(300, 10, selfControl:GetWidth() - 10, 10)
                    libFiltersResearchLineLabel:SetAnchor(CENTER, selfControl, CENTER, 0, 0)
                    libFiltersResearchLineLabel:SetText(GetString(SI_SMITHING_DECONSTRUCTION_NO_MATCHING_ITEMS))
                    libFiltersResearchLineLabel:SetColor(1, 1, 1, 1)

                    libFiltersResearchLineLabel:SetHidden(false)
                else
                    if libFiltersResearchLineLabel ~= nil then
                        libFiltersResearchLineLabel:SetHidden(true)
                    end
                end

                if iigpm() then
                    --todo 2023-08-31
                    --Gamepad mode support?
                else
                    --Keyboard mode
                    GetControl(selfControl, "ContainerDivider"):SetHidden(allItemsFiltered)
                    GetControl(selfControl, "ResearchLineList"):SetHidden(allItemsFiltered)
                    GetControl(selfControl, "ResearchLineListSelectedLabel"):SetHidden(allItemsFiltered)
                    GetControl(selfControl, "ResearchProgressLabel"):SetHidden(allItemsFiltered)
                    local researchSlotNamePrefix = self.control:GetName() .. "ZO_SmithingResearchSlot"
                    for traitIndex=1, GetNumSmithingTraitItems() do
                        local researchSlot = GetControl(researchSlotNamePrefix, tos(traitIndex))
                        if researchSlot ~= nil then
                            researchSlot:SetHidden(allItemsFiltered)
                        end
                    end
                end
            --^- Added by LibFilters - 3 -^-

        end,
    },
 }


--enable LF_SMITHING_RESEARCH_DIALOG/LF_JEWELRY_RESEARCH_DIALOG smithing/jewelry
-->See \esoui\ingame\crafting\smithingresearch_shared.lua
helpers["ZO_SharedSmithingResearch.IsResearchableItem"] = {
    version = 2,
    filterTypes = {
        [true] = {LF_SMITHING_RESEARCH_DIALOG, LF_JEWELRY_RESEARCH_DIALOG},
        [false]={LF_SMITHING_RESEARCH_DIALOG, LF_JEWELRY_RESEARCH_DIALOG}
    },
    locations = {
        [1] = ZO_SharedSmithingResearch
    },
    helper = {
        funcName = "IsResearchableItem",
        func = function(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
--d("[LibFilters3]IsResearchableItem: " ..GetItemLink(bagId, slotIndex))
			local result = doesItemPassResearchDialogFilter(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
            --Original result was determined, so add the LibFilters filterFunctions now
            return checkAndRundAdditionalFiltersBag(researchChooseItemDialog, bagId, slotIndex, result)  --SMITHING_RESEARCH_SELECT
        end,
    }
}


--enable LF_RETRAIT
--> See \esoui\ingame\retrait\zo_retraitstation_retrait_base.lua
helpers["ZO_RetraitStation_DoesItemPassFilter"] = {
    version = 4,
    filterTypes = {
        [true] = {LF_RETRAIT},
        [false]={LF_RETRAIT}
    },
    locations = {
        [1] = _G
    },
    helper = {
        funcName = "ZO_RetraitStation_DoesItemPassFilter",
        func = function(bagId, slotIndex, filterType)
			local result = doesRetraitItemItemPassFilterOriginal(bagId, slotIndex, filterType)
            --Original result was determined, so add the LibFilters filterFunctions now
			return checkAndRundAdditionalFiltersBag(retrait, bagId, slotIndex, result)  --ZO_RETRAIT_KEYBOARD
        end,
    }
}


--enable LF_SMITHING_REFINE/LF_JEWELRY_REFINE/LF_SMITHING_DECONSTRUCT/LF_JEWELRY_DECONSTRUCT smithing/jewelry
--> See \esoui\ingame\crafting\smithingextraction_shared.lua
helpers["ZO_SharedSmithingExtraction_DoesItemPassFilter"] = {
    version = 2,
    filterTypes = {
        [true] = {
            LF_SMITHING_REFINE, LF_JEWELRY_REFINE,
            LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT
        },
        [false]={LF_SMITHING_REFINE, LF_JEWELRY_REFINE, LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT}
    },
    locations = {
        [1] = _G
    },
    helper = {
        funcName = "ZO_SharedSmithingExtraction_DoesItemPassFilter",
        func = function(bagId, slotIndex, filterType)
			-- get objectVar for LF_SMITHING_REFINE/LF_JEWELRY_REFINE, or LF_SMITHING_DECONSTRUCT/LF_JEWELRY_DECONSTRUCT-> Use keyboard mode variable for gamepad mode as well
            local base = filterType == SMITHING_FILTER_TYPE_RAW_MATERIALS and smithing.refinementPanel or smithing.deconstructionPanel

			local result = doesSmithingItemPassFilterOriginal(bagId, slotIndex, filterType)
            --Original result was determined, so add the LibFilters filterFunctions now
            return checkAndRundAdditionalFiltersBag(base, bagId, slotIndex, result) --SMITHING.refinementPanel or SMITHING.deconstructionPanel
        end,
    }
}

--enable LF_SMITHING_IMPROVEMENT/LF_JEWELRY_IMPROVEMENT smithing/jewelry
--> See \esoui\ingame\crafting\smithingimprovement_shared.lua
helpers["ZO_SharedSmithingImprovement_DoesItemPassFilter"] = {
    version = 2,
    filterTypes = {
        [true] = {LF_SMITHING_IMPROVEMENT, LF_JEWELRY_IMPROVEMENT},
        [false]={LF_SMITHING_IMPROVEMENT, LF_JEWELRY_IMPROVEMENT}
    },
    locations = {
        [1] = _G
    },
    helper = {
        funcName = "ZO_SharedSmithingImprovement_DoesItemPassFilter",
        func = function(bagId, slotIndex, filterType)
			local result = doesImprovementItemPassFilterOriginal(bagId, slotIndex, filterType)
            --Original result was determined, so add the LibFilters filterFunctions now
			return checkAndRundAdditionalFiltersBag(smithing.improvementPanel, bagId, slotIndex, result) -- SMITHING.improvementPanel
        end,
    }
}


--  enable LF_SMITHING_DECONSTRUCT/LF_JEWELRY_DECONSTRUCT/LF_ENCHANTING_EXTRACT smithing/jewelry/enchanting extract at the Universal Deconstruction NPC
--> See \esoui\ingame\crafting\universaldeconstructionpanel_shared.lua
helpers["ZO_UniversalDeconstructionPanel_Shared.DoesItemPassFilter"] = {
    version = 1,
    filterTypes = {
        [true] = {LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT, LF_ENCHANTING_EXTRACTION},
        [false]= {LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT, LF_ENCHANTING_EXTRACTION}
    },
    locations = {
        [1] = ZO_UniversalDeconstructionPanel_Shared,
    },
    helper = {
        funcName = "DoesItemPassFilter",
        func = function(bagId, slotIndex, filterType)
            local result = doesUniversalDeconstructionItemPassFilterOriginal(bagId, slotIndex, filterType)
            if not result then return result end

            --> See LibFilters-3.0.lua, function "applyFixesEarly":
            --> Register a callback to the keyboard and gamepad universal decon filters (dropdown, tab, other) change
            --> UNIVERSAL_DECONSTRUCTION.deconstructionPanel:RegisterCallback("OnFilterChanged", TestOnFilterChanged)
            --> UNIVERSAL_DECONSTRUCTION_GAMEPAD.deconstructionPanel:RegisterCallback("OnFilterChanged", TestOnFilterChanged)
            --> At the callback check for the active tab via UNIVERSAL_DECONSTRUCTION.deconstructionPanel.inventory:GetCurrentFilter() which returns
            --> the filter table, where table.key will be the key string e.g. "all"/"enchantments" etc.
            --> Map this filterType key to the LibFilters LF_* filterType constant then via table mapping.universalDeconTabKeyToLibFiltersFilterType
            local universalDeconPanel = (iigpm() and universalDeconstructPanel_GP) or universalDeconstructPanel
            local universalDeconPanelInv = universalDeconPanel.inventory

            local currentFilter = universalDeconPanelInv:GetCurrentFilter()
            detectUniversalDeconstructionPanelActiveTab = detectUniversalDeconstructionPanelActiveTab or libFilters.DetectUniversalDeconstructionPanelActiveTab
            local libFiltersFilterType                  = detectUniversalDeconstructionPanelActiveTab(filterType, currentFilter.key)
            if libFiltersFilterType ~= nil then
                --Get the variable where the .additionalFilter function is stored via the filterType
                -->!!!Re-uses existing deconstruction or enchanting references as there does not exist any LF_UNIVERSAL_DECONSTRUCTION constant!!!
                local base = filterTypeToFilterBase[libFiltersFilterType]
                if base then
                    return checkAndRundAdditionalFiltersBag(base, bagId, slotIndex, result)
                end
            end
            return result
        end,
    }
}
------------------------------------------------------------------------------------------------------------------------
 -- -^- KEYBOARD and GAMEPAD - shared helpers
------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------
 -- -v- GAMEPAD ONLY helpers
------------------------------------------------------------------------------------------------------------------------

--enable LF_VENDOR_BUY for gamepad mode
--Calling local function GetBuyItems(searchContext)
--> See \esoui\ingame\storewindow\gamepad\storewindow_gamepad_util.lua
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY].list:updateFunc"] = {
    version = 2,
    filterTypes = {
        [true] = {LF_VENDOR_BUY},
        [false]={}
    },
    locations = {
        [1] = storeWindowComponents_GP[ZO_MODE_STORE_BUY].list,
    },
    helper = {
        funcName = "updateFunc",
        func = function(searchContext)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY].list:updateFunc', searchContext)

		    -- original function GetBuyItems(searchContext)
			local items = ZO_StoreManager_GetStoreItems()
			--- Gamepad versions have extra data / differently named values in templates  < ZOs
			local buyItems = {}                                             --Added by LibFilters
			for _, itemData in ipairs(items) do
			-- Add LibFilters filter function
				if checkAndRundAdditionalFilters(vendorBuy_GP, itemData, nil) == true then    --Added by LibFilters
					itemData.pressedIcon = itemData.icon
					itemData.stackCount = itemData.stack
					itemData.sellPrice = itemData.price
					if itemData.sellPrice == 0 then
						itemData.sellPrice = itemData.stackBuyPriceCurrency1
					end
					itemData.selectedNameColor = ZO_SELECTED_TEXT
					itemData.unselectedNameColor = ZO_DISABLED_TEXT

					itemData.itemLink = GetStoreItemLink(itemData.slotIndex)
					itemData.itemType = GetItemLinkItemType(itemData.itemLink)
					itemData.equipType = GetItemLinkEquipType(itemData.itemLink)

					itemData.storeGroup = GetItemStoreGroup(itemData)
					itemData.bestGamepadItemCategoryName = GetBestItemCategoryDescription(itemData)
					if not itemData.meetsRequirementsToBuy and ZO_StoreManager_DoesBuyStoreFailureLockEntry(itemData.buyStoreFailure) then
						itemData.locked = true
					end
					table.insert(buyItems, itemData)                        --Added by LibFilters
				end
			end
			return buyItems                                                 --Changed by LibFilters
		end
    },
}


--enable LF_VENDOR_SELL for gamepad mode
--Calling local function GetSellItems(searchContext)
--> See \esoui\ingame\storewindow\gamepad\storewindow_gamepad_util.lua
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL].list:updateFunc"] = {
    version = 2,
    filterTypes = {
        [true] = {LF_VENDOR_SELL},
        [false]={}
    },
    locations = {
        [1] = storeWindowComponents_GP[ZO_MODE_STORE_SELL].list,
    },
    helper = {
        funcName = "updateFunc",
        func = function(searchContext)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL].list:updateFunc')
		    -- original function GetSellItems(searchContext)
			local items = SHINV:GenerateFullSlotData(nil, BAG_WORN, BAG_BACKPACK)
			local unequippedItems = {}
			--- Setup sort filter   < zos
			for _, itemData in ipairs(items) do
				if itemData.bagId ~= BAG_WORN and not itemData.stolen and not itemData.isPlayerLocked  and searchContext and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults(searchContext, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, itemData.bagId, itemData.slotIndex) then
                    if checkAndRundAdditionalFilters(vendorSell_GP, itemData, nil) == true then       --Added by LibFilters
                        itemData.isEquipped = false
                        itemData.meetsRequirementsToBuy = true
                        itemData.meetsRequirementsToEquip = itemData.meetsUsageRequirements
                        itemData.storeGroup = GetItemStoreGroup(itemData)
                        itemData.bestGamepadItemCategoryName = GetBestSellItemCategoryDescription(itemData)
                        itemData.customSortOrder = itemData.sellInformationSortOrder
                        table.insert(unequippedItems, itemData)
                    end                                                                             --Added by LibFilters
				end
			end
			return unequippedItems
		end
    },
}

--enable LF_VENDOR_BUYBACK for gamepad mode
--Calling local function GetBuybackItems(searchContext)
--> See \esoui\ingame\storewindow\gamepad\storewindow_gamepad_util.lua
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY_BACK].list:updateFunc"] = {
    version = 2,
    filterTypes = {
        [true] = {LF_VENDOR_BUYBACK},
        [false]={}
    },
    locations = {
        [1] = storeWindowComponents_GP[ZO_MODE_STORE_BUY_BACK].list,
    },
    helper = {
        funcName = "updateFunc",
        func = function(searchContext)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY_BACK].list:updateFunc', searchContext)
		-- original function GetBuybackItems(searchContext)
			local items = {}
			for entryIndex = 1, GetNumBuybackItems() do
				if searchContext and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults(searchContext, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, BAG_BUYBACK, entryIndex) then
					local icon, name, stackCount, price, functionalQuality, meetsRequirementsToEquip, displayQuality = GetBuybackItemInfo(entryIndex)
					if stackCount > 0 then
						local itemLink = GetBuybackItemLink(entryIndex)
						local itemType = GetItemLinkItemType(itemLink)
						local equipType = GetItemLinkEquipType(itemLink)
						local traitInformation = GetItemTraitInformationFromItemLink(itemLink)
						local sellInformation = GetItemLinkSellInformation(itemLink)
						local totalPrice = price * stackCount
						local buybackData =
						{
							slotIndex = entryIndex,
							icon = icon,
							name = zo_strformat(SI_TOOLTIP_ITEM_NAME, name),
							stackCount = stackCount,
							price = price,
							sellPrice = totalPrice,
							functionalQuality = functionalQuality,
							displayQuality = displayQuality,
							-- self.quality is deprecated, included here for addon backwards compatibility
							quality = displayQuality,
							meetsRequirementsToBuy = true,
							meetsRequirementsToEquip = meetsRequirementsToEquip,
							stackBuyPrice = totalPrice,
							itemLink = itemLink,
							itemType = itemType,
							equipType = equipType,
							filterData = { GetItemLinkFilterTypeInfo(itemLink) },
							traitInformation = traitInformation,
							itemTrait = GetItemLinkTraitInfo(itemLink),
							traitInformationSortOrder = ZO_GetItemTraitInformation_SortOrder(traitInformation),
							sellInformation = sellInformation,
							sellInformationSortOrder = ZO_GetItemSellInformationCustomSortOrder(sellInformation),
						}
						buybackData.storeGroup = GetItemStoreGroup(buybackData)
						buybackData.bestGamepadItemCategoryName = GetBestItemCategoryDescription(buybackData)

                        --Original result was true, so add the LibFilters filterFunctions now
						if checkAndRundAdditionalFilters(vendorBuyBack_GP, buybackData, true) == true then
							table.insert(items, buybackData)
						end
					end
				end
			end
			return items
		end
    },
}

--enable LF_VENDOR_REPAIR for gamepad mode
--Calling local function GetRepairItems(searchContext)
--> See \esoui\ingame\storewindow\gamepad\storewindow_gamepad_util.lua
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_REPAIR].list:updateFunc"] = {
    version = 2,
    filterTypes = {
        [true] = {LF_VENDOR_REPAIR},
        [false]={}
    },
    locations = {
        [1] = storeWindowComponents_GP[ZO_MODE_STORE_REPAIR].list,
    },
    helper = {
        funcName = "updateFunc",
        func = function(searchContext)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_REPAIR].list:updateFunc', searchContext)
			local items = {}
			GatherDamagedEquipmentFromBag_Gamepad(searchContext, BAG_WORN, items)
			GatherDamagedEquipmentFromBag_Gamepad(searchContext, BAG_BACKPACK, items)
			return items
		end
    },
}


--enable LF_FENCE_SELL for gamepad mode
--Calling local function GetStolenSellItems(searchContext)
--> See \esoui\ingame\storewindow\gamepad\storewindow_gamepad_util.lua
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL_STOLEN].list:updateFunc"] = { -- not tested
    version = 2,
    filterTypes = {
        [true] = {LF_FENCE_SELL},
        [false]={}
    },
    locations = {
        [1] = storeWindowComponents_GP[ZO_MODE_STORE_SELL_STOLEN].list,
    },
    helper = {
        funcName = "updateFunc",
        func = function(searchContext)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL_STOLEN].list:updateFunc')
			local function TextSearchFilterFunction(itemData)
				local result = IsStolenItemSellable(itemData) and searchContext and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults(searchContext, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, itemData.bagId, itemData.slotIndex)
                --Original result was determined, so add the LibFilters filterFunctions now
                return checkAndRundAdditionalFilters(fenceSell_GP, itemData, result)
			end
			-- can't sell stolen things from BAG_WORN so just check BACKPACK
			return GetStolenItems(TextSearchFilterFunction, BAG_BACKPACK)
		end
    },
}


--enable LF_FENCE_LAUNDER for gamepad mode
--Calling local function GetLaunderItems(searchContext)
--> See \esoui\ingame\storewindow\gamepad\storewindow_gamepad_util.lua
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_LAUNDER].list:updateFunc"] = { -- not tested
    version = 2,
    filterTypes = {
        [true] = {LF_FENCE_LAUNDER},
        [false]={}
    },
    locations = {
        [1] = storeWindowComponents_GP[ZO_MODE_STORE_LAUNDER].list,
    },
    helper = {
        funcName = "updateFunc",
        func = function(searchContext)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_LAUNDER].list:updateFunc')
			local function TextSearchFilterFunction(itemData)
                local result = searchContext and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults(searchContext, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, itemData.bagId, itemData.slotIndex)
                --Original result was determined, so add the LibFilters filterFunctions now
				return checkAndRundAdditionalFilters(fenceLaunder_GP, itemData, result)
			end
			return GetStolenItems(TextSearchFilterFunction, BAG_WORN, BAG_BACKPACK)
		end
    },
}


--enable LF_INVENTORY_COMPANION for gamepad mode
--> See \esoui_src\live\esoui\ingame\companion\gamepad\companionequipment_gamepad.lua
helpers["COMPANION_EQUIPMENT_GAMEPAD:GetItemDataFilterComparator"] = { -- not tested
    version = 2,
    filterTypes = {
        [true] = {LF_INVENTORY_COMPANION},
        [false]={}
    },
    locations = {
        [1] = companionEquipment_GP,
    },
    helper = {
        funcName = "GetItemDataFilterComparator",
        func = function(self, filteredEquipSlot, nonEquipableFilterType)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_LAUNDER].list:updateFunc')
			return function(itemData)
                if itemData.actorCategory ~= GAMEPLAY_ACTOR_CATEGORY_COMPANION then
                    return false
                end
                if not self:IsSlotInSearchTextResults(itemData.bagId, itemData.slotIndex) then
                    return false
                end

                --Original result was true so far, so add the LibFilters filterFunctions now
                if not checkAndRundAdditionalFilters(self, itemData, true) then return false end

                if filteredEquipSlot then
                    return ZO_Character_DoesEquipSlotUseEquipType(filteredEquipSlot, itemData.equipType)
                end
            end
		end
    },
}


--enable LF_INVENTORY_QUEST for gamepad mode
--> See \esoui\ingame\inventory\gamepad\gamepadinventory.lua
helpers["GAMEPAD_INVENTORY:GetQuestItemDataFilterComparator"] = { -- not tested
    version = 2,
    filterTypes = {
        [true] = {LF_INVENTORY_QUEST},
        [false]={}
    },
    locations = {
        [1] = invBackpack_GP,
    },
    helper = {
        funcName = "GetQuestItemDataFilterComparator",
        func = function(self, questItemId)
            --d( 'GAMEPAD_INVENTORY:GetQuestItemDataFilterComparator')
            local slotData = {bagId = ZO_QUEST_ITEMS_FILTER_BAG, slotIndex = questItemId}
            --Original result was true so far, so add the LibFilters filterFunctions now
            if not checkAndRundAdditionalFilters(self.scene, slotData, true) then return false end

            return self:IsSlotInSearchTextResults(ZO_QUEST_ITEMS_FILTER_BAG, questItemId)
        end
    },
}


--enable LF_INVENTORY for gamepad mode
--> See \esoui\ingame\inventory\gamepad\gamepadinventory.lua
helpers["GAMEPAD_INVENTORY:GetItemDataFilterComparator"] = { -- not tested
    version = 2,
    filterTypes = {
        [true] = {LF_INVENTORY},
        [false]={}
    },
    locations = {
        [1] = invBackpack_GP,
    },
    helper = {
        funcName = "GetItemDataFilterComparator",
        func = function(self, filteredEquipSlot, nonEquipableFilterType)
--d( 'GAMEPAD_INVENTORY:GetItemDataFilterComparator')
            return function(itemData)
                if not self:IsSlotInSearchTextResults(itemData.bagId, itemData.slotIndex) then
                    return false
                end

                --Original result was true so far, so add the LibFilters filterFunctions now
				if not checkAndRundAdditionalFilters(bagIdToInventory[BAG_BACKPACK], itemData, true) then return false end

                if itemData.actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
                    return nonEquipableFilterType == ITEMFILTERTYPE_COMPANION
                end

                if filteredEquipSlot then
                    return ZO_Character_DoesEquipSlotUseEquipType(filteredEquipSlot, itemData.equipType)
                end

                if nonEquipableFilterType then
                    return ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, nonEquipableFilterType)
                end

                return ZO_InventoryUtils_DoesNewItemMatchSupplies(itemData)
            end
		end
    },
}

--enable LF_BANK_WITHDRAW/LF_BANK_DEPOSIT/LF_GUILDBANK_WITHDRAW/LF_GUILDBANK_DEPOSIT/LF_TRADE
--LF_GUILDSTORE_SELL/LF_HOUSE_BANK_WITHDRAW/LF_HOUSE_BANK_DEPOSIT/LF_CRAFTBAG/LF_MAIL_SEND for gamepad mode
--> See \esoui\ingame\inventory\gamepad\inventorylist_gamepad.lua
helpers["ZO_GamepadInventoryList:AddSlotDataToTable"] = {
    version = 2,
    filterTypes = {
        [true] = {
            LF_BANK_WITHDRAW, LF_BANK_DEPOSIT,
            LF_BANK_DEPOSIT, LF_GUILDBANK_DEPOSIT,
            LF_HOUSEBANK_WITHDRAW, LF_HOUSEBANK_DEPOSIT,
            LF_GUILDSTORE_SELL,
            LF_CRAFTBAG,
            LF_TRADE, LF_MAIL_SEND,
        },
        [false]={}
    },
    locations = {
        [1] = ZO_GamepadInventoryList,
    },
    helper = {
        funcName = "AddSlotDataToTable",
        func = function(self, slotsTable, inventoryType, slotIndex)
--d( 'ZO_GamepadInventoryList:AddSlotDataToTable')
            local itemFilterFunction = self.itemFilterFunction
            local categorizationFunction = self.categorizationFunction or ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription
            local slotData = SHINV:GenerateSingleSlotData(inventoryType, slotIndex)
            if slotData then
                local result = (not itemFilterFunction and true) or itemFilterFunction(slotData)
                --Original result was determined, so add the LibFilters filterFunctions now
                if checkAndRundAdditionalFilters(bagIdToInventory[inventoryType], slotData, result) == true then
                    -- itemData is shared in several places and can write their own value of bestItemCategoryName.
                    -- We'll use bestGamepadItemCategoryName instead so there are no conflicts.
                    slotData.bestGamepadItemCategoryName = categorizationFunction(slotData)

                    table.insert(slotsTable, slotData)
                end
            end

		end
    },
}

------------------------------------------------------------------------------------------------------------------------
 -- -^- GAMEPAD ONLY helpers
------------------------------------------------------------------------------------------------------------------------



------------------------------------------------------------------------------------------------------------------------
--Copy helpers into global LibFilters3.helpers
-->LibFilters3.helpers will be set to nil again within LibFilter3.lua at EVENT_ADD_ON_LOADED
for name, package in pairs(helpers) do
    if libFilters.helpers[name] == nil then
        libFilters.helpers[name] = package
    elseif libFilters.helpers[name].version < package.version then
        libFilters.helpers[name] = package
    end
end
helpers = nil

if libFilters.debug then dd("LIBRARY HELPER FILE - END") end
