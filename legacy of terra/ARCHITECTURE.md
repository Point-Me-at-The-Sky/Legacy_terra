# Architecture notes

## Active Godot project

D-025 selects direct development in Godot with GDScript. The current engine pin is
**4.7.2 standard**, using typed GDScript and the Compatibility renderer. The project
has no third-party runtime dependencies or plugins.

| File | Responsibility |
| --- | --- |
| `godot/project.godot`, `godot/scenes/main.tscn` | Engine settings and entry scene |
| `godot/content/fixtures.gd` | Original map/unit test content and movement-lab state |
| `godot/content/combat_content.gd`, `battle_fixtures.gd` | Shared unit stats, original six-card deck, defense values, and isolated battle scenarios |
| `godot/rules/board_map.gd` | Map validation, stable IDs, tile-range and area-support graphs |
| `godot/rules/movement.gd` | Fixture-state validation, common movement legality, support paths, unopposed lab transitions |
| `godot/rules/battle.gd` | Battle preparation, legal actions, immutable transitions, filtered player views, damage and outcome |
| `godot/rules/battle_random.gd`, `retreat.gd` | Serializable seeded randomness and domain-specific retreat destinations/paths |
| `godot/controllers/battle_policy.gd` | Deterministic battle decisions from a permitted player view only |
| `godot/ui/main.gd` | Selection, player/scenario controls, route presentation, keyboard focus |
| `godot/ui/battle_lab.gd` | Isolated human-versus-policy combat screen and battle record |
| `godot/tests/run.gd`, `battle_tests.gd` | Headless movement/combat and scene interaction checks |
| `godot/tests/visual_smoke.gd` | Optional graphical screenshot capture |
| `scripts/godot.py` | Version-checked editor, game, and test commands |

Rules use `RefCounted` scripts with static functions; they require no scene tree,
input, presentation, or AI policy. Maps, unit instances, and lab states contain
serializable dictionaries/arrays with stable IDs. Transitions copy caller-owned
state and return structured events. Both selectable movement players use the same
legality interface. A battle policy exists; strategic AI has not been added yet.

The `movement_lab` state is explicitly an isolated development mode. It permits
repeated unopposed moves and neutral-planet occupation, and previews hostile routes.
It blocks battle, relic destinations, and hostile structure capture until their
complete transactions exist. These restrictions are lab limitations, not new game
rules. There is no phase system, economy, conquest scoring, or full setup validator
yet. Do not use this lab transition as authoritative tactics-token execution.

The battle lab is a separate fixture, accessible from the movement screen. It never
overwrites the movement board. `Battle.start()` copies the supplied world, validates
the attack, references participant IDs in that single unit store, prepares each
player's deck in `world.combat_decks`, and rolls. `Battle.apply()` accepts only a
currently legal card, damage-target, or retreat command. `Battle.view_for()` returns
public forces/rolls/events plus the requesting player's own hand and choices; it
omits RNG state, deck order, and unrevealed opposing choices. Both controllers use
that interface. Lab seed controls are debug tools, not a future match player view.

The battle state stores integer RNG state for deterministic rolls and shuffling,
round/step, banks, commitments, pending damage, and a terminal outcome. Participants
reference canonical units/structures in the copied world, so casualties are applied
once. A completed result resets decks and active banks, retains audited final totals,
and marks its battle ID resolved. Returned worlds include casualties and retreat;
ownership and surviving structure ownership are deliberately unchanged. The next
milestone must apply conquest, capture, relic collection, victory, and token resumption
in one authoritative transaction before exposing this world as a strategic state.

## Existing browser prototype

| File | Responsibility |
| --- | --- |
| `engine.js` | Fixed map, serializable match state, validation, transitions, and current AI planning |
| `app.js` | Input handling and browser presentation |
| `index.html`, `style.css` | Game layout and styles |
| `engine.test.js` | Existing deterministic rule checks |

The runtime has no external dependencies. `npm start` serves static files through
Python; `npm test` uses Node's built-in test runner. The documentation generator
has a separate Python dependency. Preserve this historical experiment; new gameplay
belongs in Godot. No multiplayer server exists.

The intended boundaries below are implementation guidance, not evidence that a
feature exists or that an open game rule has been selected. `RULES.md` owns
gameplay semantics; consult its decision references before coding a transition.

## Confirmed production and combat requirements

Ground units and structures are built on planet quadrants; spaceships are built in space quadrants. All fighting uses one card-battle framework with a single combat deck per player, shared across ground and space battles. Each unit’s attack determines its battle dice, and cards modify or augment the results; battles have three rounds, each with one card and dice per player. Dice add attack, defense (one cancels one enemy attack), or leadership. Higher leadership wins at battle end if both sides retain living units; leadership accumulates across rounds and is compared after final damage, with ties favoring the attacker. Cards resolve attacker-first; P-009 in `RULES.md` defines selected contribution accounting and timing. Godot implements standalone battle; production and strategic integration remain future work.

