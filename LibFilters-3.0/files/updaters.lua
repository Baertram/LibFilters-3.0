------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3 name, and version
------------------------------------------------------------------------------------------------------------------------
local libFilters 	= LibFilters3

--local MAJOR      	= libFilters.name
--local GlobalLibName = libFilters.globalLibName

------------------------------------------------------------------------------------------------------------------------
--DEBUGGING & LOGGING
------------------------------------------------------------------------------------------------------------------------
--LibDebugLogger, or normal logger d() output
local debugFunctions = libFilters.debugFunctions

local dv 	= debugFunctions.dv


------------------------------------------------------------------------------------------------------------------------
--LOCAL SPEED UP VARIABLES & REFERENCES
------------------------------------------------------------------------------------------------------------------------
--Helper variables of ESO
local tos = tostring

--Game API local speedup
local SM = SCENE_MANAGER
local IsGamepad = IsInGamepadPreferredMode

--LibFilters local speedup and reference variables
--Overall constants & mapping
local constants = 					libFilters.constants
local mapping = 					libFilters.mapping
local functions = 					libFilters.functions


local inventoryTypes = 				constants.inventoryTypes
local invTypeBackpack = 			inventoryTypes["player"]
local invTypeQuest =				inventoryTypes["quest"]
local invTypeBank =					inventoryTypes["bank"]
local invTypeGuildBank =			inventoryTypes["guild_bank"]
local invTypeHouseBank =			inventoryTypes["house_bank"]
local invTypeCraftBag =				inventoryTypes["craftbag"]
local invTypeFurnitureVault = 		inventoryTypes["furnitureVault"]
--local invTypeVengeance = 			inventoryTypes["vengeance"]

--LibFilters fitlerPanelIds - local references
local LF_INVENTORY = LF_INVENTORY
local LF_BANK_WITHDRAW = LF_BANK_WITHDRAW
local LF_BANK_DEPOSIT = LF_BANK_DEPOSIT
local LF_GUILDBANK_WITHDRAW = LF_GUILDBANK_WITHDRAW
local LF_GUILDBANK_DEPOSIT = LF_GUILDBANK_DEPOSIT
local LF_VENDOR_SELL = LF_VENDOR_SELL
local LF_GUILDSTORE_SELL = LF_GUILDSTORE_SELL
local LF_MAIL_SEND = LF_MAIL_SEND
local LF_TRADE = LF_TRADE
local LF_SMITHING_DECONSTRUCT = LF_SMITHING_DECONSTRUCT
local LF_ENCHANTING_EXTRACTION = LF_ENCHANTING_EXTRACTION
local LF_FENCE_SELL = LF_FENCE_SELL
local LF_FENCE_LAUNDER = LF_FENCE_LAUNDER
local LF_HOUSE_BANK_WITHDRAW = LF_HOUSE_BANK_WITHDRAW
local LF_HOUSE_BANK_DEPOSIT = LF_HOUSE_BANK_DEPOSIT
local LF_INVENTORY_COMPANION = LF_INVENTORY_COMPANION
local LF_INVENTORY_QUEST = LF_INVENTORY_QUEST
local LF_FURNITURE_VAULT_WITHDRAW = LF_FURNITURE_VAULT_WITHDRAW
local LF_FURNITURE_VAULT_DEPOSIT = LF_FURNITURE_VAULT_DEPOSIT
local LF_INVENTORY_VENGEANCE = LF_INVENTORY_VENGEANCE
local LF_VENDOR_SELL_VENGEANCE = LF_VENDOR_SELL_VENGEANCE


local libFiltersFilterType2InventoryType = constants.LibFiltersFilterType2InventoryType

local filterTypeToUpdaterNameDynamicINVENTORY = mapping.filterTypeToUpdaterNameDynamic["INVENTORY"]
local getUpdaterCategoryAndItemListNamesByFilterPanelId = libFilters.GetUpdaterCategoryAndItemListNamesByFilterPanelId

