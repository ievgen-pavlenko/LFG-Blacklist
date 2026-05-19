local addonName, LFGBlacklist = ...

LFGBlacklist.SlashCommands = LFGBlacklist.SlashCommands or {}

local module = LFGBlacklist.SlashCommands

local defaultReasonId = "leaver"

local function PrintUsage()
    LFGBlacklist:Print("Commands: /lfgbl, /lfgbl config, /lfgbl add Name-Realm, /lfgbl remove Name-Realm, /lfgbl check Name-Realm, /lfgbl debug")
end

function module:Initialize()
    if self.initialized then
        return
    end

    SLASH_LFGBLACKLIST1 = "/lfgbl"
    SlashCmdList["LFGBLACKLIST"] = function(message)
        module:HandleCommand(message)
    end

    self.initialized = true
end

function module:HandleCommand(message)
    local trimmedMessage = strtrim(message or "")
    if trimmedMessage == "" then
        LFGBlacklist.ConfigUI:Toggle()
        return
    end

    local command, rest = trimmedMessage:match("^(%S+)%s*(.-)$")
    command = command and string.lower(command) or ""

    if command == "config" then
        LFGBlacklist.ConfigUI:Open()
        return
    end

    if command == "add" then
        if rest == "" then
            PrintUsage()
            return
        end

        local _, playerData, errorMessage = LFGBlacklist:AddPlayer(rest, defaultReasonId)
        if not playerData then
            LFGBlacklist:Print(errorMessage or "Unable to add player.")
            return
        end

        LFGBlacklist:Print(("Added %s as %s."):format(playerData.name, playerData.reason))
        return
    end

    if command == "remove" then
        if rest == "" then
            PrintUsage()
            return
        end

        local _, playerDataOrMessage = LFGBlacklist:RemovePlayer(rest)
        if type(playerDataOrMessage) == "table" then
            LFGBlacklist:Print(("Removed %s from the blacklist."):format(playerDataOrMessage.name))
        else
            LFGBlacklist:Print(playerDataOrMessage or "Unable to remove player.")
        end

        return
    end

    if command == "check" then
        if rest == "" then
            PrintUsage()
            return
        end

        local playerData, normalizedName = LFGBlacklist:GetPlayerData(rest)
        if not playerData then
            LFGBlacklist:Print(("Player is not blacklisted: %s"):format(normalizedName or rest))
            return
        end

        LFGBlacklist:Print(LFGBlacklist:BuildPlayerSummary(playerData))
        return
    end

    if command == "debug" then
        LFGBlacklist:Print("=== LFG Blacklist Debug ===")
        local scanner = LFGBlacklist.LFGScanner
        LFGBlacklist:Print("Scanner hooked: " .. tostring(scanner and scanner.hooked))

        -- Applicant check
        local hasEntry = C_LFGList.HasActiveEntryInfo and C_LFGList.HasActiveEntryInfo()
        LFGBlacklist:Print("Active listing: " .. tostring(hasEntry))
        local applicants = C_LFGList.GetApplicants and C_LFGList.GetApplicants()
        LFGBlacklist:Print("Applicants: " .. tostring(applicants and #applicants or 0))
        if applicants and applicants[1] then
            local applicantID = applicants[1]
            local info = C_LFGList.GetApplicantInfo(applicantID)
            if info then
                LFGBlacklist:Print("  applicant #" .. applicantID .. " members=" .. tostring(info.numMembers))
                -- Dump ALL keys of GetApplicantInfo
                LFGBlacklist:Print("  GetApplicantInfo keys:")
                for k, v in pairs(info) do
                    LFGBlacklist:Print("    [" .. tostring(k) .. "] = " .. tostring(v))
                end
                -- Dump ALL return values / keys of GetApplicantMemberInfo
                local m = C_LFGList.GetApplicantMemberInfo(applicantID, 1)
                if m then
                    if type(m) == "table" then
                        LFGBlacklist:Print("  GetApplicantMemberInfo (table) keys:")
                        for k, v in pairs(m) do
                            LFGBlacklist:Print("    [" .. tostring(k) .. "] = " .. tostring(v))
                        end
                    else
                        -- Returned multiple values — m is actually the first value
                        LFGBlacklist:Print("  GetApplicantMemberInfo returns multiple values, first=" .. tostring(m))
                    end
                else
                    LFGBlacklist:Print("  GetApplicantMemberInfo returned nil")
                end
            end
        end

        -- Panel structure — enumerate ALL keys of LFGListFrame
        if LFGListFrame then
            LFGBlacklist:Print("LFGListFrame keys (frames/tables):")
            for k, v in pairs(LFGListFrame) do
                local t = type(v)
                if t == "table" or t == "userdata" then
                    LFGBlacklist:Print("  ." .. tostring(k) .. " (" .. t .. ")")
                end
            end
            -- Probe ApplicationViewer and its ScrollBox
            local av = LFGListFrame.ApplicationViewer
            if av then
                LFGBlacklist:Print("ApplicationViewer keys:")
                for k, v in pairs(av) do
                    local t = type(v)
                    if t == "table" or t == "userdata" then
                        LFGBlacklist:Print("  ." .. tostring(k) .. " (" .. t .. ")")
                    end
                end
                local sb = av.ScrollBox
                if sb then
                    LFGBlacklist:Print("  ScrollBox.ForEachFrame=" .. tostring(sb.ForEachFrame ~= nil))
                    LFGBlacklist:Print("  ScrollBox.GetFrames=" .. tostring(sb.GetFrames ~= nil))
                    LFGBlacklist:Print("  ScrollBox.EnumerateFrames=" .. tostring(sb.EnumerateFrames ~= nil))
                    LFGBlacklist:Print("  ScrollBox.FullUpdate=" .. tostring(sb.FullUpdate ~= nil))
                    -- Try ForEachFrame first (WoW 12.0)
                    local frames = nil
                    if sb.ForEachFrame then
                        frames = {}
                        sb:ForEachFrame(function(f) frames[#frames + 1] = f end)
                        LFGBlacklist:Print("  ForEachFrame frame count=" .. #frames)
                    elseif sb.GetFrames then
                        frames = sb:GetFrames()
                        LFGBlacklist:Print("  GetFrames frame count=" .. tostring(frames and #frames or 0))
                    end
                    if frames and frames[1] then
                        local row = frames[1]
                        LFGBlacklist:Print("  First row type=" .. type(row))
                        if row.GetElementData then
                            local ed = row:GetElementData()
                            LFGBlacklist:Print("  First row GetElementData type=" .. type(ed))
                            if type(ed) == "number" then
                                LFGBlacklist:Print("  Element data (number)=" .. ed)
                            elseif type(ed) == "table" then
                                for k, v in pairs(ed) do
                                    LFGBlacklist:Print("    ed[" .. tostring(k) .. "]=" .. tostring(v))
                                end
                            end
                        else
                            LFGBlacklist:Print("  First row has no GetElementData")
                            LFGBlacklist:Print("  row.applicantID=" .. tostring(row.applicantID))
                        end
                    else
                        LFGBlacklist:Print("  ScrollBox: no frames found (panel may not be visible)")
                    end
                    -- Also check viewer.applicants fallback
                    if type(av.applicants) == "table" then
                        local cnt = 0
                        for _ in pairs(av.applicants) do cnt = cnt + 1 end
                        LFGBlacklist:Print("  viewer.applicants count=" .. cnt)
                    end
                end
            end
            -- Also probe SearchPanel ScrollBox
            local sp = LFGListFrame.SearchPanel
            if sp and sp.ScrollBox then
                local sb = sp.ScrollBox
                LFGBlacklist:Print("SearchPanel.ScrollBox.GetFrames=" .. tostring(sb.GetFrames ~= nil))
                local frames = sb.GetFrames and sb:GetFrames()
                if frames and frames[1] then
                    local row = frames[1]
                    if row.GetElementData then
                        local ed = row:GetElementData()
                        LFGBlacklist:Print("  Search first row ed type=" .. type(ed))
                        if type(ed) == "table" then
                            for k, v in pairs(ed) do
                                LFGBlacklist:Print("    ed[" .. tostring(k) .. "]=" .. tostring(v))
                            end
                        end
                    else
                        LFGBlacklist:Print("  Search row.resultID=" .. tostring(row.resultID))
                    end
                end
            end
        else
            LFGBlacklist:Print("LFGListFrame: nil (GroupFinder not loaded?)")
        end
        return
    end

    PrintUsage()
end