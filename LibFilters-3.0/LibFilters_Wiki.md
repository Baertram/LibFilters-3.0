# LibFilters
**An Elder Scrolls Online library to filter your items at the different inventories**

Current version: 3, last updated: 2022-01-06

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

--The callbackFunction you register to it needs to provide the following parameters in the following order:
--number filterType is the LF_* constantfor the panel currently shown/hidden
--string stateStr will be SCENE_SHOWN ("shown") if shon or SCENE_HIDDEN ("hidden") if hidden callback was fired
--boolean isInGamepadMode is true if we are in Gamepad input mode and false if in keyboard mode
--refVar fragmentOrSceneOrControl is the frament/scene/control which was used to do the isShown/isHidden check
--table lReferencesToFilterType will contain additional reference variables used to do shown/hidden checks

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




----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
-- API
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

# API functions of LibFilters

## Filter types
```lua
--Returns number the minimum possible filteType
function libFilters:GetMinFilterType()


--Returns number the maximum possible filterType
function libFilters:GetMaxFilterType()

--Set the state of the LF_FILTER_ALL "fallback" filter possibilities.
--If boolean newState is enabled: function runFilters will also check for LF_FILTER_ALL filter functions and run them:
--If the filterType passed to runfilters function got no registered filterTags with filterFunctions, the LF_FILTER_ALL "fallback" will be checked (if existing and enabled via this API function) and be run!
--If boolean newState is disabled: function runFilters will NOT use LF_FILTER_ALL fallback functions
function libFilters:SetFilterAllState(newState)


--Returns table LibFilters LF* filterType connstants table { [1] = "LF_INVENTORY", [2] = "LF_BANK_WITHDRAW", ... }
--See file constants.lua, table "libFiltersFilterConstants"
function libFilters:GetFilterTypes()


--Returns String LibFilters LF* filterType constant's name for the number filterType
function libFilters:GetFilterTypeName(filterType)


--Returns number typeOfFilterFunction used for the number LibFilters LF* filterType constant.
--Either LIBFILTERS_FILTERFUNCTIONTYPE_INVENTORYSLOT or LIBFILTERS_FILTERFUNCTIONTYPE_BAGID_AND_SLOTINDEX
--or nil if error occured or no filter function type was determined
-- returns number filterFunctionType
function libFilters:GetFilterTypeFunctionType(filterType)


--Returns number the current libFilters filterType for the inventoryType, where inventoryType would be e.g.
--INVENTORY_BACKPACK, INVENTORY_BANK, ..., or a SCENE or a control given within table libFilters.mapping.
--LF_FilterTypeToReference[gamepadMode = true / or keyboardMode = false]
function libFilters:GetCurrentFilterTypeForInventory(inventoryType, noRefUpdate)


-- Get the actually used filterType via the shown control/scene/userdata information
-- returns number LF*_filterType
function libFilters:GetCurrentFilterType()


--Function to return the mapped LF_* constant of a crafting type, for a parameter number LF_* filterType constant.
--e.g. map LF_SMITHING_DECONSTRUCT to LF_JEWElRY_DECONSTRUCT if the current crafting type is CRAFT_TYPE_JEWELRY, else for
--other craftTypes it will stay at LF_SMITHING_DECONSTRUCT.
--OPTIONAL parameter number craftType can be passed in to overwrite the detected craftType (e.g. if you need the result
--filterType without being at a crafting table).
-- returns number LF*_filterType
function libFilters:GetFilterTypeRespectingCraftType(filterTypeSource, craftType)
```

