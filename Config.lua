local addonName, addonTable = ...
local Addon = addonTable[1]
local E, L, V, P, G = unpack(ElvUI)

if E.db[addonName] == nil then
    E.db[addonName] = {}
end
P[addonName] = {
    bars = {
        ["MageBar"] = {
            enabled = true,
            class = "MAGE",
            buttonSize = 32,
            buttonSpacing = 3,
            mouseover = true,
            inheritGlobalFade = false,
            backdrop = true,
            backdropSpacing = 3,
            buttons = {
                -- Teleports
                {defaultActionIndex = 1, showOnlyMaxRank = false, actions = Addon.database.Mage.Teleports},
                -- Portals
                {defaultActionIndex = 1, showOnlyMaxRank = false, actions = Addon.database.Mage.Portals},
                -- Conjure Food
                {
                    defaultActionIndex = #Addon.database.Mage.ConjureFood,
                    showOnlyMaxRank = false,
                    actions = Addon.database.Mage.ConjureFood
                },
                -- Conjure Water
                {
                    defaultActionIndex = #Addon.database.Mage.ConjureWater,
                    showOnlyMaxRank = false,
                    actions = Addon.database.Mage.ConjureWater
                },
                -- Conjure Gem
                {
                    defaultActionIndex = #Addon.database.Mage.ConjureGem,
                    showOnlyMaxRank = false,
                    actions = Addon.database.Mage.ConjureGem
                },
                -- Armors
                {
                    defaultActionIndex = 1,
                    showOnlyMaxRank = true,
                    actions = {
                        -- Frost Armor
                        168,
                        7300,
                        7301,
                        -- Ice Armor
                        7302,
                        7320,
                        10219,
                        10220,
                        27124,
                        -- Mage Armor
                        6117,
                        22782,
                        22783,
                        27125,
                        -- Molten Armor
                        30482
                    }
                }
            }
        },
        ["ShamanBar"] = {
            enabled = true,
            class = "SHAMAN",
            buttonSize = 32,
            buttonSpacing = 3,
            mouseover = true,
            inheritGlobalFade = false,
            backdrop = true,
            backdropSpacing = 3,
            buttons = {
                -- Fire Totems
                {
                    defaultActionIndex = 1,
                    showOnlyMaxRank = true,
                    actions = {
                        -- Fire Nova Totem
                        1535,
                        8498,
                        8499,
                        11314,
                        11315,
                        -- Magma Totem
                        8190,
                        10585,
                        10586,
                        10587,
                        -- Searing Totem
                        3599,
                        6363,
                        6364,
                        6365,
                        10437,
                        10438,
                        -- Flametongue Totem
                        8227,
                        8249,
                        10526,
                        16387,
                        -- Frost Resistance Totem
                        8181,
                        10478,
                        10479
                    }
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
        barOptions.args[buttonName] = {
            order = 50 + i,
            type = "group",
            name = buttonName,
            args = {
                header = {type = "header", order = 1, name = buttonName},
                showOnlyMaxRank = {
                    order = 11,
                    type = "toggle",
                    name = L["Show Only Max Rank"],
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
                    min = 1,
                    max = #button.actions,
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