--Keyboard
local kbc                      	= 	constants.keyboard
local playerInv                	= 	kbc.playerInv
local quickslots               	=    kbc.quickslots
local store                    	= 	kbc.store
local vendorBuyBack             = 	kbc.vendorBuyBack
local vendorRepair              = 	kbc.vendorRepair
local guildStoreSellFragment   	= 	kbc.guildStoreSellFragment
local researchChooseItemDialog 	= 	kbc.researchChooseItemDialog
local companionEquipment 	   	= 	kbc.companionEquipment
local refinementPanel		   	=   kbc.refinementPanel
local improvementPanel	   	   	=   kbc.improvementPanel
local researchPanel			   	=   kbc.researchPanel
local alchemy                  	= 	kbc.alchemy
local retrait 				   	= 	kbc.retrait
local reconstruct 			 	= 	kbc.reconstruct


--Gamepad
local gpc                       = 	constants.gamepad
local invBackpack_GP            = 	gpc.invBackpack_GP
local invBank_GP                = 	gpc.invBank_GP
local invGuildBank_GP           = 	gpc.invGuildBank_GP
local store_GP                  = 	gpc.store_GP
local store_componentsGP        = 	store_GP.components
local invFurnitureVault_GP		=   gpc.invFurnitureVaultWithdraw_GP

local companionEquipment_GP 	=   gpc.companionEquipment_GP
local refinementPanel_GP	    =   gpc.refinementPanel_GP
local improvementPanel_GP		=   gpc.improvementPanel_GP
local researchPanel_GP          = 	gpc.researchPanel_GP
local researchChooseItemDialog_GP = gpc.researchChooseItemDialog_GP
local alchemy_GP                = 	gpc.alchemy_GP 				--#10
local invMailSend_GP 			= 	gpc.invMailSend_GP
local invPlayerTrade_GP 		= 	gpc.invPlayerTrade_GP
local invGuildStoreSell_GP 		= 	gpc.invGuildStoreSell_GP
local retrait_GP 				= 	gpc.retrait_GP
local reconstruct_GP 			= 	gpc.reconstruct_GP

--Functions
local fixResearchDialogRowOnItemSelectedCallback = functions.fixResearchDialogRowOnItemSelectedCallback
local getDeconstructOrExtractCraftingVarToUpdate = functions.getDeconstructOrExtractCraftingVarToUpdate


------------------------------------------------------------------------------------------------------------------------
--Updater functions, internally for LibFilters
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--KEYBOARD updater functions
------------------------------------------------------------------------------------------------------------------------
--Update the inventory lists
--if the mouse is enabled, cycle its state to refresh the integrity of the control beneath it
local function SafeUpdateList(object, ...)
	if libFilters.debug then
		local updatedName = (object and (object.name or (object.GetName and object:GetName()))
				or (object.list and object.list.GetName and object.list:GetName())
				or (object.container and object.container.GetName and object.container:GetName())
				or (object.control and object.control.GetName and object.control:GetName())
		)
		if updatedName == nil and ... ~= nil then
			if object.inventories ~= nil then
				local playerInventoryInventoriesInvToUpdate = object.inventories[...]
				updatedName = playerInventoryInventoriesInvToUpdate	and playerInventoryInventoriesInvToUpdate.listView
						and playerInventoryInventoriesInvToUpdate.listView.GetName and playerInventoryInventoriesInvToUpdate.listView:GetName()
			end
		end
		updatedName = updatedName or "n/a"
		dv("[U]SafeUpdateList, inv: %s, name: %s", tos(object), tos(updatedName))
	end
	local isMouseVisible = SM:IsInUIMode()
	if isMouseVisible then HideMouse() end
	object:UpdateList(...)
	if isMouseVisible then ShowMouse() end
end

--Function to update a ZO_ListDialog1 dialog's list contents
local function dialogUpdaterFunc(listDialogControl)
	if libFilters.debug then dv("[U]dialogUpdaterFunc, listDialogControl: %s", (listDialogControl ~= nil and listDialogControl.GetName ~= nil and tos(listDialogControl:GetName()) or "listDialogName: n/a")) end
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
					fixResearchDialogRowOnItemSelectedCallback()
				end
		  end
	 end
