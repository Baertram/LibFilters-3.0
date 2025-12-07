------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3 name, and version
------------------------------------------------------------------------------------------------------------------------
local libFilters 	= LibFilters3

--local MAJOR      	= libFilters.name
local GlobalLibName = libFilters.globalLibName
local filters    	= libFilters.filters
local horizontalScrollBarFilters = libFilters.horizontalScrollBarFilters

------------------------------------------------------------------------------------------------------------------------
--DEBUGGING & LOGGING
------------------------------------------------------------------------------------------------------------------------
--LibDebugLogger, or normal logger d() output
local logger = libFilters.logger
local debugFunctions = libFilters.debugFunctions

local dd 	= debugFunctions.dd
local dv 	= debugFunctions.dv
local dfe 	= debugFunctions.dfe


------------------------------------------------------------------------------------------------------------------------
--LOCAL SPEED UP VARIABLES & REFERENCES
------------------------------------------------------------------------------------------------------------------------
--Helper variables of ESO
local tos = tostring
local strmat = string.match
local strfor = string.format

--Game API local speedup
local EM = EVENT_MANAGER
local IsGamepad = IsInGamepadPreferredMode
local gcit = GetCraftingInteractionType
local ncc = NonContiguousCount
local isVengeanceCampaign = IsCurrentCampaignVengeanceRuleset

--LibFilters local speedup and reference variables
--Overall constants & mapping
local constants = 					libFilters.constants
local mapping = 					libFilters.mapping
local functions = 					libFilters.functions
local callbacks = 					mapping.callbacks

--Variables
local types = constants.types
local booleanType = types.bool
--local tableType = types.tab
local numberType = types.num
local stringType = types.str
--local userdataType = types.ud
local functionType = types.func


local defaultFilterUpdaterDelay = 	constants.defaultFilterUpdaterDelay

--Local LibFilters filterType references
local LF_FILTER_MIN = LF_FILTER_MIN
local LF_FILTER_MAX = LF_FILTER_MAX
local LF_FILTER_ALL = LF_FILTER_ALL
local LF_INVENTORY = LF_INVENTORY
local LF_CRAFTBAG = LF_CRAFTBAG
local LF_SMITHING_RESEARCH = LF_SMITHING_RESEARCH
local LF_INVENTORY_VENGEANCE = LF_INVENTORY_VENGEANCE
local LF_VENDOR_SELL_VENGEANCE = LF_VENDOR_SELL_VENGEANCE

--Callbacks
local callbackPattern = 			libFilters.callbackPattern

--Function references
local detectShownReferenceNow = libFilters.DetectShownReferenceNow

--Function references - Updated inline
local libFilters_IsStoreShown


local libFiltersFilterConstants = 	constants.filterTypes
local LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT = 				constants.LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT
local LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX = 			constants.LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX
local defaultLibFiltersAttributeToStoreTheFilterType = 				constants.defaultAttributeToStoreTheFilterType --"LibFilters3_filterType"
local defaultLibFiltersAttributeToStoreTheHorizontalScrollbarFilters = constants.defaultLibFiltersAttributeToStoreTheHorizontalScrollbarFilters --"LibFilters3_HorizontalScrollbarFilters"

local updaterNamePrefix = constants.updaterNamePrefix
local inventoryUpdaters = 											mapping.inventoryUpdaters
local updaterNameToFilterType =										mapping.updaterNameToFilterType
local filterTypesUsingBagIdAndSlotIndexFilterFunction = 			mapping.filterTypesUsingBagIdAndSlotIndexFilterFunction
local filterTypesUsingInventorySlotFilterFunction = 				mapping.filterTypesUsingInventorySlotFilterFunction
local filterTypeToFilterTypeRespectingCraftType = 					mapping.filterTypeToFilterTypeRespectingCraftType
local filterTypeToUpdaterName = 									mapping.filterTypeToUpdaterName
local LF_FilterTypeToReference = 									mapping.LF_FilterTypeToReference
local LF_FilterTypesToReferenceImplementedSpecial = 			    mapping.LF_FilterTypesToReferenceImplementedSpecial
local LF_FilterTypeToReferenceGamepadFallbackToKeyboard =  			mapping.LF_FilterTypeToReferenceGamepadFallbackToKeyboard
local universalDeconTabKeyToLibFiltersFilterType	   =			mapping.universalDeconTabKeyToLibFiltersFilterType
local universalDeconLibFiltersFilterTypeSupported = 				mapping.universalDeconLibFiltersFilterTypeSupported
local filterTypeToUpdaterListName_GP = 								mapping.filterTypeToUpdaterListName_GP
local craftBagUpdaterItemListName = filterTypeToUpdaterListName_GP[LF_CRAFTBAG].item

--Keyboard
local kbc                      	= 	constants.keyboard
local playerInv                	= 	kbc.playerInv
local inventories              	= 	kbc.inventories
local inventoryTypes			=	constants.inventoryTypes
local invTypeBackpack 			=   inventoryTypes["player"]

