------------------------------------------------------------------------------------------------------------------------
--LIBRARY CONSTANTS
------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3 name, and version
local MAJOR, GlobalLibName, MINOR = "LibFilters-3.0", "LibFilters3", 4.1

--Was the library loaded already? Abort here then
if _G[GlobalLibName] ~= nil then return end

--local lua speed-up variables
local tos = tostring
local strform = string.format
local strup = string.upper
local tins = table.insert

local IsGamepad = IsInGamepadPreferredMode

--local ZOs speed-up variables
--local IsGamepad = IsInGamepadPreferredMode
local SM = SCENE_MANAGER
local getScene = SM.GetScene

--Local library variable
local libFilters = {}

------------------------------------------------------------------------------------------------------------------------
--Create global library constant LibFilters3
_G[GlobalLibName] 			= libFilters --global table LibFilters3
libFilters.name	            = MAJOR
libFilters.version          = MINOR
libFilters.globalLibName    = GlobalLibName
------------------------------------------------------------------------------------------------------------------------

libFilters.filters = {}
local filters = libFilters.filters

--Horizontal scrollbar filters for e.g. crafting tables research panel
libFilters.horizontalScrollBarFilters = {}
local horizontalScrollBarFilters = libFilters.horizontalScrollBarFilters
horizontalScrollBarFilters["craftingResearch"] = {}

-- Initialization will be done via function "libFilters:InitializeLibFilters()" which should be called in addons once,
-- after EVENT_ADD_ON_LOADED
libFilters.isInitialized = false

--Use the LF_FILTER_ALL registered filters as fallback filterFunctions for all panels -> see file LibFilters-3.0.lua,
--function runFilters, and API function libFilters:SetFilterAllState(boolean newState)
libFilters.useFilterAllFallback = false

--Local variables used further down below
local filterTypeToCheckIfReferenceIsHidden

------------------------------------------------------------------------------------------------------------------------
--Debugging output enabled/disabled: Changed via SLASH_COMMANDS /libfiltersdebug or /lfdebug
libFilters.debug = false
local isDebugEnabled = libFilters.debug

--LibDebugLogger & debugging functions
if LibDebugLogger then
	 if not libFilters.logger then
		  libFilters.logger = LibDebugLogger(GlobalLibName)
	 end
end
local logger = libFilters.logger

--Debugging functions
libFilters.debugFunctions = {}
local debugFunctions = libFilters.debugFunctions


--Debugging output
local function debugMessage(text, textType)
	 if not text or text == "" then return end
	 textType = textType or 'I'
	 if logger ~= nil then
		  if textType == 'D' then
				logger:Debug(text)
		  elseif textType == 'E' then
				logger:Error(text)
		  elseif textType == 'I' then
				logger:Info(text)
		  elseif textType == 'V' then
				logger:Verbose(text)
		  elseif textType == 'W' then
				logger:Warn(text)
		  end
	 else
		  local textTypeToPrefix = {
				["D"] = "Debug",
				["E"] = "|cFF0000ERROR|r",
				["I"] = "Info",
				["V"] = "Verbose",
				["W"] = "Warning",
		  }
		  d("[".. MAJOR .."]" .. tos(textTypeToPrefix[textType]) .. ": ".. tos(text))
	 end
end
debugFunctions.debugMessage = debugMessage


--Debugging output
local function debugMessageCaller(debugType, ...)
	debugMessage(strform(...), strup(debugType))
end
debugFunctions.debugMessageCaller = debugMessageCaller

--Debugging
local function dd(...)
	debugMessageCaller('D', ...)
end
debugFunctions.dd = dd

--Information
local function df(...)
	debugMessageCaller('I', ...)
end
debugFunctions.df = df

--Vebose "spammy" message
local function dv(...)
	debugMessageCaller('V', ...)
end
debugFunctions.dv = dv

--Error message
local function dfe(...)
	debugMessageCaller('E', ...)
end
debugFunctions.dfe = dfe


--Debugging slash commands
local function debugSlashToggle(args)
	libFilters.debug = not libFilters.debug
	df("Debugging %s", (not libFilters.debug and "disabled") or "enabled")
	libFilters.UpdateIsDebugEnabled()
end
debugFunctions.debugSlashToggle = debugSlashToggle


if libFilters.debug then dd("LIBRARY CONSTANTS FILE - START") end


------------------------------------------------------------------------------------------------------------------------
libFilters.constants = {}
local constants = libFilters.constants

--10 milliseconds delay before filter update routines run -> to combine same updaters and unstress the client/server
constants.defaultFilterUpdaterDelay = 10


------------------------------------------------------------------------------------------------------------------------
--LF_* FILTER PANEL ID constants
------------------------------------------------------------------------------------------------------------------------
-- LibFilters filterPanel constants [value number] = "name"
--The possible libFilters filterPanelIds
-- !!!IMPORTANT !!! Do not change the order as these numbers were added over time and need to keep the same order !!!
--> Else the constants do not match the correct values anymore and will filter the wrong panels!
local libFiltersFilterConstants = {
	 [1]	= "LF_INVENTORY",
	 [2]	= "LF_BANK_WITHDRAW",
	 [3]	= "LF_BANK_DEPOSIT",
	 [4]	= "LF_GUILDBANK_WITHDRAW",
	 [5]	= "LF_GUILDBANK_DEPOSIT",
	 [6]	= "LF_VENDOR_BUY",
	 [7]	= "LF_VENDOR_SELL",
	 [8]	= "LF_VENDOR_BUYBACK",
	 [9]	= "LF_VENDOR_REPAIR",
	 [10]  	= "LF_GUILDSTORE_BROWSE",
	 [11]  	= "LF_GUILDSTORE_SELL",
	 [12]  	= "LF_MAIL_SEND",
	 [13]  	= "LF_TRADE",
	 [14]  	= "LF_SMITHING_REFINE",
	 [15]  	= "LF_SMITHING_CREATION",
	 [16]  	= "LF_SMITHING_DECONSTRUCT",
	 [17]  	= "LF_SMITHING_IMPROVEMENT",
	 [18]  	= "LF_SMITHING_RESEARCH",
	 [19]  	= "LF_ALCHEMY_CREATION",
	 [20]  	= "LF_ENCHANTING_CREATION",
	 [21]  	= "LF_ENCHANTING_EXTRACTION",
	 [22]  	= "LF_PROVISIONING_COOK",
	 [23]  	= "LF_PROVISIONING_BREW",
	 [24]  	= "LF_FENCE_SELL",
	 [25]  	= "LF_FENCE_LAUNDER",
	 [26]  	= "LF_CRAFTBAG",
	 [27]  	= "LF_QUICKSLOT",
	 [28]  	= "LF_RETRAIT",
	 [29]  	= "LF_HOUSE_BANK_WITHDRAW",
	 [30]  	= "LF_HOUSE_BANK_DEPOSIT",
	 [31]  	= "LF_JEWELRY_REFINE",
	 [32]  	= "LF_JEWELRY_CREATION",
	 [33]  	= "LF_JEWELRY_DECONSTRUCT",
	 [34]  	= "LF_JEWELRY_IMPROVEMENT",
	 [35]  	= "LF_JEWELRY_RESEARCH",
	 [36]  	= "LF_SMITHING_RESEARCH_DIALOG",
	 [37]  	= "LF_JEWELRY_RESEARCH_DIALOG",
	 [38]  	= "LF_INVENTORY_QUEST",
	 [39]  	= "LF_INVENTORY_COMPANION",
	 --Add new lines here and make sure you also take care of the control of the inventory needed in tables "LibFilters.filters",
	 --the updater name in table "filterTypeToUpdaterName*" and updaterFunction in table "inventoryUpdaters",
	 --as well as the way to hook to the inventory.additionalFilter in function "HookAdditionalFilters",
	 --or via a fragment in table "fragmentToFilterType",
	 --and maybe an overwritten "filter enable function" (which respects the entries of the added additionalFilter) in
	 --file "helpers.lua"
	 --[<number constant>] = "LF_...",
}
--register the filterConstants for the filterpanels in the global table _G
for value, filterConstantName in ipairs(libFiltersFilterConstants) do
	 _G[filterConstantName] = value

	--Create empty table for each filter constant LF_*
	filters[_G[filterConstantName]] = {}
end

--Get the min and max filterPanelIds
LF_FILTER_MIN					= LF_INVENTORY
LF_FILTER_MAX					= #libFiltersFilterConstants
LF_FILTER_ALL					= 9999

--Add the filterTypes to the constants
constants.filterTypes = libFiltersFilterConstants


--The default attribute at an inventory/layoutData/scene/control/userdata used within table filterTypeToReference
--to store the libFilters 3.0 filterType. This will be used to determine which filterType is currently used and store the
--filters + run the filter of the filterType.
--e.g.for keyboard player inventory see table filterTypeToReference[false][LF_INVENTORY]. Both, the
--PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK] will add the .LibFilters3_filterType attribute = LF_INVENTORY and the
--fragment BACKPACK_MENU_BAR_LAYOUT_FRAGMENT will add .LibFilters3_filterType attribute = LF_INVENTORY too. The fragment
--is needed in addition as the nomal inventory is used for multiple panels, e.g. mail send, trade, bank deposit etc. and
--only different fragments are able to distinguish the filtertype then!
local defaultLibFiltersAttributeToStoreTheFilterType = "LibFilters3_filterType"
constants.defaultAttributeToStoreTheFilterType = defaultLibFiltersAttributeToStoreTheFilterType

--The default attribute at the researchPanel (currently the only one) to store the horizontal scroll list filters'
--combined skipTable at
local defaultLibFiltersAttributeToStoreTheHorizontalScrollbarFilters = "LibFilters3_HorizontalScrollbarFilters"
constants.defaultLibFiltersAttributeToStoreTheHorizontalScrollbarFilters = defaultLibFiltersAttributeToStoreTheHorizontalScrollbarFilters


--The default attribute at an inventory/layoutData table where the filter functions of LiFilters should be added to
--and where ZOs or other addons could have already added filter functions to -> See LibFilters-3.0.lua, function HookAdditionalFilters
-->Default is: .additionalFilter e.g. at PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK] and BACKPACK_MENU_BAR_LAYOUT_FRAGMENT
-->Example why these are used, see above at comment above "defaultLibFiltersAttributeToStoreTheFilterType"
--
--!!! Important !!! There exist other special attributes which need to be applied as "fixes" -> e.g. for LF_CraftBag.
-- Please search below for "local otherOriginalFilterAttributesAtLayoutData_Table = {"
local defaultOriginalFilterAttributeAtLayoutData = "additionalFilter"
constants.defaultAttributeToAddFilterFunctions = defaultOriginalFilterAttributeAtLayoutData


--The prefix for the updater name used in libFilters:RequestUpdate()
local updaterNamePrefix = GlobalLibName .. "_update_"
constants.updaterNamePrefix = updaterNamePrefix


------------------------------------------------------------------------------------------------------------------------
--ZOs / ESOUI CONSTANTS
------------------------------------------------------------------------------------------------------------------------
constants.keyboard = {}
--KeyboardConstants
local kbc 						= constants.keyboard

constants.gamepad    = {}
--GamepadConstants
local gpc						= constants.gamepad

--Custom created fragments for the gamepad mode
--Prefix of these fragments
gpc.customFragmentPrefix        = GlobalLibName:upper() .. "_" -- LIBFILTERS3_


------------------------------------------------------------------------------------------------------------------------
--CONSTANTS (*_GP is the gamepad mode constant, the others are commonly used with both, or keyboard only constants)
------------------------------------------------------------------------------------------------------------------------
--The types of reference variables for the filterTypes and their detection
local typeOfRefConstants = {
	[1] =   1, -- Control
	[2] =   2, -- Scene
	[3] =   3, -- Fragment
	[99] = 99, -- Other
}
constants.typeOfRef = typeOfRefConstants
local LIBFILTERS_CON_TYPEOFREF_CONTROL 	= typeOfRefConstants[1]
local LIBFILTERS_CON_TYPEOFREF_SCENE 	= typeOfRefConstants[2]
local LIBFILTERS_CON_TYPEOFREF_FRAGMENT = typeOfRefConstants[3]
local LIBFILTERS_CON_TYPEOFREF_OTHER 	= typeOfRefConstants[99]

--The names of the type of reference
constants.typeOfRefToName = {
	[1] = "Control",
	[2] = "Scene",
	[3] = "Fragment",
	[99]= "Other",
}

--Constants of control names that should be searched "below" (childs) of a given control, as the control checks are done
--in function getCtrl()
local subControlsToLoop = {
		[1] = "control",
		[2] = "container",
		[3] = "list",
		[4] = "listView",
		[5] = "panelControl",
	}
constants.subControlsToLoop = subControlsToLoop

local function checkIfControlSceneFragmentOrOther(refVar)
	local retVar
	--Scene or fragment
	if refVar.sceneManager or refVar.state or refVar._state then
		if refVar.name ~= nil or refVar.fragments ~= nil then
			retVar = LIBFILTERS_CON_TYPEOFREF_SCENE -- Scene
		else
			retVar = LIBFILTERS_CON_TYPEOFREF_FRAGMENT -- Fragment
		end
	--Control
	elseif refVar.control or refVar.IsHidden then
		retVar = LIBFILTERS_CON_TYPEOFREF_CONTROL -- Controlor TopLevelControl
	--Other
	else
		retVar = LIBFILTERS_CON_TYPEOFREF_OTHER -- Other, e.g. boolean
	end
	if libFilters.debug then dv("!checkIfControlSceneFragmentOrOther - refVar %q: %s", tos(refVar), tos(retVar)) end
	return retVar
end
libFilters.CheckIfControlSceneFragmentOrOther = checkIfControlSceneFragmentOrOther

local function getCtrl(retCtrl)
	local checkType = "retCtrl"
	local ctrlToCheck = retCtrl

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
libFilters.GetCtrl = getCtrl

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
		if isDebugEnabled then dv("!checkIfRefVarIsShown - scene state: %q", tos(refVar.state)) end
		isShown = ((refVar.state == SCENE_SHOWN and true) or (refVar.IsShowing ~= nil and refVar:IsShowing())) or false
	--Fragment
	elseif refType == LIBFILTERS_CON_TYPEOFREF_FRAGMENT then
		if isDebugEnabled then dv("!checkIfRefVarIsShown - fragment state: %q", tos(refVar.state)) end
		isShown = ((refVar.state == SCENE_FRAGMENT_SHOWN and true) or (refVar.IsShowing ~= nil and refVar:IsShowing())) or false
	--Other
	elseif refType == LIBFILTERS_CON_TYPEOFREF_OTHER then
		if type(refVar) == "boolean" then
			isShown = refVar
		else
			isShown = false
		end
	end
	if isDebugEnabled then dv("!checkIfRefVarIsShown - refVar %q: %s, refType: %s", tos(refVar), tos(isShown), tos(refType)) end
	return isShown, refVar, refType
end
libFilters.CheckIfRefVarIsShown = checkIfRefVarIsShown

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
libFilters.GetFragmentControlName = getFragmentControlName

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
libFilters.GetSceneName = getSceneName

local function getCtrlName(ctrlVar)
	if ctrlVar ~= nil then
		local ctrlName
		if ctrlVar.GetName ~= nil then
			ctrlName = ctrlVar:GetName()
		elseif ctrlVar.name ~= nil then
			ctrlName = ctrlVar.name
		end
		if ctrlName ~= nil and ctrlName ~= "" then return ctrlName end
	end
	return "n/a"
end
libFilters.GetCtrlName = getCtrlName

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
libFilters.GetTypeOfRefName = getTypeOfRefName

local function getRefName(refVar)
	local typeOfRef = checkIfControlSceneFragmentOrOther(refVar)
	if typeOfRef == LIBFILTERS_CON_TYPEOFREF_CONTROL then
		return getCtrlName(refVar)
	elseif typeOfRef == LIBFILTERS_CON_TYPEOFREF_SCENE then
		return getSceneName(refVar)
	elseif typeOfRef == LIBFILTERS_CON_TYPEOFREF_FRAGMENT then
		return getFragmentControlName(refVar)
	end
	return "n/a"
end
libFilters.GetRefName = getRefName


--Check if a control is assigned to the filterType and inputType and if it is currently shown/hidden
--returns boolean isShown, controlReference controlWhichIsShown
local function isControlShown(filterType, isInGamepadMode)
	if isInGamepadMode == nil then isInGamepadMode = IsGamepad() end
	local filterTypeData = filterTypeToCheckIfReferenceIsHidden[isInGamepadMode][filterType]
	if filterTypeData == nil then
		if isDebugEnabled then dv("!isControlShown - filterType %s: %s, gamepadMode: %s, error: %s", tos(filterType), tos(false), tos(isInGamepadMode), "filterTypeData is nil!") end
		return false, nil
	end
	local retCtrl = filterTypeData["control"]

	local ctrlToCheck, checkType = getCtrl(retCtrl)
	if ctrlToCheck == nil or (ctrlToCheck ~= nil and ctrlToCheck.IsHidden == nil) then
		if isDebugEnabled then dv("!isControlShown - filterType %s: %s, gamepadMode: %s, error: %s", tos(filterType), tos(false), tos(isInGamepadMode), "no control/listView with IsHidden function found!") end
		return false, nil
	end
	local isShown = not ctrlToCheck:IsHidden()
	if isDebugEnabled then dv("!isControlShown - filterType %s, isShown: %s, gamepadMode: %s, retCtrl: %s, checkType: %s", tos(filterType), tos(isShown), tos(isInGamepadMode), tos(ctrlToCheck), tos(checkType)) end
	return isShown, ctrlToCheck
