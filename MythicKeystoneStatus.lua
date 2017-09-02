MythicKeystoneStatus = LibStub("AceAddon-3.0"):NewAddon("MythicKeystoneStatus", "AceConsole-3.0", "AceEvent-3.0" );

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)
local LibQTip = LibStub('LibQTip-1.0')
local frame = nil
local keystoneStoneDungeons = nil

local textures = {}
textures.alliance = "|TInterface\\FriendsFrame\\PlusManz-Alliance:18|t"
textures.horde = "|TInterface\\FriendsFrame\\PlusManz-Horde:18|t"

local yellow = { r = 1.0, g = 1.0, b = 0.2 }
local gray = { r = 0.5, g = 0.5, b = 0.5 }

local MythicKeystoneStatusLauncher = LDB:NewDataObject("MythicKeystoneStatus", {
		type = "data source",
		text = "Mythic Plus Status",
		label = "MythicKeystoneStatus",
		tocname = "MythicKeystoneStatus",
		icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1.png",
		OnClick = nil,
		OnEnter = function(self)
			frame = self
			MythicKeystoneStatus:ShowToolTip()
		end,
})

local function GetKeystoneDungeonList()
	local dungeons = {}

	local maps = C_ChallengeMode.GetMapTable();

	for i = 1, #maps do
		local mapInfo = maps[i]
		local mapName, _, _, mapTexture = C_ChallengeMode.GetMapInfo(mapInfo);

		tinsert(dungeons, { id = mapInfo, name = mapName, texture = mapTexture });
    end

	table.sort(dungeons, function(a, b) return a.name < b.name end);

	return dungeons
end

function MythicKeystoneStatus:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("MythicKeystoneStatusDB", defaults, true)
	LDBIcon:Register("MythicKeystoneStatus", MythicKeystoneStatusLauncher, self.db.global.MinimapButton)	
end

function MythicKeystoneStatus:OnEnable()
	C_ChallengeMode.RequestMapInfo();
	local dungeons = GetKeystoneDungeonList()
end

function MythicKeystoneStatus:OnDisable()

end

local function GetWeeklyQuestResetTime()
   local now = time()
   local region = GetCurrentRegion()
   local dayOffset = { 2, 1, 0, 6, 5, 4, 3 }
   local regionDayOffset = {{ 2, 1, 0, 6, 5, 4, 3 }, { 4, 3, 2, 1, 0, 6, 5 }, { 3, 2, 1, 0, 6, 5, 4 }, { 4, 3, 2, 1, 0, 6, 5 }, { 4, 3, 2, 1, 0, 6, 5 } }
   local nextDailyReset = GetQuestResetTime()
   local utc = date("!*t", now + nextDailyReset)      
   local reset = regionDayOffset[region][utc.wday] * 86400 + nextDailyReset
   
   return time() + reset  
end

local function GetCharacterInfo()
	local characterInfo = {}
	local _, class = UnitClass("player")

	characterInfo.name = UnitName("player")
	characterInfo.realm = GetRealmName()
	characterInfo.lastUpdate = time()
	characterInfo.class = class
	characterInfo.level = UnitLevel("player")
	characterInfo.faction = UnitFactionGroup("player")
	characterInfo.keystoneStatus = GetKeystoneStatus()

	return characterInfo
end

local function GetCharacters(realm)
	local sortedCharacters = {}
	local characters = MythicKeystoneStatus.db.global.characters or {}

	if (UnitLevel("player") == 110) then	
		local currentCharacter = GetCharacterInfo()
		characters[currentCharacter.name .. "-" .. currentCharacter.realm] = currentCharacter
		MythicKeystoneStatus.db.global.characters = characters
	end

	for key,value in pairs(characters) do
		if (not realm) or (realm == characters[i].realm) then
			tinsert(sortedCharacters, value)
		end
	end

	table.sort(sortedCharacters, function(a, b) return a.name < b.name end)

	return sortedCharacters
end

function GetKeystoneStatus()
	local keystoneStatus = {}
	local dungeons = GetKeystoneDungeonList()

	for i = 1, #dungeons do
		local status = {}
		_, status.weeklyBestTime, status.weeklyBestLevel, affixes = C_ChallengeMode.GetMapPlayerStats(dungeons[i].id);
		status.recentBestTime, status.recentBestLevel = C_ChallengeMode.GetRecentBestForMap(dungeons[i].id);

		if (status.weeklyBestLevel) and ( (not keystoneStatus.weeklyBestLevel) or (status.weeklyBestLevel > keystoneStatus.weeklyBestLevel) ) then 
			keystoneStatus.weeklyBestLevel = status.weeklyBestLevel
		end
		if (status.recentBestLevel) and  ( (not keystoneStatus.recentBestLevel) or (status.recentBestLevel > keystoneStatus.recentBestLevel) ) then
			keystoneStatus.recentBestLevel = status.recentBestLevel
		end
		
		keystoneStatus[dungeons[i].name] = status	
	end

	keystoneStatus.expires = GetWeeklyQuestResetTime()

	return keystoneStatus
end

