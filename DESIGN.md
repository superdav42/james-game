# Design

## Game board

- The game uses a centered board adjustable from 6×6 through 100×100 while retaining a 600×600 footprint in the 720×1280 mobile viewport.
- Alternating sand-colored squares keep the grid readable without visual clutter.
- Mountains use gray triangular markers.
- Trees use layered green circles and a brown trunk. They conceal enemy units from distant spyglass observation but do not block movement or firing.
- Both teams use circular unit markers: one team is red and the other is blue. Letters `A`, `S`, `T`, and `B` identify artillery, spyglass, turret, and base roles.
- Selecting a unit adds a white ring and highlights every legal destination in green.
- Reachable spyglass squares display coordinates appropriate to the current board size.
- Recent artillery targets use orange impact markers.
- A prominent team-colored label shows whose turn it is.
- Opposing units are hidden unless detected by an active-team spyglass; detected enemies receive a gold reveal ring.

## Interaction

- All primary actions are touch-friendly: tap a unit, then tap a highlighted destination.
- Movement highlights use circular distance: diagonal movement costs more than horizontal or vertical movement without increasing maximum range.
- Players select an artillery, type a target coordinate, and press `FIRE`.
- Selecting a turret makes the same coordinate control fire that turret instead, with a 4-square range.
- One move, artillery shot, or turret shot ends the active team's turn.
- When a team loses its artillery or all of its support units, the turn indicator announces the winner and action controls are disabled until a new map starts.
- A numeric grid-size control regenerates the map at the chosen dimensions.
- Two production buttons let the active team's base create a spyglass unit or turret on an adjacent open square.
- The status line explains selection and invalid moves.
- `NEW RANDOM MAP` regenerates all unit and mountain positions.
