--Init the library, if not already done
local libFilters = LibFilters3
if not libFilters then return end
libFilters:InitializeLibFilters()
 

------------------------------------------------------------------------------------------------------------------------
-- HELPER VARIABLES AND FUNCTIONS FOR TESTS
------------------------------------------------------------------------------------------------------------------------
--Helper varibales for tests
local prefix = libFilters.globalLibName
local testUItemplate = prefix .. "_Test_Template"

local filterTag = prefix .."_TestFilters_"
local filterTypeToFilterFunctionType = libFilters.mapping.filterTypeToFilterFunctionType
local LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT = libFilters.constants.LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT

libFilters.test = {}

local tlw
local tlc

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
		d("<["..prefix.."]Test filter for \'" .. filterTypeName .. "\'  unregistered!")
	else
		libFilters:RegisterFilter(filterTag, filterType, function(...) filterFunc(...) end)
		d(">["..prefix.."]Test filter for \'" .. filterTypeName .. "\' registered!")
	end
	if noUpdate then return end
	libFilters:RequestUpdate(filterType)
end


------------------------------------------------------------------------------------------------------------------------
-- Custom SLASH COMMANDS for tests
------------------------------------------------------------------------------------------------------------------------
local filterTypes = {
	LF_INVENTORY,
	LF_INVENTORY_QUEST,
	LF_CRAFTBAG,
	LF_INVENTORY_COMPANION,

	LF_QUICKSLOT,
	
	LF_BANK_WITHDRAW,
	LF_BANK_DEPOSIT,
	LF_GUILDBANK_WITHDRAW,
	LF_GUILDBANK_DEPOSIT,
	LF_HOUSE_BANK_WITHDRAW,
	LF_HOUSE_BANK_DEPOSIT,
	LF_GUILDSTORE_SELL,

	LF_VENDOR_BUY,
	LF_VENDOR_SELL,
	LF_VENDOR_BUYBACK,
	LF_VENDOR_REPAIR,
	LF_FENCE_SELL,
	LF_FENCE_LAUNDER,
	LF_MAIL_SEND,
	LF_TRADE,

	LF_SMITHING_REFINE,
	LF_SMITHING_CREATION,
	LF_SMITHING_DECONSTRUCT,
	LF_SMITHING_IMPROVEMENT,
	LF_SMITHING_RESEARCH,
	LF_SMITHING_RESEARCH_DIALOG,

	LF_JEWELRY_REFINE,
	LF_JEWELRY_CREATION,
	LF_JEWELRY_DECONSTRUCT,
	LF_JEWELRY_IMPROVEMENT,
	LF_JEWELRY_RESEARCH,
	LF_JEWELRY_RESEARCH_DIALOG,

	LF_ALCHEMY_CREATION,
	LF_ENCHANTING_CREATION,
	LF_ENCHANTING_EXTRACTION,

	LF_RETRAIT,
}


local enabledFilters = {}
local LIST_TYPE = 1
local enableList = {}
local updateList = {}

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

local function registerFilter(filterType, filterTypeName)
	local function filterBagIdAndSlotIndexCallback(bagId, slotIndex)
		local itemLink = GetItemLink(bagId, slotIndex)
		local stackCountBackpack, stackCountBank, stackCountCraftBag = GetItemLinkStacks(itemLink)
		local stackCount = stackCountBackpack + stackCountBank + stackCountCraftBag

		local result = doesItemPassFilter(bagId, slotIndex, stackCount)
		if result == false then
			-- can take a moment to display for research, has a low filter threshold
			d(string.format("--	test, filterType:( %s ), stackCount:( %s ), itemLink: %s", filterType, stackCount, itemLink))
		end
		return result
	end

	local function filterSlotDataCallback(slotData)
		local bagId, slotIndex = slotData.bagId, slotData.slotIndex
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
	
	local usingBagAndSlot = libFilters.constants.filterTypes.UsingBagIdAndSlotIndexFilterFunction[filterType]
	
	d("["..prefix.."]Registering " .. filterTypeName)
	if usingBagAndSlot then
		libFilters:RegisterFilter(filterTag, filterType, filterBagIdAndSlotIndexCallback)
	else
		libFilters:RegisterFilter(filterTag, filterType, filterSlotDataCallback)
	end
