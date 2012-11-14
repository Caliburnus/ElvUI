local E, L, V, P, G, _ = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
local NP = E:NewModule('NamePlates', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0')
local LSM = LibStub("LibSharedMedia-3.0")

local OVERLAY = [=[Interface\TargetingFrame\UI-TargetingFrame-Flash]=]
local numChildren = -1
local backdrop
NP.Handled = {} --Skinned Nameplates
NP.BattleGroundHealers = {};

NP.factionOpposites = {
	['Horde'] = 1,
	['Alliance'] = 0,
}
NP.Healers = {
	[L['Restoration']] = true,
	[L['Holy']] = true,
	[L['Discipline']] = true,
	[L['Mistweaver']] = true,
}

function NP:Initialize()
	self.db = E.db["nameplate"]
	if E.private["nameplate"].enable ~= true then return end
	E.NamePlates = NP
	
	if type(self.db.healthtext) == 'Boolean' then
		self.db.healthtext = P.nameplate.healthtext
	end
	
	CreateFrame('Frame'):SetScript('OnUpdate', function(self, elapsed)
		if(WorldFrame:GetNumChildren() ~= numChildren) then
			numChildren = WorldFrame:GetNumChildren()
			NP:HookFrames(WorldFrame:GetChildren())
		end	
		
		NP:ForEachPlate(NP.InvalidCastCheck)
		NP:ForEachPlate(NP.CheckFilter)
		
		if(self.elapsed and self.elapsed > 0.2) then
			NP:ForEachPlate(NP.UpdateThreat)
			NP:ForEachPlate(NP.CheckUnit_Guid)
			NP:ForEachPlate(NP.CheckRaidIcon)
			NP:ForEachPlate(NP.Update_LevelText)
			self.elapsed = 0
		else
			self.elapsed = (self.elapsed or 0) + elapsed
		end
	end)	

	self:UpdateAllPlates()
end

function NP:QueueObject(frame, object)
	if not frame.queue then frame.queue = {} end
	frame.queue[object] = true
	
	if object.OldShow then
		object.Show = object.OldShow
		object:Show()
	end
	
	if object.OldTexture then
		object:SetTexture(object.OldTexture)
	end
end

function NP:CreateVirtualFrame(parent, point)
	if point == nil then point = parent end
	local noscalemult = E.mult * UIParent:GetScale()
	
	if point.backdrop then return end

	
	point.backdrop2 = parent:CreateTexture(nil, "BORDER")
	point.backdrop2:SetDrawLayer("BORDER", -4)
	point.backdrop2:SetAllPoints(point)
	point.backdrop2:SetTexture(unpack(E["media"].backdropcolor))		
	
	if E.PixelMode then 
		point.bordertop = parent:CreateTexture(nil, "BORDER")
		point.bordertop:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult)
		point.bordertop:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult)
		point.bordertop:SetHeight(noscalemult)
		point.bordertop:SetTexture(unpack(E["media"].bordercolor))	
		point.bordertop:SetDrawLayer("BORDER", -7)
		
		point.borderbottom = parent:CreateTexture(nil, "BORDER")
		point.borderbottom:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", -noscalemult, -noscalemult)
		point.borderbottom:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", noscalemult, -noscalemult)
		point.borderbottom:SetHeight(noscalemult)
		point.borderbottom:SetTexture(unpack(E["media"].bordercolor))	
		point.borderbottom:SetDrawLayer("BORDER", -7)
		
		point.borderleft = parent:CreateTexture(nil, "BORDER")
		point.borderleft:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult)
		point.borderleft:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", noscalemult, -noscalemult)
		point.borderleft:SetWidth(noscalemult)
		point.borderleft:SetTexture(unpack(E["media"].bordercolor))	
		point.borderleft:SetDrawLayer("BORDER", -7)
		
		point.borderright = parent:CreateTexture(nil, "BORDER")
		point.borderright:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult)
		point.borderright:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", -noscalemult, -noscalemult)
		point.borderright:SetWidth(noscalemult)
		point.borderright:SetTexture(unpack(E["media"].bordercolor))	
		point.borderright:SetDrawLayer("BORDER", -7)			
	else
		point.backdrop = parent:CreateTexture(nil, "BORDER")
		point.backdrop:SetDrawLayer("BORDER", -8)
		point.backdrop:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult*3, noscalemult*3)
		point.backdrop:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", noscalemult*3, -noscalemult*3)
		point.backdrop:SetTexture(0, 0, 0, 1)

		point.bordertop = parent:CreateTexture(nil, "BORDER")
		point.bordertop:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult*2, noscalemult*2)
		point.bordertop:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult*2, noscalemult*2)
		point.bordertop:SetHeight(noscalemult)
		point.bordertop:SetTexture(unpack(E["media"].bordercolor))	
		point.bordertop:SetDrawLayer("BORDER", -7)
		
		point.borderbottom = parent:CreateTexture(nil, "BORDER")
		point.borderbottom:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", -noscalemult*2, -noscalemult*2)
		point.borderbottom:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", noscalemult*2, -noscalemult*2)
		point.borderbottom:SetHeight(noscalemult)
		point.borderbottom:SetTexture(unpack(E["media"].bordercolor))	
		point.borderbottom:SetDrawLayer("BORDER", -7)
		
		point.borderleft = parent:CreateTexture(nil, "BORDER")
		point.borderleft:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult*2, noscalemult*2)
		point.borderleft:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", noscalemult*2, -noscalemult*2)
		point.borderleft:SetWidth(noscalemult)
		point.borderleft:SetTexture(unpack(E["media"].bordercolor))	
		point.borderleft:SetDrawLayer("BORDER", -7)
		
		point.borderright = parent:CreateTexture(nil, "BORDER")
		point.borderright:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult*2, noscalemult*2)
		point.borderright:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", -noscalemult*2, -noscalemult*2)
		point.borderright:SetWidth(noscalemult)
		point.borderright:SetTexture(unpack(E["media"].bordercolor))	
		point.borderright:SetDrawLayer("BORDER", -7)
	end
