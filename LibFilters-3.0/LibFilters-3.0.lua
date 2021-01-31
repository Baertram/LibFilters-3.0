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
--TODO List - Count: 9                                                                         LastUpdated: 2021-01-31
--**********************************************************************************************************************
--#3 Find out why "RunFilters" is shown duplicate in chat debug mesasges if we are ar the crafting table "deconstruction",
--   once for SMITHING decon and once for JEWELRY decon? Should only be shown for one of both?!
--   And why is there only "RunFilters" debug message but no "callFilterFunc" before or similar which calls runFilter?

--#4 Filters at LF_BANK_WITHDRAW filters the same like LF_BANK_DEPOSIT (After opening the mail send panel and with addon
--  AdvancedFilters enabled)

--#5 LF_HOUSE_BANK_DEPOSIT do not work anymore?

--#6 Filters at LF_HOSUE_BANK_WITHDRAW sometimes react the same (filte the same) as LF_HOUSE_BANK_DEPOSIT?
-->seee addon HideInventoryClutter e.g.

--#7 LF_RETRAIT and FCOItemSaver are not working?

--#9 LF_ENCHANTING* does not chnage the filterTyps in the lastUsed filterTypes properly!

--#10 Bank withdraw does not filter anymore subfilters if AdvancedFilters is enabled



--**********************************************************************************************************************
-- LibFilters information
--**********************************************************************************************************************
local MAJOR, GlobalLibName, MINOR = "LibFilters-3.0", "LibFilters3", 2.0
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
local LibFiltersSVName = "LibFilters_SV"
LibFilters.sv = {}
LibFilters.isInitialized = false
local settings = {}

--Table with the helper functions (overwritten/changed vanilla code for the different LibFilters filterTypes, e.g.
--quickslots/crafting tables filter functions)
LibFilters.helpers = {}

--**********************************************************************************************************************
-- LibFilters debugging
--**********************************************************************************************************************
LibFilters.logger = nil
local logger

------------------------------------------------------------------------------------------------------------------------
-->LibDebugLogger
local function createLogger()
    if logger == nil then
d("[LibFilters-3.0]Logger created")
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

local function isInitialized(initializeIfNot)
    initializeIfNot = initializeIfNot or false
    if not LibFilters.isInitialized then
        if initializeIfNot == true then
            LibFilters:InitializeLibFilters()
        end
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
        --[LF_INVENTORY]          = true, --Do not add here or the HookAdditionalFilter is not applied!
        [LF_MAIL_SEND]          = true,
        [LF_TRADE]              = true,
        [LF_BANK_DEPOSIT]       = true,
        [LF_HOUSE_BANK_DEPOSIT] = true,
        [LF_GUILDBANK_DEPOSIT]  = true,
        [LF_VENDOR_SELL]        = true,
        [LF_FENCE_LAUNDER]      = true,
        [LF_FENCE_SELL]         = true,
        [LF_GUILDSTORE_SELL]    = true,
    }
}

--Crafting filterTypes which use the same inventory. Used to handle the OnShow/OnHide via function
--updateActiveInventoryType
local craftingFilterTypesUsingTheSameInvControl = {
    [enchanting.inventory] = {
        ["doNotHookOnShow"]         =   true,
        ["doNotHookOnHide"]         =   true,
        [LF_ENCHANTING_CREATION]    =   true,
        [LF_ENCHANTING_EXTRACTION]  =   true,
    }
}

--FilterTypes that should not update the active inventory control and filterType via function "registerActiveInventoryTypeUpdate"
-->These filtertypes will use fragments instead to update the correct filterType
local filterTypesNotUpdatingLastInventoryData  = {
    [LF_INVENTORY]          = true,
    [LF_MAIL_SEND]          = true,
    [LF_TRADE]              = true,
    [LF_BANK_DEPOSIT]       = true,
    [LF_HOUSE_BANK_DEPOSIT] = true,
    [LF_GUILDBANK_DEPOSIT]  = true,
    [LF_VENDOR_SELL]        = true,
    [LF_FENCE_LAUNDER]      = true,
    [LF_FENCE_SELL]         = true,
    [LF_GUILDSTORE_SELL]    = true,
}

