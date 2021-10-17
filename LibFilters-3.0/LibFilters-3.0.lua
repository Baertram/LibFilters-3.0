------------------------------------------------------------------------------------------------------------------------
--Bugs/Todo List for version: 3.0 r3.0
------------------------------------------------------------------------------------------------------------------------
--Known bugs: 0
--Last update: 2021-10-17, Baertram
--
--


------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3 name, and version
------------------------------------------------------------------------------------------------------------------------
local libFilters = LibFilters3
local MAJOR      = libFilters.name
local filters    = libFilters.filters


------------------------------------------------------------------------------------------------------------------------
--LOCAL SPEED UP VARIABLES & REFERENCES
------------------------------------------------------------------------------------------------------------------------
--lua API functions
local tos = tostring
local strform = string.format
local strup = string.upper

--Game API local speedup
local EM = EVENT_MANAGER
local SM = SCENE_MANAGER
local IsGamepad = IsInGamepadPreferredMode

--LibFilters local speedup and reference variables
--Overall constants
local constants = 					libFilters.constants
local mapping = 					libFilters.mapping
local libFiltersFilterConstants = 	libFilters.FilterTypes
local inventoryTypes = 				constants.inventoryTypes
local invTypeBackpack = 			inventoryTypes["player"]
local invTypeQuest =				inventoryTypes["quest"]
local invTypeBank =					inventoryTypes["bank"]
local invTypeGuildBank =			inventoryTypes["guild_bank"]
local invTypeHouseBank =			inventoryTypes["house_bank"]
local invTypeCraftBag =				inventoryTypes["craftbag"]

local enchantingModeToFilterType = 	mapping.EnchantingModeToFilterType
local filterTypeToUpdaterName = 	mapping.FilterTypeToUpdaterName
local LF_ConstantToAdditionalFilterControlSceneFragmentUserdata = 	mapping.LF_ConstantToAdditionalFilterControlSceneFragmentUserdata
local LF_ConstantToAdditionalFilterSpecialHook = 					mapping.LF_ConstantToAdditionalFilterSpecialHook

--Keyboard
local keyboardConstants = 			constants.keyboard
local playerInv = 					keyboardConstants.playerInv
local inventories = 				keyboardConstants.inventories
local researchChooseItemDialog = 	keyboardConstants.researchChooseItemDialog

--Gamepad
local gamepadConstants = 			constants.gamepad
local customFragments_GP = 			gamepadConstants.customFragments
--Get the updated constants values of the gamepad fragments, created after constants.lua was called, in file
--Gamepad/gamepadCustomFragments.lua
local invBackpackFragment_GP =	customFragments_GP[LF_INVENTORY].fragment
local invBankDeposit_GP = 		customFragments_GP[LF_BANK_DEPOSIT].fragment
local invGuildBankDeposit_GP = 	customFragments_GP[LF_GUILDBANK_DEPOSIT].fragment
local invHouseBankDeposit_GP = 	customFragments_GP[LF_HOUSE_BANK_DEPOSIT].fragment
local guildStoreSell_GP = 		customFragments_GP[LF_GUILDSTORE_SELL].fragment
local mailSend_GP = 			customFragments_GP[LF_MAIL_SEND].fragment
local player2playerTrade_GP = 	customFragments_GP[LF_TRADE].fragment


------------------------------------------------------------------------------------------------------------------------
--HOOK state variables
------------------------------------------------------------------------------------------------------------------------
--Special hooks done? Add the possible special hook names in this table so that function libFilters:HookAdditionalFilterSpecial
--will not register the special hooks more than once
local specialHooksDone = {
	 ["enchanting"] = false,
}

--Local pre-defined function names. Code will be added further down in this file. Only created here already to be re-used
--in code prior to creation (functions using it won't be called before creation was done, but they are local and more
--DOWN in the lua file than the actual fucntion's creation is done -> lua interpreter wouldn't find it).
local hookAdditionalFilter


