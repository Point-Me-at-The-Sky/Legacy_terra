# Legacy of Terra — Game Design Document

**Version:** 0.18 · **Date:** 2026-09-18 · **Status:** Draft for discussion

The game is titled **Legacy of Terra**. This document explains the vision. [DECISIONS.md](DECISIONS.md) owns requirement status, [RULES.md](RULES.md) specifies current gameplay, and [ROADMAP.md](ROADMAP.md) identifies the next buildable slice. Confirmed requirements, selected experiment rules, and still-proposed alternatives are labeled separately. Test values and names remain revisable.

## 1. Vision

A turn-based strategy game set long after an incredibly advanced human precursor civilization broke the universe and introduced magic. That civilization is gone, but its legacy shapes a universe where magic and advanced technology coexist. Alien civilizations and strange remnants or offshoots of humanity compete to claim its relics. Players simultaneously place tactics tokens to define their planned actions before seeing how the round unfolds, contest critical locations, and use a small number of consequential decisions to outmaneuver stronger forces.

The central experience is anticipation: **“Can I arrange my commands so my fleet arrives when it matters?”** Military strength should matter, but timing, position, and objective selection should offer alternatives to simply building the largest fleet.

### Confirmed direction

- An original game inspired by Forbidden Stars' mechanics.
- **Ancient humans broke a universe without magic, introducing magic alongside advanced technology.** Their precursor civilization is long gone; alien factions and strange human offshoots or remnants inhabit its aftermath. The exact catastrophe and faction identities remain open.
- **Tactics tokens placed simultaneously define what each player intends to do.** All players plan during the same phase; private commitment and shared reveal are selected experiment details (P-002).
- **The map consists of square tiles, each containing four quadrants in a 2×2 arrangement. Each quadrant represents a planet or a space area.** Movement targets an adjacent tile, with ships moving freely to space areas and ground units requiring an unbroken friendly support path (D-024).
- **Ground units and structures are built on planets; spaceships are built in space areas.** A production structure is required to produce either unit category; P-011 selects initial reach and test costs.
- **Every fight resolves as a card battle, on planets or in space. Each player has one combat deck for all battle types.**
- **Units have three stats: attack, health, and leadership.** Attack sets battle dice, health sets damage before death, and leadership decides victory if both sides survive.
- **Battles use three rounds, with one card and dice per player each round.** Dice add attack, defense, or leadership; cards add damage, defense, or leadership and may have unit-dependent effects.
- **Check damage and deaths every round.** Damage clears each battle round; routed survivors remain routed until strategic refresh. Accumulated leadership is compared after final damage, adding surviving unrouted unit leadership once under selected P-009.
- **Four starting factions, each with three ground unit types and two space unit types.** Their advancement requirements are defined below.
- **Match victory comes from collecting relics, represented by objective tokens on starting planets.** Each player places two per enemy, at most one per planet and at least two per tile; conquering a token’s planet collects it and two collected relics win a two-player game; three win larger matches. P-012 specifies initial placement details.
- Single-player against AI first; online multiplayer later.
- **Develop directly in Godot using GDScript (D-025).** The current implementation pins Godot 4.7.2 standard edition. Preserve the browser version as a legacy reference.

### Proposed product targets

- Desktop-first, mouse and keyboard, with a readable 2D strategic map.
- Initial complete release slice: one human against one AI.
- Target match duration: 30–45 minutes, subject to playtesting.
- Self-contained skirmishes before a campaign or persistent progression.
- Original setting, factions, terminology, illustrations, and rules text.

## 2. Inspiration and design pillars

Forbidden Stars combines hidden orders placed in shared system stacks, alternating execution of exposed orders, faction asymmetry, objective capture, dice-and-card combat, and movement barriers that change between rounds. The shared stacks are particularly important: another player's order can cover yours and affect when it becomes available. These are distinct from a single private reversed command queue. See the [official Learn to Play booklet](https://images-cdn.fantasyflightgames.com/filer_public/cf/97/cf971a24-1828-4671-a794-83f394380da5/fs01_learn_to_play_lowrez.pdf).