end

local function refresh(dataList)
	for _, filterType in pairs(filterTypes) do
		local isRegistered = libFilters:IsFilterRegistered(filterTag, filterType)
		local filterTypeName = libFilters:GetFilterTypeName(filterType)
		
		if enabledFilters[filterType] then
			local data = {
				['filterType'] = filterType,
				['name'] = filterTypeName
			}
			table.insert(dataList, ZO_ScrollList_CreateDataEntry(LIST_TYPE, data))
			if not isRegistered then
				registerFilter(filterType, filterTypeName)
			end
		elseif isRegistered then
			d("["..prefix.."]Unregistering " .. filterTypeName)
			libFilters:UnregisterFilter(filterTag, filterType)
		end
	end
end

local function refreshUpdateList()
	ZO_ScrollList_Clear(updateList)
	refresh(ZO_ScrollList_GetDataList(updateList))
	ZO_ScrollList_Commit(updateList)
	
	-- changing hidden state to make the scrollbar show. Otherwise updateList's scrollbar will not show 
	-- if the list was not populated with enough itmes prior to enabling /lftestfilters
	tlw:SetHidden(true)
	tlw:SetHidden(false)
end

local function refreshEnableList()
	ZO_ScrollList_Clear(enableList)
	local dataList = ZO_ScrollList_GetDataList(enableList)
	for _, filterType in pairs(filterTypes) do
		local filterTypeName = libFilters:GetFilterTypeName(filterType)
		local data = {
			['filterType'] = filterType,
			['name'] = filterTypeName
		}
		
		local newData = ZO_ScrollList_CreateDataEntry(LIST_TYPE, data)
		table.insert(dataList, newData)
	end
	ZO_ScrollList_Commit(enableList)
end

local function clearAll()
	for filterType, bool in pairs(enabledFilters) do
		if bool then
			enabledFilters[filterType] = false
		end
	end
	refreshEnableList()
	refreshUpdateList()
end

local function intialize()
	local width, height = GuiRoot:GetDimensions()
	local adjustedHeight = (height * 0.75)
	local y_Adj = (height - adjustedHeight) / 2
	
    tlw = CreateTopLevelWindow(prefix .. "_Test_TLW")
	libFilters.test.tlw = tlw
	tlw:SetHidden(true)
	
	tlc = CreateControl(prefix .. "_Test_TLC", tlw, CT_TOPLEVELCONTROL)
	libFilters.test.tlc = tlc
	tlc:SetMouseEnabled(true)
	tlc:SetMovable(true)
	tlc:SetClampedToScreen(true)
	tlc:SetDimensions(350, adjustedHeight)
	tlc:SetAnchor(TOPRIGHT, GuiRoot, TOPRIGHT, nil, y_Adj)
    local backdrop = CreateControlFromVirtual("$(parent)Bg", tlc, "ZO_DefaultBackdrop")
	backdrop:SetAnchorFill()
	
	-- create main LF_constants list
	-- this list is used to enable/disable LF_constants filters
	enableList = CreateControlFromVirtual("$(parent)EnableList", tlc, "ZO_ScrollList")
	enableList:SetDimensions(345, adjustedHeight * 0.5)
	enableList:SetAnchor(TOPLEFT, tlc, nil, 0, 25)
	
