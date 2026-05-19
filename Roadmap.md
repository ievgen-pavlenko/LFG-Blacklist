# LFG Blacklist — Roadmap

---

## v0.1.0 — MVP ✅

- ✅ Local blacklist database (SavedVariables)
- ✅ Add / remove / check players via slash commands
- ✅ Name normalization (`name-realm`, lowercase)
- ✅ Configurable reasons (Leaver, Toxic, etc.)
- ✅ Config UI — Blacklist, Reasons, Settings tabs
- ✅ Right-click popup on target / party / raid frames
- ✅ Highlight blacklisted leaders in Search panel
- ✅ Highlight blacklisted applicants in ApplicationViewer
- ✅ Chat notification when a blacklisted player applies
- ✅ Tooltip warning on blacklisted players
- ✅ `/lfgbl debug` command

---

## v0.2.0 — Polish (current)

- [ ] Minimap button
- [ ] Search / filter in the Blacklist tab
- [ ] Sort by name / date / reason
- [ ] Editable notes per player
- [ ] Login summary: "X blacklisted players on your realm"
- [ ] `/lfgbl list` — print blacklist to chat

---

## v0.3.0 — Applicant Tools

- [ ] One-click decline from applicant tooltip
- [ ] Auto-decline toggle for blacklisted applicants
- [ ] Reason shown in applicant tooltip (not row — avoids taint)
- [ ] "Add applicant to blacklist" button in ApplicationViewer

---

## v0.4.0 — M+ Tracking

- [ ] Auto-add leaver after dungeon ends without completion
- [ ] Quick blacklist popup on group disband mid-run
- [ ] "Add last group" — bulk-add all recent party members
- [ ] Track key depleted by leaver (note on player record)

---

## v0.5.0 — Data Management

- [ ] Export blacklist to a share string
- [ ] Import blacklist from a share string
- [ ] Prune stale / old entries (configurable age threshold)
- [ ] Per-character vs account-wide DB toggle

---

## v1.0.0 — Stable Release

- [ ] Full localization support (enUS baseline)
- [ ] Performance audit (no frame scans, event-driven only)
- [ ] CurseForge & Wago packaging
- [ ] README & user documentation

---

## Future / Nice-to-Have

> These require significant effort or external dependencies — not committed to any version.

- Guild blacklist sync via addon channel (requires all members to have the addon)
- Sound alert on blacklisted applicant
- Color themes / compact mode
- Raider.IO score display alongside blacklist warning (requires Raider.IO addon API cooperation)

---

## Out of Scope

> Not feasible within the WoW addon API.

- Alt / Battle.net account detection
- Cross-realm shared database without a backend server
- Desktop app / web dashboard
- Automatic backend sync