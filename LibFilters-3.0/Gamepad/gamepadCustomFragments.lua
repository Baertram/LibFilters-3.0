--[[
	Version:	1.0
	Idea:		IsJustAGhost
	Code by:	IsJustAGhost & Baertram

	Description:
	The gamepad mode does not provide fragments for the backpack, bank and other inventory types as the keyboard mode
	does, and hooks into (to add the .additionalFilter function entry). There for we create our own fragments for the
	needed inventory types and add them to the gamepad scenes (which are used already by vanilla UI).

	The new added custom fragments base on the class "LibFilters_InventoryLayoutFragment".

	The fragments will be used in LibFilters-3.0.lua to hook into them via libFilters:HookAdditionalFilter
]]

------------------------------------------------------------------------------------------------------------------------
-- Local speed-up variables
------------------------------------------------------------------------------------------------------------------------
local tos = tostring
local SM = SCENE_MANAGER
--local getScene = SM.GetScene


------------------------------------------------------------------------------------------------------------------------
-- Local library variables
------------------------------------------------------------------------------------------------------------------------
local libFilters = LibFilters3


--LibFilters local speedup and reference variables
--Overall constants
local constants = 								libFilters.constants
local inventoryTypes = 							constants.inventoryTypes
local playerInventoryType = 					inventoryTypes["player"] -- INVENTORY_BACKPACK
local mapping = 								libFilters.mapping
local callbacks = 								mapping.callbacks
local callbacksUsingFragments = 				callbacks.usingFragments
local filterTypeToCallbackRef = 				callbacks.filterTypeToCallbackRef

local LF_FilterTypeToReference =				mapping.LF_FilterTypeToReference
local LF_FilterTypeToCheckIfReferenceIsHidden = mapping.LF_FilterTypeToCheckIfReferenceIsHidden

--Keyboard
local kbc             = 						constants.keyboard
local playerInventory = 						kbc.playerInv

--Gamepad
local gpc                         	= 			constants.gamepad
local invRootScene                	= 			gpc.invRootScene_GP
local invBackpack_GP 				= 			gpc.invBackpack_GP
local invFragment_GP 				= 			gpc.invFragment_GP
local invBank_GP                  	= 			gpc.invBank_GP
local invBankScene_GP      			=			gpc.invBankScene_GP
local invGuildBankScene_GP 			= 			gpc.invGuildBankScene_GP
local invGuildBank_GP      			=			gpc.invGuildBank_GP
local invGuildStore_GP				= 			gpc.invGuildStore_GP
local gamepadTradingHouseBrowseFragment
local invGuildStoreSellScene_GP   	= 			gpc.invGuildStoreSellScene_GP
--local invGuildStoreSell_GP 			= 			gpc.invGuildStoreSell_GP
local invMailSendScene_GP         	= 			gpc.invMailSendScene_GP
local invMailSend_GP  				= 			gpc.invMailSend_GP
local invMailSendFragment_GP		=			gpc.invMailSendFragment_GP
local invPlayerTradeScene_GP		= 			gpc.invPlayerTradeScene_GP
local quickslotFragment_GP   		=			gpc.quickslotFragment_GP

local customFragments_GP          	= 			gpc.customFragments
local fragmentPrefix              	= 			gpc.customFragmentPrefix

--The local variables for the new created custom LibFilters gamepad fragments
local gamepadLibFiltersInventoryFragment
local gamepadLibFiltersBankDepositFragment
local gamepadLibFiltersGuildBankDepositFragment
local gamepadLibFiltersHouseBankDepositFragment
local gamepadLibFiltersGuildStoreSellFragment
local gamepadLibFiltersMailSendFragment
local gamepadLibFiltersPlayerTradeFragment
local gamepadLibFiltersInventoryQuestFragment

local fragmentsHooked = {}
local craftBagList_GP, craftBagFragment_GP
local comingFromCraftBagList = false


--Debugging
local debugFunctions = libFilters.debugFunctions
local dd = debugFunctions.dd

if libFilters.debug then dd("LIBRARY GAMEPAD CUSTOM FRAGMENTS FILE - START") end


------------------------------------------------------------------------------------------------------------------------
-- Local helper functions
------------------------------------------------------------------------------------------------------------------------


--Add the fragment prefix and return the fragment
local function getCustomLibFiltersFragmentName(libFiltersFilterType)
	local fragmentName = customFragments_GP[libFiltersFilterType].name
	return fragmentPrefix .. fragmentName
end
libFilters.GetCustomLibFiltersFragmentName = getCustomLibFiltersFragmentName


local function fragmentChange(oldState, newState, fragmentSource, fragmentTarget, showingFunc, shownFunc, hidingFunc, hiddenFunc)
	if not libFilters.isInitialized then return end

	if libFilters.debug then dd("GAMEPAD Fragment state change "..tos(fragmentTarget._name or fragmentTarget.name).." - State: " ..tos(newState)) end
	if (newState == SCENE_FRAGMENT_SHOWING ) then
		if showingFunc ~= nil then showingFunc(fragmentSource, fragmentTarget) end
	elseif (newState == SCENE_FRAGMENT_SHOWN ) then
		if shownFunc ~= nil then shownFunc(fragmentSource, fragmentTarget)  end
	elseif (newState == SCENE_FRAGMENT_HIDING ) then
		if hidingFunc ~= nil then hidingFunc(fragmentSource, fragmentTarget)  end
	elseif (newState == SCENE_FRAGMENT_HIDDEN ) then
		if hiddenFunc ~= nil then hiddenFunc(fragmentSource, fragmentTarget) end
	end
end


