local addonName, LFGBlacklist = ...

_G[addonName] = LFGBlacklist

LFGBlacklist.name = addonName
LFGBlacklist.version = "0.1.1"
LFGBlacklist.moduleOrder = {
    "Tooltip",
    "ConfigUI",
    "PopupMenu",
    "LFGScanner",
    "SlashCommands",
}

LFGBlacklist.defaults = {
    version = 1,
    players = {},
    reasons = {
        { id = "leaver",  label = "Leaver"      },
        { id = "toxic",   label = "Toxic"        },
        { id = "bad",     label = "Bad Player"   },
    },
    settings = {
        highlightLFG = true,
        showTooltip = true,
        autoHideGroups = false,
    },
}

-- Fixed accent color used for all blacklist highlights.
LFGBlacklist.highlightColor = { r = 1.00, g = 0.22, b = 0.22, hex = "ffff3838" }

local eventFrame = CreateFrame("Frame")
LFGBlacklist.eventFrame = eventFrame

function LFGBlacklist:Print(message)
    local prefix = ("|cff40ff80%s|r"):format(self.name)
    print(("%s: %s"):format(prefix, tostring(message or "")))
end

function LFGBlacklist:InitializeModules()
    for _, moduleName in ipairs(self.moduleOrder) do
        local module = self[moduleName]
        if module and type(module.Initialize) == "function" then
            module:Initialize()
        end
    end
end

function LFGBlacklist:ADDON_LOADED(loadedAddonName)
    if loadedAddonName == self.name then
        self:InitializeDatabase()
    elseif loadedAddonName == "Blizzard_GroupFinder" and self.LFGScanner then
        -- Group Finder loads on demand, so the row hook has to wait for this addon.
        self.LFGScanner:Initialize()
    end
end

function LFGBlacklist:PLAYER_LOGIN()
    self:InitializeModules()
end

function LFGBlacklist:LFG_LIST_SEARCH_RESULTS_RECEIVED()
    if self.LFGScanner then
        self.LFGScanner:DebouncedHighlightSearch()
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local handler = LFGBlacklist[event]
    if handler then
        handler(LFGBlacklist, ...)
    end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