end

--Updater function for a normal inventory in keyboard mode
local function updateKeyboardPlayerInventoryType(invType)
	if libFilters.debug then dv("[U]updateKeyboardPlayerInventoryType - invType: %s", tos(invType)) end
	SafeUpdateList(playerInv, invType)
end


------------------------------------------------------------------------------------------------------------------------
--KEYBOARD & GAMEPAD updater functions
------------------------------------------------------------------------------------------------------------------------
--Updater function for a crafting inventory in keyboard and gamepad mode
local function updateCraftingInventoryDirty(craftingInventory)
	if libFilters.debug then dv("[U]updateCraftingInventoryDirty - craftingInventory: %s", tos(craftingInventory)) end
	craftingInventory.inventory:HandleDirtyEvent()
end

-- update for LF_BANK_DEPOSIT/LF_GUILDBANK_DEPOSIT/LF_HOUSE_BANK_DEPOSIT/LF_FURNITURE_VAULT_DEPOSIT/LF_MAIL_SEND/LF_TRADE/LF_BANK_WITHDRAW/LF_GUILDBANK_WITHDRAW/LF_HOUSE_BANK_WITHDRAW/LF_FURNITURE_VAULT_WITHDRAW
local function updateFunction_GP_ZO_GamepadInventoryList(gpInvVar, list, callbackFunc)
	if libFilters.debug then dv("[U]updateFunction_GP_ZO_GamepadInventoryList - gpInvVar: %s, list: %s, callbackFunc: %s", tos(gpInvVar), tos(list), tos(callbackFunc)) end
	-- prevent UI errors for lists created OnDeferredInitialization
	if not gpInvVar or not gpInvVar[list] then return end
	gpInvVar[list]:RefreshList(true)  --trigger callback of vanilla ESO
	if callbackFunc then callbackFunc() end
end

-- update for LF_GUILDSTORE_SELL/LF_VENDOR_BUY/LF_VENDOR_BUYBACK/LF_VENDOR_REPAIR/LF_VENDOR_SELL/LF_FENCE_SELL/LF_FENCE_LAUNDER/LF_VENDOR_SELL_VENGEANCE gamepad
local function updateFunction_GP_UpdateList(gpInvVar)
	if libFilters.debug then dv("[U]updateFunction_GP_UpdateList - gpInvVar: %s", tos(gpInvVar)) end
	-- prevent UI errors for lists created OnDeferredInitialization
	if not gpInvVar then return end
	gpInvVar:UpdateList()
end

-- update function for LF_VENDOR_BUY/LF_VENDOR_BUYBACK/LF_VENDOR_REPAIR/LF_VENDOR_SELL/LF_FENCE_SELL/LF_FENCE_LAUNDER/LF_VENDOR_SELL_VENGEANCE gamepad
local function updateFunction_GP_Vendor(storeMode)
	if libFilters.debug then dv("[U]updateFunction_GP_Vendor - storeMode: %s", tos(storeMode)) end
	if not store_componentsGP then return end
	updateFunction_GP_UpdateList(store_componentsGP[storeMode].list)
end

