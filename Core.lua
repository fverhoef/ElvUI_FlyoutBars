local addonName, addonTable = ...
local Addon = addonTable[1]
local E, L, V, P, G = unpack(ElvUI)
local AB = E:GetModule("ActionBars")
local LAB = E.Libs.LAB

local SPELLFLYOUT_DEFAULT_SPACING = 0
local SPELLFLYOUT_INITIAL_SPACING = 0
local SPELLFLYOUT_FINAL_SPACING = 4

function Addon:CreateMover(frame, name)
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
    local bar = CreateFrame("Frame", addonName .. "_" .. name, UIParent)
    bar:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    bar:CreateBackdrop("Transparent")
    bar.db = config
    bar.buttons = {}
    for i, button in ipairs(config.buttons) do
        bar.buttons[i] = Addon:CreateFlyoutButton("Teleports", bar, button)
    end

    bar:RegisterEvent("PLAYER_ENTERING_WORLD")
    bar:RegisterEvent("LEARNED_SPELL_IN_TAB")
    bar:RegisterEvent("PLAYER_TOTEM_UPDATE")
    bar:HookScript("OnEvent", function(self, event)
        if event == "PLAYER_TOTEM_UPDATE" then
            for index = 1, _G.MAX_TOTEMS do
                local button = frame.buttons[index]

                local haveTotem, totemName, start, duration, icon = GetTotemInfo(index)
                if (haveTotem and duration > 0) then
                    -- TODO: show totem duration in a status bar instead?
                    button.CurrentAction.Duration:SetCooldown(start, duration)
                    local totemId = Addon:FindTotem(totemName)
                    if totemId then
                        local actionButton = button.childButtons[totemId]
                        if actionButton then
                            button.defaultAction = totemId
                        end
                    end
                end
            end
        end

        Addon:UpdateFlyoutBar(bar)
    end)

    Addon:CreateMover(bar, addonName .. "_" .. name)
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

    local spacing = bar.db.backdrop and bar.db.backdropSpacing
    local visibleButtonCount = 0
    local lastVisibleButton
    local buttonList = {}
    for i, button in next, bar.buttons do
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
    local defaultAction = config.actions[config.defaultActionIndex or 1]

    -- create parent frame
    local button = CreateFrame("Frame", "FlyoutButton_" .. name, bar, "SecureHandlerStateTemplate")
    button.bar = bar
    button.config = config
    button.defaultAction = defaultAction
    button.showOnlyMaxRank = config.showOnlyMaxRank or false
    button.size = button.bar.db.buttonSize
    button.childSize = button.bar.db.buttonSize - 8
    button.childButtons = {}
    button:EnableMouse(true)
    button:SetSize(button.size, button.size)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(1)

    -- Create secure open/close functions (needed for combat execution)
    button:Execute([[open = [=[
            local popups = newtable(self:GetChildren())
            for i, button in ipairs(popups) do
                local index = button:GetAttribute("index")
                if index == 0 then
                    button:SetAttribute("open", 1)
                else
                    button:Show()
                end
            end
        ]=] ]])
    button:Execute([[close = [=[
            local popups = newtable(self:GetChildren())
            for i, button in pairs(popups) do
                local index = button:GetAttribute("index")
                if index == 0 then
                    button:SetAttribute("open", 0)
                else
                    button:Hide()
                end			
            end
        ]=] ]])

    -- Create a button for the current/default action
    button.CurrentAction = CreateFrame("CheckButton", button:GetName() .. "_CurrentAction", button,
                                       "SecureHandlerStateTemplate, SecureHandlerEnterLeaveTemplate, SecureActionButtonTemplate, ActionButtonTemplate")
    button.CurrentAction:EnableMouse(true)
    button.CurrentAction:SetPoint("BOTTOM", button, "BOTTOM", 0, 0)
    button.CurrentAction:SetSize(button.size, button.size)
    button.CurrentAction:SetFrameLevel(10)
    button.CurrentAction:SetAttribute("index", 0)
    button.CurrentAction:SetAttribute("type", "spell")
    button.CurrentAction:RegisterForClicks("AnyUp")
    button.CurrentAction:Show()

    if Addon.masqueGroup then
        Addon.masqueGroup:AddButton(button.CurrentAction)
    else
        AB:StyleButton(button.CurrentAction)
    end

    SecureHandlerWrapScript(button.CurrentAction, "OnEnter", button, [[
            control:Run(open)
        ]]);
    SecureHandlerWrapScript(button.CurrentAction, "OnLeave", button, [[return true, ""]], [[
            inHeader =  control:IsUnderMouse(true)
            if not inHeader then
                control:Run(close)
            end	    
        ]])

    button.CurrentAction:HookScript("OnEnter", function()
        GameTooltip:SetOwner(button.CurrentAction, "ANCHOR_LEFT")
        GameTooltip:SetSpellByID(button.CurrentAction.spellID, false, true)
        Addon:UpdateFlyoutButtonBackground(button)
        AB:Bar_OnEnter(bar)
    end)
    button.CurrentAction:HookScript("OnLeave", function()
        GameTooltip:Hide()
        Addon:UpdateFlyoutButtonBackground(button)
        AB:Bar_OnLeave(bar)
    end)
    button.CurrentAction:HookScript("OnClick", function()
        button.CurrentAction:SetChecked(false)
    end)

    Addon:FixNormalTextureSize(button.CurrentAction)

    button.childButtons[0] = button.CurrentAction

    -- Add a duration spiral
    button.CurrentAction.Duration = CreateFrame("Cooldown", nil, button.CurrentAction, "CooldownFrameTemplate")
    button.CurrentAction.Duration:SetHideCountdownNumbers(true)
    button.CurrentAction.Duration:SetAllPoints()

    -- Create flyout border and arrow
    button.FlyoutArrowHolder = CreateFrame("Frame", nil, button.CurrentAction)
    button.FlyoutArrowHolder:SetPoint("CENTER", button.CurrentAction, "CENTER")
    button.FlyoutArrowHolder:SetFrameLevel(button.CurrentAction:GetFrameLevel() + 20)
    button.FlyoutArrow = button.FlyoutArrowHolder:CreateTexture(nil, "OVERLAY", "ActionBarFlyoutButton-ArrowUp")
    button.FlyoutArrow:SetPoint("CENTER", button.FlyoutArrowHolder, "CENTER")

    -- create background for child buttons
    button.FlyoutBackground = CreateFrame("Frame", "FlyoutButton_" .. name .. "_Background", button)
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

    Addon:UpdateFlyoutButton(button)

    -- TODO: check if any additional events need to be listened to here
    button:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    button:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    button:RegisterEvent("PLAYER_ENTERING_WORLD")
    button:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    button:RegisterEvent("UNIT_POWER_FREQUENT")
    button:RegisterEvent("LOSS_OF_CONTROL_ADDED")
    button:RegisterEvent("LOSS_OF_CONTROL_UPDATE")
    button:RegisterEvent("SPELL_UPDATE_CHARGES")
    button:RegisterEvent("SPELL_UPDATE_ICON")
    button:RegisterEvent("BAG_UPDATE")
    button:RegisterEvent("UNIT_INVENTORY_CHANGED")

    button:SetScript("OnEvent", function(self, event)
        Addon:UpdateFlyoutButton(button)
    end)

    return button
