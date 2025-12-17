------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3 name, and version
------------------------------------------------------------------------------------------------------------------------
local libFilters 	= LibFilters3

--local MAJOR      	= libFilters.name
--local GlobalLibName = libFilters.globalLibName
local filters    	= libFilters.filters

------------------------------------------------------------------------------------------------------------------------
--DEBUGGING & LOGGING
------------------------------------------------------------------------------------------------------------------------
--LibDebugLogger, or normal logger d() output
local debugFunctions = libFilters.debugFunctions

local dd 	= debugFunctions.dd
local dv 	= debugFunctions.dv
local dfe 	= debugFunctions.dfe


------------------------------------------------------------------------------------------------------------------------
--LOCAL SPEED UP VARIABLES & REFERENCES
------------------------------------------------------------------------------------------------------------------------
--Helper variables of ESO
local tos = tostring

--Game API local speedup
local IsGamepad = IsInGamepadPreferredMode
local nccnt = NonContiguousCount

--LibFilters local speedup and reference variables
--Overall constants & mapping
local constants = 					libFilters.constants
local mapping = 					libFilters.mapping
local callbacks = 					mapping.callbacks
local functions = 					libFilters.functions

local types = constants.types
local functionType = types.func
--local boolType = types.bool
--local userDataType = types.ud
--local tableType = types.tab
--local stringType = types.str
--local numberType = types.num


--FilterPanelIds
local LF_FILTER_ALL = LF_FILTER_ALL

local libFiltersFilterConstants = 	constants.filterTypes
local filterTypeDeterminationFunctions = constants.filterTypeDeterminationFunctions --#15

local defaultOriginalFilterAttributeAtLayoutData = constants.defaultAttributeToAddFilterFunctions --"additionalFilter"
local defaultSubTableWhereFilterFunctionsCouldBe = constants.defaultSubTableWhereFilterFunctionsCouldBe -- "layoutData"

local otherOriginalFilterAttributesAtLayoutData_Table = constants.otherAttributesToGetOriginalFilterFunctions
local defaultLibFiltersAttributeToStoreTheFilterType = constants.defaultAttributeToStoreTheFilterType --"LibFilters3_filterType"
local LF_FilterTypeToReference = 									mapping.LF_FilterTypeToReference

local LF_ConstantToAdditionalFilterSpecialHook = 					mapping.LF_ConstantToAdditionalFilterSpecialHook

local libFilters_IsUniversalDeconstructionPanelShown
local universalDeconTabKeyToLibFiltersFilterType	   =			mapping.universalDeconTabKeyToLibFiltersFilterType
local universalDeconFilterTypeToFilterBase = 					    mapping.universalDeconFilterTypeToFilterBase
local universalDeconLibFiltersFilterTypeSupported = 				mapping.universalDeconLibFiltersFilterTypeSupported

--Keyboard
local kbc                      	= 	constants.keyboard
local universalDeconstructPanel = 	kbc.universalDeconstructPanel
local universalDeconstructScene =   kbc.universalDeconstructScene


--Gamepad
local gpc                      	= 	constants.gamepad

local universalDeconstructPanel_GP = gpc.universalDeconstructPanel_GP
local universalDeconstructScene_GP = gpc.universalDeconstructScene_GP

--The costants for the reference types
local typeOfRefToName    = constants.typeOfRefToName


local universalDeconHookApplied         = false
libFilters.wasUniversalDeconPanelShownBefore = false
libFilters.wasUniversalDeconPanelGPEventCraftingBeginUsed 	= false


--Functions
local getValueOrCallback = 					functions.getValueOrCallback
local checkIfControlSceneFragmentOrOther = 	libFilters.CheckIfControlSceneFragmentOrOther
local getTypeOfRefName = 					libFilters.GetTypeOfRefName

--Functions without reference - will be updated inline below
local libFilters_hookAdditionalFilter
local libFilters_CallbackRaise
local libFilters_GetFilterTypeName
local updateCurrentAndLastUniversalDeconVariables
local onControlHiddenStateChange



------------------------------------------------------------------------------------------------------------------------
--RUN THE FILTERS
------------------------------------------------------------------------------------------------------------------------
--Run the applied filters' filterFunctions at a LibFilters filterType (LF_*) now, using the ... parameters
--(e.g. 1st parameter inventorySlot, or at e.g. crafting tables 1st parameter bagId & 2nd parameter slotIndex)
--If libFilters:SetFilterAllState(boolean newState) is set to true (libFilters.useFilterAllFallback == true)
--If the filterType got no registered filterTags with filterFunctions, the LF_FILTER_ALL "fallback" will be
--checked (if existing) and run!
--Returns true if all filter functions were run and their return value was true
--Returns false if any of the run filter functions was returning false or nil
local function runFilters(filterType, ...)
--d("[LibFilters3]runFilters, filterType: " ..tos(filterType))
	local filterTagsDataWithFilterFunctions = filters[filterType]
	--Use the LF_FILTER_ALL fallback filterFunctions?
	if libFilters.useFilterAllFallback == true and
			(filterTagsDataWithFilterFunctions == nil or nccnt(filterTagsDataWithFilterFunctions) == 0) then
		local allFallbackFiltersTagDataAndFunctions = filters[LF_FILTER_ALL]
		if allFallbackFiltersTagDataAndFunctions ~= nil then
			for _, fallbackFilterFunc in pairs(allFallbackFiltersTagDataAndFunctions) do
				if not fallbackFilterFunc(...) then
					return false
				end
			end
		end
	else
		for _, filterFunc in pairs(filterTagsDataWithFilterFunctions) do
			if not filterFunc(...) then
				return false
			end
		end
	end
	return true
