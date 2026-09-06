# James Game

A Godot 4.7 mobile strategy prototype played on an adjustable artillery grid.

## Current rules

- Red and Blue each begin with one artillery (`A`), spyglass unit (`S`), turret (`T`), and base (`B`).
- Each team sees only its own units during its turn.
- Red moves first, then play alternates between Red and Blue.
- Moving a unit, firing artillery, or firing a turret ends the active team's turn.
- Artillery is stationary and has unlimited range across the current board. Select it, enter a coordinate, and press **Fire**.
- A direct artillery hit removes an opposing unit; misses leave an impact marker.
- The spyglass unit moves up to 3 grid spaces and can cross or occupy mountains. Its reachable squares display their coordinates.
- The turret moves up to 4 grid spaces and must travel around mountains.
- Instead of moving, a turret can fire at a typed coordinate within 4 squares. It only damages an opposing spyglass unit.
- Spyglass units and turrets can move horizontally, vertically, or diagonally.
- Units cannot finish a move on another unit.
- Trees are decorative and do not affect movement or firing.
- A base can produce additional spyglass units or turrets in an adjacent open square. Production consumes the team's turn.
- A team loses immediately if its artillery is destroyed or every unit other than its artillery is destroyed. The opposing team wins.
- Choose a grid size from 6×6 through 100×100, then press **Apply / New Map** to regenerate units, mountains, and trees.
- Large-board coordinates continue after `Z` (`AA`, `AB`, and so on), reaching `CV100` on a 100×100 grid.

Only the active team's units can be selected. Tap a movable unit to show its legal destinations, then tap a highlighted square. Artillery cannot fire on friendly units.

## Requirements

- Godot 4.7.x

## Run locally

Run: `godot --path .`

Headless smoke check: `godot --headless --path . --quit-after 1`

Web export: `godot --headless --path . --export-release Web build/index.html`

Pushes to `main` build and deploy the web export through `.github/workflows/pages.yml`.

## Project layout

- `project.godot`: mobile-oriented project settings.
- `export_presets.cfg`: reproducible web export configuration.
- `.github/workflows/pages.yml`: GitHub Pages build and deployment workflow.
- `scenes/main.tscn`: main board and interface scene.
- `scripts/main.gd`: board generation, rendering, selection, and movement rules.
- `docs/mobile-notes.md`: next steps for Android/iOS export setup.
