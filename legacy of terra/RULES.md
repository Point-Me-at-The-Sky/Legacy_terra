# Rules specification — selected experiment v0.2

**Status:** selected specification, partially implemented. `godot/` implements map topology, movement, and standalone combat/retreat in separate labs. Battle includes seeded dice, hidden card choices, damage/routing, leadership, and defense buildings. Conquest/relic collection, production, strategic planning/refresh, and complete matches remain unimplemented. Battle returns casualties and retreat results for the future atomic conquest transaction; it does not yet transfer planet or structure ownership. D-series items
in [DECISIONS.md](DECISIONS.md) are user-confirmed. P-series items below are
**selected, revisable experiment defaults**, resolved at the user's request using
Forbidden Stars as a reference. They are not assertions of final design approval.
`RULES_LEGACY.md` preserves the superseded fixture; `GAME_DESIGN.md` describes the
current browser baseline. Do not mix either with this experiment.

## Reference and adaptation boundary

Reviewed the official [Rules Reference](https://images-cdn.fantasyflightgames.com/filer_public/5f/19/5f19d872-318e-4fcf-a398-626721f5c55c/fs01_rules_reference_lowrez.pdf), printed pages 2, 4–6, 8–11, and the [Learn to Play](https://images-cdn.fantasyflightgames.com/filer_public/cf/97/cf971a24-1828-4671-a794-83f394380da5/fs01_learn_to_play_lowrez.pdf), printed pages 9–13 and 16.

The reference separates system-range movement from ground-unit paths. Its damage
rules let the damaged player choose casualties, with overflow and routing. Its
factory reach is system-wide. These inform P-009–P-011 below. The reference's
objective distribution is not the user's minimum-two-per-tile rule; P-012 is our
explicit interpretation, not a claim about Forbidden Stars.

Preserve our own rules: simultaneous strategic planning, adjacent-tile-only
Dispatch, dice rolled every battle round, accumulated leadership, attacker victory
on ties, relic collection on conquest, and two/three relic victory. Do not import
orbital-strike exceptions, extra currencies, unit capacity limits, or an eight-cycle
match limit. The test costs, deck, dice distribution, and map below are our own.

## Vocabulary and confirmed roster

A **tile** is a square containing four **areas**, each a planet or space. A
**strategic cycle** contains planning, resolution, and refresh. A **battle round**
is one of three combat rounds. P-009 interprets the user's damage “turn” as a
battle round. A **relic** is an objective token, never a map tile or tactics token.

D-009–D-011: four faction rosters each have ground tiers 1–3 and space tiers 1–2.
Ground advancement requirements are 0/1/2; space requirements are 0/2. Unit stats
are attack (dice contribution), health (damage before death), and leadership.
Full faction content is later work; the same test entries can stand in for each.
Ground units and structures are built on planets; spaceships are built in space.

## Relics and match victory

**Confirmed D-018/D-019/D-023:** each player places two relics per enemy on their
starting planets, maximum one per planet, minimum two per tile. Conquest of a
relic planet collects its relic. Two-player games end at **two collected relics**;
larger matches end at **three**. The two-player shortage is resolved.

**Selected P-012:** interpret the minimum per placing player on each tile where
that player places relics, not on every map tile. Relics have a placing player,
but no designated collector. A player collects only relics placed by opponents;
reconquering their own relic planet does not score. Collection removes the relic
from the board permanently; reconquest cannot score it again or steal an already
collected relic. Starting ownership does not collect relics.

Resolve conquest, collection, and victory atomically after any defending force
and retreat have been resolved. Unopposed occupation by ground units also counts
as conquest. Stop further actions immediately at the threshold. Relics are not
collected by production, retreat, ships in space, or an attack with no surviving
attacker. No alternative elimination victory or automatic cycle limit is selected;
resignation may be added separately. Validate that the scenario offers enough
collectible enemy relics and legal routes before using it as a playable fixture.

## Movement and control

**Confirmed D-024:** a Dispatch goes from a tile to an adjacent tile and can target
any eligible area there. Ships need no supporting chain; ground units require an
unbroken line of friendly planets and space units. Range is not area-edge distance.

**Selected P-010:**

- Tile neighbors share a full side, not just a corner. A normal Dispatch changes
  tile exactly once between its endpoints; same-tile rearrangement is excluded
  in this slice. Ships finish in space; ground units finish on planets.
- A Dispatch names one origin area, one destination area, and a list of own unit
  IDs. All must still occupy the origin at execution. No mixed ship/ground group.
  Units never duplicate or split into multiple destinations in one token.
- Ship travel directly connects any space area in the origin tile to any space
  area in its neighbor. Empty, friendly, or enemy destinations are eligible; an
  enemy destination starts a space battle. No fuel, transport chain, or intervening
  area check applies to ships.
- For ground travel, search the **separate edge-sharing area graph** specified in
  `MAP_DESIGN.md`. Every intermediate planet must be owned by the mover and
  uncontested; every intermediate space area needs at least one of the mover's
  ships and no enemy units. The destination may be enemy or neutral. A directly
  touching pair of planets needs no intervening ship.
- Support paths may traverse other tiles; the origin/destination tile adjacency
  requirement still applies. A detour never extends the allowed destination range.
  Support ships are not cargo carriers: they are neither consumed nor moved by
  the ground Dispatch. Check support against actual state at execution, including
  earlier tokens. A promised future ship is not existing support.
- Planet ownership persists when units leave; space control exists only while
  ships occupy it. Routed ships still occupy and support a path, but cannot be
  selected for normal Dispatch. Empty hostile planets are conquered without a
  battle unless a defensive structure can fight. Production/advancement buildings
  alone do not fight and are captured with the planet.

### Retreat — selected P-009/P-010

The losing force must leave. Ground units retreat to a planet with a support path;
ships retreat to space without a support-path requirement. All survivors choose
one friendly destination in a tile adjacent to the battle tile. The losing attacker
may return to its original area if it is still legal; a losing defender cannot use
that origin tile. There is no neutral-destination fallback in this first fixture.
No legal destination means the surviving losers are destroyed. Retreat neither
collects relics nor starts a new battle. Retreating units become routed. Treat it
as a battle outcome, not a second Dispatch; winner/loser decisions and legal paths
are shared by the human and AI interfaces.

## Battle procedure — selected P-009

D-012–D-016 retain three rounds, a card and fresh dice each round, attacker-first
cards, per-round damage/deaths, temporary damage, persistent routing, and final
leadership comparison after damage. The following fills the previous gaps.

### Routing, assignment, and leadership

A unit surviving positive damage becomes routed. Its controller assigns damage,
prioritizing unrouted units; a chosen target takes damage up to remaining health,
then overflow goes to another eligible target. Routed targets are eligible only
when no unrouted target remains. Round-local damage resets; routing persists to
strategic refresh. Routed units provide no leadership, dice, or card prerequisites.
These reference-informed choices use the [Learn to Play, pp. 7, 13](https://images-cdn.fantasyflightgames.com/filer_public/cf/97/cf971a24-1828-4671-a794-83f394380da5/fs01_learn_to_play_lowrez.pdf).

This interprets D-014's leadership loss as the immediate result of routing, with
D-016 extending it beyond that round. Do not automatically restore leadership when
damage clears. A living routed unit remains a survivor for deciding whether both
forces still exist. Both forces consisting only of routed units does not by itself
end a battle early.

Our leadership formula is:

`final leadership = banked dice/card leadership + sum(leadership of living unrouted units)`

Each die/card bonus is banked once, after that round's card resolution. Unit stats
are counted once at final comparison, not added every round. Later routing/death
does not erase already banked bonuses. Compare only after the final damage step;
attacker wins equality. No partial-round leadership comparison declares a winner.

### Numbered sequence

1. **Prepare:** pause the strategic token. Record attacker, defender, origin,
   destination, participants, and RNG state. Set banked leadership to zero. Shuffle
   each player's six-card test deck and draw four; no redraw during battle.
2. **Roll:** in each round, roll fresh dice equal to the attack of currently
   unrouted living units. No pool cap in the test fixture. Faces are attack,
   attack, defense, defense, leadership, leadership on an unbiased six-sided die.
   Publish results. Do not reroll or shrink this round's results after casualties.
3. **Commit cards:** both sides secretly select one card after seeing rolls; lock
   both selections before exposing either. Reveal and resolve attacker first,
   then defender. Mandatory base bonuses apply; check a special effect's required
   living unrouted unit type immediately before that effect. Unless explicitly
   marked `allOf`, any one listed type suffices. Skipped prerequisites do not cancel
   the base bonus. Resolved one-shot effects are not rechecked later.
4. **Calculate:** add this round's leadership dice and card bonuses to its bank.
   `offense = attack dice + card damage bonuses`; `defense = defense dice + card
   defense bonuses + applicable structure defense`. Damage received is
   `max(0, enemy offense − own defense)`. Defense cancels card damage too. Compute
   both damage totals before assigning either; attacker-first cards do not grant
   an extra casualty-before-retaliation privilege for these totals.
5. **Apply damage:** attacker chooses its damage assignment, then defender chooses
   its assignment using the already computed incoming total. Destroy at health;
   nonlethal damage routes. Resolve both sides even if the first becomes empty.
   Direct-effect damage, if later added to a card, requires its own explicit timing;
   none of the initial cards bypasses this damage step.
6. **Check survival:** if only one force survives, it wins now; if neither survives,
   there is no victor or relic collector and prebattle ownership remains. Defensive
   structures count as forces for survival as specified below. Otherwise continue
   through round three; then compare final leadership.
7. **Finish round/battle:** clear round-local damage and attack/defense/card bonuses.
   Keep routed state and banked leadership between rounds. After battle, resolve
   retreat, capture surviving structures, transfer ownership if an attacker survives
   and wins, collect any eligible relic, and check match victory. Return all cards
   to their owner's deck, clear the battle bank, and resume the paused token once
   unless the match has ended. Rally routed units only at strategic refresh.

Attack/defense and all initial card bonuses apply for one round only. Leadership
alone banks across rounds. This deliberately simplifies persistent card displays
while keeping the user's accumulation rule and fresh-round rolls.

## Production and economy — selected P-011

A production building enables unit construction in its own tile. This limited
reach follows the [Rules Reference's Deploy Order, p. 6](https://images-cdn.fantasyflightgames.com/filer_public/5f/19/5f19d872-318e-4fcf-a398-626721f5c55c/fs01_rules_reference_lowrez.pdf); the following costs and restrictions are our test choices.

Each Build produces one named unit or one structure. Ground production requires
an owned planet destination and an owned production building somewhere in that
tile; space production requires an empty or friendly space destination in that
tile. Production never starts combat. Construct a building on an owned planet;
buildings do not require a production building. Allow one instance of each of the
three structure types per planet. All purchases also require their alloy cost.

Advancement eligibility tracks the distinct planets where that player has
completed an advancement building, capped at two credits. Credit persists after
loss; capture gives none; rebuilding at the same site gives no additional credit.
This implements the user's “has built” requirement rather than substituting the
reference's current-city-ownership rule. Existing units are never downgraded.

| Test item | Attack / health / leadership | Alloy cost | Advancement count |
| --- | --- | --- | --- |
| Ground 1 | 1 / 3 / 1 | 2 | 0 |
| Ground 2 | 2 / 4 / 1 | 4 | 1 |
| Ground 3 | 3 / 5 / 2 | 6 | 2 |
| Space 1 | 1 / 3 / 1 | 2 | 0 |
| Space 2 | 2 / 5 / 2 | 5 | 2 |
| Production building | No combat contribution | 3 | — |
| Advancement building | No combat contribution | 3 | — |
| Defense building | 1 / 3 / 0, plus 1 defense per round on its planet | 3 | — |

A defense building is a structure, not a unit: it cannot move, rout, satisfy unit
prerequisites, or retreat. It may defend alone. Its controller may assign damage
to it alongside unrouted units; destroy it at health, otherwise reset damage at
round end. A surviving defense building is captured if the attacker wins. None of
these test numbers or structure slots establishes final faction balance.

Extract at an owned planet adds 3 alloy; strategic refresh adds 2 alloy per player
and rallies routed units. No influence scoring. Initial test decks have two copies
each of **Strike** (+1 damage), **Guard** (+1 defense), and **Focus** (+1 leadership).
For prerequisite checks, Focus additionally grants +1 leadership if its owner has
an unrouted Ground 1 or Space 1 participant. Names and numbers are fixture content.

## Strategic planning — selected P-001–P-004

Each player privately assigns three tokens to numbered slots during the same
planning phase. Dispatch commits origin, destination and unit IDs; Build commits
its planet/space destination, facility if applicable, and purchase type; Extract
commits its planet. Structural validation catches wrong domains, missing IDs,
nonneighboring destination tiles, and malformed parameters. Ownership, available
units, support paths, prerequisites and funds are rechecked at execution.

Plans lock on commitment and reveal only after everyone commits. Resolve each
slot for the initiative player and then the opponent; rotate initiative each cycle.
Warn about conditional plans and use identical validation/projection rules for both
controllers. An invalidated token is consumed with a reason and no partial movement
or costs. A battle pauses that token. The token completes exactly once after battle
and collection. Refresh follows all tokens, unless match victory already occurred.
Shared stacks, multi-destination orders, and speculative future-unit IDs are outside
this slice. Planning can refer only to unit IDs already present in match state.

## Worked three-round battle — verified fixture

Use one Ground 1 per side, no structures, no retreat effects, and four-card hands
containing Guard, Focus, Focus, Strike. These fixed roll results are deliberate
inputs; a seeded test must reproduce or inject them. Both start at 0 banked leadership.

| Round | Attacker roll / card | Defender roll / card | Expected result |
| --- | --- | --- | --- |
| 1 | Attack / Guard | Leadership / Guard | No damage: defender's defense cancels attack. Banks A=0, D=1. |
| 2 | Leadership / Focus | Defense / Focus | No damage. Both Focus prerequisites succeed. Banks A=3, D=3. |
| 3 | Attack / Focus | Leadership / Focus | Both prerequisites succeed before damage. Banks A=5, D=6. Defender receives 1 damage and routes; attacker is unharmed. |

After final damage, attacker leadership is `5 + 1 = 6`; defender is `6 + 0 = 6`.
Attacker wins the tie. Defender must retreat via the selected legal-path rule or
be destroyed. Damage reset does not restore defender leadership before comparison.
Reusing this fixture with Space 1 units exercises the same battle calculations.

Additional damage fixture: two health-3 units take 4 incoming damage. Their owner
chooses the first to die for 3; the remaining 1 routes the second. Two health-3
opponents each receiving 3 damage in the same round both die; there is no winner
or relic collection. The Godot battle suite verifies the worked battle in both
domains and these damage cases; see `PLAYTEST.md` for coverage and limitations.
