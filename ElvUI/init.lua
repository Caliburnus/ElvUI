--[[
~AddOn Engine~

To load the AddOn engine add this to the top of your file:
	
	local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
	
To load the AddOn engine inside another addon add this to the top of your file:
	
	local E, L, V, P, G = unpack(ElvUI); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
]]
local AddOnName, Engine = ...;
local AddOn = LibStub("AceAddon-3.0"):NewAddon(AddOnName, "AceConsole-3.0", "AceEvent-3.0", 'AceTimer-3.0', 'AceHook-3.0');
local DEFAULT_WIDTH = 890;
local DEFAULT_HEIGHT = 651;
AddOn.DF = {}; AddOn.DF["profile"] = {}; AddOn.DF["global"] = {}; AddOn.privateVars = {}; AddOn.privateVars["profile"] = {}; -- Defaults
AddOn.Options = {
	type = "group",
	name = AddOnName,
	args = {},
};

local Locale = LibStub("AceLocale-3.0"):GetLocale(AddOnName, false);

Engine[1] = AddOn;
Engine[2] = Locale;
Engine[3] = AddOn.privateVars["profile"];
Engine[4] = AddOn.DF["profile"];
Engine[5] = AddOn.DF["global"];

_G[AddOnName] = Engine;

local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local LibDualSpec = LibStub('LibDualSpec-1.0')

function AddOn:OnInitialize()
	if not ElvCharacterData then
		ElvCharacterData = {};
	end
	
	self.data = LibStub("AceDB-3.0"):New("ElvData", self.DF);	
	self.charSettings = LibStub("AceDB-3.0"):New("ElvPrivateData", self.privateVars);	
	self.db = self.data.profile;
	self.global = self.data.global;
	self.private = self.charSettings.profile
	
	self:UIScale();
	self:UpdateMedia();
	
	self:RegisterEvent('PLAYER_LOGIN', 'Initialize')
	self:InitializeInitialModules()
end

function AddOn:OnProfileReset()
	StaticPopup_Show("CONFIG_RL")
end

function AddOn:OnProfileCopied(arg1, arg2, arg3)
	print(arg1, arg2, arg3)
	StaticPopup_Show("COPY_PROFILE")
end

function AddOn:LoadConfig()	
	AC:RegisterOptionsTable(AddOnName, self.Options)
	ACD:SetDefaultSize(AddOnName, DEFAULT_WIDTH, DEFAULT_HEIGHT)	
	
	--Create Profiles Table
	self.Options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.data);
	AC:RegisterOptionsTable("ElvProfiles", self.Options.args.profiles)
	self.Options.args.profiles.order = -10
	
	LibDualSpec:EnhanceDatabase(self.data, AddOnName)
	LibDualSpec:EnhanceOptions(self.Options.args.profiles, self.data)
end

function AddOn:ToggleConfig() 
	local mode = 'Close'
	if not ACD.OpenFrames[AddOnName] then
		mode = 'Open'
	end
	
	if mode == 'Open' then
		ElvConfigToggle.text:SetTextColor(unpack(AddOn.media.rgbvaluecolor))
	else
		ElvConfigToggle.text:SetTextColor(1, 1, 1)
	end
	
	ACD[mode](ACD, AddOnName) 
	
	GameTooltip:Hide() --Just in case you're mouseovered something and it closes.
end