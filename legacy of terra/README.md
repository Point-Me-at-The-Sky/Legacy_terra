# Legacy of Terra

A strategy game set in a universe where ancient humans introduced magic by breaking reality. Their advanced civilization is long gone; aliens and strange human offshoots or remnants now compete for relics amid magic and advanced technology.

Active development uses **Godot 4.7.2 standard edition and typed GDScript**, with Compatibility rendering. The prototype has a movement lab and a playable three-round battle lab. Production, conquest/relic victory, and complete tactics matches come next. The older browser game remains playable as a historical reference.

Open [the game design document](GAME_DESIGN.html) in your browser, or edit its [Markdown source](GAME_DESIGN.md), for the vision, selected rules, implementation status, and future multiplayer scope.

The legacy browser game's header also links directly to the document in a new tab. The document's browser edition includes a contents menu and print styling (use your browser’s Print → Save as PDF to export it).

## Run the Godot prototype

1. Download the **standard** build of [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/) for your operating system; .NET is unnecessary for GDScript.
2. Import [godot/project.godot](godot/project.godot) in the Godot project manager.
3. Open the project and press **F5** to run it.

Choose a scenario, select an occupied area, select units, then choose a highlighted destination. Ships can move to any space area in an adjacent tile. Try **Transport path · intact** to move ground units along a chain of ships; compare **Transport path · broken**. The player selector lets you inspect either side. Tab and arrow keys move focus; Enter/Space selects, Escape clears selection.

The movement lab allows unopposed movement and displays unit stats. Its unrestricted moves are a development tool, not the match turn system. Map attacks remain previews until conquest can resolve battle, structure capture, relic collection, and victory together.

Click **Battle lab** to fight a ground skirmish, space skirmish, or a defense building.
You control Ember against a deterministic Vesper opponent. Each round shows public
dice; choose a card, assign incoming damage to eligible targets, and choose a retreat
if you lose. Cards resolve attacker-first after both choices lock. Damaged survivors
rout, damage clears each round, and accumulated leadership plus surviving unrouted
units decides the final round; attacker wins ties. The battle record explains results.

**Restart same seed** repeats the initial deal and rolls; different decisions can
change later rolls as forces change. **New seed** gives another deal. Tab and
Enter/Space work for battle choices. The battle lab is isolated from the movement
board and does not collect relics. Its opponent is a battle policy, not strategic AI.

For command-line use, install Python 3 and optionally Node.js/npm. Set `GODOT_BIN` to the engine executable if `godot` or `godot4` is not on PATH:

```sh
export GODOT_BIN="/path/to/Godot_v4.7.2-stable_linux.x86_64"
npm run godot:editor
npm run godot:run
npm run godot:test
```

These commands invoke `python3 scripts/godot.py editor`, `run`, or `test`; npm is only a convenience. The runner verifies the version in `godot/.godot-version` and never downloads or installs an engine. On Windows, opening the project directly avoids requiring the shell tools.

## Run the legacy browser

From this directory, run `npm start` and open http://localhost:8080. Run `npm test` for its existing rule checks. These commands do not run or test the Godot game. The browser runtime has no external dependencies or build step.

## Project documents

| Document | Purpose |
| --- | --- |
| [Game design](GAME_DESIGN.md) · [browser edition](GAME_DESIGN.html) | Vision, confirmed direction, and proposed systems |
| [Decisions](DECISIONS.md) | Confirmed requirements, proposed defaults, and open choices |
| [Rules](RULES.md) | Confirmed requirements, selected v0.2 rules, and worked battle |
| [Legacy fixture](RULES_LEGACY.md) | Historical v0.1 rules; not an implementation target |
| [Map design](MAP_DESIGN.md) | Square tiles, tile-range movement, ground-support graph, and map fixtures |
| [Roadmap](ROADMAP.md) | Current status, next task, and acceptance criteria |
| [Architecture](ARCHITECTURE.md) | Current code and intended implementation boundaries |
| [Playtesting](PLAYTEST.md) | Verification scenarios and an empty session template |
| [Contributor instructions](AGENTS.md) | Guidance for future coding sessions |

The browser currently implements eight world nodes, reversed private command
queues, and deterministic attrition. It does **not** implement the confirmed tile
map, simultaneous tactics-token planning, unit stats, structures, or card battles.

The intended game uses four-quadrant square tiles and three-round card-and-dice
battles. Match victory is based on collecting relics, represented by objective tokens placed on starting planets; conquering a token’s planet collects it. Collect two relics to win a two-player game, or three in larger matches. Movement targets an adjacent tile; ships need no support path, while ground forces require a continuous friendly path. Read [current rules](RULES.md) for the confirmed mechanics and open
questions; use [the decision log](DECISIONS.md) to distinguish requirements from
proposals. The [roadmap](ROADMAP.md) sequences economy/relic rules and full turn integration. Reference-informed defaults remain revisable; map/movement and standalone combat/retreat are implemented in Godot so far.

## Build the design document

Use Python 3 and Node.js/npm for the existing project commands. To install the documentation-only dependency in an isolated environment:

```sh
python3 -m venv .venv
. .venv/bin/activate
python3 -m pip install -r requirements-docs.txt
npm run docs:build
npm run docs:check
```

Edit `GAME_DESIGN.md`, then rebuild. Presentation lives in `scripts/game_design.template.html`. The generated HTML is included in the project and can be opened without Python or an active server. `docs:check` exits unsuccessfully when the HTML is stale and does not modify files. It also checks local links and section anchors. The other project documents remain Markdown.

## Legacy browser rules

You control the orange Ember Union. Select a friendly world and queue three commands. The command stack displays execution order: the last command you add executes first. Commit, then resolve each alternating player/AI action. The opening faction alternates each cycle.

- Dispatch moves ships to an adjacent world. Friendly fleets combine. In combat, fleets remove equal numbers of opposing ships; surviving attackers capture the world. An exact tie leaves a neutral world. Empty owned worlds remain owned until captured.
- Build spends 2 alloy for 2 ships. Extract earns 3 alloy.
- Commands are checked when queued and again when executed. An invalidated command is consumed without effect. Queue against your current holdings; future captured worlds become available for planning next cycle.
- Each controlled diamond relay earns 1 influence at cycle end. Both factions also receive 2 alloy.
- Elimination wins at cycle end. Otherwise, reaching 12 influence or completing cycle 8 ends the match; highest influence wins, equal scores draw.

## Scope and next steps

The Godot project separates content, rules, controllers, and presentation.
`godot/rules/` owns movement and battle transitions; `godot/ui/` consumes permitted
views and choices. The battle policy receives the same filtered information as a
human controller. Headless tests cover rule outcomes, replay, privacy, and scene
interactions. Next: production and relic conquest, then simultaneous tactics planning
and a complete human-versus-AI match.

The legacy `engine.js` and `app.js` remain unchanged references for an older experiment. Neither runtime implements saving or networking. See [ARCHITECTURE.md](ARCHITECTURE.md) for the boundaries new gameplay must follow.
