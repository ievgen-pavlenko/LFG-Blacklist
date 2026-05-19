local addonName, LFGBlacklist = ...

LFGBlacklist.Tooltip = LFGBlacklist.Tooltip or {}

local module = LFGBlacklist.Tooltip

function module:Initialize()
    if self.initialized then
        return
    end

    self.initialized = true
end

function module:AddPlayerTooltip(tooltip, playerData)
    if not tooltip or not playerData then
        return
    end

    tooltip:AddLine(" ")
    tooltip:AddLine(LFGBlacklist:ColorizeText("LFG Blacklist"))
    tooltip:AddLine(("Player: %s"):format(playerData.name or "Unknown"), 1, 1, 1)
    tooltip:AddLine(("Reason: %s"):format(playerData.reason or "Unknown"), 0.9, 0.9, 0.9)
    tooltip:AddLine(("Added: %s"):format(LFGBlacklist:FormatTimestamp(playerData.addedAt)), 0.9, 0.9, 0.9)

    if playerData.note and playerData.note ~= "" then
        tooltip:AddLine(("Note: %s"):format(playerData.note), 0.8, 0.8, 0.8, true)
    end
end