Legacy of Terra should explore the strategic tensions behind those systems while developing its own rules:

| Pillar | Intended player experience | Design consequence |
| --- | --- | --- |
| Commit, then adapt | Predict the opponent, but recover from surprises | Simultaneously placed tactics tokens commit an action and location; execution can retain limited choices |
| Position creates opportunity | A smaller force can threaten a valuable objective | Multiple routes, contested relic planets, and understandable travel constraints |
| Battles involve decisions | Combat is more than comparing army sizes | Use the confirmed dice-and-card battle framework; test its pacing before expanding unit types |
| Factions reward different plans | Each faction changes how players approach the same map | Small, explicit asymmetries rather than numerous exceptions |
| Information is legible | Understand why a plan succeeded or failed | Show timing, costs, legality, outcomes, and command history clearly |

## 3. Setting and presentation

### Confirmed lore

- **Before magic:** the universe originally had no magic. Humans became an incredibly advanced civilization.
- **The break:** humans did something that broke the universe, introducing magic. What they did and how it worked remain unspecified.
- **The present:** the ancient human civilization is long gone. Magic and highly advanced technology now coexist. The user's Warhammer 40,000 comparison establishes this blend; Legacy of Terra keeps its own setting, factions, and history.
- **The factions:** present-day factions include aliens and may also be strange offshoots or remnants of humanity. The vanished precursor civilization does not imply that every human-derived being is extinct.
- **The contest:** players collect relics in each match. Relics are the existing objective tokens: conquer their planets to collect them, and collect two to win with two players, otherwise three (D-018/D-019/D-022/D-023).

These are confirmed requirements D-020–D-022. “Human player” in implementation notes still means a person controlling the game, regardless of their faction.

### Open lore and proposed presentation

The exact human act, dates, why the precursor civilization disappeared, and whether the break directly caused that disappearance remain open. So do individual faction histories, the nature of magic, and the appearance or function of each relic. These details need not be completed before the map and rules prototype.

The earlier fractured relay network can remain a proposed remnant of human infrastructure; it is not the confirmed cause of the cosmic break. Magical and technological motifs can inform unit, card, and structure designs. No mana resource, spell subsystem, fourth unit stat, or relic power is implied by the lore. Any mechanical effect must be specified through the existing rules and content boundaries.

### Provisional factions

The starting roster will contain **four factions**. Two currently have provisional names; the other two remain unnamed. This roster size does not imply four players in each match.

- **Ember Union:** industrial communities seeking to restore ancient infrastructure. Proposed identity: efficient recovery and reinforcement.
- **Vesper Accord:** custodians wary of uncontrolled use of precursor technology. Proposed identity: route control and precise redeployment.

These faction descriptions are proposals; they do not establish human ancestry or explain humanity’s disappearance. The existing prototype uses these names and colors, but both factions currently follow identical rules. Mechanical asymmetry is future work.

Visual direction: dark star charts, warm amber and muted violet faction accents, geometric fleet symbols, and distinct relic markers. Ownership must also use symbols or labels, not color alone. Sound should emphasize command confirmation, route activity, and readable battle outcomes without slowing play.

## 4. Implementation status

### Active Godot movement and battle labs

The Godot project implements a small map/movement slice: two square tiles with four
areas each, stable IDs, separate range/support graphs, unit instances and stats,
legal destination previews, ground transport paths, and unopposed movement. Starting,
intact-transport, and broken-transport scenarios use the fixtures in `MAP_DESIGN.md`.
Both player selectors use the same legality checks. Keyboard navigation and visible
focus are available.

The separate Battle lab adds ground and space skirmishes and a defense-building
scenario. A human plays against a deterministic battle policy through the same
permitted-view and legal-action interface. It implements fresh seeded dice,
hidden card commitment, attacker-first cards, damage assignment, persistent routing,
leadership accumulation, final comparison, and retreat. Its six-card test deck is
shared across combat domains; cards return after battle.

