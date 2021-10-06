local LibFilters = LibFilters3

local helpers = {}

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

            if self.additionalFilter and type(self.additionalFilter) == "function" then
                result = self.additionalFilter(itemData)
            end

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

                            if self.additionalFilter and type(self.additionalFilter) == "function" then
                                result = self.additionalFilter(buybackData)
                            end

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

                                    if REPAIR_WINDOW.additionalFilter and type(REPAIR_WINDOW.additionalFilter) == "function" then
                                        result = REPAIR_WINDOW.additionalFilter(data)
                                    end

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
--  LF_SMITHING_REFINE, LF_JEWELRY_REFINE
helpers["ALCHEMY_ENCHANTING_SMITHING_Inventory:EnumerateInventorySlotsAndAddToScrollData"] = {
    version = 4,
    locations = {
        [1] = ZO_AlchemyInventory,
        [2] = ZO_EnchantingInventory,
        [3] = ZO_SmithingExtractionInventory,
    },
    helper = {
        funcName = "EnumerateInventorySlotsAndAddToScrollData",
        func = function(self, predicate, filterFunction, filterType, data)
            local libFilters3FilterType = LibFilters3:GetCurrentFilterTypeForInventory(self)
            local isAlchemy     = libFilters3FilterType == LF_ALCHEMY_CREATION
            local isEnchanting  = libFilters3FilterType == LF_ENCHANTING_CREATION
            local isSmithing    = (libFilters3FilterType == LF_SMITHING_REFINE or libFilters3FilterType == LF_JEWELRY_REFINE)
--d(string.format("[LF3]libFilters3FilterType: %s, isAlchemy: %s, isEnchanting: %s, isSmithing: %s", tostring(libFilters3FilterType), tostring(isAlchemy), tostring(isEnchanting), tostring(isSmithing)))

            local oldPredicate = predicate
            predicate = function(bagId, slotIndex)
                local result = true

                if self.additionalFilter and type(self.additionalFilter) == "function" then
                    result = self.additionalFilter(bagId, slotIndex)
                end

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

            --[[
            --Overwritten original function to filter items with additional filters/filter functions
            local function IsResearchableItem(bagId, slotIndex)
                return ZO_SharedSmithingResearch.IsResearchableItem(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
            end
            ]]

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

            if result == true and type(self.additionalFilter) == "function" then
                result = self.additionalFilter(itemData)
            end

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
            if result == true and type(self.additionalFilter) == "function" then
                result = self.additionalFilter(questItemData)
            end

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
            if type(self.additionalFilter) == "function" then
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

            if base.additionalFilter and type(base.additionalFilter) == "function" then
                result = result and base.additionalFilter(itemData.bagId, itemData.slotIndex)
            end

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
    version = 5,
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
                if self.additionalFilter and type(self.additionalFilter) == "function" then
                    result = result and self.additionalFilter(bagId, slotIndex)
                end
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
            local libFilters3FilterType = LibFilters3:GetCurrentFilterTypeForInventory(self)
            local isAlchemy     = libFilters3FilterType == LF_ALCHEMY_CREATION
            local isEnchanting  = libFilters3FilterType == LF_ENCHANTING_CREATION
            local isSmithing    = (libFilters3FilterType == LF_SMITHING_REFINE or libFilters3FilterType == LF_JEWELRY_REFINE)
--d(string.format("[LF3]libFilters3FilterType: %s, isAlchemy: %s, isEnchanting: %s, isSmithing: %s", tostring(libFilters3FilterType), tostring(isAlchemy), tostring(isEnchanting), tostring(isSmithing)))

            local oldPredicate = predicate
            predicate = function(bagId, slotIndex)
                local result = true

                if self.additionalFilter and type(self.additionalFilter) == "function" then
                    result = self.additionalFilter(bagId, slotIndex)
                end

                return oldPredicate(bagId, slotIndex) and result
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
				if not filterFunction or filterFunction(itemInfo.bag, itemInfo.index, filterType) then
					filteredDataTable[#filteredDataTable + 1] = self:GenerateCraftingInventoryEntryData(
                            itemInfo.bag, itemInfo.index,
                            itemInfo.stack,
                            questSV, questItems
                    )
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
--enable LF_SMITHING_RESEARCH_DIALOG for gamepad mode --
-- if counts == 0 then trait is unselectable
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
            local result = CanItemBeSmithingTraitResearched(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
                    and DoesNotBlockResearch(bagId, slotIndex)

            --If the gamepad research -> selected item for research scene is showing/shown
            local sceneStatesAllowed = {
                [SCENE_SHOWING] = true,
                [SCENE_SHOWN] = true,
            }
            if IsInGamepadPreferredMode() and GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE
                    and sceneStatesAllowed[GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE:GetState()] then
--d(">GamePad smithing research - Selected item!")
                if GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE.additionalFilter and type(GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE.additionalFilter) == "function" then
                    return result and GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE.additionalFilter(bagId, slotIndex)
                end
            end
            return result
        end
    },
}
--[[
--enable LF_SMITHING_RESEARCH_DIALOG for gamepad mode --
-- if counts == 0 then trait is unselectable
helpers["GAMEPAD_SMITHING_RESEARCH_SELECT:GenerateResearchTraitCounts"] = {
    version = 1,
    locations = {
        [1] = SMITHING_GAMEPAD.researchPanel,
    },
    helper = {
        funcName = "GenerateResearchTraitCounts",
        func = function(self, virtualInventoryList, craftingType, researchLineIndex, numTraits)
			-- including the local function GetTraitIndexForItem, not normally in this function
			local function GetTraitIndexForItem(bagId, slotIndex, craftingType, researchLineIndex, numTraits)
				for traitIndex = 1, numTraits do
					if CanItemBeSmithingTraitResearched(bagId, slotIndex, craftingType, researchLineIndex, traitIndex) then
						return traitIndex
					end
				end
				return nil
			end

			local function additionalFilter(bagId, slotIndex)
				if self.additionalFilter and type(self.additionalFilter) == "function" then
					return self.additionalFilter(bagId, slotIndex)
				end
			end -- function DoesNotBlockResearch(bagId, slotIndex)

			-- original function
			local counts
			for itemId, itemInfo in pairs(virtualInventoryList) do
				local traitIndex = GetTraitIndexForItem(itemInfo.bag, itemInfo.index, craftingType, researchLineIndex, numTraits)
				if traitIndex and additionalFilter(itemInfo.bag, itemInfo.index) then
					counts = counts or {}
					counts[traitIndex] = (counts[traitIndex] or 0) + 1
				end
			end
			return counts
		end
    },
}

GAMEPAD_SMITHING_RESEARCH_SELECT = ZO_Object:MultiSubclass(SMITHING_GAMEPAD.researchPanel)
helpers["GAMEPAD_SMITHING_RESEARCH_SELECT:SetupDialog"] = {
    version = 1,
    locations = {
        [1] = GAMEPAD_SMITHING_RESEARCH_SELECT,
    },
    helper = {
        funcName = "SetupDialog",
        func = function(self)
			local function AddEntry(data)
				local entry = ZO_GamepadEntryData:New(data.name)
				entry:InitializeCraftingInventoryVisualData(data.bag, data.index, data.stack)
				self.confirmList:AddEntry("ZO_GamepadSubMenuEntryTemplate", entry)
			end
			
			--Overwrite the local function "IsResearchableItem" of file /esoui/ingame/crafting/gamepad/smithingresearch_gamepad.lua
			local function IsResearchableItem(bagId, slotIndex)
				local result = ZO_SharedSmithingResearch.IsResearchableItem(bagId, slotIndex, self.confirmCraftingType, self.confirmResearchLineIndex, self.confirmTraitIndex)
				
				--Is the item researchable? Then check if additional filters are registered
				if result then
					if self.additionalFilter and type(self.additionalFilter) == "function" then
						result = result and self.additionalFilter(bagId, slotIndex)
					end
				end
				return result
			end -- function IsResearchableItem(bagId, slotIndex)
			
			local confirmPanel = self.panelContent:GetNamedChild("Confirm")
			confirmPanel:GetNamedChild("SelectionText"):SetText(GetString(SI_GAMEPAD_SMITHING_RESEARCH_SELECT_ITEM))
			self.confirmList:Clear()
			
			local virtualInventoryList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, IsResearchableItem)
			if self.savedVars.includeBankedItemsChecked then
				PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BANK, IsResearchableItem, virtualInventoryList)
			end
			
			for itemId, itemInfo in pairs(virtualInventoryList) do
				itemInfo.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(itemInfo.bag, itemInfo.index))
				AddEntry(itemInfo)
			end
			self.confirmList:Commit()
			self.confirmList:Activate()
		end
    },
}

-- displays the researchable items list for items that pass the filter
function SMITHING_GAMEPAD.researchPanel:LibAdded()
	GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_SHOWING then
			GAMEPAD_SMITHING_RESEARCH_SELECT:SetupDialog()
			KEYBIND_STRIP:AddKeybindButtonGroup(self.confirmKeybindStripDescriptor)
		elseif newState == SCENE_HIDING then
			self.confirmList:Deactivate()
			KEYBIND_STRIP:RemoveKeybindButtonGroup(self.confirmKeybindStripDescriptor)
			GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
		end
	end)
end
]]

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