--[[
-- update for LF_INVENTORY_VENGEANCE gamepad
local function updateFunction_GP_VengeanceItemList(gpInvVar)
--d("[LibFilters]updateFunction_GP_VengeanceItemList - gpInvVar: " ..tos(gpInvVar))
	if libFilters.debug then dv("[U]updateFunction_GP_VengeanceItemList - gpInvVar: %s", tos(gpInvVar)) end
	if not gpInvVar.vengeanceItemList or gpInvVar.currentListType ~= "vengeanceItemList" then
		if gpInvVar.vengeanceItemList and gpInvVar.vengeanceItemList:IsEmpty() and gpInvVar.currentListType == "vengeanceCategoryList" then
--d(">itemList is empty, categoryList shows (filtered all items?!)")
		else
--d("<abort due to missing itemList")
			return
		end
	end


	if gpInvVar.RefreshActiveCategoryList and gpInvVar.vengeanceCategoryList:IsActive() then
		--d("<itemList refreshing ...")
		gpInvVar:RefreshActiveCategoryList(true) --trigger callback of vanilla ESO
	elseif gpInvVar.RefreshActiveItemList and gpInvVar.vengeanceItemList:IsActive()  then
		--d("<itemList refreshing ...")
		gpInvVar:RefreshActiveItemList(true) --trigger callback of vanilla ESO
		if gpInvVar.vengeanceItemList:IsEmpty() then
	--d(">itemList is empty!")
			gpInvVar:SwitchActiveList("vengeanceCategoryList")
		else
	--d(">itemList NOT empty, updating RightTooltip and itemActions!")
			gpInvVar:UpdateRightTooltip()
			gpInvVar:RefreshItemActions()
		end
	end
end

-- update for LF_INVENTORY/LF_INVENTORY_COMPANION/LF_INVENTORY_QUEST gamepad
-->--todo 20251207 With vengeance cyrodiil inventory enabled: if we are at normal inventory itemList (e.g. material)
--> todo and all items are filtered it automatically jumps back to the category list and selects currencies -> Error
local function updateFunction_GP_ItemList(gpInvVar)
--d("[LibFilters]updateFunction_GP_ItemListInventory - gpInvVar: " ..tos(gpInvVar))
	if libFilters.debug then dv("[U]updateFunction_GP_ItemList - gpInvVar: %s", tos(gpInvVar)) end
	if not gpInvVar.itemList or gpInvVar.currentListType ~= "itemList" then
		--todo 20251102 If we are in companion inventory and apply a filter which hides all items, the itemList is missing here?
		if gpInvVar.itemList and gpInvVar.itemList:IsEmpty() and gpInvVar.currentListType == "categoryList" then
--d(">itemList is empty, categoryList shows (filtered all items?!)")
		else
--d("<abort due to missing itemList")
			return
		end
	end
	if gpInvVar.RefreshActiveCategoryList and gpInvVar.categoryList:IsActive() then
		--d("<itemList refreshing ...")
		gpInvVar:RefreshActiveCategoryList(true) --trigger callback of vanilla ESO
	elseif gpInvVar.RefreshItemList and gpInvVar.itemList:IsActive() then
		--d("<itemList refreshing ...")
		gpInvVar:RefreshItemList(true) --trigger callback of vanilla ESO
		if gpInvVar.itemList:IsEmpty() then
			gpInvVar:SwitchActiveList("categoryList")
		else
			--d(">itemList NOT empty, updating RightTooltip and itemActions!")
			gpInvVar:UpdateRightTooltip()
			gpInvVar:RefreshItemActions()
		end
	end
end
]]

-- update for LF_INVENTORY/LF_INVENTORY_COMPANION/LF_INVENTORY_QUEST/LF_INVENTORY_VENGEANCE gamepad
local function updateFunction_GP_ItemOrCategoryList(gpInvVar, itemList, categoryList)
--d("[LibFilters]updateFunction_GP_ItemList - gpInvVar: " ..tos(gpInvVar))
	if libFilters.debug then dv("[U]updateFunction_GP_ItemOrCategoryList - gpInvVar: %s, itemList: %s, categoryList: %s", tos(gpInvVar), tos(itemList), tos(categoryList)) end
	local itemListRef = gpInvVar[itemList]
	local currentListType = gpInvVar.currentListType
	if not itemListRef or currentListType ~= itemList then
		--todo 20251102 If we are in companion inventory and apply a filter which hides all items, the itemList is missing here?
		if itemListRef and itemListRef:IsEmpty() and currentListType == categoryList then
--d(">itemList is empty, categoryList shows (filtered all items?!)")
		else