end
libFilters.IsControlShown = isControlShown

------------------------------------------------------------------------------------------------------------------------
-- Variables: Inventory
------------------------------------------------------------------------------------------------------------------------

--[Inventory types]
local invTypeBackpack           		=	INVENTORY_BACKPACK
local invTypeQuest              		= 	INVENTORY_QUEST_ITEM
local invTypeBank               		=	INVENTORY_BANK
local invTypeGuildBank          		=	INVENTORY_GUILD_BANK
local invTypeHouseBank 					=	INVENTORY_HOUSE_BANK
local invTypeCraftBag 					= 	INVENTORY_CRAFT_BAG
constants.inventoryTypes = {}
constants.inventoryTypes["player"]		=	invTypeBackpack
constants.inventoryTypes["quest"] 		= 	invTypeQuest
constants.inventoryTypes["bank"] 		= 	invTypeBank
constants.inventoryTypes["guild_bank"] 	=	invTypeGuildBank
constants.inventoryTypes["house_bank"] 	= 	invTypeHouseBank
constants.inventoryTypes["craftbag"] 	=	invTypeCraftBag


------------------------------------------------------------------------------------------------------------------------
--Other addons
------------------------------------------------------------------------------------------------------------------------
--CraftBagExtended
local cbeSupportedFilterPanels = {
	LF_MAIL_SEND,
	LF_TRADE,
	LF_VENDOR_SELL,
	LF_GUILDSTORE_SELL,
	LF_BANK_DEPOSIT, LF_GUILDBANK_DEPOSIT, LF_HOUSE_BANK_DEPOSIT,
}
constants.cbeSupportedFilterPanels = cbeSupportedFilterPanels


------------------------------------------------------------------------------------------------------------------------
--Keyboard constants
------------------------------------------------------------------------------------------------------------------------
--Inventory
kbc.playerInv                     = PLAYER_INVENTORY
local playerInv = kbc.playerInv
kbc.inventories                   = playerInv.inventories
local inventories                 = kbc.inventories
kbc.playerInvCtrl                 = ZO_PlayerInventory
kbc.inventoryFragment 			  = INVENTORY_FRAGMENT
local inventoryFragment		   	  =	kbc.inventoryFragment
inventoryFragment._name = "INVENTORY_FRAGMENT"

--Character
kbc.characterCtrl                 =	ZO_Character

--Backpack
kbc.invBackpack                   = inventories[invTypeBackpack]
local invBackpack                 = kbc.invBackpack
kbc.invBackpackFragment           = BACKPACK_MENU_BAR_LAYOUT_FRAGMENT
kbc.invBackpackFragment._name = "BACKPACK_MENU_BAR_LAYOUT_FRAGMENT"

--Craftbag
kbc.craftBagClass  				  = ZO_CraftBag
kbc.invCraftbag                   = inventories[invTypeCraftBag]
local invCraftbag 				  = kbc.invCraftbag
kbc.craftBagFragment 			  = CRAFT_BAG_FRAGMENT
local craftBagFragment 			  = kbc.craftBagFragment
craftBagFragment._name = "CRAFT_BAG_FRAGMENT"

--Quest items
kbc.invQuests                     = inventories[invTypeQuest]
local invQuests					  = kbc.invQuests
kbc.invQuestFragment			  = QUEST_ITEMS_FRAGMENT
local invQuestFragment 			  = kbc.invQuestFragment
invQuestFragment._name = "QUEST_ITEMS_FRAGMENT"

--Quickslots
kbc.quickslots                    = QUICKSLOT_KEYBOARD
local quickslots 				  = kbc.quickslots
kbc.quickslotsFragment            = KEYBOARD_QUICKSLOT_FRAGMENT
local quickslotsFragment 		  = kbc.quickslotsFragment
quickslotsFragment._name = "KEYBOARD_QUICKSLOT_FRAGMENT"


--[Banks]
--Player bank
kbc.invBankDeposit                = BACKPACK_BANK_LAYOUT_FRAGMENT
local invBankDeposit 			  = kbc.invBankDeposit
invBankDeposit._name = "BACKPACK_BANK_LAYOUT_FRAGMENT"
kbc.invBankWithdraw               = inventories[invTypeBank]
local invBankWithdraw 			  = kbc.invBankWithdraw
kbc.bankWithdrawFragment          = BANK_FRAGMENT
local bankWithdrawFragment 		  = kbc.bankWithdrawFragment
bankWithdrawFragment._name = "BANK_FRAGMENT"
kbc.invBankScene      		  	  = getScene(SM, "bank")
local invBankScene 				  = kbc.invBankScene

--Guild bank
kbc.invGuildBankDeposit           = BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT
local invGuildBankDeposit 		  = kbc.invGuildBankDeposit
invGuildBankDeposit._name = "BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT"
kbc.invGuildBankWithdraw          = inventories[invTypeGuildBank]
local invGuildBankWithdraw 		  = kbc.invGuildBankWithdraw
kbc.guildBankWithdrawFragment     = GUILD_BANK_FRAGMENT
local guildBankWithdrawFragment   = kbc.guildBankWithdrawFragment
guildBankWithdrawFragment._name = "GUILD_BANK_FRAGMENT"
kbc.invGuildBankScene      		  = getScene(SM, "guildBank")
local invGuildBankScene 		  = kbc.invGuildBankScene

--House bank
kbc.invHouseBankDeposit           = BACKPACK_HOUSE_BANK_LAYOUT_FRAGMENT
local invHouseBankDeposit 		  = kbc.invHouseBankDeposit
invHouseBankDeposit._name = "BACKPACK_HOUSE_BANK_LAYOUT_FRAGMENT"
kbc.invHouseBankWithdraw          = inventories[invTypeHouseBank]
local invHouseBankWithdraw	  	  = kbc.invHouseBankWithdraw
kbc.houseBankWithdrawFragment     = HOUSE_BANK_FRAGMENT
local houseBankWithdrawFragment	  = kbc.houseBankWithdrawFragment
houseBankWithdrawFragment._name = "HOUSE_BANK_FRAGMENT"
kbc.invHouseBankScene      		  = getScene(SM, "houseBank")
local invHouseBankScene 		  = kbc.invHouseBankScene


--[Vendor]
----Buy
kbc.store                         = STORE_WINDOW
local store 					  = kbc.store
---Sell
kbc.vendorBuy                     =	kbc.store
local vendorBuy 				  = kbc.vendorBuy
kbc.vendorBuyFragment			  = STORE_FRAGMENT
local vendorBuyFragment 	  	  = kbc.vendorBuyFragment
vendorBuyFragment._name = "STORE_FRAGMENT"
kbc.vendorSell        			  = BACKPACK_STORE_LAYOUT_FRAGMENT
local vendorSell 				  = kbc.vendorSell
vendorSell._name = "BACKPACK_STORE_LAYOUT_FRAGMENT"

---Buy back
kbc.vendorBuyBack     			  = BUY_BACK_WINDOW
local vendorBuyBack		  	 	  = kbc.vendorBuyBack
kbc.vendorBuyBackFragment		  = BUY_BACK_FRAGMENT
local vendorBuyBackFragment 	  = kbc.vendorBuyBackFragment
vendorBuyBackFragment._name = "BUY_BACK_FRAGMENT"

---Repair
kbc.vendorRepair                  = REPAIR_WINDOW
local vendorRepair 				  = kbc.vendorRepair
kbc.vendorRepairFragment          = REPAIR_FRAGMENT
local vendorRepairFragment 		  = kbc.vendorRepairFragment
vendorRepairFragment._name = "REPAIR_FRAGMENT"
kbc.storeWindows                  = {
	[ZO_MODE_STORE_BUY] = 			vendorBuy,
	[ZO_MODE_STORE_BUY_BACK] = 		vendorBuyBack,
	[ZO_MODE_STORE_SELL] = 			vendorSell,
	[ZO_MODE_STORE_REPAIR] = 		vendorRepair,
	[ZO_MODE_STORE_SELL_STOLEN] = 	vendorSell,
	[ZO_MODE_STORE_LAUNDER] = 		vendorSell,
	[ZO_MODE_STORE_STABLE] = 		vendorBuy,
}


--[Fence]
--Fence launder
kbc.fence                         = FENCE_KEYBOARD
local fence = kbc.fence
kbc.invFenceLaunderFragment       = BACKPACK_LAUNDER_LAYOUT_FRAGMENT
local invFenceLaunderFragment 	  = kbc.invFenceLaunderFragment
invFenceLaunderFragment._name = "BACKPACK_LAUNDER_LAYOUT_FRAGMENT"
invFenceLaunderFragment._state = "AddedByLibFiltersForDetection"

--Fence sell
kbc.invFenceSellFragment 		  = BACKPACK_FENCE_LAYOUT_FRAGMENT
local invFenceSellFragment 		  = kbc.invFenceSellFragment
invFenceSellFragment._name = "BACKPACK_FENCE_LAYOUT_FRAGMENT"
invFenceSellFragment._state = "AddedByLibFiltersForDetection"

--[Guild store]
kbc.guildStoreObj                 = ZO_TradingHouse
local guildStoreObj 			  = kbc.guildStoreObj
--keyboardConstants.guildStoreBuy = guildStoreBuy			--not supported by LibFilters yet
kbc.guildStoreBrowseFragment      = TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD_FRAGMENT
local guildStoreBrowseFragment	  = kbc.guildStoreBrowseFragment
guildStoreBrowseFragment._name = "TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD_FRAGMENT"

kbc.guildStoreSellLayoutFragment  = BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT
local guildStoreSellLayoutFragment= kbc.guildStoreSellLayoutFragment
guildStoreSellLayoutFragment._name = "BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT"
kbc.guildStoreSellFragment        = inventoryFragment
local guildStoreSellFragment 	  = kbc.guildStoreSellFragment


--[Mail]
kbc.mailSendObj        			= MAIL_SEND
kbc.mailSendFragment   			= BACKPACK_MAIL_LAYOUT_FRAGMENT
local mailSendFragment 			= kbc.mailSendFragment
mailSendFragment._name 			= "BACKPACK_MAIL_LAYOUT_FRAGMENT"

--[Player 2 player trade]
kbc.player2playerTradeObj         = TRADE --TRADE_WINDOW
kbc.player2playerTradeFragment 	  = BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT
local player2playerTradeFragment = kbc.player2playerTradeFragment
player2playerTradeFragment._name = "BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT"


--[Companion]
kbc.companionEquipment            = COMPANION_EQUIPMENT_KEYBOARD
local companionEquipment 		  = kbc.companionEquipment
kbc.companionEquipmentFragment	  = COMPANION_EQUIPMENT_KEYBOARD_FRAGMENT
local companionEquipmentFragment  = kbc.companionEquipmentFragment
companionEquipmentFragment._name = "COMPANION_EQUIPMENT_KEYBOARD_FRAGMENT"
kbc.companionCharacterCtrl        = ZO_CompanionCharacterWindow_Keyboard_TopLevel
kbc.companionCharacterFragment    = COMPANION_CHARACTER_KEYBOARD_FRAGMENT
kbc.companionCharacterFragment._name = "COMPANION_CHARACTER_KEYBOARD_FRAGMENT"



--[Crafting]
kbc.smithing                      = SMITHING
local smithing                    = kbc.smithing

--Refinement
kbc.refinementPanel               = smithing.refinementPanel
local refinementPanel 			  = kbc.refinementPanel

--Create
kbc.creationPanel                 = smithing.creationPanel
local creationPanel 			  = kbc.creationPanel

--Deconstruction
kbc.deconstructionPanel           = smithing.deconstructionPanel
local deconstructionPanel 		  = kbc.deconstructionPanel

--Improvement
kbc.improvementPanel              = smithing.improvementPanel
local improvementPanel 			  = kbc.improvementPanel

--Research
kbc.researchPanel                 = smithing.researchPanel
local researchPanel 			  = kbc.researchPanel
kbc.researchChooseItemDialog      = SMITHING_RESEARCH_SELECT
local researchChooseItemDialog 	  = kbc.researchChooseItemDialog

--Enchanting
kbc.enchantingClass               = ZO_Enchanting
kbc.enchanting                    =	ENCHANTING
local enchanting = kbc.enchanting
kbc.enchantingScene			      = ENCHANTING_SCENE
local enchantingScene 			  = kbc.enchantingScene

--Alchemy
kbc.alchemyClass                  =	ZO_Alchemy
kbc.alchemy                       =	ALCHEMY
local alchemy 					  = kbc.alchemy
kbc.alchemyScene                  =	ALCHEMY_SCENE
local alchemyScene 				  = kbc.alchemyScene
kbc.alchemyCtrl                   = alchemy.control
kbc.alchemyFragment               =	ALCHEMY_FRAGMENT
local alchemyFragment 			  = kbc.alchemyFragment
alchemyFragment._name = "ALCHEMY_FRAGMENT"

--Provisioning
kbc.provisionerClass              =	ZO_Provisioner
kbc.provisioner			          = PROVISIONER
local provisioner 				  = kbc.provisioner
kbc.provisionerFragment			  = PROVISIONER_FRAGMENT
local provisionerFragment		  = kbc.provisionerFragment
provisionerFragment._name = "PROVISIONER_FRAGMENT"
kbc.provisionerScene			  = PROVISIONER_SCENE

--Retrait
--keyboardConstants.retraitClass  = ZO_RetraitStation_Retrait_Base
kbc.retrait                       = ZO_RETRAIT_KEYBOARD
local retrait 					  = kbc.retrait
kbc.retraitFragment				  = RETRAIT_STATION_RETRAIT_FRAGMENT
local retraitFragment 			  = kbc.retraitFragment
retraitFragment._name = "RETRAIT_STATION_RETRAIT_FRAGMENT"

--Reconstruction
kbc.reconstruct                   =	ZO_RECONSTRUCT_KEYBOARD --todo not used yet

--Universal Deconstruction
local universalDeconstructPanel
kbc.universalDeconstruct 	  = UNIVERSAL_DECONSTRUCTION
kbc.universalDeconstructPanel = kbc.universalDeconstruct.deconstructionPanel
universalDeconstructPanel = kbc.universalDeconstructPanel
kbc.universalDeconstructScene = UNIVERSAL_DECONSTRUCTION_KEYBOARD_SCENE

--Dialogs
kbc.listDialog1 				= ZO_ListDialog1
local listDialog1 = kbc.listDialog1

--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

------------------------------------------------------------------------------------------------------------------------
--Gamepad constants
------------------------------------------------------------------------------------------------------------------------
--gamepadConstants
--[Inventories]
--Inventory
gpc.playerInvCtrl_GP 			= kbc.playerInvCtrl -- ZO_PlayerInventory

--Backpack
gpc.invBackpack_GP   			= GAMEPAD_INVENTORY
local invBackpack_GP 			= gpc.invBackpack_GP
gpc.invRootScene_GP  			= getScene(SM, "gamepad_inventory_root") --GAMEPAD_INVENTORY_ROOT_SCENE
local invRootScene_GP 			= gpc.invRootScene_GP
gpc.invFragment_GP				= GAMEPAD_INVENTORY_FRAGMENT
local invFragment_GP = gpc.invFragment_GP


--Character


--Craftbag
--gamepadConstants.invCraftbag_GP =	inventories[invTypeCraftBag] --TODO: test if GP craftbag still works. Else uncomment and re-add to filterTypeToReference[true] again

--Quest items
--custom created gamepad fragment "gamepadLibFiltersInventoryQuestFragment"

--Quickslots
gpc.quickslots_GP 				= GAMEPAD_QUICKSLOT					--TODO: remove? Quickslots for gamepad are handled differently
gpc.quickslotScene_GP 			= getScene(SM, "gamepad_quickslot")
gpc.quickslotFragment_GP		= GAMEPAD_QUICKSLOT_FRAGMENT
local quickslotFragment_GP 		= gpc.quickslotFragment_GP


--[Banks]
--Player bank
gpc.invBank_GP                  = GAMEPAD_BANKING
gpc.invBankScene_GP      		= getScene(SM, "gamepad_banking")
local invBankScene_GP 			= gpc.invBankScene_GP
--deposit: See custom gamepad fragments
--withdraw: Uses same as keyboard

--Guild bank
gpc.invGuildBank_GP      		= GAMEPAD_GUILD_BANK
gpc.invGuildBankScene_GP 		= GAMEPAD_GUILD_BANK_SCENE
local invGuildBankScene_GP 		= gpc.invGuildBankScene_GP
--deposit: See custom gamepad fragments
--withdraw: Uses same as keyboard

--House bank
--Control/scene is same as normal player bank
--deposit: See custom gamepad fragments
--withdraw: Uses same as keyboard


