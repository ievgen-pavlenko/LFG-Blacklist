local addonName, LFGBlacklist = ...

LFGBlacklist.LFGScanner = LFGBlacklist.LFGScanner or {}

local module = LFGBlacklist.LFGScanner

module.notifiedApplicants = module.notifiedApplicants or {}

-- ============================================================
-- Scroll box helpers (copied pattern from MoldDetector)
-- In WoW 12.0 ScrollBox frames use GetElementData() for their data,
-- and enumerate via GetFrames() or EnumerateFrames().
-- ============================================================

local function EnumerateScrollBoxFrames(sb)
    if not sb then return nil end
    -- WoW 12.0+: ScrollBox uses ForEachFrame
    if sb.ForEachFrame then
        local frames = {}
        sb:ForEachFrame(function(f) frames[#frames + 1] = f end)
        if #frames > 0 then return frames end
    end
    if sb.GetFrames then
        local frames = sb:GetFrames()
        if frames and #frames > 0 then return frames end
    end
    if sb.EnumerateFrames then
        local frames = {}
        for f in sb:EnumerateFrames() do frames[#frames + 1] = f end
        if #frames > 0 then return frames end
    end
    return nil
end

local function GetApplicantIDFromRow(frame)
    if not frame then return nil end
    -- Direct field (classic FrameXML rows)
    if frame.applicantID then return frame.applicantID end
    -- ScrollBox element data — may be a bare number or a table
    if frame.GetElementData then
        local ed = frame:GetElementData()
        if type(ed) == "number" then return ed end
        if type(ed) == "table" then
            return ed.applicantID or ed.applicantId or ed.ApplicantID or ed.id or ed.ID
        end
    end
    return frame.applicantId or frame.ApplicantID or frame.id
end

local function GetResultIDFromRow(frame)
    if not frame then return nil end
    if frame.resultID then return frame.resultID end
    if frame.GetElementData then
        local ed = frame:GetElementData()
        if type(ed) == "number" then return ed end
        if type(ed) == "table" then
            return ed.resultID or ed.resultId or ed.id or ed.ID
        end
    end
    return frame.resultId or frame.id
end

-- ============================================================
-- Highlight overlay (OVERLAY layer, safe even on complex frames)
-- ============================================================

local function EnsureHighlight(host)
    if not host then return nil end
    -- If the frame has no CreateTexture (e.g. it's a Texture object), try parent.
    if not host.CreateTexture and host.GetParent then
        host = host:GetParent()
    end
    if not host or not host.CreateTexture then return nil end

    if not host._lfgblHL then
        local t = host:CreateTexture(nil, "OVERLAY")
        t:SetAllPoints(true)
        local c = LFGBlacklist.highlightColor
        t:SetColorTexture(c.r, c.g, c.b, 0.45)
        host._lfgblHL = t
    end
    return host._lfgblHL
end

local function PaintHighlight(rowFrame, on)
    if not rowFrame then return end
    local candidate = rowFrame.Contents or rowFrame.Button or rowFrame.Background or rowFrame
    local t = EnsureHighlight(candidate) or EnsureHighlight(rowFrame)
    if not t then return end
    if on then t:Show() else t:Hide() end
end

-- ============================================================
-- Applicant blacklist lookup
-- GetApplicantMemberInfo returns multiple values: name, class, ...
-- ============================================================

local function GetApplicantBlacklistedMembers(applicantID)
    if not applicantID or not C_LFGList then return nil end

    local applicantInfo = C_LFGList.GetApplicantInfo(applicantID)
    if not applicantInfo then return nil end

    local blacklisted = {}
    local numMembers = applicantInfo.numMembers or 1

    for i = 1, numMembers do
        local memberName = C_LFGList.GetApplicantMemberInfo(applicantID, i)
        local playerData = LFGBlacklist:GetPlayerData(memberName)
        if playerData then
            blacklisted[#blacklisted + 1] = playerData
        end
    end

    return #blacklisted > 0 and blacklisted or nil
end

-- ============================================================
-- Applicant highlighting
-- ============================================================

local _applicantDebounce = nil

function module:DebouncedHighlightApplicants()
    if _applicantDebounce then return end
    _applicantDebounce = C_Timer.After(0.07, function()
        _applicantDebounce = nil
        module:HighlightApplicantRows()
    end)
end

function module:HighlightApplicantRows()
    if not LFGBlacklistDB or not LFGBlacklistDB.settings.highlightLFG then return end

    local viewer = LFGListFrame and LFGListFrame.ApplicationViewer
    if not viewer then return end

    -- Try ScrollBox enumeration first.
    local sb = viewer.ScrollBox
    local frames = sb and EnumerateScrollBoxFrames(sb)

    -- Fallback: iterate viewer.applicants (old-style or widget pool table).
    if not frames and type(viewer.applicants) == "table" then
        frames = {}
        for k, v in pairs(viewer.applicants) do
            local t = type(v)
            if t == "table" or t == "userdata" then
                -- If table key is a number, try it as a fallback applicantID hint.
                if type(k) == "number" then v._lfgblKeyHint = k end
                frames[#frames + 1] = v
            end
        end
    end

    if not frames or #frames == 0 then return end

    for _, row in ipairs(frames) do
        local applicantID = GetApplicantIDFromRow(row)
        -- Last-resort: use the key hint stored above.
        if not applicantID then applicantID = rawget(row, "_lfgblKeyHint") end
        local blacklisted = applicantID and GetApplicantBlacklistedMembers(applicantID)
        PaintHighlight(row, blacklisted ~= nil)
    end
end

-- ============================================================
-- Search result highlighting
-- ============================================================

local function ResolveLeaderName(info)
    local name = info.leaderName
    if not LFGBlacklist:IsSecretValue(name) then return name end
    -- In instances leaderName is secret; fall back to the GUID cache.
    local guid = info.leaderGUID
    if LFGBlacklist:IsSecretValue(guid) or not guid then return nil end
    local _, _, _, _, guidName, guidRealm = GetPlayerInfoByGUID(guid)
    if not guidName or LFGBlacklist:IsSecretValue(guidName) then return nil end
    return (guidRealm and guidRealm ~= "") and (guidName .. "-" .. guidRealm) or guidName
end

local _searchDebounce = nil

function module:DebouncedHighlightSearch()
    if _searchDebounce then return end
    _searchDebounce = C_Timer.After(0.07, function()
        _searchDebounce = nil
        module:HighlightSearchRows()
    end)
end

function module:HighlightSearchRows()
    if not LFGBlacklistDB or not LFGBlacklistDB.settings.highlightLFG then return end

    local sp = LFGListFrame and LFGListFrame.SearchPanel
    local sb = sp and sp.ScrollBox
    if not sb then return end

    local frames = EnumerateScrollBoxFrames(sb)
    if not frames then return end

    for _, row in ipairs(frames) do
        local rid = GetResultIDFromRow(row)
        local playerData = nil
        if rid and C_LFGList and C_LFGList.GetSearchResultInfo then
            if not (C_LFGList.HasSearchResultInfo and not C_LFGList.HasSearchResultInfo(rid)) then
                local info = C_LFGList.GetSearchResultInfo(rid)
                if info then
                    playerData = LFGBlacklist:GetPlayerData(ResolveLeaderName(info))
                end
            end
        end
        PaintHighlight(row, playerData ~= nil)
    end
end

-- ============================================================
-- Chat notifications for blacklisted applicants
-- ============================================================

function module:CheckApplicantsAndNotify()
    local applicants = C_LFGList.GetApplicants and C_LFGList.GetApplicants()
    if not applicants or #applicants == 0 then
        wipe(self.notifiedApplicants)
        return
    end

    -- Prune stale IDs.
    local current = {}
    for _, id in ipairs(applicants) do current[id] = true end
    for id in pairs(self.notifiedApplicants) do
        if not current[id] then self.notifiedApplicants[id] = nil end
    end

    -- Print once per new blacklisted applicant.
    for _, applicantID in ipairs(applicants) do
        if not self.notifiedApplicants[applicantID] then
            self.notifiedApplicants[applicantID] = true
            local blacklisted = GetApplicantBlacklistedMembers(applicantID)
            if blacklisted then
                for _, pd in ipairs(blacklisted) do
                    local tag = LFGBlacklist:ColorizeText("[LFG Blacklist]")
                    local reason = pd.reason and (" — " .. pd.reason) or ""
                    DEFAULT_CHAT_FRAME:AddMessage(tag .. " BLACKLISTED applicant: " .. (pd.name or "?") .. reason)
                end
            end
        end
    end
end

-- ============================================================
-- Hooks
-- ============================================================

function module:HookApplicationViewer()
    local viewer = LFGListFrame and LFGListFrame.ApplicationViewer
    if not viewer then return end

    -- Hook the ScrollBox update methods directly.
    local sb = viewer.ScrollBox
    if sb and not sb._lfgblHooked then
        sb._lfgblHooked = true
        for _, method in ipairs({ "FullUpdate", "Update", "Refresh" }) do
            if type(sb[method]) == "function" then
                hooksecurefunc(sb, method, function()
                    module:DebouncedHighlightApplicants()
                end)
            end
        end
    end

    -- Also hook global update functions if they exist.
    if not self._hookedViewerGlobals then
        self._hookedViewerGlobals = true
        for _, fn in ipairs({
            "LFGListApplicationViewer_UpdateApplicants",
            "LFGListApplicationViewer_UpdateInfo",
            "LFGListApplicationViewer_UpdateResults",
        }) do
            if type(_G[fn]) == "function" then
                hooksecurefunc(fn, function()
                    module:DebouncedHighlightApplicants()
                end)
            end
        end
    end
end

function module:HookSearchPanel()
    if self._hookedSearchPanel then return end
    self._hookedSearchPanel = true

    local sp = LFGListFrame and LFGListFrame.SearchPanel
    local sb = sp and sp.ScrollBox
    if sb and not sb._lfgblHooked then
        sb._lfgblHooked = true
        for _, method in ipairs({ "FullUpdate", "Update", "Refresh" }) do
            if type(sb[method]) == "function" then
                hooksecurefunc(sb, method, function()
                    module:DebouncedHighlightSearch()
                end)
            end
        end
    end

    for _, fn in ipairs({
        "LFGListSearchPanel_UpdateResults",
        "LFGListSearchPanel_UpdateResultList",
        "LFGListSearchEntry_Update",
    }) do
        if type(_G[fn]) == "function" then
            hooksecurefunc(fn, function()
                module:DebouncedHighlightSearch()
            end)
        end
    end
end

-- ============================================================
-- Initialize
-- ============================================================

function module:Initialize()
    if self.hooked then return end
    self.hooked = true

    local lfgEventFrame = CreateFrame("Frame")
    lfgEventFrame:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
    lfgEventFrame:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
    lfgEventFrame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
    lfgEventFrame:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
    lfgEventFrame:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
    lfgEventFrame:SetScript("OnEvent", function(_, event)
        if event == "LFG_LIST_APPLICANT_LIST_UPDATED" or event == "LFG_LIST_APPLICANT_UPDATED" then
            module:DebouncedHighlightApplicants()
            C_Timer.After(0.1, function() module:CheckApplicantsAndNotify() end)
        elseif event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
            if not C_LFGList.HasActiveEntryInfo() then
                wipe(module.notifiedApplicants)
            end
            module:HookApplicationViewer()
            module:DebouncedHighlightApplicants()
        elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" or event == "LFG_LIST_SEARCH_RESULT_UPDATED" then
            module:DebouncedHighlightSearch()
        end
    end)

    -- Hook LFGListFrame.OnShow so we wire up panel hooks as soon as panels are visible.
    if LFGListFrame then
        LFGListFrame:HookScript("OnShow", function()
            module:HookApplicationViewer()
            module:HookSearchPanel()
            C_Timer.After(0.15, function()
                module:HighlightApplicantRows()
                module:HighlightSearchRows()
            end)
        end)
    end

    -- Wire up immediately if frame already exists.
    self:HookApplicationViewer()
    self:HookSearchPanel()

    C_Timer.After(0.2, function()
        module:HighlightApplicantRows()
        module:HighlightSearchRows()
    end)
end

function module:RefreshVisibleEntries()
    self:DebouncedHighlightApplicants()
    self:DebouncedHighlightSearch()
end
