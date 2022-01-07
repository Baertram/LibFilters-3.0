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

local CM = CALLBACK_MANAGER

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
local prefixBr = "[" .. prefix .. "]"
local testUItemplate = "LibFilters_Test_Template"

local filterTag = prefix .."_TestFilters_"
local filterTypeToFilterFunctionType = libFilters.mapping.filterTypeToFilterFunctionType
local LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT = libFilters.constants.LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT


--UI
libFilters.test = {}
local tlw
local tlc
local btnFilter


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
	checkIfInitDone()

	noUpdate = noUpdate or false
	local filterTypeName = libFilters_GetFilterTypeName(libFilters, filterType)
	local filterFunc = (filterTypeToFilterFunctionType[filterType] == LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT and filterFuncForInventories) or filterFuncForCrafting

	if libFilters_IsFilterRegistered(libFilters, filterTag, filterType) then
		libFilters_UnregisterFilter(libFilters, filterTag, filterType)
		d("<"..prefixBr .. "Test filter for \'" .. filterTypeName .. "\'  unregistered!")
	else
		libFilters_RegisterFilter(libFilters, filterTag, filterType, function(...) filterFunc(...) end)
		d(">" ..prefixBr .. "Test filter for \'" .. filterTypeName .. "\' registered!")
	end
	if noUpdate then return end
	libFilters_RequestUpdate(libFilters, filterType)
end

--	LibFilters3_Test_TLC

------------------------------------------------------------------------------------------------------------------------
-- TEST UI
------------------------------------------------------------------------------------------------------------------------
local helpUIInstructionsParts = {
	"Select any number of LF_* constants in the top list. Clicking them will enable them. Clicking them again will disable them.",
	"Use \'"..GetString(SI_APPLY).."\' button to register the selected filters and populate the registered LF_* constants at the bottom list.", --"Apply" button
	"At any time, LF_* constants can be added or removed by clicking the LF_* constant in the top list and pressing " .. GetString(SI_APPLY) .. ".",
	"The \'".. GetString(SI_GAMEPAD_BANK_FILTER_HEADER) .."\' button enables/disables filtering of the registered filters.", --"Filter" button
	"The bottom list LF_* constants buttons will call the filter refresh for that button, if you click it.",
	"With a scene containing a filterable inventory, enable/disable filtering and press the according LF_* button in the bottom",
	"list. Chat output will show you some information if the default filterFunction of test.lua is used (\'/test/test.lua/defaultFilterFunction\').",
	"The \'".. GetString(SI_BUFFS_OPTIONS_ALL_ENABLED) .."\' button, will enable/disable all LF_* constants", --"All" button
	"Use /lftestfilters without any parameters to open the test UI",
	"Use /lftestfilters <LF_constant_to_add> <globalFilterFunctionToUseForThatLF_Constant> to register a special filterFunction for the provided LF_Constants",
	"e.g. /lftestfilters LF_SMITHIG_REFINE MyGlobalAddonVar.filterFunctionForSmithingRefine",
	"Use /lftestfilters without any parameter again to close the UI and unregister all registered LF_* constants",
}
local helpUIInstructions = gTab.concat(helpUIInstructionsParts, "\n")

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
local useFilter = false

--Via slash command added filter functions for the LF_* constants
local testAdditionalFilterFunctions = {
	--example
	--[LF_INVENTORY] = globalFunctionNameFromSlashCommend_lftestfilters_parameter1
	--If [LF_FILTER_ALL] is added this is the filterFunction to use for all LF_ constants!
}
libFilters.test.additionalFilterFunctions = testAdditionalFilterFunctions

--The default filter function to use. Generalized to be compatible with inventorySlots and bagId/slotIndex parameters (crafting tables e.g.)
--Will filter depending on the itemType and hide items with quality below "blue"
--and if weapons/armor also if it's locked by ZOs vanilla UI lock functionality and non companion items
--and poisons or potions or reagents by their stackCount <= 100
local useDefaultFilterFunction = false
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

