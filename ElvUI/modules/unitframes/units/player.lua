local E, L, V, P, G, _ = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
local UF = E:GetModule('UnitFrames');

local _, ns = ...
local ElvUF = ns.oUF
assert(ElvUF, "ElvUI was unable to locate oUF.")
local USING_DX11 = (GetCVar("gxapi") == "D3D11" or IsMacClient())

local CAN_HAVE_CLASSBAR = (E.myclass == "PALADIN" or E.myclass == "DRUID" or E.myclass == "DEATHKNIGHT" or E.myclass == "WARLOCK" or E.myclass == "PRIEST" or E.myclass == "MONK" or E.myclass == 'MAGE')

function UF:Construct_PlayerFrame(frame)
	frame.Threat = self:Construct_ThreatGlow(frame, true)
	
	frame.Health = self:Construct_HealthBar(frame, true, true, 'RIGHT')
	frame.Health.frequentUpdates = true;
	
	frame.Power = self:Construct_PowerBar(frame, true, true, 'LEFT', true)
	frame.Power.frequentUpdates = true;
	
	frame.Name = self:Construct_NameText(frame)
	
	frame.Portrait = self:Construct_Portrait(frame)
	
	frame.Buffs = self:Construct_Buffs(frame)
	
	frame.Debuffs = self:Construct_Debuffs(frame)
	
	frame.Castbar = self:Construct_Castbar(frame, 'LEFT', 'Player Castbar')
	
	if E.myclass == "PALADIN" then
		frame.HolyPower = self:Construct_PaladinResourceBar(frame)
	elseif E.myclass == "WARLOCK" then
		frame.ShardBar = self:Construct_WarlockResourceBar(frame)
	elseif E.myclass == "DEATHKNIGHT" then
		frame.Runes = self:Construct_DeathKnightResourceBar(frame)
	elseif E.myclass == "DRUID" then
		frame.EclipseBar = self:Construct_DruidResourceBar(frame)
		frame.DruidAltMana = self:Construct_DruidAltManaBar(frame)
	elseif E.myclass == "MONK" then
		frame.Harmony = self:Construct_MonkResourceBar(frame)
	elseif E.myclass == "PRIEST" then
		frame.ShadowOrbs = self:Construct_PriestResourceBar(frame)
	elseif E.myclass == 'MAGE' then
		frame.ArcaneChargeBar = self:Construct_MageResourceBar(frame)
	end
	
	frame.RaidIcon = UF:Construct_RaidIcon(frame)
	frame.Resting = self:Construct_RestingIndicator(frame)
	frame.Combat = self:Construct_CombatIndicator(frame)
	frame.PvPText = self:Construct_PvPIndicator(frame)
	frame.DebuffHighlight = self:Construct_DebuffHighlight(frame)
	frame.HealPrediction = self:Construct_HealComm(frame)

	frame.AuraBars = self:Construct_AuraBarHeader(frame)
		
	frame.CombatFade = true

	frame:Point('BOTTOMLEFT', E.UIParent, 'BOTTOM', -417, 75) --Set to default position	
	E:CreateMover(frame, frame:GetName()..'Mover', 'Player Frame', nil, nil, nil, 'ALL,SOLO')
end

