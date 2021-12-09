------------------------------------------------------------------------------------------------------------------------
--LIBRARY CONSTANTS
------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3 name, and version
local MAJOR, GlobalLibName, MINOR = "LibFilters-3.0", "LibFilters3", 3.0

--Was the library loaded already? Abort here then
if _G[GlobalLibName] ~= nil then return end

--local lua speed-up variables
local tos = tostring
local strform = string.format
local strup = string.upper
local tins = table.insert

--local ZOs speed-up variables
local SM = SCENE_MANAGER

--Local library variable
local libFilters = {}
libFilters.filters = {}
local filters = libFilters.filters
-- Initialization will be done via function "libFilters:InitializeLibFilters()" which should be called in addons once,
-- after EVENT_ADD_ON_LOADED
libFilters.isInitialized = false

--Use the LF_FILTER_ALL registered filters as fallback filterFunctions for all panels -> see file LibFilters-3.0.lua,
--function runFilters, and API function libFilters:SetFilterAllState(boolean newState)
libFilters.useFilterAllFallback = false


------------------------------------------------------------------------------------------------------------------------
--Debugging output enabled/disabled: Changed via SLASH_COMMANDS /libfiltersdebug or /lfdebug
libFilters.debug = false

--LibDebugLogger & debugging functions
libFilters.debugFunctions = {}
local debugFunctions = libFilters.debugFunctions

if LibDebugLogger then
	 if not libFilters.logger then
		  libFilters.logger = LibDebugLogger(MAJOR)
	 end
end
local logger = libFilters.logger


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
				["E"] = "Error",
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

--Error message
local function dfe(...)
	debugMessageCaller('E', ...)
end
debugFunctions.dfe = dfe

local function debugSlashToggle(args)
	libFilters.debug = not libFilters.debug
	df("Debugging %s", (not libFilters.debug and "disabled") or "enabled")
end
debugFunctions.debugSlashToggle = debugSlashToggle

local isDebugginEnabled = libFilters.debug
if isDebugginEnabled then dd("LIBRARY CONSTANTS FILE - START") end

------------------------------------------------------------------------------------------------------------------------
--Create global library constant LibFilters3
_G[GlobalLibName]	= libFilters
libFilters.name	            = MAJOR
libFilters.version          = MINOR
libFilters.globalLibName    = GlobalLibName
------------------------------------------------------------------------------------------------------------------------

libFilters.constants = {}

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
libFilters.constants.filterTypes = libFiltersFilterConstants

--The default attribute at an inventory/layoutData/scene/control used within table LF_ConstantToAdditionalFilterControlSceneFragmentUserdata
--to store the libFilters 3.0 filterType "currently assigned to this panel", e.g.
local defaultLibFiltersAttributeToStoreTheFilterType = "LibFilters3_filterType"
libFilters.constants.defaultAttributeToStoreTheFilterType = defaultLibFiltersAttributeToStoreTheFilterType

--The default attribute at an inventory/layoutData table where the filter functions of LiFilters should be added to
--and where ZOS or other addons could have already added filter functions to -> See LibFilters-3.0.lua, function HookAdditionalFilters
local defaultOriginalFilterAttributeAtLayoutData = "additionalFilter"
libFilters.constants.defaultAttributeToAddFilterFunctions = defaultOriginalFilterAttributeAtLayoutData

--Other attributes at an inventory/layoutData table where ZOs or other addons could have already added filter functions to
--> See LibFilters-3.0.lua, function HookAdditionalFilters
local otherOriginalFilterAttributesAtLayoutData_Table = {
	[LF_CRAFTBAG] = "additionalCraftBagFilter"
}
libFilters.constants.otherAttributesToGetOriginalFilterFunctions = otherOriginalFilterAttributesAtLayoutData_Table

--The prefix for the updater name used in libFilters:RequestUpdate()
local updaterNamePrefix = GlobalLibName .. "_updateInventory_"
libFilters.constants.updaterNamePrefix = updaterNamePrefix


------------------------------------------------------------------------------------------------------------------------
--ZOs / ESOUI CONSTANTS
------------------------------------------------------------------------------------------------------------------------
libFilters.constants.keyboard = {}
local keyboardConstants = libFilters.constants.keyboard

libFilters.constants.gamepad = {}
local gamepadConstants = libFilters.constants.gamepad

--Custom created fragments for the gamepad mode
--Prefix of these fragments
gamepadConstants.customFragmentPrefix = GlobalLibName:upper() .. "_" -- LIBFILTERS3_
local fragmentPrefix_GP = gamepadConstants.customFragmentPrefix

------------------------------------------------------------------------------------------------------------------------
--CONSTANTS (*_GP is the gamepad mode constant, the others are commonly used with both, or keyboard only constants)
------------------------------------------------------------------------------------------------------------------------
--[Inventory types]
local invTypeBackpack =			INVENTORY_BACKPACK
local invTypeQuest = 			INVENTORY_QUEST_ITEM
local invTypeBank =				INVENTORY_BANK
local invTypeGuildBank =		INVENTORY_GUILD_BANK
local invTypeHouseBank =		INVENTORY_HOUSE_BANK
local invTypeCraftBag = 		INVENTORY_CRAFT_BAG
libFilters.constants.inventoryTypes = {}
libFilters.constants.inventoryTypes["player"] = 	invTypeBackpack
libFilters.constants.inventoryTypes["quest"] = 		invTypeQuest
libFilters.constants.inventoryTypes["bank"] = 		invTypeBank
libFilters.constants.inventoryTypes["guild_bank"] = invTypeGuildBank
libFilters.constants.inventoryTypes["house_bank"] = invTypeHouseBank
libFilters.constants.inventoryTypes["craftbag"] = 	invTypeCraftBag


