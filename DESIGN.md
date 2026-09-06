# Design

## Game board

- The game uses a centered board adjustable from 6×6 through 100×100 within a 600×600 command viewport.
- Kenney's CC0 Tiny Battle pixel art provides cohesive grass, mountain, tree, headquarters, artillery, radar, and turret graphics.
- Ground details vary deterministically so the battlefield feels natural without obscuring the tactical grid.
- Mountains and trees remain visually distinct at a glance. Trees conceal enemy units from distant radar observation but do not block movement or firing.
- Red and Blue use distinct sprite sets. Compact `A`, `S`, `T`, and `B` badges preserve role recognition when sprites are unfamiliar.
- Selecting a unit adds a high-contrast white ring, armed artillery receives a cyan ring, detected enemies receive a gold ring, and legal destinations use a green fill and outline.
- Reachable spyglass squares display coordinates appropriate to the current board size.
- Recent targets use animated orange impact markers.
- A prominent team-colored command label includes the turn number.
- Opposing units are hidden unless detected by an active-team spyglass.

## Interface

- A dark navy command-console theme keeps controls separate from the brighter battlefield and meets high-contrast readability goals.
- The main content remains centered when the browser or device viewport grows beyond the 720×1280 design size.
- Large battlefields can be zoomed up to 1000% and panned by dragging, mouse wheel plus drag, or WASD. `FIT` returns to the full-board view.
- Primary controls retain at least a 42px touch target, and status text uses plain action-oriented feedback.
- A full-screen private handoff hides the board between local players until the next commander explicitly begins their turn.
- Sound can be disabled at any time. Interface, movement, impact, production, error, and victory cues reinforce visible feedback but are never required to play.

## Interaction

- All primary actions are touch-friendly: tap a unit, then tap a highlighted destination.
- Taps select or move; dragging pans only when zoomed, preventing accidental orders while inspecting large maps.
- Movement highlights use circular distance: diagonal movement costs more than horizontal or vertical movement without increasing maximum range.
- Players select an artillery, type a target coordinate, and press `FIRE`.
- Selecting a turret makes the same coordinate control fire that turret instead, with a 4-square range.
- One move, artillery shot, or turret shot ends the active team's turn.
- When a team loses its artillery or all of its support units, the turn indicator announces the winner and action controls are disabled until a new map starts.
- A numeric grid-size control regenerates the map at the chosen dimensions.
- Two production buttons let the active team's base create a spyglass unit or turret on an adjacent open square.
- The status line explains selection and invalid moves.
- `GENERATE NEW BATTLEFIELD` regenerates all unit, mountain, and tree positions.
