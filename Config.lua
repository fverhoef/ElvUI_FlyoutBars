local addonName, addonTable = ...
local Addon = addonTable[1]
local E, L, V, P, G = unpack(ElvUI)
local LSC = LibStub("LibSpellCache-1.0")

local UPDATE_DEFAULT_MODE = {
    [""] = "Never",
    ANY_CLICK = "Any Click",
    LEFT_CLICK = "Left Click",
    RIGHT_CLICK = "Right Click",
    MIDDLE_CLICK = "Middle Click"
}
Addon.UPDATE_DEFAULT_MODE = UPDATE_DEFAULT_MODE

if E.db[addonName] == nil then
    E.db[addonName] = {}
end
P[addonName] = {
    bars = {
        ["Mage Bar"] = {
            enabled = true,
            class = "MAGE",
            buttonSize = 32,
            buttonSpacing = 2,
            mouseover = true,
            inheritGlobalFade = false,
            backdrop = false,
            backdropSpacing = 2,
            direction = "UP",
            buttons = {
                {
                    enabled = true,
                    showOnlyMaxRank = false,
                    name = L["Teleports"],
                    actions = Addon.database.Mage.Teleports,
                    defaultActionUpdateMode = UPDATE_DEFAULT_MODE.ANY_CLICK
                },
                {
                    enabled = true,
                    showOnlyMaxRank = false,
                    name = L["Portals"],
                    actions = Addon.database.Mage.Portals,
                    defaultActionUpdateMode = UPDATE_DEFAULT_MODE.ANY_CLICK
                },
                {
                    enabled = true,
                    showOnlyMaxRank = false,
                    name = L["Conjure Food"],
                    actions = Addon.database.Mage.ConjureFood,
                    defaultActionUpdateMode = UPDATE_DEFAULT_MODE.ANY_CLICK
                },
                {
                    enabled = true,
                    showOnlyMaxRank = false,
                    name = L["Conjure Water"],
                    actions = Addon.database.Mage.ConjureWater,
                    defaultActionUpdateMode = UPDATE_DEFAULT_MODE.ANY_CLICK
                },
                {
                    enabled = true,
                    showOnlyMaxRank = false,
                    name = L["Conjure Gems"],
                    actions = Addon.database.Mage.ConjureGem,
                    defaultActionUpdateMode = UPDATE_DEFAULT_MODE.ANY_CLICK
                },
                {
                    enabled = true,
                    showOnlyMaxRank = true,
                    name = L["Armors"],
                    actions = Addon.database.Mage.Armors,
                    defaultActionUpdateMode = UPDATE_DEFAULT_MODE.ANY_CLICK
                }
            }
        },
        ["Shaman Bar"] = {
            enabled = true,
            class = "SHAMAN",
            buttonSize = 32,
            buttonSpacing = 2,
            mouseover = true,
            inheritGlobalFade = false,
            backdrop = false,
            backdropSpacing = 2,
            direction = "UP",
            buttons = {
                {
                    enabled = true,
                    showOnlyMaxRank = true,
                    name = L["Fire Totems"],
                    actions = Addon.database.Shaman.FireTotems,
                    defaultActionUpdateMode = UPDATE_DEFAULT_MODE.ANY_CLICK
                },
                {
                    enabled = true,
                    showOnlyMaxRank = true,
                    name = L["Earth Totems"],
                    actions = Addon.database.Shaman.EarthTotems,
                    defaultActionUpdateMode = UPDATE_DEFAULT_MODE.ANY_CLICK
                },
                {
                    enabled = true,
                    showOnlyMaxRank = true,
                    name = L["Water Totems"],
                    actions = Addon.database.Shaman.WaterTotems,
                    defaultActionUpdateMode = UPDATE_DEFAULT_MODE.ANY_CLICK
                },
                {
                    enabled = true,
                    showOnlyMaxRank = true,
                    name = L["Air Totems"],
                    actions = Addon.database.Shaman.AirTotems,
                    defaultActionUpdateMode = UPDATE_DEFAULT_MODE.ANY_CLICK
                },
                {
                    enabled = true,
                    showOnlyMaxRank = true,
                    name = L["Weapon Enchants"],
                    actions = Addon.database.Shaman.WeaponEnchants,
                    defaultActionUpdateMode = UPDATE_DEFAULT_MODE.ANY_CLICK
                }
            }
        }
    }
}

