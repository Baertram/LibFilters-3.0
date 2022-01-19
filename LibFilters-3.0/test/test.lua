-- Use /lftestfilters to open testing UI
-- To test a specific filter, you can specify a globally difined function

-- Example
-- /script testFilter = function(bagId, slotIndex) local quality = GetItemQuality(bagId, slotIndex) return quality < ITEM_FUNCTIONAL_QUALITY_ARCANE end
-- /lftestfilters testFilter

--	
--	addon.test.testFilter = function(bagId, slotIndex)
--		local quality = GetItemQuality(bagId, slotIndex)
--		return quality < ITEM_FUNCTIONAL_QUALITY_ARCANE
--	end

-- /lftestfilters addon.test.testFilter

--Init the library, if not already done
local libFilters = LibFilters3
if not libFilters then return end

local svTest

local CM = CALLBACK_MANAGER

local gilst = 	GetItemLinkStacks
local gil = 	GetItemLink
local gqil = 	GetQuestItemLink
local zigbai = 	ZO_Inventory_GetBagAndIndex

local libFilters_GetFilterTypeName = libFilters.GetFilterTypeName
local libFilters_IsFilterRegistered = libFilters.IsFilterRegistered
local libFilters_RegisterFilter = libFilters.RegisterFilter
local libFilters_UnregisterFilter = libFilters.UnregisterFilter
local libFilters_RequestUpdate = libFilters.RequestUpdate
local libFilters_CreateCallbackName = libFilters.CreateCallbackName

local function checkIfInitDone()
	if libFilters.isInitialized then return end
	libFilters:InitializeLibFilters()
end

------------------------------------------------------------------------------------------------------------------------
-- LIBRARY VARIABLES
------------------------------------------------------------------------------------------------------------------------
--local constants = libFilters.constants
local mapping = libFilters.mapping
local usingBagIdAndSlotIndexFilterFunction = mapping.filterTypesUsingBagIdAndSlotIndexFilterFunction


------------------------------------------------------------------------------------------------------------------------
-- HELPER VARIABLES AND FUNCTIONS FOR TESTS
------------------------------------------------------------------------------------------------------------------------
--ZOs helpers
local strfor = string.format
local tos = tostring
local strgm = string.gmatch
local gTab = table
local tins = gTab.insert

--Helper varibales for tests
local prefix = libFilters.globalLibName
local prefixBr = "[" .. prefix .. "] TEST "
local testUItemplate = "LibFilters_Test_Template"

local filterTag = prefix .."_TestFilters_"
local filterTypeToFilterFunctionType = libFilters.mapping.filterTypeToFilterFunctionType
local LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT = libFilters.constants.LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT

local customFilterFunctionTag = " (C)"
local allCustomFilterFunctionsDisabled = true

--UI
libFilters.test = {}
local tlw
local btnFilter



--filter function for inventories
local function filterFuncForInventories(inventorySlot)
	local bagId, slotIndex = zigbai(inventorySlot)
	d(">"..prefix.."Item: " .. gil(bagId, slotIndex))
	return false --simulate "not allowed" -> filtered
end
--filter function for crafting e.g.
local function filterFuncForCrafting(bagId, slotIndex)
	d(">"..prefix.."Item: " .. gil(bagId, slotIndex))
	return false --simulate "not allowed" -> filtered
end


--test function to register/unregister (toggle) a filterType, and update the inventory afterwards
local function toggleFilterForFilterType(filterType, noUpdate)
	checkIfInitDone()

	noUpdate = noUpdate or false
	local filterTypeName = libFilters_GetFilterTypeName(libFilters, filterType)
	local filterFunc = (filterTypeToFilterFunctionType[filterType] == LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT and filterFuncForInventories) or filterFuncForCrafting

	if libFilters_IsFilterRegistered(libFilters, filterTag, filterType) then
		libFilters_UnregisterFilter(libFilters, filterTag, filterType)
		d("<"..prefixBr .. "filter for \'" .. filterTypeName .. "\'  unregistered!")
	else
		libFilters_RegisterFilter(libFilters, filterTag, filterType, function(...) filterFunc(...) end)
		d(">" ..prefixBr .. "filter for \'" .. filterTypeName .. "\' registered!")
	end
	if noUpdate then return end
	libFilters_RequestUpdate(libFilters, filterType)
end

--	LibFilters3_Test_TLC