------------------------------------------------------------------------------------------------------------------------
--DEBUGGING & LOGGING
------------------------------------------------------------------------------------------------------------------------
--LibDebugLogger
if LibDebugLogger then
	 if not not libFilters.logger then
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

local function debugMessageCaller(debugType, ...)
	debugMessage(strform(...), strup(debugType))
end

--Information debug
local function df(...)
	debugMessageCaller('I', ...)
end
--Error debug
local function dfe(...)
	debugMessageCaller('E', ...)
end


------------------------------------------------------------------------------------------------------------------------
--UPDATERS (of inventories)
------------------------------------------------------------------------------------------------------------------------
--Update the inventory lists
--if the mouse is enabled, cycle its state to refresh the integrity of the control beneath it
local function SafeUpdateList(object, ...)
--d("[LibFilters3]SafeUpdateList, inv: " ..tos(...))
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

local function updateGamepadInventoryList(gpInvVar)
	gpInvVar:RefreshItemList()
end

--The updater functions for the different inventories. Called via LibFilters:RequestForUpdate(LF_*)
local inventoryUpdaters = {
	INVENTORY = function()
		if IsGamepad() then
			updateGamepadInventoryList(gamepadConstants.invBackpack_GP)
		else
			updateKeyboardPlayerInventoryType(invTypeBackpack)
		end
	end,
	INVENTORY_COMPANION = function()
		if IsGamepad() then
			updateGamepadInventoryList(gamepadConstants.companionEquipment_GP)
		else
			SafeUpdateList(keyboardConstants.companionEquipment, nil)
		end
	end,
	CRAFTBAG = function()
		if IsGamepad() then
			gamepadConstants.invBackpack_GP:RefreshCraftBagList()
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
	--		SafeUpdateList(quickslots_GP) --TODO
		else
			SafeUpdateList(keyboardConstants.quickslots)
		end
	end,
	BANK_WITHDRAW = function()
		if IsGamepad() then
			updateGamepadInventoryList(gamepadConstants.invBankWithdraw_GP)
		else
			updateKeyboardPlayerInventoryType(invTypeBank)
		end
	end,
	GUILDBANK_WITHDRAW = function()
		if IsGamepad() then
			updateGamepadInventoryList(gamepadConstants.invGuildBankWithdraw_GP)
		else
			updateKeyboardPlayerInventoryType(invTypeGuildBank)
		end
	end,
	HOUSE_BANK_WITHDRAW = function()
		if IsGamepad() then
			updateGamepadInventoryList(gamepadConstants.invHouseBankWithdraw_GP)
		else
			updateKeyboardPlayerInventoryType(invTypeHouseBank)
		end
	end,
	VENDOR_BUY = function()
		if IsGamepad() then
--			gamepadConstants.vendorBuy_GP:UpdateList() --TODO
		else
			if keyboardConstants.guildStoreSell.state ~= SCENE_SHOWN then --"shown"
				local store = keyboardConstants.store
				store:GetStoreItems()
				SafeUpdateList(store)
			end
		end
	end,
	VENDOR_BUYBACK = function()
		if IsGamepad() then
--			gamepadConstants.vendorBuyBack_GP:UpdateList() --TODO
		else
			SafeUpdateList(keyboardConstants.vendorBuyBack)
		end
	end,
	VENDOR_REPAIR = function()
		if IsGamepad() then
	--		gamepadConstants.vendorRepair_GP:UpdateList()  --TODO
		else
			SafeUpdateList(keyboardConstants.vendorRepair)
		end
	end,
	GUILDSTORE_BROWSE = function()
	end,
	SMITHING_REFINE = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(gamepadConstants.refinementPanel_GP.inventory)
		else
			updateCraftingInventoryDirty(keyboardConstants.refinementPanel.inventory)
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
			updateCraftingInventoryDirty(gamepadConstants.deconstructionPanel_GP.inventory)
		else
			updateCraftingInventoryDirty(keyboardConstants.deconstructionPanel.inventory)
		end
	end,
	SMITHING_IMPROVEMENT = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(gamepadConstants.improvementPanel_GP.inventory)
		else
			updateCraftingInventoryDirty(keyboardConstants.improvementPanel.inventory)
		end
	end,
	SMITHING_RESEARCH = function()
		if IsGamepad() then
			gamepadConstants.researchPanel_GP:Refresh()
		else
			keyboardConstants.researchPanel:Refresh()
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
			updateCraftingInventoryDirty(gamepadConstants.alchemy_GP.inventory) --TODO
		else
			updateCraftingInventoryDirty(keyboardConstants.alchemy.inventory)
		end
	end,
	ENCHANTING = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(gamepadConstants.enchanting_GP.inventory) --TODO
		else
			updateCraftingInventoryDirty(keyboardConstants.enchanting.inventory)
		end
	end,
	PROVISIONING_COOK = function()
	end,
	PROVISIONING_BREW = function()
	end,
	RETRAIT = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(gamepadConstants.retrait_GP) --TODO
		else
			updateCraftingInventoryDirty(keyboardConstants.retrait.inventory)
		end
	end,
	RECONSTRUCTION = function()
		if IsGamepad() then
			updateCraftingInventoryDirty(gamepadConstants.reconstruct_GP) --TODO
		else
			updateCraftingInventoryDirty(keyboardConstants.reconstruct.inventory)
		end
	end,
}
libFilters.inventoryUpdaters = inventoryUpdaters


