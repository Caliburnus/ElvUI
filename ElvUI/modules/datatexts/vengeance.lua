local E, L, V, P, G, _ = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
local DT = E:GetModule('DataTexts')

local displayString = '';
local lastPanel;
local self = lastPanel
local vengeance = GetSpellInfo(93098) or GetSpellInfo(76691)
local value
local tooltip = CreateFrame("GameTooltip", "VengeanceTooltip", UIParent, "GameTooltipTemplate")
local tooltiptext = _G[tooltip:GetName().."TextLeft2"]
tooltip:SetOwner(UIParent, "ANCHOR_NONE")
tooltiptext:SetText("")

local function calculate(self, event, ...)
	local name = UnitAura("player", vengeance, nil, "PLAYER|HELPFUL")
	
	if name then
		tooltip:ClearLines()
		tooltip:SetUnitBuff("player", name)
		value = (tooltiptext:GetText() and tonumber(string.match(tostring(tooltiptext:GetText()), "%d+"))) or -1
	else
		value = 0
	end
	
	self.text:SetFormattedText(displayString, vengeance, value);
end

local function ValueColorUpdate(hex, r, g, b)
	displayString = string.join("", "%s: ", hex, "%s|r")
	
	if lastPanel ~= nil then
		OnEvent(lastPanel)
	end
end
E['valueColorUpdateFuncs'][ValueColorUpdate] = true

--[[
	DT:RegisterDatatext(name, events, eventFunc, updateFunc, clickFunc, onEnterFunc, onLeaveFunc)
	
	name - name of the datatext (required)
	events - must be a table with string values of event names to register 
	eventFunc - function that gets fired when an event gets triggered
	updateFunc - onUpdate script target function
	click - function to fire when clicking the datatext
	onEnterFunc - function to fire OnEnter
	onLeaveFunc - function to fire OnLeave, if not provided one will be set for you that hides the tooltip.
]]
DT:RegisterDatatext("Vengeance", {"UNIT_AURA", "PLAYER_ENTERING_WORLD"}, calculate)