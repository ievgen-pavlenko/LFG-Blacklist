# Changelog

All notable changes to LFG Blacklist will be documented here.

---

## [0.1.1] — 2026-05-20

### Fixed
- Crash on player remove: `RefreshVisibleEntries` was called but not defined in `LFGScanner`
- Tooltip warning was never shown — `Tooltip:Initialize()` was empty and never hooked into the game tooltip system
- Tooltip now uses `TooltipDataProcessor.AddTooltipPostCall` (WoW 12.0 API) with fallback to `hooksecurefunc(GameTooltip, "SetUnit")`
- Custom `ChatMenu` panel was opening alongside the native WoW context menu on chat right-click — removed in favour of `PopupMenu` which already integrates cleanly into the native menu

---

## [0.1.0] — 2026-05-20

### Added
- Local blacklist database with SavedVariables (`LFGBlacklistDB`)
- Player name normalization to `name-realm` (lowercase, cross-realm safe)
- Configurable reasons: Leaver, Toxic, Bad Player, Ninja Pull, Boost Spam, Ignore
- Highlight blacklisted group leaders in the LFG Search panel
- Highlight blacklisted applicants in the ApplicationViewer (WoW 12.0 ScrollBox compatible)
- Chat notification when a blacklisted player applies to your group
- Tooltip warning when hovering over a blacklisted player
- Right-click popup integration on target, party, and raid frames
- Config window with Blacklist, Reasons, and Settings tabs
- Slash commands: `/lfgbl`, `/lfgbl add`, `/lfgbl remove`, `/lfgbl check`, `/lfgbl debug`