end
libFilters.RunFilters = runFilters


------------------------------------------------------------------------------------------------------------------------
--Hooks into ZOs vanilla code
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--HOOK VARIABLEs TO ADD .additionalFilter to them
------------------------------------------------------------------------------------------------------------------------

--local ZOsUniversalDeconGPWorkaroundForGetCurrentFilterNeeded = false
local function applyUniversalDeconstructionHook()
	--2022-02-11 PTS API101033 Universal Deconstruction
	-->Apply early so it is done before the helpers load!
	if not universalDeconHookApplied then
		--Add a filter changed callback to keyboard and gamepad variables in order to set the currently active LF filterType constant
		-->Will be re-using LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT AND LF_ENCHANTING_EXTRACTION as there does not exist any
		-->LF_UNIVERSAL_DECONSTRUCTION constant! .additionalFilter functions will also be taken from normal deconstruction/jewelry deconstruction
		-->and enchanting extraction!

		--Update the variables
		universalDeconstructPanel = universalDeconstructPanel or kbc.universalDeconstructPanel
		universalDeconstructPanel_GP = universalDeconstructPanel_GP or gpc.universalDeconstructPanel_GP

		--This workaround code below should only be needed before the function GetCurrentFilter() was added!
		--[[
		local itemTypesUniversalDecon = {}
		local itemFilterTypesUniversalDecon = {}
		local function getDataFromUniversalDeconstructionMenuBar()
			local barToSearch = ZO_UNIVERSAL_DECONSTRUCTION_FILTER_TYPES
			if barToSearch then
				for _, v in ipairs(barToSearch) do
					local filter = v.filter
					local key = v.key
					if filter ~= nil then
						if filter.itemTypes ~= nil then
							itemTypesUniversalDecon[filter.itemTypes] = key
						elseif filter.itemFilterTypes ~= nil then
							itemFilterTypesUniversalDecon[filter.itemFilterTypes] = key
						end
					end
				end
			end
			return
		end
		--Prepare the comparison string variables for the currentKey comparison
		-->Only needed as long as universalDeconstructPanel:GetCurrentFilter() is not existing
		getDataFromUniversalDeconstructionMenuBar()
		]]

		--For the .additionalFilter function: Universal deconstruction also RE-uses SMITHING for the keyboard panel, and the
		--gamepad enchanting extraction sceneas it got no own filterType LF_UNIVERSAL_DECONSTRUCTION or similar!
		local function detectUniversalDeconstructionPanelActiveTab(filterType, currentTabKey)
			--Detect the active tab via the filterData
			local libFiltersFilterType
			--CurrentTabKey == nil should only happen before the function GetCurrentFilter() was added!
			--[[
			if currentTabKey == nil then
				if filterType ~= nil then
					local itemTypes = filterType.itemTypes
					if itemTypes then
						currentTabKey = itemTypesUniversalDecon[itemTypes]
					else
						local itemFilterTypes = filterType.itemFilterTypes
						if itemFilterTypes then
							currentTabKey = itemFilterTypesUniversalDecon[itemFilterTypes]
						end
					end
				else
					currentTabKey = "all"
				end
			end
			]]
			libFiltersFilterType = universalDeconTabKeyToLibFiltersFilterType[currentTabKey]
			return libFiltersFilterType
		end
		libFilters.DetectUniversalDeconstructionPanelActiveTab = detectUniversalDeconstructionPanelActiveTab


		local function getUniversalDeconstructionPanelActiveTabFilterType(filterPanelIdComingFrom)
			local isGamepadMode = IsGamepad()
			libFilters_IsUniversalDeconstructionPanelShown = libFilters_IsUniversalDeconstructionPanelShown or libFilters.IsUniversalDeconstructionPanelShown
			local isShowingUniversalDeconScene, universaldDeconScene = libFilters_IsUniversalDeconstructionPanelShown()
			if libFilters.debug then dv("|UD> GetUniversalDeconstructionPanelActiveTabFilterType - filterPanelId: %s", tos(filterPanelIdComingFrom) ) end
			if isShowingUniversalDeconScene and universaldDeconScene ~= nil then
				local universalDeconSelectedTab
				local universalDeconSelectedTabKey
				--if filterPanelIdComingFrom == nil then
					local universaldDeconPanel = (isGamepadMode == true and universalDeconstructPanel_GP) or universalDeconstructPanel
					universalDeconSelectedTab = universaldDeconPanel.inventory:GetCurrentFilter()
					if not universalDeconSelectedTab then return false end
					universalDeconSelectedTabKey = universalDeconSelectedTab.key
					filterPanelIdComingFrom = detectUniversalDeconstructionPanelActiveTab(nil, universalDeconSelectedTabKey)
					if libFilters.debug then dv(">universalDeconTab.key: %s", tos(universalDeconSelectedTabKey)) end
				--end
				--Check if filterPanelId detected is a valid filterType for the UniversalDeconstruction tab
				if universalDeconLibFiltersFilterTypeSupported[filterPanelIdComingFrom] == true then
					if libFilters.debug then dv("<filterPanelIdComingFrom now: %q", tos(filterPanelIdComingFrom)) end
