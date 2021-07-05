local addonName, addonTable = ...
local Addon = addonTable[1]
local E, L, V, P, G = unpack(ElvUI)
local AB = E:GetModule("ActionBars")
local LAB = E.Libs.LAB

local SPELLFLYOUT_DEFAULT_SPACING = 0
local SPELLFLYOUT_INITIAL_SPACING = 0
local SPELLFLYOUT_FINAL_SPACING = 4

local function FixNormalTextureSize(button)
    local normalTexture = button:GetNormalTexture()
    if normalTexture then
        local texturePath = normalTexture:GetTexture()
        if texturePath == "Interface\\Buttons\\UI-Quickslot2" then
            local size = 66 * (button:GetWidth() / 36)
            normalTexture:SetSize(size, size)
        end
    end
end

local function CreateMover(frame, name)
    E:CreateMover(frame, name, name, nil, nil, nil, "ALL,ACTIONBARS", nil, "actionbars")

    if frame.db.inheritGlobalFade then
        frame:SetParent(AB.fadeParent)
    end
    frame:SetScript("OnEnter", function()
        AB:Bar_OnEnter(frame)
    end)
    frame:SetScript("OnLeave", function()
        AB:Bar_OnLeave(frame)
    end)
end

function Addon:CreateFlyoutBar(name, config)
    local bar = CreateFrame("Frame", addonName .. "_" .. name, E.UIParent or _G.UIParent)
    bar:SetPoint("CENTER", E.UIParent or _G.UIParent, "CENTER", 0, 0)
    bar:CreateBackdrop("Transparent")
    bar.db = config
    bar.buttons = {}
    bar.name = name
    for i, button in ipairs(config.buttons) do
        bar.buttons[i] = Addon:CreateFlyoutButton(button.name, bar, button)
    end

    bar:RegisterEvent("LEARNED_SPELL_IN_TAB")
    bar:RegisterEvent("PLAYER_TOTEM_UPDATE")
    bar:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    bar:HookScript("OnEvent", function(self, event)
        if event == "PLAYER_TOTEM_UPDATE" then
            for index = 1, _G.MAX_TOTEMS do
                local button = frame.buttons[index]

                local haveTotem, totemName, start, duration, icon = GetTotemInfo(index)
                if (haveTotem and duration > 0) then
                    -- TODO: show totem duration in a status bar instead?
                    -- button.CurrentAction.Duration:SetCooldown(start, duration)
                    local totemId = Addon:FindTotem(totemName)
                    if totemId then
                        local actionButton = button.childButtons[totemId]
                        if actionButton then
                            -- button.defaultAction = totemId
                        end
                    end
                end
            end
        elseif event == "ACTIONBAR_UPDATE_USABLE" then
            for i, button in ipairs(bar.buttons) do
                button.CurrentAction:UpdateConfig()
                for j, child in next, button.childButtons do
                    child:UpdateConfig()
                end
            end
        elseif event == "LEARNED_SPELL_IN_TAB" then
            Addon:UpdateFlyoutBar(bar)
        end
    end)

    CreateMover(bar, addonName .. "_" .. name)
    Addon:UpdateFlyoutBar(bar)

    return bar
end

function Addon:UpdateFlyoutBar(bar)
    if not bar then
        return
    end

    local class = select(2, UnitClass("player"))
    if not bar.db.enabled or (bar.db.class ~= class and (bar.db.class or "") ~= "") then
        bar:Hide()
        return
    else
        bar:Show()
    end

    -- remove deleted buttons
    for i, button in ipairs(bar.buttons) do
        local found = false
        for _, buttonConfig in ipairs(bar.db.buttons) do
            if button.config == buttonConfig then
                found = true
                break
            end
        end

        if not found then
            button:Hide()
            table.remove(bar.buttons, i)
        end
    end

    -- create newly added buttons
    for i, buttonConfig in ipairs(bar.db.buttons) do
        local found = false
        for _, button in ipairs(bar.buttons) do
            if button.config == buttonConfig then
                found = true
                break
            end
        end

        if not found then
            table.insert(bar.buttons, i, Addon:CreateFlyoutButton(buttonConfig.name, bar, buttonConfig))
        end
    end

    -- update buttons
    local spacing = bar.db.backdrop and bar.db.backdropSpacing
    local visibleButtonCount = 0
    local lastVisibleButton
    local buttonList = {}
    for i, button in ipairs(bar.buttons) do
        Addon:UpdateFlyoutButton(button)

        if button:IsVisible() then
            visibleButtonCount = visibleButtonCount + 1

            button:ClearAllPoints()
            if visibleButtonCount == 1 then
                button:SetPoint("BOTTOMLEFT", spacing or 0, spacing or 0)
            else
                button:SetPoint("BOTTOMLEFT", lastVisibleButton, "BOTTOMRIGHT", bar.db.buttonSpacing, 0)
            end

            lastVisibleButton = button
        end
    end

    local width = (visibleButtonCount) * bar.db.buttonSize + (visibleButtonCount - 1) * bar.db.buttonSpacing
    local height = bar.db.buttonSize

    if bar.db.backdrop then
        bar.backdrop:Show()

        width = width + 2 * spacing
        height = height + 2 * spacing
    else
        bar.backdrop:Hide()
    end

    bar:SetSize(width, height)
