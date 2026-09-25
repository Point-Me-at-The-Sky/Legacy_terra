# Decision log

Updated: 2026-09-18.

**Confirmed** means an established requirement. **Proposed** means a reversible
design default for an experiment. **Open** means no rule has been selected.
**Selected experiment** means an assistant-resolved default for the next prototype, under the user’s request to resolve gaps using Forbidden Stars; it is usable for implementation but remains revisable, not a new user-confirmed requirement.
**Implemented** describes code and does not imply final design approval.
**Superseded** preserves history but must not drive new implementation.
Architecture guidance and test fixtures are engineering choices, not new game rules.

## Confirmed direction

| ID | Decision | Basis and consequence |
| --- | --- | --- |
| D-001 | Title: Legacy of Terra; original strategy game inspired by Forbidden Stars | Existing project direction recorded in the game design document. Use original setting and content. |
| D-002 | Single-player against AI first; online multiplayer later; Godot is the active engine | D-025 starts direct Godot development; browser remains a legacy reference. |
| D-003 | Players place tactics tokens simultaneously to define their actions | Explicit user requirement. Planning must not require alternating token-placement turns. Resolution timing is separate. |
| D-004 | The map consists of squares; each square contains four quadrants, each a planet or space area | Explicit user requirement. Use square tiles subdivided into a 2×2 arrangement of areas. Tile arrangement and movement remain design choices. |
| D-005 | Ground units and structures are built on planets; spaceships are built in space areas | Explicit user clarification, 2026-09-18. Production eligibility must distinguish area and entity types. D-024 defines movement; selected experiments P-009–P-012 specify initial costs, facility reach, and transport details; D-008 establishes the required structure roles. |
| D-006 | All fighting resolves through card battles; each player has one combat deck shared across battle types | Explicit user clarification, 2026-09-18. Ground and space combat use the same battle framework; any future bombardment must respect it. |
| D-007 | Dice plus cards; original unit-count-plus-strength wording superseded by D-011 | Explicit user direction, 2026-09-18. D-011 clarifies the unit dice contribution as attack, superseding the undefined unit-count-plus-strength formula. D-012 defines dice result categories and three rounds; P-009 selects initial dice and timing rules; adopting Forbidden Stars verbatim is not confirmed. |
| D-008 | Small structure catalogue with defense, production, and advanced-unit access roles | User requirement, 2026-09-18: limit structures to 3–4, interpreted as types (not a per-planet/player cap). One improves defense; one is required for ground/space unit production; one unlocks higher-level units. A fourth role is optional and open. All remain planet-built under D-005. |
| D-009 | Four starting factions, each with three ground unit types and two space unit types | Explicit user requirement. One type per tier: ground 1–3 and space 1–2. Names, final stat values, roles, and eventual match player count remain open; test forces and values are specified in P-011 and the map fixture; D-011 defines the three stats. |
| D-010 | Ground/space tier 1 are initially unlocked; ground tier 2 requires one built advancement structure; ground tier 3 and space tier 2 require two | Explicit user requirement. Advancement is the existing advanced-unit-access structure type. Production prerequisites still apply at every tier. P-011 selects construction-history handling for the prototype. |
| D-011 | Units have exactly three stats: attack, health, and leadership | Explicit user requirement, 2026-09-18. Attack is the number of dice a unit rolls in battle; health is how much damage it takes before dying. D-012 defines leadership’s victory role; P-011 supplies test values; final faction values remain open. Attack clarifies and supersedes D-007’s undefined unit-count-plus-strength formula; do not add a separate base die per unit. |
| D-012 | Three-round card-and-dice battles; leadership decides when both sides survive | Explicit user requirement, 2026-09-18. Each player plays one card and rolls dice each round. Dice add attack, defense (one cancels one enemy attack), or leadership. After battle, if both sides have living units, higher leadership wins. D-015 settles accumulation, final comparison timing, attacker-first card resolution, and attacker tie advantage. P-009 selects contribution accounting, remaining effect order, and battle completion for the prototype. |
| D-013 | Cards add damage, defense, or leadership and may have unit-dependent special effects | Explicit user requirement, 2026-09-18. Special effects require the specified units to participate on the player’s side of the battle. P-009 selects condition timing; individual card content remains experimental. |
| D-014 | Check damage and deaths every round; damaged surviving units lose their leadership contribution for the rest of that round | Explicit user requirement, 2026-09-18. Suppression applies to the damaged unit’s leadership contribution. D-015/D-016 add final comparison timing, temporary damage, and persistent routing. P-009 interprets nonlethal damage as persistent routing, replacing the earlier assumption that unit leadership necessarily recovers next round. |
| D-015 | Accumulate leadership across rounds; compare after final damage; attacker resolves cards first and wins leadership ties | Explicit user requirement, 2026-09-18. Leadership is compared only at battle end when both sides survive. P-009 selects unit-versus-dice/card accounting and secret card commitment; attacker-first resolution remains confirmed. |
| D-016 | Damage lasts one turn; routing persists from the turn it occurs | Explicit user requirement, 2026-09-18. P-009 selects “turn” as battle round and defines persistent routing; this is an experiment interpretation. Resetting damage must not automatically clear routing. |
| D-017 | Surviving units may retreat to a nearby planet along a valid path | Explicit user requirement, 2026-09-18. P-009/P-010 select retreat details; ships retreat to space, ground units to planets. |
| D-018 | Win by collecting objective tokens placed on starting planets | Explicit user requirement, 2026-09-18. Each player places two tokens per enemy player on their own starting planets; at most one per planet and at least two per tile. D-019 sets collection by conquest and victory at three collected tokens. D-023 resolves two-player feasibility; P-012 selects tile scope and relic eligibility. These are distinct from tactics tokens; legacy influence scoring is not the intended victory model. |
| D-019 | Conquer an objective planet to collect its token; collecting three wins the game | Explicit user clarification, 2026-09-18. Victory occurs upon reaching three collected tokens. “Objective/victory tile” means the collectible token, not a map tile. D-023 supersedes this threshold for two players only: collect two. Three remains the threshold for larger matches. |
| D-020 | Humanity is the incredibly advanced precursor civilization, now long gone | Explicit user requirement, 2026-09-18. D-021/D-022 clarify its legacy: humans introduced magic by breaking the universe, and human offshoots/remnants may survive as factions. “Long gone” refers to the ancient precursor civilization, not a prohibition on all human-derived beings. Exact disappearance history remains open. |
| D-021 | Magic did not originally exist; ancient humans broke the universe and introduced it | Explicit user lore, 2026-09-18. Magic and highly advanced technology now coexist. Warhammer 40,000 is a reference for that coexistence, not an adopted setting or rules system. The human act, mechanism, timeline, and relationship to their civilization’s disappearance remain unspecified. |
| D-022 | Factions include aliens and may include strange human offshoots/remnants; victory objectives are relics | Explicit user lore, 2026-09-18. Relics are the objective tokens of D-018/D-019, collected by planetary conquest; D-023 sets two to win with two players, otherwise three. Specific faction identities, relic forms, and magical abilities remain open. This adds no new unit stat, resource, or collection requirement. |
| D-023 | Two-player games require two collected relics to win | Explicit user clarification, 2026-09-18. Larger games retain D-019’s three-relic threshold. Setup still places two relics per enemy; the two-player shortage is resolved. |
| D-024 | Movement goes to an adjacent square tile, with access to all its eligible areas; ships need no transport chain, ground units need an unbroken line of space units and friendly planets | Explicit user clarification, 2026-09-18. Replaces P-005 as a movement-range rule. P-010 specifies tile neighbors and the separate ground-support graph; it does not collapse a tile into one area. |
| D-025 | Start the game directly in Godot using GDScript | Explicit user approval, 2026-09-18. Engineering choices: typed GDScript, Compatibility rendering, and Godot 4.7.2 standard edition as the current version pin. These are revisable implementation choices, not additional user-approved gameplay requirements. Keep browser code as reference, not a parallel new-rules implementation. |