--Some inventories will be faster than the fragments showing, like LF_CRAFTBAG. We need to assure that the later called
--fragments (e.g. the normal inventory menu bar fragment BACKPACK_MENU_BAR_LAYOUT_FRAGMENT) is not overwriting the
--filterType of LF_CRAFTBAG  with the wrong filterType of the normal inventory again
local blockFilterTypeAtActiveInventoryUpdater = {
    --[filterType] = millisecondsToBlock "updateActiveInventoryType()"
    [LF_CRAFTBAG]                   = 10,
    --Crafting
    [LF_SMITHING_REFINE]            = 10,
    [LF_JEWELRY_REFINE]             = 10,
    [LF_JEWELRY_CREATION]           = 10,
    [LF_SMITHING_CREATION]          = 10,
    [LF_JEWELRY_DECONSTRUCT]        = 10,
    [LF_SMITHING_DECONSTRUCT]       = 10,
    [LF_JEWELRY_IMPROVEMENT]        = 10,
    [LF_SMITHING_IMPROVEMENT]       = 10,
    [LF_JEWELRY_RESEARCH]           = 10,
    [LF_SMITHING_RESEARCH]          = 10,
    --[LF_JEWELRY_RESEARCH_DIALOG]    = 10,
    --[LF_SMITHING_RESEARCH_DIALOG]   = 10,
    --Enchanting
    [LF_ENCHANTING_CREATION]        = 10,
    [LF_ENCHANTING_EXTRACTION]      = 10,
    --Crafting alchemy
    [LF_ALCHEMY_CREATION]           = 10,
    --Crafting provisioner
    [LF_PROVISIONING_COOK]          = 10,
    [LF_PROVISIONING_BREW]          = 10,
    --Crafting retrait / reconstruct
    [LF_RETRAIT]                    = 10,

}
--Flag if any filterType is curently blocked. If true the function updateActiveInventoryType will not update any other
--inventory as long as this variable is set to true. it will be reverted to false automatically after the amount of time
--in milliseconds (defined above in table blockFilterTypeAtActiveInventoryUpdater, per filterType) has ended. See description
--above at table blockFilterTypeAtActiveInventoryUpdater
local currentlyBlockedFilterTypesAtActiveInventoryUpdater = false


local craftingTypeToFilterType = {
    [CRAFTING_TYPE_BLACKSMITHING] = {
        [LF_SMITHING_REFINE]            = LF_SMITHING_REFINE,
        [LF_SMITHING_CREATION]          = LF_SMITHING_CREATION,
        [LF_SMITHING_DECONSTRUCT]       = LF_SMITHING_DECONSTRUCT,
        [LF_SMITHING_IMPROVEMENT]       = LF_SMITHING_IMPROVEMENT,
        [LF_SMITHING_RESEARCH]          = LF_SMITHING_RESEARCH,
        [LF_SMITHING_RESEARCH_DIALOG]   = LF_SMITHING_RESEARCH_DIALOG,
    },
    [CRAFTING_TYPE_JEWELRYCRAFTING] = {
        [LF_SMITHING_REFINE]            = LF_JEWELRY_REFINE,
        [LF_SMITHING_CREATION]          = LF_JEWELRY_CREATION,
        [LF_SMITHING_DECONSTRUCT]       = LF_JEWELRY_DECONSTRUCT,
        [LF_SMITHING_IMPROVEMENT]       = LF_JEWELRY_IMPROVEMENT,
        [LF_SMITHING_RESEARCH]          = LF_JEWELRY_RESEARCH,
        [LF_SMITHING_RESEARCH_DIALOG]   = LF_JEWELRY_RESEARCH_DIALOG,
    },
}
LibFilters.craftingTypeToFilterType = craftingTypeToFilterType

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
    local isMouseVisible = SCENE_MANAGER:IsInUIMode()
    if settings.debug and settings.debugDetails then df("SafeUpdateList - isMouseVisible: %s", tostring(isMouseVisible)) end

    if isMouseVisible then HideMouse() end

    object:UpdateList(...)

    if isMouseVisible then ShowMouse() end
end