------------------------------------------------------------------------------------------------------------------------
-- TEST UI
------------------------------------------------------------------------------------------------------------------------
local helpUIInstructionsParts = {
	"Use /lftestfilters without any parameters to open/close the test UI. Click the small 'x' button at the top-right edge to close the UI and clear all filters.",
	"Select any number of LF_* filterTypes in the top list. Clicking them will select them. Clicking them again will deselct them.",
	"Use \'"..GetString(SI_APPLY).."\' button to register the selected filters and populate the registered LF_* filterTypes to the bottom list.", --"Apply" button
	"At any time, LF_* filterTypes can be added or removed by selecting/deselcting the button in the top list, and pressing the button \'" .. GetString(SI_APPLY) .. "\'.",
	"The \'".. GetString(SI_GAMEPAD_BANK_FILTER_HEADER) .."\' button enables/disables filtering of the registered filters.", --"Filter" button
	"If you click the buttons of the LF_* filterTypes at the bottom list it will refresh/update the clicked filterType panel (if it's currently shown).",
	"Means: With a fragment/scene containing a filterable inventory, enable/disable filtering (middle button) and press the according LF_* button in the bottom",
	"list. Chat output will show you some information about the filtered items then. A default filterFunction is used but can be chanegd for each filterType -> See filterFunction editbox.",
	"The \'".. GetString(SI_BUFFS_OPTIONS_ALL_ENABLED) .."\' button will move down/move up all LF_* filterTypes at once.", --"All" button
}
local helpUIInstructions = gTab.concat(helpUIInstructionsParts, "\n")
local helpUICustomFilterFunctionParts = {
	"You can use the filterFunction editbox and the \'OK\' button to set a custom filterFunction for the selected (upper list) filterTypes.",
	"Important: The filterFunction name provided must be existing in the global table _G, and it needs to be a function with 2 parameters: bagId, slotIndex!",
	"If no filterType is selected at the upper list, the fallback LF_FILTER_ALL will be used (applies to all filterTypes). Dedicated filterTypes selected will",
	"always overwrite the LF_FILTER_ALL fallback filterType!",
	"Alternatively use the slash command /lftestfilters <LF_filterType> <globalFilterFunctionName> to register a special filterFunction",
	"for the provided LF_ filterType: e.g. /lftestfilters LF_SMITHIG_REFINE MyGlobalAddonFilterFunctionForSmithingRefine",
	"Use /lftestfilters <LF_filterType> without any additional filterFunctionName to reset the custom filterFunction for that filtertype to the default.",
	"If custom filterFunctions were added to a filterType the filterType button (upper and lower list) shows a \'(C)\' after the filterType number, and a tooltip shows more info.",
	"Any change to the custom filterFunctions needs to be applied to already added filterTypes (lower list) by the \'" .. GetString(SI_APPLY) .. "\' button!"
}
local helpUICustomFilterFunctions = gTab.concat(helpUICustomFilterFunctionParts, "\n")

local filterTypesToCategory = {
	{
		['filterType'] = LF_INVENTORY,
		['category'] = 'Inventory',
	},
	{
		['filterType'] = LF_INVENTORY_QUEST,
		['category'] = 'Inventory',
	},
	{
		['filterType'] = LF_CRAFTBAG,
		['category'] = 'Inventory',
	},
	{
		['filterType'] = LF_INVENTORY_COMPANION,
		['category'] = 'Inventory',
	},
	{
		['filterType'] = LF_QUICKSLOT,
		['category'] = 'Inventory',
	},
	{
		['filterType'] = LF_BANK_WITHDRAW,
		['category'] = 'Banking',
	},
	{
		['filterType'] = LF_BANK_DEPOSIT,
		['category'] = 'Banking',
	},
	{
		['filterType'] = LF_GUILDBANK_WITHDRAW,
		['category'] = 'Banking',
	},
	{
		['filterType'] = LF_GUILDBANK_DEPOSIT,
		['category'] = 'Banking',
	},
	{
		['filterType'] = LF_HOUSE_BANK_WITHDRAW,
		['category'] = 'Banking',
	},
	{
		['filterType'] = LF_HOUSE_BANK_DEPOSIT,
		['category'] = 'Banking',
	},
	{
		['filterType'] = LF_GUILDSTORE_SELL,
		['category'] = 'Banking',
	},
	{
		['filterType'] = LF_VENDOR_BUY,
		['category'] = 'Vendor',
	},
	{
		['filterType'] = LF_VENDOR_SELL,
		['category'] = 'Vendor',
	},
	{
		['filterType'] = LF_VENDOR_BUYBACK,
		['category'] = 'Vendor',
	},
	{
		['filterType'] = LF_VENDOR_REPAIR,
		['category'] = 'Vendor',
	},
	{
		['filterType'] = LF_FENCE_SELL,
		['category'] = 'Vendor',
	},
	{
		['filterType'] = LF_FENCE_LAUNDER,
		['category'] = 'Vendor',
	},
	{
		['filterType'] = LF_MAIL_SEND,
		['category'] = 'Trade',
	},
	{
		['filterType'] = LF_TRADE,
		['category'] = 'Trade',
	},
	{
		['filterType'] = LF_ALCHEMY_CREATION,
		['category'] = 'Crafting',
	},
	{
		['filterType'] = LF_ENCHANTING_CREATION,
		['category'] = 'Crafting',
	},
	{
		['filterType'] = LF_ENCHANTING_EXTRACTION,
		['category'] = 'Crafting',
	},
	{
		['filterType'] = LF_RETRAIT,
		['category'] = 'Crafting',
	},
	{
		['filterType'] = LF_SMITHING_REFINE,
		['category'] = 'Smithing',
	},
	{
		['filterType'] = LF_SMITHING_CREATION,
		['category'] = 'Smithing',
	},
	{
		['filterType'] = LF_SMITHING_DECONSTRUCT,
		['category'] = 'Smithing',
	},
	{
		['filterType'] = LF_SMITHING_IMPROVEMENT,
		['category'] = 'Smithing',
	},
	{
		['filterType'] = LF_SMITHING_RESEARCH,
		['category'] = 'Smithing',
	},
	{
		['filterType'] = LF_SMITHING_RESEARCH_DIALOG,
		['category'] = 'Smithing',
	},
	{
		['filterType'] = LF_JEWELRY_REFINE,
		['category'] = 'Jewelery',
	},
	{
		['filterType'] = LF_JEWELRY_CREATION,
		['category'] = 'Jewelery',
	},
	{
		['filterType'] = LF_JEWELRY_DECONSTRUCT,
		['category'] = 'Jewelery',
	},
	{
		['filterType'] = LF_JEWELRY_IMPROVEMENT,
		['category'] = 'Jewelery',
	},
	{
		['filterType'] = LF_JEWELRY_RESEARCH,
		['category'] = 'Jewelery',
	},
	{
		['filterType'] = LF_JEWELRY_RESEARCH_DIALOG,
		['category'] = 'Jewelery',
	}
}

