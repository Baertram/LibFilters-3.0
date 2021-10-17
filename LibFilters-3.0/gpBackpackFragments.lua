--[[
	Version:	1.0
	Idea:		IsJustAGhost
	Code by:	IsJustAGhost & Baertram

	Description:
	The gamepad mode does not provide fragments for the backpack, bank and other inventory types as the keyboard mode
	does, and hooks into (to add the .additionalFilter function entry). There for we create our own fragments for the
	needed inventory types and add them to the gamepad scenes (which are used already by vanilla UI).

	The new added custom fragments base on the class "LibFilters_InventoryLayoutFragment".

	[New added custom fragments are]
	Important: The names of the new custom fragments prefix with "LIBFILTERS_" in order to see it's origin and distin-
	guish from vanilla code ZOs fragments (and to prevent being overwritten by new added ZOs code)

	BACKPACK_BANK_GAMEPAD_FRAGMENT					Bank deposit
	BACKPACK_HOUSE_BANK_GAMEPAD_FRAGMENT			House bank deposit
	BACKPACK_GUILD_BANK_GAMEPAD_FRAGMENT			Guild bank deposit
	BACKPACK_TRADING_HOUSE_GAMEPAD_FRAGMENT			Trading house / Guild vendor deposit
	BACKPACK_MAIL_GAMEPAD_FRAGMENT					Mail send
	BACKPACK_PLAYER_TRADE_GAMEPAD_FRAGMENT			Player to player trade
	BACKPACK_INVENTORY_GAMEPAD_FRAGMENT				Player inventory

	[Existing vanilla code Scenes are]


]]

local fragmentPrefix = "LIBFILTERS_"

-- local object used to apply the needed functions to the fragments
local LibFilters_InventoryLayoutFragment = ZO_SceneFragment:Subclass()
function LibFilters_InventoryLayoutFragment:New(...)
	local fragment = ZO_SceneFragment.New(self)
    fragment:Initialize(...)
    return fragment
end
function LibFilters_InventoryLayoutFragment:Initialize(layoutData)
    if(layoutData) then
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
		self:ApplyInventoryLayout(BACKPACK_INVENTORY_GAMEPAD_FRAGMENT.layoutData)
end

function LibFilters_InventoryLayoutFragment:ApplyInventoryLayout(layoutData)
	if layoutData == PLAYER_INVENTORY.appliedLayout and not layoutData.alwaysReapplyLayout then
		return
	end
	PLAYER_INVENTORY.appliedLayout = layoutData
	
	local inventory = PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK]
	inventory.additionalFilter = layoutData.additionalFilter
end

--Add the fragment prefix and return the fragment
local function getCustomLibFiltersFragment(fragmentName)
	return _G[fragmentPrefix .. fragmentName]
end


------------------------------------------------------------------------------------------------------------------------
-- Custom added Gamepad inventory type fragments
------------------------------------------------------------------------------------------------------------------------
--Player bank deposit
local gamepadLibFiltersBankDepositFragment = LibFilters_InventoryLayoutFragment:New(
	{
		additionalFilter = function(slot) return true end
	})
_G[fragmentPrefix .. "BACKPACK_BANK_GAMEPAD_FRAGMENT"] = gamepadLibFiltersBankDepositFragment

--House bank deposit
_G[fragmentPrefix .. "BACKPACK_HOUSE_BANK_GAMEPAD_FRAGMENT"]    = ZO_DeepTableCopy(gamepadLibFiltersBankDepositFragment)

--Guild bank deposit
_G[fragmentPrefix .. "BACKPACK_GUILD_BANK_GAMEPAD_FRAGMENT"]    = ZO_DeepTableCopy(gamepadLibFiltersBankDepositFragment)

--Trading house = Guild store deposit
_G[fragmentPrefix .. "BACKPACK_TRADING_HOUSE_GAMEPAD_FRAGMENT"] = ZO_DeepTableCopy(gamepadLibFiltersBankDepositFragment)

--Mail send
_G[fragmentPrefix .. "BACKPACK_MAIL_GAMEPAD_FRAGMENT"]			= ZO_DeepTableCopy(gamepadLibFiltersBankDepositFragment)

--Player to player trade
local gamepadLibFiltersPlayerTradeFragment = LibFilters_InventoryLayoutFragment:New(
	{
		additionalFilter = function(slot) return true end,
		alwaysReapplyLayout = true
	})
_G[fragmentPrefix .. "BACKPACK_PLAYER_TRADE_GAMEPAD_FRAGMENT"] = gamepadLibFiltersPlayerTradeFragment
--Player inventory
_G[fragmentPrefix .. "BACKPACK_INVENTORY_GAMEPAD_FRAGMENT"] = ZO_DeepTableCopy(gamepadLibFiltersPlayerTradeFragment)


------------------------------------------------------------------------------------------------------------------------
-- Gamepad Scenes: Add new custom fragments to the scenes
------------------------------------------------------------------------------------------------------------------------
SCENE_MANAGER:GetScene("mailManagerGamepad"):AddFragment(getCustomLibFiltersFragment("BACKPACK_MAIL_GAMEPAD_FRAGMENT"))
SCENE_MANAGER:GetScene("gamepadTrade"):AddFragment(getCustomLibFiltersFragment("BACKPACK_PLAYER_TRADE_GAMEPAD_FRAGMENT"))
TRADING_HOUSE_GAMEPAD_SCENE:AddFragment(getCustomLibFiltersFragment("BACKPACK_TRADING_HOUSE_GAMEPAD_FRAGMENT"))
GAMEPAD_GUILD_BANK_SCENE:AddFragment(getCustomLibFiltersFragment("BACKPACK_GUILD_BANK_GAMEPAD_FRAGMENT"))

-- used for switching the gamepad bank's fragment depending if house bank or not
ZO_PreHook(GAMEPAD_BANKING, 'OnOpenBank', function(self, bankBag)
	if bankBag == BAG_BANK then
		GAMEPAD_BANKING_SCENE:RemoveFragment(getCustomLibFiltersFragment("BACKPACK_HOUSE_BANK_GAMEPAD_FRAGMENT"))
		GAMEPAD_BANKING_SCENE:AddFragment(getCustomLibFiltersFragment("BACKPACK_BANK_GAMEPAD_FRAGMENT"))
	else
		GAMEPAD_BANKING_SCENE:RemoveFragment(getCustomLibFiltersFragment("BACKPACK_BANK_GAMEPAD_FRAGMENT"))
		GAMEPAD_BANKING_SCENE:AddFragment(getCustomLibFiltersFragment("BACKPACK_HOUSE_BANK_GAMEPAD_FRAGMENT"))
	end
	return false
end)

--Gamepd player inventory
GAMEPAD_INVENTORY_ROOT_SCENE:AddFragment(getCustomLibFiltersFragment("BACKPACK_INVENTORY_GAMEPAD_FRAGMENT"))