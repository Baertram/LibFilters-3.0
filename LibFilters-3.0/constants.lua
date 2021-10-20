------------------------------------------------------------------------------------------------------------------------
--LIBRARY CONSTANTS
------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3 name, and version
local MAJOR, GlobalLibName, MINOR = "LibFilters-3.0", "LibFilters3", 3.0

--Was the library loaded already? Abort here then
if _G[GlobalLibName] ~= nil then return end

--local ZOs speed-up variables
local SM = SCENE_MANAGER

--Local library variable
local libFilters = {}
libFilters.filters = {}
local filters = libFilters.filters
libFilters.isInitialized = false

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
--!!!IMPORTANT !!! Do not change the order as these numbers were added over time and need to keep the same order !!!
--> Else the constants do not match the correct values anymore and will filter the wrong panels!
libFilters.constants.filterTypes = {}

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
	 --as well as the way to hook to the inventory.additionalFilters in function "HookAdditionalFilters",
	 --or via a fragment in table "fragmentToFilterType",
	 --and maybe an overwritten "filter enable function" (which respects the entries of the added additionalFilters) in
	 --file "helpers.lua"
	 --[<number constant>] = "LF_...",
}
--register the filterConstants for the filterpanels in the global table _G
for value, filterConstantName in ipairs(libFiltersFilterConstants) do
	 _G[filterConstantName] = value

	--Create empty table for each filter constant LF_*
	filters[_G[filterConstantName]] = {}
end
libFilters.FilterTypes = libFiltersFilterConstants
libFilters.constants.filterTypes = libFilters.FilterTypes

--Get the min and max filterPanelIds
LF_FILTER_MIN					= LF_INVENTORY
LF_FILTER_MAX					= #libFiltersFilterConstants


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
--The custom fragment names for the filter panelId
gamepadConstants.customFragments = {
	[LF_INVENTORY] 		= 		{name = fragmentPrefix_GP .. "BACKPACK_INVENTORY_GAMEPAD_FRAGMENT", fragment=nil},
	[LF_BANK_DEPOSIT] 	= 		{name = fragmentPrefix_GP .. "BACKPACK_BANK_DEPOSIT_GAMEPAD_FRAGMENT", fragment=nil},
	[LF_HOUSE_BANK_DEPOSIT] = 	{name = fragmentPrefix_GP .. "BACKPACK_HOUSE_BANK_DEPOSIT_GAMEPAD_FRAGMENT", fragment=nil},
	[LF_GUILDBANK_DEPOSIT] = 	{name = fragmentPrefix_GP .. "BACKPACK_GUILD_BANK_DEPOSIT_GAMEPAD_FRAGMENT", fragment=nil},
	[LF_GUILDSTORE_SELL] = 		{name = fragmentPrefix_GP .. "BACKPACK_TRADING_HOUSE_SELL_GAMEPAD_FRAGMENT", fragment=nil},
	[LF_MAIL_SEND] = 			{name = fragmentPrefix_GP .. "BACKPACK_MAIL_SEND_GAMEPAD_FRAGMENT", fragment=nil},
	[LF_TRADE] = 				{name = fragmentPrefix_GP .. "BACKPACK_PLAYER_TRADE_GAMEPAD_FRAGMENT", fragment=nil},
}
local customFragments_GP = gamepadConstants.customFragments

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
keyboardConstants.playerInv  =  		    	PLAYER_INVENTORY
keyboardConstants.inventories  = 				keyboardConstants.playerInv.inventories
local inventories = keyboardConstants.inventories

--Backpack
keyboardConstants.invBackpack  = 				inventories[invTypeBackpack]
local invBackpack = keyboardConstants.invBackpack
keyboardConstants.invBackpackFragment  = 		BACKPACK_MENU_BAR_LAYOUT_FRAGMENT

--Craftbag
keyboardConstants.craftBagClass  =  			ZO_CraftBag
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
keyboardConstants.vendorSell  =  				BACKPACK_STORE_LAYOUT_FRAGMENT
---Buy back
keyboardConstants.vendorBuyBack  = 				BUY_BACK_WINDOW
---Repair
keyboardConstants.vendorRepair  = 				REPAIR_WINDOW


--[Fence]
--Fence launder
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
keyboardConstants.alchemy  =  					ALCHEMY_SCENE
keyboardConstants.alchemyInv = 					ALCHEMY.inventory

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