local storeWindows             	= 	kbc.storeWindows
local companionEquipment 	   	= 	kbc.companionEquipment
local companionEquipmentCtrl   	= 	companionEquipment.control
local characterCtrl            	=	kbc.characterCtrl
local companionCharacterCtrl   	= 	kbc.companionCharacterCtrl
local refinementPanel		   	=   kbc.refinementPanel
local creationPanel			   	=   kbc.creationPanel
local deconstructionPanel	   	=   kbc.deconstructionPanel
local improvementPanel	   	   	=   kbc.improvementPanel
local researchPanel			   	=   kbc.researchPanel
local enchanting               	= 	kbc.enchanting
local enchantingInvCtrl        	= 	enchanting.inventoryControl
local alchemy                  	= 	kbc.alchemy
local alchemyCtrl              	=	kbc.alchemyCtrl
local provisioner			   	=   kbc.provisioner
local universalDeconstructPanel = 	kbc.universalDeconstructPanel
local universalDeconstructScene =   kbc.universalDeconstructScene


--Gamepad
local gpc                       = 	constants.gamepad
local invBackpack_GP            = 	gpc.invBackpack_GP
local store_GP                  = 	gpc.store_GP
local store_componentsActiveGP  =   store_GP.activeComponents
local companionEquipment_GP 	=   gpc.companionEquipment_GP
local companionEquipmentCtrl_GP = 	companionEquipment_GP.control
local companionCharacterCtrl_GP = 	gpc.companionCharacterCtrl_GP
local refinementPanel_GP	    =   gpc.refinementPanel_GP
local creationPanel_GP		    =   gpc.creationPanel_GP
local deconstructionPanel_GP    =   gpc.deconstructionPanel_GP
local improvementPanel_GP		=   gpc.improvementPanel_GP
local researchPanel_GP          = 	gpc.researchPanel_GP
local enchantingInvCtrls_GP     = 	gpc.enchantingInvCtrls_GP
local alchemy_GP                = 	gpc.alchemy_GP 				--#10
local alchemyCtrl_GP            =	gpc.alchemyCtrl_GP
local provisioner_GP			=   gpc.provisioner_GP
local invMailSend_GP 			= 	gpc.invMailSend_GP
local universalDeconstructPanel_GP = gpc.universalDeconstructPanel_GP
local universalDeconstructScene_GP = gpc.universalDeconstructScene_GP

--Other addons
local cbeSupportedFilterPanels  = constants.cbeSupportedFilterPanels

--functions
local checkIfCachedFilterTypeIsStillShown = functions.checkIfCachedFilterTypeIsStillShown
local checkIfStoreCtrlOrFragmentShown = functions.checkIfStoreCtrlOrFragmentShown
local getDialogOwner = functions.getDialogOwner
local getSmithingResearchPanel = functions.getSmithingResearchPanel
local craftBagExtendedCheckForCurrentModule = functions.craftBagExtendedCheckForCurrentModule

