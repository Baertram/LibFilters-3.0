--======================================================================================================================
-- 													LibFilters 3.0
--======================================================================================================================

------------------------------------------------------------------------------------------------------------------------
--Bugs/Todo List for version: 3.0 r3.0 - Last updated: 2021-12-06, Baertram
------------------------------------------------------------------------------------------------------------------------
--Bugs total: 				5
--Feature requests total: 	0

--[Bugs]
-- #1) 2022-01-03, Baertram: Gamepad mode - returning from craftbag to the normal inv does not trigger the custom inventory fragment's show state callback
-- #2) 2022-01-03, Baertram: Gamepad mode - callback for filterType LF_INVENTORY does not fire as callback get's added to the fragment as the inventory lists get initialized the 1st time
-- #3) 2022-01-03, Baertram: Keyboard mode - CraftBagExtended CRAFTBAG_FRAGMENT (at mail send panel e.g.) will fire it's "shown" callback first, and then LF_MAIL_SEND callback will fire too afterwards.
--	   Any way to suppress the BACKPACK_MAIL_SEND_LAYOUT_FRAGMENT callback fire?


--[Feature requests]
-- #f1)


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

--local getCurrentScene = SM.GetCurrentScene
local getScene = SM.GetScene

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
libFilters._currentFilterType 			= nil
libFilters._currentFilterTypeReferences = nil
--Cashed "last" data, before current (placeholders, currently nil)
libFilters._lastFilterType 				= nil
libFilters._lastFilterTypeReferences 	= nil


--LibFilters local speedup and reference variables
--Overall constants & mapping
local constants = 					libFilters.constants
local mapping = 					libFilters.mapping
local callbacks = 					mapping.callbacks
local callbackPattern = 			libFilters.callbackPattern
local callbacksUsingScenes = 		callbacks.usingScenes
local callbacksUsingFragments = 	callbacks.usingFragments
local callbacksUsingControls = 		callbacks.usingControls


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
local guildStoreSellFragment   = 	kbc.guildStoreSellFragment
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
local craftbagRefsFragment = LF_FilterTypeToCheckIfReferenceIsHidden[false][LF_CRAFTBAG]["fragment"]


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


--Other addons
local cbeSupportedFilterPanels  = constants.cbeSupportedFilterPanels

--The costants for the reference types
local typeOfRefConstants = constants.typeOfRef
local LIBFILTERS_CON_TYPEOFREF_CONTROL 	= typeOfRefConstants[1]
local LIBFILTERS_CON_TYPEOFREF_SCENE 	= typeOfRefConstants[2]
local LIBFILTERS_CON_TYPEOFREF_FRAGMENT = typeOfRefConstants[3]
local LIBFILTERS_CON_TYPEOFREF_OTHER 	= typeOfRefConstants[99]
local typeOfRefToName    = constants.typeOfRefToName

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


if libFilters.debug then dd("LIBRARY MAIN FILE - START") end


------------------------------------------------------------------------------------------------------------------------
--LOCAL HELPER FUNCTIONS
------------------------------------------------------------------------------------------------------------------------
--Copy the current filterType to lastFilterType (same for the referenceVariables table) if the filterType / refVariables
--table needs an update
local function updateLastAndCurrentFilterType(lFilterTypeDetected, lReferencesToFilterTyp, doNotUpdateLast)
	doNotUpdateLast = doNotUpdateLast or false
	if not doNotUpdateLast then
		local currentFilterTypeBefore 			= libFilters._currentFilterType
		if currentFilterTypeBefore ~= nil then
			libFilters._lastFilterType 				= currentFilterTypeBefore
		end
		local currentFilterTypeReferencesBefore = libFilters._currentFilterTypeReferences
		if currentFilterTypeReferencesBefore ~= nil then
			libFilters._lastFilterTypeReferences 	= currentFilterTypeReferencesBefore
		end
	end
	libFilters._currentFilterType 				= lFilterTypeDetected
	libFilters._currentFilterTypeReferences 	= lReferencesToFilterTyp
end


local function checkIfControlSceneFragmentOrOther(refVar)
	local retVar
	--Scene or fragment
	if refVar.sceneManager and refVar.state then
		if refVar.name ~= nil or refVar.fragments ~= nil then
			retVar = LIBFILTERS_CON_TYPEOFREF_SCENE -- Scene
		else
			retVar = LIBFILTERS_CON_TYPEOFREF_FRAGMENT -- Fragment
		end
	--Control
	elseif refVar.control then
		retVar = LIBFILTERS_CON_TYPEOFREF_CONTROL -- Control
	--Other
	else
		retVar = LIBFILTERS_CON_TYPEOFREF_OTHER -- Other, e.g. boolean
	end
	if libFilters.debug then dv("!checkIfControlSceneFragmentOrOther - refVar %q: %s", tos(refVar), tos(retVar)) end
	return retVar
end

local function getCtrl(retCtrl)
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
	return ctrlToCheck, checkType
end

local function checkIfRefVarIsShown(refVar)
	if not refVar then return false, nil end
	local refType = checkIfControlSceneFragmentOrOther(refVar)
	--Control
	local isShown = false
	if refType == LIBFILTERS_CON_TYPEOFREF_CONTROL then
		local refCtrl = getCtrl(refVar)
		if refCtrl == nil or refCtrl.IsHidden == nil then
			isShown = false
		else
			isShown = not refCtrl:IsHidden()
		end
	--Scene
	elseif refType == LIBFILTERS_CON_TYPEOFREF_SCENE then
		if libFilters.debug then dv("!checkIfRefVarIsShown - scene state: %q", tos(refVar.state)) end
		isShown = ((refVar.state == SCENE_SHOWN and true) or (refVar.IsShowing ~= nil and refVar:IsShowing())) or false
	--Fragment
	elseif refType == LIBFILTERS_CON_TYPEOFREF_FRAGMENT then
		if libFilters.debug then dv("!checkIfRefVarIsShown - fragment state: %q", tos(refVar.state)) end
		isShown = ((refVar.state == SCENE_FRAGMENT_SHOWN and true) or (refVar.IsShowing ~= nil and refVar:IsShowing())) or false
	--Other
	elseif refType == LIBFILTERS_CON_TYPEOFREF_OTHER then
		if type(refVar) == "boolean" then
			isShown = refVar
		else
			isShown = false
		end
	end
	if libFilters.debug then dv("!checkIfRefVarIsShown - refVar %q: %s, refType: %s", tos(refVar), tos(isShown), tos(refType)) end
	return isShown, refVar, refType
