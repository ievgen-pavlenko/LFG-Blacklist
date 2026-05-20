local addonName, LFGBlacklist = ...

LFGBlacklist.Tooltip = LFGBlacklist.Tooltip or {}

local module = LFGBlacklist.Tooltip

local function AppendBlacklistLines(tooltip, playerData)
    if not tooltip or not playerData then return end
    tooltip:AddLine(" ")
    tooltip:AddLine(LFGBlacklist:ColorizeText("LFG Blacklist"), 1, 1, 1)
    tooltip:AddLine(("Reason: %s"):format(playerData.reason or "Unknown"), 0.9, 0.9, 0.9)
    tooltip:AddLine(("Added: %s"):format(LFGBlacklist:FormatTimestamp(playerData.addedAt)), 0.7, 0.7, 0.7)
    if playerData.note and playerData.note ~= "" then
        tooltip:AddLine(("Note: %s"):format(playerData.note), 0.8, 0.8, 0.8, true)
    end
end

local function OnTooltipSetUnit(tooltip)
    if not LFGBlacklistDB or not LFGBlacklistDB.settings.showTooltip then return end
    local _, unit = tooltip:GetUnit()
    if not unit or not UnitIsPlayer(unit) then return end
    local name, realm = UnitFullName(unit)
    if not name then return end
    realm = realm and realm ~= "" and realm or (GetNormalizedRealmName() or GetRealmName())
    local playerData = LFGBlacklist:GetPlayerData(name .. "-" .. realm)
    if playerData then
        AppendBlacklistLines(tooltip, playerData)
        tooltip:Show()
    end
end

function module:Initialize()
    if self.initialized then return end
    self.initialized = true

    -- Modern API (10.0+): TooltipDataProcessor fires after all data is set.
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
            OnTooltipSetUnit(tooltip)
        end)
    else
        -- Fallback for older interface versions.
        hooksecurefunc(GameTooltip, "SetUnit", function(tooltip)
            OnTooltipSetUnit(tooltip)
        end)
    end
end

-- Public helper kept for external callers.
function module:AddPlayerTooltip(tooltip, playerData)
    AppendBlacklistLines(tooltip, playerData)
end
