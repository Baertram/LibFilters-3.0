# Wording / Glossary
## filterTag
The string defined by an addon to uniquely describe and reference the filter in the internal tables
(e.g. "addonName1FilterForInventory"). Often the filterType (see bwlow) constant will be concatenated with a prefixed "-" at the end of the filterTag to identify the filterTag's filterType, e.g. "addonName1FilterForInventory-" .. tostring(LF_INVENTORY) -> "addonName1FilterForInventory-1"
## filterType
Also libFiltersFilterType or LF_*constant: The LF_* number constant of the filter, describing the panel where it will be filtered (e.g. LF_INVENTORY for Player Inventory). LF_INVENTORY is number 1 and each other constant increases the number by 1. Never change those constants or exisitng addons will fail/break!
## filterPanel
Basically this is the scene/fragment/control/environment shown where the filterType is used. Player inventory si the panel for LF_INVENTORY
## filterReference
The referenced panel's control/fragment/scene/userdata/table where the filterType applies to. The reference is used for the "is shown"/"is hidden" callbacks of the filterTypes
## filterFunction
A function used to filter the items at the given filterType (filterPanel). The filterFunction will be added to existing ZOs vavilla filter function code (often ZOs stores them in a table attribute ".additionalFilter" at e.g. the PLAYER_INVENTORY.inventories tables or some fragments used for the layout) or to other functions (see helper.lua for the changed ZOs vanilla code functions where LibFilters needs to "hack" into to add it's own filterFunction in addition). Each filterTag and filterType "registered" as a new filter of any addon will be added to the filterfunctions and will be run "in combination" (vanille UI ZOs filterFunctions + LibFilters filterFunctions + maybe other addons filterFunctions -> if the other addons check for existing filterFunctions and do not just overwrite the existing ones and thus break LibFilters).
FilterFunctions can have different parameters (either "inventorySlot" or "bagId, slotIndex"), depending on the filterType they are registered for. Please read below at "Filter functions"

# [LibFilters]
This library is used to filter inventory items (show/hide) at the different panels/inventories -> LibFilters uses the
term "filterType" for the different filter panels. Each filterType is represented by the help of a number constant
starting with LF_<panelName> (e.g. LF_INVENTORY, LF_BANK_WITHDRAW), which is used to add filterFunctions of different
adddons to this inventory. See table libFiltersFilterConstants for the value = "filterPanel name" constants.
The number of the constant increases by 1 with each new added constant/panel.
The minimum valueis LF_FILTER_MIN (1) and the maximum is LF_FILTER_MAX (#libFiltersFilterConstants). There exists a
"fallback" constant LF_FILTER_ALL (9999) which can be used to register filters for ALL exisitng LF_* constants. If any
LF_* constant got no filterFunction registered, the entries in filters[LF_FILTER_ALL] will be used instead (if
existing, and the flag to use the LF_FILTER_ALL fallback is enabled (boolean true) via function
libFilters:SetFilterAllState(boolean newState)

The filterType (LF_* constant) of the currently shown panel (see function libFilters:GetCurrentFilterTypeForInventory(inventoryType))
will be stored at the "LibFilters3_filterType" ("constants.defaultAttributeToStoreTheFilterType")
attribute at the inventory/layoutData/scene/control involved for the filtering. See function libFilters:HookAdditionalFilter

The registered filterFunctions will run as the inventories are refreshed/updated, either by internal update routines as
the inventory's "dirty" flag was set to true. Or via function SafeUpdateList (see below), or via some other update/refresh/
ShouldAddItemToSlot function (some of them are overwriting vanilla UI source code in the file helpers.lua).
LibFilters3 will use the inventory/fragment (normal hooks), or some special hooks (e.g. ENCHANTING -> OnModeUpdated) to
add the LF* constant to the inventory/fragment/variables.
With the addition of Gamepad support the special hooks like enchanting were even changed to use the gamepad scenes of
enchanting as "object to store the" the .additionalFilter entry for the LibFilters filter functions.

The filterFunctions will be placed at the inventory/fragment/layoutData/control.additionalFilter ("constants.defaultAttributeToAddFilterFunctions") entry, and will enhance existing functions, so
that filter funtions summarize (e.g. addon1 registers a "Only show stolen filter" and addon2 registers "only show level
10 items filter" -> Only level 10 stolen items will be shown then).

The function InstallHelpers below will call special code from the file "helper.lua". In this file you define the
variable(s) and function name(s) which LibFilters should "REPLACE" -> Means it will overwrite those functions to add
the call to the LibFilters internal filterFunctions (e.g. at SMITHING crafting tables, function
EnumerateInventorySlotsAndAddToScrollData -> ZOs vanilla UI code + usage of self.additionalFilter where Libfilters
added it's filterFunctions) via the registered filterFunctions at .additionalFilter

## Gamepad mode
The files in the Gamepad folder define the custom fragments which were created for the Gamepad scenes to try to keep it
similar to the keyboard fragments (as inventory shares the same PLAYER_INVENTORY variables for e.g. player inventory,
bank/guild bank/house bank deposit, mail send and player2player trade) there needs to be one unique object per panel to
store the .additionalFilter entry. And this are the fragments in keyboard mode, and now custom fragments starting with
LIBFILTERS3_ in gamepad mode.
These fragments will be added to vanilla gamepad scenes/fragments so they show/hide with them properly.

## Important - Library initialization
You MUST call
<pre>
LibFilters3:InitializeLibFilters()
</pre>
once in any of the addons that use LibFilters, at/after EVENT_ADD_ON_LOADED callback, to create the hooks and init the
library properly!

## Filter functions
Here is the mapping which filterId constant LF* uses which type of filter function: inventorySlot or bagdId & slotIndex
Example filter functions:

Filter function with inventorySlot
local function FilterSavedItemsForSlot(inventorySlot)
  return true  show the item in the list / false = hide item
end

Filter function with bagId and slotIndex (often used at crafting tables)
local function FilterSavedItemsForBagIdAndSlotIndex(bagId, slotIndex)
  return true  show the item in the list / false = hide item
end

All LF_ constants except the ones named below, e.g. LF_INVENTORY, LF_CRAFTBAG, LF_VENDOR_SELL
are using the InventorySlot filter function!

Filter function with bagId and slotIndex (most of them are crafting related ones)
[LF_SMITHING_REFINE]                        = FilterSavedItemsForBagIdAndSlotIndex,
[LF_SMITHING_DECONSTRUCT]                   = FilterSavedItemsForBagIdAndSlotIndex,
[LF_SMITHING_IMPROVEMENT]                   = FilterSavedItemsForBagIdAndSlotIndex,
[LF_SMITHING_RESEARCH]                      = FilterSavedItemsForBagIdAndSlotIndex,
[LF_SMITHING_RESEARCH_DIALOG]               = FilterSavedItemsForBagIdAndSlotIndex,
[LF_JEWELRY_REFINE]                         = FilterSavedItemsForBagIdAndSlotIndex,
[LF_JEWELRY_DECONSTRUCT]                    = FilterSavedItemsForBagIdAndSlotIndex,
[LF_JEWELRY_IMPROVEMENT]                    = FilterSavedItemsForBagIdAndSlotIndex,
[LF_JEWELRY_RESEARCH]                       = FilterSavedItemsForBagIdAndSlotIndex,
[LF_JEWELRY_RESEARCH_DIALOG]                = FilterSavedItemsForBagIdAndSlotIndex,
[LF_ENCHANTING_CREATION]                    = FilterSavedItemsForBagIdAndSlotIndex,
[LF_ENCHANTING_EXTRACTION]                  = FilterSavedItemsForBagIdAndSlotIndex,
[LF_RETRAIT]                                = FilterSavedItemsForBagIdAndSlotIndex,
[LF_ALCHEMY_CREATION]                       = FilterSavedItemsForBagIdAndSlotIndex,

 See constants.lua -> table libFilters.constants.filterTypes.UsingBagIdAndSlotIndexFilterFunction and table
 libFilters.constants.filterTypes.UsingInventorySlotFilterFunction
 to dynamically determine the functionType to use. The following constants for the functionTypes exist:
 libFilters.constants.LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT = 1
 libFilters.constants.LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX = 2

## Test
Uncomment (remove the ##) the 2 files in the LibFilters-x.x.xt file to enable testing ingame:
```
## test/test.lua
## test/test.xml
```

You will be able to use the slash command
<pre>
/libfilterstest <OPTIONAL LF_filterTypeConstantToAddTheFilterFunctionFor> <OPTIONAL globalFilterFunctionUsingBagIdAndSlotIndex>
</pre>
to show the testing UI. It will allow you to click the given filterTypes in a list to enable/disbale their filters. Click the buttons at the test UI to register/unregister the filters selected (refresh button). The panels using these registered filterTypes' filterFunction will filter with a standard filterFunction then which will do some itemType and quality checks, or stackCount checks:
<pre>
local function defaultFilterFunction(bagId, slotIndex, stackCount)
	local itemType, specializedItemType = GetItemType(bagId, slotIndex)
	local quality = GetItemQuality(bagId, slotIndex)

	if itemType == ITEMTYPE_ENCHANTING_RUNE_ASPECT then
		return quality < ITEM_FUNCTIONAL_QUALITY_ARCANE
	elseif itemType == ITEMTYPE_BLACKSMITHING_BOOSTER then
		return quality < ITEM_FUNCTIONAL_QUALITY_ARCANE
	elseif itemType == ITEMTYPE_CLOTHIER_BOOSTER then
		return quality < ITEM_FUNCTIONAL_QUALITY_ARCANE
	elseif itemType == ITEMTYPE_JEWELRYCRAFTING_BOOSTER then
		return quality < ITEM_FUNCTIONAL_QUALITY_ARCANE
	elseif itemType == ITEMTYPE_WOODWORKING_BOOSTER then
		return quality < ITEM_FUNCTIONAL_QUALITY_ARCANE
	elseif itemType == ITEMTYPE_WEAPON or itemType == ITEMTYPE_ARMOR then
		return quality < ITEM_FUNCTIONAL_QUALITY_ARCANE and not IsItemPlayerLocked(bagId, slotIndex) and
			GetItemActorCategory(bagId, slotIndex) ~= GAMEPLAY_ACTOR_CATEGORY_COMPANION
	elseif itemType == ITEMTYPE_POISON_BASE or itemType == ITEMTYPE_POTION_BASE or itemType == ITEMTYPE_REAGENT then
		return stackCount > 100
	end

	if quality > ITEM_FUNCTIONAL_QUALITY_ARCANE then
		return false
	end
	return stackCount > 1
end
</pre>

You can specify a new global filterFunction from your addon to test the filtering by providing them via the slash command
/libfilterstest <OPTIONAL LF_filterTypeConstantToAddTheFilterFunctionFor> <globalFilterFunctionUsingBagIdAndSlotIndex> as parameters.
If no 1st param <LF_filterTypeConstantToAddTheFilterFunctionFor> was given it will use LF_FILTER_ALL and register the <globalFilterFunctionUsingBagIdAndSlotIndex as parameter> filterFunction provided for all filterTypes in the test environment.

## Example usage
You need to initialize the library once (See above "Library initialization").
You need to create a filterFunction for your needs, using the correct parameters (inventorySlot, or bagid & slotIndex).
You need to define a unique filtertAg for each filter, e.g. if your addon name is "MyAddonName1" then create a filterTag starting with your addon name, then an underscore "_", followed by a short description of the purpose and then add "-" and the LF_* constant of the filter as suffix:
"MyAddonName1_StolenOnlyInInv-1" if you want to only show stolen items in the inventory LF_INVENTORY.
You need to register a filter in order to add the filterFunction to the .additionalFilter attribute of the filters to run.
<pre>
LibFilters3:RegisterFilter("MyAddonName1_StolenOnlyInInv-1", LF_INVENTORY, filterFunctionToUseUsingTheParametersNeededForLF_INVENTORY) </pre>
You need to unregister a filter if it is not needed anymore!
<pre>
LibFilters3:UnregisterFilter("MyAddonName1_StolenOnlyInInv-1", LF_INVENTORY) </pre>
You are responsible to unregister and register filters manually in your code! Libfiletrs is not going to add/remove and filterFunctions autoamtically. They stay registered until you unregister them, means they will stay active and filter items as long as you do not unregister the filterFunction!
You need to check if a filter is registered already before registering/unregistering any by using LibFilters3:IsFilterRegistered(filterTag, filterType):
<pre>if not LibFilters3:IsFilterRegistered("MyAddonName1_StolenOnlyInInv-1", LF_INVENTORY) then</pre>

You can use the API functions provided in LibFilters-3.0.lua, search for "BEGIN LibFilters API functions BEGIN" and look below that tag, until "END LibFilters API functions END"

### Example code
The following example code initiates the library and adds a filter function to the normal player inventory, which will hide items that are
-> See file /test/test.lua for more examples.
```lua
--Call at EVENT_ADD_ON_LOADED as the library, once added to your addon's manifest .txt file tag ## DependsOn: LibFilters-3.0, will be ready then (loaded dependency before your addon was loaded)
--Initi the library and it's API
local libFilters = LibFilters3
libFilters:InitializeLibFilters()

local myAddonUniqueFilterTag = "MyAddonName_FilterForFilterType" .. tostring(LF_INVENTORY)

--The filterFunction for the inventory, using inventorySlot as parameter. Check documentation "Example filter functions" above to see which filterType uses which parameters for the filterFunctions
--This filterFunction checks if the items are bound and hides them then
local filterFuncForPlayerInv(inventorySlot)
  local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
  local itemLink = GetItemLink(bagId, slotIndex)
  return IsItemLinkBound(itemLink)
end

--Register a filterFunction to player inventory
if not libFilters:IsFilterRegistered(myAddonUniqueFilterTag, LF_INVENTORY) then
  libFilters:RegisterFilter(myAddonUniqueFilterTag, LF_INVENTORY, filterFuncForPlayerInv)
end

--At any time the filter should not be applied anymore (e.g. as the inventory LF_INVENTORY hides) you need to unregister the filter again.
--LibFilters will keep all registered filterFuctions active until you manually unregister them! So make sure to register and unregister them properly if not needed anymore
--The library provides callbacks for the filterTypes to get noticed as the filterTypes are shown/hidden.
--The callback name is build by the library prefix "LibFilters3-" (constant provided is LibFilters3.globalLibName) followed by the state of the
--filterPanel as the callback fires (can be either the constant SCENE_SHOWN or SCENE_HIDDEN), followed by "-" and the suffix is the filterType constant
--of the panel.
--The library provides the API function libfilters:CreateCallbackName(filterType, isShown) to generate the callback name for you. isShown is a boolean.
--if true SCENE_SHOWN will be used, if false SCENE_HIDDEN will be used.
--e.g. for LF_INVENTORY shown it would be
local callbackNameInvShown = libfilters:CreateCallbackName(LF_INVENTORY, true)
--Makes: "LibFilters3-shown-1"

--The callbackFunction you register to it needs to provide the following parameters:
--number filterType, refVar fragmentOrSceneOrControl, table lReferencesToFilterType, boolean isInGamepadMode, string stateStr
--number filterType is the LF_* constantfor the panel currently shown/hidden
--refVar fragmentOrSceneOrControl is the frament/scene/control which was used to do the isShown/isHidden check
--table lReferencesToFilterType will contain additional reference variables used to do shown/hidden checks
--boolean isInGamepadMode is true if we are in Gamepad input mode and false if in keyboard mode
--string stateStr will be SCENE_SHOWN ("shown") if shon or SCENE_HIDDEN ("hidden") if hidden callback was fired

local function callbackFunctionForInvShown(filterType, fragmentOrSceneOrControl, lReferencesToFilterType, isInGamepadMode, stateStr)
  --Register your filterFunction here e.g. or do whatever is needed, like adding custom controls of your addon to the currently shown panel
  if not libFilters:IsFilterRegistered(myAddonUniqueFilterTag, LF_INVENTORY) then
    libFilters:RegisterFilter(myAddonUniqueFilterTag, LF_INVENTORY, filterFuncForPlayerInv)
  end
end
local function callbackFunctionForInvHidden(filterType, fragmentOrSceneOrControl, lReferencesToFilterType, isInGamepadMode, stateStr)
  --Unregister your filterFunction here e.g. or do whatever is needed, ikehiding custom controls of your addon at the currently hidden panel
  libFilters:UnRegisterFilter(myAddonUniqueFilterTag, LF_INVENTORY)
end

--Registering this callbackname in your addon is done via the CALLBACK_MANAGER
CALLBACK_MANAGER:RegisterCallback(callbackNameInvShown, callbackFunctionForInvShown)
```

# Addons using LibFilters
AdvancedFilters
FCOItemSaver
FCOCraftFilter
HarvensStolenFilters
HideBoundItems
ItemSaver
NTakLootNSteal