--Local pre-defined function names. Code will be added further down in this file. Only created here already to be re-used
--in code prior to creation (functions using it won't be called before creation was done, but they are local and more
--DOWN in the lua file than the actual fucntion's creation is done -> lua interpreter wouldn't find it).
local libFilters_IsListDialogShown
local libFilters_IsUniversalDeconstructionPanelShown
local libFilters_GetCurrentFilterTypeForInventory
local libFilters_GetCurrentFilterTypeReference
local libFilters_GetFilterTypeReferences
local libFilters_GetFilterTypeName
local libFilters_IsCraftBagShown


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
--LOCAL HELPER FUNCTIONS - filterType mapping
------------------------------------------------------------------------------------------------------------------------
--Returns nil if no matching filterType was found for the passed in filterTypeSource and the craftType
--Else returns the filterType matching the for the passed in filterTypeSource and the craftType
--2nd return parameter is the craftType passed in, or if nothing was in: the detected craftType
local function getFilterTypeByFilterTypeRespectingCraftType(filterTypeSource, craftType)
	if filterTypeSource == nil then return nil end
	if craftType ~= nil and (type(craftType) ~= numberType
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

------------------------------------------------------------------------------------------------------------------------
--LibFilters API functions, globally accessible for other addons
------------------------------------------------------------------------------------------------------------------------

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
	if newState == nil or type(newState) ~= booleanType then
		dfe("Invalid call to SetFilterAllState(%q).\n>Needed format is: boolean newState",
			tos(newState))
		return
	end
	if libFilters.debug then dd("SetFilterAllState-%s", tos(newState)) end
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
	if libFilters.debug then dv("GetFilterTypeName - filterType: %q", tos(filterType)) end
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
	if libFilters.debug then dd("GetFilterTypeFunctionType-%q", tos(filterType)) end
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
		local invVarIsNumber = (type(inventoryType) == numberType) or false
		if not invVarIsNumber then
			--Check if inventoryType is a SCENE or fragment, e.g. GAMEPAD_ENCHANTING_CREATION_SCENE
			if inventoryType.sceneManager ~= nil and inventoryType[defaultLibFiltersAttributeToStoreTheFilterType] ~= nil then --.LibFilters3_filterType
				filterTypeDetected = inventoryType[defaultLibFiltersAttributeToStoreTheFilterType] --.LibFilters3_filterType
			end
		end
		--Afterwards:
		--Get the inventory from PLAYER_INVENTORY.inventories if the numberType check returns true,
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

	if libFilters.debug then dd("GetCurrentFilterTypeForInventory-%q: %s, error: %s", tos(inventoryType), tos(filterTypeDetected), tos(errorAppeared)) end
	return filterTypeDetected
end
libFilters_GetCurrentFilterTypeForInventory = libFilters.GetCurrentFilterTypeForInventory


-- Get the actually used filterType via the shown control/scene/userdata information
--Not implemented: If optional parameter table referencesTab (e.g. { [1] = controlRef } is passed in we will try to detect the filterType (if it cannot be detected via the usual way) directly from the reference
-- returns number LF*_filterType
--		   String universalDeconSelectedTabKey e.g. "all", "weapons", "armor", "jewelry", "enchantments" if the universal deconstruction panel is currently active
-->		 (which re-usess LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT and LF_ENCHANTING_EXTRACT)
function libFilters:GetCurrentFilterType()
	local noRefUpdate = true
	local filterTypeReference, filterType, universalDeconSelectedTabKey = libFilters_GetCurrentFilterTypeReference(libFilters, nil, nil)
	if libFilters.debug then dd("GetCurrentFilterType-filterReference: %s, filterTypeDetected: %s, universalDeconTabKey: %s", tos(filterTypeReference), tos(filterType), tos(universalDeconSelectedTabKey)) end
	if filterTypeReference == nil then
	--[[
		if type(referencesTab) ~= tableType then return nil, nil end
		filterTypeReference = referencesTab
		noRefUpdate = false
	]]
		return
	end

	--updateLastAndCurrentFilterType(nil, filterTypeReference, false)

	local currentFilterType = filterType
	--FilterType was not detected yet (e.g. from cached filterType currently shown)
	if currentFilterType == nil and universalDeconSelectedTabKey == nil then
		--Check each shown variable for the LibFilters filterType LF_* constant
		for _, shownVariable in ipairs(filterTypeReference) do
			--Only do not update the references to libFilters._currentFilterTypeReferences if it was done above already (inside libFilters_GetCurrentFilterTypeReference)
			currentFilterType = libFilters_GetCurrentFilterTypeForInventory(libFilters, shownVariable, noRefUpdate)
			if currentFilterType ~= nil then
				if libFilters.debug then dd(">filterTypeDetected updated to: %s", tos(currentFilterType)) end
				return currentFilterType
			end
		end
	end

	--[[
	--Still nothing found? Check if we passed in a reference table and get the reference objects
	if currentFilterType == nil and not ZO_IsTableEmpty(referencesTab) then
d(">trying to detect filterType by passed in referencesTab")
		local filterTypeReference, filterTypeShown, l_universalDeconSelectedTabKey = detectShownReferenceNow(nil, IsGamepad(), false, false)
		if filterTypeShown ~= nil then
d("[LibFilters]GetCurrentFilterType - Detected current shown filterType: " .. tos(currentFilterType))
			currentFilterType = filterTypeShown
			universalDeconSelectedTabKey = l_universalDeconSelectedTabKey
		end
	end
	]]

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
	if libFilters.debug then dd("GetFilterTypeRespectingCraftType-source: %q, target: %q, craftType: %s", tos(filterTypeSource), tos(filterTypeMappedByCraftingType), tos(craftType)) end
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
	if libFilters.debug then dd("IsFilterRegistered-%q,%s", tos(filterTag), tos(filterType)) end
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
	if libFilters.debug then dd("IsAllFilterRegistered-%q", tos(filterTag)) end
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
	if libFilters.debug then dd("IsFilterTagPatternRegistered-%q,%s,%s", tos(filterTagPattern), tos(filterType), tos(compareToLowerCase)) end
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
	if not filterTag or not filterType or not filterCallbacks or type(filterCallback) ~= functionType then
		dfe(registerFilterParametersErrorStr, "RegisterFilter", tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError))
		return
	end
	noInUseError = noInUseError or false
	if libFilters.debug then dd("RegisterFilter-%q,%q,%q,%s", tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError)) end
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
	if not filterTag or not filterType or not filterCallbacks or type(filterCallback) ~= functionType then
		dfe(registerFilterParametersErrorStr, "RegisterFilterIfUnregistered",
				tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError))
		return
	end
	if libFilters.debug then dd("RegisterFilterIfUnregistered-%q,%q,%q,%s", tos(filterTag), tos(filterType), tos(filterCallback), tos(noInUseError)) end
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
	if libFilters.debug then dd("UnregisterFilter-%q,%s", tos(filterTag), tos(filterType)) end
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
	if libFilters.debug then dd("GetFilterCallback-%q,%q", tos(filterTag), tos(filterType)) end
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
	if libFilters.debug then dd("GetFilterTypeCallbacks-%q", tos(filterType)) end
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
	if libFilters.debug then dd("GetFilterTagCallbacks-%q,%s,%s", tos(filterTag), tos(filterType), tos(compareToLowerCase)) end
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
	if libFilters.debug then dd("GetFilterTagPatternCallbacks-%q,%s,%s", tos(filterTagPattern), tos(filterType), tos(compareToLowerCase)) end
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
	if libFilters.debug then dv("[U-API]RequestUpdateByName-%q,%s,%s", tos(updaterName), tos(delay), tos(filterType)) end

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
		if type(delay) ~= numberType then
			dfe("Invalid OPTIONAL 2nd argument \'delay\' to RequestUpdateByName(%s).\n>Needed format is: number milliSecondsToDelay",
					tos(delay))
			return
		else
			if delay < 0 then delay = 0 end
		end
	else
		delay = defaultFilterUpdaterDelay --default value: 10ms
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
	if not filterType or not updaterName or updaterName == "" then
		dfe("Invalid arguments to RequestUpdate(%q).\n>Needed format is: number LibFiltersLF_*FilterType",
			tos(filterType))
		return
	end
	if libFilters.debug then dd("[U-API]RequestUpdate filterType: %q, updaterName: %s, delay: %s", tos(filterType), tos(updaterName), tos(delay)) end
	libFilters_RequestUpdateByName(libFilters, updaterName, delay, filterType)