## Filter check and un/register
```lua
--Check if a filterFunction at the String filterTag and OPTIONAL number filterType is already registered
--Returns boolean true if registered already, false if not
function libFilters:IsFilterRegistered(filterTag, filterType)


--Check if the LF_FILTER_ALL filterFunction at the String filterTag is already registered
--Returns boolean true if registered already, false if not
function libFilters:IsAllFilterRegistered(filterTag)


--Check if a filter function at the String filterTagPattern (uses LUA regex pattern!) and number filterType is already registered.
--Can be used to detect if any addon's tags have registered filters.
--OPTIONAL parameter boolean compareToLowerCase: If true the string comparison will be done with a lowerCase filterTag. The pattern will not be changed! Default: false
--Returns boolean true if registered already, false if not
function libFilters:IsFilterTagPatternRegistered(filterTagPattern, filterType, compareToLowerCase)


--Register a filter function at the String filterTag and number filterType.
--If filterType LF_FILTER_ALL is used this filterFunction will be used for all available filterTypes of the filterTag, where no other filterFunction was explicitly registered
--(as a kind of "fallback filter function").
--Registering a filter function does NOT automatically call the refresh/update function at the panel!
--You manually need to handle the update via libFilters:RequestUpdate(filterType) where needed
--Parameter boolean noInUseError: if set to true there will be no error message if the filterTag+filterType was registered already -> Silent fail. Return value will be false then!
--Returns true if filter function was registered, else nil in case of parameter errors, or false if same tag+type was already registered
function libFilters:RegisterFilter(filterTag, filterType, filterCallback, noInUseError)


--Check if a filter function at the String filterTag and number filterType is already registered, and if not: Register it. If it was already registered the return value will be false
--Registering a filter function does NOT automatically call the refresh/update function at the panel!
--You manually need to handle the update via libFilters:RequestUpdate(filterType) where needed
--Parameter boolean noInUseError: if set to true there will be no error message if the filterTag+filterType was registered already -> Silent fail. Return value will be false then!
--Returns true if filter function was registered, else nil in case of parameter errors, or false if same tag+type was already registered
function libFilters:RegisterFilterIfUnregistered(filterTag, filterType, filterCallback, noInUseError)


--Unregister a filter function at the String filterTag and OPTIONAL number filterType.
--If filterType is left empty you are able to unregister all filterTypes of the filterTag.
--LF_FILTER_ALL will be unregistered if filterType is left empty, or if explicitly specified!
--Unregistering a filter function does NOT automatically call the refresh/update function at the panel!
--You manually need to handle the update via libFilters:RequestUpdate(filterType) where needed
--Returns true if any filter function was unregistered
function libFilters:UnregisterFilter(filterTag, filterType)
```

## Filter callback functions
```lua
--Get the callback function of the String filterTag and number filterType
--Returns function filterCallbackFunction(inventorySlot_Or_BagIdAtCraftingTables, OPTIONAL slotIndexAtCraftingTables)
function libFilters:GetFilterCallback(filterTag, filterType)


--Get all callback function of the number filterType (of all addons which registered a filter)
--Returns nilable:table { 	[filterType_e.g._LF_INVENTORY] = { [filterTag1] = filterFunction1, [filterTag2] = filterFunction2, ... },
--				  			[filterType_e.g._LF_BANK_WITHDRAW] = { [filterTag3] = filterFunction3, [filterTag4] = filterFunction4, ... }, ... }
function libFilters:GetFilterTypeCallbacks(filterType)


--Get all callback functions of the String filterTag (e.g. all registered functions of one special addon) and OPTIONAL number filterType
--OPTIONAL parameter boolean compareToLowerCase: If true the string comparison will be done with a lowerCase filterTag. Default: false
--Returns nilable:table { 	[filterType_e.g._LF_INVENTORY] = { [filterTag1] = filterFunction1, [filterTag2] = filterFunction2, ... },
--				  			[filterType_e.g._LF_BANK_WITHDRAW] = { [filterTag3] = filterFunction3, [filterTag4] = filterFunction4, ... }, ... }
function libFilters:GetFilterTagCallbacks(filterTag, filterType, compareToLowerCase)


--Get the callback functions matching to the String filterTagPattern (uses LUA regex pattern!) and OPTIONAL number filterType
--OPTIONAL parameter boolean compareToLowerCase: If true the string comparison will be done with a lowerCase filterTag. The pattern will not be changed! Default: false
--Returns nilable:table { 	[filterType_e.g._LF_INVENTORY] = { [filterTag1] = filterFunction1, [filterTag2] = filterFunction2, ... },
--				  			[filterType_e.g._LF_BANK_WITHDRAW] = { [filterTag3] = filterFunction3, [filterTag4] = filterFunction4, ... }, ... }
function libFilters:GetFilterTagPatternCallbacks(filterTagPattern, filterType, compareToLowerCase)


## Filter update / refresh of (inventory/crafting/...) list
--Will call the updater function of number filterType, read from table "libFilters.mapping.inventoryUpdaters", depending
--on keyboard/gamepad mode.
--It will overwrite updaters of the same filterType which have been called within 10 milliseconds, so that they are not
--called multiple times shortly after another
--OPTIONAL parameter number delay will add a delay to the call of the updater function
--OPTIONAL parameter number filterType maybe needed for the updater function call. If it's missing it's tried to be determined
function libFilters:RequestUpdateByName(updaterName, delay, filterType)


--Will call the updater function of number filterType, read from table "libFilters.mapping.inventoryUpdaters", depending
--on keyboard/gamepad mode.
--It will overwrite updaters of the same filterType which have been called within 10 milliseconds, so that they are not
--called multiple times shortly after another
--OPTIONAL parameter number delay will add a delay to the call of the updater function
function libFilters:RequestUpdate(filterType, delay)


-- Get the updater name of a number filterType
-- returns String updateName
function libFilters:GetFilterTypeUpdaterName(filterType)


-- Get the updater filterTypes of a String updaterName
-- returns nilable:table filterTypesOfUpdaterName { [1] = LF_INVENTORY, [2] = LF_..., [3] = ... }
function libFilters:GetUpdaterNameFilterType(updaterName)


-- Get the updater keys and their functions used for updating/refresh of the inventories etc.
-- returns table { ["updater_name"] = function updaterFunction(OPTIONAL filterType), ... }
function libFilters:GetUpdaterCallbacks()


-- Get the updater function used for updating/refresh of the inventories etc., by help of a String updaterName
-- returns nilable:function updaterFunction(OPTIONAL filterType)
function libFilters:GetUpdaterCallback(updaterName)


-- Get the updater function used for updating/refresh of the inventories etc., by help of a number filterType
-- returns nilable:function updaterFunction(OPTIONAL filterType)
function libFilters:GetFilterTypeUpdaterCallback(filterType)
```