--d("<abort due to missing itemList")
--d("<active itemList is missing -> Switching to category list...")
			gpInvVar:SwitchActiveList(categoryList)
		end
	end
	local categoryListRef = gpInvVar[categoryList]
	if categoryListRef:IsActive() then
		--d("<active category list refreshing ...")
		gpInvVar:RefreshActiveCategoryList(true) --trigger callback of vanilla ESO
	elseif itemListRef:IsActive() then
		--d("<active itemList refreshing ...")
		gpInvVar:RefreshActiveItemList(true) --trigger callback of vanilla ESO
		if not itemListRef:IsEmpty() then
			--d(">itemList NOT empty, updating RightTooltip and itemActions!")
			gpInvVar:UpdateRightTooltip()
			gpInvVar:RefreshItemActions()
		end
	end
end


-- update for LF_CRAFTBAG gamepad
local function updateFunction_GP_CraftBagList(gpInvVar)
	if libFilters.debug then dv("[U]updateFunction_GP_CraftBagList - gpInvVar: %s", tos(gpInvVar)) end
	if not gpInvVar.craftBagList then return end
	gpInvVar:RefreshCraftBagList(true)  --trigger callback of vanilla ESO
	gpInvVar:RefreshItemActions()
end

-- update for LF_ENCHANTING_CREATION/LF_ENCHANTING_EXTRACTION gamepad
local function updateFunction_GP_CraftingInventory(craftingInventory)
	if libFilters.debug then dv("[U]updateFunction_GP_CraftingInventory - craftingInventory: %s", tos(craftingInventory)) end
	if not craftingInventory then return end
--libFilters._debugCraftingInventory = craftingInventory
	craftingInventory:PerformFullRefresh()
end


------------------------------------------------------------------------------------------------------------------------
--Update functions for the keyboard inventory
local function fallbackInventoryUpdaterKeyboard() updateKeyboardPlayerInventoryType(invTypeBackpack) end
local InventoryUpdateFunctions_KB = {
	["fallback"] = fallbackInventoryUpdaterKeyboard, --Fallback entry for all that aren't added here
	--[[
	Dynamically added below:
	[LF_INVENTORY] = function()
		updateKeyboardPlayerInventoryType(invTypeBackpack)
	end,
	[LF_INVENTORY_VENGEANCE] = function()
		updateKeyboardPlayerInventoryType(invTypeVengeance)
	end,
	[LF_VENDOR_SELL_VENGEANCE] = function()
		updateKeyboardPlayerInventoryType(invTypeVengeance)
	end,
	...
	]]
}
local inventoryUpdateFunction_KB_fallback = InventoryUpdateFunctions_KB["fallback"]
--Dynamically add all INVENTORY updaters to the table InventoryUpdateFunctions_KB above
-->so the updater functions get created per LibFilters filterPanelId, which use constants like INVENTORY_BACKPACK or INVENTORY_BANK etc.
for filterTypeOfUpdaterName, isEnabled in pairs(filterTypeToUpdaterNameDynamicINVENTORY) do
	if isEnabled then
		InventoryUpdateFunctions_KB[filterTypeOfUpdaterName] = function()
			updateKeyboardPlayerInventoryType(libFiltersFilterType2InventoryType[filterTypeOfUpdaterName] or invTypeBackpack) --fallback to INVENTORY_BACKPACK if no dedicated entry was found
		end
	end
end
libFilters.constants.keyboard.InventoryUpdateFunctions = InventoryUpdateFunctions_KB