------------------------------------------------------------------------------------------------------------------------
--Keyboard constants
------------------------------------------------------------------------------------------------------------------------
--Inventory
keyboardConstants.playerInv  =  		    	PLAYER_INVENTORY
keyboardConstants.inventories  = 				keyboardConstants.playerInv.inventories
local inventories = keyboardConstants.inventories
keyboardConstants.playerInvCtrl = 				ZO_PlayerInventory

--Character
keyboardConstants.characterCtrl =				ZO_Character

--Backpack
keyboardConstants.invBackpack  = 				inventories[invTypeBackpack]
local invBackpack = keyboardConstants.invBackpack
keyboardConstants.invBackpackFragment  = 		BACKPACK_MENU_BAR_LAYOUT_FRAGMENT

--Craftbag
--keyboardConstants.craftBagClass  =  			ZO_CraftBag
keyboardConstants.invCraftbag  = 				inventories[invTypeCraftBag]

--Quest items
keyboardConstants.invQuests  = 					inventories[invTypeQuest]

--Quickslots
keyboardConstants.quickslots  = 				QUICKSLOT_WINDOW


--[Banks]
--Player bank
keyboardConstants.invBankDeposit  = 			BACKPACK_BANK_LAYOUT_FRAGMENT
keyboardConstants.invBankWithdraw  = 			inventories[invTypeBank]

--Guild bank
keyboardConstants.invGuildBankDeposit  =    	BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT
keyboardConstants.invGuildBankWithdraw  = 		inventories[invTypeGuildBank]

--House bank
keyboardConstants.invHouseBankDeposit  =  		BACKPACK_HOUSE_BANK_LAYOUT_FRAGMENT
keyboardConstants.invHouseBankWithdraw  = 		inventories[invTypeHouseBank]

--[Vendor]
----Buy
keyboardConstants.store  = 						STORE_WINDOW
---Sell
keyboardConstants.vendorBuy   =  				keyboardConstants.store
keyboardConstants.vendorSell  =  				BACKPACK_STORE_LAYOUT_FRAGMENT
---Buy back
keyboardConstants.vendorBuyBack  = 				BUY_BACK_WINDOW
---Repair
keyboardConstants.vendorRepair  = 				REPAIR_WINDOW
keyboardConstants.storeWindows = {
	[ZO_MODE_STORE_BUY] = 			keyboardConstants.vendorBuy,
	[ZO_MODE_STORE_BUY_BACK] = 		keyboardConstants.vendorBuyBack,
	[ZO_MODE_STORE_SELL] = 			keyboardConstants.vendorSell,
	[ZO_MODE_STORE_REPAIR] = 		keyboardConstants.vendorRepair,
	[ZO_MODE_STORE_SELL_STOLEN] = 	keyboardConstants.vendorSell,
	[ZO_MODE_STORE_LAUNDER] = 		keyboardConstants.vendorSell,
	[ZO_MODE_STORE_STABLE] = 		keyboardConstants.vendorBuy,
}

--[Fence]
--Fence launder
keyboardConstants.fence = 						FENCE_KEYBOARD
keyboardConstants.invFenceLaunder  = 			BACKPACK_LAUNDER_LAYOUT_FRAGMENT

--Fence sell
keyboardConstants.invFenceSell  =  				BACKPACK_FENCE_LAYOUT_FRAGMENT


--[Guild store]
--keyboardConstants.guildStoreBuy = guildStoreBuy			--not supported by LibFilters yet
keyboardConstants.guildStoreSell  =  			BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT


--[Mail]
keyboardConstants.mailSend  = 					BACKPACK_MAIL_LAYOUT_FRAGMENT


--[Player 2 player trade]
keyboardConstants.player2playerTrade  =  		BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT


--[Companion]
keyboardConstants.companionEquipment  =  		COMPANION_EQUIPMENT_KEYBOARD
keyboardConstants.companionCharacterCtrl =    	ZO_CompanionCharacterWindow_Keyboard_TopLevel


--[Crafting]
keyboardConstants.smithing  =  					SMITHING
local smithing = keyboardConstants.smithing

--Refinement
keyboardConstants.refinementPanel  = 	  		smithing.refinementPanel

--Create
keyboardConstants.creationPanel  = 	  			smithing.creationPanel

--Deconstruction
keyboardConstants.deconstructionPanel  =  		smithing.deconstructionPanel

--Improvement
keyboardConstants.improvementPanel  = 	 		smithing.improvementPanel

--Research
keyboardConstants.researchPanel  = 		 		smithing.researchPanel
keyboardConstants.researchChooseItemDialog  = 	SMITHING_RESEARCH_SELECT

--Enchanting
keyboardConstants.enchantingClass = 			ZO_Enchanting
keyboardConstants.enchanting = 					ENCHANTING

--Alchemy
keyboardConstants.alchemy = 					ALCHEMY
keyboardConstants.alchemyScene  =				ALCHEMY_SCENE
keyboardConstants.alchemyCtrl = 				keyboardConstants.alchemy.control

--Retrait
--keyboardConstants.retraitClass  = 		  	 ZO_RetraitStation_Retrait_Base
keyboardConstants.retrait  = 				 	ZO_RETRAIT_KEYBOARD