--[Vendor]
gpc.storeScene_GP 				= getScene(SM, "gamepad_store")
local storeScene_GP 			= gpc.storeScene_GP
gpc.storeFragment_GP			= GAMEPAD_VENDOR_FRAGMENT
----Buy
gpc.store_GP                    = STORE_WINDOW_GAMEPAD
gpc.vendorBuy_GP                = ZO_GamepadStoreBuy 			--store_GP.components[ZO_MODE_STORE_BUY].list
local storeComponents = gpc.store_GP.components
---Sell
gpc.vendorSell_GP               = ZO_GamepadStoreSell 			--store_GP.components[ZO_MODE_STORE_SELL].list
---Buy back
gpc.vendorBuyBack_GP            = ZO_GamepadStoreBuyback 		--store_GP.components[ZO_MODE_STORE_BUY_BACK].list
---Repair
gpc.vendorRepair_GP             = ZO_GamepadStoreRepair 		--store_GP.components[ZO_MODE_STORE_REPAIR].list


--[Fence]
kbc.fence_GP                    = FENCE_GAMEPAD
--Fence launder
gpc.invFenceLaunder_GP          = ZO_GamepadFenceLaunder

--Fence sell
gpc.invFenceSell_GP             = ZO_GamepadFenceSell


--[Guild store]
gpc.tradingHouseBrowse_GP		= GAMEPAD_TRADING_HOUSE_BROWSE --not supported by LibFilters yet. Will be NIL here, and updated later via SecurePostHook("ZO_TradingHouse_Browse_Gamepad_OnInitialize", function()
gpc.tradingHouseBrowseResults_GP= GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS
--gpc.tradingHouseListings_GP		= GAMEPAD_TRADING_HOUSE_LISTINGS
gpc.invGuildStore_GP			= TRADING_HOUSE_GAMEPAD
gpc.invGuildStoreSell_GP        = GAMEPAD_TRADING_HOUSE_SELL --Attention: is nil until gamepad mode enabled and trading house sell opened :-(
gpc.invGuildStoreSellScene_GP   = TRADING_HOUSE_GAMEPAD_SCENE
local invGuildStoreSellScene_GP = gpc.invGuildStoreSellScene_GP


--[Mail]
gpc.invMailSendScene_GP         = getScene(SM, "mailManagerGamepad")
gpc.invMailSend_GP              = MAIL_MANAGER_GAMEPAD
gpc.invMailSendFragment_GP 		= GAMEPAD_MAIL_SEND_FRAGMENT


--[Player 2 player trade]
gpc.invPlayerTradeScene_GP      = getScene(SM, "gamepadTrade")
gpc.invPlayerTrade_GP           = GAMEPAD_TRADE
gpc.invPlayerTradeFragment_GP   = GAMEPAD_TRADE_FRAGMENT
local invPlayerTradeFragment_GP = gpc.invPlayerTradeFragment_GP


--[Companion]
gpc.companionEquipment_GP       = COMPANION_EQUIPMENT_GAMEPAD
local companionEquipment_GP 	= gpc.companionEquipment_GP
gpc.companionEquipmentScene_GP	= COMPANION_EQUIPMENT_GAMEPAD_SCENE
gpc.companionEquipmentFragment_GP = COMPANION_EQUIPMENT_GAMEPAD_FRAGMENT
local companionEquipmentFragment_GP = gpc.companionEquipmentFragment_GP
gpc.companionCharacterCtrl_GP   = ZO_Companion_Gamepad_TopLevel		--TODO is this the correct for gamepad mode of companion character?


--[Crafting]
gpc.smithing_GP                 = SMITHING_GAMEPAD
local smithing_GP               = gpc.smithing_GP

--Refinement
gpc.refinementPanel_GP          = smithing_GP.refinementPanel
local refinementPanel_GP 		= gpc.refinementPanel_GP
gpc.refinementScene_GP			= getScene(SM, "gamepad_smithing_refine")
local refinementScene_GP 		= gpc.refinementScene_GP

--Create
gpc.creationPanel_GP            = smithing_GP.creationPanel
--local creationPanel_GP 			= gpc.creationPanel_GP
gpc.creationScene_GP			= getScene(SM, "gamepad_smithing_creation")
local creationScene_GP 			= gpc.creationScene_GP

--Deconstruction
gpc.deconstructionPanel_GP      = smithing_GP.deconstructionPanel
local deconstructionPanel_GP 	= gpc.deconstructionPanel_GP
gpc.deconstructionScene_GP		= getScene(SM, "gamepad_smithing_deconstruct")
local deconstructionScene_GP 	= gpc.deconstructionScene_GP

--Improvement
gpc.improvementPanel_GP         = smithing_GP.improvementPanel
local improvementPanel_GP 		= gpc.improvementPanel_GP
gpc.improvementScene_GP         = getScene(SM, "gamepad_smithing_improvement")
local improvementScene_GP 		= gpc.improvementScene_GP

--Research
gpc.researchPanel_GP            = smithing_GP.researchPanel
local researchPanel_GP 			= gpc.researchPanel_GP
gpc.researchScene_GP            = getScene(SM, "gamepad_smithing_research")
local researchScene_GP 			= gpc.researchScene_GP
gpc.researchChooseItemDialog_GP = getScene(SM, "gamepad_smithing_research_confirm") --GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE
local researchChooseItemDialog_GP = gpc.researchChooseItemDialog_GP

--Enchanting
gpc.enchanting_GP               = GAMEPAD_ENCHANTING
local enchanting_GP 			= gpc.enchanting_GP
gpc.enchantingCreateScene_GP    = getScene(SM, "gamepad_enchanting_creation") --GAMEPAD_ENCHANTING_CREATION_SCENE
local enchantingCreateScene_GP  = gpc.enchantingCreateScene_GP
gpc.enchantingExtractScene_GP   = getScene(SM, "gamepad_enchanting_extraction") --GAMEPAD_ENCHANTING_EXTRACTION_SCENE
local enchantingExtractScene_GP = gpc.enchantingExtractScene_GP
gpc.enchantingInvCtrls_GP       = {
	[ENCHANTING_MODE_CREATION] 		= 	enchantingCreateScene_GP,
	[ENCHANTING_MODE_EXTRACTION] 	= 	enchantingExtractScene_GP,
	[ENCHANTING_MODE_RECIPES] 		= 	nil, --recipesgot no own scene, maybe a fragment?
}

--Alchemy
gpc.alchemy_GP                  = GAMEPAD_ALCHEMY
local alchemy_GP 				= gpc.alchemy_GP
gpc.alchemyCreationSecene_GP    = getScene(SM, "gamepad_alchemy_creation")
local alchemyCreationSecene_GP  = gpc.alchemyCreationSecene_GP
gpc.alchemyCtrl_GP              = gpc.alchemy_GP.control

--Retrait
gpc.retrait_GP                  = ZO_RETRAIT_STATION_RETRAIT_GAMEPAD
gpc.retraitScene_GP				= getScene(SM, "retrait_gamepad")
gpc.retraitFragment_GP			= GAMEPAD_RETRAIT_FRAGMENT
local retraitFragment_GP 		= gpc.retraitFragment_GP

--Reconstruction
gpc.reconstruct_GP              = ZO_RETRAIT_STATION_RECONSTRUCT_GAMEPAD
gpc.reconstructScene_GP			= getScene(SM, "reconstruct_gamepad")
gpc.reconstructFragment_GP		= GAMEPAD_RECONSTRUCT_FRAGMENT

--Provisioning
gpc.provisioner_GP			     = GAMEPAD_PROVISIONER
local provisioner_GP 			 = gpc.provisioner_GP
gpc.provisionerScene_GP			 = getScene(SM, "gamepad_provisioner_root")
local provisionerScene_GP 		 = gpc.provisionerScene_GP
gpc.provisionerFragment_GP		 = GAMEPAD_PROVISIONER_FRAGMENT
local provisionerFragment_GP 	 = gpc.provisionerFragment_GP

--Universal Deconstruction
local universalDeconstructPanel_GP
gpc.universalDeconstruct_GP  = UNIVERSAL_DECONSTRUCTION_GAMEPAD
gpc.universalDeconstructPanel_GP = gpc.universalDeconstruct_GP.deconstructionPanel
universalDeconstructPanel_GP = gpc.universalDeconstructPanel_GP
gpc.universalDeconstructScene_GP = UNIVERSAL_DECONSTRUCTION_GAMEPAD_SCENE

------------------------------------------------------------------------------------------------------------------------
--Custom created fragments -> See file /Gamepad/gamepadCustomFragments.lua
-----------------------------------------------------------------------------------------------------------------------
--They will be nil (see table gamepadConstants.customFragments[LF_*] = {name=..., fragment=nil}) here at the time
--constant.lua is parsed as the custom gamepad fragments were not created yet!
--> The file /Gamepad/gamepadCustomFragments.lua needs some constants for this file first!
---->But they will be added later to the constants table "gamepadConstants", as they were created in file
---->/Gamepad/gamepadCustomFragments.lua table customFragmentsUpdateRef
-->Important: The variables are updated to table libFilters.LF_FilterTypeToReference,
-->which is used for libFilters:HookAdditionalFilters!

--The custom fragment names for the filter panelId in gamepad mode, used in file /Gamepad/gamepadCustomFragments.lua
-->The fragment=nil will be updated from file /Gamepad/GamepadCustomFragments.lua later on
-->Their name will get a prefix at creation! See function libFilters.GetCustomLibFiltersFragmentName, and variable
-->gamepadConstants.customFragmentPrefix
gpc.customFragments             = {
	[LF_INVENTORY] 		= 		{name = "BACKPACK_INVENTORY_GAMEPAD_FRAGMENT", 			fragment=nil},
	[LF_BANK_DEPOSIT] 	= 		{name = "BACKPACK_BANK_DEPOSIT_GAMEPAD_FRAGMENT", 		fragment=nil},
	[LF_HOUSE_BANK_DEPOSIT] = 	{name = "BACKPACK_HOUSE_BANK_DEPOSIT_GAMEPAD_FRAGMENT",	fragment=nil},
	[LF_GUILDBANK_DEPOSIT] = 	{name = "BACKPACK_GUILD_BANK_DEPOSIT_GAMEPAD_FRAGMENT", fragment=nil},
	[LF_GUILDSTORE_SELL] = 		{name = "BACKPACK_TRADING_HOUSE_SELL_GAMEPAD_FRAGMENT", fragment=nil},
	[LF_MAIL_SEND] = 			{name = "BACKPACK_MAIL_SEND_GAMEPAD_FRAGMENT", 			fragment=nil},
	[LF_TRADE] = 				{name = "BACKPACK_PLAYER_TRADE_GAMEPAD_FRAGMENT", 		fragment=nil},
	[LF_INVENTORY_QUEST] =		{name = "BACKPACK_INVENTORY_QUEST_GAMEPAD_FRAGMENT", 	fragment=nil},
}


------------------------------------------------------------------------------------------------------------------------
--Fix for .additionalFilter attribute at some panels, e.g. LF_CRAFTBAG
-----------------------------------------------------------------------------------------------------------------------
--Other attributes at an inventory/layoutData table where ZOs or other addons could have already added filter functions to
--> See LibFilters-3.0.lua, function HookAdditionalFilters
-->Example is: .additionalCraftBagFilter at the CraftBag as PLAYER_INVENTRY:ApplyBackpackLayout will always overwrite
-->PLAYER_INVENTORY.appliedLayout.additionalFilter. Since ESOUI v7.0.5 the filterFunctions overwriting the CraftBag will
-->be read from the attribute layoutData.additionalCraftBagFilter
-->So we need to write the LibFilters filterFunctions of LF_CRAFTBAG to exactly this attribute
local otherOriginalFilterAttributesAtLayoutData_Table = {
	--Keyboard mode
	[false] = {
		[LF_CRAFTBAG] = {
			--In function libFilters:HookAdditionalFilter()
			--Read from this attribute of the provided filterReference object
			["attributeRead"] 	= "additionalCraftBagFilter",
			--Read the attributeRead above from this object to obtain the existing filter functions. If not provided the
			--attribute wil be read from the same filterReference object used at libFilters:HookAdditionalFilter
			--e.g. the layoutData used in function PLAYER_INVENTORY:ApplyBackpackLayout(layoutData)
			--After it was read and enhanced with LibFilters runFilters(filterType) call it will be re-written to
			--objectRead["attributeRead"] again
			["objectRead"] 		= kbc.invBackpackFragment.layoutData, --BACKPACK_MENU_BAR_LAYOUT_FRAGMENT
		}
	},
	--Gamepad mode -- 2021-12-11 no fixes needed yet
	[true] = {
		--[[
		[LF_CRAFTABG] = {
		}
		]]
	},
}
constants.otherAttributesToGetOriginalFilterFunctions = otherOriginalFilterAttributesAtLayoutData_Table


------------------------------------------------------------------------------------------------------------------------
--Gamepad dynamic "INVENTORY" update functions
------------------------------------------------------------------------------------------------------------------------
--Will be filled in file LibFilters-3.0.lua, see "--Update functions for the gamepad inventory"
gpc.InventoryUpdateFunctions    = {}


------------------------------------------------------------------------------------------------------------------------
--MAPPING
------------------------------------------------------------------------------------------------------------------------
libFilters.mapping = {}
local mapping = libFilters.mapping

--[Mapping for bagId to inventory types]
mapping.bagIdToInventory = {
	[BAG_BACKPACK]			= inventories[INVENTORY_BACKPACK],
	[BAG_BANK]				= inventories[INVENTORY_BANK],
	[BAG_SUBSCRIBER_BANK]	= inventories[INVENTORY_BANK],
	[BAG_VIRTUAL]			= inventories[INVENTORY_CRAFT_BAG],
	[BAG_GUILDBANK]			= inventories[INVENTORY_GUILD_BANK],
	[BAG_HOUSE_BANK_ONE]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_TWO]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_THREE]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_FOUR]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_FIVE]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_SIX]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_SEVEN]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_EIGHT]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_NINE]	= inventories[INVENTORY_HOUSE_BANK],
	[BAG_HOUSE_BANK_TEN]	= inventories[INVENTORY_HOUSE_BANK],
}

--[Mapping for filter type to filter function type: inventorySlot or crafting with bagId, slotIndex]
--Constants of the possible filter function types of LibFilters
constants.LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT = 1
local LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT = constants.LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT
constants.LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX = 2
local LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX = constants.LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX

mapping.filterTypeToFilterFunctionType = {}
local filterTypeToFilterFunctionType = mapping.filterTypeToFilterFunctionType
--The following filterTypes use bagId and slotIndex
local filterTypesUsingBagIdAndSlotIndexFilterFunction = {
	[LF_SMITHING_REFINE]			= true,
	[LF_SMITHING_DECONSTRUCT]     	= true,
	[LF_SMITHING_IMPROVEMENT]     	= true,
	[LF_SMITHING_RESEARCH]        	= true,
	[LF_SMITHING_RESEARCH_DIALOG] 	= true,
	[LF_JEWELRY_REFINE]           	= true,
	[LF_JEWELRY_DECONSTRUCT]     	= true,
	[LF_JEWELRY_IMPROVEMENT]      	= true,
	[LF_JEWELRY_RESEARCH]         	= true,
	[LF_JEWELRY_RESEARCH_DIALOG]  	= true,
	[LF_ENCHANTING_CREATION]      	= true,
	[LF_ENCHANTING_EXTRACTION]    	= true,
	[LF_RETRAIT]                  	= true,
	[LF_ALCHEMY_CREATION]         	= true,
}
mapping.filterTypesUsingBagIdAndSlotIndexFilterFunction = filterTypesUsingBagIdAndSlotIndexFilterFunction
--Add them to the table mapping.filterTypeToFilterFunctionType
for filterTypeValue, _  in pairs(filterTypesUsingBagIdAndSlotIndexFilterFunction) do
	filterTypeToFilterFunctionType[filterTypeValue] = LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX
end
--Now add all other missing filterTypes which were not added yet, with the constant LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT
mapping.filterTypesUsingInventorySlotFilterFunction = {}
for filterTypeValue, _  in pairs(libFiltersFilterConstants) do
	if filterTypeToFilterFunctionType[filterTypeValue] == nil then
		filterTypeToFilterFunctionType[filterTypeValue] = LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT
		mapping.filterTypesUsingInventorySlotFilterFunction[filterTypeValue] = true
	end
end

