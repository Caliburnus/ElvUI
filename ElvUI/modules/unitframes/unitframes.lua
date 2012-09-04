local E, L, V, P, G, _ = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
local UF = E:NewModule('UnitFrames', 'AceTimer-3.0', 'AceEvent-3.0', 'AceHook-3.0');
local LSM = LibStub("LibSharedMedia-3.0");
UF.LSM = LSM

local _, ns = ...
local ElvUF = ns.oUF
local AceTimer = LibStub:GetLibrary("AceTimer-3.0")
assert(ElvUF, "ElvUI was unable to locate oUF.")

local opposites = {
	['DEBUFFS'] = 'BUFFS',
	['BUFFS'] = 'DEBUFFS'
}

local removeMenuOptions = {
	["SET_FOCUS"] = true,
	["CLEAR_FOCUS"] = true,
	["MOVE_PLAYER_FRAME"] = true,
	["MOVE_TARGET_FRAME"] = true,
	["PET_ABANDON"] = E.myclass ~= 'HUNTER',
}

UF['headerstoload'] = {}
UF['unitgroupstoload'] = {}
UF['unitstoload'] = {}

UF['headers'] = {}
UF['groupunits'] = {}
UF['units'] = {}

UF['statusbars'] = {}
UF['fontstrings'] = {}
UF['badHeaderPoints'] = {
	['TOP'] = 'BOTTOM',
	['LEFT'] = 'RIGHT',
	['BOTTOM'] = 'TOP',
	['RIGHT'] = 'LEFT',
}

UF['classMaxResourceBar'] = {
	['DEATHKNIGHT'] = 6,
	['PALADIN'] = 5,
	['WARLOCK'] = 4,
	['PRIEST'] = 3,
	['MONK'] = 5,
	['MAGE'] = 6,
}

local find = string.find
local gsub = string.gsub

function UF:Construct_UF(frame, unit)
	frame:RegisterForClicks("AnyUp")
	frame:SetScript('OnEnter', UnitFrame_OnEnter)
	frame:SetScript('OnLeave', UnitFrame_OnLeave)	
	
	frame.menu = self.SpawnMenu
	
	frame:SetFrameLevel(5)
	
	if not self['groupunits'][unit] then
		local stringTitle = E:StringTitle(unit)
		if stringTitle:find('target') then
			stringTitle = gsub(stringTitle, 'target', 'Target')
		end
		self["Construct_"..stringTitle.."Frame"](self, frame, unit)
	else
		UF["Construct_"..E:StringTitle(self['groupunits'][unit]).."Frames"](self, frame, unit)
	end
	
	self:Update_StatusBars()
	self:Update_FontStrings()	
	return frame
end

function UF:GetPositionOffset(position, offset)
	if not offset then offset = 2; end
	local x, y = 0, 0
	if find(position, 'LEFT') then
		x = offset
	elseif find(position, 'RIGHT') then
		x = -offset
	end					
	
	if find(position, 'TOP') then
		y = -offset
	elseif find(position, 'BOTTOM') then
		y = offset
	end
	
	return x, y
end

function UF:GetAuraOffset(p1, p2)
	local x, y = 0, 0
	if p1 == "RIGHT" and p2 == "LEFT" then
		x = -3
	elseif p1 == "LEFT" and p2 == "RIGHT" then
		x = 3
	end
	
	if find(p1, 'TOP') and find(p2, 'BOTTOM') then
		y = -1
	elseif find(p1, 'BOTTOM') and find(p2, 'TOP') then
		y = 1
	end
	
	return E:Scale(x), E:Scale(y)
end

function UF:GetAuraAnchorFrame(frame, attachTo, isConflict)
	if isConflict then
		E:Print(string.format(L['%s frame(s) has a conflicting anchor point, please change either the buff or debuff anchor point so they are not attached to each other. Forcing the debuffs to be attached to the main unitframe until fixed.'], E:StringTitle(frame:GetName())))
	end
	
	if isConflict or attachTo == 'FRAME' then
		return frame
	elseif attachTo == 'BUFFS' then
		return frame.Buffs
	elseif attachTo == 'DEBUFFS' then
		return frame.Debuffs
	else
		return frame
	end
end

