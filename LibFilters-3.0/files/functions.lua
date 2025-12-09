------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3 name, and version
------------------------------------------------------------------------------------------------------------------------
local libFilters 	= LibFilters3
--local MAJOR      	= libFilters.name
--local GlobalLibName = libFilters.globalLibName

------------------------------------------------------------------------------------------------------------------------
--DEBUGGING & LOGGING
------------------------------------------------------------------------------------------------------------------------
--LibDebugLogger, or normal logger d() output
local debugFunctions = libFilters.debugFunctions
local dd 	= debugFunctions.dd
local dv	= debugFunctions.dv

------------------------------------------------------------------------------------------------------------------------
--LOCAL SPEED UP VARIABLES & REFERENCES
------------------------------------------------------------------------------------------------------------------------
--lua API functions
local tos = tostring
local strfor = string.format
local tins = table.insert

--Game API local speedup
local SM = SCENE_MANAGER
local getScene = SM.GetScene
local IsGamepad = IsInGamepadPreferredMode

local gcit = GetCraftingInteractionType
local ncc = NonContiguousCount

--LibFilters local speedup and reference variables
--Overall constants & mapping
local constants = 					libFilters.constants
local mapping = 					libFilters.mapping
local functions = 					libFilters.functions

------------------------------------------------------------------------------------------------------------------------
--Local LibFilters speed-up variables and references
------------------------------------------------------------------------------------------------------------------------
--Keyboard
local kbc                      	= 	constants.keyboard
local storeWindows             	= 			kbc.storeWindows
local researchChooseItemDialog =            kbc.researchChooseItemDialog
local researchPanel			   	=   		kbc.researchPanel

--Gamepad
local gpc                      	= 	constants.gamepad
local store_GP                  = 			gpc.store_GP
local store_componentsGP        = 			store_GP.components

local researchPanel_GP          = 			gpc.researchPanel_GP

local craftingTypeToPanelId = 						mapping.craftingTypeToPanelId
local validFilterTypesOfPanel = 					mapping.validFilterTypesOfPanel
local filterTypeToUniversalOrNormalDeconAndExtractVars =	mapping.filterTypeToUniversalOrNormalDeconAndExtractVars
local universalDeconLibFiltersFilterTypeSupported = 		mapping.universalDeconLibFiltersFilterTypeSupported
local LF_FilterTypeToDialogOwnerControl = 					mapping.LF_FilterTypeToDialogOwnerControl
local LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes =	mapping.LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes
local LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup = mapping.LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup
local LF_FilterTypeToCheckIfReferenceIsHidden = mapping.LF_FilterTypeToCheckIfReferenceIsHidden


--Other addons
local cbeSupportedFilterPanels  = constants.cbeSupportedFilterPanels

--Functions
local checkIfRefVarIsShown = libFilters.CheckIfRefVarIsShown
local isControlShown = 			libFilters.IsControlShown

local libFilters_GetCurrentFilterTypeForInventory
local libFilters_GetFilterTypeName
local libFilters_GetFilterTypeReferences
local libFilters_getUniversalDeconstructionPanelActiveTabFilterType
local libFilters_IsUniversalDeconstructionPanelShown


------------------------------------------------------------------------------------------------------------------------
--Functions, internally for LibFilters
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--LOCAL HELPER FUNCTIONS
------------------------------------------------------------------------------------------------------------------------

--Is a filterType that is supported at UniversalDeconstruction, e.g. LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT, LF_ENCHANTING_EXTRACT
local function isUniversalDeconstructionSupportedFilterType(filterType)
	local isSupported = universalDeconLibFiltersFilterTypeSupported[filterType] or false
	if libFilters.debug then dd("|UD> IsUniversalDeconstructionSupportedFilterType - %q, filterType: %s", tos(isSupported), tos(filterType)) end
	return isSupported
end
libFilters.IsUniversalDeconstructionSupportedFilterType = isUniversalDeconstructionSupportedFilterType