--[Mapping for panelIdentifier to filterTypes]
--e.g. the allowed filterTypes at the "bank" panel = withdraw and deposit
-- The allowed filterTypes are determiend via the menu buttons given to switch between the filterTypes, e.g.
-- smithing = refine, create, deconstruct, improve, research and researchDialog
-->Unsupported menu buttons like "recipes at the crafting tables, except directly at provisioner" will not be listed!
local validFilterTypesOfPanel = {
	["alchemy"] = {
		[LF_ALCHEMY_CREATION] = true,
	},
	["bank"]	= {
		[LF_BANK_WITHDRAW] = true,
		[LF_BANK_DEPOSIT] = true,
	},
	["companionInventory"]	= {
		[LF_INVENTORY_COMPANION] = true
	},
	["enchanting"] = {
		[LF_ENCHANTING_CREATION] = true,
		[LF_ENCHANTING_EXTRACTION] = true,
	},
	["fence"] = {
		[LF_FENCE_SELL] = true,
		[LF_FENCE_LAUNDER] = true,
	},
	["guildBank"]	= {
		[LF_GUILDBANK_WITHDRAW] = true,
		[LF_GUILDBANK_DEPOSIT] = true,
	},
	["guildStore"] = {
		[LF_GUILDSTORE_BROWSE] = true,
		[LF_GUILDSTORE_SELL] = true,
	},
	["houseBank"] = {
		[LF_HOUSE_BANK_WITHDRAW] = true,
		[LF_HOUSE_BANK_DEPOSIT] = true,
	},
	["inventory"]	= {
		[LF_INVENTORY] = true,
		[LF_CRAFTBAG] = true,
		[LF_INVENTORY_QUEST] = true,
		[LF_QUICKSLOT] = true,
	},
	["jewelryCrafting"]	= {
		[LF_JEWELRY_REFINE] = true,
		[LF_JEWELRY_CREATION] = true,
		[LF_JEWELRY_DECONSTRUCT] = true,
		[LF_JEWELRY_IMPROVEMENT] = true,
		[LF_SMITHING_RESEARCH] = true,
		[LF_JEWELRY_RESEARCH_DIALOG] = true,
	},
	["mail"] = {
		[LF_MAIL_SEND] = true,
	},
	["trade"] = {
		[LF_TRADE] = true,
	},
	["provisioning"] = {
		[LF_PROVISIONING_COOK] = true,
		[LF_PROVISIONING_BREW] = true,
	},
	["retrait"] = {
		[LF_RETRAIT] = true,
	},
	["smithing"] = {
		[LF_SMITHING_REFINE] = true,
		[LF_SMITHING_CREATION] = true,
		[LF_SMITHING_DECONSTRUCT] = true,
		[LF_SMITHING_IMPROVEMENT] = true,
		[LF_SMITHING_RESEARCH] = true,
		[LF_SMITHING_RESEARCH_DIALOG] = true,
	},
	["vendor"] = {
		[LF_VENDOR_BUY] = true,
		[LF_VENDOR_SELL] = true,
		[LF_VENDOR_BUYBACK] = true,
		[LF_VENDOR_REPAIR] = true,
		[LF_SMITHING_RESEARCH] = true,
		[LF_SMITHING_RESEARCH_DIALOG] = true,
	},
}
mapping.validFilterTypesOfPanel = validFilterTypesOfPanel

--The mapping between craftingType and the shown crafting panelIdentifier
local craftingTypeToPanelId = {
	[CRAFTING_TYPE_ALCHEMY] 		= "alchemy",
	[CRAFTING_TYPE_CLOTHIER] 		= "smithing",
	[CRAFTING_TYPE_ENCHANTING] 		= "enchanting",
	[CRAFTING_TYPE_JEWELRYCRAFTING] = "jewelryCrafting",
	[CRAFTING_TYPE_PROVISIONING] 	= "provisioning",
	[CRAFTING_TYPE_BLACKSMITHING] 	= "smithing",
	[CRAFTING_TYPE_WOODWORKING] 	= "smithing",
}
mapping.craftingTypeToPanelId = craftingTypeToPanelId


--[Mapping for dialogs]
--The dialogs which are given at a filterType, e.g. smithing research keyboard mode
local researchPanelControl = researchPanel.control
local filterTypeToDialogOwnerControl = {
	[CRAFTING_TYPE_BLACKSMITHING] = {
		[LF_SMITHING_RESEARCH_DIALOG] =	researchPanelControl,
	},
	[CRAFTING_TYPE_CLOTHIER] = {
		[LF_SMITHING_RESEARCH_DIALOG] =	researchPanelControl,
	},
	[CRAFTING_TYPE_JEWELRYCRAFTING] = {
		[LF_JEWELRY_RESEARCH_DIALOG] =	researchPanelControl,
	},
	[CRAFTING_TYPE_WOODWORKING] = {
		[LF_SMITHING_RESEARCH_DIALOG] =	researchPanelControl,
	},
}
mapping.LF_FilterTypeToDialogOwnerControl = filterTypeToDialogOwnerControl


--[Mapping for crafting]
--Enchaning (used to determine the correct LF_* filterType constant at enchanting tables, as they share the same inventory
--ENCHANTING.inventory. Gamepad mode uses different scenes for enchating creation and extraction so there are used
--callbacks to these scenes' state to se the appropriate LF_ENCHANTING_* constant
-->Used in function LibFilters:HookAdditionalFilterSpecial(specialType, inventory) and special callbacks
local enchantingModeToFilterType = {
	[ENCHANTING_MODE_NONE] 			= nil,
	[ENCHANTING_MODE_CREATION]		= LF_ENCHANTING_CREATION,
	[ENCHANTING_MODE_EXTRACTION]	= LF_ENCHANTING_EXTRACTION,
	[ENCHANTING_MODE_RECIPES]		= nil --not supported
}
mapping.enchantingModeToFilterType = enchantingModeToFilterType

local provisionerIngredientTypeToFilterType = {
	[PROVISIONER_SPECIAL_INGREDIENT_TYPE_NONE] 			= nil,
	[PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES]		= LF_PROVISIONING_COOK,
	[PROVISIONER_SPECIAL_INGREDIENT_TYPE_FLAVORING]		= LF_PROVISIONING_BREW,
	[PROVISIONER_SPECIAL_INGREDIENT_TYPE_FURNISHING]	= nil --not supported
}
mapping.provisionerIngredientTypeToFilterType = provisionerIngredientTypeToFilterType

local alchemyModeToFilterType = {
	[ZO_ALCHEMY_MODE_NONE] 			= nil,
	[ZO_ALCHEMY_MODE_CREATION]		= LF_ALCHEMY_CREATION,
	[ZO_ALCHEMY_MODE_RECIPES]		= nil, -- not supported
}
mapping.alchemyModeToFilterType = alchemyModeToFilterType

--Mapping for the smithing panels, and their filterTypes
mapping.smithingMapping = {
		[SMITHING_MODE_REFINEMENT] = {
			filterType 			= LF_SMITHING_REFINE,
			filterTypeJewelry 	= LF_JEWELRY_REFINE,
			ctrl 				= refinementPanel.control,
		},
		[SMITHING_MODE_CREATION] = {
			filterType 			= LF_SMITHING_CREATION,
			filterTypeJewelry 	= LF_JEWELRY_CREATION,
			ctrl 				= creationPanel.control,
		},
		[SMITHING_MODE_DECONSTRUCTION] = {
			filterType 			= LF_SMITHING_DECONSTRUCT,
			filterTypeJewelry 	= LF_JEWELRY_DECONSTRUCT,
			ctrl 				= deconstructionPanel.control,
		},
		[SMITHING_MODE_IMPROVEMENT] = {
			filterType 			= LF_SMITHING_IMPROVEMENT,
			filterTypeJewelry 	= LF_JEWELRY_IMPROVEMENT,
			ctrl 				= improvementPanel.control,
		},
		[SMITHING_MODE_RESEARCH] = {
			filterType 			= LF_SMITHING_RESEARCH,
			filterTypeJewelry 	= LF_JEWELRY_RESEARCH,
			ctrl 				= researchPanelControl,
		},
	}

--Mapping for the crafting related filterTypes
local isCraftingFilterType = {
	[LF_SMITHING_REFINE] = true,
	[LF_JEWELRY_REFINE] = true,
	[LF_SMITHING_CREATION] = true,
	[LF_JEWELRY_CREATION] = true,
	[LF_SMITHING_DECONSTRUCT] = true,
	[LF_JEWELRY_DECONSTRUCT] = true,
	[LF_SMITHING_IMPROVEMENT] = true,
	[LF_JEWELRY_IMPROVEMENT] = true,
	[LF_SMITHING_RESEARCH] = true,
	[LF_JEWELRY_RESEARCH] = true,
	[LF_SMITHING_RESEARCH_DIALOG] = true,
	[LF_JEWELRY_RESEARCH_DIALOG] = true,
	[LF_ALCHEMY_CREATION] = true,
	[LF_PROVISIONING_BREW] = true,
	[LF_PROVISIONING_COOK] = true,
	[LF_ENCHANTING_CREATION] = true,
	[LF_ENCHANTING_EXTRACTION] = true,
	--Is this crafting?
	--[LF_RETRAIT] = true,
}
mapping.isCraftingFilterType = isCraftingFilterType

--Mapping for the filterType to the normal deconstruction/extraction, or universal deconstruction panels
local filterTypeToUniversalOrNormalDeconAndExtractVars = {
	--KEYBOARD mode---------------------------------------
	[false] = {
		[LF_SMITHING_DECONSTRUCT] = {
			[true] = 	universalDeconstructPanel or deconstructionPanel,
			[false] = 	deconstructionPanel,
		},
		[LF_JEWELRY_DECONSTRUCT] = {
			[true] = 	universalDeconstructPanel or deconstructionPanel,
			[false] = 	deconstructionPanel,
		},
		[LF_ENCHANTING_EXTRACTION] = {
			[true] = 	universalDeconstructPanel or enchanting,
			[false] = 	enchanting,
		}
	},
	--GAMEPAD mode---------------------------------------
	[true] = {
		[LF_SMITHING_DECONSTRUCT] = {
			[true] = 	universalDeconstructPanel_GP or deconstructionPanel_GP,
			[false] = 	deconstructionPanel_GP,
		},
		[LF_JEWELRY_DECONSTRUCT] = {
			[true] = 	universalDeconstructPanel_GP or deconstructionPanel_GP,
			[false] = 	deconstructionPanel_GP,
		},
		[LF_ENCHANTING_EXTRACTION] = {
			[true] = 	universalDeconstructPanel_GP or enchanting_GP,
			[false] = 	enchanting_GP,
		}
	},
}
mapping.filterTypeToUniversalOrNormalDeconAndExtractVars = filterTypeToUniversalOrNormalDeconAndExtractVars

local universalDeconTabKeyToLibFiltersFilterType = {
	["all"] =           LF_SMITHING_DECONSTRUCT,
	["armor"] =         LF_SMITHING_DECONSTRUCT,
	["weapons"] =       LF_SMITHING_DECONSTRUCT,
	["jewelry"] =       LF_JEWELRY_DECONSTRUCT,
	["enchantments"] =  LF_ENCHANTING_EXTRACTION,
}
mapping.universalDeconTabKeyToLibFiltersFilterType = universalDeconTabKeyToLibFiltersFilterType

local universalDeconFilterTypeToFilterBase = {
	[LF_SMITHING_DECONSTRUCT] =     deconstructionPanel,
	[LF_JEWELRY_DECONSTRUCT] =      deconstructionPanel,
	[LF_ENCHANTING_EXTRACTION] =    enchantingExtractScene_GP
}
mapping.universalDeconFilterTypeToFilterBase = universalDeconFilterTypeToFilterBase

local universalDeconLibFiltersFilterTypeSupported = {}
for filterType, _ in pairs(universalDeconFilterTypeToFilterBase) do
	universalDeconLibFiltersFilterTypeSupported[filterType] = true
end
mapping.universalDeconLibFiltersFilterTypeSupported = universalDeconLibFiltersFilterTypeSupported

--[Mapping LibFilters LF* constants not being hooked normal -> Special functions used]
local standardSpecialHookFunc = 		"HookAdditionalFilterSpecial" 		--LibFilters:HookAdditionalFilterSpecial
local standardSceneSpecialHookFunc = 	"HookAdditionalFilterSceneSpecial"	--LibFilters:HookAdditionalFilterSceneSpecial

-->The mapping between the LF_* filterType constant and a LibFilters function name (funcName of _G["LibFilters"])
-->plus the parameters to pass to the function
-->Any entry with LF* in this table will NOT use LibFilters:HookAdditionalFilter below!
-->See mapping table table "filterTypeToReference" below
local LF_ConstantToAdditionalFilterSpecialHook = {
--[[
--DISABLED: but kept as reference for an example.
--LF_ENCHANTING_ will be now added to the gamepad scenes via normal HookAdditionalFilter function
--and used for keyboard and gamepad mode this way via helpers function ZO_Enchanting_DoesEnchantingItemPassFilter
	[LF_ENCHANTING_CREATION] = { --this will also apply the filters for LF_ENCHANTING_EXTRACTION
--		[false] = {funcName = standardSpecialHookFunc, 	params = {"enchanting"}}, --Keyboard mode
--		[true] 	= {funcName = standardSceneSpecialHookFunc, params = {"enchanting_GamePad"}},
	},
	[LF_ENCHANTING_EXTRACTION] = {
		--[false] = {}, --> See LF_ENCHANTING_CREATION above!
		--[true] = {}, --> See LF_ENCHANTING_CREATION above!
	},
	]]
}
mapping.LF_ConstantToAdditionalFilterSpecialHook = LF_ConstantToAdditionalFilterSpecialHook

--[Mapping GamePad/Keyboard control/scene/fragment/userdate/etc. .additionalFilter entry to the LF_* constant]
-->This table contains the mapping between GamePad and Keyboard mode, and the LibFilters constant LF_* to
-->the control/scene/fragment/userdata/inventory to use to store the .additionalFilter function to.
-->The controls/... can be many. Each entry in the value table will be applying .additionalFilter
-->Used in function LibFilters:HookAdditionalFilter(filterType_LF_Constant)
--
--> This table's gamepad entries of some custom created fragments (no vanilla code fragments, but custom created by
--> LibFilters to "kind of replicate" the keyboard fragments used at inventories to distinguish player inventory, mail,
--> trade, bank deposit, etc.) will be updated via file /Gamepad/gamepadCustomFragments.lua,
--
--> Attention: Entries in helper.lua which relate to "KEYBOARD and GAMEPAD - shared helpers" will not hook both, keyboard
-->  and gamepad mode! There will only be one hook then in this table, for keyboard OR gamepad mode! e.g.
--> LF_ENCHANTING_CREATION and _EXTRACTION use the gamepad scenes in helpers.lua -> ZO_Enchanting_DoesEnchantingItemPassFilter.
--> So the hook will be in the [true] subtable for gamepad mode!
--> LF_SMITHING_RESEARCH_DIALOG and LF_JEWELRY_RESEARCH_DIALOG use the keyboard control SMITHING_RESEARCH_SELECT in helpers.lua
--> ZO_SharedSmithingResearch.IsResearchableItem. So the hook will be in the [false] subtable for keyboard mode!
local filterTypeToReference = {
	--Keyboard mode
	[false] = {
		--2 entries here because ZO_InventoryManager:ApplyBackpackLayout(layoutData) changes
		--PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK].additionalFilter from layoutData.additionalFilter, where layoutData could be
		--from fragment BACKPACK_MENU_BAR_LAYOUT_FRAGMENT or others, each time and thus we need to hook both
		[LF_INVENTORY]                = { kbc.invBackpackFragment, invBackpack },
		--PLAYER_INVENTORY.inventories[INVENTORY_CRAFT_BAG].additionalFilter gets updated each time from layoutData.additionalCraftBagFilter
		--as ZO_InventoryManager:ApplyBackpackLayout(layoutData) is called.
		--Attention: As LF_INVENTORY and LF_CRAFTBAG both get hooked via fragment BACKPACK_MENU_BAR_LAYOUT_FRAGMENT it needs to be applied a
		--fix at ZO_InventoryManager:ApplyBackpackLayout in order to update layoutData.LibFilters3_filterType with the correct filterType
		--LF_INVENTORY or LF_CRAFTBAG! See file LibFilters-3.0.lua, fucntion ApplyFixesEarly() -> SecurePostHook(playerInv, "ApplyBackpackLayout", function(layoutData)
		--Else the last hooked one (LF_CRAFTBAG) will be kept as layoutData.LibFilters3_filterType all the time and filtering at other addons wont
		--work properly!
		[LF_CRAFTBAG]                 = { invCraftbag }, --, kbc.invBackpackFragment

		[LF_INVENTORY_QUEST]          = { invQuests },
		[LF_QUICKSLOT]                = { quickslots },
		[LF_INVENTORY_COMPANION]      = { companionEquipment },

		[LF_BANK_WITHDRAW]            = { invBankWithdraw },
		[LF_BANK_DEPOSIT]             = { invBankDeposit },
		[LF_GUILDBANK_WITHDRAW]       = { invGuildBankWithdraw },
		[LF_GUILDBANK_DEPOSIT]        = { invGuildBankDeposit },
		[LF_HOUSE_BANK_WITHDRAW]      = { invHouseBankWithdraw },
		[LF_HOUSE_BANK_DEPOSIT]       = { invHouseBankDeposit },

		[LF_VENDOR_BUY]               = { store },
		[LF_VENDOR_SELL]              = { vendorSell },
		[LF_VENDOR_BUYBACK]           = { vendorBuyBack },
		[LF_VENDOR_REPAIR]            = { vendorRepair },
		[LF_FENCE_SELL]               = { invFenceSellFragment },
		[LF_FENCE_LAUNDER]            = { invFenceLaunderFragment },

		[LF_GUILDSTORE_SELL]          = { guildStoreSellLayoutFragment },

		[LF_MAIL_SEND]                = { mailSendFragment },
		[LF_TRADE]                    = { player2playerTradeFragment },

		[LF_SMITHING_RESEARCH_DIALOG] = { researchChooseItemDialog },
		[LF_JEWELRY_RESEARCH_DIALOG]  = { researchChooseItemDialog },


		--Shared with gamepad mode -> See entry with LF_* at [true] (using gamepadConstants) below
		[LF_SMITHING_REFINE]          = { refinementPanel },
		[LF_SMITHING_DECONSTRUCT]     = { deconstructionPanel },
		[LF_SMITHING_IMPROVEMENT]     = { improvementPanel },
		[LF_SMITHING_RESEARCH]        = { researchPanel },
		[LF_JEWELRY_REFINE]           = { refinementPanel },
		[LF_JEWELRY_DECONSTRUCT]      = { deconstructionPanel },
		[LF_JEWELRY_IMPROVEMENT]      = { improvementPanel },
		[LF_JEWELRY_RESEARCH]         = { researchPanel },
		[LF_ALCHEMY_CREATION]         = { alchemyScene },
		[LF_RETRAIT]                  = { retrait },


		--Special entries, see table LF_ConstantToAdditionalFilterSpecialHook above!
		-->Currently disalbed as the Gamepad mode Scenes for enchatning create/extract are used to store the filters in
		-->.additionalFilter and the helper function ZO_Enchanting_DoesEnchantingItemPassFilter will be used to read the
		-->scenes for both, keyboard AND gamepad mode
		[LF_ENCHANTING_CREATION]	  = {},	--implemented special, leave empty (not NIL!) to prevent error messages
		[LF_ENCHANTING_EXTRACTION]    = {},	--implemented special, leave empty (not NIL!) to prevent error messages


		--Not implemented yet
		[LF_GUILDSTORE_BROWSE] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_COOK]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_BREW]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
	},

