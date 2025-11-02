--[[
	Version:	3.0
	Idea:		IsJustAGhost
	Code by:	IsJustAGhost & Baertram

	Description:
	The gamepad mode does not provide fragments for the backpack, bank and other inventory types as the keyboard mode
	does and hooks into (to add the .additionalFilter function entry). Therefor we create our own "custom fragments" for
	the needed inventory/panel types and add them to the gamepad scenes (which are used already by vanilla UI).
	The fragments can get conditions to prevent them showing (e.g. fragments added to gamepad bank will be normal bank
	deposit, house bank deposit and furniture vault deposit -> the conditions prevent all 3 to be shown at the same time).
	Some fragments need to be added/removed dynamically based on other panel data like the parametric scrolllist's chosen
	categories at inventory (mundus = no, currencies = no, normal inventory categories = yes) and tabs (normal inventory
	or craftbag or Cyrodiil vengeance tab).

	The new added custom fragments inherit from the LibFilters' created own class "LibFilters_InventoryLayoutFragment",
	which creates a "copy-from" default fragment "gamepadLibFiltersDefaultFragment".

	The fragments will be used in LibFilters-3.0.lua to hook into them via libFilters:HookAdditionalFilter

	If you add a new fragment first have a look at file constants.lua, table gpc.customFragments.
	Then search within this file here  for 0) and then add your local variable there, afterwards update sections
	1), 2), 3) and 4) in this file below with your fragment's code and references.
	Also make sure in file constants.lua the entries in table filterTypeToReference[true], filterTypeToCheckIfReferenceIsHidden[tue],
	filterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[true], etc. get updated with the proper variables.
	The references which are kept nil in constants.lua will be updated from this hile here below, from sections 2), 3) and 4).
]]

------------------------------------------------------------------------------------------------------------------------
-- Local speed-up variables
------------------------------------------------------------------------------------------------------------------------
local tos = tostring
local SM = SCENE_MANAGER
--local getScene = SM.GetScene
local playerBankBagIds = {
	[BAG_BANK] = true,
	[BAG_SUBSCRIBER_BANK] = true,
}


------------------------------------------------------------------------------------------------------------------------
-- Local library variables
------------------------------------------------------------------------------------------------------------------------
local libFilters = LibFilters3


--LibFilters local speedup and reference variables
--Overall constants
local constants = 								libFilters.constants
local mapping = 								libFilters.mapping
local callbacks = 								mapping.callbacks
local callbacksUsingFragments = 				callbacks.usingFragments
local filterTypeToCallbackRef = 				callbacks.filterTypeToCallbackRef

local LF_FilterTypeToReference =				mapping.LF_FilterTypeToReference
local LF_FilterTypeToCheckIfReferenceIsHidden = mapping.LF_FilterTypeToCheckIfReferenceIsHidden

local classes = 								libFilters.classes
local LibFilters_InventoryLayoutFragment_Class = classes.InventoryLayoutFragment

local fragments = 								libFilters.fragments
local gpFragments = 							fragments[true]

--Gamepad
local gpc             				= 			constants.gamepad
local invRootScene_GP 				= 			gpc.invRootScene_GP
local invBackpack_GP  				= 			gpc.invBackpack_GP
--local mundusInvCategory_GP = 1 --Mundus index in the Gamepad Inventory categoryList as of - 2025-09-19
--local currencyInvCategory_GP = 2 --Currencies index in the Gamepad Inventory categoryList as of - 2025-09-19

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
--local quickslotScene_GP				=			gpc.quickslotScene_GP

local customFragments_GP          	= 			gpc.customFragments
local fragmentPrefix              	= 			gpc.customFragmentPrefix

local LIBFILTERS_CON_TYPEOFREF_FRAGMENT = constants.typeOfRef[3]

local getFragmentControlName = 	libFilters.GetFragmentControlName

local craftBagList_GP, craftBagFragment_GP
local comingFromCraftBagList = false

local updateLastAndCurrentFilterType, detectShownReferenceNow


local fragmentsHooked = {}


--Debugging
local debugFunctions = libFilters.debugFunctions
local dd = debugFunctions.dd

if libFilters.debug then dd("LIBRARY GAMEPAD CUSTOM FRAGMENTS FILE - START") end


------------------------------------------------------------------------------------------------------------------------
--The default fragment for gamepad LibFilters fragments. Other custom fragments should copy from this one!
------------------------------------------------------------------------------------------------------------------------
-->It uses the LibFilters_InventoryLayoutFragment as a parent class, providing the basic filter possibilities
local gamepadLibFiltersDefaultFragment = LibFilters_InventoryLayoutFragment_Class:New( --See file /Gamepad/gamepadCustomFragment_class.lua
		{ --layoutData passed in
			additionalFilter = function(slot) return true end
		})

--======================================================================================================================
--0) The local variables for the new created custom LibFilters gamepad fragments
-- Add your new custom created fragment variable here, and then update the sections 1), 2), 3) and 4) below!
--======================================================================================================================
local gamepadLibFiltersInventoryFragment = gpFragments.CustomInventoryFragment --do not change!!! Was created in constants already for the class to work properly -> See file /Gamepad/gamepadCustomFragment_class.lua

--Custom added fragments, new local variables
local gamepadLibFiltersBankDepositFragment
local gamepadLibFiltersGuildBankDepositFragment
local gamepadLibFiltersHouseBankDepositFragment
local gamepadLibFiltersGuildStoreSellFragment
local gamepadLibFiltersMailSendFragment
local gamepadLibFiltersPlayerTradeFragment
local gamepadLibFiltersInventoryQuestFragment
local gamepadLibFiltersFurnitureVaultDepositFragment
local gamepadLibFiltersInventoryVengeanceFragment
--======================================================================================================================




------------------------------------------------------------------------------------------------------------------------
-- Local helper functions
------------------------------------------------------------------------------------------------------------------------
---Is*shpw functions
local function isGamepadBankDepositShowing()
	return invBankScene_GP:IsShowing() and invBank_GP:IsInDepositMode()
end

local function isFurnitureVaultShowing()
	return IsFurnitureVault(GetBankingBag())
end

local function isVengeanceCampaign()
	if IsInCampaign() == true and IsCurrentCampaignVengeanceRuleset() == true then
		return invBackpack_GP.vengeanceCategoryList:IsActive()
	end
	return false
end

local function gpInvNoCraftBagShowing()
	return invRootScene_GP:IsShowing() and (invBackpack_GP.craftBagList == nil
			or (invBackpack_GP.craftBagList ~= nil and invBackpack_GP.craftBagList:IsActive() == false))