end


--Update the normal filters (LF_SMITHING_RESEARCH / LF_JEWELRY_RESEARCH) and the horizontal scrollbar filters
-- (fromResearcLineIndex, toResearchLineIndex, skipTable) for the crafting researchPanel
--OPTIONAL parameter number delay will add a delay to the call of the updater function
function libFilters:RequestUpdateForResearchFilters(delay)
	local updaterName = "SMITHING_RESEARCH"
	if libFilters.debug then dd("[U-API]RequestUpdateForResearchFilters delay: %s", tos(delay)) end
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
	if libFilters.debug then dd("GetFilterTypeUpdaterName filterType: %q", tos(filterType)) end
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
	if libFilters.debug then dd("GetUpdaterNameFilterType updaterName: %q", tos(updaterName)) end
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
	if libFilters.debug then dd("GetUpdaterCallback updaterName: %q", tos(updaterName)) end
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
	if libFilters.debug then dd("GetFilterTypeUpdaterCallback filterType: %q", tos(filterType)) end
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
	if libFilters.debug then dd("GetFilterTypeReferences filterType: %q, %s", tos(filterType), tos(isInGamepadMode)) end
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
	if libFilters.debug then dd("[---] GetCurrentFilterTypeReference filterType: %q, %s [---]", tos(filterType), tos(isInGamepadMode)) end

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
	if libFilters.debug then dd(">isInventoryBaseShown: %s", tos(resultVar)) end
	return resultVar
end


local gamepadInventoryCategoryListNonSupportedFilters      = {
	[ITEMFILTERTYPE_QUEST] 				= true,
	[ITEMFILTERTYPE_QUEST_QUICKSLOT] 	= true,
}
local gamepadInventoryCategoryListIndicesWithoutFilterType = {
	[3] = true, --Supplies/Vorräte
}
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
			local selectedGPInvFilter = invBackpack_GP.selectedItemFilterType
			--local selectedGPInvEquipmentSlot = invBackpack_GP.selectedEquipSlot -- equipped items = character
			local selectedItemUniqueId = invBackpack_GP.selectedItemUniqueId
			local categoryListSelectedIndex = categoryList.selectedIndex --categoryListIndex 3 is 'Vorräte" which got no selectedItemFilterType and no selectedItemUniqueId -> Thus it would return false

			--Categories list is shown (1st level, e.g. material, weapons, armor, consumables, ...)
			if isCategoryListShown then
				if  (selectedGPInvFilter ~= nil and gamepadInventoryCategoryListNonSupportedFilters[selectedGPInvFilter])
					or (selectedGPInvFilter == nil and not gamepadInventoryCategoryListIndicesWithoutFilterType[categoryListSelectedIndex]) then --or selectedGPInvEquipmentSlot ~= nil
					isInvShown = false
					abortNow = true
				end

			--Items list is shown (2nd level with single items, e.g. 2hd weapons, light armor, ...)
			elseif isItemListShown then
				if (selectedGPInvFilter ~= nil and gamepadInventoryCategoryListNonSupportedFilters[selectedGPInvFilter])
					or (selectedGPInvFilter == nil and selectedItemUniqueId == nil) then --or selectedGPInvEquipmentSlot ~= nil
					isInvShown = false
					abortNow = true
				end

			end
			if not abortNow then
				isInvShown = true
			end
		end

	--Keyboard
	else
		--isInvShown = not playerInvCtrl:IsHidden()
		isInvShown, listShownGP = isInventoryBaseShown(false), nil
	end
	if libFilters.debug then dd("IsInventoryShown: %s", tos(isInvShown)) end
	return isInvShown, listShownGP
end