function UF:ClearChildPoints(...)
	for i=1, select("#", ...) do
		local child = select(i, ...)
		child:ClearAllPoints()
	end
end

function UF:UpdateColors()
	local db = self.db.colors
	local tapped = db.tapped
	local dc = db.disconnected
	local mana = db.power.MANA
	local rage = db.power.RAGE
	local focus = db.power.FOCUS
	local energy = db.power.ENERGY
	local runic = db.power.RUNIC_POWER
	local good = db.reaction.GOOD
	local bad = db.reaction.BAD
	local neutral = db.reaction.NEUTRAL
	local health = db.health
	
	ElvUF['colors'] = setmetatable({
		tapped = {tapped.r, tapped.g, tapped.b},
		disconnected = {dc.r, dc.g, dc.b},
		health = {health.r, health.g, health.b},
		power = setmetatable({
			["MANA"] = {mana.r, mana.g, mana.b},
			["RAGE"] = {rage.r, rage.g, rage.b},
			["FOCUS"] = {focus.r, focus.g, focus.b},
			["ENERGY"] = {energy.r, energy.g, energy.b},
			["RUNES"] = {0.55, 0.57, 0.61},
			["RUNIC_POWER"] = {runic.r, runic.g, runic.b},
			["AMMOSLOT"] = {0.8, 0.6, 0},
			["FUEL"] = {0, 0.55, 0.5},
			["POWER_TYPE_STEAM"] = {0.55, 0.57, 0.61},
			["POWER_TYPE_PYRITE"] = {0.60, 0.09, 0.17},
		}, {__index = ElvUF['colors'].power}),
		runes = setmetatable({
				[1] = {1, 0, 0},   -- blood
				[2] = {0, .5, 0},  -- unholy
				[3] = {0, 1, 1},   -- frost
				[4] = {.9, .1, 1}, -- death				
		}, {__index = ElvUF['colors'].runes}),
		reaction = setmetatable({
			[1] = {bad.r, bad.g, bad.b}, -- Hated
			[2] = {bad.r, bad.g, bad.b}, -- Hostile
			[3] = {bad.r, bad.g, bad.b}, -- Unfriendly
			[4] = {neutral.r, neutral.g, neutral.b}, -- Neutral
			[5] = {good.r, good.g, good.b}, -- Friendly
			[6] = {good.r, good.g, good.b}, -- Honored
			[7] = {good.r, good.g, good.b}, -- Revered
			[8] = {good.r, good.g, good.b}, -- Exalted	
		}, {__index = ElvUF['colors'].reaction}),
		smooth = setmetatable({
			1, 0, 0,
			1, 1, 0,
			health.r, health.g, health.b
		}, {__index = ElvUF['colors'].smooth}),
		
	}, {__index = ElvUF['colors']})
end

function UF:Update_StatusBars()
	for statusbar in pairs(UF['statusbars']) do
		if statusbar and statusbar:GetObjectType() == 'StatusBar' then
			statusbar:SetStatusBarTexture(LSM:Fetch("statusbar", self.db.statusbar))
		end
	end
end

function UF:Update_StatusBar(bar)
	bar:SetStatusBarTexture(LSM:Fetch("statusbar", self.db.statusbar))
end

function UF:Update_FontString(object)
	object:FontTemplate(LSM:Fetch("font", self.db.font), self.db.fontSize, self.db.fontOutline)
end

function UF:Update_FontStrings()
	for font in pairs(UF['fontstrings']) do
		font:FontTemplate(LSM:Fetch("font", self.db.font), self.db.fontSize, self.db.fontOutline)
	end
end

function UF:Configure_FontString(obj)
	UF['fontstrings'][obj] = true
	obj:FontTemplate() --This is temporary.
end

function UF:ChangeVisibility(header, visibility)
	if(visibility) then
		local type, list = string.split(' ', visibility, 2)
		if(list and type == 'custom') then
			RegisterAttributeDriver(header, 'state-visibility', list)
		end
	end	
end