------------------------------------------------------------------------------------------------------------------------
--RUN THE FILTERS
------------------------------------------------------------------------------------------------------------------------
--Run the applied filters at a LibFilters filterType (LF_*) now, using the ... parameters (e.g. inventorySlot)
local function runFilters(filterType, ...)
--d("[LibFilters3]runFilters, filterType: " ..tos(filterType))
	 for tag, filter in pairs(filters[filterType]) do
		  if not filter(...) then
				return false
		  end
	 end
	 return true
end
libFilters.RunFilters = runFilters


------------------------------------------------------------------------------------------------------------------------
--HOOK VARIABLEs TO ADD .additionalFilters to them
------------------------------------------------------------------------------------------------------------------------
--Hook the different inventory panels (LibFilters filterPanelIds) now and add the .additionalFilter entry to each panel's
--control/scene/fragment/...
local function ApplyAdditionalFilterHooks()

	--For each LF constant hook the filters now to add the .additionalFilters entry
	-->Keyboard and gamepad mode are both hooked here via 2nd param = true
	for value, filterConstantName in ipairs(libFiltersFilterConstants) do
		-->HookAdditionalFilterSpecial will be done automatically in HookAdditionalFilter, via the table
		-->LF_ConstantToAdditionalFilterSpecialHook
		hookAdditionalFilter(libFilters, value, true) --value = the same as _G[filterConstantName], eg. LF_INVENTORY
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
function libFilters:GetMinFilterType()
	 return LF_FILTER_MIN
end
libFilters.GetMinFilter = libFilters.GetMinFilterType

--Returns the maxium possible filterType
function libFilters:GetMaxFilterType()
	 return LF_FILTER_MAX
end
libFilters.GetMaxFilter = libFilters.GetMaxFilterType

--Returns the LibFilters LF* filterType connstants table: value = "name"
function libFilters:GetFilterTypes()
	 return libFiltersFilterConstants
end

--Returns the LibFilters LF* filterType connstant's name
function libFilters:GetFilterTypeName(libFiltersFilterType)
	 return libFiltersFilterConstants[libFiltersFilterType] or ""
end

