local LibFilters = LibFilters3

local SM = SCENE_MANAGER
local helpers = {}

local enchantingModeToFilterType = LibFilters3.enchantingModeToFilterType
local LF_ConstantToAdditionalFilterControlSceneFragmentUserdata = LibFilters3.LF_ConstantToAdditionalFilterControlSceneFragmentUserdata

local getCurrentFilterTypeForInventory = LibFilters3.GetCurrentFilterTypeForInventory

local function doesAdditionalFilterFuncExist(objectVar)
    return (objectVar and objectVar.additionalFilter and type(objectVar.additionalFilter) == "function") or false
end

--Check for .additionalFilter in an object and run it on the slotItem now
local function checkAndRundAdditionalFilters(objectVar, slotItem, resultIfNoAdditionalFilter)
    resultIfNoAdditionalFilter = resultIfNoAdditionalFilter or false
    if doesAdditionalFilterFuncExist(objectVar) then
        return resultIfNoAdditionalFilter and objectVar.additionalFilter(slotItem)
    end
    return resultIfNoAdditionalFilter
end

--Check for .additionalFilter in an object and run it on the bagId and slotIndex now
local function checkAndRundAdditionalFiltersBag(objectVar, bagId, slotIndex, resultIfNoAdditionalFilter)
    resultIfNoAdditionalFilter = resultIfNoAdditionalFilter or false
    if doesAdditionalFilterFuncExist(objectVar) then
        return resultIfNoAdditionalFilter and objectVar.additionalFilter(bagId, slotIndex)
    end
    return resultIfNoAdditionalFilter
end


--Original function at:
--smithingresearch_shared.lua
--[[
    local function DoesNotBlockResearch(bagId, slotIndex)
        return not IsItemPlayerLocked(bagId, slotIndex) and GetItemTraitInformation(bagId, slotIndex) ~= ITEM_TRAIT_INFORMATION_RETRAITED and GetItemTraitInformation(bagId, slotIndex) ~= ITEM_TRAIT_INFORMATION_RECONSTRUCTED
    end
]]
-->Used for LF_SMITHING_RESEARCH, LF_JEWELRY_RESEARCH, LF_SMITHING_RESEARCH_DIALOG, LF_JEWELRY_RESEARCH_DIALOG
-->
local function DoesNotBlockResearch(bagId, slotIndex)
    local disallowedItemTraits = {
        [ITEM_TRAIT_INFORMATION_RETRAITED] = true,
        [ITEM_TRAIT_INFORMATION_RECONSTRUCTED] = true,
    }
    return not IsItemPlayerLocked(bagId, slotIndex) and not disallowedItemTraits[GetItemTraitInformation(bagId, slotIndex)]
end


------------------------------------------------------------------------------------------------------------------------
 -- -v- KEYBOARD ONLY
