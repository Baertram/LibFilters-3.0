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
local getScene = SM.GetScene

--Local library variable
local libFilters = {}

------------------------------------------------------------------------------------------------------------------------
--Create global library constant LibFilters3
_G[GlobalLibName] = 		libFilters --global table LibFilters3
libFilters.name	            = MAJOR
libFilters.version          = MINOR
libFilters.globalLibName    = GlobalLibName
------------------------------------------------------------------------------------------------------------------------


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

if libFilters.debug then dd("LIBRARY CONSTANTS FILE - START") end


------------------------------------------------------------------------------------------------------------------------
libFilters.constants = {}
local constants = libFilters.constants

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
local updaterNamePrefix = GlobalLibName .. "_updateInventory_"
constants.updaterNamePrefix = updaterNamePrefix

------------------------------------------------------------------------------------------------------------------------
--ZOs / ESOUI CONSTANTS
------------------------------------------------------------------------------------------------------------------------
constants.keyboard = {}
--KeyboardConstants
local kbc 						= constants.keyboard

constants.gamepad    = {}
--GamepadConstants
local gpc                      = constants.gamepad

--Custom created fragments for the gamepad mode
--Prefix of these fragments
gpc.customFragmentPrefix        = GlobalLibName:upper() .. "_" -- LIBFILTERS3_
local fragmentPrefix_GP         = gpc.customFragmentPrefix

------------------------------------------------------------------------------------------------------------------------
--CONSTANTS (*_GP is the gamepad mode constant, the others are commonly used with both, or keyboard only constants)
------------------------------------------------------------------------------------------------------------------------
--[Inventory types]
local invTypeBackpack           =	INVENTORY_BACKPACK
local invTypeQuest              = 	INVENTORY_QUEST_ITEM
local invTypeBank               =	INVENTORY_BANK
local invTypeGuildBank          =	INVENTORY_GUILD_BANK
local invTypeHouseBank 			=	INVENTORY_HOUSE_BANK
local invTypeCraftBag 			= 	INVENTORY_CRAFT_BAG
constants.inventoryTypes = {}
constants.inventoryTypes["player"] = 	invTypeBackpack
constants.inventoryTypes["quest"] = 		invTypeQuest
constants.inventoryTypes["bank"] = 		invTypeBank
constants.inventoryTypes["guild_bank"] = invTypeGuildBank
constants.inventoryTypes["house_bank"] = invTypeHouseBank
constants.inventoryTypes["craftbag"] = 	invTypeCraftBag


------------------------------------------------------------------------------------------------------------------------
--Keyboard constants
------------------------------------------------------------------------------------------------------------------------
--Inventory
kbc.playerInv                     = PLAYER_INVENTORY
local playerInv = kbc.playerInv
kbc.inventories                   = playerInv.inventories
local inventories                 = kbc.inventories
kbc.playerInvCtrl                 = ZO_PlayerInventory

--Character
kbc.characterCtrl                 =	ZO_Character

--Backpack
kbc.invBackpack                   = inventories[invTypeBackpack]
local invBackpack                 = kbc.invBackpack
kbc.invBackpackFragment           = BACKPACK_MENU_BAR_LAYOUT_FRAGMENT

--Craftbag
kbc.craftBagClass  				  = ZO_CraftBag
kbc.invCraftbag                   = inventories[invTypeCraftBag]

--Quest items
kbc.invQuests                     = inventories[invTypeQuest]

--Quickslots
kbc.quickslots                    = QUICKSLOT_WINDOW
kbc.quickslotsFragment            = QUICKSLOT_FRAGMENT


--[Banks]
--Player bank
kbc.invBankDeposit                = BACKPACK_BANK_LAYOUT_FRAGMENT
kbc.invBankWithdraw               = inventories[invTypeBank]

--Guild bank
kbc.invGuildBankDeposit           = BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT
kbc.invGuildBankWithdraw          = inventories[invTypeGuildBank]

--House bank
kbc.invHouseBankDeposit           = BACKPACK_HOUSE_BANK_LAYOUT_FRAGMENT
kbc.invHouseBankWithdraw          = inventories[invTypeHouseBank]

--[Vendor]
----Buy
kbc.store                         = STORE_WINDOW
---Sell
kbc.vendorBuy                     =	kbc.store
kbc.vendorBuyFragment			  = STORE_FRAGMENT
kbc.vendorSell                    = BACKPACK_STORE_LAYOUT_FRAGMENT
kbc.vendorSellInventoryFragment   = INVENTORY_FRAGMENT
---Buy back
kbc.vendorBuyBack                 = BUY_BACK_WINDOW
kbc.vendorBuyBackFragment		  = BUY_BACK_FRAGMENT
---Repair
kbc.vendorRepair                  = REPAIR_WINDOW
kbc.vendorRepairFragment          = REPAIR_FRAGMENT
kbc.storeWindows                  = {
	[ZO_MODE_STORE_BUY] = 			kbc.vendorBuy,
	[ZO_MODE_STORE_BUY_BACK] = 		kbc.vendorBuyBack,
	[ZO_MODE_STORE_SELL] = 			kbc.vendorSell, --TODO: Working?
	[ZO_MODE_STORE_REPAIR] = 		kbc.vendorRepair,
	[ZO_MODE_STORE_SELL_STOLEN] = 	kbc.vendorSell, --TODO: Working?
	[ZO_MODE_STORE_LAUNDER] = 		kbc.vendorSell, --TODO: Working?
	[ZO_MODE_STORE_STABLE] = 		kbc.vendorBuy,
}

--[Fence]
--Fence launder
kbc.fence                         = FENCE_KEYBOARD
kbc.invFenceLaunder               = BACKPACK_LAUNDER_LAYOUT_FRAGMENT