--Copy the current filterType to lastFilterType (same for the referenceVariables table) if the filterType / refVariables
--table needs an update, and for the UniversalDeconstruction panel's selected tab
local function updateLastAndCurrentFilterType(lFilterTypeDetected, lReferencesToFilterTyp, universalDeconTab, doNotUpdateLast)
--Sd(">updateLastAndCurrentFilterType - lFilterTypeDetected: " ..tos(lFilterTypeDetected))
	if libFilters.debug then dd("!°!updateLastAndCurrentFilterType - filterType: %s, universalDeconTab: %s, doNotUpdateLast: %s, current: %s, last: %s, lastUniversalDeconTab: %s",
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
libFilters.UpdateLastAndCurrentFilterType = updateLastAndCurrentFilterType



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
		if isSceneOrFragment == true and libFilters.debug then dv("!isSceneFragmentShown - changed sceneName %q to scene %s - filterType %s", tos(retScene), tos(sceneOfRetSceneName), tos(filterType)) end
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
	if libFilters.debug then dv("!isSceneFragmentShown - filterType %s: %s, isSceneOrFragment: %s", tos(filterType), tos(resultIsShown), tos(isSceneOrFragment)) end
	return resultIsShown, resultSceneOrFragment
end
functions.isSceneFragmentShown = isSceneFragmentShown

--Is the dialog's owner control shown
local function isListDialogShown(dialogOwnerControlToCheck)
	local listDialog = ZO_InventorySlot_GetItemListDialog()
	local data = listDialog and listDialog.control and listDialog.control.data
	if data == nil then return false end
	local owner = data.owner
	if owner == nil or owner.control == nil then return false end
	return owner.control == dialogOwnerControlToCheck and not listDialog.control:IsHidden()
end
functions.isListDialogShown = isListDialogShown

--Get the dialog's owner control by help of the filterType
local function getDialogOwner(filterType, craftType)
	craftType = craftType or gcit()
	local filterTypeToDialogCraftTypeData = LF_FilterTypeToDialogOwnerControl[craftType]
	if filterTypeToDialogCraftTypeData == nil then return nil end
	return filterTypeToDialogCraftTypeData[filterType]
end
functions.getDialogOwner = getDialogOwner

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
functions.isListDialogShownWrapper = isListDialogShownWrapper

local function checkIfStoreCtrlOrFragmentShown(varToCheck, p_storeMode, isInGamepadMode)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	varToCheck = (varToCheck or (p_storeMode ~= nil and ((isInGamepadMode and store_componentsGP[p_storeMode]) or (not isInGamepadMode and storeWindows[p_storeMode])))) or nil
	if not varToCheck then return false end

	return checkIfRefVarIsShown(varToCheck) --isShown, controlOrFragment, refType
end
functions.checkIfStoreCtrlOrFragmentShown = checkIfStoreCtrlOrFragmentShown


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
	if libFilters.debug then
		dd(">>>>>>>>>>>>>>>>>>>>>>>>>>>>")
		dd("!isSpecialTrue - filterType: %s, gamepadMode: %s, isSpecialForced: %s, paramsGiven: %s", tos(filterType), tos(isInGamepadMode), tos(isSpecialForced), tos(... ~= nil))
	end
	if not filterType then return false end
	local filterTypeData = LF_FilterTypeToCheckIfReferenceIsHidden[isInGamepadMode][filterType]
	local specialRoutines = filterTypeData and ((isSpecialForced == true and filterTypeData["specialForced"]) or filterTypeData["special"])
	if not specialRoutines or #specialRoutines == 0 then
		if libFilters.debug then
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
			if libFilters.debug then checkType = "control"end
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
						if libFilters.debug then checkType = "control - String"end
						if ctrl[funcOrAttribute] == nil then
							skip = true
							if libFilters.debug then checkAborted = "ctrl[funcOrAttribute] = nil" end
						end
					elseif funcType == "number" then
						if libFilters.debug then checkType = "control - table"end
						if ctrlType == "table" and ctrl[funcOrAttribute] == nil then
							skip = true
							if libFilters.debug then checkAborted = "ctrl[funcOrAttribute] = nil" end
						elseif ctrlType == "userdata" then
							if libFilters.debug then checkType = "control - userdata"end
							if ctrl.GetChildren == nil then
								skip = true
								if libFilters.debug then checkAborted = "ctrl.GetChildren = nil" end
							else
								childControl = ctrl:GetChildren()[funcOrAttribute]
							end
							if childControl == nil then
								skip = true
								if libFilters.debug then checkAborted = "ctrl.childControl = nil" end
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
								if libFilters.debug then dv(">using locally passed in params") end
								params = {...}
								if ncc(params) == 0 then
									if libFilters.debug then dv(">>locally passed in params are empty") end
									noParams = true
								end
							else
								if libFilters.debug then dv(">using params of constants") end
								if ncc(params) == 0 then
									if libFilters.debug then dv(">>params of constants are empty") end
									noParams = true
								end
							end
							if libFilters.debug then dv(">>CALLING FUNCTION NOW...") end
							if not noParams then
								results = {ctrl[funcOrAttribute](unpack(params))}
							else
								results = {ctrl[funcOrAttribute]()}
							end
						else
							if libFilters.debug then dv(">>GETTING ATTRIBUTE NOW...") end
							results = {ctrl[funcOrAttribute]}
						end
						if not results then
							if libFilters.debug then dv(">>>no return values") end
							if expectedResults == nil then
								if libFilters.debug then dv(">>>no expected results -> OK") end
								loopResult = true
							end
						else
							local numResults = #results
							if libFilters.debug then dv(">>>return values: " ..tos(numResults)) end
							if numResults == 0 then
								if libFilters.debug then dv(">>>no return values") end
								if expectedResults == nil then
									if libFilters.debug then dv(">>>>no expected results -> OK") end
									loopResult = true
								end
							else
								if expectedResults == nil or #expectedResults == 0 then
									loopResult = false
									if libFilters.debug then checkAborted = ">>expectedResults missing" end
								else
									if numResults ~= #expectedResults then
										if expectedResultsMap ~= nil then
											for expectedResultsMapIdx, isExpectedResult in pairs(expectedResultsMap) do
												if isExpectedResult == true then
													loopResult = results[expectedResultsMapIdx] ~= nil
													if loopResult == false then
														if libFilters.debug then checkAborted = strfor(">>>expectedResultsMap did not match, index %s", tos(expectedResultsMapIdx)) end
													end
												end
											end
										else
											loopResult = false
											if libFilters.debug then checkAborted = strfor(">>>numResults [%s] ~= #expectedResults [%s]", tos(numResults), tos(#expectedResults)) end
										end
									else
										if numResults == 1 then
											loopResult = results[1] == expectedResults[1]
											if not loopResult then if libFilters.debug then checkAborted = ">>>results[1]: "..tos(results[1]) .." ~= expectedResults[1]: " ..tos(expectedResults[1]) end end
										elseif numResults > 1 then
											loopResult = true
										end
									end
									if loopResult == true then
										for resultIndex, resultOfResults in ipairs(results) do
											if skip == false then
												if expectedResults[resultIndex] ~= nil then
													loopResult = (resultOfResults == expectedResults[resultIndex]) or false
													if not loopResult then
														skip = true
														if libFilters.debug then checkAborted = ">>>results[" .. tos(resultIndex) .."]: "..tos(results[resultIndex]) .." ~= expectedResults[" .. tos(resultIndex) .."]: " ..tos(expectedResults[resultIndex]) end
													end
												end
											end
										end
									end
								end
							end
						end
					else
						if libFilters.debug then checkAborted = "skipped" end
					end
				else
					if libFilters.debug then checkAborted = "no func/no attribute" end
				end
			end
		elseif bool ~= nil then
			local typeBool= type(bool)
			if typeBool == "function" then
				if libFilters.debug then checkType = "boolean - function" end
				loopResult = bool()
			elseif typeBool == "boolean" then
				if libFilters.debug then checkType = "boolean"end
				loopResult = bool
			else
				if libFilters.debug then
					checkType = "boolean > false"
					checkAborted = "hardcoded boolean false"
				end
				loopResult = false
			end
		else
			if libFilters.debug then checkAborted = "no checktype" end
		end
		if libFilters.debug then
			local abortedStartStr = (checkAborted ~= "" and "<<<") or ">>>"
			dd("%scheckType: %q, abortedDueTo: %s, loopResult: %s", abortedStartStr, tos(checkType), tos(checkAborted), tos(loopResult))
		end
		totalResult = totalResult and loopResult
	end
	if libFilters.debug then
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
functions.getSmithingResearchPanel = getSmithingResearchPanel

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
functions.fixResearchDialogRowOnItemSelectedCallback = fixResearchDialogRowOnItemSelectedCallback



------------------------------------------------------------------------------------------------------------------------
--LOCAL HELPER FUNCTIONS - filterType mapping
------------------------------------------------------------------------------------------------------------------------
--is the filterType passed in a valid supported CraftBagExtended filterType?
local function isCraftBagExtendedSupportedPanel(filterTypePassedIn)
	local isSupportedFilterPanel = ZO_IsElementInNumericallyIndexedTable(cbeSupportedFilterPanels, filterTypePassedIn)
	if libFilters.debug then
		dv(">isCraftBagExtendedSupportedPanel - filterType: %s = %s", tos(filterTypePassedIn), tos(isSupportedFilterPanel))
	end
	return isSupportedFilterPanel
end
functions.isCraftBagExtendedSupportedPanel = isCraftBagExtendedSupportedPanel


--Check if CraftBagExtended addon is enabled and if any of the supported extra panels/fragments are shown
--and if the extra menu buttons of CBE are clicked to currently show the craftbag, and if the fragment's layoutData of
--the CBE fragments hooked use the same number filterType as passed in
local function craftBagExtendedCheckForCurrentModule(filterType)
	if libFilters.debug then dv("!craftBagExtendedCheckForCurrentModule - filterTypePassedIn: " .. tos(filterType)) end
	local cbe = CraftBagExtended
	if cbe == nil then return nil, nil end
	local cbeCurrentModule = cbe.currentModule
	if cbeCurrentModule == nil then
		if libFilters.debug then dv("<no current CBE module found") end
		return false, nil
	end
	local cbeDescriptorOfCraftBag = 4402 --GetString(4402) = "CraftBag"
	--Check if the CBE button at the menu is activated -> Means te CBE fragment is shown
	local cbeMenu = cbeCurrentModule.menu
	local currentlyClickedButtonDescriptor = cbeMenu.m_object:GetSelectedDescriptor()
	if libFilters.debug then dv(">currentClickedButton: %s = %q", tos(currentlyClickedButtonDescriptor), tos(GetString(currentlyClickedButtonDescriptor))) end
	if currentlyClickedButtonDescriptor == nil or currentlyClickedButtonDescriptor ~= cbeDescriptorOfCraftBag then return  nil, nil end
	local cbeFragmentLayoutData = cbeCurrentModule.layoutFragment and cbeCurrentModule.layoutFragment.layoutData
	--Get the constants.defaultAttributeToStoreTheFilterType (.LibFilters3_filterType) from the layoutData
	libFilters_GetCurrentFilterTypeForInventory = libFilters_GetCurrentFilterTypeForInventory or libFilters.GetCurrentFilterTypeForInventory
	local filterTypeAtFragment = libFilters_GetCurrentFilterTypeForInventory(libFilters, cbeFragmentLayoutData, false)
	if libFilters.debug then dv(">filterTypeAtFragment: %s", tos(filterTypeAtFragment)) end
	if filterTypeAtFragment == nil then return  nil, nil end
	local referencesFound = {}
	if filterTypeAtFragment == filterType then
		tins(referencesFound, cbeCurrentModule.scene)
		return referencesFound, filterTypeAtFragment
	end
	return nil, nil
end
functions.craftBagExtendedCheckForCurrentModule = craftBagExtendedCheckForCurrentModule



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
	if libFilters.debug then dv("checkForValidLastFilterTypesAtSamePanel - id: %s, filterType: %s", tos(panelIdentifier), tos(filterType)) end
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
	if libFilters.debug then dv("<isValidFilterTypeAtPanel: %s", tos(isValidFilterTypeAtPanel)) end
	return isValidFilterTypeAtPanel
end
functions.checkForValidFilterTypeAtSamePanel = checkForValidFilterTypeAtSamePanel


--Check if a control/fragment/scene is shown/hidden (depending on parameter "checkIfHidden") or if any special check function
--needs to be called to do additional checks, or an overall special forced check function needs to be always called at the end
--of all checks (e.g. for crafting -> check if jewelry crafting or other)
local function checkIfShownNow(filterTypeControlAndOtherChecks, isInGamepadMode, checkIfHidden, skipSpecialChecks)
	checkIfHidden = checkIfHidden or false
	skipSpecialChecks = skipSpecialChecks or false
	local lReferencesToFilterType, lFilterTypeDetected
	if filterTypeControlAndOtherChecks ~= nil then
		local filterTypeChecked = filterTypeControlAndOtherChecks.filterType
		if libFilters.debug then dv("!>>>===== checkIfShownNow = START =") end
		if libFilters.debug then
			libFilters_GetFilterTypeName = libFilters_GetFilterTypeName or libFilters.GetFilterTypeName
			dv(">checking filterType: %q [%s] - needs to be hidden: %s", libFilters_GetFilterTypeName(libFilters, filterTypeChecked), tos(filterTypeChecked), tos(checkIfHidden))
		end
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
							if libFilters.debug then
								local resultLoopStr = (resultLoop == true and ">>") or "<<"
								dv("%sfoundInLoop: %s, checkType: %s", tos(resultLoopStr), tos(resultLoop), tos(checkTypeToExecute))
							end
						else
							if checkTypeToExecute == "special" or checkTypeToExecute == "specialForced" then
								if libFilters.debug then dv("<<<skipped special check: %s", tos(checkTypeToExecute)) end
								resultLoop = true
							end
						end
					else
						if libFilters.debug then dv("<<<skipped checkType: %s  - resultOfCurrentLoop was false already", tos(checkTypeToExecute) ) end
					end
					resultOfCurrentLoop = resultOfCurrentLoop and resultLoop
				end
				--End checks
				if resultOfCurrentLoop == true then
					if doSpecialForcedCheckAtEnd == true and not skipSpecialChecks then
						resultOfCurrentLoop = isSpecialTrue(filterTypeChecked, isInGamepadMode, true, nil)
						if libFilters.debug then dv(">>>specialCheckAtEnd: " ..tos(resultOfCurrentLoop)) end
					end
					if resultOfCurrentLoop == true then
						lFilterTypeDetected = filterTypeChecked
						if currentReferenceFound == nil then
							if libFilters.debug then dv(">>>>currentReferenceFound is nil, detecing it...") end
							libFilters_GetFilterTypeReferences = libFilters_GetFilterTypeReferences or libFilters.GetFilterTypeReferences
							currentReferenceFound = libFilters_GetFilterTypeReferences(libFilters, filterTypeChecked, isInGamepadMode)
						end
						if currentReferenceFound ~= nil then
							local curRefType = type(currentReferenceFound)
							if libFilters.debug then dv(">>>>currentReferenceFound: YES, type: %s", tos(curRefType)) end
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
			if libFilters.debug then
				dd(">found filterType: %s", tos(lFilterTypeDetected))
				dv("!<<<===== checkIfShownNow = END =")
			end
			--Abort the for ... do loop now as data was found
			return lReferencesToFilterType, lFilterTypeDetected
		end
	end
	return lReferencesToFilterType, lFilterTypeDetected
end
functions.checkIfShownNow = checkIfShownNow

local function getDeconstructOrExtractCraftingVarToUpdate(filterType, isInGamepadMode, isUniversalDecon)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	if isUniversalDecon == nil then
		libFilters_IsUniversalDeconstructionPanelShown = libFilters_IsUniversalDeconstructionPanelShown or libFilters.IsUniversalDeconstructionPanelShown
		isUniversalDecon = libFilters_IsUniversalDeconstructionPanelShown(isInGamepadMode) or false
	end
	local craftingVarToUpdate = filterTypeToUniversalOrNormalDeconAndExtractVars[isInGamepadMode][filterType][isUniversalDecon]
	return craftingVarToUpdate
end
functions.getDeconstructOrExtractCraftingVarToUpdate = getDeconstructOrExtractCraftingVarToUpdate


local function getUniversalDeconstructionFilterTypeByActiveTab_AndReferenceVar(p_filterType, isInGamepadMode)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	local lFilterTypeDetected, lReferencesToFilterType, universalDeconSelectedTabKey

	--Get the active tab at the universal deconstruction panel (all, armor, weapons, jewelry, glyphs)
	--Return the detected active tab's libFiltersFilterType LF_SMITHING* etc.
	libFilters_getUniversalDeconstructionPanelActiveTabFilterType = libFilters_getUniversalDeconstructionPanelActiveTabFilterType or libFilters.GetUniversalDeconstructionPanelActiveTabFilterType
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
functions.getUniversalDeconstructionFilterTypeByActiveTab_AndReferenceVar = getUniversalDeconstructionFilterTypeByActiveTab_AndReferenceVar

local function detectShownReferenceNow(p_filterType, isInGamepadMode, checkIfHidden, skipSpecialChecks)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	checkIfHidden = checkIfHidden or false
	skipSpecialChecks = skipSpecialChecks or false
	local lFilterTypeDetected
	local lReferencesToFilterType = {}

	--Special case "Universal Deconstruction" -> Own UI cotrols but re-use LF_SMITHING* etc. filterTypes!
	libFilters_IsUniversalDeconstructionPanelShown = libFilters_IsUniversalDeconstructionPanelShown or libFilters.IsUniversalDeconstructionPanelShown
	local isUniversalDeconPanelShown = libFilters_IsUniversalDeconstructionPanelShown()
	local universalDeconSelectedTabKey

	if libFilters.debug then dd(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>") end
	if libFilters.debug then dd("!detectShownReferenceNow - filterTypePassedIn: %s, isInGamepadMode: %s, isUniversalDecon: %s",
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
					if libFilters.debug then dd("<<< found PASSED IN FILTERTYPE %q <<<<<<<<<<<<<<<<<<<<<<<<", tos(lFilterTypeDetected))	end
					--updateLastAndCurrentFilterType(lFilterTypeDetected, lReferencesToFilterType, false)
				end
			end
			return lReferencesToFilterType, lFilterTypeDetected, nil

		else
			--Dynamically get the filterType via the currently shown control/fragment/scene/special check and specialForced check
			for _, filterTypeControlAndOtherChecks in ipairs(LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[isInGamepadMode]) do
				lReferencesToFilterType, lFilterTypeDetected = checkIfShownNow(filterTypeControlAndOtherChecks, isInGamepadMode, checkIfHidden, skipSpecialChecks)
				if lFilterTypeDetected ~= nil and lReferencesToFilterType ~= nil and #lReferencesToFilterType > 0 then
					if libFilters.debug then dd("<<< FOR .. in checkTypes LOOP, found filterType: %q <<<<<<<<<<<<<<<<<<<<<<<<", tos(lFilterTypeDetected)) end
					--updateLastAndCurrentFilterType(lFilterTypeDetected, lReferencesToFilterType, false)
					--Abort the for ... do loop now as data was found
					return lReferencesToFilterType, lFilterTypeDetected, nil
				end
			end --for _, filterTypeControlAndOtherChecks in ipairs(LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[isInGamepadMode]) do
		end

	end

	if libFilters.debug then
		dd("<found filterType: %s, universalDeconTabKey: %s", tos(lFilterTypeDetected), tos(universalDeconSelectedTabKey))
		dd("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
	end
	return lReferencesToFilterType, lFilterTypeDetected, universalDeconSelectedTabKey
end
libFilters.DetectShownReferenceNow = detectShownReferenceNow

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
				if libFilters.debug then dd("!>checkIfCachedFilterTypeIsStillShown %q: %s", tos(filterTypeShown), "YES") end
				--updateLastAndCurrentFilterType(filterTypeShown, filterTypeReference, true)
				return filterTypeReference, filterTypeShown, universalDeconSelectedTabKey
			end
		end
	end
	if libFilters.debug then dd("<!checkIfCachedFilterTypeIsStillShown - currentFilterType %q: No", tos(libFilters._currentFilterType)) end
	return nil, nil, nil
end
functions.checkIfCachedFilterTypeIsStillShown = checkIfCachedFilterTypeIsStillShown