end

function NP:SetVirtualBorder(parent, r, g, b)
	parent.bordertop:SetTexture(r, g, b)
	parent.borderbottom:SetTexture(r, g, b)
	parent.borderleft:SetTexture(r, g, b)
	parent.borderright:SetTexture(r, g, b)
end

function NP:SetVirtualBackdrop(parent, r, g, b)
	parent.backdrop2:SetTexture(r, g, b)
end

--Run a function for all visible nameplates, we use this for the filter, to check unitguid, and to hide drunken text
function NP:ForEachPlate(functionToRun, ...)
	for frame, _ in pairs(NP.Handled) do
		frame = _G[frame]
		if frame and frame:IsShown() then
			functionToRun(NP, frame, ...)
		end
	end
end

function NP:HideObjects(frame)
	for object in pairs(frame.queue) do
		object.OldShow = object.Show
		object.Show = E.noop
		
		if object:GetObjectType() == "Texture" then
			object.OldTexture = object:GetTexture()
			object:SetTexture(nil)
			object:SetTexCoord(0, 0, 0, 0)
		elseif object:GetObjectType() == 'FontString' then
			object:SetWidth(0.001)
		end
		
		object:Hide()
	end
end

function NP:Colorize(frame)
	local r,g,b = frame.oldhp:GetStatusBarColor()
	for class, _ in pairs(RAID_CLASS_COLORS) do
		local r, g, b = floor(r*100+.5)/100, floor(g*100+.5)/100, floor(b*100+.5)/100
		if class == 'MONK' then
			b = b - 0.01
		end
		if RAID_CLASS_COLORS[class].r == r and RAID_CLASS_COLORS[class].g == g and RAID_CLASS_COLORS[class].b == b then
			frame.hasClass = true
			frame.isFriendly = false
			frame.hp:SetStatusBarColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b)
			return
		end
	end
	
	frame.isPlayer = nil
	
	local color
	if g+b == 0 then -- hostile
		color = self.db.enemy
		r,g,b = color.r, color.g, color.b
		frame.isFriendly = false
	elseif r+b == 0 then -- friendly npc
		color = self.db.friendlynpc
		r,g,b = color.r, color.g, color.b
		frame.isFriendly = true
	elseif r+g > 1.95 then -- neutral
		color = self.db.neutral
		r,g,b = color.r, color.g, color.b
		frame.isFriendly = false
	elseif r+g == 0 then -- friendly player
		color = self.db.friendlyplayer
		r,g,b = color.r, color.g, color.b
		frame.isFriendly = true
	else -- enemy player
		frame.isFriendly = false
	end
	frame.hasClass = false
	
	frame.hp:SetStatusBarColor(r,g,b)
end

