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
--TODO List - Count: 3                                                                          LastUpdated: 2021-01-24
--**********************************************************************************************************************
--#3 Find out why "RunFilters" is shown duplicate in chat debug mesasges if we are ar the crafting table "deconstruction",
--   once for SMITHING decon and once for JEWELRY decon? Should only be shown for one of both?!
--   And why is there only "RunFilters" debug message but no "callFilterFunc" before or similar which calls runFilter?

--**********************************************************************************************************************
-- LibFilters information
--**********************************************************************************************************************
local MAJOR, GlobalLibName, MINOR = "LibFilters-3.0", "LibFilters3", 1.8
local libPreText = "[" .. MAJOR .."]"

--**********************************************************************************************************************
-- LibFilters global variable and version check -> Only load this library once
--**********************************************************************************************************************
--Was the library loaded already, and if so:
--Was it fully initilaized already?
--Or is the version a newer than the loaded one?
--Abort here then as we do not need to run the code below twice. Should be handled by the txt file's ## AddOnVersion:
--already, so this is just a security check if someone ships this lib without the correct txt file and hardcodes the
--call in it's addon's manifest txt
local lfGlobal = _G[GlobalLibName]
if lfGlobal ~= nil then
    if lfGlobal.isInitialized == true then return end
    if lfGlobal.name ~= nil and lfGlobal.name == MAJOR
        and lfGlobal.version ~= nil and lfGlobal.version >= MINOR then return end
end


--**********************************************************************************************************************
-- LibFilters local variable pointing to global LibFiltersX
--**********************************************************************************************************************
--Local library variable pointer to global LibFilters variable
local LibFilters = {}
local LibFiltersSVName = 'LibFilters_SV'
LibFilters.sv = {}
LibFilters.isInitialized = false

LibFilters.helpers = {}
local helpers = LibFilters.helpers

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
createLogger()

--Debugging output
local function debugMessage(text, textType)
    if not text or text == "" then return end
    textType = textType or 'I'
    createLogger()
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

local function df(...)
    debugMessage(string.format(...), 'D')
end
local function dfi(...)
    debugMessage(string.format(...), 'I')
end
--Error debug
local function dfe(...)
    debugMessage(string.format(...), 'E')
end

local function isInitialized(initializeIfNot)
    initializeIfNot = initializeIfNot or false
    if not LibFilters.isInitialized and initializeIfNot == true then
        LibFilters:InitializeLibFilters()
    end
    return LibFilters.isInitialized
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
    --Add new lines here and make sure you also take care of the control of the inventory needed in table "usedControls",
    --the updater name in table "filterTypeToUpdaterName" and updaterFunction in table "inventoryUpdaters",
    --as well as the way to hook to the inventory.additionalFilters in function "HookAdditionalFilters",
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
-- LibFilters registered filters array -> Addons will register their filter callbackFunctions into this table, for each
-- LibFilters filterPanel LF_*
--The filters of the different FilterPanelIds will be registered to these sub-tables
LibFilters.filters = {}
local filters = LibFilters.filters
for _, filterConstantName in ipairs(libFiltersFilterConstants) do
    filters[_G[filterConstantName]] = {}
end

------------------------------------------------------------------------------------------------------------------------
--Some inventory variables and controls
local playerInventory =     PLAYER_INVENTORY
local inventories =         playerInventory.inventories

local quickslots =          QUICKSLOT_WINDOW

local vendor =              STORE_WINDOW
local buyBack =             BUY_BACK_WINDOW
local repair =              REPAIR_WINDOW

--Some crafting variables
local smithing =            SMITHING
local refinementPanel =     smithing.refinementPanel
local creationPanel =       smithing.creationPanel
local deconstructionPanel = smithing.deconstructionPanel
local improvementPanel =    smithing.improvementPanel
local researchPanel =       smithing.researchPanel

--local retraitClass =        ZO_RetraitStation_Retrait_Base
local retrait =             ZO_RETRAIT_KEYBOARD
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
--Special hooks
local specialHooksDone = {
    ["enchanting"] = false,
}

------------------------------------------------------------------------------------------------------------------------
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

--Mappings of the inventories
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
    [LF_RETRAIT]                    = retrait.inventory,
}
LibFilters.FilterTypeToInventory = filterTypeToInventory

--Some inventories need a special handling as they are re-used for more than one filterType e.g. ENCHANTNG
local filterTypeToSpecialInventory = {
    --Crafting enchanting
    [LF_ENCHANTING_CREATION]        = { type = "enchanting", inventory = enchanting.inventory } ,
    [LF_ENCHANTING_EXTRACTION]      = { type = "enchanting", inventory = enchanting.inventory },
}
LibFilters.FilterTypeToSpecialInventory = filterTypeToSpecialInventory

--Mappings for crafting
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