end

function Addon:UpdateFlyoutButton(button)
    local defaultAction = button.defaultAction

    button.isOpen = button.CurrentAction:GetAttribute("open") == 1

    if not InCombatLockdown() then
        button.count = 0

        -- generate buttons
        local previousButton
        for i, action in next, button.config.actions do
            local actionButton = button.childButtons[action]

            -- generate a new button if known and not generated yet
            local isKnown = IsSpellKnown(action)
            if isKnown then
                local shouldBeVisible = not button.showOnlyMaxRank or (button.showOnlyMaxRank and Addon:IsMaxKnownRank(action))
                if not actionButton and shouldBeVisible then
                    actionButton = Addon:CreateFlyoutButtonChild(button, action, i, previousButton)
                    button.childButtons[action] = actionButton
                elseif actionButton and not shouldBeVisible then
                    actionButton:Hide()
                    actionButton = nil
                    button.childButtons[action] = nil
                end
            end

            if actionButton then
                button.count = button.count + 1
                previousButton = actionButton
            end
        end

        -- if the default is not max rank, set it to max rank
        if button.showOnlyMaxRank then
            local maxRank = Addon:GetMaxKnownRank(defaultAction)
            if maxRank then
                defaultAction = maxRank
            end
        end

        -- if the default is an unknown spell, try to find one that we do know
        if not IsSpellKnown(defaultAction) then
            for i, action in next, button.config.actions do
                if IsSpellKnown(action) then
                    defaultAction = action
                end
            end
        end

        -- set current action
        if IsSpellKnown(defaultAction) then
            local spellName, _, icon = GetSpellInfo(defaultAction)
            button.CurrentAction.icon:SetTexture(icon)
            button.CurrentAction.icon:Show()
            button.CurrentAction:SetAttribute("spell", spellName)
            button.CurrentAction.spellID = defaultAction
        end

        button.defaultAction = defaultAction
    end

    button.size = button.bar.db.buttonSize
    button.childSize = button.bar.db.buttonSize - 8
    button:SetSize(button.bar.db.buttonSize, button.bar.db.buttonSize)
    button.CurrentAction:SetSize(button.bar.db.buttonSize, button.bar.db.buttonSize)
    Addon:UpdateFlyoutButtonBackground(button)

    if button.count > 0 and button.config.enabled then
        button:Show()

        for i, child in next, button.childButtons do
            Addon:UpdateFlyoutButtonChild(button, child)
        end
    else
        button:Hide()
    end
