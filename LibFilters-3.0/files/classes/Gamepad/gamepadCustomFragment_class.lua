--Reference to the global library
local libFilters = LibFilters3
local classes = libFilters.classes

--LibFilters local speedup and reference variables
--Overall constants
local constants = 								libFilters.constants
local inventoryTypes = 							constants.inventoryTypes
local playerInventoryType = 					inventoryTypes["player"] -- INVENTORY_BACKPACK

--Keyboard
local kbc             = 						constants.keyboard
local playerInventory = 						kbc.playerInv


local gamepadLibFiltersInventoryFragment =      libFilters.fragments[true].CustomInventoryFragment

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Custom added Gamepad inventory type fragment's sub-class
--  These fragments will be used to automatically transfer the .additionalFilter via their layoutData and function
--  self:ApplyInventoryLayout(self.layoutData) to the e.g. PLAYER_INVENTORY.inventories[INV_BANK] etc. as they show
--  Else one would have been able to e.g. use the via dereferedInitialized created lists' (deposit, withdraw e.g.)
--  fragments directly, but they do not use this layoutData nor additionalFilters. So LibFilters stores it's
--  filterFunction in there, like the keyboard mode does
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local LibFilters_InventoryLayoutFragment_Class = ZO_SceneFragment:Subclass()

function LibFilters_InventoryLayoutFragment_Class:New(...)
	local fragment = ZO_SceneFragment.New(self)
    fragment:Initialize(...)
    return fragment
end
function LibFilters_InventoryLayoutFragment_Class:Initialize(layoutData)
    if layoutData then
        self.layoutData = layoutData
    else
        self.layoutData = {}
    end
    self.state = SCENE_FRAGMENT_HIDDEN --to make function constants.lua -> checkIfControlSceneFragmentOrOther detect it as a fragment, as libFilters:HookAdditionalFilters is called
end
function LibFilters_InventoryLayoutFragment_Class:Show()
	self:ApplyInventoryLayout(self.layoutData)
	self:OnShown()
end
function LibFilters_InventoryLayoutFragment_Class:Hide()
	self:OnHidden()
	self:ApplyInventoryLayout(gamepadLibFiltersInventoryFragment.layoutData) --apply the normal Player Inventory layout upon hide
end


--Use the same layoutData as within Keyboard mode. If the fragments are shown the layoutData, which contains the
--.additionalFilter function entry, will be copied to the PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK].additionalFilter
--Actually happens like done in vanilla game for keybord mode, now for gamepad mode via LibFilters as well.
-->Vanila keyboard mode code, which applies the layoutData.additionalFilter (which is e.g. our hooked fragment
-->BACKPACK_MENU_BAR_LAYOUT_FRAGMENT or BACKPACK_BANK_LAYOUT_FRAGMENT)
-->https://github.com/esoui/esoui/blob/306d6f936a0daa58a24db85b85dd264a04d10699/esoui/ingame/inventory/inventory.lua#L2103
function LibFilters_InventoryLayoutFragment_Class:ApplyInventoryLayout(layoutData)
	--[[
	if layoutData == PLAYER_INVENTORY.appliedLayout and not layoutData.alwaysReapplyLayout then
		return
	end
	]]
	playerInventory.appliedLayout                                     = layoutData
	playerInventory.inventories[playerInventoryType].additionalFilter = layoutData.additionalFilter
end



--Provide the class for the custom filter fragment. A new created "copy-from" fragment "gamepadLibFiltersDefaultFragment"
-- will be created in file /Gamepad/gamepadCustomFragments.lua
classes.InventoryLayoutFragment = LibFilters_InventoryLayoutFragment_Class
