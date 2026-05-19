local addonName, LFGBlacklist = ...

LFGBlacklist.PopupMenu = LFGBlacklist.PopupMenu or {}

local module = LFGBlacklist.PopupMenu

local menuTags = {
    "MENU_UNIT_TARGET",
    "MENU_UNIT_PARTY",
    "MENU_UNIT_RAID_PLAYER",
    "MENU_UNIT_PLAYER",          -- right-click player name in chat (online)
    "MENU_UNIT_PLAYER_OFFLINE",  -- right-click player name in chat (offline/cross-realm)
    "MENU_UNIT_WHISPER_PLAYER",  -- right-click inside an open whisper conversation
    "MENU_UNIT_FRIEND",          -- right-click player in friends list
}

local function GetMenuPlayerName(contextData)
    if contextData and contextData.unit then
        local unitName = LFGBlacklist:GetFullUnitName(contextData.unit)
        if unitName then
            return unitName
        end
    end

    if contextData and contextData.name then
        return LFGBlacklist:BuildFullPlayerName(contextData.name, contextData.server)
    end

    return nil
end

local function AddBlacklistMenu(owner, rootDescription, contextData)
    local fullName = GetMenuPlayerName(contextData)
    local normalizedName = LFGBlacklist:NormalizePlayerName(fullName)
    if not normalizedName then
        return
    end

    -- Only skip NPC context menus (unit exists AND is not a player).
    -- Do NOT skip offline players — they have a unit token that UnitExists() returns false for.
    if contextData and contextData.unit then
        if UnitExists(contextData.unit) and not UnitIsPlayer(contextData.unit) then
            return
        end
    end

    rootDescription:CreateDivider()

    local blacklistMenu = rootDescription:CreateButton("LFG Blacklist")
    local addMenu = blacklistMenu:CreateButton("Add to blacklist")

    for _, reason in ipairs(LFGBlacklist:GetReasons()) do
        addMenu:CreateButton(reason.label, function()
            local _, playerData = LFGBlacklist:AddPlayer(fullName, reason.id)
            if playerData then
                LFGBlacklist:Print(("Added %s as %s."):format(playerData.name, playerData.reason))
            end
        end)
    end

    local removeButton = blacklistMenu:CreateButton("Remove from blacklist", function()
        local _, playerData = LFGBlacklist:RemovePlayer(fullName)
        if playerData then
            LFGBlacklist:Print(("Removed %s from the blacklist."):format(playerData.name))
        end
    end)

    removeButton:SetEnabled(LFGBlacklist:IsPlayerBlacklisted(normalizedName))
end

function module:Initialize()
    if self.initialized then
        return
    end

    if not Menu or type(Menu.ModifyMenu) ~= "function" then
        return
    end

    for _, menuTag in ipairs(menuTags) do
        -- Retail uses the modern menu builder here instead of legacy UnitPopup table edits.
        Menu.ModifyMenu(menuTag, AddBlacklistMenu)
    end

    self.initialized = true
end