local CLASS_RESTRICTIONS = {[""] = L["None"]}

for key, value in pairs(_G.LOCALIZED_CLASS_NAMES_MALE) do
    CLASS_RESTRICTIONS[key] = value
end

local selectedSpells = {}
local addSpellFilter
local function BarIsForCurrentClass(config)
    return config.class ~= nil and config.class ~= "" and config.class ~= E.myclass
end
local function GetActionName(action)
    local name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(action)
    local subText = GetSpellSubtext(spellId or action)
    if subText and subText ~= "" then
        name = name .. " (" .. subText .. ")"
    end
    return icon and string.format("|T%s:20:20:0:0:64:64:5:59:5:59:%d|t %s", icon, 40, name) or name
end
local function GetKnownActions(button)
    local actions = {}
    for _, action in ipairs(button.actions) do
        if IsSpellKnown(action) and (not button.showOnlyMaxRank or Addon:IsMaxKnownRank(action)) then
            table.insert(actions, GetActionName(action))
        end
    end
    return actions
end
local function GetDefaultActionIndex(button)
    local currentIndex = 1
    for _, action in ipairs(button.actions) do
        if IsSpellKnown(action) and (not button.showOnlyMaxRank or Addon:IsMaxKnownRank(action)) then
            if action == button.defaultAction then
                return currentIndex
            else
                currentIndex = currentIndex + 1
            end
        end
    end
end
local function GetKnownAction(button, index)
    local currentIndex = 1
    for _, action in ipairs(button.actions) do
        if IsSpellKnown(action) and (not button.showOnlyMaxRank or Addon:IsMaxKnownRank(action)) then
            if currentIndex == index then
                return action
            else
                currentIndex = currentIndex + 1
            end
        end
    end
end