---------------------------------------------------------------------------------------------------------------------------
--enable LF_VENDOR_BUY
helpers["STORE_WINDOW:ShouldAddItemToList"] = {
    version = 2,
    locations = {
        [1] = STORE_WINDOW,
    },
    helper = {
        funcName = "ShouldAddItemToList",
        func = function(self, itemData)
            local result = true

            result = checkAndRundAdditionalFilters(self, itemData, result)

            if self.currentFilter == ITEMFILTERTYPE_ALL then
                return result and true
            end

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
helpers["BUY_BACK_WINDOW:UpdateList"] = {
    version = 2,
    locations = {
        [1] = BUY_BACK_WINDOW,
    },
    helper = {
        funcName = "UpdateList",
        func = function(self)
            if not self.control:IsControlHidden() then
                local DATA_TYPE_BUY_BACK_ITEM = 1
                ZO_ScrollList_Clear(self.list)
                ZO_ScrollList_ResetToTop(self.list)

                local scrollData = ZO_ScrollList_GetDataList(self.list)

                for entryIndex = 1, GetNumBuybackItems() do
                    if not TEXT_SEARCH_MANAGER or
                        (TEXT_SEARCH_MANAGER and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("storeTextSearch", BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, BAG_BUYBACK, entryIndex)) then
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
                            local result = true

                            result = checkAndRundAdditionalFilters(self, buybackData, result)

                            if result then
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
local DATA_TYPE_REPAIR_ITEM = 1
helpers["REPAIR_WINDOW:UpdateList"] = {
    version = 3,
    locations = {
        [1] = REPAIR_WINDOW,
    },
    helper = {
        funcName = "UpdateList",
        func = function(self)

            local function GatherDamagedEquipmentFromBag(bagId, dataTable)
                for slotIndex in ZO_IterateBagSlots(bagId) do
                    if not TEXT_SEARCH_MANAGER or
                        (TEXT_SEARCH_MANAGER and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("storeTextSearch", BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, bagId, slotIndex)) then
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
                                    local result = true

                                    result = checkAndRundAdditionalFilters(REPAIR_WINDOW, data, result)

                                    if result then
                                        dataTable[#dataTable + 1] = ZO_ScrollList_CreateDataEntry(DATA_TYPE_REPAIR_ITEM, data)
                                    end
                                end
                            end
                        end
                    end
                end
            end

            ZO_ScrollList_Clear(self.list)
            ZO_ScrollList_ResetToTop(self.list)

            local scrollData = ZO_ScrollList_GetDataList(self.list)

            GatherDamagedEquipmentFromBag(BAG_WORN, scrollData)
            GatherDamagedEquipmentFromBag(BAG_BACKPACK, scrollData)

            self:ApplySort()
        end,
    },
}

--enable LF_ALCHEMY_CREATION, LF_ENCHANTING_CREATION, LF_ENCHANTING_EXTRACTION,
--  LF_SMITHING_REFINE, LF_JEWELRY_REFINE for keyboard mode
helpers["ALCHEMY_ENCHANTING_SMITHING_Inventory:EnumerateInventorySlotsAndAddToScrollData"] = {
    version = 5,
    locations = {
        [1] = ZO_AlchemyInventory,
        [2] = ZO_EnchantingInventory,
        [3] = ZO_SmithingExtractionInventory,
    },
    helper = {
        funcName = "EnumerateInventorySlotsAndAddToScrollData",
        func = function(self, predicate, filterFunction, filterType, data)
            local libFilters3FilterType = getCurrentFilterTypeForInventory(LibFilters3, self)
            local isAlchemy     = libFilters3FilterType == LF_ALCHEMY_CREATION
            local isEnchanting  = libFilters3FilterType == LF_ENCHANTING_CREATION
            local isSmithing    = (libFilters3FilterType == LF_SMITHING_REFINE or libFilters3FilterType == LF_JEWELRY_REFINE)
--d(string.format("[LF3]libFilters3FilterType: %s, isAlchemy: %s, isEnchanting: %s, isSmithing: %s", tostring(libFilters3FilterType), tostring(isAlchemy), tostring(isEnchanting), tostring(isSmithing)))

            local oldPredicate = predicate
            predicate = function(bagId, slotIndex)
                local result = true

                result = checkAndRundAdditionalFiltersBag(self, bagId, slotIndex, result)

                return oldPredicate(bagId, slotIndex) and result
            end

            -- Begin original function

            local list = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, predicate)
            PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BANK, predicate, list)
            PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_CRAFT_BAG, predicate, list)

            ZO_ClearTable(self.itemCounts)

            local questSV, questItems
            if isEnchanting == true then
                questSV = self.savedVars.questsOnlyChecked
                questItems = self.questRunes
            elseif isAlchemy == true then
                self.owner:UpdatePotentialQuestItems(list, self.alchemyQuestInfo)

                questSV = self.savedVars.questsOnlyChecked
                questItems = self.owner.questItems
            elseif isSmithing == true then
                questSV = nil
                questItems = nil
            end

            for itemId, itemInfo in pairs(list) do
                if not filterFunction or filterFunction(itemInfo.bag, itemInfo.index, filterType, questSV, questItems) then
                    self:AddItemData(itemInfo.bag, itemInfo.index, itemInfo.stack, self:GetScrollDataType(itemInfo.bag, itemInfo.index), data, self.customDataGetFunction)
                end
                self.itemCounts[itemId] = itemInfo.stack
            end

            return list
        end,
    },
}

--enable LF_SMITHING_DECONSTRUCT, LF_SMITHING_IMPROVEMENT
helpers["SMITHING_Extraction/Improvement_Inventory:GetIndividualInventorySlotsAndAddToScrollData"] = {
    version = 3,
    locations = {
        [1] = ZO_SmithingExtractionInventory,
        [2] = ZO_SmithingImprovementInventory,
    },
    helper = {
        funcName = "GetIndividualInventorySlotsAndAddToScrollData",
        func = function(self, predicate, filterFunction, filterType, data, useWornBag, excludeBankedItems)
            local oldPredicate = predicate
            predicate = function(itemData)
                local result = true

                result = checkAndRundAdditionalFiltersBag(self, itemData.bagId, itemData.slotIndex, result)

                return oldPredicate(itemData) and result
            end

            -- Begin original function ZO_CraftingInventory:GetIndividualInventorySlotsAndAddToScrollData
            --local bagsToUse = useWornBag and ZO_ALL_CRAFTING_INVENTORY_BAGS_AND_WORN or ZO_ALL_CRAFTING_INVENTORY_BAGS_WITHOUT_WORN
            local bagsToUse = { BAG_BACKPACK }
            if useWornBag then
                table.insert(bagsToUse, BAG_WORN)
            end
            -- Expressly using double-negative here to maintain compatibility
            if not excludeBankedItems then
                table.insert(bagsToUse, BAG_BANK)
                table.insert(bagsToUse, BAG_SUBSCRIBER_BANK)
            end
            local filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(predicate, unpack(bagsToUse))

            ZO_ClearTable(self.itemCounts)

            for i, slotData in pairs(filteredDataTable) do
                if not filterFunction or filterFunction(slotData.bagId, slotData.slotIndex, filterType) then
                    self:AddItemData(
                            slotData.bagId,
                            slotData.slotIndex,
                            slotData.stackCount,
                            self:GetScrollDataType(slotData.bagId, slotData.slotIndex),
                            data,
                            self.customDataGetFunction,
                            slotData
                    )
                end
                self.itemCounts[i] = slotData.stackCount
            end

            return filteredDataTable
        end,
    },
}

--[[
--enable LF_SMITHING_RESEARCH_DIALOG -- since API 100025 Murkmire
helpers["SMITHING_RESEARCH_SELECT:SetupDialog"] = {
    version = 2,
    locations = {
        [1] = SMITHING_RESEARCH_SELECT,
    },
    helper = {
        funcName = "SetupDialog",
        func = function(self, craftingType, researchLineIndex, traitIndex)
            --Overwrite the local function "IsResearchableItem" of file /esoui/ingame/crafting/keyboard/smithingresearch_keyboard.lua
            --inside function ZO_SmithingResearchSelect:SetupDialog
            local function IsResearchableItem(bagId, slotIndex)
                local result = ZO_SharedSmithingResearch.IsResearchableItem(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
                --Is the item researchable? Then check if additional filters are registered
                if result then
                    if self.additionalFilter and type(self.additionalFilter) == "function" then
                        result = result and self.additionalFilter(bagId, slotIndex)
                    end
                end
                return result
            end -- function IsResearchableItem(bagId, slotIndex)

            --======== Source code of original function =======================
            local listDialog = ZO_InventorySlot_GetItemListDialog()

            local _, _, _, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
            local formattedTime = ZO_FormatTime(timeRequiredForNextResearchSecs, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)

            listDialog:SetAboveText(GetString(SI_SMITHING_RESEARCH_DIALOG_SELECT))
            listDialog:SetBelowText(zo_strformat(SI_SMITHING_RESEARCH_DIALOG_CONSUME, formattedTime))
            listDialog:SetEmptyListText("")

            listDialog:ClearList()

            --Overwritten original function to filter items with additional filters/filter functions
            --local function IsResearchableItem(bagId, slotIndex)
            --    return ZO_SharedSmithingResearch.IsResearchableItem(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
            --end

            local virtualInventoryList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, IsResearchableItem)
            PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BANK, IsResearchableItem, virtualInventoryList)

            for itemId, itemInfo in pairs(virtualInventoryList) do
                itemInfo.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(itemInfo.bag, itemInfo.index))
                listDialog:AddListItem(itemInfo)
            end

            --Added local function from file /esoui/ingame/crafting/keyboard/smithingresearch_keyboard.lua
            local function SortComparator(left, right)
                return left.data.name < right.data.name
            end

            listDialog:CommitList(SortComparator)

            listDialog:AddCustomControl(self.control, LIST_DIALOG_CUSTOM_CONTROL_LOCATION_BOTTOM)
        end -- SMITHING_RESEARCH_SELECT.SetupDialog
    },
}
]]


--enable LF_QUICKSLOT
-->Will only be executed for normal inventory items but NOT for the collectible items in the quickslot filters
helpers["QUICKSLOT_WINDOW:ShouldAddItemToList"] = {
    version = 3,
    locations = {
        [1] = QUICKSLOT_WINDOW,
    },
    helper = {
        funcName = "ShouldAddItemToList",
        func = function(self, itemData)
            local result = ZO_IsElementInNumericallyIndexedTable(itemData.filterData, ITEMFILTERTYPE_QUICKSLOT) and
                (
                        (self.IsItemInTextSearch and self:IsItemInTextSearch(itemData))
                          or (TEXT_SEARCH_MANAGER and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("quickslotTextSearch", BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, itemData.bagId, itemData.slotIndex))
                )

            result = checkAndRundAdditionalFilters(self, itemData, result)

            return result
        end,
    },
}


-->Will only be executed for quest related inventory items but NOT for the normal inventory or collectible items in the quickslot filters
helpers["QUICKSLOT_WINDOW:ShouldAddQuestItemToList"] = {
    version = 2,
    locations = {
        [1] = QUICKSLOT_WINDOW,
    },
    helper = {
        funcName = "ShouldAddQuestItemToList",
        func = function(self, questItemData)

            local result = ZO_IsElementInNumericallyIndexedTable(questItemData.filterData, ITEMFILTERTYPE_QUEST_QUICKSLOT) and
                (
                        (self.IsItemInTextSearch and self:IsItemInTextSearch(questItemData))
                    or (TEXT_SEARCH_MANAGER and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("quickslotTextSearch", BACKGROUND_LIST_FILTER_TARGET_QUEST_ITEM_ID, questItemData.questItemId))
                )

            result = checkAndRundAdditionalFilters(self, questItemData, result)

            return result
        end,
    },
}

-->Will only be executed for the collectible items in the quickslot filters, but no inventory items
local DATA_TYPE_COLLECTIBLE_ITEM = 2
helpers["QUICKSLOT_WINDOW:AppendCollectiblesData"] = {
    version = 2,
    locations = {
        [1] = QUICKSLOT_WINDOW,
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
                libFiltersQuickslotCollectiblesFilterFunc = self.additionalFilter
            end
            for i, collectibleData in ipairs(dataObjects) do
                collectibleData.searchData =
                {
                    type = ZO_TEXT_SEARCH_TYPE_COLLECTIBLE,
                    collectibleId = collectibleData.collectibleId,
                }

                local result = (not libFiltersQuickslotCollectiblesFilterFunc and true) or (libFiltersQuickslotCollectiblesFilterFunc and libFiltersQuickslotCollectiblesFilterFunc(collectibleData))

                if TEXT_SEARCH_MANAGER then
                    if TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("quickslotTextSearch", BACKGROUND_LIST_FILTER_TARGET_COLLECTIBLE_ID, collectibleData.collectibleId) then
                        if result == true then
                            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_TYPE_COLLECTIBLE_ITEM, collectibleData))
                        end
                    end
                else
                    self.quickSlotSearch.Insert(collectibleData.searchData)
                    if self:IsItemInTextSearch(collectibleData) and result == true then
                        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_TYPE_COLLECTIBLE_ITEM, collectibleData))
                    end
                end
            end
        end,
    },
}


