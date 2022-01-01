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
_G[GlobalLibName] 			= libFilters --global table LibFilters3
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
if LibDebugLogger then
	 if not libFilters.logger then
		  libFilters.logger = LibDebugLogger(MAJOR)
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


--Debugging slash commands
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
local gpc						= constants.gamepad

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
constants.inventoryTypes["player"]		=	invTypeBackpack
constants.inventoryTypes["quest"] 		= 	invTypeQuest
constants.inventoryTypes["bank"] 		= 	invTypeBank
constants.inventoryTypes["guild_bank"] 	=	invTypeGuildBank
constants.inventoryTypes["house_bank"] 	= 	invTypeHouseBank
constants.inventoryTypes["craftbag"] 	=	invTypeCraftBag


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

--Character
kbc.characterCtrl                 =	ZO_Character

--Backpack
kbc.invBackpack                   = inventories[invTypeBackpack]
local invBackpack                 = kbc.invBackpack
kbc.invBackpackFragment           = BACKPACK_MENU_BAR_LAYOUT_FRAGMENT

--Craftbag
kbc.craftBagClass  				  = ZO_CraftBag
kbc.invCraftbag                   = inventories[invTypeCraftBag]
local invCraftbag 				  = kbc.invCraftbag
kbc.craftBagFragment 			  = CRAFT_BAG_FRAGMENT
local craftBagFragment 			  = kbc.craftBagFragment

--Quest items
kbc.invQuests                     = inventories[invTypeQuest]
local invQuests					  = kbc.invQuests
kbc.invQuestFragment			  = QUEST_ITEMS_FRAGMENT
local invQuestFragment 			  = kbc.invQuestFragment

--Quickslots
kbc.quickslots                    = QUICKSLOT_WINDOW
local quickslots 				  = kbc.quickslots
kbc.quickslotsFragment            = QUICKSLOT_FRAGMENT
local quickslotsFragment 		  = kbc.quickslotsFragment


--[Banks]
--Player bank
kbc.invBankDeposit                = BACKPACK_BANK_LAYOUT_FRAGMENT
local invBankDeposit 			  = kbc.invBankDeposit
kbc.invBankWithdraw               = inventories[invTypeBank]
local invBankWithdraw 			  = kbc.invBankWithdraw
kbc.bankWithdrawFragment          = BANK_FRAGMENT
local bankWithdrawFragment 		  = kbc.bankWithdrawFragment
kbc.invBankScene      		  	  = getScene(SM, "bank")
local invBankScene 				  = kbc.invBankScene

--Guild bank
kbc.invGuildBankDeposit           = BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT
local invGuildBankDeposit 		  = kbc.invGuildBankDeposit
kbc.invGuildBankWithdraw          = inventories[invTypeGuildBank]
local invGuildBankWithdraw 		  = kbc.invGuildBankWithdraw
kbc.guildBankWithdrawFragment     = GUILD_BANK_FRAGMENT
local guildBankWithdrawFragment   = kbc.guildBankWithdrawFragment
kbc.invGuildBankScene      		  = getScene(SM, "guildBank")
local invGuildBankScene 		  = kbc.invGuildBankScene

--House bank
kbc.invHouseBankDeposit           = BACKPACK_HOUSE_BANK_LAYOUT_FRAGMENT
local invHouseBankDeposit 		  = kbc.invHouseBankDeposit
kbc.invHouseBankWithdraw          = inventories[invTypeHouseBank]
local invHouseBankWithdraw	  	  = kbc.invHouseBankWithdraw
kbc.houseBankWithdrawFragment     = HOUSE_BANK_FRAGMENT
local houseBankWithdrawFragment	  = kbc.houseBankWithdrawFragment
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
kbc.vendorSell        			  = BACKPACK_STORE_LAYOUT_FRAGMENT
local vendorSell 				  = kbc.vendorSell
---Buy back
kbc.vendorBuyBack     			  = BUY_BACK_WINDOW
local vendorBuyBack		  	 	  = kbc.vendorBuyBack
kbc.vendorBuyBackFragment		  = BUY_BACK_FRAGMENT
local vendorBuyBackFragment 	  = kbc.vendorBuyBackFragment

---Repair
kbc.vendorRepair                  = REPAIR_WINDOW
local vendorRepair 				  = kbc.vendorRepair
kbc.vendorRepairFragment          = REPAIR_FRAGMENT
local vendorRepairFragment 		  = kbc.vendorRepairFragment
kbc.storeWindows                  = {
	[ZO_MODE_STORE_BUY] = 			vendorBuy,
	[ZO_MODE_STORE_BUY_BACK] = 		vendorBuyBack,
	[ZO_MODE_STORE_SELL] = 			vendorSell, --TODO: Working?
	[ZO_MODE_STORE_REPAIR] = 		vendorRepair,
	[ZO_MODE_STORE_SELL_STOLEN] = 	vendorSell, --TODO: Working?
	[ZO_MODE_STORE_LAUNDER] = 		vendorSell, --TODO: Working?
	[ZO_MODE_STORE_STABLE] = 		vendorBuy,
}