function NP:Update_LevelText(frame)
	frame.hp.oldlevel = select(5, frame:GetRegions())

	if frame.hp.oldlevel:IsShown() then
		if self.db.showlevel == true then
			local level, elite, mylevel = tonumber(frame.hp.oldlevel:GetText()), frame.hp.elite:IsShown(), UnitLevel("player")

			if frame.isBoss then
				frame.hp.level:SetText("??")
				frame.hp.level:SetTextColor(0.8, 0.05, 0)
				frame.hp.level:Show()
			elseif not elite and level == mylevel then
				frame.hp.level:Hide()
			elseif level then
				frame.hp.level:SetText(level..(elite and "+" or ""))
				frame.hp.level:SetTextColor(frame.hp.oldlevel:GetTextColor())
				frame.hp.level:Show()
			end
			
			frame.hp.oldlevel:SetWidth(000.1)
		elseif frame.hp.level then
			frame.hp.level:Hide()
		end
	elseif frame.isBoss and self.db.showlevel and frame.hp.level:GetText() ~= '??' then
		frame.hp.level:SetText("??")
		frame.hp.level:SetTextColor(0.8, 0.05, 0)
		frame.hp.level:Show()	
	end
end

function NP:HealthBar_OnShow(self, frame)
	if self.GetParent then frame = self; self = NP end
	frame = frame:GetParent()
	
	local noscalemult = E.mult * UIParent:GetScale()
	local r, g, b = frame.hp:GetStatusBarColor()
	--Have to reposition this here so it doesnt resize after being hidden
	frame.hp:ClearAllPoints()
	frame.hp:Size(self.db.width, self.db.height)	
	frame.hp:SetPoint('BOTTOM', frame, 'BOTTOM', 0, 5)
	frame.hp:GetStatusBarTexture():SetHorizTile(true)

	self:HealthBar_ValueChanged(frame.oldhp)
	
	if not E.PixelMode then
		frame.hp.backdrop:SetPoint('TOPLEFT', -noscalemult*3, noscalemult*3)
		frame.hp.backdrop:SetPoint('BOTTOMRIGHT', noscalemult*3, -noscalemult*3)	
	end

	self:Colorize(frame)
	
	frame.hp.rcolor, frame.hp.gcolor, frame.hp.bcolor = frame.hp:GetStatusBarColor()
	frame.hp.hpbg:SetTexture(frame.hp.rcolor, frame.hp.gcolor, frame.hp.bcolor, 0.25)
	
	--Position Overlay
	frame.overlay:ClearAllPoints()
	frame.overlay:SetAllPoints(frame.hp)
	
	--Set the name text
	frame.hp.name:SetText(frame.hp.oldname:GetText())	

	--Level Text
	frame.isBoss = frame.hp.boss:IsShown()
	NP:Update_LevelText(frame)
	
	NP.ScanHealth(frame.oldhp)
	NP:CheckFilter(frame)
	self:HideObjects(frame)
end

function NP:HealthBar_ValueChanged(frame)
	local frame = frame:GetParent()
	frame.hp:SetMinMaxValues(frame.oldhp:GetMinMaxValues())
	frame.hp:SetValue(frame.oldhp:GetValue() - 1) --Blizzard bug fix
	frame.hp:SetValue(frame.oldhp:GetValue())
end

function NP:OnHide(frame)
	frame.hp:SetStatusBarColor(frame.hp.rcolor, frame.hp.gcolor, frame.hp.bcolor)
	frame.hp.name:SetTextColor(1, 1, 1)
	frame.overlay:Hide()
	frame.cb:Hide()
	frame.unit = nil
	frame.isMarked = nil
	frame.raidIconType = nil
	frame.threatStatus = nil
	frame.guid = nil
	frame.hasClass = nil
	frame.isBoss = nil;
	frame.customColor = nil
	frame.customScale = nil
	frame.isFriendly = nil
	frame.hp.rcolor = nil
	frame.hp.gcolor = nil
	frame.hp.bcolor = nil
	frame.hp.shadow:SetAlpha(0)
	self:SetVirtualBackdrop(frame.hp, unpack(E["media"].backdropcolor))
	self:SetVirtualBorder(frame.hp, unpack(E["media"].bordercolor))
	if frame.icons then
		for _,icon in ipairs(frame.icons) do
			icon:Hide()
		end
	end	
end