--Mapping for some crafting inventories, where there are multiple filterpanelIds at the same inventory, e.g.
--jewelry crafting and normal, -> Both use SMITHING.xxxxxPanel
local craftingInventoryToFilterType = {
    --Refine
    [refinementPanel.inventory] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = LF_JEWELRY_REFINE,
        [CRAFTING_TYPE_BLACKSMITHING]   = LF_SMITHING_REFINE,
        [CRAFTING_TYPE_CLOTHIER]        = LF_SMITHING_REFINE,
        [CRAFTING_TYPE_WOODWORKING]     = LF_SMITHING_REFINE,
    },
    --Create
    [creationPanel] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = LF_JEWELRY_CREATION,
        [CRAFTING_TYPE_BLACKSMITHING]   = LF_SMITHING_CREATION,
        [CRAFTING_TYPE_CLOTHIER]        = LF_SMITHING_CREATION,
        [CRAFTING_TYPE_WOODWORKING]     = LF_SMITHING_CREATION,
    },
    --DeconstructenchantingMode
    [deconstructionPanel.inventory] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = LF_JEWELRY_DECONSTRUCT,
        [CRAFTING_TYPE_BLACKSMITHING]   = LF_SMITHING_DECONSTRUCT,
        [CRAFTING_TYPE_CLOTHIER]        = LF_SMITHING_DECONSTRUCT,
        [CRAFTING_TYPE_WOODWORKING]     = LF_SMITHING_DECONSTRUCT,
    },
    --Improve
    [improvementPanel.inventory] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = LF_JEWELRY_IMPROVEMENT,
        [CRAFTING_TYPE_BLACKSMITHING]   = LF_SMITHING_IMPROVEMENT,
        [CRAFTING_TYPE_CLOTHIER]        = LF_SMITHING_IMPROVEMENT,
        [CRAFTING_TYPE_WOODWORKING]     = LF_SMITHING_IMPROVEMENT,
    },
    --Research
    [researchPanel] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = LF_JEWELRY_RESEARCH,
        [CRAFTING_TYPE_BLACKSMITHING]   = LF_SMITHING_RESEARCH,
        [CRAFTING_TYPE_CLOTHIER]        = LF_SMITHING_RESEARCH,
        [CRAFTING_TYPE_WOODWORKING]     = LF_SMITHING_RESEARCH,
    },
    --ResearchDialog
    [researchDialogSelect] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = LF_JEWELRY_RESEARCH_DIALOG,
        [CRAFTING_TYPE_BLACKSMITHING]   = LF_SMITHING_RESEARCH_DIALOG,
        [CRAFTING_TYPE_CLOTHIER]        = LF_SMITHING_RESEARCH_DIALOG,
        [CRAFTING_TYPE_WOODWORKING]     = LF_SMITHING_RESEARCH_DIALOG,
    },
    --Alchemy
    [alchemy.inventory] = {
        [CRAFTING_TYPE_ALCHEMY]         = LF_ALCHEMY_CREATION,

    },
    --Enchanting
    [enchanting.inventory] = {
        [CRAFTING_TYPE_ENCHANTING]      = function()
            return enchantingModeToFilterType[enchanting.enchantingMode]
        end,
    },
    --Provisioning
    [provisioner] = {
        [CRAFTING_TYPE_PROVISIONING]    = function()
            return provisioningModeToFilterType[provisioner.filterType]
        end,
    },
    --Retrait
    [retrait.inventory] = {
        [CRAFTING_TYPE_INVALID]         = LF_RETRAIT,
    },
}
LibFilters.CraftingInventoryToFilterType = craftingInventoryToFilterType

--Filtertypes also using LF_INVENTORY's inventory control ZO_PlayerInventoryList.
--Do not add them all via the HookAdditionalFilters function but use their fragments instead!
local filterTypesUsingTheSameInvControl  = {
    [inventories[invBackPack]] = {
        [LF_MAIL_SEND]          = true,
        [LF_TRADE]              = true,
        [LF_BANK_DEPOSIT]       = true,
        [LF_HOUSE_BANK_DEPOSIT] = true,
        [LF_GUILDBANK_DEPOSIT]  = true,
        [LF_VENDOR_SELL]        = true,
        [LF_FENCE_LAUNDER]      = true,
        [LF_FENCE_SELL]         = true,
    }
}

--FilterTypes that should not update the active inventory control and filterType via function "registerActiveInventoryTypeUpdate"
-->These filtertypes will use fragments to update the correct filterType
local filterTypesNotUpdatingLastInventoryData  = {
}


local craftingFilterTypesUsingTheSameInvControl = {
    [enchanting] = {
        ["doNotHookOnShow"]         =   true,
        ["doNotHookOnHide"]         =   true,
        [LF_ENCHANTING_CREATION]    =   true,
        [LF_ENCHANTING_EXTRACTION]  =   true,
    }
}

------------------------------------------------------------------------------------------------------------------------
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
local filterTypeToUpdaterName = filterTypeToUpdaterNameFixed
--Add the fixed updaterNames of the filtertypes
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

------------------------------------------------------------------------------------------------------------------------
--Only call the function updateFunc every 10 milliseconds if requested more often
local function throttledCall(filterType, uniqueName, updateFunc)
    if not uniqueName or uniqueName == "" then
        dfe("Invalid uniqueName to throttledCall, filterType: %s", tostring(filterType))
        return
    end
    --cancel previously scheduled update, if any
    EVENT_MANAGER:UnregisterForUpdate(uniqueName)
    --register a new one
    EVENT_MANAGER:RegisterForUpdate(uniqueName, 10, updateFunc)
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

