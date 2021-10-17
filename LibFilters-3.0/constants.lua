------------------------------------------------------------------------------------------------------------------------
--LIBRARY CONSTANTS
------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3 name, and version
local MAJOR, GlobalLibName, MINOR = "LibFilters-3.0", "LibFilters3", 3.0

--Was the library loaded already? Abort here then
if _G[GlobalLibName] ~= nil then return end

--Local library variable
local libFilters = {}
libFilters.filters = {}
local filters = libFilters.filters
libFilters.isInitialized = false

--Global library constant LibFilters3
_G[GlobalLibName]	= libFilters
libFilters.name	            = MAJOR
libFilters.version          = MINOR
libFilters.globalLibName    = GlobalLibName


------------------------------------------------------------------------------------------------------------------------
--LF_* FILTER PANEL ID constants
------------------------------------------------------------------------------------------------------------------------
-- LibFilters filterPanel constants [value number] = "name"
--The possible libFilters filterPanelIds
--!!!IMPORTANT !!! Do not change the order as these numbers were added over time and need to keep the same order !!!
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
libFilters.filterTypes = libFiltersFilterConstants

--Get the min and max filterPanelIds
LF_FILTER_MIN					= LF_INVENTORY
LF_FILTER_MAX					= #libFiltersFilterConstants


------------------------------------------------------------------------------------------------------------------------
--ZOs / ESOUI CONSTANTS
------------------------------------------------------------------------------------------------------------------------
libFilters.constants = {}
libFilters.constants.keyboard = {}
local keyboardConstants = libFilters.constants.keyboard
libFilters.constants.gamepad = {}
local gamepadConstants = libFilters.constants.gamepad


