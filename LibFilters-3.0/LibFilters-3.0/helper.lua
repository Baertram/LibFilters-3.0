local LibFilters = LibFilters3

local helpers = {}

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
            local DATA_TYPE_BUY_BACK_ITEM = 1
            ZO_ScrollList_Clear(self.list)
            ZO_ScrollList_ResetToTop(self.list)

            local scrollData = ZO_ScrollList_GetDataList(self.list)

            for entryIndex = 1, GetNumBuybackItems() do
                local icon, name, stack, price, quality, meetsRequirements = GetBuybackItemInfo(entryIndex)
                local buybackData = {
                    slotIndex = entryIndex,
                    icon = icon,
                    name = name,
                    stack = stack,
                    price = price,
                    quality = quality,
                    meetsRequirements = meetsRequirements,
                    stackBuyPrice = stack * price,
                }
                local result = true

                if self.additionalFilter and type(self.additionalFilter) == "function" then
                    result = self.additionalFilter(buybackData)
                end

                if(stack > 0) and result then
                    scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(DATA_TYPE_BUY_BACK_ITEM, buybackData)
                end
            end

            self:ApplySort()
        end,
    },
}

--enable LF_VENDOR_REPAIR
helpers["REPAIR_WINDOW:UpdateList"] = {
    version = 2,
    locations = {
        [1] = REPAIR_WINDOW,
    },
    helper = {
        funcName = "UpdateList",
        func = function(self)
            local function GatherDamagedEquipmentFromBag(bagId, dataTable)
                local DATA_TYPE_REPAIR_ITEM = 1
                local bagSlots = GetBagSize(bagId)

                for slotIndex = 0, bagSlots - 1 do
                    local condition = GetItemCondition(bagId, slotIndex)

                    if condition < 100 and not IsItemStolen(bagId, slotIndex) then
                        local icon, stackCount, _, _, _, _, _, quality = GetItemInfo(bagId, slotIndex)

                        if stackCount > 0 then
                            local repairCost = GetItemRepairCost(bagId, slotIndex)

                            if repairCost > 0 then
                                local name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bagId, slotIndex))
                                local data = {
                                    bagId = bagId,
                                    slotIndex = slotIndex,
                                    name = name,
                                    icon = icon,
                                    stackCount = stackCount,
                                    quality = quality,
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
--  LF_SMITHING_REFINE
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

            for itemId, itemInfo in pairs(list) do
                if not filterFunction or filterFunction(itemInfo.bag, itemInfo.index, filterType) then
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
                    self:AddItemData(slotData.bagId, slotData.slotIndex, slotData.stackCount, self:GetScrollDataType(slotData.bagId, slotData.slotIndex), data, self.customDataGetFunction, slotData)
                end
                self.itemCounts[i] = slotData.stackCount
            end

            return filteredDataTable
        end,
    },
}

