--======================================================================================================================
-- 												LibFilters 3.0
--======================================================================================================================

------------------------------------------------------------------------------------------------------------------------
--Bugs/Todo List for version: 3.0 r3.6 - Last updated: 2022-10-29, Baertram
------------------------------------------------------------------------------------------------------------------------
--Bugs total: 				2
--Feature requests total: 	0

--[Bugs]
-- #xx) 2022-xx-xx, Baertram: Gamepad/Keyboad mode - ...

-- #02) 2022-10-29, Baertram, Gamepad mode - Universal decon panel close at jewelry tab by direct open of LF_INVENTORY and re-open of
--  Universal Decon panel afterwards will hide inventory, show jewelry, close jewerly and show jewelry again.
--  Seems this happens because control of universal decon OnEffectivelyShown will be triggered, then inventory wants to call something
-- like a "hide" but the currentFilterType is the universal decon's LF_JEWELRY_DECONSTRUCT already and then the OnShow of OnFilterChanged
-- of the universal decon gamepad panel fires again: Seems only keyboard mode actually needs the additional control's OnEffectivelyShown then
-- as the universaldeconGamepad.deconstructionPanel.inventory OnFilterChanged is called more often (on reopen too!) in Gamepad mode, compare to
-- keyboard mode?

--[Feature requests]
-- #f1)


------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3 name, and version
------------------------------------------------------------------------------------------------------------------------
local libFilters 	= LibFilters3
local MAJOR      	= libFilters.name
local GlobalLibName = libFilters.globalLibName
local filters    	= libFilters.filters
local horizontalScrollBarFilters = libFilters.horizontalScrollBarFilters

local callbacksCreated = false
local fixesLateApplied = false
local fixesLatestApplied = false

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

--local getCurrentScene = SM.GetCurrentScene
local getScene = SM.GetScene
--Mapping between fragment's and scene's stateChange states
local fragmentStateToSceneState = {
	[SCENE_FRAGMENT_SHOWING]	= SCENE_SHOWING,
	[SCENE_FRAGMENT_SHOWN] 		= SCENE_SHOWN,
	[SCENE_FRAGMENT_HIDING] 	= SCENE_HIDING,
	[SCENE_FRAGMENT_HIDDEN] 	= SCENE_HIDDEN,
}


------------------------------------------------------------------------------------------------------------------------
--LOCAL LIBRARY SPEED UP VARIABLES & REFERENCES
------------------------------------------------------------------------------------------------------------------------
--Cashed current data (placeholders, currently nil)
libFilters._currentFilterType                  = nil
libFilters._currentFilterTypeUniversalDeconTab = nil
libFilters._currentFilterTypeReferences        = nil
--Cashed "last" data, before current (placeholders, currently nil)
libFilters._lastFilterType                  = nil
libFilters._lastFilterTypeUniversalDeconTab = nil
libFilters._lastFilterTypeReferences        = nil
--Cashes "last" callback state and "do not fire callback" variables
libFilters._lastCallbackState			= nil
libFilters._lastFilterTypeNoCallback	= false


--LibFilters local speedup and reference variables
--Overall constants & mapping
local constants = 					libFilters.constants
local mapping = 					libFilters.mapping
local callbacks = 					mapping.callbacks

local defaultFilterUpdaterDelay = 	constants.defaultFilterUpdaterDelay

local callbackPattern = 			libFilters.callbackPattern
local callbackBaseLibPattern = 		libFilters.callbackBaseLibPattern
local callbacksUsingScenes = 		callbacks.usingScenes
local callbacksUsingFragments = 	callbacks.usingFragments
local callbacksUsingControls = 		callbacks.usingControls
local specialCallbacks = 			callbacks.special
local filterTypeToCallbackRef = 	callbacks.filterTypeToCallbackRef
local callbackFragmentsBlockedMapping = callbacks.callbackFragmentsBlockedMapping
local sceneStatesSupportedForCallbacks = callbacks.sceneStatesSupportedForCallbacks
local callbacksAdded = {}
--controls
callbacksAdded[1] = {}
--scenes
callbacksAdded[2] = {}
--fragments
callbacksAdded[3] = {}
callbacks.added = callbacksAdded
--The registered callbacks which will be fired: Table of unique addonName, subTable per false (keyboard)/true (gamepad) input mode, subtable
--for universalDeconstructionActiveTab, subtable with filterType, and subTable with isShown (boolean true = callback showing, false = callback hiding)
callbacks.registeredCallbacks = {
	--Keyboard
	[false] = {},
	--Gamepad
	[true] = {},
}
--The table containing all other addon registered unique calback names as key and value = boolean true
callbacks.allRegisteredAddonCallbacks = {}


local libFilters_CallbackRaise
local onControlHiddenStateChange
local onSceneStateChange
local createControlCallback

local libFiltersFilterConstants = 	constants.filterTypes
local isCraftingFilterType = 		mapping.isCraftingFilterType
local validFilterTypesOfPanel = 	mapping.validFilterTypesOfPanel
local craftingTypeToPanelId = 		mapping.craftingTypeToPanelId

local inventoryTypes = 				constants.inventoryTypes
local invTypeBackpack = 			inventoryTypes["player"]
local invTypeQuest =				inventoryTypes["quest"]
local invTypeBank =					inventoryTypes["bank"]
local invTypeGuildBank =			inventoryTypes["guild_bank"]
local invTypeHouseBank =			inventoryTypes["house_bank"]
local invTypeCraftBag =				inventoryTypes["craftbag"]

local defaultOriginalFilterAttributeAtLayoutData = constants.defaultAttributeToAddFilterFunctions --"additionalFilter"
local otherOriginalFilterAttributesAtLayoutData_Table = constants.otherAttributesToGetOriginalFilterFunctions
local defaultLibFiltersAttributeToStoreTheFilterType = constants.defaultAttributeToStoreTheFilterType --"LibFilters3_filterType"
local defaultLibFiltersAttributeToStoreTheHorizontalScrollbarFilters = constants.defaultLibFiltersAttributeToStoreTheHorizontalScrollbarFilters --"LibFilters3_HorizontalScrollbarFilters"


local updaterNamePrefix = libFilters.constants.updaterNamePrefix

local filterTypesUsingBagIdAndSlotIndexFilterFunction = 			mapping.filterTypesUsingBagIdAndSlotIndexFilterFunction
local filterTypesUsingInventorySlotFilterFunction = 				mapping.filterTypesUsingInventorySlotFilterFunction
local LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT = 				constants.LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT
local LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX = 			constants.LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX

local filterTypeToFilterTypeRespectingCraftType = 					mapping.filterTypeToFilterTypeRespectingCraftType
local filterTypeToUpdaterName = 									mapping.filterTypeToUpdaterName
local updaterNameToFilterType = 									mapping.updaterNameToFilterType
local LF_FilterTypeToReference = 									mapping.LF_FilterTypeToReference
local LF_FilterTypesToReferenceImplementedSpecial = 			    mapping.LF_FilterTypesToReferenceImplementedSpecial
local LF_FilterTypeToReferenceGamepadFallbackToKeyboard =  			mapping.LF_FilterTypeToReferenceGamepadFallbackToKeyboard


local LF_FilterTypeToCheckIfReferenceIsHidden = 					mapping.LF_FilterTypeToCheckIfReferenceIsHidden
local LF_ConstantToAdditionalFilterSpecialHook = 					mapping.LF_ConstantToAdditionalFilterSpecialHook
local LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes =	mapping.LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes
local LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup = mapping.LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup
local LF_FilterTypeToDialogOwnerControl = 							mapping.LF_FilterTypeToDialogOwnerControl

local libFilters_IsUniversalDeconstructionPanelShown
local filterTypeToUniversalOrNormalDeconAndExtractVars = 			mapping.filterTypeToUniversalOrNormalDeconAndExtractVars
local universalDeconTabKeyToLibFiltersFilterType	   =			mapping.universalDeconTabKeyToLibFiltersFilterType
local universalDeconFilterTypeToFilterBase = 					    mapping.universalDeconFilterTypeToFilterBase
local universalDeconLibFiltersFilterTypeSupported = 				mapping.universalDeconLibFiltersFilterTypeSupported

--Keyboard
local kbc                      	= 	constants.keyboard
local playerInv                	= 	kbc.playerInv
local inventories              	= 	kbc.inventories
--local craftBagFragment 		   = 	kbc.craftBagFragment
--local craftBagKBLayoutDataAttribute = otherOriginalFilterAttributesAtLayoutData_Table[false][LF_CRAFTBAG]["attributeRead"]
local quickslots               	=    kbc.quickslots
local store                    	= 	kbc.store
--local storeBuy                 = 	kbc.vendorBuy
--local storeSell                = 	kbc.vendorSell
local vendorBuyBack             = 	kbc.vendorBuyBack
local vendorRepair              = 	kbc.vendorRepair
local storeWindows             	= 	kbc.storeWindows
local guildStoreSellFragment   	= 	kbc.guildStoreSellFragment
--local fence                    = 	kbc.fence
local researchChooseItemDialog 	= 	kbc.researchChooseItemDialog
--local playerInvCtrl            =   kbc.playerInvCtrl
local companionEquipment 	   	= 	kbc.companionEquipment
local companionEquipmentCtrl   	= 	companionEquipment.control
local characterCtrl            	=	kbc.characterCtrl
local companionCharacterCtrl   	= 	kbc.companionCharacterCtrl
local refinementPanel		   	=   kbc.refinementPanel
local creationPanel			   	=   kbc.creationPanel
local deconstructionPanel	   	=   kbc.deconstructionPanel
local improvementPanel	   	   	=   kbc.improvementPanel
local researchPanel			   	=   kbc.researchPanel
local enchantingClass		   	=   kbc.enchantingClass
local enchanting               	= 	kbc.enchanting
local enchantingInvCtrl        	= 	enchanting.inventoryControl
local alchemyClass		   	   	=	kbc.alchemyClass
local alchemy                  	= 	kbc.alchemy
local alchemyCtrl              	=	kbc.alchemyCtrl
local provisionerClass		   	=	kbc.provisionerClass
local provisioner			   	=   kbc.provisioner
--local provCtrl 				 =    provisioner.control
local provisionerScene 		   	=   kbc.provisionerScene
--local smithing				   =    kbc.smithing
local retrait 				   	= 	kbc.retrait
local reconstruct 			 	= 	kbc.reconstruct

local universalDeconstruct      = 	kbc.universalDeconstruct
local universalDeconstructPanel = 	kbc.universalDeconstructPanel
local universalDeconstructScene =   kbc.universalDeconstructScene

local craftbagRefsFragment = LF_FilterTypeToCheckIfReferenceIsHidden[false][LF_CRAFTBAG]["fragment"]
local enchantingModeToFilterType = mapping.enchantingModeToFilterType
local provisionerIngredientTypeToFilterType = mapping.provisionerIngredientTypeToFilterType
local alchemyModeToFilterType = mapping.alchemyModeToFilterType


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

--local playerInvCtrl_GP         = 	gpc.playerInvCtrl_GP
local companionEquipment_GP 	=   gpc.companionEquipment_GP
local companionEquipmentCtrl_GP = 	companionEquipment_GP.control
--local characterCtrl_GP         =	gpc.characterCtrl_GP
local companionCharacterCtrl_GP = 	gpc.companionCharacterCtrl_GP
local refinementPanel_GP	    =   gpc.refinementPanel_GP
local creationPanel_GP		    =   gpc.creationPanel_GP
local deconstructionPanel_GP    =   gpc.deconstructionPanel_GP
local improvementPanel_GP		=   gpc.improvementPanel_GP
local researchPanel_GP          = 	gpc.researchPanel_GP
local researchChooseItemDialog_GP = gpc.researchChooseItemDialog_GP
local enchanting_GP             = 	gpc.enchanting_GP
local enchantingInvCtrls_GP     = 	gpc.enchantingInvCtrls_GP
local alchemy_GP                = 	gpc.alchemy
local alchemyCtrl_GP            =	gpc.alchemyCtrl_GP
local provisioner_GP			=   gpc.provisioner_GP
local provisionerScene_GP 	    =   gpc.provisionerScene_GP
local invMailSend_GP 			= 	gpc.invMailSend_GP
local invPlayerTrade_GP 		= 	gpc.invPlayerTrade_GP
local invGuildStoreSell_GP 		= 	gpc.invGuildStoreSell_GP
local retrait_GP 				= 	gpc.retrait_GP
local reconstruct_GP 			= 	gpc.reconstruct_GP

--local provCtrl_GP				=   gpc.provisioner_GP.control
local universalDeconstruct_GP   =   gpc.universalDeconstruct_GP
local universalDeconstructPanel_GP = gpc.universalDeconstructPanel_GP
local universalDeconstructScene_GP = gpc.universalDeconstructScene_GP

--Other addons
local cbeSupportedFilterPanels  = constants.cbeSupportedFilterPanels

--The costants for the reference types
local typeOfRefConstants = constants.typeOfRef
local LIBFILTERS_CON_TYPEOFREF_CONTROL 	= typeOfRefConstants[1]
local LIBFILTERS_CON_TYPEOFREF_SCENE 	= typeOfRefConstants[2]
local LIBFILTERS_CON_TYPEOFREF_FRAGMENT = typeOfRefConstants[3]
local LIBFILTERS_CON_TYPEOFREF_OTHER 	= typeOfRefConstants[99]
local typeOfRefToName    = constants.typeOfRefToName

local checkIfControlSceneFragmentOrOther = libFilters.CheckIfControlSceneFragmentOrOther
local createCustomGamepadFragmentsAndNeededHooks = libFilters.CreateCustomGamepadFragmentsAndNeededHooks

local getCtrl = 				libFilters.GetCtrl
local checkIfRefVarIsShown =	libFilters.CheckIfRefVarIsShown
local getTypeOfRefName = 		libFilters.GetTypeOfRefName
local getFragmentControlName = 	libFilters.GetFragmentControlName
local getSceneName = 			libFilters.GetSceneName
local getCtrlName = 			libFilters.GetCtrlName
local isControlShown = 			libFilters.IsControlShown

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
local libFilters_GetFilterTypeName
local libFilters_IsCraftBagShown
local libFilters_getUniversalDeconstructionPanelActiveTabFilterType

------------------------------------------------------------------------------------------------------------------------
--DEBUGGING & LOGGING
------------------------------------------------------------------------------------------------------------------------
--LibDebugLogger, or normal logger d() output
local logger = libFilters.logger
local debugFunctions = libFilters.debugFunctions

local dd 	= debugFunctions.dd
local df 	= debugFunctions.df
local dv 	= debugFunctions.dv
local dfe 	= debugFunctions.dfe

--Slash command to toggle the debug boolean true/false
local debugSlashToggle = debugFunctions.debugSlashToggle
SLASH_COMMANDS["/libfiltersdebug"] = 	debugSlashToggle
SLASH_COMMANDS["/lfdebug"] = 			debugSlashToggle

local isDebugEnabled = libFilters.debug
local function updateIsDebugEnabled()
	isDebugEnabled = libFilters.debug
end
libFilters.UpdateIsDebugEnabled = updateIsDebugEnabled


if isDebugEnabled then dd("LIBRARY MAIN FILE - START") end


------------------------------------------------------------------------------------------------------------------------
--LOCAL HELPER FUNCTIONS
------------------------------------------------------------------------------------------------------------------------
--Is a filterType that is supported at UniversalDeconstruction, e.g. LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT, LF_ENCHANTING_EXTRACT
local function isUniversalDeconstructionSupportedFilterType(filterType)
	local isSupported = universalDeconLibFiltersFilterTypeSupported[filterType] or false
	if isDebugEnabled then dd("|UD> IsUniversalDeconstructionSupportedFilterType - %q, filterType: %s", tos(isSupported), tos(filterType)) end
	return isSupported
end
libFilters.IsUniversalDeconstructionSupportedFilterType = isUniversalDeconstructionSupportedFilterType


--Copy the current filterType to lastFilterType (same for the referenceVariables table) if the filterType / refVariables
--table needs an update, and for the UniversalDeconstruction panel's selected tab
local function updateLastAndCurrentFilterType(lFilterTypeDetected, lReferencesToFilterTyp, universalDeconTab, doNotUpdateLast)
	if isDebugEnabled then dd("!°!updateLastAndCurrentFilterType - filterType: %s, universalDeconTab: %s, doNotUpdateLast: %s, current: %s, last: %s, lastUniversalDeconTab: %s",
		tos(lFilterTypeDetected), tos(universalDeconTab), tos(doNotUpdateLast), tos(libFilters._currentFilterType),
			tos(libFilters._lastFilterType), tos(libFilters._lastFilterTypeUniversalDeconTab))
	end
	doNotUpdateLast = doNotUpdateLast or false
	if not doNotUpdateLast then
		local currentFilterTypeBefore 				= libFilters._currentFilterType
		if currentFilterTypeBefore ~= nil then
			local _lastFilterType = currentFilterTypeBefore
			libFilters._lastFilterType 				= _lastFilterType
		end
		--[[
		local currentFilterTypeUniversalDeconTabBefore = libFilters._currentFilterTypeUniversalDeconTab
		if currentFilterTypeUniversalDeconTabBefore ~= nil then
			local _lastFilterTypeUniversalDeconTab = currentFilterTypeUniversalDeconTabBefore
			libFilters._lastFilterTypeUniversalDeconTab = _lastFilterTypeUniversalDeconTab
		end
		]]
		local currentFilterTypeReferencesBefore = libFilters._currentFilterTypeReferences
		if currentFilterTypeReferencesBefore ~= nil then
			local _lastFilterTypeReferences = currentFilterTypeReferencesBefore
			libFilters._lastFilterTypeReferences 	= _lastFilterTypeReferences
		end
	end
	libFilters._currentFilterType                  = 	lFilterTypeDetected
	--libFilters._currentFilterTypeUniversalDeconTab = 	universalDeconTab
	libFilters._currentFilterTypeReferences        = 	lReferencesToFilterTyp
end



--[[
--Get the currently shown scene and sceneName
local function getCurrentSceneInfo()
	if not SM then return nil, "" end
	local currentScene = getCurrentScene(SM)
	local currentSceneName = (currentScene ~= nil and currentScene.name) or ""
	if isDebugEnabled then dd("getCurrentSceneInfo - currentScene: %q, name: %q", tos(currentScene), tos(currentSceneName)) end
	return currentScene, currentSceneName
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
local function getSceneNameByFilterType(filterType, isInGamepadMode)
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
	if isDebugEnabled then dv("getSceneName - filterType %s: %q, retScene: %s", tos(filterType), tos(retSceneName), tos(retScene)) end
	return retSceneName, retScene
end
]]


--Check if a scene or fragment is assigned to the filterType and inputType
--LF_FilterTypeToCheckIfReferenceIsHidden[isInGamepadMode][filterType] it will be checked first if it's shown
--If a fragment is provided this will be checked after the scene.
--In both cases: If any of them is shown the result will be true
--boolean isSceneOrFragment defines if the call should be using the scene ONLY (true) or the fragment ONLY (false). If left
--nil both will be checked
--returns boolean isShown, sceneOrFragmentReference sceneOrFragmentWhichIsShown
local function isSceneFragmentShown(filterType, isInGamepadMode, isSceneOrFragment, checkIfHidden)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	checkIfHidden = checkIfHidden or false

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
		if isSceneOrFragment == true and isDebugEnabled then dv("!isSceneFragmentShown - changed sceneName %q to scene %s - filterType %s", tos(retScene), tos(sceneOfRetSceneName), tos(filterType)) end
		if sceneOfRetSceneName ~= nil then
			retScene = sceneOfRetSceneName
		else
			return false, retScene
		end
	end

	if isSceneOrFragment == true then
		resultIsShown = checkIfRefVarIsShown(retScene)
		if checkIfHidden == true then
			if resultIsShown == false then
				resultIsShown = true
			end
		end
		if resultIsShown == true then
			resultSceneOrFragment = retScene
		end
	else
		resultIsShown = checkIfRefVarIsShown(retFragment)
		if checkIfHidden == true then
			if resultIsShown == false then
				resultIsShown = true
			end
		end
		if resultIsShown == true then
			resultSceneOrFragment = retFragment
		end
	end
	if isDebugEnabled then dv("!isSceneFragmentShown - filterType %s: %s, isSceneOrFragment: %s", tos(filterType), tos(resultIsShown), tos(isSceneOrFragment)) end
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
		if isDebugEnabled then dv("!isListDialogShownWrapper - filterType %s: %s, gamepadMode: %s, error: %s", tos(filterType), tos(false), tos(isInGamepadMode), "filterTypeData is nil!") end
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