function NP:SkinPlate(frame)
	local oldhp, oldcb = frame:GetChildren()
	local threat, hpborder, overlay, oldname, oldlevel, bossicon, raidicon, elite = frame:GetRegions()
	local _, cbborder, cbshield, cbicon = oldcb:GetRegions()
	local font = LSM:Fetch("font", self.db.font)
	local noscalemult = E.mult * UIParent:GetScale()

	--Health Bar
	if not frame.hp then
		frame.oldhp = oldhp
		frame.oldhp:HookScript('OnValueChanged', NP.ScanHealth)

		local SHADOW_SPACING = E.PixelMode and (((noscalemult * 5) - UIParent:GetScale() / 3)) or 5
		frame.hp = CreateFrame("Statusbar", nil, frame)
		frame.hp:SetFrameLevel(oldhp:GetFrameLevel() + 1)
		frame.hp:SetFrameStrata(oldhp:GetFrameStrata())
		frame.hp:CreateShadow('Default')
		frame.hp.shadow:ClearAllPoints()
		frame.hp.shadow:Point("TOPLEFT", frame.hp, -SHADOW_SPACING, SHADOW_SPACING)
		frame.hp.shadow:Point("BOTTOMLEFT", frame.hp, -SHADOW_SPACING, -SHADOW_SPACING)
		frame.hp.shadow:Point("TOPRIGHT", frame.hp, SHADOW_SPACING, SHADOW_SPACING)
		frame.hp.shadow:Point("BOTTOMRIGHT", frame.hp, SHADOW_SPACING, -SHADOW_SPACING)	
		frame.hp.shadow:SetBackdropBorderColor(1, 1, 1, 0.75)
		frame.hp.shadow:SetFrameLevel(0)
		frame.hp.shadow:SetAlpha(0)
		self:CreateVirtualFrame(frame.hp)
		
		frame.hp.hpbg = frame.hp:CreateTexture(nil, 'BORDER')
		frame.hp.hpbg:SetAllPoints(frame.hp)
		frame.hp.hpbg:SetTexture(1,1,1,0.25) 				
	end
	frame.hp:SetStatusBarTexture(E["media"].normTex)
	self:SetVirtualBackdrop(frame.hp, unpack(E["media"].backdropcolor))
	
	-- threat updates
	if not frame.threat then	
		frame.threat = threat
	end
	
	--Level Text
	if not frame.hp.level then
		frame.hp.level = frame.hp:CreateFontString(nil, "OVERLAY")
		frame.hp.level:SetPoint("RIGHT", frame.hp, "LEFT", -1, 0)
		frame.hp.oldlevel = oldlevel
		frame.hp.boss = bossicon
		frame.hp.elite = elite
	end
	frame.hp.level:FontTemplate(font, self.db.fontSize, self.db.fontOutline)
	frame.hp.level:SetText(oldlevel:GetText())
	
	--Name Text
	if not frame.hp.name then
		frame.hp.name = frame.hp:CreateFontString(nil, 'OVERLAY')
		frame.hp.name:SetPoint('BOTTOMLEFT', frame.hp, 'TOPLEFT', -10, 3)
		frame.hp.name:SetPoint('BOTTOMRIGHT', frame.hp, 'TOPRIGHT', 10, 3)
		frame.hp.oldname = oldname
	end
	frame.hp.name:FontTemplate(font, self.db.fontSize, self.db.fontOutline)
	
	--Health Text
	if not frame.hp.value then
		frame.hp.value = frame.hp:CreateFontString(nil, "OVERLAY")	
		frame.hp.value:SetPoint("CENTER", frame.hp)
	end
	frame.hp.value:FontTemplate(font, self.db.fontSize, self.db.fontOutline)
	
	--Overlay
	overlay.oldTexture = overlay:GetTexture()
	overlay:SetTexture(1,1,1,0.15)
	frame.overlay = overlay
	
	--Cast Bar
	if not frame.cb then
		frame.oldcb = oldcb
		frame.cb = CreateFrame("Statusbar", nil, frame)
		frame.cb:SetFrameLevel(oldcb:GetFrameLevel())
		frame.cb:SetFrameStrata(oldcb:GetFrameStrata())
		self:CreateVirtualFrame(frame.cb)	
		frame.cb:Hide()
	end

	--Cast Time
	if not frame.cb.time then
		frame.cb.time = frame.cb:CreateFontString(nil, "ARTWORK")
		frame.cb.time:SetPoint("RIGHT", frame.cb, "LEFT", -1, 0)
	end
	frame.cb.time:FontTemplate(font, self.db.fontSize, self.db.fontOutline)
	
	--Cast Name
	if not frame.cb.name then
		frame.cb.name = frame.cb:CreateFontString(nil, "ARTWORK")
		frame.cb.name:SetPoint("TOP", frame.cb, "BOTTOM", 0, -3)
	end
	frame.cb.name:FontTemplate(font, self.db.fontSize, self.db.fontOutline)
	
	--Cast Icon
	if not frame.cb.icon then
		oldcb:SetAlpha(0)
		oldcb:SetScale(0.000001)
		cbicon:ClearAllPoints()
		cbicon:SetPoint("TOPLEFT", frame.hp, "TOPRIGHT", 8, 0)		
		cbicon:SetTexCoord(.07, .93, .07, .93)
		cbicon:SetDrawLayer("OVERLAY")
		cbicon:SetParent(frame.cb)
		frame.cb.icon = cbicon
		frame.cb.shield = cbshield
		self:CreateVirtualFrame(frame.cb, frame.cb.icon)
	end

	--Raid Icon
	if not frame.raidicon then
		raidicon:ClearAllPoints()
		raidicon:SetPoint("BOTTOM", frame.hp, "TOP", 0, 16)
		raidicon:SetSize(35, 35)
		raidicon:SetTexture([[Interface\AddOns\ElvUI\media\textures\raidicons.blp]])	
		frame.raidicon = raidicon	
	end
	
	--Heal Icon
	if not frame.healerIcon then
		frame.healerIcon = frame:CreateTexture(nil, 'ARTWORK')
		frame.healerIcon:SetPoint("BOTTOM", frame.hp, "TOP", 0, 16)
		frame.healerIcon:SetSize(35, 35)
		frame.healerIcon:SetTexture([[Interface\AddOns\ElvUI\media\textures\healer.tga]])	
	end
	
	if not frame.AuraWidget then
		--if not WatcherIsEnabled then Enable() end
		-- Create Base frame
		local f = CreateFrame("Frame", nil, frame)
		f:SetHeight(32); f:Show()
		f:SetPoint('BOTTOMRIGHT', frame.hp, 'TOPRIGHT', 0, 10)
		f:SetPoint('BOTTOMLEFT', frame.hp, 'TOPLEFT', 0, 10)
		
		-- Create Icon Array
		f.PollFunction = NP.UpdateAuraTime
		f.AuraIconFrames = {}
		local AuraIconFrames = f.AuraIconFrames
		for index = 1, NP.MAX_DISPLAYABLE_DEBUFFS do AuraIconFrames[index] = NP:CreateAuraIcon(f);  end
		local FirstRowCount = min(NP.MAX_DISPLAYABLE_DEBUFFS/2)
		-- Set Anchors	
		AuraIconFrames[1]:SetPoint("RIGHT", f, -1, 0)
		for index = 2, NP.MAX_DISPLAYABLE_DEBUFFS do AuraIconFrames[index]:SetPoint("RIGHT", AuraIconFrames[index-1], "LEFT", -3, 0) end
		
		-- Functions
		f._Hide = f.Hide
		f.Hide = function() NP:ClearAuraContext(f); f:_Hide() end
		f:SetScript("OnHide", function() for index = 1, 4 do NP.PolledHideIn(AuraIconFrames[index], 0) end end)	
		f.Filter = DefaultFilterFunction
		f.UpdateContext = NP.UpdateAuraContext
		f.Update = NP.UpdateAuraContext
		f.UpdateTarget = NP.UpdateAuraTarget
		
		frame.AuraWidget = f
	end
	
	for index = 1, NP.MAX_DISPLAYABLE_DEBUFFS do 
		if AuraIconFrames and AuraIconFrames[index] then
			AuraIconFrames[index].TimeLeft:FontTemplate(font, self.db.fontSize - 3, self.db.fontOutline)
		end
	end
		
	--Hide Old Stuff
	self:QueueObject(frame, oldhp)
	self:QueueObject(frame, oldlevel)
	self:QueueObject(frame, threat)
	self:QueueObject(frame, hpborder)
	self:QueueObject(frame, cbshield)
	self:QueueObject(frame, cbborder)
	self:QueueObject(frame, oldname)
	self:QueueObject(frame, bossicon)
	self:QueueObject(frame, elite)
	
	self:HealthBar_OnShow(frame.hp)
	self:CastBar_OnShow(frame.cb)
	if not self.hooks[frame] then
		self:HookScript(frame.cb, 'OnShow', 'CastBar_OnShow')
		self:HookScript(oldcb, 'OnValueChanged', 'CastBar_OnValueChanged')				
		self:HookScript(frame.hp, 'OnShow', 'HealthBar_OnShow')		
		self:HookScript(oldhp, 'OnValueChanged', 'HealthBar_ValueChanged')
		self:HookScript(frame, "OnHide", "OnHide")	
	end
	
	NP.Handled[frame:GetName()] = true
