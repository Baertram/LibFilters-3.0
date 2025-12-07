------------------------------------------------------------------------------------------------------------------------
--Name, global variable LibFilters3
------------------------------------------------------------------------------------------------------------------------
local libFilters = LibFilters3

local tos = tostring


--Helper variables of ESO

--Helper variables of the library
local constants   =                         libFilters.constants
local mapping     =                         libFilters.mapping

local kbc         =                         constants.keyboard
local gpc         =                         constants.gamepad


--Debugging
local debugFunctions = libFilters.debugFunctions
local dd = debugFunctions.dd


------------------------------------------------------------------------------------------------------------------------
--Local LibFilters speed-up variables and references
------------------------------------------------------------------------------------------------------------------------
--Keyboard
--local inventories =                         kbc.inventories
local playerInv =                           kbc.playerInv
local store =                               kbc.store
local vendorBuyBack =                       kbc.vendorBuyBack
local vendorRepair =                        kbc.vendorRepair
local quickslots  =                         kbc.quickslots
local smithing =                            kbc.smithing
local smithingResearchPanel =               smithing.researchPanel
local researchChooseItemDialog =            kbc.researchChooseItemDialog
local universalDeconstructPanel =           kbc.universalDeconstructPanel
local retrait =                             kbc.retrait

--Gamepad
local invBackpack_GP =                      gpc.invBackpack_GP
local vendorRepair_GP =                     gpc.vendorRepair_GP
local vendorBuy_GP =                        gpc.vendorBuy_GP
local vendorSell_GP =                       gpc.vendorSell_GP
local vendorBuyBack_GP =                    gpc.vendorBuyBack_GP
local fenceSell_GP =                        gpc.invFenceSell_GP
local fenceLaunder_GP =                     gpc.invFenceLaunder_GP
local vendorSellVengeance_GP =              gpc.vendorSellVengeance_GP
local storeWindowComponents_GP =            gpc.store_GP.components

local smithing_GP =                         gpc.smithing_GP
local universalDeconstructPanel_GP =        gpc.universalDeconstructPanel_GP
local companionEquipment_GP =               gpc.companionEquipment_GP

--local enchantingModeToFilterType = mapping.enchantingModeToFilterType
--local LF_ConstantToAdditionalFilterControlSceneFragmentUserdata = mapping.LF_ConstantToAdditionalFilterControlSceneFragmentUserdata
--local getCurrentFilterTypeForInventory = libFilters.GetCurrentFilterTypeForInventory
local libFilters_IsFilterTypeUsingCustomGamepadFragment = libFilters.IsFilterTypeUsingCustomGamepadFragment
local libFilters_GetCurrentFilterType = libFilters.GetCurrentFilterType


------------------------------------------------------------------------------------------------------------------------
--Functions, internally for LibFilters
------------------------------------------------------------------------------------------------------------------------