--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

	--Gamepad mode
	[true]  = {
		[LF_INVENTORY_COMPANION]      = { companionEquipment_GP },

		[LF_VENDOR_BUY]               = { gpc.vendorBuy_GP },
		[LF_VENDOR_SELL]              = { gpc.vendorSell_GP },
		[LF_VENDOR_BUYBACK]           = { gpc.vendorBuyBack_GP },
		[LF_VENDOR_REPAIR]            = { gpc.vendorRepair_GP },
		[LF_FENCE_SELL]               = { gpc.invFenceSell_GP },
		[LF_FENCE_LAUNDER]            = { gpc.invFenceLaunder_GP },

		[LF_SMITHING_RESEARCH_DIALOG] = { researchChooseItemDialog_GP },
		[LF_JEWELRY_RESEARCH_DIALOG]  = { researchChooseItemDialog_GP }, --duplicate needed compared to LF_SMITHING_RESEARCH_DIALOG ?


		--Not given in gamepad mode
		[LF_QUICKSLOT]                = { quickslotFragment_GP }, --not in gamepad mode -> quickslots are added directly from type lists. collections>mementos, collections>mounts, inventory>consumables, ... / We will just add the fragment here where the .additionalFilter function should be stored, maybe for future implementations


		--Updated with correct fragment in file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_INVENTORY]                = {}, --custom created gamepad fragment gamepadLibFiltersInventoryFragment
		[LF_BANK_DEPOSIT]             = {}, --custom created gamepad fragment gamepadLibFiltersBankDepositFragment
		[LF_GUILDBANK_DEPOSIT]        = {}, --custom created gamepad fragment gamepadLibFiltersGuildBankDepositFragment
		[LF_HOUSE_BANK_DEPOSIT]       = {}, --custom created gamepad fragment gamepadLibFiltersHouseBankDepositFragment
		[LF_GUILDSTORE_SELL]          = {}, --custom created gamepad fragment gamepadLibFiltersGuildStoreSellFragment
		[LF_MAIL_SEND]                = {}, --custom created gamepad fragment gamepadLibFiltersMailSendFragment
		[LF_TRADE]                    = {}, --custom created gamepad fragment gamepadLibFiltersPlayerTradeFragment
		[LF_INVENTORY_QUEST]          = {}, --custom created gamepad fragment gamepadLibFiltersInventoryQuestFragment


		--Shared with keyboard mode -> See entry with LF_* at [false] (using keyboardConstants) above
		-->Will ONLY be hooked in keyboard mode call (HookAdditioalFilter will be called with keyboard AND gamepad mode
		-->once as this library is loaded. Calling libFilters:HookAdditinalFilter() later on checks for the current gamepad
		--> or keyboard mode, and only hooks the currently active one -> Which will fail to load these ones here later on,
		--> as they need to be loaded via the keyboard hooks!).
		[LF_CRAFTBAG]                 = {}, --implemented in keyboard mode (see above at [false]), leave empty (not NIL!) to prevent error messages --todo: test if this works, or add "gamepadConstants.invCraftbag_GP" again above!
		[LF_BANK_WITHDRAW]            = {},	--implemented in keyboard mode (see above at [false]), leave empty (not NIL!) to prevent error messages
		[LF_GUILDBANK_WITHDRAW]       = {}, --implemented in keyboard mode (see above at [false]), leave empty (not NIL!) to prevent error messages
		[LF_HOUSE_BANK_WITHDRAW]      = {}, --implemented in keyboard mode (see above at [false]), leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_REFINE]          = {}, --implemented in keyboard mode (see above at [false]), leave empty (not NIL!) to prevent error messages --todo: test if this works, or add "gamepadConstants.refinementPanel_GP" again above!
		[LF_SMITHING_DECONSTRUCT]     = {}, --implemented in keyboard mode (see above at [false]), leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_IMPROVEMENT]     = {}, --implemented in keyboard mode (see above at [false]), leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_RESEARCH]        = {}, --implemented in keyboard mode (see above at [false]), leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_REFINE]           = {}, --implemented in keyboard mode (see above at [false]), leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_DECONSTRUCT]      = {}, --implemented in keyboard mode (see above at [false]), leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_IMPROVEMENT]      = {}, --implemented in keyboard mode (see above at [false]), leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_RESEARCH]         = {}, --implemented in keyboard mode (see above at [false]), leave empty (not NIL!) to prevent error messages
		[LF_ALCHEMY_CREATION]         = {}, --implemented in keyboard mode (see above at [false]), leave empty (not NIL!) to prevent error messages
		[LF_RETRAIT]                  = {}, --implemented in keyboard mode (see above at [false]), leave empty (not NIL!) to prevent error messages


		--Normally these are special hooks in table LF_ConstantToAdditionalFilterSpecialHook.
		--But currently they are changed to be normal entries using HookAdditionalFilter for now, to hook the scenes
		--and add .additionalFilter, used in helpers ZO_Enchanting_DoesEnchantingItemPassFilter
		-->Used for gamepad AND keyboard mode with these entries here !!!
		[LF_ENCHANTING_CREATION]	  = { enchantingCreateScene_GP },
		[LF_ENCHANTING_EXTRACTION]    = { enchantingExtractScene_GP },


		--Not implemented yet
		[LF_GUILDSTORE_BROWSE] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_COOK]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_BREW]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
	},
}
mapping.LF_FilterTypeToReference = filterTypeToReference

--FilterTypes that do not return a reference variable above at "filterTypeToReference" directly as they are implemented special,
--will return these variables here
local filterTypesToReferenceImplementedSpecial = {
	--KEYBOARD
	[false] = {
		[LF_ENCHANTING_CREATION]   = { enchanting },
		[LF_ENCHANTING_EXTRACTION] = { enchanting },
	},
	--GAMEPAD
	[true] = {

	},
}
mapping.LF_FilterTypesToReferenceImplementedSpecial = filterTypesToReferenceImplementedSpecial

--The following filterTypes fallback to keyboard reference variables as gamepad re-uses the same
local filterTypesGamepadFallbackToKeyboard = {
		[LF_CRAFTBAG]                 = true,
		[LF_BANK_WITHDRAW]            = true,
		[LF_GUILDBANK_WITHDRAW]       = true,
		[LF_HOUSE_BANK_WITHDRAW]      = true,
		[LF_SMITHING_REFINE]          = true,
		[LF_SMITHING_DECONSTRUCT]     = true,
		[LF_SMITHING_IMPROVEMENT]     = true,
		[LF_SMITHING_RESEARCH]        = true,
		[LF_JEWELRY_REFINE]           = true,
		[LF_JEWELRY_DECONSTRUCT]      = true,
		[LF_JEWELRY_IMPROVEMENT]      = true,
		[LF_JEWELRY_RESEARCH]         = true,
		[LF_ALCHEMY_CREATION]         = true,
		[LF_RETRAIT]                  = true,
}
mapping.LF_FilterTypeToReferenceGamepadFallbackToKeyboard = filterTypesGamepadFallbackToKeyboard