--[[
local function hookControlHiddenAndShownAndChangeFragmentState(ctrlToHook, sceneChanged, sourceFragment, targetFragment)
	sceneChanged:RegisterCallback("StateChange", function(oldState, newState)
		if libFilters.debug then dd(""..tos(sceneChanged:GetName()).." - State: " ..tos(newState)) end
		if not hookedControlsHiddenState[ctrlToHook] then
			fragmentChange(oldState, newState, sourceFragment, targetFragment,
					function(p_srcFragment, p_targetFragment)
						p_targetFragment:Hide() --Hide target fragment on first view as the scene has shown it
						if not hookedControlsHiddenState[ctrlToHook] then
							if ctrlToHook ~= nil then
								ctrlToHook:SetHandler("OnEffectivelyShown", function()
									if libFilters.debug then dd("" ..ctrlToHook:GetName() .. "): shown") end
									p_targetFragment:Show()
								end)
								ctrlToHook:SetHandler("OnHide", function()
									if libFilters.debug then dd("" ..ctrlToHook:GetName() .. "): hidden") end
									p_targetFragment:Hide()
								end)
								if ctrlToHook:IsHidden() then
									p_targetFragment:Show()
								else
									p_targetFragment:Hide()
								end
								hookedControlsHiddenState[ctrlToHook] = true
							end
						end
					end,
					function(p_srcFragment, p_targetFragment)
						if not hookedControlsHiddenState[ctrlToHook] then
							if ctrlToHook ~= nil then
								ctrlToHook:SetHandler("OnEffectivelyShown", function()
									if libFilters.debug then dd("" ..ctrlToHook:GetName() .. "): shown") end
									p_targetFragment:Show()
								end)
								ctrlToHook:SetHandler("OnHide", function()
									if libFilters.debug then dd("" ..ctrlToHook:GetName() .. "): hidden") end
									p_targetFragment:Hide()
								end)
								if ctrlToHook:IsHidden() then
									p_targetFragment:Show()
								else
									p_targetFragment:Hide()
								end
								hookedControlsHiddenState[ctrlToHook] = true
							end
						end
					end,
					function(p_srcFragment, p_targetFragment) p_targetFragment:Hide() return end,
					nil
			)
		end
	end)
end
]]

local function updateSceneManagerAndHideFragment(targetFragment)
	if not targetFragment then return end
	if not targetFragment.sceneManager then targetFragment:SetSceneManager(SM) end
	if not targetFragment:IsHidden() then
		targetFragment:Hide()
	end
end

local function hookListFragmentsState(hookName, sceneId, objectId, listName, targetFragment, checkFunc, addAndRemoveFragment)
	if not libFilters.isInitialized then return end

	addAndRemoveFragment = addAndRemoveFragment or false
	if not fragmentsHooked[hookName] then
		if checkFunc ~= nil and checkFunc() ~= true then return end

		if sceneId:IsShowing() then
			if listName == "deposit" then
				if objectId:IsInDepositMode() then
					targetFragment:Show()
				else
					updateSceneManagerAndHideFragment(targetFragment)
				end
			elseif listName == "withdraw" then
				if objectId:IsInWithdrawMode() then
					targetFragment:Show()
				else
					updateSceneManagerAndHideFragment(targetFragment)
				end
			end
		else
			updateSceneManagerAndHideFragment(targetFragment)
		end

		local listFragment
		if objectId.GetListFragment ~= nil then
			listFragment = objectId:GetListFragment(listName)
		elseif objectId.GetFragment ~= nil then
			listFragment = objectId:GetFragment()
		end
		if libFilters.debug then dd("GAMEPAD " .. tos(hookName) .. " - Fragment exist: " ..tostring(listFragment ~= nil)) end
		if listFragment == nil then return end
		listFragment:RegisterCallback("StateChange", function(oldState, newState)
			if libFilters.debug then dd("GAMEPAD " .. tos(hookName) .." list FRAGMENT - State: " ..tos(newState)) end
			fragmentChange(oldState, newState, nil, targetFragment,
					function(p_sourceFragment, p_targetFragment) return end, --showing
					function(p_sourceFragment, p_targetFragment)
						if checkFunc ~= nil and checkFunc() ~= true then return end
						if addAndRemoveFragment == true then
							if libFilters.debug then dd("GAMEPAD " .. tos(hookName) .." list FRAGMENT - Added fragment: " ..tos(p_targetFragment)) end
							sceneId:AddFragment(p_targetFragment)
						end
						p_targetFragment:Show()
						return
					end, --shown
					function(p_sourceFragment, p_targetFragment) return end, --hiding
					function(p_sourceFragment, p_targetFragment)
						if checkFunc ~= nil and checkFunc() ~= true then return end
						if addAndRemoveFragment == true then
							if libFilters.debug then dd("GAMEPAD " .. tos(hookName) .." list FRAGMENT - Removed fragment: " ..tos(p_targetFragment)) end
							sceneId:RemoveFragment(p_targetFragment)
						end
						p_targetFragment:Hide()
						return
					end --hidden
			)
		end)
		fragmentsHooked[hookName] = true
	end
end