--Updating the current and lastUsed inventory and libFilters filterTypes, as the Refresh/Update function of the inventory
--is called
local function updateActiveInventoryType(invType, filterType, isInventory)
    isInventory = isInventory or false
    df("updateActiveInventoryType - isInventory: %s, filterType: %s, invType: %s",tostring(isInventory), tostring(filterType), tostring(invType))
    local function updateActiveInvNow(p_inv, p_filterType, p_isInv)
        df(">>RUN: updateActiveInventoryType - isInventory: %s, filterType: %s, invType: %s",tostring(isInventory), tostring(filterType), tostring(invType))
        local lastInventoryType = LibFilters.activeInventoryType
        local lastFilterType = LibFilters.activeFilterType
        if lastInventoryType ~= nil and lastFilterType ~= nil then
            LibFilters.lastInventoryType    = lastInventoryType
            LibFilters.lastFilterType       = lastFilterType
        end
        LibFilters.activeInventoryType  = p_inv
        LibFilters.activeFilterType     = p_filterType
    end

    local callbackName = "LibFilters_updateActiveInventoryType"
    local function Update()
        EVENT_MANAGER:UnregisterForUpdate(callbackName)
        updateActiveInvNow(invType, filterType, isInventory)
    end
    throttledCall(filterType, callbackName, Update)
end

--Register the updater function which calls updateActiveInventoryType for the normal inventories and fragments
local invControlHandlersSet = {}
local function registerActiveInventoryTypeUpdate(inventoryOrFragment, filterType, isInventory, noHandlers)
    noHandlers = noHandlers or false
    --Should this filtertype not be updated here but via fragments?
    if isInventory == true and filterTypesNotUpdatingLastInventoryData[filterType] == true then return end

    --If any filter is enabled the update fucntion of the inventory (e.g. updateInventoryBase) will handle this. But if no
    --filter is registrered (yet/anymore) it wont! So we need to "duplicate" the check here somehow as the inventory's
    --control get's shown
    if not inventoryOrFragment then return end
    local invControl
    local invControlBase = filterTypeToInventory[filterType]
    if invControlBase ~= nil then
        if invControlBase.IsControlHidden ~= nil then
            invControl = invControlBase
        else
            invControl = invControlBase.control or invControlBase.listView or invControlBase.list or invControlBase.container or
                    inventoryOrFragment.control or inventoryOrFragment.listView or inventoryOrFragment.list or inventoryOrFragment.container
                    or inventoryOrFragment
        end
    end
    df("registerActiveInventoryTypeUpdate - isInventory: %s, invControl: %s, invControl.IsControlHidden: %s",tostring(isInventory), tostring(invControl), tostring(invControl.IsControlHidden ~= nil))
    if isInventory == true then
        LibFilters.registeredInventoriesData = LibFilters.registeredInventoriesData or {}
        LibFilters.registeredInventoriesData[filterType] = {
            filterType  = filterType,
            inv         = inventoryOrFragment,
            invControl  = invControl,
        }
    else
        LibFilters.registeredFragmentsData = LibFilters.registeredFragmentsData or {}
        LibFilters.registeredFragmentsData[filterType] = {
            filterType  = filterType,
            inv         = inventoryOrFragment,
            invControl  = invControl,
        }
    end

    local filterTypeUsesSameInvControl = (filterTypesUsingTheSameInvControl[inventoryOrFragment] and filterTypesUsingTheSameInvControl[inventoryOrFragment][filterType]) or false
    df(">filterType: %s, filterTypeUsesSameInvControl: %s", tostring(filterType), tostring(filterTypeUsesSameInvControl))
    if filterTypeUsesSameInvControl == true then
        --The fragments will handle the update of the active inventory type then, e.g. LF_MAIL_SEND -> BACKPACK_MAIL_LAYOUT_FRAGMENT.
        --They will also register the update of their control here with this function registerActiveInventoryTypeUpdate
        return
    end

    local isCraftingInv = usedCraftingInventoryTypes[inventoryOrFragment]
    local cBase = (isCraftingInv == true and craftingFilterTypesUsingTheSameInvControl[inventoryOrFragment]) or nil
    local craftingFilterTypeUsesTheSameInvControl = (isCraftingInv == true and cBase ~= nil and craftingFilterTypesUsingTheSameInvControl[inventoryOrFragment][filterType]) or false
    df(">>craftingFilterTypeUsesTheSameInvControl: %s", tostring(craftingFilterTypeUsesTheSameInvControl))
    if craftingFilterTypeUsesTheSameInvControl == true then
        --Enchanting e.g.
        if cBase.doNotHookOnShow == true and cBase.doNotHookOnHide == true then
            return
        end
    end

    --Is this a control? And should the handlers be set?
    if not noHandlers and invControlHandlersSet[invControl] == nil and invControl.IsControlHidden ~= nil then
        local name = invControl.GetName and invControl:GetName() or "n/a"
        df(">>>Registering OnShow/OnHide handler: %s", tostring(name))
        if cBase == nil or cBase.doNotHookOnShow == true then
            invControl:SetHandler("OnEffectivelyShown", function()
                updateActiveInventoryType(inventoryOrFragment, filterType, isInventory)
            end)
        end
        if cBase == nil or cBase.doNotHookOnHide == true then
            invControl:SetHandler("OnEffectivelyHidden", function()
                updateActiveInventoryType(nil, nil, isInventory)
            end)
        end
        invControlHandlersSet[invControl] = true
    end
end

local function updateInventoryBase(inventoryOrFragmentVar, inventoryId, callbackFunc, isCrafting, filterType)
    isCrafting = isCrafting or false
    local invId = inventoryId or inventoryOrFragmentVar
    if isCrafting == true then
        if filterType == nil then
            local libFiltersFilterTypeForCraftingBase = craftingInventoryToFilterType[inventoryOrFragmentVar]
            if not libFiltersFilterTypeForCraftingBase then return end
            local libFiltersFilterTypeForCrafting = libFiltersFilterTypeForCraftingBase[GetCraftingInteractionType()]
            if not libFiltersFilterTypeForCrafting then return end
            if type(libFiltersFilterTypeForCrafting) == "function" then
                filterType = libFiltersFilterTypeForCrafting()
            else
                filterType = libFiltersFilterTypeForCrafting
            end
        end
    end
    updateActiveInventoryType(invId, filterType)
    if callbackFunc ~= nil then callbackFunc() end