--Reconstruction
keyboardConstants.reconstruct = 				ZO_RECONSTRUCT_KEYBOARD

------------------------------------------------------------------------------------------------------------------------
--Gamepad constants
------------------------------------------------------------------------------------------------------------------------
--gamepadConstants
--[Inventories]
--Inventory
gamepadConstants.playerInvCtrl_GP = keyboardConstants.playerInvCtrl

--Backpack
gamepadConstants.invBackpack_GP =				GAMEPAD_INVENTORY
gamepadConstants.invGuildBank_GP = 				GAMEPAD_GUILD_BANK
gamepadConstants.invRootScene = 				GAMEPAD_INVENTORY_ROOT_SCENE

--Character
gamepadConstants.characterCtrl_GP = 			keyboardConstants.characterCtrl


--Craftbag
--gamepadConstants.invCraftbag_GP =				inventories[invTypeCraftBag] --TODO: test if GP craftbag still works. Else uncomment and re-add to LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[true] again

--Quest items
gamepadConstants.invQuests_GP =					gamepadConstants.invBackpack_GP.scene

--Quickslots
--gamepadConstants.quickslots_GP =				GAMEPAD_QUICKSLOT					--TODO: remove? Quickslots for gamepad are handled differently


--[Banks]
--Player bank
gamepadConstants.invBank_GP = 					GAMEPAD_BANKING
--deposit: See custom gamepad fragments
--withdraw: Uses same as keyboard

--Guild bank
gamepadConstants.invGuildBankDepositScene_GP =  GAMEPAD_GUILD_BANK_SCENE
--deposit: See custom gamepad fragments
--withdraw: Uses same as keyboard

--House bank
--Control/scene is same as normal player bank
--deposit: See custom gamepad fragments
--withdraw: Uses same as keyboard


--[Vendor]
----Buy
gamepadConstants.store_GP = 					STORE_WINDOW_GAMEPAD
gamepadConstants.vendorBuy_GP = 				ZO_GamepadStoreBuy 			--store_GP.components[ZO_MODE_STORE_BUY].list
---Sell
gamepadConstants.vendorSell_GP = 				ZO_GamepadStoreSell 		--store_GP.components[ZO_MODE_STORE_SELL].list
---Buy back
gamepadConstants.vendorBuyBack_GP = 			ZO_GamepadStoreBuyback 		--store_GP.components[ZO_MODE_STORE_BUY_BACK].list
---Repair
gamepadConstants.vendorRepair_GP =				ZO_GamepadStoreRepair 		--store_GP.components[ZO_MODE_STORE_REPAIR].list


--[Fence]
keyboardConstants.fence = 						FENCE_GAMEPAD
--Fence launder
gamepadConstants.invFenceLaunder_GP =			ZO_GamepadFenceLaunder

--Fence sell
gamepadConstants.invFenceSell_GP =				ZO_GamepadFenceSell


--[Guild store]
--gamepadConstants.guildStoreBuy_GP			--not supported by LibFilters yet
gamepadConstants.invGuildStoreSell_GP =			GAMEPAD_TRADING_HOUSE_SELL
gamepadConstants.invGuildStoreSellScene_GP =  	TRADING_HOUSE_GAMEPAD_SCENE



--[Mail]
gamepadConstants.invMailSendScene_GP = 			SM:GetScene("mailManagerGamepad")
gamepadConstants.invMailSend_GP = 				MAIL_MANAGER_GAMEPAD.send


--[Player 2 player trade]
gamepadConstants.invPlayerTradeScene_GP = 		SM:GetScene("gamepadTrade")
gamepadConstants.invPlayerTrade_GP = 			GAMEPAD_TRADE


--[Companion]
gamepadConstants.companionEquipment_GP = 		COMPANION_EQUIPMENT_GAMEPAD
gamepadConstants.companionCharacterCtrl_GP =    ZO_Companion_Gamepad_TopLevel --TODO is this the correct for gamepad mode?


--[Crafting]
gamepadConstants.smithing_GP = 					SMITHING_GAMEPAD
local smithing_GP = gamepadConstants.smithing_GP

--Refinement
gamepadConstants.refinementPanel_GP =	  		smithing_GP.refinementPanel

--Create
gamepadConstants.creationPanel_GP =	  			smithing_GP.creationPanel

--Deconstruction
gamepadConstants.deconstructionPanel_GP = 		smithing_GP.deconstructionPanel

--Improvement
gamepadConstants.improvementPanel_GP = 			smithing_GP.improvementPanel

--Research
gamepadConstants.researchPanel_GP =				smithing_GP.researchPanel
gamepadConstants.researchChooseItemDialog_GP= 	GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE

--Enchanting
gamepadConstants.enchanting_GP =				GAMEPAD_ENCHANTING
gamepadConstants.enchantingCreate_GP = 			GAMEPAD_ENCHANTING_CREATION_SCENE
gamepadConstants.enchantingExtract_GP = 		GAMEPAD_ENCHANTING_EXTRACTION_SCENE
gamepadConstants.enchantingInvCtrls_GP =		{
	[ENCHANTING_MODE_CREATION] = 	GAMEPAD_ENCHANTING_CREATION_SCENE,
	[ENCHANTING_MODE_EXTRACTION] = 	GAMEPAD_ENCHANTING_EXTRACTION_SCENE,
	[ENCHANTING_MODE_RECIPES] = 	nil, --recipesgot no own scene, maybe a fragment?
}

