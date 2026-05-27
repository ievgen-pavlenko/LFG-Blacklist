# Changelog

All notable changes to LFG Blacklist will be documented here.

---

## [0.1.2] — 2026-05-27

### Fixed
- Fixed errors and missing highlights when browsing LFG groups or reviewing applicants while inside a dungeon or instance

---

## [0.1.1] — 2026-05-21

### Fixed
- Minimized release package size by fixing `pkgmeta.yaml` ignore list (corrected indentation and filename casing) to properly exclude `img/`, `README.md`, `Roadmap.md`, and `pkgmeta.yaml` from the zip

---

## [0.1.0] — 2026-05-20

### Added
- Local blacklist of players with configurable reasons (Leaver, Toxic, Bad Player, and more)
- Highlight blacklisted group leaders in the LFG Search panel
- Highlight blacklisted applicants in the ApplicationViewer
- Chat notification when a blacklisted player applies to your group
- Right-click popup menu on target, party, and raid frames to add/remove players
- Config window with Blacklist, Reasons, and Settings tabs
- Slash commands: `/lfgbl`, `/lfgbl add`, `/lfgbl remove`, `/lfgbl check`