function UF:Update_AllFrames()
	if InCombatLockdown() then self:RegisterEvent('PLAYER_REGEN_ENABLED'); return end
	if E.private["unitframe"].enable ~= true then return; end
	self:UpdateColors()
	self:Update_FontStrings()
	self:Update_StatusBars()	
	
	for unit in pairs(self['units']) do
		if self.db['units'][unit].enable then
			self[unit]:Enable()
			self[unit]:Update()
		else
			self[unit]:Disable()
		end
	end

	for unit, group in pairs(self['groupunits']) do
		if self.db['units'][group].enable then
			self[unit]:Enable()
			self[unit]:Update()
		else
			self[unit]:Disable()
		end
	end	
	
	self:UpdateAllHeaders()
end

function UF:CreateAndUpdateUFGroup(group, numGroup)
	if InCombatLockdown() then self:RegisterEvent('PLAYER_REGEN_ENABLED'); return end

	for i=1, numGroup do
		local unit = group..i
		local frameName = E:StringTitle(unit)
		frameName = frameName:gsub('t(arget)', 'T%1')		
		if not self[unit] then
			self['groupunits'][unit] = group;	
			self[unit] = ElvUF:Spawn(unit, 'ElvUF_'..frameName)
			self[unit].index = i
			self[unit]:SetParent(ElvUF_Parent)
			self[unit]:SetID(i)
		end
		
		local frameName = E:StringTitle(group)
		frameName = frameName:gsub('t(arget)', 'T%1')		
		self[unit].Update = function()
			UF["Update_"..E:StringTitle(frameName).."Frames"](self, self[unit], self.db['units'][group])	
		end
		
		if self.db['units'][group].enable then
			self[unit]:Enable()
			self[unit].Update()
			
			if self[unit].isForced then
				self:ForceShow(self[unit])		
			end
		else
			self[unit]:Disable()
		end
	end
end

function UF:CreateAndUpdateHeaderGroup(group, groupFilter, template)
	if InCombatLockdown() then self:RegisterEvent('PLAYER_REGEN_ENABLED'); return end

	local db = self.db['units'][group]
	if not self[group] then
		ElvUF:RegisterStyle("ElvUF_"..E:StringTitle(group), UF["Construct_"..E:StringTitle(group).."Frames"])
		ElvUF:SetActiveStyle("ElvUF_"..E:StringTitle(group))

		local maxUnits, startingIndex = MAX_RAID_MEMBERS, -1
		if db.maxColumns and db.unitsPerColumn then
			startingIndex = -math.min(db.maxColumns * db.unitsPerColumn, maxUnits) + 1			
		end

		if template then
			self[group] = ElvUF:SpawnHeader("ElvUF_"..E:StringTitle(group), nil, 'raid', 
				'point', self.db['units'][group].point, 
				'oUF-initialConfigFunction', ([[self:SetWidth(%d); self:SetHeight(%d); self:SetFrameLevel(5)]]):format(db.width, db.height), 
				'template', template, 
				'columnAnchorPoint', db.columnAnchorPoint,
				'maxColumns', db.maxColumns,
				'unitsPerColumn', db.unitsPerColumn,
				'point', db.point,
				'columnSpacing', db.columnSpacing,
				'xOffset', db.xOffset,
				'yOffset', db.yOffset,
				'startingIndex', startingIndex,
				'groupFilter', groupFilter)
		else
			self[group] = ElvUF:SpawnHeader("ElvUF_"..E:StringTitle(group), nil, 'raid', 
				'point', self.db['units'][group].point, 
				'oUF-initialConfigFunction', ([[self:SetWidth(%d); self:SetHeight(%d); self:SetFrameLevel(5)]]):format(db.width, db.height), 
				'columnAnchorPoint', db.columnAnchorPoint,
				'maxColumns', db.maxColumns,
				'unitsPerColumn', db.unitsPerColumn,
				'point', db.point,
				'columnSpacing', db.columnSpacing,
				'xOffset', db.xOffset,
				'yOffset', db.yOffset,
				'startingIndex', startingIndex,
				'groupFilter', groupFilter)
		end
		
		self[group]:SetParent(ElvUF_Parent)
		RegisterAttributeDriver(self[group], 'state-visibility', 'show')	
		self[group].dirtyWidth, self[group].dirtyHeight = self[group]:GetSize()
		RegisterAttributeDriver(self[group], 'state-visibility', 'hide')	

		if not db.maxColumns then
			self[group]:SetAttribute('startingIndex', 1)
		end
		
		self['headers'][group] = self[group]
		self[group].groupName = group
	end
	
	self[group].db = db
	
	self[group].Update = function()
		local db = self.db['units'][group]
		if db.enable ~= true then return end
		UF["Update_"..E:StringTitle(group).."Header"](self, self[group], db)
		
		for i=1, self[group]:GetNumChildren() do
			local child = select(i, self[group]:GetChildren())
			UF["Update_"..E:StringTitle(group).."Frames"](self, child, self.db['units'][group])

			if _G[child:GetName()..'Pet'] then
				UF["Update_"..E:StringTitle(group).."Frames"](self, _G[child:GetName()..'Pet'], self.db['units'][group])
			end
			
			if _G[child:GetName()..'Target'] then
				UF["Update_"..E:StringTitle(group).."Frames"](self, _G[child:GetName()..'Target'], self.db['units'][group])
			end			
		end			
	end	

	if self.db['units'][group].enable then
		self[group].Update()
	else
		self[group]:SetAttribute("showParty", false)
		self[group]:SetAttribute("showRaid", false)
		self[group]:SetAttribute("showSolo", false)	
	end