end

local function checkIfInvAndNotVengeanceCampaign()
	return gpInvNoCraftBagShowing() and not isVengeanceCampaign()
end


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

local function updateSceneManagerAndHideFragment(targetFragment)
	if not targetFragment then return end
	if not targetFragment.sceneManager then targetFragment:SetSceneManager(SM) end
	if not targetFragment:IsHidden() then
		targetFragment:Hide()
	end
end

local function hookListFragmentsState(hookName, sceneId, objectId, listName, targetFragment, preHookCheckFunc, preShowCheckFunc, preHideCheckFunc, addAndRemoveFragment)
	if not libFilters.isInitialized then return end

	addAndRemoveFragment = addAndRemoveFragment or false
	if not fragmentsHooked[hookName] then
		if preHookCheckFunc ~= nil and preHookCheckFunc() ~= true then return end

		if sceneId:IsShowing() then
			if listName == "deposit" then
				if objectId:IsInDepositMode() then
					if preShowCheckFunc ~= nil and preShowCheckFunc() ~= true then return end
					targetFragment:Show()
				else
					if preHideCheckFunc ~= nil and preHideCheckFunc() ~= true then return end
					updateSceneManagerAndHideFragment(targetFragment)
				end
			elseif listName == "withdraw" then
				if objectId:IsInWithdrawMode() then
					if preShowCheckFunc ~= nil and preShowCheckFunc() ~= true then return end
					targetFragment:Show()
				else
					if preHideCheckFunc ~= nil and preHideCheckFunc() ~= true then return end
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
						if preShowCheckFunc ~= nil and preShowCheckFunc() ~= true then return end
						if addAndRemoveFragment == true then
							if libFilters.debug then dd("GAMEPAD " .. tos(hookName) .." list FRAGMENT - Added fragment: " ..tos(p_targetFragment)) end
							sceneId:AddFragment(p_targetFragment)
						end
						p_targetFragment:Show()
						return
					end, --shown
					function(p_sourceFragment, p_targetFragment) return end, --hiding
					function(p_sourceFragment, p_targetFragment)
						if preHideCheckFunc ~= nil and preHideCheckFunc() ~= true then return end
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


local function hookFragmentStateByPostHookListInitFunction(hookName, sceneId, objectId, listName, listFunctionName, targetFragment, fragmentHookCheckFunc, preShowCheckFunc, preHideCheckFunc, addAndRemoveFragment)
	if not sceneId or not objectId or not listName or not listFunctionName or not targetFragment then return end
	SecurePostHook(objectId, listFunctionName, function()
		if libFilters.debug then
			getFragmentControlName = getFragmentControlName or libFilters.GetFragmentControlName
			local fragmentName = getFragmentControlName(targetFragment)
			dd("GAMEPAD fragment %q - post hook %q - %s, %s", tos(fragmentName), tos(sceneId:GetName()), tos(hookName), tos(listFunctionName))
		end
		hookListFragmentsState(hookName, sceneId, objectId, listName, targetFragment, fragmentHookCheckFunc, preShowCheckFunc, preHideCheckFunc, addAndRemoveFragment)


		--Update the constants mapping for the customGamepad controls/fragments etc. references, now as the controls got DeferredIniztialized properly and aren't nil anymore!
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

					libFilters.mapping.callbacks.usingFragments[true][withDrawFragment]	= { LF_BANK_WITHDRAW, LF_HOUSE_BANK_WITHDRAW, LF_FURNITURE_VAULT_WITHDRAW }
					libFilters.CreateFragmentCallback(withDrawFragment, { LF_BANK_WITHDRAW, LF_HOUSE_BANK_WITHDRAW, LF_FURNITURE_VAULT_WITHDRAW }, true)
					fragmentsHooked[fragmentsHookedName] = true
				elseif hookName == "depositBank" then
					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_BANK_WITHDRAW]["control"]			= ZO_GamepadBankingTopLevelMaskContainerwithdraw
					local withDrawFragment = invBank_GP:GetListFragment("withdraw")
					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_BANK_WITHDRAW]["fragment"] 			= withDrawFragment

					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_BANK_DEPOSIT]["control"]			= ZO_GamepadBankingTopLevelMaskContainerdeposit
					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_BANK_DEPOSIT]["fragment"] 			= targetFragment

					libFilters.mapping.callbacks.usingFragments[true][withDrawFragment]	= { LF_BANK_WITHDRAW, LF_HOUSE_BANK_WITHDRAW, LF_FURNITURE_VAULT_WITHDRAW }
					libFilters.CreateFragmentCallback(withDrawFragment, { LF_BANK_WITHDRAW, LF_HOUSE_BANK_WITHDRAW, LF_FURNITURE_VAULT_WITHDRAW }, true)
					fragmentsHooked[fragmentsHookedName] = true
				elseif hookName == "depositFurnitureVault" then
					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_FURNITURE_VAULT_WITHDRAW]["control"]	= ZO_GamepadBankingTopLevelMaskContainerwithdraw
					local withDrawFragment = invBank_GP:GetListFragment("withdraw")
					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_FURNITURE_VAULT_WITHDRAW]["fragment"]	= withDrawFragment

					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_FURNITURE_VAULT_DEPOSIT]["control"]		= ZO_GamepadBankingTopLevelMaskContainerdeposit
					libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_FURNITURE_VAULT_DEPOSIT]["fragment"]	= targetFragment

					libFilters.mapping.callbacks.usingFragments[true][withDrawFragment]	= { LF_BANK_WITHDRAW, LF_HOUSE_BANK_WITHDRAW, LF_FURNITURE_VAULT_WITHDRAW }
					libFilters.CreateFragmentCallback(withDrawFragment, { LF_BANK_WITHDRAW, LF_HOUSE_BANK_WITHDRAW, LF_FURNITURE_VAULT_WITHDRAW }, true)
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
-- Hooks that need to be done on initialization of controls/fragments etc.
------------------------------------------------------------------------------------------------------------------------
local function isInvCategory(categoryIndex)
	if categoryIndex ~= nil and invBackpack_GP.categoryList then
		if invBackpack_GP.categoryList:IsActive() then
			local selectedIndex = invBackpack_GP.categoryList.selectedIndex
			if selectedIndex ~= nil then
				if selectedIndex == categoryIndex then
					return true
				end
			end
		end
	end
	return false
end