--The fragments will handle the update of the active inventory type then, e.g. LF_MAIL_SEND -> BACKPACK_MAIL_LAYOUT_FRAGMENT.
--They will also register the update of their control here with this function registerActiveInventoryTypeUpdate
--But: If a fragment is not hidden/shown properly e.g. by switching from vendor sell to vendor buyback and then back to sell,
--we need to run an updater. This is only possible via the ZO_PlayerInventoryList control then "showing again", thus we need to
--register the update here BUT check for ANY of the fragments also using this ZO_PlayerInventoryList control, to get the correct
--filterType
local function getFilterTypeOfActiveInventoryFragment(filterType)
    if settings.debug then df("getFilterTypeOfActiveInventoryFragment-isValid: %s", tostring(filterTypesNotUpdatingLastInventoryData[filterType] ~= nil)) end
    --Check if the current filterType is a valid "inventory fragment" used filterType
    if filterTypesNotUpdatingLastInventoryData[filterType] == nil then return end
    --Check which fragment is currently active
    for lfilterType, isFragmentEnabled in pairs(fragmentsActiveState) do
        if isFragmentEnabled == true then
            return lfilterType
        end
    end
    return nil
end

local function mapCraftingFilterType(filterType)
    local filterTypeToUse = filterType
    local craftingType = GetCraftingInteractionType()
    filterTypeToUse = (craftingTypeToFilterType[craftingType] ~= nil and craftingTypeToFilterType[craftingType][filterType]) or filterType
    if settings.debug then df("mapCraftingFilterType: filterType: %s, filterTypeToUse: %s, craftingType: %s", tostring(filterType), tostring(filterTypeToUse), tostring(craftingType)) end
    return filterTypeToUse, craftingType
end

--Updating the current and lastUsed inventory and libFilters filterTypes, as the Refresh/Update function of the inventory
--is called
local function updateActiveInventoryType(invOrFragmentType, filterType, isTrueInventoryOrFalseFragment, filterTypeNotUpdatingLastInventoryData, isCraftingInv)
    isTrueInventoryOrFalseFragment = isTrueInventoryOrFalseFragment or false
    filterTypeNotUpdatingLastInventoryData = filterTypeNotUpdatingLastInventoryData or false
    isCraftingInv = isCraftingInv or false
    local invName = LibFilters:GetInventoryName(invOrFragmentType)
    if settings.debug then df("]updateActiveInventoryType[\'%s\']: Blocked: %s, isInv: %s, filterType: %s, invOrFragmentType: %s, filterTypeNotUpdatingLastInventoryData: %s, isCraftingInv: %s", tostring(invName), tostring(currentlyBlockedFilterTypesAtActiveInventoryUpdater), tostring(isTrueInventoryOrFalseFragment), tostring(filterType), tostring(invOrFragmentType), tostring(filterTypeNotUpdatingLastInventoryData), tostring(isCraftingInv)) end
    if currentlyBlockedFilterTypesAtActiveInventoryUpdater == true then return end

    local craftingType = CRAFTING_TYPE_INVALID
    local filterTypeToUse = filterType
    if filterType ~= nil and isCraftingInv == true then
        filterTypeToUse, craftingType = mapCraftingFilterType(filterType)
    end

    local function updateActiveInvNow(p_inv, p_filterType, p_isInv, p_blockMilliseconds)
        df(">>RUN: updateActiveInventoryType - isInv: %s, filterType: %s, blockedMilliseconds: %s",tostring(p_isInv), tostring(p_filterType), tostring(p_blockMilliseconds))
        local lastInventoryType = LibFilters.activeInventoryType
        local lastFilterType = LibFilters.activeFilterType
        if lastInventoryType ~= nil and lastFilterType ~= nil then
            LibFilters.lastInventoryType    = lastInventoryType
            LibFilters.lastFilterType       = lastFilterType
        end
        LibFilters.activeInventoryType  = p_inv
        LibFilters.activeFilterType     = p_filterType

        if currentlyBlockedFilterTypesAtActiveInventoryUpdater == true then
            currentlyBlockedFilterTypesAtActiveInventoryUpdater = false
        end
    end

    --Some inventories will be faster than the fragments showing, like LF_CRAFTBAG. We need to assure that the later called
    --fragments (e.g. the normal inventory menu bar fragment BACKPACK_MENU_BAR_LAYOUT_FRAGMENT) is not overwriting the
    --filterType of LF_CRAFTBAG  with the wrong filterType of the normal inventory again
    local blockMilliseconds = 0
    if filterTypeToUse ~= nil then
        blockMilliseconds = blockFilterTypeAtActiveInventoryUpdater[filterTypeToUse] or 0
        if blockMilliseconds ~= nil and blockMilliseconds > 0 then
            --Will be set here and reset after the update function was called, with a delay of
            --blockMilliseconds
            currentlyBlockedFilterTypesAtActiveInventoryUpdater = true
        end
    end

    local callbackName = "LibFilters_updateActiveInventoryType"

    local function Update()
        if settings.debug then df(">Update: updateActiveInventoryType - Name: %s, Blocked: %s, blockedTime: %s, filterType: %s", tostring(callbackName),tostring(currentlyBlockedFilterTypesAtActiveInventoryUpdater), tostring(blockMilliseconds), tostring(filterTypeToUse)) end
        EVENT_MANAGER:UnregisterForUpdate(callbackName)
        zo_callLater(function()
            updateActiveInvNow(invOrFragmentType, filterTypeToUse, isTrueInventoryOrFalseFragment, blockMilliseconds)
        end, blockMilliseconds)
    end

    --Is the filterType one of many used for the ZO_PlayerInventoryList? Check for the active fragment then and use the
    --fragment's filterType!
    if filterTypeNotUpdatingLastInventoryData == true and filterTypeToUse ~= nil then
        filterTypeToUse = getFilterTypeOfActiveInventoryFragment(filterTypeToUse)
    end
    if settings.debug then df(">filterTypeAfter: %s",tostring(filterTypeToUse)) end

    throttledCall(filterTypeToUse, callbackName, Update)
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