--d("<returned: " ..tos(filterPanelIdComingFrom))
					return filterPanelIdComingFrom, universalDeconSelectedTabKey
				end
			end
			return nil, nil
		end
		libFilters.GetUniversalDeconstructionPanelActiveTabFilterType = getUniversalDeconstructionPanelActiveTabFilterType


		function updateCurrentAndLastUniversalDeconVariables(tab, doReset)
			doReset = doReset or false
			local lastFilterTypeUniversalDeconTab
			local currentFilterTypeUniversalDeconTab = libFilters._currentFilterTypeUniversalDeconTab
			--Any tab was shown before: following calls to UniversalDecon panel's OnFilterChanged function
			if libFilters.wasUniversalDeconPanelShownBefore == true then
				local currentFilterTypeUniversalDeconTabCopy = currentFilterTypeUniversalDeconTab
				lastFilterTypeUniversalDeconTab = currentFilterTypeUniversalDeconTabCopy
				libFilters._lastFilterTypeUniversalDeconTab = lastFilterTypeUniversalDeconTab
			end
			if doReset == true then
				libFilters._currentFilterTypeUniversalDeconTab = nil
			else
				libFilters._currentFilterTypeUniversalDeconTab = tab.key
			end

			if libFilters.debug then dd("|UD> updateCurrentAndLastUniversalDeconVariables - doReset: %s, tab: %q, lastTab: %s",
					tos(doReset), tos(libFilters._currentFilterTypeUniversalDeconTab), tos(lastFilterTypeUniversalDeconTab)) end
		end
		functions.updateCurrentAndLastUniversalDeconVariables = updateCurrentAndLastUniversalDeconVariables

		--Callback function - Will fire at each change of any filter (tab, multiselect dropdown filterbox, search text, ...)
		local function universalDeconOnFilterChangedCallback(tab, craftingTypes, includeBanked)
			--Update the last shown UniversalDecon tab and filterType
			updateCurrentAndLastUniversalDeconVariables(tab, false)

			--Get the filterType by help of the current activated UniversalDecon tab
			local filterTypeBefore = libFilters._lastFilterType
			local universalDeconTabBefore = libFilters._lastFilterTypeUniversalDeconTab
			local lastTab = universalDeconTabBefore
			--local wasUniversalDeconShownBefore = (universalDeconTabBefore ~= nil and true) or false
			local currentTabBefore = libFilters._currentFilterTypeUniversalDeconTab
			local currentTab = currentTabBefore
			--d("°°° [universalDecon:FilterChanged]TabNow: " .. tos(currentTab) ..", last: " ..tos(lastTab))

			local libFiltersFilterType = detectUniversalDeconstructionPanelActiveTab(nil, currentTab)
			if libFilters.debug then dd("|UD> universalDeconOnFilterChangedCallback - tab: %q, lastTab: %q, filterType: %s, lastFilterType: %s",
					tos(currentTab), tos(lastTab), tos(libFiltersFilterType), tos(filterTypeBefore)) end
			if libFiltersFilterType == nil then return end
			--Set the .LibFilters3_filterType at the UNIVERSAL_DECONSTRUCTION(_GAMEPAD) table
			universalDeconstructPanel = universalDeconstructPanel or kbc.universalDeconstructPanel
			universalDeconstructPanel_GP = universalDeconstructPanel_GP or gpc.universalDeconstructPanel_GP
			local base = universalDeconFilterTypeToFilterBase[libFiltersFilterType]
			base[defaultLibFiltersAttributeToStoreTheFilterType] = libFiltersFilterType --.LibFilters3_filterType

			--Raise the callbacks
			libFilters_CallbackRaise = libFilters_CallbackRaise or libFilters.CallbackRaise
			--Hide old panel
			local isInGamepadMode = IsGamepad()
			local universalDeconRefVar = (isInGamepadMode and universalDeconstructPanel_GP) or universalDeconstructPanel
			local universalDeconDataHideCurrentTab = {
				isShown = true, --This tells the called functions that the universal deconstruction panel is currently shown, generally!
				lastTab = lastTab,
				currentTab = currentTab,
				wasShownBefore = libFilters.wasUniversalDeconPanelShownBefore
			}
			--If the UniversalDecon panel was shown before (in keyboard mode!) the hidden state needs to be called for the current shown tab first
			-->2022-10-30: GAMEPAD: Universald Decon tab changes won't work properly anymore if removed so added a boolean to EVENT_CRAFTING_TABLE_INTERACT
			--and if it's called the 2nd time skip the onControlHiddenStateChange(false) at gamepad mode here ONCE until next EVENT_CRAFTING_TABLE_INTERACT
			--was called
			onControlHiddenStateChange = onControlHiddenStateChange or libFilters.OnControlHiddenStateChange
			if libFilters.wasUniversalDeconPanelShownBefore == true
					and (not isInGamepadMode or (isInGamepadMode and not libFilters.wasUniversalDeconPanelGPEventCraftingBeginUsed) ) then
				onControlHiddenStateChange(false, { filterTypeBefore }, universalDeconRefVar, isInGamepadMode, nil, universalDeconDataHideCurrentTab)
			end
			--reset the prevention variable (set at EVENT_CRAFTING_TABLE_INTERACT) so next tab change in gamepad mode fires the callbacks properly again
			if isInGamepadMode == true and libFilters.wasUniversalDeconPanelGPEventCraftingBeginUsed == true then
				libFilters.wasUniversalDeconPanelGPEventCraftingBeginUsed = false
			end
			--Show new panel
			local universalDeconDataShowNewTab = {
				isShown = true, --This tells the called functions that the universal deconstruction panel is currently shown, generally!
				lastTab = lastTab,
				currentTab = currentTab,
				wasShownBefore = libFilters.wasUniversalDeconPanelShownBefore
			}
			onControlHiddenStateChange(true, { libFiltersFilterType }, universalDeconRefVar, isInGamepadMode, nil, universalDeconDataShowNewTab)
			libFilters.wasUniversalDeconPanelShownBefore = true
		end

		--ZOs workaround needed?
		universalDeconstructPanel_GP = universalDeconstructPanel_GP or gpc.universalDeconstructPanel_GP
		--Workaround for GamePad mode where ZOs did not create the function GetCurrentFilter()
		-->See helper.lua, helpers["ZO_UniversalDeconstructionPanel_Shared.DoesItemPassFilter"]


		--Add the callbacks for OnFilterChanged
		universalDeconstructPanel:RegisterCallback("OnFilterChanged", 		universalDeconOnFilterChangedCallback)
		universalDeconstructPanel_GP:RegisterCallback("OnFilterChanged", 	universalDeconOnFilterChangedCallback)

		--2022-10-24 The OnFilterChanged callback at keyboard mode does not fire as you re-open the universal decon panel!
		--So we need an extra universalDeconstructPanel.control OnEffectivelyShown hook here which only runs as the UI re-opens,
		--but not at first open. It should fire the SCENE_SHOWN callback then with libFilters._lastFilterType and _lastFilterTypeUniversalDeconTab then!
		local wasUniversalDeconControlShownOnce = false
		local filterTypesOfUniversalDecon = callbacks.usingSpecials[false][universalDeconstructPanel]
		--createControlCallback(universalDeconstructPanel.control, filterTypesOfUniversalDecon, false, nil)
		ZO_PostHookHandler(universalDeconstructPanel.control, "OnEffectivelyShown", function(ctrlRef)
			if not libFilters.isInitialized then return end
			if libFilters.debug then dd("|UD> universalDeconstructPanel OnEffectivelyShown-wasUniversalDeconControlShownOnce: %s", tos(wasUniversalDeconControlShownOnce)) end
			if not wasUniversalDeconControlShownOnce then
				wasUniversalDeconControlShownOnce = true
				return
			end
			--Update the last shown UniversalDecon tab and filterType
			updateCurrentAndLastUniversalDeconVariables(universalDeconstructPanel.inventory:GetCurrentFilter(), false)
			onControlHiddenStateChange = onControlHiddenStateChange or libFilters.OnControlHiddenStateChange
			onControlHiddenStateChange(true, filterTypesOfUniversalDecon, ctrlRef, false, nil)
		end)

		--Needed? 2022-10-29 -- See bugs #2
		--[[
		local wasUniversalDeconGPControlShownOnce = false
		local filterTypesOfUniversalDecon_GP = callbacks.usingSpecials[true][universalDeconstructPanel_GP]
		--createControlCallback(universalDeconstructPanel_GP.control, filterTypesOfUniversalDecon_GP, true, nil)
		ZO_PostHookHandler(universalDeconstructPanel_GP.control, "OnEffectivelyShown", function(ctrlRef)
			if not libFilters.isInitialized then return end
			if libFilters.debug then dd("universalDeconstructPanel GAMEPAD OnEffectivelyShown-wasUniversalDeconControlShownOnce: %s", tos(wasUniversalDeconGPControlShownOnce)) end
			if not wasUniversalDeconGPControlShownOnce then
				wasUniversalDeconGPControlShownOnce = true
				return
			end
			--Update the last shown UniversalDecon tab and filterType
			updateCurrentAndLastUniversalDeconVariables(universalDeconstructPanel_GP.inventory:GetCurrentFilter())
			onControlHiddenStateChange(true, filterTypesOfUniversalDecon_GP, ctrlRef, true, nil)
		end)
		]]

		--Keyboard/Gamepad universal decon: If mail send panel was enabled before and then universal decon is opened
		--and mail send panel is opened via keybind #, the universal decon "OnClose" callback wont fire before
		--the new mail fragments show. EVENT_CRAFTING_INTERACTION_END and OnHidden of the UniversalDecon panel
		--control are too slow here...
		--So we need the extra scene HIDDE check here!
		universalDeconstructScene:RegisterCallback("StateChange",
			function(oldState, newState)
				if not libFilters.isInitialized then return end
				if newState == SCENE_HIDDEN then
					if libFilters.debug then dd("|UD> [UNIVERSAL DECON Keyboard SCENE HIDDEN]") end
					universalDeconOnFilterChangedCallback(universalDeconstructPanel.inventory:GetCurrentFilter(), nil, nil)

					--Update the current -> last universal decon tab so closing the next "normal" non-universal crafting table wont tell us we are
					--closing universal decon again, because libFilters._currentFilterTypeUniversalDeconTab is still ~= nil!
					updateCurrentAndLastUniversalDeconVariables(nil, true) --reset  libFilters._currentFilterTypeUniversalDeconTab
				end
			end)

		universalDeconstructScene_GP:RegisterCallback("StateChange",
			function(oldState, newState)
				if not libFilters.isInitialized then return end
				if newState == SCENE_HIDDEN then
					if libFilters.debug then dd("|UD> [UNIVERSAL DECON Gamepad SCENE HIDDEN]") end
					universalDeconOnFilterChangedCallback(universalDeconstructPanel_GP.inventory:GetCurrentFilter(), nil, nil)

					--Update the current -> last universal decon tab so closing the next "normal" non-universal crafting table wont tell us we are
					--closing universal decon again, because libFilters._currentFilterTypeUniversalDeconTab is still ~= nil!
					updateCurrentAndLastUniversalDeconVariables(nil, true) --reset  libFilters._currentFilterTypeUniversalDeconTab
				end
			end)

		universalDeconHookApplied = true
	end