local enabledFilters = {}
local LIST_TYPE = 1
local HEADER_TYPE = 2
local enableList = {}
local updateList = {}
local currentFilterPanelLabel
local customFilterFunctionEdit
local closeUIButton
local useFilter = false

--Via slash command added filter functions for the LF_* constants
local testAdditionalFilterFunctions = {
	--example
	--[LF_INVENTORY] = globalFunctionNameFromSlashCommend_lftestfilters_parameter1
	--If [LF_FILTER_ALL] is added this is the filterFunction to use for all LF_ constants!
}
libFilters.test.additionalFilterFunctions = testAdditionalFilterFunctions
--The String names of the custom filterFunctions
local testAdditionalFilterFunctionsNames = {}
libFilters.test.testAdditionalFilterFunctionsNames = testAdditionalFilterFunctionsNames

local function checkIfAllCustomFilterFunctionsDisabled()
	for filterType, customFilterFunc in pairs(testAdditionalFilterFunctions) do
		if filterType ~= nil and customFilterFunc ~= nil then
			allCustomFilterFunctionsDisabled = false
			return
		end
	end
	allCustomFilterFunctionsDisabled = true
end

--The default filter function to use. Generalized to be compatible with inventorySlots and bagId/slotIndex parameters (crafting tables e.g.)
--Will filter depending on the itemType and hide items with quality below "blue"
--and if weapons/armor also if it's locked by ZOs vanilla UI lock functionality and non companion items
--and poisons or potions or reagents by their stackCount <= 100
local function defaultFilterFunction(bagId, slotIndex, stackCount)
	local itemType, specializedItemType = GetItemType(bagId, slotIndex)
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

local bagIdSlotIndexFilterTypeStr = "bagId/slotIndex: (%s/%s), filterType: (%s)"
local filterChatOutputPerItemDefaultStr = "--test: filtered %s stackCount: (%s), " .. bagIdSlotIndexFilterTypeStr
local filterChatOutputPerItemCustomStr = "--test: filtered %s " .. bagIdSlotIndexFilterTypeStr
local function resultCheckFunc(p_result, p_filterTypeName, p_useDefaultFilterFunction, p_bagId, p_slotIndex, p_itemLink, p_stackCount)
	if p_result == true then return end
	if p_useDefaultFilterFunction then
		-- can take a moment to display for research, has a low filter threshold
		d(strfor(filterChatOutputPerItemDefaultStr, p_itemLink, tos(p_stackCount), tos(p_bagId), tos(p_slotIndex), p_filterTypeName))
	else
		d(strfor(filterChatOutputPerItemCustomStr, p_itemLink, tos(p_bagId), tos(p_slotIndex), p_filterTypeName))
	end
end

local function getCustomFilterFunctionInfo(filterType)
	local useDefaultFilterFunction = true
	local customFilterFunctionName = ""
	--Use the custom registered filterFunction for the LF_ filter constant, or a registered filterFunction for all LF_ constants,
	--or use the default filterFunction "defaultFilterFunction" of this test file
	local testAdditionalFilterFunctionToUse = testAdditionalFilterFunctions[filterType] or testAdditionalFilterFunctions[LF_FILTER_ALL]
	if testAdditionalFilterFunctionToUse == nil then
		testAdditionalFilterFunctionToUse = defaultFilterFunction
	else
		useDefaultFilterFunction = false
		customFilterFunctionName = testAdditionalFilterFunctionsNames[filterType] or testAdditionalFilterFunctionsNames[LF_FILTER_ALL]
		if customFilterFunctionName == nil then customFilterFunctionName = "" end
	end
	return customFilterFunctionName, useDefaultFilterFunction, testAdditionalFilterFunctionToUse
end


local function registerFilter(filterType, filterTypeName)
	local customFilterFunctionName, useDefaultFilterFunction, testAdditionalFilterFunctionToUse = getCustomFilterFunctionInfo(filterType)

	local function filterBagIdAndSlotIndexCallback(bagId, slotIndex)
		if not useFilter then return true end
		local itemLink = gil(bagId, slotIndex)
		local stackCountBackpack, stackCountBank, stackCountCraftBag = gilst(itemLink)
		local stackCount = stackCountBackpack + stackCountBank + stackCountCraftBag

		local result = testAdditionalFilterFunctionToUse(bagId, slotIndex, stackCount) --custom filterFunction will only use bagId and slotIndex, no 3rd param stackCount
		resultCheckFunc(result, filterTypeName, useDefaultFilterFunction, bagId, slotIndex, itemLink, stackCount)
		return result
	end

	local function filterSlotDataCallback(slotData)
		if not useFilter then return true end
		local bagId, slotIndex = slotData.bagId, slotData.slotIndex
		local itemLink = bagId == nil and gqil(slotIndex) or gil(bagId, slotIndex)
		local stackCountBackpack, stackCountBank, stackCountCraftBag = gilst(itemLink)
		local stackCount = stackCountBackpack + stackCountBank + stackCountCraftBag

		local result = testAdditionalFilterFunctionToUse(bagId, slotIndex, stackCount) --custom filterFunction will only use bagId and slotIndex, no 3rd param stackCount
		resultCheckFunc(result, filterTypeName, useDefaultFilterFunction, bagId, slotIndex, itemLink, stackCount)
		return result
	end

	local usingBagAndSlot = usingBagIdAndSlotIndexFilterFunction[filterType] or false
	local filterFunctioNameStr = (useDefaultFilterFunction == true and "default") or (useDefaultFilterFunction == false and "custom: \'" .. tos(customFilterFunctionName) .."\'")
	d(prefixBr .. "- Registering " .. filterTypeName .. " [" ..tos(filterType) .."], filterFunction " .. tos(filterFunctioNameStr) .. ", bagAndSlotFilterFunction: " .. tos(usingBagAndSlot))
	libFilters_RegisterFilter(libFilters, filterTag, filterType, (usingBagAndSlot == true and filterBagIdAndSlotIndexCallback) or filterSlotDataCallback)

	return useDefaultFilterFunction, customFilterFunctionName