These are development labs, not a complete match. The movement map displays relics
and stores structure fixtures, but map attacks remain previews. Standalone battle
results include casualties and retreats; ownership, surviving structure capture,
relic scoring, production, tactics turns/refresh, and strategic AI remain future
integration work. Headless rule/scene checks and graphical smoke captures verify
the current slices; they do not establish game balance.

### Preserved browser baseline

This section describes the implemented rules, not the full intended game. The eight-world graph is a temporary map and does not yet implement the confirmed square tiles and four quadrants per tile.

| Element | Current behavior |
| --- | --- |
| Map | Eight fixed worlds connected by travel links; four are scoring relays |
| Factions | One human Ember Union and one Vesper Accord AI |
| Starting position | Each faction owns one home world with five ships and five alloy |
| Planning | Each faction queues three commands in a private stack |
| Resolution | Last queued command resolves first; factions alternate actions |
| Initiative | Opening faction alternates each cycle |
| Dispatch | Move a positive whole number of ships to an adjacent world |
| Build | Spend two alloy for two ships at an owned world |
| Extract | Gain three alloy at an owned world |
| Combat | Both sides lose equal numbers of ships; surviving attackers capture the world |
| Combat tie | The contested world becomes neutral with no ships |
| Friendly movement | Arriving ships join the existing fleet |
| Empty holdings | A world remains owned when its fleet leaves |
| Cycle income | Each faction gains two alloy |
| Scoring | Each owned relay produces one influence at cycle end |
| End conditions | Elimination, either side reaching 12 influence, or completion of cycle eight |
| Winner | Elimination takes priority; otherwise highest influence wins, equal influence draws |

Elimination and scoring are evaluated at the end of a cycle. A home world has no special defeat condition beyond ownership and eventual elimination.

Commands are validated both when queued and when executed. A command that becomes invalid is consumed without effect. Costs and ships are not reserved during planning, so individually legal commands can conflict with each other. The human interface currently requires orders to target currently owned origins; it cannot plan an action from a world that will only be captured later in the cycle.

The AI uses a private projected state to assemble its plan, prioritizing attainable captures and relays before building or extracting. This allows it to plan follow-up actions from newly captured worlds, which the human interface cannot yet express. This planning mismatch makes it unsuitable for new-rule balance evaluation; the Godot implementation must provide equal planning privileges.

The prototype does not yet implement simultaneous tactics-token placement; its private command queues are an interim model. It has no tactical cards, unit classes, route disturbances, faction powers, research, save/load, or networking. Combat is a temporary numerical model.

## 5. Proposed core loop

1. **Assess:** inspect territory, objectives, resources, and visible route conditions.
2. **Plan simultaneously:** all players place a limited set of tactics tokens to define actions and their locations, checking expected execution order.
3. **Commit and reveal:** lock each plan; reveal the tokens only after every player has committed.
4. **Resolve:** execute tokens in the agreed order; choose permitted execution details and resolve battles.
5. **Refresh:** if no conquest has already ended the match, collect income, clear routing, and rotate initiative under the selected rules.
6. **Continue:** start another planning phase. Relic collection and victory are checked immediately on conquest, not postponed until refresh.

The planning interface should distinguish an impossible command from a conditional one. For example, building before moving may create enough ships for a dispatch that was impossible at the beginning of planning. Conditional plans need a clear warning and a predictable failure rule.

### Tactics tokens and simultaneous placement

**Confirmed concept:** tactics tokens represent planned actions. Players place them simultaneously during a shared planning phase to define what they will do. Placement does not execute the action immediately. “Simultaneous” means everyone plans in the same phase without taking placement turns; it does not require clicking at the same instant. Resolution timing is a separate rule.

The following P-001–P-004 details are selected for the next prototype and remain revisable:

