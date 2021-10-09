--Known bugs: 2
--Last update: 2021-10-05, Baertram
--
--Bugs/Todo List:
--
--#1: PTS API 100034, Update 29
--[[Originally Posted by code65536
Currently on the Update 29 PTS, LibFilters is causing an error when interacting with a merchant.

EsoUI/Ingame/StoreWindow/Keyboard/BuyBack_Keyboard.lua:209: operator < is not supported for nil < numberhide stack
1. EsoUI/Ingame/StoreWindow/Keyboard/BuyBack_Keyboard.lua:209: in function 'BuyBack:SetupBuyBackSlot'show
2. EsoUI/Ingame/StoreWindow/Keyboard/BuyBack_Keyboard.lua:25: in function '(anonymous)'show
3. [C]: in function 'PostHookFunction'
4. EsoUI/Libraries/ZO_Templates/ScrollTemplates.lua:2372: in function 'ZO_ScrollList_UpdateScroll'show
5. EsoUI/Libraries/ZO_Templates/ScrollTemplates.lua:2128: in function 'ZO_ScrollList_Commit'show
6. EsoUI/Ingame/StoreWindow/Keyboard/BuyBack_Keyboard.lua:226: in function 'BuyBack:ApplySort'show
7. user:/AddOns/LibFilters-3.0/LibFilters-3.0/helper.lua:73: in function 'UpdateList'show
8. EsoUI/Ingame/StoreWindow/Keyboard/BuyBack_Keyboard.lua:86: in function 'OnListTextFilterComplete'show
9. EsoUI/Libraries/Utility/ZO_CallbackObject.lua:107: in function 'ZO_CallbackObjectMixin:FireCallbacks'show
10. EsoUI/Ingame/Utility/TextSearchManager.lua:212: in function 'ZO_TextSearchManager:ExecuteSearch'show
11. EsoUI/Ingame/Utility/TextSearchManager.lua:159: in function 'ZO_TextSearchManager:CleanSearch'show
12. EsoUI/Ingame/Utility/TextSearchManager.lua:85: in function 'ZO_TextSearchManager:ActivateTextSearch'show
13. EsoUI/Ingame/StoreWindow/Keyboard/StoreWindow_Keyboard.lua:184: in function 'ShowStoreWindow'show
Looks like the code that's specific to the repair window is being executed outside of that context?
]]
--
--#2: -> Seems to be only a bug if AdvancedFilters is enabled!!!
--	 Opening bank withdraw e.g. armor heavy (where there are items!), opening mail via keybind e.g. ring filter,
--	 closing mail, opening bank withdraw again showing armor heavy (the last selected one before opening mail) and
--	 all of sudden no items are shown anymore.

--Name, global variable LibFilters3 name, and version
local MAJOR, GlobalLibName, MINOR = "LibFilters-3.0", "LibFilters3", 3.0

--Was the library loaded already?
if _G[GlobalLibName] ~= nil then return end

------------------------------------------------------------------------------------------------------------------------
--LOCAL SPEED UP VARIABLE REFERENCES
------------------------------------------------------------------------------------------------------------------------
--Game API local speedup
local EM = EVENT_MANAGER
local SM = SCENE_MANAGER
local IsGamepad = IsInGamepadPreferredMode

--LibFilters local speedup
local hookAdditionalFilter


------------------------------------------------------------------------------------------------------------------------
--LIBRARY VARIABLES
------------------------------------------------------------------------------------------------------------------------
--Local library variable
local LibFilters = {}
LibFilters.filters = {}
local filters = LibFilters.filters
LibFilters.isInitialized = false

--Global library constant
_G[GlobalLibName]	= LibFilters
LibFilters.name	  = MAJOR
LibFilters.version  = MINOR


------------------------------------------------------------------------------------------------------------------------
--DEBUGGING & LOGGING
------------------------------------------------------------------------------------------------------------------------
--LibDebugLogger
if LibDebugLogger then
	 if not not LibFilters.logger then
		  LibFilters.logger = LibDebugLogger(MAJOR)
	 end
end
local logger = LibFilters.logger

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
		  d("[".. MAJOR .."]" .. tostring(textTypeToPrefix[textType]) .. ": ".. tostring(text))
	 end
end

--Information debug
local function df(...)
	 debugMessage(string.format(...), 'I')
end
--Error debug
local function dfe(...)
	 debugMessage(string.format(...), 'E')
end