--[Fence]
--Fence launder
kbc.fence                         = FENCE_KEYBOARD
local fence = kbc.fence
kbc.invFenceLaunderFragment       = BACKPACK_LAUNDER_LAYOUT_FRAGMENT
local invFenceLaunderFragment 	  = kbc.invFenceLaunderFragment

--Fence sell
kbc.invFenceSellFragment 		  = BACKPACK_FENCE_LAYOUT_FRAGMENT
local invFenceSellFragment 		  = kbc.invFenceSellFragment

--[Guild store]
kbc.guildStoreObj                 = ZO_TradingHouse
local guildStoreObj 			  = kbc.guildStoreObj
--keyboardConstants.guildStoreBuy = guildStoreBuy			--not supported by LibFilters yet
kbc.guildStoreBrowseFragment      = TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD_FRAGMENT
local guildStoreBrowseFragment	  = kbc.guildStoreBrowseFragment

kbc.guildStoreSellLayoutFragment  = BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT
local guildStoreSellLayoutFragment= kbc.guildStoreSellLayoutFragment
kbc.guildStoreSellFragment        = INVENTORY_FRAGMENT
local guildStoreSellFragment 	  = kbc.guildStoreSellFragment


--[Mail]
kbc.mailSendObj                   =	MAIL_SEND
kbc.mailSend                      =	BACKPACK_MAIL_LAYOUT_FRAGMENT
local mailSend 					  = kbc.mailSend

--[Player 2 player trade]
kbc.player2playerTradeObj         = TRADE --TRADE_WINDOW
kbc.player2playerTrade            = BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT
local player2playerTrade 		  = kbc.player2playerTrade


--[Companion]
kbc.companionEquipment            = COMPANION_EQUIPMENT_KEYBOARD
local companionEquipment 		  = kbc.companionEquipment
kbc.companionEquipmentFragment	  = COMPANION_EQUIPMENT_KEYBOARD_FRAGMENT
local companionEquipmentFragment  = kbc.companionEquipmentFragment
kbc.companionCharacterCtrl        = ZO_CompanionCharacterWindow_Keyboard_TopLevel
kbc.companionCharacterFragment    = COMPANION_CHARACTER_KEYBOARD_FRAGMENT



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
kbc.alchemy                       =	ALCHEMY
local alchemy 					  = kbc.alchemy
kbc.alchemyScene                  =	ALCHEMY_SCENE
local alchemyScene 				  = kbc.alchemyScene
kbc.alchemyCtrl                   = alchemy.control
kbc.alchemyFragment               =	ALCHEMY_FRAGMENT
local alchemyFragment 			  = kbc.alchemyFragment

--Provisioning
kbc.provisioner			          = PROVISIONER
local provisioner 				  = kbc.provisioner
kbc.provisionerFragment			  = PROVISIONER_FRAGMENT
local provisionerFragment		  = kbc.provisionerFragment

--Retrait
--keyboardConstants.retraitClass  = ZO_RetraitStation_Retrait_Base
kbc.retrait                       = ZO_RETRAIT_KEYBOARD
local retrait 					  = kbc.retrait
kbc.retraitFragment				  = RETRAIT_STATION_RETRAIT_FRAGMENT
local retraitFragment 			  = kbc.retraitFragment

--Reconstruction
kbc.reconstruct                   =	ZO_RECONSTRUCT_KEYBOARD --todo not used yet

--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

------------------------------------------------------------------------------------------------------------------------
--Gamepad constants
------------------------------------------------------------------------------------------------------------------------
--gamepadConstants
--[Inventories]
--Inventory
gpc.playerInvCtrl_GP = kbc.playerInvCtrl

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
gpc.invQuests_GP                = invRootScene_GP --todo: use gamepad inventory root scene for quest hook? Better use something else like a gamepad quest fragment (if exists)

--Quickslots
gpc.quickslots_GP 				= GAMEPAD_QUICKSLOT					--TODO: remove? Quickslots for gamepad are handled differently
gpc.quickslotScene_GP 			= getScene(SM, "gamepad_quickslot")
gpc.quickslotFragment_GP		= GAMEPAD_QUICKSLOT_FRAGMENT


--[Banks]
--Player bank
gpc.invBank_GP                  = GAMEPAD_BANKING
gpc.invBankScene_GP      		= getScene(SM, "gamepad_banking")

--deposit: See custom gamepad fragments
--withdraw: Uses same as keyboard

