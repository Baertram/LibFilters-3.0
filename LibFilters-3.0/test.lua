--Init the library, if not already done
local libFilters = LibFilters3
if not libFilters then return end
libFilters:InitializeLibFilters()

------------------------------------------------------------------------------------------------------------------------
-- HELPER VARIABLES AND FUNCTIONS FOR TESTS
------------------------------------------------------------------------------------------------------------------------
--Helper varibales for tests
local prefix = libFilters.globalLibName
local filterTag = prefix .."_TestFilters_"
local filterTypeToFilterFunctionType = libFilters.mapping.filterTypeToFilterFunctionType
local LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT = libFilters.constants.LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT

libFilters.test = {}


--filter function for inventories
local function filterFuncForInventories(inventorySlot)
	local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
	d(">"..prefix.."Item: " .. GetItemLink(bagId, slotIndex))
	return false --simulate "not allowed" -> filtered
end
--filter function for crafting e.g.
local function filterFuncForCrafting(bagId, slotIndex)
	d(">"..prefix.."Item: " .. GetItemLink(bagId, slotIndex))
	return false --simulate "not allowed" -> filtered
end

--test function to register/unregister (toggle) a filterType, and update the inventory afterwards
local function toggleFilterForFilterType(filterType, noUpdate)
	noUpdate = noUpdate or false
	local filterTypeName = libFilters:GetFilterTypeName(filterType)
	local filterFunc = (filterTypeToFilterFunctionType[filterType] == LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT and filterFuncForInventories) or filterFuncForCrafting

	if libFilters:IsFilterRegistered(filterTag, filterType) then
		libFilters:UnregisterFilter(filterTag, filterType)
		d("<[LibFilters3]Test filter for \'" .. filterTypeName .. "\'  unregistered!")
	else
		libFilters:RegisterFilter(filterTag, filterType, function(...) filterFunc(...) end)
		d(">[LibFilters3]Test filter for \'" .. filterTypeName .. "\' registered!")
	end
	if noUpdate then return end
	libFilters:RequestUpdate(filterType)
end