--	/lftestfilters
	-- button container for clear and refresh
	local buttons = CreateControl("$(parent)Buttons", tlc, CT_CONTROL)	
	buttons:SetDimensions(340, 60)
	buttons:SetAnchor(TOP, enableList, BOTTOM, 3, 15)
    local buttonshBackdrop = CreateControlFromVirtual("$(parent)Bg", buttons, "ZO_DefaultBackdrop")
	buttonshBackdrop:SetAnchorFill()
	
	-- create Clear button
	-- resets enableList and clears updateList
	local btnClear = CreateControlFromVirtual("$(parent)ClearButton", buttons, "ZO_DefaultButton")
	btnClear:SetHidden(false)
	btnClear:SetText("Clear")
	btnClear:SetDimensions(100, 50)
	btnClear:SetAnchor(TOPLEFT, buttons, TOPLEFT, 10, 5)
	btnClear:SetHandler("OnMouseUp", function(btn)
		clearAll()
	end)
	
	-- create Refresh button
	-- refresh list of LF_constants update functions and enable/disable LF_constants filters based on selections in enableList
	local btnRefresh = CreateControlFromVirtual("$(parent)RefreshButton", buttons, "ZO_DefaultButton")
	btnRefresh:SetHidden(false)
	btnRefresh:SetText("Refresh")
	btnRefresh:SetDimensions(150, 50)
	btnRefresh:SetAnchor(TOPRIGHT, buttons, TOPRIGHT, -10, 5)
	btnRefresh:SetHandler("OnMouseUp", function(btn)
		refreshUpdateList()
	end)
	
	-- create list for LF_constants update functions
	local ul_Hight = tlc:GetBottom() -  buttons:GetBottom() - 20
	updateList = CreateControlFromVirtual("$(parent)UpdateList", tlc, "ZO_ScrollList")
	updateList:SetDimensions(345, ul_Hight)
	updateList:SetAnchor(TOP, buttons, BOTTOM, 0, 15)
	
	-- initialize lists
	ZO_ScrollList_Initialize(enableList)
	ZO_ScrollList_Initialize(updateList)
	
--	tlc:SetHidden(true)
end

local function setupUsableAndLockedColor(control, locked)
	if locked then
		control:SetAlpha(0.3)
	else
		control:SetAlpha(1)
	end
end
local function setupRow(rowControl, data, onMouseUp)
	rowControl.data = data
	local row = rowControl:GetNamedChild("Button")
	row:SetText(data.name)
	
	rowControl:SetHidden(false)
	setupUsableAndLockedColor(rowControl, not enabledFilters[data.filterType])
	
	row:SetHandler("OnMouseUp", onMouseUp)
end

local function addListDataTypes()
 	local function setupEnableRow(rowControl, data)
		setupRow(rowControl, data, function(btn)
			setupUsableAndLockedColor(rowControl, enabledFilters[data.filterType])
			enabledFilters[data.filterType] = not enabledFilters[data.filterType]
		end)
	end

 	local function setupUpdateRow(rowControl, data)
		setupRow(rowControl, data, function(btn)
			libFilters:RequestUpdate(data.filterType)
		end)
	end
	
	ZO_ScrollList_AddDataType(enableList, LIST_TYPE, testUItemplate, 50, setupEnableRow)
	ZO_ScrollList_AddDataType(updateList, LIST_TYPE, testUItemplate, 50, setupUpdateRow)
end


SLASH_COMMANDS["/lftestfilters"] = function()
--[[ is there a way to check if a virtual control exists?
	-- is test.xml enabled
	if not LibFilters3_Test_Template then
		d( "Enable test.xml in manifest")
		return
	end
]]

	if not tlw then
		intialize()
		addListDataTypes()
	end

	if not tlc:IsHidden() then
		tlw:SetHidden(true)
		ZO_ScrollList_Clear(enableList)
		ZO_ScrollList_Commit(enableList)
		return
	end
	tlw:SetHidden(false)

	refreshEnableList()
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
	d("["..prefix.."]Test scene callback for Gamepad research confirm scene was added! ReloadUI to remove it.")
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