--enable LF_SMITHING_RESEARCH -- since API 100023 Summerset
helpers["SMITHING.researchPanel:Refresh"] = {
    version = 5,
    locations = {
        [1] = SMITHING.researchPanel,
    },
    helper = {
        funcName = "Refresh",
        func = function(self)
            -- Include functions local to smithingresearch_shared.lua
            local function IsNotLockedOrRetraitedItem(bagId, slotIndex)
                return not IsItemPlayerLocked(bagId, slotIndex) and GetItemTraitInformation(bagId, slotIndex) ~= ITEM_TRAIT_INFORMATION_RETRAITED
            end

            -- Our filter function to insert LibFilter rules
            local function predicate(bagId, slotIndex)
                local result = IsNotLockedOrRetraitedItem(bagId, slotIndex)

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
helpers["QUICKSLOT_WINDOW:ShouldAddItemToList"] = {
    version = 2,
    locations = {
        [1] = QUICKSLOT_WINDOW,
    },
    helper = {
        funcName = "ShouldAddItemToList",
        func = function(self, itemData)
            local result = true

            if type(self.additionalFilter) == "function" then
                result = self.additionalFilter(itemData)
            end

            for i = 1, #itemData.filterData do
                if(itemData.filterData[i] == ITEMFILTERTYPE_QUICKSLOT) then
                    return result and true
                end
            end

            return false
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
            local base = ZO_RETRAIT_STATION_KEYBOARD
            local result = CanItemBeRetraited(itemData.bagId, itemData.slotIndex)

            if base.additionalFilter and type(base.additionalFilter) == "function" then
                result = result and base.additionalFilter(itemData.bagId, itemData.slotIndex)
            end

            return result
        end,
    }
}

--Normal inventories, now using inventory.additionalFilters = number (changed at each inventory:ChangeFilter, will not
--be hookable via normal LibFilters:HookAdditionalFilters.
--The function would need to be called each time inventory:ChangeFilter happens!
--So we will just overwrite the function "ZO_InventoryManager:ShouldAddSlotToList"
-->https://github.com/esoui/esoui/blob/pts6.2/esoui/ingame/inventory/inventory.lua#L1588
helpers["PLAYER_INVENTORY:ShouldAddSlotToList"] = {
    version = 1,
    locations = {
        [1] = PLAYER_INVENTORY,
    },
    helper = {
        funcName = "ShouldAddSlotToList", --it's defined here:
        func = function(self, inventory, slot)
--d("[LibFilters3]PLAYER_INVENTORY:ShouldAddSlotToList")
            local libFilters = LibFilters3
            --Run LibFilters registered filter functions at the current inventory
            local layoutData = inventory.layoutData or inventory
            local filterType = layoutData.LibFilters3_filterType
--d(">inv: " .. tostring(inventory) .. ", filterType: " ..tostring(filterType))
            if filterType == nil then
                --On 1st open of the normal inventory the following slots will be checked, but why?
                --ZO_CharacterEquipmentSlotsOffHand
                --ZO_CharacterEquipmentSlotsNeck
                --ZO_CharacterEquipmentSlotsShoulder
                --local itemLink = GetItemLink(slot.bagId, slot.slotIndex)
                --d("<<FilterType is NIL! " ..itemLink)
                return true
            end
            local function runLibFiltersFilters(p_slot)
                return libFilters.RunFilters(filterType, p_slot)
            end
            --https://github.com/esoui/esoui/blob/pts6.2/esoui/ingame/inventory/inventory.lua#L1578
            local function DoesSlotPassAdditionalFilter(p_slot, currentFilter, additionalFilter)
                if type(additionalFilter) == "function" then
                    return additionalFilter(p_slot)
                elseif type(additionalFilter) == "number" then
                    return ZO_ItemFilterUtils.IsSlotInItemTypeDisplayCategoryAndSubcategory(p_slot, currentFilter, additionalFilter)
                end

                return true
            end

            local result = false

            if not slot or (slot.stackCount and slot.stackCount <= 0) then
                return false
            end

            if slot.searchData and not inventory.stringSearch:IsMatch(self.cachedSearchText, slot.searchData) then
                return false
            end

            local currentFilter = inventory.currentFilter

            --Call LibFilters3 additionally registered filter functions
            local libFiltersFunctionsReturnValue = runLibFiltersFilters(slot)

            if not DoesSlotPassAdditionalFilter(slot, currentFilter, inventory.additionalFilter) and not libFiltersFunctionsReturnValue then
                return false
            end

            if self.appliedLayout and self.appliedLayout.additionalFilter and not DoesSlotPassAdditionalFilter(slot, currentFilter, self.appliedLayout.additionalFilter) and libFiltersFunctionsReturnValue then
                return false
            end

            if type(currentFilter) == "function" then
                return currentFilter(slot) and libFiltersFunctionsReturnValue
            else
                result = ZO_ItemFilterUtils.IsSlotFilterDataInItemTypeDisplayCategory(slot, currentFilter) and libFiltersFunctionsReturnValue
            end

            return result
        end,
    }
}

------------------------------------------------------------------------------------------------------------------------
--copy helpers into LibFilters

for name, package in pairs(helpers) do
    if LibFilters.helpers[name] == nil then
        LibFilters.helpers[name] = package
    elseif LibFilters.helpers[name].version < package.version then
        LibFilters.helpers[name] = package
    end
end

helpers = nil
LibFilters = nil