- Each faction receives three tactics tokens per cycle. For the first experiment, a token records an action type and its origin quadrant. Whole-tile targeting remains a possible later alternative.
- Initial action types are **Dispatch** (move forces), **Build** (produce ground units/structures on planets or ships in space), and **Extract** (gain alloy). Use the selected production and movement rules in `RULES.md`. Token counts and the available mix remain tunable.
- Each player places and edits tokens on a private planning view of the map. Opponents cannot see token types, locations, or sequence before commitment. Existing public board information remains visible.
- A player commits when ready, locking their tokens. Once all players have committed, all placements and action types are revealed together. Committing earlier grants no priority advantage.
- The AI plans from the same public starting state without access to the human's hidden tokens and commits before their reveal.
- For the first experiment, assign tokens to explicit slots 1–3 and alternate resolution by slot using rotating initiative (first both slot-1 tokens, then slot 2, then slot 3). Resolve each token once and remove it; an invalid action consumes its token with a clear explanation.
- For the selected planning experiment, commit action type, origin quadrant, and all action parameters during planning; use the unit IDs, destination, and purchase parameters defined in `RULES.md`. Compare this with execution-time choices in later playtests; full commitment is a selected experiment, not a permanent confirmed requirement.

For example, in the same planning phase, Ember places Build at a home planet and Dispatch at a frontier area while Vesper places Extract and Dispatch at its own holdings. Neither side sees the other's placements until both commit. The revealed tokens then determine which actions each faction may perform.

These strategic planning tokens are separate from the combat cards in section 7. The browser's queued commands are a precursor to this system, not a completed implementation of simultaneous token placement.

### Token ordering experiment

Simultaneous tactics-token placement is the intended direction. The remaining experiment concerns how committed tokens are ordered: a private sequence per faction or shared stacks at map locations.

**Current prototype model:** one private command stack per faction, with the last queued command executing first. This provides a reference for timing but needs a tactics-token placement interface and commitment/reveal flow.

**Possible shared-stack variant:** players still place their tactics tokens simultaneously and privately. After everyone commits, assemble shared stacks at sectors using an explicit, deterministic priority rule. Placement speed or network arrival time must never determine stack order. The exact rule for combining opposing tokens at the same sector must be designed and shown in the planning interface before this variant is implemented.

On an execution turn in that variant, choose one of your exposed tokens. If none are exposed, pass; remove each resolved or deliberately discarded token. Continue until all stacks are empty. Test whether interference and flexibility justify the extra rules before expanding content.

The confirmed map structure is square tiles with four planet-or-space quadrants each. A sector could correspond to one tile for a shared-stack variant, but token reach and the rule for combining opposing stacks still need design. See [the map specification](MAP_DESIGN.md).

## 6. Territory, economy, and victory

### Square tiles and quadrants

**Confirmed:** the map is made of squares, each divided into four quadrants in a 2×2 arrangement. Every quadrant contains a planet or a space area. A tile is the larger square; each quadrant is an individual playable area. No fixed planet-to-space ratio or map size has been chosen.

D-024 establishes adjacent-tile movement, with access to every domain-eligible destination area in that tile. Ships need no supporting chain; ground units require friendly planets and ships along a continuous path. P-010 defines side-sharing tile neighbors and a separate area-edge support graph. Area-edge movement range from the earlier prototype is superseded. Same-tile Dispatch is excluded from this experiment under the user's “adjacent squares always” rule.

The board must distinguish tiles, individual areas, ownership, units, and relics. See [MAP_DESIGN.md](MAP_DESIGN.md) for the two graphs and [RULES.md](RULES.md) for legality. Presentation highlights rule-legal destinations, including space areas that do not touch the origin area.

### Structures

**Confirmed roles:** one structure improves defensive capabilities; one is required to produce ground units or spaceships; a third grants access to higher-level units. Keep the catalogue small: **3–4 structure types**, interpreting the user's requested limit as types rather than a per-planet or per-player building cap. A fourth type is optional and its role remains open. The labels below describe roles, not final names.

