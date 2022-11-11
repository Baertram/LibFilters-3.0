# LibFilters
**An Elder Scrolls Online library to filter your items at the different inventories**

Current version: 3, last updated: 2022-11-11

This library is used to filter inventory items (show/hide) at the different panels/inventories -> LibFilters uses the
term "filterType" for the different inventories (also called filterPanels).
Check the wording/glossary Wiki page for more descriptions.

Each filterType is represented by the help of a number constant
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

## Gamepad mode - custom fragments
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
```
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
```
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
/lftestfilters OPTIONAL LF_filterTypeConstantToAddTheFilterFunctionFor OPTIONAL globalFilterFunctionUsingBagIdAndSlotIndex
</pre>
to show the testing UI. It will allow you to click the given filterTypes in a selection list (upper list (1)) to add their filters to the enabled list (lower list (2)). Click the buttons at the top list (1) to enable the filters. Yellow buttons are enabled, and a chat message shows the enabled/disabled state of the filter.
![LibFilters test UI](https://i.imgur.com/Mj9bJfu.png)
Click the "apply" button (3) to add the selected filter buttons from the upper list to the lower list (2). Only buttons shown at the bottom list (2) are currently filtered.
Click the "all" button (4) to add all filters of the upper list to the lower list, or click it again to remove all from the lower list again.
Click the "Filter" button (5) to enable/disable filters in total.

The panels using these registered filterTypes' filterFunction will filter with a standard filterFunction then which will do some itemType and quality checks, or stackCount checks:
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

### Specify own test filterFunction
You can specify your own global filterFunction from your addon to test the filtering by providing them via the slash command
<pre>/lftestfilters OPTIONAL LF_filterTypeConstantToAddTheFilterFunctionFor globalFilterFunctionUsingBagIdAndSlotIndex</pre> as parameters.
If no 1st param LF_filterTypeConstantToAddTheFilterFunctionFor was given it will use LF_FILTER_ALL and register the globalFilterFunctionUsingBagIdAndSlotIndex filterFunction provided for all filterTypes in the test environment.

**Attention: Your filterFunction passed in needs to use bagId and slotIndex for ALL filterTypes!**<br>
It does not differ between inventorySlot or bagId & slotIndex as normal filterFunctions do!



## Callbacks
LibFilters provides callbacks that fire as a panel is shown/hidden.
You can register your own callback's callback function to run as the callback fires at the different supported LF* constant's panels show/hide.
The callbacks that can fire use the ESO scene callback shown/hidden constants SCENE_SHOWN and SCENE_HIDDEN (allthough not all callbacks for keyboard/gamepad mode will use scenes. They can depend on multiple different scenes/fragments/controls or even custom code, just the constants SCENE_SHOWN and SCENE_HIDDEN are used internally to differe the OnShow and OnHide callbacks).

You need a unique callback name (e.g. starting with your addonName and then the LibFilters filterType constant LF_* you want to register the callback for, followed by a string like SHOWN or HIDDEN (which the constants SCENE_SHOWN and SCENE_HIDDEN provide)
You need to use the API function **libFilters:RegisterCallbackName** to create such a unique callback name first AND to register it's execution, so that you can use the CALLBACK_MANAGER of ESO to add a callbackFunction to this unique callbackName.
<pre>
---Create the callbackname for a libFilters filterPanel shown/hidden callback
----It will add an entry in table LibFilters3.mapping.callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType][isShown]
----number filterType needs to be a valid LF_* filterType constant
----boolean isShown true means SCENE_SHOWN will be used, and false means SCENE_HIDDEN will be used for the callbackname
----boolean inputType true = Gamepad, false= keyboard callback, leave empty for both!
----nilable:String universalDeconActiveTab The active tab at the universal deconstruction panel that this callback should be raised for, e.g. "all", "armor", "weapons", "jewelry" or "enchanting"
----nilable:String raiseBeforeOtherAddonsCallbackName If this callbackName (of another addon) is given the callback should be raised after this callback was raised. The callbackName provided here must match the
----> other parameters like filterType, isShown, inputType, universalDeconActiveTab!
----Returns String callbackNameGenerated
---->e.g. "LibFilters3-<yourAddonName>-shown-1" for SCENE_SHOWN and filterType LF_INVENTORY of addon <yourAddonName>
LibFilters3:RegisterCallbackName(yourAddonName, filterType, isShown, inputType, universalDeconActiveTab, raiseBeforeOtherAddonsCallbackName)
</pre>
You can unregister a registered callbackName again by using the function
<pre>
--Remove an added callbackname for a libFilters filterPanel shown/hidden callback again
--It will remove the entry in table LibFilters3.mapping.callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType][isShown]
--number filterType needs to be a valid LF_* filterType constant
--boolean isShown true means SCENE_SHOWN will be used, and false means SCENE_HIDDEN will be used for the callbackname
--boolean inputType true = Gamepad, false= keyboard callback, leave empty for both!
--nilable:String universalDeconActiveTab The active tab at the universal deconstruction panel that this callback should be raised for, e.g. "all", "armor", "weapons", "jewelry" or "enchanting"
--Returns boolean wasRemoved true/false
LibFilters3:UnregisterCallbackName(yourAddonName, filterType, isShown, inputType, universalDeconActiveTab)
</pre>


