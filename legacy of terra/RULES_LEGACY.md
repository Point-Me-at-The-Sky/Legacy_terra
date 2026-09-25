# Legacy rules experiment v0.1 — historical reference

**Superseded and not implemented as a complete experiment.** This preserves the
old quadrant planning fixture, not the browser baseline or the current rules.
Planet-built ships and attrition contradict confirmed requirements. Numerical
outcomes below must not become acceptance tests for new gameplay. Current rules
are in [RULES.md](RULES.md); status is in [DECISIONS.md](DECISIONS.md).

## Map and setup (legacy v0.1)

The map uses square tiles, each with four quadrants arranged NW, NE, SW, SE.
Each quadrant represents either a planet or a space area. This structure is
confirmed; the following gameplay details are proposals.

Use [MAP_DESIGN.md](MAP_DESIGN.md) for IDs and adjacency. A quadrant holds one
owner (or neutral), a nonnegative fleet count, and optional relay/home markers.
Both area types admit fleets. Build and Extract require planets. Empty owned
areas retain ownership. Relays are scenario-defined planet markers for this
experiment, not a third area type.

For a standard experimental scenario, give each faction one distinct home planet,
five ships, five alloy, and zero influence. Other areas begin neutral and empty
unless the scenario specifies otherwise. Start at cycle one with Ember initiative;
swap starting faction in paired playtests. The balanced map size is still open.

## Cycle and information

1. **Plan simultaneously.** Both factions work from the same public board state. Each privately assigns three tactics tokens to numbered execution slots 1–3. Repeated action types are allowed. Tokens are placed on origin quadrants, with slot numbers visible to their owner. Neither side can inspect the opponent's placements or parameters.
2. **Commit.** Players may edit or undo until committing. Committed plans lock; ready status is public. A first commitment neither reveals its plan nor starts resolution. No planning timer is proposed for the initial solo experiment.
3. **Reveal.** Once both plans are committed, reveal all tokens and parameters together. The AI must complete its plan using its permitted view before reading the human plan.
4. **Resolve.** The initiative faction executes slot 1, then the other faction executes slot 1; repeat for slots 2 and 3. This order is explicit and is independent of placement or submission speed. Each token is consumed once, including failed tokens.
5. **Refresh.** After all six tokens, each owned relay earns one influence and each faction gains two alloy. Evaluate end conditions. Otherwise advance the cycle, rotate initiative, clear commitments, and return three tokens to each player.

Resolution is sequential even though placement is simultaneous. The earlier
prototype's last-in-first-out stack is not the proposed numbered-slot rule.

## Tokens and validation

All token parameters are committed for this first experiment (P-004). Choosing
units or destinations at execution time remains a later comparison.

| Token | Committed parameters | Requirements at execution | Effect |
| --- | --- | --- | --- |
| Dispatch | Origin, adjacent destination, positive whole ship count | Own the origin; have the requested ships; destination is adjacent | Remove ships from origin and resolve arrival at destination |
| Build | Origin planet | Own the planet and have at least two alloy | Spend two alloy; add two ships |
| Extract | Origin planet | Own the planet | Gain three alloy |

Structural errors prevent commitment: missing slots, unknown action or area IDs,
nonadjacent Dispatch destinations, nonpositive/noninteger counts, or Build/Extract
on space. A plan must contain exactly three structurally valid tokens.

Ownership, available ships, and available alloy can change during resolution.
Treat these as conditional requirements: warn during planning, but allow commitment
of structurally valid plans that rely on a capture, build, or extraction. Show a
projection of the player's own slot sequence with a warning that opposing actions
may invalidate it. Apply identical validation to human and AI plans.

Do not reserve resources at commitment. Recheck all requirements immediately
before each token. If any fail, consume that token without moving ships or spending
alloy, explain the specific reason, and continue. There are no automatic retargets,
partial dispatches, or replacement tokens in this experiment.

## Arrival and combat

- Friendly destination: add the arriving ships to its fleet.
- Neutral or enemy destination: both fleets lose the smaller fleet count.
- Surviving attackers take ownership with their surviving ships.
- Surviving defenders keep ownership and their surviving ships.
- Equal fleets leave the destination neutral and empty.
- Entering an empty neutral or enemy area captures it with all arriving ships.
- Leaving an origin empty does not remove its ownership. Tokens referring to a captured area remain in their original plan and succeed or fail when their slot resolves.

No retreat, randomness, ground troops, or separate battle-token system is included
in this rules experiment. Opposing moves across an edge are processed in slot
order; fleets do not pass each other simultaneously or fight mid-route.

## End conditions

Evaluate only after refresh, never halfway through the six-token resolution.

1. A faction owning no areas is eliminated. If only one survives, it wins regardless of score. If neither survives, draw (a defensive rule for unusual scenarios).
2. Otherwise end when either score reaches 12 influence or cycle eight completes. Higher influence wins; equal scores draw.
3. Otherwise continue. Losing a home planet is not an immediate defeat.

## Worked round: contested relay

This single square is a rule fixture, not a balanced match map. NW and SE are home
planets; NE is a neutral relay planet; SW is neutral space. Ember owns NW with four
ships; Vesper owns SE with three. Each starts with five alloy and zero influence.
Ember has initiative. NW→NE and SE→NE are legal orthogonal moves.

| Slot | Ember's hidden plan | Vesper's hidden plan |
| --- | --- | --- |
| 1 | Dispatch 3, NW → NE | Dispatch 3, SE → NE |
| 2 | Build at NW | Build at SE |
| 3 | Extract at NW | Extract at SE |

Both place their tokens in the same planning phase. Ember's early commitment
would reveal nothing. After both commit:

1. Ember captures NE with three ships, leaving one at NW.
2. Vesper attacks NE with three ships. Both fleets are destroyed; NE is neutral. SE remains owned despite being empty.
3. Ember builds: NW now has three ships and Ember has three alloy.
4. Vesper builds: SE now has two ships and Vesper has three alloy.
5. Each extracts, bringing each alloy balance to six.
6. Refresh adds two alloy each. Both finish with eight alloy and zero influence; no one owns the relay. Cycle two begins with Vesper initiative.

## Conditional-order example

In another round, Ember commits slot 1 Dispatch from an owned planet to a neutral
adjacent planet, then slot 2 Build at the destination. The plan is structurally
valid, but Build is conditional. If Ember still owns the destination when slot 2
executes and has two alloy, it builds. If Vesper captures it between those tokens,
Build fails and consumes no alloy. The AI follows the same rule.

## Required checks for implementation

Verify the worked round, conditional capture/build success and failure, commitment
locking, no reveal before all commitments, AI information limits, equal-fleet ties,
failed tokens with no partial costs, rotating initiative, scoring once per cycle,
and deterministic results independent of submission order. See
[PLAYTEST.md](PLAYTEST.md) for manual evaluation.
