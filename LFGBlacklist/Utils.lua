local addonName, LFGBlacklist = ...

local date = date
local gsub = string.gsub
local lower = string.lower
local match = string.match
local strtrim = strtrim
local upper = string.upper

local function NormalizeRealmName(realmName)
    if type(realmName) ~= "string" then
        return nil
    end

    realmName = strtrim(realmName)
    if realmName == "" then
        return nil
    end

    realmName = gsub(realmName, "[%s%-]+", "")
    if realmName == "" then
        return nil
    end

    return lower(realmName)
end

local function TitleCaseToken(token)
    return (token:gsub("(%a)([%w']*)", function(first, rest)
        return upper(first) .. lower(rest)
    end))
end

function LFGBlacklist:NormalizePlayerName(name)
    if type(name) ~= "string" then
        return nil
    end

    local rawName = strtrim(name)
    if rawName == "" then
        return nil
    end

    rawName = gsub(rawName, "[%z\1-\31]", "")
    rawName = gsub(rawName, "%s*%-%s*", "-")

    local namePart, realmPart = match(rawName, "^([^%-]+)%-(.+)$")
    if not namePart then
        namePart = rawName
    end

    namePart = gsub(namePart, "%s+", "")
    if namePart == "" then
        return nil
    end

    realmPart = NormalizeRealmName(realmPart) or NormalizeRealmName(GetNormalizedRealmName()) or NormalizeRealmName(GetRealmName())
    if not realmPart then
        return nil
    end

    return lower(namePart .. "-" .. realmPart)
end

function LFGBlacklist:GetDisplayName(name)
    local normalizedName = self:NormalizePlayerName(name)
    if not normalizedName then
        return nil
    end

    local namePart, realmPart = match(normalizedName, "^([^%-]+)%-(.+)$")
    if not namePart or not realmPart then
        return normalizedName
    end

    return TitleCaseToken(namePart) .. "-" .. TitleCaseToken(realmPart)
end

function LFGBlacklist:BuildFullPlayerName(name, realm)
    if type(name) ~= "string" or strtrim(name) == "" then
        return nil
    end

    if type(realm) == "string" and strtrim(realm) ~= "" then
        return ("%s-%s"):format(name, realm)
    end

    return name
end

function LFGBlacklist:GetFullUnitName(unit)
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then
        return nil
    end

    local name, realm = UnitFullName(unit)
    if not name then
        return nil
    end

    realm = realm or GetNormalizedRealmName() or GetRealmName()
    return self:BuildFullPlayerName(name, realm)
end

function LFGBlacklist:ColorizeText(text)
    local hex = self.highlightColor.hex
    return ("|c%s%s|r"):format(hex, tostring(text or ""))
end

function LFGBlacklist:FormatTimestamp(timestamp)
    if type(timestamp) ~= "number" then
        return "Unknown"
    end

    return date("%Y-%m-%d", timestamp)
end

function LFGBlacklist:BuildPlayerSummary(playerData)
    if not playerData then
        return "No blacklist data available."
    end

    return ("%s - %s (Added %s)"):format(
        playerData.name or "Unknown",
        playerData.reason or "Unknown",
        self:FormatTimestamp(playerData.addedAt)
    )
end