## Proposed and selected experiments

These are assistant-authored defaults, not additional confirmed requirements. P-001–P-004 and P-009–P-012 are selected for the next prototype under the user’s request to resolve the gaps. Source references, adaptations, and original fixture values are in `RULES.md`; do not adopt unrelated Forbidden Stars rules.

| ID | Proposal | Reason / evaluation |
| --- | --- | --- |
| P-001 | Three tactics tokens per faction each cycle; Dispatch, Build, Extract; repeats allowed | Reuse the small prototype action set while testing simultaneous placement. |
| P-002 | Private planning, locked commitment, reveal all plans after everyone commits | Make anticipation testable without exposing a player's plan to the opponent or AI. |
| P-003 | Explicit slots 1–3, alternating resolution, rotating initiative | Give simultaneous plans a deterministic resolution order independent of placement speed. Supersedes reversed queue order only in the new experiment. |
| P-004 | Each token commits its origin quadrant, action, and all action parameters | Establish a fully specified first experiment. Compare with choosing Dispatch details during execution later. |
| P-005 | Superseded as movement range by D-024 | Retain edge-sharing area geometry only for the support-path graph (P-010). Ships may reach non-edge-adjacent space areas in a neighboring tile. |
| P-006 | Superseded production proposal: fleets everywhere and ships built on planets | D-005 replaces production eligibility. Retain v0.1 only as a historical sequencing fixture; movement rules need revision. |
| P-007 | Economy remains experimental; relay victory, match limits, and attrition are legacy defaults | D-006/D-007 supersede attrition; D-018 selects objective-token collection over relay influence as the intended victory model. Do not carry over elimination or cycle limits without a decision. |
| P-008 | Superseded battle-length comparison | D-012 confirms three rounds with a card and dice each round. The earlier short-battle comparison and initial-roll-only proposal are superseded. Secret simultaneous card commitment is selected in P-009; resolution stays attacker-first. |
| P-009 | Selected: complete battle sequence, routing, damage, leadership, cards, and retreat | Reference-informed adaptation in `RULES.md`; preserves fresh dice each round, attacker ties, and accumulated leadership. Standalone combat/retreat is implemented; conquest and strategic resumption remain future integration work. |
| P-010 | Selected: two topology graphs, domain-specific movement and retreat | Tile range uses D-024; ground support uses edge-connected friendly areas. No same-tile Dispatch in this slice because the user specified adjacent tiles. |
| P-011 | Selected: small production and economy fixture | Same-tile facility reach; original test costs/stats and construction-history unlocks. These are reversible balance choices, not imported faction data. |
| P-012 | Selected: generic enemy relics and token-bearing-tile minimum | No designated collector; own relics never score; collected relics leave the board permanently. At least two per player on each tile where that player places relics. |