--Get the current libFilters filterType for the inventoryType, where inventoryType would be e.g. INVENTORY_BACKPACK or
--INVENTORY_BANK, or a SCENE or a control
function libFilters:GetCurrentFilterTypeForInventory(inventoryType)
	--Get the layoutData from the fragment. If no fragment: Abort
	if inventoryType == invTypeBackpack then --INVENTORY_BACKPACK
		local layoutData = playerInv.appliedLayout
		if layoutData and layoutData.LibFilters3_filterType then
			return layoutData.LibFilters3_filterType
		else
			return
		end
	end
	local invVarIsNumber = (type(inventoryType) == "number") or false
	if not invVarIsNumber then
		--Check if inventoryType is a SCENE, e.g. GAMEPAD_ENCHANTING_CREATION_SCENE
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
function libFilters:HookAdditionalFilter(filterLFConstant, hookKeyboardAndGamepadMode)
	local function hookNowSpecial(inventoriesToHookForLFConstant_Table, isInGamepadMode)
		if not inventoriesToHookForLFConstant_Table then
			dfe("HookAdditionalFilter SPECIAL-table of hooks is empty for constant %s, isInGamepadMode: %s, keyboardAndGamepadMode: %s", tos(libFilters:GetFilterTypeName(filterLFConstant)) .. " [" .. tos(filterLFConstant) .. "]", tos(isInGamepadMode), tos(hookKeyboardAndGamepadMode))
			return
		end
		local funcName = inventoriesToHookForLFConstant_Table.funcName
		if funcName ~= nil and funcName ~= "" and libFilters[funcName] ~= nil then
			local params = inventoriesToHookForLFConstant_Table.params
			libFilters[funcName](libFilters, unpack(params)) --pass LibFilters as 1st param "self" TODO: needed?
		end
	end
	local function hookNow(inventoriesToHookForLFConstant_Table, isInGamepadMode)
		if not inventoriesToHookForLFConstant_Table then
			dfe("HookAdditionalFilter-table of hooks is empty for constant %s, isInGamepadMode: %s, keyboardAndGamepadMode: %s", tos(libFilters:GetFilterTypeName(filterLFConstant)) .. " [" .. tos(filterLFConstant) .. "]", tos(isInGamepadMode), tos(hookKeyboardAndGamepadMode))
			return
		end
		if #inventoriesToHookForLFConstant_Table == 0 then return end

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
			if inventoriesToHookForLFConstant ~= nil then
				hookNowSpecial(inventoriesToHookForLFConstant, false)
			end
			--Gamepad
			inventoriesToHookForLFConstant = hookSpecialFunctionDataOfLFConstant[true]
			if inventoriesToHookForLFConstant ~= nil then
				hookNowSpecial(inventoriesToHookForLFConstant, true)
			end
		else
			--Only currently detected mode, gamepad or keyboard
			local gamepadMode = IsGamepad()
			inventoriesToHookForLFConstant = hookSpecialFunctionDataOfLFConstant[gamepadMode]
			hookNowSpecial(inventoriesToHookForLFConstant, gamepadMode)
		end
	end
	inventoriesToHookForLFConstant = nil

	--If the special hook was found it maybe that only one of the two, keyboard or gamepad was hooked special.
	--e.g. "enchanting" -> LF_ENCHANTING_CREATION only applies to keyboard mode. Gamepad needs to hook normally to add
	--the .additionalFilter to the correct gamepad enchanting inventory
	--So try to run the same LF_ constant as normal hook as well (if it exists)
	--Hook normal via the given control/scene/fragment etc. -> See table LF_ConstantToAdditionalFilterControlSceneFragmentUserdata
	if hookKeyboardAndGamepadMode == true then
		--Keyboard
		inventoriesToHookForLFConstant = LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[false][filterLFConstant]
		if not hookSpecialFunctionDataOfLFConstant then
			hookNow(inventoriesToHookForLFConstant, false)
		end
		--Gamepad
		inventoriesToHookForLFConstant = LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[true][filterLFConstant]
		if not hookSpecialFunctionDataOfLFConstant then
			hookNow(inventoriesToHookForLFConstant, true)
		end
	else
		--Only currently detected mode, gamepad or keyboard
		local gamepadMode = IsGamepad()
		inventoriesToHookForLFConstant = LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[gamepadMode][filterLFConstant]
		if not hookSpecialFunctionDataOfLFConstant then
			hookNow(inventoriesToHookForLFConstant, gamepadMode)
		end
	end