--Guild bank
gpc.invGuildBank_GP      		= GAMEPAD_GUILD_BANK
gpc.invGuildBankScene_GP 		= GAMEPAD_GUILD_BANK_SCENE
--deposit: See custom gamepad fragments
--withdraw: Uses same as keyboard

--House bank
--Control/scene is same as normal player bank
--deposit: See custom gamepad fragments
--withdraw: Uses same as keyboard


--[Vendor]
gpc.storeScene_GP 				= getScene(SM, "gamepad_store")
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



--[Mail]
gpc.invMailSendScene_GP         = getScene(SM, "mailManagerGamepad")
gpc.invMailSend_GP              = MAIL_MANAGER_GAMEPAD
gpc.invMailSendFragment_GP 		= GAMEPAD_MAIL_SEND_FRAGMENT


--[Player 2 player trade]
gpc.invPlayerTradeScene_GP      = getScene(SM, "gamepadTrade")
gpc.invPlayerTrade_GP           = GAMEPAD_TRADE
gpc.invPlayerTradeFragment_GP   = GAMEPAD_TRADE_FRAGMENT


--[Companion]
gpc.companionEquipment_GP       = COMPANION_EQUIPMENT_GAMEPAD
gpc.companionCharacterCtrl_GP   = ZO_Companion_Gamepad_TopLevel		--TODO is this the correct for gamepad mode?


--[Crafting]
gpc.smithing_GP                 = SMITHING_GAMEPAD
local smithing_GP               = gpc.smithing_GP

--Refinement
gpc.refinementPanel_GP          = smithing_GP.refinementPanel
gpc.refinementScene_GP			= getScene(SM, "gamepad_smithing_refine")

--Create
gpc.creationPanel_GP            = smithing_GP.creationPanel
gpc.creationScene_GP			= getScene(SM, "gamepad_smithing_creation")

--Deconstruction
gpc.deconstructionPanel_GP      = smithing_GP.deconstructionPanel
gpc.deconstructionScene_GP			= getScene(SM, "gamepad_smithing_deconstruct")

--Improvement
gpc.improvementPanel_GP         = smithing_GP.improvementPanel
gpc.improvementScene_GP         = getScene(SM, "gamepad_smithing_improvement")

--Research
gpc.researchPanel_GP            = smithing_GP.researchPanel
gpc.researchScene_GP            = getScene(SM, "gamepad_smithing_research")
gpc.researchChooseItemDialog_GP = getScene(SM, "gamepad_smithing_research_confirm") --GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE
local researchChooseItemDialog_GP = gpc.researchChooseItemDialog_GP

--Enchanting
gpc.enchanting_GP               = GAMEPAD_ENCHANTING
gpc.enchantingCreateScene_GP    = getScene(SM, "gamepad_enchanting_creation") --GAMEPAD_ENCHANTING_CREATION_SCENE
gpc.enchantingExtractScene_GP   = getScene(SM, "gamepad_enchanting_extraction") --GAMEPAD_ENCHANTING_EXTRACTION_SCENE
gpc.enchantingInvCtrls_GP       = {
	[ENCHANTING_MODE_CREATION] = 	gpc.enchantingCreateScene_GP,
	[ENCHANTING_MODE_EXTRACTION] = 	gpc.enchantingExtractScene_GP,
	[ENCHANTING_MODE_RECIPES] = 	nil, --recipesgot no own scene, maybe a fragment?
}

--Alchemy
gpc.alchemy_GP                  = GAMEPAD_ALCHEMY
gpc.alchemyCreationSecene_GP    = getScene(SM, "gamepad_alchemy_creation")
gpc.alchemyCtrl_GP              = gpc.alchemy_GP.control

--Retrait
gpc.retrait_GP                  = ZO_RETRAIT_STATION_RETRAIT_GAMEPAD
gpc.retraitScene_GP				= getScene(SM, "retrait_gamepad")
gpc.retraitFragment_GP			= GAMEPAD_RETRAIT_FRAGMENT

--Reconstruction
gpc.reconstruct_GP              = ZO_RETRAIT_STATION_RECONSTRUCT_GAMEPAD
gpc.reconstructScene_GP			= getScene(SM, "reconstruct_gamepad")
gpc.reconstructFragment_GP		= GAMEPAD_RECONSTRUCT_FRAGMENT

