------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3 name, and version
------------------------------------------------------------------------------------------------------------------------
local libFilters 	= LibFilters3

--local MAJOR      	= libFilters.name
local GlobalLibName = libFilters.globalLibName

------------------------------------------------------------------------------------------------------------------------
--DEBUGGING & LOGGING
------------------------------------------------------------------------------------------------------------------------
--LibDebugLogger, or normal logger d() output
local debugFunctions = libFilters.debugFunctions

local dd 	= debugFunctions.dd
local df 	= debugFunctions.df
local dv 	= debugFunctions.dv
local dfe 	= debugFunctions.dfe

local SCENE_SHOWING = SCENE_SHOWING
local SCENE_SHOWN = SCENE_SHOWN
local SCENE_HIDDEN = SCENE_HIDDEN
local SCENE_HIDING = SCENE_HIDING
local SCENE_FRAGMENT_HIDDEN = SCENE_FRAGMENT_HIDDEN
local SCENE_FRAGMENT_SHOWN = SCENE_FRAGMENT_SHOWN
local SCENE_FRAGMENT_SHOWING = SCENE_FRAGMENT_SHOWING
local SCENE_FRAGMENT_HIDING = SCENE_FRAGMENT_HIDING


------------------------------------------------------------------------------------------------------------------------
--LOCAL SPEED UP VARIABLES & REFERENCES
------------------------------------------------------------------------------------------------------------------------
--Helper variables of ESO
local tos = tostring
local strfor = string.format
local tins = table.insert
local zieinit = ZO_IsElementInNumericallyIndexedTable


--Game API local speedup
local CM = CALLBACK_MANAGER
local EM = EVENT_MANAGER
local IsGamepad = IsInGamepadPreferredMode

--LibFilters local speedup and reference variables
--Overall constants & mapping
local constants = 					libFilters.constants
local mapping = 					libFilters.mapping
local functions = 					libFilters.functions
local callbacks = 					mapping.callbacks

--local LibFilters panelIds
local LF_CRAFTBAG = LF_CRAFTBAG

local isCraftingFilterType = 										mapping.isCraftingFilterType
local LF_FilterTypeToCheckIfReferenceIsHidden = 					mapping.LF_FilterTypeToCheckIfReferenceIsHidden
local universalDeconTabKeyToLibFiltersFilterType	   =			mapping.universalDeconTabKeyToLibFiltersFilterType
local universalDeconLibFiltersFilterTypeSupported = 				mapping.universalDeconLibFiltersFilterTypeSupported
local enchantingModeToFilterType = 									mapping.enchantingModeToFilterType
local provisionerIngredientTypeToFilterType = 						mapping.provisionerIngredientTypeToFilterType
local alchemyModeToFilterType = 									mapping.alchemyModeToFilterType
local craftbagRefsFragment = 										LF_FilterTypeToCheckIfReferenceIsHidden[false][LF_CRAFTBAG]["fragment"]

local universalDeconstructionTabNames = constants.universalDeconstructionTabNames
local universalDeconstructionTabNameAll = universalDeconstructionTabNames[1] --"all"


--Mapping between fragment's and scene's stateChange states
local fragmentStateToSceneState = {
	[SCENE_FRAGMENT_SHOWING]	= SCENE_SHOWING,
	[SCENE_FRAGMENT_SHOWN] 		= SCENE_SHOWN,
	[SCENE_FRAGMENT_HIDING] 	= SCENE_HIDING,
	[SCENE_FRAGMENT_HIDDEN] 	= SCENE_HIDDEN,
}

--Keyboard
local kbc                      	= 	constants.keyboard
local enchantingClass		   	=   kbc.enchantingClass
local enchanting               	= 	kbc.enchanting
local alchemyClass		   	   	=	kbc.alchemyClass
local alchemyCtrl              	=	kbc.alchemyCtrl
local provisionerClass		   	=	kbc.provisionerClass
local provisioner			   	=   kbc.provisioner
local provisionerScene 		   	=   kbc.provisionerScene