--Backpack
gamepadConstants.invBackpack_GP =				GAMEPAD_INVENTORY
gamepadConstants.invBank_GP = 					GAMEPAD_BANKING
gamepadConstants.invGuildBank_GP = 				GAMEPAD_GUILD_BANK
gamepadConstants.invRootScene = 				GAMEPAD_INVENTORY_ROOT_SCENE

--Craftbag
gamepadConstants.invCraftbag_GP =				inventories[invTypeCraftBag]		--remove using invCraftbag

--Quest items
gamepadConstants.invQuests_GP =					gamepadConstants.invBackpack_GP.scene				--remove using invQuests

--Quickslots
gamepadConstants.quickslots_GP =				GAMEPAD_QUICKSLOT					--remove does not exist for gamepad


--[Banks]
--Player bank
local invBank_GP = gamepadConstants.invBank_GP

--Guild bank
gamepadConstants.invGuildBankDepositScene_GP =  GAMEPAD_GUILD_BANK_SCENE

--House bank

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
--Fence launder
gamepadConstants.invFenceLaunder_GP =			ZO_GamepadFenceLaunder

--Fence sell
gamepadConstants.invFenceSell_GP =				ZO_GamepadFenceSell


--[Guild store]
--gamepadConstants.guildStoreBuy_GP			--not supported by LibFilters yet
gamepadConstants.invGuildStoreSellScene_GP =  	TRADING_HOUSE_GAMEPAD_SCENE


--[Mail]
gamepadConstants.invMailSendScene_GP = 			SM:GetScene("mailManagerGamepad")


--[Player 2 player trade]
gamepadConstants.invPlayerTradeScene_GP = 		SM:GetScene("gamepadTrade")


--[Companion]
gamepadConstants.companionEquipment_GP = 		COMPANION_EQUIPMENT_GAMEPAD


--[Crafting]
gamepadConstants.smithing_GP = 					SMITHING_GAMEPAD
local smithing_GP = gamepadConstants.smithing_GP

--Refinement
gamepadConstants.refinementPanel_GP =	  			smithing_GP.refinementPanel

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
gamepadConstants.enchantingCreate_GP = 			GAMEPAD_ENCHANTING_CREATION_SCENE
gamepadConstants.enchantingExtract_GP = 		GAMEPAD_ENCHANTING_EXTRACTION_SCENE
gamepadConstants.enchanting_GP =				GAMEPAD_ENCHANTING

--Alchemy
gamepadConstants.alchemy_GP = 					ALCHEMY_SCENE
gamepadConstants.alchemyInv_GP = 				GAMEPAD_ALCHEMY.inventory

--Retrait
--gamepadConstants.retrait = --

--Reconstruction
--gamepadConstants.reconstruct = --