end

local function updateCustomFilterFunction(filterTypes, filterFunction, filterFunctionName)
	if filterFunction == nil then
		if filterFunctionName ~= nil then
			return
		end
	end
	if filterTypes == nil then return end
	if #filterTypes == 0 then return end

	for _, filterType in ipairs(filterTypes) do
		testAdditionalFilterFunctions[filterType] = filterFunction
		testAdditionalFilterFunctionsNames[filterType] = filterFunctionName
	end
end

local function refresh(dataList)
	for _, filterData in pairs(filterTypesToCategory) do
		local filterType = filterData.filterType
		local isRegistered = libFilters_IsFilterRegistered(libFilters, filterTag, filterType)
		local filterTypeName = libFilters_GetFilterTypeName(libFilters, filterType)
		local customFilterFunctionName, _, _ = getCustomFilterFunctionInfo(filterType)
		if enabledFilters[filterType] == true then
			local data = {
				['filterType'] 	= filterType,
				['name'] 		= filterTypeName,
				['customFilterFunctionName'] = customFilterFunctionName
			}
			tins(dataList, ZO_ScrollList_CreateDataEntry(LIST_TYPE, data))

			if not isRegistered then
				registerFilter(filterType, filterTypeName)
			end

		elseif isRegistered then
			d(prefixBr .. "- Unregistering " .. filterTypeName .. " [" ..tos(filterType) .."]")
			libFilters_UnregisterFilter(libFilters, filterTag, filterType)
		end
	end
end

local function refreshUpdateList()
	ZO_ScrollList_Clear(updateList)
	refresh(ZO_ScrollList_GetDataList(updateList))
	ZO_ScrollList_Commit(updateList)
end

local function refreshEnableList()
	local lastCategory = ''
	
	ZO_ScrollList_Clear(enableList)
	local dataList = ZO_ScrollList_GetDataList(enableList)
	for _, filterData in pairs(filterTypesToCategory) do
		local listType = LIST_TYPE
		local filterType = filterData.filterType
		local filterTypeName = libFilters_GetFilterTypeName(libFilters, filterType)
		local customFilterFunctionName, _, _ = getCustomFilterFunctionInfo(filterType)

		local data = {
			['filterType'] 	= filterType,
			['name'] 		= filterTypeName,
			['customFilterFunctionName'] = customFilterFunctionName
		}
		
		if lastCategory ~= filterData.category then
			lastCategory = filterData.category
			listType = HEADER_TYPE
			data.header = filterData.category
		end
			
		local newData = ZO_ScrollList_CreateDataEntry(listType, data)
		tins(dataList, newData)
	end
	ZO_ScrollList_Commit(enableList)
end

local function setButtonToggleColor(control, filtered)
	control:SetAlpha((filtered and 1) or 0.4)
	control._selected = filtered
end

local function hasUnenabledFilters()
	for i=1, #filterTypesToCategory do
		local filterType = filterTypesToCategory[i].filterType
		if not enabledFilters[filterType] then
			return true
		end
	end
	return false
end

local function addAll()
	for i=1, #filterTypesToCategory do
		local filterType = filterTypesToCategory[i].filterType
		if not enabledFilters[filterType] then
			enabledFilters[filterType] = true
		end
	end
	refreshEnableList()
	refreshUpdateList()
	
	useFilter = false
	setButtonToggleColor(btnFilter, useFilter)
end

local function clearAll(disableCustomFilters)
	disableCustomFilters = disableCustomFilters or false
	local filterTypes = {}
	for filterType, enabled in pairs(enabledFilters) do
		if enabled then
			enabledFilters[filterType] = false
		end
	end
	if disableCustomFilters == true then
		for i=1, #filterTypesToCategory do
			local filterType = filterTypesToCategory[i].filterType
			tins(filterTypes, filterType)
		end
		tins(filterTypes, LF_FILTER_ALL)
		updateCustomFilterFunction(filterTypes, nil, nil)
	end
	refreshEnableList()
	refreshUpdateList()

	useFilter = false
	setButtonToggleColor(btnFilter, useFilter)
end

local function allButtonToggle()
	if hasUnenabledFilters() then
		addAll()
	else
		clearAll(false)
	end
end

local function updateCurrentFilterPanelLabel(stateStr)
--d("!!! updateCurrentFilterPanelLabel - state: " ..tos(stateStr))
	if currentFilterPanelLabel == nil then return end
	local currentFilterPanelName
	if stateStr == SCENE_SHOWN then
		local currentFilterPanel = libFilters._currentFilterType
		if (currentFilterPanel == nil or currentFilterPanel == 0) then return end
		currentFilterPanelName = libFilters_GetFilterTypeName(libFilters, currentFilterPanel)
		if currentFilterPanelName == nil then currentFilterPanelName = "unknown" end
	else
		currentFilterPanelName = ""
	end
	currentFilterPanelLabel:SetText("Current panel: " .. tos(currentFilterPanelName))