local function isCurrencyEntrySelected()
	local isCurrencyEntryCurrentlySelected = (invBackpack_GP.currentlySelectedData ~= nil and invBackpack_GP.currentlySelectedData.isCurrencyEntry) or false
	--if not isCurrencyEntryCurrentlySelected then isCurrencyEntryCurrentlySelected = isInvCategory(currencyInvCategory_GP) end
	return isCurrencyEntryCurrentlySelected
end

local function isMundusEntrySelected()
	local isMundusEntryCurrentlySelected = (invBackpack_GP.currentlySelectedData ~= nil and invBackpack_GP.currentlySelectedData.isMundusEntry) or false
	--if not isMundusEntryCurrentlySelected then isMundusEntryCurrentlySelected = isInvCategory(mundusInvCategory_GP) end
	return isMundusEntryCurrentlySelected
end

local function gamepadInventorySelectedCategoryChecks(selectedGPInvFilter, p_comingFromCraftBagList)
	if libFilters.debug then dd("[ ]gamepadInventorySelectedCategoryChecks - selectedGPInvFilter: " .. tos(selectedGPInvFilter) .. ", comingFromCraftBagList: " .. tos(p_comingFromCraftBagList) ) end

	--Get the currently selected gamepad inventory category
	if selectedGPInvFilter ~= nil then
		--Raise the vengeance inventory hidden callback
		updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryVengeanceFragment)
		--Raise the inventory hidden callback
		updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryFragment)

		if libFilters.debug then dd("-> No-inventory - Removed CUSTOM inventory fragment") end
		invRootScene_GP:RemoveFragment(gamepadLibFiltersInventoryVengeanceFragment)
		invRootScene_GP:RemoveFragment(gamepadLibFiltersInventoryFragment)

		if selectedGPInvFilter == ITEMFILTERTYPE_QUEST then
			if libFilters.debug then dd(">Gamepad Inventory quest is shown, fire SHOWN callback for quest") end
			updateSceneManagerAndHideFragment(quickslotFragment_GP)
			if p_comingFromCraftBagList == true then
				--Raise callback for gamepad inventory quest
				--If coming from craftbag delay the inv quest shown callback raise as else the LF_CRAFTBAG HIDDEN raise
				--will properly fire before
				zo_callLater(function()
					if libFilters.debug then dd(">>Gamepad Inventory quest DELAYED SHOW") end
					invRootScene_GP:AddFragment(gamepadLibFiltersInventoryQuestFragment)
					gamepadLibFiltersInventoryQuestFragment:Show()
				end, 5)
			else
				--Raise callback for gamepad inventory quest
				invRootScene_GP:AddFragment(gamepadLibFiltersInventoryQuestFragment)
				gamepadLibFiltersInventoryQuestFragment:Show()
			end

		elseif selectedGPInvFilter == ITEMFILTERTYPE_QUEST_QUICKSLOT then
			if libFilters.debug then dd(">Gamepad Inventory quickslots is shown, fire HIDDEN callback for quickslots") end
			updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryQuestFragment)
			invRootScene_GP:RemoveFragment(gamepadLibFiltersInventoryQuestFragment)

			--Raise callback for gamepad inventory quickslot
			quickslotFragment_GP:Show()
		end
	else
		--No selected filterType, do checks via other parameters (e.g. currencies, mundus)
		--> If these entries are selected we are not in the inventory, but just at other tabs of that inventory, so LF_INVENTORY should not raise a SHOWN callback!
		if isCurrencyEntrySelected() or isMundusEntrySelected() then
			--Raise the inventory hidden callback
			updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryFragment)
			--Raise the vengeance inventory hidden callback
			updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryVengeanceFragment)

			if libFilters.debug then dd("-> No-inventory - Removed CUSTOM inventory fragment") end
			invRootScene_GP:RemoveFragment(gamepadLibFiltersInventoryVengeanceFragment)
			invRootScene_GP:RemoveFragment(gamepadLibFiltersInventoryFragment)

			updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryQuestFragment)
			invRootScene_GP:RemoveFragment(gamepadLibFiltersInventoryQuestFragment)
			updateSceneManagerAndHideFragment(quickslotFragment_GP)
		else

		end
	end
end

local function onGamepadInventoryShownFragmentsUpdate(selectedGPInvFilter, identifierTab)
	local debugEnabled = libFilters.debug
	if debugEnabled then dd("?> onGamepadInventoryShownFragmentsUpdate - selectedGPInvFilter: " .. tos(selectedGPInvFilter) .. ", identifierTab: " .. tos(identifierTab)) end
	local isInvQuest = false
	local isInvQuickslots = false
	local isCurrencies = isCurrencyEntrySelected()
	local isMundus = isMundusEntrySelected()
	local isVengeance = false

	if type(identifierTab) == "table" then
		isVengeance = identifierTab.vengeance or false
	else
		isVengeance = libFilters:IsVengeanceInventoryShown()
	end

	--Cyrodiil vengeance inventory
	if isVengeance == true then
		--Raise the inventory hidden callback
		updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryFragment)
		invRootScene_GP:RemoveFragment(gamepadLibFiltersInventoryFragment)
		updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryQuestFragment)
		invRootScene_GP:RemoveFragment(gamepadLibFiltersInventoryQuestFragment)
		updateSceneManagerAndHideFragment(quickslotFragment_GP)

		if not invRootScene_GP:HasFragment(gamepadLibFiltersInventoryVengeanceFragment) and not gamepadLibFiltersInventoryVengeanceFragment:IsShowing() then
			if debugEnabled then dd("-> Vengeance Inventory - Added CUSTOM inventory fragment, and SHOW") end
			invRootScene_GP:AddFragment(gamepadLibFiltersInventoryVengeanceFragment)
			gamepadLibFiltersInventoryVengeanceFragment:Show()
		else
			if debugEnabled then dd("<- Vengeance Inventory - CUSTOM inventory fragment already added and/or SHOWN") end
		end

	else
		--Normal inventories
		if selectedGPInvFilter ~= nil then
			if selectedGPInvFilter == ITEMFILTERTYPE_QUEST then
				isInvQuest = true

			elseif selectedGPInvFilter == ITEMFILTERTYPE_QUEST_QUICKSLOT then
				isInvQuickslots = true
			end
		end
		if debugEnabled then dd(">>onGamepadInventoryShownFragmentsUpdate - isInvQuest: %s, isInvQuickslots: %s", tos(isInvQuest), tos(isInvQuickslots)) end

		updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryVengeanceFragment)
		invRootScene_GP:RemoveFragment(gamepadLibFiltersInventoryVengeanceFragment)

		if not isInvQuickslots then
			updateSceneManagerAndHideFragment(quickslotFragment_GP)
		end
		if not isInvQuest then
			updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryQuestFragment)
			invRootScene_GP:RemoveFragment(gamepadLibFiltersInventoryQuestFragment)
		end
		if not isCurrencies and not isInvQuickslots and not isInvQuest and not isMundus then
			if not invRootScene_GP:HasFragment(gamepadLibFiltersInventoryFragment) and not gamepadLibFiltersInventoryFragment:IsShowing() then
				if debugEnabled then dd("-> Inventory - Added CUSTOM inventory fragment, and SHOW") end
				invRootScene_GP:AddFragment(gamepadLibFiltersInventoryFragment)
				gamepadLibFiltersInventoryFragment:Show()
			else
				if debugEnabled then dd("<- Inventory - CUSTOM inventory fragment already added and/or SHOWN") end
			end
		end
	end