end

function Addon:CreateFlyoutButton(name, bar, config)
    -- create parent frame
    local button = CreateFrame("Frame", "FlyoutButton_" .. name, bar, "SecureHandlerStateTemplate")
    button.bar = bar
    button.config = config
    button.size = button.bar.db.buttonSize
    button.childSize = button.bar.db.buttonSize - 8
    button.childButtons = {}
    button:EnableMouse(true)
    button:SetSize(button.size, button.size)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(1)

    -- Create secure open/close functions (needed for combat execution)
    button:Execute([[open = [=[        
            self:SetAttribute("open", 1)
            local childButtons = newtable(self:GetChildren())
            for i, button in ipairs(childButtons) do
                local index = button:GetAttribute("index")
                local hidden = button:GetAttribute("hidden")
                if hidden == 1 then
                    button:Hide()
                else
                    button:Show()
                end
            end
        ]=] ]])
    button:Execute([[close = [=[
            self:SetAttribute("open", 0)
            local childButtons = newtable(self:GetChildren())
            for i, button in pairs(childButtons) do
                local index = button:GetAttribute("index")
                if index ~= 0 then
                    button:Hide()
                end			
            end
        ]=] ]])

    -- Create a button for the current/default action
    button.CurrentAction = LAB:CreateButton(button:GetName() .. 0, button:GetName() .. "_CurrentAction", button)
    button.CurrentAction:SetPoint("BOTTOM", button, "BOTTOM", 0, 0)
    button.CurrentAction:SetSize(button.size, button.size)
    button.CurrentAction:SetFrameLevel(10)
    button.CurrentAction:SetAttribute("index", 0)
    button.CurrentAction:Show()

    if Addon.masqueGroup then
        Addon.masqueGroup:AddButton(button.CurrentAction)
    else
        AB:StyleButton(button.CurrentAction)
    end

    SecureHandlerWrapScript(button.CurrentAction, "OnEnter", button, [[
            control:Run(open)
        ]])
    SecureHandlerWrapScript(button.CurrentAction, "OnLeave", button, [[return true, ""]], [[
            inHeader =  control:IsUnderMouse(true)
            if not inHeader then
                control:Run(close)
            end	    
        ]])

    button.CurrentAction:HookScript("OnEnter", function()
        Addon:UpdateFlyoutButtonBackground(button)
        AB:Bar_OnEnter(bar)
    end)
    button.CurrentAction:HookScript("OnLeave", function()
        Addon:UpdateFlyoutButtonBackground(button)
        AB:Bar_OnLeave(bar)
    end)
    button.CurrentAction:HookScript("OnClick", function()
        button.CurrentAction:SetChecked(false)
    end)

    Addon:CreateFlyoutButtonBackground(button)
    Addon:UpdateFlyoutButton(button)

    return button
end

function Addon:UpdateFlyoutButton(button)
    button.isOpen = button:GetAttribute("open") == 1

    if not InCombatLockdown() then
        button.count = 0

        -- generate/position child buttons
        local previousButton
        for i, action in ipairs(button.config.actions) do
            local child = button.childButtons[action]
            if not child then
                child = Addon:CreateFlyoutButtonChild(button, action, i)
                button.childButtons[action] = child
            end

            local visible = (not button.config.showOnlyMaxRank and IsSpellKnown(action)) or
                                (button.config.showOnlyMaxRank and Addon:IsMaxKnownRank(action))
            child:SetAttribute("hidden", (not visible and 1) or 0)
            child:SetShown(visible and button.isOpen)

            if visible and IsSpellKnown(action) then
                child:SetState(0, "spell", action)
                button.count = button.count + 1
                Addon:PositionFlyoutButtonChild(button, child, previousButton)
                previousButton = child
            end
        end

        for i, child in next, button.childButtons do
            -- check if child is still in use
            local spellID = child:GetAttribute("spell")
            local found = false
            for j, action in ipairs(button.config.actions) do
                if action == spellID then
                    found = true
                    break
                end
            end

            -- hide buttons that are not in use any more; else, update it
            if not found then
                child:SetAttribute("hidden", 1)
                child:Hide()
            end
        end

        Addon:SetFlyoutCurrentAction(button, button.config.defaultAction)
    end

    button.size = button.bar.db.buttonSize
    button.childSize = button.bar.db.buttonSize - 8
    button:SetSize(button.bar.db.buttonSize, button.bar.db.buttonSize)
    button.CurrentAction:SetSize(button.bar.db.buttonSize, button.bar.db.buttonSize)
    Addon:UpdateFlyoutButtonBackground(button)

    if button.count > 0 and button.config.enabled then
        button:Show()
    else
        button:Hide()
    end
