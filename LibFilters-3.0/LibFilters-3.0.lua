--======================================================================================================================
-- 													LibFilters 3.0
--======================================================================================================================
--This library is used to filter inventory items (show/hide) at the different panels/inventories -> LibFilters uses the
--term "filterType" for the different filter panels. Each filterType is represented by the help of a number constant
--starting with LF_<panelName> (e.g. LF_INVENTORY, LF_BANK_WITHDRAW), which is used to add filterFunctions of different
--adddons to this inventory. See table libFiltersFilterConstants for the value = "filterPanel name" constants.
--The number of the constant increases by 1 with each new added constant/panel.
--The minimum valueis LF_FILTER_MIN (1) and the maximum is LF_FILTER_MAX (#libFiltersFilterConstants). There exists a
--"fallback" constant LF_FILTER_ALL (9999) which can be used to register filters for ALL exisitng LF_* constants. If any
--LF_* constant got no filterFunction registered, the entries in filters[LF_FILTER_ALL] will be used instead (if
--existing, and the flag to use the LF_FILTER_ALL fallback is enabled (boolean true) via function
--libFilters:SetFilterAllState(boolean newState)
--
--The filterType (LF_* constant) of the currently shown panel (see function libFilters:GetCurrentFilterTypeForInventory(inventoryType))
--will be stored at the "LibFilters3_filterType" (constant saved at "defaultLibFiltersAttributeToStoreTheFilterType")
--attribute at the inventory/layoutData/scene/control involved for the filtering. See function libFilters:HookAdditionalFilter
--
--The registered filterFunctions will run as the inventories are refreshed/updated, either by internal update routines as
--the inventory's "dirty" flag was set to true. Or via function SafeUpdateList (see below), or via some other update/refresh/
--ShouldAddItemToSlot function (some of them are overwriting vanilla UI source code in the file helpers.lua).
--LibFilters3 will use the inventory/fragment (normal hooks), or some special hooks (e.g. ENCHANTING -> OnModeUpdated) to
--add the LF* constant to the inventory/fragment/variables.
--With the addition of Gamepad support the special hoks like enchanting were even changed to use the gamepad scenes of
--enchanting as "object to store the" the .additionalFilter (constant saved at "defaultOriginalFilterAttributeAtLayoutData")
--entry for the LibFilters filter functions.
--
--The filterFunctions will be placed at the inventory.additionalFilter entry, and will enhance existing functions, so
--that filter funtions summarize (e.g. addon1 registers a "Only show stolen filter" and addon2 registers "only show level
--10 items filter" -> Only level 10 stolen items will be shown then).
--
--The function InstallHelpers below will call special code from the file "helper.lua". In this file you define the
--variable(s) and function name(s) which LibFilters should "REPLACE" -> Means it will overwrite those functions to add
--the call to the LibFilters internal filterFunctions (e.g. at SMITHING crafting tables, function
--EnumerateInventorySlotsAndAddToScrollData -> ZOs vanilla UI code + usage of self.additionalFilter where Libfilters
--added it's filterFunctions).
--
--The files in the Gamepad folder define the custom fragments which were created for the Gamepad scenes to try to keep it
--similar to the keyboard fragments (as inventory shares the same PLAYER_INVENTORY variables for e.g. player inventory,
--bank/guild bank/house bank deposit, mail send and player2player trade there needs to be one unique object per panel to
--store the .additionalFilter entry. And this are the fragments in keyboard mode, and now custom fragemnts starting with
--LIBFILTERS3_ in gamepad mode.
--
--[Important]
--You need to call LibFilters3:InitializeLibFilters() once in any of the addons that use LibFilters, to
--create the hooks and init the library properly!
--
--
--[Example filter functions]
--Here is the mapping which filterId constant LF* uses which type of filter function: inventorySlot or bagdId & slotIndex
--Example filter functions:
--[[
--Filter function with inventorySlot
local function FilterSavedItemsForSlot(inventorySlot)
  return true -- show the item in the list / false = hide item
end

--Filter function with bagId and slotIndex (often used at crafting tables)
local function FilterSavedItemsForBagIdAndSlotIndex(bagId, slotIndex)
  return true -- show the item in the list / false = hide item
end
-- 
--All LF_ constants except the ones named below, e.g. LF_INVENTORY, LF_CRAFTBAG, LF_VENDOR_SELL
--are using the InventorySlot filter function!
--
--Filter function with bagId and slotIndex (most of them are crafting related ones)
--[LF_SMITHING_REFINE]                        = FilterSavedItemsForBagIdAndSlotIndex,
--[LF_SMITHING_DECONSTRUCT]                   = FilterSavedItemsForBagIdAndSlotIndex,
--[LF_SMITHING_IMPROVEMENT]                   = FilterSavedItemsForBagIdAndSlotIndex,
--[LF_SMITHING_RESEARCH]                      = FilterSavedItemsForBagIdAndSlotIndex,
--[LF_SMITHING_RESEARCH_DIALOG]               = FilterSavedItemsForBagIdAndSlotIndex,
--[LF_JEWELRY_REFINE]                         = FilterSavedItemsForBagIdAndSlotIndex,
--[LF_JEWELRY_DECONSTRUCT]                    = FilterSavedItemsForBagIdAndSlotIndex,
--[LF_JEWELRY_IMPROVEMENT]                    = FilterSavedItemsForBagIdAndSlotIndex,
--[LF_JEWELRY_RESEARCH]                       = FilterSavedItemsForBagIdAndSlotIndex,
--[LF_JEWELRY_RESEARCH_DIALOG]                = FilterSavedItemsForBagIdAndSlotIndex,
--[LF_ENCHANTING_CREATION]                    = FilterSavedItemsForBagIdAndSlotIndex,
--[LF_ENCHANTING_EXTRACTION]                  = FilterSavedItemsForBagIdAndSlotIndex,
--[LF_RETRAIT]                                = FilterSavedItemsForBagIdAndSlotIndex,
--[LF_ALCHEMY_CREATION]                       = FilterSavedItemsForBagIdAndSlotIndex,
--
-- See constants.lua -> table libFilters.constants.filterTypes.UsingBagIdAndSlotIndexFilterFunction and table
-- libFilters.constants.filterTypes.UsingInventorySlotFilterFunction
-- to dynamically determine the functionType to use. The following constants for the functionTypes exist:
-- libFilters.constants.LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT = 1
-- libFilters.constants.LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX = 2
--
--
--[Wording / Glossary]
---filterTag = The string defined by an addon to uniquely describe and reference the filter in the internal tables
----(e.g. "addonName1FilterForInventory")
---filterType (or libFiltersFilterType) = The LF_* constant of the filter, describing the panel where it will be filtered (e.g. LF_INVENTORY)
--
]]

------------------------------------------------------------------------------------------------------------------------
--Bugs/Todo List for version: 3.0 r3.0 - Last updated: 2021-12-06, Baertram
------------------------------------------------------------------------------------------------------------------------
--Bugs total: 				0
--Feature requests total: 	0

--[Bugs]
-- #1) 2021-12-06, ESOUI addon comments, SantaClaus:	Merry christmas :-)


--[Feature requests]
-- #f1) 2021-12-06, ESOUI addon comments, SantaClaus:	Let the bells jingle


------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3 name, and version
------------------------------------------------------------------------------------------------------------------------
local libFilters 	= LibFilters3
local MAJOR      	= libFilters.name
local GlobalLibName = libFilters.globalLibName
local filters    	= libFilters.filters


------------------------------------------------------------------------------------------------------------------------
--LOCAL SPEED UP VARIABLES & REFERENCES
------------------------------------------------------------------------------------------------------------------------
--lua API functions
local tos = tostring
local strmat = string.match
local strfor = string.format
local tins = table.insert

--Game API local speedup
local CM = CALLBACK_MANAGER
local EM = EVENT_MANAGER
local SM = SCENE_MANAGER
local IsGamepad = IsInGamepadPreferredMode
local nccnt = NonContiguousCount
local gcit = GetCraftingInteractionType
local ncc = NonContiguousCount

local getCurrentScene = SM.GetCurrentScene
local getScene = SM.GetScene


------------------------------------------------------------------------------------------------------------------------
--LOCAL LIBRARY SPEED UP VARIABLES & REFERENCES
------------------------------------------------------------------------------------------------------------------------
--Cashed current data (placeholders, currently nil)
libFilters._currentFilterType = nil
libFilters._currentFilterTypeReferences = nil


--LibFilters local speedup and reference variables
--Overall constants & mapping
local constants = 					libFilters.constants
local mapping = 					libFilters.mapping
local callbacks = 					mapping.callbacks

local libFiltersFilterConstants = 	constants.filterTypes
local inventoryTypes = 				constants.inventoryTypes
local invTypeBackpack = 			inventoryTypes["player"]
local invTypeQuest =				inventoryTypes["quest"]
local invTypeBank =					inventoryTypes["bank"]
local invTypeGuildBank =			inventoryTypes["guild_bank"]
local invTypeHouseBank =			inventoryTypes["house_bank"]
local invTypeCraftBag =				inventoryTypes["craftbag"]

local defaultOriginalFilterAttributeAtLayoutData = constants.defaultAttributeToAddFilterFunctions --"additionalFilter"
local otherOriginalFilterAttributesAtLayoutData_Table = constants.otherAttributesToGetOriginalFilterFunctions
local defaultLibFiltersAttributeToStoreTheFilterType = libFilters.constants.defaultAttributeToStoreTheFilterType --"LibFilters3_filterType"

local updaterNamePrefix = libFilters.constants.updaterNamePrefix

local filterTypesUsingBagIdAndSlotIndexFilterFunction = 			mapping.filterTypesUsingBagIdAndSlotIndexFilterFunction
local filterTypesUsingInventorySlotFilterFunction = 				mapping.filterTypesUsingInventorySlotFilterFunction
local LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT = 				constants.LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT
local LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX = 			constants.LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX

local filterTypeToFilterTypeRespectingCraftType = 					mapping.filterTypeToFilterTypeRespectingCraftType
local filterTypeToUpdaterName = 									mapping.filterTypeToUpdaterName
local updaterNameToFilterType = 									mapping.updaterNameToFilterType
local LF_FilterTypeToReference = 									mapping.LF_FilterTypeToReference
local LF_FilterTypeToCheckIfReferenceIsHidden = 					mapping.LF_FilterTypeToCheckIfReferenceIsHidden
local LF_ConstantToAdditionalFilterSpecialHook = 					mapping.LF_ConstantToAdditionalFilterSpecialHook
local LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes =	mapping.LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes
local LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup = mapping.LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup
local LF_FilterTypeToDialogOwnerControl = 							mapping.LF_FilterTypeToDialogOwnerControl

--Keyboard
local kbc                      = 	constants.keyboard
local playerInv                = 	kbc.playerInv
local inventories              = 	kbc.inventories
--local craftBagFragment 		   = 	kbc.craftBagFragment
--local craftBagKBLayoutDataAttribute = otherOriginalFilterAttributesAtLayoutData_Table[false][LF_CRAFTBAG]["attributeRead"]
local store                    = 	kbc.store
--local storeBuy                 = 	kbc.vendorBuy
--local storeSell                = 	kbc.vendorSell
--local storeBuyBack             = 	kbc.vendorBuyBack
--local storeRepair              = 	kbc.vendorRepair
local storeWindows             = 	kbc.storeWindows
--local fence                    = 	kbc.fence
local researchChooseItemDialog = 	kbc.researchChooseItemDialog
local playerInvCtrl            =    kbc.playerInvCtrl
local companionEquipmentCtrl   = 	kbc.companionEquipment.control
local characterCtrl            =	kbc.characterCtrl
local companionCharacterCtrl   = 	kbc.companionCharacterCtrl
local enchanting               = 	kbc.enchanting
local enchantingInvCtrl        = 	enchanting.inventoryControl
local alchemy                  = 	kbc.alchemy
local alchemyCtrl              =	kbc.alchemyCtrl

--Gamepad
local gpc                       = 	constants.gamepad
local invBackpack_GP            = 	gpc.invBackpack_GP
--local invRootScene_GP 			= 	gpc.invRootScene_GP
local invBank_GP                = 	gpc.invBank_GP
local invGuildBank_GP           = 	gpc.invGuildBank_GP
local store_GP                  = 	gpc.store_GP
local store_componentsGP        = 	store_GP.components
--local storeBuy_GP               = 	gpc.vendorBuy_GP
--local storeSell_GP              = 	gpc.vendorSell_GP
--local storeBuyBack_GP           = 	gpc.vendorBuyBack_GP
--local storeRepair_GP            =	gpc.vendorRepair_GP
--local fence_GP                  =	gpc.fence_GP

local researchPanel_GP          = 	gpc.researchPanel_GP
--local playerInvCtrl_GP          = 	gpc.playerInvCtrl_GP
local companionEquipmentCtrl_GP = 	gpc.companionEquipment_GP.control
--local characterCtrl_GP          =	gpc.characterCtrl_GP
local companionCharacterCtrl_GP = 	gpc.companionCharacterCtrl_GP
--local enchanting_GP             = 	gpc.enchanting_GP
local enchantingInvCtrls_GP     = 	gpc.enchantingInvCtrls_GP
local alchemy_GP                = 	gpc.alchemy
local alchemyCtrl_GP            =	gpc.alchemyCtrl_GP

--functions
--local getCustomLibFiltersFragmentName = libFilters.GetCustomLibFiltersFragmentName


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

--Local pre-defined function names. Code will be added further down in this file. Only created here already to be re-used
--in code prior to creation (functions using it won't be called before creation was done, but they are local and more
--DOWN in the lua file than the actual fucntion's creation is done -> lua interpreter wouldn't find it).
local libFilters_hookAdditionalFilter
local libFilters_GetCurrentFilterTypeForInventory
local libFilters_GetCurrentFilterTypeReference
local libFilters_GetFilterTypeReferences

------------------------------------------------------------------------------------------------------------------------
--DEBUGGING & LOGGING
------------------------------------------------------------------------------------------------------------------------
--LibDebugLogger, or normal logger d() output
local logger = libFilters.logger
local debugFunctions = libFilters.debugFunctions

local dd = debugFunctions.dd
local df = debugFunctions.df
local dfe = debugFunctions.dfe

--Slash command to toggle the debug boolean true/false
local debugSlashToggle = debugFunctions.debugSlashToggle
SLASH_COMMANDS["/libfiltersdebug"] = 	debugSlashToggle
SLASH_COMMANDS["/lfdebug"] = 			debugSlashToggle


if libFilters.debug then dd("LIBRARY MAIN FILE - START") end

------------------------------------------------------------------------------------------------------------------------
--LOCAL HELPER FUNCTIONS - Scenes
------------------------------------------------------------------------------------------------------------------------
--Get the currently shown scene and sceneName
local function getCurrentSceneInfo()
	if not SM then return nil, "" end
	local currentScene = getCurrentScene(SM)
	local currentSceneName = (currentScene ~= nil and currentScene.name) or ""
	if libFilters.debug then dd("getCurrentSceneInfo - currentScene: %q, name: %q", tos(currentScene), tos(currentSceneName)) end
	return currentScene, currentSceneName
end

local function checkIfControlSceneFragmentOrOther(refVar)
	local retVar
	--Scene or fragment
	if refVar.sceneManager and refVar.state then
		retVar = 2
	--Control
	elseif refVar.control then
		retVar = 1
	--Other
	else
		retVar = 3
	end
	if libFilters.debug then dd("checkIfControlSceneFragmentOrOther - refVar %q: %s", tos(refVar), tos(retVar)) end
	return retVar
end

local function checkIfRefVarIsShown(refVar)
	if not refVar then return false, nil end
	local refType = checkIfControlSceneFragmentOrOther(refVar)
	--Control
	local isShown = false
	if refType == 1 then
		isShown = (refVar.control ~= nil and refVar.control.IsHidden ~= nil) and not refVar.control:IsHidden()
	--Scene or fragment
	elseif refType == 2 then
		if libFilters.debug then dd("checkIfRefVarIsShown - scene/fragment state: %q", tos(refVar.state)) end
		isShown = ((refVar.state == SCENE_FRAGMENT_SHOWN or refVar.state == SCENE_SHOWN) and true) or (refVar.IsShowing and refVar:IsShowing()) or false
	--Other
	elseif refType == 3 then
		if type(refVar) == "boolean" then
			isShown = refVar
		else
			isShown = false
		end
	end
	if libFilters.debug then dd("checkIfRefVarIsShown - refVar %q: %s, refType: %s", tos(refVar), tos(isShown), tos(refType)) end
	return isShown, refVar, refType
end


--Compare the String/table sceneOrFragmentToCompare with the currentSceneOrFragment, or the sceneOrFragmentToCompare.name
--(of if it's a string it is the name already so compare it directly) with currentSceneOrFragmentName
--return true if the compared scene/name matches the passed in scene/scne.name or sceneName (if it's a String)
local function compareCurrentSceneFragment(sceneOrFragmentToCompare, currentSceneOrFragment, currentSceneOrFragmentName)
	if not sceneOrFragmentToCompare then return end
	if currentSceneOrFragment == nil then
		currentSceneOrFragment, currentSceneOrFragmentName = getCurrentSceneInfo()
	end
	if (currentSceneOrFragment == nil and currentSceneOrFragment.name == "nil") and
		(currentSceneOrFragmentName == nil or (currentSceneOrFragmentName ~= nil and currentSceneOrFragmentName == "")) then
		return false
	end
	local sceneOrFragmentNameToCompare = ""
	if type(sceneOrFragmentToCompare) == "String" then
		sceneOrFragmentNameToCompare = sceneOrFragmentToCompare
	else
		if sceneOrFragmentToCompare == currentSceneOrFragment then
			return true
		else
			if not sceneOrFragmentToCompare.state and not sceneOrFragmentToCompare.sceneManager then
				return false
			end
			if sceneOrFragmentToCompare.name then
				sceneOrFragmentNameToCompare = sceneOrFragmentToCompare.name
			end
		end
	end
	if sceneOrFragmentNameToCompare == currentSceneOrFragmentName then return true end
	return false
end

--Get the scene name which is assigned to the filterType and inputType
--returns String sceneName ("", if no scene is assigned), sceneReference scene
local function getSceneName(filterType, isInGamepadMode)
	local retSceneName = ""
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	local filterTypeData = LF_FilterTypeToCheckIfReferenceIsHidden[isInGamepadMode][filterType]
	local retScene = filterTypeData ~= nil and filterTypeData["scene"]
	if retScene then
		if type(retScene) == "String" then
			retSceneName = retScene
			local sceneOfRetSceneName = getScene(SM, retSceneName)
			retScene = sceneOfRetSceneName
		else
			if retScene.name then retSceneName = retScene.name end
		end
	end
	if libFilters.debug then dd("getSceneName - filterType %s: %q, retScene: %s", tos(filterType), tos(retSceneName), tos(retScene)) end
	return retSceneName, retScene
end

--Check if a scene or fragment is assigned to the filterType and inputType
--If OPTIONAL parameter boolean sceneFirst is false/nil: If a fragment is provided in table
--LF_FilterTypeToCheckIfReferenceIsHidden[isInGamepadMode][filterType] it will be checked first if it's shown
--if also a scene is provided it will be checked after the fragment.
--If OPTIONAL parameter boolean sceneFirst is true: If a scene is provided in the table
--LF_FilterTypeToCheckIfReferenceIsHidden[isInGamepadMode][filterType] it will be checked first if it's shown
--If a fragment is provided this will be checked after the scene.
--In both cases: If any of them is shown the result will be true
--boolean isSceneOrFragment defines if the call should be using the scene ONLY (true) or the fragment ONLY (false). If left
--nil both will be checked
--returns boolean isShown, sceneOrFragmentReference sceneOrFragmentWhichIsShown
local function isSceneFragmentShown(filterType, isInGamepadMode, sceneFirst, isSceneOrFragment)
	sceneFirst = sceneFirst or false
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	local isDebugEnabled = libFilters.debug
	local resultIsShown, resultSceneOrFragment
	local filterTypeData = LF_FilterTypeToCheckIfReferenceIsHidden[isInGamepadMode][filterType]
	if filterTypeData == nil then return false, nil end
	local retFragment = filterTypeData["fragment"]
	local retScene = filterTypeData["scene"]
	--Is the scene "name" given -> Get the scene by name
	if retScene ~= nil and type(retScene) == "string" then
		local sceneOfRetSceneName = getScene(SM, retScene)
--libFilters._lastCheckedSceneName = retScene
--libFilters._lastCheckedScene = SCENE_MANAGER:GetScene(retScene)
		if isSceneOrFragment == true and isDebugEnabled then dd("isSceneFragmentShown - changed sceneName to scene - filterType %s, sceneName: %s, scene: %s", tos(filterType), tos(retScene), tos(sceneOfRetSceneName)) end
		if sceneOfRetSceneName ~= nil then
			retScene = sceneOfRetSceneName
		else
			return false, retScene
		end
	end

	if isSceneOrFragment == nil then
		if not sceneFirst then
			resultIsShown = checkIfRefVarIsShown(retFragment)
			if resultIsShown == true then
				resultSceneOrFragment = retFragment
			end
			resultIsShown = resultSceneOrFragment == nil and checkIfRefVarIsShown(retScene)
			if resultIsShown == true and resultSceneOrFragment == nil then
				resultSceneOrFragment = retScene
			end
		else
			resultIsShown = checkIfRefVarIsShown(retScene)
			if resultIsShown == true then
				resultSceneOrFragment = retScene
			end
			resultIsShown = resultSceneOrFragment == nil and checkIfRefVarIsShown(retFragment)
			if resultIsShown == true and resultSceneOrFragment == nil then
				resultSceneOrFragment = retFragment
			end
		end
	else
		if isSceneOrFragment == true then
			resultIsShown = checkIfRefVarIsShown(retScene)
			if resultIsShown == true then
				resultSceneOrFragment = retScene
			end
		else
			resultIsShown = checkIfRefVarIsShown(retFragment)
			if resultIsShown == true then
				resultSceneOrFragment = retFragment
			end
		end
	end
	if isDebugEnabled then dd("isSceneFragmentShown - filterType %s: %s, sceneFirst: %s, isSceneOrFragment: %s", tos(filterType), tos(resultIsShown), tos(sceneFirst), tos(isSceneOrFragment)) end
	return resultIsShown, resultSceneOrFragment
end

--Is the dialog's owner control shown
local function isListDialogShown(dialogOwnerControlToCheck)
	local listDialog = ZO_InventorySlot_GetItemListDialog()
	local data = listDialog and listDialog.control and listDialog.control.data
	if data == nil then return false end
	local owner = data.owner
	if owner == nil or owner.control == nil then return false end
	return owner.control == dialogOwnerControlToCheck and not listDialog.control:IsHidden()
end

--Get the dialog's owner control by help of the filterType
local function getDialogOwner(filterType, craftType)
	craftType = craftType or gcit()
	local filterTypeToDialogCraftTypeData = LF_FilterTypeToDialogOwnerControl[craftType]
	if filterTypeToDialogCraftTypeData == nil then return nil end
	return filterTypeToDialogCraftTypeData[filterType]
end

local function isListDialogShownWrapper(filterType, isInGamepadMode)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	local filterTypeData = LF_FilterTypeToCheckIfReferenceIsHidden[isInGamepadMode][filterType]
	if filterTypeData == nil then
		if libFilters.debug then dd("isListDialogShownWrapper - filterType %s: %s, gamepadMode: %s, error: %s", tos(filterType), tos(false), tos(isInGamepadMode), "filterTypeData is nil!") end
		return false, nil
	end
	local dialogOwnerCtrl = filterTypeData["controlDialog"]
	return isListDialogShown(dialogOwnerCtrl)
end

local function checkIfStoreCtrlOrFragmentShown(varToCheck, p_storeMode, isInGamepadMode)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	varToCheck = (varToCheck or (isInGamepadMode and store_componentsGP[p_storeMode]) or storeWindows[p_storeMode])
	if not varToCheck then return false end
	local isShown, controlOrFragment, refType = checkIfRefVarIsShown(varToCheck)
	return isShown, controlOrFragment, refType
end

--Check if a control is assigned to the filterType and inputType
--returns boolean isShown), controlReference controlWhichIsShown
local function isControlShown(filterType, isInGamepadMode)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	local filterTypeData = LF_FilterTypeToCheckIfReferenceIsHidden[isInGamepadMode][filterType]
	if filterTypeData == nil then
		if libFilters.debug then dd("isControlShown - filterType %s: %s, gamepadMode: %s, error: %s", tos(filterType), tos(false), tos(isInGamepadMode), "filterTypeData is nil!") end
		return false, nil
	end
	local retCtrl = filterTypeData["control"]
	local checkType = "retCtrl"
	local ctrlToCheck = retCtrl

	local subControlsToLoop = {
		[1] = "control",
		[2] = "container",
		[3] = "list",
		[4] = "listView",
		[5] = "panelControl",
	}

	if ctrlToCheck ~= nil then
		if ctrlToCheck.IsHidden == nil then
			for _, subControlName in ipairs(subControlsToLoop)do
				if ctrlToCheck[subControlName] ~= nil and
					ctrlToCheck[subControlName].IsHidden ~= nil then
					ctrlToCheck = ctrlToCheck[subControlName]
					checkType = "retCtrl." .. subControlName
					break -- leave the loop
				end
			end
		end
	end
	if ctrlToCheck == nil or (ctrlToCheck ~= nil and ctrlToCheck.IsHidden == nil) then
		if libFilters.debug then dd("isControlShown - filterType %s: %s, gamepadMode: %s, error: %s", tos(filterType), tos(false), tos(isInGamepadMode), "no control/listView with IsHidden function found!") end
		return false, nil
	end
	local isShown = not ctrlToCheck:IsHidden()
	if libFilters.debug then dd("isControlShown - filterType %s: %s, gamepadMode: %s, retCtrl: %s, hiddenStateFrom: %s", tos(filterType), tos(isShown), tos(isInGamepadMode), tos(ctrlToCheck), tos(checkType)) end
	return isShown, ctrlToCheck
end


--[[
["special"] = {
  [1] = {
	  ["control"]  =  gamepadConstants.enchanting_GP,
	  ["funcOrAttribute"] = "GetEnchantingMode",
	  ["params"] = {}, --no params used, leave nil to pass in ... from isSpecialTrue(filterType, isInGamepadMode, ...)
	  --either control + func + params OR bool can be given!
	  ["bool"] = booleanVariableOrFunctionReturningABooleanValue,
	  ["expectedResults"] = {ENCHANTING_MODE_CREATION},
  }
}
]]
--Check if special routines defined for the filterType are met/true.
--If boolean isSpecialForced is true the table LF_FilterTypeToCheckIfReferenceIsHidden[isInGamepadMode][filterType] will
--read the "specialForced" subtable, else the "special"subtable
--If control is given, and funcOrAttribute and params are given the function of control[func](params) will be called if funcOrAttribute
--is a function. If funcOrAttribute is a number the children control of control will be determined with that number.
--If funcOrAttribute is a string (e.g. "mode") the value of control[funcOrAttribute] will be determined.
--The results of this call will be compared to the expected. The order of the expected results must match the returned
--values of that function call!
--If control is not given a bool check can be done using a boolean variable or a function returning a boolean variable
--If expectedResults are not given: If the function call does not return any results it will be assumed that everything
--was okay. This function here will return true then!
--If the function call was returning results the 1st returned result variable will be returned (it's assumed to be a boolean)
--If params are not given (nil) they will be used from the ... passed in parameters. If params are an empty {} no params will be used!
--returns boolean areAllExpectedResultsTrue
local function isSpecialTrue(filterType, isInGamepadMode, isSpecialForced, ...)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	local isDebugEnabled = libFilters.debug
	isSpecialForced = isSpecialForced or false
	if isDebugEnabled then
		dd(">>>>>>>>>>>>>>>>>>>>>>>>>>>>")
		dd("isSpecialTrue - filterType: %s, gamepadMode: %s, isSpecialForced: %s, paramsGiven: %s", tos(filterType), tos(isInGamepadMode), tos(isSpecialForced), tos(... ~= nil))
	end
	if not filterType then return false end
	local filterTypeData = LF_FilterTypeToCheckIfReferenceIsHidden[isInGamepadMode][filterType]
	local specialRoutines = filterTypeData and ((isSpecialForced == true and filterTypeData["specialForced"]) or filterTypeData["special"])
	if not specialRoutines or #specialRoutines == 0 then
		if isDebugEnabled then
			dd("isSpecialTrue - No checks found! Returned: true")
			dd("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
		end
		return true
	end
	local totalResult = true
	local loopResult = false
	for _, specialRoutineDetails in ipairs(specialRoutines) do
		loopResult = false
		local skip = false
		local checkType
		local checkAborted = ""
		local ctrl = specialRoutineDetails.control
		local bool = specialRoutineDetails.boolean
		if ctrl ~= nil and ctrl ~= "" then
			if isDebugEnabled then checkType = "control"end
			local ctrlType = type(ctrl)
			if ctrlType == "String" then
				local ctrlName = ctrl
				ctrl = GetControl(ctrlName)
			end
			local childControl
			if ctrl ~= nil then
				local funcOrAttribute = specialRoutineDetails.funcOrAttribute
				if funcOrAttribute ~= nil then
					local funcType = type(funcOrAttribute)
					if funcType == "string" then
						if isDebugEnabled then checkType = "control - String"end
						if ctrl[funcOrAttribute] == nil then
							skip = true
							if isDebugEnabled then checkAborted = "ctrl[funcOrAttribute] = nil" end
						end
					elseif funcType == "number" then
						if isDebugEnabled then checkType = "control - table"end
						if ctrlType == "table" and ctrl[funcOrAttribute] == nil then
							skip = true
							if isDebugEnabled then checkAborted = "ctrl[funcOrAttribute] = nil" end
						elseif ctrlType == "userdata" then
							if isDebugEnabled then checkType = "control - userdata"end
							if ctrl.GetChildren == nil then
								skip = true
								if isDebugEnabled then checkAborted = "ctrl.GetChildren = nil" end
							else
								childControl = ctrl:GetChildren()[funcOrAttribute]
							end
							if childControl == nil then
								skip = true
								if isDebugEnabled then checkAborted = "ctrl.childControl = nil" end
							end
						end
					end
					if not skip then
						local expectedResults = specialRoutineDetails.expectedResults
						local expectedResultsMap = specialRoutineDetails.expectedResultsMap
						local results
						local isFunction = (type(ctrl[funcOrAttribute]) == "function") or false
						if isFunction == true then
							local params = specialRoutineDetails.params
							local noParams = false
							if params == nil then
								if isDebugEnabled then dd(">using locally passed in params") end
								params = {...}
								if ncc(params) == 0 then
									if isDebugEnabled then dd(">>locally passed in params are empty") end
									noParams = true
								end
							else
								if isDebugEnabled then dd(">using params of constants") end
								if ncc(params) == 0 then
									if isDebugEnabled then dd(">>params of constants are empty") end
									noParams = true
								end
							end
							if isDebugEnabled then dd(">>CALLING FUNCTION NOW...") end
							if not noParams then
								results = {ctrl[funcOrAttribute](unpack(params))}
							else
								results = {ctrl[funcOrAttribute]()}
							end
						else
							if isDebugEnabled then dd(">>GETTING ATTRIBUTE NOW...") end
							results = {ctrl[funcOrAttribute]}
						end
						if not results then
							if isDebugEnabled then dd(">>>no return values") end
							if expectedResults == nil then
								if isDebugEnabled then dd(">>>no expected results -> OK") end
								loopResult = true
							end
						else
							local numResults = #results
							if isDebugEnabled then dd(">>>return values: " ..tos(numResults)) end
							if numResults == 0 then
								if isDebugEnabled then dd(">>>no return values") end
								if expectedResults == nil then
									if isDebugEnabled then dd(">>>>no expected results -> OK") end
									loopResult = true
								end
							else
								if expectedResults == nil or #expectedResults == 0 then
									loopResult = false
									if isDebugEnabled then checkAborted = ">>expectedResults missing" end
								else
									if numResults ~= #expectedResults then
										if expectedResultsMap ~= nil then
											for expectedResultsMapIdx, isExpectedResult in pairs(expectedResultsMap) do
												if isExpectedResult == true then
													loopResult = results[expectedResultsMapIdx] ~= nil
													if loopResult == false then
														if isDebugEnabled then checkAborted = strfor(">>>expectedResultsMap did not match, index %s", tos(expectedResultsMapIdx)) end
													end
												end
											end
										else
											loopResult = false
											if isDebugEnabled then checkAborted = strfor(">>>numResults [%s] ~= #expectedResults [%s]", tos(numResults), tos(#expectedResults)) end
										end
									elseif numResults == 1 then
										loopResult = results[1] == expectedResults[1]
										if not loopResult then if isDebugEnabled then checkAborted = ">>>results[1]: "..tos(results[1]) .." ~= expectedResults[1]: " ..tos(expectedResults[1]) end end
									end
									if loopResult == true then
										for resultIndex, resultOfResults in ipairs(results) do
											if skip == false then
												if expectedResults[resultIndex] ~= nil then
													loopResult = (resultOfResults == expectedResults[resultIndex]) or false
													if not loopResult then
														skip = true
														if isDebugEnabled then checkAborted = ">>>results[" .. tos(resultIndex) .."]: "..tos(results[resultIndex]) .." ~= expectedResults[" .. tos(resultIndex) .."]: " ..tos(expectedResults[resultIndex]) end
													end
												end
											end
										end
									end
								end
							end
						end
					else
						if isDebugEnabled then checkAborted = "skipped" end
					end
				else
					if isDebugEnabled then checkAborted = "no func/no attribute" end
				end
			end
		elseif bool ~= nil then
			local typeBool= type(bool)
			if typeBool == "function" then
				if isDebugEnabled then checkType = "boolean - function" end
				loopResult = bool()
			elseif typeBool == "boolean" then
				if isDebugEnabled then checkType = "boolean"end
				loopResult = bool
			else
				if isDebugEnabled then
					checkType = "boolean > false"
					checkAborted = "hardcoded boolean false"
				end
				loopResult = false
			end
		else
			if isDebugEnabled then checkAborted = "no checktype" end
		end
		if isDebugEnabled then dd("checkType: %q, abortedDueTo: %s, loopResult: %s", tos(checkType), tos(checkAborted), tos(loopResult)) end
		totalResult = totalResult and loopResult
	end
	if isDebugEnabled then
		dd("isSpecialTrue - filterType: %s, totalResult: %s, isSpecialForced: %s", tos(filterType), tos(totalResult), tos(isSpecialForced))
		dd("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
	end
	return totalResult
end

------------------------------------------------------------------------------------------------------------------------
--LOCAL HELPER FUNCTIONS - filterType mapping
------------------------------------------------------------------------------------------------------------------------
--Returns nil if no matching filterType was found for the passed in filterTypeSource and the craftType
--Else returns the filterType matching the for the passed in filterTypeSource and the craftType
--2nd return parameter is the craftType passed in, or if nothing was in: the detected craftType
local function getFilterTypeByFilterTypeRespectingCraftType(filterTypeSource, craftType)
	if filterTypeSource == nil then return nil end
	if craftType ~= nil and (type(craftType) ~= "number"
			or (craftType <= CRAFTING_TYPE_INVALID or craftType > CRAFTING_TYPE_JEWELRYCRAFTING)) then
		craftType = nil
	end
	craftType = craftType or gcit()
	local filterTypeTarget
	if craftType ~= CRAFTING_TYPE_INVALID then
		if filterTypeToFilterTypeRespectingCraftType[craftType] ~= nil then
			filterTypeTarget = filterTypeToFilterTypeRespectingCraftType[craftType][filterTypeSource]
		end
	end
	filterTypeTarget = filterTypeTarget or filterTypeSource
	if libFilters.debug then
		dd("getFilterTypeByFilterTypeRespectingCraftType-source: %q, target: %q, craftType: %s",
			tos(filterTypeSource), tos(filterTypeTarget), tos(craftType))
	end
	return filterTypeTarget, craftType
end

--Check if CraftBagExtended addon is enabled and if any of the supported extra panels/fragments are shown
--and if the extra menu buttons of CBE are clicked to currently show the craftbag, and if the fragment's layoutData of
--the CBE fragments hooked use the same number filterType as passed in
local function craftBagExtendedCheckForCurrentModule(filterType)
	local isDebugEnabled = libFilters.debug
	if isDebugEnabled then dd("craftBagExtendedCheckForCurrentModule - filterTypePassedIn: " .. tos(filterType)) end
	local cbe = CraftBagExtended
	local cbeCurrentModule = cbe.currentModule
	if cbeCurrentModule == nil then
		if isDebugEnabled then dd("<no current CBE module found") end
		return true, LF_INVENTORY
	end
	local cbeDescriptorOfCraftBag = 4402 --GetString(4402) = "CraftBag"
	--Check if the CBE button at the menu is activated -> Means te CBE fragment is shown
	local cbeMenu = cbeCurrentModule.menu
	local currentlyClickedButtonDescriptor = cbeMenu.m_object:GetSelectedDescriptor()
	if isDebugEnabled then dd(">currentClickedButton: %s = %q", tos(currentlyClickedButtonDescriptor), tos(GetString(currentlyClickedButtonDescriptor))) end
	if currentlyClickedButtonDescriptor == nil or currentlyClickedButtonDescriptor ~= cbeDescriptorOfCraftBag then return  nil, nil end
	local cbeFragmentLayoutData = cbeCurrentModule.layoutFragment and cbeCurrentModule.layoutFragment.layoutData
	--Get the constants.defaultAttributeToStoreTheFilterType (.LibFilters3_filterType) from the layoutdata
	local filterTypeAtFragment = libFilters_GetCurrentFilterTypeForInventory(libFilters, cbeFragmentLayoutData, false)
	if isDebugEnabled then dd(">filterTypeAtFragment: %s", tos(filterTypeAtFragment)) end
	if filterTypeAtFragment == nil then return  nil, nil end
	local referencesFound = {}
	if filterTypeAtFragment == filterType then
		tins(referencesFound, cbeCurrentModule.scene)
		return referencesFound, filterTypeAtFragment
	end
	return nil, nil
end

local function checkIfShownNow(filterTypeControlAndOtherChecks, isInGamepadMode)
	local isDebugEnabled = libFilters.debug
	local lReferencesToFilterType, lFilterTypeDetected
	if filterTypeControlAndOtherChecks ~= nil then
		local filterTypeChecked = filterTypeControlAndOtherChecks.filterType
		if isDebugEnabled then dd(">>>===== checkIfShownNow = START =") end
		if isDebugEnabled then dd(">checking filterType: %q [%s]", libFilters:GetFilterTypeName(filterTypeChecked), tos(filterTypeChecked)) end
		if filterTypeChecked ~= nil then
			local checkTypes = filterTypeControlAndOtherChecks.checkTypes
			if checkTypes ~= nil then
				local currentReferenceFound
				local resultOfCurrentLoop = true
				local resultLoop = false
				local doSpecialForcedCheckAtEnd = false
				for _, checkTypeToExecute in ipairs(checkTypes) do
					--Only go on with checks if not any check was false before
					if resultOfCurrentLoop == true then
						resultLoop = false
						if checkTypeToExecute == "control" then
							resultLoop, currentReferenceFound = isControlShown(filterTypeChecked, isInGamepadMode)
						elseif checkTypeToExecute == "controlDialog" then
							resultLoop, currentReferenceFound = isListDialogShownWrapper(filterTypeChecked, isInGamepadMode)
						elseif checkTypeToExecute == "fragment" then
							resultLoop, currentReferenceFound = isSceneFragmentShown(filterTypeChecked, isInGamepadMode, nil, false)
						elseif checkTypeToExecute == "scene" then
							resultLoop, currentReferenceFound = isSceneFragmentShown(filterTypeChecked, isInGamepadMode, nil, true)
						elseif checkTypeToExecute == "special" then
							--local paramsForFilterTypeSpecialCheck = {} --todo create  function to get needed parameters for the special check per filterType?
							resultLoop = isSpecialTrue(filterTypeChecked, isInGamepadMode, false, nil) --instead , nil ->  use , unpack(paramsForFilterTypeSpecialCheck))
						elseif checkTypeToExecute == "specialForced" then
							if resultOfCurrentLoop == true then resultLoop = true end
							doSpecialForcedCheckAtEnd = true
						end
						if isDebugEnabled then dd(">>foundInLoop: %s, checkType: %s", tos(resultLoop), tos(checkTypeToExecute)) end
					else
						if isDebugEnabled then dd(">>>skipped checkType: %s  - resultOfCurrentLoop was false already", tos(checkTypeToExecute) ) end
					end
					resultOfCurrentLoop = resultOfCurrentLoop and resultLoop
				end
				--End checks
				if resultOfCurrentLoop == true then
					if doSpecialForcedCheckAtEnd == true then
						resultOfCurrentLoop = isSpecialTrue(filterTypeChecked, isInGamepadMode, true, nil)
						if isDebugEnabled then dd(">>>specialCheckAtEnd: " ..tos(resultOfCurrentLoop)) end
					end
					if resultOfCurrentLoop == true then
						lFilterTypeDetected = filterTypeChecked
						if currentReferenceFound == nil then
							if isDebugEnabled then dd(">>>>currentReferenceFound is nil, detecing it...") end
							currentReferenceFound = libFilters_GetFilterTypeReferences(libFilters, filterTypeChecked, isInGamepadMode)
						end
						if currentReferenceFound ~= nil then
							local curRefType = type(currentReferenceFound)
							if isDebugEnabled then dd(">>>>currentReferenceFound: YES, type: %s", tos(curRefType)) end
							lReferencesToFilterType = {}
							if curRefType == "table" then
								--[[
								for _, refInRefTab in pairs(currentReferenceFound) do
									tins(lReferencesToFilterType, refInRefTab)
								end
								]]
								--lReferencesToFilterType = currentReferenceFound
								tins(lReferencesToFilterType, currentReferenceFound)
							else
								tins(lReferencesToFilterType, currentReferenceFound)
							end
						end
					end
				end
			end
		end
		--Prevent to return different filterTypes and references
		if lFilterTypeDetected ~= nil and lReferencesToFilterType ~= nil and #lReferencesToFilterType > 0 then
			if isDebugEnabled then dd("<<<===== checkIfShownNow = END =") end
			libFilters._currentFilterTypeReferences = 	lReferencesToFilterType
			libFilters._currentFilterType = 			lFilterTypeDetected
			--Abort the for ... do loop now as data was found
			return lReferencesToFilterType, lFilterTypeDetected
		end
	end
	return lReferencesToFilterType, lFilterTypeDetected
end

local function detectShownReferenceNow(p_filterType, isInGamepadMode)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	local lFilterTypeDetected = nil
	local lReferencesToFilterType = {}
	local isDebugEnabled = libFilters.debug
	if isDebugEnabled then dd(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>") end
	if isDebugEnabled then dd("detectShownReferenceNow - filterTypePassedIn: %s, isInGamepadMode: %s",
			tos(p_filterType), tos(isInGamepadMode) ) end

	--Check one specific filterType first (e.g. cached one)
	if p_filterType ~= nil then
		--Get data to check from lookup table
		local filterTypeChecksIndex = LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup[isInGamepadMode][p_filterType]
		if filterTypeChecksIndex ~= nil then
			local filterTypeControlAndOtherChecks = LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[isInGamepadMode][filterTypeChecksIndex]
			--Check if still shown
			lReferencesToFilterType, lFilterTypeDetected = checkIfShownNow(filterTypeControlAndOtherChecks, isInGamepadMode)
		end
		return lReferencesToFilterType, lFilterTypeDetected
	end

	--Dynamically get the filterType via the currently shown control/fragment/scene/special check and specialForced check
	for _, filterTypeControlAndOtherChecks in ipairs(LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[isInGamepadMode]) do
		lReferencesToFilterType, lFilterTypeDetected = checkIfShownNow(filterTypeControlAndOtherChecks, isInGamepadMode)

		--[[
		local filterTypeChecked = filterTypeControlAndOtherChecks.filterType
		if isDebugEnabled then dd("=====================") end
		if isDebugEnabled then dd(">checking filterType: %q [%s]", libFilters:GetFilterTypeName(filterTypeChecked), tos(filterTypeChecked)) end
		if filterTypeChecked ~= nil then
			local checkTypes = filterTypeControlAndOtherChecks.checkTypes
			if checkTypes ~= nil then
				local currentReferenceFound
				local resultOfCurrentLoop = true
				local resultLoop = false
				local doSpecialForcedCheckAtEnd = false
				for _, checkTypeToExecute in ipairs(checkTypes) do
					--Only go on with checks if not any check was false before
					if resultOfCurrentLoop == true then
						resultLoop = false
						if checkTypeToExecute == "control" then
							resultLoop, currentReferenceFound = isControlShown(filterTypeChecked, isInGamepadMode)
						elseif checkTypeToExecute == "controlDialog" then
							resultLoop, currentReferenceFound = isListDialogShownWrapper(filterTypeChecked, isInGamepadMode)
						elseif checkTypeToExecute == "fragment" then
							resultLoop, currentReferenceFound = isSceneFragmentShown(filterTypeChecked, isInGamepadMode, nil, false)
						elseif checkTypeToExecute == "scene" then
							resultLoop, currentReferenceFound = isSceneFragmentShown(filterTypeChecked, isInGamepadMode, nil, true)
						elseif checkTypeToExecute == "special" then
							--local paramsForFilterTypeSpecialCheck = {} --todo create  function to get needed parameters for the special check per filterType?
							resultLoop = isSpecialTrue(filterTypeChecked, isInGamepadMode, false, nil) --instead , nil ->  use , unpack(paramsForFilterTypeSpecialCheck))
						elseif checkTypeToExecute == "specialForced" then
							if resultOfCurrentLoop == true then resultLoop = true end
							doSpecialForcedCheckAtEnd = true
						end
						if isDebugEnabled then dd(">>foundInLoop: %s, checkType: %s", tos(resultLoop), tos(checkTypeToExecute)) end
					else
						if isDebugEnabled then dd(">>>skipped checkType: %s  - resultOfCurrentLoop was false already", tos(checkTypeToExecute) ) end
					end
					resultOfCurrentLoop = resultOfCurrentLoop and resultLoop
				end
				--End checks
				if resultOfCurrentLoop == true then
					if doSpecialForcedCheckAtEnd == true then
						resultOfCurrentLoop = isSpecialTrue(filterTypeChecked, isInGamepadMode, true, nil)
						if isDebugEnabled then dd(">>>specialCheckAtEnd: " ..tos(resultOfCurrentLoop)) end
					end
					if resultOfCurrentLoop == true then
						lFilterTypeDetected = filterTypeChecked
						if currentReferenceFound == nil then
							if isDebugEnabled then dd(">>>>currentReferenceFound is nil, detecing it...") end
							currentReferenceFound = libFilters_GetFilterTypeReferences(libFilters, filterTypeChecked, isInGamepadMode)
						end
						if currentReferenceFound ~= nil then
							if type(currentReferenceFound) == "table" then
								-- --[ [
								--for _, refInRefTab in pairs(currentReferenceFound) do
								--	tins(lReferencesToFilterType, refInRefTab)
								--end
								-- ] ]
								lReferencesToFilterType = currentReferenceFound
							else
								tins(lReferencesToFilterType, currentReferenceFound)
							end
						end
					end
				end
			end
		end

		--Prevent to return different filterTypes and references
		if lFilterTypeDetected ~= nil and #lReferencesToFilterType > 0 then
			if isDebugEnabled then dd("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<") end
			libFilters._currentFilterTypeReferences = 	lReferencesToFilterType
			libFilters._currentFilterType = 			lFilterTypeDetected
			--Abort the for ... do loop now as data was found
			return lReferencesToFilterType, lFilterTypeDetected
		end
		]]

		if lFilterTypeDetected ~= nil and lReferencesToFilterType ~= nil and #lReferencesToFilterType > 0 then
			if isDebugEnabled then dd("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<") end
			libFilters._currentFilterTypeReferences = 	lReferencesToFilterType
			libFilters._currentFilterType = 			lFilterTypeDetected
			--Abort the for ... do loop now as data was found
			return lReferencesToFilterType, lFilterTypeDetected
		end
	end --for _, filterTypeControlAndOtherChecks in ipairs(LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[isInGamepadMode]) do

	if isDebugEnabled then dd("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<") end
	libFilters._currentFilterTypeReferences = 	lReferencesToFilterType
	libFilters._currentFilterType = 			lFilterTypeDetected
	return lReferencesToFilterType, lFilterTypeDetected
end

--Is the filterType cached at libFilters._currentFilterType (set during call to updater functions and other functions)
--still the valid one, and it's reference is still shown?
local function checkIfCachedFilterTypeIsStillShown(filterType, isInGamepadMode)
	local isDebugEnabled = libFilters.debug
	if filterType == nil and libFilters._currentFilterType ~= nil then
		local filterTypeReference, filterTypeShown = detectShownReferenceNow(libFilters._currentFilterType, isInGamepadMode)
		if filterTypeReference ~= nil and filterTypeShown ~= nil and filterTypeShown == libFilters._currentFilterType then
			if isDebugEnabled then dd("checkIfCachedFilterTypeIsStillShown %q: %s", tos(filterTypeShown), "YES") end
			libFilters._currentFilterTypeReferences = filterTypeReference
			return filterTypeReference, filterTypeShown
		else
			libFilters._currentFilterTypeReferences = nil
			libFilters._currentFilterType = nil
		end
	end
	if isDebugEnabled then dd("checkIfCachedFilterTypeIsStillShown %q: %s", tos(filterType), "NO") end
	return nil, nil
end


------------------------------------------------------------------------------------------------------------------------
--LOCAL HELPER FUNCTIONS - Control IsShown checks
------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------
--KEYBOARD updater functions
------------------------------------------------------------------------------------------------------------------------
--Update the inventory lists
--if the mouse is enabled, cycle its state to refresh the integrity of the control beneath it
local function SafeUpdateList(object, ...)
	if libFilters.debug then
		local updatedName = (object and (object.name or (object.GetName and object:GetName()))
				or (object.list and object.list.GetName and object.list:GetName())
				or (object.container and object.container.GetName and object.container:GetName())
				or (object.control and object.control.GetName and object.control:GetName())
		)
		if updatedName == nil and ... ~= nil then
			if object.inventories ~= nil then
				local playerInventoryInventoriesInvToUpdate = object.inventories[...]
				updatedName = playerInventoryInventoriesInvToUpdate	and playerInventoryInventoriesInvToUpdate.listView
						and playerInventoryInventoriesInvToUpdate.listView.GetName and playerInventoryInventoriesInvToUpdate.listView:GetName()
			end
		end
		updatedName = updatedName or "n/a"
		dd("SafeUpdateList, inv: %s, name: %s", tos(object), tos(updatedName))
	end
	local isMouseVisible = SM:IsInUIMode()
	if isMouseVisible then HideMouse() end
	object:UpdateList(...)
	if isMouseVisible then ShowMouse() end
end

--Function to update a ZO_ListDialog1 dialog's list contents
local function dialogUpdaterFunc(listDialogControl)
	if libFilters.debug then dd("dialogUpdaterFunc, listDialogControl: %s", (listDialogControl ~= nil and listDialogControl.GetName ~= nil and tos(listDialogControl:GetName()) or "listDialogName: n/a")) end
	 if listDialogControl == nil then return nil end
	 --Get & Refresh the list dialog
	 local listDialog = ZO_InventorySlot_GetItemListDialog()
	 if listDialog ~= nil and listDialog.control ~= nil then
		  local data = listDialog.control.data
		  if not data then return end
		  --Update the research dialog?
		  if listDialogControl == researchChooseItemDialog then --SMITHING_RESEARCH_SELECT
				if data.craftingType and data.researchLineIndex and data.traitIndex then
					 --Re-Call the dialog's setup function to clear the list, check available data and filter the items (see helper.lua, helpers["SMITHING_RESEARCH_SELECT"])
					 listDialogControl.SetupDialog(listDialogControl, data.craftingType, data.researchLineIndex, data.traitIndex)
				end
		  end
	 end
end

--Updater function for a normal inventory in keyboard mode
local function updateKeyboardPlayerInventoryType(invType)
	if libFilters.debug then dd("updateKeyboardPlayerInventoryType - invType: %s", tos(invType)) end
	SafeUpdateList(playerInv, invType)
end


------------------------------------------------------------------------------------------------------------------------
--KEYBOARD & GAMEPAD updater functions
------------------------------------------------------------------------------------------------------------------------
--Updater function for a crafting inventory in keyboard and gamepad mode
local function updateCraftingInventoryDirty(craftingInventory)
	if libFilters.debug then dd("updateCraftingInventoryDirty - craftingInventory: %s", tos(craftingInventory)) end
	craftingInventory.inventory:HandleDirtyEvent()
end

-- update for LF_BANK_DEPOSIT/LF_GUILDBANK_DEPOSIT/LF_HOUSE_BANK_DEPOSIT/LF_MAIL_SEND/LF_TRADE/LF_BANK_WITHDRAW/LF_GUILDBANK_WITHDRAW/LF_HOUSE_BANK_WITHDRAW
local function updateFunction_GP_ZO_GamepadInventoryList(gpInvVar, list, callbackFunc)
	if libFilters.debug then dd("updateFunction_GP_ZO_GamepadInventoryList - gpInvVar: %s, list: %s, callbackFunc: %s", tos(gpInvVar), tos(list), tos(callbackFunc)) end
	-- prevent UI errors for lists created OnDeferredInitialization
	if not gpInvVar or not gpInvVar[list] then return end
	local TRIGGER_CALLBACK = true
	gpInvVar[list]:RefreshList(TRIGGER_CALLBACK)
	if callbackFunc then callbackFunc() end
end

-- update for LF_GUILDSTORE_SELL/LF_VENDOR_BUY/LF_VENDOR_BUYBACK/LF_VENDOR_REPAIR/LF_VENDOR_SELL/LF_FENCE_SELL/LF_FENCE_LAUNDER gamepad
local function updateFunction_GP_UpdateList(gpInvVar)
	if libFilters.debug then dd("updateFunction_GP_UpdateList - gpInvVar: %s", tos(gpInvVar)) end
	-- prevent UI errors for lists created OnDeferredInitialization
	if not gpInvVar then return end
	gpInvVar:UpdateList()
end

-- update function for LF_VENDOR_BUY/LF_VENDOR_BUYBACK/LF_VENDOR_REPAIR/LF_VENDOR_SELL/LF_FENCE_SELL/LF_FENCE_LAUNDER gamepad
local function updateFunction_GP_Vendor(storeMode)
	if libFilters.debug then dd("updateFunction_GP_Vendor - storeMode: %s", tos(storeMode)) end
	if not store_componentsGP then return end
	updateFunction_GP_UpdateList(store_componentsGP[storeMode].list)
end

-- update for LF_INVENTORY/LF_INVENTORY_COMPANION/LF_INVENTORY_QUEST gamepad
local function updateFunction_GP_ItemList(gpInvVar)
	if libFilters.debug then dd("updateFunction_GP_ItemList - gpInvVar: %s", tos(gpInvVar)) end
	if not gpInvVar.itemList or gpInvVar.currentListType ~= "itemList" then return end
	gpInvVar:RefreshItemList()
	if gpInvVar.itemList:IsEmpty() then
		gpInvVar:SwitchActiveList("categoryList")
	else
		gpInvVar:UpdateRightTooltip()
		gpInvVar:RefreshItemActions()
	end
end

-- update for LF_CRAFTBAG gamepad
local function updateFunction_GP_CraftBagList(gpInvVar)
	if libFilters.debug then dd("updateFunction_GP_CraftBagList - gpInvVar: %s", tos(gpInvVar)) end
	if not gpInvVar.craftBagList then return end
	gpInvVar:RefreshCraftBagList()
	gpInvVar:RefreshItemActions()
end

-- update for LF_ENCHANTING_CREATION/LF_ENCHANTING_EXTRACTION gamepad
local function updateFunction_GP_CraftingInventory(craftingInventory)
	if libFilters.debug then dd("updateFunction_GP_CraftingInventory - craftingInventory: %s", tos(craftingInventory)) end
	if not craftingInventory then return end
	craftingInventory:PerformFullRefresh()
end

--Update functions for the gamepad inventory
gpc.InventoryUpdateFunctions      = {
	[LF_INVENTORY] = function()
	  updateFunction_GP_ItemList(invBackpack_GP)
	end,
	[LF_BANK_DEPOSIT] = function()
		updateFunction_GP_ZO_GamepadInventoryList(invBank_GP, "depositList")
	end,
	[LF_GUILDBANK_DEPOSIT]  = function()
		updateFunction_GP_ZO_GamepadInventoryList(invGuildBank_GP, "depositList")
	end,
	[LF_HOUSE_BANK_DEPOSIT] = function()
		updateFunction_GP_ZO_GamepadInventoryList(invBank_GP, "depositList")
	end,
	[LF_MAIL_SEND] = function()
		updateFunction_GP_ZO_GamepadInventoryList(gpc.invMailSend_GP, "inventoryList")
	end,
	[LF_TRADE] = function()
		updateFunction_GP_ZO_GamepadInventoryList(gpc.invPlayerTrade_GP, "inventoryList")
	end,
	[LF_GUILDSTORE_SELL] = function()
		if libFilters.debug and gpc.invGuildStoreSell_GP == nil then dd("updateFunction LF_GUILDSTORE_SELL: Added reference to GAMEPAD_TRADING_HOUSE_SELL") end
        gpc.invGuildStoreSell_GP = gpc.invGuildStoreSell_GP or GAMEPAD_TRADING_HOUSE_SELL
		updateFunction_GP_UpdateList(gpc.invGuildStoreSell_GP)
	end,
	[LF_VENDOR_SELL] = function()
		updateFunction_GP_Vendor(ZO_MODE_STORE_SELL)
	end,
	[LF_FENCE_SELL] = function()
		updateFunction_GP_Vendor(ZO_MODE_STORE_SELL_STOLEN)
	end,
	[LF_FENCE_LAUNDER] = function()
		updateFunction_GP_Vendor(ZO_MODE_STORE_LAUNDER)
	end
}
local InventoryUpdateFunctions_GP = gpc.InventoryUpdateFunctions


------------------------------------------------------------------------------------------------------------------------
--KEYBOARD & GAMEPAD updater string to updater function
------------------------------------------------------------------------------------------------------------------------
--The updater functions used within LibFilters:RequestUpdate() for the LF_* constants
--Will call a refresh or update of the inventory lists, or scenes, or set a "isdirty" flag and update the crafting lists, etc.
local inventoryUpdaters           = {
	INVENTORY = function(filterType)
		if IsGamepad() then
			InventoryUpdateFunctions_GP[filterType]()
		else
			updateKeyboardPlayerInventoryType(invTypeBackpack)
		end
	end,
	INVENTORY_COMPANION = function()
		if IsGamepad() then
			updateFunction_GP_ItemList(gpc.companionEquipment_GP)
		else
			SafeUpdateList(kbc.companionEquipment, nil)
		end
	end,
	CRAFTBAG = function()
		if IsGamepad() then
			updateFunction_GP_CraftBagList(invBackpack_GP)
		else
			updateKeyboardPlayerInventoryType(invTypeCraftBag)
		end
	end,
	INVENTORY_QUEST = function()
		if IsGamepad() then
			updateFunction_GP_ItemList(invBackpack_GP)
		else
			updateKeyboardPlayerInventoryType(invTypeQuest)
		end
	end,
	QUICKSLOT = function()
		if IsGamepad() then
			--[[
				--Not supported yet as quickslots in gamepad mode are totally different from keyboard mode. One would
				--have to add filter possibilities not only in inventory consumables but also directly in the collections
				--somehow
			]]
			if libFilters.debug then dd("updateFunction_GP_QUICKSLOT - Not supported yet!") end
	--		SafeUpdateList(quickslots_GP) --TODO
		else
			SafeUpdateList(kbc.quickslots)
		end
	end,
	BANK_WITHDRAW = function()
		if IsGamepad() then
			updateFunction_GP_ZO_GamepadInventoryList(invBank_GP, "withdrawList")
		else
			updateKeyboardPlayerInventoryType(invTypeBank)
		end
	end,
	GUILDBANK_WITHDRAW = function()
		if IsGamepad() then
			updateFunction_GP_ZO_GamepadInventoryList(invGuildBank_GP, "withdrawList")
		else
			updateKeyboardPlayerInventoryType(invTypeGuildBank)
		end
	end,
	HOUSE_BANK_WITHDRAW = function()
		if IsGamepad() then
			updateFunction_GP_ZO_GamepadInventoryList(invBank_GP, "withdrawList")
		else
			updateKeyboardPlayerInventoryType(invTypeHouseBank)
		end
	end,
	VENDOR_BUY = function()
		if IsGamepad() then
			updateFunction_GP_Vendor(ZO_MODE_STORE_BUY)
		else
			if kbc.guildStoreSell.state ~= SCENE_SHOWN then --"shown"
				store:GetStoreItems()
				SafeUpdateList(store)
			end
		end
	end,
	VENDOR_BUYBACK = function()
		if IsGamepad() then
			updateFunction_GP_Vendor(ZO_MODE_STORE_BUY_BACK)
		else
			SafeUpdateList(kbc.vendorBuyBack)
		end
	end,
	VENDOR_REPAIR = function()
		if IsGamepad() then
			updateFunction_GP_Vendor(ZO_MODE_STORE_REPAIR)
		else
			SafeUpdateList(kbc.vendorRepair)
		end
	end,
	GUILDSTORE_BROWSE = function()
	--[[
		--Not supported yet
		if IsGamepad() then
		else
		end
	]]
		if libFilters.debug then dd("updateFunction GUILDSTORE_BROWSE: Not supported yet") end
	end,
	SMITHING_REFINE = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(gpc.refinementPanel_GP)
		else
			updateCraftingInventoryDirty(kbc.refinementPanel)
		end
	end,
	SMITHING_CREATION = function()
	--[[
		--Not supported yet
		if IsGamepad() then
		else
		end
	]]
		if libFilters.debug then dd("updateFunction SMITHING_CREATION: Not supported yet") end
	end,
	SMITHING_DECONSTRUCT = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(gpc.deconstructionPanel_GP)
		else
			updateCraftingInventoryDirty(kbc.deconstructionPanel)
		end
	end,
	SMITHING_IMPROVEMENT = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(gpc.improvementPanel_GP)
		else
			updateCraftingInventoryDirty(kbc.improvementPanel)
		end
	end,
	SMITHING_RESEARCH = function()
		if IsGamepad() then
			if not researchPanel_GP.researchLineList then return end
			if libFilters.debug then dd("updateFunction_GP_SMITHING_RESEARCH - SMITHING_GAMEPAD.researchPanel:Refresh() called") end
			researchPanel_GP:Refresh()
		else
			if libFilters.debug then dd("updateFunction_Keyboard_SMITHING_RESEARCH - SMITHING.researchPanel:Refresh() called") end
			kbc.researchPanel:Refresh()
		end
	end,
	SMITHING_RESEARCH_DIALOG = function()
		if IsGamepad() then
			-->The index [1] in GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE.callbackRegistry.StateChange is the original state change of ZOs vailla UI and should trigger the
			-->refresh of the scene's list contents
			--> See here: esoui/ingame/crafting/gamepad/smithingresearch_gamepad.lua
			-->GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE:RegisterCallback("StateChange", function(oldState, newState)
			--sceneStateChangeCallbackUpdater(gamepadConstants.researchChooseItemDialog_GP, SCENE_HIDDEN, SCENE_SHOWING, 1, nil)
			if not researchPanel_GP.confirmList then return end
			if libFilters.debug then dd("updateFunction_GP_SMITHING_RESEARCH_DIALOG - GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE:FireCallbacks(StateChange, nil, SCENE_SHOWING) called") end
			gpc.researchChooseItemDialog_GP:FireCallbacks("StateChange", nil, SCENE_SHOWING)
		else
			dialogUpdaterFunc(researchChooseItemDialog)
		end
	end,
	ALCHEMY_CREATION = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(gpc.alchemy_GP)
		else
			updateCraftingInventoryDirty(kbc.alchemy)
		end
	end,
	ENCHANTING = function()
		if IsGamepad() then
			updateFunction_GP_CraftingInventory(gpc.enchanting_GP)
		else
			updateCraftingInventoryDirty(kbc.enchanting)
		end
	end,
	PROVISIONING_COOK = function()
	--[[
		--Not supported yet
		if IsGamepad() then
		else
		end
	]]
		if libFilters.debug then dd("updateFunction PROVISIONING_COOK: Not supported yet") end
	end,
	PROVISIONING_BREW = function()
	--[[
		--Not supported yet
		if IsGamepad() then
		else
		end
	]]
		if libFilters.debug then dd("updateFunction PROVISIONING_BREW: Not supported yet") end
	end,
	RETRAIT = function()
		if IsGamepad() then
			if libFilters.debug then dd("updateFunction_GP_RETRAIT: ZO_RETRAIT_STATION_RETRAIT_GAMEPAD:Refresh() called") end
			gpc.retrait_GP:Refresh() -- ZO_RETRAIT_STATION_RETRAIT_GAMEPAD
		else
			updateCraftingInventoryDirty(kbc.retrait)
		end
	end,
	RECONSTRUCTION = function()
		if IsGamepad() then
			if libFilters.debug then dd("updateFunction_GP_RECONSTRUCTION: ZO_RETRAIT_STATION_RECONSTRUCT_GAMEPAD:RefreshFocusItems() called") end
			-- not sure how reconstruct works, how it would be filtered.
			gpc.reconstruct_GP:RefreshFocusItems() -- ZO_RETRAIT_STATION_RECONSTRUCT_GAMEPAD
		else
			updateCraftingInventoryDirty(kbc.reconstruct)
		end
	end,
}
libFilters.mapping.inventoryUpdaters = inventoryUpdaters


------------------------------------------------------------------------------------------------------------------------
--RUN THE FILTERS
------------------------------------------------------------------------------------------------------------------------
--Run the applied filters at a LibFilters filterType (LF_*) now, using the ... parameters
--(e.g. 1st parameter inventorySlot, or at e.g. carfting tables 1st parameter bagId & 2nd parameter slotIndex)
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
--HOOK VARIABLEs TO ADD .additionalFilter to them
------------------------------------------------------------------------------------------------------------------------
--Hook the different inventory panels (LibFilters filterTypes) now and add the .additionalFilter entry to each panel's
--control/scene/fragment/...
local function applyAdditionalFilterHooks()
	if libFilters.debug then dd("ApplyAdditionalFilterHooks") end
	--For each LF constant hook the filters now to add the .additionalFilter entry
	-->Keyboard and gamepad mode are both hooked here via 2nd param = true
	for value, _ in ipairs(libFiltersFilterConstants) do
		-->HookAdditionalFilterSpecial will be done automatically in HookAdditionalFilter, via the table
		-->LF_ConstantToAdditionalFilterSpecialHook
		libFilters_hookAdditionalFilter(libFilters, value, true) --value = the same as _G[filterConstantName], eg. LF_INVENTORY
	end
end



--**********************************************************************************************************************
--**********************************************************************************************************************
--**********************************************************************************************************************
-- BEGIN LibFilters API functions BEGIN
--**********************************************************************************************************************

--**********************************************************************************************************************
-- Filter types
--**********************************************************************************************************************
--Returns number the minimum possible filteType
function libFilters:GetMinFilterType()
	 return LF_FILTER_MIN
end
--Compatibility function names
libFilters.GetMinFilter = libFilters.GetMinFilterType


--Returns number the maxium possible filterType
function libFilters:GetMaxFilterType()
	 return LF_FILTER_MAX
end
--Compatibility function names
libFilters.GetMaxFilter = libFilters.GetMaxFilterType


--Set the state of the LF_FILTER_ALL "fallback" filter possibilities.
--If boolean newState is enabled: function runFilters will also check for LF_FILTER_ALL filter functions and run them
--If boolean newState is disabled: function runFilters will NOT use LF_FILTER_ALL fallback functions
function libFilters:SetFilterAllState(newState)
	if libFilters.debug then dd("SetFilterAllState-%s", tos(newState)) end
	if newState == nil or type(newState) ~= "boolean" then
		dfe("Invalid call to SetFilterAllState(%q).\n>Needed format is: boolean newState",
			tos(newState))
		return
	end
	libFilters.useFilterAllFallback = newState
end


--Returns table LibFilters LF* filterType connstants table { [1] = "LF_INVENTORY", [2] = "LF_BANK_WITHDRAW", ... }
--See file constants.lua, table "libFiltersFilterConstants"
function libFilters:GetFilterTypes()
	 return libFiltersFilterConstants
end


--Returns String LibFilters LF* filterType constant's name for the number filterType
function libFilters:GetFilterTypeName(filterType)
	if libFilters.debug then dd("GetFilterTypeName-%q", tos(filterType)) end
	if not filterType then
		dfe("Invalid argument to GetFilterTypeName(%q).\n>Needed format is: number LibFiltersLF_*FilterType",
			tos(filterType))
		return
	end
	return libFiltersFilterConstants[filterType] or ""
end
local libFilters_GetFilterTypeName = libFilters.GetFilterTypeName


--Returns number typeOfFilterFunction used for the number LibFilters LF* filterType constant.
--Either LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT or LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX
--or nil if error occured or no filter function type was determined
-- returns number filterFunctionType
function libFilters:GetFilterTypeFunctionType(filterType)
	if libFilters.debug then dd("GetFilterTypeFunctionType-%q", tos(filterType)) end
	if not filterType then
		dfe("Invalid argument to GetFilterTypeFunctionType(%q).\n>Needed format is: number LibFiltersLF_*FilterType",
			tos(filterType))
		return
	end
	if filterTypesUsingBagIdAndSlotIndexFilterFunction[filterType] ~= nil then
		return LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX
	elseif filterTypesUsingInventorySlotFilterFunction[filterType] ~= nil then
		return LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT
	end
	return nil
end


--Returns number the current libFilters filterType for the inventoryType, where inventoryType would be e.g.
--INVENTORY_BACKPACK, INVENTORY_BANK, ..., or a SCENE or a control given within table libFilters.mapping.
--LF_FilterTypeToReference[gamepadMode = true / or keyboardMode = false]
function libFilters:GetCurrentFilterTypeForInventory(inventoryType, noRefUpdate)
	noRefUpdate = noRefUpdate or false
	if not inventoryType then
		dfe("Invalid arguments to GetCurrentFilterTypeForInventory(%q).\n>Needed format is: inventoryTypeNumber(e.g. INVENTORY_BACKPACK)/userdata/table/scene/control inventoryType",
				tos(inventoryType))
		return
	end
	local errorAppeared = false
	local filterTypeDetected
	--Get the layoutData from the fragment. If no fragment: Abort
	if inventoryType == invTypeBackpack then --INVENTORY_BACKPACK
		local layoutData = playerInv.appliedLayout
		if layoutData and layoutData[defaultLibFiltersAttributeToStoreTheFilterType] then --.LibFilters3_filterType
			filterTypeDetected = layoutData[defaultLibFiltersAttributeToStoreTheFilterType] --.LibFilters3_filterType
		else
			errorAppeared = true
		end
	end
	if not errorAppeared then
		local invVarIsNumber = (type(inventoryType) == "number") or false
		if not invVarIsNumber then
			--Check if inventoryType is a SCENE or fragment, e.g. GAMEPAD_ENCHANTING_CREATION_SCENE
			if inventoryType.sceneManager ~= nil and inventoryType[defaultLibFiltersAttributeToStoreTheFilterType] ~= nil then --.LibFilters3_filterType
				filterTypeDetected = inventoryType[defaultLibFiltersAttributeToStoreTheFilterType] --.LibFilters3_filterType
			end
		end
		--Afterwards:
		--Get the inventory from PLAYER_INVENTORY.inventories if the "number" check returns true,
		--and else use inventoryType directly to support enchanting.inventory
		if filterTypeDetected == nil then
			local inventory = (invVarIsNumber and inventories[inventoryType] ~= nil and inventories[inventoryType]) or inventoryType
			if inventory == nil or inventory[defaultLibFiltersAttributeToStoreTheFilterType] == nil then
				errorAppeared = true
			else
				if filterTypeDetected == nil then
					filterTypeDetected = inventory[defaultLibFiltersAttributeToStoreTheFilterType] --.LibFilters3_filterType
				end
			end
		end
	end
	if not noRefUpdate then
		--Was updated at calling function already
		libFilters._currentFilterTypeReferences = libFilters_GetFilterTypeReferences(libFilters, filterTypeDetected)
	end
	libFilters._currentFilterType = 			filterTypeDetected

	if libFilters.debug then dd("GetCurrentFilterTypeForInventory-%q: %s, error: %s", tos(inventoryType), tos(filterTypeDetected), tos(errorAppeared)) end
	return filterTypeDetected
end
libFilters_GetCurrentFilterTypeForInventory = libFilters.GetCurrentFilterTypeForInventory


-- Get the actually used filterType via the shown control/scene/userdata information
-- returns number LF*_filterType
function libFilters:GetCurrentFilterType()
	local isDebugEnabled = libFilters.debug
	local filterTypeReference, filterType = libFilters_GetCurrentFilterTypeReference(libFilters, nil, nil)
	if isDebugEnabled then dd("GetCurrentFilterType-filterReference: %s", tos(filterTypeReference)) end
	if filterTypeReference == nil then return end

	libFilters._currentFilterTypeReferences = filterTypeReference

	local currentFilterType = filterType
	--FilterType was not detected yet (e.g. from cached filterType currently shown)
	if currentFilterType == nil then
		--Check each shown variable for the LibFilters filterType LF_* constant
		for _, shownVariable in ipairs(filterTypeReference) do
			--Do not update the references to libFilters._currentFilterTypeReferences as it was done above already
			currentFilterType = libFilters_GetCurrentFilterTypeForInventory(libFilters, shownVariable, true)
			if currentFilterType ~= nil then
				if isDebugEnabled then dd("currentFilterType: %s", tos(currentFilterType)) end
				return currentFilterType
			end
		end
	end

	libFilters._currentFilterType = currentFilterType
	if isDebugEnabled then dd("currentFilterType: %s", tos(currentFilterType)) end
	return currentFilterType
end


--Function to return the mapped LF_* constant of a crafting type, for a parameter number LF_* filterType constant.
--e.g. map LF_SMITHING_DECONSTRUCT to LF_JEWElRY_DECONSTRUCT if the current crafting type is CRAFT_TYPE_JEWELRY, else for
--other craftTypes it will stay at LF_SMITHING_DECONSTRUCT.
--OPTIONAL parameter number craftType can be passed in to overwrite the detected craftType (e.g. if you need the result
--filterType without being at a crafting table).
-- returns number LF*_filterType
function libFilters:GetFilterTypeRespectingCraftType(filterTypeSource, craftType)
	if filterTypeSource == nil then return nil end
	local filterTypeMappedByCraftingType, _ = getFilterTypeByFilterTypeRespectingCraftType(filterTypeSource, craftType)
	if libFilters.debug then dd("GetFilterTypeRespectingCraftType-source: %q, target: %q, craftType: %s", tos(filterTypeSource), tos(filterTypeMappedByCraftingType), tos(craftType)) end
	return filterTypeMappedByCraftingType
end


--**********************************************************************************************************************
-- Filter check and un/register
--**********************************************************************************************************************
--Check if a filterFunction at the String filterTag and OPTIONAL number filterType is already registered
--Returns boolean true if registered already, false if not
function libFilters:IsFilterRegistered(filterTag, filterType)
	if libFilters.debug then dd("IsFilterRegistered-%q,%s", tos(filterTag), tos(filterType)) end
	if not filterTag then
		dfe("Invalid arguments to IsFilterRegistered(%q, %s).\n>Needed format is: String uniqueFilterTag, OPTIONAL number LibFiltersLF_*FilterType",
			tos(filterTag), tos(filterType))
		return
	end
	if filterType == nil then
		--check whether there's any filter with this tag
		for _, callbacks in pairs(filters) do
			if callbacks[filterTag] ~= nil then
				return true
			end
		end
		return false
	else
		--check only the specified filter type
		local callbacks = filters[filterType]
		return callbacks[filterTag] ~= nil
	end
end
local libFilters_IsFilterRegistered = libFilters.IsFilterRegistered


--Check if the LF_FILTER_ALL filterFunction at the String filterTag is already registered
--Returns boolean true if registered already, false if not
function libFilters:IsAllFilterRegistered(filterTag)
	if libFilters.debug then dd("IsAllFilterRegistered-%q", tos(filterTag)) end
	if not filterTag then
		dfe("Invalid arguments to IsAllFilterRegistered(%q).\n>Needed format is: String uniqueFilterTag",
			tos(filterTag))
		return
	end
	local callbacks = filters[LF_FILTER_ALL]
	return callbacks[filterTag] ~= nil
end


local filterTagPatternErrorStr = "Invalid arguments to %s(%q, %s, %s).\n>Needed format is: String uniqueFilterTagLUAPattern, OPTIONAL number LibFiltersLF_*FilterType, OPTIONAL boolean compareToLowerCase"
--Check if a filter function at the String filterTagPattern (uses LUA regex pattern!) and number filterType is already registered.
--Can be used to detect if any addon's tags have registered filters.
--OPTIONAL parameter boolean compareToLowerCase: If true the string comparison will be done with a lowerCase filterTag. The pattern will not be changed! Default: false
--Returns boolean true if registered already, false if not
function libFilters:IsFilterTagPatternRegistered(filterTagPattern, filterType, compareToLowerCase)
	if libFilters.debug then dd("IsFilterTagPatternRegistered-%q,%s,%s", tos(filterTagPattern), tos(filterType), tos(compareToLowerCase)) end
	if not filterTagPattern then
		dfe(filterTagPatternErrorStr,
			"IsFilterTagPatternRegistered", tos(filterTagPattern), tos(filterType), tos(compareToLowerCase))
		return
	end
	compareToLowerCase = compareToLowerCase or false
	if filterType == nil then
		--check whether there's any filter with this tag's pattern
		for _, callbacks in pairs(filters) do
			for filterTag, _ in pairs(callbacks) do
				local filterTagToCompare = (compareToLowerCase ~= nil and compareToLowerCase == true and filterTag:lower()) or filterTag
				if strmat(filterTagToCompare, filterTagPattern) ~= nil then
					return true
				end
			end
		end
	else
	--check only the specified filter type
		local callbacks = filters[filterType]
		for filterTag, _ in pairs(callbacks) do
			local filterTagToCompare = (compareToLowerCase ~= nil and compareToLowerCase == true and filterTag:lower()) or filterTag
			if strmat(filterTagToCompare, filterTagPattern) ~= nil then
				return true
			end
		end
	end
	return false
end


local registerFilteParametersErrorStr = "Invalid arguments to %s(%q, %q, %q, %s).\n>Needed format is: String uniqueFilterTag, number LibFiltersLF_*FilterType, function filterCallbackFunction(inventorySlot_Or_BagIdAtCraftingTables, OPTIONAL slotIndexAtCraftingTables), OPTIONAL boolean noInUseError)"
--Register a filter function at the String filterTag and number filterType.
--If filterType LF_FILTER_ALL is used this filterFunction will be used for all available filterTypes of the filterTag, where no other filterFunction was explicitly registered
--(as a kind of "fallback filter function").
--Registering a filter function does NOT automatically call the refresh/update function at the panel!
--You manually need to handle the update via libFilters:RequestUpdate(filterType) where needed
--Parameter boolean noInUseError: if set to true there will be no error message if the filterTag+filterType was registered already -> Silent fail. Return value will be false then!
--Returns true if filter function was registered, else nil in case of parameter errors, or false if same tag+type was already registered
function libFilters:RegisterFilter(filterTag, filterType, filterCallback, noInUseError)
	if libFilters.debug then dd("RegisterFilter-%q,%q,%q,%s", tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError)) end
	local callbacks = filters[filterType]
	if not filterTag or not filterType or not callbacks or type(filterCallback) ~= "function" then
		dfe(registerFilteParametersErrorStr, "RegisterFilter", tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError))
		return
	end
	noInUseError = noInUseError or false
	if callbacks[filterTag] ~= nil then
		if not noInUseError then
			dfe("FilterTag \'%q\' filterType \'%q\' filterCallback function is already in use.\nPlease check via \'LibFilters:IsFilterRegistered(filterTag, filterType)\' before registering filters!", tos(filterTag), tos(filterType))
		end
		return false
	end
	callbacks[filterTag] = filterCallback
	return true
end
local libFilters_RegisterFilter = libFilters.RegisterFilter


--Check if a filter function at the String filterTag and number filterType is already registered, and if not: Register it. If it was already registered the return value will be false
--Registering a filter function does NOT automatically call the refresh/update function at the panel!
--You manually need to handle the update via libFilters:RequestUpdate(filterType) where needed
--Parameter boolean noInUseError: if set to true there will be no error message if the filterTag+filterType was registered already -> Silent fail. Return value will be false then!
--Returns true if filter function was registered, else nil in case of parameter errors, or false if same tag+type was already registered
function libFilters:RegisterFilterIfUnregistered(filterTag, filterType, filterCallback, noInUseError)
	if libFilters.debug then dd("RegisterFilterIfUnregistered-%q,%q,%q,%s", tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError)) end
	local callbacks = filters[filterType]
	if not filterTag or not filterType or not callbacks or type(filterCallback) ~= "function" then
		dfe(registerFilteParametersErrorStr, "RegisterFilterIfUnregistered", tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError))
		return
	end
	noInUseError = noInUseError or false
	if libFilters_IsFilterRegistered(libFilters, filterTag, filterType) then
		return false
	end
	return libFilters_RegisterFilter(libFilters, filterTag, filterType, filterCallback, noInUseError)
end


--Unregister a filter function at the String filterTag and OPTIONAL number filterType.
--If filterType is left empty you are able to unregister all filterTypes of the filterTag.
--LF_FILTER_ALL will be unregistered if filterType is left empty, or if explicitly specified!
--Unregistering a filter function does NOT automatically call the refresh/update function at the panel!
--You manually need to handle the update via libFilters:RequestUpdate(filterType) where needed
--Returns true if any filter function was unregistered
function libFilters:UnregisterFilter(filterTag, filterType)
	if libFilters.debug then dd("UnregisterFilter-%q,%s", tos(filterTag), tos(filterType)) end
	if not filterTag or filterTag == "" then
		dfe("Invalid arguments to UnregisterFilter(%q, %s).\n>Needed format is: String filterTag, OPTIONAL number LibFiltersLF_*FilterType",
			tos(filterTag), tos(filterType))
		return
	end
	if filterType == nil then
		--unregister all filters with this tag
		local unregisteredFilterFunctions = 0
		for _, callbacks in pairs(filters) do
			if callbacks[filterTag] ~= nil then
				callbacks[filterTag] = nil
				unregisteredFilterFunctions = unregisteredFilterFunctions + 1
			end
		end
		if unregisteredFilterFunctions > 0 then
			return true
		end
	else
		--unregister only the specified filter type
		local callbacks = filters[filterType]
		if callbacks[filterTag] ~= nil then
			callbacks[filterTag] = nil
			return true
		end
	end
	return false
end


--**********************************************************************************************************************
-- Filter callback functions
--**********************************************************************************************************************

--Get the callback function of the String filterTag and number filterType
--Returns function filterCallbackFunction(inventorySlot_Or_BagIdAtCraftingTables, OPTIONAL slotIndexAtCraftingTables)
function libFilters:GetFilterCallback(filterTag, filterType)
	if libFilters.debug then dd("GetFilterCallback-%q,%q", tos(filterTag), tos(filterType)) end
	if not filterTag or not filterType then
		dfe("Invalid arguments to GetFilterCallback(%q, %q).\n>Needed format is: String uniqueFilterTag, number LibFiltersLF_*FilterType",
			tos(filterTag), tos(filterType))
		return
	end
	if not libFilters_IsFilterRegistered(libFilters, filterTag, filterType) then return end
	return filters[filterType][filterTag]
end


--Get all callback function of the number filterType (of all addons which registered a filter)
--Returns nilable:table { 	[filterType_e.g._LF_INVENTORY] = { [filterTag1] = filterFunction1, [filterTag2] = filterFunction2, ... },
--				  			[filterType_e.g._LF_BANK_WITHDRAW] = { [filterTag3] = filterFunction3, [filterTag4] = filterFunction4, ... }, ... }
function libFilters:GetFilterTypeCallbacks(filterType)
	if libFilters.debug then dd("GetFilterTypeCallbacks-%q", tos(filterType)) end
	if not filterType then
		dfe("Invalid arguments to GetFilterTypeCallbacks(%q).\n>Needed format is: number LibFiltersLF_*FilterType",
			tos(filterType))
		return
	end
	return filters[filterType]
end


--Get all callback functions of the String filterTag (e.g. all registered functions of one special addon) and OPTIONAL number filterType
--OPTIONAL parameter boolean compareToLowerCase: If true the string comparison will be done with a lowerCase filterTag. Default: false
--Returns nilable:table { 	[filterType_e.g._LF_INVENTORY] = { [filterTag1] = filterFunction1, [filterTag2] = filterFunction2, ... },
--				  			[filterType_e.g._LF_BANK_WITHDRAW] = { [filterTag3] = filterFunction3, [filterTag4] = filterFunction4, ... }, ... }
function libFilters:GetFilterTagCallbacks(filterTag, filterType, compareToLowerCase)
	if libFilters.debug then dd("GetFilterTagCallbacks-%q,%s,%s", tos(filterTag), tos(filterType), tos(compareToLowerCase)) end
	if not filterTag then
		dfe("Invalid arguments to GetFilterTagCallbacks(%q, %s, %s).\n>Needed format is: String uniqueFilterTag, OPTIONAL number LibFiltersLF_*FilterType, OPTIONAL boolean compareToLowerCase",
			tos(filterTag), tos(filterType), tos(compareToLowerCase))
		return
	end
	compareToLowerCase = compareToLowerCase or false
	local retTab
	local filterTagToCompare = (compareToLowerCase == true and filterTag:lower()) or filterTag
	if filterType == nil then
		--check whether there's any filter with this tag's pattern
		for lFilterType, callbacks in pairs(filters) do
			for lFilterTag, filterFunction in pairs(callbacks) do
				local lFilterTagToCompare = (compareToLowerCase == true and lFilterTag:lower()) or lFilterTag
				if strmat(lFilterTagToCompare, filterTagToCompare) ~= nil then
					retTab = retTab or {}
					retTab[lFilterType] = retTab[lFilterType] or {}
					retTab[lFilterType][lFilterTag] = filterFunction
				end
			end
		end
	else
	--check only the specified filter type
		local callbacks = filters[filterType]
		for lFilterTag, filterFunction in pairs(callbacks) do
			local lFilterTagToCompare = (compareToLowerCase == true and lFilterTag:lower()) or lFilterTag
			if strmat(lFilterTagToCompare, filterTagToCompare) ~= nil then
				retTab = retTab or {}
				retTab[filterType] = retTab[filterType] or {}
				retTab[filterType][lFilterTag] = filterFunction
			end
		end
	end
	return retTab
end


--Get the callback functions matching to the String filterTagPattern (uses LUA regex pattern!) and OPTIONAL number filterType
--OPTIONAL parameter boolean compareToLowerCase: If true the string comparison will be done with a lowerCase filterTag. The pattern will not be changed! Default: false
--Returns nilable:table { 	[filterType_e.g._LF_INVENTORY] = { [filterTag1] = filterFunction1, [filterTag2] = filterFunction2, ... },
--				  			[filterType_e.g._LF_BANK_WITHDRAW] = { [filterTag3] = filterFunction3, [filterTag4] = filterFunction4, ... }, ... }
function libFilters:GetFilterTagPatternCallbacks(filterTagPattern, filterType, compareToLowerCase)
	if libFilters.debug then dd("GetFilterTagPatternCallbacks-%q,%s,%s", tos(filterTagPattern), tos(filterType), tos(compareToLowerCase)) end
	if not filterTagPattern then
		dfe(filterTagPatternErrorStr,
			"GetFilterTagPatternCallbacks", tos(filterTagPattern), tos(filterType), tos(compareToLowerCase))
		return
	end
	compareToLowerCase = compareToLowerCase or false
	local retTab
	if filterType == nil then
		--check whether there's any filter with this tag's pattern
		for lFilterType, callbacks in pairs(filters) do
			for filterTag, filterFunction in pairs(callbacks) do
				local filterTagToCompare = (compareToLowerCase ~= nil and compareToLowerCase == true and filterTag:lower()) or filterTag
				if strmat(filterTagToCompare, filterTagPattern) ~= nil then
					retTab = retTab or {}
					retTab[lFilterType] = retTab[lFilterType] or {}
					retTab[lFilterType][filterTag] = filterFunction
				end
			end
		end
	else
	--check only the specified filter type
		local callbacks = filters[filterType]
		for filterTag, filterFunction in pairs(callbacks) do
			local filterTagToCompare = (compareToLowerCase ~= nil and compareToLowerCase == true and filterTag:lower()) or filterTag
			if strmat(filterTagToCompare, filterTagPattern) ~= nil then
				retTab = retTab or {}
				retTab[filterType] = retTab[filterType] or {}
				retTab[filterType][filterTag] = filterFunction
			end
		end
	end
	return retTab
end


--**********************************************************************************************************************
-- Filter update / refresh of (inventory/crafting/...) list
--**********************************************************************************************************************
--Will call the updater function of number filterType, read from table "libFilters.mapping.inventoryUpdaters", depending
--on keyboard/gamepad mode.
--It will overwrite updaters of the same filterType which have been called within 10 milliseconds, so that they are not
--called multiple times shortly after another
--OPTIONAL parameter number delay will add a delay to the call of the updater function
--OPTIONAL parameter number filterType maybe needed for the updater function call. If it's missing it's tried to be determined
function libFilters:RequestUpdateByName(updaterName, delay, filterType)
	if libFilters.debug then dd("RequestUpdateByName-%q,%s,%s", tos(updaterName), tos(delay), tos(filterType)) end
	if not updaterName or updaterName == "" then
		dfe("Invalid arguments to RequestUpdateByName(%q).\n>Needed format is: String updaterName",
			tos(updaterName))
		return
	end

	--Try to get the filterType, if not provided yet
	if filterType == nil then
		local filterTypesTable = updaterNameToFilterType[updaterName]
		local countFilterTypesWithUpdaterName = (filterTypesTable and #filterTypesTable) or 0
		if countFilterTypesWithUpdaterName > 1 then
			--Which filterType is the correct one for the updater name?
			--One cannot know! use the first one?
			--TODO:
			filterType = filterTypesTable[1]
		elseif countFilterTypesWithUpdaterName == 1 then
			filterType = filterTypesTable[1]
		end
	end

	local callbackName = updaterNamePrefix .. updaterName
	--Should the call be delayed?
	if delay ~= nil then
		if type(delay) ~= "number" then
			dfe("Invalid OPTIONAL 2nd argument \'delay\' to RequestUpdateByName(%s).\n>Needed format is: number milliSecondsToDelay",
					tos(delay))
			return
		else
			if delay < 0 then delay = 1 end
		end
	else
		delay = 10 --default value: 10ms
	end
	if libFilters.debug then dd(">callbackName: %s, delay: %s", tos(callbackName), tos(delay)) end

	local function updateFiltersNow()
		EM:UnregisterForUpdate(callbackName)
		if libFilters.debug then dd("RequestUpdateByName->Filter update called, updaterName: %s, filterType: %s, delay: %s", tos(updaterName), tos(filterType), tos(delay)) end

		--Update the cashed filterType and it's references
		libFilters._currentFilterTypeReferences = libFilters_GetFilterTypeReferences(libFilters, filterType, nil)
		libFilters._currentFilterType = filterType

		inventoryUpdaters[updaterName](filterType)
	end

	--Cancel previously scheduled update if any given
	EM:UnregisterForUpdate(callbackName)
	--Register a new updater
	EM:RegisterForUpdate(callbackName, delay, updateFiltersNow)
end
local libFilters_RequestUpdateByName = libFilters.RequestUpdateByName


--Will call the updater function of number filterType, read from table "libFilters.mapping.inventoryUpdaters", depending
--on keyboard/gamepad mode.
--It will overwrite updaters of the same filterType which have been called within 10 milliseconds, so that they are not
--called multiple times shortly after another
--OPTIONAL parameter number delay will add a delay to the call of the updater function
function libFilters:RequestUpdate(filterType, delay)
	local updaterName = filterTypeToUpdaterName[filterType]
	if libFilters.debug then dd("RequestUpdate filterType: %q, updaterName: %s, delay: %s", tos(filterType), tos(updaterName), tos(delay)) end
	if not filterType or not updaterName or updaterName == "" then
		dfe("Invalid arguments to RequestUpdate(%q).\n>Needed format is: number LibFiltersLF_*FilterType",
			tos(filterType))
		return
	end
	libFilters_RequestUpdateByName(libFilters, updaterName, delay, filterType)
end


-- Get the updater name of a number filterType
-- returns String updateName
function libFilters:GetFilterTypeUpdaterName(filterType)
	if libFilters.debug then dd("GetFilterTypeUpdaterName filterType: %q", tos(filterType)) end
	if not filterType then
		dfe("Invalid arguments to GetFilterTypeUpdaterName(%q).\n>Needed format is: number LibFiltersLF_*FilterType",
			tos(filterType))
		return
	end
	return filterTypeToUpdaterName[filterType] or ""
end


-- Get the updater filterTypes of a String updaterName
-- returns nilable:table filterTypesOfUpdaterName { [1] = LF_INVENTORY, [2] = LF_..., [3] = ... }
function libFilters:GetUpdaterNameFilterType(updaterName)
	if libFilters.debug then dd("GetUpdaterNameFilterType updaterName: %q", tos(updaterName)) end
	if updaterName == nil or updaterName == "" then
		dfe("Invalid call to GetUpdaterNameFilterType(%q).\n>Needed format is: String updaterName",
			tos(updaterName))
		return
	end
	return updaterNameToFilterType[updaterName]
end


-- Get the updater keys and their functions used for updating/refresh of the inventories etc.
-- returns table { ["updater_name"] = function updaterFunction(OPTIONAL filterType), ... }
function libFilters:GetUpdaterCallbacks()
	return inventoryUpdaters
end


-- Get the updater function used for updating/refresh of the inventories etc., by help of a String updaterName
-- returns nilable:function updaterFunction(OPTIONAL filterType)
function libFilters:GetUpdaterCallback(updaterName)
	if libFilters.debug then dd("GetUpdaterCallback updaterName: %q", tos(updaterName)) end
	if updaterName == nil or updaterName == "" then
		dfe("Invalid call to GetUpdaterCallback(%q).\n>Needed format is: String updaterName",
			tos(updaterName))
		return
	end
	return inventoryUpdaters[updaterName]
end


-- Get the updater function used for updating/refresh of the inventories etc., by help of a number filterType
-- returns nilable:function updaterFunction(OPTIONAL filterType)
function libFilters:GetFilterTypeUpdaterCallback(filterType)
	if libFilters.debug then dd("GetFilterTypeUpdaterCallback filterType: %q", tos(filterType)) end
	if filterType == nil then
		dfe("Invalid call to GetFilterTypeUpdaterCallback(%q).\n>Needed format is: number LibFiltersLF_*FilterType",
				tos(filterType))
		return
	end
	local updaterName = filterTypeToUpdaterName[filterType]
	if not updaterName then return end
	return inventoryUpdaters[updaterName]
end


--**********************************************************************************************************************
-- API to get tables, variables and other constants
--**********************************************************************************************************************

-- Get constants used within keyboard filter hooks etc.
-- returns table keyboardConstants
function libFilters:GetKeyboardConstants()
	return kbc
end


-- Get constants used within gamepad filter hooks etc.
-- returns table gamepadConstants
function libFilters:GetGamepadConstants()
	return gpc
end


--**********************************************************************************************************************
-- API to get controls/scenes/fragments/userdata/inventories which contain the libFilters filterType
--**********************************************************************************************************************

-- Get reference (inventory, layoutData, scene, fragment, control, etc.) where the number filterType was assigned to, and
--it's filterFunction was added to the constant "defaultOriginalFilterAttributeAtLayoutData" (.additionalFilter)
-- returns table referenceVariablesOfLF_*filterType { [NumericalNonGapIndex e.g.1] = inventory/layoutData/scene/control/userdata/etc., [2] = inventory/layoutData/scene/control/userdata/etc., ... }
function libFilters:GetFilterTypeReferences(filterType, isInGamepadMode)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	if libFilters.debug then dd("GetFilterBase filterType: %q, %s", tos(filterType), tos(isInGamepadMode)) end
	if not filterType or filterType == "" then
		dfe("Invalid arguments to GetFilterTypeReferences(%q, %s).\n>Needed format is: number LibFiltersLF_*FilterType, OPTIONAL boolean isInGamepadMode",
				tos(filterType), tos(isInGamepadMode))
		return
	end
	local filterReferences = LF_FilterTypeToReference[isInGamepadMode][filterType]
	return filterReferences
end
libFilters_GetFilterTypeReferences = libFilters.GetFilterTypeReferences


-- Get the actually shown reference control/scene/userdata/inventory number e.g. INVENTORY_BACKPACK information which is relevant for a libFilters LF_* filterType.
-- OPTIONAL parameter number filterType: If provided it will be used to determine the reference control/etc. directly via table LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[isInGamepadMode]
-- OPTIONAL parameter boolean isInGamepadMode: Check with gamepad mode or keyboard. Leave empty to let it be determined automatically
-- returns table currentlyShownReferenceVariablesOfLF_*filterType { [1] = control/scene/userdata/inventory number, [2] = control/scene/userdata/inventory number, ... },
--		   number filterType
function libFilters:GetCurrentFilterTypeReference(filterType, isInGamepadMode)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end

	--Check if the cached filterType is given and still shown -> Only if no filterType was explicitly passed in
	local filterTypeReference, filterTypeShown = checkIfCachedFilterTypeIsStillShown(filterType, isInGamepadMode)
	if filterTypeReference ~= nil and filterTypeShown ~= nil then
		return filterTypeReference, filterTypeShown
	end

	--Reset cached variables
	libFilters._currentFilterTypeReferences = 	nil
	libFilters._currentFilterType = 			nil
	------------------------------------------------------------------------------------------------------------------------

	--CraftBagExtended addon is active? We got a currently shown fragment of CBE then e.g. but the "parent" filterType will be something like
	--LF_MAIL_SEND, LF_TRADE, LF_GUILDSTORE_SELL etc., and needs to be used for the reference then
	--[[
	if CraftBagExtended ~= nil then
		--TODO really needed to check here? Or just loop over the LF_FilterTypeToReference[isInGamepadMode] and check if they are shown
	end
	]]
	return detectShownReferenceNow(filterType, isInGamepadMode, nil)
end
libFilters_GetCurrentFilterTypeReference = libFilters.GetCurrentFilterTypeReference



--**********************************************************************************************************************
-- API to check if controls/scenes/fragments/userdata/inventories are shown
--**********************************************************************************************************************

local function isGPInventoryBaseShown()
	return isSceneFragmentShown(LF_INVENTORY, true, nil, true) and isSceneFragmentShown(LF_INVENTORY, true, nil, false)
			and not ZO_GamepadInventoryTopLevel:IsHidden()
end

--Is the inventory control shown
--returns boolean isShown
--		  NILABLE control gamepadList (category or item list of the gamepad inventory, which is currently shown)
function libFilters:IsInventoryShown()
	local isInvShown = false
	local listShownGP
	local isCategoryListShown = false
	local isItemListShown = false
	if IsGamepad() then
		if isGPInventoryBaseShown() == true then
			--Check if the item list is shown and active, and not the category list (containing the main filter buttons)
			local categoryList = invBackpack_GP.categoryList
			local itemList = invBackpack_GP.itemList
			if categoryList:IsActive() then
				isCategoryListShown = true
				listShownGP = categoryList
			elseif itemList:IsActive() then
				isItemListShown = true
				listShownGP = itemList
			end
			--Check selected vanilla "Inventory" filters for non-supported ones (character, currencies, quests, quickslots)
			local gamepadInventoryNonSupportedFilters = {
				[ITEMFILTERTYPE_QUEST] 				= true,
				[ITEMFILTERTYPE_QUEST_QUICKSLOT] 	= true,
			}
			local selectedGPInvFilter = invBackpack_GP.selectedItemFilterType
			--local selectedGPInvEquipmentSlot = invBackpack_GP.selectedEquipSlot -- equipped items = character
			local selectedItemUniqueId = invBackpack_GP.selectedItemUniqueId
			local categoryListSelectedIndex = categoryList.selectedIndex --categoryListIndex 2 is 'Vorräte" which got no selectedItemFilterType and no selectedItemUniqueId -> Thus it would return false

			--Categories list is shown (1st level, e.g. material, weapons, armor, consumables, ...)
			if isCategoryListShown then
				if  (selectedGPInvFilter ~= nil and gamepadInventoryNonSupportedFilters[selectedGPInvFilter])
					or (selectedGPInvFilter == nil and categoryListSelectedIndex ~= 2) then --or selectedGPInvEquipmentSlot ~= nil
					return false, listShownGP
				end

			--Items list is shown (2nd level with single items, e.g. 2hd weapons, light armor, ...)
			elseif isItemListShown then
				if (selectedGPInvFilter ~= nil and gamepadInventoryNonSupportedFilters[selectedGPInvFilter])
					or (selectedGPInvFilter == nil and selectedItemUniqueId == nil) then --or selectedGPInvEquipmentSlot ~= nil
					return false, listShownGP
				end

			end
			isInvShown = true
		end
	else
		isInvShown = not playerInvCtrl:IsHidden()
	end
	return isInvShown, listShownGP
end
local libFilters_IsInventoryShown = libFilters.IsInventoryShown

--Is the companion inventory control shown
--returns boolean isShown
function libFilters:IsCompanionInventoryShown()
    return (IsGamepad() and not companionEquipmentCtrl_GP:IsHidden()) or not companionEquipmentCtrl:IsHidden()
end

--Is the character control shown
--returns boolean isShown
function libFilters:IsCharacterShown()
	local isCharShown = false
	if IsGamepad() then
		if isGPInventoryBaseShown() == true then
			local selectedGPInvEquipmentSlot = invBackpack_GP.selectedEquipSlot
			return (selectedGPInvEquipmentSlot ~= nil and selectedGPInvEquipmentSlot >= 0 and true) or false
		end
	else
		isCharShown = not characterCtrl:IsHidden()
	end
	return isCharShown
end

--Is the companion character control shown
--returns boolean isShown
function libFilters:IsCompanionCharacterShown()
    return (IsGamepad() and not companionCharacterCtrl_GP:IsHidden()) or not companionCharacterCtrl:IsHidden()
end


--Is the bank shown
--returns boolean isShown
function libFilters:IsBankShown()
	local isBankShown = false
	if IsGamepad() then
		isBankShown = gpc.invBankScene_GP:IsShowing()
	else
		isBankShown = kbc.invBankScene:IsShowing()
	end
	return isBankShown
end


--Is the guild bank shown
--returns boolean isShown
function libFilters:IsGuildBankShown()
	local isGuildBankShown = false
	if IsGamepad() then
		isGuildBankShown = gpc.invGuildBankScene_GP:IsShowing()
	else
		isGuildBankShown = kbc.invGuildBankScene:IsShowing()
	end
	return isGuildBankShown
end


--Is the house bank shown
--returns boolean isShown
function libFilters:IsHouseBankShown()
	local isHouseBankShown = IsHouseBankBag(GetBankingBag())
	if not isHouseBankShown then return false end
	if IsGamepad() then
		isHouseBankShown = gpc.invBankScene_GP:IsShowing()
	else
		isHouseBankShown = kbc.invHouseBankScene:IsShowing()
	end
	return isHouseBankShown
end



--Check if the store (vendor) panel is shown
--If OPTIONAL parameter number storeMode (either ZO_MODE_STORE_BUY, ZO_MODE_STORE_BUY_BACK, ZO_MODE_STORE_SELL,
--ZO_MODE_STORE_REPAIR, ZO_MODE_STORE_SELL_STOLEN, ZO_MODE_STORE_LAUNDER, ZO_MODE_STORE_STABLE) is provided the store
--mode mode must be set at the store panel, if it is shown, to return true
--return boolean isShown, number storeMode, userdata/control/scene/fragment whatHasBeenDetectedToBeShown
function libFilters:IsStoreShown(storeMode)
	if not ZO_Store_IsShopping() or (storeMode and storeMode == 0) then return false, storeMode, nil end
	if IsGamepad() then
		local currentStoreMode = (store_GP.GetCurrentMode ~= nil and store_GP:GetCurrentMode()) or 0
		if currentStoreMode == 0 then
			for lStoreMode, storeComponentCtrl in pairs(store_componentsGP) do
				if checkIfStoreCtrlOrFragmentShown(storeComponentCtrl, lStoreMode) == true then
					return true, lStoreMode, storeComponentCtrl
				end
			end
		else
			if storeMode ~= nil then
				if not currentStoreMode == storeMode then
					return false, currentStoreMode, nil
				end
			end
			local isStoreCtrlShown, storeCtrl = checkIfStoreCtrlOrFragmentShown(nil, currentStoreMode)
			return isStoreCtrlShown, currentStoreMode, storeCtrl
		end
	else
		--local storeWindowMode = store:GetWindowMode() --returns if in stable mode -> ZO_STORE_WINDOW_MODE_STABLE
		for lStoreMode, storeControlOrFragment in pairs(storeWindows) do
			if checkIfStoreCtrlOrFragmentShown(storeControlOrFragment, lStoreMode) == true then
				if storeMode ~= nil then
					if storeMode == lStoreMode then
						return true, storeMode, storeControlOrFragment
					end
				else
					return true, lStoreMode, storeControlOrFragment
				end
			end
		end
	end
	return false, storeMode, nil
end


--Is a list dialog currently shown?
--OPTIONAL parameter number filterType to detect the owner control which's hidden state will be checked
--OPTIONAL parameter userdata/control dialogOwnerControlToCheck which's hidden state will be checked
--Any of the 2 parameters needs to be passed in
--returns boolean isListDialogShown
function libFilters:IsListDialogShown(filterType, dialogOwnerControlToCheck)
	if filterType == nil and dialogOwnerControlToCheck == nil then return false end
	--[[
	--Does the filterType passed in needs to be mapped to another one, depending on the craftType?
	local filterTypeMappedByCraftingType, craftType
	if filterType ~= nil then
		filterTypeMappedByCraftingType, craftType = getFilterTypeByFilterTypeRespectingCraftType(filterType, nil)
	end
	if dialogOwnerControlToCheck == nil and filterTypeMappedByCraftingType ~= nil then
		dialogOwnerControlToCheck = getDialogOwner(filterTypeMappedByCraftingType, craftType)
	end]]
	local craftType = gcit()
	if dialogOwnerControlToCheck == nil then
		dialogOwnerControlToCheck = getDialogOwner(filterType, craftType)
	end
	if libFilters.debug then
		dd("IsListDialogShown-filterType: %q, craftType: %s, dialogOwnerControl: %s", --filterTypeMapped: %q
				tos(filterType), tos(craftType), tos(dialogOwnerControlToCheck)) --tos(filterTypeMappedByCraftingType)
	end
	if dialogOwnerControlToCheck == nil then return false end
	return isListDialogShown(dialogOwnerControlToCheck)
end


--Is the retrait station curently shown
--returns boolean isRetraitStation
function libFilters:IsRetraitStationShown()
	return ZO_RETRAIT_STATION_MANAGER:IsRetraitSceneShowing()
end


--Is any crafting  station curently shown
--OPTIONAL parameter number craftType: If provided the shown state of the crafting table connected to the craftType will
--be checked and returned
--returns boolean isCraftingStationShown
function libFilters:IsCraftingStationShown(craftType)
	local retVar = ZO_CraftingUtils_IsCraftingWindowOpen()
	if craftType ~= nil then
		if retVar == false then return false end
		--TODO Connect craftType to the craftingTable controls and check if controlis shown
	end
	return retVar
end


--Is the currnt crafting type jewelry?
--return boolean isJewerlyCrafting
function libFilters:IsJewelryCrafting()
	return (gcit() == CRAFTING_TYPE_JEWELRYCRAFTING) or false
end


--Check if the Enchanting panel is shown.
--If OPTIONAL parameter number enchantingMode (either ENCHANTING_MODE_CREATION, ENCHANTING_MODE_EXTRACTION or
-- ENCHANTING_MODE_RECIPES) is provided this enchanting mode must be set at the enchanting panel, if it is shown, to return
-- true
--return boolean isShown, number enchantingMode, userdata/control/scene/fragment whatHasBeenDetectedToBeShown
function libFilters:IsEnchantingShown(enchantingMode)
    if enchantingMode and enchantingMode == ENCHANTING_MODE_NONE then return false, 0, nil	end
	if IsGamepad() then
		if enchantingMode ~= nil then
			if enchantingInvCtrls_GP[enchantingMode] then
				local enchantingControl = enchantingInvCtrls_GP[enchantingMode].control
				return not enchantingControl:IsHidden(), enchantingMode, enchantingControl
			end
		else
			for lEnchantMode, enchantScene in pairs(enchantingInvCtrls_GP) do
				if enchantScene then
					local enchantingControl = enchantScene.control
					local isEnchantingControlShown = not enchantScene.control:IsHidden()
					if isEnchantingControlShown == true then
						return true, lEnchantMode, enchantingControl
					end
				end
			end
		end
	else
		if enchantingInvCtrl ~= nil and not enchantingInvCtrl:IsHidden() then
			local lEnchantingMode = enchanting.GetEnchantingMode and enchanting:GetEnchantingMode()
			if enchantingMode ~= nil then
				if lEnchantingMode and lEnchantingMode == enchantingMode then
					return true, enchantingMode, enchantingInvCtrl
				end
			else
				return true, lEnchantingMode, enchantingInvCtrl
			end
		end
	end
	return false, enchantingMode, nil
end

--Check if the Alchemy panel is shown
--If OPTIONAL parameter number alchemyMode (either ZO_ALCHEMY_MODE_CREATION, ZO_ALCHEMY_MODE_RECIPES is provided this
-- alchemy mode must be set at the alchemy panel, if it is shown, to return true
--return boolean isShown, number alchemyMode, userdata/control/scene/fragment whatHasBeenDetectedToBeShown
function libFilters:IsAlchemyShown(alchemyMode)
	if alchemyMode and alchemyMode == ZO_ALCHEMY_MODE_NONE then return false, alchemyMode, nil end
	if IsGamepad() then
		if alchemyCtrl_GP ~= nil and not alchemyCtrl_GP:IsHidden() then
			local lAlchemyMode = alchemy_GP.mode
			if alchemyMode ~= nil then
				if lAlchemyMode and lAlchemyMode == alchemyMode then
					return true, alchemyMode, alchemyCtrl_GP
				end
			else
				return true, lAlchemyMode, alchemyCtrl_GP
			end
		end
	else
		if alchemyCtrl ~= nil and not alchemyCtrl:IsHidden() then
			local lAlchemyMode = alchemy.mode
			if alchemyMode ~= nil then
				if lAlchemyMode and lAlchemyMode == alchemyMode then
					return true, alchemyMode, alchemyCtrl
				end
			else
				return true, lAlchemyMode, alchemyCtrl
			end
		end
	end
	return false, alchemyMode, nil
end

--**********************************************************************************************************************
-- HOOKS
--**********************************************************************************************************************
--Hook the inventory layout or inventory control, a fragment, scene or userdata to apply the .additionalFilter entry for
--the filter functions registered via LibFilters:RegisterFilter("uniqueName," filterType, callbackFilterFunction)
--Using only 1 parameter number filterType now, to determine the correct control/inventory/scene/fragment/userdata to
--apply the entry .additionalFilter to from the constants table --> See file costants.lua, table
--LF_FilterTypeToReference
--As the table could contain multiple variables to hook into per LF_* constant there needs to be a loop over the entries
function libFilters:HookAdditionalFilter(filterType, hookKeyboardAndGamepadMode)
	if libFilters.debug then dd("HookAdditionalFilter-%q,%s", tos(filterType), tos(hookKeyboardAndGamepadMode)) end
	local filterTypeName
	local filterTypeNameAndTypeText
	local function hookNowSpecial(inventoriesToHookForLFConstant_Table, isInGamepadMode)
		if not inventoriesToHookForLFConstant_Table then
			filterTypeName = filterTypeName or libFilters_GetFilterTypeName(libFilters, filterType)
			filterTypeNameAndTypeText = filterTypeNameAndTypeText or (tos(filterTypeName) .. " [" .. tos(filterType) .. "]")
			dfe("HookAdditionalFilter SPECIAL-table of hooks is empty for constant %s, isInGamepadMode: %s, keyboardAndGamepadMode: %s",
					filterTypeNameAndTypeText, tos(isInGamepadMode), tos(hookKeyboardAndGamepadMode))
			return
		end
		local funcName = inventoriesToHookForLFConstant_Table.funcName
		if funcName ~= nil and funcName ~= "" and libFilters[funcName] ~= nil then
			local params = inventoriesToHookForLFConstant_Table.params
			if libFilters.debug then dd("HookAdditionalFilter > hookNowSpecial-%q,%s;%s", tos(filterType), tos(funcName), tos(params)) end
			libFilters[funcName](libFilters, unpack(params)) --pass LibFilters as 1st param "self" TODO: needed?
		end
	end

	local function hookNow(inventoriesToHookForLFConstant_Table, isInGamepadMode)
		filterTypeName = filterTypeName or libFilters_GetFilterTypeName(libFilters, filterType)
		filterTypeNameAndTypeText = filterTypeNameAndTypeText or (tos(filterTypeName) .. " [" .. tos(filterType) .. "]")
		if not inventoriesToHookForLFConstant_Table then
			dfe("HookAdditionalFilter-table of hooks is empty for constant %s, isInGamepadMode: %s, keyboardAndGamepadMode: %s",
					filterTypeNameAndTypeText, tos(isInGamepadMode), tos(hookKeyboardAndGamepadMode))
			return
		end
		if libFilters.debug then dd("HookAdditionalFilter-HookNow filterType %q, isInGamepadMode: %s, keyboardAndGamepadMode: %s",
				filterTypeNameAndTypeText, tos(isInGamepadMode), tos(hookKeyboardAndGamepadMode)) end

		if #inventoriesToHookForLFConstant_Table == 0 then return end

		for _, inventory in ipairs(inventoriesToHookForLFConstant_Table) do
			if inventory ~= nil then
				local layoutData = inventory.layoutData or inventory
				--Get the default attribute .additionalFilter of the inventory/layoutData to determine original filter value/filterFunction
				local originalFilter = layoutData[defaultOriginalFilterAttributeAtLayoutData] --.additionalFilter

				--Store the filterType at the layoutData (which could be a fragment.layoutData table or a variable like
				--PLAYER_INVENTORY.inventories[INVENTORY_*]) table to identify the panel -> will be used e.g. within
				--LibFilters:GetCurrentFilterTypeForInventory(inventoryType)
				layoutData[defaultLibFiltersAttributeToStoreTheFilterType] = filterType --.LibFilters3_filterType

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
					if libFilters.debug then dd(">filterType: %s, otherOriginalFilterAttributesAtLayoutData: %s", filterTypeNameAndTypeText, tos(readFromAttribute)) end
					local readFromObject = otherOriginalFilterAttributesAtLayoutData.objectRead
					if readFromObject == nil then
						--Fallback: Read from the same layoutData
						readFromObject = layoutData
					end
					if readFromObject == nil then
						--This will happen once for LF_CraftBag as PLAYER_INVENTORY.inventories[INVENTORY_CRAFT_BAG] does not seem to exist yet
						--as we try to add the .additionalCraftBagFilter to it
						dfe("HookAdditionalFilter-HookNow found a \"fix\" for filterType %s. But the readFrom data (%q/%q) is invalid/missing!, isInGamepadMode: %s, keyboardAndGamepadMode: %s",
								filterTypeNameAndTypeText,
								tos((readFromObject ~= nil and "readFromObject=" .. tos(readFromObject)) or "readFromObject is missing"),
								tos((readFromAttribute ~= nil and "readFromAttribute=" .. readFromAttribute) or "readFromAttribute is missing"),
								tos(isInGamepadMode), tos(hookKeyboardAndGamepadMode))
						return
					end
					otherOriginalFilter = readFromObject[readFromAttribute]
					local createFilterFunctionForLibFilters = false
					if otherOriginalFilter ~= nil then
						local originalFilterType = type(otherOriginalFilter)
						if originalFilterType == "function" then
							createFilterFunctionForLibFilters = false
							if libFilters.debug then dd(">>Updated existing filter function %q", tos(readFromAttribute)) end
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
						if libFilters.debug then dd(">>Created new filter function %q", tos(readFromAttribute)) end
						readFromObject[readFromAttribute] = function(...) --e.g. update BACKPACK_MENU_BAR_LAYOUT_FRAGMENT.additionalCraftBagFilter so it will be copied to PLAYER_INVENTORY.inventories[INVENTORY_CRAFT_BAG] at PLAYER_INVENTORY:ApplyBackpackLayout()
							return runFilters(filterType, ...)
						end
					end
				else
					if libFilters.debug then dd(">filterType: %s, normal hook: %s", filterTypeNameAndTypeText, tos(defaultOriginalFilterAttributeAtLayoutData)) end
					local originalFilterType = type(originalFilter)
					if originalFilterType == "function" then
						if libFilters.debug then dd(">Updated existing filter function %q", tos(defaultOriginalFilterAttributeAtLayoutData)) end
						--Set the .additionalFilter again with the filter function of the original and LibFilters
						layoutData[defaultOriginalFilterAttributeAtLayoutData] = function(...) --.additionalFilter
							return originalFilter(...) and runFilters(filterType, ...)
						end
					else
						if libFilters.debug then dd(">Created new filter function %q", tos(defaultOriginalFilterAttributeAtLayoutData)) end
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
	--Should the LF constant be hooked by any special function of LibFilters?
	--e.g. run LibFilters:HookAdditionalFilterSpecial("enchanting")
	local inventoriesToHookForLFConstant
	local hookSpecialFunctionDataOfLFConstant = LF_ConstantToAdditionalFilterSpecialHook[filterType]
	if hookSpecialFunctionDataOfLFConstant ~= nil then
		if hookKeyboardAndGamepadMode == true then
			--Keyboard
			inventoriesToHookForLFConstant = hookSpecialFunctionDataOfLFConstant[false]
			if inventoriesToHookForLFConstant ~= nil then
				hookNowSpecial(inventoriesToHookForLFConstant, false)
			end
			--Gamepad
			inventoriesToHookForLFConstant = hookSpecialFunctionDataOfLFConstant[true]
			if inventoriesToHookForLFConstant ~= nil then
				hookNowSpecial(inventoriesToHookForLFConstant, true)
			end
		else
			--Only currently detected mode, gamepad or keyboard
			local gamepadMode = IsGamepad()
			inventoriesToHookForLFConstant = hookSpecialFunctionDataOfLFConstant[gamepadMode]
			hookNowSpecial(inventoriesToHookForLFConstant, gamepadMode)
		end
	end
	inventoriesToHookForLFConstant = nil

	--If the special hook was found it maybe that only one of the two, keyboard or gamepad was hooked special.
	--e.g. "enchanting" -> LF_ENCHANTING_CREATION only applies to keyboard mode. Gamepad needs to hook normally to add
	--the .additionalFilter to the correct gamepad enchanting inventory
	--So try to run the same LF_ constant as normal hook as well (if it exists)
	--Hook normal via the given control/scene/fragment etc. -> See table LF_FilterTypeToReference
	if hookKeyboardAndGamepadMode == true then
		--Keyboard
		if not hookSpecialFunctionDataOfLFConstant then
			inventoriesToHookForLFConstant = LF_FilterTypeToReference[false][filterType]
			hookNow(inventoriesToHookForLFConstant, false)
		end
		--Gamepad
		if not hookSpecialFunctionDataOfLFConstant then
			inventoriesToHookForLFConstant = LF_FilterTypeToReference[true][filterType]
			hookNow(inventoriesToHookForLFConstant, true)
		end
	else
		--Only currently detected mode, gamepad or keyboard
		if not hookSpecialFunctionDataOfLFConstant then
			local gamepadMode = IsGamepad()
			inventoriesToHookForLFConstant = LF_FilterTypeToReference[gamepadMode][filterType]
			hookNow(inventoriesToHookForLFConstant, gamepadMode)
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
				if additionalFilterType == "function" then
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
				if additionalFilterType == "function" then
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


--**********************************************************************************************************************
-- API of the logger
--**********************************************************************************************************************
-- Get the LibFilters logger reference
-- returns table logger
function libFilters:GetLogger()
	return logger
end


--**********************************************************************************************************************
-- API of the helpers
--**********************************************************************************************************************
-- Get the LibFilters helpers table
-- returns table helpers
function libFilters:GetHelpers()
	return libFilters.helpers
end



--**********************************************************************************************************************
-- Special API
--**********************************************************************************************************************
--Will set the keyboard research panel's indices "from" and "to" to filter the items which do not match to the selected
--indices
--Used in addon AdvancedFilters UPDATED e.g. to filter the research panel LF_SMITHING_RESEARCH/LF_JEWELRY_RESEARCH in
--keyboard mode
function libFilters:SetResearchLineLoopValues(fromResearchLineIndex, toResearchLineIndex, skipTable)
	 local craftingType = GetCraftingInteractionType()
	if libFilters.debug then dd("SetResearchLineLoopValues craftingType: %q, fromResearchLineIndex: %q, toResearchLineIndex: %q, skipTable: %s", tos(craftingType), tos(fromResearchLineIndex), tos(toResearchLineIndex), tos(skipTable)) end
	 if craftingType == CRAFTING_TYPE_INVALID then return false end
	 if not fromResearchLineIndex or fromResearchLineIndex <= 0 then fromResearchLineIndex = 1 end
	 local numSmithingResearchLines = GetNumSmithingResearchLines(craftingType)
	 if not toResearchLineIndex or toResearchLineIndex > numSmithingResearchLines then
		  toResearchLineIndex = numSmithingResearchLines
	 end
	 local helpers = libFilters.helpers
	 if not helpers then return end
	 local smithingResearchPanel = helpers["SMITHING/SMITHING_GAMEPAD.researchPanel:Refresh"].locations[1]
	 if smithingResearchPanel then
		  smithingResearchPanel.LibFilters_3ResearchLineLoopValues = {
				from		= fromResearchLineIndex,
				to			= toResearchLineIndex,
				skipTable	= skipTable,
		  }
	 end
end

--Check if the addon CraftBagExtended is enabled and if the craftbag is currently shown at a "non vanilla craftbag" filterType
--e.g. LF_MAIL_SEND, LF_TRADE, LF_GUILDSTORE_SELL, LF_GUILDBANK_DEPOSIT, LF_BANK_DEPOSIT, LF_HOUSE_BANK_DEPOSIT
--Will return boolean true if CBE is enabled and a supported parent filterType panelis shown. Else returns false
function libFilters:IsCraftBagExtendedParentFilterType(filterTypesToCheck)
	local referencesToFilterType, filterTypeParent
	if libFilters.debug then dd("GetCraftBagExtendedParentFilterType - numFilterTypesToCheck: %s",
			tos(#filterTypesToCheck)) end
	if filterTypesToCheck ~= nil and CraftBagExtended ~= nil then
		local cbeSpecialAddonChecks = "CraftBagExtended"
		local isInGamepadMode = IsGamepad()
		for _, filterTypeToCheck in ipairs(filterTypesToCheck) do
			referencesToFilterType, filterTypeParent = nil, nil
			referencesToFilterType, filterTypeParent = craftBagExtendedCheckForCurrentModule(filterTypeToCheck)
			if referencesToFilterType ~= nil and filterTypeParent ~= nil then
				if libFilters.debug then dd(">filterTypeChecked: %s, filterTypeParent: %q",
						tos(filterTypeToCheck), tos(filterTypeParent)) end
				return true
			elseif referencesToFilterType == true and filterTypeParent == LF_INVENTORY then
				--Normal craftbag at player inventory is shown
				return true
			end
		end
		return false
	end
	if libFilters.debug then dd("< CBE: %s, filterTypeParent: %q",
			tos(CraftBagExtended ~= nil), tos(filterTypeParent)) end
	return true
end

--**********************************************************************************************************************
-- END LibFilters API functions END
--**********************************************************************************************************************
--**********************************************************************************************************************
--**********************************************************************************************************************


--**********************************************************************************************************************
-- HELPERS
--**********************************************************************************************************************
--Register all the helper functions of LibFilters, for some special panels like the Research or ResearchDialog, or
--even deconstruction and improvement, etc.
--These helper functions overwrite original ESO functions in order to use their own "predicate" or
-- "filterFunction".
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- IMPORTANT: You need to check the funtion code and compare it to Zos vanilla code after updates as if ZOs code changes
-- the helpers may need to change as well!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--> See file helper.lua
libFilters.helpers = {}
local helpers      = libFilters.helpers

--Install the helpers from table helpers now -> See file helper.lua, table "helpers"
local function installHelpers()
	if libFilters.debug then dd("InstallHelpers") end
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
-- CALLBACKS
--**********************************************************************************************************************
--Create callbacks one can register to as the filterType panels show and hide
--e.g. for LF_SMITHING_REFINE as the panel opens or closes, the signature would be
--name: LibFilters3-<shown or hidden defined via SCENE_SHOWN and SCENE_HIDDEN constants>-<filterType>
--variables passed as parameters:
--filterType,
--fragment/scene/control that was used to raise the callback,
--referenceObjects (from table filterTypeToCheckIfReferenceIsHidden),
--isGamepadModeCallback,
--shownState,
--additionalParameters ...
--e.g. showing LF_SMITHING_REFINE
--[[
	CM:FireCallbacks(GlobalLibName .. "-shown-" .. tos(LF_SMITHING_REFINE),
		LF_SMITHING_REFINE,
		filterTypeToCheckIfReferenceIsHidden[false][LF_SMITHING_REFINE],
		false,
		... ---could be SMITHING.mode in keyboard mode e.g. or other vaiable
	)
]]
--Check wich fragment is shown and rais a callback, if needed
local function callbackRaiseCheckViaFragment(filterType, fragment, stateStr, isInGamepadMode)
	if isInGamepadMode == ni then isInGamepadMode = IsGamepad() end
	--Detect the filterType if not given
	local lReferencesToFilterType
	--Call the code 1 frame later so the fragment's (and others used within detectShownReferenceNow()) state will be updated properly
	zo_callLater(function()
		lReferencesToFilterType, filterType = detectShownReferenceNow(filterType, isInGamepadMode)
		if filterType == nil then return end

		local callbackName = GlobalLibName .. "-" .. stateStr .. "-" .. tos(filterType)

		if libFilters.debug then
			dd("Fragment callback %q - state: %s, filterType: %s, gamePadMode: %s",
					callbackName, tos(stateStr), tos(filterType), tos(isInGamepadMode))
		end
		CM:FireCallbacks(callbackName,
				filterType,
				fragment,
				lReferencesToFilterType,
				isInGamepadMode,
				stateStr
		)
	end, 0)
end


local function onFragmentStateChange(oldState, newState, filterType, fragment, inputType)
	if libFilters.debug then
		dd("onFragmentStateChange oldState: %s > newState: %q - filterType: %s, isGamePad: %s", tos(oldState), tos(newState), tos(filterType), tos(inputType))
	end
	if newState == SCENE_FRAGMENT_SHOWN then
		callbackRaiseCheckViaFragment(filterType, fragment, SCENE_SHOWN, inputType)
	elseif newState == SCENE_FRAGMENT_HIDDEN then
		callbackRaiseCheckViaFragment(filterType, fragment, SCENE_HIDDEN, inputType)
	end
end

local function createCallbacks()
	if libFilters.debug then
		dd("createCallbacks")
	end
	--[fragment] = LF_* filterTypeConstant. 0 means no dedicated LF_* constant can be used and the filterType will be determined
	local callbacksUsingFragments = callbacks.usingFragments

	for inputType, callbackDataPerFilterType in pairs(callbacksUsingFragments) do
		for fragment, filterType in pairs(callbackDataPerFilterType) do
			if libFilters.debug then
				dd(">register fragment StateChange to: %s - filterType: %s", tos(fragment), tos(filterType))
			end
			if filterType == 0 then filterType = nil end
			fragment:RegisterCallback("StateChange",
					function(oldState, newState) onFragmentStateChange(oldState, newState, filterType, fragment, inputType) end)
		end
	end
end


--**********************************************************************************************************************
-- FIXES
--**********************************************************************************************************************
--Fixes which are needed BEFORE EVENT_ADD_ON_LOADED hits
local function applyFixesEarly()
	if libFilters.debug then dd("ApplyFixesEarly") end
	--[[
		--Fix for the CraftBag on PTS API100035, v7.0.4-> As ApplyBackpackLayout currently always overwrites the additionalFilter :-(
		 --Added lines with 7.0.4:
		 local craftBag = self.inventories[INVENTORY_CRAFT_BAG]
		 craftBag.additionalFilter = layoutData.additionalFilter

		--Fix applied before was:
		SecurePostHook(playerInv, "ApplyBackpackLayout", function(layoutData)
			local crafBagIsHidden = kbc.craftBagClass:IsHidden()
			d("ApplyBackpackLayout-ZO_CraftBag:IsHidden(): " ..tos(crafBagIsHidden))
			if crafBagIsHidden then return end
			--Re-Apply the .additionalFilter to CraftBag again, on each open of it
			libFilters_hookAdditionalFilter(libFilters, LF_CRAFTBAG)
		end)

		--Update 2021-12-06: ZOs changed with version 7.1.5 to usage of own layoutData.additionalCraftBagFilter now
		--But it still overwrites the filters "in general" and thus breaks this library
		local craftBag = self.inventories[INVENTORY_CRAFT_BAG]
		craftBag.additionalFilter = layoutData.additionalCraftBagFilter
		 --So we need to apply a fix to HookAdditionalFilter to read the .additionalCraftBagFilter attribute of
		 --PLAYER_INVENTORY.appliedLayout and use this as filterFunctions
		SecurePostHook(playerInv, "ApplyBackpackLayout", function(layoutData)
			local crafBagIsHidden = kbc.craftBagClass:IsHidden()
d("ApplyBackpackLayout-ZO_CraftBag:IsHidden(): " ..tos(crafBagIsHidden))
			if crafBagIsHidden then return end
			--Re-Apply the .additionalFilter to CraftBag again, on each open of it
			libFilters_hookAdditionalFilter(libFilters, LF_CRAFTBAG)
		end)

	SecurePostHook(playerInv, "ApplyBackpackLayout", function(layoutData)
		local crafBagIsHidden = kbc.craftBagClass:IsHidden()
		d("!!!!! ApplyBackpackLayout-ZO_CraftBag:IsHidden(): " ..tos(crafBagIsHidden))
		if crafBagIsHidden then return end
		--Re-Apply the .additionalFilter to CraftBag again, on each open of it
		libFilters_hookAdditionalFilter(libFilters, LF_CRAFTBAG)
	end)
	]]

end

--Fixes which are needed AFTER EVENT_ADD_ON_LOADED hits
local function applyFixesLate()
	--2021-12-19
	--Fix applied now is only needed for CraftBagExtended addon!
	--The fragments used at mail send/bank deposit/guild bank deposit and guild store sell will apply their additionalFilters
	--to the normal player inventory PLAYER_INVETORY.appliedLayout.
	--But the CBE craftbag panel will not filter with these additional filters, but the PLAYER_INVENTORY.inventories[INVENTORY_CRAFT_BAG].additionalFilters
	--And these are empty at these special CBE filters! So we need to copy them over from BACKPACK_MENU_BAR_LAYOUT_FRAGMENT.layoutData.additionalCraftBagFilter
	if CraftBagExtended ~= nil then
		SecurePostHook(playerInv, "ApplyBackpackLayout", function(layoutData)
			local crafBagIsHidden = kbc.craftBagClass:IsHidden()
			if libFilters.debug then
				dd("ApplyBackpackLayout-CraftBag hidden: %s", tos(crafBagIsHidden))
			end
			if crafBagIsHidden == true or inventories[invTypeCraftBag].additionalFilter ~= nil then return end
			local additionalCraftBagFilter = kbc.invBackpackFragment.layoutData.additionalCraftBagFilter
			if additionalCraftBagFilter == nil then return end
			inventories[invTypeCraftBag].additionalFilter = additionalCraftBagFilter
		end)
	end
end

--Fixes which are needed AFTER EVENT_PLAYER_ACTIVATED hits
local function applyFixesLatest()

end


--Called from EVENT_PLAYER_ACTIVATED -> Only once
local function eventPlayerActivatedCallback(eventId, firstCall)
	EM:UnregisterForEvent(MAJOR .. "_EVENT_PLAYER_ACTIVATED", EVENT_PLAYER_ACTIVATED)
	applyFixesLatest()
end


--Called from EVENT_ADD_ON_LOADED
local function eventAddonLoadedCallback(eventId, addonNameLoaded)
	if addonNameLoaded ~= MAJOR then return end

	EM:UnregisterForEvent(MAJOR .. "_EVENT_ADDON_LOADED", EVENT_ADD_ON_LOADED)
	--EM:RegisterForEvent(MAJOR .. "_EVENT_PLAYER_ACTIVATED", EVENT_PLAYER_ACTIVATED, eventPlayerActivatedCallback)
	applyFixesLate()
	--Create the callbacks for the filterType's panel show/hide
	createCallbacks()
end

--**********************************************************************************************************************
-- LIBRARY LOADING / INITIALIZATION
--**********************************************************************************************************************
--Function needed to be called from your addon to start the LibFilters instance and enable the filtering!
function libFilters:InitializeLibFilters()
	if libFilters.debug then dd("InitializeLibFilters - %q", tos(libFilters.isInitialized)) end
	if libFilters.isInitialized then return end
	libFilters.isInitialized = true

	--Install the helpers, which override ZOs vanilla code -> See file helpers.lua
	installHelpers()
	--Hook into the scenes/fragments/controls to apply the filter function "runFilters" to the existing .additionalFilter
	--and other existing filters, and to add the libFilters filterType to the .LibFilters3_filterType tag (to identify the
	--inventory/control/fragment again)
	applyAdditionalFilterHooks()
end

--______________________________________________________________________________________________________________________
--______________________________________________________________________________________________________________________
--______________________________________________________________________________________________________________________
--TODO: Only for debugging
if GetDisplayName() == "@Baertram" then debugSlashToggle() end


--Apply any fixes needed to be run before EVENT_ADD_ON_LOADED
applyFixesEarly()
EM:RegisterForEvent(MAJOR .. "_EVENT_ADDON_LOADED", EVENT_ADD_ON_LOADED, eventAddonLoadedCallback)

if libFilters.debug then dd("LIBRARY MAIN FILE - END") end