After registering a callbackName you need to register a callbackFunction to that callbackname in your addon via the CALLBACK_MANAGER of ESO:
<pre>
CALLBACK_MANAGER:RegisterCallback(callbackNameCreatedByLibFiltersAPIFunctionRegisterCallbackName, yourCallbackFunctionForPanelShownOrHidden)
</pre>
The **callbackNameCreatedByLibFiltersAPIFunctionRegisterCallbackName** is the name you have created via API function libfilters:RegisterCallbackName, for the show or hide callback of your addon's LF* constant!
The callback function **yourCallbackFunctionForPanelShownOrHidden** uses the following parameters:
<pre>
callbackName String: Your callbackName used, created via API function libfilters:RegisterCallbackName
filterType Number: The LibFilzetrs filterType constant LF_* used
stateStr String: SCENE_SHOWN "shown" or SCENE_HIDDEN "hidden" depending on the callback's purpose (OnShown, or OnHidden)
isInGamepadMode Boolean: true if currently ingamepad mode, else it will be false
fragmentOrSceneOrControl userdata/control/fragment/scene: The userdate/control/fragment/scene reference variable that the callback was registered to
lReferencesToFilterType table: Table of reference controls/userdata/fragments/scenes that the callback provides
universalDeconPanelShownNow nilable:String: Will comtain the name of the universald deconstruction panel currently shown. If no universal decon callback was raised it will be nil!
This is needed as the filterTypes LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT and LF_ENCHANTING_EXTRACT are re-used at the Universal Deconstruction panel, and at the normal relating panels! At the UniversalDecon panel the value will be telling you the currently selected universal decon. tab e.g. "all", or "weapons", or "armor" or "jewelry" or "enchantments", at the normal crafting station panels it will be nil! That way you are able to distinguish the callback at the different panels
as LF_SMITHING_DECONSTRUCT counts for normal smithing/clotier/woodworking and universal decon tabs "all"/"weapons"/"armor" for example.
</pre>



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

#### Hide items at the player backpack (inventory) ####
The following example code initiates the library and adds a filter function to the normal player inventory, which will hide items that are bound.
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

--At any time the filter should not be applied anymore (e.g. as the inventory LF_INVENTORY hides) you need to unregister the filter again.
--LibFilters will keep all registered filterFuctions active until you manually unregister them! So make sure to register and unregister them properly if not needed anymore
--The library provides callbacks for the filterTypes to get noticed as the filterTypes are shown/hidden.
--The callback name is build by the library prefix "LibFilters3-" (constant provided is LibFilters3.globalLibName) followed by <yourAddonName> and another "-", followed by the state of the filterPanel as the callback fires (can be either the constant SCENE_SHOWN or SCENE_HIDDEN), followed by "-" and the suffix is the filterType constant
--of the panel.
--The library provides the API function libFilters:RegisterCallbackName(yourAddonName, filterType, isShown, inputType, universalDeconActiveTab, raiseBeforeOtherAddonsCallbackName) to generate the callback name for you. isShown is a boolean.
--if true SCENE_SHOWN will be used, if false SCENE_HIDDEN will be used.
--e.g. for LF_INVENTORY shown it would be
local callbackNameInvShown = libfilters:RegisterCallbackName("MyUniqueAddonName", LF_INVENTORY, true)
--Makes: "LibFilters3-MyUniqueAddonName-shown-1"
local callbackNameInvHidden = libfilters:RegisterCallbackName("MyUniqueAddonName", LF_INVENTORY, false)
--Makes: "LibFilters3-MyUniqueAddonName-hidden-1"