------------------------------------------------------------------------------------------------------------------------
--Custom created fragments -> See file /Gamepad/gamepadCustomFragments.lua
-----------------------------------------------------------------------------------------------------------------------
-->They will be nil here at the time constant.lua is parsed as the custom gamepad fragments were not created yet!
--> The file /Gamepad/gamepadCustomFragments.lua needs some constants fo this file first!
---->But they will be added later to the constants table "gamepadConstants", as they were created in file
---->/Gamepad/gamepadCustomFragments.lua table customFragmentsUpdateRef
-->Important: The variables are updated to table libFilters.LF_ConstantToAdditionalFilterControlSceneFragmentUserdata,
-->which is used for libFilters:HookAdditionalFilters!
--[[
local invBackpackFragment_GP =	nil --customFragments_GP[LF_INVENTORY].fragment
local invBankDeposit_GP = 		nil --customFragments_GP[LF_BANK_DEPOSIT].fragment
local invGuildBankDeposit_GP = 	nil --customFragments_GP[LF_GUILDBANK_DEPOSIT].fragment
local invHouseBankDeposit_GP = 	nil --customFragments_GP[LF_HOUSE_BANK_DEPOSIT].fragment
local guildStoreSell_GP = 		nil --customFragments_GP[LF_GUILDSTORE_SELL].fragment
local mailSend_GP = 			nil --customFragments_GP[LF_MAIL_SEND].fragment
local player2playerTrade_GP = 	nil --[customFragments_GP[LF_TRADE].fragment
]]


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
libFilters.constants.filterTypes.UsingBagIdAndSlotIndexFilterFunction = filterTypesUsingBagIdAndSlotIndexFilterFunction
--Add them to the table libFilters.mapping.filterTypeToFilterFunctionType
for filterTypeValue, _  in pairs(filterTypesUsingBagIdAndSlotIndexFilterFunction) do
	filterTypeToFilterFunctionType[filterTypeValue] = LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX
end
--Now add all other missing filterTypes which were not added yet, with the constant LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT
libFilters.constants.filterTypes.UsingInventorySlotFilterFunction = {}
for filterTypeValue, _  in pairs(libFiltersFilterConstants) do
	if filterTypeToFilterFunctionType[filterTypeValue] == nil then
		filterTypeToFilterFunctionType[filterTypeValue] = LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT
		libFilters.constants.filterTypes.UsingInventorySlotFilterFunction[filterTypeValue] = true
	end
end



--[Mapping for crafting]
--Enchaning (used to determine the correct LF_* filterType constant at enchanting tables, as they share the same inventory
--ENCHANTING.inventory. Gamepad mode uses different scenes for enchating creation and extraction so there are used
--callbacks to these scenes' state to se the appropriate LF_ENCHANTING_* constant
-->Used in function LibFilters:HookAdditionalFilterSpecial(specialType, inventory)
local enchantingModeToFilterType = {
	 [ENCHANTING_MODE_CREATION]		= LF_ENCHANTING_CREATION,
	 [ENCHANTING_MODE_EXTRACTION]	= LF_ENCHANTING_EXTRACTION,
	 [ENCHANTING_MODE_RECIPES]		= nil --not supported yet
}
mapping.EnchantingModeToFilterType = enchantingModeToFilterType

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
		[LF_ALCHEMY_CREATION]         = { keyboardConstants.alchemy },
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
		[LF_CRAFTBAG]                 = { gamepadConstants.invCraftbag_GP },
		[LF_INVENTORY_COMPANION]      = { gamepadConstants.companionEquipment_GP },
		[LF_QUICKSLOT]                = {  }, --not in gamepad mode -> quickslots are added directly from type lists. collections>mementos, collections>mounts, inventory>consumables, ... -- leave empty (not NIL!) to prevent error messages
		[LF_BANK_WITHDRAW]            = { gamepadConstants.invBankWithdraw_GP },
		[LF_GUILDBANK_WITHDRAW]       = { gamepadConstants.invGuildBankWithdraw_GP },
		[LF_HOUSE_BANK_WITHDRAW]      = { gamepadConstants.invHouseBankWithdraw_GP },
		[LF_VENDOR_BUY]               = { gamepadConstants.vendorBuy_GP },
		[LF_VENDOR_SELL]              = { gamepadConstants.vendorSell_GP },
		[LF_VENDOR_BUYBACK]           = { gamepadConstants.vendorBuyBack_GP },
		[LF_VENDOR_REPAIR]            = { gamepadConstants.vendorRepair_GP },
		[LF_FENCE_SELL]               = { gamepadConstants.invFenceSell_GP },
		[LF_FENCE_LAUNDER]            = { gamepadConstants.invFenceLaunder_GP },
		[LF_SMITHING_REFINE]          = { gamepadConstants.refinementPanel_GP },
		[LF_SMITHING_RESEARCH_DIALOG] = { gamepadConstants.researchChooseItemDialog_GP },
		[LF_JEWELRY_RESEARCH_DIALOG]  = { gamepadConstants.researchChooseItemDialog_GP },


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
		--> or keyboard mode, and only hook teh active one!
		 --implemented special, leave empty (not NIL!) to prevent error messages
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
		--But curerntly they are changed to be normal entries using HookAdditionalFilter for now, to hook the scenes
		--and add .additionalFilter, used in helpers ZO_Enchanting_DoesEnchantingItemPassFilter
		-->Used for gamepad AND keyboard mode with these entries here !!!
		[LF_ENCHANTING_CREATION]	  = {gamepadConstants.enchantingCreate_GP},
		[LF_ENCHANTING_EXTRACTION]    = {gamepadConstants.enchantingExtract_GP},
	},
}
mapping.LF_ConstantToAdditionalFilterControlSceneFragmentUserdata = LF_ConstantToAdditionalFilterControlSceneFragmentUserdata

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
mapping.FilterTypeToUpdaterNameFixed = filterTypeToUpdaterNameFixed

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
mapping.FilterTypeToUpdaterNameDynamic = filterTypeToUpdaterNameDynamic
--The filterType to unique updater String table. Will be filled with the fixed updater names and the dynamic afterwards
local filterTypeToUpdaterName = {}
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
mapping.FilterTypeToUpdaterName = filterTypeToUpdaterName