--enable LF_RETRAIT
helpers["ZO_RetraitStation_CanItemBeRetraited"] = {
    version = 2,
    locations = {
        [1] = _G
    },
    helper = {
        funcName = "ZO_RetraitStation_CanItemBeRetraited",
        func = function(itemData)
            local base = ZO_RETRAIT_KEYBOARD
            local result = CanItemBeRetraited(itemData.bagId, itemData.slotIndex)

            result = checkAndRundAdditionalFiltersBag(base, itemData.bagId, itemData.slotIndex, result)

            return result
        end,
    }
}
------------------------------------------------------------------------------------------------------------------------
 -- -^- KEYBOARD ONLY
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
 -- -v- KEYBOARD and GAMEPAD - shared
------------------------------------------------------------------------------------------------------------------------
--enable LF_SMITHING_RESEARCH -- since API 100023 Summerset
helpers["SMITHING.researchPanel:Refresh"] = {
    version = 6,
    locations = {
        [1] = SMITHING.researchPanel,
        [2] = SMITHING_GAMEPAD.researchPanel, --Added with API 101032 The Deadlands 2021-10-06
    },
    helper = {
        funcName = "Refresh",
        func = function(self)

--d("[LibFilters3]SMITHING / Gamepad SMITHING:Refresh()")
            -- Our filter function to insert LibFilter rules
            local function predicate(bagId, slotIndex)
                local result = DoesNotBlockResearch(bagId, slotIndex)
                result = checkAndRundAdditionalFiltersBag(self, bagId, slotIndex, result)
                return result
            end

            -- Begin original function, ZO_SharedSmithingResearch:Refresh()
            self.dirty = false

            self.researchLineList:Clear()
            local craftingType = GetCraftingInteractionType()

            local numCurrentlyResearching = 0

            local virtualInventoryList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, predicate) --IsNotLockedOrRetraitedItem
            if self.savedVars.includeBankedItemsChecked then
                PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BANK, predicate, virtualInventoryList) -- IsNotLockedOrRetraitedItem, virtualInventoryList
            end

            --Get the from, to and skipTable values for the research Line index loop below in order to filter the research line horizontal scroll list
            --and only show some of the entries
            local smithingResearchPanel = self
            local fromIterator
            local toIterator
            local skipTable
            if smithingResearchPanel and smithingResearchPanel.LibFilters_3ResearchLineLoopValues then
                local customLoopData = smithingResearchPanel.LibFilters_3ResearchLineLoopValues
                fromIterator = customLoopData.from
                toIterator =  customLoopData.to
                skipTable = customLoopData.skipTable
            end
            if fromIterator == nil then
                fromIterator = 1
            end
            if toIterator == nil then
                toIterator = GetNumSmithingResearchLines(craftingType)
            end
            for researchLineIndex = fromIterator, toIterator do
                if not skipTable or (skipTable and skipTable[researchLineIndex] == nil) then
                    local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
                    if numTraits > 0 then
                        local researchingTraitIndex, areAllTraitsKnown = self:FindResearchingTraitIndex(craftingType, researchLineIndex, numTraits)
                        if researchingTraitIndex then
                            numCurrentlyResearching = numCurrentlyResearching + 1
                        end

                        local expectedTypeFilter = ZO_CraftingUtils_GetSmithingFilterFromTrait(GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, 1))
                        if expectedTypeFilter == self.typeFilter then
                            local itemTraitCounts = self:GenerateResearchTraitCounts(virtualInventoryList, craftingType, researchLineIndex, numTraits)
                            local data = { craftingType = craftingType, researchLineIndex = researchLineIndex, name = name, icon = icon, numTraits = numTraits, timeRequiredForNextResearchSecs = timeRequiredForNextResearchSecs, researchingTraitIndex = researchingTraitIndex, areAllTraitsKnown = areAllTraitsKnown, itemTraitCounts = itemTraitCounts }
                            self.researchLineList:AddEntry(data)
                        end
                    end
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

        end,
    },
 }