--Provisioning
gpc.provisioner_GP			     = GAMEPAD_PROVISIONER
gpc.provisionerScene_GP			 = getScene(SM, "gamepad_provisioner_root")
gpc.provisionerFragment_GP		 = GAMEPAD_PROVISIONER_FRAGMENT

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

		[LF_MAIL_SEND]                = { mailSend },
		[LF_TRADE]                    = { player2playerTrade },

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
		[LF_INVENTORY_QUEST]          = { gpc.invQuests_GP },
		[LF_INVENTORY_COMPANION]      = { gpc.companionEquipment_GP },

		[LF_VENDOR_BUY]               = { gpc.vendorBuy_GP },
		[LF_VENDOR_SELL]              = { gpc.vendorSell_GP },
		[LF_VENDOR_BUYBACK]           = { gpc.vendorBuyBack_GP },
		[LF_VENDOR_REPAIR]            = { gpc.vendorRepair_GP },
		[LF_FENCE_SELL]               = { gpc.invFenceSell_GP },
		[LF_FENCE_LAUNDER]            = { gpc.invFenceLaunder_GP },

		[LF_SMITHING_RESEARCH_DIALOG] = { researchChooseItemDialog_GP },
		[LF_JEWELRY_RESEARCH_DIALOG]  = { researchChooseItemDialog_GP }, --duplicate needed compared to LF_SMITHING_RESEARCH_DIALOG ?


		--Not given in gamepad mode
		[LF_QUICKSLOT]                = { gpc.quickslotFragment_GP }, --not in gamepad mode -> quickslots are added directly from type lists. collections>mementos, collections>mounts, inventory>consumables, ... / We will just add the fragment here where the .additionalFilter function should be stored, maybe for future implementations


		--Updated with correct fragment in file /gamepad/gamepadCustomFragments.lua as the fragments are created
		[LF_INVENTORY]                = {}, --uses fragment
		[LF_BANK_DEPOSIT]             = {}, --uses fragment
		[LF_GUILDBANK_DEPOSIT]        = {}, --uses fragment
		[LF_HOUSE_BANK_DEPOSIT]       = {}, --uses fragment
		[LF_GUILDSTORE_SELL]          = {}, --uses fragment
		[LF_MAIL_SEND]                = {}, --uses fragment
		[LF_TRADE]                    = {}, --uses fragment


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
		[LF_ENCHANTING_CREATION]	  = { gpc.enchantingCreateScene_GP },
		[LF_ENCHANTING_EXTRACTION]    = { gpc.enchantingExtractScene_GP },


		--Not implemented yet
		[LF_GUILDSTORE_BROWSE] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_COOK]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_BREW]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
	},
}
mapping.LF_FilterTypeToReference = filterTypeToReference

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
local filterTypeToCheckIfReferenceIsHidden = {
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
												  ["funcOrAttribute"] = "IsCraftBagExtendedParentFilterType",
												  ["params"]          = { _G[GlobalLibName], { LF_MAIL_SEND, LF_TRADE,
																							   LF_VENDOR_SELL, LF_GUILDSTORE_SELL,
																							   LF_BANK_DEPOSIT, LF_GUILDBANK_DEPOSIT, LF_HOUSE_BANK_DEPOSIT} --filterTypesToCheck
												   											 },
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
		[LF_GUILDSTORE_SELL]          = { ["control"] = guildStoreObj, 					["scene"] = "tradinghouse", 		["fragment"] = guildStoreSellFragment, },
		--Works: 2021-12-13
		[LF_MAIL_SEND]                = { ["control"] = kbc.mailSendObj, 				["scene"] = "mailSend", 			["fragment"] = mailSend, },
		--Works: 2021-12-13
		[LF_TRADE]                    = { ["control"] = kbc.player2playerTradeObj, 		["scene"] = "trade", 				["fragment"] = player2playerTrade, },
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
		[LF_SMITHING_RESEARCH]        = { ["control"] = researchPanel, 					["scene"] = "smithing", 			["fragment"] = nil,
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
		[LF_JEWELRY_RESEARCH]         = { ["control"] = researchPanel, 					["scene"] = "smithing", 			["fragment"] = nil,
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
		[LF_INVENTORY_QUEST]          = { ["control"] = ZO_GamepadInventoryTopLevel,	["scene"] = invRootScene_GP,		["fragment"] = invFragment_GP,
										  ["special"] = {
											  [1] = {
												  ["control"]         = invBackpack_GP,
												  ["funcOrAttribute"] = "selectedItemFilterType",
												  ["params"]          = { },
												  ["expectedResults"] = { ITEMFILTERTYPE_QUEST },
											  }
										  }
		},
		--TODO
		[LF_INVENTORY_COMPANION]      = { ["control"] = nil, 							["scene"] = gpc.companionEquipment_GP,["fragment"] = nil,
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
		[LF_VENDOR_BUY]               = { ["control"] = storeComponents[ZO_MODE_STORE_BUY].list,	["scene"] = gpc.storeScene_GP, 		["fragment"] = storeComponents[ZO_MODE_STORE_BUY].list._fragment,
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
		[LF_VENDOR_SELL]              = { ["control"] = storeComponents[ZO_MODE_STORE_SELL].list, 	["scene"] = gpc.storeScene_GP,		["fragment"] = storeComponents[ZO_MODE_STORE_SELL].list._fragment,
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
		[LF_VENDOR_BUYBACK]           = { ["control"] = storeComponents[ZO_MODE_STORE_BUY_BACK].list,	["scene"] = gpc.storeScene_GP,	["fragment"] = storeComponents[ZO_MODE_STORE_BUY_BACK].list._fragment,
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
		[LF_VENDOR_REPAIR]            = { ["control"] = storeComponents[ZO_MODE_STORE_REPAIR].list, 	["scene"] = gpc.storeScene_GP,	["fragment"] = storeComponents[ZO_MODE_STORE_REPAIR].list._fragment,
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
		[LF_FENCE_SELL]               = { ["control"] = storeComponents[ZO_MODE_STORE_SELL_STOLEN].list, 	["scene"] = gpc.storeScene_GP,	["fragment"] = storeComponents[ZO_MODE_STORE_SELL_STOLEN].list._fragment,
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
		[LF_FENCE_LAUNDER]            = { ["control"] = storeComponents[ZO_MODE_STORE_LAUNDER].list, 		["scene"] = gpc.storeScene_GP, 	["fragment"] = storeComponents[ZO_MODE_STORE_LAUNDER].list._fragment,
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
		[LF_QUICKSLOT]                = { ["control"] = ZO_GamepadQuickslotToplevel, 	["scene"] = gpc.quickslotScene_GP, 		["fragment"] = gpc.quickslotFragment_GP,		--uses inventory fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
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
		[LF_INVENTORY]                = { ["control"] = ZO_GamepadInventoryTopLevel,	["scene"] = invRootScene_GP,			["fragment"] = invFragment_GP,
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
		[LF_BANK_DEPOSIT]             = { ["control"] = ZO_GamepadBankingTopLevelMaskContainerdeposit,		["scene"] = gpc.invBankScene_GP,		["fragment"] = nil,  	--uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created. Fragment will be updated as bank lists get initialized
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
		[LF_GUILDBANK_DEPOSIT]        = { ["control"] = ZO_GuildBankTopLevel_GamepadMaskContainerdeposit, 	["scene"] = gpc.invGuildBankScene_GP, 	["fragment"] = nil, }, 	--uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created. Fragment will be updated as guild bank lists get initialized
		--Works, 2021-12-18
		[LF_HOUSE_BANK_DEPOSIT]       = { ["control"] = ZO_GamepadBankingTopLevelMaskContainerdeposit,		["scene"] = gpc.invBankScene_GP, 		["fragment"] = nil,		--uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created. Fragment will be updated as bank lists get initialized
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
		[LF_GUILDSTORE_SELL]          = { ["control"] = ZO_TradingHouse_GamepadMaskContainerSell,	["scene"] = gpc.invGuildStoreSellScene_GP, 	["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		--Works, 2021-12-18
		[LF_MAIL_SEND]                = { ["control"] = gpc.invMailSend_GP.send.sendControl,	["scene"] = gpc.invMailSendScene_GP,		["fragment"] = nil, }, --uses fragment -> See file /gamepad/gamepadCustomFragments.lua as the fragments are created
		--Works, 2021-12-23
		[LF_TRADE]                    = { ["control"] = gpc.invPlayerTrade_GP, 					["scene"] = gpc.invPlayerTradeScene_GP, 	["fragment"] = gpc.invPlayerTradeFragment_GP, },

		--Works, 2021-12-19
		[LF_CRAFTBAG]                 = { ["control"] = ZO_GamepadInventoryTopLevelMaskContainerCraftBag, 	["scene"] = invRootScene_GP, 	["fragment"] = invFragment_GP,
										  ["special"] = {
											  [1] = {
												  ["control"]         = invBackpack_GP.craftBagList,
												  ["funcOrAttribute"] = "IsActive",
												  ["params"]          = { invBackpack_GP.craftBagList },
												  ["expectedResults"] = { true },
											  }
										  }
		},
		--Works, 2021-12-18
		[LF_BANK_WITHDRAW]            = { ["control"] = ZO_GamepadBankingTopLevelMaskContainerwithdraw, 	["scene"] = gpc.invBankScene_GP, 		["fragment"] = nil, --fragment will be updated as bank lists get initialized
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
		[LF_GUILDBANK_WITHDRAW]       = { ["control"] = ZO_GuildBankTopLevel_GamepadMaskContainerwithdraw, 	["scene"] = gpc.invGuildBankScene_GP,	["fragment"] = nil, },  -- fragment will be updated as guild bank lists get initialized
		--Works, 2021-12-18
		[LF_HOUSE_BANK_WITHDRAW]      = { ["control"] = ZO_GamepadBankingTopLevelMaskContainerwithdraw, 	["scene"] = gpc.invBankScene_GP,		["fragment"] = nil,		--fragment will be updated as bank lists get initialized
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
		[LF_SMITHING_REFINE]          = { ["control"] = gpc.refinementPanel_GP, 		["scene"] = gpc.refinementScene_GP, 	["fragment"] = nil,
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
		[LF_SMITHING_DECONSTRUCT]     = { ["control"] = gpc.deconstructionPanel_GP, 	["scene"] = gpc.deconstructionScene_GP, ["fragment"] = nil,
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
		[LF_SMITHING_IMPROVEMENT]     = { ["control"] = gpc.improvementPanel_GP, 		["scene"] = gpc.improvementScene_GP, 	["fragment"] = nil,
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
		[LF_SMITHING_RESEARCH]        = { ["control"] = gpc.researchPanel_GP, 			["scene"] = gpc.researchScene_GP,		["fragment"] = nil,
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
		[LF_JEWELRY_REFINE]           = { ["control"] = gpc.refinementPanel_GP, 		["scene"] = gpc.refinementScene_GP, 	["fragment"] = nil,
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
		[LF_JEWELRY_DECONSTRUCT]      = { ["control"] = gpc.deconstructionPanel_GP, 	["scene"] = gpc.deconstructionScene_GP, ["fragment"] = nil,
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
		[LF_JEWELRY_IMPROVEMENT]      = { ["control"] = gpc.improvementPanel_GP, 		["scene"] = gpc.improvementScene_GP, 	["fragment"] = nil,
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
		[LF_JEWELRY_RESEARCH]         = { ["control"] = gpc.researchPanel_GP, 			["scene"] = gpc.researchScene_GP, 		["fragment"] = nil,
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
		[LF_ALCHEMY_CREATION]	  	  = { ["control"] = gpc.alchemy_GP, 				["scene"] = gpc.alchemyCreationSecene_GP, 	["fragment"] = nil,
										   ["special"] = {
												[1] = {
													["control"]  =  gpc.alchemy_GP,
													["funcOrAttribute"] = "mode",
													["params"] = {},
													["expectedResults"] = {ZO_ALCHEMY_MODE_CREATION},
												}
											}
		},
		--Works, 2021-12-22
		[LF_RETRAIT]                  = { ["control"] = gpc.retrait_GP, ["scene"] = gpc.retraitScene_GP, ["fragment"] = gpc.retraitFragment_GP, },


		--Normally these are special hooks in table LF_ConstantToAdditionalFilterSpecialHook.
		--But currently they are changed to be normal entries using HookAdditionalFilter for now, to hook the scenes
		--and add .additionalFilter, used in helpers ZO_Enchanting_DoesEnchantingItemPassFilter
		-->Used for gamepad AND keyboard mode with these entries here !!!
		--Works, 2021-12-22
		[LF_ENCHANTING_CREATION]	  = { ["control"] = gpc.enchanting_GP, ["scene"] = gpc.enchantingCreateScene_GP, ["fragment"] = nil,
										  ["special"] = {
											  [1] = {
												  ["control"]  =  gpc.enchanting_GP,
												  ["funcOrAttribute"] = "GetEnchantingMode",
												  ["params"] = {gpc.enchanting_GP},
												  ["expectedResults"] = {ENCHANTING_MODE_CREATION},
											  }
										  }
		},
		--Works, 2021-12-22
		[LF_ENCHANTING_EXTRACTION]	  = { ["control"] = gpc.enchanting_GP, ["scene"] = gpc.enchantingExtractScene_GP, ["fragment"] = nil,
											["special"] = {
												[1] = {
													["control"]  =  gpc.enchanting_GP,
													["funcOrAttribute"] = "GetEnchantingMode",
													["params"] = {gpc.enchanting_GP},
													["expectedResults"] = {ENCHANTING_MODE_EXTRACTION},
												}
											}
		},


		--Not implemented yet
		--Works, 2021-12-18
		--The data of control and fragment will not be provided until the gamepad guild store was opened first time!
		--> So this line will be updated again then via function "SetCurrentMode" -> See file gamepadCustomFragments, SecurePostHook("ZO_TradingHouse_Browse_Gamepad_OnInitialize", function()
		--Works, 2021-12-18
		[LF_GUILDSTORE_BROWSE]        = { ["control"] = gpc.tradingHouseBrowse_GP, 		["scene"] = gpc.invGuildStoreSellScene_GP,	["fragment"] =  nil }, --gpc.tradingHouseBrowse_GP.fragment, },
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
		[LF_PROVISIONING_COOK]		  = { ["control"] = gpc.provisioner_GP,				["scene"] = gpc.provisionerScene_GP, ["fragment"] = gpc.provisionerFragment_GP,
										   ["special"] = {
												[1] = {
													["control"]  =  gpc.provisioner_GP,
													["funcOrAttribute"] = "filterType",
													["params"] = {},
													["expectedResults"] = {PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES},
												}
											}
		},
		--Works, 2021-12-22
		[LF_PROVISIONING_BREW]		  = { ["control"] = gpc.provisioner_GP,				["scene"] = gpc.provisionerScene_GP, ["fragment"] = gpc.provisionerFragment_GP,
										   ["special"] = {
												[1] = {
													["control"]  =  gpc.provisioner_GP,
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
		{ filterType=LF_INVENTORY_COMPANION, 		checkTypes = { "fragment", "control", "special" } },
		{ filterType=LF_BANK_DEPOSIT, 				checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_GUILDBANK_DEPOSIT, 			checkTypes = { "scene", "fragment", "control" } },
		{ filterType=LF_HOUSE_BANK_DEPOSIT, 		checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_INVENTORY_QUEST,			checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_QUICKSLOT, 					checkTypes = { "scene", "fragment", "control", "special" } },
		{ filterType=LF_INVENTORY, 					checkTypes = { "scene", "fragment", "control", "special"  } },
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


--[fragment] = LF_* filterTypeConstant
--0 means no dedicated LF_* constant can be used and the filterType will be determined automatically via function
--detectShownReferenceNow(), using table mapping.LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup
--Example:
--[fragmentVariable] = LF_INVENTORY,
local callbacksUsingFragments = {
	--Keyboard
	[false] = {
		--LF_INVENTORY
		--LF_BANK_DEPOSIT
		--LF_GUILDBANK_DEPOSIT
		--LF_HOUSE_BANK_DEPOSIT
		--LF_VENDOR_SELL
		[inventoryFragment] 				= 0,
		--LF_PROVISIONING_COOK
		--LF_PROVISIONING_BREW
		[provisionerFragment]				= 0,

		--Dedicated fragments
		[invQuestFragment] 					= LF_INVENTORY_QUEST,
		[craftBagFragment] 					= LF_CRAFTBAG,
		[quickslotsFragment] 				= LF_QUICKSLOT,
		[bankWithdrawFragment] 				= LF_BANK_WITHDRAW,
		[guildBankWithdrawFragment]     	= LF_GUILDBANK_WITHDRAW,
		[houseBankWithdrawFragment]			= LF_HOUSE_BANK_WITHDRAW,
		[vendorBuyFragment]  				= LF_VENDOR_BUY,
		[vendorBuyBackFragment]				= LF_VENDOR_BUYBACK,
		[vendorRepairFragment]				= LF_VENDOR_REPAIR,
		[invFenceSellFragment]				= LF_FENCE_SELL,
		[invFenceLaunderFragment]			= LF_FENCE_LAUNDER,
		[guildStoreBrowseFragment]			= LF_GUILDSTORE_BROWSE,
		[guildStoreSellLayoutFragment]		= LF_GUILDSTORE_SELL,
		[mailSend]							= LF_MAIL_SEND,
		[player2playerTrade]				= LF_TRADE,
		[alchemyFragment]					= LF_ALCHEMY_CREATION,
		[retraitFragment]					= LF_RETRAIT,
		[companionEquipmentFragment] 		= LF_INVENTORY_COMPANION,
	},

--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

	--Gamepad
	[true] = {
		--LF_INVENTORY --> Maybe, should be also be triggered via custom fragment "gamepadLibFiltersInventoryFragment"!
		--LF_CRAFTBAG
		--LF_INVENTORY_QUEST
		[invFragment_GP]					= 0,
		--LF_SMITHING_RESEARCH_DIALOG
		--LF_JEWELRY_RESEARCH_DIALOG
		[researchChooseItemDialog_GP]		= 0,
		--LF_PROVISIONING_COOK
		--LF_PROVISIONING_BREW
		[gpc.provisionerFragment_GP] 		= 0,

		--Dedicated fragments
		[storeComponents[ZO_MODE_STORE_BUY].list._fragment] 		= LF_VENDOR_BUY,
		[storeComponents[ZO_MODE_STORE_SELL].list._fragment] 		= LF_VENDOR_SELL,
		[storeComponents[ZO_MODE_STORE_BUY_BACK].list._fragment] 	= LF_VENDOR_BUYBACK,
		[storeComponents[ZO_MODE_STORE_REPAIR].list._fragment] 		= LF_VENDOR_REPAIR,
		[storeComponents[ZO_MODE_STORE_SELL_STOLEN].list._fragment] = LF_FENCE_SELL,
		[storeComponents[ZO_MODE_STORE_LAUNDER].list._fragment] 	= LF_FENCE_LAUNDER,
		[gpc.quickslotFragment_GP] 									= LF_QUICKSLOT,
		[gpc.retraitFragment_GP]									= LF_RETRAIT,
		[gpc.invPlayerTradeFragment_GP]								= LF_TRADE,			--> Maybe, should be also be triggered via custom fragment "gamepadLibFiltersPlayerTradeFragment"!

		-->Custom fragments will be updated from file /Gamepad/gamepadCustomFragments.lua
		--The fragments will be updated as bank lists get initialized
		--callbacksUsingFragments[true][gamepadLibFiltersInventoryFragment] 		= LF_INVENTORY
		--callbacksUsingFragments[true][gamepadLibFiltersBankDepositFragment] 		= LF_BANK_DEPOSIT
		--callbacksUsingFragments[true][gamepadLibFiltersGuildBankDepositFragment] 	= LF_GUILDBANK_DEPOSIT
		--callbacksUsingFragments[true][gamepadLibFiltersHouseBankDepositFragment] 	= LF_HOUSE_BANK_DEPOSIT
		--[tradingHouseBrowse_GP.fragment] 											= LF_GUILDSTORE_BROWSE,
		--callbacksUsingFragments[true][gamepadLibFiltersGuildStoreSellFragment] 	= LF_GUILDSTORE_SELL
		--callbacksUsingFragments[true][gamepadLibFiltersMailSendFragment] 			= LF_MAIL_SEND
		--callbacksUsingFragments[true][gamepadLibFiltersPlayerTradeFragment] 		= LF_TRADE
		--[1] = LF_BANK_WITHDRAW,
		--[1] = LF_GUILDBANK_WITHDRAW,
		--[1] = LF_HOUSE_BANK_WITHDRAW,

	}
}
callbacks.usingFragments = callbacksUsingFragments


--[scene_Or_sceneName] = LF_* filterTypeConstant
--0 means no dedicated LF_* constant can be used and the filterType will be determined automatically via function
--detectShownReferenceNow(), using table mapping.LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypesLookup
--Example:
--[sceneVariable] = LF_INVENTORY,
local callbacksUsingScenes = {
	--Keyboard
	[false] = {
		--LF_ENCHANTING_CREATION
		--LF_ENCHANTING_EXTRACTION
		[enchantingScene] = 0,
	},

--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

	--Gamepad
	[true] = {
	 	--LF_SMITHING_REFINE
		--LF_JEWELRY_REFINE
		[gpc.refinementScene_GP] 			= 0,
	 	--LF_SMITHING_CREATION
		--LF_JEWELRY_CREATION
		[gpc.creationScene_GP] 				= 0,
		--LF_SMITHING_DECONSTRUCT
		--LF_JEWELRY_DECONSTRUCT
		[gpc.deconstructionScene_GP] 		= 0,
		--LF_SMITHING_IMPROVEMENT
		--LF_JEWELRY_IMPROVEMENT
		[gpc.improvementScene_GP] 			= 0,
		--LF_SMITHING_RESEARCH
		--LF_JEWELRY_RESEARCH
		[gpc.researchScene_GP] 				= 0,
		--LF_SMITHING_RESEARCH_DIALOG
		--LF_JEWELRY_RESEARCH_DIALOG
		[researchChooseItemDialog_GP] 		= 0,

		--Dedicated scenes
		[gpc.alchemyCreationSecene_GP] 		= LF_ALCHEMY_CREATION,
		[gpc.enchantingCreateScene_GP] 		= LF_ENCHANTING_CREATION,
		[gpc.enchantingExtractScene_GP] 	= LF_ENCHANTING_EXTRACTION,

	}
}
callbacks.usingScenes = callbacksUsingScenes


--[control] = LF_* filterTypeConstant
--0 means no dedicated LF_* constant can be used and the filterType will be determined
--Example:
--[controlVariable] = LF_INVENTORY,
local callbacksUsingControl = {
	--Keyboard
	[false] = {
	 	--LF_SMITHING_REFINE
		--LF_JEWELRY_REFINE
		[refinementPanel] 		= 0,
	 	--LF_SMITHING_CREATION
		--LF_JEWELRY_CREATION
		[creationPanel] 		= 0,
		--LF_SMITHING_DECONSTRUCT
		--LF_JEWELRY_DECONSTRUCT
		[deconstructionPanel] 	= 0,
		--LF_SMITHING_IMPROVEMENT
		--LF_JEWELRY_IMPROVEMENT
		[improvementPanel] 		= 0,
		--LF_SMITHING_RESEARCH
		--LF_JEWELRY_RESEARCH
		[researchPanel] 		= 0,
		--LF_SMITHING_RESEARCH_DIALOG
		--LF_JEWELRY_RESEARCH_DIALOG
		[researchPanelControl] 	= 0,
	},

--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

	--Gamepad
	[true] = {
		[invBackpack_GP.craftBagList] = LF_CRAFTBAG,
	},
}
callbacks.usingControls = callbacksUsingControl

if libFilters.debug then dd("LIBRARY CONSTANTS FILE - END") end