end

------------------------------------------------------------------------------------------------------------------------
--HOOK state variables
------------------------------------------------------------------------------------------------------------------------
--Special hooks done? Add the possible special hook names in this table so that function libFilters:HookAdditionalFilterSpecial
--will not register the special hooks more than once
--[[
local specialHooksDone = {
	 --["enchanting"] = false, --example entry
}
--Used in function libFilters:HookAdditionalFilterSpecial
local specialHooksLibFiltersDataRegistered = {}
]]


------------------------------------------------------------------------------------------------------------------------
--HOOK additionaFilter table, or add it to fragments/controls/userdate etc. where needed
--> The filterFunctions will be added and run there
------------------------------------------------------------------------------------------------------------------------
--**********************************************************************************************************************
-- HOOKS
--**********************************************************************************************************************
------------------------------------------------------------------------------------------------------------------------
--- Special hook (add the .additionalFilter and .LibFilter3_filterType entries to) of controls/scenes/fragments/userdata/etc.
local function hookNowSpecial(inventoriesToHookForLFConstant_Table, isInGamepadMode, filterType, hookKeyboardAndGamepadMode)
	if not inventoriesToHookForLFConstant_Table then
		local filterTypeName = libFilters_GetFilterTypeName(libFilters, filterType)
		local filterTypeNameAndTypeText = tos(filterTypeName) .. " [" .. tos(filterType) .. "]"
		dfe("HookAdditionalFilter SPECIAL-table of hooks is empty for constant %s, isInGamepadMode: %s, keyboardAndGamepadMode: %s",
				filterTypeNameAndTypeText, tos(isInGamepadMode), tos(hookKeyboardAndGamepadMode))
		return
	end
	local funcName = inventoriesToHookForLFConstant_Table.funcName
	if funcName ~= nil and funcName ~= "" and libFilters[funcName] ~= nil then
		local params = inventoriesToHookForLFConstant_Table.params
		if libFilters.debug then dd("HookAdditionalFilter > hookNowSpecial-%q,%s;%s", tos(filterType), tos(funcName), tos(params)) end
		libFilters[funcName](libFilters, unpack(params))
	end