##  API to get library internal tables, variables and other constants
```lua
-- Get constants used within keyboard filter hooks etc.
-- returns table keyboardConstants
function libFilters:GetKeyboardConstants()


-- Get constants used within gamepad filter hooks etc.
-- returns table gamepadConstants
function libFilters:GetGamepadConstants()


-- Get the LibFilters logger reference
-- returns table logger
function libFilters:GetLogger()


-- Get the LibFilters helpers table
-- returns table helpers
function libFilters:GetHelpers()
```

## API to get reference (controls/scenes/fragments/userdata/inventories) which contain the libFilters filterType
```lua
-- Get reference (inventory, layoutData, scene, fragment, control, etc.) where the number filterType was assigned to, and
--it's filterFunction was added to the constant "defaultOriginalFilterAttributeAtLayoutData" (.additionalFilter)
-- returns table referenceVariablesOfLF_*filterType { [NumericalNonGapIndex e.g.1] = inventory/layoutData/scene/control/userdata/etc., [2] = inventory/layoutData/scene/control/userdata/etc., ... }
function libFilters:GetFilterTypeReferences(filterType, isInGamepadMode)


-- Get the actually shown reference control/scene/userdata/inventory number e.g. INVENTORY_BACKPACK information which is relevant for a libFilters LF_* filterType.
-- OPTIONAL parameter number filterType: If provided it will be used to determine the reference control/etc. directly via table LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[isInGamepadMode]
-- OPTIONAL parameter boolean isInGamepadMode: Check with gamepad mode or keyboard. Leave empty to let it be determined automatically
-- returns table currentlyShownReferenceVariablesOfLF_*filterType { [1] = control/scene/userdata/inventory number, [2] = control/scene/userdata/inventory number, ... },
--		   number filterType
function libFilters:GetCurrentFilterTypeReference(filterType, isInGamepadMode)
```