end


local good, bad, transition, transition2, combat, goodscale, badscale
function NP:UpdateThreat(frame)
	if frame.hasClass then return end
	combat = InCombatLockdown()
	good = self.db.goodcolor
	bad = self.db.badcolor
	goodscale = self.db.goodscale
	badscale = self.db.badscale
	transition = self.db.goodtransitioncolor
	transition2 = self.db.badtransitioncolor
	local bgMult = self.db.bgMult
	if self.db.enhancethreat ~= true then
		if(frame.threat:IsShown()) then
			local _, val = frame.threat:GetVertexColor()
			if(val > 0.7) then
				self:SetVirtualBorder(frame.hp, transition.r, transition.g, transition.b)
				if not frame.customScale and (goodscale ~= 1 or badscale ~= 1) then
					frame.hp:Height(self.db.height)
					frame.hp:Width(self.db.width)
				end					
			else
				self:SetVirtualBorder(frame.hp, bad.r, bad.g, bad.b)
				if not frame.customScale and badscale ~= 1 then
					frame.hp:Height(self.db.height * badscale)
					frame.hp:Width(self.db.width * badscale)
				end						
			end
		else
			self:SetVirtualBorder(frame.hp, unpack(E["media"].bordercolor))
			if not frame.customScale and goodscale ~= 1 then
				frame.hp:Height(self.db.height * goodscale)
				frame.hp:Width(self.db.width * goodscale)
			end								
		end
		frame.hp.name:SetTextColor(1, 1, 1)
	else
		if not frame.threat:IsShown() then
			if combat and frame.isFriendly ~= true then
				--No Threat
				if E.role == "Tank" then
					if not frame.customColor then
						frame.hp:SetStatusBarColor(bad.r, bad.g, bad.b)
						frame.hp.hpbg:SetTexture(bad.r, bad.g, bad.b, bgMult)
					end

					if not frame.customScale and badscale ~= 1 then
						frame.hp:Height(self.db.height * badscale)
						frame.hp:Width(self.db.width * badscale)
					end								
					frame.threatStatus = "BAD"
				else
					if not frame.customColor then
						frame.hp:SetStatusBarColor(good.r, good.g, good.b)
						frame.hp.hpbg:SetTexture(good.r, good.g, good.b, bgMult)
					end
					
					if not frame.customScale and goodscale ~= 1 then
						frame.hp:Height(self.db.height * goodscale)
						frame.hp:Width(self.db.width * goodscale)
					end					
					frame.threatStatus = "GOOD"
				end		
			else
				--Set colors to their original, not in combat
				if not frame.customColor then
					frame.hp:SetStatusBarColor(frame.hp.rcolor, frame.hp.gcolor, frame.hp.bcolor)
					frame.hp.hpbg:SetTexture(frame.hp.rcolor, frame.hp.gcolor, frame.hp.bcolor, bgMult)
				end
				
				if not frame.customScale and (goodscale ~= 1 or badscale ~= 1) then
					frame.hp:Height(self.db.height)
					frame.hp:Width(self.db.width)
				end			
				frame.threatStatus = nil
			end
		else
			--Ok we either have threat or we're losing/gaining it
			local r, g, b = frame.threat:GetVertexColor()
			if g + b == 0 then
				--Have Threat
				if E.role == "Tank" then
					if not frame.customColor then
						frame.hp:SetStatusBarColor(good.r, good.g, good.b)
						frame.hp.hpbg:SetTexture(good.r, good.g, good.b, bgMult)
					end
					
					if not frame.customScale and goodscale ~= 1 then
						frame.hp:Height(self.db.height * goodscale)
						frame.hp:Width(self.db.width * goodscale)
					end
					
					frame.threatStatus = "GOOD"
				else
					if not frame.customColor then
						frame.hp:SetStatusBarColor(bad.r, bad.g, bad.b)
						frame.hp.hpbg:SetTexture(bad.r, bad.g, bad.b, bgMult)
					end
					
					if not frame.customScale and badscale ~= 1 then
						frame.hp:Height(self.db.height * badscale)
						frame.hp:Width(self.db.width * badscale)
					end					
					frame.threatStatus = "BAD"
				end
			else
				--Losing/Gaining Threat
				
				if not frame.customScale and (goodscale ~= 1 or badscale ~= 1) then
					frame.hp:Height(self.db.height)
					frame.hp:Width(self.db.width)
				end	
				
				if E.role == "Tank" then
					if frame.threatStatus == "GOOD" then
						--Losing Threat
						if not frame.customColor then
							frame.hp:SetStatusBarColor(transition2.r, transition2.g, transition2.b)	
							frame.hp.hpbg:SetTexture(transition2.r, transition2.g, transition2.b, bgMult)
						end
					else
						--Gaining Threat
						if not frame.customColor then
							frame.hp:SetStatusBarColor(transition.r, transition.g, transition.b)	
							frame.hp.hpbg:SetTexture(transition.r, transition.g, transition.b, bgMult)
						end
					end
				else
					if frame.threatStatus == "GOOD" then
						--Losing Threat
						if not frame.customColor then
							frame.hp:SetStatusBarColor(transition.r, transition.g, transition.b)	
							frame.hp.hpbg:SetTexture(transition.r, transition.g, transition.b, bgMult)
						end
					else
						--Gaining Threat
						if not frame.customColor then
							frame.hp:SetStatusBarColor(transition2.r, transition2.g, transition2.b)	
							frame.hp.hpbg:SetTexture(transition2.r, transition2.g, transition2.b, bgMult)
						end
					end				
				end
			end
		end
		
		if combat then
			frame.hp.name:SetTextColor(frame.hp.rcolor, frame.hp.gcolor, frame.hp.bcolor)
		else
			frame.hp.name:SetTextColor(1, 1, 1)
		end
	end