--The callbackFunction you register to it needs to provide the following parameters in the following order:
--callbackName, filterType, stateStr, isInGamepadMode, fragmentOrSceneOrControl, lReferencesToFilterType, universalDeconSelectedTabNow
--Your defined callback's unique name
--number filterType is the LF_* constant for the panel currently shown/hidden
--string stateStr will be SCENE_SHOWN ("shown") if shon or SCENE_HIDDEN ("hidden") if hidden callback was fired
--boolean isInGamepadMode is true if we are in Gamepad input mode and false if in keyboard mode
--refVar fragmentOrSceneOrControl is the frament/scene/control which was used to do the isShown/isHidden check
--table lReferencesToFilterType will contain additional reference variables used to do shown/hidden checks
--nilable:String universalDeconSelectedTabNow e.g. "all", "armor", "weapons", "jewelry" or "enchanting"

local function callbackFunctionForInvShown(callbackName, filterType, stateStr, isInGamepadMode, fragmentOrSceneOrControl, lReferencesToFilterType, universalDeconSelectedTabNow)
  --Register your filterFunction here e.g. or do whatever is needed, like adding custom controls of your addon to the currently shown panel
  if not libFilters:IsFilterRegistered(myAddonUniqueFilterTag, LF_INVENTORY) then
    libFilters:RegisterFilter(myAddonUniqueFilterTag, LF_INVENTORY, filterFuncForPlayerInv)
  end
end
local function callbackFunctionForInvHidden(callbackName, filterType, stateStr, isInGamepadMode, fragmentOrSceneOrControl, lReferencesToFilterType, universalDeconSelectedTabNow)
  --Unregister your filterFunction here e.g. or do whatever is needed, ikehiding custom controls of your addon at the currently hidden panel
  libFilters:UnRegisterFilter(myAddonUniqueFilterTag, LF_INVENTORY)
end

--Registering this callbackname in your addon is done via the CALLBACK_MANAGER
CALLBACK_MANAGER:RegisterCallback(callbackNameInvShown, callbackFunctionForInvShown)
CALLBACK_MANAGER:RegisterCallback(callbackNameInvHidden, callbackFunctionForInvHidden)
```

#### Hide items at the smithing crafting table, deconstruction ####
The following example code initiates the library and adds a filter function to the smithing deconstruction crafting table, which will hide items that are bound.
-> See file /test/test.lua for more examples.

```lua
--Call at EVENT_ADD_ON_LOADED as the library, once added to your addon's manifest .txt file tag ## DependsOn: LibFilters-3.0, will be ready then (loaded dependency before your addon was loaded)
--Initi the library and it's API
local libFilters = LibFilters3
libFilters:InitializeLibFilters()

local myAddonUniqueFilterTag = "MyAddonName_FilterForFilterType" .. tostring(LF_SMITHING_DECONSTRUCT)

--The filterFunction for the crafting table deconstruct, using bagId and slotIndex as parameter. Check documentation "Example filter functions" above to see which filterType uses which parameters for the filterFunctions
--This filterFunction checks if the items are bound and hides them then
local filterFuncForSmithingDeconstruction(bagId, slotIndex)
  local itemLink = GetItemLink(bagId, slotIndex)
  return IsItemLinkBound(itemLink)
end

--At any time the filter should not be applied anymore (e.g. as the crafting table LF_SMITHING_DECONSTRUCT hides) you need to unregister the filter again.
--LibFilters will keep all registered filterFuctions active until you manually unregister them! So make sure to register and unregister them properly if not needed anymore
--The library provides callbacks for the filterTypes to get noticed as the filterTypes are shown/hidden.
--The callback name is build by the library prefix "LibFilters3-" (constant provided is LibFilters3.globalLibName) followed by <yourAddonName> and another "-", followed by the state of the filterPanel as the callback fires (can be either the constant SCENE_SHOWN or SCENE_HIDDEN), followed by "-" and the suffix is the filterType constant
--of the panel.
--The library provides the API function libFilters:RegisterCallbackName(yourAddonName, filterType, isShown, inputType, universalDeconActiveTab, raiseBeforeOtherAddonsCallbackName) to generate the callback name for you. isShown is a boolean.
--if true SCENE_SHOWN will be used, if false SCENE_HIDDEN will be used.
--e.g. for LF_INVENTORY shown it would be
local callbackNameInvShown = libfilters:RegisterCallbackName("MyUniqueAddonName", LF_SMITHING_DECONSTRUCT, true)
--Makes: "LibFilters3-MyUniqueAddonName-shown-16"
local callbackNameInvHidden = libfilters:RegisterCallbackName("MyUniqueAddonName", LF_SMITHING_DECONSTRUCT, false)
--Makes: "LibFilters3-MyUniqueAddonName-hidden-16"