end

function UF:PLAYER_REGEN_ENABLED()
	self:Update_AllFrames()
	self:UnregisterEvent('PLAYER_REGEN_ENABLED')
end

function UF:CreateAndUpdateUF(unit)
	assert(unit, 'No unit provided to create or update.')
	if InCombatLockdown() then self:RegisterEvent('PLAYER_REGEN_ENABLED'); return end

	local frameName = E:StringTitle(unit)
	frameName = frameName:gsub('t(arget)', 'T%1')
	if not self[unit] then
		self[unit] = ElvUF:Spawn(unit, 'ElvUF_'..frameName)
		self['units'][unit] = unit
	end

	self[unit].Update = function()
		UF["Update_"..frameName.."Frame"](self, self[unit], self.db['units'][unit])
	end

	if self.db['units'][unit].enable then
		self[unit]:Enable()
		self[unit].Update()
	else
		self[unit]:Disable()
	end
	
	if self[unit]:GetParent() ~= ElvUF_Parent then
		self[unit]:SetParent(ElvUF_Parent)
	end
end


function UF:LoadUnits()
	for _, unit in pairs(self['unitstoload']) do
		self:CreateAndUpdateUF(unit)
	end	
	self['unitstoload'] = nil
	
	for group, numGroup in pairs(self['unitgroupstoload']) do
		self:CreateAndUpdateUFGroup(group, numGroup)
	end
	self['unitgroupstoload'] = nil
	
	for group, groupOptions in pairs(self['headerstoload']) do
		local groupFilter, template
		if type(groupOptions) == 'table' then
			groupFilter, template = unpack(groupOptions)
		end

		self:CreateAndUpdateHeaderGroup(group, groupFilter, template)
	end
	self['headerstoload'] = nil
end

function UF:UpdateAllHeaders(event)	
	if InCombatLockdown() then
		self:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateAllHeaders')
		return
	end
	
	if event == 'PLAYER_REGEN_ENABLED' then
		self:UnregisterEvent('PLAYER_REGEN_ENABLED')
	end
		
	local _, instanceType = IsInInstance();
	local ORD = ns.oUF_RaidDebuffs or oUF_RaidDebuffs
	if ORD then
		ORD:ResetDebuffData()
		
		if instanceType == "party" or instanceType == "raid" then
			ORD:RegisterDebuffs(E.global.unitframe.aurafilters.RaidDebuffs.spells)
		else
			ORD:RegisterDebuffs(E.global.unitframe.aurafilters.CCDebuffs.spells)
		end
	end	
	
	for _, header in pairs(UF['headers']) do
		header:Update()
	end	
	
	if E.private.unitframe.disableBlizzard then
		ElvUF:DisableBlizzard('party')	
	end
end

function HideRaid()
	if InCombatLockdown() then return end
	CompactRaidFrameManager:Kill()
	local compact_raid = CompactRaidFrameManager_GetSetting("IsShown")
	if compact_raid and compact_raid ~= "0" then 
		CompactRaidFrameManager_SetSetting("IsShown", "0")
	end
end