local function hookFragmentStateByPostHookListInitFunction(hookName, sceneId, objectId, listName, listFunctionName, targetFragment, checkFunc, addAndRemoveFragment)
	if not sceneId or not objectId or not listName or not listFunctionName or not targetFragment then return end
	SecurePostHook(objectId, listFunctionName, function()
		if libFilters.debug then dd("GAMEPAD fragment - post hook %q - %s, %s", tos(sceneId:GetName()), tos(hookName), tos(listFunctionName)) end
		if checkFunc == nil or (checkFunc ~= nil and checkFunc() == true) then
			hookListFragmentsState(hookName, sceneId, objectId, listName, targetFragment, checkFunc, addAndRemoveFragment)
		end

		local fragmentsHookedName = hookName .. "_UpdateFragmentAtIsShown"
		if not fragmentsHooked[fragmentsHookedName] then
			--After bank/house bank was initialized update the fragments at the libFilters lookup tables for "is shown"
			if objectId == invBank_GP and listName == "deposit" then
				if hookName == "depositHouseBank" then
					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_HOUSE_BANK_WITHDRAW]["control"]		= ZO_GamepadBankingTopLevelMaskContainerwithdraw
					local withDrawFragment = invBank_GP:GetListFragment("withdraw")
					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_HOUSE_BANK_WITHDRAW]["fragment"] 	= withDrawFragment

					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_HOUSE_BANK_DEPOSIT]["control"]		= ZO_GamepadBankingTopLevelMaskContainerdeposit
					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_HOUSE_BANK_DEPOSIT]["fragment"] 	= targetFragment

					libFilters.mapping.callbacks.usingFragments[true][withDrawFragment]	= { LF_BANK_WITHDRAW, LF_HOUSE_BANK_WITHDRAW }
					libFilters.CreateFragmentCallback(withDrawFragment, { LF_BANK_WITHDRAW, LF_HOUSE_BANK_WITHDRAW }, true)
					fragmentsHooked[fragmentsHookedName] = true
				elseif hookName == "depositBank" then
					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_BANK_WITHDRAW]["control"]			= ZO_GamepadBankingTopLevelMaskContainerwithdraw
					local withDrawFragment = invBank_GP:GetListFragment("withdraw")
					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_BANK_WITHDRAW]["fragment"] 			= withDrawFragment

					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_BANK_DEPOSIT]["control"]			= ZO_GamepadBankingTopLevelMaskContainerdeposit
					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_BANK_DEPOSIT]["fragment"] 			= targetFragment

					libFilters.mapping.callbacks.usingFragments[true][withDrawFragment]	= { LF_BANK_WITHDRAW, LF_HOUSE_BANK_WITHDRAW }
					libFilters.CreateFragmentCallback(withDrawFragment, { LF_BANK_WITHDRAW, LF_HOUSE_BANK_WITHDRAW }, true)
					fragmentsHooked[fragmentsHookedName] = true
				end
			--After guild bank was initialized update the fragments at the libFilters lookup tables for "is shown"
			elseif objectId == invGuildBank_GP and listName == "deposit" then
				libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_GUILDBANK_WITHDRAW]["control"]			= ZO_GuildBankTopLevel_GamepadMaskContainerwithdraw
				local withDrawFragment = invGuildBank_GP:GetListFragment("withdraw")
				libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_GUILDBANK_WITHDRAW]["fragment"] 		= withDrawFragment

				libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_GUILDBANK_DEPOSIT]["control"]			= ZO_GuildBankTopLevel_GamepadMaskContainerdeposit
				libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_GUILDBANK_DEPOSIT]["fragment"] 			= targetFragment

				libFilters.mapping.callbacks.usingFragments[true][withDrawFragment]	= { LF_GUILDBANK_WITHDRAW }
				libFilters.CreateFragmentCallback(withDrawFragment, { LF_GUILDBANK_WITHDRAW }, true)
				fragmentsHooked[fragmentsHookedName] = true
			end
		end
	end)
end


------------------------------------------------------------------------------------------------------------------------
-- Custom added Gamepad inventory type fragment's sub-class
-- These fragments will be used to automatically transfer the .additionalFilter via their layoutData and function
-- self:ApplyInventoryLayout(self.layoutData) to the e.g. PLAYER_INVENTORY.inventories[INV_BANK] etc. as they show
-- Else one would have been able to e.g. use the via dereferedInitialized created lists' (deposit, withdraw e.g.)
-- fragments directly, but they do not use this layoutData nor additionalFilters. So LibFilters stores it's
-- filterFunction in there, like the keyboard mode does
------------------------------------------------------------------------------------------------------------------------
local LibFilters_InventoryLayoutFragment = ZO_SceneFragment:Subclass()
libFilters.InventoryLayoutFragmentClass = LibFilters_InventoryLayoutFragment

function LibFilters_InventoryLayoutFragment:New(...)
	local fragment = ZO_SceneFragment.New(self)
    fragment:Initialize(...)
    return fragment
end
function LibFilters_InventoryLayoutFragment:Initialize(layoutData)
    if layoutData then
        self.layoutData = layoutData
    else
        self.layoutData = {}
    end
end
function LibFilters_InventoryLayoutFragment:Show()
	self:ApplyInventoryLayout(self.layoutData)
	self:OnShown()
end
function LibFilters_InventoryLayoutFragment:Hide()
	self:OnHidden()
	self:ApplyInventoryLayout(gamepadLibFiltersInventoryFragment.layoutData)
end

--Use the same layoutData as within Keyboard mode. If the fragments are shown the layoutData, which contains the
--.additionalFilter entry, will be copied to the PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK].additionalFilter
--Actually happens like done in vanilla game for keybord mode, now for gamepad mode via LibFilters as well.
-->Vanila keyboard mode code, which applies the layoutData.additionalFilter (which is e.g. our hooked fragment
-->BACKPACK_MENU_BAR_LAYOUT_FRAGMENT or BACKPACK_BANK_LAYOUT_FRAGMENT)
-->https://github.com/esoui/esoui/blob/306d6f936a0daa58a24db85b85dd264a04d10699/esoui/ingame/inventory/inventory.lua#L2103
function LibFilters_InventoryLayoutFragment:ApplyInventoryLayout(layoutData)
	--[[
	if layoutData == PLAYER_INVENTORY.appliedLayout and not layoutData.alwaysReapplyLayout then
		return
	end
	]]
	playerInventory.appliedLayout                                     = layoutData
	playerInventory.inventories[playerInventoryType].additionalFilter = layoutData.additionalFilter
end


------------------------------------------------------------------------------------------------------------------------
-- Hooks that need to be done on initialization of controls/fragments etc.
------------------------------------------------------------------------------------------------------------------------
SecurePostHook("ZO_TradingHouse_Browse_Gamepad_OnInitialize", function()
	--Update trading house browse
	local tradingHouseBrowse_GP = GAMEPAD_TRADING_HOUSE_BROWSE
	if not fragmentsHooked["GAMEPAD_TRADING_HOUSE_BROWSE"] and tradingHouseBrowse_GP ~= nil then
		--Update the fragment exists checks with the now existing guild store sell fragment
		gamepadTradingHouseBrowseFragment = tradingHouseBrowse_GP.fragment
		libFilters.constants.gamepad.tradingHouseBrowse_GP = tradingHouseBrowse_GP
		libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_GUILDSTORE_BROWSE] = {
			["control"] = tradingHouseBrowse_GP, ["scene"] = gpc.invGuildStoreSellScene_GP,	["fragment"] = gamepadTradingHouseBrowseFragment,
		}
		libFilters.mapping.callbacks.usingFragments[true][gamepadTradingHouseBrowseFragment]   = { LF_GUILDSTORE_BROWSE }
		libFilters.CreateFragmentCallback(gamepadTradingHouseBrowseFragment, { LF_GUILDSTORE_BROWSE }, true)

		fragmentsHooked["GAMEPAD_TRADING_HOUSE_BROWSE"] = true
	end