end

function Addon:CreateFlyoutButtonBackground(button)
    button.FlyoutArrowHolder = CreateFrame("Frame", nil, button.CurrentAction)
    button.FlyoutArrowHolder:SetPoint("CENTER", button.CurrentAction, "CENTER")
    button.FlyoutArrowHolder:SetFrameLevel(button.CurrentAction:GetFrameLevel() + 20)
    button.FlyoutArrow = button.FlyoutArrowHolder:CreateTexture(nil, "OVERLAY", "ActionBarFlyoutButton-ArrowUp")
    button.FlyoutArrow:SetPoint("CENTER", button.FlyoutArrowHolder, "CENTER")

    button.FlyoutBackground = CreateFrame("Frame", button:GetName() .. "_Background", button)
    button.FlyoutBackground:EnableMouse(true)

    button.FlyoutBackground.End = button.FlyoutBackground:CreateTexture(nil, "BACKGROUND")
    button.FlyoutBackground.End:SetTexture([[Interface\Buttons\ActionBarFlyoutButton]])
    button.FlyoutBackground.End:SetTexCoord(0.01562500, 0.59375000, 0.74218750, 0.91406250)
    button.FlyoutBackground.End:SetVertexColor(0.5, 0.5, 0.5, 1)
    button.FlyoutBackground.End:SetSize(button.size, 22)
    button.FlyoutBackground.End:Hide()

    button.FlyoutBackground.Vertical = button.FlyoutBackground:CreateTexture(nil, "BACKGROUND")
    button.FlyoutBackground.Vertical:SetTexture([[Interface\Buttons\ActionBarFlyoutButton-FlyoutMid]])
    button.FlyoutBackground.Vertical:SetTexCoord(0, 0.578125, 0, 1)
    button.FlyoutBackground.Vertical:SetVertexColor(0.5, 0.5, 0.5, 1)
    button.FlyoutBackground.Vertical:SetSize(button.size, button.size)
    button.FlyoutBackground.Vertical:Hide()

    button.FlyoutBackground.Horizontal = button.FlyoutBackground:CreateTexture(nil, "BACKGROUND")
    button.FlyoutBackground.Horizontal:SetTexture([[Interface\Buttons\ActionBarFlyoutButton-FlyoutMidLeft]])
    button.FlyoutBackground.Horizontal:SetTexCoord(0, 1, 0, 0.578125)
    button.FlyoutBackground.Horizontal:SetVertexColor(0.5, 0.5, 0.5, 1)
    button.FlyoutBackground.Horizontal:SetSize(button.size, button.size)
    button.FlyoutBackground.Horizontal:Hide()
end