| Structure role | Purpose |
| --- | --- |
| Defense | Adds defensive capabilities, with its effects resolved through the shared card-battle system |
| Production | Required for producing ground units on planets and spaceships in space areas |
| Advanced-unit access | Unlocks higher-level units; their production still requires the production structure |
| Optional fourth | No role selected; keep within the 3–4-type scope |

All structures are built on planets. A planet-based production structure must therefore enable ship construction in an eligible space area; P-011 selects any legal space destination in the same tile. Do not move ship construction onto planets or introduce an extra space-based structure by implication.

P-011 selects test costs, defense behavior, one purchase per Build, one building per type per planet, and construction-history advancement. These choices are revisable and are specified in `RULES.md`. Defense-building combat is implemented in the battle lab; construction, advancement, and capture remain pending.

### Unit stats

**Confirmed (D-011):** ground and space units have exactly three stats.

| Stat | Meaning |
| --- | --- |
| Attack | Number of dice the unit rolls in battle |
| Health | Amount of damage the unit takes before dying |
| Leadership | Determines the winner when both sides have living units at battle end: higher leadership wins |

P-009/P-011 select original test stats and routing semantics. Godot stores and
displays those stats and uses them for dice, damage, routing, and final leadership
in the battle lab. Use `RULES.md` for those semantics. Final faction balance remains open.

### Unit roster and advancement

**Confirmed:** each of the four starting factions has **three ground unit types** (tiers 1–3) and **two space unit types** (tiers 1–2). This gives five types per faction and twenty faction-specific roster entries overall; names, battlefield roles, stat values, and differences between factions remain open.

| Unit type in each faction | Advancement structures required to have been built | Production location |
| --- | --- | --- |
| Ground tier 1 | 0 — accessible from the start | Planet |
| Ground tier 2 | 1 | Planet |
| Ground tier 3 | 2 | Planet |
| Space tier 1 | 0 — accessible from the start | Space area |
| Space tier 2 | 2 | Space area |

The **advancement structure** is the existing advanced-unit-access structure, not an additional structure type. Two advancement structures means two instances of that type. These are unlock thresholds, not structures spent when producing a unit. All unit tiers still require production capability and payment of their eventual costs. Starting access to tier 1 means no advancement prerequisite; it does not give free units or waive the production structure.

The requirement concerns structures the player has built. P-011 counts distinct qualifying construction sites, preserves earned credit after loss, and gives no credit for capture or rebuilding the same site. The reference game’s current-city count is not substituted for this requirement.

### Economy and objective-token victory

P-011 selects alloy as the sole spendable resource for this experiment. Influence scoring belongs to the legacy browser baseline.

**Confirmed (D-018/D-022):** overall victory is based on collecting relics, represented by objective tokens. During setup, each player places **two tokens for every enemy player** on their own starting planets, with **at most one token per planet** and **at least two tokens per tile**. Objective tokens are distinct from tactics tokens.

With all other players as enemies, each player places two/four/six tokens in a two/three/four-player match, requiring at least two/four/six eligible starting planets respectively.

**Confirmed collection and victory (D-019/D-023):** conquer a relic planet to collect its token. Two relics win with two players; three win larger matches. Check victory immediately after collection. Relic tokens are not map tiles.

P-012 selects generic enemy relics, permanent collection, no scoring of one's own relics, and the two-token minimum per placing player on each token-bearing tile. These are explicit experiment interpretations, not Forbidden Stars setup rules. No cycle-limit or separate elimination victory is added. The two-player setup conflict is resolved by D-023.

Route disturbances are a later experiment: announce a link closure one cycle before it occurs, limit closures to preserve meaningful access, and show the next change directly on the map. Their purpose is to shift strategic opportunities while allowing preparation. Exact frequency and connectivity safeguards remain undecided.

## 7. Combat direction

### Confirmed foundation and selected adaptation