end


--[[
--Get the currently shown scene and sceneName
local function getCurrentSceneInfo()
	if not SM then return nil, "" end
	local currentScene = getCurrentScene(SM)
	local currentSceneName = (currentScene ~= nil and currentScene.name) or ""
	if libFilters.debug then dd("getCurrentSceneInfo - currentScene: %q, name: %q", tos(currentScene), tos(currentSceneName)) end
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
	if libFilters.debug then dv("getSceneName - filterType %s: %q, retScene: %s", tos(filterType), tos(retSceneName), tos(retScene)) end
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
		if libFilters.debug then dv("!isListDialogShownWrapper - filterType %s: %s, gamepadMode: %s, error: %s", tos(filterType), tos(false), tos(isInGamepadMode), "filterTypeData is nil!") end
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


local function getFragmentControlName(fragment)
	if fragment ~= nil then
		local fragmentControl
		if fragment.name ~= nil then
			return fragment.name
		elseif fragment._name ~= nil then
			return fragment._name
		elseif fragment.GetControl then
			fragmentControl = getCtrl(fragment:GetControl())
		elseif fragment.control then
			fragmentControl = getCtrl(fragment.control)
		end

		if fragmentControl ~= nil then
			local fragmentControlName = (fragmentControl.GetName ~= nil and fragmentControl:GetName())
					or (fragmentControl.name ~= nil and fragmentControl.name)
			if fragmentControlName ~= nil and fragmentControlName ~= "" then return fragmentControlName end
		end
	end
	return "n/a"
end

local function getSceneName(scene)
	if scene ~= nil then
		if scene.GetName then
			return scene:GetName()
		else
			if scene.name ~= nil then
				local sceneName = scene.name
				if sceneName ~= "" then return sceneName end
			end
		end
	end
	return "n/a"
end

local function getCtrlName(ctrlVar)
	local ctrlName = (ctrlVar.GetName ~= nil and ctrlVar:GetName()) or (ctrlVar.name ~= nil and ctrlVar.name)
	if ctrlName ~= nil and ctrlName ~= "" then return ctrlName end
	return "n/a"
end

local function getTypeOfRefName(typeOfRef, filterTypeRefToHook)
	if typeOfRef == LIBFILTERS_CON_TYPEOFREF_CONTROL then
		return getCtrlName(filterTypeRefToHook)
	elseif typeOfRef == LIBFILTERS_CON_TYPEOFREF_SCENE then
		return getSceneName(filterTypeRefToHook)
	elseif typeOfRef == LIBFILTERS_CON_TYPEOFREF_FRAGMENT then
		return getFragmentControlName(filterTypeRefToHook)
	end
	return "n/a"
end


--Check if a control is assigned to the filterType and inputType and if it is currently shown/hidden
--returns boolean isShown), controlReference controlWhichIsShown
local function isControlShown(filterType, isInGamepadMode)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	local filterTypeData = LF_FilterTypeToCheckIfReferenceIsHidden[isInGamepadMode][filterType]
	if filterTypeData == nil then
		if libFilters.debug then dv("!isControlShown - filterType %s: %s, gamepadMode: %s, error: %s", tos(filterType), tos(false), tos(isInGamepadMode), "filterTypeData is nil!") end
		return false, nil
	end
	local retCtrl = filterTypeData["control"]

	local ctrlToCheck, checkType = getCtrl(retCtrl)
	if ctrlToCheck == nil or (ctrlToCheck ~= nil and ctrlToCheck.IsHidden == nil) then
		if libFilters.debug then dv("!isControlShown - filterType %s: %s, gamepadMode: %s, error: %s", tos(filterType), tos(false), tos(isInGamepadMode), "no control/listView with IsHidden function found!") end
		return false, nil
	end
	local isShown = not ctrlToCheck:IsHidden()
	if libFilters.debug then dv("!isControlShown - filterType %s, isShown: %s, gamepadMode: %s, retCtrl: %s, checkType: %s", tos(filterType), tos(isShown), tos(isInGamepadMode), tos(ctrlToCheck), tos(checkType)) end
	return isShown, ctrlToCheck
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
	local isDebugEnabled = libFilters.debug
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
		dv("!getFilterTypeByFilterTypeRespectingCraftType-source: %q, target: %q, craftType: %s",
			tos(filterTypeSource), tos(filterTypeTarget), tos(craftType))
	end
	return filterTypeTarget, craftType
end

--is the filterType passed in a valid supported CraftBagExtended filterType?
local function isCraftBagExtendedSupportedPanel(filterTypePassedIn)
	local isSupportedFilterPanel = ZO_IsElementInNumericallyIndexedTable(cbeSupportedFilterPanels, filterTypePassedIn)
	if libFilters.debug then
		dv(">isCraftBagExtendedSupportedPanel - filterType: %s = %s", tos(filterTypePassedIn), tos(isSupportedFilterPanel))
	end
	return isSupportedFilterPanel
end


--Check if CraftBagExtended addon is enabled and if any of the supported extra panels/fragments are shown
--and if the extra menu buttons of CBE are clicked to currently show the craftbag, and if the fragment's layoutData of
--the CBE fragments hooked use the same number filterType as passed in
local function craftBagExtendedCheckForCurrentModule(filterType)
	local isDebugEnabled = libFilters.debug
	if isDebugEnabled then dv("!craftBagExtendedCheckForCurrentModule - filterTypePassedIn: " .. tos(filterType)) end
	local cbe = CraftBagExtended
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
	--Get the constants.defaultAttributeToStoreTheFilterType (.LibFilters3_filterType) from the layoutdata
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

--Check if a control/fragment/scene is shown/hidden (depending on parameter "checkIfHidden") or if any special check function
--needs to be called to do additional checks, or an overall special forced check function needs to be always called at the end
--of all checks (e.g. for crafting -> check if jewelry crafting or other)
local function checkIfShownNow(filterTypeControlAndOtherChecks, isInGamepadMode, checkIfHidden, skipSpecialChecks)
	checkIfHidden = checkIfHidden or false
	skipSpecialChecks = skipSpecialChecks or false
	local isDebugEnabled = libFilters.debug
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
							--local paramsForFilterTypeSpecialCheck = {} --todo create  function to get needed parameters for the special check per filterType?
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

local function detectShownReferenceNow(p_filterType, isInGamepadMode, checkIfHidden, skipSpecialChecks)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	checkIfHidden = checkIfHidden or false
	skipSpecialChecks = skipSpecialChecks or false
	local lFilterTypeDetected = nil
	local lReferencesToFilterType = {}
	local isDebugEnabled = libFilters.debug
	if isDebugEnabled then dd(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>") end
	if isDebugEnabled then dd("!detectShownReferenceNow - filterTypePassedIn: %s, isInGamepadMode: %s",
			tos(p_filterType), tos(isInGamepadMode) ) end

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
		return lReferencesToFilterType, lFilterTypeDetected
	end

	--Dynamically get the filterType via the currently shown control/fragment/scene/special check and specialForced check
	for _, filterTypeControlAndOtherChecks in ipairs(LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[isInGamepadMode]) do
		lReferencesToFilterType, lFilterTypeDetected = checkIfShownNow(filterTypeControlAndOtherChecks, isInGamepadMode, checkIfHidden, skipSpecialChecks)
		if lFilterTypeDetected ~= nil and lReferencesToFilterType ~= nil and #lReferencesToFilterType > 0 then
			if isDebugEnabled then
				dd("<<< FOR .. in checkTypes LOOP, found filterType: %q <<<<<<<<<<<<<<<<<<<<<<<<", tos(lFilterTypeDetected))
			end
			--updateLastAndCurrentFilterType(lFilterTypeDetected, lReferencesToFilterType, false)
			--Abort the for ... do loop now as data was found
			return lReferencesToFilterType, lFilterTypeDetected
		end
	end --for _, filterTypeControlAndOtherChecks in ipairs(LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[isInGamepadMode]) do

	if isDebugEnabled then
		dd("<found filterType: %s", tos(lFilterTypeDetected))
		dd("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
	end
	return lReferencesToFilterType, lFilterTypeDetected
end

--Is the filterType cached at libFilters._currentFilterType (set during call to updater functions and other functions)
--still the valid one, and it's reference is still shown?
local function checkIfCachedFilterTypeIsStillShown(isInGamepadMode)
	local isDebugEnabled = libFilters.debug
	if libFilters._currentFilterType ~= nil then
		local filterTypeReference, filterTypeShown = detectShownReferenceNow(libFilters._currentFilterType, isInGamepadMode, false, false)
		if filterTypeReference ~= nil and filterTypeShown ~= nil and filterTypeShown == libFilters._currentFilterType then
			if isDebugEnabled then dd("!checkIfCachedFilterTypeIsStillShown %q: %s", tos(filterTypeShown), "YES") end
			--updateLastAndCurrentFilterType(filterTypeShown, filterTypeReference, true)
			return filterTypeReference, filterTypeShown
		end
	end
	if isDebugEnabled then dd("!checkIfCachedFilterTypeIsStillShown - currentFilterType %q: No", tos(libFilters._currentFilterType)) end
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
		dv("[U]SafeUpdateList, inv: %s, name: %s", tos(object), tos(updatedName))
	end
	local isMouseVisible = SM:IsInUIMode()
	if isMouseVisible then HideMouse() end
	object:UpdateList(...)
	if isMouseVisible then ShowMouse() end
end

--Function to update a ZO_ListDialog1 dialog's list contents
local function dialogUpdaterFunc(listDialogControl)
	if libFilters.debug then dv("[U]dialogUpdaterFunc, listDialogControl: %s", (listDialogControl ~= nil and listDialogControl.GetName ~= nil and tos(listDialogControl:GetName()) or "listDialogName: n/a")) end
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
	if libFilters.debug then dv("[U]updateKeyboardPlayerInventoryType - invType: %s", tos(invType)) end
	SafeUpdateList(playerInv, invType)
end


------------------------------------------------------------------------------------------------------------------------
--KEYBOARD & GAMEPAD updater functions
------------------------------------------------------------------------------------------------------------------------
--Updater function for a crafting inventory in keyboard and gamepad mode
local function updateCraftingInventoryDirty(craftingInventory)
	if libFilters.debug then dv("[U]updateCraftingInventoryDirty - craftingInventory: %s", tos(craftingInventory)) end
	craftingInventory.inventory:HandleDirtyEvent()
end

-- update for LF_BANK_DEPOSIT/LF_GUILDBANK_DEPOSIT/LF_HOUSE_BANK_DEPOSIT/LF_MAIL_SEND/LF_TRADE/LF_BANK_WITHDRAW/LF_GUILDBANK_WITHDRAW/LF_HOUSE_BANK_WITHDRAW
local function updateFunction_GP_ZO_GamepadInventoryList(gpInvVar, list, callbackFunc)
	if libFilters.debug then dv("[U]updateFunction_GP_ZO_GamepadInventoryList - gpInvVar: %s, list: %s, callbackFunc: %s", tos(gpInvVar), tos(list), tos(callbackFunc)) end
	-- prevent UI errors for lists created OnDeferredInitialization
	if not gpInvVar or not gpInvVar[list] then return end
	local TRIGGER_CALLBACK = true
	gpInvVar[list]:RefreshList(TRIGGER_CALLBACK)
	if callbackFunc then callbackFunc() end
end

-- update for LF_GUILDSTORE_SELL/LF_VENDOR_BUY/LF_VENDOR_BUYBACK/LF_VENDOR_REPAIR/LF_VENDOR_SELL/LF_FENCE_SELL/LF_FENCE_LAUNDER gamepad
local function updateFunction_GP_UpdateList(gpInvVar)
	if libFilters.debug then dv("[U]updateFunction_GP_UpdateList - gpInvVar: %s", tos(gpInvVar)) end
	-- prevent UI errors for lists created OnDeferredInitialization
	if not gpInvVar then return end
	gpInvVar:UpdateList()
end

-- update function for LF_VENDOR_BUY/LF_VENDOR_BUYBACK/LF_VENDOR_REPAIR/LF_VENDOR_SELL/LF_FENCE_SELL/LF_FENCE_LAUNDER gamepad
local function updateFunction_GP_Vendor(storeMode)
	if libFilters.debug then dv("[U]updateFunction_GP_Vendor - storeMode: %s", tos(storeMode)) end
	if not store_componentsGP then return end
	updateFunction_GP_UpdateList(store_componentsGP[storeMode].list)
end

-- update for LF_INVENTORY/LF_INVENTORY_COMPANION/LF_INVENTORY_QUEST gamepad
local function updateFunction_GP_ItemList(gpInvVar)
	if libFilters.debug then dv("[U]updateFunction_GP_ItemList - gpInvVar: %s", tos(gpInvVar)) end
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
	if libFilters.debug then dv("[U]updateFunction_GP_CraftBagList - gpInvVar: %s", tos(gpInvVar)) end
	if not gpInvVar.craftBagList then return end
	gpInvVar:RefreshCraftBagList()
	gpInvVar:RefreshItemActions()
end

-- update for LF_ENCHANTING_CREATION/LF_ENCHANTING_EXTRACTION gamepad
local function updateFunction_GP_CraftingInventory(craftingInventory)
	if libFilters.debug then dv("[U]updateFunction_GP_CraftingInventory - craftingInventory: %s", tos(craftingInventory)) end
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
		if libFilters.debug and gpc.invGuildStoreSell_GP == nil then dv("[U]updateFunction LF_GUILDSTORE_SELL: Added reference to GAMEPAD_TRADING_HOUSE_SELL") end
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
			if libFilters.debug then dv("[U]updateFunction_GP_QUICKSLOT - Not supported yet!") end
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
		if libFilters.debug then dv("[U]updateFunction GUILDSTORE_BROWSE: Not supported yet") end
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
		if libFilters.debug then dv("[U]updateFunction SMITHING_CREATION: Not supported yet") end
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
			if libFilters.debug then dv("[U]updateFunction_GP_SMITHING_RESEARCH - SMITHING_GAMEPAD.researchPanel:Refresh() called") end
			researchPanel_GP:Refresh()
		else
			if libFilters.debug then dv("[U]updateFunction_Keyboard_SMITHING_RESEARCH - SMITHING.researchPanel:Refresh() called") end
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
			if libFilters.debug then dv("[U]updateFunction_GP_SMITHING_RESEARCH_DIALOG - GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE:FireCallbacks(StateChange, nil, SCENE_SHOWING) called") end
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
		if libFilters.debug then dv("[U]updateFunction PROVISIONING_COOK: Not supported yet") end
	end,
	PROVISIONING_BREW = function()
	--[[
		--Not supported yet
		if IsGamepad() then
		else
		end
	]]
		if libFilters.debug then dv("[U]updateFunction PROVISIONING_BREW: Not supported yet") end
	end,
	RETRAIT = function()
		if IsGamepad() then
			if libFilters.debug then dv("[U]updateFunction_GP_RETRAIT: ZO_RETRAIT_STATION_RETRAIT_GAMEPAD:Refresh() called") end
			gpc.retrait_GP:Refresh() -- ZO_RETRAIT_STATION_RETRAIT_GAMEPAD
		else
			updateCraftingInventoryDirty(kbc.retrait)
		end
	end,
	RECONSTRUCTION = function()
		if IsGamepad() then
			if libFilters.debug then dv("[U]updateFunction_GP_RECONSTRUCTION: ZO_RETRAIT_STATION_RECONSTRUCT_GAMEPAD:RefreshFocusItems() called") end
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
	if libFilters.debug then dv("GetFilterTypeName - filterType: %q", tos(filterType)) end
	if not filterType then
		dfe("Invalid argument to GetFilterTypeName(%q).\n>Needed format is: number LibFiltersLF_*FilterType",
			tos(filterType))
		return
	end
	return libFiltersFilterConstants[filterType] or ""
end
libFilters_GetFilterTypeName = libFilters.GetFilterTypeName


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
	local currentFilterTypeReferences
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
	--Was the filterType referenceVariableTable updated at calling function already?
	if not noRefUpdate then
		currentFilterTypeReferences = libFilters_GetFilterTypeReferences(libFilters, filterTypeDetected)
		--updateLastAndCurrentFilterType(filterTypeDetected, currentFilterTypeReferences, false)
	end

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

	--updateLastAndCurrentFilterType(nil, filterTypeReference, false)

	local currentFilterType = filterType
	--FilterType was not detected yet (e.g. from cached filterType currently shown)
	if currentFilterType == nil then
		--Check each shown variable for the LibFilters filterType LF_* constant
		for _, shownVariable in ipairs(filterTypeReference) do
			--Do not update the references to libFilters._currentFilterTypeReferences as it was done above already
			currentFilterType = libFilters_GetCurrentFilterTypeForInventory(libFilters, shownVariable, true)
			if currentFilterType ~= nil then
				if isDebugEnabled then dd(">currentFilterType: %s", tos(currentFilterType)) end
				return currentFilterType
			end
		end
	end

	--updateLastAndCurrentFilterType(currentFilterType, nil, true)

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
	if libFilters.debug then dd("IsAllFilterRegistered-%q", tos(filterTag)) end
	if not filterTag then
		dfe("Invalid arguments to IsAllFilterRegistered(%q).\n>Needed format is: String uniqueFilterTag",
			tos(filterTag))
		return
	end
	local filterCallbacks = filters[LF_FILTER_ALL]
	return filterCallbacks[filterTag] ~= nil
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
	local filterCallbacks = filters[filterType]
	if not filterTag or not filterType or not filterCallbacks or type(filterCallback) ~= "function" then
		dfe(registerFilteParametersErrorStr, "RegisterFilter", tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError))
		return
	end
	noInUseError = noInUseError or false
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
	if libFilters.debug then dd("RegisterFilterIfUnregistered-%q,%q,%q,%s", tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError)) end
	local filterCallbacks = filters[filterType]
	if not filterTag or not filterType or not filterCallbacks or type(filterCallback) ~= "function" then
		dfe(registerFilteParametersErrorStr, "RegisterFilterIfUnregistered",
				tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError))
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
	if libFilters.debug then dv("[U-API]RequestUpdateByName-%q,%s,%s", tos(updaterName), tos(delay), tos(filterType)) end
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
	if libFilters.debug then dv(">callbackName: %s, delay: %s", tos(callbackName), tos(delay)) end

	local function updateFiltersNow()
		EM:UnregisterForUpdate(callbackName)
		if libFilters.debug then dv("!!!RequestUpdateByName->Update called now, updaterName: %s, filterType: %s, delay: %s", tos(updaterName), tos(filterType), tos(delay)) end

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
	if libFilters.debug then dd("[U-API]RequestUpdate filterType: %q, updaterName: %s, delay: %s", tos(filterType), tos(updaterName), tos(delay)) end
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
	if not filterType or filterType == "" then
		dfe("Invalid arguments to GetFilterTypeReferences(%q, %s).\n>Needed format is: number LibFiltersLF_*FilterType, OPTIONAL boolean isInGamepadMode",
				tos(filterType), tos(isInGamepadMode))
		return
	end
	if libFilters.debug then dd("GetFilterTypeReferences filterType: %q, %s", tos(filterType), tos(isInGamepadMode)) end
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
	if libFilters.debug then dd("GetCurrentFilterTypeReference filterType: %q, %s", tos(filterType), tos(isInGamepadMode)) end

	--Check if the cached "current filterType" is given and still shown -> Only if no filterType was explicitly passed in
	if filterType == nil then
		local filterTypeReference, filterTypeShown = checkIfCachedFilterTypeIsStillShown(filterType, isInGamepadMode)
		if filterTypeReference ~= nil and filterTypeShown ~= nil then
			return filterTypeReference, filterTypeShown
		end
	end
	------------------------------------------------------------------------------------------------------------------------

	--CraftBagExtended addon is active? We got a currently shown fragment of CBE then e.g. but the "parent" filterType will be something like
	--LF_MAIL_SEND, LF_TRADE, LF_GUILDSTORE_SELL etc., and needs to be used for the reference then
	--[[
	if CraftBagExtended ~= nil then
		--TODO really needed to check here? Or just loop over the LF_FilterTypeToReference[isInGamepadMode] and check if they are shown
	end
	]]
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
	local lReferencesToFilterType, lFilterTypeDetected = detectShownReferenceNow(LF_INVENTORY, isInGamepadMode, false, true)
	if lReferencesToFilterType ~= nil and lFilterTypeDetected == LF_INVENTORY then
		return true
	end
	return false
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
		--isInvShown = not playerInvCtrl:IsHidden()
		return isInventoryBaseShown(false), nil
	end
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
	local filterTypeName = libFilters_GetFilterTypeName(libFilters, filterType)
	local filterTypeNameAndTypeText = (tos(filterTypeName) .. " [" .. tos(filterType) .. "]")
	if libFilters.debug then dd("HookAdditionalFilter - %q, %s", tos(filterTypeNameAndTypeText), tos(hookKeyboardAndGamepadMode)) end
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
		if libFilters.debug then
			dv(">____________________>")
			dv("[HookNow]filterType %q, isInGamepadMode: %s, keyboardAndGamepadMode: %s",
				filterTypeNameAndTypeText, tos(isInGamepadMode), tos(hookKeyboardAndGamepadMode)) end

		if #inventoriesToHookForLFConstant_Table == 0 then return end

		for _, filterTypeRefToHook in ipairs(inventoriesToHookForLFConstant_Table) do
			if filterTypeRefToHook ~= nil then
				local typeOfRef = checkIfControlSceneFragmentOrOther(filterTypeRefToHook)
				local typeOfRefStr = typeOfRefToName[typeOfRef]
				if libFilters.debug then
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
						if originalFilterType == "function" then
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
					if originalFilterType == "function" then
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
		--local cbeSpecialAddonChecks = "CraftBagExtended"
		--local isInGamepadMode = IsGamepad()
		for _, filterTypeToCheck in ipairs(filterTypesToCheck) do
			referencesToFilterType, filterTypeParent = nil, nil
			referencesToFilterType, filterTypeParent = craftBagExtendedCheckForCurrentModule(filterTypeToCheck)
			if referencesToFilterType ~= nil and filterTypeParent ~= nil then
				if libFilters.debug then dv(">filterTypeChecked: %s, filterTypeParent: %q",
						tos(filterTypeToCheck), tos(filterTypeParent)) end
				return true
			end
		end
	end
	if libFilters.debug then dv(">CBE: %s, filterTypeParent: %q",
			tos(CraftBagExtended ~= nil), tos(filterTypeParent)) end
	return false