function UF:UpdatePlayerFrameAnchors(frame, isShown)
	local db = E.db['unitframe']['units'].player
	local health = frame.Health
	local threat = frame.Threat
	local PORTRAIT_WIDTH = db.portrait.width
	local USE_PORTRAIT = db.portrait.enable
	local USE_PORTRAIT_OVERLAY = db.portrait.overlay and USE_PORTRAIT and USING_DX11
	local CLASSBAR_HEIGHT = db.classbar.height
	local USE_CLASSBAR = db.classbar.enable
	local USE_MINI_CLASSBAR = db.classbar.fill == "spaced" and USE_CLASSBAR
	local USE_POWERBAR = db.power.enable
	local USE_MINI_POWERBAR = db.power.width ~= 'fill' and USE_POWERBAR
	local USE_POWERBAR_OFFSET = db.power.offset ~= 0 and USE_POWERBAR
	local POWERBAR_OFFSET = db.power.offset
	local POWERBAR_HEIGHT = db.power.height
	local SPACING = 1;
	
	if not USE_POWERBAR then
		POWERBAR_HEIGHT = 0
	end
	
	if USE_PORTRAIT_OVERLAY or not USE_PORTRAIT then
		PORTRAIT_WIDTH = 0
	end
	
	if USE_MINI_CLASSBAR then
		CLASSBAR_HEIGHT = CLASSBAR_HEIGHT / 2
	end
	
	if isShown then
		if db.power.offset ~= 0 then
			health:Point("TOPRIGHT", frame, "TOPRIGHT", -(2+db.power.offset), -(2 + CLASSBAR_HEIGHT + 1))
		else
			health:Point("TOPRIGHT", frame, "TOPRIGHT", -2, -(2 + CLASSBAR_HEIGHT + 1))
		end
		health:Point("TOPLEFT", frame, "TOPLEFT", PORTRAIT_WIDTH + 2, -(2 + CLASSBAR_HEIGHT + 1))	

		local mini_classbarY = 0
		if USE_MINI_CLASSBAR then
			mini_classbarY = -(SPACING+(CLASSBAR_HEIGHT))
		end		
		
		threat:Point("TOPLEFT", -4, 4+mini_classbarY)
		threat:Point("TOPRIGHT", 4, 4+mini_classbarY)
		
		if USE_MINI_POWERBAR then
			threat:Point("BOTTOMLEFT", -4, -4 + (POWERBAR_HEIGHT/2))
			threat:Point("BOTTOMRIGHT", 4, -4 + (POWERBAR_HEIGHT/2))		
		else
			threat:Point("BOTTOMLEFT", -4, -4)
			threat:Point("BOTTOMRIGHT", 4, -4)
		end		
		
		if USE_POWERBAR_OFFSET then
			threat:Point("TOPRIGHT", 4-POWERBAR_OFFSET, 4+mini_classbarY)
			threat:Point("BOTTOMRIGHT", 4-POWERBAR_OFFSET, -4)	
		end				

		
		if db.portrait.enable and not USE_PORTRAIT_OVERLAY then
			local portrait = frame.Portrait
			portrait.backdrop:ClearAllPoints()
			if USE_MINI_CLASSBAR and USE_CLASSBAR then
				portrait.backdrop:Point("TOPLEFT", frame, "TOPLEFT", 0, -(CLASSBAR_HEIGHT + 1))
			else
				portrait.backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT")
			end		
			
			if USE_MINI_POWERBAR or USE_POWERBAR_OFFSET or not USE_POWERBAR then
				portrait.backdrop:Point("BOTTOMRIGHT", frame.Health.backdrop, "BOTTOMLEFT", -1, 0)
			else
				portrait.backdrop:Point("BOTTOMRIGHT", frame.Power.backdrop, "BOTTOMLEFT", -1, 0)
			end				
		end
	else
		if db.power.offset ~= 0 then
			health:Point("TOPRIGHT", frame, "TOPRIGHT", -(2 + db.power.offset), -2)
		else
			health:Point("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
		end
		health:Point("TOPLEFT", frame, "TOPLEFT", PORTRAIT_WIDTH + 2, -2)	

		threat:Point("TOPLEFT", -4, 4)
		threat:Point("TOPRIGHT", 4, 4)
		
		if USE_MINI_POWERBAR then
			threat:Point("BOTTOMLEFT", -4, -4 + (POWERBAR_HEIGHT/2))
			threat:Point("BOTTOMRIGHT", 4, -4 + (POWERBAR_HEIGHT/2))		
		else
			threat:Point("BOTTOMLEFT", -4, -4)
			threat:Point("BOTTOMRIGHT", 4, -4)
		end		
		
		if USE_POWERBAR_OFFSET then
			threat:Point("TOPRIGHT", 4-POWERBAR_OFFSET, 4)
			threat:Point("BOTTOMRIGHT", 4-POWERBAR_OFFSET, -4)	
		end				

		if db.portrait.enable and not USE_PORTRAIT_OVERLAY then
			local portrait = frame.Portrait
			portrait.backdrop:ClearAllPoints()
			portrait.backdrop:Point("TOPLEFT", frame, "TOPLEFT")
			
			if USE_MINI_POWERBAR or USE_POWERBAR_OFFSET or not USE_POWERBAR then
				portrait.backdrop:Point("BOTTOMRIGHT", frame.Health.backdrop, "BOTTOMLEFT", -1, 0)
			else
				portrait.backdrop:Point("BOTTOMRIGHT", frame.Power.backdrop, "BOTTOMLEFT", -1, 0)
			end				
		end		
	end
end

function UF:Update_PlayerFrame(frame, db)
	frame.db = db
	local BORDER = E:Scale(2)
	local SPACING = E:Scale(1)
	local UNIT_WIDTH = db.width
	local UNIT_HEIGHT = db.height

	local USE_POWERBAR = db.power.enable
	local USE_MINI_POWERBAR = db.power.width ~= 'fill' and USE_POWERBAR
	local USE_POWERBAR_OFFSET = db.power.offset ~= 0 and USE_POWERBAR
	local POWERBAR_OFFSET = db.power.offset
	local POWERBAR_HEIGHT = db.power.height
	local POWERBAR_WIDTH = db.width - (BORDER*2)
	
	local USE_CLASSBAR = db.classbar.enable and CAN_HAVE_CLASSBAR
	local USE_MINI_CLASSBAR = db.classbar.fill == "spaced" and USE_CLASSBAR
	local CLASSBAR_HEIGHT = db.classbar.height
	local CLASSBAR_WIDTH = db.width - (BORDER*2)
	
	local USE_PORTRAIT = db.portrait.enable
	local USE_PORTRAIT_OVERLAY = db.portrait.overlay and USE_PORTRAIT and USING_DX11
	local PORTRAIT_WIDTH = db.portrait.width
	
	local unit = self.unit
	
	frame.colors = ElvUF.colors
	frame:Size(UNIT_WIDTH, UNIT_HEIGHT)
	_G[frame:GetName()..'Mover']:Size(frame:GetSize())
	
	--Adjust some variables
	do
		if not USE_POWERBAR then
			POWERBAR_HEIGHT = 0
		end
		
		if USE_PORTRAIT_OVERLAY or not USE_PORTRAIT then
			PORTRAIT_WIDTH = 0		
		end
		
		if USE_PORTRAIT then
			CLASSBAR_WIDTH = math.ceil((UNIT_WIDTH - (BORDER*2)) - PORTRAIT_WIDTH)
		end
		
		if USE_POWERBAR_OFFSET then
			CLASSBAR_WIDTH = CLASSBAR_WIDTH - POWERBAR_OFFSET
		end
		
		if USE_MINI_POWERBAR then
			POWERBAR_WIDTH = POWERBAR_WIDTH / 2
		end
	end
	
	--Threat
	do
		local threat = frame.Threat
		
		local mini_classbarY = 0
		if USE_MINI_CLASSBAR then
			mini_classbarY = -(SPACING+(CLASSBAR_HEIGHT/2))
		end
		
		threat:ClearAllPoints()
		threat:SetBackdropBorderColor(0, 0, 0, 0)
		threat:Point("TOPLEFT", -4, 4+mini_classbarY)
		threat:Point("TOPRIGHT", 4, 4+mini_classbarY)
		
		if USE_MINI_POWERBAR then
			threat:Point("BOTTOMLEFT", -4, -4 + (POWERBAR_HEIGHT/2))
			threat:Point("BOTTOMRIGHT", 4, -4 + (POWERBAR_HEIGHT/2))		
		else
			threat:Point("BOTTOMLEFT", -4, -4)
			threat:Point("BOTTOMRIGHT", 4, -4)
		end

		if USE_POWERBAR_OFFSET then
			threat:Point("TOPRIGHT", 4-POWERBAR_OFFSET, 4+mini_classbarY)
			threat:Point("BOTTOMRIGHT", 4-POWERBAR_OFFSET, -4)	
		end		

		if USE_POWERBAR_OFFSET == true then
			if USE_PORTRAIT == true and not USE_PORTRAIT_OVERLAY then
				threat:Point("BOTTOMLEFT", frame.Portrait.backdrop, "BOTTOMLEFT", -4, -4)
			else
				threat:Point("BOTTOMLEFT", frame.Health, "BOTTOMLEFT", -5, -5)
			end
			threat:Point("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", 5, -5)
		end				
	end
	
	--Rest Icon
	do
		local rIcon = frame.Resting
		if db.restIcon then
			if not frame:IsElementEnabled('Resting') then
				frame:EnableElement('Resting')
			end				
		elseif frame:IsElementEnabled('Resting') then
			frame:DisableElement('Resting')
			rIcon:Hide()
		end
	end
	
	--Health
	do
		local health = frame.Health
		health.Smooth = self.db.smoothbars

		--Text
		local x, y = self:GetPositionOffset(db.health.position)
		health.value:ClearAllPoints()
		health.value:Point(db.health.position, health, db.health.position, x, y)
		frame:Tag(health.value, db.health.text_format)
		
		--Colors
		health.colorSmooth = nil
		health.colorHealth = nil
		health.colorClass = nil
		health.colorReaction = nil
		if self.db['colors'].healthclass ~= true then
			if self.db['colors'].colorhealthbyvalue == true then
				health.colorSmooth = true
			else
				health.colorHealth = true
			end		
		else
			health.colorClass = true
			health.colorReaction = true
		end	
		
		--Position
		health:ClearAllPoints()
		health:Point("TOPRIGHT", frame, "TOPRIGHT", -BORDER, -BORDER)
		if USE_POWERBAR_OFFSET then
			health:Point("TOPRIGHT", frame, "TOPRIGHT", -(BORDER+POWERBAR_OFFSET), -BORDER)
			health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, BORDER+POWERBAR_OFFSET)
		elseif USE_MINI_POWERBAR then
			health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, BORDER + (POWERBAR_HEIGHT/2))
		else
			health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, BORDER + POWERBAR_HEIGHT)
		end
		
		health.bg:ClearAllPoints()
		if not USE_PORTRAIT_OVERLAY then
			health:Point("TOPLEFT", PORTRAIT_WIDTH+BORDER, -BORDER)		
			health.bg:SetParent(health)
			health.bg:SetAllPoints()
		else
			health.bg:Point('BOTTOMLEFT', health:GetStatusBarTexture(), 'BOTTOMRIGHT')
			health.bg:Point('TOPRIGHT', health)		
			health.bg:SetParent(frame.Portrait.overlay)			
		end
		
		if USE_CLASSBAR then
			local DEPTH
			if USE_MINI_CLASSBAR then
				DEPTH = -(BORDER+(CLASSBAR_HEIGHT/2))
			else
				DEPTH = -(BORDER+CLASSBAR_HEIGHT+SPACING)
			end
			
			if USE_POWERBAR_OFFSET then
				health:Point("TOPRIGHT", frame, "TOPRIGHT", -(BORDER+POWERBAR_OFFSET), DEPTH)
			else
				health:Point("TOPRIGHT", frame, "TOPRIGHT", -BORDER, DEPTH)
			end
			
			health:Point("TOPLEFT", frame, "TOPLEFT", PORTRAIT_WIDTH+BORDER, DEPTH)
		end
	end
	
	--Name
	do
		local name = frame.Name
		if not db.power.hideonnpc then
			local x, y = self:GetPositionOffset(db.name.position)
			name:ClearAllPoints()
			name:Point(db.name.position, frame.Health, db.name.position, x, y)				
		end
		
		frame:Tag(name, db.name.text_format)
	end	
	
	--PvP
	do
		local pvp = frame.PvPText
		local x, y = self:GetPositionOffset(db.pvp.position)
		pvp:ClearAllPoints()
		pvp:Point(db.pvp.position, frame.Health, db.pvp.position, x, y)	

		frame:Tag(pvp, db.pvp.text_format)		
	end
	
	--Power
	do
		local power = frame.Power
		if USE_POWERBAR then
			if not frame:IsElementEnabled('Power') then
				frame:EnableElement('Power')
				power:Show()
			end		
		
			power.Smooth = self.db.smoothbars
			
			--Text
			local x, y = self:GetPositionOffset(db.power.position)
			power.value:ClearAllPoints()
			power.value:Point(db.power.position, frame.Health, db.power.position, x, y)		
			frame:Tag(power.value, db.power.text_format)
			
			--Colors
			power.colorClass = nil
			power.colorReaction = nil	
			power.colorPower = nil
			if self.db['colors'].powerclass then
				power.colorClass = true
				power.colorReaction = true
			else
				power.colorPower = true
			end		
			
			--Position
			power:ClearAllPoints()
			if USE_POWERBAR_OFFSET then
				power:Point("TOPRIGHT", frame.Health, "TOPRIGHT", POWERBAR_OFFSET, -POWERBAR_OFFSET)
				power:Point("BOTTOMLEFT", frame.Health, "BOTTOMLEFT", POWERBAR_OFFSET, -POWERBAR_OFFSET)
				power:SetFrameStrata("LOW")
				power:SetFrameLevel(2)
			elseif USE_MINI_POWERBAR then
				power:Width(POWERBAR_WIDTH - BORDER*2)
				power:Height(POWERBAR_HEIGHT - BORDER*2)
				power:Point("RIGHT", frame, "BOTTOMRIGHT", -(BORDER*2 + 4), BORDER + (POWERBAR_HEIGHT/2))
				power:SetFrameStrata("MEDIUM")
				power:SetFrameLevel(frame:GetFrameLevel() + 3)
			else
				power:Point("TOPLEFT", frame.Health.backdrop, "BOTTOMLEFT", BORDER, -(BORDER + SPACING))
				power:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -BORDER, BORDER)
			end
		elseif frame:IsElementEnabled('Power') then
			frame:DisableElement('Power')
			power:Hide()
		end
	end
	
	--Portrait
	do
		local portrait = frame.Portrait
		
		--Set Points
		if USE_PORTRAIT then
			if not frame:IsElementEnabled('Portrait') then
				frame:EnableElement('Portrait')
			end
			
			portrait:ClearAllPoints()
			
			if USE_PORTRAIT_OVERLAY then
				portrait:SetFrameLevel(frame.Health:GetFrameLevel() + 1)
				portrait:SetAllPoints(frame.Health)
				portrait:SetAlpha(0.3)
				portrait:Show()		
				portrait.backdrop:Hide()
			else
				portrait:SetAlpha(1)
				portrait:Show()
				portrait.backdrop:Show()
				if USE_MINI_CLASSBAR and USE_CLASSBAR then
					portrait.backdrop:Point("TOPLEFT", frame, "TOPLEFT", 0, -((CLASSBAR_HEIGHT/2)))
				else
					portrait.backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT")
				end		
				
				if USE_MINI_POWERBAR or USE_POWERBAR_OFFSET or not USE_POWERBAR then
					portrait.backdrop:Point("BOTTOMRIGHT", frame.Health.backdrop, "BOTTOMLEFT", -SPACING, 0)
				else
					portrait.backdrop:Point("BOTTOMRIGHT", frame.Power.backdrop, "BOTTOMLEFT", -SPACING, 0)
				end	

				portrait:Point('BOTTOMLEFT', portrait.backdrop, 'BOTTOMLEFT', BORDER, BORDER)		
				portrait:Point('TOPRIGHT', portrait.backdrop, 'TOPRIGHT', -BORDER, -BORDER)				
			end
		else
			if frame:IsElementEnabled('Portrait') then
				frame:DisableElement('Portrait')
				portrait:Hide()
				portrait.backdrop:Hide()
			end		
		end
	end

	--Auras Disable/Enable
	--Only do if both debuffs and buffs aren't being used.
	do
		if db.debuffs.enable or db.buffs.enable then
			if not frame:IsElementEnabled('Aura') then
				frame:EnableElement('Aura')
			end	
		else
			if frame:IsElementEnabled('Aura') then
				frame:DisableElement('Aura')
			end			
		end
		
		frame.Buffs:ClearAllPoints()
		frame.Debuffs:ClearAllPoints()
	end
	
	--Buffs
	do
		local buffs = frame.Buffs
		local rows = db.buffs.numrows
		
		if USE_POWERBAR_OFFSET then
			buffs:SetWidth(UNIT_WIDTH - POWERBAR_OFFSET)
		else
			buffs:SetWidth(UNIT_WIDTH)
		end
		
		buffs.forceShow = frame.forceShowAuras
		buffs.num = db.buffs.perrow * rows
		buffs.size = db.buffs.sizeOverride ~= 0 and db.buffs.sizeOverride or ((((buffs:GetWidth() - (buffs.spacing*(buffs.num/rows - 1))) / buffs.num)) * rows)

		if db.buffs.sizeOverride and db.buffs.sizeOverride > 0 then
			buffs:SetWidth(db.buffs.perrow * db.buffs.sizeOverride)
		end
		
		local x, y = E:GetXYOffset(db.buffs.anchorPoint)
		local attachTo = self:GetAuraAnchorFrame(frame, db.buffs.attachTo)
		
		buffs:Point(E.InversePoints[db.buffs.anchorPoint], attachTo, db.buffs.anchorPoint, x + db.buffs.xOffset, y + db.buffs.yOffset)
		buffs:Height(buffs.size * rows)
		buffs["growth-y"] = db.buffs.anchorPoint:find('TOP') and 'UP' or 'DOWN'
		buffs["growth-x"] = db.buffs.anchorPoint == 'LEFT' and 'LEFT' or  db.buffs.anchorPoint == 'RIGHT' and 'RIGHT' or (db.buffs.anchorPoint:find('LEFT') and 'RIGHT' or 'LEFT')
		buffs.initialAnchor = E.InversePoints[db.buffs.anchorPoint]

		if db.buffs.enable then			
			buffs:Show()
		else
			buffs:Hide()
		end
	end
	
	--Debuffs
	do
		local debuffs = frame.Debuffs
		local rows = db.debuffs.numrows
		
		if USE_POWERBAR_OFFSET then
			debuffs:SetWidth(UNIT_WIDTH - POWERBAR_OFFSET)
		else
			debuffs:SetWidth(UNIT_WIDTH)
		end
		
		debuffs.forceShow = frame.forceShowAuras
		debuffs.num = db.debuffs.perrow * rows
		debuffs.size = db.debuffs.sizeOverride ~= 0 and db.debuffs.sizeOverride or ((((debuffs:GetWidth() - (debuffs.spacing*(debuffs.num/rows - 1))) / debuffs.num)) * rows)
		
		if db.debuffs.sizeOverride and db.debuffs.sizeOverride > 0 then
			debuffs:SetWidth(db.debuffs.perrow * db.debuffs.sizeOverride)
		end
		
		local x, y = E:GetXYOffset(db.debuffs.anchorPoint)
		local attachTo = self:GetAuraAnchorFrame(frame, db.debuffs.attachTo, db.debuffs.attachTo == 'BUFFS' and db.buffs.attachTo == 'DEBUFFS')
		
		debuffs:Point(E.InversePoints[db.debuffs.anchorPoint], attachTo, db.debuffs.anchorPoint, x + db.debuffs.xOffset, y + db.debuffs.yOffset)
		debuffs:Height(debuffs.size * rows)
		debuffs["growth-y"] = db.debuffs.anchorPoint:find('TOP') and 'UP' or 'DOWN'
		debuffs["growth-x"] = db.debuffs.anchorPoint == 'LEFT' and 'LEFT' or  db.debuffs.anchorPoint == 'RIGHT' and 'RIGHT' or (db.debuffs.anchorPoint:find('LEFT') and 'RIGHT' or 'LEFT')
		debuffs.initialAnchor = E.InversePoints[db.debuffs.anchorPoint]

		if db.debuffs.enable then			
			debuffs:Show()
		else
			debuffs:Hide()
		end
	end	
	
	--Castbar
	do
		local castbar = frame.Castbar
		castbar:Width(db.castbar.width - 4)
		castbar:Height(db.castbar.height)
		castbar.Holder:Width(db.castbar.width)
		castbar.Holder:Height(db.castbar.height + 4)
		castbar.Holder:GetScript('OnSizeChanged')(castbar.Holder)
		
		--Latency
		if db.castbar.latency then
			castbar.SafeZone = castbar.LatencyTexture
			castbar.LatencyTexture:Show()
		else
			castbar.SafeZone = nil
			castbar.LatencyTexture:Hide()
		end
		
		--Icon
		if db.castbar.icon then
			castbar.Icon = castbar.ButtonIcon
			castbar.Icon.bg:Width(db.castbar.height + 4)
			castbar.Icon.bg:Height(db.castbar.height + 4)
			
			castbar:Width(db.castbar.width - castbar.Icon.bg:GetWidth() - 5)
			castbar.Icon.bg:Show()
		else
			castbar.ButtonIcon.bg:Hide()
			castbar.Icon = nil
		end

		if db.castbar.spark then
			castbar.Spark:Show()
		else
			castbar.Spark:Hide()
		end

		if db.castbar.enable and not frame:IsElementEnabled('Castbar') then
			frame:EnableElement('Castbar')
		elseif not db.castbar.enable and frame:IsElementEnabled('Castbar') then
			frame:DisableElement('Castbar')	
		end			
	end
	
	--Resource Bars
	do
		if E.myclass == "PALADIN" then
			local bars = frame.HolyPower
			bars:ClearAllPoints()
			
			local MAX_HOLY_POWER = 5
			
			if USE_MINI_CLASSBAR then
				CLASSBAR_WIDTH = CLASSBAR_WIDTH * (MAX_HOLY_POWER - 1) / MAX_HOLY_POWER		
				bars:Point("CENTER", frame.Health.backdrop, "TOP", -(BORDER*3 + 6), 0)
				bars:SetFrameStrata("MEDIUM")
			else
				bars:Point("BOTTOMLEFT", frame.Health.backdrop, "TOPLEFT", BORDER, BORDER+SPACING)
				bars:SetFrameStrata("LOW")
			end

			bars:Width(CLASSBAR_WIDTH)
			bars:Height(CLASSBAR_HEIGHT - (BORDER*2))			

			for i = 1, MAX_HOLY_POWER do
				bars[i]:SetHeight(bars:GetHeight())	
				bars[i]:SetWidth(E:Scale(bars:GetWidth() - 2)/MAX_HOLY_POWER)	
				bars[i]:GetStatusBarTexture():SetHorizTile(false)
				bars[i]:ClearAllPoints()
				if i == 1 then
					bars[i]:SetPoint("LEFT", bars)
				else
					if USE_MINI_CLASSBAR then
						bars[i]:Point("LEFT", bars[i-1], "RIGHT", SPACING+(BORDER*2)+2, 0)
					else
						bars[i]:Point("LEFT", bars[i-1], "RIGHT", SPACING, 0)
					end
				end
				
				if not USE_MINI_CLASSBAR then
					bars[i].backdrop:Hide()
				else
					bars[i].backdrop:Show()
				end
			end
			
			if not USE_MINI_CLASSBAR then
				bars.backdrop:Show()
			else
				bars.backdrop:Hide()			
			end		
			
			if USE_CLASSBAR and not frame:IsElementEnabled('HolyPower') then
				frame:EnableElement('HolyPower')
				bars:Show()
			elseif not USE_CLASSBAR and frame:IsElementEnabled('HolyPower') then
				frame:DisableElement('HolyPower')	
				bars:Hide()
			end		
		elseif E.myclass == 'PRIEST' then
			local bars = frame.ShadowOrbs
			bars:ClearAllPoints()
			if USE_MINI_CLASSBAR then
				CLASSBAR_WIDTH = CLASSBAR_WIDTH * (PRIEST_BAR_NUM_ORBS - 1) / PRIEST_BAR_NUM_ORBS
				bars:Point("CENTER", frame.Health.backdrop, "TOP", -(BORDER*3 + 6), 0)
				bars:SetFrameStrata("MEDIUM")
			else
				bars:Point("BOTTOMLEFT", frame.Health.backdrop, "TOPLEFT", BORDER, BORDER+SPACING)
				bars:SetFrameStrata("LOW")
			end
				
			bars:Width(CLASSBAR_WIDTH)
			bars:Height(CLASSBAR_HEIGHT - (BORDER*2))

			for i = 1, PRIEST_BAR_NUM_ORBS do
				bars[i]:SetHeight(bars:GetHeight())	
				bars[i]:SetWidth(E:Scale(bars:GetWidth() - 2)/PRIEST_BAR_NUM_ORBS)	
				bars[i]:GetStatusBarTexture():SetHorizTile(false)
				bars[i]:ClearAllPoints()
				if i == 1 then
					bars[i]:SetPoint("LEFT", bars)
				else
					if USE_MINI_CLASSBAR then
						bars[i]:Point("LEFT", bars[i-1], "RIGHT", SPACING+(BORDER*2)+8, 0)
					else
						bars[i]:Point("LEFT", bars[i-1], "RIGHT", SPACING, 0)
					end
				end
				
				if not USE_MINI_CLASSBAR then
					bars[i].backdrop:Hide()
				else
					bars[i].backdrop:Show()
				end
			end
			
			if not USE_MINI_CLASSBAR then
				bars.backdrop:Show()
			else
				bars.backdrop:Hide()			
			end		
			
			if USE_CLASSBAR and not frame:IsElementEnabled('ShadowOrbs') then
				frame:EnableElement('ShadowOrbs')
			elseif not USE_CLASSBAR and frame:IsElementEnabled('ShadowOrbs') then
				frame:DisableElement('ShadowOrbs')	
				bars:Hide()
			end
		elseif E.myclass == 'MAGE' then
			local bars = frame.ArcaneChargeBar
			bars:ClearAllPoints()
			if USE_MINI_CLASSBAR then
				CLASSBAR_WIDTH = CLASSBAR_WIDTH * (UF['classMaxResourceBar'][E.myclass] - 1) / UF['classMaxResourceBar'][E.myclass]
				bars:Point("CENTER", frame.Health.backdrop, "TOP", -(BORDER*3 + 12), 0)
				bars:SetFrameStrata("MEDIUM")
			else
				bars:Point("BOTTOMLEFT", frame.Health.backdrop, "TOPLEFT", BORDER, BORDER+SPACING)
				bars:SetFrameStrata("LOW")
			end
				
			bars:Width(CLASSBAR_WIDTH)
			bars:Height(CLASSBAR_HEIGHT - (BORDER*2))

			for i = 1, UF['classMaxResourceBar'][E.myclass] do
				bars[i]:SetHeight(bars:GetHeight())	
				bars[i]:SetWidth(E:Scale(bars:GetWidth() - 2)/UF['classMaxResourceBar'][E.myclass])	
				bars[i]:GetStatusBarTexture():SetHorizTile(false)
				bars[i]:ClearAllPoints()
				if i == 1 then
					bars[i]:SetPoint("LEFT", bars)
				else
					if USE_MINI_CLASSBAR then
						bars[i]:Point("LEFT", bars[i-1], "RIGHT", SPACING+(BORDER*2)+2, 0)
					else
						bars[i]:Point("LEFT", bars[i-1], "RIGHT", SPACING, 0)
					end
				end
				
				if not USE_MINI_CLASSBAR then
					bars[i].backdrop:Hide()
				else
					bars[i].backdrop:Show()
				end
			end
			
			if not USE_MINI_CLASSBAR then
				bars.backdrop:Show()
			else
				bars.backdrop:Hide()			
			end		

			if USE_CLASSBAR and not frame:IsElementEnabled('ArcaneChargeBar') then
				frame:EnableElement('ArcaneChargeBar')
			elseif not USE_CLASSBAR and frame:IsElementEnabled('ArcaneChargeBar') then
				frame:DisableElement('ArcaneChargeBar')	
			end		
		elseif E.myclass == "WARLOCK" then
			local bars = frame.ShardBar
			bars:ClearAllPoints()
			if USE_MINI_CLASSBAR then
				CLASSBAR_WIDTH = CLASSBAR_WIDTH * 2 / 3
				bars:Point("CENTER", frame.Health.backdrop, "TOP", -(BORDER*3 + 6), 0)
				bars:SetFrameStrata("MEDIUM")
			else
				bars:Point("BOTTOMLEFT", frame.Health.backdrop, "TOPLEFT", BORDER, BORDER+SPACING)
				bars:SetFrameStrata("LOW")
			end
			bars:Width(CLASSBAR_WIDTH)
			bars:Height(CLASSBAR_HEIGHT - (BORDER*2))
			
			if not USE_MINI_CLASSBAR then
				bars.backdrop:Show()
			else
				bars.backdrop:Hide()			
			end
			
			if USE_CLASSBAR and not frame:IsElementEnabled('ShardBar') then
				frame:EnableElement('ShardBar')
			elseif not USE_CLASSBAR and frame:IsElementEnabled('ShardBar') then
				frame:DisableElement('ShardBar')
				bars:Hide()
			end					
		elseif E.myclass == 'MONK' then
			local bars = frame.Harmony
			bars:ClearAllPoints()
			if USE_MINI_CLASSBAR then
				bars:Point("CENTER", frame.Health.backdrop, "TOP", -(BORDER*3 + 6), 0)
				bars:SetFrameStrata("MEDIUM")			
			else
				bars:Point("BOTTOMLEFT", frame.Health.backdrop, "TOPLEFT", BORDER, BORDER+SPACING)
				bars:SetFrameStrata("LOW")
			end
			bars:Width(CLASSBAR_WIDTH)
			bars:Height(CLASSBAR_HEIGHT - (BORDER*2))
			
			if not USE_MINI_CLASSBAR then
				bars.backdrop:Show()
			else
				bars.backdrop:Hide()			
			end
			
			if USE_CLASSBAR and not frame:IsElementEnabled('Harmony') then
				frame:EnableElement('Harmony')
				bars:Show()
			elseif not USE_CLASSBAR and frame:IsElementEnabled('Harmony') then
				frame:DisableElement('Harmony')
				bars:Hide()
			end				
		elseif E.myclass == "DEATHKNIGHT" then
			local runes = frame.Runes
			runes:ClearAllPoints()
			if USE_MINI_CLASSBAR then
				CLASSBAR_WIDTH = CLASSBAR_WIDTH * 4/5
				runes:Point("CENTER", frame.Health.backdrop, "TOP", -(BORDER*3 + 8), 0)
				runes:SetFrameStrata("MEDIUM")
			else
				runes:Point("BOTTOMLEFT", frame.Health.backdrop, "TOPLEFT", BORDER, BORDER+SPACING)
				runes:SetFrameStrata("LOW")
			end
			runes:Width(CLASSBAR_WIDTH)
			runes:Height(CLASSBAR_HEIGHT - (BORDER*2))			
			
			for i = 1, 6 do
				runes[i]:SetHeight(runes:GetHeight())
				runes[i]:SetWidth(E:Scale(runes:GetWidth() - 5) / 6)	
				if USE_MINI_CLASSBAR then
					runes[i].backdrop:Show()
				else
					runes[i].backdrop:Hide()	
				end
				
				runes[i]:ClearAllPoints()
				if i == 1 then
					runes[i]:SetPoint("LEFT", runes)
				else
					if USE_MINI_CLASSBAR then
						runes[i]:Point("LEFT", runes[i-1], "RIGHT", SPACING+(BORDER*2)+2, 0)
					else
						runes[i]:Point("LEFT", runes[i-1], "RIGHT", SPACING, 0)
					end
				end	
				
				if not USE_MINI_CLASSBAR then
					runes[i].backdrop:Hide()
				else
					runes[i].backdrop:Show()
				end					
			end
			
			if not USE_MINI_CLASSBAR then
				runes.backdrop:Show()
			else
				runes.backdrop:Hide()
			end		

			if USE_CLASSBAR and not frame:IsElementEnabled('Runes') then
				frame:EnableElement('Runes')
				runes:Show()
			elseif not USE_CLASSBAR and frame:IsElementEnabled('Runes') then
				frame:DisableElement('Runes')	
				runes:Hide()
				RuneFrame.Show = RuneFrame.Hide
				RuneFrame:Hide()				
			end								
		elseif E.myclass == "DRUID" then
			local eclipseBar = frame.EclipseBar

			eclipseBar:ClearAllPoints()
			if not USE_MINI_CLASSBAR then
				eclipseBar:Point("BOTTOMLEFT", frame.Health.backdrop, "TOPLEFT", BORDER, BORDER+SPACING)
				eclipseBar:SetFrameStrata("LOW")
			else		
				CLASSBAR_WIDTH = CLASSBAR_WIDTH * 2/3			
				eclipseBar:Point("LEFT", frame.Health.backdrop, "TOPLEFT", (BORDER*2 + 4), 0)
				eclipseBar:SetFrameStrata("MEDIUM")						
			end

			eclipseBar:Width(CLASSBAR_WIDTH)
			eclipseBar:Height(CLASSBAR_HEIGHT - (BORDER*2))	
			
			--?? Apparent bug fix for the width after in-game settings change
			eclipseBar.LunarBar:SetMinMaxValues(0, 0)
			eclipseBar.SolarBar:SetMinMaxValues(0, 0)
			eclipseBar.LunarBar:Size(CLASSBAR_WIDTH, CLASSBAR_HEIGHT - (BORDER*2))			
			eclipseBar.SolarBar:Size(CLASSBAR_WIDTH, CLASSBAR_HEIGHT - (BORDER*2))	
			
			if USE_CLASSBAR and not frame:IsElementEnabled('EclipseBar') then
				frame:EnableElement('EclipseBar')
				eclipseBar:Show()
			elseif not USE_CLASSBAR and frame:IsElementEnabled('EclipseBar') then
				frame:DisableElement('EclipseBar')	
				eclipseBar:Hide()
			end					
		end
	end
	
	--Combat Fade
	do
		if db.combatfade and not frame:IsElementEnabled('CombatFade') then
			frame:EnableElement('CombatFade')
		elseif not db.combatfade and frame:IsElementEnabled('CombatFade') then
			frame:DisableElement('CombatFade')
		end		
	end
	
	--Debuff Highlight
	do
		local dbh = frame.DebuffHighlight
		if E.db.unitframe.debuffHighlighting then
			frame:EnableElement('DebuffHighlight')
		else
			frame:DisableElement('DebuffHighlight')	
		end
	end
	
	--OverHealing
	do
		local healPrediction = frame.HealPrediction
		
		if db.healPrediction then
			if not frame:IsElementEnabled('HealPrediction') then
				frame:EnableElement('HealPrediction')
			end

			healPrediction.myBar:ClearAllPoints()
			healPrediction.myBar:Width(db.width - (BORDER*2))
			healPrediction.myBar:SetPoint('BOTTOMLEFT', frame.Health:GetStatusBarTexture(), 'BOTTOMRIGHT')
			healPrediction.myBar:SetPoint('TOPLEFT', frame.Health:GetStatusBarTexture(), 'TOPRIGHT')	

			healPrediction.otherBar:ClearAllPoints()
			healPrediction.otherBar:SetPoint('TOPLEFT', healPrediction.myBar:GetStatusBarTexture(), 'TOPRIGHT')	
			healPrediction.otherBar:SetPoint('BOTTOMLEFT', healPrediction.myBar:GetStatusBarTexture(), 'BOTTOMRIGHT')	
			healPrediction.otherBar:Width(db.width - (BORDER*2))
			
			if not USE_PORTRAIT_OVERLAY then
				healPrediction.myBar:SetParent(frame)
				healPrediction.otherBar:SetParent(frame)
			else	
				healPrediction.myBar:SetParent(frame.Portrait.overlay)		
				healPrediction.otherBar:SetParent(frame.Portrait.overlay)					
			end
		else
			if frame:IsElementEnabled('HealPrediction') then
				frame:DisableElement('HealPrediction')
			end		
		end
	end
	
	--AuraBars
	do
		local auraBars = frame.AuraBars
		
		if db.aurabar.enable then
			if not frame:IsElementEnabled('AuraBars') then
				frame:EnableElement('AuraBars')
			end
			auraBars:Show()
			auraBars.friendlyAuraType = db.aurabar.friendlyAuraType
			auraBars.enemyAuraType = db.aurabar.enemyAuraType
			
			local buffColor = UF.db.colors.auraBarBuff
			local debuffColor = UF.db.colors.auraBarDebuff
			local attachTo = frame
			
			if db.aurabar.attachTo == 'BUFFS' then
				attachTo = frame.Buffs
			elseif db.aurabar.attachTo == 'DEBUFFS' then
				attachTo = frame.Debuffs
			end
			
			local anchorPoint, anchorTo = 'BOTTOM', 'TOP'
			if db.aurabar.anchorPoint == 'BELOW' then
				anchorPoint, anchorTo = 'TOP', 'BOTTOM'
			end

			auraBars:ClearAllPoints()
			auraBars:SetPoint(anchorPoint..'LEFT', attachTo, anchorTo..'LEFT', (attachTo == frame and anchorTo == 'BOTTOM') and POWERBAR_OFFSET or 0, 0)
			auraBars:SetPoint(anchorPoint..'RIGHT', attachTo, anchorTo..'RIGHT', attachTo == frame and POWERBAR_OFFSET * (anchorTo == 'BOTTOM' and 0 or -1) or 0, 0)

			auraBars.buffColor = {buffColor.r, buffColor.g, buffColor.b}
			auraBars.debuffColor = {debuffColor.r, debuffColor.g, debuffColor.b}
			auraBars.down = db.aurabar.anchorPoint == 'BELOW'
			auraBars:SetAnchors()
		else
			if frame:IsElementEnabled('AuraBars') then
				frame:DisableElement('AuraBars')
				auraBars:Hide()
			end		
		end
	end

	if db.customTexts then
		for objectName, _ in pairs(db.customTexts) do
			if not frame[objectName] then
				frame[objectName] = frame:CreateFontString(nil, 'OVERLAY')
			end
			
			local objectDB = db.customTexts[objectName]
			UF:CreateCustomTextGroup('player', objectName)
			
			frame[objectName]:FontTemplate(UF.LSM:Fetch("font", objectDB.font or UF.db.font), objectDB.size or UF.db.fontSize, objectDB.fontOutline or UF.db.fontOutline)
			frame:Tag(frame[objectName], objectDB.text_format or '')
			frame[objectName]:SetPoint('CENTER', frame, 'CENTER', objectDB.xOffset, objectDB.yOffset)
		end
	end

	E:SetMoverSnapOffset(frame:GetName()..'Mover', -(12 + db.castbar.height))
	frame:UpdateAllElements()
end

tinsert(UF['unitstoload'], 'player')