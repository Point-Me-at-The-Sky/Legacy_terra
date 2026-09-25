# Map specification

**Implementation:** `godot/rules/board_map.gd` and `godot/rules/movement.gd` implement the two graphs, state validation, legal movement and support paths. The movement lab includes the starting map and intact/broken transport fixtures below. Standalone combat uses `retreat.gd` with these same graphs. Its separate three-tile fixtures add a friendly retreat tile and have no relics; they are not match setups. Full setup validation, map-to-battle integration, conquest, and relic scoring remain future work.

## Confirmed geometry and movement

D-004: each square tile has exactly four areas in a 2×2 arrangement. Every area is
one planet or one space area; the tile is never a single world.

D-024: movement goes to an adjacent tile and may reach any eligible destination
area there. Ships need no support chain. Ground units require an unbroken line
of friendly planets and space units. P-010 resolves the precise graphs below.

```text
One tile                  Neighboring tile
┌───────────┬───────────┐  ┌───────────┬───────────┐
│ NW        │ NE        │  │ NW        │ NE        │
├───────────┼───────────┤  ├───────────┼───────────┤
│ SW        │ SE        │  │ SW        │ SE        │
└───────────┴───────────┘  └───────────┴───────────┘
```

## Stable data and two separate graphs — selected P-010

| Data | Meaning |
| --- | --- |
| Tile ID | Stable identity independent of label, art, or position |
| Tile position | Integer grid column/row; no duplicate positions |
| Quadrant key | Exactly `nw`, `ne`, `sw`, `se`, once each per tile |
| Area ID | Stable identity such as `tile-a:nw` |
| Area type | `planet` or `space` |
| Static content | Types, display labels, tile references and positions |
| Scenario state | Starting ownership, units, structures, relics and resources |

**Tile-neighbor graph:** `(c1,r1)` and `(c2,r2)` are neighbors when
`abs(c1-c2) + abs(r1-r2) = 1`. No corner adjacency or jumping across missing tiles.
Any space area in one tile can reach any space area in its neighbor in one ship
Dispatch. Ground destinations may be any planet in that neighboring tile, subject
to support. Same-tile Dispatch is excluded under the user's “adjacent squares
always” instruction, rather than silently importing same-system movement.

**Area-support graph:** quadrant cells at tile `(c,r)` have coordinates
NW `(2c,2r)`, NE `(2c+1,2r)`, SW `(2c,2r+1)`, SE `(2c+1,2r+1)`.
Support edges connect existing cells at Manhattan distance one. These edges do
not impose ship range. They determine whether a continuous ground-support path
exists, using current friendly planets and spaces occupied by the mover's ships.
Intermediate enemy/neutral planets, empty spaces, and contested areas break that
path; the final planet may be hostile or neutral. A path may detour through other
tiles, but the movement endpoints must still lie in adjacent tiles.

Ground units end on planets, ships on space. Movement permission and support
occupancy come from rules, not screen coordinates. Expose the returned valid path
in ground-move previews so the player can see which ships enable the move.

## Relic placement — D-018/D-019/D-023 and selected P-012

Each player places `2 × enemy count` relics on their own starting planets, maximum
one per planet. The selected interpretation requires at least two of that player's
relics per **token-bearing tile**, not every tile in the map. A tile can hold at
most four relics; setup must supply enough eligible planets. There is no designated
collector: enemy relics score, own relics do not. Conquest collects permanently.

Two players require two collected relics to win; larger matches require three.
These setup/scoring rules are distinct from relic artwork and tactics-token slots.
An empty geometry preview need not satisfy match setup, but must not be labeled a
valid match scenario. Validate full setup before starting a game.

## Small two-player verification fixture — selected test content

Two side-adjacent tiles: `tile-a` at `(0,0)`, `tile-b` at `(1,0)`.
Both have NW/NE planets and SW/SE space. Player A starts owning both A planets;
player B owns both B planets. Each places one relic on each owned planet. Each
starts with Ground 1 on each planet, Space 1 in its SE area, a production building
on its NW planet, and 5 alloy. A has first initiative. This is a correctness fixture,
not a balanced map or final force composition.

Movement checks can override occupancy explicitly without changing geometry:

- A ship at `tile-a:sw` can move to `tile-b:se` although those areas do not share an edge.
- The directly touching planets `tile-a:ne → tile-b:nw` permit a ground move without
  intervening ships; support chains can consist solely of friendly planets up to
  the final hostile destination.

For an isolated support-path fixture, use `tile-a:nw` as the origin planet and `tile-b:nw`
as the destination planet. All other areas are space. Put A ships at `tile-a:sw`,
`tile-a:se`, and `tile-b:sw`; leave other spaces empty. The sole route is
`tile-a:nw → tile-a:sw → tile-a:se → tile-b:sw → tile-b:nw`. Removing any one of those ships blocks it;
adding alternative support can restore a route. This separate geometry fixture
has no relic setup and is not a playable scenario.

## Validation and presentation

Validate unique IDs/positions, exactly four quadrant keys, valid types/references,
symmetric graphs without self-links, and domain-correct entity placement. Distinguish
physical graph connectivity from legal support reachability. Verify a non-edge
ship move, blocked/supported ground moves, diagonal tile rejection, same-tile
rejection, and execution-time support changes. Relic validation checks counts,
starting ownership, one per planet, and the selected per-tile minimum.

Render outer tile borders, quadrant dividers, readable type/ownership labels,
units/structures, separate relic markers, and keyboard-accessible selection.
Show all rule-legal destinations in a neighboring tile, not just touching areas.
Retreat highlighting uses its own legal-action result. The small map does not
choose final tile count, faction balance, planet density, portals, or map rotation.