##  API to check if controls/scenes/fragments/userdata/inventories are shown
```lua
--Is the inventory control shown
--returns boolean isShown
--NILABLE control gamepadList (category or item list of the gamepad inventory, which is currently shown)
function libFilters:IsInventoryShown()


--Is the companion inventory control shown
--returns boolean isShown
function libFilters:IsCompanionInventoryShown()

--Is the character control shown
--returns boolean isShown
function libFilters:IsCharacterShown()


--Is the companion character control shown
--returns boolean isShown
function libFilters:IsCompanionCharacterShown()


--Is the bank shown
--returns boolean isShown
function libFilters:IsBankShown()


--Is the guild bank shown
--returns boolean isShown
function libFilters:IsGuildBankShown()


--Is the house bank shown
--returns boolean isShown
function libFilters:IsHouseBankShown()


--Check if the store (vendor) panel is shown
--If OPTIONAL parameter number storeMode (either ZO_MODE_STORE_BUY, ZO_MODE_STORE_BUY_BACK, ZO_MODE_STORE_SELL,
--ZO_MODE_STORE_REPAIR, ZO_MODE_STORE_SELL_STOLEN, ZO_MODE_STORE_LAUNDER, ZO_MODE_STORE_STABLE) is provided the store
--mode mode must be set at the store panel, if it is shown, to return true
--return boolean isShown, number storeMode, userdata/control/scene/fragment whatHasBeenDetectedToBeShown
function libFilters:IsStoreShown(storeMode)


--Is a list dialog currently shown?
--OPTIONAL parameter number filterType to detect the owner control which's hidden state will be checked
--OPTIONAL parameter userdata/control dialogOwnerControlToCheck which's hidden state will be checked
--Any of the 2 parameters needs to be passed in
--returns boolean isListDialogShown
function libFilters:IsListDialogShown(filterType, dialogOwnerControlToCheck)


--Is the retrait station curently shown
--returns boolean isRetraitStation
function libFilters:IsRetraitStationShown()


--Is any crafting  station curently shown
--OPTIONAL parameter number craftType: If provided the shown state of the crafting table connected to the craftType will
--be checked and returned
--returns boolean isCraftingStationShown
function libFilters:IsCraftingStationShown(craftType)


--Is the currnt crafting type jewelry?
--return boolean isJewerlyCrafting
function libFilters:IsJewelryCrafting()


--Check if the Enchanting panel is shown.
--If OPTIONAL parameter number enchantingMode (either ENCHANTING_MODE_CREATION, ENCHANTING_MODE_EXTRACTION or
-- ENCHANTING_MODE_RECIPES) is provided this enchanting mode must be set at the enchanting panel, if it is shown, to return
-- true
--return boolean isShown, number enchantingMode, userdata/control/scene/fragment whatHasBeenDetectedToBeShown
function libFilters:IsEnchantingShown(enchantingMode)


--Check if the Alchemy panel is shown
--If OPTIONAL parameter number alchemyMode (either ZO_ALCHEMY_MODE_CREATION, ZO_ALCHEMY_MODE_RECIPES is provided this
-- alchemy mode must be set at the alchemy panel, if it is shown, to return true
--return boolean isShown, number alchemyMode, userdata/control/scene/fragment whatHasBeenDetectedToBeShown
function libFilters:IsAlchemyShown(alchemyMode)
```

##  Special API
```lua
--Will set the keyboard research panel's indices "from" and "to" to filter the items which do not match to the selected
--indices
--Used in addon AdvancedFilters UPDATED e.g. to filter the research panel LF_SMITHING_RESEARCH/LF_JEWELRY_RESEARCH in
--keyboard mode
function libFilters:SetResearchLineLoopValues(fromResearchLineIndex, toResearchLineIndex, skipTable)


--Check if the addon CraftBagExtended is enabled and if the craftbag is currently shown at a "non vanilla craftbag" filterType
--e.g. LF_MAIL_SEND, LF_TRADE, LF_GUILDSTORE_SELL, LF_GUILDBANK_DEPOSIT, LF_BANK_DEPOSIT, LF_HOUSE_BANK_DEPOSIT
--Will return boolean true if CBE is enabled and a supported parent filterType panelis shown. Else returns false
function libFilters:IsCraftBagExtendedParentFilterType(filterTypesToCheck)
```

## Callback API
```lua
--Create the callbackname for a libFilters filterPanel shown/hidden callback
--number filterType needs to be a valid LF_* filterType constant
--boolean isShown true means SCENE_SHOWn will be used, and false means SCENE_HIDDEN will be used for the callbackname
--Returns String callbackNameGenerated
function libFilters:CreateCallbackName(filterType, isShown)
```