--The callbackFunction you register to it needs to provide the following parameters in the following order:
--callbackName, filterType, stateStr, isInGamepadMode, fragmentOrSceneOrControl, lReferencesToFilterType, universalDeconSelectedTabNow
--Your defined callback's unique name
--number filterType is the LF_* constant for the panel currently shown/hidden
--string stateStr will be SCENE_SHOWN ("shown") if shon or SCENE_HIDDEN ("hidden") if hidden callback was fired
--boolean isInGamepadMode is true if we are in Gamepad input mode and false if in keyboard mode
--refVar fragmentOrSceneOrControl is the frament/scene/control which was used to do the isShown/isHidden check
--table lReferencesToFilterType will contain additional reference variables used to do shown/hidden checks
--nilable:String universalDeconSelectedTabNow e.g. "all", "armor", "weapons", "jewelry" or "enchanting"

local function callbackFunctionForSmithingDeconstructionShown(callbackName, filterType, stateStr, isInGamepadMode, fragmentOrSceneOrControl, lReferencesToFilterType, universalDeconSelectedTabNow)
  --As LF_SMITHING_DECONSTRUCT could be re-used for UniversalDeconstruction exclude the uniersal decon panels here!
  --Check if the param universalDeconSelectedTabNow is nil, else it's a String containing the UniversalDecon currently selected tab!
  if universalDeconSelectedTabNow ~= nil then return end

  --Register your filterFunction here e.g. or do whatever is needed, like adding custom controls of your addon to the currently shown panel
  if not libFilters:IsFilterRegistered(myAddonUniqueFilterTag, LF_INVENTORY) then
    libFilters:RegisterFilter(myAddonUniqueFilterTag, LF_SMITHING_DECONSTRUCT, filterFuncForSmithingDeconstruction)
  end
end
local function callbackFunctionForSmithingDeconstructionHidden(callbackName, filterType, stateStr, isInGamepadMode, fragmentOrSceneOrControl, lReferencesToFilterType, universalDeconSelectedTabNow)
  --As LF_SMITHING_DECONSTRUCT could be re-used for UniversalDeconstruction exclude the uniersal decon panels here!
  --Check if the param universalDeconSelectedTabNow is nil, else it's a String containing the UniversalDecon currently selected tab!
  if universalDeconSelectedTabNow ~= nil then return end

  --Unregister your filterFunction here e.g. or do whatever is needed, e.g. hiding custom controls of your addon at the currently hidden panel
  libFilters:UnRegisterFilter(myAddonUniqueFilterTag, LF_SMITHING_DECONSTRUCT)
end

--Registering this callbackname in your addon is done via the CALLBACK_MANAGER
CALLBACK_MANAGER:RegisterCallback(callbackNameInvShown, callbackFunctionForSmithingDeconstructionShown)
CALLBACK_MANAGER:RegisterCallback(callbackNameInvHidden, callbackFunctionForSmithingDeconstructionHidden)
```

#### Use a callback for show/hide of UniversalDeconstruction panel ####
The following example will create callback functions that fire each time the UniversalDeconstruction panel (at keyboard mode!) will show or hide, or
as a tab at the UniversalDeconstruction panel changes (from "all" to "jewelry", or "jewelry" to "enchantments", etc.).
<br>
The parameter "LibFilters_OtherAddonName_shown_16_all" is an example how to raise your callback before a callback of another registered addon, using LibFilters callbacks, is raised. That oher addon's name is "OtherAddonName", it's the "OnShow" callback as you can see by the "shown" text of SCENE_SHOWN constant, 15 is LF_SMITHING_DECONSTRUCT which is used at UniversalDecon's "all" tab, and "all" is the UniversalDecon tab name active at that panel.<br>

Used within addon FCO CraftFilter:<br>
```lua
 local addonName = "FCOCraftFilter"


 --======== UNIVERSAL DECONSTRUCTION ===========================================================
    --[[
        callbackName,
        filterType,
        stateStr,
        isInGamepadMode,
        fragmentOrSceneOrControl,
        lReferencesToFilterType,
        universalDeconSelectedTabNow
    ]]
    local function libFiltersUniversalDeconShownOrHiddenCallback(isShown, callbackName, filterType, stateStr, isInGamepadMode, fragmentOrSceneOrControl, lReferencesToFilterType, universalDeconSelectedTabNow)