--Alchemy
gamepadConstants.alchemy_GP = 					GAMEPAD_ALCHEMY
gamepadConstants.alchemySecene_GP = 			ALCHEMY_SCENE
gamepadConstants.alchemyCtrl_GP = 				gamepadConstants.alchemy_GP.control

--Retrait
gamepadConstants.retrait_GP = 					ZO_RETRAIT_STATION_RETRAIT_GAMEPAD

--Reconstruction
gamepadConstants.reconstruct_GP = 				ZO_RETRAIT_STATION_RECONSTRUCT_GAMEPAD


------------------------------------------------------------------------------------------------------------------------
--Custom created fragments -> See file /Gamepad/gamepadCustomFragments.lua
-----------------------------------------------------------------------------------------------------------------------
--They will be nil (see table gamepadConstants.customFragments[LF_*] = {name=..., fragment=nil}) here at the time
--constant.lua is parsed as the custom gamepad fragments were not created yet!
--> The file /Gamepad/gamepadCustomFragments.lua needs some constants for this file first!
---->But they will be added later to the constants table "gamepadConstants", as they were created in file
---->/Gamepad/gamepadCustomFragments.lua table customFragmentsUpdateRef
-->Important: The variables are updated to table libFilters.LF_ConstantToAdditionalFilterControlSceneFragmentUserdata,
-->which is used for libFilters:HookAdditionalFilters!

--The custom fragment names for the filter panelId in gamepad mode, used in file /Gamepad/gamepadCustomFragments.lua
-->The fragment=nil will be updated from file /Gamepad/GamepadCustomFragments.lua later on
gamepadConstants.customFragments = {
	[LF_INVENTORY] 		= 		{name = fragmentPrefix_GP .. "BACKPACK_INVENTORY_GAMEPAD_FRAGMENT", 			fragment=nil},
	[LF_BANK_DEPOSIT] 	= 		{name = fragmentPrefix_GP .. "BACKPACK_BANK_DEPOSIT_GAMEPAD_FRAGMENT", 			fragment=nil},
	[LF_HOUSE_BANK_DEPOSIT] = 	{name = fragmentPrefix_GP .. "BACKPACK_HOUSE_BANK_DEPOSIT_GAMEPAD_FRAGMENT",	fragment=nil},
	[LF_GUILDBANK_DEPOSIT] = 	{name = fragmentPrefix_GP .. "BACKPACK_GUILD_BANK_DEPOSIT_GAMEPAD_FRAGMENT", 	fragment=nil},
	[LF_GUILDSTORE_SELL] = 		{name = fragmentPrefix_GP .. "BACKPACK_TRADING_HOUSE_SELL_GAMEPAD_FRAGMENT", 	fragment=nil},
	[LF_MAIL_SEND] = 			{name = fragmentPrefix_GP .. "BACKPACK_MAIL_SEND_GAMEPAD_FRAGMENT", 			fragment=nil},
	[LF_TRADE] = 				{name = fragmentPrefix_GP .. "BACKPACK_PLAYER_TRADE_GAMEPAD_FRAGMENT", 			fragment=nil},
}
--local customFragments_GP = gamepadConstants.customFragments

------------------------------------------------------------------------------------------------------------------------
--Gamepad dynamic "INVENTORY" update functions
------------------------------------------------------------------------------------------------------------------------
--Will be filled in file LibFilters-3.0.lua, see "--Update functions for the gamepad inventory"
gamepadConstants.InventoryUpdateFunctions = {}


------------------------------------------------------------------------------------------------------------------------
--MAPPING
------------------------------------------------------------------------------------------------------------------------
libFilters.mapping = {}
local mapping = libFilters.mapping

--[Mapping for filter type to filter function type: inventorySlot or crafting with bagId, slotIndex]
--Constants of the possible filter function types of LibFilters
libFilters.constants.LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT = 1
local LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT = libFilters.constants.LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT
libFilters.constants.LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX = 2
local LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX = libFilters.constants.LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX

libFilters.mapping.filterTypeToFilterFunctionType = {}
local filterTypeToFilterFunctionType = libFilters.mapping.filterTypeToFilterFunctionType
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
libFilters.mapping.filterTypesUsingBagIdAndSlotIndexFilterFunction = filterTypesUsingBagIdAndSlotIndexFilterFunction
--Add them to the table libFilters.mapping.filterTypeToFilterFunctionType
for filterTypeValue, _  in pairs(filterTypesUsingBagIdAndSlotIndexFilterFunction) do
	filterTypeToFilterFunctionType[filterTypeValue] = LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX
end
--Now add all other missing filterTypes which were not added yet, with the constant LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT
libFilters.mapping.filterTypesUsingInventorySlotFilterFunction = {}
for filterTypeValue, _  in pairs(libFiltersFilterConstants) do
	if filterTypeToFilterFunctionType[filterTypeValue] == nil then
		filterTypeToFilterFunctionType[filterTypeValue] = LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT
		libFilters.mapping.filterTypesUsingInventorySlotFilterFunction[filterTypeValue] = true
	end
end