end

local function raiseGamepadInventoryFragmentSHOWNDelayed(delay, ...)
	--Call delayed with 50ms to let the LF_CRAFTBAG fragment HIDDEN state fire properly before LF_INVENTORY will be shown again!
	delay = delay or 50
	if libFilters.debug then dd(">raiseGamepadInventoryFragmentSHOWNDelayed - delay: %s", tos(delay)) end
	local varArgs = {...}
	zo_callLater(function()
		if libFilters.debug then dd(">Gamepad Inventory is shown, fire SHOWN callback of fragment - comingFromCraftBagList: %s", tos(comingFromCraftBagList)) end
		onGamepadInventoryShownFragmentsUpdate(unpack(varArgs))
	end, delay)
end

--Add a callback to GAMEPAD_INVENTORY.categoryList SelectedDataChanged to update the current LibFilters filterType and fire the callbacks
--Match the tooltip to the selected data because it looks nicer
local function OnSelectedCategoryChangedLibFilters(list, selectedData)
	local selectedGPInvFilter = invBackpack_GP.selectedItemFilterType
	if libFilters.debug then dd("???? GAMEPAD inventory:OnSelectedDataChanged: %s [%s], comingFromCB: %s", tos(selectedData.text), tos(selectedGPInvFilter), tos(comingFromCraftBagList)) end

	if not libFilters.isInitialized then return end

	--At Cyrodiil vengeance inventory categoryList?
	if libFilters:IsVengeanceInventoryShown() then
		if comingFromCraftBagList == false then
			if libFilters.debug then dd(">Gamepad Vengeance Inventory is shown, fire SHOWN callback of fragment - comingFromCraftBagList: %s", tos(comingFromCraftBagList)) end
			onGamepadInventoryShownFragmentsUpdate(selectedGPInvFilter, { vengeance = true })
		else
			raiseGamepadInventoryFragmentSHOWNDelayed(50, selectedGPInvFilter, { vengeance = true })
		end

	--At normal inventory categoryList?
	elseif libFilters:IsInventoryShown()  then
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

	--Others
	else
		gamepadInventorySelectedCategoryChecks(selectedGPInvFilter, comingFromCraftBagList)
	end
	comingFromCraftBagList = false
end


------------------------------------------------------------------------------------------------------------------------
--Deferred initialization of gamepad inventory: Set a new LibFilters function for SetOnSelectedDataChangedCallback (if any category in the current vertical parametric scroll list changes, eg.. from currency to normal inventory contents)
--hook SetCurrentList to see if any list changes e.g. between inventory, vengeance inventory or carftbag,
--set the fragment's Show/Hide callbacks,
--and update the now not-nil-anymore reference variables etc.
SecurePostHook(invBackpack_GP, "OnDeferredInitialize", function(self)
	if libFilters.debug then dd("!-!-! GAMEPAD Inventory OnDeferredInitialize") end

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
					if invRootScene_GP:HasFragment(p_targetFragment) then
						--20205-09-19 Do not show if the current gamepad inventory list should show the Cyrodiil vengeance inventory
						if isVengeanceCampaign() then
							if libFilters.debug then dd("<GAMEPAD CUSTOM inventory FRAGMENT - HIDING NOW due to Vengeance inventory showing: " ..tos(p_targetFragment)) end
							p_targetFragment:Hide()
						else
							if libFilters.debug then dd("GAMEPAD CUSTOM inventory FRAGMENT - show: " ..tos(p_targetFragment)) end
							p_targetFragment:Show()
						end
					else
						--20205-09-19 Do not show if the current gamepad inventory list should show the Cyrodiil vengeance inventory
						if isVengeanceCampaign() then
							if libFilters.debug then dd("<<GAMEPAD CUSTOM inventory FRAGMENT - HIDING NOW due to Vengeance inventory showing: " ..tos(p_targetFragment)) end
							p_targetFragment:Hide()
						else
							if libFilters:IsInventoryShown() then
								if libFilters.debug then dd("GAMEPAD CUSTOM inventory FRAGMENT > ADDED - show: " ..tos(p_targetFragment)) end
								invRootScene_GP:AddFragment(p_targetFragment)
								p_targetFragment:Show()
							end

						end
					end
					return
				end, --shown
				function(p_sourceFragment, p_targetFragment) return end, --hiding
				function(p_sourceFragment, p_targetFragment)
					if invRootScene_GP:HasFragment(p_targetFragment) then
						if libFilters.debug then dd("GAMEPAD CUSTOM inventory FRAGMENT - hide: " ..tos(p_targetFragment)) end
						p_targetFragment:Hide()
					end
					return
				end --hidden
		)
	end)

	--Only start the SetCurrentList checks after Init of the Gamepad inventory
	local wasGPInventoryListSetBefore = false
	SecurePostHook(invBackpack_GP, "SetCurrentList", function(self, list)
		if libFilters.debug then dd("?? GAMEPAD inventory:SetCurrentList") end
		if not libFilters.isInitialized then return end

		comingFromCraftBagList = false
		if list == invBackpack_GP.craftBagList then
			updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryFragment)
			updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryQuestFragment)
			updateSceneManagerAndHideFragment(gamepadLibFiltersInventoryVengeanceFragment)
			updateSceneManagerAndHideFragment(quickslotFragment_GP)
			if libFilters.debug then dd("-> CraftBag - Removed CUSTOM inventory fragment") end
			invRootScene_GP:RemoveFragment(gamepadLibFiltersInventoryFragment)
			invRootScene_GP:RemoveFragment(gamepadLibFiltersInventoryQuestFragment)
			invRootScene_GP:RemoveFragment(gamepadLibFiltersInventoryVengeanceFragment)

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

			--At Cyrodiil vengeance inventory categoryList?
			if libFilters:IsVengeanceInventoryShown() then
				if comingFromCraftBagList == false then
					onGamepadInventoryShownFragmentsUpdate(nil, { vengeance = true })
				end


			else
				--2025-09-19 What if we are in AvA region and vengeanace is active and we open the inventory the first time?
				--Seems the normal invList is selected and then the vengeance list is selected directly. Which makes the invList
				--callback trigger too and we need to suppress it then "once on first open of the inventory". All following opens seem to work fine and:
				-->See file constants.lua callbackFragmentsBlockedMapping[true][SCENE_SHOWN][invFragment_GP] -> should handle 2nd, 3rd, ... opens "prevention of LV_INVENTORY" too
				if not wasGPInventoryListSetBefore then
					if IsInCampaign() and IsCurrentCampaignVengeanceRuleset() then
						wasGPInventoryListSetBefore = true
						return
					end
				end

				--Check for non-inventory selected entries in the categorylist, like "quests" or "quickslots" and remove the custom inv. fragment then
				if libFilters:IsInventoryShown() then
					if comingFromCraftBagList == false then
						onGamepadInventoryShownFragmentsUpdate()
					end
				else
					gamepadInventorySelectedCategoryChecks(invBackpack_GP.selectedItemFilterType, comingFromCraftBagList)
				end
			end
		end
		wasGPInventoryListSetBefore = true
	end)
