local addonName, LFGBlacklist = ...

LFGBlacklist.ConfigUI = LFGBlacklist.ConfigUI or {}

local module = LFGBlacklist.ConfigUI

local function CreateRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(490, 28)

    row.background = row:CreateTexture(nil, "BACKGROUND")
    row.background:SetAllPoints()

    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.nameText:SetPoint("LEFT", 8, 0)
    row.nameText:SetWidth(155)
    row.nameText:SetJustifyH("LEFT")

    row.reasonText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.reasonText:SetPoint("LEFT", row.nameText, "RIGHT", 8, 0)
    row.reasonText:SetWidth(130)
    row.reasonText:SetJustifyH("LEFT")

    row.addedText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.addedText:SetPoint("LEFT", row.reasonText, "RIGHT", 8, 0)
    row.addedText:SetWidth(90)
    row.addedText:SetJustifyH("LEFT")

    row.removeButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.removeButton:SetSize(78, 22)
    row.removeButton:SetPoint("RIGHT", -8, 0)
    row.removeButton:SetText("Remove")
    row.removeButton:SetScript("OnClick", function(button)
        local playerKey = button:GetParent().playerKey
        if not playerKey then
            return
        end

        local normalizedName, playerData = LFGBlacklist:RemovePlayer(playerKey)
        if normalizedName and playerData then
            LFGBlacklist:Print(("Removed %s from the blacklist."):format(playerData.name))
        end
    end)

    return row
end

function module:Initialize()
    if self.frame then
        return
    end

    local frame = CreateFrame("Frame", "LFGBlacklistConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(560, 420)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    self.frame = frame
    frame.rows = {}

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOP", 0, -12)
    frame.title:SetText("LFG Blacklist")

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOPLEFT", 16, -34)
    frame.subtitle:SetPoint("TOPRIGHT", -16, -34)
    frame.subtitle:SetJustifyH("LEFT")
    frame.subtitle:SetText("Local blacklist entries used for Premade Group Finder highlights.")

    frame.headerBackground = frame:CreateTexture(nil, "ARTWORK")
    frame.headerBackground:SetColorTexture(0.12, 0.12, 0.12, 0.75)
    frame.headerBackground:SetPoint("TOPLEFT", 14, -58)
    frame.headerBackground:SetPoint("TOPRIGHT", -34, -58)
    frame.headerBackground:SetHeight(24)

    local headers = {
        { text = "Player", x = 22,  width = 155 },
        { text = "Reason", x = 185, width = 130 },
        { text = "Added",  x = 323, width = 90  },
    }

    for _, header in ipairs(headers) do
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", header.x, -64)
        label:SetWidth(header.width)
        label:SetJustifyH("LEFT")
        label:SetText(header.text)
    end

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 14, -84)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 16)
    self.scrollFrame = scrollFrame

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(490, 1)
    scrollFrame:SetScrollChild(content)
    self.content = content

    frame.emptyText = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    frame.emptyText:SetPoint("TOP", 0, -16)
    frame.emptyText:SetText("Your blacklist is currently empty.")

    frame:SetScript("OnShow", function()
        module:Refresh()
    end)
end

function module:Refresh()
    if not self.frame then
        return
    end

    local players = LFGBlacklist:GetPlayersSorted()
    self.frame.emptyText:SetShown(#players == 0)

    local contentHeight = math.max(1, #players * 30)
    self.content:SetHeight(contentHeight)

    for index, playerEntry in ipairs(players) do
        local row = self.frame.rows[index]
        if not row then
            row = CreateRow(self.content)
            self.frame.rows[index] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -((index - 1) * 30))
        row:SetPoint("TOPRIGHT", 0, -((index - 1) * 30))
        row.playerKey = playerEntry.key

        if index % 2 == 0 then
            row.background:SetColorTexture(0.09, 0.09, 0.09, 0.60)
        else
            row.background:SetColorTexture(0.05, 0.05, 0.05, 0.60)
        end

        row.nameText:SetText(playerEntry.data.name or playerEntry.key)
        row.reasonText:SetText(playerEntry.data.reason or "Unknown")
        row.addedText:SetText(LFGBlacklist:FormatTimestamp(playerEntry.data.addedAt))
        row:Show()
    end

    for index = #players + 1, #self.frame.rows do
        self.frame.rows[index]:Hide()
        self.frame.rows[index].playerKey = nil
    end
end

function module:Toggle()
    if not self.frame then
        self:Initialize()
    end

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

function module:Open()
    if not self.frame then
        self:Initialize()
    end

    self.frame:Show()
end