end
hookAdditionalFilter = libFilters.HookAdditionalFilter


--Hook the inventory in a special way, e.g. at ENCHANTING where there is only 1 inventory variable and no
--extra fragment for the different modes (creation, extraction).
local specialHooksLibFiltersDataRegistered = {}
function libFilters:HookAdditionalFilterSpecial(specialType)
	if specialHooksDone[specialType] == true then return end

	--ENCHANTING keyboard
	--[[
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
		ZO_PreHook(keyboardConstants.enchantingClass, "OnModeUpdated", function(selfEnchanting)
			onEnchantingModeUpdated(selfEnchanting, selfEnchanting.enchantingMode)
		end)

		specialHooksDone[specialType] = true
	end
	]]
end

--Hook the inventory in a special way, e.g. at ENCHANTING for gamepad using the SCENES to add the .additionalFilter, but
-- using the GAMEPAD_ENCHANTING.inventory to store the current LibFilters3_filterType
function libFilters:HookAdditionalFilterSceneSpecial(specialType)
	if specialHooksDone[specialType] == true then return end

	--ENCHANTING gamepad
	--[[
	if specialType == "enchanting_GamePad" then
		--The enchanting scenes to hook into
		local enchantingScenesGamepad = {
			[LF_ENCHANTING_CREATION] = 		gamepadConstants.enchantingCreate_GP,
			[LF_ENCHANTING_EXTRACTION] = 	gamepadConstants.enchantingExtract_GP,
		}

		local function updateLibFilters3_filterTypeAtGamepadEnchantingInventory(enchantingVar)
			local enchantingMode = enchantingVar:GetEnchantingMode()
			local libFiltersEnchantingFilterType = enchantingModeToFilterType[enchantingMode]
			enchantingVar.inventory.LibFilters3_filterType = libFiltersEnchantingFilterType
		end

		--Add the .additionalFilter to the gamepad enchanting creation and extraction scenes once
		--Only add .additionalFilter once
		for libFiltersEnchantingFilterType, enchantingSceneGamepad in pairs(enchantingScenesGamepad) do
			specialHooksLibFiltersDataRegistered[specialType] = specialHooksLibFiltersDataRegistered[specialType] or {}
			if libFiltersEnchantingFilterType ~= nil and not specialHooksLibFiltersDataRegistered[specialType][libFiltersEnchantingFilterType] then
				local originalFilter = enchantingSceneGamepad.additionalFilter
				local additionalFilterType = type(originalFilter)
				if additionalFilterType == "function" then
					enchantingSceneGamepad.additionalFilter = function(...)
						return originalFilter(...) and runFilters(libFiltersEnchantingFilterType, ...)
					end
				else
					enchantingSceneGamepad.additionalFilter = function(...)
						return runFilters(libFiltersEnchantingFilterType, ...)
					end
				end
				specialHooksLibFiltersDataRegistered[specialType][libFiltersEnchantingFilterType] = true
			end

			--Register a stateChange callback: Change the .LibFilters3_filterType at GAMEPAD_ENCHANTING.inventory
		    --for GAMEPAD_ENCHANTING.inventory:EnumerateInventorySlotsAndAddToScrollData (see helpers.lua)
			enchantingSceneGamepad:RegisterCallback("StateChange", function(oldState, newState)
				if newState == SCENE_SHOWING then
--d("[LF3]GamePadEnchanting " ..tostring(libFilters:GetFilterTypeName(libFiltersEnchantingFilterType)) .." Scene:Showing")
					updateLibFilters3_filterTypeAtGamepadEnchantingInventory(gamepadConstants.enchanting_GP)
				end
			end)
		end

		specialHooksDone[specialType] = true
	end
	]]