end
local libFilters_IsCraftBagExtendedParentFilterType = libFilters.IsCraftBagExtendedParentFilterType

--Is any CarftBag shown, vanilla UI or CraftBagExtended
function libFilters:IsCraftBagShown()
	local lReferencesToFilterType, lFilterTypeDetected = detectShownReferenceNow(LF_CRAFTBAG, nil, false, true)
	local vanillaUICraftBagShown = ((lFilterTypeDetected == LF_CRAFTBAG and lReferencesToFilterType ~= nil) and true) or false0
	local cbeCraftBagShown = libFilters_IsCraftBagExtendedParentFilterType(libFilters, cbeSupportedFilterPanels)
	df(">vanillaUICraftBagShown: %s, cbeCraftBagShown: %s", tos(vanillaUICraftBagShown), tos(cbeCraftBagShown))
	if vanillaUICraftBagShown == true or cbeCraftBagShown == true then return true end
	return false
end

--**********************************************************************************************************************
-- Callback API
--**********************************************************************************************************************
--Create the callbackname for a libFilters filterPanel shown/hidden callback
--number filterType needs to be a valid LF_* filterType constant
--boolean isShown true means SCENE_SHOWn will be used, and false means SCENE_HIDDEN will be used for the callbackname
--Returns String callbackNameGenerated
function libFilters:CreateCallbackName(filterType, isShown)
	isShown = isShown or false
	return strfor(callbackPattern, (isShown == true and SCENE_SHOWN) or SCENE_HIDDEN, tos(filterType))
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
local sceneStatesSupportedForCallbacks = {
	[SCENE_SHOWN] 	= true,
	[SCENE_HIDDEN] 	= true,
}

