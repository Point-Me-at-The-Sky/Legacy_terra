# Roadmap

Updated: 2026-09-18. Checkboxes mean delivered work, not final design approval.
P-series **selected experiments** are usable implementation defaults under the
user's request to resolve gaps using Forbidden Stars. They remain revisable.

## Current state

- [x] Playable browser baseline: one person versus AI on eight world nodes.
- [x] Design document, decision log, architecture, rules, map specification, and checks.
- [x] Repeatable design-document generation and freshness/link checks.
- [x] Confirmed setting: humans introduced magic by breaking the universe; alien and human-remnant factions compete for relics amid advanced technology.
- [x] Confirmed simultaneous tactics-token planning and four-quadrant square tiles.
- [x] Confirmed production categories, three structure roles, four faction rosters, and advancement thresholds.
- [x] Confirmed unit stats and three-round dice/card battles, attacker-first resolution and ties, temporary damage and persistent routing.
- [x] Confirmed relic collection on conquest: two relics win with two players, otherwise three.
- [x] Confirmed adjacent-tile movement: ships move without support paths; ground units need continuous friendly support.
- [x] Official Forbidden Stars rules reviewed; selected v0.2 choices, original test content, map fixtures, and a worked battle recorded.
- [x] Godot 4.7.2 project with typed GDScript and Compatibility rendering (D-025).
- [x] Tile map, dual topology graphs, unit instances, route previews, and unopposed movement lab implemented and tested.
- [x] Standalone battle sequence and retreat implemented, with a playable battle lab and a permitted-view opponent.
- [ ] Production, construction-history advancement, and relic victory implemented.
- [ ] Simultaneous private planning and common human/AI validation implemented.
- [ ] Full faction content, balance, and polished Godot skirmish implemented.

## Readiness after the reference review

**Ready for implementation:** the old two-player relic conflict is resolved by
D-023. D-024 fixes movement range; P-009–P-012 fill the previously open mechanical
choices. `RULES.md` is the current experimental specification, including explicit
formulas, timings, test values, and expected results. Do not ask again about a
selected rule merely because an older revision called it open.

Start with a small fixture, not all faction content. The remaining work is to
implement and verify the selected choices, then evaluate their balance. Final
faction identities, relic art, extra cards, and production map sizes are not
prerequisites. D-025 starts development directly in Godot with GDScript; version
4.7.2 is pinned. Preserve the browser baseline as a historical reference.

Two deliberate adaptations deserve early playtesting: persistent routing paired
with fresh dice each round, and adjacent-tile-only movement without same-tile
rearrangement. Test that units do not become trapped by layout or loss of transport
support. The chosen relic-tile interpretation must also remain visible in setup UI.

## Delivered: Godot map and movement lab

`godot/` contains stable tile/area IDs, four areas per tile, geometry validation,
unit selection, tile-neighbor and area-support graphs, and the starting/intact/broken
fixtures from `MAP_DESIGN.md`. The lab can execute unopposed moves and occupy empty
planets; it blocks combat, relic collection, and hostile structure capture. Both
player selectors share the rules interface. This is not a complete match.

Verified: 100 headless checks cover geometry/state validation, range versus support,
ownership and routing, alternate/broken paths, immutable transitions, and scene
interaction/focus. Graphical starting-board and transport-path captures were checked
for readability. Full-match setup and balance remain unverified.

## Delivered: combat and retreat fixtures

Scene-independent GDScript implements the six-card test deck, shared ground/space
battle sequence, owner damage assignment, persistent routing, final leadership,
defense buildings, and retreat. A rules-owned seeded RNG supports replay. Filtered
player views and shared legal actions serve the human and deterministic battle policy.
The Battle lab offers ground, space, and structure-only defense scenarios.

Verified: the worked three-round tie and damage examples match `RULES.md`;
routing survives damage reset; required-unit effects use the correct instant;
retreat paths and no-path outcomes match; both damage totals resolve even on
mutual destruction. Hidden cards stay private; no input-state mutation or preview
consumption of authoritative randomness. Finished states reject repeated commands
and resolved battle IDs cannot be restarted in the returned world. Strategic token
resumption is not implemented. Conquest must consume the returned combat result
atomically; neither lab applies partial ownership or relic changes.

## Next: production, conquest, and relic rules

Implement P-011/P-012 with the small test content: production destinations and costs,
construction-history advancement, starting relic validation, structure capture,
and conquest/collection/victory as one transaction. Connect completed battle outcomes
to conquest before enabling attacks in a match.

Acceptance: wrong-domain/facility production is rejected; construction credit survives
loss and cannot be farmed by rebuilding; two/three relic thresholds match player count;
own relics never score; collection cannot repeat; victory stops further actions.

## Then: playable board and one complete tactics cycle

Connect the verified rules to the map. Implement P-001–P-004: three private numbered
tokens, locked commitment, reveal after all commitments, alternating slot resolution,
and rotating initiative. Human and AI must receive the same legal choices and
permitted information. Avoid reproducing the legacy future-origin planning mismatch;
both controllers must have equivalent planning privileges in Godot.

Acceptance: complete the two-player fixture through relic victory; a battle pauses
and resumes one token exactly once; a failed token causes no partial movement or
cost; early commitment leaks nothing; AI cannot inspect opposing plans/hands;
submission order does not change priority; victory stops further actions. Verify
movement, production, combat, retreat, relic display, readable text and keyboard
focus in Godot. Keep the old browser game available as a reference.

## Then: playtest and revise selected defaults

Use paired matches with reversed initiative. Measure card choices, attacker advantage,
routing frequency, movement/retreat bottlenecks, relic contestability, and match
length. Explicitly amend selected experiments when evidence warrants it. Do not
turn a fixture stat or reference mechanic into a permanent requirement by accident.

## Later

1. Full faction rosters, original cards, structure tuning, and balanced maps.
2. Polish the Godot solo skirmish with tutorial and save/resume.
3. Refine AI, accessibility, presentation, and balance.
4. Add private online matches with authoritative state and hidden-information handling.

Shared stacks, extra resources, standalone magic subsystems, campaigns, and ranked
play remain outside the immediate slice. The completed movement and battle labs
are implementation milestones, not a complete or balanced match.