end

local function updatePlayerInventoryType(inventoryOrFragmentVar, inventoryId, callbackFunc, filterType)
    updateInventoryBase(inventoryOrFragmentVar, inventoryId, callbackFunc, false, filterType)
    SafeUpdateList(playerInventory, inventoryOrFragmentVar)
end

local function updateCraftingInventoryType(craftingInventoryOrFragmentVar, inventoryId, callbackFunc, craftingInvRefreshFunc)
    updateInventoryBase(craftingInventoryOrFragmentVar, inventoryId, callbackFunc, true)
    if craftingInvRefreshFunc ~= nil then
        if type(craftingInvRefreshFunc) == "function" then
            craftingInvRefreshFunc()
        else
            dfe("updateCraftingInventoryType - craftingInvRefreshFunc is no function! craftingInvRefreshFunc: %s", tostring(craftingInvRefreshFunc))
            return
        end
    else
        if not craftingInventoryOrFragmentVar then
            dfe("updateCraftingInventoryType - craftingInventoryOrFragmentVar is nil! inventoryId: %s", tostring(inventoryId))
            return
        end
        if craftingInventoryOrFragmentVar.HandleDirtyEvent then
            craftingInventoryOrFragmentVar:HandleDirtyEvent()
        end
    end
end

local function updateOtherInventoryType(otherInventoryOrFragmentVar, inventoryId, callbackFunc, filterType)
    updateInventoryBase(otherInventoryOrFragmentVar, inventoryId, callbackFunc, false, filterType)
    SafeUpdateList(otherInventoryOrFragmentVar)
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
        updateCraftingInventoryType(researchPanel, nil, nil, function() researchPanel:Refresh() end)
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
            updateInventoryBase(listDialogControl, nil, nil, true, nil)
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
        SafeUpdateList(playerInventory, invBackPack)
    end,
    BANK_WITHDRAW = function()
        SafeUpdateList(playerInventory, invBank)
    end,
    GUILDBANK_WITHDRAW = function()
        SafeUpdateList(playerInventory, invGuildBank)
    end,
    VENDOR_BUY = function()
        if tradingHouseInvFragment.state ~= SCENE_SHOWN then --"shown"
            vendor:GetStoreItems()
            SafeUpdateList(vendor)
        end
    end,
    VENDOR_BUYBACK = function()
        SafeUpdateList(buyBack)
    end,
    VENDOR_REPAIR = function()
        SafeUpdateList(repair)
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
        --TODO
    end,
    PROVISIONING_BREW = function()
        --TODO
    end,
    CRAFTBAG = function()
        SafeUpdateList(playerInventory, invCraftBag)
    end,
    QUICKSLOT = function()
        SafeUpdateList(quickslots)
    end,
    RETRAIT = function()
        retrait.inventory:HandleDirtyEvent()
    end,
    HOUSE_BANK_WITHDRAW = function()
        SafeUpdateList(playerInventory, invHouseBank )
    end,
    SMITHING_RESEARCH_DIALOG = function()
        dialogUpdaterFunc(researchDialogSelect)
    end,
    RECONSTRUCTION = function()
        reconstruct.inventory:HandleDirtyEvent()
    end,
    INVENTORY_QUEST = function()
        SafeUpdateList(playerInventory, invQuestItem)
    end,
}
LibFilters.inventoryUpdaters = inventoryUpdaters

------------------------------------------------------------------------------------------------------------------------
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

--The filter function, using the inventory/fragment.additionalFilter function/value and the registered filter function at
--the filterType (e.g. LF_INVENTORY) via function runFilters
local function callFilterFunc(p_inventory, filterType)
    local originalFilter = p_inventory.additionalFilter
    local additionalFilterType = type(originalFilter)
    if additionalFilterType == "function" then
        p_inventory.additionalFilter = function(...)
            return originalFilter(...) and runFilters(filterType, ...)
        end
    else
        p_inventory.additionalFilter = function(...)
            return runFilters(filterType, ...)
        end
    end
end
LibFilters.CallFilterFunc = callFilterFunc

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
--Returns the filter callbackFunction for the specified filterTag e.g. <addonName> and filterType LF*
function LibFilters:GetFilterCallback(filterTag, filterType)
    if not isInitialized(true) then return end
    if not LibFilters:IsFilterRegistered(filterTag, filterType) then return end
    return filters[filterType][filterTag]
end


--**********************************************************************************************************************
--  LibFilters global library API functions - Get: Filter types for "LibFilters"
--**********************************************************************************************************************
--Returns the minimum possible filterPanelId
function LibFilters:GetMinFilterType()
    return LF_FILTER_MIN
end
LibFilters.GetMinFilter = LibFilters.GetMinFilterType

--Returns the maxium possible filterPanelId
function LibFilters:GetMaxFilterType()
    return LF_FILTER_MAX
end
LibFilters.GetMaxFilter = LibFilters.GetMaxFilterType

--Returns the LibFilters LF* filterType connstants table: value = "name"
function LibFilters:GetFilterTypes()
    return libFiltersFilterConstants
end

