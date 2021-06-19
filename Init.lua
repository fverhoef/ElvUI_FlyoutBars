local addonName, addonTable = ...
local E, L, V, P, G = unpack(ElvUI) -- Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local EP = LibStub("LibElvUIPlugin-1.0")
local LSM = LibStub("LibSharedMedia-3.0")
local version = GetAddOnMetadata(addonName, "Version")

local Module = E:NewModule(addonName, "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0")
Module.name = "Classic Class Bars"
Module.title = "|cff76FF03" .. Module.name .. "|r"

addonTable[1] = Module
_G[addonName] = Module

function Module:Initialize()
    EP:RegisterPlugin(addonName, Module.InsertOptions)

    local mageMasqueGroup
    if LibStub("Masque", true) then
        mageMasqueGroup = LibStub("Masque", true):Group(Module.title, "Mage Bar", true)
    end

    local shamanMasqueGroup
    if LibStub("Masque", true) then
        shamanMasqueGroup = LibStub("Masque", true):Group(Module.title, "Shaman Bar", true)
    end

    local class = select(2, UnitClass("player"))
    if class == "MAGE" then
        Module.MageBar = Module:CreateMageBar(mageMasqueGroup)

        Module:RegisterEvent("PLAYER_ENTERING_WORLD", Module.Update)
        Module:SecureHook("MultiActionBar_Update", Module.Update)
        Module:SecureHook("MainMenuBar_UpdateExperienceBars", Module.Update)
    elseif class == "SHAMAN" then
        Module.ShamanBar = Module:CreateShamanBar(shamanMasqueGroup)

        Module:RegisterEvent("PLAYER_ENTERING_WORLD", Module.Update)
        Module:SecureHook("MultiActionBar_Update", Module.Update)
        Module:SecureHook("MainMenuBar_UpdateExperienceBars", Module.Update)
    end

    Module:Update()
end

function Module:Update()
    Module:UpdateClassBar(Module.MageBar)
    Module:UpdateClassBar(Module.ShamanBar)
end

E:RegisterModule(Module:GetName())