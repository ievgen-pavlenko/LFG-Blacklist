local addonName, LFGBlacklist = ...

LFGBlacklist.ChatMenu = LFGBlacklist.ChatMenu or {}

local module = LFGBlacklist.ChatMenu

-- ============================================================
-- Constants
-- ============================================================

local PANEL_WIDTH   = 174
local BUTTON_HEIGHT = 20
local PADDING       = 6
local TITLE_HEIGHT  = 36  -- space for title + player name

-- ============================================================
-- Panel state
-- ============================================================

local panel        = nil
local clickCatcher = nil

local function HidePanel()
    if panel        then panel:Hide()        end
    if clickCatcher then clickCatcher:Hide() end
end

-- ============================================================
-- Panel construction (lazy, built once)
-- ============================================================

local function EnsurePanel()
    if panel then return panel end

    -- Full-screen transparent click-catcher sits behind the panel.
    -- Any click outside the panel hides everything.
    clickCatcher = CreateFrame("Frame", nil, UIParent)
    clickCatcher:SetAllPoints(UIParent)
    clickCatcher:SetFrameStrata("FULLSCREEN")
    clickCatcher:EnableMouse(true)
    clickCatcher:Hide()
    clickCatcher:SetScript("OnMouseDown", HidePanel)

    -- Main popup panel
    panel = CreateFrame("Frame", "LFGBlacklistChatPanel", UIParent, "BackdropTemplate")
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetFrameLevel(10)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:Hide()

    panel:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    panel:SetBackdropColor(0.03, 0.07, 0.03, 0.97)
    panel:SetBackdropBorderColor(0.2, 0.75, 0.2, 0.9)

    -- Title
    local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", 0, -8)
    titleText:SetTextColor(0.25, 1, 0.25)
    titleText:SetText("LFG Blacklist")

    -- Player name sub-title
    local nameText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("TOP", 0, -22)
    nameText:SetTextColor(0.75, 0.75, 0.75)
    panel.nameText = nameText

    -- Divider below header
    local sep = panel:CreateTexture(nil, "OVERLAY")
    sep:SetColorTexture(0.25, 0.6, 0.25, 0.55)
    sep:SetSize(PANEL_WIDTH - 12, 1)
    sep:SetPoint("TOP", 0, -(TITLE_HEIGHT))

    panel.buttons = {}

    return panel
end

-- ============================================================
-- Build and position the panel for a given player name
-- ============================================================

-- Creates a labelled button whose FontString is explicitly set up so
-- GetFontString() is never nil and SetJustifyH/SetTextColor work correctly.
local function CreateLabelButton(parent)
    local btn = CreateFrame("Button", nil, parent)
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", btn, "LEFT", 4, 0)
    label:SetPoint("RIGHT", btn, "RIGHT", 0, 0)
    label:SetJustifyH("LEFT")
    btn:SetFontString(label)
    return btn
end

