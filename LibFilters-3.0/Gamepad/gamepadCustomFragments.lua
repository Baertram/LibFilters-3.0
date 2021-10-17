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


------------------------------------------------------------------------------------------------------------------------
-- Local library variables
------------------------------------------------------------------------------------------------------------------------
local libFilters = LibFilters3

--LibFilters local speedup and reference variables
--Overall constants
local constants = 					libFilters.constants
local inventoryTypes = 				constants.inventoryTypes
local playerInventoryType = 		inventoryTypes["player"] -- INVENTORY_BACKPACK
local mapping = 					libFilters.mapping
local LF_ConstantToAdditionalFilterControlSceneFragmentUserdata = mapping.LF_ConstantToAdditionalFilterControlSceneFragmentUserdata

--Keyboard
local keyboardConstants = 			constants.keyboard
local palyerInventory = 			keyboardConstants.playerInv

--Gamepad
local gamepadConstants = 			constants.gamepad
local invRootScene = 				gamepadConstants.invRootScene
local invBackpack_GP = 				gamepadConstants.invBackpack_GP
local invBank_GP = 					gamepadConstants.invBank_GP
local invGuildStoreSellScene_GP = 	gamepadConstants.invGuildStoreSellScene_GP
local invGuildBankDepositScene_GP = gamepadConstants.invGuildBankDepositScene_GP
local invMailSendScene_GP = 		gamepadConstants.invMailSendScene_GP
local invPlayerTradeScene_GP = 		gamepadConstants.invPlayerTradeScene_GP

local customFragments_GP = 			gamepadConstants.customFragments
local fragmentPrefix = 				gamepadConstants.customFragmentPrefix


--The local fragment variables
local gamepadLibFiltersInventoryDepositFragment
local gamepadLibFiltersBankDepositFragment
local gamepadLibFiltersGuildBankDepositFragment
local gamepadLibFiltersHouseBankDepositFragment
local gamepadLibFiltersGuildStoreSellFragment
local gamepadLibFiltersMaiLSendFragment
local gamepadLibFiltersPlayerTradeFragment


------------------------------------------------------------------------------------------------------------------------
-- Local helper functions
------------------------------------------------------------------------------------------------------------------------
--Add the fragment prefix and return the fragment
local function getCustomLibFiltersFragmentName(libFiltersFilterType)
	local fragmentName = customFragments_GP[libFiltersFilterType].name
	return fragmentPrefix .. fragmentName
end
libFilters.GetCustomLibFiltersFragmentName = getCustomLibFiltersFragmentName


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
	if invBackpack_GP.layoutData then
	end
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
	palyerInventory.appliedLayout = layoutData
	palyerInventory.inventories[playerInventoryType].additionalFilter = layoutData.additionalFilter
end


------------------------------------------------------------------------------------------------------------------------
-- Custom added Gamepad inventory type fragments -> Create the fragments now
------------------------------------------------------------------------------------------------------------------------
--Player bank deposit
gamepadLibFiltersBankDepositFragment = LibFilters_InventoryLayoutFragment:New(
	{
		additionalFilter = function(slot) return true end
	})
_G[getCustomLibFiltersFragmentName(LF_BANK_DEPOSIT)] = gamepadLibFiltersBankDepositFragment

--House bank deposit
gamepadLibFiltersHouseBankDepositFragment = ZO_DeepTableCopy(gamepadLibFiltersBankDepositFragment)
_G[getCustomLibFiltersFragmentName(LF_HOUSE_BANK_DEPOSIT)]  = gamepadLibFiltersHouseBankDepositFragment

--Guild bank deposit
gamepadLibFiltersGuildBankDepositFragment = ZO_DeepTableCopy(gamepadLibFiltersBankDepositFragment)
_G[getCustomLibFiltersFragmentName(LF_GUILDBANK_DEPOSIT)]  = gamepadLibFiltersGuildBankDepositFragment

--Trading house = Guild store deposit
gamepadLibFiltersGuildStoreSellFragment = ZO_DeepTableCopy(gamepadLibFiltersBankDepositFragment)
_G[getCustomLibFiltersFragmentName(LF_GUILDSTORE_SELL)]	= gamepadLibFiltersGuildStoreSellFragment

--Mail send
gamepadLibFiltersMaiLSendFragment = ZO_DeepTableCopy(gamepadLibFiltersBankDepositFragment)
_G[getCustomLibFiltersFragmentName(LF_MAIL_SEND)]			= gamepadLibFiltersMaiLSendFragment

--Player to player trade
--[[
gamepadLibFiltersPlayerTradeFragment = LibFilters_InventoryLayoutFragment:New(
	{
		additionalFilter = function(slot) return true end,
		alwaysReapplyLayout = true
	})
	]]