------------------------------------------------------------------------------------------------------------------------
 -- -^- KEYBOARD and GAMEPAD - shared
------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------
 -- -v- GAMEPAD ONLY
------------------------------------------------------------------------------------------------------------------------
-------------------
--locals for Vendor/Fence
-------------------
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
    local items = SHARED_INVENTORY:GenerateFullSlotData(IsStolenItem, ...)
    local unequippedItems = {}
    --- Setup sort filter
    for _, itemData in ipairs(items) do
        itemData.isEquipped = false
        itemData.meetsRequirementsToBuy = true
        itemData.meetsRequirementsToEquip = itemData.meetsUsageRequirements
        itemData.storeGroup = GetItemStoreGroup(itemData)
        itemData.bestGamepadItemCategoryName = GetBestItemCategoryDescription(itemData)
        table.insert(unequippedItems, itemData)
    end
    return unequippedItems
end
-------------------

--enable LF_VENDOR_BUY for gamepad mode
local gamepad_Store_Buy = STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY].list
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY].list:updateFunc"] = {
    version = 1,
    locations = {
        [1] = gamepad_Store_Buy,
    },
    helper = {
        funcName = "updateFunc",
        func = function(searchContext)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY].list:updateFunc', searchContext)
			-- added filter
			local function shouldAddItemToList(itemData)
                return checkAndRundAdditionalFilters(ZO_GamepadStoreBuy, itemData, nil)
			end
			
		-- original function
			local items = ZO_StoreManager_GetStoreItems()
			--- Gamepad versions have extra data / differently named values in templates  < zos
			local buyItems = {}
			for index, itemData in ipairs(items) do
			-- add filter
				if shouldAddItemToList(itemData) then
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
					table.insert(buyItems, itemData)
				end
			end
			return buyItems
		end
    },
}