function UF:DisableBlizzard(event)
	hooksecurefunc("CompactRaidFrameManager_UpdateShown", HideRaid)
	CompactRaidFrameManager:HookScript('OnShow', HideRaid)
	CompactRaidFrameContainer:UnregisterAllEvents()
	
	HideRaid()
	hooksecurefunc("CompactUnitFrame_RegisterEvents", CompactUnitFrame_UnregisterEvents)
end

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local HandleFrame = function(baseName)
	local frame
	if(type(baseName) == 'string') then
		frame = _G[baseName]
	else
		frame = baseName
	end

	if(frame) then
		frame:UnregisterAllEvents()
		frame:Hide()

		-- Keep frame hidden without causing taint
		frame:SetParent(hiddenParent)

		local health = frame.healthbar
		if(health) then
			health:UnregisterAllEvents()
		end

		local power = frame.manabar
		if(power) then
			power:UnregisterAllEvents()
		end

		local spell = frame.spellbar
		if(spell) then
			spell:UnregisterAllEvents()
		end

		local altpowerbar = frame.powerBarAlt
		if(altpowerbar) then
			altpowerbar:UnregisterAllEvents()
		end
	end
end

function ElvUF:DisableBlizzard(unit)
	if(not unit) or InCombatLockdown() then return end

	if(unit == 'player') then
		HandleFrame(PlayerFrame)

		-- For the damn vehicle support:
		PlayerFrame:RegisterEvent('UNIT_ENTERING_VEHICLE')
		PlayerFrame:RegisterEvent('UNIT_ENTERED_VEHICLE')
		PlayerFrame:RegisterEvent('UNIT_EXITING_VEHICLE')
		PlayerFrame:RegisterEvent('UNIT_EXITED_VEHICLE')
		PlayerFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
		
		-- User placed frames don't animate
		PlayerFrame:SetUserPlaced(true)
		PlayerFrame:SetDontSavePosition(true)
	elseif(unit == 'pet') then
		HandleFrame(PetFrame)
	elseif(unit == 'target') then
		HandleFrame(TargetFrame)
		HandleFrame(ComboFrame)
	elseif(unit == 'focus') then
		HandleFrame(FocusFrame)
		HandleFrame(TargetofFocusFrame)
	elseif(unit == 'targettarget') then
		HandleFrame(TargetFrameToT)
	elseif(unit:match'(boss)%d?$' == 'boss') then
		local id = unit:match'boss(%d)'
		if(id) then
			HandleFrame('Boss' .. id .. 'TargetFrame')
		else
			for i=1, 4 do
				HandleFrame(('Boss%dTargetFrame'):format(i))
			end
		end
	elseif(unit:match'(party)%d?$' == 'party') then
		local id = unit:match'party(%d)'
		if(id) then
			HandleFrame('PartyMemberFrame' .. id)
		else
			for i=1, 4 do
				HandleFrame(('PartyMemberFrame%d'):format(i))
			end
		end
	elseif(unit:match'(arena)%d?$' == 'arena') then
		local id = unit:match'arena(%d)'

		if(id) then
			HandleFrame('ArenaEnemyFrame' .. id)
			HandleFrame('ArenaPrepFrame'..id)
			HandleFrame('ArenaEnemyFrame'..id..'PetFrame')
		else
			for i=1, 5 do
				HandleFrame(('ArenaEnemyFrame%d'):format(i))
				HandleFrame(('ArenaPrepFrame%d'):format(i))
				HandleFrame(('ArenaEnemyFrame%dPetFrame'):format(i))
			end
		end
	end
end

function UF:ADDON_LOADED(event, addon)
	if addon ~= 'Blizzard_ArenaUI' then return; end
	ElvUF:DisableBlizzard('arena')
	self:UnregisterEvent("ADDON_LOADED");
end

function UF:PLAYER_ENTERING_WORLD(event)
	self:Update_AllFrames()
	self:UpdatePrep(event)
end

function UF:UnitFrameThreatIndicator_Initialize(_, unitFrame)
	unitFrame:UnregisterAllEvents() --Arena Taint Fix
end

