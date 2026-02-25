--======================================================================================================================
-- 												LibFilters 3.0
--======================================================================================================================

------------------------------------------------------------------------------------------------------------------------
--Bugs/Todo List for version: 3.0 r4.9 - Last updated: 2025-12-17, Baertram
------------------------------------------------------------------------------------------------------------------------
--Bugs total: 				16
--[[
 #2025_01   --todo 20251031 in KB mode (maybe GP too): Why does EACH of the registered callbacks fire if ANY of the UniversalDeconstruction tabs is selected? See test UI
			--todo And why does first the HIDDEN callback fire for e.g. "armor" if we select the "armor" tab, and then it fires the SHOWN state for "armor" again?
			--todo It should first fire the real hidden tab, e.g. "all" or "weapons" (where we were before selecting the "armor" tab.
			--todo and it should only fire once per tab, as registered below: tab + show, or tab + hide!
]]


--Feature requests total: 	0

--[Bugs]
--#2026_16 Gamepad enchanting create control is nil or GP scene not detected properly if crafting a glyph

--[Feature requests]


------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3 name, and version
------------------------------------------------------------------------------------------------------------------------
local libFilters 	= LibFilters3
local MAJOR      	= libFilters.name
--local GlobalLibName = libFilters.globalLibName

------------------------------------------------------------------------------------------------------------------------
--DEBUGGING & LOGGING
------------------------------------------------------------------------------------------------------------------------
--LibDebugLogger, or normal logger d() output
local debugFunctions = libFilters.debugFunctions
local debugSlashToggle = debugFunctions.debugSlashToggle
local dd 	= debugFunctions.dd

------------------------------------------------------------------------------------------------------------------------
--LOCAL SPEED UP VARIABLES & REFERENCES
------------------------------------------------------------------------------------------------------------------------
--lua API functions
local tos = tostring

--Game API local speedup
local EM = EVENT_MANAGER


--LibFilters local speedup and reference variables
--Overall constants & mapping
local constants = 					libFilters.constants
local functions = 					libFilters.functions

local inventoryTypes = 				constants.inventoryTypes
local invTypeCraftBag =				inventoryTypes["craftbag"]

--Keyboard
local kbc                      	= 	constants.keyboard
local playerInv                	= 	kbc.playerInv
local inventories              	= 	kbc.inventories
local researchPanel			   	=   kbc.researchPanel

--local fixesLateApplied = false
local fixesLatestApplied = false


--Functions
local fixResearchDialogRowOnItemSelectedCallback = functions.fixResearchDialogRowOnItemSelectedCallback


--Functions without reference - updated inline below
local libFilters_IsListDialogShown


if libFilters.debug then dd("LIBRARY MAIN FILE - START") end


------------------------------------------------------------------------------------------------------------------------
-- LibFilters 3.0 - AddOn loading and init
------------------------------------------------------------------------------------------------------------------------


--**********************************************************************************************************************
-- HELPERS
--**********************************************************************************************************************
--Register all the helper functions of LibFilters, for some special panels like the Research or ResearchDialog, or
--deconstruction and improvement, inventories (Keyboard or Gamepad) etc.
--These helper functions overwrite original ESO functions in order to use their own "predicate" or
-- "filterFunction".
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- IMPORTANT: You need to check the funtion code and compare it to ZOs vanilla code after ESO updates:
-- if ZOs code changes the helpers' function code may need to change too!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--> See file helper.lua
local helpers = libFilters.helpers

--Install the helpers from table helpers now -> See file helper.lua, table "helpers"
local function installHelpers()
	if not libFilters.isInitialized then return end

	if libFilters.debug then dd("---InstallHelpers---") end
	for _, package in pairs(helpers) do
		local helper = package.helper
		local funcName = helper.funcName
		local func = helper.func

		for _, location in pairs(package.locations) do
			--e.g. ZO_SmithingExtractionInventory["GetIndividualInventorySlotsAndAddToScrollData"] = overwritten
			--function from helpers table, param "func"
			location[funcName] = func
		end
	end
end


--**********************************************************************************************************************
-- FIXES
--**********************************************************************************************************************
--Fixes which are needed BEFORE EVENT_ADD_ON_LOADED hits
local function applyFixesEarly()
	if libFilters.debug then dd("---ApplyFixesEarly---") end
	if libFilters.debug then dd(">Early fixes were applied") end
end

--Fixes which are needed AFTER EVENT_ADD_ON_LOADED hits
local function applyFixesLate()
	if libFilters.debug then dd("---ApplyFixesLate---") end
	--[[
	if not libFilters.isInitialized or fixesLateApplied then return end
	fixesLateApplied = true
	]]

	--Overwrite the rowSelected callback function of the keyboard research dialog as it got no nil check for the selectedData
	--table and raises errors as ZO_ScrollList_SelectData is used with nil data, or dialog:ClearList() is called
	local researchPopupDialogCustomControl = ESO_Dialogs["SMITHING_RESEARCH_SELECT"].customControl()
	ZO_PreHookHandler(researchPopupDialogCustomControl, "OnShow", function()
		if researchPopupDialogCustomControl ~= nil then
			libFilters_IsListDialogShown = libFilters_IsListDialogShown or libFilters.IsListDialogShown
			if libFilters_IsListDialogShown(libFilters, nil, researchPanel.control) then
				zo_callLater(function()
					fixResearchDialogRowOnItemSelectedCallback()
				end, 100)
			end
		end
	end)

	if libFilters.debug then dd(">Late fixes were applied") end
end

--Fixes which are needed AFTER EVENT_PLAYER_ACTIVATED hits
local function applyFixesLatest()
	if libFilters.debug then dd("---ApplyFixesLatest---") end
	if not libFilters.isInitialized or fixesLatestApplied then return end

	--2021-12-19
	--Fix applied now is only needed for CraftBagExtended addon!
	--The fragments used at mail send/bank deposit/guild bank deposit and guild store sell will apply their additionalFilters
	--to the normal player inventory PLAYER_INVENTORY.appliedLayout.
	--But the CBE craftbag panel will not filter with these additional filters, but the PLAYER_INVENTORY.inventories[INVENTORY_CRAFT_BAG].additionalFilters
	--And these are empty at these special CBE filters! So we need to copy them over from BACKPACK_MENU_BAR_LAYOUT_FRAGMENT.layoutData.additionalCraftBagFilter
	if CraftBagExtended ~= nil then
		SecurePostHook(playerInv, "ApplyBackpackLayout", function(layoutData)
			local crafBagIsHidden = kbc.craftBagClass:IsHidden()
			if libFilters.debug then dd("ApplyBackpackLayout-CraftBag hidden: %s", tos(crafBagIsHidden)) end
			if crafBagIsHidden == true or inventories[invTypeCraftBag].additionalFilter ~= nil then return end
			local additionalCraftBagFilter = kbc.invBackpackFragment.layoutData.additionalCraftBagFilter
			if additionalCraftBagFilter == nil then return end
			inventories[invTypeCraftBag].additionalFilter = additionalCraftBagFilter
		end)
	end

	fixesLatestApplied = true
	if libFilters.debug then dd(">Latest fixes were applied") end
end


--**********************************************************************************************************************
-- SLASH COMMANDS
--**********************************************************************************************************************
local function loadSlashCommands()
	SLASH_COMMANDS["/libfiltersdebug"] = 	debugSlashToggle
	SLASH_COMMANDS["/lfdebug"] = 			debugSlashToggle
	SLASH_COMMANDS["/lfverboseasdebug"] =	debugFunctions.debugVerboseAsDebugMessage
end


--**********************************************************************************************************************
-- EVENTs
--**********************************************************************************************************************
--Called from EVENT_PLAYER_ACTIVATED -> Only once
local function eventPlayerActivatedCallback(eventId, firstCall)
	EM:UnregisterForEvent(MAJOR .. "_EVENT_PLAYER_ACTIVATED", EVENT_PLAYER_ACTIVATED)
	applyFixesLatest()
end

--Called from EVENT_ADD_ON_LOADED
local function eventAddonLoadedCallback(eventId, addonNameLoaded)
	if addonNameLoaded ~= MAJOR then return end
	EM:UnregisterForEvent(MAJOR .. "_EVENT_ADDON_LOADED", EVENT_ADD_ON_LOADED)

	applyFixesLate()
	--Create the callbacks for the filterType's panel show/hide
	libFilters.CreateCallbacks()

	--Load the Slash Commands
	loadSlashCommands()

	EM:RegisterForEvent(MAJOR .. "_EVENT_PLAYER_ACTIVATED", EVENT_PLAYER_ACTIVATED, eventPlayerActivatedCallback)
end

------------------------------------------------------------------------------------------------------------------------
--[[
local function doTestStuff()
libFilters._callbackData = {}
libFilters._callbackData[LF_INVENTORY] = {}

	local function callbackFunctionForInvShown(callbackName, filterType, stateStr, isInGamepadMode, fragmentOrSceneOrControl, lReferencesToFilterType, universalDeconSelectedTabNow)
	d("callbackinvshown")

		libFilters._callbackData[LF_INVENTORY][stateStr] = {
	callbackName = callbackName,
	filterType = filterType,
	stateStr = stateStr,
	isInGamepadMode = isInGamepadMode,
	fragmentOrSceneOrControl = fragmentOrSceneOrControl,
	lReferencesToFilterType = lReferencesToFilterType,
	universalDeconSelectedTabNow = universalDeconSelectedTabNow,
}

		if filterType == LF_INVENTORY then
			d("Inventory - " ..tos(stateStr))
		end
	end

	local function callbackFunctionForInvHidden(callbackName, filterType, stateStr, isInGamepadMode, fragmentOrSceneOrControl, lReferencesToFilterType, universalDeconSelectedTabNow)
	d("callbackinvhidden")
libFilters._callbackData[LF_INVENTORY][stateStr] = {
	callbackName = callbackName,
	filterType = filterType,
	stateStr = stateStr,
	isInGamepadMode = isInGamepadMode,
	fragmentOrSceneOrControl = fragmentOrSceneOrControl,
	lReferencesToFilterType = lReferencesToFilterType,
	universalDeconSelectedTabNow = universalDeconSelectedTabNow,
}
		if filterType == LF_INVENTORY then
			d("Inventory - " ..tos(stateStr))
		end
	end

	local callbackNameInvShown = libFilters:CreateCallbackName("ASOD", LF_INVENTORY, true)
	d("Callback created: " ..callbackNameInvShown)
	CALLBACK_MANAGER:RegisterCallback(callbackNameInvShown, callbackFunctionForInvShown)
	local callbackNameInvHidden = libFilters:CreateCallbackName("ASOD", LF_INVENTORY, false)
	d("Callback created: " ..callbackNameInvHidden)
	CALLBACK_MANAGER:RegisterCallback(callbackNameInvHidden, callbackFunctionForInvHidden)
end
]]

--**********************************************************************************************************************
-- LIBRARY LOADING / INITIALIZATION
--**********************************************************************************************************************
--Function needed to be called from your addon to start the LibFilters instance and enable the filtering!
function libFilters:InitializeLibFilters()
	if libFilters.debug then dd("!-!-!-!-! InitializeLibFilters - %q !-!-!-!-!", tos(libFilters.isInitialized)) end
	if libFilters.isInitialized == true then return end
	libFilters.isInitialized = true

	--Install the helpers, which override ZOs vanilla code -> See file helpers.lua
	installHelpers()

	--Create the custom gamepad fragments and their needed hooks
	-->First create the customFragments, else function applyAdditionalFilterHooks beklow will only find an empty table
	-->constants.filterTypeToReference[true][filterType] and the .additionalFilters will never be applied properly!
	libFilters.CreateCustomGamepadFragmentsAndNeededHooks()

	--Hook into the scenes/fragments/controls to apply the filter function "runFilters" to the existing .additionalFilter
	--and other existing filters, and to add the libFilters filterType to the .LibFilters3_filterType tag (to identify the
	--inventory/control/fragment again)
	libFilters.ApplyAdditionalFilterHooks()

	--Apply the late fixes if not already done
	applyFixesLate()

	--Create the callbacks if not already done
	libFilters.CreateCallbacks()


	--Test stuff
	--[[
	if GetDisplayName() == "@Baertram" then
		doTestStuff()
	end
	]]
end

--______________________________________________________________________________________________________________________
--______________________________________________________________________________________________________________________
--______________________________________________________________________________________________________________________
--TODO: Only for debugging
--if GetDisplayName() == "@Baertram" then debugSlashToggle() end


--Apply any fixes needed to be run before EVENT_ADD_ON_LOADED
applyFixesEarly()
EM:RegisterForEvent(MAJOR .. "_EVENT_ADDON_LOADED", EVENT_ADD_ON_LOADED, eventAddonLoadedCallback)

if libFilters.debug then dd("LIBRARY MAIN FILE - END") end