local filterChatOutputPerItemDefaultStr = "--test, itemLink: %s, stackCount:( %s ), bagId/slotIndex: (%s/%s), filterType:( %s )"
local filterChatOutputPerItemCustomStr = "--test, itemLink: %s, bagId/slotIndex: (%s/%s), filterType:( %s )"
local function resultCheckFunc(p_result, p_filterTypeName, p_useDefaultFilterFunction, p_bagId, p_slotIndex, p_itemLink, p_stackCount)
	if p_result == true then return end
	if p_useDefaultFilterFunction then
		-- can take a moment to display for research, has a low filter threshold
		d(strfor(filterChatOutputPerItemDefaultStr, p_itemLink, tos(p_stackCount), tos(p_bagId), tos(p_slotIndex), p_filterTypeName))
	else
		d(strfor(filterChatOutputPerItemCustomStr, p_itemLink, tos(p_bagId), tos(p_slotIndex), p_filterTypeName))
	end
end

local function registerFilter(filterType, filterTypeName)
	--Use the custom registered filterFunction for the LF_ filter constant, or a registered filterFunction for all LF_ constants,
	--or use the default filterFunction "defaultFilterFunction" of this test file
	local testAdditionalFilterFunctionToUse = testAdditionalFilterFunctions[filterType] or testAdditionalFilterFunctions[LF_FILTER_ALL]
	if testAdditionalFilterFunctionToUse == nil then
		useDefaultFilterFunction = true
		testAdditionalFilterFunctionToUse = defaultFilterFunction
	else
		useDefaultFilterFunction = false
	end

	local function filterBagIdAndSlotIndexCallback(bagId, slotIndex)
		if not useFilter then return true end
		local itemLink = GetItemLink(bagId, slotIndex)
		local stackCountBackpack, stackCountBank, stackCountCraftBag = GetItemLinkStacks(itemLink)
		local stackCount = stackCountBackpack + stackCountBank + stackCountCraftBag

		local result = testAdditionalFilterFunctionToUse(bagId, slotIndex, stackCount)
		resultCheckFunc(result, filterTypeName, useDefaultFilterFunction, bagId, slotIndex, itemLink, stackCount)
		return result
	end

	local function filterSlotDataCallback(slotData)
		if not useFilter then return true end
		local bagId, slotIndex = slotData.bagId, slotData.slotIndex
		local itemLink = bagId == nil and GetQuestItemLink(slotIndex) or GetItemLink(bagId, slotIndex)
		local stackCountBackpack, stackCountBank, stackCountCraftBag = GetItemLinkStacks(itemLink)
		local stackCount = stackCountBackpack + stackCountBank + stackCountCraftBag

		local result = testAdditionalFilterFunctionToUse(bagId, slotIndex, stackCount)
		resultCheckFunc(result, filterTypeName, useDefaultFilterFunction, bagId, slotIndex, itemLink, stackCount)
		return result
	end

	local usingBagAndSlot = usingBagIdAndSlotIndexFilterFunction[filterType]
	d(prefixBr .. "TEST - Registering " .. filterTypeName .. " [" ..tos(filterType) .."], filterFunction: " .. (useDefaultFilterFunction and "default") or "custom" .. ", invSlotFilterFunction: " .. tos(not usingBagAndSlot))
	libFilters_RegisterFilter(libFilters, filterTag, filterType, (usingBagAndSlot and filterBagIdAndSlotIndexCallback) or filterSlotDataCallback)

	return useDefaultFilterFunction
end

local function refresh(dataList)
	for _, filterData in pairs(filterTypesToCategory) do
		local filterType = filterData.filterType
		local isRegistered = libFilters_IsFilterRegistered(libFilters, filterTag, filterType)
		local filterTypeName = libFilters_GetFilterTypeName(libFilters, filterType)
		local usesDefaultFilterFunction = false
		if enabledFilters[filterType] == true then
			if not isRegistered then
				usesDefaultFilterFunction = registerFilter(filterType, filterTypeName)
			end
			if usesDefaultFilterFunction == false then
				filterTypeName = filterTypeName .. " - Custom"
			end

			local data = {
				['filterType'] 	= filterType,
				['name'] 		= filterTypeName
			}
			tins(dataList, ZO_ScrollList_CreateDataEntry(LIST_TYPE, data))

		elseif isRegistered then
			d(prefixBr .. "TEST - Unregistering " .. filterTypeName .. " [" ..tos(filterType) .."]")
			libFilters_UnregisterFilter(libFilters, filterTag, filterType)
		end
	end