end)

local function isInvCategory(categoryIndex)
	if categoryIndex ~= nil and invBackpack_GP.categoryList then
		local selectedIndex = invBackpack_GP.categoryList.selectedIndex
		if selectedIndex ~= nil then
			if selectedIndex == categoryIndex then --Currencies
				return true
			end
		end
	end
	return false
end

local function gamepadInventorySelectedCategoryChecks(selectedGPInvFilter, p_comingFromCraftBagList)
	--Get the currently selected gamepad inventory category
	if selectedGPInvFilter ~= nil then
		--Raise the inventory hidden callback
		updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryFragment)
		if libFilters.debug then dd("-> No-inventory - Removed CUSTOM inventory fragment") end
		invRootScene:RemoveFragment(gamepadLibFiltersInventoryFragment)

		if selectedGPInvFilter == ITEMFILTERTYPE_QUEST then
			if libFilters.debug then dd(">Gamepad Inventory quest is shown, fire SHOWN callback for quest") end
			updateSceneManagerAndHideFragment(quickslotFragment_GP)
			if p_comingFromCraftBagList == true then
				--Raise callback for gamepad inventory quest
				--If coming from craftbag delay the inv quest shown callback raise as else the LF_CRAFTBAG HIDDEN raise
				--will properly fire before
				zo_callLater(function()
					if libFilters.debug then dd(">>Gamepad Inventory quest DELAYED SHOW") end
					invRootScene:AddFragment(gamepadLibFiltersInventoryQuestFragment)
					gamepadLibFiltersInventoryQuestFragment:Show()
				end, 5)
			else
				--Raise callback for gamepad inventory quest
				invRootScene:AddFragment(gamepadLibFiltersInventoryQuestFragment)
				gamepadLibFiltersInventoryQuestFragment:Show()
			end

		elseif selectedGPInvFilter == ITEMFILTERTYPE_QUEST_QUICKSLOT then
			if libFilters.debug then dd(">Gamepad Inventory quickslots is shown, fire HIDDEN callback for quickslots") end
			updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryQuestFragment)
			invRootScene:RemoveFragment(gamepadLibFiltersInventoryQuestFragment)

			--Raise callback for gamepad inventory quickslot
			quickslotFragment_GP:Show()
		end
	else
		--No selected filterType, do checks via other parameters (e.g. currencies)
		if isInvCategory(1) then --Currencies
			updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryFragment)
			if libFilters.debug then dd("-> No-inventory - Removed CUSTOM inventory fragment") end
			invRootScene:RemoveFragment(gamepadLibFiltersInventoryFragment)

			updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryQuestFragment)
			invRootScene:RemoveFragment(gamepadLibFiltersInventoryQuestFragment)
			updateSceneManagerAndHideFragment(quickslotFragment_GP)
		end
	end
end

local function onGamepadInventoryShownFragmentsUpdate(selectedGPInvFilter)
	local debugEnabled = libFilters.debug
	local isInvQuest = false
	local isInvQuickslots = false
	local isCurrencies = isInvCategory(1) --Currencies
	if selectedGPInvFilter ~= nil then
		if selectedGPInvFilter == ITEMFILTERTYPE_QUEST then
			isInvQuest = true

		elseif selectedGPInvFilter == ITEMFILTERTYPE_QUEST_QUICKSLOT then
			isInvQuickslots = true
		end
	end

	if debugEnabled then dd(">>onGamepadInventoryShownFragmentsUpdate - isInvQuest: %s, isInvQuickslots: %s", tos(isInvQuest), tos(isInvQuickslots)) end
	if not isInvQuickslots then
		updateSceneManagerAndHideFragment(quickslotFragment_GP)
	end
	if not isInvQuest then
		updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryQuestFragment)
		invRootScene:RemoveFragment(gamepadLibFiltersInventoryQuestFragment)
	end
	if not isCurrencies and not isInvQuickslots and not isInvQuest then
		if not invRootScene:HasFragment(gamepadLibFiltersInventoryFragment) and not gamepadLibFiltersInventoryFragment:IsShowing() then
			if debugEnabled then dd("-> Inventory - Added CUSTOM inventory fragment, and SHOW") end
			invRootScene:AddFragment(gamepadLibFiltersInventoryFragment)
			gamepadLibFiltersInventoryFragment:Show()
		else
			if debugEnabled then dd("<- Inventory - CUSTOM inventory fragment already added and/or SHOWN") end
		end
	end
end

local function raiseGamepadInventoryFragmentSHOWNDelayed(delay, selectedGPInvFilter)
	--Call delayed with 50ms to let the LF_CRAFTBAG fragment HIDDEN state fire properly before LF_INVENTORY will be shown again!
	delay = delay or 50
	if libFilters.debug then dd(">raiseGamepadInventoryFragmentSHOWNDelayed - delay: %s", tos(delay)) end
	zo_callLater(function()
		if libFilters.debug then dd(">Gamepad Inventory is shown, fire SHOWN callback of fragment - comingFromCraftBagList: %s", tos(comingFromCraftBagList)) end
		onGamepadInventoryShownFragmentsUpdate(selectedGPInvFilter)
	end, delay)
end