end)

------------------------------------------------------------------------------------------------------------------------
--Trading house (guild vendor) -  Search/Browse
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



------------------------------------------------------------------------------------------------------------------------
-- 1) Custom added Gamepad inventory type fragments -> Create the fragments now
------------------------------------------------------------------------------------------------------------------------
local function createCustomGamepadFragmentsAndNeededHooks()
	if libFilters.debug then dd("---Create custom gamepad fragments---") end
	if not libFilters.isInitialized then return end

	--Player bank deposit
	gamepadLibFiltersBankDepositFragment 			= ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersBankDepositFragment._name 		= getCustomLibFiltersFragmentName(LF_BANK_DEPOSIT)
	_G[gamepadLibFiltersBankDepositFragment._name]	= gamepadLibFiltersBankDepositFragment
	--> Will be added/removed via hookFragmentStateByPostHookListInitFunction
	hookFragmentStateByPostHookListInitFunction("depositBank", invBankScene_GP, invBank_GP, "deposit", "InitializeLists",
			gamepadLibFiltersBankDepositFragment,
			nil, --the checkFunc here checks if the fragment should be hooked as the OnDeferredInitialization happens,
	--so we cannot check for anything specific about the bagId to differ the normal, houseBank or furniturea vault here!
	--These kind of chekcs needs to be added to the fragment's conditional checks (see below at gamepadLibFiltersBankDepositFragment:SetConditional)
			nil, --preShowCheckFunc
			nil, --preHideCheckFunc
			true)


	--House bank deposit
	gamepadLibFiltersHouseBankDepositFragment 			= ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersHouseBankDepositFragment._name 	= getCustomLibFiltersFragmentName(LF_HOUSE_BANK_DEPOSIT)
	_G[gamepadLibFiltersHouseBankDepositFragment._name]	= gamepadLibFiltersHouseBankDepositFragment
	--> Will be added/removed via hookFragmentStateByPostHookListInitFunction
	hookFragmentStateByPostHookListInitFunction("depositHouseBank", invBankScene_GP, invBank_GP, "deposit", "InitializeLists",
			gamepadLibFiltersHouseBankDepositFragment,
			nil, --See above at gamepadLibFiltersBankDepositFragment
			nil, --preShowCheckFunc
			nil, --preHideCheckFunc
			true)

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

	--Furniture vault deposit
	gamepadLibFiltersFurnitureVaultDepositFragment 				= ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersFurnitureVaultDepositFragment._name 		= getCustomLibFiltersFragmentName(LF_FURNITURE_VAULT_DEPOSIT)
	_G[gamepadLibFiltersFurnitureVaultDepositFragment._name]	= gamepadLibFiltersFurnitureVaultDepositFragment
	--> Will be added/removed via hookFragmentStateByPostHookListInitFunction
	hookFragmentStateByPostHookListInitFunction("depositFurnitureVault", invBankScene_GP, invBank_GP, "deposit", "InitializeLists",
			gamepadLibFiltersFurnitureVaultDepositFragment,
			nil, --See above at gamepadLibFiltersBankDepositFragment
			nil, --preShowCheckFunc
			nil, --preHideCheckFunc
			true)

	--Guild bank deposit
	gamepadLibFiltersGuildBankDepositFragment 					= ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersGuildBankDepositFragment._name 			= getCustomLibFiltersFragmentName(LF_GUILDBANK_DEPOSIT)
	_G[gamepadLibFiltersGuildBankDepositFragment._name]			= gamepadLibFiltersGuildBankDepositFragment
	--> Will be added/removed via hookFragmentStateByPostHookListInitFunction
	hookFragmentStateByPostHookListInitFunction("depositGuildBank", invGuildBankScene_GP, invGuildBank_GP, "deposit", "InitializeLists",
			gamepadLibFiltersGuildBankDepositFragment,
			nil,
			nil, --preShowCheckFunc
			nil, --preHideCheckFunc
			false)


	--Trading house = Guild store sell
	gamepadLibFiltersGuildStoreSellFragment 					= ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersGuildStoreSellFragment._name 				= getCustomLibFiltersFragmentName(LF_GUILDSTORE_SELL)
	_G[gamepadLibFiltersGuildStoreSellFragment._name]			= gamepadLibFiltersGuildStoreSellFragment
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
	--Hide/Show with GAMEPAD_MAIL_SEND_FRAGMENT -> via function SwitchToFragment
	--> 2025-11-01 This is too early! Will add our fragment as gamepad mail send panel shows but the inventory list is still hidden there!
	--[[
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
	]]

	SecurePostHook(invMailSend_GP.send, "PerformDeferredInitialization", function(self)
		--Update the reference table with the existing control now:
		libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_MAIL_SEND].control = gpc.invMailSend_GP.send.inventoryListControl

		--[[
		ZO_PreHook(invMailSend_GP.send.inventoryList, "Activate", function()
d("[LibFilters]Gamepad mail inv list - Activate")
			if not libFilters.isInitialized then return end
			--Needed to "early set" the filterType for the Gamepad mail send panel detection at filter function -> See helpers.lua, ZO_GamepadInventoryList:AddSlotDataToTable
			updateLastAndCurrentFilterType = updateLastAndCurrentFilterType or libFilters.UpdateLastAndCurrentFilterType
			detectShownReferenceNow = detectShownReferenceNow or libFilters.DetectShownReferenceNow
			local LF_FilterTypeMailSend = LF_MAIL_SEND
			local lReferencesToFilterTyp = detectShownReferenceNow(LF_FilterTypeMailSend, true, false, true) --Skip special checks, only control shown check needed e.g.
			updateLastAndCurrentFilterType(LF_FilterTypeMailSend, lReferencesToFilterTyp, nil, false)

			if not invMailSendScene_GP:HasFragment(gamepadLibFiltersMailSendFragment) then
				if libFilters.debug then dd("Gamepad Mail Send Inventory:Activate - Adding custom mail send fragment") end
				invMailSendScene_GP:AddFragment(gamepadLibFiltersMailSendFragment)
			end
		end)
		ZO_PostHook(invMailSend_GP.send.inventoryList, "Deactivate", function()
d("[LibFilters]Gamepad mail inv list - Deactivate")
			if not libFilters.isInitialized then return end

			if invMailSendScene_GP:HasFragment(gamepadLibFiltersMailSendFragment) then
				if libFilters.debug then dd("Gamepad Mail Send Inventory:Activate - Removing custom mail send fragment") end
				updateSceneManagerAndHideFragment(gamepadLibFiltersMailSendFragment)
				invMailSendScene_GP:RemoveFragment(gamepadLibFiltersMailSendFragment)
			end
		end)
		]]

		ZO_PreHookHandler(invMailSend_GP.send.inventoryListControl, "OnEffectivelyShown", function()
d("[LibFilters]Gamepad mail inv list - OnEffectivelyShown")
			if not libFilters.isInitialized then return end
			--Needed to "early set" the filterType for the Gamepad mail send panel detection at filter function -> See helpers.lua, ZO_GamepadInventoryList:AddSlotDataToTable
			updateLastAndCurrentFilterType = updateLastAndCurrentFilterType or libFilters.UpdateLastAndCurrentFilterType
			detectShownReferenceNow = detectShownReferenceNow or libFilters.DetectShownReferenceNow
			--[[
				local LF_FilterTypeMailSend = LF_MAIL_SEND
				local lReferencesToFilterTyp = detectShownReferenceNow(LF_FilterTypeMailSend, true, false, true) --Skip special checks, only control shown check needed e.g.
				updateLastAndCurrentFilterType(LF_FilterTypeMailSend, lReferencesToFilterTyp, nil, false)
				libFilters.preventCallbackUpdateLastVars = true --for function callbackRaiseCheck in LibFilters-3.0.lua -> Prevent resetting updateLastAndCurrentFilterType once
			]]
			if not invMailSendScene_GP:HasFragment(gamepadLibFiltersMailSendFragment) then
				if libFilters.debug then dd("Gamepad Mail Send Inventory:Activate - Adding custom mail send fragment") end
				invMailSendScene_GP:AddFragment(gamepadLibFiltersMailSendFragment)
			end
		end)
		ZO_PostHookHandler(invMailSend_GP.send.inventoryListControl, "OnEffectivelyHidden", function()
d("[LibFilters]Gamepad mail inv list - OnEffectivelyHidden")
			if not libFilters.isInitialized then return end

			if invMailSendScene_GP:HasFragment(gamepadLibFiltersMailSendFragment) then
				if libFilters.debug then dd("Gamepad Mail Send Inventory:Activate - Removing custom mail send fragment") end
				updateSceneManagerAndHideFragment(gamepadLibFiltersMailSendFragment)
				invMailSendScene_GP:RemoveFragment(gamepadLibFiltersMailSendFragment)
			end
		end)

	end)

	--Player to player trade
	gamepadLibFiltersPlayerTradeFragment 			= ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersPlayerTradeFragment._name 		= getCustomLibFiltersFragmentName(LF_TRADE)
	_G[gamepadLibFiltersPlayerTradeFragment._name] 	= gamepadLibFiltersPlayerTradeFragment
	gamepadLibFiltersPlayerTradeFragment:RegisterCallback("StateChange", function(oldState, newState)
		if libFilters.debug then dd("GAMEPAD CUSTOM player trade FRAGMENT - State: " ..tos(newState)) end
	end)
	--> Will be added to gamepad player trade scene below


	--Player inventory quest
	gamepadLibFiltersInventoryQuestFragment			= ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersInventoryQuestFragment._name 	= getCustomLibFiltersFragmentName(LF_INVENTORY_QUEST)
	_G[gamepadLibFiltersInventoryQuestFragment._name]= gamepadLibFiltersInventoryQuestFragment
	gamepadLibFiltersInventoryQuestFragment:RegisterCallback("StateChange", function(oldState, newState)
		if libFilters.debug then dd("GAMEPAD CUSTOM Inventory Quest FRAGMENT - State: " ..tos(newState)) end
	end)
	--> Will be added/removed via gamepadInventorySelectedCategoryChecks etc.


	--Player inventory
	gamepadLibFiltersInventoryFragment              = ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersInventoryFragment._name 		= getCustomLibFiltersFragmentName(LF_INVENTORY)
	_G[gamepadLibFiltersInventoryFragment._name]	= gamepadLibFiltersInventoryFragment
	gamepadLibFiltersInventoryFragment:RegisterCallback("StateChange", function(oldState, newState)
		if libFilters.debug then dd("GAMEPAD CUSTOM Inventory FRAGMENT - State: " ..tos(newState)) end
	end)
	--> Will be added/removed via gamepadInventorySelectedCategoryChecks etc.


	--Cyrodiil Vengeance inventory
	gamepadLibFiltersInventoryVengeanceFragment     = ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
	gamepadLibFiltersInventoryVengeanceFragment._name 		= getCustomLibFiltersFragmentName(LF_INVENTORY_VENGEANCE)
	_G[gamepadLibFiltersInventoryVengeanceFragment._name]	= gamepadLibFiltersInventoryVengeanceFragment

	gamepadLibFiltersInventoryVengeanceFragment:RegisterCallback("StateChange", function(oldState, newState)
		if libFilters.debug then dd("GAMEPAD CUSTOM Cyrodiil Vengeance Inventory FRAGMENT - State: " ..tos(newState)) end
	end)
	--> Will be added/removed via gamepadInventorySelectedCategoryChecks etc.

	--Quickslots -> Updating custom inventory fragment's shown state
	-->Should not be needed anymore due to gamepadLibFiltersInventoryFragment -> gamepadInventorySelectedCategoryChecks etc.



	------------------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------
	--2) Add conditions to check if a fragment should be shown or not
	------------------------------------------------------------------------------------------------------------------------
	--Inventory
	gamepadLibFiltersInventoryFragment:SetConditional(function()
		local retVar = checkIfInvAndNotVengeanceCampaign()
		if libFilters.debug then
			dd("GAMEPAD CUSTOM inventory FRAGMENT - Condition: " ..tos(retVar))
		end
		return retVar
	end)

	--Inventory quest
	gamepadLibFiltersInventoryQuestFragment:SetConditional(function()
		local retVar = checkIfInvAndNotVengeanceCampaign() and invBackpack_GP.selectedItemFilterType == ITEMFILTERTYPE_QUEST
		if libFilters.debug then
			dd("GAMEPAD CUSTOM inventory quest FRAGMENT - Condition: " ..tos(retVar))
		end
		return retVar
	end)

	--Inventory vengeance (Cyrodiil)
	gamepadLibFiltersInventoryVengeanceFragment:SetConditional(function()
		local retVar = gpInvNoCraftBagShowing() and isVengeanceCampaign()
		if libFilters.debug then
			dd("GAMEPAD CUSTOM inventory vengeance FRAGMENT - Condition: " ..tos(retVar))
		end
		return retVar
	end)

	--Bank deposit
	gamepadLibFiltersBankDepositFragment:SetConditional(function()
		local retVar = isGamepadBankDepositShowing() and playerBankBagIds[GetBankingBag()]
		if libFilters.debug then
			dd("GAMEPAD CUSTOM bank deposit FRAGMENT - Condition: " ..tos(retVar))
		end
		return retVar
	end)

	--House Bank deposit
	gamepadLibFiltersHouseBankDepositFragment:SetConditional(function()
		local retVar = isGamepadBankDepositShowing() and IsHouseBankBag(GetBankingBag()) and not isFurnitureVaultShowing()
		if libFilters.debug then
			dd("GAMEPAD CUSTOM house bank deposit FRAGMENT - Condition: " ..tos(retVar))
		end
		return retVar
	end)

	--Furniture vault (bank) deposit
	gamepadLibFiltersFurnitureVaultDepositFragment:SetConditional(function()
		local retVar = isGamepadBankDepositShowing() and isFurnitureVaultShowing()
		if libFilters.debug then
			dd("GAMEPAD CUSTOM furniture vault deposit FRAGMENT - Condition: " ..tos(retVar))
		end
		return retVar
	end)

	--Guild bank deposit
	gamepadLibFiltersGuildBankDepositFragment:SetConditional(function()
		local retVar = invGuildBankScene_GP:IsShowing() and invGuildBank_GP:IsInDepositMode()
		if libFilters.debug then
			dd("GAMEPAD CUSTOM guild bank deposit FRAGMENT - Condition: " ..tos(retVar))
		end
		return retVar
	end)



	------------------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------
	-- 3) Gamepad Scenes: Add new custom fragments to the scenes so they show and hide with the vanilla scenes properly
	------------------------------------------------------------------------------------------------------------------------
	--Information only:
	--gamepadLibFiltersInventoryFragment 		--will be added/removed dynamically via functions invBackpack_GP.categoryList:SetOnSelectedDataChangedCallback and invBackpack_GP:SetCurrentList, and hookFragmentStateByPostHookListInitFunction above
	--gamepadLibFiltersGuildBankDepositFragment --will be added/removed dynamically via function hookFragmentStateByPostHookListInitFunction above
	--gamepadLibFiltersGuildStoreSellFragment 	--will be added/removed dynamically via function GAMEPAD_TRADING_HOUSE:SetCurrentMode() above
	--gamepadLibFiltersMailSendFragment 		--will be added/removed dynamically via function mailManagerGamepadScene:SwitchToFragment() above

	--Actually adding fragments to gamepad scenes:
	invPlayerTradeScene_GP:AddFragment(gamepadLibFiltersPlayerTradeFragment)








	--==================================================================================================================
	--==================================================================================================================
	--==================================================================================================================
	------------------------------------------------------------------------------------------------------------------------
	-- 4) Add the created fragments to the LibFilters gamepad fragment constants so they are not nil anymore (they get Deferred initialized and are nil until first opened!)
	--  in LibFilters-3.0.lua later on.
	--  See constants.lua -> table gamepadConstants.customFragments with the pre-defined placeholders
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
	customFragmentsUpdateRef[LF_FURNITURE_VAULT_DEPOSIT].fragment      				= 	gamepadLibFiltersFurnitureVaultDepositFragment
	customFragmentsUpdateRef[LF_INVENTORY_VENGEANCE].fragment          				= 	gamepadLibFiltersInventoryVengeanceFragment

	--Update the table libFilters.LF_FilterTypeToReference for the gamepad mode fragments
	-->THIS TABLE IS USED TO GET THE FRAGMENT's REFERENCE OF GAMEPAD filterTypes WITHIN LibFilters-3.0.lua, function ApplyAdditionalFilterHooks()!
	---> At this reference variable the subtable layoutData and in it the .additionalFilter function will be searched later
	LF_FilterTypeToReference[true][LF_INVENTORY]          							= 	{ gamepadLibFiltersInventoryFragment }
	LF_FilterTypeToReference[true][LF_BANK_DEPOSIT]       							= 	{ gamepadLibFiltersBankDepositFragment }
	LF_FilterTypeToReference[true][LF_GUILDBANK_DEPOSIT]  							= 	{ gamepadLibFiltersGuildBankDepositFragment }
	LF_FilterTypeToReference[true][LF_HOUSE_BANK_DEPOSIT] 							= 	{ gamepadLibFiltersHouseBankDepositFragment }
	LF_FilterTypeToReference[true][LF_GUILDSTORE_SELL]                            	= 	{ gamepadLibFiltersGuildStoreSellFragment }
	LF_FilterTypeToReference[true][LF_MAIL_SEND]                                  	= 	{ gamepadLibFiltersMailSendFragment }
	LF_FilterTypeToReference[true][LF_TRADE]                                      	= 	{ gamepadLibFiltersPlayerTradeFragment }
	LF_FilterTypeToReference[true][LF_INVENTORY_QUEST] 								=   { gamepadLibFiltersInventoryQuestFragment }
	LF_FilterTypeToReference[true][LF_FURNITURE_VAULT_DEPOSIT]      				= 	{ gamepadLibFiltersFurnitureVaultDepositFragment }
	LF_FilterTypeToReference[true][LF_INVENTORY_VENGEANCE]          				= 	{ gamepadLibFiltersInventoryVengeanceFragment }


	-->Update the references to the fragments so one is able to use them within the "isShown" routines
	--LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_INVENTORY]["fragment"] 		= 	gamepadLibFiltersInventoryFragment --uses GAMEPAD_INVENTORY_FRAGMENT now for detection as this' shown state get's updated properly after quickslot wheel was closed again
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_BANK_DEPOSIT]["fragment"] 		=	gamepadLibFiltersBankDepositFragment
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_GUILDBANK_DEPOSIT]["fragment"] = 	gamepadLibFiltersGuildBankDepositFragment
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_HOUSE_BANK_DEPOSIT]["fragment"]= 	gamepadLibFiltersHouseBankDepositFragment
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_GUILDSTORE_SELL]["fragment"] 	= 	gamepadLibFiltersGuildStoreSellFragment
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_MAIL_SEND]["fragment"]       	= 	gamepadLibFiltersMailSendFragment
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_TRADE]["fragment"]           	= 	gamepadLibFiltersPlayerTradeFragment
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_INVENTORY_QUEST]["fragment"]	=   gamepadLibFiltersInventoryQuestFragment
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_FURNITURE_VAULT_DEPOSIT]["fragment"] =	gamepadLibFiltersFurnitureVaultDepositFragment
	LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_INVENTORY_VENGEANCE]["fragment"] =	gamepadLibFiltersInventoryVengeanceFragment

	-->Update the new created custom fragments to the callback-by-fragment-StateChange lookup table
	callbacksUsingFragments[true][gamepadLibFiltersInventoryFragment] 				= { LF_INVENTORY }
	callbacksUsingFragments[true][gamepadLibFiltersBankDepositFragment] 			= { LF_BANK_DEPOSIT }
	callbacksUsingFragments[true][gamepadLibFiltersGuildBankDepositFragment] 		= { LF_GUILDBANK_DEPOSIT }
	callbacksUsingFragments[true][gamepadLibFiltersHouseBankDepositFragment] 		= { LF_HOUSE_BANK_DEPOSIT }
	callbacksUsingFragments[true][gamepadLibFiltersGuildStoreSellFragment] 			= { LF_GUILDSTORE_SELL }
	callbacksUsingFragments[true][gamepadLibFiltersMailSendFragment] 				= { LF_MAIL_SEND }
	callbacksUsingFragments[true][gamepadLibFiltersPlayerTradeFragment] 			= { LF_TRADE }
	callbacksUsingFragments[true][gamepadLibFiltersInventoryQuestFragment] 			= { LF_INVENTORY_QUEST }
	callbacksUsingFragments[true][gamepadLibFiltersFurnitureVaultDepositFragment] 	= { LF_FURNITURE_VAULT_DEPOSIT }
	callbacksUsingFragments[true][gamepadLibFiltersInventoryVengeanceFragment] 		= { LF_INVENTORY_VENGEANCE }

	--Update the callback invoker fragments
	filterTypeToCallbackRef[true][LF_INVENTORY] = 			{ ref = gamepadLibFiltersInventoryFragment, 		refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_BANK_DEPOSIT] = 		{ ref = gamepadLibFiltersBankDepositFragment, 		refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_GUILDBANK_DEPOSIT] = 	{ ref = gamepadLibFiltersGuildBankDepositFragment, 	refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_HOUSE_BANK_DEPOSIT] = 	{ ref = gamepadLibFiltersHouseBankDepositFragment, 	refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_GUILDSTORE_SELL] = 	{ ref = gamepadLibFiltersGuildStoreSellFragment, 	refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_MAIL_SEND] = 			{ ref = gamepadLibFiltersMailSendFragment, 			refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_TRADE] = 				{ ref = gamepadLibFiltersPlayerTradeFragment, 		refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_INVENTORY_QUEST] = 	{ ref = gamepadLibFiltersInventoryQuestFragment,	refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_FURNITURE_VAULT_DEPOSIT] =	{ ref = gamepadLibFiltersFurnitureVaultDepositFragment,	refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }
	filterTypeToCallbackRef[true][LF_INVENTORY_VENGEANCE] = { ref = gamepadLibFiltersInventoryVengeanceFragment, refType = LIBFILTERS_CON_TYPEOFREF_FRAGMENT }


	--Update the custom Gamepad fragments to the LibFilters.fragments[true] table
	gpFragments.CustomBankDepositFragment = 			gamepadLibFiltersBankDepositFragment
	gpFragments.CustomHouseBankDepositFragment = 		gamepadLibFiltersHouseBankDepositFragment
	gpFragments.CustomFurnitureVaultDepositFragment = 	gamepadLibFiltersFurnitureVaultDepositFragment
	gpFragments.CustomGuildBankDepositFragment = 		gamepadLibFiltersGuildBankDepositFragment
	gpFragments.CustomGuildStoreSellFragment = 			gamepadLibFiltersGuildStoreSellFragment
	gpFragments.CustomMaiLSendFragment = 				gamepadLibFiltersMailSendFragment
	gpFragments.CustomPlayerTradeFragment = 			gamepadLibFiltersPlayerTradeFragment
	gpFragments.CustomInventoryQuestFragment = 			gamepadLibFiltersInventoryQuestFragment
	gpFragments.CustomInventoryVengeanceFragment = 		gamepadLibFiltersInventoryVengeanceFragment

	------------------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------
	if libFilters.debug then dd(">Custom GAMEPAD fragments were created") end
end
libFilters.CreateCustomGamepadFragmentsAndNeededHooks = createCustomGamepadFragmentsAndNeededHooks


--Used for helper functions to determine if a custom GP fragment exists and if that stores the .additionalFilter functions in it
function libFilters.IsFilterTypeUsingCustomGamepadFragment(filterType)
	if filterType == nil then return false, nil end
	local customFragmentsGPData = customFragments_GP[filterType]
	if customFragmentsGPData ~= nil and customFragmentsGPData.fragment ~= nil then
		return true, customFragmentsGPData.fragment
	end
	return false, nil
end

function libFilters.GetCustomGamepadFragmentOfFilterType(filterType)
	if filterType == nil then return false, nil end
	local customFragmentsGPData = customFragments_GP[filterType]
	if customFragmentsGPData ~= nil and customFragmentsGPData.fragment ~= nil then
		return customFragmentsGPData.fragment
	end
	return nil
end

if libFilters.debug then dd("LIBRARY GAMEPAD CUSTOM FRAGMENTS FILE - END") end
