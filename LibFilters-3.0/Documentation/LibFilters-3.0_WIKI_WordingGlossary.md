# Wording / Glossary
## filterTag
The string defined by an addon to uniquely describe and reference the filter in the internal tables
(e.g. "addonName1FilterForInventory"). Often the filterType (see bwlow) constant will be concatenated with a prefixed "-" at the end of the filterTag to identify the filterTag's filterType, e.g. "addonName1FilterForInventory-" .. tostring(LF_INVENTORY) -> "addonName1FilterForInventory-1"
## filterType
Also libFiltersFilterType or LF_*constant: The LF_* number constant of the filter, describing the panel where it will be filtered (e.g. LF_INVENTORY for Player Inventory). LF_INVENTORY is number 1 and each other constant increases the number by 1. Never change those constants or exisitng addons will fail/break!
## panel or filterPanel
Basically this is the scene/fragment/control/environment shown where the filterType is used. Player inventory si the panel for LF_INVENTORY
## filterReference
The referenced panel's control/fragment/scene/userdata/table where the filterType applies to. The reference is used for the "is shown"/"is hidden" callbacks of the filterTypes
## filterFunction
A function used to filter the items at the given filterType (filterPanel). The filterFunction will be added to existing ZOs vavilla filter function code (often ZOs stores them in a table attribute ".additionalFilter" at e.g. the PLAYER_INVENTORY.inventories tables or some fragments used for the layout) or to other functions (see helper.lua for the changed ZOs vanilla code functions where LibFilters needs to "hack" into to add it's own filterFunction in addition). Each filterTag and filterType "registered" as a new filter of any addon will be added to the filterfunctions and will be run "in combination" (vanille UI ZOs filterFunctions + LibFilters filterFunctions + maybe other addons filterFunctions -> if the other addons check for existing filterFunctions and do not just overwrite the existing ones and thus break LibFilters).
FilterFunctions can have different parameters (either "inventorySlot" or "bagId, slotIndex"), depending on the filterType they are registered for. Please read below at "Filter functions"
## panel callback
A callback function that fires as the filterPanel is shown or hidden. You define that callback with a uniqueName in your addon so that you can use it to register (show) and unregister (hide9 your filterFunctions, or add additional filter controls (buttons, dropdown boxes,...) for example
