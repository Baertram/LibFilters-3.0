local libFilters = LibFilters3
if not libFilters then return end
libFilters:InitializeLibFilters()

libFilters.test = {}
libFiltersTest = {}

-- /script d(libFiltersTest)
-- /script d(#libFiltersTest)
-- /script d(#libFiltersTest[7])
-- /script libFiltersTest = {}

SLASH_COMMANDS["/testfilters"] = function()
	local filterTag = "TEST"
	local filterTypes = {
		LF_INVENTORY, 
		LF_INVENTORY_QUEST,
		LF_CRAFTBAG,
		LF_BANK_WITHDRAW, 
		LF_BANK_DEPOSIT, 
		LF_GUILDBANK_WITHDRAW,
		LF_GUILDBANK_DEPOSIT, 
		LF_VENDOR_BUY, 
		LF_VENDOR_SELL, 
		LF_VENDOR_BUYBACK,
		LF_VENDOR_REPAIR, 
		LF_GUILDSTORE_SELL, 
		LF_MAIL_SEND, 
		LF_TRADE,
		LF_SMITHING_REFINE, 
		LF_SMITHING_DECONSTRUCT, 
		LF_SMITHING_IMPROVEMENT,
		LF_SMITHING_RESEARCH, 
		LF_ALCHEMY_CREATION, 
		LF_ENCHANTING_CREATION,
		LF_ENCHANTING_EXTRACTION, 
		LF_FENCE_SELL, 
		LF_FENCE_LAUNDER, 
		LF_QUICKSLOT, 
		LF_RETRAIT, 
		LF_HOUSE_BANK_WITHDRAW, 
		LF_HOUSE_BANK_DEPOSIT,
		LF_JEWELRY_REFINE, 
		LF_JEWELRY_CREATION, 
		LF_JEWELRY_DECONSTRUCT, 
		LF_JEWELRY_IMPROVEMENT,
		LF_JEWELRY_RESEARCH, 
		LF_SMITHING_RESEARCH_DIALOG, 
		LF_JEWELRY_RESEARCH_DIALOG,
		LF_INVENTORY_COMPANION
	}

	for _, filterType in pairs(filterTypes) do
		libFilters.test[filterType] = {}
		libFiltersTest[filterType] = {}

		local function filterCallback(...)
			d( "filter test " .. filterType)
			table.insert(libFiltersTest[filterType], {...})
			return false
		end

		if libFilters:IsFilterRegistered(filterTag, filterType) then
			d("Unregistering " .. filterType)
			libFilters:UnregisterFilter(filterTag, filterType)
	 --	   libFilters:RequestUpdate(filterType)
		else
			d("Registering " .. filterType)
			libFilters:RegisterFilter(filterTag, filterType, filterCallback)
	 --	   libFilters:RequestUpdate(filterType)
		end
	end
end

--depends on Item Saver by Randactyl
SLASH_COMMANDS["/testenchant"] = function()
	local filterTag = "TestEnchant"
	local isRegistered = libFilters:IsFilterRegistered(filterTag, LF_ENCHANTING_CREATION)

	local function filterCallback(slotOrBagId, slotIndex)
		local bagId

		if type(slotOrBagId) == "number" then
			if not slotIndex then return false end

			bagId = slotOrBagId
		else
			bagId, slotIndex = ItemSaver.util.GetInfoFromRowControl(slotOrBagId)
		end

		local isSaved, savedSet = ItemSaver_IsItemSaved(bagId, slotIndex)

		return not isSaved
	end

	if not isRegistered then
		libFilters:RegisterFilter(filterTag, LF_ENCHANTING_CREATION, filterCallback)
		libFilters:RequestUpdate(LF_ENCHANTING_CREATION)
		libFilters:RegisterFilter(filterTag, LF_ENCHANTING_EXTRACTION, filterCallback)
		libFilters:RequestUpdate(LF_ENCHANTING_EXTRACTION)
	else
		libFilters:UnregisterFilter(filterTag, LF_ENCHANTING_CREATION)
		libFilters:RequestUpdate(LF_ENCHANTING_CREATION)
		libFilters:UnregisterFilter(filterTag, LF_ENCHANTING_EXTRACTION)
		libFilters:RequestUpdate(LF_ENCHANTING_EXTRACTION)
	end
end