--Custom created fragments for the gamepad mode
--Prefix of these fragments
gamepadConstants.customFragmentPrefix = GlobalLibName:upper() .. "_" -- LIBFILTERS3_
local fragmentPrefix_GP = libFilters.customFragmentPrefix
--The custom fragment names for the filter panelId
gamepadConstants.customFragments = {
	[LF_INVENTORY] 		= 		fragmentPrefix_GP .. "BACKPACK_INVENTORY_GAMEPAD_FRAGMENT",
	[LF_BANK_DEPOSIT] 	= 		fragmentPrefix_GP .. "BACKPACK_BANK_DEPOSIT_GAMEPAD_FRAGMENT",
	[LF_HOUSE_BANK_DEPOSIT] = 	fragmentPrefix_GP .. "BACKPACK_HOUSE_BANK_DEPOSIT_GAMEPAD_FRAGMENT",
	[LF_GUILD_BANK_DEPOSIT] = 	fragmentPrefix_GP .. "BACKPACK_GUILD_BANK_DEPOSIT_GAMEPAD_FRAGMENT",
	[LF_GUILDSTORE_SELL] = 		fragmentPrefix_GP .. "BACKPACK_TRADING_HOUSE_SELL_GAMEPAD_FRAGMENT",
	[LF_MAIL_SEND] = 			fragmentPrefix_GP .. "BACKPACK_MAIL_SEND_GAMEPAD_FRAGMENT",
	[LF_TRADE] = 				fragmentPrefix_GP .. "BACKPACK_PLAYER_TRADE_GAMEPAD_FRAGMENT",
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

--[Inventories]
local playerInv = 		    	PLAYER_INVENTORY
local inventories =				playerInv.inventories

--Backpack
local invBackpack =				inventories[invTypeBackpack]
local invBackpackFragment =		BACKPACK_MENU_BAR_LAYOUT_FRAGMENT
local invBackpack_GP =			GAMEPAD_INVENTORY				--
local invBank_GP = 				GAMEPAD_BANKING					-- can remove not in use
local invGuildBank_GP = 		GAMEPAD_GUILD_BANK				-- can remove not in use

--Craftbag
local craftBagClass = 			ZO_CraftBag
local invCraftbag =				inventories[invTypeCraftBag]
local invCraftbag_GP =			inventories[invTypeCraftBag]		--remove using invCraftbag

--Quest items
local invQuests =				inventories[invTypeQuest]
local invQuests_GP =			invBackpack_GP.scene				--remove using invQuests

--Quickslots
local quickslots =				QUICKSLOT_WINDOW
local quickslots_GP =			GAMEPAD_QUICKSLOT					--remove does not exist for gamepad


--[Banks]
--Player bank
local invBankDeposit =			BACKPACK_BANK_LAYOUT_FRAGMENT
local invBankWithdraw =			inventories[invTypeBank]
local invBankWithdraw_GP =		invBank_GP.withdrawList				--remove using invBankWithdraw

--Guild bank
local invGuildBankDeposit =   	BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT
local invGuildBankWithdraw =	inventories[invTypeGuildBank]
local invGuildBankWithdraw_GP = invGuildBank_GP.withdrawList		--remove using invGuildBankWithdraw

--House bank
local invHouseBankDeposit = 	BACKPACK_HOUSE_BANK_LAYOUT_FRAGMENT
local invHouseBankWithdraw =	inventories[invTypeHouseBank]
local invHouseBankWithdraw_GP =	invBank_GP.withdrawList 			--remove using invHouseBankWithdraw

--[Vendor]
----Buy
local store =					STORE_WINDOW
local store_GP = 				STORE_WINDOW_GAMEPAD
local vendorBuy_GP = 			ZO_GamepadStoreBuy 			--store_GP.components[ZO_MODE_STORE_BUY].list
---Sell
local vendorSell = 				BACKPACK_STORE_LAYOUT_FRAGMENT
local vendorSell_GP = 			ZO_GamepadStoreSell 		--store_GP.components[ZO_MODE_STORE_SELL].list
---Buy back
local vendorBuyBack =			BUY_BACK_WINDOW
local vendorBuyBack_GP = 		ZO_GamepadStoreBuyback 		--store_GP.components[ZO_MODE_STORE_BUY_BACK].list
---Repair
local vendorRepair =			REPAIR_WINDOW
local vendorRepair_GP =			ZO_GamepadStoreRepair 		--store_GP.components[ZO_MODE_STORE_REPAIR].list


--[Fence]
--Fence launder
local invFenceLaunder =			BACKPACK_LAUNDER_LAYOUT_FRAGMENT
local invFenceLaunder_GP =		ZO_GamepadFenceLaunder

--Fence sell
local invFenceSell = 			BACKPACK_FENCE_LAYOUT_FRAGMENT
local invFenceSell_GP =			ZO_GamepadFenceSell


--[Guild store]
local guildStoreBuy 			--not supported by LibFilters yet
local guildStoreBuy_GP			--not supported by LibFilters yet
local guildStoreSell = 			BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT


--[Mail]
local mailSend =				BACKPACK_MAIL_LAYOUT_FRAGMENT


--[Player 2 player trade]
local player2playerTrade = 		BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT

--[Companion]
local companionEquipment = 		COMPANION_EQUIPMENT_KEYBOARD
local companionEquipment_GP = 	COMPANION_EQUIPMENT_GAMEPAD


--[Custom created fragments -> See file /Gamepad/gamepadCustomFragments.lua]
-->They will be nil here at the time constant.lua is parsed as the custom gamepad fragments were not created yet!
--> The file /Gamepad/gamepadCustomFragments.lua needs some constants fo this file first!
---->But they will be added later to these constants tables, as they were created in file /Gamepad/gamepadCustomFragments.lua
local invBackpackFragment_GP =	nil --_G[customFragments_GP[LF_INVENTORY]]
local invBankDeposit_GP = 		nil --_G[customFragments_GP[LF_BANK_DEPOSIT]]
local invGuildBankDeposit_GP = 	nil --_G[customFragments_GP[LF_GUILDBANK_DEPOSIT]]
local invHouseBankDeposit_GP = 	nil --_G[customFragments_GP[LF_HOUSE_BANK_DEPOSIT]]
local guildStoreSell_GP = 		nil --_G[customFragments_GP[LF_GUILDSTORE_SELL]]
local mailSend_GP = 			nil --_G[customFragments_GP[LF_MAIL_SEND]]
local player2playerTrade_GP = 	nil --_G[customFragments_GP[LF_TRADE]]



--[Crafting]
local smithing = 				SMITHING
local smithing_GP = 			SMITHING_GAMEPAD

--Refinement
local refinementPanel =	  		smithing.refinementPanel

--Create
local creationPanel =	  		smithing.creationPanel

--Deconstruction
local deconstructionPanel = 	smithing.deconstructionPanel
local deconstructionPanel_GP = 	smithing_GP.deconstructionPanel

--Improvement
local improvementPanel =	 	smithing.improvementPanel

--Research
local researchPanel =		 	smithing.researchPanel
local researchChooseItemDialog= SMITHING_RESEARCH_SELECT
local researchPanel_GP =		smithing_GP.researchPanel
local researchChooseItemDialog_GP= GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE

--Enchanting
local enchantingCreate_GP = 	GAMEPAD_ENCHANTING_CREATION_SCENE
local enchantingExtract_GP = 	GAMEPAD_ENCHANTING_EXTRACTION_SCENE

--Alchemy
--local alchemy = 				ALCHEMY
local alchemy = 				ALCHEMY_SCENE

--Retrait
--local retraitClass =		  	 ZO_RetraitStation_Retrait_Base
local retrait =				 	ZO_RETRAIT_KEYBOARD

--Reconstruction
local reconstruct = 			ZO_RECONSTRUCT_KEYBOARD


------------------------------------------------------------------------------------------------------------------------
--MAPPING
------------------------------------------------------------------------------------------------------------------------
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
libFilters.enchantingModeToFilterType = enchantingModeToFilterType

--[Mapping LibFilters LF* constants not being hooked normal -> Special functions used]
local standardSpecialHookFunc = "HookAdditionalFilterSpecial" --LibFilters:HookAdditionalFilterSpecial
local standardSceneSpecialHookFunc = "HookAdditionalFilterSceneSpecial" --LibFilters:HookAdditionalFilterSceneSpecial

-->The mapping between the LF_* filterType constant and a LibFilters function name (funcName of _G["LibFilters"])
-->plus the parameters to pass to the function
-->Any entry with LF* in this table will NOT use LibFilters:HookAdditionalFilter below!
-->See mapping table table "LF_ConstantToAdditionalFilterControlSceneFragmentUserdata" below
local LF_ConstantToAdditionalFilterSpecialHook = {
	[LF_ENCHANTING_CREATION] = { --this will also apply the filters for LF_ENCHANTING_EXTRACTION
--		[false] = {funcName = standardSpecialHookFunc, 	params = {"enchanting"}}, --Keyboard mode
--		[true] 	= {funcName = standardSceneSpecialHookFunc, params = {"enchanting_GamePad"}},
	},
	[LF_ENCHANTING_EXTRACTION] = {
		--[false] = {}, --> See LF_ENCHANTING_CREATION above!
		--[true] = {}, --> See LF_ENCHANTING_CREATION above!
	},
}

--[Mapping GamePad/Keyboard control/scene/fragment/userdate/etc. .additionalFilter entry to the LF_* constant]
-->This table contains the mapping between GamePad and Keyboard mode, and the LibFilters constant LF_* to
-->the control, scene, fragment, userdata to use to store the .additionalFilters table addition to.
-->The controls/fregments/scenes can be many. Each entry in the value table will be applying .additionalFilters
-->Used in function LibFilters:HookAdditionalFilter(filterType_LF_Constant)
local LF_ConstantToAdditionalFilterControlSceneFragmentUserdata = {
	--Keyboard mode
	[false] = {
		[LF_INVENTORY]                = { invBackpack, invBackpackFragment },
		[LF_INVENTORY_QUEST]          = { invQuests },
		[LF_CRAFTBAG]                 = { invCraftbag },
		[LF_INVENTORY_COMPANION]      = { companionEquipment },
		[LF_QUICKSLOT]                = { quickslots },
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
		[LF_FENCE_SELL]               = { invFenceSell },
		[LF_FENCE_LAUNDER]            = { invFenceLaunder },
		[LF_GUILDSTORE_BROWSE] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_GUILDSTORE_SELL]          = { guildStoreSell },
		[LF_MAIL_SEND]                = { mailSend },
		[LF_TRADE]                    = { player2playerTrade },
		[LF_SMITHING_REFINE]          = { refinementPanel },
		[LF_SMITHING_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_DECONSTRUCT]     = { deconstructionPanel },
		[LF_SMITHING_IMPROVEMENT]     = { improvementPanel },
		[LF_SMITHING_RESEARCH]        = { researchPanel },
		[LF_SMITHING_RESEARCH_DIALOG] = { researchChooseItemDialog },
		[LF_JEWELRY_REFINE]           = { refinementPanel },
		[LF_JEWELRY_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_DECONSTRUCT]      = { deconstructionPanel },
		[LF_JEWELRY_IMPROVEMENT]      = { improvementPanel },
		[LF_JEWELRY_RESEARCH]         = { researchPanel },
		[LF_JEWELRY_RESEARCH_DIALOG]  = { researchChooseItemDialog },
		[LF_ALCHEMY_CREATION]         = { alchemy },
		[LF_PROVISIONING_COOK]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_BREW]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_RETRAIT]                  = { retrait },

		--Special entries, see table LF_ConstantToAdditionalFilterSpecialHook above!