end

function Addon:UpdateFlyoutButtonBackground(button)
    button.isOpen = button.CurrentAction:GetAttribute("open") == 1

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

function Addon:CreateFlyoutButtonChild(button, action, index, previousButton)
    local spellName, _, icon = GetSpellInfo(action)

    local actionButton = CreateFrame("CheckButton", button:GetName() .. "_Button_" .. index, button,
                                     "SecureHandlerStateTemplate, SecureHandlerEnterLeaveTemplate, SecureActionButtonTemplate, ActionButtonTemplate")
    actionButton:EnableMouse(true)
    actionButton:SetSize(button.childSize, button.childSize)
    actionButton:SetFrameLevel(5)
    actionButton:SetAttribute("index", index)
    actionButton:SetAttribute("type", "spell")
    actionButton:SetAttribute("spell", spellName)
    actionButton:RegisterForClicks("AnyUp")
    actionButton.icon:SetTexture(icon)
    actionButton.icon:Show()
    actionButton.spellID = action
    actionButton:Hide()

    if Addon.masqueGroup then
        Addon.masqueGroup:AddButton(actionButton)
    else
        AB:StyleButton(actionButton)
    end

    actionButton:ClearAllPoints()
    if button.bar.db.direction == "UP" then
        if previousButton then
            actionButton:SetPoint("BOTTOM", previousButton, "TOP", 0, SPELLFLYOUT_DEFAULT_SPACING)
        else
            actionButton:SetPoint("BOTTOM", button.CurrentAction, "TOP", 0, SPELLFLYOUT_INITIAL_SPACING)
        end
    elseif button.bar.db.direction == "DOWN" then
        if previousButton then
            actionButton:SetPoint("TOP", previousButton, "BOTTOM", 0, -SPELLFLYOUT_DEFAULT_SPACING)
        else
            actionButton:SetPoint("TOP", button.CurrentAction, "BOTTOM", 0, -SPELLFLYOUT_INITIAL_SPACING)
        end
    elseif button.bar.db.direction == "LEFT" then
        if previousButton then
            actionButton:SetPoint("RIGHT", previousButton, "LEFT", -SPELLFLYOUT_DEFAULT_SPACING, 0)
        else
            actionButton:SetPoint("RIGHT", button.CurrentAction, "LEFT", -SPELLFLYOUT_INITIAL_SPACING, 0)
        end
    elseif button.bar.db.direction == "RIGHT" then
        if previousButton then
            actionButton:SetPoint("LEFT", previousButton, "RIGHT", SPELLFLYOUT_DEFAULT_SPACING, 0)
        else
            actionButton:SetPoint("LEFT", button.CurrentAction, "RIGHT", SPELLFLYOUT_INITIAL_SPACING, 0)
        end
    end

    actionButton:HookScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_LEFT")
        GameTooltip:SetSpellByID(action, false, true)
        Addon:UpdateFlyoutButtonBackground(button)
        AB:Bar_OnEnter(button:GetParent())
    end)
    actionButton:HookScript("OnLeave", function()
        GameTooltip:Hide()
        AB:Bar_OnLeave(button:GetParent())
    end)
    actionButton:HookScript("OnHide", function()
        Addon:UpdateFlyoutButtonBackground(button)
    end)
    actionButton:HookScript("OnClick", function()
        actionButton:SetChecked(false)
        if not InCombatLockdown() then
            button.defaultAction = action
            Addon:UpdateFlyoutButton(button)
        end
    end)

    SecureHandlerWrapScript(actionButton, "OnEnter", button, [[
        control:Run(open)
    ]])
    SecureHandlerWrapScript(actionButton, "OnLeave", button, [[return true, ""]], [[
        inHeader =  control:IsUnderMouse(true)
        if not inHeader then
            control:Run(close)
        end	    
    ]])

    Addon:FixNormalTextureSize(actionButton)

    return actionButton