--enable LF_VENDOR_SELL for gamepad mode
local gamepad_Store_Sell = STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL].list
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL].list:updateFunc"] = {
    version = 1,
    locations = {
        [1] = gamepad_Store_Sell,
    },
    helper = {
        funcName = "updateFunc",
        func = function(searchContext)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL].list:updateFunc')
			-- added filter
			local function shouldAddItemToList(itemData)
				local result = itemData.bagId ~= BAG_WORN and not itemData.stolen and not itemData.isPlayerLocked  and searchContext and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults(searchContext, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, itemData.bagId, itemData.slotIndex)
				if result then
                    result = checkAndRundAdditionalFilters(ZO_GamepadStoreSell, itemData, result)
				end
				return result
			end
			
			-- original function
			local items = SHARED_INVENTORY:GenerateFullSlotData(nil, BAG_WORN, BAG_BACKPACK)
			local unequippedItems = {}
			--- Setup sort filter   < zos
			for _, itemData in ipairs(items) do
			-- add filter
				if shouldAddItemToList(itemData) then
					itemData.isEquipped = false
					itemData.meetsRequirementsToBuy = true
					itemData.meetsRequirementsToEquip = itemData.meetsUsageRequirements
					itemData.storeGroup = GetItemStoreGroup(itemData)
					itemData.bestGamepadItemCategoryName = GetBestSellItemCategoryDescription(itemData)
					itemData.customSortOrder = itemData.sellInformationSortOrder
					table.insert(unequippedItems, itemData)
				end
			end
			return unequippedItems
		end
    },
}

--enable LF_VENDOR_BUYBACK for gamepad mode
local gamepad_Store_BuyBack = STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY_BACK].list
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY_BACK].list:updateFunc"] = {
    version = 1,
    locations = {
        [1] = gamepad_Store_BuyBack,
    },
    helper = {
        funcName = "updateFunc",
        func = function(searchContext)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY_BACK].list:updateFunc', searchContext)
		-- original function
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
						
						local result = true

                        result = checkAndRundAdditionalFilters(ZO_GamepadStoreBuyback, buybackData, result)

						if result then
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
local gamepad_Store_Repair = STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_REPAIR].list
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_REPAIR].list:updateFunc"] = {
    version = 1,
    locations = {
        [1] = gamepad_Store_Repair,
    },
    helper = {
        funcName = "updateFunc",
        func = function(searchContext)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_REPAIR].list:updateFunc', searchContext)
			local function GatherDamagedEquipmentFromBag(searchContext, bagId, itemTable)
				local bagSlots = GetBagSize(bagId)
				for slotIndex = 0, bagSlots - 1 do
					if searchContext and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults(searchContext, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, bagId, slotIndex) then
						local condition = GetItemCondition(bagId, slotIndex)
						if condition < 100 and not IsItemStolen(bagId, slotIndex) then
							local _, stackCount = GetItemInfo(bagId, slotIndex)
							if stackCount > 0 then
								local repairCost = GetItemRepairCost(bagId, slotIndex)
								if repairCost > 0 then
									local damagedItem = SHARED_INVENTORY:GenerateSingleSlotData(bagId, slotIndex)
									
									local result = true

                                    result = checkAndRundAdditionalFilters(ZO_GamepadStoreRepair, damagedItem, result)

									if result then
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
			
			local items = {}
			GatherDamagedEquipmentFromBag(searchContext, BAG_WORN, items)
			GatherDamagedEquipmentFromBag(searchContext, BAG_BACKPACK, items)
			return items
		end
    },
}

--enable LF_FENCE_SELL for gamepad mode
local gamepad_Fence_Sell = STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL_STOLEN].list
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL_STOLEN].list:updateFunc"] = { -- not tested
    version = 1,
    locations = {
        [1] = gamepad_Fence_Sell,
    },
    helper = {
        funcName = "updateFunc",
        func = function(searchContext)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL_STOLEN].list:updateFunc')
			local function TextSearchFilterFunction(itemData)
				local result = itemData.sellPrice > 0 and searchContext and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults(searchContext, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, itemData.bagId, itemData.slotIndex)

				if result then
                    result = checkAndRundAdditionalFilters(ZO_GamepadFenceSell, itemData, result)
				end
				return result
			end
			-- can't sell stolen things from BAG_WORN so just check BACKPACK
			return GetStolenItems(TextSearchFilterFunction, BAG_BACKPACK)
		end
    },
}

--enable LF_FENCE_LAUNDER for gamepad mode
local gamepad_Fence_Launder = STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_LAUNDER].list
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_LAUNDER].list:updateFunc"] = { -- not tested
    version = 1,
    locations = {
        [1] = gamepad_Fence_Launder,
    },
    helper = {
        funcName = "updateFunc",
        func = function(searchContext)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_LAUNDER].list:updateFunc')
			local function TextSearchFilterFunction(itemData)
				local result = searchContext and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults(searchContext, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, itemData.bagId, itemData.slotIndex)
				if result then
                    result = checkAndRundAdditionalFilters(ZO_GamepadFenceLaunder, itemData, result)
				end
				return result
			end
			return GetStolenItems(TextSearchFilterFunction, BAG_WORN, BAG_BACKPACK)
		end
    },
}