end

local helpWasNotShownYet = true
local function toggleUI(numRetTab, doCloseOverride)
	doCloseOverride = doCloseOverride or false
	if not tlw:IsHidden() then
		if doCloseOverride == true or (numRetTab ~= nil and numRetTab < 2) then
			clearAll()
			tlw:SetHidden(true)
			return
		end
	end
	if helpWasNotShownYet then
		d(prefixBr .. "==============================\n" .. helpUIInstructions .. "==============================\n")
		helpWasNotShownYet = false
	end

	tlw:SetHidden(false)
	refreshEnableList()
end

local function intializeFilterUI()
	local _, height = GuiRoot:GetDimensions()
	local adjustedHeight = (height * 0.75)
	local y_Adj = (height - adjustedHeight) / 2

	tlw = CreateTopLevelWindow("LibFilters_Test_TLW")
	libFilters.test.tlw = tlw
	tlw:SetHidden(true)

	tlw:SetMouseEnabled(true)
	tlw:SetMovable(true)
	tlw:SetClampedToScreen(true)
	tlw:SetDimensions(350, adjustedHeight)

	local left = svTest.testUI.left
	local top = svTest.testUI.top
	if left == nil or top == nil then
		tlw:SetAnchor(TOPRIGHT, GuiRoot, TOPRIGHT, nil, y_Adj)
	else
		tlw:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
	end

	local backdrop = CreateControlFromVirtual("$(parent)Bg", tlw, "ZO_DefaultBackdrop")
	backdrop:SetAnchorFill()
	tlw:SetHandler("OnMouseEnter", function()
		ZO_Tooltips_ShowTextTooltip(tlw, LEFT, helpUIInstructions)
	end)
	tlw:SetHandler("OnMouseExit", function()
		ZO_Tooltips_HideTextTooltip()
	end)
	tlw:SetHandler("OnMoveStop", function()
		svTest.testUI.left = tlw:GetLeft()
		svTest.testUI.top  = tlw:GetTop()
	end)

	--Create the current filterPanel label
	currentFilterPanelLabel = CreateControlFromVirtual("$(parent)CurrentFilterPanelLabel", tlw, "LibFilters_Test_CurrentFilterPanelTemplate")
	currentFilterPanelLabel:SetDimensions(345, 25)
	currentFilterPanelLabel:SetAnchor(TOPLEFT, tlw, nil, 5, 5)
	currentFilterPanelLabel:SetText("Current panel: ")
	updateCurrentFilterPanelLabel(SCENE_SHOWN)

	-- create main LF_constants list
	-- this list is used to enable/disable LF_constants filters
	enableList = CreateControlFromVirtual("$(parent)EnableList", tlw, "ZO_ScrollList")
	enableList:SetDimensions(345, adjustedHeight * 0.5)
	enableList:SetAnchor(TOPLEFT, currentFilterPanelLabel, BOTTOMLEFT, -5, 0)

	-- button container for clear and refresh
	local buttons = CreateControl("$(parent)Buttons", tlw, CT_CONTROL)
	buttons:SetDimensions(340, 80)
	buttons:SetAnchor(TOP, enableList, BOTTOM, 3, 15)
	local buttonshBackdrop = CreateControlFromVirtual("$(parent)Bg", buttons, "ZO_DefaultBackdrop")
	buttonshBackdrop:SetAnchorFill()

	-- create All button
	-- enable all filters if any are not enabled, else disables all filters
	local btnAll = CreateControlFromVirtual("$(parent)AllButton", buttons, "ZO_DefaultButton")
	btnAll:SetHidden(false)
	btnAll:SetText(GetString(SI_BUFFS_OPTIONS_ALL_ENABLED))
	btnAll:SetDimensions(100, 40)
	btnAll:SetAnchor(TOPLEFT, buttons, TOPLEFT, 0, 8)
	btnAll:SetHandler("OnMouseUp", function(btn)
		allButtonToggle()
	end)

	-- create Filter button
	-- enable/disable active filters to allow various update results
	btnFilter = CreateControlFromVirtual("$(parent)FilterButton", buttons, "LibFilters_Test_DefaultButton")
	btnFilter:SetHidden(false)
	btnFilter:SetText(GetString(SI_GAMEPAD_BANK_FILTER_HEADER))
	btnFilter:SetDimensions(100, 40)
	btnFilter:SetAnchor(TOP, buttons, TOP, -20, 8)
	setButtonToggleColor(btnFilter, useFilter)
	btnFilter:SetHandler("OnMouseUp", function(btn)
		useFilter = not useFilter
		setButtonToggleColor(btnFilter, useFilter)
	end)

	-- create Refresh button
	-- refresh list of LF_constants update functions and enable/disable LF_constants filters based on selections in enableList
	local btnRefresh = CreateControlFromVirtual("$(parent)RefreshButton", buttons, "ZO_DefaultButton")
	btnRefresh:SetHidden(false)
	btnRefresh:SetText(GetString(SI_APPLY))
	btnRefresh:SetDimensions(150, 40)
	btnRefresh:SetAnchor(TOPRIGHT, buttons, TOPRIGHT, 0, 8)
	btnRefresh:SetHandler("OnMouseUp", function(btn)
		refreshUpdateList()
	end)

	--The custom filterFunction edit box
	customFilterFunctionEdit = CreateControlFromVirtual("$(parent)CustomFilterFunctionEdit", buttons, "LibFilters_Test_FilterFunction_Edit_Template")
	customFilterFunctionEdit:SetHidden(false)
	customFilterFunctionEdit:SetDimensions(318, 25)
	customFilterFunctionEdit:SetAnchor(TOPLEFT, btnAll, BOTTOMLEFT, 5, 3)
	customFilterFunctionEdit:SetHandler("OnTextChanged", function(selfEdit)
		ZO_EditDefaultText_OnTextChanged(selfEdit)
	end )
	customFilterFunctionEdit:SetHandler("OnMouseEnter", function()
		ZO_Tooltips_ShowTextTooltip(tlw, LEFT, helpUICustomFilterFunctions)
	end)
	customFilterFunctionEdit:SetHandler("OnMouseExit", function()
		ZO_Tooltips_HideTextTooltip()
	end)


	customFilterFunctionEdit.saveButton = GetControl(customFilterFunctionEdit:GetName(), "SaveButton")
	customFilterFunctionEdit.saveButton.OnClickedCallback = function(selfButton)
		customFilterFunctionEdit:LoseFocus()
		local refreshNeeded = false
		local filterFunctionName = customFilterFunctionEdit:GetText()
		if not filterFunctionName then return end

		local filterTypes = {}
		local usingLfAll = true
		--Check if any filterType is selected at the upper enableList
		local dataList = ZO_ScrollList_GetDataList(enableList)
		for i=1, #dataList do
			local dataOfEnableListEntry = dataList[i]
			local data = dataOfEnableListEntry.data
			local filterType = data.filterType
			--Check if the entry of the enabledList is currently selected
			local isSelected = enabledFilters[filterType] or false
			if isSelected == true then
				tins(filterTypes, filterType)
				usingLfAll = false
			end
		end
		if #filterTypes == 0 then
			tins(filterTypes, LF_FILTER_ALL)
			usingLfAll = true
		end
		local filterTypesSelectedStr = (usingLfAll == true and "ALL") or "selected"

		--Reset to default filterFunction?
		if filterFunctionName == "" then
			if not allCustomFilterFunctionsDisabled then
				d(strfor(prefixBr.. "resetting filter function for %s filterTypes to default", filterTypesSelectedStr))
				updateCustomFilterFunction(filterTypes, nil, nil)
				refreshNeeded= true
			end
			if usingLfAll == true then
				allCustomFilterFunctionsDisabled = true
			else
				checkIfAllCustomFilterFunctionsDisabled()
			end
		else
			--Apply custom global filterFunction
			local filterFunction = _G[filterFunctionName]
			if filterFunction == nil or type(filterFunction) ~= "function" then
				d(strfor(prefixBr.. "ERROR -  global filter function %q does not exist!", filterFunctionName))
				return
			end
			d(strfor(prefixBr.. "Setting filter function %q for %s filterTypes", filterFunctionName, filterTypesSelectedStr))
			updateCustomFilterFunction(filterTypes, filterFunction, filterFunctionName)
			allCustomFilterFunctionsDisabled = false
			refreshNeeded= true
		end
		if refreshNeeded then
			refreshEnableList()
			--refreshUpdateList()
		end
	end
	customFilterFunctionEdit.saveButton.data = {
		tooltipText = "Enter a global filterFunction name, without specifying the () or the parameters.\nNeeded parameters at the filterFunction are \'bagId, slotIndex\'.\n\nClicking on the \'OK\' button will set the filterFunction to all selected (upper list) filterTypes.\nIf no filterType is selected the filterFunction will be applied to all filterTypes!\n\nLeave the edit field empty to set the default filterFunction again."
	}
	customFilterFunctionEdit.saveButton:SetHandler("OnMouseEnter", 	ZO_Options_OnMouseEnter)
	customFilterFunctionEdit.saveButton:SetHandler("OnMouseExit", 	ZO_Options_OnMouseExit)

	-- create list for LF_constants update functions
	local ul_Height = tlw:GetBottom() - buttons:GetBottom() - 15
	updateList = CreateControlFromVirtual("$(parent)UpdateList", tlw, "ZO_ScrollList")
	updateList:SetDimensions(345, ul_Height)
	updateList:SetAnchor(TOP, buttons, BOTTOM, 0, 0)

	--Close button
	closeUIButton =  CreateControlFromVirtual("$(parent)CloseUIButton", tlw, "LibFilters_Test_CloseButton")
	closeUIButton:SetDimensions(24, 24)
	closeUIButton:SetAnchor(BOTTOMRIGHT, tlw, TOPRIGHT, 6, 4)
	closeUIButton.OnClickedCallback = function()
		toggleUI(nil, true)
	end

	-- initialize lists
	ZO_ScrollList_Initialize(enableList)
	enableList:SetMouseEnabled(true)
	ZO_ScrollList_Initialize(updateList)