The intended model must distinguish ground units, ships, and structures, with stable entity/content IDs and area references. Validate production by entity category and area type through the same legal-action interface for human and AI. P-009–P-011 in `RULES.md` define the selected facility, movement, transport, and defense rules; architecture does not invent alternative defaults.

The structure catalogue is scoped to 3–4 types (the current interpretation of the user's limit): defense, production, advanced-unit access, and an optional fourth role. Model these roles in content and enforce their effects in rules. Unit production requires the production structure; higher-level units also require the access it unlocks. Both controllers must receive the same legal build options and failure reasons.

Structures remain planet-based, while ships appear in space areas. Represent the supporting structure and production destination separately; validate that both are in the same tile under P-011. Keep defensive effects inside battle resolution. The selected test costs, one-instance-per-type-per-planet limit, and prerequisite lifecycle are in P-011. Do not treat 3–4 types as an implemented limit on structure instances.

## Unit roster and advancement model

Content must describe four starting factions, each with three ground types (tiers 1–3) and two space types (tiers 1–2). Use stable faction and unit-type IDs, domain, tier, and required advancement count: ground `[0, 1, 2]`, space `[0, 2]`. This roster size is independent of the number of participants in a match. Unit content has exactly three stats: attack (battle dice), health (damage before death), and leadership (decides victory when both sides survive). P-009/P-011 specify test values, damage assignment, routing, and “turn” as a battle round; do not introduce a separate strength stat or base die per unit.

Advancement structures are instances of the existing advanced-unit-access type. Keep tier eligibility separate from production-facility eligibility, area legality, and cost validation; tier 1 bypasses only the advancement prerequisite. Both controllers use the same rule checks. P-011 tracks qualifying construction sites per player: capture and rebuilding the same site do not increase credit, and loss does not remove earned credit. Do not substitute current building ownership for this history. These requirements are documented but not implemented.

## Movement boundary

D-024/P-010 requires two independently testable graphs: tile neighbors for movement
range and area-edge connections for ground support. A ship destination may be
any space area in a neighboring tile. For ground movement, validate neighboring
origin/destination tiles, then search the friendly support graph. Keep origins,
destinations, unit IDs, and returned support paths as stable references. Revalidate
support at execution. The UI must not reuse area-edge adjacency as ship range.
Retreat is a distinct rule action using the selected destination restrictions.

## Intended boundaries

Keep content, authoritative rules, controllers, and presentation separate. Extend
the Godot rules layer incrementally, keeping rules independent of scene nodes and
input. Add controllers when their behaviors are needed; avoid speculative abstractions.

Static content describes tiles, quadrants, markers, and balance values. Match state
stores area ownership, unit/structure instances, resources, scores, phase, cycle, initiative, token
plans, commitment flags, and an event history. Stable IDs replace numeric positions
as cross-file references in the new model.

Suggested experimental phases are `planning`, `reveal`, `resolution`, and
`finished`; refresh can be an atomic transition after the last token. A reveal UI
must not permit plan edits. Each transition validates inputs and returns a new
state without mutating the caller's state, matching the current engine convention.

Controllers submit intentions through common rules. Supply AI policy with a
faction-specific view containing public board information and its own private plan;
do not hand it the full authoritative state containing hidden human tokens. An
opponent's commitment flag may be visible before their token contents are revealed.
Local single-player separation supports fair AI; it is not online security.

Use structured events with action, faction, affected areas, and failure reason when
upgrading the existing text log. Presentation formats those events for players.
Human and AI planning projections must use the same rules and mark uncertain outcomes.

## Contracts for new rule code

Introduce these boundaries incrementally as their feature is built; exact module
and function names can follow the existing code. No framework, generic effect
language, event-sourcing system, or network layer is needed now.

| Boundary | Contract |
| --- | --- |
| Content → rules | Immutable map, unit, structure, and card definitions with stable IDs; validate references and shape at load time |
| Controller → rules | Actor ID and typed action parameters; shared validation checks phase, ownership, and permitted choices |
| Rules → state | Authoritative transition returns serializable state and structured events without mutating caller-owned input |
| State → controller/UI | Player-specific permitted view; legal choices and previews cannot expose hidden hands, plans, or RNG state |
| Rules → presentation | Events describe effects and reasons; animations consume events and never determine rules or randomness |

Distinguish malformed requests (rejected without changing state or RNG) from a
valid committed token whose conditions fail during execution (consumed with a
failure event under the planning proposal). Projections/previews must not consume
authoritative randomness. Given identical state, content, action sequence, and RNG
state, authoritative results must be reproducible.

Unit type definitions hold attack, health, and leadership. Individual instances
hold IDs, owners, area references, and mutable damage/status as the selected rules
require. A scalar fleet count cannot distinguish damaged survivors. Track temporary
leadership suppression separately from base stats; do not mutate the shared unit
definition when one instance is damaged. Battle participants reference canonical
unit instances so casualties are not independently applied twice.

Represent card bonuses and required unit-type IDs as data, with explicit rule
handlers for supported special effects. Do not place arbitrary executable scripts
in card data or hardcode unit names into the UI. Exact condition semantics and
effect priority must come from the selected battle rules.

## Lore and mechanical content

D-020–D-022 establish the origin of magic, alien/human-remnant faction scope, and
relic objectives. Keep lore, names, and presentation in content. Magical and
technological effects use the same authoritative unit/card/structure rules once
specified; neither faction ancestry nor a visual effect grants implicit powers.
No new resource, magic engine, unit stat, or runtime dependency follows from this
lore update. Specific faction identities and relic art can remain placeholders.

## Relic (objective-token) boundary

D-018/D-019 make objective collection the intended match victory model; D-022 names these objects relics. Represent each
objective token with a stable ID, placing player, initial planet, and collection
state separate from tactics tokens and legacy influence. Under D-019, resolve collection when a planet is conquered and check the match-size threshold (two for two players, otherwise three) in the same authoritative transition; stop further strategic actions once the game is won. P-012 permits generic enemy relic collection and excludes own relics; there is no designated collector. Validate setup totals, starting-planet
eligibility, and one token per planet. Apply the selected minimum to each placing player’s token-bearing tiles. Resolve collection and victory through shared authoritative rules,
with events preventing duplicate collection or scoring. UI and AI consume those
rules rather than deriving victory from visible token counts independently.

## Battle boundary and pending strategic integration

When fighting starts, suspend strategic token resolution and create serializable battle state: battle ID, location/domain, participants, participating entity IDs, current step/round, dice and modifiers, card commitments, pending decisions, and outcomes. Keep each player's single deck, hand, and any discard/played zones in authoritative player state; battle state references them rather than creating separate ground and space decks. Use the selected six-card deck/four-card hand lifecycle from P-009; content sizes remain test values.

Card content must represent damage, defense, and leadership bonuses plus special effects with required participating unit types. Validate those requirements through authoritative rules for both controllers; P-009 checks prerequisites immediately before the special effect. Track damage and casualties per round, with a persistent routed flag independent of base stats and the leadership bank. Keep one-turn damage, persistent routing, and accumulated leadership in separate state fields. Clearing damage must not clear routing or accumulated leadership. P-009 interprets “turn” as battle round and D-014 suppression as routing; use that selected rule consistently. Compare leadership after final damage, with equal totals awarding victory to the attacker; add surviving unrouted unit leadership once to the bank, following P-009.

Expose battle actions through the common validation interface. Human and AI receive public forces, public rolls and revealed cards, their own hand, and only permitted commitment status. Hide opposing hands, unrevealed choices, deck order, and RNG state. Legal choices must not reveal hidden cards indirectly. P-009 selects simultaneous hidden commitment after the public roll, followed by attacker-first reveal/resolution. Both controllers commit without access to the opposing card.

Use a rules-owned seeded random generator; preserve its state and roll events for reproducible fixtures and eventual save/resume. Controllers and animations never generate authoritative rolls. Resolve cards attacker-first in explicit rule order; apply damage and deaths each round. At battle completion, reconcile surviving units, retreats, and ownership according to selected rules and resume the paused token exactly once; do not defer all casualties until battle end. A production UI cannot settle unresolved battle rules through animation order.

These boundaries must support the confirmed three rounds with a card and dice each round. Keep dice/card-result defense separate from the three unit stats. Implement P-009’s numbered sequence and worked battle before connecting it to strategic resolution. Test contribution accounting, routing, damage reset, hand lifecycle, structure participation, mutual destruction, and retreat. Retreat validation must return legal destinations and paths through the same rules used by both controllers; use the selected adjacent-tile retreat rule; space units retreat to space. Add fixtures for both battle domains, hidden-card isolation, replay, and strategic resumption when that feature is implemented.

## Godot and persistence

Godot 4.7.2 and GDScript are selected; keep the version pin and runner synchronized
when deliberately upgrading. Implement the current specification using reproducible
scenario fixtures. The legacy worked round in `RULES_LEGACY.md` covers
old sequencing only; replace its superseded production/combat expectations before
using it to validate the intended rules.
The JavaScript source is a reference, not an automatic port.

When saving is introduced, include schema/rules versions, map content identity,
full match state, hidden plans, decks/hands, active battle, RNG state, and resolution cursor. No save compatibility is
promised by the current prototype. Battles already use rules-owned seeded randomness;
full match persistence is not implemented.

## Later networking

A server owns state, authenticates players, validates commitments, and sends only
authorized views. Submission order cannot determine token priority. Reconnects,
duplicate submissions, persistence, disconnect policy, and version compatibility
need explicit designs before online implementation. Do not send hidden plans, hands, deck order, unrevealed battle choices, or RNG state to an
opponent's client and rely on the UI to conceal them.

## Documentation pipeline

`GAME_DESIGN.md` plus `scripts/game_design.template.html` generate
`GAME_DESIGN.html` via `scripts/build_docs.py`. Commit source, template, and generated
output together. `npm run docs:check` detects stale output without writing files.
Other Markdown files are linked from the README and remain directly editable.
