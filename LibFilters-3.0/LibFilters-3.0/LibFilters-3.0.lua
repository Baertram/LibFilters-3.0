local MAJOR, GlobalLibName, MINOR = "LibFilters-3.0", "LibFilters3", 1.7

--Was the library loaded already?
if _G[GlobalLibName] ~= nil then return end

--Local library variable
local LibFilters = {}

--Global library constant
_G[GlobalLibName]   = LibFilters
LibFilters.name     = MAJOR
LibFilters.version  = MINOR

--Other libraries

--LibDebugLogger
if LibDebugLogger then
    if not not LibFilters.logger then
        LibFilters.logger = LibDebugLogger(MAJOR)
    end
end
local logger = LibFilters.logger

--The possible LibFilters filterPanelIds
LF_INVENTORY                = 1
LF_BANK_WITHDRAW            = 2
LF_BANK_DEPOSIT             = 3
LF_GUILDBANK_WITHDRAW       = 4
LF_GUILDBANK_DEPOSIT        = 5
LF_VENDOR_BUY               = 6
LF_VENDOR_SELL              = 7
LF_VENDOR_BUYBACK           = 8
LF_VENDOR_REPAIR            = 9
LF_GUILDSTORE_BROWSE        = 10
LF_GUILDSTORE_SELL          = 11
LF_MAIL_SEND                = 12
LF_TRADE                    = 13
LF_SMITHING_REFINE          = 14
LF_SMITHING_CREATION        = 15
LF_SMITHING_DECONSTRUCT     = 16
LF_SMITHING_IMPROVEMENT     = 17
LF_SMITHING_RESEARCH        = 18
LF_ALCHEMY_CREATION         = 19
LF_ENCHANTING_CREATION      = 20
LF_ENCHANTING_EXTRACTION    = 21
LF_PROVISIONING_COOK        = 22
LF_PROVISIONING_BREW        = 23
LF_FENCE_SELL               = 24
LF_FENCE_LAUNDER            = 25
LF_CRAFTBAG                 = 26
LF_QUICKSLOT                = 27
LF_RETRAIT                  = 28
LF_HOUSE_BANK_WITHDRAW      = 29
LF_HOUSE_BANK_DEPOSIT       = 30
LF_JEWELRY_REFINE           = 31
LF_JEWELRY_CREATION         = 32
LF_JEWELRY_DECONSTRUCT      = 33
LF_JEWELRY_IMPROVEMENT      = 34
LF_JEWELRY_RESEARCH         = 35
LF_SMITHING_RESEARCH_DIALOG = 36
LF_JEWELRY_RESEARCH_DIALOG  = 37
LF_INVENTORY_QUEST          = 38

--Get the min and max filterPanelIds
LF_FILTER_MIN               = LF_INVENTORY
LF_FILTER_MAX               = LF_INVENTORY_QUEST

--Returns the minimum possible filterPanelId
function LibFilters:GetMinFilter()
    return LF_FILTER_MIN
end

--Returns the maxium possible filterPanelId
function LibFilters:GetMaxFilter()
    return LF_FILTER_MAX
end

LibFilters.isInitialized = false

--The filters of the different FilterPanelIds will be registered to these sub-tables
LibFilters.filters = {
    [LF_INVENTORY] = {},
    [LF_BANK_WITHDRAW] = {},
    [LF_BANK_DEPOSIT] = {},
    [LF_GUILDBANK_WITHDRAW] = {},
    [LF_GUILDBANK_DEPOSIT] = {},
    [LF_VENDOR_BUY] = {},
    [LF_VENDOR_SELL] = {},
    [LF_VENDOR_BUYBACK] = {},
    [LF_VENDOR_REPAIR] = {},
    [LF_GUILDSTORE_BROWSE] = {},
    [LF_GUILDSTORE_SELL] = {},
    [LF_MAIL_SEND] = {},
    [LF_TRADE] = {},
    [LF_SMITHING_REFINE] = {},
    [LF_SMITHING_CREATION] = {},
    [LF_SMITHING_DECONSTRUCT] = {},
    [LF_SMITHING_IMPROVEMENT] = {},
    [LF_SMITHING_RESEARCH] = {},
    [LF_ALCHEMY_CREATION] = {},
    [LF_ENCHANTING_CREATION] = {},
    [LF_ENCHANTING_EXTRACTION] = {},
    [LF_PROVISIONING_COOK] = {},
    [LF_PROVISIONING_BREW] = {},
    [LF_FENCE_SELL] = {},
    [LF_FENCE_LAUNDER] = {},
    [LF_CRAFTBAG] = {},
    [LF_QUICKSLOT] = {},
    [LF_RETRAIT] = {},
    [LF_HOUSE_BANK_WITHDRAW] = {},
    [LF_HOUSE_BANK_DEPOSIT] = {},
    [LF_JEWELRY_REFINE]      = {},
    [LF_JEWELRY_CREATION]    = {},
    [LF_JEWELRY_DECONSTRUCT] = {},
    [LF_JEWELRY_IMPROVEMENT] = {},
    [LF_JEWELRY_RESEARCH]    = {},
    [LF_SMITHING_RESEARCH_DIALOG] = {},
    [LF_JEWELRY_RESEARCH_DIALOG] = {},
    [LF_INVENTORY_QUEST] = {},
}
local filters = LibFilters.filters