end

function NP:ScanHealth()
	-- show current health value
	local frame = self:GetParent()
	local minHealth, maxHealth = frame.oldhp:GetMinMaxValues()
	local valueHealth = frame.oldhp:GetValue()
	local d =(valueHealth/maxHealth)*100
	
	if NP.db.healthtext ~= '' and valueHealth and maxHealth and maxHealth > 1 then
		frame.hp.value:Show()
		frame.hp.value:SetText(E:GetFormattedText(NP.db.healthtext, valueHealth, maxHealth))
	else
		frame.hp.value:Hide()
	end
			
	--Setup frame shadow to change depending on enemy players health, also setup targetted unit to have white shadow
	if (NP.db.lowHealthWarning == 'PLAYERS' and frame.hasClass == true or frame.isFriendly == true) or NP.db.lowHealthWarning == 'ALL' then
		local threshold = NP.db.lowHealthWarningThreshold * 100
		if(d <= threshold and d >= (threshold / 2)) then
			NP:SetVirtualBorder(frame.hp, 1, 1, 0)
		elseif(d < (threshold / 2)) then
			NP:SetVirtualBorder(frame.hp, 1, 0, 0)
		else
			NP:SetVirtualBorder(frame.hp, unpack(E["media"].bordercolor))
		end
	elseif (frame.hasClass ~= true and frame.isFriendly ~= true) or NP.db.lowHealthWarning == 'ALL' then
		NP:SetVirtualBorder(frame.hp, unpack(E["media"].bordercolor))
	end
