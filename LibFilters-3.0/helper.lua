------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3
------------------------------------------------------------------------------------------------------------------------
local libFilters = LibFilters3


------------------------------------------------------------------------------------------------------------------------
--Local LibFilters speed-up variables and references
------------------------------------------------------------------------------------------------------------------------
--local mapping = libFilters.mapping
--local enchantingModeToFilterType = mapping.enchantingModeToFilterType
--local LF_ConstantToAdditionalFilterControlSceneFragmentUserdata = mapping.LF_ConstantToAdditionalFilterControlSceneFragmentUserdata
--local getCurrentFilterTypeForInventory = libFilters.GetCurrentFilterTypeForInventory


------------------------------------------------------------------------------------------------------------------------
--Local variables for the helpers
------------------------------------------------------------------------------------------------------------------------
local helpers = {}


------------------------------------------------------------------------------------------------------------------------
--Local functions for the helpers
------------------------------------------------------------------------------------------------------------------------
local function doesAdditionalFilterFuncExist(objectVar)
    return (objectVar and objectVar.additionalFilter and type(objectVar.additionalFilter) == "function") or false
end

--Check for .additionalFilter in an object and run it on the slotItem now
local function checkAndRundAdditionalFilters(objectVar, slotItem, resultIfNoAdditionalFilter)
	if resultIfNoAdditionalFilter == nil then resultIfNoAdditionalFilter = true end
	
    if doesAdditionalFilterFuncExist(objectVar) then
		if resultIfNoAdditionalFilter then
			resultIfNoAdditionalFilter = objectVar.additionalFilter(slotItem)
		end
    end
	return resultIfNoAdditionalFilter
end

--Check for .additionalFilter in an object and run it on the bagId and slotIndex now
local function checkAndRundAdditionalFiltersBag(objectVar, bagId, slotIndex, resultIfNoAdditionalFilter)
	if resultIfNoAdditionalFilter == nil then resultIfNoAdditionalFilter = true end
	
    if doesAdditionalFilterFuncExist(objectVar) then
		if resultIfNoAdditionalFilter then
			resultIfNoAdditionalFilter = objectVar.additionalFilter(bagId, slotIndex)
		end
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
--The helpers: Overwritten/changed ZOs vanilla code for the different LibFilters LF_* filterTypes. Most of them will
--check for the existance of an entry .additionalFilter and run the filters together with vanilla code filters then.
--Some vanilla filters like the inventories of player, bank, guild bank deposits already use .additionalFilter them-
--selves in the ZOs code and we did just hook it to add our own functions in addition. See file LibFilters-3.0.lua,
--function libFilters:HookAdditionalFilter(LF_* constant) and runFilters()
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
 -- -v- KEYBOARD ONLY helpers
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
------------------------------------------------------------------------------------------------------------------------
 -- -^- KEYBOARD ONLY helpers
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
 -- -v- KEYBOARD and GAMEPAD - shared helpers
------------------------------------------------------------------------------------------------------------------------
--enable LF_ENCHANTING_CREATION/LF_ENCHANTING_EXTRACTION
helpers["ZO_Enchanting_DoesEnchantingItemPassFilter"] = {
    version = 1,
    locations = {
        [1] = _G
    },
    helper = {
        funcName = "ZO_Enchanting_DoesEnchantingItemPassFilter",
        func = function(bagId, slotIndex, filterType, questFilterChecked, questRunes)
			-- using GAMEPAD_ENCHANTING_CREATION_SCENE/GAMEPAD_ENCHANTING_EXTRACTION_SCENE exclusively
			
			-- i used the gamepad scenes here since they were already set to be filters and required less changing
			-- they also are both for what they are being used for ENCHANTING_CREATION/ENCHANTING_EXTRACTION
			local usedInCraftingType, craftingSubItemType, runeType = GetItemCraftingInfo(bagId, slotIndex)
			if filterType == EXTRACTION_FILTER then
				local result = craftingSubItemType == ITEMTYPE_GLYPH_WEAPON or craftingSubItemType == ITEMTYPE_GLYPH_ARMOR or craftingSubItemType == ITEMTYPE_GLYPH_JEWELRY
				return checkAndRundAdditionalFiltersBag(GAMEPAD_ENCHANTING_EXTRACTION_SCENE, bagId, slotIndex, result)
			elseif filterType == NO_FILTER or filterType == runeType then
				local function doesItemPassFilter(bagId, slotIndex, runeType, questFilterChecked)
					if questFilterChecked then
						local itemId = GetItemId(bagId, slotIndex)
						if questRunes.potency == itemId or questRunes.essence == itemId or questRunes.aspect == itemId then
							return DoesPlayerHaveRunesForEnchanting(questRunes.aspect, questRunes.essence, questRunes.potency)
						else
							return false
						end
					else
						return runeType == ENCHANTING_RUNE_ASPECT or runeType == ENCHANTING_RUNE_ESSENCE or runeType == ENCHANTING_RUNE_POTENCY
					end
				end
				local result = doesItemPassFilter(bagId, slotIndex, runeType, questFilterChecked)
				return checkAndRundAdditionalFiltersBag(GAMEPAD_ENCHANTING_CREATION_SCENE, bagId, slotIndex, result)
			end
			return false
        end,
    }
}