--[Mapping for crafting]
--Enchaning (used to determine the correct LF_* filterType constant at enchanting tables, as they share the same inventory
--ENCHANTING.inventory. Gamepad mode uses different scenes for enchating creation and extraction so there are used
--callbacks to these scenes' state to se the appropriate LF_ENCHANTING_* constant
-->Used in function LibFilters:HookAdditionalFilterSpecial(specialType, inventory)
--[[
local enchantingModeToFilterType = {
	 [ENCHANTING_MODE_CREATION]		= LF_ENCHANTING_CREATION,
	 [ENCHANTING_MODE_EXTRACTION]	= LF_ENCHANTING_EXTRACTION,
	 [ENCHANTING_MODE_RECIPES]		= nil --not supported yet
}
mapping.enchantingModeToFilterType = enchantingModeToFilterType
]]
--[Mapping LibFilters LF* constants not being hooked normal -> Special functions used]
local standardSpecialHookFunc = 		"HookAdditionalFilterSpecial" 		--LibFilters:HookAdditionalFilterSpecial
local standardSceneSpecialHookFunc = 	"HookAdditionalFilterSceneSpecial"	--LibFilters:HookAdditionalFilterSceneSpecial

-->The mapping between the LF_* filterType constant and a LibFilters function name (funcName of _G["LibFilters"])
-->plus the parameters to pass to the function
-->Any entry with LF* in this table will NOT use LibFilters:HookAdditionalFilter below!
-->See mapping table table "LF_ConstantToAdditionalFilterControlSceneFragmentUserdata" below
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
-->the control, scene, fragment, userdata to use to store the .additionalFilters table addition to.
-->The controls/fragments/scenes can be many. Each entry in the value table will be applying .additionalFilters
-->Used in function LibFilters:HookAdditionalFilter(filterType_LF_Constant)
--
--> This table's gamepad entries of some fragments (custom created ones!) will be updated via file
--> /Gamepad/gamepadCustomFragments.lua,
--
--> Attention: Entries in helper.lua which relate to keyboard AND gamepad made will not hook both, keyboard and
--> gamepad mode! There will only be one hook then in this table, for keyboard OR gamepad mode! e.g.
--> LF_ENCHANTING_CREATION and _EXTRACTION use the gamepad scenes in helpers.lua -> ZO_Enchanting_DoesEnchantingItemPassFilter.
--> So the hook will be in the [true] subtable for gamepad mode!
--> LF_SMITHING_RESEARCH_DIALOG and LF_JEWELRY_RESEARCH_DIALOG use the keyboard control SMITHING_RESEARCH_SELECT in helpers.lua
--> ZO_SharedSmithingResearch.IsResearchableItem. So the hook will be in the [false] subtable for keyboard mode!
local LF_ConstantToAdditionalFilterControlSceneFragmentUserdata = {
	--Keyboard mode
	[false] = {
		[LF_INVENTORY]                = { invBackpack, keyboardConstants.invBackpackFragment },
		[LF_INVENTORY_QUEST]          = { keyboardConstants.invQuests },
		[LF_CRAFTBAG]                 = { keyboardConstants.invCraftbag },
		[LF_INVENTORY_COMPANION]      = { keyboardConstants.companionEquipment },
		[LF_QUICKSLOT]                = { keyboardConstants.quickslots },
		[LF_BANK_WITHDRAW]            = { keyboardConstants.invBankWithdraw },
		[LF_BANK_DEPOSIT]             = { keyboardConstants.invBankDeposit },
		[LF_GUILDBANK_WITHDRAW]       = { keyboardConstants.invGuildBankWithdraw },
		[LF_GUILDBANK_DEPOSIT]        = { keyboardConstants.invGuildBankDeposit },
		[LF_HOUSE_BANK_WITHDRAW]      = { keyboardConstants.invHouseBankWithdraw },
		[LF_HOUSE_BANK_DEPOSIT]       = { keyboardConstants.invHouseBankDeposit },
		[LF_VENDOR_BUY]               = { keyboardConstants.store },
		[LF_VENDOR_SELL]              = { keyboardConstants.vendorSell },
		[LF_VENDOR_BUYBACK]           = { keyboardConstants.vendorBuyBack },
		[LF_VENDOR_REPAIR]            = { keyboardConstants.vendorRepair },
		[LF_FENCE_SELL]               = { keyboardConstants.invFenceSell },
		[LF_FENCE_LAUNDER]            = { keyboardConstants.invFenceLaunder },
		[LF_GUILDSTORE_SELL]          = { keyboardConstants.guildStoreSell },
		[LF_MAIL_SEND]                = { keyboardConstants.mailSend },
		[LF_TRADE]                    = { keyboardConstants.player2playerTrade },
		[LF_SMITHING_RESEARCH_DIALOG] = { keyboardConstants.researchChooseItemDialog },
		[LF_JEWELRY_RESEARCH_DIALOG]  = { keyboardConstants.researchChooseItemDialog },


		--Not implemented yet
		[LF_GUILDSTORE_BROWSE] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_COOK]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_BREW]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages


		--Shared with gamepad mode -> See entry with LF_* at [true] (using gamepadConstants) below
		[LF_SMITHING_REFINE]          = { keyboardConstants.refinementPanel },
		[LF_SMITHING_DECONSTRUCT]     = { keyboardConstants.deconstructionPanel },
		[LF_SMITHING_IMPROVEMENT]     = { keyboardConstants.improvementPanel },
		[LF_SMITHING_RESEARCH]        = { keyboardConstants.researchPanel },
		[LF_JEWELRY_REFINE]           = { keyboardConstants.refinementPanel },
		[LF_JEWELRY_DECONSTRUCT]      = { keyboardConstants.deconstructionPanel },
		[LF_JEWELRY_IMPROVEMENT]      = { keyboardConstants.improvementPanel },
		[LF_JEWELRY_RESEARCH]         = { keyboardConstants.researchPanel },
		[LF_ALCHEMY_CREATION]         = { keyboardConstants.alchemyScene },
		[LF_RETRAIT]                  = { keyboardConstants.retrait },


		--Special entries, see table LF_ConstantToAdditionalFilterSpecialHook above!
		-->Currently disalbed as the Gamepad mode Scenes for enchatning create/extract are used to store the filters in
		-->.additionalFilter and the helper function ZO_Enchanting_DoesEnchantingItemPassFilter will be used to read the
		-->scenes for both, keyboard AND gamepad mode
		 --implemented special, leave empty (not NIL!) to prevent error messages
		[LF_ENCHANTING_CREATION]	  = {  },
		[LF_ENCHANTING_EXTRACTION]    = {  },
	},

	--Gamepad mode
	[true]  = {
		[LF_INVENTORY_QUEST]          = { gamepadConstants.invQuests_GP },
		[LF_INVENTORY_COMPANION]      = { gamepadConstants.companionEquipment_GP },
		[LF_VENDOR_BUY]               = { gamepadConstants.vendorBuy_GP },
		[LF_VENDOR_SELL]              = { gamepadConstants.vendorSell_GP },
		[LF_VENDOR_BUYBACK]           = { gamepadConstants.vendorBuyBack_GP },
		[LF_VENDOR_REPAIR]            = { gamepadConstants.vendorRepair_GP },
		[LF_FENCE_SELL]               = { gamepadConstants.invFenceSell_GP },
		[LF_FENCE_LAUNDER]            = { gamepadConstants.invFenceLaunder_GP },
		[LF_SMITHING_RESEARCH_DIALOG] = { gamepadConstants.researchChooseItemDialog_GP },
		[LF_JEWELRY_RESEARCH_DIALOG]  = { gamepadConstants.researchChooseItemDialog_GP }, --duplicate needed compared to LF_SMITHING_RESEARCH_DIALOG ?


		--Not given in gamepad mode
		[LF_QUICKSLOT]                = {  }, --not in gamepad mode -> quickslots are added directly from type lists. collections>mementos, collections>mounts, inventory>consumables, ... -- leave empty (not NIL!) to prevent error messages


		--Not implemented yet
		[LF_GUILDSTORE_BROWSE] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_COOK]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_BREW]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages


		--Updated with correct fragment in file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_INVENTORY]                = { }, --uses fragment
		[LF_BANK_DEPOSIT]             = { }, --uses fragment
		[LF_GUILDBANK_DEPOSIT]        = { }, --uses fragment
		[LF_HOUSE_BANK_DEPOSIT]       = { }, --uses fragment
		[LF_GUILDSTORE_SELL]          = { }, --uses fragment
		[LF_MAIL_SEND]                = { }, --uses fragment
		[LF_TRADE]                    = { }, --uses fragment


		--Shared with keyboard mode -> See entry with LF_* at [false] (using keyboardConstants) above
		-->Will only be hooked in keyboard mode call (HookAdditioalFilter will be called with keyboard AND gamepad mode
		-->once as this library is loaded. Calling libFilters:HookAdditinalFilter later on checks for the current gamepad
		--> or keyboard mode, and only hook the active one!
		 --implemented special, leave empty (not NIL!) to prevent error messages
		[LF_CRAFTBAG]                 = {  }, --todo: test if this works, or add "gamepadConstants.invCraftbag_GP" again above!
		[LF_BANK_WITHDRAW]            = {  },
		[LF_GUILDBANK_WITHDRAW]       = {  },
		[LF_HOUSE_BANK_WITHDRAW]      = {  },
		[LF_SMITHING_REFINE]          = {  }, --todo: test if this works, or add "gamepadConstants.refinementPanel_GP" again above!
		[LF_SMITHING_DECONSTRUCT]     = {  },
		[LF_SMITHING_IMPROVEMENT]     = {  },
		[LF_SMITHING_RESEARCH]        = {  },
		[LF_JEWELRY_REFINE]           = {  },
		[LF_JEWELRY_DECONSTRUCT]      = {  },
		[LF_JEWELRY_IMPROVEMENT]      = {  },
		[LF_JEWELRY_RESEARCH]         = {  },
		[LF_ALCHEMY_CREATION]         = {  },
		[LF_RETRAIT]                  = {  },


		--Normally these are special hooks in table LF_ConstantToAdditionalFilterSpecialHook.
		--But currently they are changed to be normal entries using HookAdditionalFilter for now, to hook the scenes
		--and add .additionalFilter, used in helpers ZO_Enchanting_DoesEnchantingItemPassFilter
		-->Used for gamepad AND keyboard mode with these entries here !!!
		[LF_ENCHANTING_CREATION]	  = {gamepadConstants.enchantingCreate_GP},
		[LF_ENCHANTING_EXTRACTION]    = {gamepadConstants.enchantingExtract_GP},
	},
}
mapping.LF_ConstantToAdditionalFilterControlSceneFragmentUserdata = LF_ConstantToAdditionalFilterControlSceneFragmentUserdata