--Returns the mapping table of the LibFilters LF_* filterTypes to the inventory variable
function LibFilters:GetFilterTypeToInventory()
    return filterTypeToInventory
end

--Get the current libFilters filterType for the active inventory, as well as the filterType that was used before.
--Active inventory will be set as the hook of the supported inventories gets applied and as it's updaterFunction is run.
--The activeInventory will be e.g. INVENTORY_BACKPACK
function LibFilters:GetCurrentFilterType()
    if not isInitialized(true) then return nil, nil end
    return LibFilters.activeFilterType, LibFilters.lastFilterType
end

--Get the current libFilters filterType for the inventoryType, where inventoryType would be e.g. INVENTORY_BACKPACK or
--INVENTORY_BANK
function LibFilters:GetCurrentFilterTypeForInventory(inventoryType)
    if not isInitialized(true) then return end
    if not inventoryType then return end
    local invVarType = type(inventoryType)
    local isNumber  = invVarType == "number"
    local isTable   = invVarType == "table"
    local filterTypeOfInv = (isNumber == true and inventories[inventoryType] and inventories[inventoryType].LibFilters3_filterType)
            or (isTable == true and inventoryType.layoutData and inventoryType.layoutData.LibFilters3_filterType)
            or inventoryType and inventoryType.LibFilters3_filterType
    return filterTypeOfInv
end


--**********************************************************************************************************************
--  LibFilters global library API functions - Get: Inventories for "LibFilters"
--**********************************************************************************************************************
--Get the current libFilters active inventory type. The activeInventory type will be e.g. INVENTORY_BACKPACK
--or a userdate/table of the e.g. crafting inventory
function LibFilters:GetCurrentInventoryType()
    if not isInitialized(true) then return nil, nil end
    return LibFilters.activeInventoryType, LibFilters.lastInventoryType
end


--Get the current libFilters active inventory, and the last inventory that was active before.
--The activeInventory will be e.g. PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK] or a similar userdate/table of the
--inventory
-->Returns inventoryVar, lastInventoryVar, isInventoryVarACraftingTable
function LibFilters:GetCurrentInventoryVar()
    if not isInitialized(true) then return nil, nil, nil end
    local activeInventoryType, lastInventoryType = LibFilters:GetCurrentInventoryType()
    local invVarType, lastInvVarType
    local inventory, lastInventory
    local isNumber
    local isTable
    local isCrafting = false
    if activeInventoryType then
        invVarType = type(activeInventoryType)
        isNumber  = invVarType == "number"
        isTable   = invVarType == "table"
        isCrafting = isNumber == false
        inventory = (isNumber == true and inventories[activeInventoryType])
                or (isTable == true and activeInventoryType)
    end
    if lastInventoryType then
        lastInvVarType = type(lastInventoryType)
        isNumber  = lastInvVarType == "number"
        isTable   = lastInvVarType == "table"
        lastInventory = (isNumber == true and inventories[lastInventoryType])
                or (isTable == true and lastInventoryType)
    end
    return inventory, lastInventory, isCrafting
end

--Returns the inventory for the LibFilters LF_* filterType
function LibFilters:GetInventoryOfFilterType(filterType)
    return filterTypeToInventory[filterType]
end


--**********************************************************************************************************************
-- LibFilters library global library API functions - Get: for "Vanilla UI inventories"
--**********************************************************************************************************************
--Return the currently active inventory's main filterType (e.g. Weapons, Armor) -> inventory.currentFilter
-->Returns currentFilter, inventoryType, inventoryVar, libFiltersFilterTypeOfInventory
function LibFilters:GetCurrentInventoryFilter()
    if not isInitialized(true) then return nil, nil, nil, nil end
    local activeInventoryType, _ =      LibFilters:GetCurrentInventoryType()
    local activeInventoryVar, _ =       LibFilters:GetCurrentInventoryVar()
    local activeFilterType, _ =         LibFilters:GetCurrentFilterType()

    --Should be "currentFilter" for normal inventories
    local currentFilter = activeInventoryVar and activeInventoryVar.currentFilter
    return currentFilter, activeInventoryType, activeInventoryVar, activeFilterType
end

--Return the currently active inventory's main filterType's subFilterType (e.g. Weapons- > 1hd)  -> inventory.subFilter
-->Returns currentSubFilter, currentFilter, inventoryType, inventoryControl, libFiltersFilterTypeOfInventory
function LibFilters:GetCurrentInventorySubFilter()
    if not isInitialized(true) then return nil, nil, nil, nil end
    local currentFilter, activeInventoryType, activeInventoryVar, activeFilterType = LibFilters:GetCurrentInventoryFilter()
    local currentSubFilter = activeInventoryVar and activeInventoryVar.subFilter
    return currentSubFilter, currentFilter, activeInventoryType, activeInventoryVar, activeFilterType
end


--**********************************************************************************************************************
-- LibFilters library global library API functions - (Un)Register filters of addons
--**********************************************************************************************************************
--Checks if a filter function is already registered for the filterTag e.g. <addonName> and the filterType LF*
function LibFilters:IsFilterRegistered(filterTag, filterType)
    if not isInitialized(true) then return end
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
    if not isInitialized(true) then return end
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
    if not isInitialized(true) then return end
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
    if not isInitialized(true) then return end
    local updaterName = filterTypeToUpdaterName[filterType]
    if not updaterName or updaterName == "" then
        dfe("Invalid arguments to RequestUpdate(%s).\n>Needed format is: number LibFiltersLF_*FilterPanelConstant", tostring(filterType))
        return
    end
    local callbackName = "LibFilters_updateInventory_" .. updaterName
    local function Update()
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
    if not isInitialized(true) then return end
    if LibFilters.sv.debug then df("ResetFilterTypeAfterListDialogClose - listDialogControl: %s", tostring(listDialogControl)) end
    if listDialogControl == nil then return end
    return resetLibFiltersFilterTypeAfterDialogClose(listDialogControl)