local function getAdditionalFilterObjectFromGamepadEnchantingScene(enchantingMode)
    local enchantingFilterType = enchantingModeToFilterType[enchantingMode]
    if not enchantingFilterType then return end
d(">>enchantingFilterType: " ..tostring(enchantingFilterType))
    local enchantingScene = LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[true][enchantingFilterType]
    if not enchantingScene then return end
d(">>enchantingScene: " ..tostring(enchantingScene.name))
    return enchantingScene
end
--enable LF_ALCHEMY_CREATION, LF_ENCHANTING_CREATION, LF_ENCHANTING_EXTRACTION,
--  LF_SMITHING_REFINE, LF_JEWELRY_REFINE for gamepad mode
helpers["GAMEPAD_ALCHEMY_ENCHANTING_SMITHING_Inventory:EnumerateInventorySlotsAndAddToScrollData"] = {
    version = 1,
    locations = {
		[1] = ZO_GamepadAlchemyInventory,
		[2] = ZO_GamepadEnchantingInventory,
        [3] = ZO_GamepadExtractionInventory,
    },
    helper = {
        funcName = "EnumerateInventorySlotsAndAddToScrollData",
        func = function(self, predicate, filterFunction, filterType, data)
            --self = GAMEPAD_ENCHANTING.inventory -> self.owner: GAMEPAD_ENCHANTING
LibFilters3._enchantingGamepadSelf = self
            --If we are at enchanting and the LibFilters filterType constant LF was not set via the scene callback yet
            local enchantingMode
            if self.owner == GAMEPAD_ENCHANTING and self.LibFilters3_filterType == nil then
                enchantingMode = self.owner:GetEnchantingMode()
                self.LibFilters3_filterType = enchantingModeToFilterType[enchantingMode]
            end

            local libFilters3FilterType = getCurrentFilterTypeForInventory(LibFilters3, self)
            local isAlchemy     = libFilters3FilterType == LF_ALCHEMY_CREATION
            local isEnchanting  = libFilters3FilterType == LF_ENCHANTING_CREATION
            local isSmithing    = (libFilters3FilterType == LF_SMITHING_REFINE or libFilters3FilterType == LF_JEWELRY_REFINE)
d(string.format("[LF3]GAMEPAD_ENCHANTING.inventory:EnumerateInventorySlotsAndAddToScrollData-libFilters3FilterType: %s, isAlchemy: %s, isEnchanting: %s, isSmithing: %s", tostring(libFilters3FilterType), tostring(isAlchemy), tostring(isEnchanting), tostring(isSmithing)))

            --Enchanting? Get the actual enchantingMode, and the enchanting gamepad scene
            local additionalFilterObject
            if isEnchanting == true or libFilters3FilterType == LF_ENCHANTING_EXTRACTION or self.owner.GetEnchantingMode then
                enchantingMode = enchantingMode or self.owner:GetEnchantingMode()
d(">enchantingMode: " .. tostring(enchantingMode))
                additionalFilterObject = getAdditionalFilterObjectFromGamepadEnchantingScene(enchantingMode)
            else
                additionalFilterObject = self
            end

            local oldPredicate = predicate
            predicate = function(bagId, slotIndex)
                local result = true
				result = checkAndRundAdditionalFiltersBag(additionalFilterObject, bagId, slotIndex, result)
                return result and oldPredicate(bagId, slotIndex)
            end

            -- Begin original function
            local list = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, predicate)
            PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BANK, predicate, list)
            PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_CRAFT_BAG, predicate, list)

            ZO_ClearTable(self.itemCounts)

            local questSV, questItems
            if isEnchanting == true then
                questSV = self.savedVars.shouldFilterQuests
                questItems = self.questRunes
            elseif isAlchemy == true then
                self.owner:UpdatePotentialQuestItems(list, self.alchemyQuestInfo)
                questSV = self.savedVars.shouldFilterQuests
                questItems = self.owner.questItems
            elseif isSmithing == true then
                questSV = nil
                questItems = nil
            end

			local filteredDataTable = {}
			for itemId, itemInfo in pairs(list) do
				if not filterFunction or filterFunction(itemInfo.bag, itemInfo.index, filterType, questSV, questItems) then
					filteredDataTable[#filteredDataTable + 1] = self:GenerateCraftingInventoryEntryData(itemInfo.bag, itemInfo.index, itemInfo.stack)
				end
				self.itemCounts[itemId] = itemInfo.stack
			end
			self:AddFilteredDataToList(filteredDataTable)
			return list
        end,
    },
}