end

function Addon:UpdateFlyoutButtonChild(button, child)
    if child ~= button.CurrentAction then
        child:SetSize(button.childSize, button.childSize)
    end

    if child.spellID then
        child.isUsable, child.notEnoughMana = IsUsableSpell(child.spellID)

        if child.isUsable and UnitOnTaxi("player") then
            child.isUsable = false
        end

        if child.isUsable then
            child.icon:SetVertexColor(1.0, 1.0, 1.0)
        elseif child.notEnoughMana then
            child.icon:SetVertexColor(0.5, 0.5, 1.0)
        else
            child.icon:SetVertexColor(0.4, 0.4, 0.4)
        end

        -- update charges
        child.reagentCount = LibStub("LibClassicSpellActionCount-1.0"):GetSpellReagentCount(child.spellID)
        if child.reagentCount ~= nil then
            child.Count:SetText(child.reagentCount)
        else
            child.Count:SetText("")
        end

        -- update cooldown
        local start, duration, enable, modRate = GetSpellCooldown(child.spellID)
        local charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetSpellCharges(child.spellID)

        if (child.cooldown.currentCooldownType ~= COOLDOWN_TYPE_NORMAL) then
            child.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge");
            child.cooldown:SetSwipeColor(0, 0, 0);
            child.cooldown:SetHideCountdownNumbers(false);
            child.cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL;
        end

        if (charges and maxCharges and maxCharges > 1 and charges < maxCharges) then
            StartChargeCooldown(child, chargeStart, chargeDuration, chargeModRate)
        else
            ClearChargeCooldown(child)
        end

        CooldownFrame_Set(child.cooldown, start, duration, enable, false, modRate)
    end
end

function Addon:FixNormalTextureSize(button)
    local normalTexture = button:GetNormalTexture()
    if normalTexture then
        local texturePath = normalTexture:GetTexture()
        if texturePath == "Interface\\Buttons\\UI-Quickslot2" then
            local size = 66 * (button:GetWidth() / 36)
            normalTexture:SetSize(size, size)
        end
    end
end
