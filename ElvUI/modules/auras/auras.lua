local E, L, V, P, G, _ = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
local A = E:NewModule('Auras', 'AceHook-3.0', 'AceEvent-3.0');
local LSM = LibStub("LibSharedMedia-3.0")

function A:FormatTime(s)
	local day, hour, minute = 86400, 3600, 60
	if s >= day then
		return format("|cffeeeeee%dd|r", ceil(s / day))
	elseif s >= hour then
		return format("|cffeeeeee%dh|r", ceil(s / hour))
	elseif s >= minute then
		return format("|cffeeeeee%dm|r", ceil(s / minute))
	elseif s >= minute / 12 and s > E.db.auras.fadeThreshold then
		return tostring(floor(s))..'s'
	end
	return format("%.1fs", s)
end

function A:UpdateTime(elapsed)
	if(self.expiration) then	
		self.expiration = math.max(self.expiration - elapsed, 0)
		if(self.expiration <= 0) then
			self.time:SetText("")
		else
			local time = A:FormatTime(self.expiration)
			if self.expiration <= 86400.5 and self.expiration > 3600.5 then
				self.time:SetText("|cffcccccc"..time.."|r")
				E:StopFlash(self)
			elseif self.expiration <= 3600.5 and self.expiration > 60.5 then
				self.time:SetText("|cffcccccc"..time.."|r")
				E:StopFlash(self)
			elseif self.expiration <= 60.5 and self.expiration > E.db.auras.fadeThreshold then
				self.time:SetText("|cffcccccc"..time.."|r")
				E:StopFlash(self)
			elseif self.expiration <= E.db.auras.fadeThreshold then
				self.time:SetText("|cffff0000"..time.."|r")
				E:Flash(self, 1)
			end
		end
	end
end

function A:UpdateWeapons(button, slot, active, expiration)
	if not button.texture then
		button.texture = button:CreateTexture(nil, "BORDER")
		button.texture:SetAllPoints()
		
		button.time = button:CreateFontString(nil, "ARTWORK")
		button.time:SetPoint("TOP", button, 'BOTTOM', 0, -2)
		button.time:FontTemplate(nil, nil, 'OUTLINE')
		button.time:SetShadowColor(0, 0, 0, 0.4)
		button.time:SetShadowOffset(E.mult, -E.mult)
				
		button:CreateBackdrop('Default')
		
		button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
		button.highlight:SetTexture(1,1,1,0.45)
		button.highlight:SetAllPoints(button.texture)		
	end
	local font = LSM:Fetch("font", self.db.font)
	button.time:FontTemplate(font, self.db.fontSize, self.db.fontOutline)	
	
	if active then
		button.id = GetInventorySlotInfo(slot)
		button.quality = GetInventoryItemQuality('player', button.id)
		button.icon = GetInventoryItemTexture("player", button.id)
		button.texture:SetTexture(button.icon)
		button.texture:SetTexCoord(unpack(E.TexCoords))		
		button.expiration = (expiration/1000)
		
		local r, g, b = GetItemQualityColor(button.quality)
		button.backdrop:SetBackdropBorderColor(r, g, b)
		button:SetScript("OnUpdate", A.UpdateTime)		
	elseif not active then
		button.texture:SetTexture(nil)
		button.time:SetText("")
		button:SetScript("OnUpdate", nil)
	end
end

function A:UpdateAuras(header, button)
	if(not button.texture) then
		button.texture = button:CreateTexture(nil, "BORDER")
		button.texture:SetAllPoints()

		button.count = button:CreateFontString(nil, "ARTWORK")
		button.count:SetPoint("BOTTOMRIGHT", -1, 1)
		button.count:FontTemplate()--safty

		button.time = button:CreateFontString(nil, "ARTWORK")
		button.time:SetPoint("TOP", button, 'BOTTOM', 0, -2)
		button.time:FontTemplate()--safty

		button:SetScript("OnUpdate", A.UpdateTime)
		
		button:CreateBackdrop('Default')

		button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
		button.highlight:SetTexture(1,1,1,0.45)
		button.highlight:SetAllPoints(button.texture)			
		
		E:SetUpAnimGroup(button)
	end
	local font = LSM:Fetch("font", self.db.font)
	button.count:FontTemplate(font, self.db.fontSize, self.db.fontOutline)
	button.time:FontTemplate(font, self.db.fontSize, self.db.fontOutline)
	
	local name, _, texture, count, dtype, duration, expiration = UnitAura(header:GetAttribute("unit"), button:GetID(), header:GetAttribute("filter"))
	
	if(name) then
		button.texture:SetTexture(texture)
		button.texture:SetTexCoord(unpack(E.TexCoords))
		button.count:SetText(count > 1 and count or "")
		button.expiration = expiration - GetTime()
		
		if(header:GetAttribute("filter") == "HARMFUL") then
			local color = DebuffTypeColor[dtype] or DebuffTypeColor.none
			button.backdrop:SetBackdropBorderColor(color.r * 3/5, color.g * 3/5, color.b * 3/5)
		end
	end
end

function A:ScanAuras(event, unit)
	if(unit) then
		if(unit ~= PlayerFrame.unit) then return end
		if(unit ~= self:GetAttribute("unit")) then
			self:SetAttribute("unit", unit)
		end
	end
	
	for index = 1, 32 do		
		local child = self:GetAttribute("child" .. index)
		if(child) then
			A:UpdateAuras(self, child)
		end
	end
