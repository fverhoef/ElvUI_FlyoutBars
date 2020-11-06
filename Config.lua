local addonName, addonTable = ...
local Module = addonTable[1]
local E, L, V, P, G = unpack(ElvUI)

if E.db[addonName] == nil then
    E.db[addonName] = {}
end
P[addonName] = {
    mageBar = {enabled = true, buttonSize = 32, buttonSpacing = 3, mouseover = true, inheritGlobalFade = false, backdrop = true, backdropSpacing = 3},
    shamanBar = {enabled = true, buttonSize = 32, buttonSpacing = 3, mouseover = false, inheritGlobalFade = false, backdrop = true, backdropSpacing = 3}
}

function Module:InsertOptions()
    E.Options.args[addonName] = {
        order = 100,
        type = "group",
        name = Module.title,
        childGroups = "tab",
        args = {
            name = {order = 1, type = "header", name = Module.title},
            mageBar = {
                order = 1,
                type = "group",
                name = L["Mage Bar"],
                args = {
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = L["Enabled"],
                        get = function(info)
                            return E.db[addonName].mageBar.enabled
                        end,
                        set = function(info, value)
                            E.db[addonName].mageBar.enabled = value
                            Module:UpdateClassBar(Module.MageBar)
                        end
                    },
                    buttonSize = {
                        order = 2,
                        type = "range",
                        name = L["Button Size"],
                        desc = L["The size of the action buttons."],
                        min = 15,
                        max = 60,
                        step = 1,
                        get = function(info)
                            return E.db[addonName].mageBar.buttonSize
                        end,
                        set = function(info, value)
                            E.db[addonName].mageBar.buttonSize = value
                            Module:UpdateClassBar(Module.MageBar)
                        end
                    },
                    buttonSpacing = {
                        order = 3,
                        type = "range",
                        name = L["Button Spacing"],
                        desc = L["The spacing between buttons."],
                        min = -3,
                        max = 20,
                        step = 1,
                        get = function(info)
                            return E.db[addonName].mageBar.buttonSpacing
                        end,
                        set = function(info, value)
                            E.db[addonName].mageBar.buttonSpacing = value
                            Module:UpdateClassBar(Module.MageBar)
                        end
                    },
                    backdrop = {
                        order = 4,
                        type = "toggle",
                        name = L["Backdrop"],
                        get = function(info)
                            return E.db[addonName].mageBar.backdrop
                        end,
                        set = function(info, value)
                            E.db[addonName].mageBar.backdrop = value
                            Module:UpdateClassBar(Module.MageBar)
                        end
                    },
                    backdropSpacing = {
                        order = 5,
                        type = "range",
                        name = L["Backdrop Spacing"],
                        desc = L["The spacing between the backdrop and the buttons."],
                        min = 0,
                        max = 10,
                        step = 1,
                        get = function(info)
                            return E.db[addonName].mageBar.backdropSpacing
                        end,
                        set = function(info, value)
                            E.db[addonName].mageBar.backdropSpacing = value
                            Module:UpdateClassBar(Module.MageBar)
                        end
                    },
                    inheritGlobalFade = {
                        order = 6,
                        type = "toggle",
                        name = L["Inherit Global Fade"],
                        get = function(info)
                            return E.db[addonName].mageBar.inheritGlobalFade
                        end,
                        set = function(info, value)
                            E.db[addonName].mageBar.inheritGlobalFade = value
                            Module:UpdateClassBar(Module.MageBar)
                        end
                    }
                }
            },
            shamanBar = {
                order = 2,
                type = "group",
                name = L["Shaman Bar"],
                args = {
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = L["Enabled"],
                        get = function(info)
                            return E.db[addonName].shamanBar.enabled
                        end,
                        set = function(info, value)
                            E.db[addonName].shamanBar.enabled = value
                            Module:UpdateClassBar(Module.ShamanBar)
                        end
                    },
                    buttonSize = {
                        order = 2,
                        type = "range",
                        name = L["Button Size"],
                        desc = L["The size of the action buttons."],
                        min = 15,
                        max = 60,
                        step = 1,
                        get = function(info)
                            return E.db[addonName].shamanBar.buttonSize
                        end,
                        set = function(info, value)
                            E.db[addonName].shamanBar.buttonSize = value
                            Module:UpdateClassBar(Module.ShamanBar)
                        end
                    },
                    buttonSpacing = {
                        order = 3,
                        type = "range",
                        name = L["Button Spacing"],
                        desc = L["The spacing between buttons."],
                        min = -3,
                        max = 20,
                        step = 1,
                        get = function(info)
                            return E.db[addonName].shamanBar.buttonSpacing
                        end,
                        set = function(info, value)
                            E.db[addonName].shamanBar.buttonSpacing = value
                            Module:UpdateClassBar(Module.ShamanBar)
                        end
                    },
                    backdrop = {
                        order = 4,
                        type = "toggle",
                        name = L["Backdrop"],
                        get = function(info)
                            return E.db[addonName].shamanBar.backdrop
                        end,
                        set = function(info, value)
                            E.db[addonName].shamanBar.backdrop = value
                            Module:UpdateClassBar(Module.ShamanBar)
                        end
                    },
                    backdropSpacing = {
                        order = 5,
                        type = "range",
                        name = L["Backdrop Spacing"],
                        desc = L["The spacing between the backdrop and the buttons."],
                        min = 0,
                        max = 10,
                        step = 1,
                        get = function(info)
                            return E.db[addonName].shamanBar.backdropSpacing
                        end,
                        set = function(info, value)
                            E.db[addonName].shamanBar.backdropSpacing = value
                            Module:UpdateClassBar(Module.ShamanBar)
                        end
                    },
                    inheritGlobalFade = {
                        order = 6,
                        type = "toggle",
                        name = L["Inherit Global Fade"],
                        get = function(info)
                            return E.db[addonName].shamanBar.inheritGlobalFade
                        end,
                        set = function(info, value)
                            E.db[addonName].shamanBar.inheritGlobalFade = value
                            Module:UpdateClassBar(Module.ShamanBar)
                        end
                    }
                }
            }
        }
    }
end