--enable LF_SMITHING_DECONSTRUCT, LF_SMITHING_IMPROVEMENT for gamepad mode
helpers["GAMEPAD_SMITHING_Extraction/Improvement_Inventory:GetIndividualInventorySlotsAndAddToScrollData"] = {
    version = 1,
    locations = {
        [1] = ZO_GamepadExtractionInventory,
        [2] = ZO_GamepadImprovementInventory,
    },
    helper = {
        funcName = "GetIndividualInventorySlotsAndAddToScrollData",
        func = function(self, predicate, filterFunction, filterType, data, useWornBag, excludeBankedItems)
            local oldPredicate = predicate
            predicate = function(itemData)
                local result = true

                if self.additionalFilter and type(self.additionalFilter) == "function" then
                    result = self.additionalFilter(itemData.bagId, itemData.slotIndex)
                end

                return oldPredicate(itemData) and result
            end

            -- Begin original function ZO_CraftingInventory:GetIndividualInventorySlotsAndAddToScrollData
            --local bagsToUse = useWornBag and ZO_ALL_CRAFTING_INVENTORY_BAGS_AND_WORN or ZO_ALL_CRAFTING_INVENTORY_BAGS_WITHOUT_WORN
            local bagsToUse = { BAG_BACKPACK }
            if useWornBag then
                table.insert(bagsToUse, BAG_WORN)
            end
            -- Expressly using double-negative here to maintain compatibility
            if not excludeBankedItems then
                table.insert(bagsToUse, BAG_BANK)
                table.insert(bagsToUse, BAG_SUBSCRIBER_BANK)
            end
            local list = SHARED_INVENTORY:GenerateFullSlotData(predicate, unpack(bagsToUse))

            ZO_ClearTable(self.itemCounts)

			local filteredDataTable = {}
			for i, slotData in ipairs(list) do
				local bagId = slotData.bagId
				local slotIndex = slotData.slotIndex
				if not filterFunction or filterFunction(bagId, slotIndex, filterType) then
					filteredDataTable[#filteredDataTable + 1] = self:GenerateCraftingInventoryEntryData(bagId, slotIndex, slotData.stackCount, slotData)
				end
				self.itemCounts[i] = slotData.stackCount
			end
			self:AddFilteredDataToList(filteredDataTable)
			return list
        end,
    },
}

--enable LF_SMITHING_RESEARCH_DIALOG, LF_JEWELRY_RESEARCH_DIALOG for keyboard and gamepad mode --
local origZO_SharedSmithingResearch_IsResearchableItem = ZO_SharedSmithingResearch.IsResearchableItem
helpers["ZO_SharedSmithingResearch.IsResearchableItem"] = {
    version = 1,
    locations = {
        [1] = ZO_SharedSmithingResearch,
    },
    helper = {
        funcName = "IsResearchableItem",
        func = function(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
--d("ZO_SharedSmithingResearch.IsResearchableItem: " ..GetItemLink(bagId, slotIndex))
            --Do original filters
            local result = origZO_SharedSmithingResearch_IsResearchableItem(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)

            --If the gamepad research -> selected item for research scene is showing/shown
            local gamePadMode = IsInGamepadPreferredMode()
            if gamePadMode then
                local sceneStatesAllowed = {
                    [SCENE_SHOWING] = true,
                    [SCENE_SHOWN] = true,
                }
                local gpsmresc = GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE
                if gpsmresc and sceneStatesAllowed[gpsmresc:GetState()] and
                   gpsmresc.additionalFilter and type(gpsmresc.additionalFilter) == "function" then
                    return result and gpsmresc.additionalFilter(bagId, slotIndex)
                end
            else--if not gamePadMode then
                local smReSe = SMITHING_RESEARCH_SELECT
                if smReSe and not smReSe:IsHidden() and smReSe.additionalFilter and type(smReSe.additionalFilter) == "function" then
                    return result and smReSe.additionalFilter(bagId, slotIndex)
                end
            end
            return result
        end
    },
}

--enable LF_INVENTORY_COMPANION for gamepad mode
helpers["COMPANION_EQUIPMENT_GAMEPAD:GetItemDataFilterComparator"] = { -- not tested
    version = 1,
    locations = {
        [1] = COMPANION_EQUIPMENT_GAMEPAD,
    },
    helper = {
        funcName = "GetItemDataFilterComparator",
        func = function(self, filteredEquipSlot, nonEquipableFilterType)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_LAUNDER].list:updateFunc')
			return function(itemData)
				if self.additionalFilter and type(self.additionalFilter) == "function" then
					if not self.additionalFilter(itemData) then return end
				end
				if not self:IsSlotInSearchTextResults(itemData.bagId, itemData.slotIndex) then
					return false
				end
				if itemData.actorCategory ~= GAMEPLAY_ACTOR_CATEGORY_COMPANION then
					return false
				end
				if filteredEquipSlot then
					return ZO_Character_DoesEquipSlotUseEquipType(filteredEquipSlot, itemData.equipType)
				end
			end
		end
    },
}

local inventories =				PLAYER_INVENTORY.inventories
local bagList = { -- < rename?
	[BAG_BACKPACK]			= inventories[INVENTORY_BACKPACK],
	[BAG_BANK]				= inventories[INVENTORY_BANK],
	[BAG_SUBSCRIBER_BANK]	= inventories[INVENTORY_BANK],
	[BAG_VIRTUAL]			= inventories[INVENTORY_CRAFT_BAG],
	[BAG_GUILDBANK]			= inventories[INVENTORY_GUILD_BANK],
	[BAG_HOUSE_BANK_ONE]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_TWO]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_THREE]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_FOUR]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_FIVE]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_SIX]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_SEVEN]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_EIGHT]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_NINE]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_TEN]	= inventories[INVENTORY_HOUSE_BANK],
}