--Is the companion inventory control shown
--returns boolean isShown
function libFilters:IsCompanionInventoryShown()
    return (IsGamepad() and not companionEquipmentCtrl_GP:IsHidden()) or not companionEquipmentCtrl:IsHidden()
end

--Is the Vengeance Inventory shown
--returns boolean isShown
function libFilters:IsVengeanceInventoryShown()
	if isVengeanceCampaign() then
		local lReferencesToFilterType, lFilterTypeDetected
		local inputType = IsGamepad()
		if inputType == true then
			if invBackpack_GP.vengeanceCategoryList ~= nil then
				local currentGPInvListType = invBackpack_GP.currentListType
				if libFilters.debug then dd("IsVengeanceInventoryShown> active: %s, actionMode: %s, currentListType: %s",
						tos(invBackpack_GP.vengeanceCategoryList:IsActive() or invBackpack_GP.vengeanceItemList:IsActive()), tos(invBackpack_GP.actionMode), tos(currentGPInvListType)) end
				if (invBackpack_GP.vengeanceCategoryList:IsActive() or currentGPInvListType == "vengeanceCategoryList")
				   or (invBackpack_GP.vengeanceItemList:IsActive() or currentGPInvListType == "vengeanceItemList") then
					lFilterTypeDetected = 		LF_INVENTORY_VENGEANCE
					lReferencesToFilterType = 	LF_FilterTypeToReference[inputType][LF_INVENTORY_VENGEANCE]
				end
			end
		else
			lReferencesToFilterType, lFilterTypeDetected = detectShownReferenceNow(LF_INVENTORY_VENGEANCE, nil, false, true)
		end
		local vengeanceInventoryShown = ((lFilterTypeDetected ~= nil and lFilterTypeDetected == LF_INVENTORY_VENGEANCE and lReferencesToFilterType ~= nil) and true) or false
		if libFilters.debug then dd("IsVengeanceInventoryShown: %s", tos(vengeanceInventoryShown)) end
		return vengeanceInventoryShown
	end
	return false
end

--Is the Vengeance Store shown
--returns boolean isShown
--ZO_VENGEANCE_BAG_SELL_ENABLED = true --todo 20251207 Disable again after testing!
function libFilters:IsVengeanceStoreShown()
	if isVengeanceCampaign() and ZO_VENGEANCE_BAG_SELL_ENABLED == true then
		local lReferencesToFilterType, lFilterTypeDetected
		local inputType = IsGamepad()
		if inputType == true then
			libFilters_IsStoreShown = libFilters_IsStoreShown or libFilters.IsStoreShown
			if libFilters_IsStoreShown(libFilters, ZO_MODE_STORE_SELL_VENGEANCE) then
				if libFilters.debug then dd("IsVengeanceStoreShown: true") end
				lFilterTypeDetected = 		LF_VENDOR_SELL_VENGEANCE
				lReferencesToFilterType = 	LF_FilterTypeToReference[inputType][LF_VENDOR_SELL_VENGEANCE]
			end
		else
			lReferencesToFilterType, lFilterTypeDetected = detectShownReferenceNow(LF_VENDOR_SELL_VENGEANCE, nil, false, true)
		end
		local vengeanceStoreShown = ((lFilterTypeDetected ~= nil and lFilterTypeDetected == LF_VENDOR_SELL_VENGEANCE and lReferencesToFilterType ~= nil) and true) or false
		if libFilters.debug then dd("IsVengeanceStoreShown: %s", tos(vengeanceStoreShown)) end
		return vengeanceStoreShown
	end
	return false
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
	local bankingBag = GetBankingBag()
	local isBankShown = not IsHouseBankBag(bankingBag) and not IsFurnitureVault(bankingBag)
	if IsGamepad() then
		isBankShown = gpc.invBankScene_GP:IsShowing()
	else
		isBankShown = kbc.invBankScene:IsShowing()
	end
	return isBankShown
end
local libFilters_IsBankShown = libFilters.IsBankShown


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
	local bankingBag = GetBankingBag()
	local isHouseBankShown = IsHouseBankBag(bankingBag) and not IsFurnitureVault(bankingBag)
	if not isHouseBankShown then return false end
	if IsGamepad() then
		isHouseBankShown = gpc.invBankScene_GP:IsShowing()
	else
		isHouseBankShown = kbc.invHouseBankScene:IsShowing()
	end
	return isHouseBankShown
end
local libFilters_IsHouseBankShown = libFilters.IsHouseBankShown


--Is the furniture vault shown
--returns boolean isShown
function libFilters:IsFurnitureVaultShown()
	 --HOUSING_EDITOR_STATE:CanDepositIntoFurnitureVault()
	local isFurnitureBagShown = IsFurnitureVault(GetBankingBag())
	if not isFurnitureBagShown then return false end
	if IsGamepad() then
		isFurnitureBagShown = gpc.invBankScene_GP:IsShowing()
	else
		isFurnitureBagShown = kbc.furnitureVaultScene:IsShowing()
	end
	return isFurnitureBagShown