------------------------------------------------------------------------------------------------------------------------
-- Custom SLASH COMMANDS for tests
------------------------------------------------------------------------------------------------------------------------
SLASH_COMMANDS["/lftestfilters"] = function()
	local filterTypes = {
		LF_INVENTORY,
		LF_INVENTORY_QUEST,
		LF_CRAFTBAG,
		LF_BANK_WITHDRAW,
		LF_BANK_DEPOSIT,
		LF_GUILDBANK_WITHDRAW,
		LF_GUILDBANK_DEPOSIT,
		LF_VENDOR_BUY,
		LF_VENDOR_SELL,
		LF_VENDOR_BUYBACK,
		LF_VENDOR_REPAIR,
		LF_GUILDSTORE_SELL,
		LF_MAIL_SEND,
		LF_TRADE,
		LF_SMITHING_REFINE,
		LF_SMITHING_DECONSTRUCT,
		LF_SMITHING_IMPROVEMENT,
		LF_SMITHING_RESEARCH,
		LF_ALCHEMY_CREATION,
		LF_ENCHANTING_CREATION,
		LF_ENCHANTING_EXTRACTION,
		LF_FENCE_SELL,
		LF_FENCE_LAUNDER,
		LF_QUICKSLOT,
		LF_RETRAIT,
		LF_HOUSE_BANK_WITHDRAW,
		LF_HOUSE_BANK_DEPOSIT,
		LF_JEWELRY_REFINE,
		LF_JEWELRY_CREATION,
		LF_JEWELRY_DECONSTRUCT,
		LF_JEWELRY_IMPROVEMENT,
		LF_JEWELRY_RESEARCH,
		LF_SMITHING_RESEARCH_DIALOG,
		LF_JEWELRY_RESEARCH_DIALOG,
		LF_INVENTORY_COMPANION
	}


	local function doesItemPassFilter(bagId, slotIndex, stackCount)
		local itemType,  specializedItemType = GetItemType(bagId, slotIndex)
		local quality = GetItemQuality(bagId, slotIndex)

		if itemType == ITEMTYPE_ENCHANTING_RUNE_ASPECT then
			return quality < ITEM_FUNCTIONAL_QUALITY_ARCANE
		elseif itemType == ITEMTYPE_BLACKSMITHING_BOOSTER then
			return quality < ITEM_FUNCTIONAL_QUALITY_ARCANE
		elseif itemType == ITEMTYPE_CLOTHIER_BOOSTER then
			return quality < ITEM_FUNCTIONAL_QUALITY_ARCANE
		elseif itemType == ITEMTYPE_JEWELRYCRAFTING_BOOSTER then
			return quality < ITEM_FUNCTIONAL_QUALITY_ARCANE
		elseif itemType == ITEMTYPE_WOODWORKING_BOOSTER then
			return quality < ITEM_FUNCTIONAL_QUALITY_ARCANE
		elseif itemType == ITEMTYPE_WEAPON or itemType == ITEMTYPE_ARMOR then
			return quality < ITEM_FUNCTIONAL_QUALITY_ARCANE and not IsItemPlayerLocked(bagId, slotIndex) and
				GetItemActorCategory(bagId, slotIndex) ~= GAMEPLAY_ACTOR_CATEGORY_COMPANION
		elseif itemType == ITEMTYPE_POISON_BASE or itemType == ITEMTYPE_POTION_BASE or itemType == ITEMTYPE_REAGENT then
			return stackCount > 100
		end

		if quality > ITEM_FUNCTIONAL_QUALITY_ARCANE then
			return false
		end
		return stackCount > 1
	end

	for _, filterType in pairs(filterTypes) do
		libFilters.test[filterType] = {}

		local function filterCallback(slotOrBagId, slotIndex)
			if slotIndex then
				local bagId = slotOrBagId
				local itemLink = GetItemLink(bagId, slotIndex)
				local stackCountBackpack, stackCountBank, stackCountCraftBag = GetItemLinkStacks(itemLink)
				local stackCount = stackCountBackpack + stackCountBank + stackCountCraftBag

				local result = doesItemPassFilter(bagId, slotIndex, stackCount)
				if result == false then
					-- can take a moment to display for research, has a low filter threshold
					d(string.format("--	test, filterType:( %s ), stackCount:( %s ), itemLink: %s", filterType, stackCount, itemLink))
				end
				return result
			else
				local bagId, slotIndex = slotOrBagId.bagId, slotOrBagId.slotIndex
				local itemLink = bagId == nil and GetQuestItemLink(slotIndex) or GetItemLink(bagId, slotIndex)
				local stackCountBackpack, stackCountBank, stackCountCraftBag = GetItemLinkStacks(itemLink)
				local stackCount = stackCountBackpack + stackCountBank + stackCountCraftBag

				local result = doesItemPassFilter(bagId, slotIndex, stackCount)
				if result == false then
					-- can take a moment to display for research, has a low filter threshold
					d(string.format("--	test, filterType:( %s ), stackCount:( %s ), itemLink: %s", filterType, stackCount, itemLink))
				end
				return result
			end
		end

		local filterTypeName = libFilters:GetFilterTypeName(filterType)
		if libFilters:IsFilterRegistered(filterTag, filterType) then
			d("[LibFilters3]Unregistering " .. filterTypeName)
			libFilters:UnregisterFilter(filterTag, filterType)
		else
			d("[LibFilters3]Registering " .. filterTypeName)
			libFilters:RegisterFilter(filterTag, filterType, filterCallback)
		end
 	    libFilters:RequestUpdate(filterType)
	end
end

