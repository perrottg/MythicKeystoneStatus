local L = LibStub("AceLocale-3.0"):GetLocale("MythicKeystoneStatus")
MythicKeystoneStatus = LibStub("AceAddon-3.0"):NewAddon("MythicKeystoneStatus", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0" );

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)
local LibQTip = LibStub('LibQTip-1.0')
local frame = nil
local keystoneStoneDungeons = nil
local updateDelay = 3

local textures = {}
textures.alliance = "|TInterface\\FriendsFrame\\PlusManz-Alliance:18|t"
textures.horde = "|TInterface\\FriendsFrame\\PlusManz-Horde:18|t"

local yellow = { r = 1.0, g = 1.0, b = 0.2 }
local gray = { r = 0.5, g = 0.5, b = 0.5 }
local green = { r = 0.2, g = 1.0, b = 0.2 }

local MythicKeystoneStatusLauncher = LDB:NewDataObject("MythicKeystoneStatus", {
		type = "data source",
		text = L["Mythic Keystone Status"],
		label = "MythicKeystoneStatus",
		tocname = "MythicKeystoneStatus",
		icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1.png",
		OnClick = function(clickedframe, button)
			MythicKeystoneStatus:ShowOptions()
		end,
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


local function UpdateCharacter()
	--MythicKeystoneStatus:Print("Updating character...")

	if (UnitLevel("player") < 110) then return end

	local characters = MythicKeystoneStatus.db.global.characters or {}
	local currentCharacter = GetCharacterInfo()

	characters[currentCharacter.name .. "-" .. currentCharacter.realm] = currentCharacter
	MythicKeystoneStatus.db.global.characters = characters
end


function MythicKeystoneStatus:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("MythicKeystoneStatusDB", defaults, true)
	LDBIcon:Register("MythicKeystoneStatus", MythicKeystoneStatusLauncher, self.db.global.MinimapButton)	
	MythicKeystoneStatus:InitializeOptions()
end

function MythicKeystoneStatus:OnEnable()
	C_ChallengeMode.RequestMapInfo();
	local dungeons = GetKeystoneDungeonList()

	-- BAG_NEW_ITEMS_UPDATED

	--CHALLENGE_MODE_NEW_RECORD

	--self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
	MythicKeystoneStatus:ScheduleTimer(UpdateCharacter, updateDelay)
end

function MythicKeystoneStatus:OnDisable()
	--self:UnregisterEvent("BAG_UPDATE")
	self:UnregisterEvent("CHALLENGE_MODE_COMPLETED")
end

function MythicKeystoneStatus:CHALLENGE_MODE_COMPLETED(event)
	--MythicKeystoneStatus:Print("CHALLENGE_MODE_COMPLETED event received!")
	MythicKeystoneStatus:ScheduleTimer(UpdateCharacter, updateDelay)
end

function MythicKeystoneStatus:BAG_UPDATE(event, bag)
	MythicKeystoneStatus:Print("BAG_UPDATE event received!")
	MythicKeystoneStatus:ScheduleTimer(UpdateBag, updateDelay)
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


local function GetCharacters(realm)
	local sortedCharacters = {}
	local characters = MythicKeystoneStatus.db.global.characters or {}

	for key,value in pairs(characters) do
		if (not realm) or (realm == characters[i].realm) then
			tinsert(sortedCharacters, value)
		end
	end

	table.sort(sortedCharacters, function(a, b) return a.name < b.name end)

	return sortedCharacters
end

local function GetActiveKeystone()
	local keystoneInfo = nil
	
	for bag = 0, NUM_BAG_SLOTS do
		local slots = GetContainerNumSlots(bag);
		for slot = 1, slots do
			if (GetContainerItemID(bag, slot) == 138019) then
				local keystoneLink = GetContainerItemLink(bag, slot);
				local parts = { strsplit(':', keystoneLink) }
				local keystoneLevel	= tonumber(parts[3]);
				local keystoneDungeon = C_ChallengeMode.GetMapInfo(tonumber(parts[2]));
				
				keystoneInfo = { dungeon = keystoneDungeon, level = keystoneLevel, link = keystoneLink }
			end
		end
	end

	return keystoneInfo;
end


local function UpdateBag()
	MythicKeystoneStatus:Print("Updating bag...")
end


function GetKeystoneStatus()
	local keystoneStatus = {}
	local dungeons = GetKeystoneDungeonList()

	for i = 1, #dungeons do
		local status = {}
		_, status.weeklyBestTime, status.weeklyBestLevel, affixes = C_ChallengeMode.GetMapPlayerStats(dungeons[i].id);
		status.recentBestTime, status.recentBestLevel = C_ChallengeMode.GetRecentBestForMap(dungeons[i].id);

		if (status.weeklyBestLevel) then
			if (not keystoneStatus.weeklyBest) or (keystoneStatus.weeklyBest.level < status.weeklyBestLevel) or 
				( (keystoneStatus.weeklyBest.level == status.weeklyBestlevel) and (keystoneStatus.weeklyBest.time > status.weeklyBestTime) ) then
				keystoneStatus.weeklyBest = {level = status.weeklyBestLevel, time = status.weeklyBestTime, dungeon = dungeons[i].name}
			end
		end

		if (status.recentBestLevel) then
			if (not keystoneStatus.recentBest) or (keystoneStatus.recentBest.level < status.recentBestLevel) or 
				( (keystoneStatus.recentBest.level == status.recentBestLevel) and (keystoneStatus.recentBest.time > status.recentBestTime) ) then
				keystoneStatus.recentBest = {level = status.recentBestLevel, time = status.recentBestTime, dungeon = dungeons[i].name}
			end
		end
		
		keystoneStatus[dungeons[i].name] = status	
	end

	keystoneStatus.activeKeystone = GetActiveKeystone()

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
		title = L["Weekly Best"]
	else
		title = L["Recent Best"]
	end

	line = subTooltip:AddLine()	
	subTooltip:SetCell(line, 1, title, nil, "LEFT", 3)
	subTooltip:SetCellTextColor(line, 1, yellow.r, yellow.g, yellow.b)
	subTooltip:AddSeparator(6,0,0,0,0)

	line = subTooltip:AddLine(L["Dungeon"], L["Time"], L["Level"])
	subTooltip:SetLineTextColor(line, yellow.r, yellow.g, yellow.b)
	subTooltip:AddSeparator(3,0,0,0,0)

	for i = 1, #dungeons do
		local line = subTooltip:AddLine()
		local keystoneStatus = character.keystoneStatus[dungeons[i].name]
		
		subTooltip:SetCell(line, 1, "|T"..dungeons[i].texture..":0|t " .. dungeons[i].name, nil, "LEFT", nil, nil, nil, 10)

		if (type == "WEEKLY") then
			local level = keystoneStatus.weeklyBestLevel

			if (keystoneStatus.weeklyBestTime) then
				subTooltip:SetCell(line, 2, GetTimeStringFromSeconds(keystoneStatus.weeklyBestTime / 1000), nil, "LEFT")
			else
				subTooltip:SetLineTextColor(line, gray.r, gray.g, gray.b)
			end

			if (level) then level = "+"..level end
			subTooltip:SetCell(line, 3, level, nil, "RIGHT")				
		else 

			local level = keystoneStatus.recentBestLevel

			if (keystoneStatus.recentBestTime) then
				subTooltip:SetCell(line, 2, GetTimeStringFromSeconds(keystoneStatus.recentBestTime / 1000), nil, "LEFT")
			else
				subTooltip:SetLineTextColor(line, gray.r, gray.g, gray.b)
			end
			if (level ) then level = "+"..level end
			subTooltip:SetCell(line, 3, level, nil, "RIGHT")	
		end

		subTooltip:SetCellTextColor(line, 3, green.r, green.g, green.b)
	end

	subTooltip:Show()
end

function HideSubTooltip()
	local subTooltip = MythicKeystoneStatus.subTooltip
	if subTooltip then
		LibQTip:Release(subTooltip)
		subTooltip = nil
	end
	GameTooltip:Hide()
	MythicKeystoneStatus.subTooltip = subTooltip
end

local function GetDungeonNameOffset()
	local offset = 0
	local options = MythicKeystoneStatus:GetOptions()

	if (options.showDungeonNames) then 
		offset = 1
	end

	return offset
end

local function GetRecentBestOffset()
	local offset = 0
	local options = MythicKeystoneStatus:GetOptions()

	if (options.showRecentBest) then
		offset = 1 + GetDungeonNameOffset()
	end

	return offset
end

local function ShowCharacter(characterInfo)
	local lastReset = WorldBossStatus:GetWeeklyQuestResetTime() - 604800
	local tooltip = MythicKeystoneStatus.tooltip
	local line = tooltip:AddLine()
	local factionIcon = ""
	local dungeons = GetKeystoneDungeonList()
	local keystoneStatus = characterInfo.keystoneStatus
	local characterName = characterInfo.name
	local dungeonNameOffset = GetDungeonNameOffset()
	local recentBestOffset = GetRecentBestOffset()
	local options = MythicKeystoneStatus:GetOptions()


	if (options.expandCharacterNames) then
		characterName = characterInfo.name .. "-" .. characterInfo.realm
	end

	if characterInfo.faction and characterInfo.faction == "Alliance" then
		factionIcon = textures.alliance
	elseif characterInfo.faction and characterInfo.faction == "Horde" then
		factionIcon = textures.horde
	end

	tooltip:SetCell(line, 1, factionIcon.." "..characterName)

	if characterInfo.class then
		local color = RAID_CLASS_COLORS[characterInfo.class]
		tooltip:SetCellTextColor(line, 1, color.r, color.g, color.b)
	end	

	if (characterInfo.lastUpdate > lastReset) and (keystoneStatus.weeklyBest) then
		if (options.showDungeonNames) then
			tooltip:SetCell(line, 2, keystoneStatus.weeklyBest.dungeon, nil, "RIGHT", nil, nil, 10)
		end
		tooltip:SetCell(line, 2 + dungeonNameOffset, "+" .. keystoneStatus.weeklyBest.level, nil, "RIGHT")
	end
	tooltip:SetCellTextColor(line, 2 + dungeonNameOffset, green.r, green.g, green.b)

	tooltip:SetCellScript(line, 2 + dungeonNameOffset, "OnEnter", function(self)
			local info = { character = characterInfo, type = "WEEKLY" }
			MythicKeystoneStatus:ShowSubTooltip(self, info)
		end)

	tooltip:SetCellScript(line, 2 + dungeonNameOffset, "OnLeave", HideSubTooltip)

	if (options.showRecentBest) then
		if (keystoneStatus.recentBest) then
			if (options.showDungeonNames) then 
				tooltip:SetCell(line, 4, keystoneStatus.recentBest.dungeon, nil, "RIGHT", nil, nil, 10)
			end
			tooltip:SetCell(line, 3 + (2 * dungeonNameOffset), "+" .. keystoneStatus.recentBest.level, nil, "RIGHT")
		end		
		tooltip:SetCellTextColor(line, 3 + (2 * dungeonNameOffset), green.r, green.g, green.b)

		tooltip:SetCellScript(line, 3 + (2 * dungeonNameOffset), "OnEnter", function(self)
				local info = { character = characterInfo, type= "RECENT" }
				MythicKeystoneStatus:ShowSubTooltip(self, info)
			end)

		tooltip:SetCellScript(line, 3 + (2 * dungeonNameOffset), "OnLeave", HideSubTooltip)
	end

	if (characterInfo.lastUpdate > lastReset) and (keystoneStatus.activeKeystone) then
		tooltip:SetCell(line, 3 + recentBestOffset + dungeonNameOffset, keystoneStatus.activeKeystone.dungeon, nil, "RIGHT", nil, nil, 10)
		tooltip:SetCell(line, 4 + recentBestOffset + dungeonNameOffset, "+" .. keystoneStatus.activeKeystone.level, nil, "RIGHT")
	end
	tooltip:SetCellTextColor(line, 4 + recentBestOffset + dungeonNameOffset, green.r, green.g, green.b)
end

function MythicKeystoneStatus:ShowToolTip()
	C_ChallengeMode.RequestMapInfo();
	UpdateCharacter()

	local tooltip = MythicKeystoneStatus.tooltip
	local character = GetCharacterInfo()
	local dungeons = GetKeystoneDungeonList()
	local characters = GetCharacters()
	local columnCount = 5
	local dungeonNameOffset = GetDungeonNameOffset()
	local recentBestOffset = GetRecentBestOffset()
	local weeklyBestTitle = L["Weekly"]
	local recentBestTitle = L["Recent"]
	local options = MythicKeystoneStatus:GetOptions()

	if (options.showDungeonNames) then
		weeklyBestTitle = L["Weekly Best"]
		recentBestTitle = L["Recent Best"]
	end

	columnCount = 4 + dungeonNameOffset + recentBestOffset

	if LibQTip:IsAcquired("MythicKeystoneStatusTooltip") and tooltip then
		tooltip:Clear()
	else
		tooltip = LibQTip:Acquire("MythicKeystoneStatusTooltip", columnCount, "LEFT", "RIGHT", "RIGHT", "RIGHT", "RIGHT")
		MythicKeystoneStatus.tooltip = tooltip 
	end

	line = tooltip:AddHeader(" ")
	tooltip:SetCell(1, 1, "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1:16|t "..L["Mythic Keystone Status"], nil, "LEFT", tooltip:GetColumnCount())
	tooltip:AddSeparator(6,0,0,0,0)

	line = tooltip:AddLine()
	tooltip:SetCell(line, 1, L["Character"])
	tooltip:SetCellTextColor(line, 1, yellow.r, yellow.g, yellow.b)

	tooltip:SetCell(line, 2, weeklyBestTitle, nil, "RIGHT", 1 + dungeonNameOffset)
	tooltip:SetCellTextColor(line, 2, yellow.r, yellow.g, yellow.b)

	if (options.showRecentBest) then
		tooltip:SetCell(line, 3 + dungeonNameOffset, recentBestTitle, nil, "RIGHT", 1 + dungeonNameOffset)
		tooltip:SetCellTextColor(line, 3 + dungeonNameOffset, yellow.r, yellow.g, yellow.b)
		column = 6
	end

	tooltip:SetCell(line, 3 + recentBestOffset + dungeonNameOffset, L["Active Keystone"], nil, "RIGHT", 2)
	tooltip:SetCellTextColor(line, 3 + recentBestOffset + dungeonNameOffset, yellow.r, yellow.g, yellow.b)

	tooltip:AddSeparator(3,0,0,0,0)

	for i=1, #characters do		
		ShowCharacter(characters[i])		
	end

	if (options.showTips) then
		tooltip:AddSeparator(6,0,0,0,0)
		line = tooltip:AddLine()
		tooltip:SetCell(line, 1, L["TIP: Hover over level number for more details"], nil, "LEFT", columnCount)
	end


	if (frame) then
		tooltip:SetAutoHideDelay(0.01, frame)
		tooltip:SmartAnchorTo(frame)
	end 

	tooltip:UpdateScrolling()
	tooltip:Show()
end