------------------------------------------------------------------------------------------------------------------------
--LF_* FILTER PANEL IDS
------------------------------------------------------------------------------------------------------------------------
-- LibFilters filterPanel constants [value number] = "name"
--The possible libFilters filterPanelIds
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
	 [10]  = "LF_GUILDSTORE_BROWSE",
	 [11]  = "LF_GUILDSTORE_SELL",
	 [12]  = "LF_MAIL_SEND",
	 [13]  = "LF_TRADE",
	 [14]  = "LF_SMITHING_REFINE",
	 [15]  = "LF_SMITHING_CREATION",
	 [16]  = "LF_SMITHING_DECONSTRUCT",
	 [17]  = "LF_SMITHING_IMPROVEMENT",
	 [18]  = "LF_SMITHING_RESEARCH",
	 [19]  = "LF_ALCHEMY_CREATION",
	 [20]  = "LF_ENCHANTING_CREATION",
	 [21]  = "LF_ENCHANTING_EXTRACTION",
	 [22]  = "LF_PROVISIONING_COOK",
	 [23]  = "LF_PROVISIONING_BREW",
	 [24]  = "LF_FENCE_SELL",
	 [25]  = "LF_FENCE_LAUNDER",
	 [26]  = "LF_CRAFTBAG",
	 [27]  = "LF_QUICKSLOT",
	 [28]  = "LF_RETRAIT",
	 [29]  = "LF_HOUSE_BANK_WITHDRAW",
	 [30]  = "LF_HOUSE_BANK_DEPOSIT",
	 [31]  = "LF_JEWELRY_REFINE",
	 [32]  = "LF_JEWELRY_CREATION",
	 [33]  = "LF_JEWELRY_DECONSTRUCT",
	 [34]  = "LF_JEWELRY_IMPROVEMENT",
	 [35]  = "LF_JEWELRY_RESEARCH",
	 [36]  = "LF_SMITHING_RESEARCH_DIALOG",
	 [37]  = "LF_JEWELRY_RESEARCH_DIALOG",
	 [38]  = "LF_INVENTORY_QUEST",
	 [39]  = "LF_INVENTORY_COMPANION",
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
LibFilters.filterTypes = libFiltersFilterConstants

--Get the min and max filterPanelIds
LF_FILTER_MIN					= LF_INVENTORY
LF_FILTER_MAX					= #libFiltersFilterConstants


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
local invBackpack_GP =			GAMEPAD_INVENTORY.itemList

--Craftbag
local craftBagClass = 			ZO_CraftBag
local invCraftbag =				inventories[invTypeCraftBag]
local invCraftbag_GP =			GAMEPAD_INVENTORY.craftBagList

--Quest items
local invQuests =				inventories[invTypeQuest]
local invQuests_GP				--TODO

--Quickslots
local quickslots =				QUICKSLOT_WINDOW
local quickslots_GP =			GAMEPAD_QUICKSLOT


--[Banks]
--Player bank
local invBankDeposit =			BACKPACK_BANK_LAYOUT_FRAGMENT
local invBankDeposit_GP =		GAMEPAD_BANKING.depositList
local invBankWithdraw =			inventories[invTypeBank]
local invBankWithdraw_GP =		GAMEPAD_BANKING.withdrawList

--Guild bank
local invGuildBankDeposit =   	BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT
local invGuildBankDeposit_GP =	GAMEPAD_GUILD_BANK.depositList
local invGuildBankWithdraw =	inventories[invTypeGuildBank]
local invGuildBankWithdraw_GP = GAMEPAD_GUILD_BANK.withdrawList

--House bank
local invHouseBankDeposit = 	BACKPACK_HOUSE_BANK_LAYOUT_FRAGMENT
local invHouseBankDeposit_GP =	GAMEPAD_BANKING.depositList
local invHouseBankWithdraw =	inventories[invTypeHouseBank]
local invHouseBankWithdraw_GP =	GAMEPAD_BANKING.withdrawList


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
local invFenceLaunder_GP		--TODO

--Fence sell
local invFenceSell = 			BACKPACK_FENCE_LAYOUT_FRAGMENT
local invFenceSell_GP			--TODO


--[Guild store]
local guildStoreBuy 			--not supported by LibFilters yet
local guildStoreBuy_GP			--not supported by LibFilters yet
local guildStoreSell = 			BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT
local guildStoreSell_GP = 		GAMEPAD_TRADING_HOUSE_FRAGMENT


--[Mail]
local mailSend =				BACKPACK_MAIL_LAYOUT_FRAGMENT
local mailSend_GP =				GAMEPAD_MAIL_SEND_FRAGMENT


--[Player 2 player trade]
local player2playerTrade = 		BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT
local player2playerTrade_GP = 	GAMEPAD_TRADE_FRAGMENT


--[Companion]
local companionEquipment = 		COMPANION_EQUIPMENT_KEYBOARD
local companionEquipment_GP = 	COMPANION_EQUIPMENT_GAMEPAD


--[Crafting]
local smithing = 				SMITHING
local smithing_GP = 			SMITHING_GAMEPAD

--Refinement
local refinementPanel =	  		smithing.refinementPanel
local refinementPanel_GP =	  	smithing_GP.refinementPanel

--Create
local creationPanel =	  		smithing.creationPanel		---not "officially" supported by LibFilters yet
local creationPanel_GP =	  	smithing_GP.creationPanel	---not "officially" supported by LibFilters yet

--Deconstruction
local deconstructionPanel = 	smithing.deconstructionPanel
local deconstructionPanel_GP = 	smithing_GP.deconstructionPanel

--Improvement
local improvementPanel =	 	smithing.improvementPanel
local improvementPanel_GP =	 	smithing_GP.improvementPanel

--Research
local researchPanel =		 	smithing.researchPanel
local researchChooseItemDialog= SMITHING_RESEARCH_SELECT
local researchPanel_GP =		smithing_GP.researchPanel
local researchChooseItemDialog_GP= GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE

--Enchanting
local enchantingClass =	  		ZO_Enchanting
local enchantingClass_GP = 		ZO_GamepadEnchanting
local enchanting =			 	ENCHANTING
local enchanting_GP = 			GAMEPAD_ENCHANTING
local enchantingCreate_GP = 	GAMEPAD_ENCHANTING_CREATION_SCENE
local enchantingExtract_GP = 	GAMEPAD_ENCHANTING_EXTRACTION_SCENE

--Alchemy
local alchemy = 				ALCHEMY
local alchemy_GP = 				GAMEPAD_ALCHEMY

--Retrait
--local retraitClass =		  	 ZO_RetraitStation_Retrait_Base
local retrait =				 	ZO_RETRAIT_KEYBOARD
local retrait_GP = 				ZO_RETRAIT_STATION_GAMEPAD

--Reconstruction
local reconstruct = 			ZO_RECONSTRUCT_KEYBOARD
local reconstruct_GP = 			ZO_RETRAIT_STATION_RECONSTRUCT_GAMEPAD


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

--[Mapping LibFilters LF* constants not being hooked normal -> Special functions used]
local standardSpecialHookFunc = "HookAdditionalFilterSpecial" --LibFilters:HookAdditionalFilterSpecial
-->The mapping between the LF_* filterType constant and a LibFilters function name (funcName of _G["LibFilters"])
-->plus the parameters to pass to the function
-->Any entry with LF* in this table will NOT use LibFilters:HookAdditionalFilter below!
-->See mapping table table "LF_ConstantToAdditionalFilterControlSceneFragmentUserdata" below
local LF_ConstantToAdditionalFilterSpecialHook = {
	[LF_ENCHANTING_CREATION] = { --this will also apply the filters for LF_ENCHANTING_EXTRACTION
		[false] = {funcName = standardSpecialHookFunc, 	params = {"enchanting"}}, --Keyboard mode
		--Gamepad mode is done normal via SCENES in LF_ConstantToAdditionalFilterControlSceneFragmentUserdata table below!
		--[true] 	= {funcName = "HookAdditionalFilterSpecial", params = {"enchanting_GamePad"}},
	},
	--[LF_ENCHANTING_EXTRACTION] = {} -> See LF_ENCHANTING_CREATION above!
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
		--[LF_GUILDSTORE_BROWSE] 		= {},
		[LF_GUILDSTORE_SELL]          = { guildStoreSell },
		[LF_MAIL_SEND]                = { mailSend },
		[LF_TRADE]                    = { player2playerTrade },
		[LF_SMITHING_REFINE]          = { refinementPanel.inventory },
		--[LF_SMITHING_CREATION] 		= {},
		[LF_SMITHING_DECONSTRUCT]     = { deconstructionPanel.inventory },
		[LF_SMITHING_IMPROVEMENT]     = { improvementPanel.inventory },
		[LF_SMITHING_RESEARCH]        = { researchPanel },
		[LF_SMITHING_RESEARCH_DIALOG] = { researchChooseItemDialog },
		[LF_JEWELRY_REFINE]           = { refinementPanel.inventory },
		--[LF_JEWELRY_CREATION] 		= {},
		[LF_JEWELRY_DECONSTRUCT]      = { deconstructionPanel.inventory },
		[LF_JEWELRY_IMPROVEMENT]      = { improvementPanel.inventory },
		[LF_JEWELRY_RESEARCH]         = { researchPanel },
		[LF_JEWELRY_RESEARCH_DIALOG]  = { researchChooseItemDialog },
		[LF_ALCHEMY_CREATION]         = { alchemy.inventory },
		--[LF_PROVISIONING_COOK]		= {},
		--[LF_PROVISIONING_BREW]		= {},
		[LF_RETRAIT]                  = { retrait },

		--Special entries, see table LF_ConstantToAdditionalFilterSpecialHook above!
		--[LF_ENCHANTING_CREATION]	  = {},
		--[LF_ENCHANTING_EXTRACTION]  = {},
	},

	--Gamepad mode
	[true]  = {
		[LF_INVENTORY]                = { invBackpack_GP }, --TODO replace with e.g. GAMEPAD_INVENTORY.itemList and add helper to GAMEPAD_INVENTORY.itemList:SetItemFilterFunction
		[LF_INVENTORY_QUEST]          = { invQuests_GP },
		[LF_CRAFTBAG]                 = { invCraftbag_GP }, --TODO replace with e.g. GAMEPAD_INVENTORY.craftBagList and add helper to GAMEPAD_INVENTORY.craftBagList:SetItemFilterFunction
		[LF_INVENTORY_COMPANION]      = { companionEquipment_GP }, --TODO Validate for gamepad mode
		[LF_QUICKSLOT]                = { quickslots_GP }, --TODO Validate for gamepad mode
		[LF_BANK_WITHDRAW]            = { invBankWithdraw_GP }, --TODO replace with e.g. GAMEPAD_BANKING.withdrawList and add helper to GAMEPAD_BANKING.withdrawList:SetItemFilterFunction
		[LF_BANK_DEPOSIT]             = { invBankDeposit_GP }, --TODO replace with e.g. GAMEPAD_BANKING.depositList and add helper to GAMEPAD_BANKING.depositList:SetItemFilterFunction
		[LF_GUILDBANK_WITHDRAW]       = { invGuildBankWithdraw_GP }, --TODO replace with e.g. GAMEPAD_GUILD_BANK.withdrawList and add helper to GAMEPAD_GUILD_BANK.withdrawList:SetItemFilterFunction
		[LF_GUILDBANK_DEPOSIT]        = { invGuildBankDeposit_GP }, --TODO replace with e.g. GAMEPAD_GUILD_BANK.depositList and add helper to GAMEPAD_GUILD_BANK.depositList:SetItemFilterFunction
		[LF_HOUSE_BANK_WITHDRAW]      = { invHouseBankWithdraw_GP }, --TODO replace with e.g. GAMEPAD_BANKING.withdrawList and add helper to GAMEPAD_BANKING.withdrawList:SetItemFilterFunction and check for houseBankBag -> GetBankingBag()
		[LF_HOUSE_BANK_DEPOSIT]       = { invHouseBankDeposit_GP }, --TODO replace with e.g. GAMEPAD_BANKING.depositList and add helper to GAMEPAD_BANKING.depositList:SetItemFilterFunction and check for houseBankBag -> GetBankingBag()
		[LF_VENDOR_BUY]               = { vendorBuy_GP },
		[LF_VENDOR_SELL]              = { vendorSell_GP },
		[LF_VENDOR_BUYBACK]           = { vendorBuyBack_GP },
		[LF_VENDOR_REPAIR]            = { vendorRepair_GP },
		[LF_FENCE_SELL]               = { invFenceSell_GP },
		[LF_FENCE_LAUNDER]            = { invFenceLaunder_GP },
		--[LF_GUILDSTORE_BROWSE] 		= {},
		[LF_GUILDSTORE_SELL]          = { guildStoreSell_GP },
		[LF_MAIL_SEND]                = { mailSend_GP }, --TODO replace with e.g. MAIL_MANAGER_GAMEPAD.send.inventoryList and add helper to MAIL_MANAGER_GAMEPAD.send.inventoryList:SetItemFilterFunction
		[LF_TRADE]                    = { player2playerTrade_GP },
		[LF_SMITHING_REFINE]          = { refinementPanel_GP.inventory },
		--[LF_SMITHING_CREATION] 		= {},
		[LF_SMITHING_DECONSTRUCT]     = { deconstructionPanel_GP.inventory },
		[LF_SMITHING_IMPROVEMENT]     = { improvementPanel_GP.inventory },
		[LF_SMITHING_RESEARCH]        = { researchPanel_GP },
		[LF_SMITHING_RESEARCH_DIALOG] = { researchChooseItemDialog_GP },
		[LF_JEWELRY_REFINE]           = { refinementPanel_GP.inventory },
		--[LF_JEWELRY_CREATION] 		= {},
		[LF_JEWELRY_DECONSTRUCT]      = { deconstructionPanel_GP.inventory },
		[LF_JEWELRY_IMPROVEMENT]      = { improvementPanel_GP.inventory },
		[LF_JEWELRY_RESEARCH]         = { researchPanel_GP },
		[LF_JEWELRY_RESEARCH_DIALOG]  = { researchChooseItemDialog_GP },
		[LF_ALCHEMY_CREATION]         = { alchemy_GP.inventory },
		--[LF_PROVISIONING_COOK]		= {},
		--[LF_PROVISIONING_BREW]		= {},
		[LF_RETRAIT]                  = { retrait_GP },

		[LF_ENCHANTING_CREATION]	  = {enchantingCreate_GP},
		[LF_ENCHANTING_EXTRACTION]    = {enchantingExtract_GP},

		--Special entries, see table LF_ConstantToAdditionalFilterSpecialHook above!
	},
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
LibFilters.filterTypeToUpdaterName = filterTypeToUpdaterName