end

local TimeSinceLastUpdate = 1
function A:CheckWeapons(elapsed)
	TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed
	
	if (TimeSinceLastUpdate >= 1) then
		local e1, e1time, _, e2, e2time  = GetWeaponEnchantInfo()
		
		local w1 = self:GetAttribute("tempEnchant1")

		if w1 then A:UpdateWeapons(w1, "MainHandSlot", e1, e1time) end

		TimeSinceLastUpdate = 0
	end
end

function A:UpdateHeader(header)
	local db = self.db.debuffs
	if header:GetAttribute('filter') == 'HELPFUL' then
		db = self.db.buffs
		header:SetAttribute("consolidateTo", self.db.consolidedBuffs == true and E.private.general.minimap.enable == true and 1 or 0)
		header:SetAttribute("separateOwn", self.db.seperateOwn)
	end

	header:SetAttribute("sortMethod", db.sortMethod)
	header:SetAttribute("sortDir", db.sortDir)
	header:SetAttribute("maxWraps", db.maxWraps)
	header:SetAttribute("wrapAfter", self.db.wrapAfter)
	
	header:SetAttribute("minWidth", ((10 + E.private.auras.size) * self.db.wrapAfter) - 6)
	header:SetAttribute("minHeight", (10 - E.private.auras.size) * db.maxWraps)
	header:SetAttribute("wrapYOffset", -(18 + E.private.auras.size))
	AurasHolder:Width(header:GetAttribute('minWidth'))
	
	self.ScanAuras(header)
	
	A:PostDrag()
end

function A:UpdateAllHeaders()
	if E.private.auras.enable ~= true then return end
	local headers = {ElvUIPlayerBuffs,ElvUIPlayerDebuffs}
	for _, header in pairs(headers) do
		if header then
			A:UpdateHeader(header)
		end
	end
end

function A:CreateAuraHeader(filter)
	local name	
	if filter == "HELPFUL" then name = "ElvUIPlayerBuffs" else name = "ElvUIPlayerDebuffs" end

	local header = CreateFrame("Frame", name, E.UIParent, "SecureAuraHeaderTemplate")
	header:SetClampedToScreen(true)
	header:SetAttribute("template", "ElvUIAuraTemplate"..E.private.auras.size)
	header:HookScript("OnEvent", A.ScanAuras)
	header:SetAttribute("unit", "player")
	header:SetAttribute("filter", filter)
	RegisterStateDriver(header, "visibility", "[petbattle] hide; show")
	
	-- look for weapons buffs
	if filter == "HELPFUL" then
		header:SetAttribute("includeWeapons", 1)
		header:SetAttribute("weaponTemplate", "ElvUIAuraTemplate")
		header:HookScript("OnUpdate", A.CheckWeapons)
	end
	
	A:UpdateHeader(header)
	header:Show()
	
	return header
end

function A:PostDrag(position)
	local headers = {ElvUIPlayerBuffs,ElvUIPlayerDebuffs}
	for _, header in pairs(headers) do
		if header then
			if not position then position = E:GetScreenQuadrant(header) end
			if string.find(position, "LEFT") then
				header:SetAttribute("point", "TOPLEFT")
				header:SetAttribute("xOffset", (E.private.auras.size + 10))
			else
				header:SetAttribute("point", "TOPRIGHT")
				header:SetAttribute("xOffset", -(E.private.auras.size + 10))		
			end
			
			header:ClearAllPoints()
		end
	end
	
	if string.find(position, "LEFT") then
		ElvUIPlayerBuffs:Point("TOPLEFT", AurasHolder, "TOPLEFT", 2, -2)
		
		if ElvUIPlayerDebuffs then
			ElvUIPlayerDebuffs:Point("BOTTOMLEFT", AurasHolder, "BOTTOMLEFT", 2, 2)
		end
	else
		ElvUIPlayerBuffs:Point("TOPRIGHT", AurasHolder, "TOPRIGHT", -2, -2)
		
		if ElvUIPlayerDebuffs then
			ElvUIPlayerDebuffs:Point("BOTTOMRIGHT", AurasHolder, "BOTTOMRIGHT", -2, 2)	
		end
	end
end


function A:Initialize()
	if self.db then return; end --IDK WHY BUT THIS IS GETTING CALLED TWICE FROM SOMEWHERE...
	self.db = E.db.auras
	
	if E.private.auras.enable ~= true then return end
	
	BuffFrame:Kill()
	ConsolidatedBuffs:Kill()
	TemporaryEnchantFrame:Kill()	
	InterfaceOptionsFrameCategoriesButton12:SetScale(0.0001)
	
	local holder = CreateFrame("Frame", "AurasHolder", E.UIParent)
	holder:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -8, 2)
	holder:Width(456)
	holder:Height(E.MinimapHeight)
	
	self.BuffFrame = self:CreateAuraHeader("HELPFUL")
	self.DebuffFrame = self:CreateAuraHeader("HARMFUL")

	E:CreateMover(AurasHolder, "AurasMover", "Auras Frame", false, nil, A.PostDrag)

	self:Construct_ConsolidatedBuffs()
end

E:RegisterModule(A:GetName())