--Gamepad
local gpc                       = 	constants.gamepad
local provisioner_GP			=   gpc.provisioner_GP
local provisionerScene_GP 	    =   gpc.provisionerScene_GP


--Callback variables
local callbacksCreated = false
local callbackBaseLibPattern = 		libFilters.callbackBaseLibPattern
local callbacksUsingScenes = 		callbacks.usingScenes
local callbacksUsingFragments = 	callbacks.usingFragments
local callbacksUsingControls = 		callbacks.usingControls
local specialCallbacks = 			callbacks.special
local filterTypeToCallbackRef = 	callbacks.filterTypeToCallbackRef
local callbackFragmentsBlockedMapping = callbacks.callbackFragmentsBlockedMapping
local sceneStatesSupportedForCallbacks = callbacks.sceneStatesSupportedForCallbacks

--Callbacks which have been added -Subtabel per type
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

--Other addons
local cbeSupportedFilterPanels  = constants.cbeSupportedFilterPanels

--The costants for the reference types
local typeOfRefConstants = constants.typeOfRef
local LIBFILTERS_CON_TYPEOFREF_CONTROL 	= typeOfRefConstants[1]
local LIBFILTERS_CON_TYPEOFREF_SCENE 	= typeOfRefConstants[2]
local LIBFILTERS_CON_TYPEOFREF_FRAGMENT = typeOfRefConstants[3]
local typeOfRefToName    = constants.typeOfRefToName

local getCtrl = 				libFilters.GetCtrl
local getFragmentControlName = 	libFilters.GetFragmentControlName
local getSceneName = 			libFilters.GetSceneName
local getCtrlName = 			libFilters.GetCtrlName

--Functions
local isCraftBagExtendedSupportedPanel = functions.isCraftBagExtendedSupportedPanel
local updateCurrentAndLastUniversalDeconVariables
local checkForValidFilterTypeAtSamePanel = functions.checkForValidFilterTypeAtSamePanel

--Non referenced functions - updated inline below
local updateLastAndCurrentFilterType
local detectShownReferenceNow
local libFilters_CallbackRaise
local libFilters_GetCallbackReference
local onControlHiddenStateChange
local onSceneStateChange
local createControlCallback
local libFilters_GetFilterTypeName
local libFilters_IsCraftBagExtendedParentFilterType
local libFilters_IsUniversalDeconstructionPanelShown



--**********************************************************************************************************************
-- CALLBACKS
--**********************************************************************************************************************
--Returns a callback name based on the filterType and SCENE_SHOWN or SCENE_HIDDEN and the current universal deconstruction tab name
--number filterType, boolean isShown, string (see table constants.universalDeconTabKeyToLibFiltersFilterType for posible strings of the tab names) universalDeconSelectedTabNow
--Default callbackName pattern is "LibFilters3-%s-%s-%s"
--example callbackName would be (for filterTyle LF_INVENTORY, isshown = true, universalDeconSelectedTabNow = nil): "LibFilters3-shown-1-"
function libFilters:CreateCallbackName(filterType, isShown, universalDeconSelectedTabNow)
	universalDeconSelectedTabNow = universalDeconSelectedTabNow or ""
	return strfor(callbackBaseLibPattern, (isShown == true and SCENE_SHOWN) or SCENE_HIDDEN, tos(filterType), tos(universalDeconSelectedTabNow))
end
local libFilters_CreateCallbackName = libFilters.CreateCallbackName