## Decision disposition

| ID | Question | When it matters |
| --- | --- | --- |
| O-001 | Private slots or shared tile stacks? | P-001–P-004 selected for first prototype; shared stacks deferred. |
| O-002 | Full commitment or execution-time choices? | Full commitment selected; damage assignment and retreat remain battle choices. |
| O-003 | Final map layout, size, and starting balance? | A verification fixture is specified in `MAP_DESIGN.md`; production map balance remains open. |
| O-004 | Movement, transport, ownership? | D-024 plus P-010 resolves first prototype behavior; no separate orbit state. |
| O-005 | Relic eligibility and two-player feasibility? | D-023 resolves threshold; P-012 selects eligibility. No separate elimination victory or turn limit selected. |
| O-006 | Godot version and GDScript versus C#? | Resolved by D-025: typed GDScript; current pin 4.7.2 stable, Compatibility renderer. |
| O-007 | Final faction identities, relic art, and match-length target? | Open content/balance work; does not block fixture development. |
| O-008 | Structure reach, costs, unlock lifecycle, slots? | P-011 selects initial behavior and test values; fourth structure deferred. |
| O-009 | Leadership accounting and suppression? | P-009 selects accumulated dice/card bonuses plus surviving unrouted units counted once. |
| O-010 | Damage assignment and routing? | P-009 selects owner assignment, round-local damage, persistent routing, and cycle-refresh recovery. |
| O-011 | Card timing, dice, hands, and test values? | P-009 and its worked battle specify a testable sequence and original test content. |
| O-012 | Battle ending and retreat? | P-009/P-010 define mutual destruction, domain-appropriate retreat, and no-path losses. |
| O-013 | Scope of tile minimum and designated tokens? | P-012 selects token-bearing tiles per placing player, generic enemy relics, and setup validation. |

## Current implementation and revision history