end
local libFilters_IsFurnitureVaultShown = libFilters.IsFurnitureVaultShown


--Is the normal bank shown (no house bank and no furniture vault)
--returns boolean IsNormalBankShown
function libFilters:IsNormalBankShown()
	if libFilters_IsHouseBankShown(libFilters) or libFilters_IsFurnitureVaultShown(libFilters) then
		return false
	end
	return libFilters_IsBankShown(libFilters)
end

--Check if the mail send panel is shown.
--return boolean isShown, control mailSendPanel
function libFilters:IsMailSendShown()
	if IsGamepad() then
		if gpc.invMailSendFragment_GP:IsShowing() and invMailSend_GP ~= nil then
			if invMailSend_GP.send.inventoryList and invMailSend_GP.send.inventoryList:IsActive() then
				return true, invMailSend_GP.send
			end
		end
	else
		if kbc.mailSendFragment ~= nil and kbc.mailSendFragment:IsShowing() then
			return true, kbc.mailSendFragment.control
		end
	end
	return false, nil
end

--Check if the store (vendor) panel is shown
--If OPTIONAL parameter number storeMode (either ZO_MODE_STORE_BUY, ZO_MODE_STORE_BUY_BACK, ZO_MODE_STORE_SELL,
--ZO_MODE_STORE_REPAIR, ZO_MODE_STORE_SELL_STOLEN, ZO_MODE_STORE_LAUNDER, ZO_MODE_STORE_STABLE, ZO_MODE_STORE_SELL_VENGEANCE) is provided the store
--mode must be set at the store panel, if it is shown, to return true
--return boolean isShown, number storeMode, userdata/control/scene/fragment whatHasBeenDetectedToBeShown
function libFilters:IsStoreShown(storeMode)
	if not ZO_Store_IsShopping() or (storeMode and storeMode < 1) then return false, storeMode, nil end
	if IsGamepad() then
		local currentStoreMode = store_GP:GetCurrentMode()
		if currentStoreMode == nil then
			--Is any component of the store shown (only loop the active components!)
			for lStoreMode, storeComponentCtrl in pairs(store_componentsActiveGP) do
				if checkIfStoreCtrlOrFragmentShown(storeComponentCtrl, lStoreMode, true) == true then
					return true, lStoreMode, storeComponentCtrl
				end
			end
		else
			local storeActiveComponent = store_GP:GetActiveComponent()
			--Compare passed in storeMode with the currently shown one
			if storeMode ~= nil then
				if currentStoreMode ~= storeMode then
					return false, currentStoreMode, storeActiveComponent
				else
					return true, currentStoreMode, storeActiveComponent
				end
			end
			local isStoreCtrlShown, storeCtrl, _ = checkIfStoreCtrlOrFragmentShown(storeActiveComponent, currentStoreMode, true)
			return isStoreCtrlShown, currentStoreMode, storeCtrl
		end
	else
		--local storeWindowMode = store:GetWindowMode() --returns if in stable mode -> ZO_STORE_WINDOW_MODE_STABLE
		for lStoreMode, storeControlOrFragment in pairs(storeWindows) do
			if checkIfStoreCtrlOrFragmentShown(storeControlOrFragment, lStoreMode, false) == true then
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
libFilters_IsStoreShown = libFilters.IsStoreShown


--Is a list dialog currently shown?
--OPTIONAL parameter number filterType to detect the owner control which's hidden state will be checked
--OPTIONAL parameter userdata/control dialogOwnerControlToCheck which's hidden state will be checked
--Any of the 2 parameters needs to be passed in
--returns boolean isListDialogShown
function libFilters:IsListDialogShown(filterType, dialogOwnerControlToCheck)
	if filterType == nil and dialogOwnerControlToCheck == nil then return false end
	libFilters_IsListDialogShown = libFilters_IsListDialogShown or libFilters.IsListDialogShown
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
	if libFilters.debug then dd("IsListDialogShown-filterType: %q, craftType: %s, dialogOwnerControl: %s", --filterTypeMapped: %q
				tos(filterType), tos(craftType), tos(dialogOwnerControlToCheck)) --tos(filterTypeMappedByCraftingType)
	end
	if dialogOwnerControlToCheck == nil then return false end
	return libFilters_IsListDialogShown(dialogOwnerControlToCheck)
end
libFilters_IsListDialogShown = libFilters.IsListDialogShown


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