--enable LF_ALCHEMY_CREATION
helpers["ZO_Alchemy_DoesAlchemyItemPassFilter"] = {
    version = 1,
    locations = {
        [1] = _G
    },
    helper = {
        funcName = "ZO_Alchemy_DoesAlchemyItemPassFilter",
        func = function(bagId, slotIndex, filterType, isQuestFilterChecked, questInfo)
			-- using ALCHEMY_SCENE exclusively
--d( 'ZO_Alchemy_DoesAlchemyItemPassFilter')
			local function doesItemPassFilter(bagId, slotIndex, runeType, questFilterChecked)
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
					return true
				end
				local _, craftingSubItemType = GetItemCraftingInfo(bagId, slotIndex)
				if type(filterType) == "function" then
					return filterType(craftingSubItemType)
				end
				return filterType == craftingSubItemType
			end
			
			local result = doesItemPassFilter(bagId, slotIndex, runeType, questFilterChecked)
			return checkAndRundAdditionalFiltersBag(ALCHEMY_SCENE, bagId, slotIndex, result)
        end,
    }
}


--enable LF_SMITHING_RESEARCH -- since API 100023 Summerset
helpers["SMITHING/SMITHING_GAMEPAD.researchPanel:Refresh"] = {
    version = 6,
    locations = {
        [1] = SMITHING.researchPanel,
        [2] = SMITHING_GAMEPAD.researchPanel, --Added with API 101032 The Deadlands 2021-10-06
    },
    helper = {
        funcName = "Refresh",
        func = function(self)
            --Test: Always use SMITHING.researchPanel as self, even in gamepad mode, so registered filter functions at
            --will be read from .additionalFilter!
            local base = SMITHING.researchPanel


--d("[LibFilters3]SMITHING / Gamepad SMITHING:Refresh()")
            -- Our filter function to insert LibFilter filter callback function (.additionalFilter at SMITHING.researchPanel.inventory)
            local function predicate(bagId, slotIndex)
                local result = DoesNotBlockResearch(bagId, slotIndex)
                --result = checkAndRundAdditionalFiltersBag(self, bagId, slotIndex, result)
                result = checkAndRundAdditionalFiltersBag(base, bagId, slotIndex, result)
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
                            local data = { 
								name = name, 
								icon = icon, 
								numTraits = numTraits,
								craftingType = craftingType, 
								itemTraitCounts = itemTraitCounts,
								areAllTraitsKnown = areAllTraitsKnown,
								researchLineIndex = researchLineIndex,
								researchingTraitIndex = researchingTraitIndex,
								timeRequiredForNextResearchSecs = timeRequiredForNextResearchSecs
							}
							
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


--enable LF_SMITHING_RESEARCH_DIALOG/LF_JEWELRY_RESEARCH_DIALOG smithing/jewelry
helpers["ZO_SharedSmithingResearch.IsResearchableItem"] = {
    version = 1,
    locations = {
        [1] = ZO_SharedSmithingResearch
    },
    helper = {
        funcName = "IsResearchableItem",
        func = function(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
--d("[LibFilters3]IsResearchableItem: " ..GetItemLink(bagId, slotIndex))
			-- get objectVar for LF_SMITHING_RESEARCH_DIALOG or LF_JEWELRY_RESEARCH_DIALOG
            local base = SMITHING_RESEARCH_SELECT
			
			local function doesItemPassFilter(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
				return CanItemBeSmithingTraitResearched(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
						and DoesNotBlockResearch(bagId, slotIndex)
			end
			local result = doesItemPassFilter(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
			return checkAndRundAdditionalFiltersBag(base, bagId, slotIndex, result)
        end,
    }
}

--enable LF_RETRAIT
local function doesSmithingItemPassFilter(bagId, slotIndex, filterType)
	return ZO_CraftingUtils_GetSmithingFilterFromItem(bagId, slotIndex) == filterType
end
helpers["ZO_RetraitStation_DoesItemPassFilter"] = {
    version = 2,
    locations = {
        [1] = _G
    },
    helper = {
        funcName = "ZO_RetraitStation_DoesItemPassFilter",
        func = function(bagId, slotIndex, filterType)
            -- get objectVar for LF_RETRAIT -> Use keyboard mode variable for gamepad mode as well
            local base = ZO_RETRAIT_KEYBOARD
			
			local result = doesSmithingItemPassFilter(bagId, slotIndex, filterType)
			return checkAndRundAdditionalFiltersBag(base, bagId, slotIndex, result)
        end,
    }
}


--enable LF_SMITHING_REFINE/LF_JEWELRY_REFINE/LF_SMITHING_DECONSTRUCT/LF_JEWELRY_DECONSTRUCT smithing/jewelry
helpers["ZO_SharedSmithingExtraction_DoesItemPassFilter"] = {
    version = 1,
    locations = {
        [1] = _G
    },
    helper = {
        funcName = "ZO_SharedSmithingExtraction_DoesItemPassFilter",
        func = function(bagId, slotIndex, filterType)
			-- get objectVar for LF_SMITHING_REFINE/LF_JEWELRY_REFINE, or LF_SMITHING_DECONSTRUCT/LF_JEWELRY_DECONSTRUCT-> Use keyboard mode variable for gamepad mode as well
            local base = filterType == SMITHING_FILTER_TYPE_RAW_MATERIALS and SMITHING.refinementPanel or SMITHING.deconstructionPanel

			local result = doesSmithingItemPassFilter(bagId, slotIndex, filterType)
			return checkAndRundAdditionalFiltersBag(base, bagId, slotIndex, result)
        end,
    }
}


--enable LF_SMITHING_IMPROVEMENT/LF_JEWELRY_IMPROVEMENT smithing/jewelry
helpers["ZO_SharedSmithingImprovement_DoesItemPassFilter"] = {
    version = 1,
    locations = {
        [1] = _G
    },
    helper = {
        funcName = "ZO_SharedSmithingImprovement_DoesItemPassFilter",
        func = function(bagId, slotIndex, filterType)
			-- get objectVar for LF_SMITHING_IMPROVEMENT or LF_JEWELRY_IMPROVEMENT -> Use keyboard mode variable for gamepad mode as well
            local base = SMITHING.improvementPanel
			
			local result = doesSmithingItemPassFilter(bagId, slotIndex, filterType)
			return checkAndRundAdditionalFiltersBag(base, bagId, slotIndex, result)
        end,
    }
}

------------------------------------------------------------------------------------------------------------------------
 -- -^- KEYBOARD and GAMEPAD - shared helpers
------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------
 -- -v- GAMEPAD ONLY helpers
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


--enable LF_VENDOR_BUY for gamepad mode
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY].list:updateFunc"] = {
    version = 1,
    locations = {
        [1] = STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY].list,
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
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL].list:updateFunc"] = {
    version = 1,
    locations = {
        [1] = STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL].list,
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
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY_BACK].list:updateFunc"] = {
    version = 1,
    locations = {
        [1] = STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY_BACK].list,
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
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_REPAIR].list:updateFunc"] = {
    version = 1,
    locations = {
        [1] = STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_REPAIR].list,
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
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL_STOLEN].list:updateFunc"] = { -- not tested
    version = 1,
    locations = {
        [1] = STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL_STOLEN].list,
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
helpers["STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_LAUNDER].list:updateFunc"] = { -- not tested
    version = 1,
    locations = {
        [1] = STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_LAUNDER].list,
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
                if not checkAndRundAdditionalFilters(self, itemData, nil) then return end
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
					local slotData = {bagId = ZO_QUEST_ITEMS_FILTER_BAG, slotIndex = questItemId}
					result = checkAndRundAdditionalFilters(self.scene, slotData, result)
				end
				return result
			end
			
			return doesItemPassFilter(questItemId)
		end
    },
}


--enable LF_INVENTORY for gamepad mode
local inventories = PLAYER_INVENTORY.inventories
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
--				if not checkAndRundAdditionalFilters(self, itemData, nil) then return end
				if not checkAndRundAdditionalFilters(bagList[BAG_BACKPACK], itemData, nil) then return end
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
                    result = checkAndRundAdditionalFilters(bagList[inventoryType], slotData, result)
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

------------------------------------------------------------------------------------------------------------------------
 -- -^- GAMEPAD ONLY helpers
------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------
--copy helpers into global LibFilters3.helpers
-->LibFilters3.helpers will be set to nil again within LibFilter3.lua at event_add_on_loaded
for name, package in pairs(helpers) do
    if libFilters.helpers[name] == nil then
        libFilters.helpers[name] = package
    elseif libFilters.helpers[name].version < package.version then
        libFilters.helpers[name] = package
    end
end
helpers = nil