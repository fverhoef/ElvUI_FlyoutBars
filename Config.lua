local addonName, addonTable = ...
local Addon = addonTable[1]
local E, L, V, P, G = unpack(ElvUI)

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
                -- Teleports
                {
                    enabled = true,
                    defaultActionIndex = 1,
                    showOnlyMaxRank = false,
                    name = L["Teleports"],
                    actions = Addon.database.Mage.Teleports
                },
                -- Portals
                {
                    enabled = true,
                    defaultActionIndex = 1,
                    showOnlyMaxRank = false,
                    name = L["Portals"],
                    actions = Addon.database.Mage.Portals
                },
                -- Conjure Food
                {
                    enabled = true,
                    defaultActionIndex = #Addon.database.Mage.ConjureFood,
                    showOnlyMaxRank = false,
                    name = L["Conjure Food"],
                    actions = Addon.database.Mage.ConjureFood
                },
                -- Conjure Water
                {
                    enabled = true,
                    defaultActionIndex = #Addon.database.Mage.ConjureWater,
                    showOnlyMaxRank = false,
                    name = L["Conjure Water"],
                    actions = Addon.database.Mage.ConjureWater
                },
                -- Conjure Gem
                {
                    enabled = true,
                    defaultActionIndex = #Addon.database.Mage.ConjureGem,
                    showOnlyMaxRank = false,
                    name = L["Conjure Gems"],
                    actions = Addon.database.Mage.ConjureGem
                },
                -- Armors
                {
                    enabled = true,
                    defaultActionIndex = 1,
                    showOnlyMaxRank = true,
                    name = L["Armors"],
                    actions = Addon.database.Mage.Armors
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
                    defaultActionIndex = 1,
                    showOnlyMaxRank = true,
                    name = L["Fire Totems"],
                    actions = Addon.database.Shaman.FireTotems
                },
                {
                    enabled = true,
                    defaultActionIndex = 1,
                    showOnlyMaxRank = true,
                    name = L["Earth Totems"],
                    actions = Addon.database.Shaman.EarthTotems
                },
                {
                    enabled = true,
                    defaultActionIndex = 1,
                    showOnlyMaxRank = true,
                    name = L["Water Totems"],
                    actions = Addon.database.Shaman.WaterTotems
                },
                {
                    enabled = true,
                    defaultActionIndex = 1,
                    showOnlyMaxRank = true,
                    name = L["Air Totems"],
                    actions = Addon.database.Shaman.AirTotems
                },
                {
                    enabled = true,
                    defaultActionIndex = 1,
                    showOnlyMaxRank = true,
                    name = L["Weapon Enchants"],
                    actions = Addon.database.Shaman.WeaponEnchants
                }
            }
        }
    }
}

local CLASS_RESTRICTIONS = {[""] = L["None"]}

for key, value in pairs(_G.LOCALIZED_CLASS_NAMES_MALE) do
    CLASS_RESTRICTIONS[key] = value
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
            buttonsHeader = {type = "header", order = 50, name = "Buttons"}
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
                header = {type = "header", order = 1, name = buttonTitle},
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
                    end
                },
                defaultActionIndex = {
                    order = 12,
                    type = "range",
                    name = L["Default Action Index"],
                    desc = L["The default action to show when the button is collapsed."],
                    min = 1,
                    max = function()
                        return Addon:GetKnownActionCount(button.actions, button.showOnlyMaxRank)
                    end,
                    step = 1,
                    get = function(info)
                        return button.defaultActionIndex
                    end,
                    set = function(info, value)
                        button.defaultActionIndex = value
                        Addon:Update()
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
