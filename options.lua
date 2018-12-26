local L = LibStub("AceLocale-3.0"):GetLocale("MythicKeystoneStatus")

local optionsTable = {
	handler = MythicKeystoneStatus,
	type = "group",
	name = L["General Options"],
	args = {
		displayOptions = {
			type = "group",
			inline = true,
			name = L["Display Options"],
			args = {			
				expandCharacterNames = {
					name = L["Expand Character Names"],
					desc = "Shows the character full name including realm name",
					type = "toggle",
					set = function(info,val)
						local options = MythicKeystoneStatus:GetOptions()
						options.expandCharacterNames = val
						MythicKeystoneStatus:SetOptions(options)
					end,						
					get = function(info)
						local options = MythicKeystoneStatus:GetOptions()
						return options.expandCharacterNames
					end
				},
				showSeasonBest = {
					name = L["Show Season Best"],
					desc = L["Shows the season best statistic in the main tooltp"],
					type = "toggle",
					set = function(info,val)
						local options = MythicKeystoneStatus:GetOptions()
						options.showSeasonBest = val
						MythicKeystoneStatus:SetOptions(options)
					end,						
					get = function(info)
						local options = MythicKeystoneStatus:GetOptions()
						return options.showSeasonBest
					end
				},
				showDungeonNames = {
					name = L["Show Dungeon Names"],
					desc = L["Includes dungeon name when with weekly best and season best statistics."],
					type = "toggle",
					set = function(info,val)
						local options = MythicKeystoneStatus:GetOptions()
						options.showDungeonNames = val
						MythicKeystoneStatus:SetOptions(options)
					end,						
					get = function(info)
						local options = MythicKeystoneStatus:GetOptions()
						return options.showDungeonNames
					end
				},
				showTips = {
					name = L["Show Tips"],
					desc = L["Shows helpful messages at the bottom of the tooltip"],
					type = "toggle",
					set = function(info,val)
						local options = MythicKeystoneStatus:GetOptions()
						options.showTips = val
						MythicKeystoneStatus:SetOptions(options)
					end,						
					get = function(info)
						local options = MythicKeystoneStatus:GetOptions()
						return options.showTips
					end
				},
			}
		}
	}
}

function MythicKeystoneStatus:InitializeOptions()
	local mkscfg = LibStub("AceConfig-3.0")
	mkscfg:RegisterOptionsTable(L["Mythic Keystone Status Options"], optionsTable)

	local mksdia = LibStub("AceConfigDialog-3.0")
	MythicKeystoneStatus.optionsFrame =  mksdia:AddToBlizOptions(L["Mythic Keystone Status Options"], L["Mythic Keystone Status"])
end

function MythicKeystoneStatus:ShowOptions()
	InterfaceOptionsFrame_OpenToCategory(MythicKeystoneStatus.optionsFrame)
	InterfaceOptionsFrame_OpenToCategory(MythicKeystoneStatus.optionsFrame)
end

function MythicKeystoneStatus:GetOptions()
	local options = MythicKeystoneStatus.db.global.options

	if (not options) then
		options = {}
		options.expandCharacterNames = false
		options.showSeasonBest = true
		options.showDungeonNames = true
		options.showTips = true
	end

	return options
end

function MythicKeystoneStatus:SetOptions(options)
	MythicKeystoneStatus.db.global.options = options
end