--Register the updater function which calls updateActiveInventoryType for the normal inventories and fragments
local invControlHandlersSet = {}
local function registerActiveInventoryTypeUpdate(inventoryOrFragment, filterType, isInventory, noHandlers)
    noHandlers = noHandlers or false

    --If any filter is enabled the update fucntion of the inventory (e.g. updateInventoryBase) will handle this. But if no
    --filter is registrered (yet/anymore) it wont! So we need to "duplicate" the check here somehow as the inventory's
    --control get's shown
    if not inventoryOrFragment then return end

    local invControlBase = filterTypeToInventory[filterType]
    local invControl = getInventoryControl(inventoryOrFragment, invControlBase)
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

    local isCraftingInv = usedCraftingInventoryTypes[inventoryOrFragment]
    local cBase = (isCraftingInv == true and craftingFilterTypesUsingTheSameInvControl[inventoryOrFragment]) or nil
    local craftingFilterTypeUsesTheSameInvControl = (isCraftingInv == true and cBase ~= nil and craftingFilterTypesUsingTheSameInvControl[inventoryOrFragment][filterType]) or false
    df(">>isCraftingInv: %s, craftingFilterTypeUsesTheSameInvControl: %s", tostring(isCraftingInv), tostring(craftingFilterTypeUsesTheSameInvControl))
    if craftingFilterTypeUsesTheSameInvControl == true then
        --Enchanting e.g.
        if cBase.doNotHookOnShow == true and cBase.doNotHookOnHide == true then
            df("<<ABORT: DoNotHook onShow and OnHide is set, filterType: %s", tostring(filterType))
            return
        end
    end

    local filterTypeNotUpdatingLastInventoryData = (filterType ~= nil and filterTypesNotUpdatingLastInventoryData[filterType]) or false
    df(">filterType: %s, filterTypeNotUpdatingLastInventoryData: %s", tostring(filterType), tostring(filterTypeNotUpdatingLastInventoryData))
    --if filterTypeUsesSameInvControl == true then
        --The fragments will handle the update of the active inventory type then, e.g. LF_MAIL_SEND -> BACKPACK_MAIL_LAYOUT_FRAGMENT.
        --They will also register the update of their control here with this function registerActiveInventoryTypeUpdate
        --But: If a fragment is not hidden/shown properly e.g. by switching from vendor sell to vendor buyback and then back to sell,
        --we need to run an updater. This is only possible via the ZO_PlayerInventoryList control then "showing again", thus we need to
        --register the update here BUT check for ANY of the fragments also using this ZO_PlayerInventoryList control, to get the correct
        --filterType

        --return
    --end

    --Is this a control? And should the handlers be set?
    if not noHandlers and invControlHandlersSet[invControl] == nil and invControl.IsControlHidden ~= nil then
        local invName = LibFilters:GetInventoryName(inventoryOrFragment)
        df(">>>Registering OnShow/OnHide handler: %s, isCraftingInv: %s", tostring(invName), tostring(isCraftingInv))
        if cBase == nil or not cBase.doNotHookOnShow then
            invControl:SetHandler("OnEffectivelyShown", function()
                local linvName = LibFilters:GetInventoryName(inventoryOrFragment)
                if settings.debug then df(">>[OnEffShow]name: %s, filterType: %s, filterTypeNotUpdatingLastInventoryData: %s, isCraftingInv: %s", tostring(linvName), tostring(filterType), tostring(filterTypeNotUpdatingLastInventoryData), tostring(isCraftingInv)) end
                updateActiveInventoryType(inventoryOrFragment, filterType, isInventory, filterTypeNotUpdatingLastInventoryData, isCraftingInv)
            end)
        end
        if cBase == nil or not cBase.doNotHookOnHide then
            invControl:SetHandler("OnEffectivelyHidden", function()
                local linvName = LibFilters:GetInventoryName(inventoryOrFragment)
                if settings.debug then df("<<[OnEffHidden]name: %s, filterType: %s, filterTypeNotUpdatingLastInventoryData: %s, isCraftingInv: %s", tostring(linvName), tostring(filterType), tostring(filterTypeNotUpdatingLastInventoryData), tostring(isCraftingInv)) end
                updateActiveInventoryType(nil, nil, isInventory, nil)
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
    --updateActiveInventoryType(invId, filterType, nil)
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
    --Inventory backpack variables
    INVENTORY = function()
        updatePlayerInventoryType(invBackPack, nil, nil, LF_INVENTORY)
    end,
    BANK_WITHDRAW = function()
        updatePlayerInventoryType(invBank, nil, nil, LF_BANK_WITHDRAW)
    end,
    GUILDBANK_WITHDRAW = function()
        updatePlayerInventoryType(invGuildBank, nil, nil, LF_GUILDBANK_WITHDRAW)
    end,
    HOUSE_BANK_WITHDRAW = function()
        updatePlayerInventoryType(invHouseBank, nil, nil, LF_HOUSE_BANK_WITHDRAW)
    end,
    INVENTORY_QUEST = function()
        updatePlayerInventoryType(invQuestItem, nil, nil, LF_INVENTORY_QUEST)
    end,
    QUICKSLOT = function()
        updateOtherInventoryType(quickslots, nil, nil, LF_QUICKSLOT)
    end,
    CRAFTBAG = function()
        updatePlayerInventoryType(invCraftBag, nil, nil, LF_CRAFTBAG)
    end,

    --Fragments
    BANK_DEPOSIT = function()
        updatePlayerInventoryType(invBackPack, bankInvFragment, nil, LF_BANK_DEPOSIT)
    end,
    GUILDBANK_DEPOSIT = function()
        updatePlayerInventoryType(invBackPack, guildBankInvFragment, nil, LF_GUILDBANK_DEPOSIT)
    end,
    HOUSE_BANK_DEPOSIT = function()
        updatePlayerInventoryType(invBackPack, houseBankInvFragment, nil, LF_HOUSE_BANK_DEPOSIT)
    end,
    VENDOR_SELL = function()
        updatePlayerInventoryType(invBackPack, storeInvFragment, nil, LF_VENDOR_SELL)
    end,
    GUILDSTORE_SELL = function()
        updatePlayerInventoryType(invBackPack, tradingHouseInvFragment, nil, LF_GUILDSTORE_SELL)
    end,
    MAIL_SEND = function()
        updatePlayerInventoryType(invBackPack, mailInvFragment, nil, LF_MAIL_SEND)
    end,
    TRADE = function()
        updatePlayerInventoryType(invBackPack, playerTradeInvFragment, nil, LF_TRADE)
    end,
    FENCE_SELL = function()
        updatePlayerInventoryType(invBackPack, fenceInvFragment, nil, LF_FENCE_SELL)
    end,
    FENCE_LAUNDER = function()
        updatePlayerInventoryType(invBackPack, launderInvFragment, nil, LF_FENCE_LAUNDER)
    end,

    --Other inventory variables
    VENDOR_BUY = function()
        if tradingHouseInvFragment.state ~= SCENE_SHOWN then --"shown"
            updateOtherInventoryType(vendor, nil, function() vendor:GetStoreItems() end, LF_VENDOR_BUY)
        end
    end,
    VENDOR_BUYBACK = function()
        updateOtherInventoryType(buyBack, nil, nil, LF_VENDOR_BUYBACK)
    end,
    VENDOR_REPAIR = function()
        updateOtherInventoryType(repair, nil, nil, LF_VENDOR_REPAIR)
    end,

    --Crafting
    SMITHING_REFINE = function()
        updateCraftingInventoryType(refinementPanel.inventory, nil, nil, nil)
    end,
    SMITHING_CREATION = function()
    end,
    SMITHING_DECONSTRUCT = function()
        updateCraftingInventoryType(deconstructionPanel.inventory, nil, nil, nil)
    end,
    SMITHING_IMPROVEMENT = function()
        updateCraftingInventoryType(improvementPanel.inventory, nil, nil, nil)
    end,
    SMITHING_RESEARCH = function()
        updateCraftingInventoryType(researchPanel, nil, nil, function() researchPanel:Refresh() end)
    end,
    ALCHEMY_CREATION = function()
        updateCraftingInventoryType(alchemy.inventory, nil, nil, nil)
    end,
    ENCHANTING = function()
        updateCraftingInventoryType(enchanting.inventory, nil, nil, nil)
    end,
    RETRAIT = function()
        updateCraftingInventoryType(retrait.inventory, nil, nil, nil)
    end,
    SMITHING_RESEARCH_DIALOG = function()
        dialogUpdaterFunc(researchDialogSelect)
    end,

    --Todo: Add support in the future maybe
    PROVISIONING_COOK = function()
    end,
    PROVISIONING_BREW = function()
    end,
    GUILDSTORE_BROWSE = function()
    end,

 --[[

    --Old updaters for reference
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
    ]]
}
LibFilters.inventoryUpdaters = inventoryUpdaters

