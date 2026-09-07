# Design

## Game board

- The game uses a centered board adjustable from 6×6 through 100×100 within a 600×600 command viewport.
- Kenney's CC0 Tiny Battle pixel art provides cohesive grass, mountain, tree, headquarters, city, scout, vehicle, and infantry graphics. Stationary artillery uses a procedural silver Civil War cannon with wooden wheels.
- Ground details vary deterministically so the battlefield feels natural without obscuring the tactical grid.
- Mountains and trees remain visually distinct at a glance. Trees conceal enemy units from distant radar observation but do not block movement or firing.
- Mountains and trees grow from weighted neighboring cells into separated clusters of at most eight matching tiles, counting diagonal contact. This creates natural formations without producing impassable map-spanning terrain.
- Red and Blue use distinct sprite sets. Compact role badges preserve recognition across all ten unit and structure types.
- Selecting a unit adds a high-contrast white ring, armed artillery receives a cyan ring, detected enemies receive a gold ring, and legal destinations use a green fill and outline.
- Every square in a selected spyglass unit's circular range displays its coordinate, including occupied squares; only open squares receive movement highlights and accept movement.
- Recent targets use animated orange impact markers. Cannon shots add recoil and a muzzle flash before resolving.
- Stationary artillery fire temporarily replaces the command view with a three-second cinematic reenactment image. A warm discharge flash, slow image push, subtle camera vibration, smoke-filled frame, countdown, and explicit `HISTORICAL REENACTMENT` label provide realistic spectacle without implying archival footage exists from the 1860s.
- A prominent team-colored command label includes the turn number and current Movement or Shooting phase.
- Opposing units are hidden unless detected by an active-team Spyglass or Motorcycle, or exposed as a legal direct-attack target.
- Teams deploy in opposing compact regions, but all eight cells around both starting headquarters remain free of initial units and cities. This preserves room around each strategic structure while retaining coherent team placement.

## Interface

- A dark navy command-console theme keeps controls separate from the brighter battlefield and meets high-contrast readability goals.
- The main content remains centered when the browser or device viewport grows beyond the 720×1280 design size.
- Large battlefields can be zoomed up to 1000% and panned by dragging, mouse wheel plus drag, or WASD. `FIT` returns to the full-board view.
- Primary controls retain at least a 42px touch target, and status text uses plain action-oriented feedback.
- A persistent phase button advances from Movement to Shooting and then ends the turn.
- After `END TURN`, a full-screen `OPPONENT'S TURN` transition hides the board for five seconds before the private handoff lets the next commander begin.
- The active treasury, city count, and projected per-turn income replace the decorative subtitle.
- Sound can be disabled at any time. Interface, movement, impact, production, error, and victory cues reinforce visible feedback but are never required to play.

## Interaction

- Movement uses an explicit two-click order: select a unit, then select an arrow-marked destination. This avoids accidental moves and works consistently with mouse or touch input.
- Taps select or move; dragging pans only when zoomed, preventing accidental orders while inspecting large maps.
- Movement highlights use circular distance: diagonal movement costs more than horizontal or vertical movement without increasing maximum range.
- Occupied cells block path traversal for every unit. Mountains block every unit except Spyglass; Spyglass may cross or occupy mountains but cannot pass through friendly or enemy units.
- Units animate tile by tile along the chosen legal route at a brisk, readable speed.
- During Movement, each movable unit may move once and each HQ may produce once. Newly produced units cannot act until the next turn.
- During Shooting, artillery and every Mobile Flank may each make one coordinate shot. Turrets and eligible adjacent-attack units may also attack once.
- Selecting artillery arms unlimited coordinate fire; selecting a Mobile Flank limits the same control to 10 squares; selecting a Turret limits it to 4 squares.
- Artillery and Mobile Flanks can damage any enemy except Tank Destroyers. Turrets damage Spyglass and Grenade Men; Tanks damage adjacent Turrets and Grenade Men; Tank Destroyers damage adjacent Tanks; Grenade Men are the only units that damage Tank Destroyers.
- When a team loses its artillery or all of its support units, the turn indicator announces the winner and action controls are disabled until a new map starts.
- A numeric grid-size control regenerates the map at the chosen dimensions.
- Seven compact shop controls expose all purchasable units and their prices after the active HQ is selected.
- Each team receives `ceil(grid size / 10)` cities, and each surviving city adds `$100` at the beginning of its owner's turn.
- The status line explains selection and invalid moves.
- `GENERATE NEW BATTLEFIELD` regenerates all unit, mountain, and tree positions.