------------------------------------------------------------------------------------------------------------------------
--Update functions for the gamepad inventory
local InventoryUpdateFunctions_GP      = {
	[LF_INVENTORY] = function()
		updateFunction_GP_ItemOrCategoryList(invBackpack_GP, 			getUpdaterCategoryAndItemListNamesByFilterPanelId(LF_INVENTORY))
	end,
	[LF_INVENTORY_VENGEANCE] = function()
		updateFunction_GP_ItemOrCategoryList(invBackpack_GP, 			getUpdaterCategoryAndItemListNamesByFilterPanelId(LF_INVENTORY_VENGEANCE))
	end,
	[LF_BANK_DEPOSIT] = function()
		updateFunction_GP_ZO_GamepadInventoryList(invBank_GP, 			getUpdaterCategoryAndItemListNamesByFilterPanelId(LF_BANK_DEPOSIT))
	end,
	[LF_GUILDBANK_DEPOSIT]  = function()
		updateFunction_GP_ZO_GamepadInventoryList(invGuildBank_GP, 		getUpdaterCategoryAndItemListNamesByFilterPanelId(LF_GUILDBANK_DEPOSIT))
	end,
	[LF_HOUSE_BANK_DEPOSIT] = function()
		updateFunction_GP_ZO_GamepadInventoryList(invBank_GP, 			getUpdaterCategoryAndItemListNamesByFilterPanelId(LF_HOUSE_BANK_DEPOSIT))
	end,
	[LF_FURNITURE_VAULT_DEPOSIT] = function()
		updateFunction_GP_ZO_GamepadInventoryList(invFurnitureVault_GP, getUpdaterCategoryAndItemListNamesByFilterPanelId(LF_FURNITURE_VAULT_DEPOSIT))
	end,
	[LF_MAIL_SEND] = function()
		updateFunction_GP_ZO_GamepadInventoryList(invMailSend_GP.send, 	getUpdaterCategoryAndItemListNamesByFilterPanelId(LF_MAIL_SEND))
	end,
	[LF_TRADE] = function()
		updateFunction_GP_ZO_GamepadInventoryList(invPlayerTrade_GP, 	getUpdaterCategoryAndItemListNamesByFilterPanelId(LF_TRADE))
	end,
	[LF_GUILDSTORE_SELL] = function()
		if libFilters.debug and invGuildStoreSell_GP == nil then dv("[U]updateFunction LF_GUILDSTORE_SELL: Added reference to GAMEPAD_TRADING_HOUSE_SELL") end
        invGuildStoreSell_GP = invGuildStoreSell_GP or GAMEPAD_TRADING_HOUSE_SELL
		updateFunction_GP_UpdateList(invGuildStoreSell_GP)
	end,
	[LF_VENDOR_SELL] = function()
		updateFunction_GP_Vendor(ZO_MODE_STORE_SELL)
	end,
	[LF_FENCE_SELL] = function()
		updateFunction_GP_Vendor(ZO_MODE_STORE_SELL_STOLEN)
	end,
	[LF_FENCE_LAUNDER] = function()
		updateFunction_GP_Vendor(ZO_MODE_STORE_LAUNDER)
	end,
	[LF_VENDOR_SELL_VENGEANCE] = function()
		updateFunction_GP_Vendor(ZO_MODE_STORE_SELL_VENGEANCE)
	end,
}
libFilters.constants.gamepad.InventoryUpdateFunctions = InventoryUpdateFunctions_GP