function MythicKeystoneStatus:ShowSubTooltip(cell, info)	
	if not info then
		return
	end

	local character = info.character
	local type = info.type
	local title = nil

	local subTooltip = MythicKeystoneStatus.subTooltip
	local dungeons = GetKeystoneDungeonList()

	if LibQTip:IsAcquired("MKSsubTooltip") and subTooltip then
		subTooltip:Clear()
	else 
		subTooltip = LibQTip:Acquire("MKSsubTooltip", 3, "LEFT", "LEFT", "RIGHT")
		MythicKeystoneStatus.subTooltip = subTooltip	
	end	

	subTooltip:ClearAllPoints()
	subTooltip:SetClampedToScreen(true)
	subTooltip:SetPoint("TOP", MythicKeystoneStatus.tooltip, "TOP", 30, 0)
	subTooltip:SetPoint("RIGHT", MythicKeystoneStatus.tooltip, "LEFT", -20, 0)

	if (type == "WEEKLY") then
		title = "Weekly Best"
	else
		title = "All-Time Best"
	end

	line = subTooltip:AddLine()	
	subTooltip:SetCell(line, 1, title, nil, "LEFT", 3)
	subTooltip:SetCellTextColor(line, 1, yellow.r, yellow.g, yellow.b)
	subTooltip:AddSeparator(6,0,0,0,0)

	line = subTooltip:AddLine("Dungeon", "Time", "Level")
	subTooltip:SetLineTextColor(line, yellow.r, yellow.g, yellow.b)
	subTooltip:AddSeparator(3,0,0,0,0)

	for i = 1, #dungeons do
		local line = subTooltip:AddLine()
		
		subTooltip:SetCell(line, 1, "|T"..dungeons[i].texture..":0|t " .. dungeons[i].name, nil, "LEFT")

		if (type == "WEEKLY") then
			if (character.keystoneStatus[dungeons[i].name].weeklyBestTime) then
				subTooltip:SetCell(line, 2, GetTimeStringFromSeconds(character.keystoneStatus[dungeons[i].name].weeklyBestTime / 1000), nil, "LEFT")
			else
				subTooltip:SetLineTextColor(line, gray.r, gray.g, gray.b)
			end
			subTooltip:SetCell(line, 3, character.keystoneStatus[dungeons[i].name].weeklyBestLevel, nil, "RIGHT")				
		else 
			if (character.keystoneStatus[dungeons[i].name].recentBestTime) then
				subTooltip:SetCell(line, 2, GetTimeStringFromSeconds(character.keystoneStatus[dungeons[i].name].recentBestTime / 1000), nil, "LEFT")
			else
				subTooltip:SetLineTextColor(line, gray.r, gray.g, gray.b)
			end
			subTooltip:SetCell(line, 3, character.keystoneStatus[dungeons[i].name].recentBestLevel, nil, "RIGHT")	
		end
	end

	subTooltip:Show()
end

local function HideSubTooltip()
	local subTooltip = MythicKeystoneStatus.subTooltip
	if subTooltip then
		LibQTip:Release(subTooltip)
		subTooltip = nil
	end
	GameTooltip:Hide()
	MythicKeystoneStatus.subTooltip = subTooltip
end

local function ShowCharacter(characterInfo)
	local lastReset = WorldBossStatus:GetWeeklyQuestResetTime() - 604800
	local tooltip = MythicKeystoneStatus.tooltip
	local line = tooltip:AddLine()
	local factionIcon = ""
	local dungeons = GetKeystoneDungeonList()
	local weeklyBestLevel = nil
	local recentBestLevel = nil

	if characterInfo.faction and characterInfo.faction == "Alliance" then
		factionIcon = textures.alliance
	elseif characterInfo.faction and characterInfo.faction == "Horde" then
		factionIcon = textures.horde
	end

	tooltip:SetCell(line, 1, factionIcon.." "..characterInfo.name)

	if characterInfo.class then
		local color = RAID_CLASS_COLORS[characterInfo.class]
		tooltip:SetCellTextColor(line, 1, color.r, color.g, color.b)
	end	

	if (characterInfo.lastUpdate > lastReset) then
		weeklyBestLevel = characterInfo.keystoneStatus.weeklyBestLevel
		recentBestLevel = characterInfo.keystoneStatus.recentBestLevel
	end
	
	tooltip:SetCell(line, 2, weeklyBestLevel, nil, "RIGHT")
	tooltip:SetCell(line, 3, recentBestLevel, nil, "RIGHT")

	tooltip:SetCellScript(line, 2, "OnEnter", function(self)
			local info = { character = characterInfo, type = "WEEKLY" }
			MythicKeystoneStatus:ShowSubTooltip(self, info)
		end)

	tooltip:SetCellScript(line, 2, "OnLeave", HideSubTooltip)

	tooltip:SetCellScript(line, 3, "OnEnter", function(self)
			local info = { character = characterInfo, type= "ALLTIME" }
			MythicKeystoneStatus:ShowSubTooltip(self, info)
		end)

	tooltip:SetCellScript(line, 3, "OnLeave", HideSubTooltip)
end

function MythicKeystoneStatus:ShowToolTip()
	C_ChallengeMode.RequestMapInfo();

	local tooltip = MythicKeystoneStatus.tooltip
	local character = GetCharacterInfo()
	local dungeons = GetKeystoneDungeonList()
	local characters = GetCharacters()
	
	if LibQTip:IsAcquired("MythicKeystoneStatusTooltip") and tooltip then
		tooltip:Clear()
	else
		tooltip = LibQTip:Acquire("MythicKeystoneStatusTooltip", 3, "LEFT", "RIGHT", "RIGHT")
		MythicKeystoneStatus.tooltip = tooltip 
	end

	line = tooltip:AddHeader(" ")
	tooltip:SetCell(1, 1, "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1:16|t ".."Mythic Keystone Status", nil, "LEFT", tooltip:GetColumnCount())
	tooltip:AddSeparator(6,0,0,0,0)

	line = tooltip:AddLine("Character", "Weekly", "All-Time")
	tooltip:SetLineTextColor(line, yellow.r, yellow.g, yellow.b)
	tooltip:AddSeparator(3,0,0,0,0)

	for i=1, #characters do		
		ShowCharacter(characters[i])		
	end

	if (frame) then
		tooltip:SetAutoHideDelay(0.01, frame)
		tooltip:SmartAnchorTo(frame)
	end 

	tooltip:UpdateScrolling()
	tooltip:Show()
end