end

------------------------------------------------------------------------------------------------------------------------
--- Normal hook (add the .additionalFilter and .LibFilter3_filterType entries to) of controls/scenes/fragments/userdata/etc.
local function hookNow(inventoriesToHookForLFConstant_Table, isInGamepadMode, filterType, hookKeyboardAndGamepadMode)
	local filterTypeNameAndTypeText, filterTypeName
	if not inventoriesToHookForLFConstant_Table then
		filterTypeName = libFilters_GetFilterTypeName(libFilters, filterType)
		filterTypeNameAndTypeText = tos(filterTypeName) .. " [" .. tos(filterType) .. "]"
		dfe("HookAdditionalFilter-table of hooks is empty for constant %s, isInGamepadMode: %s, keyboardAndGamepadMode: %s",
				filterTypeNameAndTypeText, tos(isInGamepadMode), tos(hookKeyboardAndGamepadMode))
		return
	end
	if libFilters.debug then
		filterTypeName = libFilters_GetFilterTypeName(libFilters, filterType)
		filterTypeNameAndTypeText = tos(filterTypeName) .. " [" .. tos(filterType) .. "]"
		dv(">____________________>")
		dv("[HookNow]filterType %q, isInGamepadMode: %s, keyboardAndGamepadMode: %s",
			filterTypeNameAndTypeText, tos(isInGamepadMode), tos(hookKeyboardAndGamepadMode)) end

	if #inventoriesToHookForLFConstant_Table == 0 then return end

	for _, filterTypeRefToHook in ipairs(inventoriesToHookForLFConstant_Table) do
		if filterTypeRefToHook ~= nil then
			local typeOfRef = checkIfControlSceneFragmentOrOther(filterTypeRefToHook, filterType, isInGamepadMode)
			local typeOfRefStr = typeOfRefToName[typeOfRef]
			if libFilters.debug then
				local typeOfRefName = getTypeOfRefName(typeOfRef, filterTypeRefToHook)
				dv(">Hooking into %q, type: %s", tos(typeOfRefName), tos(typeOfRefStr))
			end

			local layoutData = filterTypeRefToHook[defaultSubTableWhereFilterFunctionsCouldBe] or filterTypeRefToHook --used <object>.layoutData or <object> to store the .additionalFilter functions
			--Get the default attribute .additionalFilter of the inventory/layoutData to determine original filter value/filterFunction
			local originalFilter = layoutData[defaultOriginalFilterAttributeAtLayoutData] --.additionalFilter

			--Store the filterType at the layoutData (which could be a fragment.layoutData table or a variable like
			--PLAYER_INVENTORY.inventories[INVENTORY_*]) table to identify the panel -> will be used e.g. within
			--LibFilters:GetCurrentFilterTypeForInventory(inventoryType)
			--#15 Check if the added filterType should be a number LF_* constant or a function returning that
			local filterTypeDeterminationFunc = filterTypeDeterminationFunctions[filterType] --#15
			if type(filterTypeDeterminationFunc) == functionType then
				layoutData[defaultLibFiltersAttributeToStoreTheFilterType] = filterTypeDeterminationFunc --.LibFilters3_filterType -> using a function! --#15
			else
				layoutData[defaultLibFiltersAttributeToStoreTheFilterType] = filterType --.LibFilters3_filterType --#15
			end

			--Special handling for some filterTypes -> Add additional filter functions/values to the originalFilter
			--which were added to other fields than "additionalFilter" (e.g. "additionalCraftBagFilter" at BACKPACK_MENU_BAR_LAYOUT_FRAGMENT which is copied over to
			--PLAYER_INVENTORY.inventories[INVENTORY_CARFT_BAG].additionalFilter)
			--Will be read from layoutData[attributeRead] (attributeRead entry defined at table otherOriginalFilterAttributesAtLayoutData_Table[isInGamepadMode][filterType])
			--and write to (if entry objectWrite and/or subObjectWrite is/are defined at table otherOriginalFilterAttributesAtLayoutData_Table[isInGamepadMode][filterType]
			--they will be used to write to, else layoutData will be used again to write to)[attributeWrite]
			-->e.g. LF_CRAFTBAG -> layoutData.additionalCraftBagFilter in PLAYER_INVENTORY.appliedLayouts
			local otherOriginalFilter
			local otherOriginalFilterAttributesAtLayoutData = otherOriginalFilterAttributesAtLayoutData_Table[isInGamepadMode][filterType]
			--Special filterFunction needed, not located at .additionalFilter but e.g. .additionalCraftBag filter?
			if otherOriginalFilterAttributesAtLayoutData ~= nil then
				local readFromAttribute = otherOriginalFilterAttributesAtLayoutData.attributeRead
				if libFilters.debug then dv(">>filterType: %s, otherOriginalFilterAttributesAtLayoutData: %s", filterTypeNameAndTypeText, tos(readFromAttribute)) end
				local readFromObject = otherOriginalFilterAttributesAtLayoutData.objectRead
				if readFromObject == nil then
					--Fallback: Read from the same layoutData
					readFromObject = layoutData
				end
				if readFromObject == nil then
					--This will happen once for LF_CraftBag as PLAYER_INVENTORY.inventories[INVENTORY_CRAFT_BAG] does not seem to exist yet
					--as we try to add the .additionalCraftBagFilter to it
					dfe("HookAdditionalFilter-HookNow found a \"fix\" for filterType %s, type: %s. But the readFrom data (%q/%q) is invalid/missing!, isInGamepadMode: %s, keyboardAndGamepadMode: %s",
							filterTypeNameAndTypeText,
							tos(typeOfRefStr),
							tos((readFromObject ~= nil and "readFromObject=" .. tos(readFromObject)) or "readFromObject is missing"),
							tos((readFromAttribute ~= nil and "readFromAttribute=" .. readFromAttribute) or "readFromAttribute is missing"),
							tos(isInGamepadMode), tos(hookKeyboardAndGamepadMode))
					return
				end
				otherOriginalFilter = readFromObject[readFromAttribute]
				local createFilterFunctionForLibFilters = false
				if otherOriginalFilter ~= nil then
					local originalFilterType = type(otherOriginalFilter)
					if originalFilterType == functionType then
						createFilterFunctionForLibFilters = false
						if libFilters.debug then dv(">>>Updated existing filter function %q", tos(readFromAttribute)) end
						readFromObject[readFromAttribute] = function(...) --e.g. update BACKPACK_MENU_BAR_LAYOUT_FRAGMENT.additionalCraftBagFilter so it will be copied to PLAYER_INVENTORY.inventories[INVENTORY_CRAFT_BAG] at PLAYER_INVENTORY:ApplyBackpackLayout()
							return otherOriginalFilter(...) and runFilters(filterType, ...)
						end
					else
						--There was no filterFunction provided yet
						createFilterFunctionForLibFilters = true
					end
				else
					--There was no filterFunction provided yet -> the attribute was missing/nil
					createFilterFunctionForLibFilters = true
				end
				if createFilterFunctionForLibFilters == true then
					if libFilters.debug then dv(">>>Created new filter function %q", tos(readFromAttribute)) end
					readFromObject[readFromAttribute] = function(...) --e.g. update BACKPACK_MENU_BAR_LAYOUT_FRAGMENT.additionalCraftBagFilter so it will be copied to PLAYER_INVENTORY.inventories[INVENTORY_CRAFT_BAG] at PLAYER_INVENTORY:ApplyBackpackLayout()
						return runFilters(filterType, ...)
					end
				end
			else
				if libFilters.debug then dv(">>filterType: %s, normal hook: %s", filterTypeNameAndTypeText, tos(defaultOriginalFilterAttributeAtLayoutData)) end
				local originalFilterType = type(originalFilter)
				if originalFilterType == functionType then
					if libFilters.debug then dv(">>>Updated existing filter function %q", tos(defaultOriginalFilterAttributeAtLayoutData)) end
					--Set the .additionalFilter again with the filter function of the original and LibFilters
					layoutData[defaultOriginalFilterAttributeAtLayoutData] = function(...) --.additionalFilter
						return originalFilter(...) and runFilters(filterType, ...)
					end
				else
					if libFilters.debug then dv(">>>Created new filter function %q", tos(defaultOriginalFilterAttributeAtLayoutData)) end
					--Set the .additionalFilter again with the filter function of LibFilters only
					layoutData[defaultOriginalFilterAttributeAtLayoutData] = function(...) --.additionalFilter
						return runFilters(filterType, ...)
					end
				end
			end
		end
	end --for _, inventory in ipairs(inventoriesToHookForLFConstant_Table) do