------------------------------------------------------------------------------------------------------------------------
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

--Register the filter function, using the inventory/fragment.additionalFilter function/value and the registered filter function at
--the filterType (e.g. LF_INVENTORY) via function runFilters
local function registerAdditionalFilterFunc(p_inventory, filterType)
    if settings.debug and settings.debugDetails then df("callFilterFunc, p_inventory: %s, filterType: %s", tostring(p_inventory), tostring(filterType)) end
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
LibFilters.RegisterAdditionalFilterFunc = registerAdditionalFilterFunc

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
    if settings.debug then df("GetFilterCallback - filterTag: %s, filterType: %s",tostring(filterTag),tostring(filterType)) end
    if not LibFilters:IsFilterRegistered(filterTag, filterType) then return end
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
    if settings.debug then
        local filterTypeIsRegisteredType = filterType or "-IsRegistered all-"
        df("IsFilterRegistered - filterTag: %s, filterType: %s",tostring(filterTag),tostring(filterTypeIsRegisteredType))
    end
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
    if not isInitialized(true) then return end
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

    if not isInitialized(true) then return end
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
    if not isInitialized(true) then return end
    if settings.debug then df("ResetFilterTypeAfterListDialogClose - listDialogControl: %s", tostring(listDialogControl)) end
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
--functions