CompactUnitFrameProfiles:UnregisterEvent('VARIABLES_LOADED') 	--Re-Register this event only if disableblizzard is turned off.
function UF:Initialize()	
	self.db = E.db["unitframe"]
	CompactUnitFrameProfiles:RegisterEvent('VARIABLES_LOADED')
	if E.private["unitframe"].enable ~= true then return; end
	E.UnitFrames = UF;
	
	local ElvUF_Parent = CreateFrame('Frame', 'ElvUF_Parent', E.UIParent, 'SecureHandlerStateTemplate');
	ElvUF_Parent:SetAllPoints(E.UIParent)
	ElvUF_Parent:SetAttribute("_onstate-show", [[		
		if newstate == "hide" then
			self:Hide();
		else
			self:Show();
		end	
	]]);

	RegisterStateDriver(ElvUF_Parent, "show", '[petbattle] hide;show');	

	ElvUF:RegisterStyle('ElvUF', function(frame, unit)
		self:Construct_UF(frame, unit)
	end)
	
	self:LoadUnits()
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
	self:RegisterEvent('ARENA_PREP_OPPONENT_SPECIALIZATIONS', 'UpdatePrep')
	self:RegisterEvent('ARENA_OPPONENT_UPDATE', 'UpdatePrep')

	if E.private["unitframe"].disableBlizzard then
		self:DisableBlizzard()	
		self:SecureHook('UnitFrameThreatIndicator_Initialize')
		InterfaceOptionsFrameCategoriesButton9:SetScale(0.0001)
		InterfaceOptionsFrameCategoriesButton10:SetScale(0.0001)
		InterfaceOptionsFrameCategoriesButton11:SetScale(0.0001)

		if not IsAddOnLoaded('Blizzard_ArenaUI') then
			self:RegisterEvent('ADDON_LOADED')
		else
			ElvUF:DisableBlizzard('arena')
		end
			
		for _, menu in pairs(UnitPopupMenus) do
			for index = #menu, 1, -1 do
				if removeMenuOptions[menu[index]] then
					table.remove(menu, index)
				end
			end
		end				

		self:RegisterEvent('GROUP_ROSTER_UPDATE', 'DisableBlizzard')
	else
		CompactUnitFrameProfiles:RegisterEvent('VARIABLES_LOADED')
	end
		
	local ORD = ns.oUF_RaidDebuffs or oUF_RaidDebuffs
	if not ORD then return end
	ORD.ShowDispelableDebuff = true
	ORD.FilterDispellableDebuff = true
	ORD.MatchBySpellName = true
end

function UF:ResetUnitSettings(unit)
	E:CopyTable(self.db['units'][unit], P['unitframe']['units'][unit]); 
	
	self:Update_AllFrames()
end

function UF:ToggleForceShowGroupFrames(unitGroup, numGroup)
	for i=1, numGroup do
		if self[unitGroup..i] and not self[unitGroup..i].isForced then
			UF:ForceShow(self[unitGroup..i])
		elseif self[unitGroup..i] then
			UF:UnforceShow(self[unitGroup..i])
		end
	end
end

local ignoreSettings = {
	['position'] = true
}
function UF:MergeUnitSettings(fromUnit, toUnit)
	local db = self.db['units']
	
	if fromUnit ~= toUnit then
		for option, value in pairs(db[fromUnit]) do
			if type(value) ~= 'table' and not ignoreSettings[option] then
				if db[toUnit][option] ~= nil then
					db[toUnit][option] = value
				end
			elseif not ignoreSettings[option] then
				if type(value) == 'table' then
					for opt, val in pairs(db[fromUnit][option]) do
						if type(val) ~= 'table' and not ignoreSettings[opt] then
							if db[toUnit][option] ~= nil and db[toUnit][option][opt] ~= nil then
								db[toUnit][option][opt] = val
							end				
						elseif not ignoreSettings[o] then
							if type(val) == 'table' then
								for o, v in pairs(db[fromUnit][option][opt]) do
									if not ignoreSettings[o] then
										if db[toUnit][option] ~= nil and db[toUnit][option][opt] ~= nil and db[toUnit][option][opt][o] ~= nil then
											db[toUnit][option][opt][o] = v	
										end
									end
								end		
							end
						end
					end
				end
			end
		end
	else
		E:Print(L['You cannot copy settings from the same unit.'])
	end
	
	self:Update_AllFrames()
end


E:RegisterInitialModule(UF:GetName())