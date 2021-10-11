------------------------------------------------------------------------------------------------------------------------
-- Gamepad Backpack Fragments
------------------------------------------------------------------------------------------------------------------------
-- append ApplyBackpackLayout function to ZO_GamepadInventoryList object
-- adds self.additionalFilter to helper "ZO_GamepadInventoryList:AddSlotDataToTable"
function ZO_GamepadInventoryList:ApplyBackpackLayout(layoutData)
	if layoutData == PLAYER_INVENTORY.appliedLayout and not layoutData.alwaysReapplyLayout then
		return
	end
	PLAYER_INVENTORY.appliedLayout = layoutData
	
	local inventory = PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK]
	inventory.additionalFilter = layoutData.additionalFilter
	
	local craftBag = PLAYER_INVENTORY.inventories[INVENTORY_CRAFT_BAG]
--	craftBag.additionalFilter = layoutData.additionalCraftBagFilter
--	craftBag.additionalFilter = layoutData.additionalFilter
end

-- local object used to apply the needed functions to the fragments
local GP_BackpackLayoutFragment = ZO_SceneFragment:Subclass()
function GP_BackpackLayoutFragment:New(...)
	local fragment = ZO_SceneFragment.New(self)
	return fragment
end
function GP_BackpackLayoutFragment:Show()
	ZO_GamepadInventoryList:ApplyBackpackLayout(self)
	self:OnShown()
end
function GP_BackpackLayoutFragment:Hide()
	self:OnHidden()
end

BACKPACK_BANK_GAMEPAD_FRAGMENT       = GP_BackpackLayoutFragment:New(
	{
		additionalFilter = function(slot) end
	})
BACKPACK_HOUSE_BANK_GAMEPAD_FRAGMENT    = ZO_DeepTableCopy(BACKPACK_BANK_GAMEPAD_FRAGMENT)
BACKPACK_GUILD_BANK_GAMEPAD_FRAGMENT    = ZO_DeepTableCopy(BACKPACK_BANK_GAMEPAD_FRAGMENT)
BACKPACK_TRADING_HOUSE_GAMEPAD_FRAGMENT = ZO_DeepTableCopy(BACKPACK_BANK_GAMEPAD_FRAGMENT)
BACKPACK_MAIL_GAMEPAD_FRAGMENT         = ZO_DeepTableCopy(BACKPACK_BANK_GAMEPAD_FRAGMENT)
BACKPACK_PLAYER_TRADE_GAMEPAD_FRAGMENT = GP_BackpackLayoutFragment:New(
	{
		additionalFilter = function(slot) end,
		alwaysReapplyLayout = true,
	})
	
	
-- BACKPACK_STORE_GAMEPAD_FRAGMENT = ZO_DeepTableCopy(BACKPACK_PLAYER_TRADE_GAEMPAD_FRAGMENT)
-- BACKPACK_FENCE_GAMEPAD_FRAGMENT = ZO_DeepTableCopy(BACKPACK_PLAYER_TRADE_GAEMPAD_FRAGMENT)
-- BACKPACK_LAUNDER_GAMEPAD_FRAGMENT = ZO_DeepTableCopy(BACKPACK_PLAYER_TRADE_GAEMPAD_FRAGMENT)

SCENE_MANAGER:GetScene("mailManagerGamepad"):AddFragment(BACKPACK_MAIL_GAMEPAD_FRAGMENT)
SCENE_MANAGER:GetScene("gamepadTrade"):AddFragment(BACKPACK_PLAYER_TRADE_GAMEPAD_FRAGMENT)
TRADING_HOUSE_GAMEPAD_SCENE:AddFragment(BACKPACK_TRADING_HOUSE_GAMEPAD_FRAGMENT)
GAMEPAD_GUILD_BANK_SCENE:AddFragment(BACKPACK_GUILD_BANK_GAMEPAD_FRAGMENT)


-- used for switching the gamepad bank's fragment depending if house bank or not
ZO_PostHook(GAMEPAD_BANKING, 'OnOpenBank', function(self, bankBag)
	if bankBag == BAG_BANK then
		GAMEPAD_BANKING_SCENE:RemoveFragment(BACKPACK_HOUSE_BANK_GAMEPAD_FRAGMENT)
		GAMEPAD_BANKING_SCENE:AddFragment(BACKPACK_BANK_GAMEPAD_FRAGMENT)
	else
		GAMEPAD_BANKING_SCENE:RemoveFragment(BACKPACK_BANK_GAMEPAD_FRAGMENT)
		GAMEPAD_BANKING_SCENE:AddFragment(BACKPACK_HOUSE_BANK_GAMEPAD_FRAGMENT)
	end
end)


--GAMEPAD_ENCHANTING_CREATION_SCENE