end

--Scan all visible nameplate for a known unit.
function NP:CheckUnit_Guid(frame, ...)
	if UnitExists("target") and frame:GetAlpha() == 1 and UnitName("target") == frame.hp.name:GetText() then
		frame.guid = UnitGUID("target")
		frame.unit = "target"
		NP:UpdateAurasByUnitID("target")
		frame.hp.shadow:SetAlpha(1)
	elseif frame.overlay:IsShown() and UnitExists("mouseover") and UnitName("mouseover") == frame.hp.name:GetText() then
		frame.guid = UnitGUID("mouseover")
		frame.unit = "mouseover"
		NP:UpdateAurasByUnitID("mouseover")
		frame.hp.shadow:SetAlpha(0)
	else
		frame.unit = nil
		frame.hp.shadow:SetAlpha(0)
	end	
end

function NP:TogglePlate(frame, hide)
	if hide == true then
		frame.hp:Hide()
		frame.cb:Hide()
		frame.overlay:Hide()
		frame.overlay:SetTexture(nil)
		frame.hp.oldlevel:Hide()	
	else
		frame.hp:Show()
		frame.overlay:SetTexture(1, 1, 1, 0.15)	
	end
end

--Create our blacklist for nameplates, so prevent a certain nameplate from ever showing
function NP:CheckFilter(frame, ...)
	local name = frame.hp.oldname:GetText()
	local db = E.global.nameplate["filter"][name]

	if db and db.enable then
		if db.hide then
			self:TogglePlate(frame, true)
		else
			self:TogglePlate(frame, false)
			
			if db.customColor then
				frame.customColor = db.customColor
				frame.hp.hpbg:SetTexture(db.color.r, db.color.g, db.color.b, 0.25)
				frame.hp:SetStatusBarColor(db.color.r, db.color.g, db.color.b)
			else
				frame.customColor = nil	
			end
			
			if db.customScale and db.customScale ~= 1 then
				frame.hp:Height(self.db.height * db.customScale)
				frame.hp:Width(self.db.width * db.customScale)
				frame.customScale = db.customScale
			else
				frame.customScale = nil
			end
		end
	else
		self:TogglePlate(frame, false)
	end
	
	--Check For Healers
	if self.BattleGroundHealers[name] then
		frame.healerIcon:Show()
	else
		frame.healerIcon:Hide()
	end