------------------------------------------------------------------------------------------------------------------------
--HOOK state variables
------------------------------------------------------------------------------------------------------------------------
--Special hooks
local specialHooksDone = {
	 ["enchanting"] = false,
}


------------------------------------------------------------------------------------------------------------------------
--UPDATERS (of inventories)
------------------------------------------------------------------------------------------------------------------------
--Update the inventory lists
--if the mouse is enabled, cycle its state to refresh the integrity of the control beneath it
local function SafeUpdateList(object, ...)
--d("[LibFilters3]SafeUpdateList, inv: " ..tostring(...))
	 local isMouseVisible = SM:IsInUIMode()

	 if isMouseVisible then HideMouse() end

	 object:UpdateList(...)

	 if isMouseVisible then ShowMouse() end
end

--Function to update a ZO_ListDialog1 dialog's list contents
local function dialogUpdaterFunc(listDialogControl)
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
	SafeUpdateList(playerInv, invType)
end

local function updateCraftingInventoryDirty(craftingInventory)
	craftingInventory:HandleDirtyEvent()
end

--The updater functions for the different inventories. Called via LibFilters:RequestForUpdate(LF_*)
local inventoryUpdaters = {
	INVENTORY = function()
		if IsGamepad() then
			--TODO
		else
			updateKeyboardPlayerInventoryType(invTypeBackpack)
		end
	end,
	CRAFTBAG = function()
		if IsGamepad() then
			--TODO
		else
			updateKeyboardPlayerInventoryType(invTypeCraftBag)
		end
	end,
	INVENTORY_QUEST = function()
		if IsGamepad() then
			--TODO
		else
			updateKeyboardPlayerInventoryType(invTypeQuest)
		end
	end,
	QUICKSLOT = function()
		if IsGamepad() then
			SafeUpdateList(quickslots_GP) --TODO
		else
			SafeUpdateList(quickslots)
		end
	end,
	BANK_WITHDRAW = function()
		if IsGamepad() then
			--TODO
		else
			updateKeyboardPlayerInventoryType(invTypeBank)
		end
	end,
	GUILDBANK_WITHDRAW = function()
		if IsGamepad() then
			--TODO
		else
			updateKeyboardPlayerInventoryType(invTypeGuildBank)
		end
	end,
	HOUSE_BANK_WITHDRAW = function()
		if IsGamepad() then
			--TODO
		else
			updateKeyboardPlayerInventoryType(invTypeHouseBank)
		end
	end,
	VENDOR_BUY = function()
		if IsGamepad() then
			vendorBuy_GP:UpdateList() --TODO
		else
			if guildStoreSell.state ~= SCENE_SHOWN then --"shown"
				store:GetStoreItems()
				SafeUpdateList(store)
			end
		end
	end,
	VENDOR_BUYBACK = function()
		if IsGamepad() then
			vendorBuyBack_GP:UpdateList() --TODO
		else
			SafeUpdateList(vendorBuyBack)
		end
	end,
	VENDOR_REPAIR = function()
		if IsGamepad() then
			vendorRepair_GP:UpdateList()  --TODO
		else
			SafeUpdateList(vendorRepair)
		end
	end,
	GUILDSTORE_BROWSE = function()
	end,
	INVENTORY_COMPANION = function()
		if IsGamepad() then
			SafeUpdateList(companionEquipment_GP, nil) --TODO
		else
			SafeUpdateList(companionEquipment, nil)
		end
	end,
	SMITHING_REFINE = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(refinementPanel_GP.inventory)
		else
			updateCraftingInventoryDirty(refinementPanel.inventory)
		end
	end,
	SMITHING_CREATION = function()
	--[[
	--Not supported yet
	if IsGamepad() then
	else
	end
	]]
	end,
	SMITHING_DECONSTRUCT = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(deconstructionPanel_GP.inventory)
		else
			updateCraftingInventoryDirty(deconstructionPanel.inventory)
		end
	end,
	SMITHING_IMPROVEMENT = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(improvementPanel_GP.inventory)
		else
			updateCraftingInventoryDirty(improvementPanel.inventory)
		end
	end,
	SMITHING_RESEARCH = function()
		if IsGamepad() then
			researchPanel_GP:Refresh()
		else
			researchPanel:Refresh()
		end
	end,
	SMITHING_RESEARCH_DIALOG = function()
		if IsGamepad() then
			--TODO
		else
			dialogUpdaterFunc(researchChooseItemDialog)
		end
	end,
	ALCHEMY_CREATION = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(alchemy_GP.inventory) --TODO
		else
			updateCraftingInventoryDirty(alchemy.inventory)
		end
	end,
	ENCHANTING = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(enchanting_GP.inventory) --TODO
		else
			updateCraftingInventoryDirty(enchanting.inventory)
		end
	end,
	PROVISIONING_COOK = function()
	end,
	PROVISIONING_BREW = function()
	end,
	RETRAIT = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(retrait_GP) --TODO
		else
			updateCraftingInventoryDirty(retrait.inventory)
		end
	end,
	RECONSTRUCTION = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(reconstruct_GP) --TODO
		else
			updateCraftingInventoryDirty(reconstruct.inventory)
		end
	end,
}
LibFilters.inventoryUpdaters = inventoryUpdaters