--The fixed updater names for the LibFilters unique updater string
local filterTypeToUpdaterNameFixed = {
    [LF_BANK_WITHDRAW]              = "BANK_WITHDRAW",
    [LF_GUILDBANK_WITHDRAW]         = "GUILDBANK_WITHDRAW",
    [LF_VENDOR_BUY]                 = "VENDOR_BUY",
    [LF_VENDOR_BUYBACK]             = "VENDOR_BUYBACK",
    [LF_VENDOR_REPAIR]              = "VENDOR_REPAIR",
    [LF_GUILDSTORE_BROWSE]          = "GUILDSTORE_BROWSE",
    [LF_ALCHEMY_CREATION]           = "ALCHEMY_CREATION",
    [LF_PROVISIONING_COOK]          = "PROVISIONING_COOK",
    [LF_PROVISIONING_BREW]          = "PROVISIONING_BREW",
    [LF_CRAFTBAG]                   = "CRAFTBAG",
    [LF_QUICKSLOT]                  = "QUICKSLOT",
    [LF_RETRAIT]                    = "RETRAIT",
    [LF_HOUSE_BANK_WITHDRAW]        = "HOUSE_BANK_WITHDRAW",
    [LF_INVENTORY_QUEST]            = "INVENTORY_QUEST"
}
--The updater names which are shared with others
local filterTypeToUpdaterNameDynamic = {
    ["INVENTORY"] = {
        [LF_INVENTORY]=true,
        [LF_BANK_DEPOSIT]=true,
        [LF_GUILDBANK_DEPOSIT]=true,
        [LF_VENDOR_SELL]=true,
        [LF_GUILDSTORE_SELL]=true,
        [LF_MAIL_SEND]=true,
        [LF_TRADE]=true,
        [LF_FENCE_SELL]=true,
        [LF_FENCE_LAUNDER]=true,
        [LF_HOUSE_BANK_DEPOSIT]=true,
    },
    ["SMITHING_REFINE"] = {
        [LF_SMITHING_REFINE]=true,
        [LF_JEWELRY_REFINE]=true,
    },
    ["SMITHING_CREATION"] = {
        [LF_SMITHING_CREATION]=true,
        [LF_JEWELRY_CREATION]=true,
    },
    ["SMITHING_DECONSTRUCT"] = {
        [LF_SMITHING_DECONSTRUCT]=true,
        [LF_JEWELRY_DECONSTRUCT]=true,
    },
    ["SMITHING_IMPROVEMENT"] = {
        [LF_SMITHING_IMPROVEMENT]=true,
        [LF_JEWELRY_IMPROVEMENT]=true,
    },
    ["SMITHING_RESEARCH"] = {
        [LF_SMITHING_RESEARCH]=true,
        [LF_JEWELRY_RESEARCH]=true,
    },
    ["SMITHING_RESEARCH_DIALOG"] = {
        [LF_SMITHING_RESEARCH_DIALOG]=true,
        [LF_JEWELRY_RESEARCH_DIALOG]=true,
    },
    ["ENCHANTING"] = {
        [LF_ENCHANTING_CREATION]=true,
        [LF_ENCHANTING_EXTRACTION]=true,
    },
}
--The filterType to unique updater String table. Will be filled with the fixed updater names and the dynamic afterwards
local filterTypeToUpdaterName = {}
--Add the fixed updaterNames of the filtertypes
filterTypeToUpdaterName = filterTypeToUpdaterNameFixed
--Then dynamically add the other updaterNames from the above table filterTypeToUpdaterNameDynamic
for updaterName, filterTypesTableForUpdater in pairs(filterTypeToUpdaterNameDynamic) do
    if updaterName ~= "" then
        for filterType, isEnabled in pairs(filterTypesTableForUpdater) do
            if isEnabled then
                filterTypeToUpdaterName[filterType] = updaterName
            end
        end
    end
