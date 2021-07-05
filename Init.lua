local addonName, addonTable = ...
local E, L, V, P, G = unpack(ElvUI) -- Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local EP = LibStub("LibElvUIPlugin-1.0")
local version = GetAddOnMetadata(addonName, "Version")

local Addon = E:NewModule(addonName, "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0")
Addon.name = "Flyout Bars"
Addon.title = "|cff1784d1ElvUI|r |cffFFB600Flyout Bars|r"

addonTable[1] = Addon
_G[addonName] = Addon

function Addon:Initialize()
    EP:RegisterPlugin(addonName, Addon.InsertOptions)

    if LibStub("Masque", true) then
        Addon.masqueGroup = LibStub("Masque", true):Group(Addon.title, "Flyout Bars", true)
    end

    Addon.bars = {}
    for name, config in pairs(E.db[addonName].bars) do
        Addon.bars[name] = Addon:CreateFlyoutBar(name, config)
    end
end

function Addon:Update()
    for name, bar in pairs(Addon.bars) do
        if E.db[addonName].bars[name] then
            Addon:UpdateFlyoutBar(bar)
        else
            bar:Hide()
            Addon.bars[name] = nil
        end
    end

    for name, config in pairs(E.db[addonName].bars) do
        if not Addon.bars[name] then
            Addon.bars[name] = Addon:CreateFlyoutBar(name, config)
        end
    end
end

E:RegisterModule(Addon:GetName())