--The mapping table containing the "lookup" data of control or scene/fragment to us for "is hidden" checks
local filterTypeToCheckControlOrSceneFragmentIsHidden = {
--Keyboard mode
	[false] = {
		[LF_INVENTORY]                = { ["control"] = invBackpack, ["scene"] = nil, ["fragment"] = keyboardConstants.invBackpackFragment },
		[LF_INVENTORY_QUEST]          = { ["control"] = keyboardConstants.invQuests, ["scene"] = nil, ["fragment"] = nil, },
		[LF_CRAFTBAG]                 = { ["control"] = keyboardConstants.invCraftbag, ["scene"] = nil, ["fragment"] = nil, },
		[LF_INVENTORY_COMPANION]      = { ["control"] = keyboardConstants.companionEquipment, ["scene"] = nil, ["fragment"] = nil, },
		[LF_QUICKSLOT]                = { ["control"] = keyboardConstants.quickslots, ["scene"] = nil, ["fragment"] = nil, },
		[LF_BANK_WITHDRAW]            = { ["control"] = keyboardConstants.invBankWithdraw, ["scene"] = nil, ["fragment"] = nil, },
		[LF_BANK_DEPOSIT]             = { ["control"] = keyboardConstants.invBankDeposit, ["scene"] = nil, ["fragment"] = nil, },
		[LF_GUILDBANK_WITHDRAW]       = { ["control"] = keyboardConstants.invGuildBankWithdraw, ["scene"] = nil, ["fragment"] = nil, },
		[LF_GUILDBANK_DEPOSIT]        = { ["control"] = keyboardConstants.invGuildBankDeposit, ["scene"] = nil, ["fragment"] = nil, },
		[LF_HOUSE_BANK_WITHDRAW]      = { ["control"] = keyboardConstants.invHouseBankWithdraw, ["scene"] = nil, ["fragment"] = nil, },
		[LF_HOUSE_BANK_DEPOSIT]       = { ["control"] = keyboardConstants.invHouseBankDeposit, ["scene"] = nil, ["fragment"] = nil, },
		[LF_VENDOR_BUY]               = { ["control"] = keyboardConstants.store, ["scene"] = nil, ["fragment"] = nil, },
		[LF_VENDOR_SELL]              = { ["control"] = keyboardConstants.vendorSell, ["scene"] = nil, ["fragment"] = nil, },
		[LF_VENDOR_BUYBACK]           = { ["control"] = keyboardConstants.vendorBuyBack, ["scene"] = nil, ["fragment"] = nil, },
		[LF_VENDOR_REPAIR]            = { ["control"] = keyboardConstants.vendorRepair, ["scene"] = nil, ["fragment"] = nil, },
		[LF_FENCE_SELL]               = { ["control"] = keyboardConstants.invFenceSell, ["scene"] = nil, ["fragment"] = nil, },
		[LF_FENCE_LAUNDER]            = { ["control"] = keyboardConstants.invFenceLaunder, ["scene"] = nil, ["fragment"] = nil, },
		[LF_GUILDSTORE_SELL]          = { ["control"] = keyboardConstants.guildStoreSell, ["scene"] = nil, ["fragment"] = nil, },
		[LF_MAIL_SEND]                = { ["control"] = keyboardConstants.mailSend, ["scene"] = nil, ["fragment"] = nil, },
		[LF_TRADE]                    = { ["control"] = keyboardConstants.player2playerTrade, ["scene"] = nil, ["fragment"] = nil, },
		[LF_SMITHING_RESEARCH_DIALOG] = { ["control"] = keyboardConstants.researchChooseItemDialog, ["scene"] = nil, ["fragment"] = nil, },
		[LF_JEWELRY_RESEARCH_DIALOG]  = { ["control"] = keyboardConstants.researchChooseItemDialog, ["scene"] = nil, ["fragment"] = nil, },


		--Not implemented yet
		[LF_GUILDSTORE_BROWSE] 		  = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_CREATION] 		  = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_CREATION] 		  = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_COOK]		  = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_BREW]		  = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages


		--Shared with gamepad mode -> See entry with LF_* at [true] (using gamepadConstants) below
		[LF_SMITHING_REFINE]          = { ["control"] = keyboardConstants.refinementPanel, ["scene"] = nil, ["fragment"] = nil, },
		[LF_SMITHING_DECONSTRUCT]     = { ["control"] = keyboardConstants.deconstructionPanel, ["scene"] = nil, ["fragment"] = nil, },
		[LF_SMITHING_IMPROVEMENT]     = { ["control"] = keyboardConstants.improvementPanel, ["scene"] = nil, ["fragment"] = nil, },
		[LF_SMITHING_RESEARCH]        = { ["control"] = keyboardConstants.researchPanel, ["scene"] = nil, ["fragment"] = nil, },
		[LF_JEWELRY_REFINE]           = { ["control"] = keyboardConstants.refinementPanel, ["scene"] = nil, ["fragment"] = nil, },
		[LF_JEWELRY_DECONSTRUCT]      = { ["control"] = keyboardConstants.deconstructionPanel, ["scene"] = nil, ["fragment"] = nil, },
		[LF_JEWELRY_IMPROVEMENT]      = { ["control"] = keyboardConstants.improvementPanel, ["scene"] = nil, ["fragment"] = nil, },
		[LF_JEWELRY_RESEARCH]         = { ["control"] = keyboardConstants.researchPanel, ["scene"] = nil, ["fragment"] = nil, },
		[LF_ALCHEMY_CREATION]         = { ["control"] = keyboardConstants.alchemyScene, ["scene"] = nil, ["fragment"] = nil, },
		[LF_RETRAIT]                  = { ["control"] = keyboardConstants.retrait, ["scene"] = nil, ["fragment"] = nil, },


		--Special entries, see table LF_ConstantToAdditionalFilterSpecialHook above!
		-->Currently disalbed as the Gamepad mode Scenes for enchatning create/extract are used to store the filters in
		-->.additionalFilter and the helper function ZO_Enchanting_DoesEnchantingItemPassFilter will be used to read the
		-->scenes for both, keyboard AND gamepad mode
		 --implemented special, leave empty (not NIL!) to prevent error messages
		[LF_ENCHANTING_CREATION]	  = { ["control"] = keyboardConstants.enchanting, ["scene"] = nil, ["fragment"] = nil, },
		[LF_ENCHANTING_EXTRACTION]    = { ["control"] = keyboardConstants.enchanting, ["scene"] = nil, ["fragment"] = nil, },
	},

	--Gamepad mode
	[true]  = {
		[LF_INVENTORY_QUEST]          = { ["control"] = nil, ["scene"] = gamepadConstants.invQuests_GP, ["fragment"] = nil, },
		[LF_INVENTORY_COMPANION]      = { ["control"] = nil, ["scene"] = gamepadConstants.companionEquipment_GP, ["fragment"] = nil, },
		[LF_VENDOR_BUY]               = { ["control"] = gamepadConstants.vendorBuy_GP, ["scene"] = nil, ["fragment"] = nil, },
		[LF_VENDOR_SELL]              = { ["control"] = gamepadConstants.vendorSell_GP, ["scene"] = nil, ["fragment"] = nil, },
		[LF_VENDOR_BUYBACK]           = { ["control"] = gamepadConstants.vendorBuyBack_GP, ["scene"] = nil, ["fragment"] = nil, },
		[LF_VENDOR_REPAIR]            = { ["control"] = gamepadConstants.vendorRepair_GP, ["scene"] = nil, ["fragment"] = nil, },
		[LF_FENCE_SELL]               = { ["control"] = gamepadConstants.invFenceSell_GP, ["scene"] = nil, ["fragment"] = nil, },
		[LF_FENCE_LAUNDER]            = { ["control"] = gamepadConstants.invFenceLaunder_GP, ["scene"] = nil, ["fragment"] = nil, },
		[LF_SMITHING_RESEARCH_DIALOG] = { ["control"] = nil, ["scene"] = gamepadConstants.researchChooseItemDialog_GP, ["fragment"] = nil, },
		[LF_JEWELRY_RESEARCH_DIALOG]  = { ["control"] = nil, ["scene"] = gamepadConstants.researchChooseItemDialog_GP, ["fragment"] = nil, },


		--Not given in gamepad mode
		[LF_QUICKSLOT]                = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --not in gamepad mode -> quickslots are added directly from type lists. collections>mementos, collections>mounts, inventory>consumables, ... -- leave empty (not NIL!) to prevent error messages


		--Not implemented yet
		[LF_GUILDSTORE_BROWSE] 		  = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_CREATION] 		  = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_CREATION] 		  = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_COOK]		  = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_BREW]		  = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages


		--Updated with correct fragment in file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_INVENTORY]                = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_BANK_DEPOSIT]             = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_GUILDBANK_DEPOSIT]        = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_HOUSE_BANK_DEPOSIT]       = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_GUILDSTORE_SELL]          = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_MAIL_SEND]                = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_TRADE]                    = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created


		[LF_CRAFTBAG]                 = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },
		[LF_BANK_WITHDRAW]            = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },
		[LF_GUILDBANK_WITHDRAW]       = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },
		[LF_HOUSE_BANK_WITHDRAW]      = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },
		[LF_SMITHING_REFINE]          = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },
		[LF_SMITHING_DECONSTRUCT]     = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },
		[LF_SMITHING_IMPROVEMENT]     = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },
		[LF_SMITHING_RESEARCH]        = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },
		[LF_JEWELRY_REFINE]           = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },
		[LF_JEWELRY_DECONSTRUCT]      = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },
		[LF_JEWELRY_IMPROVEMENT]      = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },
		[LF_JEWELRY_RESEARCH]         = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },
		[LF_ALCHEMY_CREATION]         = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },
		[LF_RETRAIT]                  = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },


		--Normally these are special hooks in table LF_ConstantToAdditionalFilterSpecialHook.
		--But currently they are changed to be normal entries using HookAdditionalFilter for now, to hook the scenes
		--and add .additionalFilter, used in helpers ZO_Enchanting_DoesEnchantingItemPassFilter
		-->Used for gamepad AND keyboard mode with these entries here !!!
		[LF_ENCHANTING_CREATION]	  = { ["control"] = nil, ["scene"] = gamepadConstants.enchantingCreate_GP, ["fragment"] = nil,},
		[LF_ENCHANTING_EXTRACTION]    = { ["control"] = nil, ["scene"] = gamepadConstants.enchantingExtract_GP, ["fragment"] = nil,},
	}
}
mapping.LF_FilterTypeToCheckControlOrSceneFragmentIsHidden = filterTypeToCheckControlOrSceneFragmentIsHidden


--[Mapping for filterTypes, to other filterTypes (dependend on crafting)]
mapping.filterTypeToFilterTypeRespectingCraftType = {
	[CRAFTING_TYPE_JEWELRYCRAFTING] = {
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

if isDebugginEnabled then dd("LIBRARY CONSTANTS FILE - END") end
