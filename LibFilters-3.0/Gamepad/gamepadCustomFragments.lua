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
local SM = SCENE_MANAGER


------------------------------------------------------------------------------------------------------------------------
-- Local library variables
------------------------------------------------------------------------------------------------------------------------
local libFilters = LibFilters3

--LibFilters local speedup and reference variables
local constants = libFilters.constants
local gamepadConstants = libFilters.constants.gamepad
local customFragments = gamepadConstants.customFragments
local fragmentPrefix = gamepadConstants.customFragmentPrefix

--The fragment variables
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
	local fragmentName = customFragments[libFiltersFilterType]
	return fragmentPrefix .. fragmentName
end


------------------------------------------------------------------------------------------------------------------------
-- Custom added Gamepad inventory type fragment's sub-class
------------------------------------------------------------------------------------------------------------------------
local LibFilters_InventoryLayoutFragment = ZO_SceneFragment:Subclass()
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
	if GAMEPAD_INVENTORY.layoutData then
	end
		self:ApplyInventoryLayout(gamepadLibFiltersInventoryDepositFragment.layoutData)
end

--Use the same layoutData as within Keyboard mode
function LibFilters_InventoryLayoutFragment:ApplyInventoryLayout(layoutData)
	--[[
	if layoutData == PLAYER_INVENTORY.appliedLayout and not layoutData.alwaysReapplyLayout then
		return
	end
	]]
	PLAYER_INVENTORY.appliedLayout = layoutData
	PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK].additionalFilter = layoutData.additionalFilter
end


------------------------------------------------------------------------------------------------------------------------
-- Custom added Gamepad inventory type fragments
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
_G[getCustomLibFiltersFragmentName(LF_GUILD_BANK_DEPOSIT)]  = gamepadLibFiltersGuildBankDepositFragment

--Trading house = Guild store deposit
gamepadLibFiltersGuildStoreSellFragment = ZO_DeepTableCopy(gamepadLibFiltersBankDepositFragment)
_G[getCustomLibFiltersFragmentName(LF_GUILD_STORE_SELL)]	= gamepadLibFiltersGuildStoreSellFragment

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
-- Gamepad Scenes: Add new custom fragments to the scenes
------------------------------------------------------------------------------------------------------------------------
--Gamepd player inventory
GAMEPAD_INVENTORY_ROOT_SCENE:AddFragment(gamepadLibFiltersInventoryDepositFragment)

-- Gamepad bank and house bank: Used for switching the gamepad bank's fragment depending if house bank or not
ZO_PreHook(GAMEPAD_BANKING, 'OnOpenBank', function(self, bankBag)
	if bankBag == BAG_BANK then
		GAMEPAD_BANKING_SCENE:RemoveFragment(gamepadLibFiltersHouseBankDepositFragment)
		GAMEPAD_BANKING_SCENE:AddFragment(gamepadLibFiltersBankDepositFragment)
	else
		--House bank
		GAMEPAD_BANKING_SCENE:RemoveFragment(gamepadLibFiltersBankDepositFragment)
		GAMEPAD_BANKING_SCENE:AddFragment(gamepadLibFiltersHouseBankDepositFragment)
	end
	return false
end)

GAMEPAD_GUILD_BANK_SCENE:AddFragment(gamepadLibFiltersGuildBankDepositFragment)
TRADING_HOUSE_GAMEPAD_SCENE:AddFragment(gamepadLibFiltersGuildStoreSellFragment)
SM:GetScene("mailManagerGamepad"):AddFragment(gamepadLibFiltersMaiLSendFragment)
SM:GetScene("gamepadTrade"):AddFragment(gamepadLibFiltersPlayerTradeFragment)
