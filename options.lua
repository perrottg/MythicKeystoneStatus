

local optionsTable = {
	handler = MythicKeystoneStatus,
	type = "group",
	name = "General Options",
	args = {
		displayOptions = {
			type = "group",
			inline = true,
			name = "Display Options",
			args = {			
				expandCharacterNames = {
					name = "Expand Character Names",
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
				showRecentBest = {
					name = "Show Recent Best",
					desc = "Shows the recent best statistic in the main tooltp",
					type = "toggle",
					set = function(info,val)
						local options = MythicKeystoneStatus:GetOptions()
						options.showRecentBest = val
						MythicKeystoneStatus:SetOptions(options)
					end,						
					get = function(info)
						local options = MythicKeystoneStatus:GetOptions()
						return options.showRecentBest
					end
				},
				showDungeonNames = {
					name = "Show Dungeon Names",
					desc = "Includes dungeon name when with weekly best and recent best statistics.",
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
					name = "Show Tips",
					desc = "Shows helpful messages at the bottom of the tooltip",
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
	mkscfg:RegisterOptionsTable("Mythic Keystone Status Options", optionsTable)

	local mksdia = LibStub("AceConfigDialog-3.0")
	MythicKeystoneStatus.optionsFrame =  mksdia:AddToBlizOptions("Mythic Keystone Status Options", "Mythic Keystone Status")
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
		options.showRecentBest = true
		options.showDungeonNames = true
		options.showTips = true
	end

	return options
end

function MythicKeystoneStatus:SetOptions(options)
	MythicKeystoneStatus.db.global.options = options
end

function MythicKeystoneStatus:GetOption(info)
	MythicKeystoneStatus:Print(info)
end

function MythicKeystoneStatus:SetOption(info, value)
end