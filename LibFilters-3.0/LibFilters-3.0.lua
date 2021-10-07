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
local MAJOR, GlobalLibName, MINOR = "LibFilters-3.0", "LibFilters3", 2.3

--Was the library loaded already?
if _G[GlobalLibName] ~= nil then return end

--Local library variable
local LibFilters = {}

--Global library constant
_G[GlobalLibName]	= LibFilters
LibFilters.name	  = MAJOR
LibFilters.version  = MINOR

--Other libraries

--LibDebugLogger
if LibDebugLogger then
	 if not not LibFilters.logger then
		  LibFilters.logger = LibDebugLogger(MAJOR)
	 end
end
local logger = LibFilters.logger

--Local speed up variables
local IsGamepad = IsInGamepadPreferredMode

------------------------------------------------------------------------------------------------------------------------
--The possible LibFilters filterPanelIds
--**********************************************************************************************************************
-- LibFilters filterPanel constants [value number] = "name"
--**********************************************************************************************************************
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
end
LibFilters.filterTypes = libFiltersFilterConstants

--Get the min and max filterPanelIds
LF_FILTER_MIN					= LF_INVENTORY
LF_FILTER_MAX					= #libFiltersFilterConstants


LibFilters.isInitialized = false

--Some inventory variables
local inventories =			PLAYER_INVENTORY.inventories

--Some crafting variables
local refinementPanel =	  		SMITHING.refinementPanel
local deconstructionPanel = 	SMITHING.deconstructionPanel
local improvementPanel =	 	SMITHING.improvementPanel
local researchPanel =		 	SMITHING.researchPanel

local refinementPanel_GP =	  	SMITHING_GAMEPAD.refinementPanel
local deconstructionPanel_GP = 	SMITHING_GAMEPAD.deconstructionPanel
local improvementPanel_GP =	 	SMITHING_GAMEPAD.improvementPanel
local researchPanel_GP =		SMITHING_GAMEPAD.researchPanel

local enchantingClass =	  		ZO_Enchanting
local enchantingClass_GP = 		ZO_GamepadEnchanting
local enchanting =			 	ENCHANTING
local enchanting_GP = 			GAMEPAD_ENCHANTING

local alchemy = 				ALCHEMY
local alchemy_GP = 				GAMEPAD_ALCHEMY

--local retraitClass =		  ZO_RetraitStation_Retrait_Base
local retrait =				 	ZO_RETRAIT_KEYBOARD
local retrait_GP = 				ZO_RETRAIT_STATION_GAMEPAD


--Special hooks
local specialHooksDone = {
	 ["enchanting"] = false,
}

--Mappings

--Mapping for crafting
local enchantingModeToFilterType = {
	 [ENCHANTING_MODE_CREATION]		= LF_ENCHANTING_CREATION,
	 [ENCHANTING_MODE_EXTRACTION]	= LF_ENCHANTING_EXTRACTION,
	 [ENCHANTING_MODE_RECIPES]		= nil --not supported yet
}


--The filters of the different FilterPanelIds will be registered to these sub-tables
LibFilters.filters = {
	 [LF_INVENTORY] = {},
	 [LF_BANK_WITHDRAW] = {},
	 [LF_BANK_DEPOSIT] = {},
	 [LF_GUILDBANK_WITHDRAW] = {},
	 [LF_GUILDBANK_DEPOSIT] = {},
	 [LF_VENDOR_BUY] = {},
	 [LF_VENDOR_SELL] = {},
	 [LF_VENDOR_BUYBACK] = {},
	 [LF_VENDOR_REPAIR] = {},
	 [LF_GUILDSTORE_BROWSE] = {},
	 [LF_GUILDSTORE_SELL] = {},
	 [LF_MAIL_SEND] = {},
	 [LF_TRADE] = {},
	 [LF_SMITHING_REFINE] = {},
	 [LF_SMITHING_CREATION] = {},
	 [LF_SMITHING_DECONSTRUCT] = {},
	 [LF_SMITHING_IMPROVEMENT] = {},
	 [LF_SMITHING_RESEARCH] = {},
	 [LF_ALCHEMY_CREATION] = {},
	 [LF_ENCHANTING_CREATION] = {},
	 [LF_ENCHANTING_EXTRACTION] = {},
	 [LF_PROVISIONING_COOK] = {},
	 [LF_PROVISIONING_BREW] = {},
	 [LF_FENCE_SELL] = {},
	 [LF_FENCE_LAUNDER] = {},
	 [LF_CRAFTBAG] = {},
	 [LF_QUICKSLOT] = {},
	 [LF_RETRAIT] = {},
	 [LF_HOUSE_BANK_WITHDRAW] = {},
	 [LF_HOUSE_BANK_DEPOSIT] = {},
	 [LF_JEWELRY_REFINE]		= {},
	 [LF_JEWELRY_CREATION]	 = {},
	 [LF_JEWELRY_DECONSTRUCT] = {},
	 [LF_JEWELRY_IMPROVEMENT] = {},
	 [LF_JEWELRY_RESEARCH]	 = {},
	 [LF_SMITHING_RESEARCH_DIALOG] = {},
	 [LF_JEWELRY_RESEARCH_DIALOG] = {},
	 [LF_INVENTORY_QUEST] = {},
	 [LF_INVENTORY_COMPANION] = {},
}
local filters = LibFilters.filters