--depends on Item Saver by Randactyl
SLASH_COMMANDS["/lftestenchant"] = function()
	if not ItemSaver then return end

	local isRegistered = libFilters:IsFilterRegistered(filterTag, LF_ENCHANTING_CREATION)

	local function filterCallback(slotOrBagId, slotIndex)
		local bagId

		if type(slotOrBagId) == "number" then
			if not slotIndex then return false end

			bagId = slotOrBagId
		else
			bagId, slotIndex = ItemSaver.util.GetInfoFromRowControl(slotOrBagId)
		end

		local isSaved, savedSet = ItemSaver_IsItemSaved(bagId, slotIndex)

		return not isSaved
	end

	if not isRegistered then
		libFilters:RegisterFilter(filterTag, LF_ENCHANTING_CREATION, filterCallback)
		libFilters:RequestUpdate(LF_ENCHANTING_CREATION)
		libFilters:RegisterFilter(filterTag, LF_ENCHANTING_EXTRACTION, filterCallback)
		libFilters:RequestUpdate(LF_ENCHANTING_EXTRACTION)
	else
		libFilters:UnregisterFilter(filterTag, LF_ENCHANTING_CREATION)
		libFilters:RequestUpdate(LF_ENCHANTING_CREATION)
		libFilters:UnregisterFilter(filterTag, LF_ENCHANTING_EXTRACTION)
		libFilters:RequestUpdate(LF_ENCHANTING_EXTRACTION)
	end
end


--testing Gamepad research dialog confirm scene: Add [2] to GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE.callbackRegistry.StateChange
-->The index [1] in GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE.callbackRegistry.StateChange is the original state change of ZOs vailla UI and should trigger the
-->refresh of the scene's list contents
--> See here: esoui/ingame/crafting/gamepad/smithingresearch_gamepad.lua
-->GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE:RegisterCallback("StateChange", function(oldState, newState)
local researchConfirmSceneCallbackAdded = false
SLASH_COMMANDS["/lftestresearchdialog"] = function()
	if researchConfirmSceneCallbackAdded then return end
	GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE:RegisterCallback("StateChange", function(oldState, newState)
		d("GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE [2] - StateChange: " ..string.format("oldState: %s, newState: %s", tostring(oldState), tostring(newState)))
	end)
	local origStateChangeFunc = GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE.callbackRegistry.StateChange[1][1]
	GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE.callbackRegistry.StateChange[1][1] = function(...)
		local oldState, newState = select(1, ...)
		d("OGIG: - GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE [1] - StateChange: " ..string.format("oldState: %s, newState: %s", tostring(oldState), tostring(newState)))
		origStateChangeFunc(...)
	end
	d("[LibFilters3]Test scene callback for Gamepad research confirm scene was added! ReloadUI to remove it.")
	researchConfirmSceneCallbackAdded = true
end


------------------------------------------------------------------------------------------------------------------------
-- SLASH COMMANDS for toggel & update tests
------------------------------------------------------------------------------------------------------------------------
--Alchemy
SLASH_COMMANDS["/lftestalchemy"] = function()
	toggleFilterForFilterType(LF_ALCHEMY_CREATION)
end

--Inventory
SLASH_COMMANDS["/lftestinv"] = function()
	toggleFilterForFilterType(LF_INVENTORY)
end

--Inventory
SLASH_COMMANDS["/lftestcraftbag"] = function()
	toggleFilterForFilterType(LF_CRAFTBAG)
end


--Bank withdraw
SLASH_COMMANDS["/lftestbankwithdraw"] = function()
	toggleFilterForFilterType(LF_BANK_WITHDRAW)
end

--Guild Bank withdraw
SLASH_COMMANDS["/lftestguildbankwithdraw"] = function()
	toggleFilterForFilterType(LF_GUILDBANK_WITHDRAW)
end

--House bank withdraw
SLASH_COMMANDS["/lftesthousebankwithdraw"] = function()
	toggleFilterForFilterType(LF_HOUSE_BANK_WITHDRAW)
end