end
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------


--Hook the inventory layout or inventory control, a fragment, scene or userdata to apply the .additionalFilter entry for
--the filter functions registered via LibFilters:RegisterFilter("uniqueName," filterType, callbackFilterFunction)
--Using only 1 parameter number filterType now, to determine the correct control/inventory/scene/fragment/userdata to
--apply the entry .additionalFilter to from the constants table --> See file costants.lua, table
--LF_FilterTypeToReference
--As the table could contain multiple variables to hook into per LF_* constant there needs to be a loop over the entries
function libFilters:HookAdditionalFilter(p_filterType, hookKeyboardAndGamepadMode)
	libFilters_GetFilterTypeName = libFilters_GetFilterTypeName or libFilters.GetFilterTypeName
	local filterType = getValueOrCallback(p_filterType)
	if libFilters.debug then
		local filterTypeName = libFilters_GetFilterTypeName(libFilters, filterType)
		local filterTypeNameAndTypeText = (tos(filterTypeName) .. " [" .. tos(filterType) .. "]")
		dd("HookAdditionalFilter - %q, %s", tos(filterTypeNameAndTypeText), tos(hookKeyboardAndGamepadMode))
	end

	--Should the LF constant be hooked by any special function of LibFilters?
	--e.g. run LibFilters:HookAdditionalFilterSpecial("enchanting")
	local inventoriesToHookForLFConstant
	local hookSpecialFunctionDataOfLFConstant = LF_ConstantToAdditionalFilterSpecialHook[filterType]
	if not ZO_IsTableEmpty(hookSpecialFunctionDataOfLFConstant) then
		if hookKeyboardAndGamepadMode == true then
			--Keyboard
			inventoriesToHookForLFConstant = hookSpecialFunctionDataOfLFConstant[false]
			if inventoriesToHookForLFConstant ~= nil then
				hookNowSpecial(inventoriesToHookForLFConstant, false, filterType, hookKeyboardAndGamepadMode)
				inventoriesToHookForLFConstant = nil
			end
			--Gamepad
			inventoriesToHookForLFConstant = hookSpecialFunctionDataOfLFConstant[true]
			if inventoriesToHookForLFConstant ~= nil then
				hookNowSpecial(inventoriesToHookForLFConstant, true, filterType, hookKeyboardAndGamepadMode)
			end
		else
			--Only currently detected mode, gamepad or keyboard
			local gamepadMode = IsGamepad()
			inventoriesToHookForLFConstant = hookSpecialFunctionDataOfLFConstant[gamepadMode]
				hookNowSpecial(inventoriesToHookForLFConstant, gamepadMode, filterType, hookKeyboardAndGamepadMode)
		end
	end
	inventoriesToHookForLFConstant = nil
	------------------------------------------------------------------------------------------------------------------------

	--If the special hook was found it maybe that only one of the two, keyboard or gamepad was hooked special.
	--e.g. "enchanting" -> LF_ENCHANTING_CREATION only applies to keyboard mode. Gamepad needs to hook normally to add
	--the .additionalFilter to the correct gamepad enchanting inventory.
	--So try to run the same LF_ constant as normal hook as well (if it exists)
	--Hook normal via the given control/scene/fragment/userdata etc. -> See table LF_FilterTypeToReference
	if ZO_IsTableEmpty(hookSpecialFunctionDataOfLFConstant) then
		if hookKeyboardAndGamepadMode == true then
			--Keyboard
			inventoriesToHookForLFConstant = LF_FilterTypeToReference[false][filterType]
				hookNow(inventoriesToHookForLFConstant, false, filterType, hookKeyboardAndGamepadMode)
			inventoriesToHookForLFConstant = nil
			--Gamepad
			inventoriesToHookForLFConstant = LF_FilterTypeToReference[true][filterType]
				hookNow(inventoriesToHookForLFConstant, true, filterType, hookKeyboardAndGamepadMode)
		else
			--Only currently detected mode, gamepad or keyboard
			local gamepadMode = IsGamepad()
			inventoriesToHookForLFConstant = LF_FilterTypeToReference[gamepadMode][filterType]
				hookNow(inventoriesToHookForLFConstant, gamepadMode, filterType, hookKeyboardAndGamepadMode)
		end
	end