end

local function refreshUpdateList()
	ZO_ScrollList_Clear(updateList)
	refresh(ZO_ScrollList_GetDataList(updateList))
	ZO_ScrollList_Commit(updateList)
	
	-- changing hidden state to make the scrollbar show. Otherwise updateList's scrollbar will not show 
	-- if the list was not populated with enough items prior to enabling /lftestfilters
	tlw:SetHidden(true)
	tlw:SetHidden(false)
end

local function refreshEnableList()
	local lastCategory = ''
	
	ZO_ScrollList_Clear(enableList)
	local dataList = ZO_ScrollList_GetDataList(enableList)
	for _, filterData in pairs(filterTypesToCategory) do
		local listType = LIST_TYPE
		local filterType = filterData.filterType
		local filterTypeName = libFilters_GetFilterTypeName(libFilters, filterType)
		
		local data = {
			['filterType'] 	= filterType,
			['name'] 		= filterTypeName
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
libFilters.test.buttonControl = control
	control:SetAlpha((filtered and 1) or 0.4)
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

local function clearAll()
	for filterType, enabled in pairs(enabledFilters) do
		if enabled then
			enabledFilters[filterType] = false
		end
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
		clearAll()
	end
end

local function updateCurrentFilterPanelLabel(stateStr)
d("!!! updateCurrentFilterPanelLabel - state: " ..tos(stateStr))
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
	currentFilterPanelLabel:SetText("Current filterPanel: " .. tos(currentFilterPanelName))
end

local function intializeFilterUI()
	local _, height = GuiRoot:GetDimensions()
	local adjustedHeight = (height * 0.75)
	local y_Adj = (height - adjustedHeight) / 2
	
    tlw = CreateTopLevelWindow("LibFilters_Test_TLW")
	libFilters.test.tlw = tlw
	tlw:SetHidden(true)

	tlc = CreateControl("LibFilters_Test_TLC", tlw, CT_TOPLEVELCONTROL)
	libFilters.test.tlc = tlc
	tlc:SetMouseEnabled(true)
	tlc:SetMovable(true)
	tlc:SetClampedToScreen(true)
	tlc:SetDimensions(350, adjustedHeight)
	tlc:SetAnchor(TOPRIGHT, GuiRoot, TOPRIGHT, nil, y_Adj)
    local backdrop = CreateControlFromVirtual("$(parent)Bg", tlc, "ZO_DefaultBackdrop")
	backdrop:SetAnchorFill()
	tlc:SetHandler("OnMouseEnter", function()
		ZO_Tooltips_ShowTextTooltip(tlc, LEFT, helpUIInstructions)
	end)
	tlc:SetHandler("OnMouseExit", function()
		ZO_Tooltips_HideTextTooltip()
	end)

	--Create the current filterPanel label
	currentFilterPanelLabel = CreateControlFromVirtual("$(parent)CurrentFilterPanelLabel", tlc, "LibFilters_Test_CurrentFilterPanelTemplate")
	currentFilterPanelLabel:SetDimensions(345, 25)
	currentFilterPanelLabel:SetAnchor(TOPLEFT, tlc, nil, 5, 5)
	currentFilterPanelLabel:SetText("Current filterPanel: ")
	updateCurrentFilterPanelLabel(SCENE_SHOWN)

	-- create main LF_constants list
	-- this list is used to enable/disable LF_constants filters
	enableList = CreateControlFromVirtual("$(parent)EnableList", tlc, "ZO_ScrollList")
	enableList:SetDimensions(345, adjustedHeight * 0.5)
	enableList:SetAnchor(TOPLEFT, currentFilterPanelLabel, BOTTOMLEFT, -5, 0)
	
	-- button container for clear and refresh
	local buttons = CreateControl("$(parent)Buttons", tlc, CT_CONTROL)	
	buttons:SetDimensions(340, 60)
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
	
	-- create list for LF_constants update functions
	local ul_Hight = tlc:GetBottom() -  buttons:GetBottom() - 15
	updateList = CreateControlFromVirtual("$(parent)UpdateList", tlc, "ZO_ScrollList")
	updateList:SetDimensions(345, ul_Hight)
	updateList:SetAnchor(TOP, buttons, BOTTOM, 0, 0)

	-- initialize lists
	ZO_ScrollList_Initialize(enableList)
	enableList:SetMouseEnabled(true)
	ZO_ScrollList_Initialize(updateList)
	
--	tlc:SetHidden(true)
end

local function setupRow(rowControl, data, onMouseUp)
	rowControl.data = data
	local filterType = data.filterType
	local row = rowControl:GetNamedChild("Button")
	row:SetText(data.name .. " [" ..tos(filterType) .. "]")
	
	rowControl:SetHidden(false)
	setButtonToggleColor(rowControl:GetNamedChild("Button"), enabledFilters[filterType])
	
	row:SetHandler("OnMouseUp", onMouseUp)
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
			d(prefixBr .. "TEST - Requesting update for filterType \'" .. tos(data.name) .. "\' [" .. tos(filterType) .. "]")
			libFilters_RequestUpdate(libFilters, filterType)
		end)
	end
		
	ZO_ScrollList_AddDataType(updateList, LIST_TYPE, testUItemplate, 40, setupUpdateRow)
	ZO_ScrollList_AddDataType(enableList, LIST_TYPE, testUItemplate, 40, setupEnableRow)
	ZO_ScrollList_AddDataType(enableList, HEADER_TYPE, testUItemplate .. "_WithHeader", 80, setupEnableRowWithHeader)