end


--Used for the SMITHING table -> research panel: Set some values of the currently selected research horizontal scroll list
--etc. so that loops are able to start at these values
function LibFilters:SetResearchLineLoopValues(fromResearchLineIndex, toResearchLineIndex, skipTable)
    if not isInitialized(true) then return end
    local craftingType = GetCraftingInteractionType()
    if craftingType == CRAFTING_TYPE_INVALID then return false end
    if not fromResearchLineIndex or fromResearchLineIndex <= 0 then fromResearchLineIndex = 1 end
    if not toResearchLineIndex or toResearchLineIndex > GetNumSmithingResearchLines(craftingType) then
        toResearchLineIndex = GetNumSmithingResearchLines(craftingType)
    end
    if not helpers then return end
    local smithingResearchPanel = helpers["SMITHING.researchPanel:Refresh"].locations[1]
    if smithingResearchPanel then
        smithingResearchPanel.libFilters_3ResearchLineLoopValues = {
            from        = fromResearchLineIndex,
            to          = toResearchLineIndex,
            skipTable   = skipTable,
        }
        return true
    end
    return false
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
--functionss

--Hook the inventory layout or inventory to apply additional filter functions
function LibFilters:HookAdditionalFilter(filterType, inventoryOrFragment, isInventory)
    isInventory = isInventory or false
    df("HookAdditionalFilter - isInventory: %s, invControl: %s, filterType: %s",tostring(isInventory), tostring(inventoryOrFragment), tostring(filterType))
    local layoutData = inventoryOrFragment.layoutData or inventoryOrFragment
    layoutData.LibFilters3_filterType = filterType

    if isInventory == true then
        registerActiveInventoryTypeUpdate(inventoryOrFragment, filterType, isInventory, false)
    end

    callFilterFunc(layoutData, filterType)

    --[[
    local layoutData = inventoryOrFragment.layoutData or inventoryOrFragment
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
    ]]
end

--Hook the inventory in a special way, e.g. at ENCHANTING where there is only 1 inventory variable and no
--extra fragment for the different modes (creation, extraction).
function LibFilters:HookAdditionalFilterSpecial(specialType, inventory)
    if specialHooksDone[specialType] == true then return end

    --ENCHANTING
    if specialType == "enchanting" then
        local function onEnchantingModeUpdated(enchantingVar, enchantingMode)
            local libFiltersEnchantingFilterType = enchantingModeToFilterType[enchantingMode]
            if libFiltersEnchantingFilterType == nil then return end

            --updateActiveInventoryType(enchanting.inventory, libFiltersEnchantingFilterType)
            registerActiveInventoryTypeUpdate(enchanting, libFiltersEnchantingFilterType, true, false)

            inventory.LibFilters3_filterType = libFiltersEnchantingFilterType
            callFilterFunc(inventory, libFiltersEnchantingFilterType)

            LibFilters:RequestUpdate(libFiltersEnchantingFilterType)
        end
        ZO_PreHook(enchantingClass, "OnModeUpdated", function(selfEnchanting)
            onEnchantingModeUpdated(selfEnchanting, selfEnchanting.enchantingMode)
        end)
        specialHooksDone[specialType] = true
    end
end

local function fragmentChange(oldState, newState, fragmentId, fragmentName, filterType)
    df("Fragment \'%s\' state change - newState: %s", tostring(fragmentName), tostring(newState))
    if newState == SCENE_FRAGMENT_HIDING  then
        updateActiveInventoryType(nil, nil)
    elseif newState == SCENE_FRAGMENT_SHOWN then
        filterType = filterType or LibFilters:GetCurrentFilterTypeForInventory(fragmentId)
        updateActiveInventoryType(fragmentId, filterType)
    end
end