end
libFilters_hookAdditionalFilter = libFilters.HookAdditionalFilter

--[[
--Hook the inventory in a special way, e.g. at ENCHANTING where there is only 1 inventory variable and no
--extra fragment for the different modes (creation, extraction).
--Uses String specialType to define which special hooks should be used
--> Is only kept as example here! Currently LF_ENCHANTING_CREATION and _EXTRACTION use the gamepad scenes in helpers.lua
--> ZO_Enchanting_DoesEnchantingItemPassFilter for both, keyboard and gamepad mode!
function libFilters:HookAdditionalFilterSpecial(specialType)
	if libFilters.debug then dd("HookAdditionalFilterSpecial-%q", tos(specialType)) end
	if specialHooksDone[specialType] then return end

	--[ [
	--ENCHANTING keyboard
	if specialType == "enchanting" then

		local function onEnchantingModeUpdated(enchantingVar, enchantingMode)
			local libFiltersEnchantingFilterType = enchantingModeToFilterType[enchantingMode]
			enchantingVar.inventory.LibFilters3_filterType = libFiltersEnchantingFilterType

			specialHooksLibFiltersDataRegistered[specialType] = specialHooksLibFiltersDataRegistered[specialType] or {}

			--Only once
			if libFiltersEnchantingFilterType ~= nil and not specialHooksLibFiltersDataRegistered[specialType][libFiltersEnchantingFilterType] then
				local originalFilter = enchantingVar.inventory.additionalFilter
				local additionalFilterType = type(originalFilter)
				if additionalFilterType == functionType then
					enchantingVar.inventory.additionalFilter = function(...)
						return originalFilter(...) and runFilters(libFiltersEnchantingFilterType, ...)
					end
				else
					enchantingVar.inventory.additionalFilter = function(...)
						return runFilters(libFiltersEnchantingFilterType, ...)
					end
				end

				specialHooksLibFiltersDataRegistered[specialType][libFiltersEnchantingFilterType] = true
			end

		end

		--Hook the class variable (used for keyboard and gamepad as a base) OnModeUpdate to get the switch between
		--enchanting creation and enchanting extarction
		ZO_PreHook(keyboardConstants.enchantingClass, "OnModeUpdated", function(selfEnchanting)
			onEnchantingModeUpdated(selfEnchanting, selfEnchanting.enchantingMode)
		end)

		specialHooksDone[specialType] = true
	end
	] ]
end
]]