------------------------------------------------------------------------------------------------------------------------
--RUN THE FILTERS
------------------------------------------------------------------------------------------------------------------------
--Run the applied filters at a LibFilters filterType (LF_*) now, using the ... parameters (e.g. inventorySlot)
local function runFilters(filterType, ...)
--d("[LibFilters3]runFilters, filterType: " ..tostring(filterType))
	 for tag, filter in pairs(filters[filterType]) do
		  if not filter(...) then
				return false
		  end
	 end
	 return true
end
LibFilters.RunFilters = runFilters


------------------------------------------------------------------------------------------------------------------------
--HOOK VARIABLEs TO ADD .additionalFilters to them
------------------------------------------------------------------------------------------------------------------------
--Hook all the filters at the different inventory panels (LibFilters filterPanelIds) now
local function HookAdditionalFilters()

	--For each LF constant hook the filters now to add the .additionalFilters entry
	-->Keyboard and gamepad mode are both hooked here via 2nd param = true
	for value, filterConstantName in ipairs(libFiltersFilterConstants) do
		-->HookAdditionalFilterSpecial will be done automatically in HookAdditionalFilter, via the table
		-->LF_ConstantToAdditionalFilterSpecialHook
		hookAdditionalFilter(LibFilters, value, true) --value = the same as _G[filterConstantName], eg. LF_INVENTORY
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
--Returns the minimum possible filteType
function LibFilters:GetMinFilterType()
	 return LF_FILTER_MIN
end
LibFilters.GetMinFilter = LibFilters.GetMinFilterType

--Returns the maxium possible filterType
function LibFilters:GetMaxFilterType()
	 return LF_FILTER_MAX
end
LibFilters.GetMaxFilter = LibFilters.GetMaxFilterType