SecurePostHook(invBackpack_GP, "OnDeferredInitialize", function(self)
	if libFilters.debug then dd("!-!-! GAMEPAD Inventory OnDeferredInitialize") end

	--Add a callback to GAMEPAD_INVENTORY.categoryList SelectedDataChanged to update the current LibFilters filterType and fire the callbacks
	--Match the tooltip to the selected data because it looks nicer
	local function OnSelectedCategoryChangedLibFilters(list, selectedData)
		local selectedGPInvFilter = invBackpack_GP.selectedItemFilterType
		if libFilters.debug then dd("?? GAMEPAD inventory:OnSelectedDataChanged: %s [%s], comingFromCB: %s", tos(selectedData.text), tos(selectedGPInvFilter), tos(comingFromCraftBagList)) end

		if not libFilters.isInitialized then return end

		--At normal inventory categoryList?
		if libFilters:IsInventoryShown()  then
			if comingFromCraftBagList == false then
				if libFilters.debug then dd(">Gamepad Inventory is shown, fire SHOWN callback of fragment - comingFromCraftBagList: %s", tos(comingFromCraftBagList)) end
				onGamepadInventoryShownFragmentsUpdate(selectedGPInvFilter)
			else
				raiseGamepadInventoryFragmentSHOWNDelayed(50, selectedGPInvFilter)
			end

			--Still at CraftBag list
		elseif libFilters:IsVanillaCraftBagShown() then
			--Switching back to inventory categoryList?
			if comingFromCraftBagList == true then
				raiseGamepadInventoryFragmentSHOWNDelayed(50, selectedGPInvFilter)
			end

		else
			gamepadInventorySelectedCategoryChecks(selectedGPInvFilter, comingFromCraftBagList)
		end
		comingFromCraftBagList = false
	end
	invBackpack_GP.categoryList:SetOnSelectedDataChangedCallback(OnSelectedCategoryChangedLibFilters)

	--Update the control and special checks controls with the now existing CraftBag list controls
	craftBagList_GP = invBackpack_GP.craftBagList
	craftBagFragment_GP = craftBagList_GP._fragment
	libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_CRAFTBAG]["control"] = craftBagFragment_GP.control  --ZO_GamepadInventoryTopLevelMaskContainerCraftBag

	--Not needed anymore as specialFunction changed to libFilters internally LibFilters3:IsVanillaCraftBagShown()
	--libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_CRAFTBAG]["special"][1]["control"] 		= craftBagList_GP
	--libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_CRAFTBAG]["special"][1]["params"][1]	= craftBagList_GP

	libFilters.mapping.callbacks.usingFragments[true][craftBagFragment_GP] = { LF_CRAFTBAG }
	libFilters.CreateFragmentCallback(craftBagFragment_GP, { LF_CRAFTBAG }, true)

	--Add StateChange callback to GAMEPAD_INVENTORY_FRAGMENT and show/hide the custom inventory fragment of LibFilters with this vanilla fragment
	invFragment_GP:RegisterCallback("StateChange", function(oldState, newState)
		if libFilters.debug then dd("GAMEPAD Inventory FRAGMENT - State: " ..tos(newState)) end
		fragmentChange(oldState, newState, invFragment_GP, gamepadLibFiltersInventoryFragment,
				function(p_sourceFragment, p_targetFragment) return end, --showing
				function(p_sourceFragment, p_targetFragment)
					if invRootScene:HasFragment(p_targetFragment) then
						if libFilters.debug then dd("GAMEPAD CUSTOM inventory FRAGMENT - show: " ..tos(p_targetFragment)) end
						p_targetFragment:Show()
					else
						if libFilters:IsInventoryShown() then
							if libFilters.debug then dd("GAMEPAD CUSTOM inventory FRAGMENT > ADDED - show: " ..tos(p_targetFragment)) end
							invRootScene:AddFragment(p_targetFragment)
							p_targetFragment:Show()
						end
					end
					return
				end, --shown
				function(p_sourceFragment, p_targetFragment) return end, --hiding
				function(p_sourceFragment, p_targetFragment)
					if invRootScene:HasFragment(p_targetFragment) then
						if libFilters.debug then dd("GAMEPAD CUSTOM inventory FRAGMENT - hide: " ..tos(p_targetFragment)) end
						p_targetFragment:Hide()
					end
					return
				end --hidden
		)
	end)
end)


------------------------------------------------------------------------------------------------------------------------
-- Custom added Gamepad inventory type fragments -> Create the fragments now
------------------------------------------------------------------------------------------------------------------------
local gamepadLibFiltersDefaultFragment = LibFilters_InventoryLayoutFragment:New(
		{
			additionalFilter = function(slot) return true end
		})