end
LibFilters.filterTypeToUpdaterName = filterTypeToUpdaterName

--Update the inventory lists
--if the mouse is enabled, cycle its state to refresh the integrity of the control beneath it
local function SafeUpdateList(object, ...)
--d("[LibFilters3]SafeUpdateList, inv: " ..tostring(...))
    local isMouseVisible = SCENE_MANAGER:IsInUIMode()

    if isMouseVisible then HideMouse() end

    object:UpdateList(...)

    if isMouseVisible then ShowMouse() end
end

--Function to update a ZO_ListDialog1 dialog's list contents
local function dialogUpdaterFunc(listDialogControl)
    if listDialogControl == nil then return nil end
    --Get & Refresh the list dialog
    local listDialog = ZO_InventorySlot_GetItemListDialog()
    if listDialog ~= nil and listDialog.control ~= nil then
        local data = listDialog.control.data
        if not data then return end
        --Update the research dialog?
        if listDialogControl == SMITHING_RESEARCH_SELECT then
            if data.craftingType and data.researchLineIndex and data.traitIndex then
                --Re-Call the dialog's setup function to clear the list, check available data and filter the items (see helper.lua, helpers["SMITHING_RESEARCH_SELECT"])
                listDialogControl.SetupDialog(listDialogControl, data.craftingType, data.researchLineIndex, data.traitIndex)
            end
        end
    end
end

--Some inventory variables
local inventories =         PLAYER_INVENTORY.inventories
--Some crafting variables
local refinementPanel =     SMITHING.refinementPanel
local deconstructionPanel = SMITHING.deconstructionPanel
local improvementPanel =    SMITHING.improvementPanel
local researchPanel =       SMITHING.researchPanel

--The updater functions for the inventories
local inventoryUpdaters = {
    INVENTORY = function()
        SafeUpdateList(PLAYER_INVENTORY, INVENTORY_BACKPACK)
    end,
    BANK_WITHDRAW = function()
        SafeUpdateList(PLAYER_INVENTORY, INVENTORY_BANK)
    end,
    GUILDBANK_WITHDRAW = function()
        SafeUpdateList(PLAYER_INVENTORY, INVENTORY_GUILD_BANK)
    end,
    VENDOR_BUY = function()
        if BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT.state ~= SCENE_SHOWN then --"shown"
            STORE_WINDOW:GetStoreItems()
            SafeUpdateList(STORE_WINDOW)
        end
    end,
    VENDOR_BUYBACK = function()
        SafeUpdateList(BUY_BACK_WINDOW)
    end,
    VENDOR_REPAIR = function()
        SafeUpdateList(REPAIR_WINDOW)
    end,
    GUILDSTORE_BROWSE = function()
    end,
    SMITHING_REFINE = function()
        refinementPanel.inventory:HandleDirtyEvent()
    end,
    SMITHING_CREATION = function()
    end,
    SMITHING_DECONSTRUCT = function()
        deconstructionPanel.inventory:HandleDirtyEvent()
    end,
    SMITHING_IMPROVEMENT = function()
        improvementPanel.inventory:HandleDirtyEvent()
    end,
    SMITHING_RESEARCH = function()
        researchPanel:Refresh()
    end,
    ALCHEMY_CREATION = function()
        ALCHEMY.inventory:HandleDirtyEvent()
    end,
    ENCHANTING = function()
        ENCHANTING.inventory:HandleDirtyEvent()
    end,
    PROVISIONING_COOK = function()
    end,
    PROVISIONING_BREW = function()
    end,
    CRAFTBAG = function()
        SafeUpdateList(PLAYER_INVENTORY, INVENTORY_CRAFT_BAG)
    end,
    QUICKSLOT = function()
        SafeUpdateList(QUICKSLOT_WINDOW)
    end,
    RETRAIT = function()
        ZO_RETRAIT_KEYBOARD.inventory:HandleDirtyEvent()
    end,
    HOUSE_BANK_WITHDRAW = function()
        SafeUpdateList(PLAYER_INVENTORY, INVENTORY_HOUSE_BANK )
    end,
    SMITHING_RESEARCH_DIALOG = function()
        dialogUpdaterFunc(SMITHING_RESEARCH_SELECT)
    end,
    RECONSTRUCTION = function()
        ZO_RECONSTRUCT_KEYBOARD.inventory:HandleDirtyEvent()
    end,
    INVENTORY_QUEST = function()
        SafeUpdateList(PLAYER_INVENTORY, INVENTORY_QUEST_ITEM)
    end,
}
LibFilters.inventoryUpdaters = inventoryUpdaters


