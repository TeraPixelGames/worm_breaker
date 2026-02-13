# WormBreak

WormBreak is a Godot 4.x tunnel brick-breaker.  
You clear surface-aligned bricks on the inside of a 360-degree cylinder and advance through levels.

## Highlights

- Deterministic ball simulation in `(theta, z)` surface coordinates
- Wrap-aware angular collision math across the `-PI/PI` seam
- Paddle rotation via keyboard and touch drag
- 3 JSON levels with progression and save data
- Headless test runner for core math and collision logic

## Run

- Open `project.godot` in Godot 4.x.
- Press Play.

## Run Tests

- `godot4 --headless --path . --script res://tests/run_tests.gd`

## Deploy To GitHub Pages

- Workflow file: `.github/workflows/deploy-pages.yml`
- Trigger: push to `main` or `master` (or manual run from Actions tab)
- Build target: Godot Web export preset (`export_presets.cfg`, preset name `Web`)
- Output: `build/web`

After first push:

1. Open repository settings on GitHub.
2. Go to `Pages`.
3. Set source to `GitHub Actions` (if not already set).

The site will be published at:

- `https://<owner>.github.io/<repo>/`