local function ShowPanel(playerName)
    local p = EnsurePanel()

    local normalizedName = LFGBlacklist:NormalizePlayerName(playerName)
    if not normalizedName then return end

    local displayName = LFGBlacklist:GetDisplayName(playerName) or playerName
    p.nameText:SetText(displayName)
    p.currentPlayer = playerName

    -- Recycle / hide previous buttons
    for _, btn in ipairs(p.buttons) do
        btn:Hide()
    end
    wipe(p.buttons)

    local reasons = LFGBlacklist:GetReasons()
    local yOff    = -(TITLE_HEIGHT + PADDING + 4)

    -- One button per blacklist reason
    for i, reason in ipairs(reasons) do
        local btn = CreateLabelButton(p)
        btn:SetSize(PANEL_WIDTH - PADDING * 2, BUTTON_HEIGHT)
        btn:SetPoint("TOPLEFT", PADDING, yOff)
        btn:SetText("|cff88ff88+|r " .. reason.label)

        btn:SetScript("OnEnter", function(b) b:GetFontString():SetTextColor(1, 1, 0.4) end)
        btn:SetScript("OnLeave", function(b) b:GetFontString():SetTextColor(1, 1, 1)   end)

        local capturedReason = reason
        btn:SetScript("OnClick", function()
            local _, data = LFGBlacklist:AddPlayer(p.currentPlayer, capturedReason.id)
            if data then
                LFGBlacklist:Print(("Added %s as %s."):format(data.name, data.reason))
            end
            HidePanel()
        end)

        p.buttons[i] = btn
        yOff = yOff - BUTTON_HEIGHT - 2
    end

    -- Thin separator before the remove button (reuse cached texture)
    if not p.sep2 then
        p.sep2 = p:CreateTexture(nil, "OVERLAY")
        p.sep2:SetColorTexture(0.2, 0.2, 0.2, 0.7)
        p.sep2:SetSize(PANEL_WIDTH - 12, 1)
    end
    yOff = yOff - 3
    p.sep2:ClearAllPoints()
    p.sep2:SetPoint("TOPLEFT", 6, yOff)
    yOff = yOff - 5

    -- Remove button
    local isBlacklisted = LFGBlacklist:IsPlayerBlacklisted(normalizedName)
    local removeIdx     = #reasons + 1

    if not p.removeBtn then
        p.removeBtn = CreateLabelButton(p)
    end
    local removeBtn = p.removeBtn

    removeBtn:SetSize(PANEL_WIDTH - PADDING * 2, BUTTON_HEIGHT)
    removeBtn:ClearAllPoints()
    removeBtn:SetPoint("TOPLEFT", PADDING, yOff)
    removeBtn:SetEnabled(isBlacklisted)

    if isBlacklisted then
        removeBtn:SetText("|cffff7777-|r Remove from blacklist")
        removeBtn:GetFontString():SetTextColor(1, 1, 1)
        removeBtn:SetScript("OnEnter", function(b) b:GetFontString():SetTextColor(1, 0.4, 0.4) end)
        removeBtn:SetScript("OnLeave", function(b) b:GetFontString():SetTextColor(1, 1, 1)     end)
    else
        removeBtn:SetText("|cff555555-|r Not blacklisted")
        removeBtn:GetFontString():SetTextColor(0.4, 0.4, 0.4)
    end

    removeBtn:SetScript("OnClick", function()
        local _, data = LFGBlacklist:RemovePlayer(p.currentPlayer)
        if data then
            LFGBlacklist:Print(("Removed %s from the blacklist."):format(data.name))
        end
        HidePanel()
    end)

    p.buttons[removeIdx] = removeBtn
    yOff = yOff - BUTTON_HEIGHT - PADDING

    -- Resize panel to fit content
    p:SetSize(PANEL_WIDTH, -yOff)

    -- Position near cursor, clamped to screen edges
    local cx, cy   = GetCursorPosition()
    local uiScale  = UIParent:GetEffectiveScale()
    cx, cy         = cx / uiScale, cy / uiScale

    local sw       = GetScreenWidth()
    local pw, ph   = p:GetWidth(), p:GetHeight()

    local posX = cx + 14
    local posY = cy

    if posX + pw > sw  then posX = cx - pw - 14 end
    if posY - ph < 0   then posY = posY + ph     end

    p:ClearAllPoints()
    p:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", posX, posY)

    clickCatcher:Show()
    p:Show()
end

-- ============================================================
-- SetItemRef hook — fires when any chat hyperlink is clicked
-- ============================================================

function module:Initialize()
    if self.initialized then return end

    -- hooksecurefunc runs after the original, so the default WoW player
    -- context menu is already open when our panel appears alongside it.
    hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
        if button ~= "RightButton" then
            HidePanel()
            return
        end

        -- Player link format: player:Name-Realm:level:CLASS:...
        -- Extract only the Name-Realm part (everything before the second colon).
        if link:sub(1, 7) ~= "player:" then
            HidePanel()
            return
        end
        local playerString = link:match("^player:([^:]+)")
        if not playerString then
            HidePanel()
            return
        end

        if not LFGBlacklistDB or not LFGBlacklistDB.settings then
            return
        end

        ShowPanel(playerString)
    end)

    self.initialized = true
end