gamepadLibFiltersPlayerTradeFragment = ZO_DeepTableCopy(gamepadLibFiltersBankDepositFragment)
_G[getCustomLibFiltersFragmentName(LF_TRADE)] = gamepadLibFiltersPlayerTradeFragment

--Player inventory
gamepadLibFiltersInventoryDepositFragment = ZO_DeepTableCopy(gamepadLibFiltersPlayerTradeFragment)
_G[getCustomLibFiltersFragmentName(LF_INVENTORY)] = gamepadLibFiltersInventoryDepositFragment


------------------------------------------------------------------------------------------------------------------------
-- Add the created fragments to the LibFilters gamepad fragment constants so they are not nil anymore in
-- LibFilters-3.0.lua. See constants.lua -> table gamepadConstants.customFragments with the pre-defined placeholders
------------------------------------------------------------------------------------------------------------------------
local customFragmentsUpdateRef                           = libFilters.constants.gamepad.customFragments
customFragmentsUpdateRef[LF_INVENTORY].fragment          = gamepadLibFiltersInventoryDepositFragment
customFragmentsUpdateRef[LF_BANK_DEPOSIT].fragment       = gamepadLibFiltersBankDepositFragment
customFragmentsUpdateRef[LF_GUILDBANK_DEPOSIT].fragment = gamepadLibFiltersGuildBankDepositFragment
customFragmentsUpdateRef[LF_HOUSE_BANK_DEPOSIT].fragment = gamepadLibFiltersHouseBankDepositFragment
customFragmentsUpdateRef[LF_GUILDSTORE_SELL].fragment   = gamepadLibFiltersGuildStoreSellFragment
customFragmentsUpdateRef[LF_MAIL_SEND].fragment          = gamepadLibFiltersMaiLSendFragment
customFragmentsUpdateRef[LF_TRADE].fragment              = gamepadLibFiltersPlayerTradeFragment
--Update the table libFilters.LF_ConstantToAdditionalFilterControlSceneFragmentUserdata for the gamepad mode fragments
-->THIS TABLE IS USED TO GET THE FRAGMENT's REFERENCE WITHIN LibFilters-3.0.lua, function ApplyAdditionalFilterHooks()!
LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[true][LF_INVENTORY] 			= { gamepadLibFiltersInventoryDepositFragment }
LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[true][LF_BANK_DEPOSIT] 		= { gamepadLibFiltersBankDepositFragment }
LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[true][LF_GUILDBANK_DEPOSIT] 	= { gamepadLibFiltersGuildBankDepositFragment }
LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[true][LF_HOUSE_BANK_DEPOSIT] 	= { gamepadLibFiltersHouseBankDepositFragment }
LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[true][LF_GUILDSTORE_SELL] 	= { gamepadLibFiltersGuildStoreSellFragment }
LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[true][LF_MAIL_SEND] 			= { gamepadLibFiltersMaiLSendFragment }
LF_ConstantToAdditionalFilterControlSceneFragmentUserdata[true][LF_TRADE] 				= { gamepadLibFiltersPlayerTradeFragment }



------------------------------------------------------------------------------------------------------------------------
-- Gamepad Scenes: Add new custom fragments to the scenes so they show and hide properly
------------------------------------------------------------------------------------------------------------------------
--Gamepd player inventory
invRootScene:AddFragment(gamepadLibFiltersInventoryDepositFragment)

-- Gamepad bank and house bank: Used for switching the gamepad bank's fragment depending if house bank or not
local gamepadBankingScene = GAMEPAD_BANKING_SCENE
ZO_PreHook(invBank_GP, 'OnOpenBank', function(self, bankBag)
	if bankBag == BAG_BANK then
		gamepadBankingScene:RemoveFragment(gamepadLibFiltersHouseBankDepositFragment)
		gamepadBankingScene:AddFragment(gamepadLibFiltersBankDepositFragment)
	else
		--House bank
		gamepadBankingScene:RemoveFragment(gamepadLibFiltersBankDepositFragment)
		gamepadBankingScene:AddFragment(gamepadLibFiltersHouseBankDepositFragment)
	end
	return false
end)

invGuildBankDepositScene_GP:AddFragment(gamepadLibFiltersGuildBankDepositFragment)
invGuildStoreSellScene_GP:AddFragment(gamepadLibFiltersGuildStoreSellFragment)

invMailSendScene_GP:AddFragment(gamepadLibFiltersMaiLSendFragment)
invPlayerTradeScene_GP:AddFragment(gamepadLibFiltersPlayerTradeFragment)