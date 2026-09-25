# Legacy of Terra — contributor instructions

## Start here

Read [README.md](README.md), [DECISIONS.md](DECISIONS.md), and
[ROADMAP.md](ROADMAP.md). Before implementation, read
[ARCHITECTURE.md](ARCHITECTURE.md); for gameplay also read [RULES.md](RULES.md),
and for maps read [MAP_DESIGN.md](MAP_DESIGN.md). The roadmap identifies what can
be built now and which decisions block later integration.

## Design authority

- Follow the user's latest explicit instructions. Record new requirements in the decision log.
- Use the D-series entries in `DECISIONS.md` for confirmed requirements; do not treat a short summary elsewhere as exhaustive.
- Keep **confirmed**, **selected experiment**, **proposed**, **implemented**, and **open** distinct. Assistant-written defaults and worked examples do not become user-approved rules automatically.
- Document ownership: `DECISIONS.md` owns requirement status and unresolved choices; `RULES.md` owns current gameplay semantics; `MAP_DESIGN.md` owns map geometry; `ARCHITECTURE.md` owns code boundaries; `ROADMAP.md` owns task order and acceptance criteria; `GAME_DESIGN.md` explains the vision; `PLAYTEST.md` owns verification scenarios. Current source code establishes implemented behavior.
- `RULES_LEGACY.md` is historical reference only. Never implement its superseded production or combat rules as the intended game.
- Before coding, identify the relevant decision IDs, proposal status, required inputs, and expected outcomes. Use documented proposals only within the authorized experiment; label fixture values as test data. If an open rule changes the outcome, first check whether the user has delegated its resolution. Selected experiments in `RULES.md` may be implemented within scope without asking again; otherwise ask for that rule and continue independent work. Routine implementation choices need no extra approval.
- Resolve discrepancies explicitly and update affected documents together. Do not silently turn current prototype limitations into permanent design requirements.

## Implementation

- Active development is in `godot/`, using Godot 4.7.2 standard edition, typed GDScript, and Compatibility rendering (D-025). Preserve the legacy browser as a playable reference; do not build new gameplay there unless requested. Keep the engine pin in `godot/.godot-version` synchronized with project documentation.
- Keep rules independent of the DOM, AI policy, and presentation. Keep static unit/card definitions separate from mutable unit instances and battle state. Give human and AI controllers the same legal-action interface and permitted information.
- Use stable tile and quadrant IDs in the new map model. Keep logical adjacency separate from screen coordinates. Tile-neighbor movement range and area-edge ground-support paths are separate graphs (D-024/P-010). Do not treat a four-quadrant tile as a single world.
- Keep game changes scoped to the current roadmap task. Avoid implementing speculative multiplayer, extra resources, or faction systems along with basic planning work.
- Preserve unrelated edits. Do not introduce a framework or runtime dependency without a concrete need.

## Documentation and checks

- Edit `GAME_DESIGN.md` as the design-document source. `GAME_DESIGN.html` is generated; change its presentation in `scripts/game_design.template.html`.
- Run `npm run docs:build` after editing the source or template; run `npm run docs:check` to verify the generated page is current.
- Run `npm run godot:test` for Godot changes; set `GODOT_BIN` to the pinned executable if it is not on PATH. The headless suite includes rule and scene interaction checks. Run `npm test` for the preserved browser baseline. Add meaningful scenarios from `RULES.md` and `PLAYTEST.md`, distinguishing implemented movement from future combat checks.
- Run `npm run godot:run` for manual Godot checks. Verify changed flows, readable text, and keyboard focus. The optional `godot/tests/visual_smoke.gd` captures graphical screens. Use `npm start` only when checking the legacy browser.
- Update the roadmap when implementation status changes. Report what changed, what was verified, and any remaining limitations.

These instructions do not require extra approval for routine work within the user's request.