All fighting uses a shared card-battle framework and one deck per player. Battles have three rounds, with fresh dice and one card per player each round. Unit attack determines dice; dice add attack, defense, or leadership; cards add damage, defense, leadership, and unit-dependent special effects. Damage and deaths are checked each round. Leadership accumulates and is compared after final damage, with the attacker winning ties. Cards resolve attacker-first.

At the user's request, the remaining details were resolved into **selected experiment P-009**, using official Forbidden Stars references while retaining these differences. [RULES.md](RULES.md) owns the complete sequence, source links, test content, leadership formula, and worked example. P-010/P-011/P-012 cover movement, production, and relic setup. These remain revisable defaults. Standalone combat/retreat is implemented and tested; strategic consequences and production/relic rules remain pending.

Present the round's rolls, card effects, incoming damage, routing, banked leadership, and eligible unit leadership separately. Explain why a prerequisite failed or a retreat path is blocked. The worked fixture specifically checks a defender routed in round three before an attacker-winning leadership tie.

### Playtest focus

Measure battle duration, usefulness of card choices, first-attacker advantage, transport bottlenecks, and understanding of routing versus round-local damage. Test both combat domains, successive battles using the same deck, and identical information limits for human and AI controllers. Final card content, faction asymmetry, and large-map balance can follow the verified fixture.

## 8. AI design

The AI should pursue victory objectives, defend threatened holdings, manage its economy, and form command sequences that remain useful under plausible enemy responses.

- Apply the same command rules and information limits to both sides.
- Supply AI decisions through the same validated command interface as human decisions.
- Score candidate plans using objective progress, territorial risk, resource efficiency, and execution reliability.
- Start with bounded heuristic search; keep planning time short enough for interactive play.
- Introduce difficulty through search quality and risk tolerance before resource bonuses.
- Record decision explanations for development; show players only information they are entitled to know.

Scenario checks should cover defending a threatened relic planet, avoiding an unwinnable attack, spending resources productively, and recovering from a failed command.

## 9. User experience

The main screen should prioritize the map, objectives, current phase, faction resources, and the player's command plan. Selection details and an expandable event log support those elements.

Essential feedback:

- Highlight legal origins and destinations for the selected command.
- Display execution order explicitly, including the meaning of stack position.
- Preview costs and combat results where rules allow certainty.
- Label conditional orders and explain failed commands with the actual reason.
- Provide a tactics-token tray and show each placed token’s action, location, and expected execution order.
- Allow token editing and undo before commitment; lock the plan after commitment. Show which players are ready without exposing their placements, then reveal all plans together.
- Offer manual stepping and faster automatic resolution.
- Explain victory progress and why the match ended.

The first tutorial for the new experiment should teach quadrant movement, planet/space production, simultaneous tactics-token placement, commitment/reveal, numbered execution slots, and objective-token collection through a short playable scenario using the selected relic rules. Reversed execution belongs to the current browser baseline. Save/resume and a restart confirmation are needed for longer matches. Keyboard navigation, readable text scaling, and symbols supplementing faction colors are usability targets.

## 10. Technical direction

Develop directly in **Godot with typed GDScript**, as selected in D-025. The project
pins **Godot 4.7.2 standard edition** and uses Compatibility rendering. The browser
build remains a playable historical reference; new rules are implemented and tested
in `godot/`.

Maintain separate responsibilities:

- **Rules:** authoritative state, legal actions, combat, scoring, and phase transitions.
- **Controllers:** human input, AI plans, and later remote commands.
- **Presentation:** map rendering, animation, audio, and UI.
- **Content:** map definitions, faction data, units, and balance values.

The JavaScript engine records an older experiment, not the current gameplay contract.
Implement `RULES.md` in scene-independent GDScript using reproducible state/action
fixtures. Rules own validation and transitions; presentation consumes legal choices
and structured outcomes. The movement lab establishes these boundaries without
introducing a networking layer or third-party framework.

