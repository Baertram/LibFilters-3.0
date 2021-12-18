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
local LF_FilterTypeToReference =				mapping.LF_FilterTypeToReference
local LF_FilterTypeToCheckIfReferenceIsHidden = mapping.LF_FilterTypeToCheckIfReferenceIsHidden

--Keyboard
local kbc             = 						constants.keyboard
local playerInventory = 						kbc.playerInv

--Gamepad
local gpc                         	= 			constants.gamepad
local invRootScene                	= 			gpc.invRootScene
local invBank_GP                  	= 			gpc.invBank_GP
local invBankScene_GP      			=			gpc.invBankScene_GP
local invGuildBankScene_GP 			= 			gpc.invGuildBankScene_GP
local invGuildBank_GP      			=			gpc.invGuildBank_GP
local invGuildStore_GP				= 			gpc.invGuildStore_GP
local invGuildStoreSellScene_GP   	= 			gpc.invGuildStoreSellScene_GP
local invGuildStoreSell_GP 			= 			gpc.invGuildStoreSell_GP
local invMailSendScene_GP         	= 			gpc.invMailSendScene_GP
local invPlayerTradeScene_GP      	= 			gpc.invPlayerTradeScene_GP

local customFragments_GP          	= 			gpc.customFragments
local fragmentPrefix              	= 			gpc.customFragmentPrefix

--The local variables for the new created custom LibFilters gamepad fragments
local gamepadLibFiltersInventoryDepositFragment
local gamepadLibFiltersBankDepositFragment
local gamepadLibFiltersGuildBankDepositFragment
local gamepadLibFiltersHouseBankDepositFragment
local gamepadLibFiltersGuildStoreSellFragment
local gamepadLibFiltersMailSendFragment
local gamepadLibFiltersPlayerTradeFragment


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
	if libFilters.debug then dd("[LibFilters3] Fragment state change "..tos(fragmentTarget).." - State: " ..tos(newState)) end
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