--[[
--Special entries can be added for dynamically done checks -> See LibFilters-3.0.lua, function isSpecialTrue(filterType, isInGamepadMode, false, ...)
["special"] = {
  [1] = {
	  ["control"]  =  gamepadConstants.enchanting_GP,
	  ["funcOrAttribute"] = "GetEnchantingMode",
	  ["params"] = {}, --no params used, leave nil to pass in ... from isSpecialTrue(filterType, isInGamepadMode, false, ...)
	  --either control + func + params OR bool can be given!
	  ["bool"] = booleanVariableOrFunctionReturningABooleanValue,
	  ["expectedResults"] = {ENCHANTING_MODE_CREATION},
	  ["expectedResultsMap"] = { [1] = true, [2] = nil } --Optional. Used if the function returns more than one parameter. You are able to to define which result parameter needs to be checked (true), or not (false/nil)
  }
}
--SpecialForced entries can be added for dynamically done checks -> See LibFilters-3.0.lua, function isSpecialTrue(filterType, isInGamepadMode, true, ...)
["specialForced"] = {
  [1] = {
	  ["control"]  =  gamepadConstants.enchanting_GP,
	  ["funcOrAttribute"] = "GetEnchantingMode",
	  ["params"] = {}, --no params used, leave nil to pass in ... from isSpecialTrue(filterType, isInGamepadMode, true, ...)
	  --either control + func + params OR bool can be given!
	  ["bool"] = booleanVariableOrFunctionReturningABooleanValue,
	  ["expectedResults"] = {ENCHANTING_MODE_CREATION},
	  ["expectedResultsMap"] = { [1] = true, [2] = nil } --Optional. Used if the function returns more than one parameter. You are able to to define which result parameter needs to be checked (true), or not (false/nil)
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
	isSpecialForced = isSpecialForced or false
	if isDebugEnabled then
		dd(">>>>>>>>>>>>>>>>>>>>>>>>>>>>")
		dd("!isSpecialTrue - filterType: %s, gamepadMode: %s, isSpecialForced: %s, paramsGiven: %s", tos(filterType), tos(isInGamepadMode), tos(isSpecialForced), tos(... ~= nil))
	end
	if not filterType then return false end
	local filterTypeData = LF_FilterTypeToCheckIfReferenceIsHidden[isInGamepadMode][filterType]
	local specialRoutines = filterTypeData and ((isSpecialForced == true and filterTypeData["specialForced"]) or filterTypeData["special"])
	if not specialRoutines or #specialRoutines == 0 then
		if isDebugEnabled then
			dd("!isSpecialTrue - No checks found! Returned: true")
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
								if isDebugEnabled then dv(">using locally passed in params") end
								params = {...}
								if ncc(params) == 0 then
									if isDebugEnabled then dv(">>locally passed in params are empty") end
									noParams = true
								end
							else
								if isDebugEnabled then dv(">using params of constants") end
								if ncc(params) == 0 then
									if isDebugEnabled then dv(">>params of constants are empty") end
									noParams = true
								end
							end
							if isDebugEnabled then dv(">>CALLING FUNCTION NOW...") end
							if not noParams then
								results = {ctrl[funcOrAttribute](unpack(params))}
							else
								results = {ctrl[funcOrAttribute]()}
							end
						else
							if isDebugEnabled then dv(">>GETTING ATTRIBUTE NOW...") end
							results = {ctrl[funcOrAttribute]}
						end
						if not results then
							if isDebugEnabled then dv(">>>no return values") end
							if expectedResults == nil then
								if isDebugEnabled then dv(">>>no expected results -> OK") end
								loopResult = true
							end
						else
							local numResults = #results
							if isDebugEnabled then dv(">>>return values: " ..tos(numResults)) end
							if numResults == 0 then
								if isDebugEnabled then dv(">>>no return values") end
								if expectedResults == nil then
									if isDebugEnabled then dv(">>>>no expected results -> OK") end
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
		if isDebugEnabled then
			local abortedStartStr = (checkAborted ~= "" and "<<<") or ">>>"
			dd("%scheckType: %q, abortedDueTo: %s, loopResult: %s", abortedStartStr, tos(checkType), tos(checkAborted), tos(loopResult))
		end
		totalResult = totalResult and loopResult
	end
	if isDebugEnabled then
		dd("!isSpecialTrue - filterType: %s, totalResult: %s, isSpecialForced: %s", tos(filterType), tos(totalResult), tos(isSpecialForced))
		dd("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
	end
	return totalResult
end


local function getSmithingResearchPanel()
	if IsGamepad() then
		return researchPanel_GP
	else
		return researchPanel
	end
end


------------------------------------------------------------------------------------------------------------------------
--LOCAL HELPER FUNCTIONS - fix function
------------------------------------------------------------------------------------------------------------------------
local function fixResearchDialogRowOnItemSelectedCallback()
	if researchChooseItemDialog.listDialog ~= nil then
		researchChooseItemDialog.listDialog:SetOnSelectedCallback(function(selectedData)
			if selectedData == nil then
				return
			end --fix to prevent nil error
			researchChooseItemDialog:OnItemSelected(selectedData.bag, selectedData.index)
		end)
	end
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
	if isDebugEnabled then
		dv("!getFilterTypeByFilterTypeRespectingCraftType-source: %q, target: %q, craftType: %s",
			tos(filterTypeSource), tos(filterTypeTarget), tos(craftType))
	end
	return filterTypeTarget, craftType
end

--is the filterType passed in a valid supported CraftBagExtended filterType?
local function isCraftBagExtendedSupportedPanel(filterTypePassedIn)
	local isSupportedFilterPanel = ZO_IsElementInNumericallyIndexedTable(cbeSupportedFilterPanels, filterTypePassedIn)
	if isDebugEnabled then
		dv(">isCraftBagExtendedSupportedPanel - filterType: %s = %s", tos(filterTypePassedIn), tos(isSupportedFilterPanel))
	end
	return isSupportedFilterPanel
end


--Check if CraftBagExtended addon is enabled and if any of the supported extra panels/fragments are shown
--and if the extra menu buttons of CBE are clicked to currently show the craftbag, and if the fragment's layoutData of
--the CBE fragments hooked use the same number filterType as passed in
local function craftBagExtendedCheckForCurrentModule(filterType)
	if isDebugEnabled then dv("!craftBagExtendedCheckForCurrentModule - filterTypePassedIn: " .. tos(filterType)) end
	local cbe = CraftBagExtended
	if cbe == nil then return nil, nil end
	local cbeCurrentModule = cbe.currentModule
	if cbeCurrentModule == nil then
		if isDebugEnabled then dv("<no current CBE module found") end
		return false, nil
	end
	local cbeDescriptorOfCraftBag = 4402 --GetString(4402) = "CraftBag"
	--Check if the CBE button at the menu is activated -> Means te CBE fragment is shown
	local cbeMenu = cbeCurrentModule.menu
	local currentlyClickedButtonDescriptor = cbeMenu.m_object:GetSelectedDescriptor()
	if isDebugEnabled then dv(">currentClickedButton: %s = %q", tos(currentlyClickedButtonDescriptor), tos(GetString(currentlyClickedButtonDescriptor))) end
	if currentlyClickedButtonDescriptor == nil or currentlyClickedButtonDescriptor ~= cbeDescriptorOfCraftBag then return  nil, nil end
	local cbeFragmentLayoutData = cbeCurrentModule.layoutFragment and cbeCurrentModule.layoutFragment.layoutData
	--Get the constants.defaultAttributeToStoreTheFilterType (.LibFilters3_filterType) from the layoutData
	local filterTypeAtFragment = libFilters_GetCurrentFilterTypeForInventory(libFilters, cbeFragmentLayoutData, false)
	if isDebugEnabled then dv(">filterTypeAtFragment: %s", tos(filterTypeAtFragment)) end
	if filterTypeAtFragment == nil then return  nil, nil end
	local referencesFound = {}
	if filterTypeAtFragment == filterType then
		tins(referencesFound, cbeCurrentModule.scene)
		return referencesFound, filterTypeAtFragment
	end
	return nil, nil
end


--Check the valid "last shown" filterTypes at a given panelIdentifier.
--This will prevent e.g. the raise of callback "inventory hidden" if you open the alchemy station and the last opened
--alchemy station panel was the recipes panel -> The callback SCENE_HIDDEN with libFilters._lastFilterType will be raised then
-->but this must only happen if the last known filterType was any valid at the current panel
local function checkForValidFilterTypeAtSamePanel(filterType, panelIdentifier, craftingType)
	if panelIdentifier == nil then
		craftingType = craftingType or gcit()
		panelIdentifier = craftingTypeToPanelId[craftingType]
		if panelIdentifier == nil then
			return false
		end
	end
	if isDebugEnabled then dv("checkForValidLastFilterTypesAtSamePanel - id: %s, filterType: %s", tos(panelIdentifier), tos(filterType)) end
	--No filterType given? Then act normal and allow the SCENE_HIDDEN callback of the panel
	if filterType == nil then return true end

	--Map the identifier of the panel from normal smithing crafting to jewelry crafting if the current craftingType is jewelry crafting
	if panelIdentifier == "smithing" then
		craftingType = craftingType or gcit()
		if craftingType == CRAFTING_TYPE_JEWELRYCRAFTING then
			panelIdentifier = "jewelryCrafting"
		end
	end
	local validFilterTypes = validFilterTypesOfPanel[panelIdentifier]
	local isValidFilterTypeAtPanel = validFilterTypes[filterType] or false
	if isDebugEnabled then dv("<isValidFilterTypeAtPanel: %s", tos(isValidFilterTypeAtPanel)) end
	return isValidFilterTypeAtPanel
end


--Check if a control/fragment/scene is shown/hidden (depending on parameter "checkIfHidden") or if any special check function
--needs to be called to do additional checks, or an overall special forced check function needs to be always called at the end
--of all checks (e.g. for crafting -> check if jewelry crafting or other)
local function checkIfShownNow(filterTypeControlAndOtherChecks, isInGamepadMode, checkIfHidden, skipSpecialChecks)
	checkIfHidden = checkIfHidden or false
	skipSpecialChecks = skipSpecialChecks or false
	local lReferencesToFilterType, lFilterTypeDetected
	if filterTypeControlAndOtherChecks ~= nil then
		local filterTypeChecked = filterTypeControlAndOtherChecks.filterType
		if isDebugEnabled then dv("!>>>===== checkIfShownNow = START =") end
		if isDebugEnabled then dv(">checking filterType: %q [%s] - needs to be hidden: %s", libFilters_GetFilterTypeName(libFilters, filterTypeChecked), tos(filterTypeChecked), tos(checkIfHidden)) end
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
						local doHiddenTwistCheck = true
						if checkTypeToExecute == "control" then
							resultLoop, currentReferenceFound = isControlShown(filterTypeChecked, isInGamepadMode)
						elseif checkTypeToExecute == "controlDialog" then
							resultLoop, currentReferenceFound = isListDialogShownWrapper(filterTypeChecked, isInGamepadMode)
						elseif checkTypeToExecute == "fragment" then
							doHiddenTwistCheck = false
							resultLoop, currentReferenceFound = isSceneFragmentShown(filterTypeChecked, isInGamepadMode, false, checkIfHidden)
						elseif checkTypeToExecute == "scene" then
							doHiddenTwistCheck = false
							resultLoop, currentReferenceFound = isSceneFragmentShown(filterTypeChecked, isInGamepadMode, true, checkIfHidden)
						elseif not skipSpecialChecks and checkTypeToExecute == "special" then
							doHiddenTwistCheck = false
							resultLoop = isSpecialTrue(filterTypeChecked, isInGamepadMode, false, nil) --instead , nil ->  use , unpack(paramsForFilterTypeSpecialCheck))
						elseif not skipSpecialChecks and checkTypeToExecute == "specialForced" then
							doHiddenTwistCheck = false
							if resultOfCurrentLoop == true then resultLoop = true end
							doSpecialForcedCheckAtEnd = true
						end
						--No special check was done, only normal control/fragment/scene shown check
						if doHiddenTwistCheck == true then
							--Is the expected result a "hidden" state of the control/scene/fragment?
							-->Check if the resultLoop is "false" then
							--->But it could also be false without having found the reference needed so also check if the ref. is given!
							if checkIfHidden == true then
								dv(">>hidden check - foundInLoop: %s, checkType: %s, refFound: %s", tos(resultLoop), tos(checkTypeToExecute), tos(currentReferenceFound ~= nil))
								if currentReferenceFound ~= nil and resultLoop == false then
									resultLoop = true
								end
							end
						end
						if not skipSpecialChecks then
							if isDebugEnabled then
								local resultLoopStr = (resultLoop == true and ">>") or "<<"
								dv("%sfoundInLoop: %s, checkType: %s", tos(resultLoopStr), tos(resultLoop), tos(checkTypeToExecute))
							end
						else
							if checkTypeToExecute == "special" or checkTypeToExecute == "specialForced" then
								if isDebugEnabled then dv("<<<skipped special check: %s", tos(checkTypeToExecute)) end
								resultLoop = true
							end
						end
					else
						if isDebugEnabled then dv("<<<skipped checkType: %s  - resultOfCurrentLoop was false already", tos(checkTypeToExecute) ) end
					end
					resultOfCurrentLoop = resultOfCurrentLoop and resultLoop
				end
				--End checks
				if resultOfCurrentLoop == true then
					if doSpecialForcedCheckAtEnd == true and not skipSpecialChecks then
						resultOfCurrentLoop = isSpecialTrue(filterTypeChecked, isInGamepadMode, true, nil)
						if isDebugEnabled then dv(">>>specialCheckAtEnd: " ..tos(resultOfCurrentLoop)) end
					end
					if resultOfCurrentLoop == true then
						lFilterTypeDetected = filterTypeChecked
						if currentReferenceFound == nil then
							if isDebugEnabled then dv(">>>>currentReferenceFound is nil, detecing it...") end
							currentReferenceFound = libFilters_GetFilterTypeReferences(libFilters, filterTypeChecked, isInGamepadMode)
						end
						if currentReferenceFound ~= nil then
							local curRefType = type(currentReferenceFound)
							if isDebugEnabled then dv(">>>>currentReferenceFound: YES, type: %s", tos(curRefType)) end
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
			if isDebugEnabled then
				dd(">found filterType: %s", tos(lFilterTypeDetected))
				dv("!<<<===== checkIfShownNow = END =")
			end
			--Abort the for ... do loop now as data was found
			return lReferencesToFilterType, lFilterTypeDetected
		end
	end
	return lReferencesToFilterType, lFilterTypeDetected
end


local function getDeconstructOrExtractCraftingVarToUpdate(filterType, isInGamepadMode, isUniversalDecon)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	libFilters_IsUniversalDeconstructionPanelShown = libFilters_IsUniversalDeconstructionPanelShown or libFilters.IsUniversalDeconstructionPanelShown
	if isUniversalDecon == nil then
		isUniversalDecon = libFilters_IsUniversalDeconstructionPanelShown(isInGamepadMode) or false
	end
	local craftingVarToUpdate = filterTypeToUniversalOrNormalDeconAndExtractVars[isInGamepadMode][filterType][isUniversalDecon]
	return craftingVarToUpdate
end

local function getUniversalDeconstructionFilterTypeByActiveTab_AndReferenceVar(p_filterType, isInGamepadMode)
	libFilters_getUniversalDeconstructionPanelActiveTabFilterType = libFilters_getUniversalDeconstructionPanelActiveTabFilterType or libFilters.GetUniversalDeconstructionPanelActiveTabFilterType
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	local lFilterTypeDetected, lReferencesToFilterType, universalDeconSelectedTabKey

	--Get the active tab at the universal deconstruction panel (all, armor, weapons, jewelry, glyphs)
	--Return the detected active tab's libFiltersFilterType LF_SMITHING* etc.
	lFilterTypeDetected, universalDeconSelectedTabKey = libFilters_getUniversalDeconstructionPanelActiveTabFilterType(p_filterType)
	if lFilterTypeDetected ~= nil then
		--Get the filter panel's control/scene/frament reference, but use Universal deconstruction here!
		lReferencesToFilterType = getDeconstructOrExtractCraftingVarToUpdate(lFilterTypeDetected, isInGamepadMode, true)
		if lReferencesToFilterType ~= nil then
			return lFilterTypeDetected, lReferencesToFilterType, universalDeconSelectedTabKey
		end
	end
	return nil, nil, nil
end

local function detectShownReferenceNow(p_filterType, isInGamepadMode, checkIfHidden, skipSpecialChecks)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	checkIfHidden = checkIfHidden or false
	skipSpecialChecks = skipSpecialChecks or false
	local lFilterTypeDetected
	local lReferencesToFilterType = {}

	--Special case "Universal Deconstruction" -> Own UI cotrols but re-use LF_SMITHING* etc. filterTypes!
	local isUniversalDeconPanelShown = libFilters_IsUniversalDeconstructionPanelShown()
	local universalDeconSelectedTabKey

	if isDebugEnabled then dd(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>") end
	if isDebugEnabled then dd("!detectShownReferenceNow - filterTypePassedIn: %s, isInGamepadMode: %s, isUniversalDecon: %s",
			tos(p_filterType), tos(isInGamepadMode), tos(isUniversalDeconPanelShown) ) end

	--Universal Deconstruction?
	if isUniversalDeconPanelShown == true then
		lFilterTypeDetected, lReferencesToFilterType, universalDeconSelectedTabKey = getUniversalDeconstructionFilterTypeByActiveTab_AndReferenceVar(p_filterType, isInGamepadMode)
	else

		--All other panels
		--Check one specific filterType first (e.g. cached one)
		if p_filterType ~= nil then
			--Get data to check from lookup table
			local filterTypeChecksIndex = LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup[isInGamepadMode][p_filterType]
			if filterTypeChecksIndex ~= nil then
				local filterTypeControlAndOtherChecks = LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[isInGamepadMode][filterTypeChecksIndex]
				--Check if still shown
				lReferencesToFilterType, lFilterTypeDetected = checkIfShownNow(filterTypeControlAndOtherChecks, isInGamepadMode, checkIfHidden, skipSpecialChecks)
				if lFilterTypeDetected ~= nil and lReferencesToFilterType ~= nil and #lReferencesToFilterType > 0 then
					if isDebugEnabled then
						dd("<<< found PASSED IN FILTERTYPE %q <<<<<<<<<<<<<<<<<<<<<<<<", tos(lFilterTypeDetected))
					end
					--updateLastAndCurrentFilterType(lFilterTypeDetected, lReferencesToFilterType, false)
				end
			end
			return lReferencesToFilterType, lFilterTypeDetected, nil

		else
			--Dynamically get the filterType via the currently shown control/fragment/scene/special check and specialForced check
			for _, filterTypeControlAndOtherChecks in ipairs(LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[isInGamepadMode]) do
				lReferencesToFilterType, lFilterTypeDetected = checkIfShownNow(filterTypeControlAndOtherChecks, isInGamepadMode, checkIfHidden, skipSpecialChecks)
				if lFilterTypeDetected ~= nil and lReferencesToFilterType ~= nil and #lReferencesToFilterType > 0 then
					if isDebugEnabled then
						dd("<<< FOR .. in checkTypes LOOP, found filterType: %q <<<<<<<<<<<<<<<<<<<<<<<<", tos(lFilterTypeDetected))
					end
					--updateLastAndCurrentFilterType(lFilterTypeDetected, lReferencesToFilterType, false)
					--Abort the for ... do loop now as data was found
					return lReferencesToFilterType, lFilterTypeDetected, nil
				end
			end --for _, filterTypeControlAndOtherChecks in ipairs(LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[isInGamepadMode]) do
		end

	end

	if isDebugEnabled then
		dd("<found filterType: %s, universalDeconTabKey: %s", tos(lFilterTypeDetected), tos(universalDeconSelectedTabKey))
		dd("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
	end
	return lReferencesToFilterType, lFilterTypeDetected, universalDeconSelectedTabKey
end

--Is the filterType cached at libFilters._currentFilterType (set during call to updater functions and other functions)
--still the valid one, and it's reference is still shown?
local function checkIfCachedFilterTypeIsStillShown(isInGamepadMode)
	local currentFilterType = libFilters._currentFilterType
	if currentFilterType ~= nil then
		local filterTypeReference, filterTypeShown, universalDeconSelectedTabKey = detectShownReferenceNow(currentFilterType, isInGamepadMode, false, false)
		if filterTypeReference ~= nil and filterTypeShown ~= nil then
			local currentFilterTypeUniversalDeconTab = libFilters._currentFilterTypeUniversalDeconTab
			if filterTypeShown == currentFilterType and
				(currentFilterTypeUniversalDeconTab == nil or (currentFilterTypeUniversalDeconTab ~= nil and currentFilterTypeUniversalDeconTab == universalDeconSelectedTabKey)) then
				if isDebugEnabled then dd("!>checkIfCachedFilterTypeIsStillShown %q: %s", tos(filterTypeShown), "YES") end
				--updateLastAndCurrentFilterType(filterTypeShown, filterTypeReference, true)
				return filterTypeReference, filterTypeShown, universalDeconSelectedTabKey
			end
		end
	end
	if isDebugEnabled then dd("<!checkIfCachedFilterTypeIsStillShown - currentFilterType %q: No", tos(libFilters._currentFilterType)) end
	return nil, nil, nil
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
	if isDebugEnabled then
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
		dv("[U]SafeUpdateList, inv: %s, name: %s", tos(object), tos(updatedName))
	end
	local isMouseVisible = SM:IsInUIMode()
	if isMouseVisible then HideMouse() end
	object:UpdateList(...)
	if isMouseVisible then ShowMouse() end
end

--Function to update a ZO_ListDialog1 dialog's list contents
local function dialogUpdaterFunc(listDialogControl)
	if isDebugEnabled then dv("[U]dialogUpdaterFunc, listDialogControl: %s", (listDialogControl ~= nil and listDialogControl.GetName ~= nil and tos(listDialogControl:GetName()) or "listDialogName: n/a")) end
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
					fixResearchDialogRowOnItemSelectedCallback()
				end
		  end
	 end
end

--Updater function for a normal inventory in keyboard mode
local function updateKeyboardPlayerInventoryType(invType)
	if isDebugEnabled then dv("[U]updateKeyboardPlayerInventoryType - invType: %s", tos(invType)) end
	SafeUpdateList(playerInv, invType)
end


------------------------------------------------------------------------------------------------------------------------
--KEYBOARD & GAMEPAD updater functions
------------------------------------------------------------------------------------------------------------------------
--Updater function for a crafting inventory in keyboard and gamepad mode
local function updateCraftingInventoryDirty(craftingInventory)
	if isDebugEnabled then dv("[U]updateCraftingInventoryDirty - craftingInventory: %s", tos(craftingInventory)) end
	craftingInventory.inventory:HandleDirtyEvent()
end

-- update for LF_BANK_DEPOSIT/LF_GUILDBANK_DEPOSIT/LF_HOUSE_BANK_DEPOSIT/LF_MAIL_SEND/LF_TRADE/LF_BANK_WITHDRAW/LF_GUILDBANK_WITHDRAW/LF_HOUSE_BANK_WITHDRAW
local function updateFunction_GP_ZO_GamepadInventoryList(gpInvVar, list, callbackFunc)
	if isDebugEnabled then dv("[U]updateFunction_GP_ZO_GamepadInventoryList - gpInvVar: %s, list: %s, callbackFunc: %s", tos(gpInvVar), tos(list), tos(callbackFunc)) end
	-- prevent UI errors for lists created OnDeferredInitialization
	if not gpInvVar or not gpInvVar[list] then return end
	local TRIGGER_CALLBACK = true
	gpInvVar[list]:RefreshList(TRIGGER_CALLBACK)
	if callbackFunc then callbackFunc() end
end

-- update for LF_GUILDSTORE_SELL/LF_VENDOR_BUY/LF_VENDOR_BUYBACK/LF_VENDOR_REPAIR/LF_VENDOR_SELL/LF_FENCE_SELL/LF_FENCE_LAUNDER gamepad
local function updateFunction_GP_UpdateList(gpInvVar)
	if isDebugEnabled then dv("[U]updateFunction_GP_UpdateList - gpInvVar: %s", tos(gpInvVar)) end
	-- prevent UI errors for lists created OnDeferredInitialization
	if not gpInvVar then return end
	gpInvVar:UpdateList()
end

-- update function for LF_VENDOR_BUY/LF_VENDOR_BUYBACK/LF_VENDOR_REPAIR/LF_VENDOR_SELL/LF_FENCE_SELL/LF_FENCE_LAUNDER gamepad
local function updateFunction_GP_Vendor(storeMode)
	if isDebugEnabled then dv("[U]updateFunction_GP_Vendor - storeMode: %s", tos(storeMode)) end
	if not store_componentsGP then return end
	updateFunction_GP_UpdateList(store_componentsGP[storeMode].list)
end

-- update for LF_INVENTORY/LF_INVENTORY_COMPANION/LF_INVENTORY_QUEST gamepad
local function updateFunction_GP_ItemList(gpInvVar)
	if isDebugEnabled then dv("[U]updateFunction_GP_ItemList - gpInvVar: %s", tos(gpInvVar)) end
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
	if isDebugEnabled then dv("[U]updateFunction_GP_CraftBagList - gpInvVar: %s", tos(gpInvVar)) end
	if not gpInvVar.craftBagList then return end
	gpInvVar:RefreshCraftBagList()
	gpInvVar:RefreshItemActions()
end

-- update for LF_ENCHANTING_CREATION/LF_ENCHANTING_EXTRACTION gamepad
local function updateFunction_GP_CraftingInventory(craftingInventory)
	if isDebugEnabled then dv("[U]updateFunction_GP_CraftingInventory - craftingInventory: %s", tos(craftingInventory)) end
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
		updateFunction_GP_ZO_GamepadInventoryList(invMailSend_GP, "inventoryList")
	end,
	[LF_TRADE] = function()
		updateFunction_GP_ZO_GamepadInventoryList(invPlayerTrade_GP, "inventoryList")
	end,
	[LF_GUILDSTORE_SELL] = function()
		if isDebugEnabled and invGuildStoreSell_GP == nil then dv("[U]updateFunction LF_GUILDSTORE_SELL: Added reference to GAMEPAD_TRADING_HOUSE_SELL") end
        invGuildStoreSell_GP = invGuildStoreSell_GP or GAMEPAD_TRADING_HOUSE_SELL
		updateFunction_GP_UpdateList(invGuildStoreSell_GP)
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
			updateFunction_GP_ItemList(companionEquipment_GP)
		else
			SafeUpdateList(companionEquipment, nil)
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
			if isDebugEnabled then dv("[U]updateFunction_GP_QUICKSLOT - Not supported yet!") end
	--		SafeUpdateList(quickslots_GP) --TODO quickslots GP are not supported yet
		else
			SafeUpdateList(quickslots)
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
			if guildStoreSellFragment.state ~= SCENE_SHOWN then --"shown"
				store:GetStoreItems()
				SafeUpdateList(store)
			end
		end
	end,
	VENDOR_BUYBACK = function()
		if IsGamepad() then
			updateFunction_GP_Vendor(ZO_MODE_STORE_BUY_BACK)
		else
			SafeUpdateList(vendorBuyBack)
		end
	end,
	VENDOR_REPAIR = function()
		if IsGamepad() then
			updateFunction_GP_Vendor(ZO_MODE_STORE_REPAIR)
		else
			SafeUpdateList(vendorRepair)
		end
	end,
	GUILDSTORE_BROWSE = function()
	--[[
		--Not supported yet
		if IsGamepad() then
		else
		end
	]]
		if isDebugEnabled then dv("[U]updateFunction GUILDSTORE_BROWSE: Not supported yet") end
	end,
	SMITHING_REFINE = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(refinementPanel_GP)
		else
			updateCraftingInventoryDirty(refinementPanel)
		end
	end,
	SMITHING_CREATION = function()
	--[[
		--Not supported yet
		if IsGamepad() then
		else
		end
	]]
		if isDebugEnabled then dv("[U]updateFunction SMITHING_CREATION: Not supported yet") end
	end,
	SMITHING_DECONSTRUCT = function()
		updateCraftingInventoryDirty(getDeconstructOrExtractCraftingVarToUpdate(LF_SMITHING_DECONSTRUCT, nil))
	end,
	SMITHING_IMPROVEMENT = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(improvementPanel_GP)
		else
			updateCraftingInventoryDirty(improvementPanel)
		end
	end,
	SMITHING_RESEARCH = function()
		if IsGamepad() then
			if not researchPanel_GP.researchLineList then return end
			if isDebugEnabled then dv("[U]updateFunction_GP_SMITHING_RESEARCH - SMITHING_GAMEPAD.researchPanel:Refresh() called") end
			researchPanel_GP:Refresh()
		else
			if isDebugEnabled then dv("[U]updateFunction_Keyboard_SMITHING_RESEARCH - SMITHING.researchPanel:Refresh() called") end
			researchPanel:Refresh()
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
			if isDebugEnabled then dv("[U]updateFunction_GP_SMITHING_RESEARCH_DIALOG - GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE:FireCallbacks(StateChange, nil, SCENE_SHOWING) called") end
			researchChooseItemDialog_GP:FireCallbacks("StateChange", nil, SCENE_SHOWING)
		else
			dialogUpdaterFunc(researchChooseItemDialog)
		end
	end,
	ALCHEMY_CREATION = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(alchemy_GP)
		else
			updateCraftingInventoryDirty(alchemy)
		end
	end,
	ENCHANTING = function()
		local isInGamepadMode = IsGamepad()
		local enchantingCraftVarTpUpdate = getDeconstructOrExtractCraftingVarToUpdate(LF_ENCHANTING_EXTRACTION, isInGamepadMode)
		if isInGamepadMode then
			updateFunction_GP_CraftingInventory(enchantingCraftVarTpUpdate)
		else
			updateCraftingInventoryDirty(enchantingCraftVarTpUpdate)
		end
	end,
	PROVISIONING_COOK = function()
	--[[
		--Not supported yet
		if IsGamepad() then
		else
		end
	]]
		if isDebugEnabled then dv("[U]updateFunction PROVISIONING_COOK: Not supported yet") end
	end,
	PROVISIONING_BREW = function()
	--[[
		--Not supported yet
		if IsGamepad() then
		else
		end
	]]
		if isDebugEnabled then dv("[U]updateFunction PROVISIONING_BREW: Not supported yet") end
	end,
	RETRAIT = function()
		if IsGamepad() then
			if isDebugEnabled then dv("[U]updateFunction_GP_RETRAIT: ZO_RETRAIT_STATION_RETRAIT_GAMEPAD:Refresh() called") end
			retrait_GP:Refresh() -- ZO_RETRAIT_STATION_RETRAIT_GAMEPAD
		else
			updateCraftingInventoryDirty(retrait)
		end
	end,
	RECONSTRUCTION = function()
		if IsGamepad() then
			if isDebugEnabled then dv("[U]updateFunction_GP_RECONSTRUCTION: ZO_RETRAIT_STATION_RECONSTRUCT_GAMEPAD:RefreshFocusItems() called") end
			-- not sure how reconstruct works, how it would be filtered.
			reconstruct_GP:RefreshFocusItems() -- ZO_RETRAIT_STATION_RECONSTRUCT_GAMEPAD
		else
			updateCraftingInventoryDirty(reconstruct)
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
local universalDeconHookApplied         = false
local wasUniversalDeconPanelShownBefore = false
local wasUniversalDeconPanelGPEventCraftingBeginUsed 	= false
local updateCurrentAndLastUniversalDeconVariables


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


		function libFilters_getUniversalDeconstructionPanelActiveTabFilterType(filterPanelIdComingFrom)
			local isGamepadMode = IsGamepad()
			libFilters_IsUniversalDeconstructionPanelShown = libFilters_IsUniversalDeconstructionPanelShown or libFilters.IsUniversalDeconstructionPanelShown
			local isShowingUniversalDeconScene, universaldDeconScene = libFilters_IsUniversalDeconstructionPanelShown()
			if isDebugEnabled then dv("|UD> GetUniversalDeconstructionPanelActiveTabFilterType - filterPanelId: %s", tos(filterPanelIdComingFrom) ) end
			if isShowingUniversalDeconScene and universaldDeconScene ~= nil then
				local universalDeconSelectedTab
				local universalDeconSelectedTabKey
				--if filterPanelIdComingFrom == nil then
					local universaldDeconPanel = (isGamepadMode == true and universalDeconstructPanel_GP) or universalDeconstructPanel
					universalDeconSelectedTab = universaldDeconPanel.inventory:GetCurrentFilter()
					if not universalDeconSelectedTab then return false end
					universalDeconSelectedTabKey = universalDeconSelectedTab.key
					filterPanelIdComingFrom = detectUniversalDeconstructionPanelActiveTab(nil, universalDeconSelectedTabKey)
					if isDebugEnabled then dv(">universalDeconTab.key: %s", tos(universalDeconSelectedTabKey)) end
				--end
				--Check if filterPanelId detected is a valid filterType for the UniversalDeconstruction tab
				if universalDeconLibFiltersFilterTypeSupported[filterPanelIdComingFrom] == true then
					if isDebugEnabled then dv("<filterPanelIdComingFrom now: %q", tos(filterPanelIdComingFrom)) end
--d("<returned: " ..tos(filterPanelIdComingFrom))
					return filterPanelIdComingFrom, universalDeconSelectedTabKey
				end
			end
			return nil, nil
		end
		libFilters.GetUniversalDeconstructionPanelActiveTabFilterType = libFilters_getUniversalDeconstructionPanelActiveTabFilterType


		function updateCurrentAndLastUniversalDeconVariables(tab, doReset)
			doReset = doReset or false
			local lastFilterTypeUniversalDeconTab
			local currentFilterTypeUniversalDeconTab = libFilters._currentFilterTypeUniversalDeconTab
			--Any tab was shown before: following calls to UniversalDecon panel's OnFilterChanged function
			if wasUniversalDeconPanelShownBefore == true then
				local currentFilterTypeUniversalDeconTabCopy = currentFilterTypeUniversalDeconTab
				lastFilterTypeUniversalDeconTab = currentFilterTypeUniversalDeconTabCopy
				libFilters._lastFilterTypeUniversalDeconTab = lastFilterTypeUniversalDeconTab
			end
			if doReset == true then
				libFilters._currentFilterTypeUniversalDeconTab = nil
			else
				libFilters._currentFilterTypeUniversalDeconTab = tab.key
			end

			if isDebugEnabled then dd("|UD> updateCurrentAndLastUniversalDeconVariables - doReset: %s, tab: %q, lastTab: %s",
					tos(doReset), tos(libFilters._currentFilterTypeUniversalDeconTab), tos(lastFilterTypeUniversalDeconTab)) end
		end

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
			if isDebugEnabled then dd("|UD> universalDeconOnFilterChangedCallback - tab: %q, lastTab: %q, filterType: %s, lastFilterType: %s",
					tos(currentTab), tos(lastTab), tos(libFiltersFilterType), tos(filterTypeBefore)) end
			if libFiltersFilterType == nil then return end
			--Set the .LibFilters3_filterType at the UNIVERSAL_DECONSTRUCTION(_GAMEPAD) table
			universalDeconstructPanel = universalDeconstructPanel or kbc.universalDeconstructPanel
			universalDeconstructPanel_GP = universalDeconstructPanel_GP or gpc.universalDeconstructPanel_GP
			local base = universalDeconFilterTypeToFilterBase[libFiltersFilterType]
			base[defaultLibFiltersAttributeToStoreTheFilterType] = libFiltersFilterType

			--Raise the callbacks
			libFilters_CallbackRaise = libFilters_CallbackRaise or libFilters.CallbackRaise
			--Hide old panel
			local isInGamepadMode = IsGamepad()
			local universalDeconRefVar = (isInGamepadMode and universalDeconstructPanel_GP) or universalDeconstructPanel
			local universalDeconDataHideCurrentTab = {
				isShown = true, --This tells the called functions that the universal deconstruction panel is currently shown, generally!
				lastTab = lastTab,
				currentTab = currentTab,
				wasShownBefore = wasUniversalDeconPanelShownBefore
			}
			--If the UniversalDecon panel was shown before (in keyboard mode!) the hidden state needs to be called for the current shown tab first
			-->2022-10-30: GAMEPAD: Universald Decon tab changes won't work properly anymore if removed so added a boolean to EVENT_CRAFTING_TABLE_INTERACT
			--and if it's called the 2nd time skip the onControlHiddenStateChange(false) at gamepad mode here ONCE until next EVENT_CRAFTING_TABLE_INTERACT
			--was called
			if wasUniversalDeconPanelShownBefore == true
					and (not isInGamepadMode or (isInGamepadMode and not wasUniversalDeconPanelGPEventCraftingBeginUsed) ) then
				onControlHiddenStateChange(false, { filterTypeBefore }, universalDeconRefVar, isInGamepadMode, nil, universalDeconDataHideCurrentTab)
			end
			--reset the prevention variable (set at EVENT_CRAFTING_TABLE_INTERACT) so next tab change in gamepad mode fires the callbacks properly again
			if isInGamepadMode == true and wasUniversalDeconPanelGPEventCraftingBeginUsed == true then
				wasUniversalDeconPanelGPEventCraftingBeginUsed = false
			end
			--Show new panel
			local universalDeconDataShowNewTab = {
				isShown = true, --This tells the called functions that the universal deconstruction panel is currently shown, generally!
				lastTab = lastTab,
				currentTab = currentTab,
				wasShownBefore = wasUniversalDeconPanelShownBefore
			}
			onControlHiddenStateChange(true, { libFiltersFilterType }, universalDeconRefVar, isInGamepadMode, nil, universalDeconDataShowNewTab)
			wasUniversalDeconPanelShownBefore = true
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
			if isDebugEnabled then dd("|UD> universalDeconstructPanel OnEffectivelyShown-wasUniversalDeconControlShownOnce: %s", tos(wasUniversalDeconControlShownOnce)) end
			if not wasUniversalDeconControlShownOnce then
				wasUniversalDeconControlShownOnce = true
				return
			end
			--Update the last shown UniversalDecon tab and filterType
			updateCurrentAndLastUniversalDeconVariables(universalDeconstructPanel.inventory:GetCurrentFilter(), false)
			onControlHiddenStateChange(true, filterTypesOfUniversalDecon, ctrlRef, false, nil)
		end)

		--Needed? 2022-10-29 -- See bugs #2
		--[[
		local wasUniversalDeconGPControlShownOnce = false
		local filterTypesOfUniversalDecon_GP = callbacks.usingSpecials[true][universalDeconstructPanel_GP]
		--createControlCallback(universalDeconstructPanel_GP.control, filterTypesOfUniversalDecon_GP, true, nil)
		ZO_PostHookHandler(universalDeconstructPanel_GP.control, "OnEffectivelyShown", function(ctrlRef)
			if not libFilters.isInitialized then return end
			if isDebugEnabled then dd("universalDeconstructPanel GAMEPAD OnEffectivelyShown-wasUniversalDeconControlShownOnce: %s", tos(wasUniversalDeconGPControlShownOnce)) end
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
					if isDebugEnabled then dd("|UD> [UNIVERSAL DECON Keyboard SCENE HIDDEN]") end
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
					if isDebugEnabled then dd("|UD> [UNIVERSAL DECON Gamepad SCENE HIDDEN]") end
					universalDeconOnFilterChangedCallback(universalDeconstructPanel_GP.inventory:GetCurrentFilter(), nil, nil)

					--Update the current -> last universal decon tab so closing the next "normal" non-universal crafting table wont tell us we are
					--closing universal decon again, because libFilters._currentFilterTypeUniversalDeconTab is still ~= nil!
					updateCurrentAndLastUniversalDeconVariables(nil, true) --reset  libFilters._currentFilterTypeUniversalDeconTab
				end
			end)

		universalDeconHookApplied = true
	end
end


--Hook the different inventory panels (LibFilters filterTypes) now and add the .additionalFilter entry to each panel's
--control/scene/fragment/...
local function applyAdditionalFilterHooks()
	if isDebugEnabled then dd("---ApplyAdditionalFilterHooks---") end

	--Universal deconstruction -> Special, as it re-used LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT and LF_ENCHANTING_EXTRACT
	applyUniversalDeconstructionHook()

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


--Returns number the maximum possible filterType
function libFilters:GetMaxFilterType()
	 return LF_FILTER_MAX
end
--Compatibility function names
libFilters.GetMaxFilter = libFilters.GetMaxFilterType


--Set the state of the LF_FILTER_ALL "fallback" filter possibilities.
--If boolean newState is enabled: function runFilters will also check for LF_FILTER_ALL filter functions and run them:
--If the filterType passed to runfilters function got no registered filterTags with filterFunctions, the LF_FILTER_ALL "fallback" will be checked (if existing and enabled via this API function) and be run!
--If boolean newState is disabled: function runFilters will NOT use LF_FILTER_ALL fallback functions
function libFilters:SetFilterAllState(newState)
	if newState == nil or type(newState) ~= "boolean" then
		dfe("Invalid call to SetFilterAllState(%q).\n>Needed format is: boolean newState",
			tos(newState))
		return
	end
	if isDebugEnabled then dd("SetFilterAllState-%s", tos(newState)) end
	libFilters.useFilterAllFallback = newState
end


--Returns table LibFilters LF* filterType connstants table { [1] = "LF_INVENTORY", [2] = "LF_BANK_WITHDRAW", ... }
--See file constants.lua, table "libFiltersFilterConstants"
function libFilters:GetFilterTypes()
	 return libFiltersFilterConstants
end


--Returns String LibFilters LF* filterType constant's name for the number filterType
function libFilters:GetFilterTypeName(filterType)
	if not filterType then
		dfe("Invalid argument to GetFilterTypeName(%q).\n>Needed format is: number LibFiltersLF_*FilterType",
			tos(filterType))
		return
	end
	if isDebugEnabled then dv("GetFilterTypeName - filterType: %q", tos(filterType)) end
	return libFiltersFilterConstants[filterType] or ""
end
libFilters_GetFilterTypeName = libFilters.GetFilterTypeName


--Returns number typeOfFilterFunction used for the number LibFilters LF* filterType constant.
--Either LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT or LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX
--or nil if error occured or no filter function type was determined
-- returns number filterFunctionType
function libFilters:GetFilterTypeFunctionType(filterType)
	if not filterType then
		dfe("Invalid argument to GetFilterTypeFunctionType(%q).\n>Needed format is: number LibFiltersLF_*FilterType",
			tos(filterType))
		return
	end
	if isDebugEnabled then dd("GetFilterTypeFunctionType-%q", tos(filterType)) end
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
	if not inventoryType then
		dfe("Invalid arguments to GetCurrentFilterTypeForInventory(%q).\n>Needed format is: inventoryTypeNumber(e.g. INVENTORY_BACKPACK)/userdata/table/scene/control inventoryType",
				tos(inventoryType))
		return
	end
	noRefUpdate = noRefUpdate or false
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
	--[[
	--Was the filterType referenceVariableTable updated at calling function already?
	if not noRefUpdate and filterTypeDetected ~= nil then
		local currentFilterTypeReferences = libFilters_GetFilterTypeReferences(libFilters, filterTypeDetected)
		--updateLastAndCurrentFilterType(filterTypeDetected, currentFilterTypeReferences, false)
	end
	]]

	if isDebugEnabled then dd("GetCurrentFilterTypeForInventory-%q: %s, error: %s", tos(inventoryType), tos(filterTypeDetected), tos(errorAppeared)) end
	return filterTypeDetected
end
libFilters_GetCurrentFilterTypeForInventory = libFilters.GetCurrentFilterTypeForInventory


-- Get the actually used filterType via the shown control/scene/userdata information
-- returns number LF*_filterType
--		   String universalDeconSelectedTabKey e.g. "all", "weapons", "armor", "jewelry", "enchantments" if the universal deconstruction panel is currently active
-->		 (which re-usess LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT and LF_ENCHANTING_EXTRACT)
function libFilters:GetCurrentFilterType()
	local filterTypeReference, filterType, universalDeconSelectedTabKey = libFilters_GetCurrentFilterTypeReference(libFilters, nil, nil)
	if isDebugEnabled then dd("GetCurrentFilterType-filterReference: %s, filterTypeDetected: %s, universalDeconTabKey: %s", tos(filterTypeReference), tos(filterType), tos(universalDeconSelectedTabKey)) end
	if filterTypeReference == nil then return end

	--updateLastAndCurrentFilterType(nil, filterTypeReference, false)

	local currentFilterType = filterType
	--FilterType was not detected yet (e.g. from cached filterType currently shown)
	if currentFilterType == nil and universalDeconSelectedTabKey == nil then
		--Check each shown variable for the LibFilters filterType LF_* constant
		for _, shownVariable in ipairs(filterTypeReference) do
			--Do not update the references to libFilters._currentFilterTypeReferences as it was done above already
			currentFilterType = libFilters_GetCurrentFilterTypeForInventory(libFilters, shownVariable, true)
			if currentFilterType ~= nil then
				if isDebugEnabled then dd(">filterTypeDetected updated to: %s", tos(currentFilterType)) end
				return currentFilterType
			end
		end
	end
	return currentFilterType, universalDeconSelectedTabKey
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
	if isDebugEnabled then dd("GetFilterTypeRespectingCraftType-source: %q, target: %q, craftType: %s", tos(filterTypeSource), tos(filterTypeMappedByCraftingType), tos(craftType)) end
	return filterTypeMappedByCraftingType
end


--**********************************************************************************************************************
-- Filter check and un/register
--**********************************************************************************************************************
--Check if a filterFunction at the String filterTag and OPTIONAL number filterType is already registered
--Returns boolean true if registered already, false if not
function libFilters:IsFilterRegistered(filterTag, filterType)
	if not filterTag then
		dfe("Invalid arguments to IsFilterRegistered(%q, %s).\n>Needed format is: String uniqueFilterTag, OPTIONAL number LibFiltersLF_*FilterType",
			tos(filterTag), tos(filterType))
		return
	end
	if isDebugEnabled then dd("IsFilterRegistered-%q,%s", tos(filterTag), tos(filterType)) end
	if filterType == nil then
		--check whether there's any filter with this tag
		for _, filterCallbacks in pairs(filters) do
			if filterCallbacks[filterTag] ~= nil then
				return true
			end
		end
		return false
	else
		--check only the specified filter type
		local filterCallbacks = filters[filterType]
		return filterCallbacks[filterTag] ~= nil
	end
end
local libFilters_IsFilterRegistered = libFilters.IsFilterRegistered


--Check if the LF_FILTER_ALL filterFunction at the String filterTag is already registered
--Returns boolean true if registered already, false if not
function libFilters:IsAllFilterRegistered(filterTag)
	if not filterTag then
		dfe("Invalid arguments to IsAllFilterRegistered(%q).\n>Needed format is: String uniqueFilterTag",
			tos(filterTag))
		return
	end
	if isDebugEnabled then dd("IsAllFilterRegistered-%q", tos(filterTag)) end
	local filterCallbacks = filters[LF_FILTER_ALL]
	return filterCallbacks[filterTag] ~= nil
end


local filterTagPatternErrorStr = "Invalid arguments to %s(%q, %s, %s).\n>Needed format is: String uniqueFilterTagLUAPattern, OPTIONAL number LibFiltersLF_*FilterType, OPTIONAL boolean compareToLowerCase"
--Check if a filter function at the String filterTagPattern (uses LUA regex pattern!) and number filterType is already registered.
--Can be used to detect if any addon's tags have registered filters.
--OPTIONAL parameter boolean compareToLowerCase: If true the string comparison will be done with a lowerCase filterTag. The pattern will not be changed! Default: false
--Returns boolean true if registered already, false if not
function libFilters:IsFilterTagPatternRegistered(filterTagPattern, filterType, compareToLowerCase)
	if not filterTagPattern then
		dfe(filterTagPatternErrorStr,
			"IsFilterTagPatternRegistered", tos(filterTagPattern), tos(filterType), tos(compareToLowerCase))
		return
	end
	compareToLowerCase = compareToLowerCase or false
	if isDebugEnabled then dd("IsFilterTagPatternRegistered-%q,%s,%s", tos(filterTagPattern), tos(filterType), tos(compareToLowerCase)) end
	if filterType == nil then
		--check whether there's any filter with this tag's pattern
		for _, filterCallbacks in pairs(filters) do
			for filterTag, _ in pairs(filterCallbacks) do
				local filterTagToCompare = (compareToLowerCase ~= nil and compareToLowerCase == true and filterTag:lower()) or filterTag
				if strmat(filterTagToCompare, filterTagPattern) ~= nil then
					return true
				end
			end
		end
	else
	--check only the specified filter type
		local filterCallbacks = filters[filterType]
		for filterTag, _ in pairs(filterCallbacks) do
			local filterTagToCompare = (compareToLowerCase ~= nil and compareToLowerCase == true and filterTag:lower()) or filterTag
			if strmat(filterTagToCompare, filterTagPattern) ~= nil then
				return true
			end
		end
	end
	return false
end


local registerFilterParametersErrorStr = "Invalid arguments to %s(%q, %q, %q, %s).\n>Needed format is: String uniqueFilterTag, number LibFiltersLF_*FilterType, function filterCallbackFunction(inventorySlot_Or_BagIdAtCraftingTables, OPTIONAL slotIndexAtCraftingTables), OPTIONAL boolean noInUseError)"
--Register a filter function at the String filterTag and number filterType.
--If filterType LF_FILTER_ALL is used this filterFunction will be used for all available filterTypes of the filterTag, where no other filterFunction was explicitly registered
--(as a kind of "fallback filter function").
--Registering a filter function does NOT automatically call the refresh/update function at the panel!
--You manually need to handle the update via libFilters:RequestUpdate(filterType) where needed
--Parameter boolean noInUseError: if set to true there will be no error message if the filterTag+filterType was registered already -> Silent fail. Return value will be false then!
--Returns true if filter function was registered, else nil in case of parameter errors, or false if same tag+type was already registered
function libFilters:RegisterFilter(filterTag, filterType, filterCallback, noInUseError)
	local filterCallbacks = filters[filterType]
	if not filterTag or not filterType or not filterCallbacks or type(filterCallback) ~= "function" then
		dfe(registerFilterParametersErrorStr, "RegisterFilter", tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError))
		return
	end
	noInUseError = noInUseError or false
	if isDebugEnabled then dd("RegisterFilter-%q,%q,%q,%s", tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError)) end
	if filterCallbacks[filterTag] ~= nil then
		if not noInUseError then
			dfe("FilterTag \'%q\' filterType \'%q\' filterCallback function is already in use.\nPlease check via \'LibFilters:IsFilterRegistered(filterTag, filterType)\' before registering filters!",
					tos(filterTag), tos(filterType))
		end
		return false
	end
	filterCallbacks[filterTag] = filterCallback
	return true
end
local libFilters_RegisterFilter = libFilters.RegisterFilter


--Check if a filter function at the String filterTag and number filterType is already registered, and if not: Register it. If it was already registered the return value will be false
--Registering a filter function does NOT automatically call the refresh/update function at the panel!
--You manually need to handle the update via libFilters:RequestUpdate(filterType) where needed
--Parameter boolean noInUseError: if set to true there will be no error message if the filterTag+filterType was registered already -> Silent fail. Return value will be false then!
--Returns true if filter function was registered, else nil in case of parameter errors, or false if same tag+type was already registered
function libFilters:RegisterFilterIfUnregistered(filterTag, filterType, filterCallback, noInUseError)
	local filterCallbacks = filters[filterType]
	if not filterTag or not filterType or not filterCallbacks or type(filterCallback) ~= "function" then
		dfe(registerFilterParametersErrorStr, "RegisterFilterIfUnregistered",
				tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError))
		return
	end
	if isDebugEnabled then dd("RegisterFilterIfUnregistered-%q,%q,%q,%s", tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError)) end
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
	if not filterTag or filterTag == "" then
		dfe("Invalid arguments to UnregisterFilter(%q, %s).\n>Needed format is: String filterTag, OPTIONAL number LibFiltersLF_*FilterType",
			tos(filterTag), tos(filterType))
		return
	end
	if isDebugEnabled then dd("UnregisterFilter-%q,%s", tos(filterTag), tos(filterType)) end
	if filterType == nil then
		--unregister all filters with this tag
		local unregisteredFilterFunctions = 0
		for _, filterCallbacks in pairs(filters) do
			if filterCallbacks[filterTag] ~= nil then
				filterCallbacks[filterTag] = nil
				unregisteredFilterFunctions = unregisteredFilterFunctions + 1
			end
		end
		if unregisteredFilterFunctions > 0 then
			return true
		end
	else
		--unregister only the specified filter type
		local filterCallbacks = filters[filterType]
		if filterCallbacks[filterTag] ~= nil then
			filterCallbacks[filterTag] = nil
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
	if not filterTag or not filterType then
		dfe("Invalid arguments to GetFilterCallback(%q, %q).\n>Needed format is: String uniqueFilterTag, number LibFiltersLF_*FilterType",
			tos(filterTag), tos(filterType))
		return
	end
	if isDebugEnabled then dd("GetFilterCallback-%q,%q", tos(filterTag), tos(filterType)) end
	if not libFilters_IsFilterRegistered(libFilters, filterTag, filterType) then return end
	return filters[filterType][filterTag]
end


--Get all callback function of the number filterType (of all addons which registered a filter)
--Returns nilable:table { 	[filterType_e.g._LF_INVENTORY] = { [filterTag1] = filterFunction1, [filterTag2] = filterFunction2, ... },
--				  			[filterType_e.g._LF_BANK_WITHDRAW] = { [filterTag3] = filterFunction3, [filterTag4] = filterFunction4, ... }, ... }
function libFilters:GetFilterTypeCallbacks(filterType)
	if not filterType then
		dfe("Invalid arguments to GetFilterTypeCallbacks(%q).\n>Needed format is: number LibFiltersLF_*FilterType",
			tos(filterType))
		return
	end
	if isDebugEnabled then dd("GetFilterTypeCallbacks-%q", tos(filterType)) end
	return filters[filterType]
end


--Get all callback functions of the String filterTag (e.g. all registered functions of one special addon) and OPTIONAL number filterType
--OPTIONAL parameter boolean compareToLowerCase: If true the string comparison will be done with a lowerCase filterTag. Default: false
--Returns nilable:table { 	[filterType_e.g._LF_INVENTORY] = { [filterTag1] = filterFunction1, [filterTag2] = filterFunction2, ... },
--				  			[filterType_e.g._LF_BANK_WITHDRAW] = { [filterTag3] = filterFunction3, [filterTag4] = filterFunction4, ... }, ... }
function libFilters:GetFilterTagCallbacks(filterTag, filterType, compareToLowerCase)
	if not filterTag then
		dfe("Invalid arguments to GetFilterTagCallbacks(%q, %s, %s).\n>Needed format is: String uniqueFilterTag, OPTIONAL number LibFiltersLF_*FilterType, OPTIONAL boolean compareToLowerCase",
			tos(filterTag), tos(filterType), tos(compareToLowerCase))
		return
	end
	if isDebugEnabled then dd("GetFilterTagCallbacks-%q,%s,%s", tos(filterTag), tos(filterType), tos(compareToLowerCase)) end
	compareToLowerCase = compareToLowerCase or false
	local retTab
	local filterTagToCompare = (compareToLowerCase == true and filterTag:lower()) or filterTag
	if filterType == nil then
		--check whether there's any filter with this tag's pattern
		for lFilterType, filterCallbacks in pairs(filters) do
			for lFilterTag, filterFunction in pairs(filterCallbacks) do
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
		local filterCallbacks = filters[filterType]
		for lFilterTag, filterFunction in pairs(filterCallbacks) do
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
	if not filterTagPattern then
		dfe(filterTagPatternErrorStr,
			"GetFilterTagPatternCallbacks", tos(filterTagPattern), tos(filterType), tos(compareToLowerCase))
		return
	end
	if isDebugEnabled then dd("GetFilterTagPatternCallbacks-%q,%s,%s", tos(filterTagPattern), tos(filterType), tos(compareToLowerCase)) end
	compareToLowerCase = compareToLowerCase or false
	local retTab
	if filterType == nil then
		--check whether there's any filter with this tag's pattern
		for lFilterType, filterCallbacks in pairs(filters) do
			for filterTag, filterFunction in pairs(filterCallbacks) do
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
		local filterCallbacks = filters[filterType]
		for filterTag, filterFunction in pairs(filterCallbacks) do
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
	if not updaterName or updaterName == "" then
		dfe("Invalid arguments to RequestUpdateByName(%q).\n>Needed format is: String updaterName",
			tos(updaterName))
		return
	end
	if isDebugEnabled then dv("[U-API]RequestUpdateByName-%q,%s,%s", tos(updaterName), tos(delay), tos(filterType)) end

	--Try to get the filterType, if not provided yet
	if filterType == nil then
		local filterTypesTable = updaterNameToFilterType[updaterName]
		local countFilterTypesWithUpdaterName = (filterTypesTable and #filterTypesTable) or 0
		if countFilterTypesWithUpdaterName > 1 then
			if countFilterTypesWithUpdaterName > 2 then
				--Should not happen? Always take the 1st entry then as fallback
				filterType = filterTypesTable[1]
			else
				--Which filterType is the correct one for the updater name?
				--If there are 2 filterTypes it should be LF_SMITHING_ and LF_JEWELRY_, so the filterType should be
				--detectable by help of the current CraftingInteractionType?
				local craftingType = gcit()
				for _, filterTypeLoop in ipairs(filterTypesTable) do
					if filterType ~= nil then
						filterType = getFilterTypeByFilterTypeRespectingCraftType(filterTypeLoop, craftingType)
					end
				end
				if filterType == nil then
					--Should not happen? Always take the 1st entry then as fallback
					filterType = filterTypesTable[1]
				end
			end
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
			if delay < 0 then delay = 0 end
		end
	else
		delay = defaultFilterUpdaterDelay --default value: 10ms
	end
	if isDebugEnabled then dv(">callbackName: %s, delay: %s", tos(callbackName), tos(delay)) end

	local function updateFiltersNow()
		EM:UnregisterForUpdate(callbackName)
		if isDebugEnabled then dv("!!!RequestUpdateByName->Update called now, updaterName: %s, filterType: %s, delay: %s", tos(updaterName), tos(filterType), tos(delay)) end

		--Update the cashed filterType and it's references
		--local currentFilterTypeReferences = libFilters_GetFilterTypeReferences(libFilters, filterType, nil)
		--updateLastAndCurrentFilterType(filterType, currentFilterTypeReferences)

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
	if not filterType or not updaterName or updaterName == "" then
		dfe("Invalid arguments to RequestUpdate(%q).\n>Needed format is: number LibFiltersLF_*FilterType",
			tos(filterType))
		return
	end
	if isDebugEnabled then dd("[U-API]RequestUpdate filterType: %q, updaterName: %s, delay: %s", tos(filterType), tos(updaterName), tos(delay)) end
	libFilters_RequestUpdateByName(libFilters, updaterName, delay, filterType)
end


--Update the normal filters (LF_SMITHING_RESEARCH / LF_JEWELRY_RESEARCH) and the horizontal scrollbar filters
-- (fromResearcLineIndex, toResearchLineIndex, skipTable) for the crafting researchPanel
--OPTIONAL parameter number delay will add a delay to the call of the updater function
function libFilters:RequestUpdateForResearchFilters(delay)
	local updaterName = "SMITHING_RESEARCH"
	if isDebugEnabled then dd("[U-API]RequestUpdateForResearchFilters delay: %s", tos(delay)) end
	libFilters_RequestUpdateByName(libFilters, updaterName, delay, getFilterTypeByFilterTypeRespectingCraftType(LF_SMITHING_RESEARCH, gcit()))
end
local libFilters_RequestUpdateForResearchFilters = libFilters.RequestUpdateForResearchFilters


-- Get the updater name of a number filterType
-- returns String updateName
function libFilters:GetFilterTypeUpdaterName(filterType)
	if not filterType then
		dfe("Invalid arguments to GetFilterTypeUpdaterName(%q).\n>Needed format is: number LibFiltersLF_*FilterType",
			tos(filterType))
		return
	end
	if isDebugEnabled then dd("GetFilterTypeUpdaterName filterType: %q", tos(filterType)) end
	return filterTypeToUpdaterName[filterType] or ""
end


-- Get the updater filterTypes of a String updaterName
-- returns nilable:table filterTypesOfUpdaterName { [1] = LF_INVENTORY, [2] = LF_..., [3] = ... }
function libFilters:GetUpdaterNameFilterType(updaterName)
	if updaterName == nil or updaterName == "" then
		dfe("Invalid call to GetUpdaterNameFilterType(%q).\n>Needed format is: String updaterName",
			tos(updaterName))
		return
	end
	if isDebugEnabled then dd("GetUpdaterNameFilterType updaterName: %q", tos(updaterName)) end
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
	if updaterName == nil or updaterName == "" then
		dfe("Invalid call to GetUpdaterCallback(%q).\n>Needed format is: String updaterName",
			tos(updaterName))
		return
	end
	if isDebugEnabled then dd("GetUpdaterCallback updaterName: %q", tos(updaterName)) end
	return inventoryUpdaters[updaterName]
end


-- Get the updater function used for updating/refresh of the inventories etc., by help of a number filterType
-- returns nilable:function updaterFunction(OPTIONAL filterType)
function libFilters:GetFilterTypeUpdaterCallback(filterType)
	if filterType == nil then
		dfe("Invalid call to GetFilterTypeUpdaterCallback(%q).\n>Needed format is: number LibFiltersLF_*FilterType",
				tos(filterType))
		return
	end
	if isDebugEnabled then dd("GetFilterTypeUpdaterCallback filterType: %q", tos(filterType)) end
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

local function getFilterTypeReference(filterType, isInGamepadMode)
	local refVars = LF_FilterTypesToReferenceImplementedSpecial[isInGamepadMode][filterType]
	if refVars == nil then
		if isInGamepadMode == true then
			local gamepadFallbackToKeyboardRef = LF_FilterTypeToReferenceGamepadFallbackToKeyboard[filterType]
			if not gamepadFallbackToKeyboardRef then
				--use keyboard ref vars
				refVars = LF_FilterTypeToReference[false][filterType]
			else
				refVars = LF_FilterTypeToReference[true][filterType]
			end
		else
			refVars = LF_FilterTypeToReference[false][filterType]
		end
	end
	return refVars
end

-- Get reference (inventory, layoutData, scene, fragment, control, etc.) where the number filterType was assigned to, and
--it's filterFunction was added to the constant "defaultOriginalFilterAttributeAtLayoutData" (.additionalFilter)
-- returns table referenceVariablesOfLF_*filterType { [NumericalNonGapIndex e.g.1] = inventory/layoutData/scene/control/userdata/etc., [2] = inventory/layoutData/scene/control/userdata/etc., ... }
--If the filterType passed in is a UniversalDeconstruction supported one, 2nd return parameter "universalDeconRef" will be a table with the reference varable to the UniversalDeconstruction panel
function libFilters:GetFilterTypeReferences(filterType, isInGamepadMode)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	if not filterType or filterType == "" then
		dfe("Invalid arguments to GetFilterTypeReferences(%q, %s).\n>Needed format is: number LibFiltersLF_*FilterType, OPTIONAL boolean isInGamepadMode",
				tos(filterType), tos(isInGamepadMode))
		return
	end
	if isDebugEnabled then dd("GetFilterTypeReferences filterType: %q, %s", tos(filterType), tos(isInGamepadMode)) end
	local filterReferences = getFilterTypeReference(filterType, isInGamepadMode)
	--if the filterType passed in is a UniversalDeconstruction supported one, return the reference for it too as 2nd return parameter.
	local universalDeconRef
	if universalDeconLibFiltersFilterTypeSupported[filterType] == true then
		universalDeconRef = (isInGamepadMode == true and universalDeconstructPanel_GP.control) or universalDeconstructPanel.control
	end
	return filterReferences, universalDeconRef
end
libFilters_GetFilterTypeReferences = libFilters.GetFilterTypeReferences


-- Get the actually shown reference control/scene/userdata/inventory number e.g. INVENTORY_BACKPACK information which is relevant for a libFilters LF_* filterType.
-- OPTIONAL parameter number filterType: If provided it will be used to determine the reference control/etc. directly via table LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[isInGamepadMode]
-- OPTIONAL parameter boolean isInGamepadMode: Check with gamepad mode or keyboard. Leave empty to let it be determined automatically
-- returns table currentlyShownReferenceVariablesOfLF_*filterType { [1] = control/scene/userdata/inventory number, [2] = control/scene/userdata/inventory number, ... },
--		   number filterType
--		   nilable:String universalDeconSelectedTabKey
function libFilters:GetCurrentFilterTypeReference(filterType, isInGamepadMode)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	if isDebugEnabled then dd("[---] GetCurrentFilterTypeReference filterType: %q, %s [---]", tos(filterType), tos(isInGamepadMode)) end

	--Check if the cached "current filterType" is given and still shown -> Only if no filterType was explicitly passed in
	if filterType == nil then
		local filterTypeReference, filterTypeShown, universalDeconSelectedTabKey = checkIfCachedFilterTypeIsStillShown(isInGamepadMode)
		if filterTypeReference ~= nil and filterTypeShown ~= nil then
			return filterTypeReference, filterTypeShown, universalDeconSelectedTabKey
		end
	end
	return detectShownReferenceNow(filterType, isInGamepadMode, false, false)
end
libFilters_GetCurrentFilterTypeReference = libFilters.GetCurrentFilterTypeReference


--**********************************************************************************************************************
-- API to check if controls/scenes/fragments/userdata/inventories are shown
--**********************************************************************************************************************

local function isInventoryBaseShown(isInGamepadMode)
	--[[
	return isSceneFragmentShown(LF_INVENTORY, true, true, false)
			and isSceneFragmentShown(LF_INVENTORY, true, false, false)
			and not ZO_GamepadInventoryTopLevel:IsHidden()
	]]
	local resultVar = false
	local lReferencesToFilterType, lFilterTypeDetected = detectShownReferenceNow(LF_INVENTORY, isInGamepadMode, false, true)
	if lReferencesToFilterType ~= nil and lFilterTypeDetected == LF_INVENTORY then
		--Check if the CraftBag is shown, and exclude it, as it will use the same fragment GAMEPAD_INVENTORY_FRAGMENT as the normal inventory
		if libFilters_IsCraftBagShown(libFilters) then
			resultVar = false
		else
			resultVar = true
		end
	end
	if isDebugEnabled then dv(">isInventoryBaseShown: %s", tos(resultVar)) end
	return resultVar
end


--Is the inventory control shown
--returns boolean isShown
--		  NILABLE control gamepadList (category or item list of the gamepad inventory, which is currently shown)
function libFilters:IsInventoryShown()
	local isInvShown = false
	local listShownGP
	local isCategoryListShown = false
	local isItemListShown = false
	local abortNow = false
	if IsGamepad() then
		if isInventoryBaseShown(true) == true then
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
					isInvShown = false
					abortNow = true
				end

			--Items list is shown (2nd level with single items, e.g. 2hd weapons, light armor, ...)
			elseif isItemListShown then
				if (selectedGPInvFilter ~= nil and gamepadInventoryNonSupportedFilters[selectedGPInvFilter])
					or (selectedGPInvFilter == nil and selectedItemUniqueId == nil) then --or selectedGPInvEquipmentSlot ~= nil
					isInvShown = false
					abortNow = true
				end

			end
			if not abortNow then
				isInvShown = true
			end
		end
	else
		--isInvShown = not playerInvCtrl:IsHidden()
		isInvShown, listShownGP = isInventoryBaseShown(false), nil
	end
	if isDebugEnabled then dd("IsInventoryShown: %s", tos(isInvShown)) end
	return isInvShown, listShownGP
end


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
		if isInventoryBaseShown() == true then
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
			local isStoreCtrlShown, storeCtrl, _ = checkIfStoreCtrlOrFragmentShown(nil, currentStoreMode)
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
	if isDebugEnabled then
		dd("IsListDialogShown-filterType: %q, craftType: %s, dialogOwnerControl: %s", --filterTypeMapped: %q
				tos(filterType), tos(craftType), tos(dialogOwnerControlToCheck)) --tos(filterTypeMappedByCraftingType)
	end
	if dialogOwnerControlToCheck == nil then return false end
	return isListDialogShown(dialogOwnerControlToCheck)
end
local libFilters_IsListDialogShown = libFilters.IsListDialogShown


--Is the retrait station curently shown
--returns boolean isRetraitStation
function libFilters:IsRetraitStationShown()
	return ZO_RETRAIT_STATION_MANAGER:IsRetraitSceneShowing()
end


--Is any crafting  station curently shown
--OPTIONAL parameter number craftType: If provided the craftType must be active
--returns boolean isCraftingStationShown
function libFilters:IsCraftingStationShown(craftType)
	local craftTypeMatches = true
	if craftType ~= nil then
		craftTypeMatches = (gcit() == craftType) or false
	end
	return ZO_CraftingUtils_IsCraftingWindowOpen() and craftTypeMatches
end


--Is the currnt crafting type jewelry?
--return boolean isJewerlyCrafting
function libFilters:IsJewelryCrafting()
	return (gcit() == CRAFTING_TYPE_JEWELRYCRAFTING) or false
end


--Check if the refinement panel is shown.
--return boolean isShown, control refinementPanel
function libFilters:IsRefinementShown()
	if IsGamepad() then
		if refinementPanel_GP ~= nil then
			if refinementPanel_GP.control ~= nil and not refinementPanel_GP.control:IsHidden() then
				return true, refinementPanel_GP.control
			end
		end
	else
		if refinementPanel ~= nil and refinementPanel.control ~= nil and not refinementPanel.control:IsHidden() then
			return true, refinementPanel.control
		end
	end
	return false, nil
end


--Check if the creation panel is shown.
--return boolean isShown, control creationPanel
function libFilters:IsCreationShown()
	if IsGamepad() then
		if creationPanel_GP ~= nil then
			if creationPanel_GP.control ~= nil and not creationPanel_GP.control:IsHidden() then
				return true, creationPanel_GP.control
			end
		end
	else
		if creationPanel ~= nil and creationPanel.control ~= nil and not creationPanel.control:IsHidden() then
			return true, creationPanel.control
		end
	end
	return false, nil
end


--Check if the deconstruction panel is shown.
--return boolean isShown, control deconstructionPanel
function libFilters:IsDeconstructionShown()
	if IsGamepad() then
		if deconstructionPanel_GP ~= nil then
			if deconstructionPanel_GP.control ~= nil and not deconstructionPanel_GP.control:IsHidden() then
				return true, deconstructionPanel_GP.control
			end
		end
	else
		if deconstructionPanel ~= nil and deconstructionPanel.control ~= nil and not deconstructionPanel.control:IsHidden() then
			return true, deconstructionPanel.control
		end
	end
	return false, nil
end


--Check if the improvement panel is shown.
--return boolean isShown, control improvementPanel
function libFilters:IsImprovementShown()
	if IsGamepad() then
		if improvementPanel_GP ~= nil then
			if improvementPanel_GP.control ~= nil and not improvementPanel_GP.control:IsHidden() then
				return true, improvementPanel_GP.control
			end
		end
	else
		if improvementPanel ~= nil and improvementPanel.control ~= nil and not improvementPanel.control:IsHidden() then
			return true, improvementPanel.control
		end
	end
	return false, nil
end


--Check if the research panel is shown.
--return boolean isShown, control researchPanel
function libFilters:IsResearchShown()
	if IsGamepad() then
		if researchPanel_GP ~= nil and researchPanel_GP.researchLineList ~= nil then
			if researchPanel_GP.control ~= nil and not researchPanel_GP.control:IsHidden() then
				return true, researchPanel_GP.control
			end
		end
	else
		if researchPanel ~= nil and researchPanel.control ~= nil and not researchPanel.control:IsHidden() then
			return true, researchPanel.control
		end
	end
	return false, nil
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

--Check if the Universal Deconstruction panel is shown
--returns boolean isShown
--sceneReference UniversalDeconstructionScene (gamepad or keyboard mode)
function libFilters:IsUniversalDeconstructionPanelShown(isGamepadMode)
	if isGamepadMode == nil then isGamepadMode = IsGamepad() end
	--Check if the gamepad or keyboard scene :IsShowing()
	local universalDeconScene = isGamepadMode and universalDeconstructScene_GP or universalDeconstructScene
	if not universalDeconScene then return false end
	local isShowing = universalDeconScene:IsShowing()
	if isDebugEnabled then dv("IsUniversalDeconstructionPanelShown - %q, gamepadMode: %s", tos(isShowing), tos(isGamepadMode)) end
	return isShowing, universalDeconScene
end
libFilters_IsUniversalDeconstructionPanelShown = libFilters.IsUniversalDeconstructionPanelShown


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
	local filterTypeName = libFilters_GetFilterTypeName(libFilters, filterType)
	local filterTypeNameAndTypeText = (tos(filterTypeName) .. " [" .. tos(filterType) .. "]")
	if isDebugEnabled then dd("HookAdditionalFilter - %q, %s", tos(filterTypeNameAndTypeText), tos(hookKeyboardAndGamepadMode)) end
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
			if isDebugEnabled then dd("HookAdditionalFilter > hookNowSpecial-%q,%s;%s", tos(filterType), tos(funcName), tos(params)) end
			libFilters[funcName](libFilters, unpack(params))
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
		if isDebugEnabled then
			dv(">____________________>")
			dv("[HookNow]filterType %q, isInGamepadMode: %s, keyboardAndGamepadMode: %s",
				filterTypeNameAndTypeText, tos(isInGamepadMode), tos(hookKeyboardAndGamepadMode)) end

		if #inventoriesToHookForLFConstant_Table == 0 then return end

		for _, filterTypeRefToHook in ipairs(inventoriesToHookForLFConstant_Table) do
			if filterTypeRefToHook ~= nil then
				local typeOfRef = checkIfControlSceneFragmentOrOther(filterTypeRefToHook)
				local typeOfRefStr = typeOfRefToName[typeOfRef]
				if isDebugEnabled then
					local typeOfRefName = getTypeOfRefName(typeOfRef, filterTypeRefToHook)
					dv(">Hooking into %q, type: %s", tos(typeOfRefName), tos(typeOfRefStr))
				end

				local layoutData = filterTypeRefToHook.layoutData or filterTypeRefToHook
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
					if isDebugEnabled then dv(">>filterType: %s, otherOriginalFilterAttributesAtLayoutData: %s", filterTypeNameAndTypeText, tos(readFromAttribute)) end
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
						if originalFilterType == "function" then
							createFilterFunctionForLibFilters = false
							if isDebugEnabled then dv(">>>Updated existing filter function %q", tos(readFromAttribute)) end
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
						if isDebugEnabled then dv(">>>Created new filter function %q", tos(readFromAttribute)) end
						readFromObject[readFromAttribute] = function(...) --e.g. update BACKPACK_MENU_BAR_LAYOUT_FRAGMENT.additionalCraftBagFilter so it will be copied to PLAYER_INVENTORY.inventories[INVENTORY_CRAFT_BAG] at PLAYER_INVENTORY:ApplyBackpackLayout()
							return runFilters(filterType, ...)
						end
					end
				else
					if isDebugEnabled then dv(">>filterType: %s, normal hook: %s", filterTypeNameAndTypeText, tos(defaultOriginalFilterAttributeAtLayoutData)) end
					local originalFilterType = type(originalFilter)
					if originalFilterType == "function" then
						if isDebugEnabled then dv(">>>Updated existing filter function %q", tos(defaultOriginalFilterAttributeAtLayoutData)) end
						--Set the .additionalFilter again with the filter function of the original and LibFilters
						layoutData[defaultOriginalFilterAttributeAtLayoutData] = function(...) --.additionalFilter
							return originalFilter(...) and runFilters(filterType, ...)
						end
					else
						if isDebugEnabled then dv(">>>Created new filter function %q", tos(defaultOriginalFilterAttributeAtLayoutData)) end
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
	if isDebugEnabled then dd("HookAdditionalFilterSpecial-%q", tos(specialType)) end
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
	if isDebugEnabled then dd("HookAdditionalFilterSceneSpecial-%q", tos(specialType)) end
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
-- API for the horizontal scrollbar filters, at e.g. SMITHING.researchPanel
--**********************************************************************************************************************
local function combineTablesOnlyBooleanTrue(dest, ...)
    for sourceTableIndex = 1, select("#", ...) do
        local sourceTable = select(sourceTableIndex, ...)
        for key, data in pairs(sourceTable) do
			if data ~= nil and data == true and not dest[key] then
				dest[key] = true
			end
        end
    end
end

--Cached table of combined skipTaables. WIll be set below at function combineCraftingResearchHorizontalScrollbarFilterSkipTables and
--will be reset if a new filter for the research horizontal scroll list for the same crafting type will be un-/registered
local cachedLastCombinedSkipTable = {}

--Combine all the registered skipTables of the research horizontal scroll bar, and add them to the researchPanel table,
--with entry LibFilters3_HorizontalScrollbarFilters
local function combineCraftingResearchHorizontalScrollbarFilterSkipTables(craftingType)
--d("[LF3]combineCraftingResearchHorizontalScrollbarFilterSkipTables: " ..tos(craftingType))
	if not craftingType then return false, nil end
	local combinedSkipTables = {}

	--Get all registered skipTables for the CraftingType
	local filtersRegistered = horizontalScrollBarFilters["craftingResearch"][craftingType]
	--If no skipTables are registred: Nothing to filter!
	if filtersRegistered == nil then return true, nil end

	--Was the same table cached before already?
	if cachedLastCombinedSkipTable ~= nil and cachedLastCombinedSkipTable[craftingType] ~= nil then
		--d(">>using cached combined skipTables")
		combinedSkipTables = cachedLastCombinedSkipTable[craftingType]
	else
		--d(">>building new combined skipTables")
		--Combine only those entries which got the skipTable entry with value == boolean true
		for filterTag, skipTableData in pairs(filtersRegistered) do
			if skipTableData.skipTable ~= nil then
				combineTablesOnlyBooleanTrue(combinedSkipTables, skipTableData.skipTable)
			end
			if skipTableData.from ~= nil then
				if combinedSkipTables.from == nil or combinedSkipTables.from < skipTableData.from then
					combinedSkipTables.from = skipTableData.from
				end
			end
			if skipTableData.to ~= nil then
				if combinedSkipTables.to == nil or combinedSkipTables.to > skipTableData.to then
					combinedSkipTables.to = skipTableData.to
				end
			end
		end
	end

	if NonContiguousCount(combinedSkipTables) == 0 then
--d(">>no skip table needed -> No filters applied")
		cachedLastCombinedSkipTable[craftingType] = nil
		return true, nil
	end
	cachedLastCombinedSkipTable[craftingType] = combinedSkipTables
	return true, combinedSkipTables
end

--Use API function libFilters.ApplyCraftingResearchHorizontalScrollbarFilters(craftingType, noRefresh) to apply the combined
--skiptables to the researchPanel table LibFilters3_HorizontalScrollbarFilters
local function applyCraftingResearchHorizontalScrollbarFilters(craftingType, noRefresh)
--d("[LF3]applyCraftingResearchHorizontalScrollbarFilters")
	craftingType = craftingType or gcit()
	noRefresh = noRefresh or false
	local wasBuild, combinedSkipTables = combineCraftingResearchHorizontalScrollbarFilterSkipTables(craftingType)
	if wasBuild == true then
--d(">combinedTable was build")
		--Apply the combined skiptables to the panel now
		local smithingResearchPanel = getSmithingResearchPanel(craftingType)
		if smithingResearchPanel ~= nil then
			if combinedSkipTables ~= nil then
				local from = 	combinedSkipTables.from
				local to = 		combinedSkipTables.to
				combinedSkipTables.from = nil
				combinedSkipTables.to = nil
				smithingResearchPanel[defaultLibFiltersAttributeToStoreTheHorizontalScrollbarFilters] = {
					from =		from,
					to = 		to,
					skipTable = combinedSkipTables
				}
			else
				--Nothing to filter
				smithingResearchPanel[defaultLibFiltersAttributeToStoreTheHorizontalScrollbarFilters] = {}
			end

			--Update the research panel now?
			if not noRefresh then
				--Refresh the panel now
				--smithingResearchPanel:Refresh() --> Will rebuild the list entries and call list:Commit()
				libFilters_RequestUpdateForResearchFilters(libFilters, 0)
			end
		end
	end
end
libFilters.ApplyCraftingResearchHorizontalScrollbarFilters = applyCraftingResearchHorizontalScrollbarFilters


local registerResearchHorizontolScrollBarFilterParametersErrorStr = "Invalid arguments to %s(%q, %q, %q, %q, %q, %s).\n>Needed format is: String uniqueFilterTag, number CraftingInteractionTpe, table skipTable = {[researchLineIndex] = boolean skipOrNot, ...}, OPTIONAL number fromResearchLineIndex, OPTIONAl number toResearchLineIndex"
--Register a filter by help of a researchLineIndex "skipTable" for a craftingType
--Parameter tyble skipTable contains key = researchLineIndex and value = boolean where "true" means: filter/skip (hide) this researchLineIndex at the horizontal scroll list.
--Parameter number fromResearchLineIndex sets the researchLineIndex to start the output of the horizontal scrollbar: It filters (hides) the possibe entries "in total".
--Parameter number toResearchLineIndex sets the researchLineIndex to stop the output of the horizontal scrollbar: It filters (hides) the possible entries "in total".
--Parameter boolean noInUseError: if set to true there will be no error message if the filterTag+filterType was registered already -> Silent fail. Return value will be false then!
--Returns true if filter table skipTable was registered, else nil in case of parameter errors, or false if same tag+type was already registered
--If different addons register skipTables for the same crafting type, these skipTables will be combined!
-->The combined entries of the skipTable are added, directly upon registering such filter, to they researchPanel table, with entry LibFilters3_HorizontalScrollbarFilters
-->You need to manually call libFilters:RequestUpdateForResearchFilters(delay) to update the horizontal scrollbar (and the normal research filters) via researchPanel:Refresh()
function libFilters:RegisterResearchHorizontalScrollbarFilter(filterTag, craftingType, skipTable, fromResearchLineIndex, toResearchLineIndex, noInUseError)
	if not filterTag or not craftingType or not skipTable then
		dfe(registerResearchHorizontolScrollBarFilterParametersErrorStr, "RegisterResearchHorizontalScrollbarFilter", tos(filterTag), tos(craftingType), tos(skipTable), tos(fromResearchLineIndex), tos(toResearchLineIndex), tos(noInUseError))
		return
	end
	if isDebugEnabled then dd("RegisterResearchHorizontalScrollbarFilter-%q,%q,%q,%q,%q,%s", tos(filterTag), tos(craftingType), tos(skipTable), tos(fromResearchLineIndex), tos(toResearchLineIndex), tos(noInUseError)) end
	local filtersRegistered = horizontalScrollBarFilters["craftingResearch"]
	filtersRegistered[craftingType] = filtersRegistered[craftingType] or {}
	if filtersRegistered[craftingType][filterTag] ~= nil then
		if not noInUseError then
			dfe("FilterTag \'%q\' craftingType \'%q\' skipTable is already in use!",
					tos(filterTag), tos(craftingType))
		end
		return false
	end
	filtersRegistered[craftingType][filterTag] = { skipTable = skipTable, from = fromResearchLineIndex, to = toResearchLineIndex }
	cachedLastCombinedSkipTable[craftingType] = nil
	applyCraftingResearchHorizontalScrollbarFilters(craftingType, true)
	return true
end

--Unregister a filter by help of a researchLineIndex "skipTable" for a craftingType, which will show the entries at the horizontal scroll list again.
--If different addons have registered skipTables for the same crafting type, these skipTables will be combined, and thus unregistering 1 filterTag might
--still have any other registered which hides the entry at the horizontal scrollbar
-->The combined entries of the skipTable are added, directly upon unregistering such filter, to they researchPanel table, with entry LibFilters3_HorizontalScrollbarFilters
-->You need to manually call libFilters:RequestUpdateForResearchFilters(delay) to update the horizontal scrollbar (and the normal research filters) via researchPanel:Refresh()
function libFilters:UnregisterResearchHorizontalScrollbarFilter(filterTag, craftingType)
	if not filterTag or filterTag == "" or craftingType == nil then
		dfe("Invalid arguments to UnregisterResearchHorizontalScrollbarFilter(%q, %s).\n>Needed format is: String filterTag, number CraftingInteractionType",
			tos(filterTag), tos(craftingType))
		return
	end
	if isDebugEnabled then dd("UnregisterResearchHorizontalScrollbarFilter-%q,%s", tos(filterTag), tos(craftingType)) end
	local filtersRegistered = horizontalScrollBarFilters["craftingResearch"][craftingType]
	if filtersRegistered ~= nil and filtersRegistered[filterTag] ~= nil then
		filtersRegistered[filterTag] = nil
		cachedLastCombinedSkipTable[craftingType] = nil
		applyCraftingResearchHorizontalScrollbarFilters(craftingType, true)
		return true
	end
	return false
end


--**********************************************************************************************************************
-- Special API
--**********************************************************************************************************************
--Check if the addon CraftBagExtended is enabled and if the craftbag is currently shown at a "non vanilla craftbag" filterType
--e.g. LF_MAIL_SEND, LF_TRADE, LF_GUILDSTORE_SELL, LF_GUILDBANK_DEPOSIT, LF_BANK_DEPOSIT, LF_HOUSE_BANK_DEPOSIT
--Will return boolean true if CBE is enabled and a supported parent filterType panelis shown. Else returns false
function libFilters:IsCraftBagExtendedParentFilterType(filterTypesToCheck)
	local referencesToFilterType, filterTypeParent
	if isDebugEnabled then dd("GetCraftBagExtendedParentFilterType - numFilterTypesToCheck: %s",
			tos(#filterTypesToCheck)) end
	if filterTypesToCheck ~= nil and CraftBagExtended ~= nil then
		--local cbeSpecialAddonChecks = "CraftBagExtended"
		--local isInGamepadMode = IsGamepad()
		for _, filterTypeToCheck in ipairs(filterTypesToCheck) do
			referencesToFilterType, filterTypeParent = nil, nil
			referencesToFilterType, filterTypeParent = craftBagExtendedCheckForCurrentModule(filterTypeToCheck)
			if referencesToFilterType ~= nil and filterTypeParent ~= nil then
				if isDebugEnabled then dv(">filterTypeChecked: %s, filterTypeParent: %q",
						tos(filterTypeToCheck), tos(filterTypeParent)) end
				return true
			end
		end
	end
	if isDebugEnabled then dv(">IsCraftBagExtendedParentFilterType: %s, CBE enabled: %s",
			tos(filterTypeParent), tos(CraftBagExtended ~= nil)) end
	return false
end
local libFilters_IsCraftBagExtendedParentFilterType = libFilters.IsCraftBagExtendedParentFilterType


--Is the vanillaUI CraftBag shown
--returns boolean isShown
function libFilters:IsVanillaCraftBagShown()
	local lReferencesToFilterType, lFilterTypeDetected
	local inputType = IsGamepad()
	if inputType == true then
		if invBackpack_GP.craftBagList ~= nil then
			--If craftbag was not opened before the craftBagList:IsActive might return false, so we need to check for other parameters then
			if isDebugEnabled then dd("IsVanillaCraftBagShown> active: %s, actionMode: %s, currentListType: %s",
					tos(invBackpack_GP.craftBagList:IsActive()), tos(invBackpack_GP.actionMode), tos(invBackpack_GP.currentListType)) end
			if invBackpack_GP.craftBagList:IsActive() or invBackpack_GP.actionMode == 3 or invBackpack_GP.currentListType == "craftBagList" then
				lFilterTypeDetected = 		LF_CRAFTBAG
				lReferencesToFilterType = 	LF_FilterTypeToReference[inputType][LF_CRAFTBAG]
			end
		end
	else
		lReferencesToFilterType, lFilterTypeDetected = detectShownReferenceNow(LF_CRAFTBAG, nil, false, true)
	end
	local vanillaUICraftBagShown = ((lFilterTypeDetected ~= nil and lFilterTypeDetected == LF_CRAFTBAG and lReferencesToFilterType ~= nil) and true) or false
	if isDebugEnabled then dd("IsVanillaCraftBagShown - vanillaUIShown: %s", tos(vanillaUICraftBagShown)) end
	return vanillaUICraftBagShown
end
local libFilters_IsVanillaCraftBagShown = libFilters.IsVanillaCraftBagShown


--Is any CraftBag shown, vanilla UI or CraftBagExtended
--returns boolean isShown
function libFilters:IsCraftBagShown()
	local vanillaUICraftBagShown = libFilters_IsVanillaCraftBagShown(libFilters)
	local cbeCraftBagShown = libFilters_IsCraftBagExtendedParentFilterType(libFilters, cbeSupportedFilterPanels)
	if isDebugEnabled then dd("IsCraftBagShown - vanillaUIShown: %s, cbeShown: %s", tos(vanillaUICraftBagShown), tos(cbeCraftBagShown)) end
	if vanillaUICraftBagShown == true or cbeCraftBagShown == true then return true end
	return false
end
libFilters_IsCraftBagShown = libFilters.IsCraftBagShown


--**********************************************************************************************************************
-- Callback API
--**********************************************************************************************************************
--Create the callbackname for a libFilters filterPanel shown/hidden callback
----It will add an entry in table LibFilters3.mapping.callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType][isShown]
----number filterType needs to be a valid LF_* filterType constant
----boolean isShown true means SCENE_SHOWN will be used, and false means SCENE_HIDDEN will be used for the callbackname
----boolean inputType true = Gamepad, false= keyboard callback, leave empty for both!
----nilable:String universalDeconActiveTab The active tab at the universal deconstruction panel that this callback should be raised for, e.g. "all", "armor", "weapons", "jewelry" or "enchanting"
----nilable:String raiseBeforeOtherAddonsCallbackName If this callbackName (of another addon) is given the callback should be raised after this callback was raised. The callbackName provided here must match the
----> other parameters like filterType, isShown, inputType, universalDeconActiveTab!
----Returns String callbackNameGenerated
---->e.g. "LibFilters3-<yourAddonName>-shown-1" for SCENE_SHOWN and filterType LF_INVENTORY of addon <yourAddonName>
function libFilters:RegisterCallbackName(yourAddonName, filterType, isShown, inputType, universalDeconActiveTab, raiseBeforeOtherAddonsCallbackName)
	isShown = isShown or false
	if yourAddonName == nil or yourAddonName == "" or yourAddonName == GlobalLibName or type(yourAddonName) ~= "string" then
		dfe("[RegisterCallbackName]ERROR - The addonName %q must be a string, or cannot be used!", tos(yourAddonName))
		return
	end
	if type(isShown) ~= "boolean" then
		dfe("[RegisterCallbackName]ERROR - isShown %q needs to be a boolean (false/true)!", tos(isShown))
		return
	end
	if universalDeconActiveTab == nil then universalDeconActiveTab = "" end
	if type(universalDeconActiveTab) ~= "string" or (universalDeconActiveTab ~= "" and universalDeconTabKeyToLibFiltersFilterType[universalDeconActiveTab] == nil) then
		dfe("[RegisterCallbackName]ERROR - universalDeconActiveTab %q needs to be a String (all/armor/weapons/jewelry/enchantments)!", tos(universalDeconActiveTab))
		return
	end
	if raiseBeforeOtherAddonsCallbackName ~= nil and (raiseBeforeOtherAddonsCallbackName == "" or raiseBeforeOtherAddonsCallbackName == GlobalLibName or type(raiseBeforeOtherAddonsCallbackName) ~= "string") then
		dfe("[RegisterCallbackName]ERROR - The raiseBeforeOtherAddonsCallbackName %q must be a string, or cannot be used!", tos(raiseBeforeOtherAddonsCallbackName))
		return
	end

	--Build the unique callback Name
	local callBackUniqueName = strfor(callbackPattern, tos(yourAddonName), (isShown == true and SCENE_SHOWN) or SCENE_HIDDEN, tos(filterType), tos(universalDeconActiveTab))

	--Add the callback to the registered table
	if universalDeconActiveTab == "" then
		universalDeconActiveTab = "_NONE_"
	end
	if inputType == nil then
		--Keyboard
		callbacks.registeredCallbacks[false][yourAddonName] = callbacks.registeredCallbacks[false][yourAddonName] or {}
		callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab] = callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab] or {}
		callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab][filterType] = callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab][filterType] or {}
		callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab][filterType][isShown] =  { callbackName=callBackUniqueName, raiseBefore=raiseBeforeOtherAddonsCallbackName }
		--Gamepad
		callbacks.registeredCallbacks[true][yourAddonName] = callbacks.registeredCallbacks[true][yourAddonName] or {}
		callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab] = callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab] or {}
		callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab][filterType] = callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab][filterType] or {}
		callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab][filterType][isShown] = { callbackName=callBackUniqueName, raiseBefore=raiseBeforeOtherAddonsCallbackName }
	elseif type(inputType) == "boolean" then
		callbacks.registeredCallbacks[inputType][yourAddonName] = callbacks.registeredCallbacks[inputType][yourAddonName] or {}
		callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab] = callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab] or {}
		callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType] = callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType] or {}
		callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType][isShown] = { callbackName=callBackUniqueName, raiseBefore=raiseBeforeOtherAddonsCallbackName }
	else
		dfe("[RegisterCallbackName]ERROR - inputType %q needs to be a boolean (false = Keyboard/true = Gamepad), or nil (both inut types)!", tos(inputType))
		return
	end

	callbacks.allRegisteredAddonCallbacks[callBackUniqueName] = true

	return callBackUniqueName
