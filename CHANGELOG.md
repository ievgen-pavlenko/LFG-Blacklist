# Changelog

All notable changes to LFG Blacklist will be documented here.

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