local function createCustomGamepadFragmentsAndNeededHooks()
	if libFilters.debug then dd("---Create custom gamepad fragments---") end
	if not libFilters.isInitialized then return end

	--Player bank deposit
	gamepadLibFiltersBankDepositFragment 			= ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersBankDepositFragment._name 		= getCustomLibFiltersFragmentName(LF_BANK_DEPOSIT)
	_G[gamepadLibFiltersBankDepositFragment._name]	= gamepadLibFiltersBankDepositFragment
	hookFragmentStateByPostHookListInitFunction("depositBank", invBankScene_GP, invBank_GP,
			"deposit", "InitializeLists",
			gamepadLibFiltersBankDepositFragment,
			function() return GetBankingBag() == BAG_BANK end, true)


	--House bank deposit
	gamepadLibFiltersHouseBankDepositFragment 			= ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersHouseBankDepositFragment._name 	= getCustomLibFiltersFragmentName(LF_HOUSE_BANK_DEPOSIT)
	_G[gamepadLibFiltersHouseBankDepositFragment._name]	= gamepadLibFiltersHouseBankDepositFragment
	hookFragmentStateByPostHookListInitFunction("depositHouseBank", invBankScene_GP, invBank_GP,
			"deposit", "InitializeLists",
			gamepadLibFiltersHouseBankDepositFragment,
			function() return IsHouseBankBag(GetBankingBag()) end, true)

	-- Gamepad bank and house bank: Used for switching the gamepad bank's fragment depending if house bank or not
	--[[
	--Not needed anymore as it will be done within hookFragmentStateByPostHookListInitFunction last's parameter addAndRemoveFragment = true
	ZO_PreHook(invBank_GP, 'OnOpenBank', function(self, bankBag)
		if bankBag == BAG_BANK then
			invBankScene_GP:RemoveFragment(gamepadLibFiltersHouseBankDepositFragment)
			invBankScene_GP:AddFragment(gamepadLibFiltersBankDepositFragment)
		else
			--House bank
			invBankScene_GP:RemoveFragment(gamepadLibFiltersBankDepositFragment)
			invBankScene_GP:AddFragment(gamepadLibFiltersHouseBankDepositFragment)
		end
		return false
	end)
	]]


	--Guild bank deposit
	gamepadLibFiltersGuildBankDepositFragment 			= ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersGuildBankDepositFragment._name 	= getCustomLibFiltersFragmentName(LF_GUILDBANK_DEPOSIT)
	_G[gamepadLibFiltersGuildBankDepositFragment._name]	= gamepadLibFiltersGuildBankDepositFragment
	hookFragmentStateByPostHookListInitFunction("depositGuildBank", invGuildBankScene_GP, invGuildBank_GP,
			"deposit", "InitializeLists",
			gamepadLibFiltersGuildBankDepositFragment, nil, false)


	--Trading house = Guild store sell
	gamepadLibFiltersGuildStoreSellFragment 			= ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersGuildStoreSellFragment._name 		= getCustomLibFiltersFragmentName(LF_GUILDSTORE_SELL)
	_G[gamepadLibFiltersGuildStoreSellFragment._name]	= gamepadLibFiltersGuildStoreSellFragment


	--The GAMEPAD_TRADING_HOUSE_SELL variable is not given until gamepad mode is enabled and the trading house sell panel is opened...
	--So we will use TRADING_HOUSE_GAMEPAD instead, function SetCurrentListObject(GAMEPAD_TRADING_HOUSE_SELL)
	SecurePostHook(invGuildStore_GP, "SetCurrentMode", function(self, tradingMode)
		if not libFilters.isInitialized then return end
		if libFilters.debug then dd("GAMEPAD_TRADING_HOUSE - SetCurrentMode: " ..tos(tradingMode)) end
		if tradingMode == ZO_TRADING_HOUSE_MODE_SELL then
			--Delay the fragment addition so the HIDE of GuildStore browse will finish properly before
			zo_callLater(function()
				invGuildStoreSellScene_GP:AddFragment(gamepadLibFiltersGuildStoreSellFragment)
			end, 200)
		else
			updateSceneManagerAndHideFragment(gamepadLibFiltersGuildStoreSellFragment)
			invGuildStoreSellScene_GP:RemoveFragment(gamepadLibFiltersGuildStoreSellFragment)
		end
	end)


	--Mail send
	gamepadLibFiltersMailSendFragment 				= ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersMailSendFragment._name 		= getCustomLibFiltersFragmentName(LF_MAIL_SEND)
	_G[gamepadLibFiltersMailSendFragment._name]		= gamepadLibFiltersMailSendFragment
	--[[
	--Hide/Show with GAMEPAD_MAIL_SEND_FRAGMENT
	GAMEPAD_MAIL_SEND_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
		if libFilters.debug then dd("GAMEPAD_MAIL_SEND_FRAGMENT - State: " ..tos(newState)) end
		fragmentChange(oldState, newState, GAMEPAD_MAIL_SEND_FRAGMENT, gamepadLibFiltersMailSendFragment,
				function(sourceFragment, targetFragment) return end, --showing
				function(sourceFragment, targetFragment)
					targetFragment:Show()
					return
				end, --shown
				function(sourceFragment, targetFragment) return end, --hiding
				function(sourceFragment, targetFragment)
					targetFragment:Hide()
					return
				end --hidden
		)
	end)
	]]
	ZO_PreHook(invMailSend_GP, 'SwitchToFragment', function(self, fragment)
		if not libFilters.isInitialized then return end

		if fragment == invMailSendFragment_GP then
			if libFilters.debug then dd("Gamepad Mail Send Scene:SwitchToFragment - Adding custom mail send fragment") end
			invMailSendScene_GP:AddFragment(gamepadLibFiltersMailSendFragment)
		else
			updateSceneManagerAndHideFragment(gamepadLibFiltersMailSendFragment)
			if libFilters.debug then dd("Gamepad Mail Send Scene:SwitchToFragment - Removing custom mail send fragment") end
			invMailSendScene_GP:RemoveFragment(gamepadLibFiltersMailSendFragment)
		end
	end)


	--Player to player trade
	gamepadLibFiltersPlayerTradeFragment 			= ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersPlayerTradeFragment._name 		= getCustomLibFiltersFragmentName(LF_TRADE)
	_G[gamepadLibFiltersPlayerTradeFragment._name] 	= gamepadLibFiltersPlayerTradeFragment


	--Player inventory quest
	gamepadLibFiltersInventoryQuestFragment			= ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersInventoryQuestFragment._name 	= getCustomLibFiltersFragmentName(LF_INVENTORY_QUEST)
	_G[gamepadLibFiltersInventoryQuestFragment._name]= gamepadLibFiltersInventoryQuestFragment

	gamepadLibFiltersInventoryQuestFragment:RegisterCallback("StateChange", function(oldState, newState)
		if libFilters.debug then dd("GAMEPAD CUSTOM Inventory Quest FRAGMENT - State: " ..tos(newState)) end
	end)


	--Player inventory
	gamepadLibFiltersInventoryFragment              = ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersInventoryFragment._name 		= getCustomLibFiltersFragmentName(LF_INVENTORY)
	_G[gamepadLibFiltersInventoryFragment._name]	= gamepadLibFiltersInventoryFragment

	gamepadLibFiltersInventoryFragment:RegisterCallback("StateChange", function(oldState, newState)
		if libFilters.debug then dd("GAMEPAD CUSTOM Inventory FRAGMENT - State: " ..tos(newState)) end
	end)


	SecurePostHook(invBackpack_GP, "SetCurrentList", function(self, list)
		if libFilters.debug then dd("?? GAMEPAD inventory:SetCurrentList") end
		if not libFilters.isInitialized then return end

		comingFromCraftBagList = false
		if list == invBackpack_GP.craftBagList then
			updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryFragment)
			updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryQuestFragment)
			updateSceneManagerAndHideFragment(quickslotFragment_GP)
			if libFilters.debug then dd("-> CraftBag - Removed CUSTOM inventory fragment") end
			invRootScene:RemoveFragment(gamepadLibFiltersInventoryFragment)
			invRootScene:RemoveFragment(gamepadLibFiltersInventoryQuestFragment)

		else
			--Coming from CraftBag?
			if craftBagFragment_GP ~= nil and self.previousListType == "craftBagList" then
				if libFilters.debug then dd("-> Coming from CraftBag - Hiding the fragment") end
				--If the normal custom inventory fragment is given at the gamepad inventory root scene the craftbag fragment SCENE_HIDDEN state will not raise
				--before the inventory fragment SHOWN raises. So we need to delay the SHOWN fragment stateChange of the normal LF_INVENTORY a bit here, else the error message
				--"<<fragmentOfLastFilterType not valid" in libFilters:RaiseCallback will prevent the SCENE_HIDDEN of LF_CRAFTBAG
				--Variable comingFromCraftBagList will be checked and used in GAMEPAD_INVENTORY.categoryList:SetOnSelectedDataChangedCallback() hook, which is called after
				--the categoryList was shown (as we come back from the craftbag)
				comingFromCraftBagList = true
			end

			--Check for non-inventory selected entries in the categorylist, like "quests" or "quickslots" and remove the custom inv. fragment then
			if libFilters:IsInventoryShown() then
				if comingFromCraftBagList == false then
					onGamepadInventoryShownFragmentsUpdate()
				end
			else
				local selectedGPInvFilter = invBackpack_GP.selectedItemFilterType
				gamepadInventorySelectedCategoryChecks(selectedGPInvFilter, comingFromCraftBagList)
			end
		end
	end)

	--Quickslots -> Updating custom inventory fragment's shown state
	-->Should not be needed anymore due to invBackpack_GP.itemList._fragment StateChange above
	--[[
	gpc.quickslotFragment_GP:RegisterCallback("StateChange", function(oldState, newState)
		if libFilters.debug then dd("GAMEPAD quickslot FRAGMENT - State: " ..tos(newState)) end
		fragmentChange(oldState, newState, nil, gamepadLibFiltersInventoryFragment,
				function(p_sourceFragment, p_targetFragment) return end, --showing
				function(p_sourceFragment, p_targetFragment)
					if invRootScene:HasFragment(p_targetFragment) then
						if libFilters.debug then dd("GAMEPAD Quickslots - inventory FRAGMENT - hide: " ..tos(p_targetFragment)) end
						p_targetFragment:Hide()
					end
					return
				end, --shown
				function(p_sourceFragment, p_targetFragment) return end, --hiding
				function(p_sourceFragment, p_targetFragment)
					if invRootScene:HasFragment(p_targetFragment) then
						if libFilters.debug then dd("GAMEPAD Quickslots - inventory FRAGMENT - show: " ..tos(p_targetFragment)) end
						p_targetFragment:Show()
					end
					return
				end --hidden
		)
	end)
	]]

	------------------------------------------------------------------------------------------------------------------------
	--Conditions to check if a fragment should be shown or not
	------------------------------------------------------------------------------------------------------------------------
	gamepadLibFiltersBankDepositFragment:SetConditional(function()
		return invBankScene_GP:IsShowing() and GetBankingBag() == BAG_BANK and invBank_GP:IsInDepositMode()
	end)


	gamepadLibFiltersHouseBankDepositFragment:SetConditional(function()
		return invBankScene_GP:IsShowing() and (IsHouseBankBag(GetBankingBag()) and invBank_GP:IsInDepositMode())
	end)


	gamepadLibFiltersGuildBankDepositFragment:SetConditional(function()
		return invGuildBankScene_GP:IsShowing() and invGuildBank_GP:IsInDepositMode()
	end)

	--[[
	--Obsolete as fragment will be added/removed to/from guildStore scene with conditions already
	gamepadLibFiltersGuildStoreSellFragment:SetConditional(function()
		return invGuildStoreSellScene_GP:IsShowing()
				and ((invGuildStore_GP ~= nil and invGuildStore_GP:GetCurrentMode() == GAMEPAD_TRADING_HOUSE_SELL)
				or (ZO_TradingHouse_GamepadMaskContainerSell ~= nil and not ZO_TradingHouse_GamepadMaskContainerSell:IsHidden()))
	end)
	]]

	local function gpInvNoCraftBagShowing()
		return invRootScene:IsShowing() and (invBackpack_GP.craftBagList == nil
				or (invBackpack_GP.craftBagList ~= nil and invBackpack_GP.craftBagList:IsActive() == false))
	end

	gamepadLibFiltersInventoryQuestFragment:SetConditional(function()
		return gpInvNoCraftBagShowing() and invBackpack_GP.selectedItemFilterType == ITEMFILTERTYPE_QUEST

	end)

	gamepadLibFiltersInventoryFragment:SetConditional(function()
		return gpInvNoCraftBagShowing()
	end)


	------------------------------------------------------------------------------------------------------------------------
	-- Add the created fragments to the LibFilters gamepad fragment constants so they are not nil anymore in
	-- LibFilters-3.0.lua later on.
	-- See constants.lua -> table gamepadConstants.customFragments with the pre-defined placeholders
	--> [LF_*] = {name="...", fragment=nil},
	------------------------------------------------------------------------------------------------------------------------
	local customFragmentsUpdateRef                           						= 	libFilters.constants.gamepad.customFragments
	customFragmentsUpdateRef[LF_INVENTORY].fragment          						= 	gamepadLibFiltersInventoryFragment
	customFragmentsUpdateRef[LF_BANK_DEPOSIT].fragment      						= 	gamepadLibFiltersBankDepositFragment
	customFragmentsUpdateRef[LF_GUILDBANK_DEPOSIT].fragment 						= 	gamepadLibFiltersGuildBankDepositFragment
	customFragmentsUpdateRef[LF_HOUSE_BANK_DEPOSIT].fragment 						= 	gamepadLibFiltersHouseBankDepositFragment
	customFragmentsUpdateRef[LF_GUILDSTORE_SELL].fragment               			= 	gamepadLibFiltersGuildStoreSellFragment
	customFragmentsUpdateRef[LF_MAIL_SEND].fragment                     			= 	gamepadLibFiltersMailSendFragment
	customFragmentsUpdateRef[LF_TRADE].fragment                         			= 	gamepadLibFiltersPlayerTradeFragment
	customFragmentsUpdateRef[LF_INVENTORY_QUEST].fragment 							=   gamepadLibFiltersInventoryQuestFragment

	--Update the table libFilters.LF_FilterTypeToReference for the gamepad mode fragments
	-->THIS TABLE IS USED TO GET THE FRAGMENT's REFERENCE OF GAMEPAD filterTypes WITHIN LibFilters-3.0.lua, function ApplyAdditionalFilterHooks()!
	LF_FilterTypeToReference[true][LF_INVENTORY]          							= 	{ gamepadLibFiltersInventoryFragment }
	LF_FilterTypeToReference[true][LF_BANK_DEPOSIT]       							= 	{ gamepadLibFiltersBankDepositFragment }
	LF_FilterTypeToReference[true][LF_GUILDBANK_DEPOSIT]  							= 	{ gamepadLibFiltersGuildBankDepositFragment }
	LF_FilterTypeToReference[true][LF_HOUSE_BANK_DEPOSIT] 							= 	{ gamepadLibFiltersHouseBankDepositFragment }
	LF_FilterTypeToReference[true][LF_GUILDSTORE_SELL]                            	= 	{ gamepadLibFiltersGuildStoreSellFragment }
	LF_FilterTypeToReference[true][LF_MAIL_SEND]                                  	= 	{ gamepadLibFiltersMailSendFragment }
	LF_FilterTypeToReference[true][LF_TRADE]                                      	= 	{ gamepadLibFiltersPlayerTradeFragment }
	LF_FilterTypeToReference[true][LF_INVENTORY_QUEST] 								=   { gamepadLibFiltersInventoryQuestFragment }

	-->Update the references to the fragments so one is able to use them within the "isShown" routines
	--LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_INVENTORY]["fragment"] 		= 	gamepadLibFiltersInventoryFragment --uses GAMEPAD_INVENTORY_FRAGMENT now for detection as this' shown state get's updated properly after quickslot wheel was closed again
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_BANK_DEPOSIT]["fragment"] 		=	gamepadLibFiltersBankDepositFragment
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_GUILDBANK_DEPOSIT]["fragment"] = 	gamepadLibFiltersGuildBankDepositFragment
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_HOUSE_BANK_DEPOSIT]["fragment"]= 	gamepadLibFiltersHouseBankDepositFragment
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_GUILDSTORE_SELL]["fragment"] 	= 	gamepadLibFiltersGuildStoreSellFragment
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_MAIL_SEND]["fragment"]       	= 	gamepadLibFiltersMailSendFragment
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_TRADE]["fragment"]           	= 	gamepadLibFiltersPlayerTradeFragment
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_INVENTORY_QUEST]["fragment"]	=   gamepadLibFiltersInventoryQuestFragment

	-->Update the new created custom fragments to the callback-by-fragment-StateChange lookup table
	callbacksUsingFragments[true][gamepadLibFiltersInventoryFragment] 				= { LF_INVENTORY }
	callbacksUsingFragments[true][gamepadLibFiltersBankDepositFragment] 			= { LF_BANK_DEPOSIT }
	callbacksUsingFragments[true][gamepadLibFiltersGuildBankDepositFragment] 		= { LF_GUILDBANK_DEPOSIT }
	callbacksUsingFragments[true][gamepadLibFiltersHouseBankDepositFragment] 		= { LF_HOUSE_BANK_DEPOSIT }
	callbacksUsingFragments[true][gamepadLibFiltersGuildStoreSellFragment] 			= { LF_GUILDSTORE_SELL }
	callbacksUsingFragments[true][gamepadLibFiltersMailSendFragment] 				= { LF_MAIL_SEND }
	callbacksUsingFragments[true][gamepadLibFiltersPlayerTradeFragment] 			= { LF_TRADE }
	callbacksUsingFragments[true][gamepadLibFiltersInventoryQuestFragment] 			= { LF_INVENTORY_QUEST }
	--Update the callback invoker fragments
	filterTypeToCallbackRef[true][LF_INVENTORY] = 			{ ref = gamepadLibFiltersInventoryFragment, 		refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_BANK_DEPOSIT] = 		{ ref = gamepadLibFiltersBankDepositFragment, 		refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_GUILDBANK_DEPOSIT] = 	{ ref = gamepadLibFiltersGuildBankDepositFragment, 	refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_HOUSE_BANK_DEPOSIT] = 	{ ref = gamepadLibFiltersHouseBankDepositFragment, 	refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_GUILDSTORE_SELL] = 	{ ref = gamepadLibFiltersGuildStoreSellFragment, 	refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_MAIL_SEND] = 			{ ref = gamepadLibFiltersMailSendFragment, 			refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_TRADE] = 				{ ref = gamepadLibFiltersPlayerTradeFragment, 		refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_INVENTORY_QUEST] = 	{ ref = gamepadLibFiltersInventoryQuestFragment,	refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }

	------------------------------------------------------------------------------------------------------------------------
	-- Gamepad Scenes: Add new custom fragments to the scenes so they show and hide properly
	------------------------------------------------------------------------------------------------------------------------
	--Gamepd player inventory
	--invRootScene:AddFragment(gamepadLibFiltersInventoryFragment) --will be added/removed dynamically via functions invBackpack_GP.categoryList:SetOnSelectedDataChangedCallback and invBackpack_GP:SetCurrentList, and others

	--invGuildBankScene_GP:AddFragment(gamepadLibFiltersGuildBankDepositFragment) --will be added/removed dynamically via function hookFragmentStateByPostHookListInitFunction

	--invGuildStoreSellScene_GP:AddFragment(gamepadLibFiltersGuildStoreSellFragment) --will be added/removed dynamically via function GAMEPAD_TRADING_HOUSE:SetCurrentMode() above

	--invMailSendScene_GP:AddFragment(gamepadLibFiltersMailSendFragment) --will be added/removed dynamically via function mailManagerGamepadScene:SwitchToFragment() above

	invPlayerTradeScene_GP:AddFragment(gamepadLibFiltersPlayerTradeFragment)

	if libFilters.debug then dd(">Custom GAMEPAD fragments were created") end
end
libFilters.CreateCustomGamepadFragmentsAndNeededHooks = createCustomGamepadFragmentsAndNeededHooks

if libFilters.debug then dd("LIBRARY GAMEPAD CUSTOM FRAGMENTS FILE - END") end
