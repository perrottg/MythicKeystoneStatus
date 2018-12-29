local L = LibStub("AceLocale-3.0"):GetLocale("MythicKeystoneStatus")

local selectedCharacter = nil

local defaults = {
	global = {
		options = {
			expandCharacterNames = false,
			showSeasonBest = true,
			showDungeonNames = true,
			showTips = true,
			MinimapButton = {
				hide = false,
			}, 
		},
	},
}

local optionsTable = {
	handler = MythicKeystoneStatus,
	type = "group",
	name = L["General Options"],
	args = {
		displayOptions = {
			type = "group",
			inline = true,
			name = L["Display Options"],
			order = 1,
			args = {			
				showMiniMapButton = {
					type = "toggle",
					name = L["Show Minimap Button"],
					desc = L["Toggles the display of the minimap button."],
					get = function(info)
						local options = MythicKeystoneStatus:GetOptions()
						return not options.MinimapButton.hide
					end,
					set = "ToggleMinimapButton",
					order=1,
				},
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
					end,
					order=2,
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
					end,
					order=3,
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
					end,
					order=4,
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
					end,
					order=5,
				},
			}
		},
		trackedCharactersOption = {
			type = "group",
			inline = true,
			name = L["Remove Tracked Characters"],
			desc = "",
			order = 2,
			args = {
				characterSelect = {
					type = "select",                        
					name = L["Character"],
					desc = L["Select the tracked character to remove."],
					order = 2,
					values = function()
								local list = {}
								local characters = MythicKeystoneStatus.db.global.characters or {}

								for key,value in pairs(characters) do
									list[key] = key
								end

								return list
							 end,
					get = function(info)
							return selectedCharacter
						  end,
					set = function(info, value)                                
							selectedCharacter = value
						  end,
				},
				removeAction = {
					type = "execute",							
					name = L["Remove"],
					desc = L["Click to remove the selected tracked character."],
					order = 3,
					disabled = function()
								  return selectedCharacter == nil
							   end,
					func = function()
						local characters = MythicKeystoneStatus.db.global.characters or {}
						local character = characters[selectedCharacter]

						if character then
							characters[selectedCharacter] = nil
							MythicKeystoneStatus.db.global.characters = characters
						end
					end,
				},
			},
		},

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

	if not options.MinimapButton then
		options.MinimapButton = {}
		options.MinimapButton.hide = false
	end

	return options
end

function MythicKeystoneStatus:GetDefaultOptions()
	return defaults;
end

function MythicKeystoneStatus:SetOptions(options)
	MythicKeystoneStatus.db.global.options = options
end