--enable LF_INVENTORY_QUEST for gamepad mode
helpers["GAMEPAD_INVENTORY:GetQuestItemDataFilterComparator"] = { -- not tested
    version = 1,
    locations = {
        [1] = GAMEPAD_INVENTORY,
    },
    helper = {
        funcName = "GetQuestItemDataFilterComparator",
        func = function(self, questItemId)
--d( 'GAMEPAD_INVENTORY:GetQuestItemDataFilterComparator')
			local function doesItemPassFilter(questItemId)
				local result = self:IsSlotInSearchTextResults(ZO_QUEST_ITEMS_FILTER_BAG, questItemId)
				if result then
	--				local additionalFilter = inventories[INVENTORY_QUEST_ITEM] and inventories[INVENTORY_QUEST_ITEM].additionalFilter
					if inventories[INVENTORY_QUEST_ITEM].additionalFilter and type(inventories[INVENTORY_QUEST_ITEM].additionalFilter) == "function" then
						local slotData = {bagId = ZO_QUEST_ITEMS_FILTER_BAG, slotIndex = questItemId}
						result = result and inventories[INVENTORY_QUEST_ITEM].additionalFilter(slotData)
					end
				end
				return result
			end
			
			return doesItemPassFilter(questItemId)
		end
    },
}

--enable LF_INVENTORY for gamepad mode
helpers["GAMEPAD_INVENTORY:GetItemDataFilterComparator"] = { -- not tested
    version = 1,
    locations = {
        [1] = GAMEPAD_INVENTORY,
    },
    helper = {
        funcName = "GetItemDataFilterComparator",
        func = function(self, filteredEquipSlot, nonEquipableFilterType)
--d( 'GAMEPAD_INVENTORY:GetItemDataFilterComparator')
			return function(itemData)
				if self.additionalFilter and type(self.additionalFilter) == "function" then
					if not self.additionalFilter(itemData) then return false end
				end
				if not self:IsSlotInSearchTextResults(itemData.bagId, itemData.slotIndex) then
					return false
				end
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
helpers["ZO_GamepadInventoryList:AddSlotDataToTable"] = {
    version = 1,
    locations = {
        [1] = ZO_GamepadInventoryList,
    },
    helper = {
        funcName = "AddSlotDataToTable",
        func = function(self, slotsTable, inventoryType, slotIndex)
--d( 'ZO_GamepadInventoryList:AddSlotDataToTable')
			local function shouldInclude(slotData)
				local result = true

				if self.itemFilterFunction then
					result = self.itemFilterFunction(slotData)
				end
				if result then
					local additionalFilter = bagList[inventoryType].additionalFilter
					if type(additionalFilter) == "function" then
						result = result and additionalFilter(slotData)
					end
				end    
				return result
			end
			
			local categorizationFunction = self.categorizationFunction or ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription
			local slotData = SHARED_INVENTORY:GenerateSingleSlotData(inventoryType, slotIndex)
			
			if slotData then
				if shouldInclude(slotData) then
					-- itemData is shared in several places and can write their own value of bestItemCategoryName.
					-- We'll use bestGamepadItemCategoryName instead so there are no conflicts.
					slotData.bestGamepadItemCategoryName = categorizationFunction(slotData)
					table.insert(slotsTable, slotData)
				end
			end
		end
    },
}

--]]

--[[
--enable LF_INVENTORY/LF_BANK_WITHDRAW/LF_BANK_DEPOSIT/LF_GUILDBANK_WITHDRAW/LF_GUILDBANK_DEPOSIT/LF_GUILDSTORE_SELL/LF_HOUSE_BANK_WITHDRAW/LF_HOUSE_BANK_DEPOSIT/LF_CRAFTBAG for gamepad mode
helpers["ZO_GamepadInventoryList:AddSlotDataToTable"] = { -- not tested
    version = 1,
    locations = {
        [1] = GAMEPAD_INVENTORY.itemList,
        [2] = GAMEPAD_INVENTORY.craftBagList,
        [3] = GAMEPAD_BANKING.depositList,
        [4] = GAMEPAD_BANKING.withdrawList,
        [5] = GAMEPAD_GUILD_BANK.depositList,
        [6] = GAMEPAD_GUILD_BANK.withdrawList,
        [7] = ZO_MailSend_Gamepad.inventoryList,
    },
    helper = {
        funcName = "AddSlotDataToTable",
        func = function(slotsTable, inventoryType, slotIndex)
--d( 'STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_LAUNDER].list:updateFunc')
			local function shouldInclude(slotData)
				local result = true
				if self.itemFilterFunction then
					result = self.itemFilterFunction(slotData)
				end
				if result then
					local additionalFilter = self.additionalFilter or bagList[inventoryType].additionalFilter
					if type(additionalFilter) == "function" then
						result = additionalFilter(slotData)
					end
				end
				return result
			end
			
			
			local itemFilterFunction = self.itemFilterFunction
			local categorizationFunction = self.categorizationFunction or ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription
			local slotData = SHARED_INVENTORY:GenerateSingleSlotData(inventoryType, slotIndex)
			
			if slotData then
				if shouldInclude(slotData) then
					-- itemData is shared in several places and can write their own value of bestItemCategoryName.
					-- We'll use bestGamepadItemCategoryName instead so there are no conflicts.
					slotData.bestGamepadItemCategoryName = categorizationFunction(slotData)
					table.insert(slotsTable, slotData)
				end
			end
		end
    },
}
--]]

------------------------------------------------------------------------------------------------------------------------
 -- -^- GAMEPAD ONLY
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--copy helpers into global LibFilters3Helper
-->Will be set to nil within LibFilter3.lua at event_add_on_loaded

for name, package in pairs(helpers) do
    if LibFilters.helpers[name] == nil then
        LibFilters.helpers[name] = package
    elseif LibFilters.helpers[name].version < package.version then
        LibFilters.helpers[name] = package
    end
end

helpers = nil
LibFilters = nil