end

local function setupRow(rowControl, data, onMouseUp)
	rowControl.data = data
	local filterType = data.filterType
	local rowButton  = rowControl:GetNamedChild("Button")

	data.tooltiptext = nil
	local customFilterFunctionName = data.customFilterFunctionName
	local customFilterFunctionSuffix = ""
	if customFilterFunctionName ~= nil and customFilterFunctionName ~= "" then
		customFilterFunctionSuffix = " " .. customFilterFunctionTag
		data.tooltipText = "Uses custom filterFunction:\' " ..tos(customFilterFunctionName) .. "\'"
	end
	rowButton:SetText(data.name .. " [" ..tos(filterType) .. "]" .. customFilterFunctionSuffix)

	rowControl:SetHidden(false)
	setButtonToggleColor(rowControl:GetNamedChild("Button"), enabledFilters[filterType])

	rowButton:SetHandler("OnMouseUp", 	onMouseUp)
	rowButton:SetHandler("OnMouseEnter", function(rowBtnCtrl)
		if rowControl.data and rowControl.data.tooltipText then
			ZO_Options_OnMouseEnter(rowControl)
		else
			ZO_Options_OnMouseExit(rowControl)
		end
	end)
	rowButton:SetHandler("OnMouseExit", 	ZO_Options_OnMouseExit)