--Debugging output
local function debugMessage(text, textType)
    if not text or text == "" then return end
    textType = textType or 'I'
    if logger ~= nil then
        if textType == 'D' then
            logger:Debug(text)
        elseif textType == 'E' then
            logger:Error(text)
        elseif textType == 'I' then
            logger:Info(text)
        elseif textType == 'V' then
            logger:Verbose(text)
        elseif textType == 'W' then
            logger:Warn(text)
        end
    else
        local textTypeToPrefix = {
            ["D"] = "Debug",
            ["E"] = "Error",
            ["I"] = "Info",
            ["V"] = "Verbose",
            ["W"] = "Warning",
        }
        d("[".. MAJOR .."]" .. tostring(textTypeToPrefix[textType]) .. ": ".. tostring(text))
    end
end

--Information debug
local function df(...)
    debugMessage(string.format(...), 'I')
end
--Error debug
local function dfe(...)
    debugMessage(string.format(...), 'E')
end

--Run the applied filters at a LibFilters filterType (LF_*) now, using the ... parameters (e.g. inventorySlot)
local function runFilters(filterType, ...)
--d("[LibFilters3]runFilters, filterType: " ..tostring(filterType))
    for tag, filter in pairs(filters[filterType]) do
        if not filter(...) then
            return false
        end
    end
    return true
end
LibFilters.RunFilters = runFilters