--Returns the LibFilters LF* filterType connstants table: value = "name"
function LibFilters:GetFilterTypes()
	 return libFiltersFilterConstants
end

--Returns the LibFilters LF* filterType connstant's name
function LibFilters:GetFilterTypeName(libFiltersFilterType)
	 return libFiltersFilterConstants[libFiltersFilterType] or ""
end

--Get the current libFilters filterType for the inventoryType, where inventoryType would be e.g. INVENTORY_BACKPACK or
--INVENTORY_BANK, or a SCENE or a control
function LibFilters:GetCurrentFilterTypeForInventory(inventoryType)
	--Get the layoutData from the fragment. If no fragment: Abort
	if inventoryType == INVENTORY_BACKPACK then
		local layoutData = playerInv.appliedLayout
		if layoutData and layoutData.LibFilters3_filterType then
			return layoutData.LibFilters3_filterType
		else
			return
		end
	end
	local invVarIsNumber = (type(inventoryType) == "number") or false
	if not invVarIsNumber then
		--local isGamePad = IsInGamepadPreferredMode()
		--If in gamepad mode: Check if inventoryType is a SCENE, e.g. GAMEPAD_ENCHANTING_CREATION_SCENE
		--if isGamePad then
		if inventoryType.sceneManager ~= nil and inventoryType.LibFilters3_filterType ~= nil then
			return inventoryType.LibFilters3_filterType
		end
		--end
	end
	--Afterwards:
	--Get the inventory from PLAYER_INVENTORY.inventories if the "number" check returns true,
	--and else use inventoryType directly to support enchanting.inventory
	local inventory = (invVarIsNumber and inventories[inventoryType] ~= nil and inventories[inventoryType]) or inventoryType
	if inventory == nil or inventory.LibFilters3_filterType == nil then return end
	return inventory.LibFilters3_filterType
end

--**********************************************************************************************************************
--Hook the inventory layout or inventory to apply additional filter functions
--->Orig function until LibFilters 3.0r3.0, 2021-10-08. Changed to a more dynamic version below
--[[
function LibFilters:HookAdditionalFilter(filterType, inventory)
	 local layoutData = inventory.layoutData or inventory
	 local originalFilter = layoutData.additionalFilter

	 layoutData.LibFilters3_filterType = filterType
	 local additionalFilterType = type(originalFilter)
	 if additionalFilterType == "function" then
		  layoutData.additionalFilter = function(...)
				return originalFilter(...) and runFilters(filterType, ...)
		  end
	 else
		  layoutData.additionalFilter = function(...)
				return runFilters(filterType, ...)
		  end
	 end
end
]]


--Hook the inventory layout or inventory contro, a fragment, scene or userdata to apply the .additionalFilter entry for
--the filter functions registered via LibFilters:RegisterFilter("uniqueName," LF_*constant, callbackFilterFunction)
--> Using only 1 parameter "filterLFConstant" now, to determine the correct control/inventory/scene/fragment/userdata to
--> apply the entry .additionalFilter to from the constants table LF_ConstantToAdditionalFilterControlSceneFragmentUserdata
--> at the beginning of this file!
--> As the table could contain multiple variables to hook into per LF_* constant there needs to be a loop over the entries
function LibFilters:HookAdditionalFilter(filterLFConstant, hookKeyboardAndGamepadMode)
	local function hookNowSpecial(inventoriesToHookForLFConstant_Table)
		if not inventoriesToHookForLFConstant_Table then
			dfe("HookAdditionalFilter SPECIAL-table of hooks is empty for LF_ constant %s, keyboardAndGamepadMode: %s", tostring(filterLFConstant), tostring(hookKeyboardAndGamepadMode))
			return
		end
		local funcName = inventoriesToHookForLFConstant_Table.funcName
		if funcName ~= nil and funcName ~= "" and LibFilters[funcName] ~= nil then
			local params = inventoriesToHookForLFConstant_Table.params
			LibFilters[funcName](LibFilters, unpack(params)) --pass LibFilters as 1st param "self" TODO: needed?
		end
	end
	local function hookNow(inventoriesToHookForLFConstant_Table)
		if not inventoriesToHookForLFConstant_Table then
			dfe("HookAdditionalFilter-table of hooks is empty for LF_ constant %s, keyboardAndGamepadMode: %s", tostring(filterLFConstant), tostring(hookKeyboardAndGamepadMode))
			return
		end
		for _, inventory in ipairs(inventoriesToHookForLFConstant_Table) do
			if inventory ~= nil then
				local layoutData = inventory.layoutData or inventory
				local originalFilter = layoutData.additionalFilter

				layoutData.LibFilters3_filterType = filterLFConstant
				local additionalFilterType = type(originalFilter)
				if additionalFilterType == "function" then
					layoutData.additionalFilter = function(...)
						return originalFilter(...) and runFilters(filterLFConstant, ...)
					end
				else
					layoutData.additionalFilter = function(...)
						return runFilters(filterLFConstant, ...)
					end
				end
			end
		end
	end