--The mapping table containing the "lookup" data of control or scene/fragment to us for "is hidden" checks
--The control must be a control with IsHidden() function or a .control subtable with that function
--The scene needs to be a scene name or scene variable with the .state attribute
--The fragment needs to be a fragment name or fragment variable with the .state and .sceneManager attributes
--Special entries can be added for dynamically done checks -> See LibFilters-3.0.lua, function isSpecialTrue(filterType, isInGamepadMode, false)
--[[
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
--SpecialForced entries can be added for dynamically done checks -> See LibFilters-3.0.lua, function isSpecialTrue(filterType, isInGamepadMode, true)
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
filterTypeToCheckIfReferenceIsHidden = {
--Keyboard mode
	[false] = {
		--Works: 2021-12-13
		[LF_INVENTORY]                = { ["control"] = invBackpack, 					["scene"] = "inventory", 			["fragment"] = inventoryFragment },
		[LF_INVENTORY_QUEST]          = { ["control"] = invQuests, 						["scene"] = "inventory",			["fragment"] = invQuestFragment, },
		--Works: 2021-12-13
		[LF_CRAFTBAG]                 = { ["control"] = invCraftbag, 					["scene"] = nil, 					["fragment"] = craftBagFragment,
										  --Check for CraftBagExtended addon and change the detected CraftBag panel to any other supported, e.g.
										  --MailSend, Trade, GuildStoreSell, Bank deposit, guild bank deposit, house bank deposit
										  ["specialForced"] = {
											  [1] = {
												  ["control"]         = _G[GlobalLibName],
												  ["funcOrAttribute"] = "IsCraftBagShown",
												  ["params"]          = { _G[GlobalLibName] },
												  ["expectedResults"] = { true },
											  }
										  },
		},
		--Works: 2021-12-13
		[LF_INVENTORY_COMPANION]      = { ["control"] = companionEquipment, 			["scene"] = "companionCharacterKeyboard", ["fragment"] = companionEquipmentFragment, },
		--Works: 2021-12-13
		[LF_QUICKSLOT]                = { ["control"] = quickslots, 					["scene"] = "inventory",			["fragment"] = quickslotsFragment, },
		--Works: 2021-12-13
		[LF_BANK_WITHDRAW]            = { ["control"] = invBankWithdraw, 				["scene"] = invBankScene, 			["fragment"] = bankWithdrawFragment, },
		--Works: 2021-12-13
		[LF_BANK_DEPOSIT]             = { ["control"] = invBankDeposit, 				["scene"] = invBankScene, 			["fragment"] = inventoryFragment, },
		--Works: 2021-12-13
		[LF_GUILDBANK_WITHDRAW]       = { ["control"] = invGuildBankWithdraw, 			["scene"] = invGuildBankScene,		["fragment"] = guildBankWithdrawFragment, },
		--Works: 2021-12-13
		[LF_GUILDBANK_DEPOSIT]        = { ["control"] = invGuildBankDeposit, 			["scene"] = invGuildBankScene, 		["fragment"] = inventoryFragment, },
		--Works: 2021-12-13
		[LF_HOUSE_BANK_WITHDRAW]      = { ["control"] = invHouseBankWithdraw, 			["scene"] = invHouseBankScene ,		["fragment"] = houseBankWithdrawFragment, },
		--Works: 2021-12-13
		[LF_HOUSE_BANK_DEPOSIT]       = { ["control"] = invHouseBankDeposit, 			["scene"] = invHouseBankScene , 	["fragment"] = inventoryFragment, },
		--Works: 2021-12-13
		[LF_VENDOR_BUY]               = { ["control"] = store, 							["scene"] = "store", 				["fragment"] = vendorBuyFragment, },
		--Works: 2021-12-13
		[LF_VENDOR_SELL]              = { ["control"] = invBackpack, 					["scene"] = "store", 				["fragment"] = inventoryFragment, },
		--Works: 2021-12-13
		[LF_VENDOR_BUYBACK]           = { ["control"] = vendorBuyBack,					["scene"] = "store", 				["fragment"] = vendorBuyBackFragment, },
		--Works: 2021-12-13
		[LF_VENDOR_REPAIR]            = { ["control"] = vendorRepair, 					["scene"] = "store", 				["fragment"] = vendorRepairFragment, },
		--Works: 2021-12-13
		[LF_FENCE_SELL]               = { ["control"] = fence, 							["scene"] = "fence_keyboard",		["fragment"] = invFenceSellFragment, },
		--Works: 2021-12-13
		[LF_FENCE_LAUNDER]            = { ["control"] = fence, 							["scene"] = "fence_keyboard", 		["fragment"] = invFenceLaunderFragment, },
		--Works: 2021-12-13
		[LF_GUILDSTORE_SELL]          = { ["control"] = guildStoreObj, 					["scene"] = "tradinghouse", 		["fragment"] = guildStoreSellFragment, }, -- = inventoryFragment
		--Works: 2021-12-13
		[LF_MAIL_SEND]                = { ["control"] = kbc.mailSendObj, 				["scene"] = "mailSend", 			["fragment"] = mailSendFragment, },
		--Works: 2021-12-13
		[LF_TRADE]                    = { ["control"] = kbc.player2playerTradeObj, 		["scene"] = "trade", 				["fragment"] = player2playerTradeFragment, },
		--Works: 2021-12-13
		[LF_SMITHING_RESEARCH_DIALOG] = { ["controlDialog"] = researchPanelControl,		["scene"] = "smithing", 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {false},
												}
											}
		},
		--Works: 2021-12-13
		[LF_JEWELRY_RESEARCH_DIALOG]  = { ["controlDialog"] = researchPanelControl,		["scene"] = "smithing",	 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		--Works: 2021-12-13
		[LF_SMITHING_REFINE]          = { ["control"] = refinementPanel, 				["scene"] = "smithing", 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {false},
												}
											}
										},
		--Works: 2021-12-13
		[LF_SMITHING_DECONSTRUCT]     = { ["control"] = deconstructionPanel, 			["scene"] = "smithing", 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {false},
												}
											}
		},
		--Works: 2021-12-13
		[LF_SMITHING_IMPROVEMENT]     = { ["control"] = improvementPanel, 				["scene"] = "smithing", 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {false},
												}
											}
		},
		--Works: 2021-12-13
		[LF_SMITHING_RESEARCH]        = { ["control"] = researchPanelControl, 					["scene"] = "smithing", 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {false},
												}
											}
		},
		--Works: 2021-12-13
		[LF_JEWELRY_CREATION] 		  = { ["control"] = creationPanel,					["scene"] = "smithing", 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		--Works: 2021-12-13
		[LF_JEWELRY_REFINE]           = { ["control"] = refinementPanel, 				["scene"] = "smithing", 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		--Works: 2021-12-13
		[LF_JEWELRY_DECONSTRUCT]      = { ["control"] = deconstructionPanel, 			["scene"] = "smithing", 			["fragment"] = nil,
												   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		--Works: 2021-12-13
		[LF_JEWELRY_IMPROVEMENT]      = { ["control"] = improvementPanel, 				["scene"] = "smithing",	 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		--Works: 2021-12-13
		[LF_JEWELRY_RESEARCH]         = { ["control"] = researchPanelControl, 					["scene"] = "smithing", 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		--Works: 2021-12-13
		[LF_ALCHEMY_CREATION]		  = { ["control"] = alchemy, 						["scene"] = alchemyScene, 		["fragment"] = alchemyFragment,
										   ["special"] = {
												[1] = {
													["control"]  =  alchemy,
													["funcOrAttribute"] = "mode",
													["params"] = {},
													["expectedResults"] = {ZO_ALCHEMY_MODE_CREATION},
												}
											}
		},
		--Works: 2021-12-13
		[LF_RETRAIT]                  = { ["control"] = retrait, 						["scene"] = "retrait_keyboard_root",["fragment"] = retraitFragment, },
		--Works: 2021-12-13
		[LF_ENCHANTING_CREATION]	  = { ["control"] = enchanting, 					["scene"] = enchantingScene,		["fragment"] = nil,
										  ["special"] = {
											  [1] = {
												  ["control"]  =  enchanting,
												  ["funcOrAttribute"] = "GetEnchantingMode",
												  ["params"] = {enchanting},
												  ["expectedResults"] = {ENCHANTING_MODE_CREATION},
											  }
										  }
		},
		--Works: 2021-12-13
		[LF_ENCHANTING_EXTRACTION]	  = { ["control"] = enchanting, 					["scene"] = enchantingScene,		["fragment"] = nil,
											["special"] = {
												[1] = {
													["control"]  =  enchanting,
													["funcOrAttribute"] = "GetEnchantingMode",
													["params"] = {enchanting},
													["expectedResults"] = {ENCHANTING_MODE_EXTRACTION},
												}
											}
		},

		--Not implemented yet
		--Works: 2021-12-13
		[LF_GUILDSTORE_BROWSE]        = { ["control"] = guildStoreObj, 					["scene"] = "tradinghouse", 		["fragment"] = guildStoreBrowseFragment, },
		--Works: 2021-12-13
		[LF_SMITHING_CREATION] 		  = { ["control"] = creationPanel,					["scene"] = "smithing", 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {false},
												}
											}
		},
		--Works: 2021-12-13
		[LF_JEWELRY_CREATION] 		  = { ["control"] = creationPanel,					["scene"] = "smithing", 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		--Works: 2021-12-13
		[LF_PROVISIONING_COOK]		  = { ["control"] = provisioner,					["scene"] = "provisioner", 			["fragment"] = provisionerFragment,
										   ["special"] = {
												[1] = {
													["control"]  =  provisioner,
													["funcOrAttribute"] = "filterType",
													["params"] = {},
													["expectedResults"] = {PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES},
												}
											}
		},
		--Works: 2021-12-13
		[LF_PROVISIONING_BREW]		  = { ["control"] = provisioner,					["scene"] = "provisioner", 			["fragment"] = provisionerFragment,
										   ["special"] = {
												[1] = {
													["control"]  =  provisioner,
													["funcOrAttribute"] = "filterType",
													["params"] = {},
													["expectedResults"] = {PROVISIONER_SPECIAL_INGREDIENT_TYPE_FLAVORING},
												}
											}
		},
	},

--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

	--Gamepad mode
	[true]  = {
		--Works, 2021-12-20
		[LF_INVENTORY_QUEST]          = { ["control"] = ZO_GamepadInventoryTopLevel,	["scene"] = invRootScene_GP,		["fragment"] = nil, --custom created gamepad fragment "gamepadLibFiltersInventoryQuestFragment"
										  ["special"] = {
											  [1] = {
												  ["control"]         = invBackpack_GP,
												  ["funcOrAttribute"] = "selectedItemFilterType",
												  ["params"]          = { },
												  ["expectedResults"] = { ITEMFILTERTYPE_QUEST },
											  }
										  }
		},
		--Works, 2022-01-02
		[LF_INVENTORY_COMPANION]      = { ["control"] = companionEquipment_GP, 						["scene"] = gpc.companionEquipmentScene_GP,	["fragment"] = companionEquipmentFragment_GP,
										  ["special"] = {
											  [1] = {
												  ["control"]         = _G[GlobalLibName],
												  ["funcOrAttribute"] = "IsCompanionInventoryShown",
												  ["params"]          = { _G[GlobalLibName] },
												  ["expectedResults"] = { true },
											  }
										  }
		},
		--Works, 2021-12-19
		[LF_VENDOR_BUY]               = { ["control"] = storeComponents[ZO_MODE_STORE_BUY].list,	["scene"] = storeScene_GP,		["fragment"] = storeComponents[ZO_MODE_STORE_BUY].list._fragment,
										  ["special"] = {
											  [1] = {
												  ["control"]         = _G[GlobalLibName],
												  ["funcOrAttribute"] = "IsStoreShown",
												  ["params"]          = { _G[GlobalLibName], ZO_MODE_STORE_BUY },
												  ["expectedResults"] = { true },
												  ["expectedResultsMap"] = { true, nil, nil },
											  }
										  }
		},
		--Works, 2021-12-19
		[LF_VENDOR_SELL]              = { ["control"] = storeComponents[ZO_MODE_STORE_SELL].list, 	["scene"] = storeScene_GP,		["fragment"] = storeComponents[ZO_MODE_STORE_SELL].list._fragment,
										  ["special"] = {
											  [1] = {
												  ["control"]         = _G[GlobalLibName],
												  ["funcOrAttribute"] = "IsStoreShown",
												  ["params"]          = { _G[GlobalLibName], ZO_MODE_STORE_SELL },
												  ["expectedResults"] = { true },
												  ["expectedResultsMap"] = { true, nil, nil },
											  }
										  }
		},
		--Works, 2021-12-19
		[LF_VENDOR_BUYBACK]           = { ["control"] = storeComponents[ZO_MODE_STORE_BUY_BACK].list,	["scene"] = storeScene_GP,	["fragment"] = storeComponents[ZO_MODE_STORE_BUY_BACK].list._fragment,
										  ["special"] = {
											  [1] = {
												  ["control"]         = _G[GlobalLibName],
												  ["funcOrAttribute"] = "IsStoreShown",
												  ["params"]          = { _G[GlobalLibName], ZO_MODE_STORE_BUY_BACK },
												  ["expectedResults"] = { true },
												  ["expectedResultsMap"] = { true, nil, nil },
											  }
										  }
		},
		--Works, 2021-12-19
		[LF_VENDOR_REPAIR]            = { ["control"] = storeComponents[ZO_MODE_STORE_REPAIR].list, 	["scene"] = storeScene_GP,	["fragment"] = storeComponents[ZO_MODE_STORE_REPAIR].list._fragment,
										  ["special"] = {
											  [1] = {
												  ["control"]         = _G[GlobalLibName],
												  ["funcOrAttribute"] = "IsStoreShown",
												  ["params"]          = { _G[GlobalLibName], ZO_MODE_STORE_REPAIR },
												  ["expectedResults"] = { true },
												  ["expectedResultsMap"] = { true, nil, nil },
											  }
										  }
		},
		--Works, 2021-12-19
		[LF_FENCE_SELL]               = { ["control"] = storeComponents[ZO_MODE_STORE_SELL_STOLEN].list, 	["scene"] = storeScene_GP,	["fragment"] = storeComponents[ZO_MODE_STORE_SELL_STOLEN].list._fragment,
										  ["special"] = {
											  [1] = {
												  ["control"]         = _G[GlobalLibName],
												  ["funcOrAttribute"] = "IsStoreShown",
												  ["params"]          = { _G[GlobalLibName], ZO_MODE_STORE_SELL_STOLEN },
												  ["expectedResults"] = { true },
												  ["expectedResultsMap"] = { true, nil, nil },
											  }
										  }
		},
		--Works, 2021-12-19
		[LF_FENCE_LAUNDER]            = { ["control"] = storeComponents[ZO_MODE_STORE_LAUNDER].list, 		["scene"] = storeScene_GP, 	["fragment"] = storeComponents[ZO_MODE_STORE_LAUNDER].list._fragment,
										  ["special"] = {
											  [1] = {
												  ["control"]         = _G[GlobalLibName],
												  ["funcOrAttribute"] = "IsStoreShown",
												  ["params"]          = { _G[GlobalLibName], ZO_MODE_STORE_LAUNDER },
												  ["expectedResults"] = { true },
												  ["expectedResultsMap"] = { true, nil, nil },
											  }
										  }
		},
		--Works, 2021-12-21
		[LF_SMITHING_RESEARCH_DIALOG] = { ["control"] = nil, 							["scene"] = researchChooseItemDialog_GP,	["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {false},
												}
											}
		},
		--Works, 2021-12-21
		[LF_JEWELRY_RESEARCH_DIALOG]  = { ["control"] = nil, 							["scene"] = researchChooseItemDialog_GP,	["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},


		--Not given in gamepad mode
		--Works, 2021-12-21
		[LF_QUICKSLOT]                = { ["control"] = ZO_GamepadQuickslotToplevel, 	["scene"] = gpc.quickslotScene_GP, 		["fragment"] = quickslotFragment_GP,		--uses inventory fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
										  ["special"] = {
											  [1] = {
												  ["control"]         = invBackpack_GP,
												  ["funcOrAttribute"] = "selectedItemFilterType",
												  ["params"]          = { },
												  ["expectedResults"] = { ITEMFILTERTYPE_QUICKSLOT },
											  }
										  }
		},	--not in gamepad mode -> quickslots are added directly from type lists. collections>mementos, collections>mounts, inventory>consumables, ... -- leave empty (not NIL!) to prevent error messages


		--Updated with correct fragment in file /gamepad/gamepadCustomFragments.lua as the fragments are created
		--Works, 2021-12-19
		[LF_INVENTORY]                = { ["control"] = ZO_GamepadInventoryTopLevel,	["scene"] = invRootScene_GP,			["fragment"] = invFragment_GP, --uses GAMEPAD_INVENTORY_FRAGMENT instead of custom gamepadLibFiltersInventoryFragment now for detection as this' shown state get's updated properly after quickslot wheel was closed again
										  ["special"] = {
											  [1] = {
												  ["control"]         = _G[GlobalLibName],
												  ["funcOrAttribute"] = "IsInventoryShown",
												  ["params"]          = { _G[GlobalLibName] },
												  ["expectedResults"] = { true },
												  ["expectedResultsMap"] = { true, nil },
											  }
										  }
		},
		--Works, 2021-12-18
		[LF_BANK_DEPOSIT]             = { ["control"] = ZO_GamepadBankingTopLevelMaskContainerdeposit,		["scene"] = invBankScene_GP,		["fragment"] = nil,  	--uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created. Fragment will be updated as bank lists get initialized
										  ["special"] = {
											  [1] = {
												  ["control"]         = _G[GlobalLibName],
												  ["funcOrAttribute"] = "IsHouseBankShown",
												  ["params"]          = { _G[GlobalLibName] },
												  ["expectedResults"] = { false },
											  }
										  }
		},
		--Works, 2021-12-18
		[LF_GUILDBANK_DEPOSIT]        = { ["control"] = ZO_GuildBankTopLevel_GamepadMaskContainerdeposit, 	["scene"] = invGuildBankScene_GP, 	["fragment"] = nil, }, 	--uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created. Fragment will be updated as guild bank lists get initialized
		--Works, 2021-12-18
		[LF_HOUSE_BANK_DEPOSIT]       = { ["control"] = ZO_GamepadBankingTopLevelMaskContainerdeposit,		["scene"] = invBankScene_GP, 		["fragment"] = nil,		--uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created. Fragment will be updated as bank lists get initialized
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsHouseBankShown",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		--Works, 2021-12-18
		[LF_GUILDSTORE_SELL]          = { ["control"] = ZO_TradingHouse_GamepadMaskContainerSell,	["scene"] = invGuildStoreSellScene_GP, 	["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		--Works, 2021-12-18
		[LF_MAIL_SEND]                = { ["control"] = gpc.invMailSend_GP.send.sendControl,	["scene"] = gpc.invMailSendScene_GP,		["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		--Works, 2021-12-23
		[LF_TRADE]                    = { ["control"] = gpc.invPlayerTrade_GP, 					["scene"] = gpc.invPlayerTradeScene_GP, 	["fragment"] = invPlayerTradeFragment_GP, },

		--Works, 2021-12-19
		[LF_CRAFTBAG]                 = { ["control"] = ZO_GamepadInventoryTopLevelMaskContainerCraftBag, 	["scene"] = invRootScene_GP, 	["fragment"] = invFragment_GP, --control will be nil here, and initialized in GAMEPAD_INVENTORY:OnDeferredInitialize. So it will be populated to this table here there
										  ["special"] = {
											--[[
											  [1] = {
												  ["control"]         = invBackpack_GP.craftBagList,		--will be nil here, and initialized in GAMEPAD_INVENTORY:OnDeferredInitialize. So it will be populated to this table here there
												  ["funcOrAttribute"] = "IsActive",							--On first open of the gamepad CraftBag list this function will return false...
												  ["params"]          = { invBackpack_GP.craftBagList },	--will be nil here, and initialized in GAMEPAD_INVENTORY:OnDeferredInitialize. So it will be populated to this table here there
												  ["expectedResults"] = { true },
											  }
											  ]]
											  [1] = {
												  ["control"]         = _G[GlobalLibName],		--will be nil here, and initialized in GAMEPAD_INVENTORY:OnDeferredInitialize. So it will be populated to this table here there
												  ["funcOrAttribute"] = "IsVanillaCraftBagShown", --On first open of the gamepad CraftBag list this function will return false...
												  ["params"]          = { _G[GlobalLibName] },	--will be nil here, and initialized in GAMEPAD_INVENTORY:OnDeferredInitialize. So it will be populated to this table here there
												  ["expectedResults"] = { true },
											  }
										  }
		},
		--Works, 2021-12-18
		[LF_BANK_WITHDRAW]            = { ["control"] = ZO_GamepadBankingTopLevelMaskContainerwithdraw, 	["scene"] = invBankScene_GP, 		["fragment"] = nil, --fragment will be updated as bank lists get initialized
										  ["special"] = {
											  [1] = {
												  ["control"]         = _G[GlobalLibName],
												  ["funcOrAttribute"] = "IsHouseBankShown",
												  ["params"]          = { _G[GlobalLibName] },
												  ["expectedResults"] = { false },
											  }
										  }
		},
		--Works, 2021-12-18
		[LF_GUILDBANK_WITHDRAW]       = { ["control"] = ZO_GuildBankTopLevel_GamepadMaskContainerwithdraw, 	["scene"] = invGuildBankScene_GP,	["fragment"] = nil, },  -- fragment will be updated as guild bank lists get initialized
		--Works, 2021-12-18
		[LF_HOUSE_BANK_WITHDRAW]      = { ["control"] = ZO_GamepadBankingTopLevelMaskContainerwithdraw, 	["scene"] = invBankScene_GP,		["fragment"] = nil,		--fragment will be updated as bank lists get initialized
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsHouseBankShown",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		--Works, 2021-12-21
		[LF_SMITHING_REFINE]          = { ["control"] = refinementPanel_GP, 		["scene"] = refinementScene_GP, 	["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {false},
												}
											}
		},
		--Works, 2021-12-21
		[LF_SMITHING_DECONSTRUCT]     = { ["control"] = deconstructionPanel_GP, 	["scene"] = deconstructionScene_GP, ["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {false},
												}
											}
		},
		--Works, 2021-12-21
		[LF_SMITHING_IMPROVEMENT]     = { ["control"] = improvementPanel_GP, 		["scene"] = improvementScene_GP, 	["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {false},
												}
											}
		},
		--Works, 2021-12-21
		[LF_SMITHING_RESEARCH]        = { ["control"] = researchPanel_GP, 			["scene"] = researchScene_GP,		["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {false},
												}
											}
		},
		--Works, 2021-12-21
		[LF_JEWELRY_REFINE]           = { ["control"] = refinementPanel_GP, 		["scene"] = refinementScene_GP, 	["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		--Works, 2021-12-21
		[LF_JEWELRY_DECONSTRUCT]      = { ["control"] = deconstructionPanel_GP, 	["scene"] = deconstructionScene_GP, ["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		--Works, 2021-12-21
		[LF_JEWELRY_IMPROVEMENT]      = { ["control"] = improvementPanel_GP, 		["scene"] = improvementScene_GP, 	["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		--Works, 2021-12-21
		[LF_JEWELRY_RESEARCH]         = { ["control"] = researchPanel_GP, 			["scene"] = researchScene_GP, 		["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		--Works, 2021-12-22
		[LF_ALCHEMY_CREATION]	  	  = { ["control"] = alchemy_GP, 				["scene"] = alchemyCreationSecene_GP, 	["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"] = alchemy_GP,
													["funcOrAttribute"] = "mode",
													["params"] = {},
													["expectedResults"] = {ZO_ALCHEMY_MODE_CREATION},
												}
											}
		},
		--Works, 2021-12-22
		[LF_RETRAIT]                  = { ["control"] = gpc.retrait_GP, ["scene"] = gpc.retraitScene_GP, ["fragment"] = retraitFragment_GP, },


		--Normally these are special hooks in table LF_ConstantToAdditionalFilterSpecialHook.
		--But currently they are changed to be normal entries using HookAdditionalFilter for now, to hook the scenes
		--and add .additionalFilter, used in helpers ZO_Enchanting_DoesEnchantingItemPassFilter
		-->Used for gamepad AND keyboard mode with these entries here !!!
		--Works, 2021-12-22
		[LF_ENCHANTING_CREATION]	  = { ["control"] = enchanting_GP, ["scene"] = enchantingCreateScene_GP, ["fragment"] = nil,
										  ["special"] = {
											  [1] = {
												  ["control"]  =  enchanting_GP,
												  ["funcOrAttribute"] = "GetEnchantingMode",
												  ["params"] = {enchanting_GP},
												  ["expectedResults"] = {ENCHANTING_MODE_CREATION},
											  }
										  }
		},
		--Works, 2021-12-22
		[LF_ENCHANTING_EXTRACTION]	  = { ["control"] = enchanting_GP, ["scene"] = enchantingExtractScene_GP, ["fragment"] = nil,
											["special"] = {
												[1] = {
													["control"]  =  enchanting_GP,
													["funcOrAttribute"] = "GetEnchantingMode",
													["params"] = {enchanting_GP},
													["expectedResults"] = {ENCHANTING_MODE_EXTRACTION},
												}
											}
		},


		--Not implemented yet
		--Works, 2021-12-18
		--The data of control and fragment will not be provided until the gamepad guild store was opened first time!
		--> So this line will be updated again then via function "SetCurrentMode" -> See file gamepadCustomFragments, SecurePostHook("ZO_TradingHouse_Browse_Gamepad_OnInitialize", function()
		--Works, 2021-12-18
		[LF_GUILDSTORE_BROWSE]        = { ["control"] = gpc.tradingHouseBrowse_GP, 		["scene"] = invGuildStoreSellScene_GP,	["fragment"] =  nil }, --gpc.tradingHouseBrowse_GP.fragment, },
		--Works, 2021-12-21
		[LF_SMITHING_CREATION] 		  = { ["control"] = gpc.creationPanel_GP,			["scene"] = gpc.creationScene_GP, 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {false},
												}
											}
		},
		--Works, 2021-12-21
		[LF_JEWELRY_CREATION] 		  = { ["control"] = gpc.creationPanel_GP,			["scene"] = gpc.creationScene_GP, 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		--Works, 2021-12-22
		[LF_PROVISIONING_COOK]		  = { ["control"] = provisioner_GP,				["scene"] = provisionerScene_GP, ["fragment"] = provisionerFragment_GP,
										   ["special"] = {
												[1] = {
													["control"]  =  provisioner_GP,
													["funcOrAttribute"] = "filterType",
													["params"] = {},
													["expectedResults"] = {PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES},
												}
											}
		},
		--Works, 2021-12-22
		[LF_PROVISIONING_BREW]		  = { ["control"] = provisioner_GP,				["scene"] = provisionerScene_GP, ["fragment"] = provisionerFragment_GP,
										   ["special"] = {
												[1] = {
													["control"]  =  provisioner_GP,
													["funcOrAttribute"] = "filterType",
													["params"] = {},
													["expectedResults"] = {PROVISIONER_SPECIAL_INGREDIENT_TYPE_FLAVORING},
												}
											}
		},
	}
}
mapping.LF_FilterTypeToCheckIfReferenceIsHidden = filterTypeToCheckIfReferenceIsHidden


--Define the order in which the controls/scenes/fragments should be checked if no filterType is given.
--This is important o e.g. check LF_INVENTORY at last as the control of it could be used in multiple other filterTypes.
--Non-gap number index = { filterType = LF_*filterType constant, checkTypes = {"control", "fragment", "special", "specialForced" } }
--The LF_*filterTypeConstant will be used to get the control/scene/fragment/sepcial data from
--mapping.LF_FilterTypeToCheckIfReferenceIsHidden and the checkTypes define which of the checks should be done
--in which order (in the example above: 1st control, 2nd fragment, 3rd special
local filterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes = {
	--The order of the entries is fixed and should be used to assure no wrong control/scene/fragment/special check is
	--found "too early", and thus the wrong filterType is returned (e.g. ZO_PlayerInventory could be shown at
	--mail, trade, bank, inventory)
	--checkTypes will be checked from left to right (by the index of the table checkTypes) and either of them must be
	--shown == true, except specialForced: It will always be checked "in addition" to the result of the before done
	--checks!
	--Keyboard mode
	[false] = {
		{ filterType=LF_CRAFTBAG, 					checkTypes = { "fragment", "control", "special", "specialForced" } }, --> CraftBagExtended: Handled in specialForced
		{ filterType=LF_MAIL_SEND, 					checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_TRADE, 						checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_VENDOR_BUY, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_VENDOR_SELL, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_VENDOR_BUYBACK, 			checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_VENDOR_REPAIR, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_FENCE_SELL, 				checkTypes = { "scene", "fragment", "control"} },
		{ filterType=LF_FENCE_LAUNDER, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_SMITHING_CREATION, 			checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_JEWELRY_CREATION, 			checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_SMITHING_REFINE, 			checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_JEWELRY_REFINE, 			checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_SMITHING_DECONSTRUCT, 		checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_JEWELRY_DECONSTRUCT, 		checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_SMITHING_IMPROVEMENT, 		checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_JEWELRY_IMPROVEMENT, 		checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_SMITHING_RESEARCH_DIALOG,	checkTypes = { "special", "scene", "controlDialog" } },
		{ filterType=LF_JEWELRY_RESEARCH_DIALOG, 	checkTypes = { "special", "scene", "controlDialog" } },
		{ filterType=LF_SMITHING_RESEARCH, 			checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_JEWELRY_RESEARCH, 			checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_ENCHANTING_CREATION, 		checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_ENCHANTING_EXTRACTION, 		checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_GUILDSTORE_BROWSE, 			checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_GUILDSTORE_SELL, 			checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_ALCHEMY_CREATION, 			checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_PROVISIONING_COOK, 			checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_PROVISIONING_BREW, 			checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_BANK_WITHDRAW, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_HOUSE_BANK_WITHDRAW, 		checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_GUILDBANK_WITHDRAW, 		checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_RETRAIT, 					checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_INVENTORY_COMPANION, 		checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_BANK_DEPOSIT, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_GUILDBANK_DEPOSIT, 			checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_HOUSE_BANK_DEPOSIT, 		checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_INVENTORY_QUEST,			checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_QUICKSLOT, 					checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_INVENTORY, 					checkTypes = { "scene", "fragment", "control" } },
	},

--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

	--Gamepad mode
	[true] = {
		{ filterType=LF_CRAFTBAG, 					checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_MAIL_SEND, 					checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_TRADE, 						checkTypes = { "scene", "fragment", "control" }, },
		{ filterType=LF_VENDOR_BUY, 				checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_VENDOR_SELL, 				checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_VENDOR_BUYBACK, 			checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_VENDOR_REPAIR, 				checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_FENCE_SELL, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_FENCE_LAUNDER, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_SMITHING_CREATION, 			checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_JEWELRY_CREATION, 			checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_SMITHING_REFINE, 			checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_JEWELRY_REFINE, 			checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_SMITHING_DECONSTRUCT, 		checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_JEWELRY_DECONSTRUCT, 		checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_SMITHING_IMPROVEMENT, 		checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_JEWELRY_IMPROVEMENT, 		checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_SMITHING_RESEARCH_DIALOG,	checkTypes = { "special", "scene" } },
		{ filterType=LF_JEWELRY_RESEARCH_DIALOG, 	checkTypes = { "special", "scene" } },
		{ filterType=LF_SMITHING_RESEARCH, 			checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_JEWELRY_RESEARCH, 			checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_ENCHANTING_CREATION, 		checkTypes = { "scene", "control", "special" } },
		{ filterType=LF_ENCHANTING_EXTRACTION, 		checkTypes = { "scene", "control", "special" } },
		{ filterType=LF_GUILDSTORE_BROWSE, 			checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_GUILDSTORE_SELL, 			checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_ALCHEMY_CREATION, 			checkTypes = { "scene", "control", "special" } },
		{ filterType=LF_PROVISIONING_COOK, 			checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_PROVISIONING_BREW, 			checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_BANK_WITHDRAW, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_HOUSE_BANK_WITHDRAW, 		checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_GUILDBANK_WITHDRAW, 		checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_RETRAIT, 					checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_INVENTORY_COMPANION, 		checkTypes = { "fragment", "scene", "control" } },
		{ filterType=LF_BANK_DEPOSIT, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_GUILDBANK_DEPOSIT, 			checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_HOUSE_BANK_DEPOSIT, 		checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_INVENTORY_QUEST,			checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_QUICKSLOT, 					checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_INVENTORY, 					checkTypes = { "scene", "fragment", "control", "special" } },
	}
}
mapping.LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes = filterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes

local filterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup = {}
for inputMode, inputModeData in pairs(filterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes) do
	if filterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup[inputMode] == nil then
		filterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup[inputMode] = {}
	end
	for idx, filterTypeData in ipairs(inputModeData) do
		filterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup[inputMode][filterTypeData.filterType] = idx
	end
end
mapping.LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup = filterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup

--[Mapping for filterTypes, to other filterTypes (dependend on crafting)]
mapping.filterTypeToFilterTypeRespectingCraftType = {
	[CRAFTING_TYPE_JEWELRYCRAFTING] = {
		--Non jewelry filterTypes mapped to jewelry ones
		[LF_SMITHING_REFINE]            = LF_JEWELRY_REFINE,
		[LF_SMITHING_DECONSTRUCT]       = LF_JEWELRY_DECONSTRUCT,
		[LF_SMITHING_IMPROVEMENT]       = LF_JEWELRY_IMPROVEMENT,
		[LF_SMITHING_RESEARCH]          = LF_JEWELRY_RESEARCH,
		[LF_SMITHING_RESEARCH_DIALOG]   = LF_JEWELRY_RESEARCH_DIALOG,
	}
}


--[Mapping for update of inventories]
--The fixed updater names for the LibFilters unique updater string -> See table inventoryUpdaters below -> The key is
--the value of this table here, e.g. BANK_WITHDRAW
local filterTypeToUpdaterNameFixed = {
	 [LF_BANK_WITHDRAW]				= "BANK_WITHDRAW",
	 [LF_GUILDBANK_WITHDRAW]		= "GUILDBANK_WITHDRAW",
	 [LF_VENDOR_BUY]				= "VENDOR_BUY",
	 [LF_VENDOR_BUYBACK]			= "VENDOR_BUYBACK",
	 [LF_VENDOR_REPAIR]				= "VENDOR_REPAIR",
	 [LF_GUILDSTORE_BROWSE]			= "GUILDSTORE_BROWSE",
	 [LF_ALCHEMY_CREATION]			= "ALCHEMY_CREATION",
	 [LF_PROVISIONING_COOK]			= "PROVISIONING_COOK",
	 [LF_PROVISIONING_BREW]			= "PROVISIONING_BREW",
	 [LF_CRAFTBAG]					= "CRAFTBAG",
	 [LF_QUICKSLOT]					= "QUICKSLOT",
	 [LF_RETRAIT]					= "RETRAIT",
	 [LF_HOUSE_BANK_WITHDRAW]		= "HOUSE_BANK_WITHDRAW",
	 [LF_INVENTORY_QUEST]			= "INVENTORY_QUEST",
	 [LF_INVENTORY_COMPANION]		= "INVENTORY_COMPANION"
}
mapping.filterTypeToUpdaterNameFixed = filterTypeToUpdaterNameFixed

--The updater names which are shared with others
local filterTypeToUpdaterNameDynamic = {
	 ["INVENTORY"] = {
		  [LF_INVENTORY]=true,
		  [LF_BANK_DEPOSIT]=true,
		  [LF_GUILDBANK_DEPOSIT]=true,
		  [LF_VENDOR_SELL]=true,
		  [LF_GUILDSTORE_SELL]=true,
		  [LF_MAIL_SEND]=true,
		  [LF_TRADE]=true,
		  [LF_FENCE_SELL]=true,
		  [LF_FENCE_LAUNDER]=true,
		  [LF_HOUSE_BANK_DEPOSIT]=true,
	 },
	 ["SMITHING_REFINE"] = {
		  [LF_SMITHING_REFINE]=true,
		  [LF_JEWELRY_REFINE]=true,
	 },
	 ["SMITHING_CREATION"] = {
		  [LF_SMITHING_CREATION]=true,
		  [LF_JEWELRY_CREATION]=true,
	 },
	 ["SMITHING_DECONSTRUCT"] = {
		  [LF_SMITHING_DECONSTRUCT]=true,
		  [LF_JEWELRY_DECONSTRUCT]=true,
	 },
	 ["SMITHING_IMPROVEMENT"] = {
		  [LF_SMITHING_IMPROVEMENT]=true,
		  [LF_JEWELRY_IMPROVEMENT]=true,
	 },
	 ["SMITHING_RESEARCH"] = {
		  [LF_SMITHING_RESEARCH]=true,
		  [LF_JEWELRY_RESEARCH]=true,
	 },
	 ["SMITHING_RESEARCH_DIALOG"] = {
		  [LF_SMITHING_RESEARCH_DIALOG]=true,
		  [LF_JEWELRY_RESEARCH_DIALOG]=true,
	 },
	 ["ENCHANTING"] = {
		  [LF_ENCHANTING_CREATION]=true,
		  [LF_ENCHANTING_EXTRACTION]=true,
	 },
}
mapping.filterTypeToUpdaterNameDynamic = filterTypeToUpdaterNameDynamic

--The filterType to unique updater String table. Will be filled with the fixed updater names and the dynamic afterwards
local filterTypeToUpdaterName = {}
local updaterNameToFilterType = {}
--Add the fixed updaterNames of the filtertypes
filterTypeToUpdaterName = filterTypeToUpdaterNameFixed
--Then dynamically add the other updaterNames from the above table filterTypeToUpdaterNameDynamic
for updaterName, filterTypesTableForUpdater in pairs(filterTypeToUpdaterNameDynamic) do
	 if updaterName ~= "" then
		  for filterType, isEnabled in pairs(filterTypesTableForUpdater) do
				if isEnabled then
					 filterTypeToUpdaterName[filterType] = updaterName
				end
		  end
	 end
end
mapping.filterTypeToUpdaterName = filterTypeToUpdaterName
for filterType, updaterName in pairs(filterTypeToUpdaterName) do
	updaterNameToFilterType[updaterName] = updaterNameToFilterType[updaterName] or {}
	tins(updaterNameToFilterType[updaterName], filterType)
end
mapping.updaterNameToFilterType = updaterNameToFilterType

--Will be filled within file LibFilters-3.0.lua with the above strings and their related updater function (divived by
--keyboard and gamepad mode)
mapping.inventoryUpdaters = { }


--[Mapping for the callbacks as filterType panels are shown/hidden]
libFilters.mapping.callbacks = {}
local callbacks = libFilters.mapping.callbacks
--The pattern for the filterPanel shown/hidden callbacks,
-->e.g. "LibFilters3-<yourAddonName>-shown-1-all" for SCENE_SHOWN and filterType LF_INVENTORY of addon <yourAddonName>, and universalDeconTab "all"
libFilters.callbackPattern = GlobalLibName .. "-%s-%s-%s-%s"
--The pattern for non-addons -> Base Library callback raising! LibFilters3-shown-1-all for SCENE_SHOWN and filterType LF_INVENTORY and universalDeconTab "all"
libFilters.callbackBaseLibPattern = GlobalLibName .. "-%s-%s-%s"

--The supported SCENE states for the callbacks
--Currently: shown and hidden
local sceneStatesSupportedForCallbacks = {
	[SCENE_SHOWN] 	= true,
	[SCENE_HIDDEN] 	= true,
}
callbacks.sceneStatesSupportedForCallbacks = sceneStatesSupportedForCallbacks


--[fragment] = { LF_* filterTypeConstant, LF_* filterTypeConstant, ... } -> Will be checked in this order
--0 means no dedicated LF_* constant can be used and the filterType will be determined automatically via function
--detectShownReferenceNow(), using table mapping.LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup
-->0 should be added as last entry if an automated check should be done at the end!
--Example:
--[fragmentVariable] = { LF_INVENTORY, 0}
local callbacksUsingFragments = {
	--Keyboard
	[false] = {
		--LF_INVENTORY
		--LF_BANK_DEPOSIT
		--LF_GUILDBANK_DEPOSIT
		--LF_HOUSE_BANK_DEPOSIT
		--LF_VENDOR_SELL
		[inventoryFragment] 			= { LF_INVENTORY, LF_BANK_DEPOSIT, LF_GUILDBANK_DEPOSIT, LF_HOUSE_BANK_DEPOSIT, LF_VENDOR_SELL, LF_GUILDSTORE_SELL },

		--Dedicated fragments
		[invQuestFragment] 				= { LF_INVENTORY_QUEST },
		[craftBagFragment] 				= { LF_CRAFTBAG },
		[quickslotsFragment]			= { LF_QUICKSLOT },
		[bankWithdrawFragment]         	= { LF_BANK_WITHDRAW },
		[guildBankWithdrawFragment]    	= { LF_GUILDBANK_WITHDRAW },
		[houseBankWithdrawFragment]    	= { LF_HOUSE_BANK_WITHDRAW },
		[vendorBuyFragment]            	= { LF_VENDOR_BUY },
		[vendorBuyBackFragment]        	= { LF_VENDOR_BUYBACK },
		[vendorRepairFragment]         	= { LF_VENDOR_REPAIR },
		[invFenceSellFragment]         	= { LF_FENCE_SELL },
		[invFenceLaunderFragment]      	= { LF_FENCE_LAUNDER },
		[guildStoreBrowseFragment]     	= { LF_GUILDSTORE_BROWSE },
		[mailSendFragment]             	= { LF_MAIL_SEND },
		[player2playerTradeFragment]   	= { LF_TRADE },
		[retraitFragment]              	= { LF_RETRAIT },
		[companionEquipmentFragment]   	= { LF_INVENTORY_COMPANION },
	},

--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

	--Gamepad
	[true] = {

		--Dedicated fragments
		[storeComponents[ZO_MODE_STORE_BUY].list._fragment] 		= { LF_VENDOR_BUY },
		[storeComponents[ZO_MODE_STORE_SELL].list._fragment] 		= { LF_VENDOR_SELL },
		[storeComponents[ZO_MODE_STORE_BUY_BACK].list._fragment] 	= { LF_VENDOR_BUYBACK },
		[storeComponents[ZO_MODE_STORE_REPAIR].list._fragment] 		= { LF_VENDOR_REPAIR },
		[storeComponents[ZO_MODE_STORE_SELL_STOLEN].list._fragment] = { LF_FENCE_SELL },
		[storeComponents[ZO_MODE_STORE_LAUNDER].list._fragment] 	= { LF_FENCE_LAUNDER },
		[quickslotFragment_GP] 										= { LF_QUICKSLOT },
		[retraitFragment_GP]										= { LF_RETRAIT },
		[invPlayerTradeFragment_GP]									= { LF_TRADE },			--> Maybe, should be also be triggered via custom fragment "gamepadLibFiltersPlayerTradeFragment"!
		[companionEquipmentFragment_GP]								= { LF_INVENTORY_COMPANION }

		-->Custom fragments will be updated from file /Gamepad/gamepadCustomFragments.lua
		--The fragments will be updated as inv/bank lists get initialized
		--callbacksUsingFragments[true][gamepadLibFiltersInventoryFragment] 		= { LF_INVENTORY }
		--callbacksUsingFragments[true][gamepadLibFiltersBankDepositFragment] 		= { LF_BANK_DEPOSIT }
		--callbacksUsingFragments[true][gamepadLibFiltersGuildBankDepositFragment] 	= { LF_GUILDBANK_DEPOSIT }
		--callbacksUsingFragments[true][gamepadLibFiltersHouseBankDepositFragment] 	= { LF_HOUSE_BANK_DEPOSIT }
		--[tradingHouseBrowse_GP.fragment] 											= { LF_GUILDSTORE_BROWSE }
		--callbacksUsingFragments[true][gamepadLibFiltersGuildStoreSellFragment] 	= { LF_GUILDSTORE_SELL }
		--callbacksUsingFragments[true][gamepadLibFiltersMailSendFragment] 			= { LF_MAIL_SEND }
		--callbacksUsingFragments[true][gamepadLibFiltersPlayerTradeFragment] 		= { LF_TRADE }
		--callbacksUsingFragments[true][gamepadLibFiltersInventoryQuestFragment] 	= { LF_INVENTORY_QUEST }
		--[1] = { LF_BANK_WITHDRAW },
		--[1] = { LF_GUILDBANK_WITHDRAW },
		--[1] = { LF_HOUSE_BANK_WITHDRAW },
		--[invBackpack_GP.craftBagList._fragment] = { LF_CRAFTBAG }, --Will be updated in file /Gamepad/gamepadCustomFragments.lua, function SecurePostHook(invBackpack_GP, "OnDeferredInitialize", function(self)
	}
}
callbacks.usingFragments = callbacksUsingFragments


--A table with the mapping of a fragment to a table of filterTypes that libFilters._currentFilterType is not allowed to
--currently equal to. Else the fragment's callback will not fire. e.g. the inventory fragment will fire after the mail send layout fragment.
--The mail send layout fragment will set libFilters._currentFilterType to LF_MAIL_SEND and the inventory fragment would afterwards try to detect
--other panels again, which is not needed!
local callbackFragmentsBlockedMapping = {
	--Keyboard
	[false] = {
		[SCENE_SHOWN] = {
			[inventoryFragment] = { LF_MAIL_SEND }, --Will not raise a callback for inventoryFragment if current filterType is LF_MAIL_SEND

		},
		[SCENE_HIDDEN] = {

		}
	},

--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

	--Gamepad
	[true] = {
		[SCENE_SHOWN] = {
		},
		[SCENE_HIDDEN] = {
		}
	}
}
callbacks.callbackFragmentsBlockedMapping = callbackFragmentsBlockedMapping

--[scene_Or_sceneName] = { LF_* filterTypeConstant, LF_* filterTypeConstant, ... }
--0 means no dedicated LF_* constant can be used and the filterType will be determined automatically via function
--detectShownReferenceNow(), using table mapping.LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup
-->0 should be added as last entry if an automated check should be done at the end!
--Example:
--[sceneVariable] = { LF_INVENTORY, 0 }
local callbacksUsingScenes = {
	--Keyboard
	[false] = {
		--Dedicated scenes
	},

--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

	--Gamepad
	[true] = {
	 	--LF_SMITHING_REFINE
		--LF_JEWELRY_REFINE
		[refinementScene_GP] 				= { LF_SMITHING_REFINE, LF_JEWELRY_REFINE },
	 	--LF_SMITHING_CREATION
		--LF_JEWELRY_CREATION
		[creationScene_GP] 					= { LF_SMITHING_CREATION, LF_JEWELRY_CREATION },
		--LF_SMITHING_DECONSTRUCT
		--LF_JEWELRY_DECONSTRUCT
		[deconstructionScene_GP] 			= { LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT },
		--LF_SMITHING_IMPROVEMENT
		--LF_JEWELRY_IMPROVEMENT
		[improvementScene_GP] 				= { LF_SMITHING_IMPROVEMENT, LF_JEWELRY_IMPROVEMENT },
		--LF_SMITHING_RESEARCH
		--LF_JEWELRY_RESEARCH
		[researchScene_GP] 					= { LF_SMITHING_RESEARCH, LF_JEWELRY_RESEARCH },
		--LF_SMITHING_RESEARCH_DIALOG
		--LF_JEWELRY_RESEARCH_DIALOG
		[researchChooseItemDialog_GP] 		= { LF_SMITHING_RESEARCH_DIALOG, LF_JEWELRY_RESEARCH_DIALOG },

		--Dedicated scenes
		[alchemyCreationSecene_GP] 			= { LF_ALCHEMY_CREATION },
		[enchantingCreateScene_GP] 			= { LF_ENCHANTING_CREATION },
		[enchantingExtractScene_GP] 		= { LF_ENCHANTING_EXTRACTION },
	}
}
callbacks.usingScenes = callbacksUsingScenes


------------------------------------------------------------------------------------------------------------------------
--Special control callback check functions


--[control] = { {filterTypes={LF_* filterTypeConstant, ...}, specialPanelControlFunc=funcRef}, {filterTypes={0}, specialPanelControlFunc=funcRef}, {...} }
--filterTypes={0} means no dedicated LF_* constant can be used and the filterType will be determined
-->0 should be added as last entry if an automated check should be done at the end!
--Example:
--[controlVariable] = { filterTypes={LF_INVENTORY}}
--specialPanelControlFunc is a function with parameters = LF_constant, panelControl, isInGamepadMode. It checks code and returns an alternative
--panelControl to register/run the callback on, or the default panelControl passed in if no special control is needed
local callbacksUsingControls = {
	--Keyboard
	[false] = {
	 	--LF_SMITHING_REFINE
		--LF_JEWELRY_REFINE
		[refinementPanel] 					= { {filterTypes={LF_SMITHING_REFINE, LF_JEWELRY_REFINE}, specialPanelControlFunc=nil}, },
	 	--LF_SMITHING_CREATION
		--LF_JEWELRY_CREATION
		[creationPanel] 					= { {filterTypes={LF_SMITHING_CREATION, LF_JEWELRY_CREATION}, specialPanelControlFunc=nil}, },
		--LF_SMITHING_DECONSTRUCT
		--LF_JEWELRY_DECONSTRUCT
		[deconstructionPanel] 				= { {filterTypes={LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT}, specialPanelControlFunc=nil}, },
		--LF_SMITHING_IMPROVEMENT
		--LF_JEWELRY_IMPROVEMENT
		[improvementPanel] 					= { {filterTypes={LF_SMITHING_IMPROVEMENT, LF_JEWELRY_IMPROVEMENT}, specialPanelControlFunc=nil}, },
		--LF_SMITHING_RESEARCH
		--LF_JEWELRY_RESEARCH
		[researchPanel] 					= { {filterTypes={LF_SMITHING_RESEARCH, LF_JEWELRY_RESEARCH}, specialPanelControlFunc=nil}, },
		--LF_SMITHING_RESEARCH_DIALOG
		--LF_JEWELRY_RESEARCH_DIALOG
		[listDialog1] 						= { {filterTypes={LF_SMITHING_RESEARCH_DIALOG, LF_JEWELRY_RESEARCH_DIALOG}, specialPanelControlFunc=nil}, },
	},

--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

	--Gamepad
	[true] = {

		--Dedicated controls
	},
}
callbacks.usingControls = callbacksUsingControls


--Callbacks using special functions etc.
--Important: No callbacks are registered diretly to the table contents below!
-->The table below "is just kept to fill the reference control/scene/fragment" to table callbacks.filterTypeToCallbackRef
-->so that e.g. the EVENT_END_CRAFTING_STATION_INTERACT will find a referenced control to raise a SCENE_HIDDEN callback on
-->via function libFilters_RaiseFilterTypeCallback(libFilters, lastShownFilterType, SCENE_HIDDEN, nil)
local callbacksUsingSpecials = {
	--Keyboard
	[false] = {
		[enchanting.control] 				= { LF_ENCHANTING_CREATION, LF_ENCHANTING_EXTRACTION }, 	--via ENCHANTING:OnModeUpdated
		[provisioner.control] 				= { LF_PROVISIONING_COOK, LF_PROVISIONING_BREW },  			--via PROVISIONER:OnTabFilterChanged
		[alchemy.control]              		= { LF_ALCHEMY_CREATION },									--via ALCHEMY:SetMode
		--All crafting tables open/close via EVENT_CRAFTING_STATION_INTERACT and EVENT_END_CRAFTING_STATION_INTERACT

		--Universal Deconstruction: Re-Uses filterTypes
		--LF_SMITHING_DECONSTRUCT
		--LF_JEWELRY_DECONSTRUCT
		--LF_ENCHANTING_EXTRACTION
		--Universal deconstruction: Re-uses filterTypes LF_SMITHING_DECONSTRUCT and LF_JEWELRY_DECONSTRUCT and just shows them at new UI controls
		-->Therefor the specialPanelControlFunc will check if the UniversalDecon panel is shown and replace the panelControl where the callback
		-->was added/run on
		--> Also a special hook will be added at universalDeconstructionPanel:RegisterCallback("OnFilterChanged", function(tab, craftingTypes, includeBanked)
		[universalDeconstructPanel]			= { LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT, LF_ENCHANTING_EXTRACTION }, --via UNIVERSAL_DECONSTRUCTION.deconstructionPanel:OnFilterChanged
	},

--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

	--Gamepad
	[true] = {
		[provisioner_GP.control] 			= { LF_PROVISIONING_COOK, LF_PROVISIONING_BREW },  			--via GAMEPAD_PROVISIONER:OnTabFilterChanged

		--Universal Deconstruction: Re-Uses filterTypes
		--LF_SMITHING_DECONSTRUCT
		--LF_JEWELRY_DECONSTRUCT
		--LF_ENCHANTING_EXTRACTION
		--Universal deconstruction: Re-uses filterTypes LF_SMITHING_DECONSTRUCT and LF_JEWELRY_DECONSTRUCT and just shows them at new UI controls
		-->Therefor the specialPanelControlFunc will check if the UniversalDecon panel is shown and replace the panelControl where the callback
		-->was added/run on
		[universalDeconstructPanel_GP]		= { LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT, LF_ENCHANTING_EXTRACTION }, --via UNIVERSAL_DECONSTRUCTION_GAMEPAD.deconstructionPanel:OnFilterChanged
	},

}
callbacks.usingSpecials = callbacksUsingSpecials


--Exclude these callback variables as they would overwrite the filterTypes of other callbacks!
-->UniversalDeconstrction e.g.
local callbacksExcludeFilterTypesFromFilterTypeToCallbackRef = {
	--Keyboard
	[false] = {
		[universalDeconstructPanel] = true, --UniversalDeconstruction Keyboard: Prevent overwriting LF_SMITHING_DECONSTRUCT/LF_JEWELRY_DECONSTRUCT/LF_ENCHANTING_EXTRACT in table filterTypeToCallbackRef
	},
	--Gamepad
	[true] = {
		[universalDeconstructPanel_GP] = true,  --UniversalDeconstruction Gamepad: Prevent overwriting LF_SMITHING_DECONSTRUCT/LF_JEWELRY_DECONSTRUCT/LF_ENCHANTING_EXTRACT in table filterTypeToCallbackRef
	},
}

--The mapping tables to determine the callback's reference variables by the filterType and inputType
local filterTypeToCallbackRef = {
	--Keyboard
	[false] = {
	},

--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

	--Gamepad
	[true] = {
	},
}
--Fill the mapping table above for each type of reference and inputType
--Scenes
for inputType, sceneCallbackData in pairs(callbacksUsingScenes) do
--d("[SCENE callbacks - inputType: " ..tos(inputType))
	for sceneVar, filterTypes in pairs(sceneCallbackData) do
		if not callbacksExcludeFilterTypesFromFilterTypeToCallbackRef[inputType][sceneVar] then
			for _, filterType in ipairs(filterTypes) do
--d(">Adding filterType: " ..tos(filterType) .. ", name: " ..tostring(getRefName(sceneVar)))
				filterTypeToCallbackRef[inputType][filterType] = {
					ref = sceneVar,
					refType = LIBFILTERS_CON_TYPEOFREF_SCENE
				}
			end
		end
	end
end
--Fragments
for inputType, fragmentCallbackData in pairs(callbacksUsingFragments) do
--d("[FRAGMENT callbacks - inputType: " ..tos(inputType))
	for fragmentVar, filterTypes in pairs(fragmentCallbackData) do
		if not callbacksExcludeFilterTypesFromFilterTypeToCallbackRef[inputType][fragmentVar] then
			for _, filterType in ipairs(filterTypes) do
--d(">Adding filterType: " ..tos(filterType) .. ", name: " ..tostring(getRefName(fragmentVar)))
				filterTypeToCallbackRef[inputType][filterType] = {
					ref = fragmentVar,
					refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT
				}
			end
		end
	end
end

--Controls
for inputType, controlsCallbackDataOfInputType in pairs(callbacksUsingControls) do
--d("[CONTROL callbacks - inputType: " ..tos(inputType))
	for controlVar, controlVarCallbackData in pairs(controlsCallbackDataOfInputType) do
		if not callbacksExcludeFilterTypesFromFilterTypeToCallbackRef[inputType][controlVar] then
			for _, controlCallbackData in ipairs(controlVarCallbackData) do
				local controlFilterTypes = controlCallbackData.filterTypes
				if controlFilterTypes ~= nil then
					for _, filterType in ipairs(controlFilterTypes) do
--d(">Adding filterType: " ..tos(filterType) .. ", name: " ..tostring(getRefName(controlVar)))
						filterTypeToCallbackRef[inputType][filterType] = {
							ref = controlVar,
							refType = LIBFILTERS_CON_TYPEOFREF_CONTROL,
							specialPanelControlFunc=controlCallbackData.specialPanelControlFunc
						}
					end
				end
			end
		else
--d("<excluded control: " ..tos(getRefName(controlVar)))
		end
	end
end
--Specials
for inputType, specialsCallbackData in pairs(callbacksUsingSpecials) do
--d("[SPECIAL callbacks - inputType: " ..tos(inputType))
	for specialVar, filterTypes in pairs(specialsCallbackData) do
		if not callbacksExcludeFilterTypesFromFilterTypeToCallbackRef[inputType][specialVar] then
			for _, filterType in ipairs(filterTypes) do
--d(">Adding filterType: " ..tos(filterType) .. ", name: " ..tostring(getRefName(specialVar)))
				local refType = checkIfControlSceneFragmentOrOther(specialVar)
				filterTypeToCallbackRef[inputType][filterType] = {
					ref = specialVar,
					refType = refType
				}
			end
		end
	end
end
callbacks.filterTypeToCallbackRef = filterTypeToCallbackRef


--Special callbacks at controls e.g. OnHide of ZO_ListDialog1 -> Detect the shown panel again to e.g. change the currentFilterType from LF_SMITHING_RESEARCH_DIALOG to
--LF_SMITHING_RESEARCH again
--[controlOrSceneOrFragentReference] = { [SCENE_SHOWN  or SCENE_HIDDEN] =
-- function(controlOrSceneOrFragmentRef, stateStr, inputType, refType) yourFunction(controlOrSceneOrFragmentRef, stateStr, inputType, refType) end }
callbacks.special = {
	--LF_SMITHING_RESEARCH_DIALOG
	--LF_JEWELRY_RESEARCH_DIALOG
	[listDialog1] = {
		[SCENE_HIDDEN] = function(controlOrSceneOrFragmentRef, stateStr, inputType, refType)
			if libFilters.debug then dv(">>>Special callback: ZO_ListDialog1:OnHide") end
			--Detect the shown panel again
			if not libFilters:IsCraftingStationShown() then return end
			libFilters:RaiseShownFilterTypeCallback(SCENE_SHOWN, inputType, false)
		end,
	},
}

if libFilters.debug then dd("LIBRARY CONSTANTS FILE - END") end