function Addon:UpdateFlyoutButtonBackground(button)
    button.isOpen = button:GetAttribute("open") == 1

    local arrowDistance = button.isOpen and 5 or 2
    button.FlyoutArrow:Show()
    button.FlyoutArrow:ClearAllPoints()
    if button.bar.db.direction == "LEFT" then
        button.FlyoutArrow:SetPoint("LEFT", button.CurrentAction, "LEFT", -arrowDistance, 0)
        SetClampedTextureRotation(button.FlyoutArrow, 270)
    elseif button.bar.db.direction == "RIGHT" then
        button.FlyoutArrow:SetPoint("RIGHT", button.CurrentAction, "RIGHT", arrowDistance, 0)
        SetClampedTextureRotation(button.FlyoutArrow, 90)
    elseif button.bar.db.direction == "DOWN" then
        button.FlyoutArrow:SetPoint("BOTTOM", button.CurrentAction, "BOTTOM", 0, -arrowDistance)
        SetClampedTextureRotation(button.FlyoutArrow, 180)
    else
        button.FlyoutArrow:SetPoint("TOP", button.CurrentAction, "TOP", 0, arrowDistance)
        SetClampedTextureRotation(button.FlyoutArrow, 0)
    end

    if button.isOpen then
        button.FlyoutBackground:Show()
    else
        button.FlyoutBackground:Hide()
    end

    button.FlyoutBackground:EnableMouse(button.isOpen)
    button.FlyoutBackground.End:SetSize(button.size, 22)
    button.FlyoutBackground.Vertical:SetSize(button.size, button.size)
    button.FlyoutBackground.Horizontal:SetSize(button.size, button.size)

    if button.bar.db.direction == "UP" then
        button.FlyoutBackground:SetPoint("BOTTOM", button, "TOP")
        button.FlyoutBackground.End:Show()
        button.FlyoutBackground.End:SetPoint("TOP", button.FlyoutBackground, "TOP", 0, 0)
        SetClampedTextureRotation(button.FlyoutBackground.End, 0)
        button.FlyoutBackground.Horizontal:Hide()
        button.FlyoutBackground.Vertical:Show()
        button.FlyoutBackground.Vertical:ClearAllPoints()
        button.FlyoutBackground.Vertical:SetPoint("TOP", button.FlyoutBackground.End, "BOTTOM")
        button.FlyoutBackground.Vertical:SetPoint("BOTTOM", 0, -4)
    elseif button.bar.db.direction == "DOWN" then
        button.FlyoutBackground:SetPoint("TOP", button, "BOTTOM")
        button.FlyoutBackground.End:Show()
        button.FlyoutBackground.End:SetPoint("BOTTOM", button.FlyoutBackground, "BOTTOM", 0, 0)
        SetClampedTextureRotation(button.FlyoutBackground.End, 180)
        button.FlyoutBackground.Horizontal:Hide()
        button.FlyoutBackground.Vertical:Show()
        button.FlyoutBackground.Vertical:ClearAllPoints()
        button.FlyoutBackground.Vertical:SetPoint("BOTTOM", button.FlyoutBackground.End, "TOP")
        button.FlyoutBackground.Vertical:SetPoint("TOP", 0, 4)
    elseif button.bar.db.direction == "LEFT" then
        button.FlyoutBackground:SetPoint("RIGHT", button, "LEFT")
        button.FlyoutBackground.End:Show()
        button.FlyoutBackground.End:SetPoint("LEFT", button.FlyoutBackground, "LEFT", 0, 0)
        SetClampedTextureRotation(button.FlyoutBackground.End, 270)
        button.FlyoutBackground.Vertical:Hide()
        button.FlyoutBackground.Horizontal:Show()
        button.FlyoutBackground.Horizontal:ClearAllPoints()
        button.FlyoutBackground.Horizontal:SetPoint("LEFT", button.FlyoutBackground.End, "RIGHT")
        button.FlyoutBackground.Horizontal:SetPoint("RIGHT", 4, 0)
    elseif button.bar.db.direction == "RIGHT" then
        button.FlyoutBackground:SetPoint("LEFT", button, "RIGHT")
        button.FlyoutBackground.End:Show()
        button.FlyoutBackground.End:SetPoint("RIGHT", button.FlyoutBackground, "RIGHT", 0, 0)
        SetClampedTextureRotation(button.FlyoutBackground.End, 90)
        button.FlyoutBackground.Vertical:Hide()
        button.FlyoutBackground.Horizontal:Show()
        button.FlyoutBackground.Horizontal:ClearAllPoints()
        button.FlyoutBackground.Horizontal:SetPoint("RIGHT", button.FlyoutBackground.End, "LEFT")
        button.FlyoutBackground.Horizontal:SetPoint("LEFT", -4, 0)
    end

    if (button.bar.db.direction == "UP" or button.bar.db.direction == "DOWN") then
        button.FlyoutBackground:SetHeight((button.childSize + SPELLFLYOUT_DEFAULT_SPACING) * button.count -
                                              SPELLFLYOUT_DEFAULT_SPACING + SPELLFLYOUT_INITIAL_SPACING +
                                              SPELLFLYOUT_FINAL_SPACING)
        button.FlyoutBackground:SetWidth(button.size - 3)
    else
        button.FlyoutBackground:SetHeight(button.size - 3)
        button.FlyoutBackground:SetWidth((button.childSize + SPELLFLYOUT_DEFAULT_SPACING) * button.count -
                                             SPELLFLYOUT_DEFAULT_SPACING + SPELLFLYOUT_INITIAL_SPACING + SPELLFLYOUT_FINAL_SPACING)
    end
