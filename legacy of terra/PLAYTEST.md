# Verification and playtest notes

The Godot movement and battle labs implement map/movement and standalone combat/retreat
from v0.2. `npm run godot:test` verifies movement, battle rules, hidden information,
seeded replay, deck lifecycle, and UI flows through all three battle scenarios.
Graphical movement, card-choice, and outcome captures are checked at 1280×800.
These are automated and visual smoke checks, not human balance playtests or a full
accessibility review. See the test command output for the current assertion count.

`npm test` covers only the legacy browser. No full-match playtest results exist yet.
Production, relics, strategic refresh, and complete-cycle scenarios remain acceptance
criteria for future implementation. Battle outcome consumption and strategic resumption
cannot be tested until their integration exists.

Run the lab through `npm run godot:run`. To reproduce screenshots with a graphical
display, run the pinned executable with `--path godot --script res://tests/visual_smoke.gd
-- --capture-dir=/path/to/output`. The output directory must exist. Screenshots are
local verification artifacts, not source assets.

## Map and movement fixtures

Use the two graphs and isolated support fixture in `MAP_DESIGN.md`.
The headless suite checks range, friendly/hostile support, broken and alternate paths,
routing restrictions, and execution-time revalidation. Token consumption is not
implemented; the lab instead rejects invalid moves without changing state.

| Scenario | Expected outcome |
| --- | --- |
| Ship between non-touching areas in neighboring tiles | Legal when both endpoints are space; no support chain needed |
| Normal move within the same tile or to a diagonal tile | Rejected by selected P-010 |
| Ground path through friendly planets and occupied friendly space | Legal to a planet in an adjacent tile, including a hostile final planet |
| Remove a necessary support ship before execution | Token fails unless another valid path exists; no partial movement |
| Ship attempts planet destination / ground unit attempts space destination | Rejected |
| Longer friendly support detour | Permitted, but cannot extend destination beyond adjacent tiles |
| Ground path uses empty/enemy space or an intermediate nonfriendly planet | Rejected |
| Routed ship provides support but attempts Dispatch | Support persists; normal movement rejected |

## Battle fixtures

The Godot battle suite verifies the worked battle in both ground and space domains,
the damage examples, prerequisite checks, defense buildings, retreat, privacy,
replay, immutable transitions, and rejection of repeated terminal actions. The lab
opponent and human controls consume the same legal-action/player-view interface.

| Scenario | Expected outcome |
| --- | --- |
| Three-round worked battle | Banks finish 5 and 6; defender routes; final totals 6–6; attacker wins |
| Round-one nonlethal damage | Unit routes, damage clears at round end, routing persists to strategic refresh |
| Routed/dead prerequisite unit | Conditional effect fails; base bonus still applies |
| Future attacker effect changes defender prerequisite before defender resolves | Check defender requirement at its effect's actual resolution time; no initial card changes enemy prerequisites, so this remains a future-content scenario |
| Leadership banking | Credit each dice/card bonus once; unit leadership is added once after final damage |
| 4 damage to two health-3 units | Chosen first unit dies, second takes 1 and routes |
| Both health-3 last units receive 3 damage | Resolve both totals; neither wins or collects a relic |
| Losing ground unit with legal friendly retreat path | Retreat to the selected eligible planet; become routed |
| Losing ship | Retreat to eligible space; never a planet |
| No legal retreat destination | Surviving loser destroyed |
| Same player fights twice before strategic refresh | Routed state persists; deck/hand reset follows P-009 |
| Defense building fights alone | Uses P-011 combat values, cannot rout, and cannot enable a unit prerequisite |

Covered: hidden simultaneous choices, attacker-first resolution, public rolls,
seeded replay, and previews/rejections preserving authoritative state and RNG.
Terminal commands and duplicate battle IDs are rejected in the returned state.
Full strategic application of a result exactly once remains an integration check.

## Production and advancement fixtures

Reject wrong-domain production, enemy production destinations, insufficient funds,
and a facility in the wrong tile. Build exactly one purchase, and charge once.
Building a structure does not require a production facility. Enforce one instance
of each structure type per planet. With qualifying construction sites 0/1/2,
verify ground access 1/1–2/1–3 and space access 1/1/1–2 for every faction placeholder.
Capturing or rebuilding a previously credited advancement site does not add credit;
losing it does not remove credit. Both controllers see identical eligibility.

## Relic and setup fixtures

Two/three/four-player setup places two/four/six relics per player respectively.
Reject duplicate planet placement, nonstarting planets, wrong total counts, and
fewer than two of a player's relics on one of that player's token-bearing tiles.
Non-token-bearing tiles need not contain relics. Scenario setup must provide enough
eligible planets and enemy relics; map-only previews are not match fixtures.

For two players, one collected relic does not win and the second does. For larger
matches, two do not win and the third does. Conquest collects only an opponent's
remaining relic; reconquest of one's own relic does not score. Collected relics
leave the board, remain credited, and cannot be collected twice. Retreat and
production do not collect. Victory is checked in the conquest transaction and
stops later tokens. Multi-player cases here are data/rule tests, not authorization
to implement networking or expand the initial one-person-versus-AI interface.

## Complete-cycle and interface checks

Verify commitment locking, reveal only after everyone commits, equivalent human/AI
planning privileges, failed tokens without partial effects, correct initiative,
and exactly-once battle resumption or game completion. Play the small two-player
map through victory after integration. Check legal destination highlights, shown
ground-support paths, relics distinct from tactics tokens, damage versus routing,
banked versus unit leadership, readable text, and keyboard focus.

Legacy v0.1 worked outcomes remain in `RULES_LEGACY.md` for historical comparison
only; do not reuse planet-built ships, attrition, influence, or cycle-eight victory
as acceptance criteria for the new game.

## Playtest procedure and session template

Run paired matches with initiative swapped. Change one selected rule family at a
time; separate rule confusion from UI faults, AI weaknesses, and balance. Track
attacker advantage, supported movement opportunities, failed retreats, routing,
relic collection times, useful card choices, and match duration.

```text
Date / tester:
Revision / selected experiment IDs:
Map / factions / starting initiative / AI policy:
Question being tested:
Duration / cycles / winner:
First conflict:
Relic collections / timing:
Battle duration / useful choices / routing:
Movement bottlenecks / failed retreat reasons:
Failed tokens and reasons:
Confusing feedback / focus or readability issues:
Player explanation of outcome:
Proposed revision and supporting observations:
```