Represent matches as serializable data with stable entity IDs, a rules version, phase, initiative, resources, objectives, tactics-token placements, commitment status, resolution order, and an ordered event history. Dice battles require authoritative seeded randomness and recorded roll outcomes; persist deck order, hands, battle choices, and the paused strategic resolution cursor when implementing them. Save files should include enough state to resume a match exactly.

### Later online multiplayer

**Proposed initial online scope:** two human players in a private match; player count remains open. A server owns the authoritative state, validates each player's commands, and sends each client only permitted information. Before the shared reveal, hidden token placements must never be included in the opponent's client state. Begin resolution only after all plans are committed; network arrival order must not affect priority.

Reconnection, duplicate command handling, match persistence, surrender, disconnect policy, and version compatibility are required design work. Competitive matchmaking, ranked ladders, spectators, and asynchronous correspondence play are outside the initial online milestone.

Keeping the rules separate now reduces future work, but the current prototype is not network-ready.

## 11. Milestones and acceptance criteria

| Milestone | Deliverable | Exit criteria |
| --- | --- | --- |
| A — Baseline prototype | Existing browser skirmish, preserved with a known planning limitation | Baseline rules documented and tested; retained as historical reference, not a new-rule balance test |
| B — Godot rules and tactics loop | Movement and battle labs delivered; economy, conquest/relics, and planning next | Selected fixtures pass; human and AI have equal legal choices and private commitment; reveal waits for everyone; resolution is independent of placement speed; a match reaches relic victory |
| C — Strategic identity | Tested victory model, shared dice-and-card combat for ground and space, four faction rosters with three ground and two space types each, and advancement thresholds | All four factions have viable plans; battles and objectives reward more than fleet accumulation |
| D — Polished vertical slice | One Godot human-versus-AI skirmish with tutorial and save/resume | Full match resumes correctly; rule fixtures pass; essential UI is usable |
| E — Solo refinement | Better AI, balance, accessibility, and feedback | Repeated playtests meet agreed match-length and usability targets |
| F — Online foundation | Private two-player matches | Server validation, hidden information, persistence, and reconnection work correctly |

These are product milestones, not an independent implementation order. Follow
`ROADMAP.md`: movement and combat/retreat labs are delivered; production/conquest/relic
rules come next, then the full tactics cycle.

No calendar estimates are assigned yet. Resolve the major rule experiments before estimating content production.

## 12. Playtesting and open decisions

Track match duration, first-player advantage, time to first conflict, failed orders and their causes, score swings, repeatable dominant openings, and whether players can explain why they lost. Compare outcomes across both starting sides and multiple AI policies.

The previous outcome-changing questions now have selected experiment answers in `RULES.md` and dispositions in `DECISIONS.md`. Test those choices before adding systems. Still open are final balance, faction identities, and production map size. Godot/GDScript is selected and the engine version is pinned. Shared token stacks and execution-time strategic choices remain later comparisons, not blockers for the private-slot prototype.

## References and implementation

- [Documentation index and setup](README.md)
- [Decision status and open questions](DECISIONS.md)
- [Current rules and selected battle semantics](RULES.md)
- [Historical v0.1 worked round](RULES_LEGACY.md)
- [Square tile and quadrant specification](MAP_DESIGN.md)
- [Ordered implementation roadmap](ROADMAP.md)
- [Architecture notes](ARCHITECTURE.md)
- [Playtest scenarios and session template](PLAYTEST.md)
- [Contributor instructions](AGENTS.md)

- [Forbidden Stars — official Learn to Play](https://images-cdn.fantasyflightgames.com/filer_public/cf/97/cf971a24-1828-4671-a794-83f394380da5/fs01_learn_to_play_lowrez.pdf): reference for the inspiration summary; not Legacy of Terra's rulebook.
- [Prototype instructions](README.md)
- [Godot project](godot/project.godot)
- [Godot movement rules](godot/rules/movement.gd)
- [Godot battle rules](godot/rules/battle.gd)
- [Godot rule and scene checks](godot/tests/run.gd)
- [Legacy browser rules](engine.js)
- [Legacy browser checks](engine.test.js)
