local addonName, LFGBlacklist = ...

local function CopyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end

            CopyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local function SanitizePlayers()
    local sanitizedPlayers = {}

    for playerKey, playerData in pairs(LFGBlacklistDB.players or {}) do
        local normalizedName = LFGBlacklist:NormalizePlayerName((type(playerData) == "table" and playerData.name) or playerKey)
        if normalizedName then
            local reason = LFGBlacklist:GetReasonById(type(playerData) == "table" and playerData.reasonId or nil)

            sanitizedPlayers[normalizedName] = {
                name = LFGBlacklist:GetDisplayName(normalizedName),
                reasonId = reason.id,
                reason = reason.label,
                note = type(playerData) == "table" and tostring(playerData.note or "") or "",
                addedAt = type(playerData) == "table" and tonumber(playerData.addedAt) or time(),
            }
        end
    end

    LFGBlacklistDB.players = sanitizedPlayers
end

function LFGBlacklist:GetDB()
    return LFGBlacklistDB
end

function LFGBlacklist:GetReasons()
    if LFGBlacklistDB and type(LFGBlacklistDB.reasons) == "table" then
        return LFGBlacklistDB.reasons
    end

    return self.defaults.reasons
end

function LFGBlacklist:GetReasonById(reasonId)
    local reasons = self:GetReasons()

    for _, reason in ipairs(reasons) do
        if reason.id == reasonId then
            return reason
        end
    end

    return reasons[1]
end

function LFGBlacklist:InitializeDatabase()
    if type(LFGBlacklistDB) ~= "table" then
        LFGBlacklistDB = {}
    end

    CopyDefaults(LFGBlacklistDB, self.defaults)
    SanitizePlayers()
end

function LFGBlacklist:GetPlayerData(name)
    local normalizedName = self:NormalizePlayerName(name)
    if not normalizedName then
        return nil, nil
    end

    return LFGBlacklistDB.players[normalizedName], normalizedName
end

function LFGBlacklist:IsPlayerBlacklisted(name)
    local playerData = self:GetPlayerData(name)
    return playerData ~= nil
end

function LFGBlacklist:GetPlayersSorted()
    local players = {}

    for playerKey, playerData in pairs(LFGBlacklistDB.players or {}) do
        players[#players + 1] = {
            key = playerKey,
            data = playerData,
        }
    end

    table.sort(players, function(left, right)
        return (left.data.name or "") < (right.data.name or "")
    end)

    return players
end

function LFGBlacklist:RefreshDataViews()
    if self.ConfigUI then
        self.ConfigUI:Refresh()
    end

    if self.LFGScanner then
        self.LFGScanner:RefreshVisibleEntries()
    end
end

function LFGBlacklist:AddPlayer(name, reasonId, note)
    local normalizedName = self:NormalizePlayerName(name)
    if not normalizedName then
        return nil, nil, "Invalid player name."
    end

    local reason = self:GetReasonById(reasonId)
    local playerData = {
        name = self:GetDisplayName(normalizedName),
        reasonId = reason.id,
        reason = reason.label,
        note = tostring(note or ""),
        addedAt = time(),
    }

    LFGBlacklistDB.players[normalizedName] = playerData
    self:RefreshDataViews()

    return normalizedName, playerData
end

function LFGBlacklist:RemovePlayer(name)
    local normalizedName = self:NormalizePlayerName(name)
    if not normalizedName then
        return nil, "Invalid player name."
    end

    local existingPlayer = LFGBlacklistDB.players[normalizedName]
    if not existingPlayer then
        return nil, "Player is not blacklisted."
    end

    LFGBlacklistDB.players[normalizedName] = nil
    self:RefreshDataViews()

    return normalizedName, existingPlayer
end