end

function Addon:CreateFlyoutButtonChild(button, action, index)
    local child = LAB:CreateButton(button:GetName() .. index, button:GetName() .. "_Button_" .. index, button)
    child:SetSize(button.childSize, button.childSize)
    child:SetFrameLevel(5)
    child:SetAttribute("index", index)
    child:Hide()

    if Addon.masqueGroup then
        Addon.masqueGroup:AddButton(child)
    else
        AB:StyleButton(child)
    end

    child:HookScript("OnEnter", function()
        Addon:UpdateFlyoutButtonBackground(button)
        AB:Bar_OnEnter(button:GetParent())
    end)
    child:HookScript("OnLeave", function()
        AB:Bar_OnLeave(button:GetParent())
    end)
    child:HookScript("OnHide", function()
        Addon:UpdateFlyoutButtonBackground(button)
    end)
    child:HookScript("OnClick", function(self, mouseButton)
        child:SetChecked(false)
        if not InCombatLockdown() then
            local mode = button.config.defaultActionUpdateMode
            if (mode == Addon.UPDATE_DEFAULT_MODE.ANY_CLICK) or
                (mouseButton == "LeftButton" and (mode == Addon.UPDATE_DEFAULT_MODE.LEFT_CLICK)) or
                (mouseButton == "RightButton" and (mode == Addon.UPDATE_DEFAULT_MODE.RIGHT_CLICK)) or
                (mouseButton == "MiddleButton" and (mode == Addon.UPDATE_DEFAULT_MODE.MIDDLE_CLICK)) then
                Addon:SetFlyoutCurrentAction(button, action)
            end
            Addon:UpdateFlyoutButton(button)
        end
    end)

    SecureHandlerWrapScript(child, "OnEnter", button, [[
        control:Run(open)
    ]])
    SecureHandlerWrapScript(child, "OnLeave", button, [[return true, ""]], [[
        inHeader =  control:IsUnderMouse(true)
        if not inHeader then
            control:Run(close)
        end	    
    ]])

    return child
end

function Addon:PositionFlyoutButtonChild(button, child, previousButton)
    child:SetSize(button.childSize, button.childSize)
    child:ClearAllPoints()
    if button.bar.db.direction == "UP" then
        if previousButton then
            child:SetPoint("BOTTOM", previousButton, "TOP", 0, SPELLFLYOUT_DEFAULT_SPACING)
        else
            child:SetPoint("BOTTOM", button.CurrentAction, "TOP", 0, SPELLFLYOUT_INITIAL_SPACING)
        end
    elseif button.bar.db.direction == "DOWN" then
        if previousButton then
            child:SetPoint("TOP", previousButton, "BOTTOM", 0, -SPELLFLYOUT_DEFAULT_SPACING)
        else
            child:SetPoint("TOP", button.CurrentAction, "BOTTOM", 0, -SPELLFLYOUT_INITIAL_SPACING)
        end
    elseif button.bar.db.direction == "LEFT" then
        if previousButton then
            child:SetPoint("RIGHT", previousButton, "LEFT", -SPELLFLYOUT_DEFAULT_SPACING, 0)
        else
            child:SetPoint("RIGHT", button.CurrentAction, "LEFT", -SPELLFLYOUT_INITIAL_SPACING, 0)
        end
    elseif button.bar.db.direction == "RIGHT" then
        if previousButton then
            child:SetPoint("LEFT", previousButton, "RIGHT", SPELLFLYOUT_DEFAULT_SPACING, 0)
        else
            child:SetPoint("LEFT", button.CurrentAction, "RIGHT", SPELLFLYOUT_INITIAL_SPACING, 0)
        end
    end
end

function Addon:SetFlyoutCurrentAction(button, action)
    local actionFound = false
    for _, id in ipairs(button.config.actions) do
        if action == id then
            actionFound = true
        end
    end

    if not actionFound then
        action = button.config.defaultAction or Addon:GetMaxKnownRank(button.config.actions[1]) or button.config.actions[1]
    end

    if button.config.showOnlyMaxRank then
        action = Addon:GetMaxKnownRank(action) or action
    end

    if action and not IsSpellKnown(action) then
        for _, id in next, button.config.actions do
            if IsSpellKnown(id) then
                action = id
            end
        end
    end

    if action and IsSpellKnown(action) then
        local icon = select(3, GetSpellInfo(action))
        button.CurrentAction.icon:SetTexture(icon)
        button.CurrentAction.icon:Show()

        button.CurrentAction:SetState(0, "spell", action)
        button.config.defaultAction = action
    end
end