--Fence sell
kbc.invFenceSell                  = BACKPACK_FENCE_LAYOUT_FRAGMENT


--[Guild store]
kbc.guildStoreObj                 = ZO_TradingHouse
--keyboardConstants.guildStoreBuy = guildStoreBuy			--not supported by LibFilters yet
kbc.guildStoreSell                = BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT


--[Mail]
kbc.mailSendObj                   =	MAIL_SEND
kbc.mailSend                      =	BACKPACK_MAIL_LAYOUT_FRAGMENT

--[Player 2 player trade]
kbc.player2playerTradeObj         = TRADE --TRADE_WINDOW
kbc.player2playerTrade            = BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT


--[Companion]
kbc.companionEquipment            = COMPANION_EQUIPMENT_KEYBOARD
kbc.companionCharacterCtrl        = ZO_CompanionCharacterWindow_Keyboard_TopLevel


--[Crafting]
kbc.smithing                      = SMITHING
local smithing                    = kbc.smithing

--Refinement
kbc.refinementPanel               = smithing.refinementPanel

--Create
kbc.creationPanel                 = smithing.creationPanel

--Deconstruction
kbc.deconstructionPanel           = smithing.deconstructionPanel

--Improvement
kbc.improvementPanel              = smithing.improvementPanel

--Research
kbc.researchPanel                 = smithing.researchPanel
local researchPanel = kbc.researchPanel
kbc.researchChooseItemDialog      = SMITHING_RESEARCH_SELECT

--Enchanting
kbc.enchantingClass               = ZO_Enchanting
kbc.enchanting                    =	ENCHANTING

--Alchemy
kbc.alchemy                       =	ALCHEMY
kbc.alchemyScene                  =	ALCHEMY_SCENE
kbc.alchemyCtrl                   = kbc.alchemy.control

--Retrait
--keyboardConstants.retraitClass  = ZO_RetraitStation_Retrait_Base
kbc.retrait                       = ZO_RETRAIT_KEYBOARD

--Reconstruction
kbc.reconstruct                   =	ZO_RECONSTRUCT_KEYBOARD

------------------------------------------------------------------------------------------------------------------------
--Gamepad constants
------------------------------------------------------------------------------------------------------------------------
--gamepadConstants
--[Inventories]
--Inventory
gpc.playerInvCtrl_GP            = kbc.playerInvCtrl

--Backpack
gpc.invBackpack_GP              = GAMEPAD_INVENTORY
gpc.invGuildBank_GP             = GAMEPAD_GUILD_BANK
gpc.invRootScene                = GAMEPAD_INVENTORY_ROOT_SCENE

--Character
gpc.characterCtrl_GP            = kbc.characterCtrl


--Craftbag
--gamepadConstants.invCraftbag_GP =	inventories[invTypeCraftBag] --TODO: test if GP craftbag still works. Else uncomment and re-add to filterTypeToReference[true] again

--Quest items
gpc.invQuests_GP                = gpc.invBackpack_GP.scene

--Quickslots
--gamepadConstants.quickslots_GP = GAMEPAD_QUICKSLOT					--TODO: remove? Quickslots for gamepad are handled differently


--[Banks]
--Player bank
gpc.invBank_GP                  = GAMEPAD_BANKING
--deposit: See custom gamepad fragments
--withdraw: Uses same as keyboard

--Guild bank
gpc.invGuildBankDepositScene_GP = GAMEPAD_GUILD_BANK_SCENE
--deposit: See custom gamepad fragments
--withdraw: Uses same as keyboard

--House bank
--Control/scene is same as normal player bank
--deposit: See custom gamepad fragments
--withdraw: Uses same as keyboard


--[Vendor]
----Buy
gpc.store_GP                    = STORE_WINDOW_GAMEPAD
gpc.vendorBuy_GP                = ZO_GamepadStoreBuy 			--store_GP.components[ZO_MODE_STORE_BUY].list
---Sell
gpc.vendorSell_GP               = ZO_GamepadStoreSell 		--store_GP.components[ZO_MODE_STORE_SELL].list
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
--gamepadConstants.guildStoreBuy_GP			--not supported by LibFilters yet
gpc.invGuildStoreSell_GP        = GAMEPAD_TRADING_HOUSE_SELL
gpc.invGuildStoreSellScene_GP   = TRADING_HOUSE_GAMEPAD_SCENE



--[Mail]
gpc.invMailSendScene_GP         = getScene(SM, "mailManagerGamepad")
gpc.invMailSend_GP              = MAIL_MANAGER_GAMEPAD.send


--[Player 2 player trade]
gpc.invPlayerTradeScene_GP      = getScene(SM, "gamepadTrade")
gpc.invPlayerTrade_GP           = GAMEPAD_TRADE


--[Companion]
gpc.companionEquipment_GP       = COMPANION_EQUIPMENT_GAMEPAD
gpc.companionCharacterCtrl_GP   = ZO_Companion_Gamepad_TopLevel --TODO is this the correct for gamepad mode?


--[Crafting]
gpc.smithing_GP                 = SMITHING_GAMEPAD
local smithing_GP               = gpc.smithing_GP

--Refinement
gpc.refinementPanel_GP          = smithing_GP.refinementPanel

--Create
gpc.creationPanel_GP            = smithing_GP.creationPanel

--Deconstruction
gpc.deconstructionPanel_GP      = smithing_GP.deconstructionPanel

--Improvement
gpc.improvementPanel_GP         = smithing_GP.improvementPanel

--Research
gpc.researchPanel_GP            = smithing_GP.researchPanel
gpc.researchChooseItemDialog_GP = GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE

--Enchanting
gpc.enchanting_GP               = GAMEPAD_ENCHANTING
gpc.enchantingCreate_GP         = GAMEPAD_ENCHANTING_CREATION_SCENE
gpc.enchantingExtract_GP        = GAMEPAD_ENCHANTING_EXTRACTION_SCENE
gpc.enchantingInvCtrls_GP       = {
	[ENCHANTING_MODE_CREATION] = 	GAMEPAD_ENCHANTING_CREATION_SCENE,
	[ENCHANTING_MODE_EXTRACTION] = 	GAMEPAD_ENCHANTING_EXTRACTION_SCENE,
	[ENCHANTING_MODE_RECIPES] = 	nil, --recipesgot no own scene, maybe a fragment?
}

--Alchemy
gpc.alchemy_GP                  = GAMEPAD_ALCHEMY
gpc.alchemySecene_GP            = ALCHEMY_SCENE
gpc.alchemyCtrl_GP              = gpc.alchemy_GP.control

--Retrait
gpc.retrait_GP                  = ZO_RETRAIT_STATION_RETRAIT_GAMEPAD

--Reconstruction
gpc.reconstruct_GP              = ZO_RETRAIT_STATION_RECONSTRUCT_GAMEPAD


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
gpc.customFragments             = {
	[LF_INVENTORY] 		= 		{name = fragmentPrefix_GP .. "BACKPACK_INVENTORY_GAMEPAD_FRAGMENT", 			fragment=nil},
	[LF_BANK_DEPOSIT] 	= 		{name = fragmentPrefix_GP .. "BACKPACK_BANK_DEPOSIT_GAMEPAD_FRAGMENT", 			fragment=nil},
	[LF_HOUSE_BANK_DEPOSIT] = 	{name = fragmentPrefix_GP .. "BACKPACK_HOUSE_BANK_DEPOSIT_GAMEPAD_FRAGMENT",	fragment=nil},
	[LF_GUILDBANK_DEPOSIT] = 	{name = fragmentPrefix_GP .. "BACKPACK_GUILD_BANK_DEPOSIT_GAMEPAD_FRAGMENT", 	fragment=nil},
	[LF_GUILDSTORE_SELL] = 		{name = fragmentPrefix_GP .. "BACKPACK_TRADING_HOUSE_SELL_GAMEPAD_FRAGMENT", 	fragment=nil},
	[LF_MAIL_SEND] = 			{name = fragmentPrefix_GP .. "BACKPACK_MAIL_SEND_GAMEPAD_FRAGMENT", 			fragment=nil},
	[LF_TRADE] = 				{name = fragmentPrefix_GP .. "BACKPACK_PLAYER_TRADE_GAMEPAD_FRAGMENT", 			fragment=nil},
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
			--["objectRead"] 	= kbc.invCraftbag, --PLAYER_INVENTORY.inventories[INVENTORY_CRAFT_BAG]
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
		--from fragment BACKPACK_MENU_BAR_LAYOUT_FRAGMENT or others
		--each time, and thus we need to hook both
		[LF_INVENTORY]                = { kbc.invBackpackFragment, invBackpack },

		[LF_INVENTORY_QUEST]          = { kbc.invQuests },
		--PLAYER_INVENTORY.inventories[INVENTORY_CRAFT_BAG].additionalFilter gets updated each time from layoutData.additionalCraftBagFilter
		--as ZO_InventoryManager:ApplyBackpackLayout(layoutData) is called,
		[LF_CRAFTBAG]                 = { kbc.invBackpackFragment, kbc.invCraftbag },

		[LF_INVENTORY_COMPANION]      = { kbc.companionEquipment },
		[LF_QUICKSLOT]                = { kbc.quickslots },
		[LF_BANK_WITHDRAW]            = { kbc.invBankWithdraw },
		[LF_BANK_DEPOSIT]             = { kbc.invBankDeposit },
		[LF_GUILDBANK_WITHDRAW]       = { kbc.invGuildBankWithdraw },
		[LF_GUILDBANK_DEPOSIT]        = { kbc.invGuildBankDeposit },
		[LF_HOUSE_BANK_WITHDRAW]      = { kbc.invHouseBankWithdraw },
		[LF_HOUSE_BANK_DEPOSIT]       = { kbc.invHouseBankDeposit },
		[LF_VENDOR_BUY]               = { kbc.store },
		[LF_VENDOR_SELL]              = { kbc.vendorSell },
		[LF_VENDOR_BUYBACK]           = { kbc.vendorBuyBack },
		[LF_VENDOR_REPAIR]            = { kbc.vendorRepair },
		[LF_FENCE_SELL]               = { kbc.invFenceSell },
		[LF_FENCE_LAUNDER]            = { kbc.invFenceLaunder },
		[LF_GUILDSTORE_SELL]          = { kbc.guildStoreSell },
		[LF_MAIL_SEND]                = { kbc.mailSend },
		[LF_TRADE]                    = { kbc.player2playerTrade },
		[LF_SMITHING_RESEARCH_DIALOG] = { kbc.researchChooseItemDialog },
		[LF_JEWELRY_RESEARCH_DIALOG]  = { kbc.researchChooseItemDialog },


		--Not implemented yet
		[LF_GUILDSTORE_BROWSE] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_COOK]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_BREW]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages


		--Shared with gamepad mode -> See entry with LF_* at [true] (using gamepadConstants) below
		[LF_SMITHING_REFINE]          = { kbc.refinementPanel },
		[LF_SMITHING_DECONSTRUCT]     = { kbc.deconstructionPanel },
		[LF_SMITHING_IMPROVEMENT]     = { kbc.improvementPanel },
		[LF_SMITHING_RESEARCH]        = { kbc.researchPanel },
		[LF_JEWELRY_REFINE]           = { kbc.refinementPanel },
		[LF_JEWELRY_DECONSTRUCT]      = { kbc.deconstructionPanel },
		[LF_JEWELRY_IMPROVEMENT]      = { kbc.improvementPanel },
		[LF_JEWELRY_RESEARCH]         = { kbc.researchPanel },
		[LF_ALCHEMY_CREATION]         = { kbc.alchemyScene },
		[LF_RETRAIT]                  = { kbc.retrait },


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
		[LF_INVENTORY_QUEST]          = { gpc.invQuests_GP },
		[LF_INVENTORY_COMPANION]      = { gpc.companionEquipment_GP },
		[LF_VENDOR_BUY]               = { gpc.vendorBuy_GP },
		[LF_VENDOR_SELL]              = { gpc.vendorSell_GP },
		[LF_VENDOR_BUYBACK]           = { gpc.vendorBuyBack_GP },
		[LF_VENDOR_REPAIR]            = { gpc.vendorRepair_GP },
		[LF_FENCE_SELL]               = { gpc.invFenceSell_GP },
		[LF_FENCE_LAUNDER]            = { gpc.invFenceLaunder_GP },
		[LF_SMITHING_RESEARCH_DIALOG] = { gpc.researchChooseItemDialog_GP },
		[LF_JEWELRY_RESEARCH_DIALOG]  = { gpc.researchChooseItemDialog_GP }, --duplicate needed compared to LF_SMITHING_RESEARCH_DIALOG ?


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
		[LF_ENCHANTING_CREATION]	  = { gpc.enchantingCreate_GP},
		[LF_ENCHANTING_EXTRACTION]    = { gpc.enchantingExtract_GP},
	},
}
mapping.LF_FilterTypeToReference = filterTypeToReference