------------------------------------------------------------------------------------------------------------------------
--KEYBOARD & GAMEPAD updater string to updater function
------------------------------------------------------------------------------------------------------------------------
--The updater functions used within LibFilters:RequestUpdate() for the LF_* constants
--Will call a refresh or update of the inventory lists, or scenes, or set a "isdirty" flag and update the crafting lists, etc.
--> See file constants.lua, table filterTypeToUpdaterNameDynamic for all LF_* constants used for e.g. the dynamic updater name INVENTORY etc.
local inventoryUpdaters = {
	INVENTORY = function(filterType)
		if filterType == nil then return end
		if IsGamepad() then
			InventoryUpdateFunctions_GP[filterType]()
		else
			local updFunc = InventoryUpdateFunctions_KB[filterType] or inventoryUpdateFunction_KB_fallback
			updFunc()
		end
	end,
	INVENTORY_COMPANION = function()
		if IsGamepad() then
			--updateFunction_GP_ItemList(companionEquipment_GP)
			updateFunction_GP_ItemOrCategoryList(companionEquipment_GP, getUpdaterCategoryAndItemListNamesByFilterPanelId(LF_INVENTORY_COMPANION))
		else
			SafeUpdateList(companionEquipment, nil)
		end
	end,
	CRAFTBAG = function()
		if IsGamepad() then
			updateFunction_GP_CraftBagList(invBackpack_GP)
		else
			updateKeyboardPlayerInventoryType(invTypeCraftBag)
		end
	end,
	INVENTORY_QUEST = function()
		if IsGamepad() then
			--updateFunction_GP_ItemList(invBackpack_GP)
			updateFunction_GP_ItemOrCategoryList(invBackpack_GP, getUpdaterCategoryAndItemListNamesByFilterPanelId(LF_INVENTORY_QUEST))
		else
			updateKeyboardPlayerInventoryType(invTypeQuest)
		end
	end,
	QUICKSLOT = function()
		if IsGamepad() then
			--[[
				--Not supported yet as quickslots in gamepad mode are totally different from keyboard mode. One would
				--have to add filter possibilities not only in inventory consumables but also directly in the collections
				--somehow
			]]
			if libFilters.debug then dv("[U]updateFunction_GP_QUICKSLOT - Not supported yet!") end
	--		SafeUpdateList(quickslots_GP) --TODO quickslots GP are not supported yet
		else
			SafeUpdateList(quickslots)
		end
	end,
	BANK_WITHDRAW = function()
		if IsGamepad() then
			updateFunction_GP_ZO_GamepadInventoryList(invBank_GP, getUpdaterCategoryAndItemListNamesByFilterPanelId(LF_BANK_WITHDRAW))
		else
			updateKeyboardPlayerInventoryType(invTypeBank)
		end
	end,
	GUILDBANK_WITHDRAW = function()
		if IsGamepad() then
			updateFunction_GP_ZO_GamepadInventoryList(invGuildBank_GP, getUpdaterCategoryAndItemListNamesByFilterPanelId(LF_GUILDBANK_WITHDRAW))
		else
			updateKeyboardPlayerInventoryType(invTypeGuildBank)
		end
	end,
	HOUSE_BANK_WITHDRAW = function()
		if IsGamepad() then
			updateFunction_GP_ZO_GamepadInventoryList(invBank_GP, getUpdaterCategoryAndItemListNamesByFilterPanelId(LF_HOUSE_BANK_WITHDRAW))
		else
			updateKeyboardPlayerInventoryType(invTypeHouseBank)
		end
	end,
	FURNITURE_VAULT_WITHDRAW = function()
		if IsGamepad() then
			updateFunction_GP_ZO_GamepadInventoryList(invFurnitureVault_GP, getUpdaterCategoryAndItemListNamesByFilterPanelId(LF_FURNITURE_VAULT_WITHDRAW))
		else
			updateKeyboardPlayerInventoryType(invTypeFurnitureVault)
		end
	end,
	VENDOR_BUY = function()
		if IsGamepad() then
			updateFunction_GP_Vendor(ZO_MODE_STORE_BUY)
		else
			if guildStoreSellFragment.state ~= SCENE_SHOWN then --"shown"
				store:GetStoreItems()
				SafeUpdateList(store)
			end
		end
	end,
	VENDOR_BUYBACK = function()
		if IsGamepad() then
			updateFunction_GP_Vendor(ZO_MODE_STORE_BUY_BACK)
		else
			SafeUpdateList(vendorBuyBack)
		end
	end,
	VENDOR_REPAIR = function()
		if IsGamepad() then
			updateFunction_GP_Vendor(ZO_MODE_STORE_REPAIR)
		else
			SafeUpdateList(vendorRepair)
		end
	end,
	GUILDSTORE_BROWSE = function()
	--[[
		--Not supported yet
		if IsGamepad() then
		else
		end
	]]
		if libFilters.debug then dv("[U]updateFunction GUILDSTORE_BROWSE: Not supported yet") end
	end,
	SMITHING_REFINE = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(refinementPanel_GP)
		else
			updateCraftingInventoryDirty(refinementPanel)
		end
	end,
	SMITHING_CREATION = function()
	--[[
		--Not supported yet
		if IsGamepad() then
		else
		end
	]]
		if libFilters.debug then dv("[U]updateFunction SMITHING_CREATION: Not supported yet") end
	end,
	SMITHING_DECONSTRUCT = function()
		updateCraftingInventoryDirty(getDeconstructOrExtractCraftingVarToUpdate(LF_SMITHING_DECONSTRUCT, nil))
	end,
	SMITHING_IMPROVEMENT = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(improvementPanel_GP)
		else
			updateCraftingInventoryDirty(improvementPanel)
		end
	end,
	SMITHING_RESEARCH = function()
		if IsGamepad() then
			if not researchPanel_GP.researchLineList then return end
			if libFilters.debug then dv("[U]updateFunction_GP_SMITHING_RESEARCH - SMITHING_GAMEPAD.researchPanel:Refresh() called") end
			researchPanel_GP:Refresh()
		else
			if libFilters.debug then dv("[U]updateFunction_Keyboard_SMITHING_RESEARCH - SMITHING.researchPanel:Refresh() called") end
			researchPanel:Refresh()
		end
	end,
	SMITHING_RESEARCH_DIALOG = function()
		if IsGamepad() then
			-->The index [1] in GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE.callbackRegistry.StateChange is the original state change of ZOs vailla UI and should trigger the
			-->refresh of the scene's list contents
			--> See here: esoui/ingame/crafting/gamepad/smithingresearch_gamepad.lua
			-->GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE:RegisterCallback("StateChange", function(oldState, newState)
			--sceneStateChangeCallbackUpdater(gamepadConstants.researchChooseItemDialog_GP, SCENE_HIDDEN, SCENE_SHOWING, 1, nil)
			if not researchPanel_GP.confirmList then return end
			if libFilters.debug then dv("[U]updateFunction_GP_SMITHING_RESEARCH_DIALOG - GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE:FireCallbacks(StateChange, nil, SCENE_SHOWING) called") end
			researchChooseItemDialog_GP:FireCallbacks("StateChange", nil, SCENE_SHOWING)
		else
			dialogUpdaterFunc(researchChooseItemDialog)
		end
	end,
	ALCHEMY_CREATION = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(alchemy_GP)
		else
			updateCraftingInventoryDirty(alchemy)
		end
	end,
	ENCHANTING = function()
		local isInGamepadMode = IsGamepad()
		local enchantingCraftVarToUpdate = getDeconstructOrExtractCraftingVarToUpdate(LF_ENCHANTING_EXTRACTION, isInGamepadMode)
		if isInGamepadMode then
			updateFunction_GP_CraftingInventory(enchantingCraftVarToUpdate.inventory)
		else
			updateCraftingInventoryDirty(enchantingCraftVarToUpdate)
		end
	end,
	PROVISIONING_COOK = function()
	--[[
		--Not supported yet
		if IsGamepad() then
		else
		end
	]]
		if libFilters.debug then dv("[U]updateFunction PROVISIONING_COOK: Not supported yet") end
	end,
	PROVISIONING_BREW = function()
	--[[
		--Not supported yet
		if IsGamepad() then
		else
		end
	]]
		if libFilters.debug then dv("[U]updateFunction PROVISIONING_BREW: Not supported yet") end
	end,
	RETRAIT = function()
		if IsGamepad() then
			if libFilters.debug then dv("[U]updateFunction_GP_RETRAIT: ZO_RETRAIT_STATION_RETRAIT_GAMEPAD:Refresh() called") end
			retrait_GP:Refresh() -- ZO_RETRAIT_STATION_RETRAIT_GAMEPAD
		else
			updateCraftingInventoryDirty(retrait)
		end
	end,
	RECONSTRUCTION = function()
		if IsGamepad() then
			if libFilters.debug then dv("[U]updateFunction_GP_RECONSTRUCTION: ZO_RETRAIT_STATION_RECONSTRUCT_GAMEPAD:RefreshFocusItems() called") end
			-- not sure how reconstruct works, how it would be filtered.
			reconstruct_GP:RefreshFocusItems() -- ZO_RETRAIT_STATION_RECONSTRUCT_GAMEPAD
		else
			updateCraftingInventoryDirty(reconstruct)
		end
	end,
}
libFilters.mapping.inventoryUpdaters = inventoryUpdaters