--		[LF_ENCHANTING_CREATION]	  = {}, --implemented special, leave empty (not NIL!) to prevent error messages
--		[LF_ENCHANTING_EXTRACTION]    = {}, --implemented special, leave empty (not NIL!) to prevent error messages
	},

	--Gamepad mode
	[true]  = {
		[LF_INVENTORY]                = { invBackpackFragment_GP },
		[LF_INVENTORY_QUEST]          = { invQuests_GP },
		[LF_CRAFTBAG]                 = { invCraftbag_GP },	--using inventories[invType]
		[LF_INVENTORY_COMPANION]      = { companionEquipment_GP },
--		[LF_QUICKSLOT]                = { quickslots_GP }, --not in gamepad mode
		[LF_BANK_WITHDRAW]            = { invBankWithdraw_GP },	--using inventories[invType]
		[LF_BANK_DEPOSIT]             = { invBankDeposit_GP },	--using inventories[invType]
		[LF_GUILDBANK_WITHDRAW]       = { invGuildBankWithdraw_GP },	--using inventories[invType]
		[LF_GUILDBANK_DEPOSIT]        = { invGuildBankDeposit_GP },	--using inventories[invType]
		[LF_HOUSE_BANK_WITHDRAW]      = { invHouseBankWithdraw_GP },	--using inventories[invType]
		[LF_HOUSE_BANK_DEPOSIT]       = { invHouseBankDeposit_GP },	--using inventories[invType]
		[LF_VENDOR_BUY]               = { vendorBuy_GP },
		[LF_VENDOR_SELL]              = { vendorSell_GP },
		[LF_VENDOR_BUYBACK]           = { vendorBuyBack_GP },
		[LF_VENDOR_REPAIR]            = { vendorRepair_GP },
		[LF_FENCE_SELL]               = { invFenceSell_GP },
		[LF_FENCE_LAUNDER]            = { invFenceLaunder_GP },
		[LF_GUILDSTORE_BROWSE] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_GUILDSTORE_SELL]          = { guildStoreSell_GP },	--using inventories[invType]
		[LF_MAIL_SEND]                = { mailSend_GP },
		[LF_TRADE]                    = { player2playerTrade_GP },