end

--**********************************************************************************************************************
-- Filter callback and un/register
function libFilters:GetFilterCallback(filterTag, filterType)
	 if not self:IsFilterRegistered(filterTag, filterType) then return end

	 return filters[filterType][filterTag]
end

function libFilters:IsFilterRegistered(filterTag, filterType)
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

function libFilters:RegisterFilter(filterTag, filterType, filterCallback)
	 local callbacks = filters[filterType]

	 if not filterTag or not callbacks or type(filterCallback) ~= "function" then
		  dfe("Invalid arguments to RegisterFilter(%q, %s, %s).\n>Needed format is: String uniqueFilterTag, number LibFiltersLF_*FilterPanelConstant, function filterCallbackFunction",
				tos(filterTag), tos(filterType), tos(filterCallback))
		  return
	 end

	 if callbacks[filterTag] ~= nil then
		  dfe("filterTag \'%q\' filterType \'%s\' filterCallback function is already in use",
				tos(filterTag), tos(filterType))
		  return
	 end

	 callbacks[filterTag] = filterCallback
end

function libFilters:UnregisterFilter(filterTag, filterType)
	 if not filterTag or filterTag == "" then
		  dfe("Invalid arguments to UnregisterFilter(%s, %s).\n>Needed format is: String filterTag, number filterPanelId", tos(filterTag), tos(filterType))
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
function libFilters:RequestUpdate(filterType)
d("[LibFilters3]RequestUpdate-filterType: " ..tos(filterType))
	 local updaterName = filterTypeToUpdaterName[filterType]
	 if not updaterName or updaterName == "" then
		  dfe("Invalid arguments to RequestUpdate(%s).\n>Needed format is: number filterPanelId", tos(filterType))
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
function libFilters:SetResearchLineLoopValues(fromResearchLineIndex, toResearchLineIndex, skipTable)
	 local craftingType = GetCraftingInteractionType()
	 if craftingType == CRAFTING_TYPE_INVALID then return false end
	 if not fromResearchLineIndex or fromResearchLineIndex <= 0 then fromResearchLineIndex = 1 end
	 local numSmithingResearchLines = GetNumSmithingResearchLines(craftingType)
	 if not toResearchLineIndex or toResearchLineIndex > numSmithingResearchLines then
		  toResearchLineIndex = numSmithingResearchLines
	 end
	 local helpers = libFilters.helpers
	 if not helpers then return end
	 local smithingResearchPanel = helpers["SMITHING.researchPanel:Refresh"].locations[1]
	 if smithingResearchPanel then
		  smithingResearchPanel.LibFilters_3ResearchLineLoopValues = {
				from		= fromResearchLineIndex,
				to			= toResearchLineIndex,
				skipTable	= skipTable,
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
libFilters.helpers = {}
local helpers      = libFilters.helpers

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
	--d("ApplyBackpackLayout-ZO_CraftBag:IsHidden(): " ..tos(ZO_CraftBag:IsHidden()))
		if keyboardConstants.craftBagClass:IsHidden() then return end
		--Re-Apply the .additionalFilter to CraftBag again, on each open of it
		hookAdditionalFilter(libFilters, LF_CRAFTBAG)
	end)
end


--**********************************************************************************************************************
--**********************************************************************************************************************
--**********************************************************************************************************************
--Function needed to be called from your addon to start the LibFilters instance and enable the filtering!
function libFilters:InitializeLibFilters()
	 if self.isInitialized then return end
	 self.isInitialized = true

	 InstallHelpers()
	 ApplyAdditionalFilterHooks()
end

--______________________________________________________________________________________________________________________
--______________________________________________________________________________________________________________________
--______________________________________________________________________________________________________________________
--Apply any fixes needed to be run before EVENT_ADD_ON_LOADED
ApplyFixes()
