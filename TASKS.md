# TASKS - worm_breaker

<!-- BEGIN CODEX REVIEW 2026-04-24 -->

## Automated Review - 2026-04-24

Review commands used:
- `audit_repo.ps1 -TargetRepo <game>`
- `verify_repo.ps1 -TargetRepo <game> -Suite unit -GodotBin C:\code\bin\godot.exe`
- `verify-visual-smoke.ps1 -TargetRepo <game> -GodotBin C:\code\bin\godot.exe`

Current state:
- [ ] Adopt premium ArcadeCore UI primitives and update menu/HUD/results screens to use them.

Next implementation tasks:
- [ ] Do a product-specific polish pass: menu/game HUD/results, input feel, and mobile layout.
- [ ] Investigate remaining Godot shutdown RID/resource leak warnings from visual-smoke runs where present.
- [ ] Re-run unit and visual-smoke verification after each fix and update this section with the result.

<!-- END CODEX REVIEW 2026-04-24 -->