local function CreateBarOptions(config, name, order)
    local barOptions = {
        order = index,
        type = "group",
        name = name,
        args = {
            enabled = {
                order = 1,
                type = "toggle",
                name = L["Enabled"],
                desc = L["Whether or not this bar is enabled."],
                get = function(info)
                    return config.enabled
                end,
                set = function(info, value)
                    config.enabled = value
                    Addon:Update()
                end
            },
            header = {type = "header", order = 2, name = ""},
            class = {
                order = 10,
                type = "select",
                name = L["Class Restriction"],
                desc = L["This bar will only show for the selected class. Set to 'None' if it should always be shown."],
                values = CLASS_RESTRICTIONS,
                get = function()
                    for key, val in pairs(CLASS_RESTRICTIONS) do
                        if (config.class or "") == key then
                            return key
                        end
                    end
                end,
                set = function(_, key)
                    if key == "" then
                        key = nil
                    end
                    config.class = key
                    Addon:Update()
                end
            },
            sizeSpacer = {type = "description", order = 20, name = ""},
            buttonSize = {
                order = 21,
                type = "range",
                name = L["Button Size"],
                desc = L["The size of the action buttons."],
                min = 15,
                max = 60,
                step = 1,
                get = function(info)
                    return config.buttonSize
                end,
                set = function(info, value)
                    config.buttonSize = value
                    Addon:Update()
                end
            },
            buttonSpacing = {
                order = 22,
                type = "range",
                name = L["Button Spacing"],
                desc = L["The spacing between buttons."],
                min = -3,
                max = 20,
                step = 1,
                get = function(info)
                    return config.buttonSpacing
                end,
                set = function(info, value)
                    config.buttonSpacing = value
                    Addon:Update()
                end
            },
            backdropSpacer = {type = "description", order = 30, name = ""},
            backdrop = {
                order = 31,
                type = "toggle",
                name = L["Backdrop"],
                desc = L["Whether or not this bar's backdrop is enabled."],
                get = function(info)
                    return config.backdrop
                end,
                set = function(info, value)
                    config.backdrop = value
                    Addon:Update()
                end
            },
            backdropSpacing = {
                order = 32,
                type = "range",
                name = L["Backdrop Spacing"],
                desc = L["The spacing between the backdrop and the buttons."],
                min = 0,
                max = 10,
                step = 1,
                get = function(info)
                    return config.backdropSpacing
                end,
                set = function(info, value)
                    config.backdropSpacing = value
                    Addon:Update()
                end
            },
            fadeSpacer = {type = "description", order = 40, name = ""},
            inheritGlobalFade = {
                order = 41,
                type = "toggle",
                name = L["Inherit Global Fade"],
                desc = L["Whether this bar should inherit the global ElvUI fade state."],
                get = function(info)
                    return config.inheritGlobalFade
                end,
                set = function(info, value)
                    config.inheritGlobalFade = value
                    Addon:Update()
                end
            },
            buttonsHeader = {type = "header", order = 50, name = L["Buttons"]}
        }
    }

    for i, button in ipairs(config.buttons) do
        local buttonName = L["Button"] .. " " .. i
        local buttonTitle = buttonName .. ((button.name and (" (" .. button.name .. ")")) or "")
        barOptions.args[buttonName] = {
            order = 50 + i,
            type = "group",
            name = buttonTitle,
            args = {
                header = {type = "header", order = 0, name = buttonTitle},
                disabledDescription = {
                    type = "description",
                    order = 1,
                    name = L["|cffFF0000Warning:|r You can only edit the buttons of bars for your own class, or of bars with no class restriction."],
                    hidden = function()
                        return not BarIsForCurrentClass(config)
                    end
                },
                enabled = {
                    order = 2,
                    type = "toggle",
                    name = L["Enabled"],
                    desc = L["Whether or not this button is enabled."],
                    get = function(info)
                        return button.enabled
                    end,
                    set = function(info, value)
                        button.enabled = value
                        Addon:Update()
                    end,
                    disabled = function()
                        return BarIsForCurrentClass(config)
                    end
                },
                name = {
                    order = 10,
                    type = "input",
                    name = L["Name"],
                    desc = L["The name of the button."],
                    width = "full",
                    get = function(info)
                        return button.name
                    end,
                    set = function(info, value)
                        button.name = value
                        Addon:Update()
                    end,
                    disabled = function()
                        return BarIsForCurrentClass(config)
                    end
                },
                showOnlyMaxRank = {
                    order = 11,
                    type = "toggle",
                    name = L["Show Only Max Rank"],
                    desc = L["Whether this button will only show the max rank of each spell."],
                    width = "full",
                    get = function(info)
                        return button.showOnlyMaxRank
                    end,
                    set = function(info, value)
                        button.showOnlyMaxRank = value
                        Addon:Update()
                    end,
                    disabled = function()
                        return BarIsForCurrentClass(config)
                    end
                },
                actions = {
                    order = 20,
                    type = "multiselect",
                    width = 1.75,
                    name = L["Actions"],
                    tristate = false,
                    values = function()
                        local actions = {}
                        for i, action in ipairs(button.actions) do
                            actions[i] = GetActionName(action)
                        end
                        return actions
                    end,
                    get = function(info, key)
                        for i, action in ipairs(button.actions) do
                            if i == key then
                                return selectedSpells[action]
                            end
                        end
                    end,
                    set = function(info, key)
                        for i, action in ipairs(button.actions) do
                            if i == key then
                                selectedSpells[action] = not selectedSpells[action]
                            end
                        end
                    end,
                    disabled = function()
                        return BarIsForCurrentClass(config)
                    end
                },
                removeAction = {
                    order = 21,
                    type = "execute",
                    name = L["Remove Selected Spell(s)"],
                    func = function()
                        for selectedSpell, _ in pairs(selectedSpells) do
                            for i, action in ipairs(button.actions) do
                                if selectedSpell == action then
                                    table.remove(button.actions, i)
                                    break
                                end
                            end
                        end
                        selectedSpells = {}

                        Addon:Update()
                    end,
                    disabled = function()
                        return BarIsForCurrentClass(config)
                    end
                },
                addSpellBreak = {order = 22, type = "description", name = ""},
                findSpellName = {
                    order = 23,
                    type = "input",
                    name = L["Filter"],
                    desc = L["Name or ID of the spell to add."],
                    get = function(info)
                        LSC:BuildKnownSpellCache()
                        return addSpellFilter
                    end,
                    set = function(info, value)
                        addSpellFilter = LSC:MatchSpellName(value, true)
                        spellToAdd = nil
                    end,
                    disabled = function()
                        return BarIsForCurrentClass(config)
                    end
                },
                findSpellResults = {
                    order = 24,
                    type = "select",
                    name = L["Select Spell"],
                    values = function()
                        local spells = {}
                        if addSpellFilter then
                            local ids = LSC:GetKnownSpells(addSpellFilter)
                            for _, id in ipairs(ids) do
                                if IsSpellKnown(id) then
                                    spells[id] = GetActionName(id)
                                end
                            end
                        end
                        return spells
                    end,
                    get = function(info, key)
                        return spellToAdd
                    end,
                    set = function(info, key)
                        spellToAdd = key
                    end,
                    disabled = function()
                        return BarIsForCurrentClass(config)
                    end
                },
                addSpell = {
                    order = 25,
                    type = "execute",
                    name = L["Add Selected Spell"],
                    disabled = function()
                        return not spellToAdd
                    end,
                    func = function()
                        if not spellToAdd then
                            return
                        end

                        for i, action in ipairs(button.actions) do
                            if action == spellToAdd then
                                return
                            end
                        end

                        table.insert(button.actions, spellToAdd)

                        Addon:Update()
                    end,
                    disabled = function()
                        return BarIsForCurrentClass(config)
                    end
                },
                defaultAction = {
                    order = 26,
                    type = "select",
                    name = L["Default Action"],
                    desc = L["The default action to show when the button is collapsed."],
                    values = function()
                        return GetKnownActions(button)
                    end,
                    get = function(info)
                        return GetDefaultActionIndex(button)
                    end,
                    set = function(info, index)
                        button.defaultAction = GetKnownAction(button, index)
                        Addon:Update()
                    end,
                    disabled = function()
                        return BarIsForCurrentClass(config)
                    end
                },
                defaultActionUpdateMode = {
                    order = 27,
                    type = "select",
                    name = L["Default Action Update Mode"],
                    desc = L["When and how to update the default action for this button."],
                    values = UPDATE_DEFAULT_MODE,
                    get = function()
                        for key, value in pairs(UPDATE_DEFAULT_MODE) do
                            if value == (button.defaultActionUpdateMode or "") then
                                return key
                            end
                        end
                    end,
                    set = function(_, key)
                        local value = UPDATE_DEFAULT_MODE[key]
                        if value == "" then
                            value = nil
                        end
                        button.defaultActionUpdateMode = value
                        Addon:Update()
                    end,
                    disabled = function()
                        return BarIsForCurrentClass(config)
                    end
                },
                defaultActionMaxRankDescription = {
                    type = "description",
                    order = 28,
                    name = L["|cffFF0000Warning:|r The 'Show Only Max Rank' option is currently enabled; you can only set the default action to the max rank of each spell."],
                    hidden = function()
                        return not button.showOnlyMaxRank
                    end
                }
            }
        }
    end

    return barOptions
end

function Addon:InsertOptions()
    local options = {
        order = 100,
        type = "group",
        name = Addon.title,
        childGroups = "tab",
        args = {name = {order = 1, type = "header", name = Addon.title}}
    }

    for name, config in pairs(E.db[addonName].bars) do
        options.args[name] = CreateBarOptions(config, name, #options.args + 1)
    end

    E.Options.args[addonName] = options
end