end

function NP:CheckBGHealers()
	for i = 1, GetNumBattlefieldScores() do
		local name, _, _, _, _, faction, _, _, _, _, _, _, _, _, _, talentSpec = GetBattlefieldScore(i);
		if name then
			name = name:match("(.+)%-.+") or name
			if name and self.Healers[talentSpec] and self.factionOpposites[self.PlayerFaction] == faction then
				self.BattleGroundHealers[name] = talentSpec
			elseif name and self.BattleGroundHealers[name] then
				self.BattleGroundHealers[name] = nil;
			end
		end
	end
end

function NP:CheckArenaHealers()
	if not self.db.markBGHealers then return; end
	local inInstance, instanceType = IsInInstance()
	if inInstance and instanceType == 'arena' then
		local numOpps = GetNumArenaOpponentSpecs()
		for i=1, numOpps do
			local specID = GetArenaOpponentSpec(i)
			local unit = 'arena'..i
			if specID and specID > 0 then
				local _, talentSpec = GetSpecializationInfoByID(specID);
				local unitName = UnitName(unit)
				if unitName and self.Healers[talentSpec] then
					self.BattleGroundHealers[unitName] = talentSpec
				end
			end	
		end
	end
end

function NP:PLAYER_ENTERING_WORLD()
	if InCombatLockdown() and self.db.combat then 
		SetCVar("nameplateShowEnemies", 1) 
	elseif self.db.combat then
		SetCVar("nameplateShowEnemies", 0) 
	end
	
	self:UpdateRoster()
	self:CleanAuraLists()
	
	table.wipe(self.BattleGroundHealers)
	local inInstance, instanceType = IsInInstance()
	if inInstance and instanceType == 'pvp' and self.db.markBGHealers then
		self.CheckHealerTimer = self:ScheduleRepeatingTimer("CheckBGHealers", 1)
		self:CheckBGHealers()
	else
		if self.CheckHealerTimer then
			self:CancelTimer(self.CheckHealerTimer)
			self.CheckHealerTimer = nil;
		end
	end
	
	self.PlayerFaction = UnitFactionGroup("player")
end

function NP:UpdateAllPlates()
	if E.private["nameplate"].enable ~= true then return end
	for frame, _ in pairs(self.Handled) do
		frame = _G[frame]
		self:SkinPlate(frame)
	end

	self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateRoster")
	self:RegisterEvent("PARTY_CONVERTED_TO_RAID", "UpdateRoster")
	self:RegisterEvent('UPDATE_MOUSEOVER_UNIT', 'UpdateCastInfo')
	self:RegisterEvent('PLAYER_TARGET_CHANGED', 'UpdateCastInfo')
	self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
	self:RegisterEvent('ARENA_OPPONENT_UPDATE', 'CheckArenaHealers')
	self:RegisterEvent('PLAYER_REGEN_ENABLED')
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
	self:RegisterEvent('UNIT_TARGET')
	self:RegisterEvent('UNIT_AURA')	
	self:PLAYER_ENTERING_WORLD()
end

function NP:HookFrames(...)
	for index = 1, select('#', ...) do
		local frame = select(index, ...)
		local region = frame:GetRegions()
		
		if(not NP.Handled[frame:GetName()] and (frame:GetName() and frame:GetName():find("NamePlate%d")) and region and region:GetObjectType() == 'Texture') then
			NP:SkinPlate(frame)
		end
	end
end

E:RegisterModule(NP:GetName())