end

local function addFilterUIListDataTypes()
	local function onMouseUpOnRow(rowControl, data)
		local filterType = data.filterType
		enabledFilters[filterType] = not enabledFilters[filterType]
		setButtonToggleColor(rowControl:GetNamedChild("Button"), enabledFilters[filterType])
	end
	local function setupEnableRowWithHeader(rowControl, data, selected, selectedDuringRebuild, enabled, activated)
		local header = rowControl:GetNamedChild('Header')
		header:SetText(data.header)
		header:SetHidden(false)
		setupRow(rowControl, data, function(btn)
			onMouseUpOnRow(rowControl, data)
		end)
	end
	local function setupEnableRow(rowControl, data, selected, selectedDuringRebuild, enabled, activated)
		setupRow(rowControl, data, function(btn)
			onMouseUpOnRow(rowControl, data)
		end)
	end

 	local function setupUpdateRow(rowControl, data)
		setupRow(rowControl, data, function(btn)
			local filterType = data.filterType
			local customFilterFunctionName = data.customFilterFunctionName
			local customFilterFunctionSuffix = ""
			if customFilterFunctionName ~= nil and customFilterFunctionName ~= "" then
				customFilterFunctionSuffix = ", custom filterFunction: \'" .. customFilterFunctionName .. "\'"
			end
			d(prefixBr .. "- Requesting update for filterType \'" .. tos(data.name) .. "\' [" .. tos(filterType) .. "]" .. customFilterFunctionSuffix)
			libFilters_RequestUpdate(libFilters, filterType)
		end)
	end
		
	ZO_ScrollList_AddDataType(updateList, LIST_TYPE, testUItemplate, 40, setupUpdateRow)
	ZO_ScrollList_AddDataType(enableList, LIST_TYPE, testUItemplate, 40, setupEnableRow)
	ZO_ScrollList_AddDataType(enableList, HEADER_TYPE, testUItemplate .. "_WithHeader", 80, setupEnableRowWithHeader)
end

local function callbackFunctionForPanelShowOrHide(filterTypeName, filterType, stateStr, isInGamepadMode, fragmentOrSceneOrControl, lReferencesToFilterType)
	local filterTypeNameStr = filterTypeName .. " [" .. tos(filterType) .. "]"
	d(prefixBr .. "callback - filterType: " .. filterTypeNameStr .. ", state: " .. stateStr)
	updateCurrentFilterPanelLabel(stateStr)
end

local function enableFilterTypeCallbacks()
	local libFiltersFilterConstants = libFilters.constants.filterTypes
	--For each filterType register a stateChange for show/hidestate change
	for filterType, filterTypeName in ipairs(libFiltersFilterConstants) do
		--Shown callbacks
		local callbackName = libFilters_CreateCallbackName(libFilters, filterType, true)
		CM:RegisterCallback(callbackName, function(...) callbackFunctionForPanelShowOrHide(filterTypeName, ...) end)
		--Hidden callbacks
		callbackName = libFilters_CreateCallbackName(libFilters, filterType, false)
		CM:RegisterCallback(callbackName, function(...) callbackFunctionForPanelShowOrHide(filterTypeName, ...) end)
	end
end

local function parseArguments(args, slashCommand)
	local retTab = {}
    local elements = {}
    for param in strgm(args, "([^%s.]+)%s*") do
        if param ~= nil and param ~= "" then
            tins(elements, param)
        end
    end
	local numElements = #elements
	libFilters.test.slashCommandParams = elements

	--Slash command check
	if slashCommand == "lftestfilters" then
		local filterType, filterFunctionName
		--Parameter checks
		--No filterType is given, only a function was specified?
		if numElements == 1 then
			retTab[1] = LF_FILTER_ALL --specify that the function is to be used for all LF_* constants

			filterFunctionName = elements[1]
			if filterFunctionName ~= nil and _G[filterFunctionName] ~= nil and type(_G[filterFunctionName]) == "function" then
				retTab[2] = filterFunctionName
			elseif filterFunctionName ~= nil and filterFunctionName == "" then
				retTab[2] = ""
			else
				d(strfor(prefixBr.. "ERROR -  filterFunction %q does not exist!", tos(filterFunctionName)))
				return { }
			end

		--FilterType LF* and filterFunction were both given
		elseif numElements == 2 then
			filterType = tonumber(elements[1])
			if filterType ~= nil and type(filterType) == "number" and filterType >= LF_FILTER_MIN and filterType <= LF_FILTER_MAX then
				retTab[1] = filterType
			else
				d(strfor(prefixBr.. "ERROR -  filterType %q does not exist!", tos(filterType)))
				return { }
			end

			filterFunctionName = elements[2]
			if filterFunctionName ~= nil and _G[filterFunctionName] ~= nil and type(_G[filterFunctionName]) == "function" then
				retTab[2] = filterFunctionName
			elseif filterFunctionName ~= nil and filterFunctionName == "" then
				retTab[2] = ""
			else
				d(strfor(prefixBr.. "ERROR -  filterFunction %q does not exist!", tos(filterFunctionName)))
				return { }
			end
		end
	end
	return retTab
end