--		[LF_SMITHING_REFINE]          = { refinementPanel_GP },
--		[LF_SMITHING_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_SMITHING_DECONSTRUCT]     = { deconstructionPanel_GP },
--		[LF_SMITHING_IMPROVEMENT]     = { improvementPanel_GP },
		[LF_SMITHING_RESEARCH]        = { researchPanel_GP },
		[LF_SMITHING_RESEARCH_DIALOG] = { researchChooseItemDialog_GP },
--		[LF_JEWELRY_REFINE]           = { refinementPanel_GP },
--		[LF_JEWELRY_CREATION] 		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_JEWELRY_DECONSTRUCT]      = { deconstructionPanel_GP },
--		[LF_JEWELRY_IMPROVEMENT]      = { improvementPanel_GP },
		[LF_JEWELRY_RESEARCH]         = { researchPanel_GP },
--		[LF_JEWELRY_RESEARCH_DIALOG]  = { researchChooseItemDialog_GP },
--		[LF_ALCHEMY_CREATION]         = { alchemy_GP },
		[LF_PROVISIONING_COOK]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
		[LF_PROVISIONING_BREW]		  = {}, --not implemented yet, leave empty (not NIL!) to prevent error messages
--		[LF_RETRAIT]                  = { retrait_GP },

		--Special entries, see table LF_ConstantToAdditionalFilterSpecialHook above!
		 [LF_ENCHANTING_CREATION]	  = {enchantingCreate_GP},
		 [LF_ENCHANTING_EXTRACTION]    = {enchantingExtract_GP},

	},
}
libFilters.LF_ConstantToAdditionalFilterControlSceneFragmentUserdata = LF_ConstantToAdditionalFilterControlSceneFragmentUserdata

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
libFilters.filterTypeToUpdaterName = filterTypeToUpdaterName