end


--Remove an added callbackname for a libFilters filterPanel shown/hidden callback again
--It will remove the entry in table LibFilters3.mapping.callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType][isShown]
--number filterType needs to be a valid LF_* filterType constant
--boolean isShown true means SCENE_SHOWN will be used, and false means SCENE_HIDDEN will be used for the callbackname
--boolean inputType true = Gamepad, false= keyboard callback, leave empty for both!
--nilable:String universalDeconActiveTab The active tab at the universal deconstruction panel that this callback should be raised for, e.g. "all", "armor", "weapons", "jewelry" or "enchanting"
--Returns boolean wasRemoved true/false
function libFilters:UnregisterCallbackName(yourAddonName, filterType, isShown, inputType, universalDeconActiveTab)
	isShown = isShown or false
	if yourAddonName == nil or yourAddonName == "" or yourAddonName == GlobalLibName or type(yourAddonName) ~= "string" then
		dfe("[UnregisterCallbackName]ERROR - The addonName %q must be a string, or cannot be used!", tos(yourAddonName))
		return
	end
	if type(isShown) ~= "boolean" then
		dfe("[UnregisterCallbackName]ERROR - isShown %q needs to be a boolean (false/true)!", tos(isShown))
		return
	end
	if universalDeconActiveTab == nil then universalDeconActiveTab = "" end
	if type(universalDeconActiveTab) ~= "string" or (universalDeconActiveTab ~= "" and universalDeconTabKeyToLibFiltersFilterType[universalDeconActiveTab] == nil) then
		dfe("[UnregisterCallbackName]ERROR - universalDeconActiveTab %q needs to be a String (all/armor/weapons/jewelry/enchantments)!", tos(universalDeconActiveTab))
		return
	end

	--Build the unique callback Name
	local callBackUniqueName = strfor(callbackPattern, tos(yourAddonName), (isShown == true and SCENE_SHOWN) or SCENE_HIDDEN, tos(filterType), tos(universalDeconActiveTab))

	--Add the callback to the registered table
	if universalDeconActiveTab == "" then
		universalDeconActiveTab = "_NONE_"
	end
	if inputType == nil then
		--Keyboard
		if callbacks.registeredCallbacks[false][yourAddonName] ~= nil then
			if callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab] ~= nil then
				if callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab][filterType]  ~= nil then
					local callbackData = callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab][filterType][isShown]
					if callbackData ~= nil and callbackData.callbackName == callBackUniqueName then
						callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab][filterType][isShown] = nil
						callbacks.allRegisteredAddonCallbacks[callBackUniqueName] = nil

						if NonContiguousCount(callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab][filterType]) == 0 then
							callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab][filterType] = nil
						end
						if NonContiguousCount(callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab]) == 0 then
							callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab] = nil
						end
						if NonContiguousCount(callbacks.registeredCallbacks[false][yourAddonName]) == 0 then
							callbacks.registeredCallbacks[false][yourAddonName] = nil
						end
					end
				end
			end
		end
		--Gamepad
		if callbacks.registeredCallbacks[true][yourAddonName] ~= nil then
			if callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab] ~= nil then
				if callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab][filterType]  ~= nil then
					local callbackData = callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab][filterType][isShown]
					if callbackData ~= nil and callbackData.callbackName == callBackUniqueName then
						callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab][filterType][isShown] = nil
						callbacks.allRegisteredAddonCallbacks[callBackUniqueName] = nil

						if NonContiguousCount(callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab][filterType]) == 0 then
							callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab][filterType] = nil
						end
						if NonContiguousCount(callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab]) == 0 then
							callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab] = nil
						end
						if NonContiguousCount(callbacks.registeredCallbacks[true][yourAddonName]) == 0 then
							callbacks.registeredCallbacks[true][yourAddonName] = nil
						end
					end
				end
			end
		end
	elseif type(inputType) == "boolean" then
		if callbacks.registeredCallbacks[inputType][yourAddonName] ~= nil then
			if callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab] ~= nil then
				if callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType]  ~= nil then
					local callbackData = callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType][isShown]
					if callbackData ~= nil and callbackData.callbackName == callBackUniqueName then
						callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType][isShown] = nil
						callbacks.allRegisteredAddonCallbacks[callBackUniqueName] = nil

						if NonContiguousCount(callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType]) == 0 then
							callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType] = nil
						end
						if NonContiguousCount(callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab]) == 0 then
							callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab] = nil
						end
						if NonContiguousCount(callbacks.registeredCallbacks[inputType][yourAddonName]) == 0 then
							callbacks.registeredCallbacks[inputType][yourAddonName] = nil
						end
					end
				end
			end
		end
	else
		dfe("[UnregisterCallbackName]ERROR - inputType %q needs to be a boolean (false = Keyboard/true = Gamepad), or nil (both inut types)!", tos(inputType))
		return
	end
	return true