--Hook all the filters at the different inventory panels (LibFilters filterPanelIds) now
local function HookAdditionalFilters()
    LibFilters:HookAdditionalFilter(LF_INVENTORY, inventories[INVENTORY_BACKPACK])
    LibFilters:HookAdditionalFilter(LF_INVENTORY, BACKPACK_MENU_BAR_LAYOUT_FRAGMENT)

    LibFilters:HookAdditionalFilter(LF_BANK_WITHDRAW, inventories[INVENTORY_BANK])
    LibFilters:HookAdditionalFilter(LF_BANK_DEPOSIT, BACKPACK_BANK_LAYOUT_FRAGMENT)

    LibFilters:HookAdditionalFilter(LF_GUILDBANK_WITHDRAW, inventories[INVENTORY_GUILD_BANK])
    LibFilters:HookAdditionalFilter(LF_GUILDBANK_DEPOSIT, BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT)

    LibFilters:HookAdditionalFilter(LF_VENDOR_BUY, STORE_WINDOW)
    LibFilters:HookAdditionalFilter(LF_VENDOR_SELL, BACKPACK_STORE_LAYOUT_FRAGMENT)
    LibFilters:HookAdditionalFilter(LF_VENDOR_BUYBACK, BUY_BACK_WINDOW)
    LibFilters:HookAdditionalFilter(LF_VENDOR_REPAIR, REPAIR_WINDOW)

    --LibFilters:HookAdditionalFilter(LF_GUILDSTORE_BROWSE, )
    LibFilters:HookAdditionalFilter(LF_GUILDSTORE_SELL, BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT)

    LibFilters:HookAdditionalFilter(LF_MAIL_SEND, BACKPACK_MAIL_LAYOUT_FRAGMENT)

    LibFilters:HookAdditionalFilter(LF_TRADE, BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT)

    LibFilters:HookAdditionalFilter(LF_SMITHING_REFINE, refinementPanel.inventory)
    --LibFilters:HookAdditionalFilter(LF_SMITHING_CREATION, )
    LibFilters:HookAdditionalFilter(LF_SMITHING_DECONSTRUCT, deconstructionPanel.inventory)
    LibFilters:HookAdditionalFilter(LF_SMITHING_IMPROVEMENT, improvementPanel.inventory)
    LibFilters:HookAdditionalFilter(LF_SMITHING_RESEARCH, researchPanel)
    LibFilters:HookAdditionalFilter(LF_JEWELRY_REFINE, refinementPanel.inventory)
    --LibFilters:HookAdditionalFilter(LF_JEWELRY_CREATION, )
    LibFilters:HookAdditionalFilter(LF_JEWELRY_DECONSTRUCT, deconstructionPanel.inventory)
    LibFilters:HookAdditionalFilter(LF_JEWELRY_IMPROVEMENT, improvementPanel.inventory)
    LibFilters:HookAdditionalFilter(LF_JEWELRY_RESEARCH, researchPanel)

    LibFilters:HookAdditionalFilter(LF_ALCHEMY_CREATION, ALCHEMY.inventory)

    LibFilters:HookAdditionalFilter(LF_ENCHANTING_CREATION, ENCHANTING.inventory)
    LibFilters:HookAdditionalFilter(LF_ENCHANTING_EXTRACTION, ENCHANTING.inventory)

    --LibFilters:HookAdditionalFilter(LF_PROVISIONING_COOK, )
    --LibFilters:HookAdditionalFilter(LF_PROVISIONING_BREW, )

    LibFilters:HookAdditionalFilter(LF_FENCE_SELL, BACKPACK_FENCE_LAYOUT_FRAGMENT)
    LibFilters:HookAdditionalFilter(LF_FENCE_LAUNDER, BACKPACK_LAUNDER_LAYOUT_FRAGMENT)

    LibFilters:HookAdditionalFilter(LF_CRAFTBAG, inventories[INVENTORY_CRAFT_BAG])

    LibFilters:HookAdditionalFilter(LF_QUICKSLOT, QUICKSLOT_WINDOW)

    LibFilters:HookAdditionalFilter(LF_RETRAIT, ZO_RETRAIT_KEYBOARD)

    LibFilters:HookAdditionalFilter(LF_HOUSE_BANK_WITHDRAW, inventories[INVENTORY_HOUSE_BANK])
    LibFilters:HookAdditionalFilter(LF_HOUSE_BANK_DEPOSIT, BACKPACK_HOUSE_BANK_LAYOUT_FRAGMENT)

    LibFilters:HookAdditionalFilter(LF_SMITHING_RESEARCH_DIALOG, SMITHING_RESEARCH_SELECT)
    LibFilters:HookAdditionalFilter(LF_JEWELRY_RESEARCH_DIALOG, SMITHING_RESEARCH_SELECT)

    LibFilters:HookAdditionalFilter(LF_INVENTORY_QUEST, inventories[INVENTORY_QUEST_ITEM])
end

--**********************************************************************************************************************
--Hook the inventory layout or inventory to apply additional filter functions
function LibFilters:HookAdditionalFilter(filterType, inventory)
    local layoutData = inventory.layoutData or inventory
    local originalFilter = layoutData.additionalFilter

    layoutData.LibFilters3_filterType = filterType
    local additionalFilterType = type(originalFilter)
    if additionalFilterType == "function" then
        layoutData.additionalFilter = function(...)
            return originalFilter(...) and runFilters(filterType, ...)
        end
    else
        layoutData.additionalFilter = function(...)
            return runFilters(filterType, ...)
        end
    end
end

--Get the current Libfilters filterType for the inventoryType, where inventoryType would be e.g. INVENTORY_BACKPACK or
--INVENTORY_BANK
function LibFilters:GetCurrentFilterTypeForInventory(inventoryType)
    if inventoryType == INVENTORY_BACKPACK then
        local layoutData = PLAYER_INVENTORY.appliedLayout
        if layoutData and layoutData.LibFilters3_filterType then
            return layoutData.LibFilters3_filterType
        else
            return
        end
    end
    local inventory = inventories[inventoryType]
    if not inventory or not inventory.LibFilters3_filterType then return end
    return inventory.LibFilters3_filterType
end

function LibFilters:GetFilterCallback(filterTag, filterType)
    if not self:IsFilterRegistered(filterTag, filterType) then return end

    return filters[filterType][filterTag]
end

function LibFilters:IsFilterRegistered(filterTag, filterType)
    if filterType == nil then
        --check whether there's any filter with this tag
        for _, callbacks in pairs(filters) do
            if callbacks[filterTag] ~= nil then
                return true
            end
        end

        return false
    else
        --check only the specified filter type
        local callbacks = filters[filterType]

        return callbacks[filterTag] ~= nil
    end
end