--d("[UNIVERSAL_DECONSTRUCTION - CALLBACK - " ..tos(callbackName) .. ", state: "..tos(stateStr) .. ", filterType: " ..tos(filterType) ..", isInGamepadMode: " ..tos(isInGamepadMode) .. ", universalDeconSelectedTabNow: " ..tos(universalDeconSelectedTabNow))
        FCOCraftFilter_CheckIfUniversalDeconIsShownAndAddButton(FCOCF_CRAFTINGTYPE_UNIVERSAL_DECONSTRUCTION, stateStr, universalDeconSelectedTabNow)
    end
    local callbackNameUniversalDeconDeconAllShown = libFilters:RegisterCallbackName(addonName, LF_SMITHING_DECONSTRUCT, true, nil, "all", "LibFilters_OtherAddonName_show_16_all")
    local callbackNameUniversalDeconDeconAllHidden = libFilters:RegisterCallbackName(addonName, LF_SMITHING_DECONSTRUCT, false, nil, "all")
    CM:RegisterCallback(callbackNameUniversalDeconDeconAllShown, function(...) libFiltersUniversalDeconShownOrHiddenCallback(true, ...) end)
    CM:RegisterCallback(callbackNameUniversalDeconDeconAllHidden, function(...) libFiltersUniversalDeconShownOrHiddenCallback(false, ...) end)
    local callbackNameUniversalDeconDeconArmorShown = libFilters:RegisterCallbackName(addonName, LF_SMITHING_DECONSTRUCT, true, nil, "armor")
    local callbackNameUniversalDeconDeconArmorHidden = libFilters:RegisterCallbackName(addonName, LF_SMITHING_DECONSTRUCT, false, nil, "armor")
    CM:RegisterCallback(callbackNameUniversalDeconDeconArmorShown, function(...) libFiltersUniversalDeconShownOrHiddenCallback(true, ...) end)
    CM:RegisterCallback(callbackNameUniversalDeconDeconArmorHidden, function(...) libFiltersUniversalDeconShownOrHiddenCallback(false, ...) end)
    local callbackNameUniversalDeconDeconWeaponsShown = libFilters:RegisterCallbackName(addonName, LF_SMITHING_DECONSTRUCT, true, nil, "weapons")
    local callbackNameUniversalDeconDeconWeaponsHidden = libFilters:RegisterCallbackName(addonName, LF_SMITHING_DECONSTRUCT, false, nil, "weapons")
    CM:RegisterCallback(callbackNameUniversalDeconDeconWeaponsShown, function(...) libFiltersUniversalDeconShownOrHiddenCallback(true, ...) end)
    CM:RegisterCallback(callbackNameUniversalDeconDeconWeaponsHidden, function(...) libFiltersUniversalDeconShownOrHiddenCallback(false, ...) end)
    local callbackNameUniversalDeconJewelryDeconShown = libFilters:RegisterCallbackName(addonName, LF_JEWELRY_DECONSTRUCT, true, nil, "jewelry")
    local callbackNameUniversalDeconJewelryDeconHidden = libFilters:RegisterCallbackName(addonName, LF_JEWELRY_DECONSTRUCT, false, nil, "jewelry")
    CM:RegisterCallback(callbackNameUniversalDeconJewelryDeconShown, function(...) libFiltersUniversalDeconShownOrHiddenCallback(true, ...) end)
    CM:RegisterCallback(callbackNameUniversalDeconJewelryDeconHidden, function(...) libFiltersUniversalDeconShownOrHiddenCallback(false, ...) end)
    local callbackNameUniversalDeconEnchantingShown = libFilters:RegisterCallbackName(addonName, LF_ENCHANTING_EXTRACTION, true, nil, "enchantments")
    local callbackNameUniversalDeconEnchantingHidden = libFilters:RegisterCallbackName(addonName, LF_ENCHANTING_EXTRACTION, false, nil, "enchantments")
    CM:RegisterCallback(callbackNameUniversalDeconEnchantingShown, function(...) libFiltersUniversalDeconShownOrHiddenCallback(true, ...) end)
    CM:RegisterCallback(callbackNameUniversalDeconEnchantingHidden, function(...) libFiltersUniversalDeconShownOrHiddenCallback(false, ...) end)
```