------------------------------------------------------------------------------------------------------------------------
	--Should the LF constant be hooked by any special function of LibFilters?
	--e.g. run LibFilters:HookAdditionalFilterSpecial("enchanting")
	local inventoriesToHookForLFConstant
	local hookSpecialFunctionDataOfLFConstant = LF_ConstantToAdditionalFilterSpecialHook[filterLFConstant]
	if hookSpecialFunctionDataOfLFConstant ~= nil then
		if hookKeyboardAndGamepadMode == true then
			--Keyboard
			inventoriesToHookForLFConstant = hookSpecialFunctionDataOfLFConstant[false]
			hookNowSpecial(inventoriesToHookForLFConstant)
			--Gamepad
			inventoriesToHookForLFConstant = hookSpecialFunctionDataOfLFConstant[true]
			hookNowSpecial(inventoriesToHookForLFConstant)
		else
			--Only currently detected mode, gamepad or keyboard
			inventoriesToHookForLFConstant = hookSpecialFunctionDataOfLFConstant[IsGamepad()]
			hookNowSpecial(inventoriesToHookForLFConstant)
		end
	else
		--Hook normal via the given control/scene/fragment etc. -> See table LF_ConstantToAdditionalFilterControlSceneFragmentUserdata
		if hookKeyboardAndGamepadMode == true then
			--Keyboard
			inventoriesToHookForLFConstant = LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[false][filterLFConstant]
			hookNow(inventoriesToHookForLFConstant)
			--Gamepad
			inventoriesToHookForLFConstant = LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[true][filterLFConstant]
			hookNow(inventoriesToHookForLFConstant)
		else
			--Only currently detected mode, gamepad or keyboard
			inventoriesToHookForLFConstant = LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[IsGamepad()][filterLFConstant]
			hookNow(inventoriesToHookForLFConstant)
		end
	end
end
hookAdditionalFilter = LibFilters.HookAdditionalFilter


--Hook the inventory in a special way, e.g. at ENCHANTING where there is only 1 inventory variable and no
--extra fragment for the different modes (creation, extraction).
local specialHooksLibFiltersDataRegistered = {}
function LibFilters:HookAdditionalFilterSpecial(specialType)
	 if specialHooksDone[specialType] == true then return end

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
		ZO_PreHook(enchantingClass, "OnModeUpdated", function(selfEnchanting)
			onEnchantingModeUpdated(selfEnchanting, selfEnchanting.enchantingMode)
		end)
		specialHooksDone[specialType] = true


	--ENCHANTING gamepad
	--[[
	elseif specialType == "enchanting_GamePad" then

		local function updateAdditionalFiltersAtGamepadEnchantingInventory(enchantingVar, enchantingMode)
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
		local enchantingMode = ENCHANTING_MODE_NONE
     	--Enchanting creation scene gamepad
		GAMEPAD_ENCHANTING_CREATION_SCENE:RegisterCallback("StateChange", function(oldState, newState)
			if newState == SCENE_SHOWING then
				enchantingMode = ENCHANTING_MODE_CREATION
				updateAdditionalFiltersAtGamepadEnchantingInventory(enchanting_GP, enchantingMode)
			elseif newState == SCENE_SHOWN then
				enchantingMode = ENCHANTING_MODE_CREATION
			elseif newState == SCENE_HIDING then
				enchantingMode = ENCHANTING_MODE_NONE
			end
		end)
		--Enchanting extraction scene gamepad
		GAMEPAD_ENCHANTING_EXTRACTION_SCENE:RegisterCallback("StateChange", function(oldState, newState)
			if newState == SCENE_SHOWING then
				enchantingMode = ENCHANTING_MODE_EXTRACTION
				updateAdditionalFiltersAtGamepadEnchantingInventory(enchanting_GP, enchantingMode)
			elseif newState == SCENE_SHOWN then
				enchantingMode = ENCHANTING_MODE_EXTRACTION
			elseif newState == SCENE_HIDING then
				enchantingMode = ENCHANTING_MODE_NONE
			end
		end)
		specialHooksDone[specialType] = true
	]]
	end
end

--**********************************************************************************************************************
-- Filter callback and un/register
function LibFilters:GetFilterCallback(filterTag, filterType)
	 if not self:IsFilterRegistered(filterTag, filterType) then return end

	 return filters[filterType][filterTag]
end

function LibFilters:IsFilterRegistered(filterTag, filterType)
	 if filterType == nil then
		  --check whether there's any filter with this tag
		  for _, callbacks in pairs(filters) do
				if callbacks[filterTag] ~= nil then
					 return true
				end
		  end

		  return false
	 else
		  --check only the specified filter type
		  local callbacks = filters[filterType]

		  return callbacks[filterTag] ~= nil
	 end
end

function LibFilters:RegisterFilter(filterTag, filterType, filterCallback)
	 local callbacks = filters[filterType]

	 if not filterTag or not callbacks or type(filterCallback) ~= "function" then
		  dfe("Invalid arguments to RegisterFilter(%q, %s, %s).\n>Needed format is: String uniqueFilterTag, number LibFiltersLF_*FilterPanelConstant, function filterCallbackFunction",
				tostring(filterTag), tostring(filterType), tostring(filterCallback))
		  return
	 end

	 if callbacks[filterTag] ~= nil then
		  dfe("filterTag \'%q\' filterType \'%s\' filterCallback function is already in use",
				tostring(filterTag), tostring(filterType))
		  return
	 end

	 callbacks[filterTag] = filterCallback
end

