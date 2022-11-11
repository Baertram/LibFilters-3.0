Last updated: 2022-11-11
```
         [1]	= "LF_INVENTORY",
	 [2]	= "LF_BANK_WITHDRAW",
	 [3]	= "LF_BANK_DEPOSIT",
	 [4]	= "LF_GUILDBANK_WITHDRAW",
	 [5]	= "LF_GUILDBANK_DEPOSIT",
	 [6]	= "LF_VENDOR_BUY",
	 [7]	= "LF_VENDOR_SELL",
	 [8]	= "LF_VENDOR_BUYBACK",
	 [9]	= "LF_VENDOR_REPAIR",
	 [10]  	= "LF_GUILDSTORE_BROWSE",
	 [11]  	= "LF_GUILDSTORE_SELL",
	 [12]  	= "LF_MAIL_SEND",
	 [13]  	= "LF_TRADE",
	 [14]  	= "LF_SMITHING_REFINE",
	 [15]  	= "LF_SMITHING_CREATION",
	 [16]  	= "LF_SMITHING_DECONSTRUCT",
	 [17]  	= "LF_SMITHING_IMPROVEMENT",
	 [18]  	= "LF_SMITHING_RESEARCH",
	 [19]  	= "LF_ALCHEMY_CREATION",
	 [20]  	= "LF_ENCHANTING_CREATION",
	 [21]  	= "LF_ENCHANTING_EXTRACTION",
	 [22]  	= "LF_PROVISIONING_COOK",
	 [23]  	= "LF_PROVISIONING_BREW",
	 [24]  	= "LF_FENCE_SELL",
	 [25]  	= "LF_FENCE_LAUNDER",
	 [26]  	= "LF_CRAFTBAG",
	 [27]  	= "LF_QUICKSLOT",
	 [28]  	= "LF_RETRAIT",
	 [29]  	= "LF_HOUSE_BANK_WITHDRAW",
	 [30]  	= "LF_HOUSE_BANK_DEPOSIT",
	 [31]  	= "LF_JEWELRY_REFINE",
	 [32]  	= "LF_JEWELRY_CREATION",
	 [33]  	= "LF_JEWELRY_DECONSTRUCT",
	 [34]  	= "LF_JEWELRY_IMPROVEMENT",
	 [35]  	= "LF_JEWELRY_RESEARCH",
	 [36]  	= "LF_SMITHING_RESEARCH_DIALOG",
	 [37]  	= "LF_JEWELRY_RESEARCH_DIALOG",
	 [38]  	= "LF_INVENTORY_QUEST",
	 [39]  	= "LF_INVENTORY_COMPANION",
```

**Attention:**
The UniversalDeconstruction panel does not provide it's own LF_UNIVERSAL_DECON filterTypes as it is reusing the already provided filterTypes at the different UniversalDecon tabs "all", "weapons", "armor", "jewelry" and "enchantments":<br>
```
"all" = LF_SMITHING_DECONSTRUCT
"weapons"  = LF_SMITHING_DECONSTRUCT
"armor"  = LF_SMITHING_DECONSTRUCT
"jewelry"  = LF_JEWELRY_DECONSTRUCT
"enchantments"  = LF_ENCHANTING_EXTRACT
```
The callback API functions and other API functions (returning the currently active panel) will provide an addition return parameter returning the active UniversalDeconstruction tab if UniversalDecon panel is shown.<br>
Else this additional return parameter will be nil!<br>
<br>
