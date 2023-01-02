# API functions of LibFilters

Last updated: 2023-01-02<br>
**The WIKI entries here might be outdated.**<br>
**!!!Please ALWAYS have a look at the file LibFilters-3.0/LibFilters-3.0.lua and search for!!!**<br>
```
-- BEGIN LibFilters API functions BEGIN
```
!!!Below that searched string you will find the API functions with the most up2date parameters and comments!!!<br>



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
--		   String universalDeconSelectedTabKey e.g. "all", "weapons", "armor", "jewelry", "enchantments" if the universal deconstruction panel is currently active
-->		 (which re-usess LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT and LF_ENCHANTING_EXTRACT)
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


##  Panel updaters (apply the registered filters/remove the unregistered filters)
Registered/Unregistered filters only apply to the panels/inventories/scenes/fragments/controls/userdata as you refresh/update them via their methods.<br>
LibFilters provides updater methods to do that for you, which you can manually call as you need them (e.g. via libFilters:RequestUpdate(LF*_filterTypeConstant).<br>


### Filter update / refresh of (inventory/crafting/...) list
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

### Filter update of specil panels
```lua
--Update the normal filters (LF_SMITHING_RESEARCH / LF_JEWELRY_RESEARCH) and the horizontal scrollbar filters
-- (fromResearcLineIndex, toResearchLineIndex, skipTable) for the crafting researchPanel
--OPTIONAL parameter number delay will add a delay to the call of the updater function
function libFilters:RequestUpdateForResearchFilters(delay)
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
--If the filterType passed in is a UniversalDeconstruction supported one, 2nd return parameter "universalDeconRef" will be a table with the reference varable to the UniversalDeconstruction panel
function libFilters:GetFilterTypeReferences(filterType, isInGamepadMode)


-- Get the actually shown reference control/scene/userdata/inventory number e.g. INVENTORY_BACKPACK information which is relevant for a libFilters LF_* filterType.
-- OPTIONAL parameter number filterType: If provided it will be used to determine the reference control/etc. directly via table LF_FilterTypeToCheckIfReferenceIsHiddenOrderAndCheckTypes[isInGamepadMode]
-- OPTIONAL parameter boolean isInGamepadMode: Check with gamepad mode or keyboard. Leave empty to let it be determined automatically
-- returns table currentlyShownReferenceVariablesOfLF_*filterType { [1] = control/scene/userdata/inventory number, [2] = control/scene/userdata/inventory number, ... },
--		   number filterType
--		   nilable:String universalDeconSelectedTabKey
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

--Check if the Universal Deconstruction panel is shown
--returns boolean isShown
--sceneReference UniversalDeconstructionScene (gamepad or keyboard mode)
function libFilters:IsUniversalDeconstructionPanelShown(isGamepadMode)
```

##  Horizontal scrollbar filters (at crafting tables like "Research")
```lua
--Register a filter by help of a researchLineIndex "skipTable" for a craftingType
--Parameter tyble skipTable contains key = researchLineIndex and value = boolean where "true" means: filter/skip (hide) this researchLineIndex at the horizontal scroll list.
--Parameter number fromResearchLineIndex sets the researchLineIndex to start the output of the horizontal scrollbar: It filters (hides) the possibe entries "in total".
--Parameter number toResearchLineIndex sets the researchLineIndex to stop the output of the horizontal scrollbar: It filters (hides) the possible entries "in total".
--Parameter boolean noInUseError: if set to true there will be no error message if the filterTag+filterType was registered already -> Silent fail. Return value will be false then!
--Returns true if filter table skipTable was registered, else nil in case of parameter errors, or false if same tag+type was already registered
--If different addons register skipTables for the same crafting type, these skipTables will be combined!
-->The combined entries of the skipTable are added, directly upon registering such filter, to they researchPanel table, with entry LibFilters3_HorizontalScrollbarFilters
-->You need to manually call libFilters:RequestUpdateForResearchFilters(delay) to update the horizontal scrollbar (and the normal research filters) via researchPanel:Refresh()
function libFilters:RegisterResearchHorizontalScrollbarFilter(filterTag, craftingType, skipTable, fromResearchLineIndex, toResearchLineIndex, noInUseError)


--Unregister a filter by help of a researchLineIndex "skipTable" for a craftingType, which will show the entries at the horizontal scroll list again.
--If different addons have registered skipTables for the same crafting type, these skipTables will be combined, and thus unregistering 1 filterTag might
--still have any other registered which hides the entry at the horizontal scrollbar
-->The combined entries of the skipTable are added, directly upon unregistering such filter, to they researchPanel table, with entry LibFilters3_HorizontalScrollbarFilters
-->You need to manually call libFilters:RequestUpdateForResearchFilters(delay) to update the horizontal scrollbar (and the normal research filters) via researchPanel:Refresh()
function libFilters:UnregisterResearchHorizontalScrollbarFilter(filterTag, craftingType)


--Use API function libFilters.ApplyCraftingResearchHorizontalScrollbarFilters(craftingType, noRefresh) to apply the combined
--skiptables to the researchPanel table LibFilters3_HorizontalScrollbarFilters
--Attention: This function will automatically call the Refresh function of the crafting refresh panel afterwards, unless you suppress it via parameter doNotRefresh!
--Important This function will be automatically called, without a panel resfresh, as the horizontal scrollbar filters get registered or unregistered, so you do not need to manually call it, in general!
--OPTIONAL parameter number craftingType: The crafting interaction type
--OPTIONAL parameter boolean doNotRefresh: true = do not call the refresh function of the panel. You can manually refresh the panel via function libFilters:RequestUpdateForResearchFilters(delay)

function libFilters.ApplyCraftingResearchHorizontalScrollbarFilters(craftingType, doNotRefresh)
```


##  Special API
```lua
--Check if the addon CraftBagExtended is enabled and if the craftbag is currently shown at a "non vanilla craftbag" filterType
--e.g. LF_MAIL_SEND, LF_TRADE, LF_GUILDSTORE_SELL, LF_GUILDBANK_DEPOSIT, LF_BANK_DEPOSIT, LF_HOUSE_BANK_DEPOSIT
--Will return boolean true if CBE is enabled and a supported parent filterType panelis shown. Else returns false
function libFilters:IsCraftBagExtendedParentFilterType(filterTypesToCheck)

--Is the vanillaUI CraftBag shown
--returns boolean isShown
function libFilters:IsVanillaCraftBagShown()

--Is any CraftBag shown, vanilla UI or CraftBagExtended
--returns boolean isShown
function libFilters:IsCraftBagShown()
```


## Callback API
```lua
--Create the callbackname for a libFilters filterPanel shown/hidden callback
----It will add an entry in table LibFilters3.mapping.callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType][isShown]
----number filterType needs to be a valid LF_* filterType constant
----boolean isShown true means SCENE_SHOWN will be used, and false means SCENE_HIDDEN will be used for the callbackname
----boolean inputType true = Gamepad, false= keyboard callback, leave empty for both!
----nilable:String universalDeconActiveTab The active tab at the universal deconstruction panel that this callback should be raised for, e.g. "all", "armor", "weapons", "jewelry" or "enchanting"
----nilable:String raiseBeforeOtherAddonsCallbackName If this callbackName (of another addon) is given the callback should be raised after this callback was raised. The callbackName provided here must match the
----> other parameters like filterType, isShown, inputType, universalDeconActiveTab!
----Returns String callbackNameGenerated
---->e.g. "LibFilters3-<yourAddonName>-shown-1" for SCENE_SHOWN and filterType LF_INVENTORY of addon <yourAddonName>
function libFilters:RegisterCallbackName(yourAddonName, filterType, isShown, inputType, universalDeconActiveTab, raiseBeforeOtherAddonsCallbackName)


--Remove an added callbackname for a libFilters filterPanel shown/hidden callback again
--It will remove the entry in table LibFilters3.mapping.callbacks.registeredCallbacks[inputType][yourAddonName][universalDeconActiveTab][filterType][isShown]
--number filterType needs to be a valid LF_* filterType constant
--boolean isShown true means SCENE_SHOWN will be used, and false means SCENE_HIDDEN will be used for the callbackname
--boolean inputType true = Gamepad, false= keyboard callback, leave empty for both!
--nilable:String universalDeconActiveTab The active tab at the universal deconstruction panel that this callback should be raised for, e.g. "all", "armor", "weapons", "jewelry" or "enchanting"
--Returns boolean wasRemoved true/false
function libFilters:UnregisterCallbackName(yourAddonName, filterType, isShown, inputType, universalDeconActiveTab)


```