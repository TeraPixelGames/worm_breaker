# Worm Breaker Gameplay UI Mockups

These mockups apply the `godot-game-ui-director` pass to the current gameplay capture at `artifacts/gameplay-current-desktop.png`.

## Current Read

The tunnel, paddle, ball, and signal gate already have strong motion and fantasy. The weak point is operational readability: score, depth, rival pressure, phase, combo, mode, and powerup state are compressed into a small bottom dock far from the paddle/ball action.

## Mockup 01: Signal Cockpit HUD

Recommended first implementation. Move the most important run state into three compact top cells: `SIGNAL`, `DEPTH`, and `PULSE`. Keep the lower dock for rival pressure, mode, and powerup timers. This gives players a quick glance path without covering the tunnel.

## Mockup 02: Targeting Ring Read

Use when misses feel unfair or hard to diagnose. Add a short-lived predictive guide between the pulse and stabilizer, plus contextual chips such as `SLOW 4s` and `MISS RISK`. This should appear only when the guidance is useful, not as constant clutter.

## Mockup 03: Breach Event Layer

Use for signal gate hits, level clear, combo spikes, powerup pickups, and danger states. Replace generic centered messages with brief event cards that explain what just happened and what pressure changed.

## Implementation Recommendation

Start with Mockup 01, then add Mockup 03 as an event-message upgrade. Mockup 02 is valuable, but it changes gameplay perception more directly and should follow once the base HUD hierarchy is improved.