--Hook all the filters at the different inventory panels (LibFilters filterPanelIds) now
local function HookAdditionalFilters()
    --Hook the inventories (no fragments)
    for filterType, inventory in pairs(filterTypeToInventory) do
        --Do not use if a special inventory register needs to be done -> Is only in this list to get the inventory control
        local doRegister = (filterTypesUsingTheSameInvControl[inventory] == nil or (filterTypesUsingTheSameInvControl[inventory] ~= nil and filterTypesUsingTheSameInvControl[inventory][filterType] == nil)) or false
        if doRegister == true and filterTypeToSpecialInventory[filterType] == nil then
            --e.g. LibFilters:HookAdditionalFilter(LF_INVENTORY, inventories[invBackPack], true)
            LibFilters:HookAdditionalFilter(filterType, inventory, true)
        end
    end

    --HookAdditionalFilter: Does not work for enchanting as all filter constants LF_ENCHANTNG* use ENCHANTING.inventory
    --and thus the last call to it (currently LF_ENCHANTING_EXTRACTION) will override the value of before registered ones
    --Hook the special inventories (no fragments)
    for filterType, specialInventoryData in pairs(filterTypeToSpecialInventory) do
        --Only register once
        local specialInventoryTypeStr = specialInventoryData.type
        if not specialHooksDone[specialInventoryTypeStr] then
            --e.g. LibFilters:HookAdditionalFilterSpecial("enchanting", enchanting.inventory)
            LibFilters:HookAdditionalFilterSpecial(specialInventoryTypeStr, specialInventoryData.inventory)
        end
    end

    --Hook the fragments
    for fragmentId, fragmentData in pairs(fragmentToFilterType) do
        --e.g. LibFilters:HookAdditionalFilter(LF_INVENTORY, menuBarInvFragment)
        --LibFilters:HookAdditionalFilter(filterType, fragmentId, false)
        --use the fragment's state change callback!
        if fragmentId and fragmentData.name ~= "" then
            local filterType
            if type(fragmentData.filterType) == "function" then
                filterType = fragmentData.filterType()
            else
                filterType = fragmentData.filterType
            end
            fragmentId:RegisterCallback("StateChange", function(oldState, newState)
                fragmentChange(oldState, newState, fragmentId, fragmentData.name, filterType)
            end)
        end
    end

    --[[
    LibFilters:HookAdditionalFilter(LF_INVENTORY, inventories[invBackPack], true)
    LibFilters:HookAdditionalFilter(LF_INVENTORY, menuBarInvFragment)

    LibFilters:HookAdditionalFilter(LF_BANK_WITHDRAW, inventories[invBank], true)
    LibFilters:HookAdditionalFilter(LF_BANK_DEPOSIT, bankInvFragment)

    LibFilters:HookAdditionalFilter(LF_GUILDBANK_WITHDRAW, inventories[invGuildBank], true)
    LibFilters:HookAdditionalFilter(LF_GUILDBANK_DEPOSIT, guildBankInvFragment)

    LibFilters:HookAdditionalFilter(LF_VENDOR_BUY, vendor, true)
    LibFilters:HookAdditionalFilter(LF_VENDOR_SELL, storeInvFragment)
    LibFilters:HookAdditionalFilter(LF_VENDOR_BUYBACK, buyBack, true)
    LibFilters:HookAdditionalFilter(LF_VENDOR_REPAIR, repair, true)

    --LibFilters:HookAdditionalFilter(LF_GUILDSTORE_BROWSE, )
    LibFilters:HookAdditionalFilter(LF_GUILDSTORE_SELL, tradingHouseInvFragment)

    LibFilters:HookAdditionalFilter(LF_MAIL_SEND, mailInvFragment)

    LibFilters:HookAdditionalFilter(LF_TRADE, playerTradeInvFragment)

    LibFilters:HookAdditionalFilter(LF_SMITHING_REFINE, refinementPanel.inventory, true)
    --LibFilters:HookAdditionalFilter(LF_SMITHING_CREATION, )
    LibFilters:HookAdditionalFilter(LF_SMITHING_DECONSTRUCT, deconstructionPanel.inventory, true)
    LibFilters:HookAdditionalFilter(LF_SMITHING_IMPROVEMENT, improvementPanel.inventory, true)
    LibFilters:HookAdditionalFilter(LF_SMITHING_RESEARCH, researchPanel, true)
    LibFilters:HookAdditionalFilter(LF_JEWELRY_REFINE, refinementPanel.inventory, true)
    --LibFilters:HookAdditionalFilter(LF_JEWELRY_CREATION, )
    LibFilters:HookAdditionalFilter(LF_JEWELRY_DECONSTRUCT, deconstructionPanel.inventory, true)
    LibFilters:HookAdditionalFilter(LF_JEWELRY_IMPROVEMENT, improvementPanel.inventory, true)
    LibFilters:HookAdditionalFilter(LF_JEWELRY_RESEARCH, researchPanel, true)

    LibFilters:HookAdditionalFilter(LF_ALCHEMY_CREATION, alchemy.inventory, true)

    --LibFilters:HookAdditionalFilter(LF_PROVISIONING_COOK, )
    --LibFilters:HookAdditionalFilter(LF_PROVISIONING_BREW, )

    LibFilters:HookAdditionalFilter(LF_FENCE_SELL, fenceInvFragment)
    LibFilters:HookAdditionalFilter(LF_FENCE_LAUNDER, launderInvFragment)

    LibFilters:HookAdditionalFilter(LF_CRAFTBAG, inventories[invCraftBag], true)

    LibFilters:HookAdditionalFilter(LF_QUICKSLOT, quickslots, true)

    LibFilters:HookAdditionalFilter(LF_RETRAIT, retrait, true)

    LibFilters:HookAdditionalFilter(LF_HOUSE_BANK_WITHDRAW, inventories[invHouseBank], true)
    LibFilters:HookAdditionalFilter(LF_HOUSE_BANK_DEPOSIT, houseBankInvFragment)

    LibFilters:HookAdditionalFilter(LF_SMITHING_RESEARCH_DIALOG, researchDialogSelect, true)
    LibFilters:HookAdditionalFilter(LF_JEWELRY_RESEARCH_DIALOG, researchDialogSelect, true)

    LibFilters:HookAdditionalFilter(LF_INVENTORY_QUEST, inventories[invQuestItem], true)

    --HookAdditionalFilter: Does not work for enchanting as all filter constants LF_ENCHANTNG* use ENCHANTING.inventory
    --and thus the last call to it (currently LF_ENCHANTING_EXTRACTION) will override the value of before registered ones
    LibFilters:HookAdditionalFilterSpecial("enchanting", enchanting.inventory)
    ]]
end


