# James Game

A polished Godot 4.7 local hot-seat strategy game played on an adjustable artillery grid.

## Current rules

- Red and Blue begin in opposing compact regions with one stationary artillery cannon (`A`), Spyglass (`S`), Turret (`T`), headquarters (`B`), and one city (`C`) per ten board rows, rounded up. The eight tiles immediately surrounding each starting HQ are reserved and begin without units or cities.
- Each city pays its owner `$100` when that commander begins a turn. The treasury and expected next-turn income remain visible above the board.
- A turn has a **Movement** phase followed by a **Shooting** phase. Press **Begin Shooting** after movement, then **End Turn** after firing.
- During Movement, every movable unit may move once. Movement uses a two-click order: select a unit to display destination arrows, then select an arrow-marked tile to confirm. A brisk tile-by-tile animation follows the selected route.
- During Shooting, stationary artillery may fire once, every Mobile Flank may fire once, and each eligible direct-attack unit may attack once. Firing one unit does not prevent the others from firing.
- Artillery has unlimited coordinate range. Firing opens a three-second cinematic cutaway built from a clearly labelled realistic Civil War artillery reenactment, with flash, smoke, recoil, and camera movement before the shot resolves.
- A direct artillery or Mobile Flank hit removes an opposing unit except a Tank Destroyer; misses leave an impact marker.
- The Spyglass moves within a circular 3-space range and may cross or occupy mountains. It must still route around occupied friendly and enemy tiles. Every square in range displays its coordinate, including occupied squares, but only reachable empty squares are legal destinations.
- The Turret moves 4 and may fire within 4 squares at opposing Spyglass or Grenade Men units.
- Grenade Men move 4 and destroy an adjacent Tank Destroyer.
- Tanks move 3 and destroy an adjacent Turret or Grenade Men unit.
- Motorcycles move 10, scout within 3 squares, display scouting coordinates, and cannot enter or cross mountains.
- Mobile Flanks move 3 and fire at typed coordinates within 10 squares.
- Tank Destroyers move 3 and destroy an adjacent Tank. Only Grenade Men can destroy a Tank Destroyer.
- Movable units may travel horizontally, vertically, or diagonally. All units route around occupied friendly and enemy tiles; every unit except Spyglass also routes around mountains. Diagonal steps use their true longer distance, and no unit may finish on another unit.
- Spyglass units and Motorcycles reveal enemies within 3 squares. An enemy in a tree remains concealed unless a scout is directly adjacent, including diagonally.
- Trees do not block movement or firing.
- Mountains and trees generate as natural-looking connected groups. No connected group contains more than eight matching terrain tiles, including diagonal contact.
- Select an HQ during Movement to buy one unit per turn in an adjacent open square. New units wait until the next turn to move or attack.
- Shop prices are Spyglass `$50`, Turret `$50`, Grenade Men `$75`, Tank `$100`, Motorcycle `$150`, Mobile Flank `$300`, and Tank Destroyer `$300`.
- A team loses immediately if its artillery is destroyed or every unit other than its artillery is destroyed. The opposing team wins.
- Choose a grid size from 6×6 through 100×100, then press **Apply / New Map** to regenerate units, mountains, and trees.
- Large-board coordinates continue after `Z` (`AA`, `AB`, and so on), reaching `CV100` on a 100×100 grid.
- A five-second **Opponent's Turn** screen hides the battlefield after **End Turn**, followed by a private command handoff until the next player is ready.
- Large battlefields support button or mouse-wheel zoom, drag panning, WASD panning, and one-tap **Fit** reset.
- Sound cues reinforce selection, movement, firing, invalid orders, production, and victory; **Sound On/Off** makes all audio optional.

Only the active team's units can be selected. Artillery, Turrets, and Mobile Flanks cannot fire on friendly units.

The game uses a cohesive pixel-art command interface. Compact letter badges keep every role readable at a glance, including `A`, `S`, `T`, `C`, `F`, `K`, `M`, `D`, and `G`.

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