local callbacksAdded = {}
--controls
callbacksAdded[1] = {}
--scenes
callbacksAdded[2] = {}
--fragments
callbacksAdded[3] = {}
callbacks.added = callbacksAdded

local function callbackRaise(filterTypes, fragmentOrSceneOrControl, stateStr, isInGamepadMode, typeOfRef)
	local isShown = (stateStr == SCENE_SHOWN and true) or false

	--Update lastFilterType and ref and reset the currentFilterType and ref to nil
	updateLastAndCurrentFilterType(nil, nil, false)

	if filterTypes == nil or fragmentOrSceneOrControl == nil or stateStr == nil or stateStr == "" then return end
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	local lReferencesToFilterType, filterType
	--local skipIsShownChecks = false
	--local checkIfHidden = (stateStr == SCENE_HIDDEN and true) or false
	local checkIfHidden = false

	if libFilters.debug then
		dv("![CB]callbackRaise - state %s, #filterTypes: %s, refType: %s", tos(stateStr), tos(#filterTypes), tos(typeOfRef))
		if #filterTypes > 0 then
			for filterTypeIdx, filterTypePassedIn in ipairs(filterTypes) do
				dv(">passedInFilterType %s: %s", tos(filterTypeIdx), tos(filterTypePassedIn))
			end
		end
	end

	--!!!SCENE_HIDING and SCENE_SHOWING are not supported as of 2022-01-04!!!
	--> So the code below relating to these states is just "left over" for future implementation!

	--Are we hiding or is a control/scene/fragment already hidden?
	--The shown checks might not work properly then, so we need to "cache" the last used filterType and reference variables!
	local lastKnownFilterType, lastKnownRefVars
	lastKnownFilterType = libFilters._lastFilterType
	lastKnownRefVars 	= libFilters._lastFilterTypeReferences
	if stateStr == SCENE_HIDDEN then --or stateStr == SCENE_HIDING   then

		if lastKnownFilterType ~= nil then
			if libFilters.debug then dv(">lastKnownFilterType: %s", tos(lastKnownFilterType)) end

			--Check if the fragment or scene hiding/hidden is related to the lastKnown filterType:
			--Some fragments like INVENTORY_FRAGMENT and BACKPACK_MAIL_LAYOUT_FRAGMENT are added to the same scenes (mail send e.g.).
			--If this scene is hiding/hidden both fragment's raise callbacks for hiding and hidden state where only the "dedicated fragment
			--(here: BACKPACK_MAIL_LAYOUT_FRAGMENT") to the lastShown filterPanel (LF_MAIL_SEND) should fire it!
			-->So we need to block the others!
			if typeOfRef == LIBFILTERS_CON_TYPEOFREF_SCENE then
				--Check if there is a scene registered as callack for the last shown filterType
				local sceneOfLastFilterType = callbacksUsingScenes[isInGamepadMode][fragmentOrSceneOrControl]
				if sceneOfLastFilterType ~= nil then
					if ZO_IsElementInNumericallyIndexedTable(sceneOfLastFilterType, lastKnownFilterType) == false then
						if libFilters.debug then dv("<<sceneOfLastFilterType not valid") end
						return
					end
				else
					if libFilters.debug then dv("<<sceneOfLastFilterType not found", tos(lastKnownFilterType)) end
					return
				end

			elseif typeOfRef == LIBFILTERS_CON_TYPEOFREF_FRAGMENT then
				--Check if there is a scene registered as callack for the last shown filterType
				local fragmentOfLastFilterType = callbacksUsingFragments[isInGamepadMode][fragmentOrSceneOrControl]
				if fragmentOfLastFilterType ~= nil then
					if ZO_IsElementInNumericallyIndexedTable(fragmentOfLastFilterType, lastKnownFilterType) == false then
						if libFilters.debug then dv("<<fragmentOfLastFilterType not valid") end
						return
					end
				else
					if libFilters.debug then dv("<<fragmentOfLastFilterType not found") end
					return
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
	elseif stateStr == SCENE_SHOWN then
		---With the addon craftbag extended active:
		--Some fragments like BACKPACK_MAIL_LAYOUT_FRAGMENT are changing their hidden state to Shown after the CRAFTBAG_FRAGMENT was shown already.
		-->In order to leave only the craftbag fragment active we need to check the later called "non-craftbag" (layout) fragments and do not fire
		--> their state change
		if isInGamepadMode == false and CraftBagExtended ~= nil and lastKnownFilterType == LF_CRAFTBAG then
			if libFilters.debug then dv(">>CraftBagExtended active") end
			if not craftbagRefsFragment[fragmentOrSceneOrControl] then
				if libFilters.debug then dv(">>>Current fragment is not the craftbag fragment") end
				local isCBESupportedPanel = (#filterTypes == 0) or false
				if isCBESupportedPanel == false then
					for _, filterTypePassedIn in ipairs(filterTypes) do
						isCBESupportedPanel = isCraftBagExtendedSupportedPanel(filterTypePassedIn)
						if isCBESupportedPanel == true then
							if libFilters.debug then dv(">>>CraftBagExtended supported panel was found: %s", tos(filterTypePassedIn)) end
							break
						end
					end
				else
					if libFilters.debug then dv(">>>No filterTypes passed in -> Checking for CBE filterPanels") end
				end
				if isCBESupportedPanel == true and libFilters_IsCraftBagExtendedParentFilterType(libFilters, cbeSupportedFilterPanels) then
					if libFilters.debug then dv("<<CraftBagExtended craftbagFragment was shown already") end
					return
				end
			end
		end
	end

	--Check for shown controls/fragments/scenes -> Only for the stateStr SCENE_SHOWN, SCENE_HIDING and SCENE_HIDDEN
	--if skipIsShownChecks == false then
	--Detect which control/fragment/scene is currently shown
	if #filterTypes == 0 then
		--Detect the currently shown control/fragment/scene and get the filterType
		lReferencesToFilterType, filterType = detectShownReferenceNow(nil, isInGamepadMode, checkIfHidden, false)
	else
		local checkForAllPanelsAtTheEnd = false
		--Check the given filterTypes first
		for idx, filterTypeInLoop in ipairs(filterTypes) do
			if filterType == nil and lReferencesToFilterType == nil then
				local skipCheck = false
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
					lReferencesToFilterType, filterType = detectShownReferenceNow(filterTypeInLoop, isInGamepadMode, checkIfHidden, false)
					if filterType ~= nil and lReferencesToFilterType ~= nil then
						break -- leave the loop if filterType and reference were found
					end
				end
			end
		end
		--At the end: was any entry with filterType = 0 provided in the filterTypes table?
		if checkForAllPanelsAtTheEnd == true and filterType == nil and lReferencesToFilterType == nil then
			--Detect the currently shown control/fragment/scene and get the filterType
			lReferencesToFilterType, filterType = detectShownReferenceNow(nil, isInGamepadMode, checkIfHidden, false)
		end
	end
	--end
	--Was a filterType found or provided (SCENE_HIDING/SCENE_HIDDEN: libFilters._currentFilterType as the callback was raised;
	--SCENE_SHOWING: passed in filterType if only 1 was passed in)
	if filterType == nil then
		--Are we at hiding/hidden state?
		if lastKnownFilterType ~= nil and lastKnownRefVars ~= nil then
			--The last used filterType should be the one used before hiding then -> Use it
			filterType 				= lastKnownFilterType
			lReferencesToFilterType = lastKnownRefVars
		else
			return
		end
	end
	if lReferencesToFilterType == nil then lReferencesToFilterType = {} end

	local callbackName = GlobalLibName .. "-" .. stateStr .. "-" .. tos(filterType)

	if libFilters.debug then
		local filterTypeName = libFilters_GetFilterTypeName(libFilters, filterType)
		local callbackRefType = typeOfRefToName[typeOfRef]
		df(">!!! CALLBACK - filterType: %q [%s] - %s !!!>", tos(filterTypeName), tos(filterType), tos(stateStr))
		dd("Callback %s raise %q - state: %s, filterType: %s, gamePadMode: %s",
				tos(callbackRefType), callbackName, tos(stateStr), tos(filterType), tos(isInGamepadMode))
		df("<!!! end CALLBACK - filterType: %q [%s] - %s !!!>", tos(filterTypeName), tos(filterType), tos(stateStr))
	end

	--Update currentFilterTyp and ref if the ref is shown. Do not update if it got hidden!
	if isShown then
		updateLastAndCurrentFilterType(filterType, lReferencesToFilterType, true)
	end

	--Fire the callback now
	CM:FireCallbacks(callbackName,
			filterType,
			stateStr,
			isInGamepadMode,
			fragmentOrSceneOrControl,
			lReferencesToFilterType
	)
end

--Check wich fragment is shown and rais a callback, if needed
local function callbackRaiseCheck(filterTypes, fragmentOrScene, stateStr, isInGamepadMode, typeOfRef)
	--Only fire callbacks for the scene states supported
	if not sceneStatesSupportedForCallbacks[stateStr] then return end
	if stateStr == SCENE_SHOWN then
		--Call the code 1 frame later (zo_callLater with 0 ms > next frame) so the fragment's shown state (used within detectShownReferenceNow())
		--will be updated properly. Else it will fire too early and the fragment is still in state "Showing", on it's way to state "Shown"!
		zo_callLater(function()
			callbackRaise(filterTypes, fragmentOrScene, stateStr, isInGamepadMode, typeOfRef)
		end, 0)
	else
		--For the scene fragment hiding, hidden and showing check there is no delay needed
		callbackRaise(filterTypes, fragmentOrScene, stateStr, isInGamepadMode, typeOfRef)
	end
end

local function onFragmentStateChange(oldState, newState, filterTypes, fragment, inputType)
	if libFilters.debug then
		local fragmentName = getFragmentControlName(fragment)
		dd("~~~ FRAGMENT STATE CHANGE ~~~")
		dd("onFragmentStateChange: %q - oldState: %s > newState: %q - #filterTypes: %s, isGamePad: %s", tos(fragmentName), tos(oldState), tos(newState), #filterTypes, tos(inputType))
	end
	callbackRaiseCheck(filterTypes, fragment, fragmentStateToSceneState[newState], inputType, 3)
end

local function onSceneStateChange(oldState, newState, filterTypes, scene, inputType)
	if libFilters.debug then
		local sceneName = getSceneName(scene)
		dd("~~~ SCENE STATE CHANGE ~~~")
		dd("onSceneStateChange: %q - oldState: %s > newState: %q - #filterTypes: %s, isGamePad: %s", tos(sceneName), tos(oldState), tos(newState), #filterTypes, tos(inputType))
	end
	callbackRaiseCheck(filterTypes, scene, newState, inputType, 2)
end

local function onControlHiddenStateChange(isShown, filterTypes, ctrlRef, inputType)
	if libFilters.debug then
		local ctrlName = getCtrlName(ctrlRef)
		dd("~~~ CONTROL HIDDEN STATE CHANGE ~~~")
		dd("ControlHiddenStateChange: %q  - hidden: %s - #filterTypes: %s, isGamePad: %s", tos(ctrlName), tos(not isShown), #filterTypes, tos(inputType))
	end
	local stateStr = (isShown == true and SCENE_SHOWN) or SCENE_HIDDEN --using the SCENE_* constants to unify the callback name for fragments, scenes and controls
	callbackRaise(filterTypes, ctrlRef, stateStr, inputType, 1)
end

local function createFragmentCallback(fragment, filterTypes, inputType)
	if libFilters.debug then
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
	if callbacksAdded[3][fragment] == nil or (callbacksAdded[3][fragment] ~= nil and not callbacksAdded[3][fragment][inputType]) then
		fragment:RegisterCallback("StateChange",
				function(oldState, newState)
					onFragmentStateChange(oldState, newState, filterTypes, fragment, inputType)
				end
		)
		callbacksAdded[3][fragment] = callbacksAdded[3][fragment] or {}
		callbacksAdded[3][fragment][inputType] = filterTypes
	end
end
libFilters.CreateFragmentCallback = createFragmentCallback

local function createFragmentCallbacks()
	if libFilters.debug then
		dd("createFragmentCallbacks")
	end
	--Fragments
	--[fragment] = LF_* filterTypeConstant. 0 means no dedicated LF_* constant can be used and the filterType will be determined
	for inputType, callbackDataPerFilterType in pairs(callbacksUsingFragments) do
		for fragment, filterTypes in pairs(callbackDataPerFilterType) do
			createFragmentCallback(fragment, filterTypes, inputType)
		end
	end
end

local function createSceneCallbacks()
	if libFilters.debug then
		dd("createSceneCallbacks")
	end
	--Scenes
	--[scene] = LF_* filterTypeConstant. 0 means no dedicated LF_* constant can be used and the filterType will be determined
	for inputType, callbackDataPerFilterType in pairs(callbacksUsingScenes) do
		for scene, filterTypes in pairs(callbackDataPerFilterType) do
			if filterTypes ~= nil and #filterTypes > 0 then
				if libFilters.debug then
					if scene ~= nil then
						local sceneName = getSceneName(scene)
						dv(">register scene StateChange to: %s - #filterTypes: %s", tos(sceneName), #filterTypes)
					else
						dv(">scene is NIL! StateChange not possible - #filterTypes: %s", #filterTypes)
					end
				end
				if scene == nil then return end
				--Only add the callback once per input type
				if callbacksAdded[2][scene] == nil or (callbacksAdded[2][scene] ~= nil and not callbacksAdded[2][scene][inputType]) then
					scene:RegisterCallback("StateChange",
							function(oldState, newState) onSceneStateChange(oldState, newState, filterTypes, scene, inputType) end)
					callbacksAdded[2][scene] = callbacksAdded[2][scene] or {}
					callbacksAdded[2][scene][inputType] = filterTypes
				end
			end
		end
	end
end

local function createControlCallback(controlRef, filterTypes, inputType)
	if libFilters.debug then
		local ctrlName = "n/a"
		if controlRef ~= nil then
			local controlRefNew, _ = getCtrl(controlRef)
			controlRef = controlRefNew
			ctrlName = getCtrlName(controlRef)
			dv(">register control %q OnShow/OnHide - #filterType: %s", tos(ctrlName), #filterTypes)
		else
			dv(">register control OnShow/OnHide: control is NIL! - #filterTypes: %s", #filterTypes)
			--For controls which get created OnDeferredInitialize
			return
		end
	end
	--Only add the callback once per input type
	if callbacksAdded[1][controlRef] == nil or (callbacksAdded[1][controlRef] ~= nil and not callbacksAdded[1][controlRef][inputType]) then

		--OnShow
		local onShowHandler = controlRef.GetHandler and controlRef:GetHandler("OnEffectivelyShown")
		if onShowHandler ~= nil then
			ZO_PostHookHandler(controlRef, "OnEffectivelyShown", function(ctrlRef)
				onControlHiddenStateChange(true, filterTypes, ctrlRef, inputType)
			end)
		else
			controlRef:SetHandler("OnEffectivelyShown", function(ctrlRef)
				onControlHiddenStateChange(true, filterTypes, ctrlRef, inputType)
			end)
		end

		--OnHide
		local onHideHandler = controlRef.GetHandler and controlRef:GetHandler("OnHide")
		if onHideHandler ~= nil then
			ZO_PostHookHandler(controlRef, "OnHide", function(ctrlRef)
				onControlHiddenStateChange(false, filterTypes, ctrlRef, inputType)
			end)
		else
			controlRef:SetHandler("OnHide", function(ctrlRef)
				onControlHiddenStateChange(false, filterTypes, ctrlRef, inputType)
			end)
		end
		callbacksAdded[1][controlRef] = callbacksAdded[1][controlRef] or {}
		callbacksAdded[1][controlRef][inputType] = filterTypes
	end
end
libFilters.CreateControlCallback = createControlCallback

local function createControlCallbacks()
	if libFilters.debug then
		dd("createControlCallbacks")
	end
	--Controls
	--[control] = LF_* filterTypeConstant. 0 means no dedicated LF_* constant can be used and the filterType will be determined
	for inputType, callbackDataPerFilterType in pairs(callbacksUsingControls) do
		for controlRef, filterTypes in pairs(callbackDataPerFilterType) do
			createControlCallback(controlRef, filterTypes, inputType)
		end
	end
end

local function createCallbacks()
	if libFilters.debug then
		dd("createCallbacks")
	end
	createSceneCallbacks()
	createFragmentCallbacks()
	createControlCallbacks()
end


--**********************************************************************************************************************
-- FIXES
--**********************************************************************************************************************
--Fixes which are needed BEFORE EVENT_ADD_ON_LOADED hits
local function applyFixesEarly()
	if libFilters.debug then dd("ApplyFixesEarly") end
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

