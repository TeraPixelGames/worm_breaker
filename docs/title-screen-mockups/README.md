# Worm Breaker Title Screen Mockups

These mockups apply the `godot-game-ui-director` title-screen guidance to the current Worm Breaker fantasy: a signal tunnel, stabilizer control, rival pressure, and stability versus overdrive run choice.

## Mockup 01: Cinematic Signal Prompt

Use when the title art should dominate. This is the simplest title-screen read: world image first, one hot launch prompt second, progress chips at the edge.

## Mockup 02: Asymmetric Launch Deck

Use when the menu must support multiple actions without losing momentum. The launch deck is the primary structure, while live run context sits off to the right.

## Mockup 03: Mode Select Tactical Board

Use when Stability and Overdrive should feel like meaningful run profiles. The selected run gets the dominant detail bay and launch action; other modes become compact secondary choices.

## Recommendation

Mockup 02 is the strongest next implementation target. It improves the current launch deck without turning the screen into a mode-selection dashboard, and it maps cleanly to the existing `StartButton`, `OverdriveButton`, `TutorialButton`, and `QuitButton` node contract.