--Create callbacks one can register to as the filterType panels show and hide
--e.g. for LF_SMITHING_REFINE as the panel opens or closes, the signature would be
--name: LibFilters3-<shown or hidden defined via SCENE_SHOWN and SCENE_HIDDEN constants>-<filterType>
--variables passed as parameters:
--filterTypes table,
--fragment/scene/control that was used to raise the callback,
--shownState,
--isGamepadMode,
--referenceObjects (from table filterTypeToCheckIfReferenceIsHidden),
--doNotUpdateCurrentAndLastFilterTypes
--specialPanelControlFunc
--universalDeconData
--
--e.g. showing LF_SMITHING_REFINE
--[[
		--The library provides callbacks for the filterTypes to get noticed as the filterTypes are shown/hidden.
		--The callback name is build by the library prefix "LibFilters3-" (constant provided is LibFilters3.globalLibName) followed by the state of the
		--filterPanel as the callback fires (can be either the constant SCENE_SHOWN = "shown" or SCENE_HIDDEN = "hidden"), followed by "-" and the suffix
		--is the filterType constant number of the panel.
		--The library provides the API function libfilters:CreateCallbackName(filterType, isShown, universalDeconstructionSelectedTab) to generate the
		--callback name of "LibFilters internal callbacks" (which always fire if that panel is shown/hidden) for you.
		--Important: All addon added custom callbacks must be registered via libFilters:RegisterCallbackName!!!
		--isShown is a boolean.
		--if true SCENE_SHOWN will be used, if false SCENE_HIDDEN will be used.
		--e.g. for LF_INVENTORY shown it would be
		local callbackNameInvShown = libfilters:CreateCallbackName(LF_INVENTORY, true, universalDeconSelectedTabNow)
		--Makes: "LibFilters3-shown-1"

		--The callbackFunction you register to it needs to provide the following parameters (signature):
		--string callbackName Concatenated callback name
		--number filterType is the LF_* constant for the panel currently shown/hidden
		--string stateStr will be SCENE_SHOWN ("shown") if shown, or SCENE_HIDDEN ("hidden") if hidden callback was fired
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
	--local lastFilterTypeRefBeforeReset               	= lastFilterTypeRefBefore
	if libFilters.debug then dd("[CallbackRaise]state: %s, currentBefore: %s, lastBefore: %s, currentUniversalDeconTab: %s, lastUniversalDeconTab: %s, doNotUpdate: %s",
				tos(stateStr), tos(currentFilterTypeBeforeReset), tos(lastFilterTypeBeforeReset), tos(currentFilterTypeUniversalDeconTab),
				tos(lastFilterTypeUniversalDeconTabBeforeReset), tos(doNotUpdateCurrentAndLastFilterTypes))
	end

	--Update lastFilterType and ref and reset the currentFilterType and ref to nil
	--todo: 2022-01-14: Currently parameter doNotUpdateCurrentAndLastFilterTypes is not used anywhere. Was used for crafting tables > inventory -> crafting table switch I think I remember?!
	if not doNotUpdateCurrentAndLastFilterTypes then
		updateLastAndCurrentFilterType = updateLastAndCurrentFilterType or libFilters.UpdateLastAndCurrentFilterType
		updateLastAndCurrentFilterType(nil, nil, nil, false)
	end

	if filterTypes == nil or fragmentOrSceneOrControl == nil or stateStr == nil or stateStr == "" then return end
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end

	local lReferencesToFilterType, filterType, universalDeconSelectedTabNow
	--local skipIsShownChecks = false
	--local checkIfHidden = (stateStr == SCENE_HIDDEN and true) or false
	local checkIfHidden = false

	if libFilters.debug then dd("![CB]callbackRaise - state %s, #filterTypes: %s, refType: %s, specialPanelControlFunc: %s, isUniversalDecon: %s",
				tos(stateStr), tos(#filterTypes), tos(typeOfRef), tos(specialPanelControlFunc), tos(universalDeconData.isShown)
		)
		if #filterTypes > 0 then
			for filterTypeIdx, filterTypePassedIn in ipairs(filterTypes) do
				dd(">passedInFilterType %s: %s", tos(filterTypeIdx), tos(filterTypePassedIn))
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
			if libFilters.debug then dv(">lastKnownFilterType: %s", tos(lastKnownFilterType)) end

			--Check if the fragment or scene hiding/hidden is related to the lastKnown filterType:
			--Some fragments like INVENTORY_FRAGMENT and BACKPACK_MAIL_LAYOUT_FRAGMENT are added to the same scenes (mail send e.g.).
			--If this scene is hiding/hidden both fragment's raise callbacks for hiding and hidden state where only the "dedicated" fragment
			--(here: BACKPACK_MAIL_LAYOUT_FRAGMENT) to the lastShown filterPanel (LF_MAIL_SEND) should fire it!
			-->So we need to block the others!
			if typeOfRef == LIBFILTERS_CON_TYPEOFREF_SCENE then
				--Check if there is a scene registered as callack for the last shown filterType
				local sceneOfLastFilterType = callbacksUsingScenes[isInGamepadMode][fragmentOrSceneOrControl]
				if sceneOfLastFilterType ~= nil then
					if zieinit(sceneOfLastFilterType, lastKnownFilterType) == false then
						if libFilters.debug then dv("<<sceneOfLastFilterType not valid") end
						return false
					end
				else
					if libFilters.debug then dv("<<sceneOfLastFilterType not found", tos(lastKnownFilterType)) end
					return false
				end

			elseif typeOfRef == LIBFILTERS_CON_TYPEOFREF_FRAGMENT then
				--Check if there is a scene registered as callack for the last shown filterType
				local fragmentOfLastFilterType = callbacksUsingFragments[isInGamepadMode][fragmentOrSceneOrControl]
				if fragmentOfLastFilterType ~= nil then
					if zieinit(fragmentOfLastFilterType, lastKnownFilterType) == false then
						if libFilters.debug then dv("<<fragmentOfLastFilterType not valid") end
						return false
					end
				else
					if libFilters.debug then dv("<<fragmentOfLastFilterType not found") end
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
				libFilters_IsCraftBagExtendedParentFilterType = libFilters_IsCraftBagExtendedParentFilterType or libFilters.IsCraftBagExtendedParentFilterType
				if isCBESupportedPanel == true and libFilters_IsCraftBagExtendedParentFilterType(libFilters, cbeSupportedFilterPanels) then
					if libFilters.debug then dv("<<CraftBagExtended craftbagFragment was shown already") end
					return false
				end
			end
		end
	end

	--Check for shown controls/fragments/scenes -> Only for the stateStr SCENE_SHOWN, SCENE_HIDING and SCENE_HIDDEN
	--if skipIsShownChecks == false then
	--Detect which control/fragment/scene is currently shown
	detectShownReferenceNow = detectShownReferenceNow or libFilters.DetectShownReferenceNow
	if #filterTypes == 0 then
		--Detect the currently shown control/fragment/scene and get the filterType
		lReferencesToFilterType, filterType, universalDeconSelectedTabNow = detectShownReferenceNow(nil, isInGamepadMode, checkIfHidden, false)
	else
		local checkForAllPanelsAtTheEnd = false
		--Check if the controls/fragments/scenes for the given filterTypes are shown/hidden (checkIfHidden) first
		for idx, filterTypeInLoop in ipairs(filterTypes) do
			if filterType == nil and lReferencesToFilterType == nil then
				local skipCheck = false
				--is the filterType set to 0 (automatically detection based on some code),
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
						if libFilters.debug then dd("<<filterType was found in loop: %s", tos(filterType)) end
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
				if libFilters.debug then dd(">SHOWN - No filterType found. Resetting the current %s and last filterType %s",
						tos(currentFilterTypeBefore), tos(lastFilterTypeBefore))
				end
			end
			return false
		end
	else
		if switchToLastFilterType == true then
			if libFilters.debug then dd(">switched filterType %s to last one %s", tos(filterType), tos(lastKnownFilterType)) end
			filterType = lastKnownFilterType
		end
	end

	--Was the callback, which should fire now, the last activated one itsself already?
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
		if libFilters.debug then dd("<CALLBACK ABORTED - filterType: %s and state %s currently already active! currentNow: %s, lastNow: %s, universalDeconTabNow: %s, universalDeconTabLast: %s",
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
				if libFilters.debug then dd("|UD> CallbackRaise-universal deconstruction CLOSED - currentTab is NIL! Using last tab: %q", tos(universalDeconData.lastTab)) end
				universalDeconSelectedTabNow = universalDeconData.lastTab
			else
				--If currentTab AND lastTab cannot be used just pass in the "all" tab...
				if libFilters.debug then dd("|UD> CallbackRaise-universal deconstruction CLOSED - currentTab AND lastTab are NIL! Using last tab: %q", "all") end
				universalDeconSelectedTabNow = universalDeconstructionTabNameAll
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
	--local callbackName = strfor(callbackBaseLibPattern, (isShown == true and SCENE_SHOWN) or SCENE_HIDDEN, tos(filterType), tos(universalDeconSelectedTabNowForCallbackName))
	local callbackName = libFilters_CreateCallbackName(libFilters, filterType, isShown, universalDeconSelectedTabNowForCallbackName)

	local callbackRaisePrefixStr = ""
	local callbackRaiseSuffixStr = ""
	local callbackStr = "!!! CALLBACK -> filterType: %q [%s] - %s"
	if libFilters.debug then
		libFilters_GetFilterTypeName = libFilters_GetFilterTypeName or libFilters.GetFilterTypeName
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
		updateLastAndCurrentFilterType = updateLastAndCurrentFilterType or libFilters.UpdateLastAndCurrentFilterType
		updateLastAndCurrentFilterType(filterType, lReferencesToFilterType, universalDeconSelectedTabNow, true)
	end

	--Fire the callback now
	libFilters._lastCallbackState = stateStr


--d("[LibFilters]fire Callback - filterType: " ..tos(filterType) .. "; state: " ..tos(stateStr))
	--Raise the library internal callback
	CM:FireCallbacks(callbackName,
			-->Signature of the callback function (parameters)
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

				if libFilters.debug then
					libFilters_GetFilterTypeName = libFilters_GetFilterTypeName or libFilters.GetFilterTypeName
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
	libFilters_GetCallbackReference = libFilters_GetCallbackReference or libFilters.GetCallbackReference
	if inputType == nil then inputType = IsGamepad() end
	local callbackRefData = filterTypeToCallbackRef[inputType][filterType]
	if callbackRefData == nil then return end
	return callbackRefData.ref, callbackRefData.refType, callbackRefData.specialPanelControlFunc
end
libFilters_GetCallbackReference = libFilters.GetCallbackReference


--For the special callbacks: Detect the currently shown filterType and panel reference variables, and then raise the
--callback with "stateStr" (SCENE_SHOWN or SCENE_HIDDEN) for the relevant control/fragment/scene of that filterType
--Boolean inputType true gamepad, false keyboard input mode. Leave empty to automatically detect it
--Boolean doNotUpdateCurrentAndLastFilterTypes controls if the raise of the callback will save the now shown, and last shown, callbacks
--filterTypes etc., or not.
--returns nilable boolean true if the callback was raised, or false if not. nil will be returned if an error occured
function libFilters:RaiseShownFilterTypeCallback(stateStr, inputType, doNotUpdateCurrentAndLastFilterTypes)
	if inputType == nil then inputType = IsGamepad() end
	doNotUpdateCurrentAndLastFilterTypes = doNotUpdateCurrentAndLastFilterTypes or false
	detectShownReferenceNow = detectShownReferenceNow or libFilters.DetectShownReferenceNow
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
--> See file constants.lua, table universalDeconstructionTabNames
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
			wasShownBefore = libFilters.wasUniversalDeconPanelShownBefore
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
	if libFilters.debug then
		dv(">checkIfSpecialCallbackNeedsToBeAdded - %q, stateStr: %s, refType: %s", tos(refName), tos(stateStr), tos(refType))
	end
	local specialCallbackForCtrl = specialCallbacks[controlOrSceneOrFragmentRef]
	if specialCallbackForCtrl ~= nil then
		local funcToCall = specialCallbackForCtrl[stateStr]
		if funcToCall ~= nil and type(funcToCall) == "function" then
			if libFilters.debug then
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

	local doNotUpdateLastVars = libFilters.preventCallbackUpdateLastVars
	if stateStr == SCENE_SHOWN then
		--Call the code 1 frame later (zo_callLater with 0 ms > next frame) so the fragment's shown state (used within detectShownReferenceNow())
		--will be updated properly. Else it will fire too early and the fragment is still in state "Showing", on it's way to state "Shown"!
		zo_callLater(function()
			libFilters_CallbackRaise(libFilters, filterTypes, fragmentOrScene, stateStr, isInGamepadMode, typeOfRef, doNotUpdateLastVars, nil, nil)
			checkIfSpecialCallbackNeedsToBeAdded(fragmentOrScene, stateStr, isInGamepadMode, typeOfRef, refName)
		end, 0)
	else
		--For the scene fragment hiding, hidden and showing check there is no delay needed
		libFilters_CallbackRaise(libFilters, filterTypes, fragmentOrScene, stateStr, isInGamepadMode, typeOfRef, doNotUpdateLastVars, nil, nil)
		checkIfSpecialCallbackNeedsToBeAdded(fragmentOrScene, stateStr, isInGamepadMode, typeOfRef, refName)
	end
	libFilters.preventCallbackUpdateLastVars = nil
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
		if libFilters.debug then dd(">isFragmentBlockedByAlreadyDeterminedFilterType: %q - stateStr: %s - currentFilterType: %s",
					tos(fragmentName), tos(stateStr), tos(currentFilterType))
		end

		for _, filterTypeBlocked in ipairs(callbackFragmentBlockedFilterTypes) do
			if filterTypeBlocked == currentFilterType then
				if libFilters.debug then dd(">>>>> YES, filterType %s is blocked!", tos(filterTypeBlocked))	end
				return true
			end
		end
	end
	return false
end


local function onFragmentStateChange(oldState, newState, filterTypes, fragment, inputType)
	local fragmentName
	if libFilters.debug then
		fragmentName = getFragmentControlName(fragment) dd("~~~ FRAGMENT STATE CHANGE ~~~")
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
	if libFilters.debug then
		sceneName = getSceneName(scene)	dd("~~~ SCENE STATE CHANGE ~~~")
		dd("onSceneStateChange: %q - oldState: %s > newState: %q - #filterTypes: %s, isGamePad: %s", tos(sceneName), tos(oldState), tos(newState), #filterTypes, tos(inputType))
	end
	callbackRaiseCheck(filterTypes, scene, newState, inputType, LIBFILTERS_CON_TYPEOFREF_SCENE, sceneName)
end
libFilters.OnSceneStateChange = onSceneStateChange

function onControlHiddenStateChange(isShown, filterTypes, ctrlRef, inputType, specialPanelControlFunc, universalDeconData)
	local ctrlName
	if libFilters.debug then
		ctrlName = getCtrlName(ctrlRef)
		dd("~~~ CONTROL HIDDEN STATE CHANGE ~~~") dd("ControlHiddenStateChange: %q  - hidden: %s - #filterTypes: %s, isGamePad: %s", tos(ctrlName), tos(not isShown), #filterTypes, tos(inputType))
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
libFilters.OnControlHiddenStateChange = onControlHiddenStateChange

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
	if libFilters.debug then dd("-->CreateFragmentCallbacks---") end
	--Fragments
	--[fragment] = LF_* filterTypeConstant. 0 means no dedicated LF_* constant can be used and the filterType will be determined
	for inputType, callbackDataPerFilterType in pairs(callbacksUsingFragments) do
		for fragment, filterTypes in pairs(callbackDataPerFilterType) do
			createFragmentCallback(fragment, filterTypes, inputType)
		end
	end
end


local function createSceneCallbacks()
	if libFilters.debug then dd("-->CreateSceneCallbacks---") end
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
	if libFilters.debug then
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
			ctrlName = (libFilters.debug == true and ctrlName) or getCtrlName(controlRef)
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
	if libFilters.debug then dd("-->CreateControlCallbacks---") end
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
--d("[LibFilters]provisionerSpecialCallback - provFilterType: " ..tos(provFilterType) .. ", currentFilterType: " .. tos(currentFilterType) .. ", isInGamepadMode: " .. tos(isInGamepadMode))
	if (isInGamepadMode and not provisionerScene_GP:IsShowing()) or (not isInGamepadMode and not provisionerScene:IsShowing()) then
--d("<abort")
		return
	end
	local currentProvFilterType = (isInGamepadMode == true and provFilterType) or selfProvisioner.filterType
	local filterType = provisionerIngredientTypeToFilterType[currentProvFilterType]
	local doShow = (filterType ~= nil and true) or false

--d(">currentProvFilterType: " ..tos(currentProvFilterType) .. ", filterType: " ..tos(filterType) .. ", doShow: " .. tos(doShow))
	local hideOldProvFilterType = (filterType ~= nil and currentFilterType ~= nil and currentFilterType ~= filterType and true)  or false

	if overrideDoShow ~= nil then
		doShow = overrideDoShow
		hideOldProvFilterType = false
	end

	local provisionerControl = selfProvisioner.control
	local provCallbackName = (isInGamepadMode and "Gamepad Provisioner") or "Provisioner"

	if libFilters.debug then dd("~%s:OnTabFilterChanged: %s, filterType: %s, doShow: %s, hideOldProvFilterType: %s", tos(provCallbackName), tos(currentProvFilterType), tos(filterType), tos(doShow), tos(hideOldProvFilterType)) end
	if hideOldProvFilterType == true then
--d(">hide old")
		onControlHiddenStateChange(false, { currentFilterType }, provisionerControl, isInGamepadMode)
	end
	if doShow == false or (doShow == true and filterType ~= nil) then
--d(">hide/show new")
		onControlHiddenStateChange(doShow, { filterType }, provisionerControl, isInGamepadMode)
	end
end


local function createSpecialCallbacks()
	if libFilters.debug then dd("-->CreateSpecialCallbacks---") end

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
				if libFilters.debug then dd("~ABORT Enchanting:OnModeUpdated - currentFilterType is nil and lastFilterType not matching crafting type") end
				libFilters._lastFilterTypeNoCallback = false
				return
			else
				local lastKnownFilterType = libFilters._lastFilterType
				if lastKnownFilterType ~= nil then
					if libFilters.debug then
						libFilters_GetFilterTypeName = libFilters_GetFilterTypeName or libFilters.GetFilterTypeName
						dd("~Enchanting:OnModeUpdated - lastFilterType: %s[%s], noCallbackForLastFilterType: %s", tos(libFilters_GetFilterTypeName(libFilters, lastKnownFilterType)), tos(lastKnownFilterType), tos(libFilters._lastFilterTypeNoCallback))
					end
					if libFilters._lastFilterTypeNoCallback == true then
						libFilters._lastFilterTypeNoCallback = false
						return
					end
				end
			end
		end

		local currentFilterType = libFilters._currentFilterType
		local hideOldEnchantingFilterType = (filterType ~= nil and currentFilterType ~= nil and currentFilterType ~= filterType and true)  or false
		if libFilters.debug then dd("~Enchanting:OnModeUpdated: %s, filterType: %s, hideCurrentEnchantingFilterType: %s", tos(enchantingMode), tos(filterType), tos(hideOldEnchantingFilterType)) end
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
				if libFilters.debug then dd("~ABORT Alchemy:SetMode - currentFilterType is nil and lastFilterType not matching crafting type") end
				libFilters._lastFilterTypeNoCallback = false
				return
			else
				local lastKnownFilterType = libFilters._lastFilterType
				if lastKnownFilterType ~= nil then
					if libFilters.debug then
						libFilters_GetFilterTypeName = libFilters_GetFilterTypeName or libFilters.GetFilterTypeName
						dd("~Alchemy:SetMode - lastFilterType: %s[%s], noCallbackForLastFilterType: %s", tos(libFilters_GetFilterTypeName(libFilters, lastKnownFilterType)), tos(lastKnownFilterType), tos(libFilters._lastFilterTypeNoCallback))
					end
					if libFilters._lastFilterTypeNoCallback == true then
						libFilters._lastFilterTypeNoCallback = false
						return
					end
				end
			end
		end

		local currentFilterType = libFilters._currentFilterType
		local hideOldAlchemyFilterType = (filterType ~= nil and currentFilterType ~= nil and currentFilterType ~= filterType and true)  or false
		if libFilters.debug then dd("~Alchemy:SetMode: %s, filterType: %s, hideOldAlchemyFilterType: %s", tos(mode), tos(filterType), tos(hideOldAlchemyFilterType)) end
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
		if libFilters.debug then dd("<[EVENT_END_CRAFTING_STATION_INTERACT] craftSkill: %s, currentFilterType: %s, lastFilterType: %s, isUniversalDecon: %s",
				tos(craftSkill), tos(currentFilterType), tos(lastFilterType), tos(isUniversalDeconShown)) end

		local lastFilterTypeIsValidAtClosedCraftingTable = (lastFilterType ~= nil and checkForValidFilterTypeAtSamePanel(lastFilterType, nil, craftSkill)) or false
		if currentFilterType == nil and lastFilterTypeIsValidAtClosedCraftingTable == true then
			if libFilters.debug then dv(">lastFilterType will \'not\' raise a HIDDEN callback at next crafting table open!") end
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
				if libFilters.debug then dv(">currentFilterType is no crafting filterType at the closed crafting table! lastFilterType will raise a HIDDEN callback now!") end
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
			updateCurrentAndLastUniversalDeconVariables = updateCurrentAndLastUniversalDeconVariables or functions.updateCurrentAndLastUniversalDeconVariables
			updateCurrentAndLastUniversalDeconVariables(nil, true) --reset  libFilters._currentFilterTypeUniversalDeconTab
		end
	end

	local function eventCraftingStationInteract(eventId, craftSkill)
		if libFilters.debug then dd(">[EVENT_CRAFTING_STATION_INTERACT] craftSkill: %s", tos(craftSkill)) end
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
		libFilters.wasUniversalDeconPanelGPEventCraftingBeginUsed = false
		--If Gamepad Universal Deconstruction was shown before the first open of the panel will hide, show, hide the lastPanel (e.g. LF_INVENTORY)
		--and the universal decon tab somehow. Prevent this by setting a variable here and clering it at the UniversalDeconGamepad.deconstructionPanel.inventoy:OnFilterChanged
		--callback again
		if isInGamepadMode and libFilters.wasUniversalDeconPanelShownBefore == true then
			libFilters.wasUniversalDeconPanelGPEventCraftingBeginUsed = true
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
			if libFilters.debug then
					libFilters_GetFilterTypeName = libFilters_GetFilterTypeName or libFilters.GetFilterTypeName
					dd("~Gamepad Provisioner:OnTabFilterChanged - lastFilterType: %s[%s], noCallbackForLastFilterType: %s", tos(libFilters_GetFilterTypeName(libFilters, lastKnownFilterType)), tos(lastKnownFilterType), tos(libFilters._lastFilterTypeNoCallback))
			end
			if libFilters._lastFilterTypeNoCallback == true then
				libFilters._lastFilterTypeNoCallback = false
				return
			end
		end

		provisionerSpecialCallback(selfProvisioner, filterType, nil)
	end)
end


---------------------------------------------------------------------------------
-- Load the callbacks
---------------------------------------------------------------------------------
local function createCallbacks()
	if libFilters.debug then dd("---CreateCallbacks---") end
	if not libFilters.isInitialized and not callbacksCreated then return end

	createSceneCallbacks()
	createFragmentCallbacks()
	createControlCallbacks()
	createSpecialCallbacks()

	callbacksCreated = true
	if libFilters.debug then dd(">Callbacks were created") end
end
libFilters.CreateCallbacks = createCallbacks