end

--**********************************************************************************************************************
-- END LibFilters API functions END
--**********************************************************************************************************************
--**********************************************************************************************************************
--**********************************************************************************************************************


--**********************************************************************************************************************
-- CALLBACKS
--**********************************************************************************************************************
--Create callbacks one can register to as the filterType panels show and hide
--e.g. for LF_SMITHING_REFINE as the panel opens or closes, the signature would be
--name: LibFilters3-<shown or hidden defined via SCENE_SHOWN and SCENE_HIDDEN constants>-<filterType>
--variables passed as parameters:
--filterType,
--shownState,
--isGamepadModeCallback,
--fragment/scene/control that was used to raise the callback,
--referenceObjects (from table filterTypeToCheckIfReferenceIsHidden),
--additionalParameters ...
--e.g. showing LF_SMITHING_REFINE
--[[
		--The library provides callbacks for the filterTypes to get noticed as the filterTypes are shown/hidden.
		--The callback name is build by the library prefix "LibFilters3-" (constant provided is LibFilters3.globalLibName) followed by the state of the
		--filterPanel as the callback fires (can be either the constant SCENE_SHOWN or SCENE_HIDDEN), followed by "-" and the suffix is the filterType constant
		--of the panel.
		--The library provides the API function libfilters:CreateCallbackName(filterType, isShown) to generate the callback name for you. isShown is a boolean.
		--if true SCENE_SHOWN will be used, if false SCENE_HIDDEN will be used.
		--e.g. for LF_INVENTORY shown it would be
		local callbackNameInvShown = libfilters:CreateCallbackName(LF_INVENTORY, true)
		--Makes: "LibFilters3-shown-1"

		--The callbackFunction you register to it needs to provide the following parameters:
		--number filterType is the LF_* constantfor the panel currently shown/hidden
		--string stateStr will be SCENE_SHOWN ("shown") if shon or SCENE_HIDDEN ("hidden") if hidden callback was fired
		--boolean isInGamepadMode is true if we are in Gamepad input mode and false if in keyboard mode
		--refVar fragmentOrSceneOrControl is the frament/scene/control which was used to do the isShown/isHidden check
		--table lReferencesToFilterType will contain additional reference variables used to do shown/hidden checks
]]
function libFilters:CallbackRaise(filterTypes, fragmentOrSceneOrControl, stateStr, isInGamepadMode, typeOfRef, doNotUpdateCurrentAndLastFilterTypes, specialPanelControlFunc, universalDeconData)
	local isShown = (stateStr == SCENE_SHOWN and true) or false
	doNotUpdateCurrentAndLastFilterTypes = doNotUpdateCurrentAndLastFilterTypes or false

	universalDeconData = universalDeconData or {}
	if universalDeconData.isShown == nil then
		libFilters_IsUniversalDeconstructionPanelShown = libFilters_IsUniversalDeconstructionPanelShown or libFilters.IsUniversalDeconstructionPanelShown
		universalDeconData.isShown = libFilters_IsUniversalDeconstructionPanelShown()
	end
	if universalDeconData.isShown == true and stateStr == SCENE_HIDDEN then
		if universalDeconData.lastTab == nil and universalDeconData.wasShownBefore then
			dfe("[CallbackRaise]|UD> ERROR at UNIVERSAL DECON - state: %s - Last tab coming from unknown!", tos(stateStr))
			return
		end
	end

	local switchToLastFilterType = false

	--Backup the lastFilterTyp and references if given
	local lastFilterTypeBefore                  		= libFilters._lastFilterType
	local lastFilterTypeUniversalDeconTabBefore 		= libFilters._lastFilterTypeUniversalDeconTab
	local lastFilterTypeRefBefore               		= libFilters._lastFilterTypeReferences
	local currentFilterType                            	= libFilters._currentFilterType
	local currentFilterTypeUniversalDeconTab           	= libFilters._currentFilterTypeUniversalDeconTab
	local currentFilterTypeRef                         	= libFilters._currentFilterTypeReferences
	local currentFilterTypeBeforeReset                  = currentFilterType
	local currentFilterTypeUniversalDeconTabBeforeReset = currentFilterTypeUniversalDeconTab
	local currentFilterTypeRefBeforeReset               = currentFilterTypeRef
	local lastFilterTypeBeforeReset                  	= lastFilterTypeBefore
	local lastFilterTypeUniversalDeconTabBeforeReset 	= lastFilterTypeUniversalDeconTabBefore
	local lastFilterTypeRefBeforeReset               	= lastFilterTypeRefBefore
	if isDebugEnabled then
		dd("[CallbackRaise]state: %s, currentBefore: %s, lastBefore: %s, currentUniversalDeconTab: %s, lastUniversalDeconTab: %s, doNotUpdate: %s",
				tos(stateStr), tos(currentFilterTypeBeforeReset), tos(lastFilterTypeBeforeReset), tos(currentFilterTypeUniversalDeconTab),
				tos(lastFilterTypeUniversalDeconTabBeforeReset), tos(doNotUpdateCurrentAndLastFilterTypes))
	end

	--Update lastFilterType and ref and reset the currentFilterType and ref to nil
	if not doNotUpdateCurrentAndLastFilterTypes then
		updateLastAndCurrentFilterType(nil, nil, nil, false)
	end

	if filterTypes == nil or fragmentOrSceneOrControl == nil or stateStr == nil or stateStr == "" then return end
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end

	local lReferencesToFilterType, filterType, universalDeconSelectedTabNow
	--local skipIsShownChecks = false
	--local checkIfHidden = (stateStr == SCENE_HIDDEN and true) or false
	local checkIfHidden = false

	if isDebugEnabled then
		dv("![CB]callbackRaise - state %s, #filterTypes: %s, refType: %s, specialPanelControlFunc: %s, isUniversalDecon: %s",
				tos(stateStr), tos(#filterTypes), tos(typeOfRef), tos(specialPanelControlFunc), tos(universalDeconData.isShown)
		)
		if #filterTypes > 0 then
			for filterTypeIdx, filterTypePassedIn in ipairs(filterTypes) do
				dv(">passedInFilterType %s: %s", tos(filterTypeIdx), tos(filterTypePassedIn))
			end
		end
	end
	--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	--!!!SCENE_HIDING and SCENE_SHOWING are not supported as of 2022-01-04!!!
	--> So the code below relating to these states is just "left over" for future implementation!
	--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	--Are we hiding or is a control/scene/fragment already hidden?
	--The shown checks might not work properly then, so we need to "cache" the last used filterType and reference variables!
	local lastKnownFilterType, lastKnownRefVars, lastFilterTypeUniversalDeconTab
	currentFilterType 				=	libFilters._currentFilterType
	lastKnownFilterType             =	libFilters._lastFilterType
	lastFilterTypeUniversalDeconTab =	libFilters._lastFilterTypeUniversalDeconTab
	lastKnownRefVars                =	libFilters._lastFilterTypeReferences

	--todo: 2022-01-14: Currently parameter doNotUpdateCurrentAndLastFilterTypes is not used anywhere. Was used for crafting tables > inventory -> crafting table switch I think I remember?!
	if doNotUpdateCurrentAndLastFilterTypes == true
			and ((lastKnownFilterType ~= nil and currentFilterType ~= nil and lastKnownFilterType ~= currentFilterType) or
			(lastFilterTypeUniversalDeconTab ~= nil and currentFilterTypeUniversalDeconTab ~= nil and lastFilterTypeUniversalDeconTab ~= currentFilterTypeUniversalDeconTab)
	) then
		checkIfHidden = true
	end

	--Hide the scene/fragment/control
	if stateStr == SCENE_HIDDEN then --or stateStr == SCENE_HIDING   then

		if lastKnownFilterType ~= nil then
			if isDebugEnabled then dv(">lastKnownFilterType: %s", tos(lastKnownFilterType)) end

			--Check if the fragment or scene hiding/hidden is related to the lastKnown filterType:
			--Some fragments like INVENTORY_FRAGMENT and BACKPACK_MAIL_LAYOUT_FRAGMENT are added to the same scenes (mail send e.g.).
			--If this scene is hiding/hidden both fragment's raise callbacks for hiding and hidden state where only the "dedicated" fragment
			--(here: BACKPACK_MAIL_LAYOUT_FRAGMENT) to the lastShown filterPanel (LF_MAIL_SEND) should fire it!
			-->So we need to block the others!
			if typeOfRef == LIBFILTERS_CON_TYPEOFREF_SCENE then
				--Check if there is a scene registered as callack for the last shown filterType
				local sceneOfLastFilterType = callbacksUsingScenes[isInGamepadMode][fragmentOrSceneOrControl]
				if sceneOfLastFilterType ~= nil then
					if ZO_IsElementInNumericallyIndexedTable(sceneOfLastFilterType, lastKnownFilterType) == false then
						if isDebugEnabled then dv("<<sceneOfLastFilterType not valid") end
						return false
					end
				else
					if isDebugEnabled then dv("<<sceneOfLastFilterType not found", tos(lastKnownFilterType)) end
					return false
				end

			elseif typeOfRef == LIBFILTERS_CON_TYPEOFREF_FRAGMENT then
				--Check if there is a scene registered as callack for the last shown filterType
				local fragmentOfLastFilterType = callbacksUsingFragments[isInGamepadMode][fragmentOrSceneOrControl]
				if fragmentOfLastFilterType ~= nil then
					if ZO_IsElementInNumericallyIndexedTable(fragmentOfLastFilterType, lastKnownFilterType) == false then
						if isDebugEnabled then dv("<<fragmentOfLastFilterType not valid") end
						return false
					end
				else
					if isDebugEnabled then dv("<<fragmentOfLastFilterType not found") end
					return false
				end
			elseif typeOfRef == LIBFILTERS_CON_TYPEOFREF_CONTROL then
				--Check if we are the universal deconstruction panel
				if universalDeconData.isShown ==true and lastFilterTypeUniversalDeconTab ~= nil then
					--The last tab raised the hide callback so switch the filterType from the new detected one to the last one again
					--later on
					switchToLastFilterType = true
				end
			end
		end
		--[[
            elseif stateStr == SCENE_SHOWING then
                --!!! 2022-01-04 Not used !!!
                --If a fragment/scene is showing the controls etc. needed for the "detectShownReferenceNow" check below will be
                --sill hidden/not properly created. The last used filterType does neither help so we need to check if 1 dedicated
                --filterType was passed in and if so: Fire the callback "showing" for that filterType
                if #filterTypes == 1 then
                    lastKnownFilterType = filterTypes[1]
                    lastKnownRefVars = libFilters_GetFilterTypeReferences(libFilters, lastKnownFilterType, isInGamepadMode)
                    skipIsShownChecks = true
                end
        ]]

		--Show the scene/fragment/control
	elseif stateStr == SCENE_SHOWN then
		---With the addon craftbag extended active:
		--Some fragments like BACKPACK_MAIL_LAYOUT_FRAGMENT are changing their hidden state to Shown after the CRAFTBAG_FRAGMENT was shown already.
		-->In order to leave only the craftbag fragment active we need to check the later called "non-craftbag" (layout) fragments and do not fire
		-->their state change!
		if isInGamepadMode == false and CraftBagExtended ~= nil and lastKnownFilterType == LF_CRAFTBAG then
			if isDebugEnabled then dv(">>CraftBagExtended active") end
			if not craftbagRefsFragment[fragmentOrSceneOrControl] then
				if isDebugEnabled then dv(">>>Current fragment is not the craftbag fragment") end
				local isCBESupportedPanel = (#filterTypes == 0) or false
				if isCBESupportedPanel == false then
					for _, filterTypePassedIn in ipairs(filterTypes) do
						isCBESupportedPanel = isCraftBagExtendedSupportedPanel(filterTypePassedIn)
						if isCBESupportedPanel == true then
							if isDebugEnabled then dv(">>>CraftBagExtended supported panel was found: %s", tos(filterTypePassedIn)) end
							break
						end
					end
				else
					if isDebugEnabled then dv(">>>No filterTypes passed in -> Checking for CBE filterPanels") end
				end
				if isCBESupportedPanel == true and libFilters_IsCraftBagExtendedParentFilterType(libFilters, cbeSupportedFilterPanels) then
					if isDebugEnabled then dv("<<CraftBagExtended craftbagFragment was shown already") end
					return false
				end
			end
		end
	end

	--Check for shown controls/fragments/scenes -> Only for the stateStr SCENE_SHOWN, SCENE_HIDING and SCENE_HIDDEN
	--if skipIsShownChecks == false then
	--Detect which control/fragment/scene is currently shown
	if #filterTypes == 0 then
		--Detect the currently shown control/fragment/scene and get the filterType
		lReferencesToFilterType, filterType, universalDeconSelectedTabNow = detectShownReferenceNow(nil, isInGamepadMode, checkIfHidden, false)
	else
		local checkForAllPanelsAtTheEnd = false
		--Check if the controls/fragments/scenes for the given filterTypes are shown/hidden (checkIfHidden) first
		for idx, filterTypeInLoop in ipairs(filterTypes) do
			if filterType == nil and lReferencesToFilterType == nil then
				local skipCheck = false
				--is the filterType set to 0 (automatically detection based on some code,
				--e.g. at re-used fragments like BACKPACK_LAYOUT_FRAGMENT at inventory, bank deposit, guild bank deposit, trading house sell, mail, trade, ...)
				if filterTypeInLoop == 0 then
					--If the entry is not the last entry in the table "dynamically move it there"
					if idx ~= #filterTypes then
						checkForAllPanelsAtTheEnd = true
						skipCheck = true
					else
						checkForAllPanelsAtTheEnd = false
						filterTypeInLoop = nil
					end
				end
				if not skipCheck then
					--Get the reference variables and filterType currently shown
					lReferencesToFilterType, filterType, universalDeconSelectedTabNow = detectShownReferenceNow(filterTypeInLoop, isInGamepadMode, checkIfHidden, false)
					if filterType ~= nil and lReferencesToFilterType ~= nil then
						if isDebugEnabled then dv("<<filterType was found in loop: %s", tos(filterType)) end
						break -- leave the loop if filterType and reference were found
					end
				end
			end
		end
		--At the end: was any entry with filterType = 0 provided in the filterTypes table?
		if checkForAllPanelsAtTheEnd == true and filterType == nil and lReferencesToFilterType == nil then
			--Detect the currently shown control/fragment/scene and get the filterType
			lReferencesToFilterType, filterType, universalDeconSelectedTabNow = detectShownReferenceNow(nil, isInGamepadMode, checkIfHidden, false)
		end
	end
	--end

	--Was a filterType found or provided (SCENE_HIDING/SCENE_HIDDEN: libFilters._currentFilterType as the callback was raised;
	--SCENE_SHOWING: passed in filterType if only 1 was passed in)
	if filterType == nil then
		--Are we at hiding/hidden state?
		if stateStr == SCENE_HIDDEN and lastKnownFilterType ~= nil and lastKnownRefVars ~= nil and not doNotUpdateCurrentAndLastFilterTypes then
			--The last used filterType used before hiding is given? -> Use it for the hiding now
			filterType 				= lastKnownFilterType
			lReferencesToFilterType = lastKnownRefVars
		else
			--Only if PerfectPixel addon is enabled! Else this would e.g. make the gamepad mode switch from craftbag back to inventory (where in the inventory
			--"Currencies" category is selected and thus libFilters._currentFilterType would be nil) stop the callback and reset the current filterType to CraftBag -> Wrong!
			if PP ~= nil and stateStr == SCENE_SHOWN and lastKnownFilterType ~= nil and currentFilterType == nil and lastKnownFilterType ~= currentFilterType then
				--Reset the current and last filterTypes again as no new filterType currently shown could be found
				-->This will prevent a nil of the current filterType if another fragment/control tries to fire a callback
				-->later than the last successfully fired callback (e.g. with enabled addon PerfectPixel the LF_MAIL_SEND
				-->BACKPACK_MAIL_LAYOUT_FRAGMENT fragment in keyboard mode will fire it's statechange before inventory_fragment
				-->fires. The inventory fragment will then overwrite the current filterType and set it to nil, and the lastFilterType
				-->will be set to LF_MAIL_SEND, which is incorrect and leads to errors in the further processing)
				local currentFilterTypeBefore 			= libFilters._lastFilterType
				if currentFilterTypeBefore ~= nil then
					libFilters._currentFilterType 			= currentFilterTypeBefore
					local currentFilterTypeReferencesBefore = libFilters._lastFilterTypeReferences
					libFilters._currentFilterTypeReferences = currentFilterTypeReferencesBefore
				end
				if lastFilterTypeBefore ~= nil then
					libFilters._lastFilterType = lastFilterTypeBefore
				end
				if lastFilterTypeUniversalDeconTabBefore ~= nil then
					libFilters._lastFilterTypeUniversalDeconTab = lastFilterTypeUniversalDeconTabBefore
				end
				if lastFilterTypeRefBefore ~= nil then
					libFilters._lastFilterTypeReferences = lastFilterTypeRefBefore
				end
				if isDebugEnabled then dd(">SHOWN - No filterType found. Resetting the current %s and last filterType %s",
						tos(currentFilterTypeBefore), tos(lastFilterTypeBefore))
				end
			end
			return false
		end
	else
		if switchToLastFilterType == true then
			if isDebugEnabled then dd(">switched filterType %s to last one %s", tos(filterType), tos(lastKnownFilterType)) end
			filterType = lastKnownFilterType
		end
	end

	--Was the callback that should fire now the last activated one already?
	local lastCallbackState = libFilters._lastCallbackState
	if ( lastCallbackState ~= nil and lastCallbackState == stateStr
			and (
			(currentFilterTypeBeforeReset ~= nil and filterType == currentFilterTypeBeforeReset)
					and (currentFilterTypeUniversalDeconTabBeforeReset == nil
					or (currentFilterTypeUniversalDeconTabBeforeReset ~= nil and universalDeconSelectedTabNow ~= nil
					and universalDeconSelectedTabNow == currentFilterTypeUniversalDeconTabBeforeReset)
			)
	)
	) then
		--Reset the current and last variables now
		libFilters._currentFilterType                  	= currentFilterTypeBeforeReset
		libFilters._currentFilterTypeUniversalDeconTab 	= currentFilterTypeUniversalDeconTabBeforeReset
		libFilters._currentFilterTypeReferences        	= currentFilterTypeRefBeforeReset
		libFilters._lastFilterType                  	= lastKnownFilterType
		libFilters._lastFilterTypeUniversalDeconTab 	= lastFilterTypeUniversalDeconTab
		libFilters._lastFilterTypeReferences        	= lastKnownRefVars
		if isDebugEnabled then
			dd("<CALLBACK ABORTED - filterType: %s and state %s currently already active! currentNow: %s, lastNow: %s, universalDeconTabNow: %s, universalDeconTabLast: %s",
					tos(filterType), tos(stateStr),
					tos(libFilters._currentFilterType), tos(libFilters._lastFilterType),
					tos(libFilters._currentFilterTypeUniversalDeconTab), tos(libFilters._lastFilterTypeUniversalDeconTab)
			)
		end
		return
	end

	--Universal Deconstruction - If UniversalDecon panel is closed the currentTabNow will be nil, so use the currently shown universalDecon Tab before the panel
	--was closed instead: libFilters._currentFilterTypeUniversalDeconTab
	--> Passed in from EVENT_CRAFTING_INTERACTON_END call
	if not isShown and universalDeconData.isShown == true then
		if universalDeconSelectedTabNow == nil then
			if universalDeconData.currentTab ~= nil then
				universalDeconSelectedTabNow = universalDeconData.currentTab
			elseif universalDeconData.lastTab ~= nil then
				--If currentTab cannot be used try the last activetab before to at least send some info, that the universalDecon panel was closed
				--and not any normal decon, jewelry decon or enchanting extarction panel!
				dd("|UD> CallbackRaise-universal deconstruction CLOSED - currentTab is NIL! Using last tab: %q", tos(universalDeconData.lastTab))
				universalDeconSelectedTabNow = universalDeconData.lastTab
			else
				--If currentTab AND lastTab cannot be used just pass in the "all" tab...
				dd("|UD> CallbackRaise-universal deconstruction CLOSED - currentTab AND lastTab are NIL! Using last tab: %q", "all")
				universalDeconSelectedTabNow = "all"
			end
		end
	end

	if lReferencesToFilterType == nil then lReferencesToFilterType = {} end
	--Default callback name for LibFilters base callback (non-addon related, only raised directly by the library internally!)
	-->The addon callbacks should be raised directly after this one!
	--local callbackName = GlobalLibName .. "-" .. stateStr .. "-" .. tos(filterType) .. "-" .. tos(universalDeconSelectedTabNow)
	local universalDeconSelectedTabNowForCallbackName = universalDeconSelectedTabNow
	if universalDeconSelectedTabNowForCallbackName == nil then
		universalDeconSelectedTabNowForCallbackName = ""
	end
	local callbackName = strfor(callbackBaseLibPattern, (isShown == true and SCENE_SHOWN) or SCENE_HIDDEN, tos(filterType), tos(universalDeconSelectedTabNowForCallbackName))

	local callbackRaisePrefixStr = ""
	local callbackRaiseSuffixStr = ""
	local callbackStr = "!!! CALLBACK -> filterType: %q [%s] - %s"
	if isDebugEnabled then
		local filterTypeName = libFilters_GetFilterTypeName(libFilters, filterType)
		local callbackRefType = typeOfRefToName[typeOfRef]
		if universalDeconData.isShown == true then
			callbackRaisePrefixStr = "|UD> "
		end
		if isShown == true then
			callbackRaisePrefixStr = ">> " .. callbackRaisePrefixStr
			callbackRaiseSuffixStr = " >>"
		else
			callbackRaisePrefixStr = "<< " .. callbackRaisePrefixStr
			callbackRaiseSuffixStr = " <<"
		end
		if universalDeconData.isShown == true then
			callbackStr = callbackStr .. " - UniversalDecon - TabNow: %s, TabBefore: %s !!!"
			df(callbackRaisePrefixStr .. callbackStr .. callbackRaiseSuffixStr,
					tos(filterTypeName), tos(filterType), tos(stateStr), tos(universalDeconSelectedTabNow), tos(universalDeconData.lastTab))
		else
			callbackStr = callbackStr .. " !!!"
			df(callbackRaisePrefixStr .. callbackStr .. callbackRaiseSuffixStr,
					tos(filterTypeName), tos(filterType), tos(stateStr))
		end
		dd(callbackRaisePrefixStr .. "Callback %s raise %q - state: %s, filterType: %s, gamePadMode: %s, UniversalDecon - TabNow: %s, TabBefore: %s" .. callbackRaiseSuffixStr,
				tos(callbackRefType), callbackName, tos(stateStr), tos(filterType), tos(isInGamepadMode), tos(universalDeconSelectedTabNow), tos(universalDeconData.lastTab))
	end

	--Update currentFilterTyp and ref if the ref is shown. Do not update if it got hidden!
	if isShown == true and not doNotUpdateCurrentAndLastFilterTypes then
		updateLastAndCurrentFilterType(filterType, lReferencesToFilterType, universalDeconSelectedTabNow, true)
	end

	--Fire the callback now
	libFilters._lastCallbackState = stateStr
	--Raise the library internal callback
	CM:FireCallbacks(callbackName,
			callbackName,
			filterType,
			stateStr,
			isInGamepadMode,
			fragmentOrSceneOrControl,
			lReferencesToFilterType,
			universalDeconSelectedTabNow
	)


--d("[OTHER ADDONs CALLBACKs - FIRE NOW]")
	--Check if other addons have registered a callback at the panel and raise these callbacks then
	local callbacksOfOtherAddonsSortedToRaiseNow = {}
	local callbacksOfOtherAddonsAddedForRaise = {}
	local otherAddonCallbacks = callbacks.registeredCallbacks[isInGamepadMode] --[yourAddonName][universalDeconActiveTab][filterType][showTrueOrHideFalse]
	if otherAddonCallbacks ~= nil then
		local universalDeconSelectedTabNowForCallbackNameCheckStr = universalDeconSelectedTabNowForCallbackName
		if universalDeconSelectedTabNowForCallbackNameCheckStr == "" then
			universalDeconSelectedTabNowForCallbackNameCheckStr = "_NONE_"
		end

		for uniqueAddonName, callbacksOfAddon in pairs(otherAddonCallbacks) do
			for universalDeconActiveTabOfCallbackOfOtherAddon, filterTypesOfCallbacksOfUniqueAddon in pairs(callbacksOfAddon) do
				if universalDeconActiveTabOfCallbackOfOtherAddon == universalDeconSelectedTabNowForCallbackNameCheckStr then
					local universalDeconActiveTabOfCallbackOfOtherAddonForCallback = universalDeconSelectedTabNowForCallbackNameCheckStr
					if universalDeconActiveTabOfCallbackOfOtherAddonForCallback == "_NONE_" then
						universalDeconActiveTabOfCallbackOfOtherAddonForCallback = nil
					end
					for filterTypeOfCallbackOfUniqueAddon, callbackDataOfFilterTypesOfUniqueAddon in pairs(filterTypesOfCallbacksOfUniqueAddon) do
						if filterTypeOfCallbackOfUniqueAddon == filterType then
							for isShownCallback, callbackDataOfUniqueAddon in pairs(callbackDataOfFilterTypesOfUniqueAddon) do
								if isShownCallback == isShown then
									local callbackNameOfUniqueAddon = callbackDataOfUniqueAddon.callbackName
--d(">isShownCallback: " .. tos(isShownCallback) ..", uniqueAddonName: " ..tos(uniqueAddonName) .. ", filterType: " ..tos(filterTypeOfCallbackOfUniqueAddon) .. ", callBackName: " ..tos(callbackNameOfUniqueAddon))
									if callbackNameOfUniqueAddon ~= nil and callbackNameOfUniqueAddon ~= "" and not callbacksOfOtherAddonsAddedForRaise[callbackNameOfUniqueAddon] then
										--Any other callbach should be risen before?
										local callbackRaiseBeforeName = callbackDataOfUniqueAddon.raiseBefore
										if callbackRaiseBeforeName ~= nil and callbackRaiseBeforeName ~= "" and callbackRaiseBeforeName ~= callbackNameOfUniqueAddon
												and not callbacksOfOtherAddonsAddedForRaise[callbackRaiseBeforeName] then
--d(">>callbackRaiseBefore: " ..tos(callbackRaiseBeforeName))
											--Check if this other callback exists and raise it first
											local otherAddonsCallbackData = callbacks.allRegisteredAddonCallbacks[callbackRaiseBeforeName]
											if otherAddonsCallbackData == true then
												--Add the callbackData of the callback to raise first to the sorted callback raising table now
												callbacksOfOtherAddonsAddedForRaise[callbackRaiseBeforeName] = true
--d(">>>added 'run before' callback to sorted table")
												tins(callbacksOfOtherAddonsSortedToRaiseNow, {
													callbackNameOfUniqueAddon = callbackRaiseBeforeName,
													filterTypeOfCallbackOfUniqueAddon = filterTypeOfCallbackOfUniqueAddon,
													universalDeconActiveTabOfCallbackOfUniqueAddon = universalDeconActiveTabOfCallbackOfOtherAddonForCallback,
												})
											end
										end
--d(">>>added callback to sorted table")
										--Add the callbackData to the sorted callback raising table now
										callbacksOfOtherAddonsAddedForRaise[callbackNameOfUniqueAddon] = true
										tins(callbacksOfOtherAddonsSortedToRaiseNow, {
											callbackNameOfUniqueAddon = callbackNameOfUniqueAddon,
											filterTypeOfCallbackOfUniqueAddon = filterTypeOfCallbackOfUniqueAddon,
											universalDeconActiveTabOfCallbackOfUniqueAddon = universalDeconActiveTabOfCallbackOfOtherAddonForCallback,
										})
									end
								end
							end
						end
					end
				end
			end
		end

		if callbacksOfOtherAddonsSortedToRaiseNow ~= nil and #callbacksOfOtherAddonsSortedToRaiseNow > 0 then
--d(">>>>Run " ..tos(#callbacksOfOtherAddonsSortedToRaiseNow) .." callbacks now")
			for _, callbackDataToRaise in ipairs(callbacksOfOtherAddonsSortedToRaiseNow) do
				local callbackNameOfUniqueAddon = callbackDataToRaise.callbackNameOfUniqueAddon
				local filterTypeOfCallbackOfUniqueAddon = callbackDataToRaise.filterTypeOfCallbackOfUniqueAddon
				local universalDeconActiveTabOfCallbackOfUniqueAddon = callbackDataToRaise.universalDeconActiveTabOfCallbackOfUniqueAddon

				if isDebugEnabled then
					local filterTypeNameOfUniqueAddonCallback = libFilters_GetFilterTypeName(libFilters, filterTypeOfCallbackOfUniqueAddon)

					df(callbackRaisePrefixStr .. "(" .. callbackNameOfUniqueAddon .. ") " .. callbackStr .. callbackRaiseSuffixStr,
							tos(filterTypeNameOfUniqueAddonCallback), tos(filterTypeOfCallbackOfUniqueAddon),
							tos(stateStr), tos(callbackDataToRaise.universalDeconActiveTabOfCallbackOfUniqueAddon), tos(universalDeconData.lastTab))
				end
				--Raise the registered callback of other addons
				CM:FireCallbacks(callbackNameOfUniqueAddon,
						callbackNameOfUniqueAddon,
						filterTypeOfCallbackOfUniqueAddon,
						stateStr,
						isInGamepadMode,
						fragmentOrSceneOrControl,
						lReferencesToFilterType,
						universalDeconActiveTabOfCallbackOfUniqueAddon
				)
			end
		end
	end
	return true
end
libFilters_CallbackRaise = libFilters.CallbackRaise


--Get the relevant reference variable (scene, fragment, control) for the callback of a filterType and inputType
--Boolean inputType true gamepad, false keyboard input mode. Leave empty to automatically detect it
--returns the reference variable, and the type of reference variable,
--- and nilable:specialPanelControlFunc function (used for UniversalDeconstruction) with params controlPassedIn (should be = callbackRefData.ref), filterType, inputType
---> returning either a new control determined within the function (e.g. UNIVERSAL_DECONSTRUCTION.control) or the parameter controlPassedIn
function libFilters:GetCallbackReference(filterType, inputType)
	if inputType == nil then inputType = IsGamepad() end
	local callbackRefData = filterTypeToCallbackRef[inputType][filterType]
	if callbackRefData == nil then return end
	return callbackRefData.ref, callbackRefData.refType, callbackRefData.specialPanelControlFunc
end
local libFilters_GetCallbackReference = libFilters.GetCallbackReference


--For the special callbacks: Detect the currently shown filterType and panel reference variables, and then raise the
--callback with "stateStr" (SCENE_SHOWN or SCENE_HIDDEN) for the relevant control/fragment/scene of that filterType
--Boolean inputType true gamepad, false keyboard input mode. Leave empty to automatically detect it
--Boolean doNotUpdateCurrentAndLastFilterTypes controls if the raise of the callback will save the now shown, and last shown, callbacks
--filterTypes etc., or not.
--returns nilable boolean true if the callback was raised, or false if not. nil will be returned if an error occured
function libFilters:RaiseShownFilterTypeCallback(stateStr, inputType, doNotUpdateCurrentAndLastFilterTypes)
	if inputType == nil then inputType = IsGamepad() end
	doNotUpdateCurrentAndLastFilterTypes = doNotUpdateCurrentAndLastFilterTypes or false
	local lReferencesOfShownFilterType, shownFilterType, universalDeconSelectedTabKey = detectShownReferenceNow(nil, inputType, false, false)
	if shownFilterType == nil or lReferencesOfShownFilterType == nil then return end
	--Raise the callback of the filterType with SCENE_SHOWN
	local filterTypes = { shownFilterType }
	--local refVar = lReferencesOfShownFilterType[1]
	local refVar, typeOfRef, specialControlFunc = libFilters_GetCallbackReference(libFilters, shownFilterType, inputType)
	if not refVar then return end
	local universalDeconData = {
		isShown = (universalDeconSelectedTabKey ~= nil and true) or false,
		currentTab = universalDeconSelectedTabKey,
	}
	return libFilters_CallbackRaise(libFilters, filterTypes, refVar, stateStr, inputType, typeOfRef, doNotUpdateCurrentAndLastFilterTypes, specialControlFunc, universalDeconData)
end


--Raise the callback of a dedicated filterType
--callback with "stateStr" (SCENE_SHOWN or SCENE_HIDDEN) for the relevant control/fragment/scene of that filterType
--Boolean inputType true gamepad, false keyboard input mode. Leave empty to automatically detect it
--Boolean doNotUpdateCurrentAndLastFilterTypes controls if the raise of the callback will save the now shown, and last shown, callbacks
--filterTypes etc., or not.
--Parameter universalDeconTab can be used to raise the callback for the universal deconstruction panels "all", "armor", "weapons", "jewelry" or "enchantments"
--IF the filterType constant LF* passed in matches the tab e.g. LF_SMITHING_DECONSTRUCT for all, armor, weapons, LF_JEWELRY_DECONSTRUCT for jewelry and
--LF_ENCHANTING_EXTRACT for enchantments
--returns nilable boolean true if the callback was raised, or false if not. nil will be returned if an error occured
function libFilters:RaiseFilterTypeCallback(filterType, stateStr, inputType, doNotUpdateCurrentAndLastFilterTypes, universalDeconTab)
	if filterType == nil or stateStr == nil then return end
	if inputType == nil then inputType = IsGamepad() end
	doNotUpdateCurrentAndLastFilterTypes = doNotUpdateCurrentAndLastFilterTypes or false
	--Raise the callback of the filterType with SCENE_SHOWN
	local universalDeconData
	if universalDeconTab ~= nil then
		--Check for valid universal decon tab name and filterType pairs
		if universalDeconTabKeyToLibFiltersFilterType[universalDeconTab] == nil then
			dfe("Passed in UNIVERSAL DECONSTRUCTION tab name is not allowed: %", tos(universalDeconTab))
			return
		end
		if not universalDeconLibFiltersFilterTypeSupported[filterType] then
			dfe("Passed in UNIVERSAL DECONSTRUCTION filterType is not allowed: %", tos(filterType))
			return
		end
		local lastTab = libFilters._lastFilterTypeUniversalDeconTab or universalDeconTab
		universalDeconData = {
			isShown 	= true,
			lastTab		= lastTab,
			currentTab 	= universalDeconTab,
			wasShownBefore = wasUniversalDeconPanelShownBefore
		}
	end
	local filterTypes = { filterType }
	local refVar, typeOfRef, specialControlFunc = libFilters_GetCallbackReference(libFilters, filterType, inputType)
	if not refVar then
		dfe("[) ERROR (]No callback reference found for filterType: %s, inputType: %s", tos(filterType), tos(inputType))
		return
	end
	return libFilters_CallbackRaise(libFilters, filterTypes, refVar, stateStr, inputType, typeOfRef, doNotUpdateCurrentAndLastFilterTypes, specialControlFunc, universalDeconData)
end
local libFilters_RaiseFilterTypeCallback = libFilters.RaiseFilterTypeCallback


local function checkIfSpecialCallbackNeedsToBeAdded(controlOrSceneOrFragmentRef, stateStr, inputType, refType, refName, specialPanelControlFunc)
	if isDebugEnabled then
		dv(">checkIfSpecialCallbackNeedsToBeAdded - %q, stateStr: %s, refType: %s", tos(refName), tos(stateStr), tos(refType))
	end
	local specialCallbackForCtrl = specialCallbacks[controlOrSceneOrFragmentRef]
	if specialCallbackForCtrl ~= nil then
		local funcToCall = specialCallbackForCtrl[stateStr]
		if funcToCall ~= nil and type(funcToCall) == "function" then
			if isDebugEnabled then
				dv(">>special callback function will be called now...")
			end
			funcToCall(controlOrSceneOrFragmentRef, stateStr, inputType, refType)
		end
	end
end


--Check which fragment is shown and raise a callback, if needed
local function callbackRaiseCheck(filterTypes, fragmentOrScene, stateStr, isInGamepadMode, typeOfRef, refName)
	--Only fire callbacks for the scene states supported
	if not sceneStatesSupportedForCallbacks[stateStr] then return end
	if stateStr == SCENE_SHOWN then
		--Call the code 1 frame later (zo_callLater with 0 ms > next frame) so the fragment's shown state (used within detectShownReferenceNow())
		--will be updated properly. Else it will fire too early and the fragment is still in state "Showing", on it's way to state "Shown"!
		zo_callLater(function()
			libFilters_CallbackRaise(libFilters, filterTypes, fragmentOrScene, stateStr, isInGamepadMode, typeOfRef, nil, nil, nil)
			checkIfSpecialCallbackNeedsToBeAdded(fragmentOrScene, stateStr, isInGamepadMode, typeOfRef, refName)
		end, 0)
	else
		--For the scene fragment hiding, hidden and showing check there is no delay needed
		libFilters_CallbackRaise(libFilters, filterTypes, fragmentOrScene, stateStr, isInGamepadMode, typeOfRef, nil, nil, nil)
		checkIfSpecialCallbackNeedsToBeAdded(fragmentOrScene, stateStr, isInGamepadMode, typeOfRef, refName)
	end
end


local function isFragmentBlockedByAlreadyDeterminedFilterType(fragment, stateStr, inputType, fragmentName)
	local currentFilterType = libFilters._currentFilterType
	if not fragment then return false end
	if not currentFilterType then return false end
	--Is the fragment a registered callback fragment?
	if callbacksUsingFragments[inputType][fragment] == nil then return end
	--Got this fragment any filterTypes to block it's callback raise?
	local callbackFragmentBlockedFilterTypesBase = callbackFragmentsBlockedMapping[inputType][stateStr]
	local callbackFragmentBlockedFilterTypes = (callbackFragmentBlockedFilterTypesBase ~= nil and callbackFragmentBlockedFilterTypesBase[fragment]) or nil
	if callbackFragmentBlockedFilterTypes ~= nil and #callbackFragmentBlockedFilterTypes > 0 then
		if isDebugEnabled then
			dd(">isFragmentBlockedByAlreadyDeterminedFilterType: %q - stateStr: %s - currentFilterType: %s",
					tos(fragmentName), tos(stateStr), tos(currentFilterType))
		end

		for _, filterTypeBlocked in ipairs(callbackFragmentBlockedFilterTypes) do
			if filterTypeBlocked == currentFilterType then
				if isDebugEnabled then
					dd(">>>>> YES, filterType %s is blocked!", tos(filterTypeBlocked))
				end
				return true
			end
		end
	end
	return false
end


local function onFragmentStateChange(oldState, newState, filterTypes, fragment, inputType)
	local fragmentName
	if isDebugEnabled then
		fragmentName = getFragmentControlName(fragment)
		dd("~~~ FRAGMENT STATE CHANGE ~~~")
		dd("onFragmentStateChange: %q - oldState: %s > newState: %q - #filterTypes: %s, isGamePad: %s", tos(fragmentName), tos(oldState), tos(newState), #filterTypes, tos(inputType))
	end
	local stateStr = fragmentStateToSceneState[newState]

	--Check if the fragment should not raise a callback if any other fragment has fired it's callback before
	--and changed the libFilters._currentFilterType to a special value
	--e.g. INVENTORY_FRAGMENT will fire at LF_MAIL_SEND but it does not not need to do any further checks then
	if not isFragmentBlockedByAlreadyDeterminedFilterType(fragment, stateStr, inputType, fragmentName) then
		callbackRaiseCheck(filterTypes, fragment, stateStr, inputType, LIBFILTERS_CON_TYPEOFREF_FRAGMENT, fragmentName)
	end
end


function onSceneStateChange(oldState, newState, filterTypes, scene, inputType)
	local sceneName
	if isDebugEnabled then
		sceneName = getSceneName(scene)
		dd("~~~ SCENE STATE CHANGE ~~~")
		dd("onSceneStateChange: %q - oldState: %s > newState: %q - #filterTypes: %s, isGamePad: %s", tos(sceneName), tos(oldState), tos(newState), #filterTypes, tos(inputType))
	end
	callbackRaiseCheck(filterTypes, scene, newState, inputType, LIBFILTERS_CON_TYPEOFREF_SCENE, sceneName)
end


function onControlHiddenStateChange(isShown, filterTypes, ctrlRef, inputType, specialPanelControlFunc, universalDeconData)
	local ctrlName
	if isDebugEnabled then
		ctrlName = getCtrlName(ctrlRef)
		dd("~~~ CONTROL HIDDEN STATE CHANGE ~~~")
		dd("ControlHiddenStateChange: %q  - hidden: %s - #filterTypes: %s, isGamePad: %s", tos(ctrlName), tos(not isShown), #filterTypes, tos(inputType))
	end
	local stateStr = (isShown == true and SCENE_SHOWN) or SCENE_HIDDEN --using the SCENE_* constants to unify the callback name for fragments, scenes and controls
	if isShown == true then
		--Call the code 1 frame later (zo_callLater with 0 ms -> next frame) so the controls' shown state (used within detectShownReferenceNow())
		--will be updated properly. Else it will fire too early and the control is still in another state, on it's way to state "Shown"!
		zo_callLater(function()
			libFilters_CallbackRaise(libFilters, filterTypes, ctrlRef, stateStr, inputType, LIBFILTERS_CON_TYPEOFREF_CONTROL, nil, specialPanelControlFunc, universalDeconData)
			checkIfSpecialCallbackNeedsToBeAdded(ctrlRef, stateStr, inputType, LIBFILTERS_CON_TYPEOFREF_CONTROL, ctrlName, specialPanelControlFunc)
		end, 0)
	else
		libFilters_CallbackRaise(libFilters, filterTypes, ctrlRef, stateStr, inputType, LIBFILTERS_CON_TYPEOFREF_CONTROL, nil, specialPanelControlFunc, universalDeconData)
		checkIfSpecialCallbackNeedsToBeAdded(ctrlRef, stateStr, inputType, LIBFILTERS_CON_TYPEOFREF_CONTROL, ctrlName, specialPanelControlFunc)
	end
end


local function createFragmentCallback(fragment, filterTypes, inputType)
	if isDebugEnabled then
		if fragment ~= nil then
			local fragmentName = getFragmentControlName(fragment)
			dv(">register fragment StateChange to: %s - #filterTypes: %s", tos(fragmentName), #filterTypes)
		else
			dv(">fragment is NIL! StateChange not possible - #filterTypes: %s", #filterTypes)
		end
	end
	--For controls which get created OnDeferredInitialize
	if fragment == nil then return end
	--Only add the callback once per input type
	if callbacksAdded[LIBFILTERS_CON_TYPEOFREF_FRAGMENT][fragment] == nil or (callbacksAdded[LIBFILTERS_CON_TYPEOFREF_FRAGMENT][fragment] ~= nil
			and not callbacksAdded[LIBFILTERS_CON_TYPEOFREF_FRAGMENT][fragment][inputType]) then
		fragment:RegisterCallback("StateChange",
				function(oldState, newState)
					if not libFilters.isInitialized then return end
					onFragmentStateChange(oldState, newState, filterTypes, fragment, inputType)
				end
		)
		callbacksAdded[LIBFILTERS_CON_TYPEOFREF_FRAGMENT][fragment] = callbacksAdded[LIBFILTERS_CON_TYPEOFREF_FRAGMENT][fragment] or {}
		callbacksAdded[LIBFILTERS_CON_TYPEOFREF_FRAGMENT][fragment][inputType] = filterTypes
	end
end
libFilters.CreateFragmentCallback = createFragmentCallback


local function createFragmentCallbacks()
	if isDebugEnabled then dd("-->CreateFragmentCallbacks---") end
	--Fragments
	--[fragment] = LF_* filterTypeConstant. 0 means no dedicated LF_* constant can be used and the filterType will be determined
	for inputType, callbackDataPerFilterType in pairs(callbacksUsingFragments) do
		for fragment, filterTypes in pairs(callbackDataPerFilterType) do
			createFragmentCallback(fragment, filterTypes, inputType)
		end
	end
end


local function createSceneCallbacks()
	if isDebugEnabled then dd("-->CreateSceneCallbacks---") end
	--Scenes
	--[scene] = LF_* filterTypeConstant. 0 means no dedicated LF_* constant can be used and the filterType will be determined
	for inputType, callbackDataPerFilterType in pairs(callbacksUsingScenes) do
		for scene, filterTypes in pairs(callbackDataPerFilterType) do
			if filterTypes ~= nil and #filterTypes > 0 then
				if isDebugEnabled then
					if scene ~= nil then
						local sceneName = getSceneName(scene)
						dv(">register scene StateChange to: %s - #filterTypes: %s", tos(sceneName), #filterTypes)
					else
						dv(">scene is NIL! StateChange not possible - #filterTypes: %s", #filterTypes)
					end
				end
				if scene == nil then return end
				--Only add the callback once per input type
				if callbacksAdded[LIBFILTERS_CON_TYPEOFREF_SCENE][scene] == nil or (callbacksAdded[LIBFILTERS_CON_TYPEOFREF_SCENE][scene] ~= nil
						and not callbacksAdded[LIBFILTERS_CON_TYPEOFREF_SCENE][scene][inputType]) then
					scene:RegisterCallback("StateChange",
							function(oldState, newState)
								if not libFilters.isInitialized then return end
								onSceneStateChange(oldState, newState, filterTypes, scene, inputType)
							end)
					callbacksAdded[LIBFILTERS_CON_TYPEOFREF_SCENE][scene] = callbacksAdded[LIBFILTERS_CON_TYPEOFREF_SCENE][scene] or {}
					callbacksAdded[LIBFILTERS_CON_TYPEOFREF_SCENE][scene][inputType] = filterTypes
				end
			end
		end
	end
end

function createControlCallback(controlRef, filterTypes, inputType, specialPanelControlFunc)
	local ctrlName = "n/a"
	local controlRefNew, _ = getCtrl(controlRef)
	if controlRefNew ~= controlRef then controlRef = controlRefNew end
	if isDebugEnabled then
		if controlRef ~= nil then
			ctrlName = getCtrlName(controlRef)
			dv(">register control %q OnShow/OnHide - #filterType: %s", tos(ctrlName), #filterTypes)
		else
			dv(">register control OnShow/OnHide: control is NIL! - #filterTypes: %s", #filterTypes)
			--For controls which get created OnDeferredInitialize
			return
		end
	end
	if not controlRef or not controlRef.SetHandler then
		if controlRef ~= nil then
			ctrlName = (isDebugEnabled == true and ctrlName) or getCtrlName(controlRef)
		end
		dfe("Callback control: Cannot set OnEffectivelyShown/OnHide handler for: %q, inputType: %s", tos(ctrlName), tos(inputType))
		return
	end

	--Only add the callback once per input type
	if callbacksAdded[LIBFILTERS_CON_TYPEOFREF_CONTROL][controlRef] == nil or (callbacksAdded[LIBFILTERS_CON_TYPEOFREF_CONTROL][controlRef] ~= nil
			and not callbacksAdded[LIBFILTERS_CON_TYPEOFREF_CONTROL][controlRef][inputType]) then

		--OnShow
		local onShowHandler = controlRef.GetHandler and controlRef:GetHandler("OnEffectivelyShown")
		if onShowHandler ~= nil then
			ZO_PostHookHandler(controlRef, "OnEffectivelyShown", function(ctrlRef)
				if not libFilters.isInitialized then return end
				onControlHiddenStateChange(true, filterTypes, ctrlRef, inputType, specialPanelControlFunc)
			end)
		else
			controlRef:SetHandler("OnEffectivelyShown", function(ctrlRef)
				if not libFilters.isInitialized then return end
				onControlHiddenStateChange(true, filterTypes, ctrlRef, inputType, specialPanelControlFunc)
			end)
		end

		--OnHide
		local onHideHandler = controlRef.GetHandler and controlRef:GetHandler("OnHide")
		if onHideHandler ~= nil then
			ZO_PostHookHandler(controlRef, "OnHide", function(ctrlRef)
				if not libFilters.isInitialized then return end
				onControlHiddenStateChange(false, filterTypes, ctrlRef, inputType, specialPanelControlFunc)
			end)
		else
			controlRef:SetHandler("OnHide", function(ctrlRef)
				if not libFilters.isInitialized then return end
				onControlHiddenStateChange(false, filterTypes, ctrlRef, inputType, specialPanelControlFunc)
			end)
		end
		callbacksAdded[LIBFILTERS_CON_TYPEOFREF_CONTROL][controlRef] = callbacksAdded[LIBFILTERS_CON_TYPEOFREF_CONTROL][controlRef] or {}
		callbacksAdded[LIBFILTERS_CON_TYPEOFREF_CONTROL][controlRef][inputType] = filterTypes
	end
end
libFilters.CreateControlCallback = createControlCallback


local function createControlCallbacks()
	if isDebugEnabled then dd("-->CreateControlCallbacks---") end
	--Controls
	--[control] = LF_* filterTypeConstant. 0 means no dedicated LF_* constant can be used and the filterType will be determined
	--[[
	--Old code before 2022-10-21
	for inputType, callbackDataPerFilterType in pairs(callbacksUsingControls) do
		for controlRef, filterTypes in pairs(callbackDataPerFilterType) do
			createControlCallback(controlRef, filterTypes, inputType)
		end
	end
	]]
	--New code since 2022-10-21, support for Universal Deconstruction where LF_SMITHING_DECONSTRUCTION e.g. will be used
	--as filterType but the control for the callback is not SMITHING.deconstructionPanel but UNIVERSAL_DECONSTRUCTION.control
	-->specialPanelControlFunc will take care of the correct detection of the control to register the callback to then
	for inputType, controlsCallbackDataOfInputType in pairs(callbacksUsingControls) do
--d(">inputType: " ..tos(inputType))
		for controlRef, controlVarCallbackData in pairs(controlsCallbackDataOfInputType) do
--d(">>controlRef: " ..tos(getCtrlName(controlRef)))
			for _, controlCallbackData in ipairs(controlVarCallbackData) do
--d(">>>filterTypes: " ..tos(controlCallbackData.filterTypes))
				createControlCallback(controlRef, controlCallbackData.filterTypes, inputType, controlCallbackData.specialPanelControlFunc)
			end
		end
	end
end


local function provisionerSpecialCallback(selfProvisioner, provFilterType, overrideDoShow)
	--Only fire if current scene is the provisioner scene (as PROVISIONER:OnTabFilterChanged also fires if enchanting scene is shown...)
	local currentFilterType = libFilters._currentFilterType
	local isInGamepadMode = IsGamepad()
	if (isInGamepadMode and not provisionerScene_GP:IsShowing()) or (not isInGamepadMode and not provisionerScene:IsShowing()) then
		return
	end
	local currentProvFilterType = (isInGamepadMode == true and provFilterType) or selfProvisioner.filterType
	local filterType = provisionerIngredientTypeToFilterType[currentProvFilterType]
	local doShow = (filterType ~= nil and true) or false


	local hideOldProvFilterType = (filterType ~= nil and currentFilterType ~= nil and currentFilterType ~= filterType and true)  or false

	if overrideDoShow ~= nil then
		doShow = overrideDoShow
		hideOldProvFilterType = false
	end

	local provisionerControl = selfProvisioner.control
	local provCallbackName = (isInGamepadMode and "Gamepad Provisioner") or "Provisioner"

	if isDebugEnabled then dd("~%s:OnTabFilterChanged: %s, filterType: %s, doShow: %s, hideOldProvFilterType: %s", tos(provCallbackName), tos(currentProvFilterType), tos(filterType), tos(doShow), tos(hideOldProvFilterType)) end
	if hideOldProvFilterType == true then
		onControlHiddenStateChange(false, { currentFilterType }, provisionerControl, isInGamepadMode)
	end
	if doShow == false or (doShow == true and filterType ~= nil) then
		onControlHiddenStateChange(doShow, { filterType }, provisionerControl, isInGamepadMode)
	end
end


local function createSpecialCallbacks()
	if isDebugEnabled then dd("-->CreateSpecialCallbacks---") end

	--[Keyboard mode]
	--LF_PROVISIONER_COOK, LF_PROVISIONER_BREW
	-->ZO_Provisioner:OnTabFilterChanged(filterData)
	--SecurePostHook(provisioner, "OnTabFilterChanged", function(selfProvisioner, filterTabData) --202203016 change to provisionerClass ZO_Provisioner
	SecurePostHook(provisionerClass, "OnTabFilterChanged", function(selfProvisioner, filterTabData)
		provisionerSpecialCallback(selfProvisioner, filterTabData, nil)
	end)

	--LF_ENCHANTING_CREATION, LF_ENCHANTING_EXTRACTION
	local enchantingControl = enchanting.control
	--SecurePostHook(enchanting, "OnModeUpdated", function() --202203016 change to enchantingClass ZO_Enchanting AND update AdvancedFilters AND FCOIS properly!
	SecurePostHook(enchantingClass, "OnModeUpdated", function()
		local enchantingMode = enchanting:GetEnchantingMode()
		if not enchantingMode then return end
		local filterType = enchantingModeToFilterType[enchantingMode]
		local doShow = (filterType ~= nil and true) or false
		if doShow == false then
			if libFilters._currentFilterType == nil and not checkForValidFilterTypeAtSamePanel(libFilters._lastFilterType, "enchanting") then
				if isDebugEnabled then dd("~ABORT Enchanting:OnModeUpdated - currentFilterType is nil and lastFilterType not matching crafting type") end
				libFilters._lastFilterTypeNoCallback = false
				return
			else
				local lastKnownFilterType = libFilters._lastFilterType
				if lastKnownFilterType ~= nil then
					if isDebugEnabled then dd("~Enchanting:OnModeUpdated - lastFilterType: %s[%s], noCallbackForLastFilterType: %s", tos(libFilters_GetFilterTypeName(libFilters, lastKnownFilterType)), tos(lastKnownFilterType), tos(libFilters._lastFilterTypeNoCallback)) end
					if libFilters._lastFilterTypeNoCallback == true then
						libFilters._lastFilterTypeNoCallback = false
						return
					end
				end
			end
		end

		local currentFilterType = libFilters._currentFilterType
		local hideOldEnchantingFilterType = (filterType ~= nil and currentFilterType ~= nil and currentFilterType ~= filterType and true)  or false
		if isDebugEnabled then dd("~Enchanting:OnModeUpdated: %s, filterType: %s, hideCurrentEnchantingFilterType: %s", tos(enchantingMode), tos(filterType), tos(hideOldEnchantingFilterType)) end
		if hideOldEnchantingFilterType == true then
			onControlHiddenStateChange(false, { currentFilterType }, enchantingControl, false)
		end
		if doShow == false or (doShow == true and filterType ~= nil) then
			onControlHiddenStateChange(doShow, { filterType }, enchantingControl, false)
		end
	end)

	--LF_ALCHEMY_CREATION
	--SecurePostHook(alchemy, "SetMode", function(alchemySelf, mode) --202203016 change to alchemygClass ZO_Alchemy
	SecurePostHook(alchemyClass, "SetMode", function(alchemySelf, mode)
		if not mode then return end
		local filterType = alchemyModeToFilterType[mode]
		local doShow = (filterType ~= nil and true) or false
		if doShow == false then
			--Will only be checked if the current filterType is not given, as else it would prevent a SCENE_HIDDEN callback for e.g. switching from alchemy creation to
			--alchemy recipes, if one has had opened the inventory in between and the libFilters._lastFilterType = LF_INVENTORY in that case -> LF_INVENTORY does not belong to
			--the current panel "alchemy" and LF_ALCHEMY_CREATION would not be firing it's HIDDEN callback then as one switches to the recipes tab (which is not supported and got no LF* constant)
			-->todo: Prevent if any panel was last opened that does not belong to the current crafting table (e.g. LF_VENDOR_REPAIR) and currentFilterType is nil because the last panel was hidden already - Also working?
			if libFilters._currentFilterType == nil and not checkForValidFilterTypeAtSamePanel(libFilters._lastFilterType, "alchemy") then
				if isDebugEnabled then dd("~ABORT Alchemy:SetMode - currentFilterType is nil and lastFilterType not matching crafting type") end
				libFilters._lastFilterTypeNoCallback = false
				return
			else
				local lastKnownFilterType = libFilters._lastFilterType
				if lastKnownFilterType ~= nil then
					if isDebugEnabled then dd("~Alchemy:SetMode - lastFilterType: %s[%s], noCallbackForLastFilterType: %s", tos(libFilters_GetFilterTypeName(libFilters, lastKnownFilterType)), tos(lastKnownFilterType), tos(libFilters._lastFilterTypeNoCallback)) end
					if libFilters._lastFilterTypeNoCallback == true then
						libFilters._lastFilterTypeNoCallback = false
						return
					end
				end
			end
		end

		local currentFilterType = libFilters._currentFilterType
		local hideOldAlchemyFilterType = (filterType ~= nil and currentFilterType ~= nil and currentFilterType ~= filterType and true)  or false
		if isDebugEnabled then dd("~Alchemy:SetMode: %s, filterType: %s, hideOldAlchemyFilterType: %s", tos(mode), tos(filterType), tos(hideOldAlchemyFilterType)) end
		if hideOldAlchemyFilterType == true then
			onControlHiddenStateChange(false, { currentFilterType }, alchemyCtrl, false)
		end
		if doShow == false or (doShow == true and filterType ~= nil) then
			onControlHiddenStateChange(doShow, { filterType }, alchemyCtrl, false)
		end
	end)


	--Crafting table close / ESC key
	--> The last shown panel needs to fire it's HIDE state now
	--LF_SMITHING*, LF_ALCHEMY*, LF_ENCHANTING*, LF_JEWELRY*, LF_PROVISIONER*
	local craftTypesOpenedAlready = {}
	local function eventCraftingStationInteractEnd(eventId, craftSkill)
		EM:UnregisterForEvent(GlobalLibName, EVENT_END_CRAFTING_STATION_INTERACT)
		--Was the last shown filterType a crafting table filterType?
		local currentFilterType = libFilters._currentFilterType
		local lastFilterType = libFilters._lastFilterType
		libFilters._lastFilterTypeNoCallback = false
		--local lastTab = libFilters._lastFilterTypeUniversalDeconTab
		local currentTab = libFilters._currentFilterTypeUniversalDeconTab
		local isUniversalDeconShown = (currentTab ~= nil and true) or false
		--Is the current filterType not given (e.g. at alchemy recipes tab) and the last filterType shown before was valid at the current crafting table?
		-->This would lead to a SCENE_HIDDEN callback firing for the lastFilterType the next time the crafting table opens, eben though the "recipes" tab at the crafting table would be
		-->re-opened and thus no callback would be needed (SCENE_HIDDEN for lastFilterType already fired as the recipestab was activated!)
		if isDebugEnabled then dd("<[EVENT_END_CRAFTING_STATION_INTERACT] craftSkill: %s, currentFilterType: %s, lastFilterType: %s, isUniversalDecon: %s",
				tos(craftSkill), tos(currentFilterType), tos(lastFilterType), tos(isUniversalDeconShown)) end

		local lastFilterTypeIsValidAtClosedCraftingTable = (lastFilterType ~= nil and checkForValidFilterTypeAtSamePanel(lastFilterType, nil, craftSkill)) or false
		if currentFilterType == nil and lastFilterTypeIsValidAtClosedCraftingTable == true then
			if isDebugEnabled then dv(">lastFilterType will \'not\' raise a HIDDEN callback at next crafting table open!") end
			--Set the flag that the lastFilterType will not fire a HIDDEN callback as the crafting table get's opened next time!
			libFilters._lastFilterTypeNoCallback = true
		--[[
		--The current filterType could be LF_INVENTORY due to opening the inventory via keybind directly from the crafting table.
		--The inventory_fragment callback will fire before the event_end_crafting_station_interact fires ... So the currentFilterType is LF_INVENTORY,
		--and the lastFilterType will be the crafting table's filterType  then
		-->Though this only seems to happen if PerfectPixel addon is active?
		elseif currentFilterType ~= nil and lastFilterTypeIsValidAtClosedCraftingTable == true and currentFilterType ~= lastFilterType then
			--Is the current filterType not valid at the closed craftingTable
			if not checkForValidFilterTypeAtSamePanel(currentFilterType, nil, craftSkill) then
				if isDebugEnabled then dv(">currentFilterType is no crafting filterType at the closed crafting table! lastFilterType will raise a HIDDEN callback now!") end
				libFilters_RaiseFilterTypeCallback(libFilters, lastFilterType, SCENE_HIDDEN, nil, true) --do not update current and last filterType in this case as they alredy are up2date
				return
			end
		]]
		end
		if not isCraftingFilterType[currentFilterType] then return end
		--Fire the HIDE callback of the last used crafting filterType
		local universalDeconTab = (isUniversalDeconShown == true and currentTab) or nil
		libFilters_RaiseFilterTypeCallback(libFilters, currentFilterType, SCENE_HIDDEN, nil, false, universalDeconTab)
		--Update the current -> last universal decon tab so closing the next "normal" non-universal crafting table wont tell us we are
		--closing universal decon again, because libFilters._currentFilterTypeUniversalDeconTab is still ~= nil!
		if isUniversalDeconShown == true then
			updateCurrentAndLastUniversalDeconVariables(nil, true) --reset  libFilters._currentFilterTypeUniversalDeconTab
		end
	end

	local function eventCraftingStationInteract(eventId, craftSkill)
		if isDebugEnabled then dd(">[EVENT_CRAFTING_STATION_INTERACT] craftSkill: %s", tos(craftSkill)) end
		EM:RegisterForEvent(GlobalLibName, EVENT_END_CRAFTING_STATION_INTERACT, eventCraftingStationInteractEnd)
		libFilters._lastFilterTypeNoCallback = false
		--Craftingtype was opened before already?
		if craftTypesOpenedAlready[craftSkill] ~= nil then
			--Provisioner?
			if craftSkill == CRAFTING_TYPE_PROVISIONING then
				--Raise the callback for SHOWN of the last opened provisioner panel
				provisionerSpecialCallback(provisioner, nil, true) --last param says "show"
			end
		end
		craftTypesOpenedAlready[craftSkill] = true

		--Universal Deconstruction check
		local isInGamepadMode = IsGamepad()
		wasUniversalDeconPanelGPEventCraftingBeginUsed = false
		--If Gamepad Universal Deconstruction was shown before the first open of the panel will hide, show, hide the lastPanel (e.g. LF_INVENTORY)
		--and the universal decon tab somehow. Prevent this by setting a variable here and clering it at the UniversalDeconGamepad.deconstructionPanel.inventoy:OnFilterChanged
		--callback again
		if isInGamepadMode and wasUniversalDeconPanelShownBefore == true then
			wasUniversalDeconPanelGPEventCraftingBeginUsed = true
		end
	end
	EM:RegisterForEvent(GlobalLibName, EVENT_CRAFTING_STATION_INTERACT, eventCraftingStationInteract)


--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

	--[Gamepad mode]
	--LF_PROVISIONER_COOK, LF_PROVISIONER_BREW
	-->ZO_Provisioner:OnTabFilterChanged(filterData)
	SecurePostHook(provisioner_GP, "OnTabFilterChanged", function(selfProvisioner, filterType)
		local lastKnownFilterType = libFilters._lastFilterType
		if lastKnownFilterType ~= nil then
			if isDebugEnabled then dd("~Gamepad Provisioner:OnTabFilterChanged - lastFilterType: %s[%s], noCallbackForLastFilterType: %s", tos(libFilters_GetFilterTypeName(libFilters, lastKnownFilterType)), tos(lastKnownFilterType), tos(libFilters._lastFilterTypeNoCallback)) end
			if libFilters._lastFilterTypeNoCallback == true then
				libFilters._lastFilterTypeNoCallback = false
				return
			end
		end

		provisionerSpecialCallback(selfProvisioner, filterType, nil)
	end)


end

local function createCallbacks()
	if isDebugEnabled then dd("---CreateCallbacks---") end
	if not libFilters.isInitialized and not callbacksCreated then return end

	createSceneCallbacks()
	createFragmentCallbacks()
	createControlCallbacks()
	createSpecialCallbacks()

	callbacksCreated = true
	if isDebugEnabled then dd(">Callbacks were created") end
end


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
	if not libFilters.isInitialized then return end

	if isDebugEnabled then dd("---InstallHelpers---") end
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
	if isDebugEnabled then dd("---ApplyFixesEarly---") end
	if isDebugEnabled then dd(">Early fixes were applied") end
end

--Fixes which are needed AFTER EVENT_ADD_ON_LOADED hits
local function applyFixesLate()
	if isDebugEnabled then dd("---ApplyFixesLate---") end
	--[[
	if not libFilters.isInitialized or fixesLateApplied then return end
	fixesLateApplied = true
	]]

	--Overwrite the rowSelected callback function of the keyboard research dialog as it got no nil check for the selectedData
	--table and raises errors as ZO_ScrollList_SelectData is used with nil data, or dialog:ClearList() is called
	local researchPopupDialogCustomControl = ESO_Dialogs["SMITHING_RESEARCH_SELECT"].customControl()
	ZO_PreHookHandler(researchPopupDialogCustomControl, "OnShow", function()
		if researchPopupDialogCustomControl ~= nil then
			if libFilters_IsListDialogShown(libFilters, nil, researchPanel.control) then
				zo_callLater(function()
					fixResearchDialogRowOnItemSelectedCallback()
				end, 100)
			end
		end
	end)

	if isDebugEnabled then dd(">Late fixes were applied") end
end

--Fixes which are needed AFTER EVENT_PLAYER_ACTIVATED hits
local function applyFixesLatest()
	if isDebugEnabled then dd("---ApplyFixesLatest---") end
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
			if isDebugEnabled then
				dd("ApplyBackpackLayout-CraftBag hidden: %s", tos(crafBagIsHidden))
			end
			if crafBagIsHidden == true or inventories[invTypeCraftBag].additionalFilter ~= nil then return end
			local additionalCraftBagFilter = kbc.invBackpackFragment.layoutData.additionalCraftBagFilter
			if additionalCraftBagFilter == nil then return end
			inventories[invTypeCraftBag].additionalFilter = additionalCraftBagFilter
		end)
	end

	fixesLatestApplied = true
	if isDebugEnabled then dd(">Latest fixes were applied") end
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
	createCallbacks()

	EM:RegisterForEvent(MAJOR .. "_EVENT_PLAYER_ACTIVATED", EVENT_PLAYER_ACTIVATED, eventPlayerActivatedCallback)
end

------------------------------------------------------------------------------------------------------------------------
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

--**********************************************************************************************************************
-- LIBRARY LOADING / INITIALIZATION
--**********************************************************************************************************************
--Function needed to be called from your addon to start the LibFilters instance and enable the filtering!
function libFilters:InitializeLibFilters()
	if isDebugEnabled then dd("!-!-!-!-! InitializeLibFilters - %q !-!-!-!-!", tos(libFilters.isInitialized)) end
	if libFilters.isInitialized == true then return end
	libFilters.isInitialized = true

	--Install the helpers, which override ZOs vanilla code -> See file helpers.lua
	installHelpers()

	--Hook into the scenes/fragments/controls to apply the filter function "runFilters" to the existing .additionalFilter
	--and other existing filters, and to add the libFilters filterType to the .LibFilters3_filterType tag (to identify the
	--inventory/control/fragment again)
	applyAdditionalFilterHooks()

	--Apply the late fixes if not already done
	applyFixesLate()

	--Create the custom gamepad fragments and their needed hooks
	createCustomGamepadFragmentsAndNeededHooks()

	--Create the callbacks if not already done
	createCallbacks()


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

if isDebugEnabled then dd("LIBRARY MAIN FILE - END") end