function LibFilters:RegisterFilter(filterTag, filterType, filterCallback)
    local callbacks = filters[filterType]

    if not filterTag or not callbacks or type(filterCallback) ~= "function" then
        dfe("Invalid arguments to RegisterFilter(%q, %s, %s).\n>Needed format is: String uniqueFilterTag, number LibFiltersLF_*FilterPanelConstant, function filterCallbackFunction",
            tostring(filterTag), tostring(filterType), tostring(filterCallback))
        return
    end

    if callbacks[filterTag] ~= nil then
        dfe("filterTag \'%q\' filterType \'%s\' filterCallback function is already in use",
            tostring(filterTag), tostring(filterType))
        return
    end

    callbacks[filterTag] = filterCallback
end

function LibFilters:RequestUpdate(filterType)
--d("[LibFilters3]RequestUpdate-filterType: " ..tostring(filterType))
    local updaterName = filterTypeToUpdaterName[filterType]
    if not updaterName or updaterName == "" then
        dfe("Invalid arguments to RequestUpdate(%s).\n>Needed format is: number filterPanelId", tostring(filterType))
        return
    end
    local callbackName = "LibFilters_updateInventory_" .. updaterName
    local function Update()
--d(">[LibFilters3]RequestUpdate->Update called")
        EVENT_MANAGER:UnregisterForUpdate(callbackName)
        inventoryUpdaters[updaterName]()
    end

    --cancel previously scheduled update if any
    EVENT_MANAGER:UnregisterForUpdate(callbackName)
    --register a new one
    EVENT_MANAGER:RegisterForUpdate(callbackName, 10, Update)
end

function LibFilters:UnregisterFilter(filterTag, filterType)
    if not filterTag or filterTag == "" then
        dfe("Invalid arguments to UnregisterFilter(%s, %s).\n>Needed format is: String filterTag, number filterPanelId", tostring(filterTag), tostring(filterType))
        return
    end
    if filterType == nil then
        --unregister all filters with this tag
        for _, callbacks in pairs(filters) do
            if callbacks[filterTag] ~= nil then
                callbacks[filterTag] = nil
            end
        end
    else
        --unregister only the specified filter type
        local callbacks = filters[filterType]

        if callbacks[filterTag] ~= nil then
            callbacks[filterTag] = nil
        end
    end
end

function LibFilters:SetResearchLineLoopValues(fromResearchLineIndex, toResearchLineIndex, skipTable)
    local craftingType = GetCraftingInteractionType()
    if craftingType == CRAFTING_TYPE_INVALID then return false end
    if not fromResearchLineIndex or fromResearchLineIndex <= 0 then fromResearchLineIndex = 1 end
    if not toResearchLineIndex or toResearchLineIndex > GetNumSmithingResearchLines(craftingType) then
        toResearchLineIndex = GetNumSmithingResearchLines(craftingType)
    end
    local helpers = LibFilters.helpers
    if not helpers then return end
    local smithingResearchPanel = helpers["SMITHING.researchPanel:Refresh"].locations[1]
    if smithingResearchPanel then
        smithingResearchPanel.LibFilters_3ResearchLineLoopValues = {
            from        =fromResearchLineIndex,
            to          =toResearchLineIndex,
            skipTable   =skipTable,
        }
    end
end


--**********************************************************************************************************************
--Register all the helper functions of LibFilters, for some special panels like the Research or ResearchDialog, or
--even deconstruction and improvement, etc.
--These helper funmctions might overwrite original ESO functions in order to use their own "predicate" or
-- "filterFunction".  So check them if the orig functions update, and upate them as well.
--> See file helper.lua
LibFilters.helpers = {}
local helpers = LibFilters.helpers

--Install the helpers from table helpers now -> See file helper.lua, table "helpers"
local function InstallHelpers()
    for _, package in pairs(helpers) do
        local funcName = package.helper.funcName
        local func = package.helper.func

        for _, location in pairs(package.locations) do
            --e.g. ZO_SmithingExtractionInventory["GetIndividualInventorySlotsAndAddToScrollData"] = overwritten
            --function from helpers table, param "func"
            location[funcName] = func
        end
    end
end

--**********************************************************************************************************************
--**********************************************************************************************************************
--**********************************************************************************************************************

--Function needed to be called from your addon to start the LibFilters instance and enable the filtering!
function LibFilters:InitializeLibFilters()
    if self.isInitialized then return end
    self.isInitialized = true

    InstallHelpers()
    HookAdditionalFilters()
end