--Register all the helper functions of LibFilters, for some panels like the Research or ResearchDialog, or even
-- deconstruction and improvement, etc.
--These helper functions will overwrite original vanilla UI ESO functions in order to add and use the LibFilters
--"predicate"/"filterFunction" within the ZOs code. If the vanilla UI function updates this versions here need to be
--updated as well!
--> See file helper.lua

--Install the helpers from table helpers now -> See file helper.lua, table "helpers"
local function InstallHelpers()
    for packageName, package in pairs(helpers) do
        local funcName = package.helper.funcName
        local func = package.helper.func

        for _, location in pairs(package.locations) do
            --e.g. ZO_SmithingExtractionInventory["GetIndividualInventorySlotsAndAddToScrollData"] = overwritten
            --function from helpers table, param "func"
            local locationName
            if location then
                if location.control and location.control.GetName then
                    locationName = location.control:GetName()
                elseif location.GetName then
                    locationName = location:GetName()
                else
                    locationName = location
                end
            end
            location[funcName] = func
        end
    end
end
------------------------------------------------------------------------------------------------------------------------
-- HOKS END
------------------------------------------------------------------------------------------------------------------------


--**********************************************************************************************************************
-- LibFilters slash commands
--**********************************************************************************************************************
local function slashCommands()
    SLASH_COMMANDS["/libfilters_debug"] = function()
        LibFilters.sv.debug = not LibFilters.sv.debug
        dfi("Debugging: %s", tostring(LibFilters.sv.debug))
    end
    SLASH_COMMANDS["/libfilters_debugdetails"] = function()
        LibFilters.sv.debugDetails = not LibFilters.sv.debugDetails
        if LibFilters.sv.debugDetails == true then
            LibFilters.sv.debug = true
        else
            LibFilters.sv.debug = false
        end
        dfi("Debugging with details: %s", tostring(LibFilters.sv.debugDetails))

    end
    SLASH_COMMANDS["/dialogmovable"] = function()
        LibFilters:SetDialogsMovable(not LibFilters.sv.dialogMovable)
    end
end

--**********************************************************************************************************************
-- LibFilters SavedVariables
--**********************************************************************************************************************
local function loadSavedVariables()
    local libFiltersSV_Defaults = {
        debug           = false,
        debugDetails    = false,
        dialogMovable   = false
    }
    local displayName = GetDisplayName()
    local worldName = GetWorldName()

    if _G[LibFiltersSVName] == nil or _G[LibFiltersSVName][worldName] == nil or _G[LibFiltersSVName][worldName][displayName] == nil then
        if _G[LibFiltersSVName] ~= nil then
            _G[LibFiltersSVName][worldName] = _G[LibFiltersSVName][worldName] or {}
            _G[LibFiltersSVName][worldName][displayName] = libFiltersSV_Defaults
        else
            _G[LibFiltersSVName] = {}
            _G[LibFiltersSVName][worldName] = {}
            _G[LibFiltersSVName][worldName][displayName] = libFiltersSV_Defaults
        end
    end
    LibFilters.sv = _G[LibFiltersSVName][worldName][displayName]
end


--**********************************************************************************************************************
-- LibFilters global variable and initialization
--**********************************************************************************************************************
--Check for old LibFilters 1 / LibFilters 2 versions and deactivate them
local function checkforOldLibFiltersVersionAndDeactive()
    --Are any older versions of libFilters loaded?
    local libFiltersOldVersionErrorText = "Please do not use the library \'%s\' anymore! Deinstall this library and switch to the newest version \'" .. MAJOR .. "\'.\nPlease also inform the author of the addons, which still use \'%s\', to update their addon code immediately!"
    if _G["LibFilters"] ~= nil then
        _G["LibFilters"] = nil
        local lf1 = "LibFilters 1"
        dfe(libFiltersOldVersionErrorText, lf1, lf1)
    elseif _G["LibFilters2"] ~= nil then
        _G["LibFilters2"] = nil
        local lf2 = "LibFilters 2"
        dfe(libFiltersOldVersionErrorText, lf2, lf2)
    end
end

--Function needed to be called from your addon to start the libFilters instance and enable the filtering!
function LibFilters:InitializeLibFilters()
    checkforOldLibFiltersVersionAndDeactive()

    if isInitialized(false) then return end

    InstallHelpers()
    HookAdditionalFilters()

    LibFilters.isInitialized = true
end


--**********************************************************************************************************************
-- LibFilters global variable and initialization
--**********************************************************************************************************************
function LibFilters.Initialize(eventName, addonName)
    --if addonName ~= MAJOR then return end
    --EVENT_MANAGER:UnregisterForEvent(MAJOR .. "_EVENT_ADD_ON_LOADED", EVENT_ADD_ON_LOADED)
    if isInitialized(false) then return end

    if LibFilters.sv.debug then df("Initialize") end

    loadSavedVariables()

    LibFilters.name     = MAJOR
    LibFilters.version  = MINOR
    LibFilters.author   = "ingeniousclown, Randactyl, Baertram"

    LibFilters.lastInventoryType = nil
    LibFilters.lastFilterType = nil
    LibFilters.activeInventoryType = nil
    LibFilters.activeFilterType = nil

    --Create the slash commands for the chat
    slashCommands()

    --Create the global library variable
    _G[GlobalLibName] = LibFilters
end

--EVENT_MANAGER:RegisterForEvent(MAJOR .. "_EVENT_ADD_ON_LOADED", EVENT_ADD_ON_LOADED, LibFilters.Initialize)
LibFilters.Initialize()