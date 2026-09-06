# James Game

A polished Godot 4.7 local hot-seat strategy game played on an adjustable artillery grid.

## Current rules

- Red and Blue each begin with one artillery (`A`), spyglass unit (`S`), turret (`T`), and base (`B`).
- Each team sees its own units and enemies detected by its spyglass units.
- Red moves first, then play alternates between Red and Blue.
- Moving a unit, firing artillery, or firing a turret ends the active team's turn.
- Artillery is stationary and has unlimited range across the current board. Select it, enter a coordinate, and press **Fire**.
- A direct artillery hit removes an opposing unit; misses leave an impact marker.
- The spyglass unit moves within a circular 3-space range and can cross or occupy mountains. Its reachable squares display their coordinates.
- The turret moves within a circular 4-space range and must travel around mountains. Diagonal steps use their true longer distance.
- Instead of moving, a turret can fire at a typed coordinate within 4 squares. It only damages an opposing spyglass unit.
- Spyglass units and turrets can move horizontally, vertically, or diagonally.
- Units cannot finish a move on another unit.
- A spyglass reveals enemies within its 3-space movement radius. An enemy in a tree is concealed unless a spyglass is directly adjacent, including diagonally.
- Trees do not block movement or firing.
- A base can produce additional spyglass units or turrets in an adjacent open square. Production consumes the team's turn.
- A team loses immediately if its artillery is destroyed or every unit other than its artillery is destroyed. The opposing team wins.
- Choose a grid size from 6×6 through 100×100, then press **Apply / New Map** to regenerate units, mountains, and trees.
- Large-board coordinates continue after `Z` (`AA`, `AB`, and so on), reaching `CV100` on a 100×100 grid.
- A private command handoff hides the battlefield between turns until the next player is ready.
- Large battlefields support button or mouse-wheel zoom, drag panning, WASD panning, and one-tap **Fit** reset.
- Sound cues reinforce selection, movement, firing, invalid orders, production, and victory; **Sound On/Off** makes all audio optional.

Only the active team's units can be selected. Tap a movable unit to show its legal destinations, then tap a highlighted square. Artillery cannot fire on friendly units.

The game uses a cohesive pixel-art command interface. The radar-dish sprite is the spyglass unit (`S`), the tank is the movable turret (`T`), the command building is the base (`B`), and the fixed gun emplacement is artillery (`A`).

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
- `assets/kenney/`: selected CC0 battlefield graphics, sound effects, and original license files.
- `THIRD_PARTY_ASSETS.md`: asset provenance and license summary.
- `docs/mobile-notes.md`: next steps for Android/iOS export setup.