--The mapping table containing the "lookup" data of control or scene/fragment to us for "is hidden" checks
--The control must be a control with IsHidden() function or a .control subtable with that function
--The scene needs to be a scene name or scene variable with the .state attribute
--The fragment needs to be a fragment name or fragment variable with the .state and .sceneManager attributes
--Special entries can be added for dynamically done checks -> See LibFilters-3.0.lua, function isSpecialTrue(filterType, isInGamepadMode, ...)
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
local filterTypeToCheckIfReferenceIsHidden = {
--Keyboard mode
	[false] = {
		--Works: 2021-12-13
		[LF_INVENTORY]                = { ["control"] = invBackpack, 					["scene"] = nil, 					["fragment"] = kbc.invBackpackFragment },
		[LF_INVENTORY_QUEST]          = { ["control"] = kbc.invQuests, 					["scene"] = nil, 					["fragment"] = nil, },
		--TODO - Does not detect properly: 2021-12-13
		[LF_CRAFTBAG]                 = { ["control"] = kbc.invCraftbag, 				["scene"] = nil, 					["fragment"] = nil, },
		[LF_INVENTORY_COMPANION]      = { ["control"] = kbc.companionEquipment, 		["scene"] = nil, 					["fragment"] = nil, },
		[LF_QUICKSLOT]                = { ["control"] = kbc.quickslots, 				["scene"] = nil, 					["fragment"] = kbc.quickslotsFragment, },
		[LF_BANK_WITHDRAW]            = { ["control"] = kbc.invBankWithdraw, 			["scene"] = nil, 					["fragment"] = nil, },
		[LF_BANK_DEPOSIT]             = { ["control"] = kbc.invBankDeposit, 			["scene"] = "bank", 				["fragment"] = nil, },
		[LF_GUILDBANK_WITHDRAW]       = { ["control"] = kbc.invGuildBankWithdraw, 		["scene"] = nil, 					["fragment"] = nil, },
		[LF_GUILDBANK_DEPOSIT]        = { ["control"] = kbc.invGuildBankDeposit, 		["scene"] = "guildBank", 			["fragment"] = nil, },
		[LF_HOUSE_BANK_WITHDRAW]      = { ["control"] = kbc.invHouseBankWithdraw, 		["scene"] = nil, 					["fragment"] = nil, },
		[LF_HOUSE_BANK_DEPOSIT]       = { ["control"] = kbc.invHouseBankDeposit, 		["scene"] = "houseBank", 			["fragment"] = nil, },
		[LF_VENDOR_BUY]               = { ["control"] = kbc.store, 						["scene"] = "store", 				["fragment"] = kbc.vendorBuyFragment, },
		[LF_VENDOR_SELL]              = { ["control"] = invBackpack, 					["scene"] = "store", 				["fragment"] = kbc.vendorSellInventoryFragment, },
		[LF_VENDOR_BUYBACK]           = { ["control"] = kbc.vendorBuyBack,				["scene"] = "store", 				["fragment"] = kbc.vendorBuyBackFragment, },
		[LF_VENDOR_REPAIR]            = { ["control"] = kbc.vendorRepair, 				["scene"] = "store", 				["fragment"] = kbc.vendorRepairFragment, },
		--Works: 2021-12-13
		[LF_FENCE_SELL]               = { ["control"] = kbc.fence, 						["scene"] = "fence_keyboard",		["fragment"] = kbc.invFenceSell, },
		--Works: 2021-12-13
		[LF_FENCE_LAUNDER]            = { ["control"] = kbc.fence, 						["scene"] = "fence_keyboard", 		["fragment"] = kbc.invFenceLaunder, },
		--Works: 2021-12-13
		[LF_GUILDSTORE_SELL]          = { ["control"] = kbc.guildStoreObj, 				["scene"] = "tradinghouse", 		["fragment"] = kbc.guildStoreSell, },
		--Works: 2021-12-13
		[LF_MAIL_SEND]                = { ["control"] = kbc.mailSendObj, 				["scene"] = "mailSend", 			["fragment"] = kbc.mailSend, },
		--Works: 2021-12-13
		[LF_TRADE]                    = { ["control"] = kbc.player2playerTradeObj, 		["scene"] = "trade", 				["fragment"] = kbc.player2playerTrade, },
		--TODO - Does not detect properly: 2021-12-13
		[LF_SMITHING_RESEARCH_DIALOG] = { ["controlDialog"] = kbc.researchPanel.control, 	["scene"] = "smithing", 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {false},
												}
											}
		},
		[LF_JEWELRY_RESEARCH_DIALOG]  = { ["controlDialog"] = kbc.researchPanel.control,	["scene"] = "smithing",	 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},


		--Not implemented yet
		[LF_GUILDSTORE_BROWSE] 		  = { ["control"] = nil, 							["scene"] = nil, 					["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_CREATION] 		  = { ["control"] = nil, 							["scene"] = nil, 					["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_CREATION] 		  = { ["control"] = nil, 							["scene"] = nil, 					["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_COOK]		  = { ["control"] = nil, 							["scene"] = nil, 					["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_BREW]		  = { ["control"] = nil,							["scene"] = nil, 					["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages

		--Works: 2021-12-13
		[LF_SMITHING_REFINE]          = { ["control"] = kbc.refinementPanel, 			["scene"] = "smithing", 			["fragment"] = nil,
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
		[LF_SMITHING_DECONSTRUCT]     = { ["control"] = kbc.deconstructionPanel, 		["scene"] = "smithing", 			["fragment"] = nil,
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
		[LF_SMITHING_IMPROVEMENT]     = { ["control"] = kbc.improvementPanel, 			["scene"] = "smithing", 			["fragment"] = nil,
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
		[LF_SMITHING_RESEARCH]        = { ["control"] = kbc.researchPanel, 				["scene"] = "smithing", 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {false},
												}
											}
		},
		[LF_JEWELRY_REFINE]           = { ["control"] = kbc.refinementPanel, 			["scene"] = "smithing", 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		[LF_JEWELRY_DECONSTRUCT]      = { ["control"] = kbc.deconstructionPanel, 		["scene"] = "smithing", 			["fragment"] = nil,
												   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		[LF_JEWELRY_IMPROVEMENT]      = { ["control"] = kbc.improvementPanel, 			["scene"] = "smithing",	 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		[LF_JEWELRY_RESEARCH]         = { ["control"] = kbc.researchPanel, 				["scene"] = "smithing", 			["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  _G[GlobalLibName],
													["funcOrAttribute"] = "IsJewelryCrafting",
													["params"] = {_G[GlobalLibName]},
													["expectedResults"] = {true},
												}
											}
		},
		[LF_ALCHEMY_CREATION]		  = { ["control"] = kbc.alchemy, 					["scene"] = kbc.alchemyScene, 		["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  kbc.alchemy,
													["funcOrAttribute"] = "mode",
													["params"] = {},
													["expectedResults"] = {ZO_ALCHEMY_MODE_CREATION},
												}
											}
		},
		[LF_RETRAIT]                  = { ["control"] = kbc.retrait, 					["scene"] = nil, 					["fragment"] = nil, },
		[LF_ENCHANTING_CREATION]	  = { ["control"] = kbc.enchanting, 				["scene"] = "enchanting", 			["fragment"] = nil,
										  ["special"] = {
											  [1] = {
												  ["control"]  =  kbc.enchanting,
												  ["funcOrAttribute"] = "GetEnchantingMode",
												  ["params"] = {kbc.enchanting},
												  ["expectedResults"] = {ENCHANTING_MODE_CREATION},
											  }
										  }
		},
		[LF_ENCHANTING_EXTRACTION]	  = { ["control"] = kbc.enchanting, 				["scene"] = "enchanting", 			["fragment"] = nil,
											["special"] = {
												[1] = {
													["control"]  =  kbc.enchanting,
													["funcOrAttribute"] = "GetEnchantingMode",
													["params"] = {kbc.enchanting},
													["expectedResults"] = {ENCHANTING_MODE_EXTRACTION},
												}
											}
		},
	},
	--Gamepad mode
	[true]  = {
		[LF_INVENTORY_QUEST]          = { ["control"] = nil, 							["scene"] = gpc.invQuests_GP, 		["fragment"] = nil, },
		[LF_INVENTORY_COMPANION]      = { ["control"] = nil, 							["scene"] = gpc.companionEquipment_GP, ["fragment"] = nil, },
		[LF_VENDOR_SELL]              = { ["control"] = gpc.vendorSell_GP, 				["scene"] = nil,	 				["fragment"] = nil, },
		[LF_VENDOR_BUYBACK]           = { ["control"] = gpc.vendorBuyBack_GP, 			["scene"] = nil, 					["fragment"] = nil, },
		[LF_VENDOR_REPAIR]            = { ["control"] = gpc.vendorRepair_GP, 			["scene"] = nil, 					["fragment"] = nil, },
		[LF_FENCE_SELL]               = { ["control"] = gpc.invFenceSell_GP, 			["scene"] = nil, 					["fragment"] = nil, },
		[LF_FENCE_LAUNDER]            = { ["control"] = gpc.invFenceLaunder_GP, 		["scene"] = nil, 					["fragment"] = nil, },
		[LF_SMITHING_RESEARCH_DIALOG] = { ["control"] = nil, 							["scene"] = gpc.researchChooseItemDialog_GP, ["fragment"] = nil, },
		[LF_JEWELRY_RESEARCH_DIALOG]  = { ["control"] = nil, 							["scene"] = gpc.researchChooseItemDialog_GP, ["fragment"] = nil, },


		--Not given in gamepad mode
		[LF_QUICKSLOT]                = { ["control"] = nil, 							["scene"] = nil, 					["fragment"] = nil, }, --not in gamepad mode -> quickslots are added directly from type lists. collections>mementos, collections>mounts, inventory>consumables, ... -- leave empty (not NIL!) to prevent error messages


		--Not implemented yet
		[LF_GUILDSTORE_BROWSE] 		  = { ["control"] = nil, 							["scene"] = nil, 					["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_CREATION] 		  = { ["control"] = nil, 							["scene"] = "gamepad_smithing_creation", ["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_CREATION] 		  = { ["control"] = nil, 							["scene"] = "gamepad_smithing_creation", ["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_COOK]		  = { ["control"] = nil, 							["scene"] = nil, 				["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_BREW]		  = { ["control"] = nil, 							["scene"] = nil, 				["fragment"] = nil, }, --not implemented yet, leave empty (not NIL!) to prevent error messages


		--Updated with correct fragment in file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_INVENTORY]                = { ["control"] = nil, 							["scene"] = nil, 				["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_BANK_DEPOSIT]             = { ["control"] = nil, 							["scene"] = nil, 				["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_GUILDBANK_DEPOSIT]        = { ["control"] = nil, 							["scene"] = "gamepad_guild_bank", ["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_HOUSE_BANK_DEPOSIT]       = { ["control"] = nil, 							["scene"] = nil, 				["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_GUILDSTORE_SELL]          = { ["control"] = nil, 							["scene"] = nil, 				["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_MAIL_SEND]                = { ["control"] = nil, 							["scene"] = nil, 				["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_TRADE]                    = { ["control"] = nil, 							["scene"] = nil, 				["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created


		[LF_CRAFTBAG]                 = { ["control"] = nil, 							["scene"] = nil, 				["fragment"] = nil, },
		[LF_BANK_WITHDRAW]            = { ["control"] = nil, 							["scene"] = nil, 				["fragment"] = nil, },
		[LF_GUILDBANK_WITHDRAW]       = { ["control"] = nil, 							["scene"] = nil, 				["fragment"] = nil, },
		[LF_HOUSE_BANK_WITHDRAW]      = { ["control"] = nil, 							["scene"] = nil, 				["fragment"] = nil, },
		[LF_SMITHING_REFINE]          = { ["control"] = nil, 							["scene"] = "gamepad_smithing_refine", ["fragment"] = nil, },
		[LF_SMITHING_DECONSTRUCT]     = { ["control"] = nil, 							["scene"] = "gamepad_smithing_deconstruct", ["fragment"] = nil, },
		[LF_SMITHING_IMPROVEMENT]     = { ["control"] = nil, 							["scene"] = "gamepad_smithing_improvement", ["fragment"] = nil, },
		[LF_SMITHING_RESEARCH]        = { ["control"] = nil, 							["scene"] = "gamepad_smithing_research", ["fragment"] = nil, },
		[LF_JEWELRY_REFINE]           = { ["control"] = nil, 							["scene"] = "gamepad_smithing_refine", ["fragment"] = nil, },
		[LF_JEWELRY_DECONSTRUCT]      = { ["control"] = nil, 							["scene"] = "gamepad_smithing_deconstruct", ["fragment"] = nil, },
		[LF_JEWELRY_IMPROVEMENT]      = { ["control"] = nil, 							["scene"] = "gamepad_smithing_improvement", ["fragment"] = nil, },
		[LF_JEWELRY_RESEARCH]         = { ["control"] = nil, 							["scene"] = "gamepad_smithing_research", ["fragment"] = nil, },
		[LF_ALCHEMY_CREATION]	  	  = { ["control"] = gpc.alchemy_GP, 				["scene"] = gpc.alchemySecene_GP, ["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  gpc.alchemy_GP,
													["funcOrAttribute"] = "mode",
													["params"] = {},
													["expectedResults"] = {ZO_ALCHEMY_MODE_CREATION},
												}
											}
		},
		[LF_RETRAIT]                  = { ["control"] = nil, ["scene"] = nil, ["fragment"] = nil, },


		--Normally these are special hooks in table LF_ConstantToAdditionalFilterSpecialHook.
		--But currently they are changed to be normal entries using HookAdditionalFilter for now, to hook the scenes
		--and add .additionalFilter, used in helpers ZO_Enchanting_DoesEnchantingItemPassFilter
		-->Used for gamepad AND keyboard mode with these entries here !!!
		[LF_ENCHANTING_CREATION]	  = { ["control"] = gpc.enchanting_GP, 				["scene"] = gpc.enchantingCreate_GP, ["fragment"] = nil,
										  ["special"] = {
											  [1] = {
												  ["control"]  =  gpc.enchanting_GP,
												  ["funcOrAttribute"] = "GetEnchantingMode",
												  ["params"] = {gpc.enchanting_GP},
												  ["expectedResults"] = {ENCHANTING_MODE_CREATION},
											  }
										  }
		},
		[LF_ENCHANTING_EXTRACTION]	  = { ["control"] = gpc.enchanting_GP, 				["scene"] = gpc.enchantingExtract_GP, ["fragment"] = nil,
											["special"] = {
												[1] = {
													["control"]  =  gpc.enchanting_GP,
													["funcOrAttribute"] = "GetEnchantingMode",
													["params"] = {gpc.enchanting_GP},
													["expectedResults"] = {ENCHANTING_MODE_EXTRACTION},
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

	--From FCOItemSaver as example:
	--[[
		--The current game's SCENE and name (used for determining bank/guild bank deposit)
		local currentScene, currentSceneName = getCurrentSceneInfo()

		--Inside mail panel?
			--Inside trading player 2 player panel?
		elseif (filterType and filterType == LF_TRADE) or (not filterType and not ctrlVars.PLAYER_TRADE.control:IsHidden()) then
			filterTypeDetected = LF_TRADE
			--Are we at the store scene?
		elseif (filterType and (filterType == LF_VENDOR_BUY or filterType == LF_VENDOR_SELL or filterType == LF_VENDOR_BUYBACK or filterType == LF_VENDOR_REPAIR)) or (not filterType and isSceneFragmentShown(LF_VENDOR_SELL, isInGamepadMode)) then
			--Vendor buy
			if (filterType and filterType == LF_VENDOR_BUY) or (not filterType and ((not ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
				filterTypeDetected = LF_VENDOR_BUY
				--Vendor sell
			elseif (filterType and filterType == LF_VENDOR_SELL) or (not filterType and ((ctrlVars.STORE:IsHidden() and not ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
				filterTypeDetected = LF_VENDOR_SELL
				--Vendor buyback
			elseif (filterType and filterType == LF_VENDOR_BUYBACK) or (not filterType and ((ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and not ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
				filterTypeDetected = LF_VENDOR_BUYBACK
				--Vendor repair
			elseif (filterType and filterType == LF_VENDOR_REPAIR) or (not filterType and ((ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and not ctrlVars.REPAIR_LIST:IsHidden()))) then
				filterTypeDetected = LF_VENDOR_REPAIR
			end
			--Fence/Launder scene
		elseif (filterType and filterType == LF_FENCE_SELL) or (not filterType and isSceneFragmentShown(LF_FENCE_SELL, isInGamepadMode)) then
			--Inside fence sell?
			local fenceCtrl = isInGamepadMode and fence_GP or fence
			if fenceCtrl ~= nil and fenceCtrl:IsSellingStolenItems() then
				filterTypeDetected = LF_FENCE_SELL
			end
		elseif (filterType and filterType == LF_FENCE_LAUNDER) or (not filterType and isSceneFragmentShown(LF_FENCE_LAUNDER, isInGamepadMode)) then
			--Inside launder sell?
			local fenceCtrl = isInGamepadMode and fence_GP or fence
			if fenceCtrl ~= nil and fenceCtrl:IsLaundering() then
				filterTypeDetected = LF_FENCE_LAUNDER
			end
			--Inside crafting station refinement
		elseif (filterType and (filterType == LF_SMITHING_REFINE or filterType == LF_JEWELRY_REFINE)) or (not filterType and (not ctrlVars.REFINEMENT:IsHidden() or (filterType == LF_SMITHING_REFINE or filterType == LF_JEWELRY_REFINE))) then
			filterTypeDetected = getFilterTypeByFilterTypeRespectingCraftType(LF_SMITHING_REFINE)
			--Inside crafting station deconstruction
		elseif (filterType and (filterType == LF_SMITHING_DECONSTRUCT or filterType == LF_JEWELRY_DECONSTRUCT)) or (not filterType and (not ctrlVars.DECONSTRUCTION:IsHidden() or (filterType == LF_SMITHING_DECONSTRUCT or filterType == LF_JEWELRY_DECONSTRUCT))) then
			filterTypeDetected = getFilterTypeByFilterTypeRespectingCraftType(LF_SMITHING_DECONSTRUCT)
			--Inside crafting station improvement
		elseif (filterType and (filterType == LF_SMITHING_IMPROVEMENT or filterType == LF_JEWELRY_IMPROVEMENT)) or (not filterType and (not ctrlVars.IMPROVEMENT:IsHidden() or (filterType == LF_SMITHING_IMPROVEMENT or filterType == LF_JEWELRY_IMPROVEMENT))) then
			filterTypeDetected = getFilterTypeByFilterTypeRespectingCraftType(LF_SMITHING_IMPROVEMENT)
			--Are we at the crafting stations research panel's popup list dialog?
		elseif (filterType and (filterType == LF_SMITHING_RESEARCH_DIALOG or filterType == LF_JEWELRY_RESEARCH_DIALOG)) or (not filterType and (isResearchListDialogShown() or (filterType == LF_SMITHING_RESEARCH_DIALOG or filterType == LF_JEWELRY_RESEARCH_DIALOG))) then
			filterTypeDetected = getFilterTypeByFilterTypeRespectingCraftType(LF_SMITHING_RESEARCH_DIALOG)
			--Are we at the crafting stations research panel?
		elseif (filterType and (filterType == LF_SMITHING_RESEARCH or filterType == LF_JEWELRY_RESEARCH)) or (not filterType and (not ctrlVars.RESEARCH:IsHidden() or (filterType == LF_SMITHING_RESEARCH or filterType == LF_JEWELRY_RESEARCH))) then
			filterTypeDetected = getFilterTypeByFilterTypeRespectingCraftType(LF_SMITHING_RESEARCH)
			--Inside enchanting station
		elseif (filterType and (filterType == LF_ENCHANTING_EXTRACTION or filterType == LF_ENCHANTING_CREATION)) or (not filterType and not ctrlVars.ENCHANTING_STATION:IsHidden()) then
			--Enchanting Extraction panel?
			local enchantingMode = (isInGamepadMode and enchanting_GP:GetEnchantingMode()) or enchanting:GetEnchantingMode()
			if filterType == LF_ENCHANTING_EXTRACTION or enchantingMode == ENCHANTING_MODE_EXTRACTION then
				filterTypeDetected = LF_ENCHANTING_EXTRACTION
				--Enchanting Creation panel?
			elseif filterType == LF_ENCHANTING_CREATION or enchantingMode == ENCHANTING_MODE_CREATION then
				filterTypeDetected = LF_ENCHANTING_CREATION
			end
			--Inside guild store selling?
		elseif (filterType and filterType == LF_GUILDSTORE_SELL) or (not filterType and not ctrlVars.GUILD_STORE:IsHidden()) then
			filterTypeDetected = LF_GUILDSTORE_SELL
			--Are we at the alchemy station?
		elseif (filterType and filterType == LF_ALCHEMY_CREATION) or (not filterType and not ctrlVars.ALCHEMY_STATION:IsHidden()) then
			filterTypeDetected = LF_ALCHEMY_CREATION
			--Are we at a bank and trying to withdraw some items by double clicking it?
		elseif (filterType and filterType == LF_BANK_WITHDRAW) or (not filterType and not ctrlVars.BANK:IsHidden()) then
			--Set filterTypeDetected to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
			filterTypeDetected = LF_BANK_WITHDRAW
		elseif (filterType and filterType == LF_HOUSE_BANK_WITHDRAW) or (not filterType and not ctrlVars.HOUSE_BANK:IsHidden()) then
			--Set filterTypeDetected to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
			filterTypeDetected = LF_HOUSE_BANK_WITHDRAW
			--Are we at a guild bank and trying to withdraw some items by double clicking it?
		elseif (filterType and filterType == LF_GUILDBANK_WITHDRAW) or (not filterType and not ctrlVars.GUILD_BANK:IsHidden()) then
			--Set filterTypeDetected to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
			filterTypeDetected = LF_GUILDBANK_WITHDRAW
			--Are we at a transmutation/retrait station?
		elseif (filterType and filterType == LF_RETRAIT) or (not filterType and libFilters:IsRetraitStationShown()) then
			--Set filterTypeDetected to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
			filterTypeDetected = LF_RETRAIT
			--Are we at a companion inventory?
		elseif (filterType and filterType == LF_INVENTORY_COMPANION) or (not filterType and libFilters:IsCompanionInventoryShown()) then
			filterTypeDetected = LF_INVENTORY_COMPANION
		--Are we at the bank deposit
		elseif (filterType and filterType == LF_BANK_DEPOSIT or (not filterType and (IsBankOpen() or (currentSceneName ~= nil and (currentSceneName == getSceneName(LF_BANK_DEPOSIT, isInGamepadMode)))) and ctrlVars.BANK:IsHidden())) then

		--Are we at the guild bank deposit
		elseif (filterType and filterType == LF_GUILDBANK_DEPOSIT or (not filterType and (IsGuildBankOpen() or (currentSceneName ~= nil and (currentSceneName == getSceneName(LF_GUILDBANK_DEPOSIT, isInGamepadMode)))) and ctrlVars.GUILD_BANK:IsHidden())) then

		--Are we at the house bank deposit
		elseif (filterType and filterType == LF_HOUSE_BANK_DEPOSIT or (not filterType and (IsBankOpen() or (currentSceneName ~= nil and (currentSceneName == getSceneName(LF_HOUSE_BANK_DEPOSIT, isInGamepadMode)))) and ctrlVars.HOUSE_BANK:IsHidden() )) then

		--Are we at the inventory
		elseif (filterType and (filterType == LF_INVENTORY or (not filterType and not ctrlVars.BACKPACK:IsHidden()))) then
			filterTypeDetected = LF_INVENTORY
		else
			--All others: Unknown
		end
	]]

	--Keyboard mode
	[false] = {
		{ filterType=LF_MAIL_SEND, 					checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_TRADE, 						checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_VENDOR_BUY, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_VENDOR_SELL, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_VENDOR_BUYBACK, 			checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_VENDOR_REPAIR, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_FENCE_SELL, 				checkTypes = { "scene", "fragment", "control"} },
		{ filterType=LF_FENCE_LAUNDER, 				checkTypes = { "scene", "fragment", "control" } },
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
		{ filterType=LF_ENCHANTING_EXTRACTION, 		checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_ENCHANTING_CREATION, 		checkTypes = { "special", "scene", "control" } },
		{ filterType=LF_GUILDSTORE_SELL, 			checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_ALCHEMY_CREATION, 			checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_BANK_WITHDRAW, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_HOUSE_BANK_WITHDRAW, 		checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_GUILDBANK_WITHDRAW, 		checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_RETRAIT, 					checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_INVENTORY_COMPANION, 		checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_BANK_DEPOSIT, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_GUILDBANK_DEPOSIT, 			checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_HOUSE_BANK_DEPOSIT, 		checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_INVENTORY, 					checkTypes = { "fragment", "control", "special" } },
	},
	--Gamepad mode
	[true] = {
		{ filterType=LF_MAIL_SEND, 					checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_TRADE, 						checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_VENDOR_BUY, 				checkTypes = { "fragment", "control", "special", "specialForced" } },
		{ filterType=LF_VENDOR_SELL, 				checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_VENDOR_BUYBACK, 			checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_VENDOR_REPAIR, 				checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_FENCE_SELL, 				checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_FENCE_LAUNDER, 				checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_SMITHING_REFINE, 			checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_JEWELRY_REFINE, 			checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_SMITHING_DECONSTRUCT, 		checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_JEWELRY_DECONSTRUCT, 		checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_SMITHING_IMPROVEMENT, 		checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_JEWELRY_IMPROVEMENT, 		checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_SMITHING_RESEARCH_DIALOG,	checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_JEWELRY_RESEARCH_DIALOG, 	checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_SMITHING_RESEARCH, 			checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_JEWELRY_RESEARCH, 			checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_ENCHANTING_EXTRACTION, 		checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_ENCHANTING_CREATION, 		checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_GUILDSTORE_SELL, 			checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_ALCHEMY_CREATION, 			checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_BANK_WITHDRAW, 				checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_HOUSE_BANK_WITHDRAW, 		checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_GUILDBANK_WITHDRAW, 		checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_RETRAIT, 					checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_INVENTORY_COMPANION, 		checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_BANK_DEPOSIT, 				checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_GUILDBANK_DEPOSIT, 			checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_HOUSE_BANK_DEPOSIT, 		checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_INVENTORY, 					checkTypes = { "fragment", "control", "special" } },
	}
}
mapping.LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes = filterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes

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

if libFilters.debug then dd("LIBRARY CONSTANTS FILE - END") end