- 2026-09-18: implemented the next roadmap milestone: scene-independent combat and retreat, seeded replay, filtered player views, and a playable ground/space/defense battle lab. Tests verify the worked 6–6 tie, damage overflow and priority, routing, mutual destruction, structures, deck lifecycle, privacy, and retreat. A deterministic battle policy uses only permitted views. This implements selected P-009/P-010 and defense contributions from P-011; it adds no new gameplay requirements. Production, atomic conquest/relic victory, strategic refresh/planning, and strategic AI are still pending.

- 2026-09-18: created the Godot 4.7.2/GDScript movement lab: two tiles, stable area IDs, distinct range/support graphs, unit selection, route previews, and unopposed sandbox moves. Added headless rule and UI tests. Battle, conquest, relic victory, production actions, tactics planning, and AI remain unimplemented in Godot.

- 2026-09-18: confirmed two-player victory at two relics and adjacent-tile movement with free ship travel and supported ground paths. Reviewed official Forbidden Stars rulebooks and selected a documented, revisable experiment for unresolved details at user request. Replaced area-edge movement range, retained separate support geometry, and added numerical battle/map fixtures. Runtime remains unchanged.

- 2026-09-18: confirmed a formerly nonmagical universe broken by ancient humans, introducing magic alongside advanced technology; alien and human-remnant faction scope; relics as the existing victory tokens. Clarified vanished civilization versus surviving offshoots. Reviewed development readiness; no new magic mechanics or runtime changes.

- 2026-09-18: confirmed humanity as the incredibly advanced, long-gone precursor civilization; revised setting and provisional faction descriptions without inventing disappearance lore or new mechanics.

- 2026-09-18: confirmed conquest of an objective planet collects its token and three collected tokens win immediately. Flagged the two-player shortage under enemy-only collection; no exception invented.
- 2026-09-18: confirmed objective-token collection as the match victory direction and setup quantities: two per enemy, one maximum per starting planet, two minimum per tile. Recorded tile-scope and collection/threshold questions without inventing answers; runtime unchanged.
- 2026-09-18: confirmed accumulated leadership compared after final damage, attacker-first card resolution and attacker leadership ties, one-turn damage with persistent routing, and path-dependent retreat to nearby planets. Routing semantics and “turn” interpretation remain explicit questions. No runtime changes.
- 2026-09-18 documentation review: separated legacy rules, clarified document ownership and engineering contracts, split combat questions, and staged map work ahead of integration dependencies. No new gameplay requirements approved and no runtime changes.
- The browser implements eight world nodes, private reversed command queues, deterministic attrition, alloy, and relay scoring. It does not implement the quadrant map or simultaneous token placement.
- Human planning cannot use newly captured origins, while the AI projects captures. This mismatch is an existing issue, not an intended rule.
- 2026-09-18: confirmed card damage/defense/leadership bonuses and unit-dependent special effects; damage and deaths checked each round; damaged survivors stop contributing unit leadership for the rest of that round. No runtime changes.
- 2026-09-18: confirmed three battle rounds, one card and dice per player each round, attack/defense/leadership dice results, one-for-one defense cancellation, and higher-leadership victory when both sides survive. Superseded P-008’s battle-length comparison; no runtime changes.
- 2026-09-18: confirmed attack (battle dice per unit), health (damage before death), and leadership (effect open) as the three unit stats. Replaced the undefined dice-pool formula in current design requirements; runtime remains unchanged.
- 2026-09-18: confirmed four starting faction rosters, each with three ground and two space types, and advancement thresholds of 0/1/2 for ground and 0/2 for space. No runtime implementation or unit statistics added.
- 2026-09-18: added the small structure catalogue and three required roles; recorded the types interpretation and left numerical effects, facility reach, and building caps open.
- 2026-09-18: confirmed planet/space production, one combat deck per player, and dice-plus-card battles for all fighting. Reviewed Forbidden Stars; digital adaptation remains proposed. Superseded conflicting defaults without changing the browser.
- 2026-09-17: documented simultaneous tactics-token placement; removed alternating placement from the intended shared-stack experiment.
- 2026-09-17: recorded the four-quadrant square requirement; added rules, map specification, contributor instructions, roadmap, architecture, and playtest notes.

When a proposal is adopted, changed, or rejected, retain its ID and record the reason here. Do not infer approval merely because a proposal appears in code or a design document.