end

local function callbackFunctionForPanelShowOrHide(filterTypeName, filterType, stateStr, isInGamepadMode, fragmentOrSceneOrControl, lReferencesToFilterType)
	local filterTypeNameStr = filterTypeName .. " [" .. tos(filterType) .. "]"
	d(prefixBr .. "TEST callback - filterType: " .. filterTypeNameStr .. ", state: " .. stateStr)
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
		local filterType, filterFunction
		--Parameter checks
		--No filterType is given, only a function was specified?
		if numElements == 1 then
			filterFunction = elements[1]
			if filterFunction and type(filterFunction) == "function" then
				retTab[1] = LF_FILTER_ALL --specify that the function is to be used for all LF_* constants
				retTab[2] = filterFunction
			end
		--FilterType LF* and filterFunction were both given
		elseif numElements == 2 then
			filterType = elements[1]
			filterFunction = elements[2]
			if filterType ~= nil and type(filterType) == "number" and filterType <= LF_FILTER_MAX
					and filterFunction ~= nil and type(filterFunction) == "function" then
				retTab[1] = filterType
				retTab[2] = filterFunction
			end
		end
	end
	return retTab
end

------------------------------------------------------------------------------------------------------------------------
-- SLASH COMMAND for filter UI
------------------------------------------------------------------------------------------------------------------------
local helpWasNotShownYet = true
SLASH_COMMANDS["/lftestfilters"] = function(args)
--[[ is there a way to check if a virtual control exists?
	-- is test.xml enabled
	if not LibFilters3_Test_Template then
		d( "Enable test.xml in manifest")
		return
	end
]]

	if not tlw then
		checkIfInitDone()
		intializeFilterUI()
		addFilterUIListDataTypes()
		enableFilterTypeCallbacks()
	end

	--Parse the slash commands for LF_* filter constant (optional! If not given LF_FILTER_ALL will be used) and a
	--custom global filterFunction to use
	local retTab = parseArguments(args, "lftestfilters")
	local numRetTab = #retTab
	if retTab and numRetTab == 2 then
		testAdditionalFilterFunctions[retTab[1]] = retTab[2]
		useDefaultFilterFunction = false
	else
		useDefaultFilterFunction = true
	end
	
	if not tlc:IsHidden() then
		clearAll()
		if numRetTab < 2 then
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