function LibFilters:UnregisterFilter(filterTag, filterType)
	 if not filterTag or filterTag == "" then
		  dfe("Invalid arguments to UnregisterFilter(%s, %s).\n>Needed format is: String filterTag, number filterPanelId", tostring(filterTag), tostring(filterType))
		  return
	 end
	 if filterType == nil then
		  --unregister all filters with this tag
		  for _, callbacks in pairs(filters) do
				if callbacks[filterTag] ~= nil then
					 callbacks[filterTag] = nil
				end
		  end
	 else
		  --unregister only the specified filter type
		  local callbacks = filters[filterType]

		  if callbacks[filterTag] ~= nil then
				callbacks[filterTag] = nil
		  end
	 end
end

--**********************************************************************************************************************
-- Filter update
function LibFilters:RequestUpdate(filterType)
--d("[LibFilters3]RequestUpdate-filterType: " ..tostring(filterType))
	 local updaterName = filterTypeToUpdaterName[filterType]
	 if not updaterName or updaterName == "" then
		  dfe("Invalid arguments to RequestUpdate(%s).\n>Needed format is: number filterPanelId", tostring(filterType))
		  return
	 end
	 local callbackName = "LibFilters_updateInventory_" .. updaterName
	 local function Update()
--d(">[LibFilters3]RequestUpdate->Update called")
		  EM:UnregisterForUpdate(callbackName)
		  inventoryUpdaters[updaterName]()
	 end

	 --cancel previously scheduled update if any
	 EM:UnregisterForUpdate(callbackName)
	 --register a new one
	 EM:RegisterForUpdate(callbackName, 10, Update)
end


--**********************************************************************************************************************
-- Special API
function LibFilters:SetResearchLineLoopValues(fromResearchLineIndex, toResearchLineIndex, skipTable)
	 local craftingType = GetCraftingInteractionType()
	 if craftingType == CRAFTING_TYPE_INVALID then return false end
	 if not fromResearchLineIndex or fromResearchLineIndex <= 0 then fromResearchLineIndex = 1 end
	 local numSmithingResearchLines = GetNumSmithingResearchLines(craftingType)
	 if not toResearchLineIndex or toResearchLineIndex > numSmithingResearchLines then
		  toResearchLineIndex = numSmithingResearchLines
	 end
	 local helpers = LibFilters.helpers
	 if not helpers then return end
	 local smithingResearchPanel = helpers["SMITHING.researchPanel:Refresh"].locations[1]
	 if smithingResearchPanel then
		  smithingResearchPanel.LibFilters_3ResearchLineLoopValues = {
				from		  =fromResearchLineIndex,
				to			 =toResearchLineIndex,
				skipTable	=skipTable,
		  }
	 end
end

--**********************************************************************************************************************
-- END LibFilters API functions END
--**********************************************************************************************************************
--**********************************************************************************************************************
--**********************************************************************************************************************


--**********************************************************************************************************************
--Register all the helper functions of LibFilters, for some special panels like the Research or ResearchDialog, or
--even deconstruction and improvement, etc.
--These helper funmctions might overwrite original ESO functions in order to use their own "predicate" or
-- "filterFunction".  So check them if the orig functions update, and upate them as well.
--> See file helper.lua
LibFilters.helpers = {}
local helpers = LibFilters.helpers

--Install the helpers from table helpers now -> See file helper.lua, table "helpers"
local function InstallHelpers()
	 for _, package in pairs(helpers) do
		  local funcName = package.helper.funcName
		  local func = package.helper.func

		  for _, location in pairs(package.locations) do
				--e.g. ZO_SmithingExtractionInventory["GetIndividualInventorySlotsAndAddToScrollData"] = overwritten
				--function from helpers table, param "func"
				location[funcName] = func
		  end
	 end
end


--**********************************************************************************************************************
--**********************************************************************************************************************
--**********************************************************************************************************************
--Fixes which are needed
local function ApplyFixes()
	--Fix for the CraftBag on PTS API100035, v7.0.4-> As ApplyBackpackLayout currently always overwrites the additionalFilter :-(
	--[[
		 --Added lines with 7.0.4:
		 local craftBag = self.inventories[INVENTORY_CRAFT_BAG]
		 craftBag.additionalFilter = layoutData.additionalFilter
	]]
	SecurePostHook(playerInv, "ApplyBackpackLayout", function(layoutData)
	--d("ApplyBackpackLayout-ZO_CraftBag:IsHidden(): " ..tostring(ZO_CraftBag:IsHidden()))
		if craftBagClass:IsHidden() then return end
		--Re-Apply the .additionalFilter to CraftBag again, on each open of it
		hookAdditionalFilter(LibFilters, LF_CRAFTBAG)
	end)
end


--**********************************************************************************************************************
--**********************************************************************************************************************
--**********************************************************************************************************************
--Function needed to be called from your addon to start the LibFilters instance and enable the filtering!
function LibFilters:InitializeLibFilters()
	 if self.isInitialized then return end
	 self.isInitialized = true

	 InstallHelpers()
	 HookAdditionalFilters()
end

--______________________________________________________________________________________________________________________
--______________________________________________________________________________________________________________________
--______________________________________________________________________________________________________________________
--Apply any fixes needed to be run before EVENT_ADD_ON_LOADED
ApplyFixes()
