--[LibFilters] Main version: 3
--Created by: ingeniousclown - 2014 (LibFilters 1)
--Contributors: Baertram, Randactly, Votan, sirinsidiator, Scootworks
--Current maintainer: Baertram (since 2018-02)

--This library is used to filter inventory items (show/hide) at the different panels/inventories -> Libfilters uses the
--term "filterType" for the different filter panels. Each filterType is representey by the help of a constant starting
--with LF_<panelName> (e.g. LF_INVENTOR, LF_BANK_WITHDRAW), which is used to add filterFunctions of different addons
--to this inventory. See table libFiltersFilterConstants for the value = "filterPanel name" constants.
--
--The registered filterFunctions will run as the inventories are refreshed/updated, either by internal update routines as
--the inventory's "dirty" flag was set to true. Or via function SafeUpdateList (see below), or via some other update/refresh/
--ShouldAddItemToSlot function (sme of them are overwriting vanilla UI source code in the file helpers.lua).
--LibFilters3 will use the inventory/fragment (normal hooks), or some special hooks (e.g. ENCHANTING -> OnModeUpdated) to
--add the LF* constant to the inventory/fragment/variables.
--
--The filterFunctions will be placed at the inventory.additionalFilter entry, and will enhance existing functions, so
--that filter funtions sumarize (e.g. addon1 registers a "Only show stolen filter" and addon2 registers "only show level
--10 items filter" -> Only level 10 stolen items will be shown then).
--
--The function InstallHelpers below will call special code from the file "helper.lua". In this file you define the
--variable(s) and function name(s) which LibFilters should "REPLACE" -> Means it will overwrite those functions to add
--the call to the LibFilters internal filterFunctions (e.g. at SMITHING crafting tables, function
--EnumerateInventorySlotsAndAddToScrollData -> ZOs vanilla UI code + usage of self.additionalFilter where Libfilters
--added it's filterFunctions).
--
--
--[Important]
--You need to call LibFilters3:InitializeLibFilters() once in any of the addons that use LibFilters, to
--create the hooks and init the library properly!


--**********************************************************************************************************************
--TODO List - Count: 1                                                                         LastUpdated: 2021-01-31
--**********************************************************************************************************************
--#1 Crafting smithing jewelry does not filter "include banked items" checkbox properly at research



--**********************************************************************************************************************
-- LibFilters information
--**********************************************************************************************************************
local MAJOR, GlobalLibName, MINOR = "LibFilters-3.0", "LibFilters3", 2.0
local libPreText = "[" .. MAJOR .."]"

--**********************************************************************************************************************
-- LibFilters global variable and version check -> Only load this library once
--**********************************************************************************************************************
--Was the library loaded already, and if so:
if _G[GlobalLibName] ~= nil then return end

--Local library variable
local LibFilters = {}
local LibFiltersSVName = "LibFilters_SV"
LibFilters.sv = {}
LibFilters.isInitialized = false
local settings = {}

LibFilters.name     = MAJOR
LibFilters.version  = MINOR
LibFilters.author   = "ingeniousclown, Randactyl, Baertram"

--Create the global library variable
_G[GlobalLibName] = LibFilters


--**********************************************************************************************************************
-- LibFilters debugging
--**********************************************************************************************************************
LibFilters.logger = nil
local logger

------------------------------------------------------------------------------------------------------------------------
-->LibDebugLogger
local function createLogger()
    if logger == nil then
        logger = LibDebugLogger ~= nil and LibDebugLogger(MAJOR)
        LibFilters.logger = logger
        logger:SetEnabled(true)
    end
end

local function debugFunc()
    --TODO: Disable code lines below before setting library live!
    if GetDisplayName() ~= "@Baertram" then return end
    settings.debug          = true
end

--Debugging output
local function debugMessage(text, textType)
    if not text or text == "" then return end
    textType = textType or 'I'
    logger = logger or LibFilters.logger
    if logger ~= nil then
        --logger:SetEnabled(true)
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

        --Logger:Debug does not work before event_add_on_loaded as SavedVArs of LibDebugLogger are not loaded yet.
        --So we manually changed the StartupConfig.lua file in LibDebugLogger folder to enable the "verbose" logging
        --until SVs get loaded.
        --Workaround: Enable debug output via d() below
        --d(text)

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

--[[
local function debugNow(params, debugType)
    local text
    if #params > 1 then
        text = string.format(unpack(params))
    else
        text = params[1]
    end
    debugMessage(text, debugType)
end
]]
--Normal debug
local function df(...)
     debugMessage(string.format(...), 'D')
end
--Information
local function dfi(...)
    debugMessage(string.format(...), 'I')
end
--Error debug
local function dfe(...)
    debugMessage(string.format(...), 'E')
end
--Warning
local function dfw(...)
    debugMessage(string.format(...), 'W')
end
--Verbose
local function dfv(...)
    debugMessage(string.format(...), 'V')
end

------------------------------------------------------------------------------------------------------------------------
--The possible LibFilters filterPanelIds
--**********************************************************************************************************************
-- LibFilters filterPanel constants value = "name"
--**********************************************************************************************************************
--The possible libFilters filterPanelIds
local libFiltersFilterConstants = {
    [1]   = "LF_INVENTORY",
    [2]   = "LF_BANK_WITHDRAW",
    [3]   = "LF_BANK_DEPOSIT",
    [4]   = "LF_GUILDBANK_WITHDRAW",
    [5]   = "LF_GUILDBANK_DEPOSIT",
    [6]   = "LF_VENDOR_BUY",
    [7]   = "LF_VENDOR_SELL",
    [8]   = "LF_VENDOR_BUYBACK",
    [9]   = "LF_VENDOR_REPAIR",
    [10]  = "LF_GUILDSTORE_BROWSE",
    [11]  = "LF_GUILDSTORE_SELL",
    [12]  = "LF_MAIL_SEND",
    [13]  = "LF_TRADE",
    [14]  = "LF_SMITHING_REFINE",
    [15]  = "LF_SMITHING_CREATION",
    [16]  = "LF_SMITHING_DECONSTRUCT",
    [17]  = "LF_SMITHING_IMPROVEMENT",
    [18]  = "LF_SMITHING_RESEARCH",
    [19]  = "LF_ALCHEMY_CREATION",
    [20]  = "LF_ENCHANTING_CREATION",
    [21]  = "LF_ENCHANTING_EXTRACTION",
    [22]  = "LF_PROVISIONING_COOK",
    [23]  = "LF_PROVISIONING_BREW",
    [24]  = "LF_FENCE_SELL",
    [25]  = "LF_FENCE_LAUNDER",
    [26]  = "LF_CRAFTBAG",
    [27]  = "LF_QUICKSLOT",
    [28]  = "LF_RETRAIT",
    [29]  = "LF_HOUSE_BANK_WITHDRAW",
    [30]  = "LF_HOUSE_BANK_DEPOSIT",
    [31]  = "LF_JEWELRY_REFINE",
    [32]  = "LF_JEWELRY_CREATION",
    [33]  = "LF_JEWELRY_DECONSTRUCT",
    [34]  = "LF_JEWELRY_IMPROVEMENT",
    [35]  = "LF_JEWELRY_RESEARCH",
    [36]  = "LF_SMITHING_RESEARCH_DIALOG",
    [37]  = "LF_JEWELRY_RESEARCH_DIALOG",
    [38]  = "LF_INVENTORY_QUEST",
    --Add new lines here and make sure you also take care of the control of the inventory needed in tables "usedInventoryTypes"
    --and "usedCraftingInventoryTypes" below, the updater name in table "filterTypeToUpdaterName" and updaterFunction in
    --table "inventoryUpdaters", as well as the way to hook to the inventory.additionalFilters in function "HookAdditionalFilters",
    --or via a fragment in table "fragmentToFilterType",
    --and maybe an overwritten "filter enable function" (which respects the entries of the added additionalFilters) in
    --file "helpers.lua"
    --[39] = "LF_RECONSTRUCT",
    --[40] = "LF_...",
}
--register the filterConstants for the filterpanels in the global table _G
for value, filterConstantName in ipairs(libFiltersFilterConstants) do
    _G[filterConstantName] = value
end
LibFilters.filterTypes = libFiltersFilterConstants

--Get the min and max filterPanelIds
LF_FILTER_MIN               = LF_INVENTORY
LF_FILTER_MAX               = #libFiltersFilterConstants

------------------------------------------------------------------------------------------------------------------------
--Special hooks
local specialHooksDone = {
    ["enchanting"] = false,
}

------------------------------------------------------------------------------------------------------------------------
--Some inventory variables and controls
local playerInventory =     PLAYER_INVENTORY
local inventories =         PLAYER_INVENTORY.inventories

local quickslots =          QUICKSLOT_WINDOW

local vendor =              STORE_WINDOW
local buyBack =             BUY_BACK_WINDOW
local repair =              REPAIR_WINDOW

--Some crafting variables
local smithing =            SMITHING
local refinementPanel =     SMITHING.refinementPanel
local creationPanel =       SMITHING.creationPanel
local deconstructionPanel = SMITHING.deconstructionPanel
local improvementPanel =    SMITHING.improvementPanel
local researchPanel =       SMITHING.researchPanel

--local retraitClass =        ZO_RetraitStation_Retrait_Base
local retrait =             ZO_RETRAIT_KEYBOARD
--local retraitStation =      ZO_RETRAIT_STATION_KEYBOARD
local reconstruct =         ZO_RECONSTRUCT_KEYBOARD

local enchantingClass =     ZO_Enchanting
local enchanting =          ENCHANTING

--local alchemyClass =        ZO_Alchemy
local alchemy =             ALCHEMY

--TODO: Provisioning?!
local provisioner =         PROVISIONER

--Dialogs
local researchDialogSelect= SMITHING_RESEARCH_SELECT
local ZOsDialog1 =          ZO_Dialog1
local ZOsListDialog1 =      ZO_ListDialog1
local ZOsDialogs = {
    [ZOsDialog1]        = true,
    [ZOsListDialog1]    = true,
}


------------------------------------------------------------------------------------------------------------------------
--Inventories and fragments

--Inventory types
local invBackPack   = INVENTORY_BACKPACK
local invBank       = INVENTORY_BANK
local invHouseBank  = INVENTORY_HOUSE_BANK
local invGuildBank  = INVENTORY_GUILD_BANK
local invQuestItem  = INVENTORY_QUEST_ITEM
local invCraftBag   = INVENTORY_CRAFT_BAG

local usedInventoryTypes = {
    [inventories[invBackPack]]      = true,
    [inventories[invBank]]          = true,
    [inventories[invHouseBank]]     = true,
    [inventories[invGuildBank]]     = true,
    [inventories[invQuestItem]]     = true,
    [inventories[invCraftBag]]      = true,
    [vendor]                        = true,
    [buyBack]                       = true,
    [repair]                        = true,
    [quickslots]                    = true
}
LibFilters.Inventories = usedInventoryTypes

local usedCraftingInventoryTypes = {
    [refinementPanel.inventory]     = true,
    [creationPanel]                 = true,
    [deconstructionPanel.inventory] = true,
    [improvementPanel.inventory]    = true,
    [researchPanel]                 = true,
    [researchDialogSelect]          = true,
    [alchemy.inventory]             = true,
    [enchanting.inventory]          = true,
    [provisioner.ingredientRows]    = true,
    [retrait.inventory]             = true,
}
LibFilters.CraftingInventories = usedCraftingInventoryTypes

------------------------------------------------------------------------------------------------------------------------
-- LibFilters local variables and constants for the fragments which are added to some inventory scenes
--Scene fragments of the inventories/filterPanels
local menuBarInvFragment        = BACKPACK_MENU_BAR_LAYOUT_FRAGMENT
local bankInvFragment           = BACKPACK_BANK_LAYOUT_FRAGMENT
local houseBankInvFragment      = BACKPACK_HOUSE_BANK_LAYOUT_FRAGMENT
local guildBankInvFragment      = BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT
local tradingHouseInvFragment   = BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT
local mailInvFragment           = BACKPACK_MAIL_LAYOUT_FRAGMENT
local playerTradeInvFragment    = BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT
local storeInvFragment          = BACKPACK_STORE_LAYOUT_FRAGMENT
local fenceInvFragment          = BACKPACK_FENCE_LAYOUT_FRAGMENT
local launderInvFragment        = BACKPACK_LAUNDER_LAYOUT_FRAGMENT
local fragmentToFilterType = {
    [menuBarInvFragment]        = { name = "BACKPACK_MENU_BAR_LAYOUT_FRAGMENT",     filterType = LF_INVENTORY },
    [bankInvFragment]           = { name = "BACKPACK_BANK_LAYOUT_FRAGMENT",         filterType = LF_BANK_DEPOSIT },
    [houseBankInvFragment]      = { name = "BACKPACK_HOUSE_BANK_LAYOUT_FRAGMENT",   filterType = LF_HOUSE_BANK_DEPOSIT },
    [guildBankInvFragment]      = { name = "BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT",   filterType = LF_GUILDBANK_DEPOSIT },
    [tradingHouseInvFragment]   = { name = "BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT",filterType = LF_GUILDSTORE_SELL },
    [mailInvFragment]           = { name = "BACKPACK_MAIL_LAYOUT_FRAGMENT",         filterType = LF_MAIL_SEND },
    [playerTradeInvFragment]    = { name = "BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT", filterType = LF_TRADE },
    [storeInvFragment]          = { name = "BACKPACK_STORE_LAYOUT_FRAGMENT",        filterType = LF_VENDOR_SELL },
    [fenceInvFragment]          = { name = "BACKPACK_FENCE_LAYOUT_FRAGMENT",        filterType = LF_FENCE_SELL },
    [launderInvFragment]        = { name = "BACKPACK_LAUNDER_LAYOUT_FRAGMENT",      filterType = LF_FENCE_LAUNDER },
}
LibFilters.fragmentToFilterType = fragmentToFilterType
LibFilters.fragmentsActiveState = {}
local fragmentsActiveState = LibFilters.fragmentsActiveState


------------------------------------------------------------------------------------------------------------------------
--Mappings

--Mapping for crafting
local enchantingModeToFilterType = {
    [ENCHANTING_MODE_CREATION]      = LF_ENCHANTING_CREATION,
    [ENCHANTING_MODE_EXTRACTION]    = LF_ENCHANTING_EXTRACTION,
    [ENCHANTING_MODE_RECIPES]       = nil --not supported yet
}

local provisioningModeToFilterType = {
    [PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES]        = LF_PROVISIONING_BREW,
    [PROVISIONER_SPECIAL_INGREDIENT_TYPE_FLAVORING]     = LF_PROVISIONING_COOK,
    [PROVISIONER_SPECIAL_INGREDIENT_TYPE_FURNISHING]    = nil --not supported yet
}


--Mappings for the inventories
local filterTypeToInventory = {
    --Normal inventories (all using the same)
    [LF_INVENTORY]                  = inventories[invBackPack],
    [LF_BANK_DEPOSIT]               = inventories[invBackPack],
    [LF_GUILDBANK_DEPOSIT]          = inventories[invBackPack],
    [LF_HOUSE_BANK_DEPOSIT]         = inventories[invBackPack],
    [LF_MAIL_SEND]                  = inventories[invBackPack],
    [LF_TRADE]                      = inventories[invBackPack],
    [LF_GUILDSTORE_SELL]            = inventories[invBackPack],
    [LF_VENDOR_SELL]                = inventories[invBackPack],
    [LF_FENCE_LAUNDER]              = inventories[invBackPack],
    [LF_FENCE_SELL]                 = inventories[invBackPack],

    --Banks withdraw
    [LF_BANK_WITHDRAW]              = inventories[invBank],
    [LF_GUILDBANK_WITHDRAW]         = inventories[invGuildBank],
    [LF_HOUSE_BANK_WITHDRAW]        = inventories[invHouseBank],
    --Vendor
    [LF_VENDOR_BUY]                 = vendor,
    [LF_VENDOR_BUYBACK]             = buyBack,
    [LF_VENDOR_REPAIR]              = repair,
    --Guild store / Trading house
    --[LF_GUILDSTORE_BROWSE]          = ?,
    --Other inventories
    [LF_CRAFTBAG]                   = inventories[invCraftBag],
    [LF_INVENTORY_QUEST]            = inventories[invQuestItem],
    [LF_QUICKSLOT]                  = quickslots,
    --Crafting smithing
    [LF_JEWELRY_REFINE]             = refinementPanel.inventory,
    [LF_SMITHING_REFINE]            = refinementPanel.inventory,
    [LF_JEWELRY_CREATION]           = creationPanel,
    [LF_SMITHING_CREATION]          = creationPanel,
    [LF_JEWELRY_DECONSTRUCT]        = deconstructionPanel.inventory,
    [LF_SMITHING_DECONSTRUCT]       = deconstructionPanel.inventory,
    [LF_JEWELRY_IMPROVEMENT]        = improvementPanel.inventory,
    [LF_SMITHING_IMPROVEMENT]       = improvementPanel.inventory,
    [LF_JEWELRY_RESEARCH]           = researchPanel,
    [LF_SMITHING_RESEARCH]          = researchPanel,
    [LF_JEWELRY_RESEARCH_DIALOG]    = researchDialogSelect,
    [LF_SMITHING_RESEARCH_DIALOG]   = researchDialogSelect,
    --Crafting alchemy
    [LF_ALCHEMY_CREATION]           = alchemy.inventory,
    --Crafting provisioner
    [LF_PROVISIONING_COOK]          = provisioner.ingredientRows, --1 to 6
    [LF_PROVISIONING_BREW]          = provisioner.ingredientRows, --1 to 6
    --Crafting retrait / reconstruct
    [LF_RETRAIT]                    = retrait, --!!! Important !!! retrait.inventory will fail to filter properly due to additionalFilters used from ZO_RETRAIT_KEYBOARD
}
LibFilters.FilterTypeToInventory = filterTypeToInventory



------------------------------------------------------------------------------------------------------------------------
-- LibFilters registered filters array -> Addons will register their filter callbackFunctions into this table, for each
-- LibFilters filterPanel LF_*
--The filters of the different FilterPanelIds will be registered to these sub-tables
LibFilters.filters = {}
for _, filterConstantName in ipairs(libFiltersFilterConstants) do
    LibFilters.filters[_G[filterConstantName]] = {}
end
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


--Only call the function updateFunc every 10 milliseconds if requested more often
local function throttledCall(filterType, uniqueName, updateFunc, ...)
    if settings.debug then df(">throttledCall: uniqueName: %s, filterType: %s", tostring(uniqueName), tostring(filterType)) end
    if not uniqueName or uniqueName == "" then
        dfe("Invalid uniqueName to throttledCall, filterType: %s", tostring(filterType))
        return
    end
    --cancel previously scheduled update, if any
    EVENT_MANAGER:UnregisterForUpdate(uniqueName)
    --register a new one
    EVENT_MANAGER:RegisterForUpdate(uniqueName, 10, function(...) updateFunc(...) end)
end

--Update the inventory lists
--if the mouse is enabled, cycle its state to refresh the integrity of the control beneath it
local function SafeUpdateList(object, ...)
--d("[LibFilters3]SafeUpdateList, inv: " ..tostring(...))
    local isMouseVisible = SCENE_MANAGER:IsInUIMode()

    if isMouseVisible then HideMouse() end

    object:UpdateList(...)

    if isMouseVisible then ShowMouse() end
end

local function getInventoryControl(inventoryOrFragment, invControlBase)
    if inventoryOrFragment == nil and invControlBase == nil then return end
    local invControl
    if inventoryOrFragment ~= nil then
        if inventoryOrFragment.IsControlHidden ~= nil then
            invControl = inventoryOrFragment
        end
    end
    if invControl == nil and invControlBase ~= nil then
        if invControlBase.IsControlHidden ~= nil then
            invControl = invControlBase
        end
    end
    if invControl == nil then
        invControl = (invControlBase ~= nil and (invControlBase.control or invControlBase.listView or invControlBase.list or invControlBase.container)) or
                (inventoryOrFragment ~= nil and (inventoryOrFragment.control or inventoryOrFragment.listView or inventoryOrFragment.list or inventoryOrFragment.container or
                inventoryOrFragment))
    end
    return invControl
end


local function resetLibFiltersFilterTypeAfterDialogClose(dialogControl)
    --[[
    local dialogCtrlName = (dialogControl and (dialogControl.control and dialogControl.control.GetName and dialogControl.control:GetName())
                            or (dialogControl and dialogControl.GetName and dialogControl:GetName())
                           ) or "n/a"
   ]]
    --SMITHING research item dialog
    if dialogControl == researchDialogSelect then
        --Reset LibFilters filterType to LF_SMITHING_RESEARCH or LF_JEWELRY_RESEARCH
       --researchPanel:HandleDirtyEvent()
       researchPanel:Refresh()
        return true
    end
    return false
end

--Function to update a ZO_ListDialog1 dialog's list contents
-->Used for the Research item dialog
local dialogUpdaterCloseCallbacks = {
    [researchDialogSelect] = false,
}
local function dialogUpdaterFunc(listDialogControl)
    if listDialogControl == nil then return nil end
    --Get & Refresh the list dialog
    local listDialog = ZO_InventorySlot_GetItemListDialog()
    if listDialog ~= nil and listDialog.GetControl ~= nil then
        local control = listDialog:GetControl()
        local data = control.data
        if not data then return end
        local dialogNeedsOnCloseCallback = false

        --SMITHING research item dialog
        if listDialogControl == researchDialogSelect then
            dialogNeedsOnCloseCallback = true
            local craftingType, researchLineIndex, traitIndex  = data.craftingType, data.researchLineIndex, data.traitIndex
            if craftingType and researchLineIndex and traitIndex then
                --Re-Call the dialog's setup function to clear the list, check available data and filter the items (see helper.lua, helpers["SMITHING_RESEARCH_SELECT"])
                listDialogControl.SetupDialog(listDialogControl, craftingType, researchLineIndex, traitIndex)
            end
        end

        --Add an updater function as the dialog closes the next time, so that the LibFilters filterType will be reset to the
        --SMITHING's current panel again (e.g. to LF_SMITHING_RESEARCH)
        if not dialogNeedsOnCloseCallback or dialogUpdaterCloseCallbacks[listDialogControl] then return end
        ZOsListDialog1:SetHandler("OnEffectivelyHidden", function()
            resetLibFiltersFilterTypeAfterDialogClose(listDialogControl)
        end, MAJOR)
        dialogUpdaterCloseCallbacks[listDialogControl] = true
    end
end

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
        alchemy.inventory:HandleDirtyEvent()
    end,
    ENCHANTING = function()
        enchanting.inventory:HandleDirtyEvent()
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

--Run the applied filters at a LibFilters filterType (LF_*) now, using the ... parameters (e.g. inventorySlot)
local function runFilters(filterType, ...)
    if settings.debug and settings.debugDetails then df("runFilters, filterType: %s", tostring(filterType)) end
    for tag, filter in pairs(filters[filterType]) do
        if not filter(...) then
            return false
        end
    end
    return true
end
LibFilters.RunFilters = runFilters


------------------------------------------------------------------------------------------------------------------------
--**********************************************************************************************************************
--**********************************************************************************************************************
--**********************************************************************************************************************
-- -v-  API                                                                                                         -v-
--**********************************************************************************************************************
--**********************************************************************************************************************
--**********************************************************************************************************************


--**********************************************************************************************************************
-- LibFilters library global library API functions - Filter functions
--**********************************************************************************************************************


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

--Hook the inventory in a special way, e.g. at ENCHANTING where there is only 1 inventory variable and no
--extra fragment for the different modes (creation, extraction).
local specialHooksLibFiltersDataRegistered = {}
function LibFilters:HookAdditionalFilterSpecial(specialType, inventory)
    local debug = settings.debug
    if debug then df("[HookAdditionalFilterSpecial] - specialType: %s, hookAlreadyDone: %s, inventory: %s", tostring(specialType), tostring(specialHooksDone[specialType]), tostring(inventory)) end
    if specialHooksDone[specialType] == true then return end

    --ENCHANTING
    if specialType == "enchanting" then
        local function onEnchantingModeUpdated(enchantingVar, enchantingMode)
            local libFiltersEnchantingFilterType = enchantingModeToFilterType[enchantingMode]
            if debug then df("onEnchantingModeUpdated - enchantingMode: %s, filterType: %s", tostring(enchantingMode), tostring(libFiltersEnchantingFilterType)) end
            enchantingVar.inventory.LibFilters3_filterType = libFiltersEnchantingFilterType

            specialHooksLibFiltersDataRegistered[specialType] = specialHooksLibFiltersDataRegistered[specialType] or {}

            --Only once
            if libFiltersEnchantingFilterType ~= nil and not specialHooksLibFiltersDataRegistered[specialType][libFiltersEnchantingFilterType] then
                local originalFilter = enchantingVar.inventory.additionalFilter
                local additionalFilterType = type(originalFilter)
                if additionalFilterType == "function" then
                    enchantingVar.inventory.additionalFilter = function(...)
                        return originalFilter(...) and runFilters(libFiltersEnchantingFilterType, ...)
                    end
                else
                    enchantingVar.inventory.additionalFilter = function(...)
                        return runFilters(libFiltersEnchantingFilterType, ...)
                    end
                end

                specialHooksLibFiltersDataRegistered[specialType][libFiltersEnchantingFilterType] = true
            end

        end
        ZO_PreHook(enchantingClass, "OnModeUpdated", function(selfEnchanting)
            onEnchantingModeUpdated(selfEnchanting, selfEnchanting.enchantingMode)
        end)
        specialHooksDone[specialType] = true
    end
end


--**********************************************************************************************************************
-- LibFilters library global library API functions - Filter functions
--**********************************************************************************************************************
--Returns the filter callbackFunction for the specified filterTag e.g. <addonName> and filterType LF*
function LibFilters:GetFilterCallback(filterTag, filterType)
    if settings.debug then df("GetFilterCallback - filterTag: %s, filterType: %s",tostring(filterTag),tostring(filterType)) end
    if not self:IsFilterRegistered(filterTag, filterType) then return end
    return filters[filterType][filterTag]
end


--**********************************************************************************************************************
--  LibFilters global library API functions - Get: Filter types for "LibFilters"
--**********************************************************************************************************************
--Returns the minimum possible filteType
function LibFilters:GetMinFilterType()
    return LF_FILTER_MIN
end
LibFilters.GetMinFilter = LibFilters.GetMinFilterType

--Returns the maxium possible filterType
function LibFilters:GetMaxFilterType()
    return LF_FILTER_MAX
end
LibFilters.GetMaxFilter = LibFilters.GetMaxFilterType

--Returns the LibFilters LF* filterType connstants table: value = "name"
function LibFilters:GetFilterTypes()
    return libFiltersFilterConstants
end

--Returns the LibFilters LF* filterType connstant's name
function LibFilters:GetFilterTypeName(libFiltersFilterType)
    return libFiltersFilterConstants[libFiltersFilterType] or ""
end


--Returns the mapping table of the LibFilters LF_* filterTypes to the inventory variable
function LibFilters:GetFilterTypeToInventory()
    return filterTypeToInventory
end


--Get the current libFilters filterType for the inventoryType, where inventoryType would be e.g. INVENTORY_BACKPACK or
--INVENTORY_BANK
function LibFilters:GetCurrentFilterTypeForInventory(inventoryType)
    --LibFilters._inventoryType = inventoryType
    --Get the layoutData from the fragment. If no fragment: Abort
    if inventoryType == INVENTORY_BACKPACK then
        local layoutData = PLAYER_INVENTORY.appliedLayout
        if layoutData and layoutData.LibFilters3_filterType then
            return layoutData.LibFilters3_filterType
        else
            return
        end
    end
    --Get the inventory from PLAYER_INVENTORY.inventories
    --> Added new: "number" check and else inventoryType to support enchanting.inventory
    local inventory = (type(inventoryType) == "number" and inventories[inventoryType]) or inventoryType
    if not inventory or not inventory.LibFilters3_filterType then return end
    if settings.debug then df("<LibFilters:GetCurrentFilterTypeForInventory(%s) = %s", tostring(inventoryType), tostring(inventory.LibFilters3_filterType)) end
    return inventory.LibFilters3_filterType
end

--**********************************************************************************************************************
--  LibFilters global library API functions - Get: Inventories for "LibFilters"
--**********************************************************************************************************************
--Returns the inventory for the LibFilters LF_* filterType
function LibFilters:GetInventoryOfFilterType(filterType)
    return filterTypeToInventory[filterType]
end

function LibFilters:GetInventoryName(inventoryOrFragment)
    if inventoryOrFragment == nil then return end
    local invOrFragmentName
    local invData = usedInventoryTypes[inventoryOrFragment] or usedCraftingInventoryTypes[inventoryOrFragment]
    if not invData then
        local fragmentData = fragmentToFilterType[inventoryOrFragment]
        if fragmentData ~= nil then
            invOrFragmentName = fragmentData.name
        end
    elseif invData == true then
        local invControl = getInventoryControl(inventoryOrFragment, nil)
        if invControl ~= nil then
            invOrFragmentName = invControl.GetName and invControl:GetName() or invControl.name or "n/a"
        end
    end
    return invOrFragmentName
end


--**********************************************************************************************************************
-- LibFilters library global library API functions - (Un)Register filters of addons
--**********************************************************************************************************************
--Checks if a filter function is already registered for the filterTag e.g. <addonName> and the filterType LF*
function LibFilters:IsFilterRegistered(filterTag, filterType)
    if settings.debug then
        local filterTypeIsRegisteredType = filterType or "-IsRegistered all-"
        df("IsFilterRegistered - filterTag: %s, filterType: %s",tostring(filterTag),tostring(filterTypeIsRegisteredType))
    end
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


--Registers the filter callbackFunction for the specified filterTag e.g. <addonName> and filterType LF*
--The filterCallback function must be a function with either the inventorySlot as parameter (normal inventories like
--backpack, banks, vendor, mail, etc.)
--or the bagId and slotIndex as parameters (only for crafting stations like alchemy, refine deconstruction, improvement,
--retrait, enchanting, ...)
function LibFilters:RegisterFilter(filterTag, filterType, filterCallback)
    if settings.debug then df("RegisterFilter - filterTag: %s, filterType: %s, filterCallback: %s",tostring(filterTag),tostring(filterType),tostring(filterCallback)) end
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
    return true
end


--Un-Registers the filter callbackFunction for the specified filterTag e.g. <addonName> and filterType LF*
function LibFilters:UnregisterFilter(filterTag, filterType)
    if settings.debug then
        local filterTypeUnregType = filterType or "-Unregister all-"
        df("UnregisterFilter - filterTag: %s, filterType: %s",tostring(filterTag),tostring(filterTypeUnregType))
    end
    if not filterTag or filterTag == "" then
        dfe("Invalid arguments to UnregisterFilter(%s, %s).\n>Needed format is: String filterTag, number LibFiltersLF_*FilterPanelConstant", tostring(filterTag), tostring(filterType))
        return
    end
    if filterType == nil then
        --unregister all filters with this tag
        for _, callbacks in pairs(filters) do
            if callbacks[filterTag] ~= nil then
                callbacks[filterTag] = nil
            end
        end
        return true
    else
        --unregister only the specified filter type
        local callbacks = filters[filterType]

        if callbacks[filterTag] ~= nil then
            callbacks[filterTag] = nil
            return true
        end
    end
end

--**********************************************************************************************************************
-- LibFilters library global library API functions - Update / Refresh
--**********************************************************************************************************************
--Requests to call the update function of the inventory/fragment of filterType LF*
function LibFilters:RequestUpdate(filterType)
    local debug = settings.debug
    if debug then df("RequestUpdate - filterType: %s", tostring(filterType)) end

    local updaterName = filterTypeToUpdaterName[filterType]
    if not updaterName or updaterName == "" then
        dfe("Invalid arguments to RequestUpdate(%s).\n>Needed format is: number LibFiltersLF_*FilterPanelConstant", tostring(filterType))
        return
    end
    local callbackName = "LibFilters_updateInventory_" .. updaterName
    local function Update()
        if settings.debug then df("!>>RUN: RequestUpdate->Update - callbackName: %s, filterType: %s", tostring(callbackName), tostring(filterType)) end
        EVENT_MANAGER:UnregisterForUpdate(callbackName)
        inventoryUpdaters[updaterName]()
    end
    throttledCall(filterType, callbackName, Update)
    return true
end

--**********************************************************************************************************************
-- LibFilters library global API functions - Special functions
--**********************************************************************************************************************
--Reset the filterType of LibFilters to to currently shown inventory again, after a list-dialog closes (e.g. the
--research list dialo -> SMITHING_RESEARCH_SELECT)
function LibFilters:ResetFilterTypeAfterListDialogClose(listDialogControl)
    if settings.debug then df("ResetFilterTypeAfterListDialogClose - listDialogControl: %s", tostring(listDialogControl)) end
    if listDialogControl == nil then return end
    return resetLibFiltersFilterTypeAfterDialogClose(listDialogControl)
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

--Enable some hooks for the ZO_*Dialog1 controls
-->Enable drag&drop
local isDialogMovable = false
local function HookDialogs(doEnable)
    for dialogCtrl, isToHook in pairs(ZOsDialogs) do
        if isToHook == true and dialogCtrl ~= nil and dialogCtrl.SetMovable ~= nil then
            local setMovableFunc = function()
                local modalUnderlay = GetControl(dialogCtrl, "ModalUnderlay")
                if modalUnderlay ~= nil then
                    modalUnderlay:SetHidden(doEnable)
                    dialogCtrl:SetMovable(doEnable)
                    if doEnable == false then
                        dialogCtrl:ClearAnchors()
                        dialogCtrl:SetAnchor(CENTER, GUI_ROOT, CENTER)
                    end
                end
            end
            dialogCtrl:SetHandler("OnEffectivelyShown", setMovableFunc, MAJOR)
            --Is the dialog currently shown? Then update it's movable state now
            if dialogCtrl.IsHidden and dialogCtrl:IsHidden() == false then
                setMovableFunc()
            end
        end
    end
    isDialogMovable = not isDialogMovable
end

--If doEnabled = true: Remove the modal underlay behind ZO_(List)Dialog1 and make the dialog movable
--If doEnable = false: Re-Enable the modal underlay behind the dialogs and remove the movable state
function LibFilters:SetDialogsMovable(doEnable)
    doEnable = doEnable or false
    HookDialogs(doEnable)
end

--**********************************************************************************************************************
--**********************************************************************************************************************
--**********************************************************************************************************************
-- -^-  API                                                                                                         -^-
--**********************************************************************************************************************
--**********************************************************************************************************************
--**********************************************************************************************************************

------------------------------------------------------------------------------------------------------------------------
-- INSTALL THE HOOKS TO THE INVENTORIES AND FRAGMENTS TO USE THE additionalFilters subtable for the LibFilters filter
--functions

--**********************************************************************************************************************
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

    --Does not work! Same inventory, would always return LF_ENCHANTING_EXTRACTION (as it was added at last)
    --LibFilters:HookAdditionalFilter(LF_ENCHANTING_CREATION, ENCHANTING.inventory)
    --LibFilters:HookAdditionalFilter(LF_ENCHANTING_EXTRACTION, ENCHANTING.inventory)
     LibFilters:HookAdditionalFilterSpecial("enchanting", enchanting.inventory)

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
-- LibFilters SavedVariables
--**********************************************************************************************************************
local function loadSavedVariables()
    df("Loading SavedVariables")
    --if settings and settings.dialogMovable ~= nil then return end
    local libFiltersSV_Defaults = {
        debug           = false,
        debugDetails    = false,
        dialogMovable   = false
    }
    local displayName   = GetDisplayName()
    local worldName     = GetWorldName()

    local worldNameTabExists = (_G[LibFiltersSVName] ~= nil and _G[LibFiltersSVName][worldName] ~= nil) or false
    local displayNameTabExists = (worldNameTabExists and _G[LibFiltersSVName][worldName][displayName] ~= nil) or false

    if _G[LibFiltersSVName] == nil or worldNameTabExists == false or displayNameTabExists == false then
        if _G[LibFiltersSVName] ~= nil then
            if worldNameTabExists == false then
                df(">Creating worldname SV sub-table")
            end
            if displayNameTabExists == false then
                df(">Creating display name SV sub-table")
            end
            _G[LibFiltersSVName][worldName] = _G[LibFiltersSVName][worldName] or {}
            _G[LibFiltersSVName][worldName][displayName] = _G[LibFiltersSVName][worldName][displayName] or libFiltersSV_Defaults
        else
            df(">Creating SV table + sub-tables new")
            _G[LibFiltersSVName] = {}
            _G[LibFiltersSVName][worldName] = {}
            _G[LibFiltersSVName][worldName][displayName] = libFiltersSV_Defaults
        end
    end
    settings = _G[LibFiltersSVName][worldName][displayName]

    debugFunc()
end


--**********************************************************************************************************************
-- LibFilters slash commands
--**********************************************************************************************************************
local function slashCommands()
    SLASH_COMMANDS["/libfilters_debug"] = function()
        settings.debug = not settings.debug
        if settings.debug == false then
            settings.debugDetails = false
        end
        dfi("Debugging: %s", tostring(settings.debug))
    end
    SLASH_COMMANDS["/libfilters_debugdetails"] = function()
        settings.debugDetails = not settings.debugDetails
        if settings.debugDetails == true then
            settings.debug = true
        end
        dfi("Debugging with details: %s", tostring(settings.debugDetails))

    end
    SLASH_COMMANDS["/dialogmovable"] = function()
        LibFilters:SetDialogsMovable(not settings.dialogMovable)
    end
end


--**********************************************************************************************************************
-- LibFilters global variable and initialization
--**********************************************************************************************************************
--Check for old LibFilters 1 / LibFilters 2 versions and deactivate them
local function checkforOldLibFiltersVersionAndDeactive()
    --Are any older versions of libFilters loaded?
    local libFiltersOldVersionErrorText = "Please do not use the library \'%s\' anymore! Deinstall this library and switch to the newest version \'" .. MAJOR .. "\'.\nPlease also inform the author of the addons, which still use \'%s\', to update their addon code immediately!"
    local libFiltersTemplateStr = "LibFilters-%s.0"
    local libFiltersOldVersionStr
    local libFiltersOldVersionsToCheck = {
        0,
        1,
        2,
    }
    for _, oldLibFilterVersion in ipairs( libFiltersOldVersionsToCheck ) do
        local versionStrToCheck
        if oldLibFilterVersion == 0 then
            versionStrToCheck = ""
        else
            versionStrToCheck = tostring(oldLibFilterVersion)
        end
        if _G["LibFilters" .. versionStrToCheck] ~= nil then
            libFiltersOldVersionStr = string.format(libFiltersTemplateStr, tostring(1))
            dfe(libFiltersOldVersionErrorText, libFiltersOldVersionStr, libFiltersOldVersionStr)
            return true
        end
    end
    return false
end


--**********************************************************************************************************************
--**********************************************************************************************************************
--**********************************************************************************************************************

--Function needed to be called from your addon to start the LibFilters instance and enable the filtering!
function LibFilters:InitializeLibFilters()
    debugFunc()

    if settings.debug then df("InitializeLibFilters - isInitialized: %s", tostring(self.isInitialized )) end
    if self.isInitialized then return end

    if checkforOldLibFiltersVersionAndDeactive() == true then
        d("Old LibFilters version found -> Please deactivate it!")
    end
    self.isInitialized = true

    InstallHelpers()
    HookAdditionalFilters()
end

local function LibFilters_OnAddOnLoaded(eventName, addonName)
    if addonName ~= MAJOR then return end
    EVENT_MANAGER:UnregisterForEvent(MAJOR .. "_EVENT_ADD_ON_LOADED", EVENT_ADD_ON_LOADED)

    loadSavedVariables()
    if settings.debug then df("EVENT_ADD_ON_LOADED") end
end
EVENT_MANAGER:RegisterForEvent(MAJOR .. "_EVENT_ADD_ON_LOADED", EVENT_ADD_ON_LOADED, LibFilters_OnAddOnLoaded)

--Run once
debugFunc()
createLogger()
--Create the slash commands for the chat
slashCommands()