--[[
--Hook the inventory in a special way, e.g. at ENCHANTING for gamepad using the SCENES to add the .additionalFilter, but
--using the GAMEPAD_ENCHANTING.inventory to store the current LibFilters3_filterType (constant: defaultLibFiltersAttributeToStoreTheFilterType)
--Uses String specialType to define which special hooks should be used
--> Is only kept as example here! Currently LF_ENCHANTING_CREATION and _EXTRACTION use the gamepad scenes in helpers.lua
--> ZO_Enchanting_DoesEnchantingItemPassFilter for both, keyboard and gamepad mode!
function libFilters:HookAdditionalFilterSceneSpecial(specialType)
	if libFilters.debug then dd("HookAdditionalFilterSceneSpecial-%q", tos(specialType)) end
	if specialHooksDone[specialType] then return end

--[ [
	--ENCHANTING gamepad
	if specialType == "enchanting_GamePad" then
		--The enchanting scenes to hook into
		local enchantingScenesGamepad = {
			[LF_ENCHANTING_CREATION] = 		gamepadConstants.enchantingCreateScene_GP,
			[LF_ENCHANTING_EXTRACTION] = 	gamepadConstants.enchantingExtractScene_GP,
		}

		local function updateLibFilters3_filterTypeAtGamepadEnchantingInventory(enchantingVar)
			local enchantingMode = enchantingVar:GetEnchantingMode()
			local libFiltersEnchantingFilterType = enchantingModeToFilterType[enchantingMode]
			enchantingVar.inventory.LibFilters3_filterType = libFiltersEnchantingFilterType
		end

		--Add the .additionalFilter to the gamepad enchanting creation and extraction scenes once
		--Only add .additionalFilter once
		for libFiltersEnchantingFilterType, enchantingSceneGamepad in pairs(enchantingScenesGamepad) do
			specialHooksLibFiltersDataRegistered[specialType] = specialHooksLibFiltersDataRegistered[specialType] or {}
			if libFiltersEnchantingFilterType ~= nil and not specialHooksLibFiltersDataRegistered[specialType][libFiltersEnchantingFilterType] then
				local originalFilter = enchantingSceneGamepad.additionalFilter
				local additionalFilterType = type(originalFilter)
				if additionalFilterType == functionType then
					enchantingSceneGamepad.additionalFilter = function(...)
						return originalFilter(...) and runFilters(libFiltersEnchantingFilterType, ...)
					end
				else
					enchantingSceneGamepad.additionalFilter = function(...)
						return runFilters(libFiltersEnchantingFilterType, ...)
					end
				end
				specialHooksLibFiltersDataRegistered[specialType][libFiltersEnchantingFilterType] = true
			end

			--Register a stateChange callback: Change the .LibFilters3_filterType at GAMEPAD_ENCHANTING.inventory
		    --for GAMEPAD_ENCHANTING.inventory:EnumerateInventorySlotsAndAddToScrollData (see helpers.lua)
			enchantingSceneGamepad:RegisterCallback("StateChange", function(oldState, newState)
				if newState == SCENE_SHOWING then
--d("[LF3]GamePadEnchanting " ..tostring(libFilters_GetFilterTypeName(libFilters, libFiltersEnchantingFilterType)) .." Scene:Showing")
					updateLibFilters3_filterTypeAtGamepadEnchantingInventory(gamepadConstants.enchanting_GP)
				end
			end)
		end

		specialHooksDone[specialType] = true
	end
 ] ]
end
]]


--Hook the different inventory panels (LibFilters filterTypes) now and add the .additionalFilter entry to each panel's
--control/scene/fragment/...
local function applyAdditionalFilterHooks()
	if libFilters.debug then dd("---ApplyAdditionalFilterHooks---") end

	--Universal deconstruction -> Special, as it re-used LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT and LF_ENCHANTING_EXTRACT
	applyUniversalDeconstructionHook()

	--For each LF constant hook the filters now to add the .additionalFilter entry
	-->Keyboard and gamepad mode are both hooked here via 2nd param = true
	for filterTypeId, _ in ipairs(libFiltersFilterConstants) do
		-->HookAdditionalFilterSpecial will be done automatically in HookAdditionalFilter, via the table
		-->LF_ConstantToAdditionalFilterSpecialHook
		libFilters_hookAdditionalFilter(libFilters, filterTypeId, true) --filterTypeId = the same as _G[filterConstantName], eg. LF_INVENTORY
	end
end
libFilters.ApplyAdditionalFilterHooks = applyAdditionalFilterHooks