local fragmentsHooked = {}
--[[
local hookedControlsHiddenState = {}
local function hookControlHiddenAndShownAndChangeFragmentState(ctrlToHook, sceneChanged, sourceFragment, targetFragment)
	sceneChanged:RegisterCallback("StateChange", function(oldState, newState)
		if libFilters.debug then dd("[LibFilters3]"..tos(sceneChanged:GetName()).." - State: " ..tos(newState)) end
		if not hookedControlsHiddenState[ctrlToHook] then
			fragmentChange(oldState, newState, sourceFragment, targetFragment,
					function(p_srcFragment, p_targetFragment)
						p_targetFragment:Hide() --Hide target fragment on first view as the scene has shown it
						if not hookedControlsHiddenState[ctrlToHook] then
							if ctrlToHook ~= nil then
								ctrlToHook:SetHandler("OnEffectivelyShown", function()
									if libFilters.debug then dd("[LibFilters3]" ..ctrlToHook:GetName() .. "): shown") end
									p_targetFragment:Show()
								end)
								ctrlToHook:SetHandler("OnHide", function()
									if libFilters.debug then dd("[LibFilters3]" ..ctrlToHook:GetName() .. "): hidden") end
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
									if libFilters.debug then dd("[LibFilters3]" ..ctrlToHook:GetName() .. "): shown") end
									p_targetFragment:Show()
								end)
								ctrlToHook:SetHandler("OnHide", function()
									if libFilters.debug then dd("[LibFilters3]" ..ctrlToHook:GetName() .. "): hidden") end
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

local function hookListFragmentsState(hookName, sceneId, objectId, listName, targetFragment, checkFunc, addAndRemoveFragment)
	addAndRemoveFragment = addAndRemoveFragment or false
	if not fragmentsHooked[hookName] then
		if checkFunc ~= nil and checkFunc() ~= true then return end

		if sceneId:IsShowing() then
			if listName == "deposit" then
				if objectId:IsInDepositMode() then
					targetFragment:Show()
				else
					targetFragment:Hide()
				end
			elseif listName == "withdraw" then
				if objectId:IsInWithdrawMode() then
					targetFragment:Show()
				else
					targetFragment:Hide()
				end
			end
		else
			targetFragment:Hide()
		end

		local listFragment
		if objectId.GetListFragment ~= nil then
			listFragment = objectId:GetListFragment(listName)
		elseif objectId.GetFragment ~= nil then
			listFragment = objectId:GetFragment()
		end
		if libFilters.debug then dd("[LibFilters3]GAMEPAD " .. tos(hookName) .. " - Fragment exist: " ..tostring(listFragment ~= nil)) end
		if listFragment == nil then return end
		listFragment:RegisterCallback("StateChange", function(oldState, newState)
			if libFilters.debug then dd("[LibFilters3]GAMEPAD " .. tos(hookName) .." list FRAGMENT - State: " ..tos(newState)) end
			fragmentChange(oldState, newState, nil, targetFragment,
					function(p_sourceFragment, p_targetFragment) return end, --showing
					function(p_sourceFragment, p_targetFragment)
						if checkFunc ~= nil and checkFunc() ~= true then return end
						if addAndRemoveFragment == true then
							sceneId:AddFragment(p_targetFragment)
						end
						p_targetFragment:Show()
						return
					end, --shown
					function(p_sourceFragment, p_targetFragment) return end, --hiding
					function(p_sourceFragment, p_targetFragment)
						if checkFunc ~= nil and checkFunc() ~= true then return end
						if addAndRemoveFragment == true then
							if sceneId:Hasfragment(p_targetFragment) then
								sceneId:RemoveFragment(p_targetFragment)
							end
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
		if libFilters.debug then dd("[LibFilters3]GAMEPAD fragment - post hook %q - %s, %s", tos(sceneId:GetName()), tos(hookName), tos(listFunctionName)) end
		if checkFunc == nil or (checkFunc ~= nil and checkFunc() == true) then
			hookListFragmentsState(hookName, sceneId, objectId, listName, targetFragment, checkFunc, addAndRemoveFragment)
		end
	end)
end

------------------------------------------------------------------------------------------------------------------------
-- Custom added Gamepad inventory type fragment's sub-class
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
	self:ApplyInventoryLayout(gamepadLibFiltersInventoryDepositFragment.layoutData)
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
-- Custom added Gamepad inventory type fragments -> Create the fragments now
------------------------------------------------------------------------------------------------------------------------
local gamepadLibFiltersDefaultFragment = LibFilters_InventoryLayoutFragment:New(
		{
			additionalFilter = function(slot) return true end
		})


--Player bank deposit
gamepadLibFiltersBankDepositFragment = ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
_G[getCustomLibFiltersFragmentName(LF_BANK_DEPOSIT)] = gamepadLibFiltersBankDepositFragment
hookFragmentStateByPostHookListInitFunction("depositBank", invBankScene_GP, invBank_GP, "deposit", "InitializeLists", gamepadLibFiltersBankDepositFragment,
		function() return GetBankingBag() == BAG_BANK end, true)


--House bank deposit
gamepadLibFiltersHouseBankDepositFragment = ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
_G[getCustomLibFiltersFragmentName(LF_HOUSE_BANK_DEPOSIT)]  = gamepadLibFiltersHouseBankDepositFragment
hookFragmentStateByPostHookListInitFunction("depositHouseBank", invBankScene_GP, invBank_GP, "deposit", "InitializeLists", gamepadLibFiltersHouseBankDepositFragment,
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
gamepadLibFiltersGuildBankDepositFragment = ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
_G[getCustomLibFiltersFragmentName(LF_GUILDBANK_DEPOSIT)]  = gamepadLibFiltersGuildBankDepositFragment
hookFragmentStateByPostHookListInitFunction("depositGuildBank", invGuildBankScene_GP, invGuildBank_GP, "deposit", "InitializeLists", gamepadLibFiltersGuildBankDepositFragment, nil)


--Trading house = Guild store sell
gamepadLibFiltersGuildStoreSellFragment = ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
_G[getCustomLibFiltersFragmentName(LF_GUILDSTORE_SELL)]	= gamepadLibFiltersGuildStoreSellFragment


--The GAMEPAD_TRADING_HOUSE_SELL variable is not given until gamepad mode is enabled and the trading house sell panel is opened...
--So we will use TRADING_HOUSE_GAMEPAD instead, function SetCurrentListObject(GAMEPAD_TRADING_HOUSE_SELL)
ZO_PreHook(invGuildStore_GP, "SetCurrentMode", function(self, tradingMode)
	if libFilters.debug then dd("[LibFilters3]GAMEPAD_TRADING_HOUSE - SetCurrentMode: " ..tos(tradingMode)) end
	if tradingMode == ZO_TRADING_HOUSE_MODE_SELL then
		invGuildStoreSellScene_GP:AddFragment(gamepadLibFiltersGuildStoreSellFragment)
		gamepadLibFiltersGuildStoreSellFragment:Show()
	else
		if not gamepadLibFiltersGuildStoreSellFragment.sceneManager then gamepadLibFiltersGuildStoreSellFragment:SetSceneManager(SM) end
		if not gamepadLibFiltersGuildStoreSellFragment:IsHidden() then gamepadLibFiltersGuildStoreSellFragment:Hide() end
		if invGuildStoreSellScene_GP:HasFragment(gamepadLibFiltersGuildStoreSellFragment) then
			invGuildStoreSellScene_GP:RemoveFragment(gamepadLibFiltersGuildStoreSellFragment)
		end
	end
end)
SecurePostHook("ZO_TradingHouse_Browse_Gamepad_OnInitialize", function()
	--Update trading house browse
	if not fragmentsHooked["GAMEPAD_TRADING_HOUSE_BROWSE"] and GAMEPAD_TRADING_HOUSE_BROWSE ~= nil then
		local tradingHouseBrowse_GP = GAMEPAD_TRADING_HOUSE_BROWSE
		libFilters.constants.gamepad.tradingHouseBrowse_GP = tradingHouseBrowse_GP
		libFilters.mapping.LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_GUILDSTORE_BROWSE] = {
			["control"] = tradingHouseBrowse_GP, ["scene"] = gpc.invGuildStoreSellScene_GP,	["fragment"] =  tradingHouseBrowse_GP.fragment,
		}
		fragmentsHooked["GAMEPAD_TRADING_HOUSE_BROWSE"] = true
	end
end)


--Mail send
gamepadLibFiltersMailSendFragment = ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
_G[getCustomLibFiltersFragmentName(LF_MAIL_SEND)]		= gamepadLibFiltersMailSendFragment
--[[
--Hide/Show with GAMEPAD_MAIL_SEND_FRAGMENT
GAMEPAD_MAIL_SEND_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
	if libFilters.debug then dd("[LibFilters3]GAMEPAD_MAIL_SEND_FRAGMENT - State: " ..tos(newState)) end
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
SecurePostHook(invMailSendScene_GP, 'SwitchToFragment', function(self, fragment)
    if fragment == gpc.invMailSendFragment then
        invMailSendScene_GP:AddFragment(gamepadLibFiltersMailSendFragment)
    else
		if not gamepadLibFiltersMailSendFragment.sceneManager then gamepadLibFiltersMailSendFragment:SetSceneManager(SM) end
		if not gamepadLibFiltersMailSendFragment:IsHidden() then gamepadLibFiltersMailSendFragment:Hide() end
		if invMailSendScene_GP:HasFragment(gamepadLibFiltersMailSendFragment) then
			invMailSendScene_GP:RemoveFragment(gamepadLibFiltersMailSendFragment)
		end
    end
end)


--Player to player trade
gamepadLibFiltersPlayerTradeFragment = ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
_G[getCustomLibFiltersFragmentName(LF_TRADE)] = gamepadLibFiltersPlayerTradeFragment


--Player inventory
gamepadLibFiltersInventoryDepositFragment = ZO_DeepTableCopy(gamepadLibFiltersDefaultFragment)
_G[getCustomLibFiltersFragmentName(LF_INVENTORY)] = gamepadLibFiltersInventoryDepositFragment


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


------------------------------------------------------------------------------------------------------------------------
-- Add the created fragments to the LibFilters gamepad fragment constants so they are not nil anymore in
-- LibFilters-3.0.lua later on.
-- See constants.lua -> table gamepadConstants.customFragments with the pre-defined placeholders
--> [LF_*] = {name="...", fragment=nil},
------------------------------------------------------------------------------------------------------------------------
local customFragmentsUpdateRef                           						= 	libFilters.constants.gamepad.customFragments
customFragmentsUpdateRef[LF_INVENTORY].fragment          						= 	gamepadLibFiltersInventoryDepositFragment
customFragmentsUpdateRef[LF_BANK_DEPOSIT].fragment      						= 	gamepadLibFiltersBankDepositFragment
customFragmentsUpdateRef[LF_GUILDBANK_DEPOSIT].fragment 						= 	gamepadLibFiltersGuildBankDepositFragment
customFragmentsUpdateRef[LF_HOUSE_BANK_DEPOSIT].fragment 						= 	gamepadLibFiltersHouseBankDepositFragment
customFragmentsUpdateRef[LF_GUILDSTORE_SELL].fragment               			= 	gamepadLibFiltersGuildStoreSellFragment
customFragmentsUpdateRef[LF_MAIL_SEND].fragment                     			= 	gamepadLibFiltersMailSendFragment
customFragmentsUpdateRef[LF_TRADE].fragment                         			= 	gamepadLibFiltersPlayerTradeFragment

--Update the table libFilters.LF_FilterTypeToReference for the gamepad mode fragments
-->THIS TABLE IS USED TO GET THE FRAGMENT's REFERENCE OF GAMEPAD filterTypes WITHIN LibFilters-3.0.lua, function ApplyAdditionalFilterHooks()!
LF_FilterTypeToReference[true][LF_INVENTORY]          							= 	{ gamepadLibFiltersInventoryDepositFragment }
LF_FilterTypeToReference[true][LF_BANK_DEPOSIT]       							= 	{ gamepadLibFiltersBankDepositFragment }
LF_FilterTypeToReference[true][LF_GUILDBANK_DEPOSIT]  							= 	{ gamepadLibFiltersGuildBankDepositFragment }
LF_FilterTypeToReference[true][LF_HOUSE_BANK_DEPOSIT] 							= 	{ gamepadLibFiltersHouseBankDepositFragment }
LF_FilterTypeToReference[true][LF_GUILDSTORE_SELL]                            	= 	{ gamepadLibFiltersGuildStoreSellFragment }
LF_FilterTypeToReference[true][LF_MAIL_SEND]                                  	= 	{ gamepadLibFiltersMailSendFragment }
LF_FilterTypeToReference[true][LF_TRADE]                                      	= 	{ gamepadLibFiltersPlayerTradeFragment }

-->Update the references to the fragments so one is able to use them within the "isShown" routines
LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_INVENTORY]["fragment"] 		=	gamepadLibFiltersInventoryDepositFragment
LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_BANK_DEPOSIT]["fragment"] 		=	gamepadLibFiltersBankDepositFragment
LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_GUILDBANK_DEPOSIT]["fragment"] = 	gamepadLibFiltersGuildBankDepositFragment
LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_HOUSE_BANK_DEPOSIT]["fragment"]= 	gamepadLibFiltersHouseBankDepositFragment
LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_GUILDSTORE_SELL]["fragment"] 	= 	gamepadLibFiltersGuildStoreSellFragment
LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_MAIL_SEND]["fragment"]       	= 	gamepadLibFiltersMailSendFragment
LF_FilterTypeToCheckIfReferenceIsHidden[true][LF_TRADE]["fragment"]           	= 	gamepadLibFiltersPlayerTradeFragment


------------------------------------------------------------------------------------------------------------------------
-- Gamepad Scenes: Add new custom fragments to the scenes so they show and hide properly
------------------------------------------------------------------------------------------------------------------------
--Gamepd player inventory
invRootScene:AddFragment(gamepadLibFiltersInventoryDepositFragment)

invGuildBankScene_GP:AddFragment(gamepadLibFiltersGuildBankDepositFragment)

invGuildStoreSellScene_GP:AddFragment(gamepadLibFiltersGuildStoreSellFragment) --will be added/removed dynamically via function GAMEPAD_TRADING_HOUSE:SetCurrentMode() above

--invMailSendScene_GP:AddFragment(gamepadLibFiltersMailSendFragment) --will be added/removed dynamically via function mailManagerGamepadScene:SwitchToFragment() above

invPlayerTradeScene_GP:AddFragment(gamepadLibFiltersPlayerTradeFragment)


if libFilters.debug then dd("LIBRARY GAMEPAD CUSTOM FRAGMENTS FILE - END") end