------------------------------------------------------------------------------------------------------------------------
-- SLASH COMMAND for filter UI
------------------------------------------------------------------------------------------------------------------------
SLASH_COMMANDS["/lftestfilters"] = function(args)
--[[ is there a way to check if a virtual control exists?
	-- is test.xml enabled
	if not LibFilters3_Test_Template then
		d( "Enable test.xml in manifest")
		return
	end
]]

	--Get SavedVariables
	LIBFILTERS_SV_TEST = LIBFILTERS_SV_TEST or {}
	svTest = LIBFILTERS_SV_TEST
	svTest._lastAccount = 	GetDisplayName()
	svTest._lastCharacter = ZO_CachedStrFormat(SI_UNIT_NAME, GetUnitName("player"))
	svTest._lastLoaded = 	os.date("%c", GetTimeStamp())
	svTest.testUI = svTest.testUI or {}

	if not tlw then
		checkIfInitDone()
		intializeFilterUI()
		addFilterUIListDataTypes()
		enableFilterTypeCallbacks()
	end

	--Parse the slash commands for LF_* filter constant (optional! If not given LF_FILTER_ALL will be used) and a
	--custom global filterFunction to use
	local retTab = parseArguments(args, "lftestfilters")
	local numRetTab = (retTab == nil and 0) or #retTab
	if numRetTab == 2 then
		local filterType = retTab[1]
		local filterFunctionName = retTab[2]
		--local refreshNeeded = false
		--Reset to default filterFunction?
		if filterFunctionName == "" then
			if not allCustomFilterFunctionsDisabled then
				d(strfor(prefixBr.. "resetting filter function for filterType %s to default", tos(filterType)))
				updateCustomFilterFunction({ filterType }, nil, nil)
				--refreshNeeded = true
			end
			if filterType == LF_FILTER_ALL then
				allCustomFilterFunctionsDisabled = true
			else
				checkIfAllCustomFilterFunctionsDisabled()
			end
		else
			local filterFunction = _G[filterFunctionName]
			if filterFunction == nil or type(filterFunction) ~= "function" then
				d(strfor(prefixBr.. "ERROR -  global filter function %q does not exist!", filterFunctionName))
				return
			end
			d(strfor(prefixBr.. "Setting filter function %q for %s filterTypes", filterFunctionName, filterTypesSelectedStr))
			updateCustomFilterFunction({ filterType }, filterFunction, filterFunctionName)
			allCustomFilterFunctionsDisabled = false
			refreshNeeded = true
		end
		--if refreshNeeded then
			--refreshEnableList()
			--refreshUpdateList()
		--end
	end

	toggleUI(numRetTab, false)
end
--	/script testFilter = function(bagId, slotIndex) if slotIndex == 1 then return false end return true end
--	/lftestfilters testFilter

------------------------------------------------------------------------------------------------------------------------
-- Custom SLASH COMMANDS for tests
------------------------------------------------------------------------------------------------------------------------
--depends on Item Saver by Randactyl
--[[
SLASH_COMMANDS["/lftestenchant"] = function()
	if not ItemSaver then return end
	checkIfInitDone()

	local isRegistered = libFilters_IsFilterRegistered(libFilters, filterTag, LF_ENCHANTING_CREATION)

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
		libFilters_RegisterFilter(libFilters, filterTag, LF_ENCHANTING_CREATION, filterCallback)
		libFilters_RequestUpdate(libFilters, LF_ENCHANTING_CREATION)
		libFilters_RegisterFilter(libFilters, filterTag, LF_ENCHANTING_EXTRACTION, filterCallback)
		libFilters_RequestUpdate(libFilters, LF_ENCHANTING_EXTRACTION)
	else
		libFilters_UnregisterFilter(libFilters, filterTag, LF_ENCHANTING_CREATION)
		libFilters_RequestUpdate(libFilters, LF_ENCHANTING_CREATION)
		libFilters_UnregisterFilter(libFilters, filterTag, LF_ENCHANTING_EXTRACTION)
		libFilters_RequestUpdate(libFilters, LF_ENCHANTING_EXTRACTION)
	end
end
]]


--testing Gamepad research dialog confirm scene: Add [2] to GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE.callbackRegistry.StateChange
-->The index [1] in GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE.callbackRegistry.StateChange is the original state change of ZOs vailla UI and should trigger the
-->refresh of the scene's list contents
--> See here: esoui/ingame/crafting/gamepad/smithingresearch_gamepad.lua
-->GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE:RegisterCallback("StateChange", function(oldState, newState)
--[[
local researchConfirmSceneCallbackAdded = false
SLASH_COMMANDS["/lftestresearchdialog"] = function()
	if researchConfirmSceneCallbackAdded then return end
	checkIfInitDone()
	GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE:RegisterCallback("StateChange", function(oldState, newState)
		d("GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE [2] - StateChange: " ..strfor("oldState: %s, newState: %s", tos(oldState), tos(newState)))
	end)
	local origStateChangeFunc = GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE.callbackRegistry.StateChange[1][1]
	GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE.callbackRegistry.StateChange[1][1] = function(...)
		local oldState, newState = select(1, ...)
		d("ORIG: - GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE [1] - StateChange: " ..strfor("oldState: %s, newState: %s", tos(oldState), tos(newState)))
		origStateChangeFunc(...)
	end
	d(prefixBr .. "Test scene callback for Gamepad research confirm scene was added! ReloadUI to remove it.")
	researchConfirmSceneCallbackAdded = true
end
]]

------------------------------------------------------------------------------------------------------------------------
-- SLASH COMMANDS for toggle & update tests
------------------------------------------------------------------------------------------------------------------------
--Alchemy
--[[
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
]]