--The fixed updater names for the LibFilters unique updater string
local filterTypeToUpdaterNameFixed = {
	 [LF_BANK_WITHDRAW]				  = "BANK_WITHDRAW",
	 [LF_GUILDBANK_WITHDRAW]			= "GUILDBANK_WITHDRAW",
	 [LF_VENDOR_BUY]					  = "VENDOR_BUY",
	 [LF_VENDOR_BUYBACK]				 = "VENDOR_BUYBACK",
	 [LF_VENDOR_REPAIR]				  = "VENDOR_REPAIR",
	 [LF_GUILDSTORE_BROWSE]			 = "GUILDSTORE_BROWSE",
	 [LF_ALCHEMY_CREATION]			  = "ALCHEMY_CREATION",
	 [LF_PROVISIONING_COOK]			 = "PROVISIONING_COOK",
	 [LF_PROVISIONING_BREW]			 = "PROVISIONING_BREW",
	 [LF_CRAFTBAG]						 = "CRAFTBAG",
	 [LF_QUICKSLOT]						= "QUICKSLOT",
	 [LF_RETRAIT]						  = "RETRAIT",
	 [LF_HOUSE_BANK_WITHDRAW]		  = "HOUSE_BANK_WITHDRAW",
	 [LF_INVENTORY_QUEST]				= "INVENTORY_QUEST",
	 [LF_INVENTORY_COMPANION]		  = "INVENTORY_COMPANION"
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

--Update the inventory lists
--if the mouse is enabled, cycle its state to refresh the integrity of the control beneath it
local function SafeUpdateList(object, ...)
--d("[LibFilters3]SafeUpdateList, inv: " ..tostring(...))
	 local isMouseVisible = SCENE_MANAGER:IsInUIMode()

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
		  if listDialogControl == SMITHING_RESEARCH_SELECT then
				if data.craftingType and data.researchLineIndex and data.traitIndex then
					 --Re-Call the dialog's setup function to clear the list, check available data and filter the items (see helper.lua, helpers["SMITHING_RESEARCH_SELECT"])
					 listDialogControl.SetupDialog(listDialogControl, data.craftingType, data.researchLineIndex, data.traitIndex)
				end
		  end
	 end
end

--The updater functions for the inventories
local inventoryUpdaters = {
	 INVENTORY = function()
		  SafeUpdateList(PLAYER_INVENTORY, INVENTORY_BACKPACK)
	 end,
	 BANK_WITHDRAW = function()
		  SafeUpdateList(PLAYER_INVENTORY, INVENTORY_BANK)
	 end,
	 GUILDBANK_WITHDRAW = function()
		  SafeUpdateList(PLAYER_INVENTORY, INVENTORY_GUILD_BANK)
	 end,
	 VENDOR_BUY = function()
		  if BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT.state ~= SCENE_SHOWN then --"shown"
				STORE_WINDOW:GetStoreItems()
				SafeUpdateList(STORE_WINDOW)
		  end
	 end,
	 VENDOR_BUYBACK = function()
		  SafeUpdateList(BUY_BACK_WINDOW)
	 end,
	 VENDOR_REPAIR = function()
		  SafeUpdateList(REPAIR_WINDOW)
	 end,
	 GUILDSTORE_BROWSE = function()
	 end,
	 SMITHING_REFINE = function()
		  if IsGamepad() then
				refinementPanel_GP.inventory:HandleDirtyEvent()
		  else
				refinementPanel.inventory:HandleDirtyEvent()
		  end
	 end,
	 SMITHING_CREATION = function()
		  --[[
		  if IsGamepad() then
		  else
		  end
		  ]]
	 end,
	 SMITHING_DECONSTRUCT = function()
		  if IsGamepad() then
				deconstructionPanel_GP.inventory:HandleDirtyEvent()
		  else
				deconstructionPanel.inventory:HandleDirtyEvent()
		  end
	 end,
	 SMITHING_IMPROVEMENT = function()
		  if IsGamepad() then
				improvementPanel_GP.inventory:HandleDirtyEvent()
		  else
				improvementPanel.inventory:HandleDirtyEvent()
		  end
	 end,
	 SMITHING_RESEARCH = function()
		  if IsGamepad() then
				researchPanel_GP:Refresh()
		  else
				researchPanel:Refresh()
		  end
	 end,
	 ALCHEMY_CREATION = function()
		  if IsGamepad() then
			  alchemy_GP.inventory:HandleDirtyEvent()
		  else
		      alchemy.inventory:HandleDirtyEvent()
		  end
	 end,
	 ENCHANTING = function()
		  if IsGamepad() then
		  	  enchanting_GP.inventory:HandleDirtyEvent()
		  else
		  	  enchanting.inventory:HandleDirtyEvent()
		  end
	 end,
	 PROVISIONING_COOK = function()
	 end,
	 PROVISIONING_BREW = function()
	 end,
	 CRAFTBAG = function()
		  SafeUpdateList(PLAYER_INVENTORY, INVENTORY_CRAFT_BAG)
	 end,
	 QUICKSLOT = function()
		  SafeUpdateList(QUICKSLOT_WINDOW)
	 end,
	 RETRAIT = function()
		  if IsGamepad() then
		  	  retrait_GP:HandleDirtyEvent()
		  else
		      retrait.inventory:HandleDirtyEvent()
		  end
	 end,
	 HOUSE_BANK_WITHDRAW = function()
		  SafeUpdateList(PLAYER_INVENTORY, INVENTORY_HOUSE_BANK )
	 end,
	 SMITHING_RESEARCH_DIALOG = function()
		  dialogUpdaterFunc(SMITHING_RESEARCH_SELECT)
	 end,
	 RECONSTRUCTION = function()
		  ZO_RECONSTRUCT_KEYBOARD.inventory:HandleDirtyEvent()
	 end,
	 INVENTORY_QUEST = function()
		  SafeUpdateList(PLAYER_INVENTORY, INVENTORY_QUEST_ITEM)
	 end,
	 INVENTORY_COMPANION = function()
		  SafeUpdateList(COMPANION_EQUIPMENT_KEYBOARD, nil)
	 end
}
LibFilters.inventoryUpdaters = inventoryUpdaters


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

--Hook all the filters at the different inventory panels (LibFilters filterPanelIds) now
local function HookAdditionalFilters()
------------------------------------------------------------------------------------------------------------------------
	 --Keyboard -v-
------------------------------------------------------------------------------------------------------------------------
	 --Inventories
	 LibFilters:HookAdditionalFilter(LF_INVENTORY, inventories[INVENTORY_BACKPACK])
	 LibFilters:HookAdditionalFilter(LF_INVENTORY, BACKPACK_MENU_BAR_LAYOUT_FRAGMENT)

	 LibFilters:HookAdditionalFilter(LF_INVENTORY_QUEST, inventories[INVENTORY_QUEST_ITEM])
	 LibFilters:HookAdditionalFilter(LF_INVENTORY_COMPANION, COMPANION_EQUIPMENT_KEYBOARD)

	 --Craftbag
	 LibFilters:HookAdditionalFilter(LF_CRAFTBAG, inventories[INVENTORY_CRAFT_BAG])

	 --Quickslots
	 LibFilters:HookAdditionalFilter(LF_QUICKSLOT, QUICKSLOT_WINDOW)

	 --Banks
	 LibFilters:HookAdditionalFilter(LF_BANK_WITHDRAW, inventories[INVENTORY_BANK])
	 LibFilters:HookAdditionalFilter(LF_BANK_DEPOSIT, BACKPACK_BANK_LAYOUT_FRAGMENT)

	 LibFilters:HookAdditionalFilter(LF_GUILDBANK_WITHDRAW, inventories[INVENTORY_GUILD_BANK])
	 LibFilters:HookAdditionalFilter(LF_GUILDBANK_DEPOSIT, BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT)

	 LibFilters:HookAdditionalFilter(LF_HOUSE_BANK_WITHDRAW, inventories[INVENTORY_HOUSE_BANK])
	 LibFilters:HookAdditionalFilter(LF_HOUSE_BANK_DEPOSIT, BACKPACK_HOUSE_BANK_LAYOUT_FRAGMENT)

	 --Vendors
	 LibFilters:HookAdditionalFilter(LF_VENDOR_BUY, STORE_WINDOW)
	 LibFilters:HookAdditionalFilter(LF_VENDOR_SELL, BACKPACK_STORE_LAYOUT_FRAGMENT)
	 LibFilters:HookAdditionalFilter(LF_VENDOR_BUYBACK, BUY_BACK_WINDOW)
	 LibFilters:HookAdditionalFilter(LF_VENDOR_REPAIR, REPAIR_WINDOW)

	 --Fence & launder
	 LibFilters:HookAdditionalFilter(LF_FENCE_SELL, BACKPACK_FENCE_LAYOUT_FRAGMENT)
	 LibFilters:HookAdditionalFilter(LF_FENCE_LAUNDER, BACKPACK_LAUNDER_LAYOUT_FRAGMENT)

	 --Guild store
	 --LibFilters:HookAdditionalFilter(LF_GUILDSTORE_BROWSE, )
	 LibFilters:HookAdditionalFilter(LF_GUILDSTORE_SELL, BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT)

	 --Send Mail
	 LibFilters:HookAdditionalFilter(LF_MAIL_SEND, BACKPACK_MAIL_LAYOUT_FRAGMENT)

	 --Player 2 player trade
	 LibFilters:HookAdditionalFilter(LF_TRADE, BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT)

	 --Crafting
	 LibFilters:HookAdditionalFilter(LF_SMITHING_REFINE, refinementPanel.inventory)
	 --LibFilters:HookAdditionalFilter(LF_SMITHING_CREATION, )
	 LibFilters:HookAdditionalFilter(LF_SMITHING_DECONSTRUCT, deconstructionPanel.inventory)
	 LibFilters:HookAdditionalFilter(LF_SMITHING_IMPROVEMENT, improvementPanel.inventory)
	 LibFilters:HookAdditionalFilter(LF_SMITHING_RESEARCH, researchPanel)
	 LibFilters:HookAdditionalFilter(LF_JEWELRY_REFINE, refinementPanel.inventory)
	 --LibFilters:HookAdditionalFilter(LF_JEWELRY_CREATION, )
	 LibFilters:HookAdditionalFilter(LF_JEWELRY_DECONSTRUCT, deconstructionPanel.inventory)
	 LibFilters:HookAdditionalFilter(LF_JEWELRY_IMPROVEMENT, improvementPanel.inventory)
	 LibFilters:HookAdditionalFilter(LF_JEWELRY_RESEARCH, researchPanel)

	 LibFilters:HookAdditionalFilter(LF_SMITHING_RESEARCH_DIALOG, SMITHING_RESEARCH_SELECT)
	 LibFilters:HookAdditionalFilter(LF_JEWELRY_RESEARCH_DIALOG, SMITHING_RESEARCH_SELECT)

	 LibFilters:HookAdditionalFilter(LF_ALCHEMY_CREATION, alchemy.inventory)
	 --LibFilters:HookAdditionalFilter(LF_PROVISIONING_COOK, )
	 --LibFilters:HookAdditionalFilter(LF_PROVISIONING_BREW, )

	 LibFilters:HookAdditionalFilter(LF_RETRAIT, retrait)

	--The commented lines below do not work! Same inventory, would always return LF_ENCHANTING_EXTRACTION (as it was
	--added at last)
	--LibFilters:HookAdditionalFilter(LF_ENCHANTING_CREATION, ENCHANTING.inventory)
	--LibFilters:HookAdditionalFilter(LF_ENCHANTING_EXTRACTION, ENCHANTING.inventory)
	--So this new function call here splits it up properly
	 LibFilters:HookAdditionalFilterSpecial("enchanting", enchanting.inventory)

	------------------------------------------------------------------------------------------------------------------------
	 --Keyboard -^-
------------------------------------------------------------------------------------------------------------------------
	 --Gamepad -v-
------------------------------------------------------------------------------------------------------------------------
	
--	COMPANION_GAMEPAD_FRAGMENT
--	OMPANION_EQUIPMENT_GAMEPAD	-- object
--	COMPANION_EQUIPMENT_GAMEPAD_SCENE
--	COMPANION_EQUIPMENT_GAMEPAD_FRAGMENT
 --	LibFilters:HookAdditionalFilter(LF_INVENTORY_COMPANION, COMPANION_EQUIPMENT_KEYBOARD)

	 --Craftbag
--	LibFilters:HookAdditionalFilter(LF_CRAFTBAG, inventories[INVENTORY_CRAFT_BAG])


	 --Banks
 --	LibFilters:HookAdditionalFilter(LF_BANK_WITHDRAW, inventories[INVENTORY_BANK])
 --	LibFilters:HookAdditionalFilter(LF_BANK_DEPOSIT, BACKPACK_BANK_LAYOUT_FRAGMENT)

 --	LibFilters:HookAdditionalFilter(LF_GUILDBANK_WITHDRAW, inventories[INVENTORY_GUILD_BANK])
 --	LibFilters:HookAdditionalFilter(LF_GUILDBANK_DEPOSIT, BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT)

--	 LibFilters:HookAdditionalFilter(LF_HOUSE_BANK_WITHDRAW, inventories[INVENTORY_HOUSE_BANK])
--	 LibFilters:HookAdditionalFilter(LF_HOUSE_BANK_DEPOSIT, BACKPACK_HOUSE_BANK_LAYOUT_FRAGMENT)

	 --Vendors
  --  LibFilters:HookAdditionalFilter(LF_VENDOR_BUY, STORE_WINDOW)
 --	LibFilters:HookAdditionalFilter(LF_VENDOR_SELL, BACKPACK_STORE_LAYOUT_FRAGMENT)
  --  LibFilters:HookAdditionalFilter(LF_VENDOR_BUYBACK, BUY_BACK_WINDOW)
 --	LibFilters:HookAdditionalFilter(LF_VENDOR_REPAIR, REPAIR_WINDOW)

	 --Fence & launder
--	 LibFilters:HookAdditionalFilter(LF_FENCE_SELL, BACKPACK_FENCE_LAYOUT_FRAGMENT)
--	 LibFilters:HookAdditionalFilter(LF_FENCE_LAUNDER, BACKPACK_LAUNDER_LAYOUT_FRAGMENT)

	 --Guild store
  ---  LibFilters:HookAdditionalFilter(LF_GUILDSTORE_SELL, BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT)

	 --Send Mail
 --	LibFilters:HookAdditionalFilter(LF_MAIL_SEND, BACKPACK_MAIL_LAYOUT_FRAGMENT)
--	 LibFilters:HookAdditionalFilter(LF_TRADE, BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT)

	LibFilters:HookAdditionalFilter(LF_SMITHING_REFINE, refinementPanel_GP.inventory)
	LibFilters:HookAdditionalFilter(LF_SMITHING_DECONSTRUCT, deconstructionPanel_GP.inventory)
	LibFilters:HookAdditionalFilter(LF_SMITHING_IMPROVEMENT, improvementPanel_GP.inventory)
	LibFilters:HookAdditionalFilter(LF_SMITHING_RESEARCH, researchPanel_GP)
	LibFilters:HookAdditionalFilter(LF_SMITHING_RESEARCH_DIALOG, GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE)

	LibFilters:HookAdditionalFilter(LF_JEWELRY_REFINE, refinementPanel_GP.inventory)
	LibFilters:HookAdditionalFilter(LF_JEWELRY_DECONSTRUCT, deconstructionPanel_GP.inventory)
    LibFilters:HookAdditionalFilter(LF_JEWELRY_IMPROVEMENT, improvementPanel_GP.inventory)
	LibFilters:HookAdditionalFilter(LF_JEWELRY_RESEARCH, researchPanel_GP)
	LibFilters:HookAdditionalFilter(LF_JEWELRY_RESEARCH_DIALOG, GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE)

	LibFilters:HookAdditionalFilter(LF_ALCHEMY_CREATION, alchemy_GP.inventory)

	LibFilters:HookAdditionalFilter(LF_RETRAIT, retrait_GP)

	--LibFilters:HookAdditionalFilter(LF_ENCHANTING_CREATION, GAMEPAD_ENCHANTING_CREATION_SCENE)
	--LibFilters:HookAdditionalFilter(LF_ENCHANTING_EXTRACTION, GAMEPAD_ENCHANTING_EXTRACTION_SCENE)
	--The commented lines below do not work! Same inventory, would always return LF_ENCHANTING_EXTRACTION (as it was
	--added at last)
	--LibFilters:HookAdditionalFilter(LF_ENCHANTING_CREATION, enchanting_GP.inventory)
	--LibFilters:HookAdditionalFilter(LF_ENCHANTING_EXTRACTION, enchanting_GP.inventory)
	--So this new function call here splits it up properly
	 LibFilters:HookAdditionalFilterSpecial("enchanting_GamePad", enchanting_GP.inventory)

------------------------------------------------------------------------------------------------------------------------
	 --Gamepad -^-
------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------
	 --Keyboard & Gamepad -v-
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
	 --Keyboard & Gamepad -^-
------------------------------------------------------------------------------------------------------------------------


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
		local layoutData = PLAYER_INVENTORY.appliedLayout
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

--Hook the inventory in a special way, e.g. at ENCHANTING where there is only 1 inventory variable and no
--extra fragment for the different modes (creation, extraction).
local specialHooksLibFiltersDataRegistered = {}
function LibFilters:HookAdditionalFilterSpecial(specialType, inventory)
	 if specialHooksDone[specialType] == true then return end

	--ENCHANTING keyboard
	if specialType == "enchanting" then

		local function onEnchantingModeUpdated(enchantingVar, enchantingMode)
d("[LibFilters3]onEnchantingModeUpdated-enchantingMode: " ..tostring(enchantingMode))
LibFilters3._enchantingVar = enchantingVar

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
		local enchantingVar = enchanting_GP
		local enchantingMode = ENCHANTING_MODE_NONE
     	--Enchanting creation scene gamepad
		GAMEPAD_ENCHANTING_CREATION_SCENE:RegisterCallback("StateChange", function(oldState, newState)
			if newState == SCENE_SHOWING then
				enchantingMode = ENCHANTING_MODE_CREATION
				updateAdditionalFiltersAtGamepadEnchantingInventory(enchantingVar, enchantingMode)
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
				updateAdditionalFiltersAtGamepadEnchantingInventory(enchantingVar, enchantingMode)
			elseif newState == SCENE_SHOWN then
				enchantingMode = ENCHANTING_MODE_EXTRACTION
			elseif newState == SCENE_HIDING then
				enchantingMode = ENCHANTING_MODE_NONE
			end
		end)
		specialHooksDone[specialType] = true
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
		  EVENT_MANAGER:UnregisterForUpdate(callbackName)
		  inventoryUpdaters[updaterName]()
	 end

	 --cancel previously scheduled update if any
	 EVENT_MANAGER:UnregisterForUpdate(callbackName)
	 --register a new one
	 EVENT_MANAGER:RegisterForUpdate(callbackName, 10, Update)
end


--**********************************************************************************************************************
-- Special API
function LibFilters:SetResearchLineLoopValues(fromResearchLineIndex, toResearchLineIndex, skipTable)
	 local craftingType = GetCraftingInteractionType()
	 if craftingType == CRAFTING_TYPE_INVALID then return false end
	 if not fromResearchLineIndex or fromResearchLineIndex <= 0 then fromResearchLineIndex = 1 end
	 if not toResearchLineIndex or toResearchLineIndex > GetNumSmithingResearchLines(craftingType) then
		  toResearchLineIndex = GetNumSmithingResearchLines(craftingType)
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

--Function needed to be called from your addon to start the LibFilters instance and enable the filtering!
function LibFilters:InitializeLibFilters()
	 if self.isInitialized then return end
	 self.isInitialized = true

	 InstallHelpers()
	 HookAdditionalFilters()
end

--Fix for the CraftBag on PTS API100035, v7.0.4-> As ApplyBackpackLayout currently always overwrites the additionalFilter :-(
--[[
	 --Added lines with 7.0.4:
	 local craftBag = self.inventories[INVENTORY_CRAFT_BAG]
	 craftBag.additionalFilter = layoutData.additionalFilter
]]
SecurePostHook(PLAYER_INVENTORY, "ApplyBackpackLayout", function(layoutData)
--d("ApplyBackpackLayout-ZO_CraftBag:IsHidden(): " ..tostring(ZO_CraftBag:IsHidden()))
	 if ZO_CraftBag:IsHidden() then return end
	 LibFilters:HookAdditionalFilter(LF_CRAFTBAG, inventories[INVENTORY_CRAFT_BAG])
end)