--Add the LibFilters3_filterType variable to the inventory or fragment (or it's layoutData if it exists),
--and register the "currentInventory" and "currentFilterType" updater functions -> Only for a real inventory, not a fragment
-->Fragment's updates will be called from their stateChange function "fragmentChange" already!
--and add the filterFunction enhancement to the "additionalFilters" of the inventory/fragment
local function addLibFiltersFilterTypeIdentifierAndAddFilterFunctionAndActiveInventoryUpdater(inventoryOrFragment, filterType, isInventory)
    local layoutData = inventoryOrFragment.layoutData or inventoryOrFragment
    layoutData.LibFilters3_filterType = filterType

    if isInventory == true then
        registerActiveInventoryTypeUpdate(inventoryOrFragment, filterType, isInventory, false)
    end

    registerAdditionalFilterFunc(layoutData, filterType)
end

--Hook the inventory layout or inventory to apply additional filter functions
function LibFilters:HookAdditionalFilter(filterType, inventoryOrFragment, isInventory)
    isInventory = isInventory or false
    if settings.debug then df("[HookAdditionalFilter] - isInventory: %s, filterType: %s, invControl: %s", tostring(isInventory), tostring(filterType) .. "=" .. tostring(self:GetFilterTypeName(filterType)), tostring(inventoryOrFragment)) end
    addLibFiltersFilterTypeIdentifierAndAddFilterFunctionAndActiveInventoryUpdater(inventoryOrFragment, filterType, isInventory)

    --[[
    --Old, for reference
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

            inventory.LibFilters3_filterType = libFiltersEnchantingFilterType

            if libFiltersEnchantingFilterType ~= nil and not specialHooksLibFiltersDataRegistered[specialType][libFiltersEnchantingFilterType] then
                registerAdditionalFilterFunc(inventory, libFiltersEnchantingFilterType)
                specialHooksLibFiltersDataRegistered[specialType][libFiltersEnchantingFilterType] = true
            end

            updateActiveInventoryType(inventory, libFiltersEnchantingFilterType, true, false, true)

            --TODO: Not working properly as it will be only called once and not on each filter change at the enchanting table
            --Only add the filterFunctions and the updater of the active inventory etc. once per filterType
            --[[
            if not specialHooksLibFiltersDataRegistered[specialType][libFiltersEnchantingFilterType] then
                addLibFiltersFilterTypeIdentifierAndAddFilterFunctionAndActiveInventoryUpdater(enchanting.inventory, libFiltersEnchantingFilterType, true)
                specialHooksLibFiltersDataRegistered[specialType][libFiltersEnchantingFilterType] = true
            end
            ]]
        end
        ZO_PreHook(enchantingClass, "OnModeUpdated", function(selfEnchanting)
            onEnchantingModeUpdated(selfEnchanting, selfEnchanting.enchantingMode)
        end)
        specialHooksDone[specialType] = true
    end
end

local function fragmentChange(oldState, newState, fragmentId, fragmentName, filterType)
    local debug = settings.debug
    if debug then df("Fragment \'%s\' state change - newState: %s", tostring(fragmentName), tostring(newState)) end
    if newState == SCENE_FRAGMENT_HIDING  then
        if debug then df("<<<<<FRAGMENT HID-ING!") end
        fragmentsActiveState[filterType] = nil
        updateActiveInventoryType(nil, nil, false, nil)
    elseif newState == SCENE_FRAGMENT_HIDDEN then
        fragmentsActiveState[filterType] = false
        if debug then df("<<<FRAGMENT HIDDEN!") end
    elseif newState == SCENE_FRAGMENT_SHOWING then
        fragmentsActiveState[filterType] = nil
        if debug then df(">>>FRAGMENT SHOW-ING!") end
    elseif newState == SCENE_FRAGMENT_SHOWN then
        fragmentsActiveState[filterType] = true
        if debug then df(">>>>>FRAGMENT SHOWN!") end
        filterType = filterType or LibFilters:GetCurrentFilterTypeForInventory(fragmentId)
        updateActiveInventoryType(fragmentId, filterType, false, nil)
    end
end


--Hook all the filters at the different inventory panels (LibFilters filterPanelIds) now
local function HookAdditionalFilters()
    local debug = settings.debug
    if debug then df("Hook additionalFilters") end

    --Hook the inventories (no fragments)
    for filterType, inventory in pairs(filterTypeToInventory) do
        --Do not use if a special inventory register needs to be done -> Is only in this list to get the inventory control
        local doRegister = (filterTypesUsingTheSameInvControl[inventory] == nil or
                (filterTypesUsingTheSameInvControl[inventory] ~= nil and filterTypesUsingTheSameInvControl[inventory][filterType] == nil)) or false
        if doRegister == true and filterTypeToSpecialInventory[filterType] == nil then
            --e.g. LibFilters:HookAdditionalFilter(LF_INVENTORY, inventories[invBackPack], true)
            LibFilters:HookAdditionalFilter(filterType, inventory, true)
        end
    end

    --HookAdditionalFilter: Does not work for enchanting as all filter constants LF_ENCHANTNG* use ENCHANTING.inventory
    --and thus the last call to it (currently LF_ENCHANTING_EXTRACTION) will override the value of before registered ones
    --Hook the special inventories (no fragments)
    for _, specialInventoryData in pairs(filterTypeToSpecialInventory) do
        --Only register once
        local specialInventoryTypeStr = specialInventoryData.type
        if not specialHooksDone[specialInventoryTypeStr] then
            specialHooksLibFiltersDataRegistered[specialInventoryTypeStr] = {}
            --e.g. LibFilters:HookAdditionalFilterSpecial("enchanting", enchanting.inventory)
            LibFilters:HookAdditionalFilterSpecial(specialInventoryTypeStr, specialInventoryData.inventory)
        end
    end

    --Hook the fragments
    for fragmentId, fragmentData in pairs(fragmentToFilterType) do
        --e.g. LibFilters:HookAdditionalFilter(LF_INVENTORY, menuBarInvFragment)
        --LibFilters:HookAdditionalFilter(filterType, fragmentId, false)
        --use the fragment's state change callback!
        local fragmentName = fragmentData.name
        if fragmentName ~= nil and fragmentName ~= "" then
            if _G[fragmentName] ~= nil then
                local filterType
                if type(fragmentData.filterType) == "function" then
                    filterType = fragmentData.filterType()
                else
                    filterType = fragmentData.filterType
                end
                if settings.debug then df("[HookAdditionalFilters-Fragments] - name: %s, filterType: %s, fragment: %s", tostring(fragmentData.name), tostring(filterType), tostring(_G[fragmentName])) end
                _G[fragmentName]:RegisterCallback("StateChange", function(oldState, newState)
                    fragmentChange(oldState, newState, fragmentId, fragmentData.name, filterType)
                end)

                addLibFiltersFilterTypeIdentifierAndAddFilterFunctionAndActiveInventoryUpdater(_G[fragmentName], filterType, false)
            end
        end
    end

    --[[
        --old Hooks into the inventories and fragments, for reference
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
d(">settings.debug: " ..tostring(settings.debug))
    local debug = settings.debug
    if debug then df("InstallHelpers") end
    local helpers = LibFilters.helpers
    for packageName, package in pairs(helpers) do
        local funcName = package.helper.funcName
        local func = package.helper.func
        if debug then df("->Package: %s, funcName: %s", tostring(packageName), tostring(funcName)) end

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
            if debug then df("-->Adding to location: %s ", tostring(locationName)) end
            location[funcName] = func
        end
    end
end
------------------------------------------------------------------------------------------------------------------------
-- HOKS END
------------------------------------------------------------------------------------------------------------------------

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

--Function needed to be called from your addon to start the libFilters instance and enable the filtering!
function LibFilters:InitializeLibFilters()
    debugFunc()

    local isLibInitialized = isInitialized(false)
    if settings.debug then df("InitializeLibFilters - isInitialized: %s", tostring(isLibInitialized)) end
    if isLibInitialized then return end

    if checkforOldLibFiltersVersionAndDeactive() == true then
        d("Old LibFilters version found -> Please deactivate it!")
    end

    InstallHelpers()
    HookAdditionalFilters()

    LibFilters.isInitialized = true
end


--**********************************************************************************************************************
-- LibFilters global variable and initialization
--**********************************************************************************************************************
function LibFilters.Initialize(eventName, addonName)
    if isInitialized(false) then return end

    debugFunc()

    createLogger()

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

local function LibFilters_OnAddOnLoaded(eventName, addonName)
    if addonName ~= MAJOR then return end
    EVENT_MANAGER:UnregisterForEvent(MAJOR .. "_EVENT_ADD_ON_LOADED", EVENT_ADD_ON_LOADED)

    loadSavedVariables()
    if settings.debug then df("EVENT_ADD_ON_LOADED") end
end

EVENT_MANAGER:RegisterForEvent(MAJOR .. "_EVENT_ADD_ON_LOADED", EVENT_ADD_ON_LOADED, LibFilters_OnAddOnLoaded)

LibFilters.Initialize()