--Check if the Provisioner panel is shown
--If OPTIONAL parameter number provisionerMode (either PROVISIONER_MODE_ROOT, PROVISIONER_MODE_CREATION, PROVISIONER_MODE_FILLET is provided this
-- provisioner mode must be set at the provisioner panel, if it is shown, to return true
--return boolean isShown, number provisionerMode, provisionerFilterType, userdata/control/scene/fragment whatHasBeenDetectedToBeShown
function libFilters:IsProvisionerShown(provisionerMode)
	if IsGamepad() then
		if provisioner_GP ~= nil and provisioner_GP.control ~= nil and not provisioner_GP.control:IsHidden() then
			local lProvisionerMode = provisioner_GP.mode
			local provisionerFilterType = provisioner_GP.filterType
			if provisionerMode ~= nil then
				if lProvisionerMode and lProvisionerMode == provisionerMode then
					return true, provisionerMode, provisionerFilterType, provisioner_GP
				end
			else
				return true, lProvisionerMode, provisionerFilterType, provisioner_GP
			end
		end
	else
		if provisioner ~= nil and not provisioner:IsHidden() then
			local lProvisionerMode = provisioner.mode
			local provisionerFilterType = provisioner.filterType
			if provisionerMode ~= nil then
				if lProvisionerMode and lProvisionerMode == provisionerMode then
					return true, provisionerMode, provisionerFilterType, provisioner
				end
			else
				return true, lProvisionerMode, provisionerFilterType, provisioner
			end
		end
	end
	return false, provisionerMode, nil, nil
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
	if libFilters.debug then dv("IsUniversalDeconstructionPanelShown - %q, gamepadMode: %s", tos(isShowing), tos(isGamepadMode)) end
	return isShowing, universalDeconScene
end
libFilters_IsUniversalDeconstructionPanelShown = libFilters.IsUniversalDeconstructionPanelShown



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

	if ncc(combinedSkipTables) == 0 then
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
--d("[LibFilters3]applyCraftingResearchHorizontalScrollbarFilters")
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
	if libFilters.debug then dd("RegisterResearchHorizontalScrollbarFilter-%q,%q,%q,%q,%q,%s", tos(filterTag), tos(craftingType), tos(skipTable), tos(fromResearchLineIndex), tos(toResearchLineIndex), tos(noInUseError)) end
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
	if libFilters.debug then dd("UnregisterResearchHorizontalScrollbarFilter-%q,%s", tos(filterTag), tos(craftingType)) end
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
	if libFilters.debug then dv(">IsCraftBagExtendedParentFilterType: %s, CBE enabled: %s",
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
			if libFilters.debug then dd("IsVanillaCraftBagShown> active: %s, actionMode: %s, currentListType: %s",
					tos(invBackpack_GP.craftBagList:IsActive()), tos(invBackpack_GP.actionMode), tos(invBackpack_GP.currentListType)) end
			if invBackpack_GP.craftBagList:IsActive() or invBackpack_GP.currentListType == craftBagUpdaterItemListName then --"craftBagList"
				lFilterTypeDetected = 		LF_CRAFTBAG
				lReferencesToFilterType = 	LF_FilterTypeToReference[inputType][LF_CRAFTBAG]
			end
		end
	else
		lReferencesToFilterType, lFilterTypeDetected = detectShownReferenceNow(LF_CRAFTBAG, nil, false, true)
	end
	local vanillaUICraftBagShown = ((lFilterTypeDetected ~= nil and lFilterTypeDetected == LF_CRAFTBAG and lReferencesToFilterType ~= nil) and true) or false
	if libFilters.debug then dd("IsVanillaCraftBagShown - vanillaUIShown: %s", tos(vanillaUICraftBagShown)) end
	return vanillaUICraftBagShown
end
local libFilters_IsVanillaCraftBagShown = libFilters.IsVanillaCraftBagShown


--Is any CraftBag shown, vanilla UI or CraftBagExtended
--returns boolean isShown
function libFilters:IsCraftBagShown()
	local vanillaUICraftBagShown = libFilters_IsVanillaCraftBagShown(libFilters)
	local cbeCraftBagShown = libFilters_IsCraftBagExtendedParentFilterType(libFilters, cbeSupportedFilterPanels)
	if libFilters.debug then dd("IsCraftBagShown - vanillaUIShown: %s, cbeShown: %s", tos(vanillaUICraftBagShown), tos(cbeCraftBagShown)) end
	if vanillaUICraftBagShown == true or cbeCraftBagShown == true then return true end
	return false
end
libFilters_IsCraftBagShown = libFilters.IsCraftBagShown


--**********************************************************************************************************************
-- Callback API
--**********************************************************************************************************************
local function getAddonCallbackName(yourAddonName, isShown, filterType, universalDeconActiveTab)
	universalDeconActiveTab = universalDeconActiveTab or ""
	return strfor(callbackPattern, tos(yourAddonName), (isShown == true and SCENE_SHOWN) or SCENE_HIDDEN, tos(filterType), tos(universalDeconActiveTab))
end

--Create the callback name for a libFilters filterPanel shown/hidden callback
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
	if yourAddonName == nil or yourAddonName == "" or yourAddonName == GlobalLibName or type(yourAddonName) ~= stringType then
		dfe("[RegisterCallbackName]ERROR - The addonName %q must be a string, or cannot be used!", tos(yourAddonName))
		return
	end
	if type(isShown) ~= booleanType then
		dfe("[RegisterCallbackName]ERROR - isShown %q needs to be a boolean (false/true)!", tos(isShown))
		return
	end
	if universalDeconActiveTab == nil then universalDeconActiveTab = "" end
	if type(universalDeconActiveTab) ~= stringType or (universalDeconActiveTab ~= "" and universalDeconTabKeyToLibFiltersFilterType[universalDeconActiveTab] == nil) then
		dfe("[RegisterCallbackName]ERROR - universalDeconActiveTab %q needs to be a String (all/armor/weapons/jewelry/enchantments)!", tos(universalDeconActiveTab))
		return
	end
	if raiseBeforeOtherAddonsCallbackName ~= nil and (raiseBeforeOtherAddonsCallbackName == "" or raiseBeforeOtherAddonsCallbackName == GlobalLibName or type(raiseBeforeOtherAddonsCallbackName) ~= stringType) then
		dfe("[RegisterCallbackName]ERROR - The raiseBeforeOtherAddonsCallbackName %q must be a string, or cannot be used!", tos(raiseBeforeOtherAddonsCallbackName))
		return
	end

	--Build the unique callback Name
	--local callBackUniqueName = strfor(callbackPattern, tos(yourAddonName), (isShown == true and SCENE_SHOWN) or SCENE_HIDDEN, tos(filterType), tos(universalDeconActiveTab))
	local callBackUniqueName = getAddonCallbackName(tos(yourAddonName), (isShown == true and SCENE_SHOWN) or SCENE_HIDDEN, tos(filterType), tos(universalDeconActiveTab))

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
	elseif type(inputType) == booleanType then
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


--Remove an added callback name for a libFilters filterPanel shown/hidden callback again
--It will remove the entry in table LibFilters3.mapping.callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType][isShown]
--number filterType needs to be a valid LF_* filterType constant
--boolean isShown true means SCENE_SHOWN will be used, and false means SCENE_HIDDEN will be used for the callbackname
--boolean inputType true = Gamepad, false= keyboard callback, leave empty for both!
--nilable:String universalDeconActiveTab The active tab at the universal deconstruction panel that this callback should be raised for, e.g. "all", "armor", "weapons", "jewelry" or "enchanting"
--Returns boolean wasRemoved true/false
function libFilters:UnregisterCallbackName(yourAddonName, filterType, isShown, inputType, universalDeconActiveTab)
	isShown = isShown or false
	if yourAddonName == nil or yourAddonName == "" or yourAddonName == GlobalLibName or type(yourAddonName) ~= stringType then
		dfe("[UnregisterCallbackName]ERROR - The addonName %q must be a string, or cannot be used!", tos(yourAddonName))
		return
	end
	if type(isShown) ~= booleanType then
		dfe("[UnregisterCallbackName]ERROR - isShown %q needs to be a boolean (false/true)!", tos(isShown))
		return
	end
	if universalDeconActiveTab == nil then universalDeconActiveTab = "" end
	if type(universalDeconActiveTab) ~= stringType or (universalDeconActiveTab ~= "" and universalDeconTabKeyToLibFiltersFilterType[universalDeconActiveTab] == nil) then
		dfe("[UnregisterCallbackName]ERROR - universalDeconActiveTab %q needs to be a String (all/armor/weapons/jewelry/enchantments)!", tos(universalDeconActiveTab))
		return
	end

	--Build the unique callback Name
	--local callBackUniqueName = strfor(callbackPattern, tos(yourAddonName), (isShown == true and SCENE_SHOWN) or SCENE_HIDDEN, tos(filterType), tos(universalDeconActiveTab))
	local callBackUniqueName = getAddonCallbackName(tos(yourAddonName), (isShown == true and SCENE_SHOWN) or SCENE_HIDDEN, tos(filterType), tos(universalDeconActiveTab))

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

						if ncc(callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab][filterType]) == 0 then
							callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab][filterType] = nil
						end
						if ncc(callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab]) == 0 then
							callbacks.registeredCallbacks[false][yourAddonName][universalDeconActiveTab] = nil
						end
						if ncc(callbacks.registeredCallbacks[false][yourAddonName]) == 0 then
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

						if ncc(callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab][filterType]) == 0 then
							callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab][filterType] = nil
						end
						if ncc(callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab]) == 0 then
							callbacks.registeredCallbacks[true][yourAddonName][universalDeconActiveTab] = nil
						end
						if ncc(callbacks.registeredCallbacks[true][yourAddonName]) == 0 then
							callbacks.registeredCallbacks[true][yourAddonName] = nil
						end
					end
				end
			end
		end
	elseif type(inputType) == booleanType then
		if callbacks.registeredCallbacks[inputType][yourAddonName] ~= nil then
			if callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab] ~= nil then
				if callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType]  ~= nil then
					local callbackData = callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType][isShown]
					if callbackData ~= nil and callbackData.callbackName == callBackUniqueName then
						callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType][isShown] = nil
						callbacks.allRegisteredAddonCallbacks[callBackUniqueName] = nil

						if ncc(callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType]) == 0 then
							callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType] = nil
						end
						if ncc(callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab]) == 0 then
							callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab] = nil
						end
						if ncc(callbacks.registeredCallbacks[inputType][yourAddonName]) == 0 then
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