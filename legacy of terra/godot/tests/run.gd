extends SceneTree

const BoardMap = preload("res://rules/board_map.gd")
const Fixtures = preload("res://content/fixtures.gd")
const Movement = preload("res://rules/movement.gd")
const MainScene = preload("res://scenes/main.tscn")
const BattleTests = preload("res://tests/battle_tests.gd")

var checks: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_map()
	_test_movement()
	_test_support()
	_test_transitions()
	var battles: RefCounted = BattleTests.new()
	battles.run()
	checks += battles.checks
	failures.append_array(battles.failures)
	await _test_interface()
	for failure: String in failures:
		printerr("FAIL: " + failure)
	print("Godot checks: %d passed, %d failed." % [checks - failures.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)


func _action(origin: String, destination: String, ids: Array) -> Dictionary:
	return {"type": "dispatch", "origin": origin, "destination": destination, "unit_ids": ids}


func _test_map() -> void:
	var definition: Dictionary = Fixtures.map_definition()
	var original: Dictionary = definition.duplicate(true)
	var board: Dictionary = BoardMap.build(definition)
	_check(board.ok and board.areas.size() == 8, "Two tiles produce eight independent areas")
	_check(definition == original, "Map construction does not mutate input content")
	_check(board.tile_neighbors["tile-a"] == ["tile-b"], "Side-sharing tiles are neighbors")
	_check(not "tile-b:se" in board.support_neighbors["tile-a:sw"], "Area support does not collapse to tile range")
	for id: String in board.support_neighbors:
		_check(not id in board.support_neighbors[id], "No support self-edge: " + id)
		for neighbor: String in board.support_neighbors[id]:
			_check(id in board.support_neighbors[neighbor], "Symmetric support edge")
	var invalid: Dictionary = definition.duplicate(true)
	invalid.tiles[0].quadrants.erase("nw")
	_check(not BoardMap.build(invalid).ok, "Reject missing quadrant")
	invalid = definition.duplicate(true)
	invalid.tiles[1].position = [0, 0]
	_check(not BoardMap.build(invalid).ok, "Reject overlapping tiles")
	invalid = definition.duplicate(true)
	invalid.tiles[1].id = "tile-a"
	_check(not BoardMap.build(invalid).ok, "Reject duplicate tile IDs")
	invalid = definition.duplicate(true)
	invalid.tiles[1].quadrants.nw.id = "tile-a:nw"
	_check(not BoardMap.build(invalid).ok, "Reject duplicate area IDs")
	invalid = definition.duplicate(true)
	invalid.tiles[0].quadrants.nw.type = "relic"
	_check(not BoardMap.build(invalid).ok, "Relic is not an area type")
	invalid = definition.duplicate(true)
	invalid.tiles[1].position = [1, 1]
	_check(BoardMap.build(invalid).tile_neighbors["tile-a"].is_empty(), "Corners do not connect tiles")
	invalid.tiles[1].position = [2, 0]
	_check(BoardMap.build(invalid).tile_neighbors["tile-a"].is_empty(), "Missing tile gap cannot be jumped")
	_check(not BoardMap.build({"tiles": [null]}).ok, "Malformed tile rejected without crash")
	_check(not BoardMap.build({}).ok, "Missing tiles rejected")
	# Names and coordinates can change without changing identities.
	invalid = definition.duplicate(true)
	invalid.tiles[0].position = [-1, 0]
	invalid.tiles[1].position = [0, 0]
	_check(BoardMap.build(invalid).areas.has("tile-a:nw"), "Stable IDs survive repositioning")


func _test_movement() -> void:
	var f: Dictionary = Fixtures.create()
	_check(Movement.validate_state(f.board, f.state, Fixtures.UNIT_TYPES).is_empty(), "Starting fixture state is valid")
	var state: Dictionary = f.state
	var board: Dictionary = f.board
	var ship: String = "tile-a-ship"
	var action: Dictionary = _action("tile-a:se", "tile-b:se", [ship])
	var result: Dictionary = Movement.legal_action(board, state, Fixtures.UNIT_TYPES, 0, action)
	_check(result.ok and result.battle_required, "Ship can target non-touching hostile space in adjacent tile")
	_check(result.path.is_empty(), "Ship needs no ground-support path")
	_check(not Movement.legal_action(board, state, Fixtures.UNIT_TYPES, 1, action).ok, "Cannot command enemy units")
	_check(not Movement.legal_action(board, state, Fixtures.UNIT_TYPES, 0, _action("tile-a:se", "tile-b:nw", [ship])).ok, "Ship cannot land on a planet")
	_check(not Movement.legal_action(board, state, Fixtures.UNIT_TYPES, 0, _action("tile-a:se", "tile-a:sw", [ship])).ok, "Same-tile Dispatch is rejected")
	_check(not Movement.legal_action(board, state, Fixtures.UNIT_TYPES, 0, _action("tile-a:se", "tile-b:sw", [ship, ship])).ok, "Duplicate units are rejected")
	_check(not Movement.legal_action(board, state, Fixtures.UNIT_TYPES, 0, _action("tile-a:se", "tile-b:sw", [])).ok, "Empty force is rejected")
	_check(not Movement.legal_action(board, state, Fixtures.UNIT_TYPES, 0, {"type": "dispatch"}).ok, "Missing parameters rejected")
	_check(not Movement.legal_action(board, state, Fixtures.UNIT_TYPES, 0, _action("unknown", "tile-b:sw", [ship])).ok, "Unknown origin rejected")
	state.units[ship].routed = true
	_check(not Movement.legal_action(board, state, Fixtures.UNIT_TYPES, 0, action).ok, "Routed units cannot Dispatch")
	var bad: Dictionary = state.duplicate(true)
	bad.units[ship].area_id = "tile-a:nw"
	_check(not Movement.validate_state(board, bad, Fixtures.UNIT_TYPES).is_empty(), "Invalid domain placement fails state validation")
	bad = state.duplicate(true)
	bad.units[ship].area_id = "missing"
	_check(not Movement.validate_state(board, bad, Fixtures.UNIT_TYPES).is_empty(), "Unknown unit area fails state validation")


func _test_support() -> void:
	var f: Dictionary = Fixtures.create(true)
	var action: Dictionary = _action("tile-a:nw", "tile-b:nw", ["a-ground"])
	var result: Dictionary = Movement.legal_action(f.board, f.state, Fixtures.UNIT_TYPES, 0, action)
	_check(result.ok, "Intact transport chain enables ground movement")
	_check(result.path == ["tile-a:nw", "tile-a:sw", "tile-a:se", "tile-b:sw", "tile-b:nw"], "Returned path shows the actual supporting areas")
	for ship: String in ["support-1", "support-2", "support-3"]:
		var broken: Dictionary = f.state.duplicate(true)
		broken.units.erase(ship)
		_check(not Movement.legal_action(f.board, broken, Fixtures.UNIT_TYPES, 0, action).ok, "Removing necessary ship breaks transport: " + ship)
	var routed: Dictionary = f.state.duplicate(true)
	routed.units["support-2"].routed = true
	_check(Movement.legal_action(f.board, routed, Fixtures.UNIT_TYPES, 0, action).ok, "Routed ship still occupies and supports its space")
	var contested: Dictionary = f.state.duplicate(true)
	contested.units.enemy = {"id": "enemy", "area_id": "tile-a:se", "owner": 1, "type_id": "space_1", "routed": false, "damage": 0}
	_check(not Movement.legal_action(f.board, contested, Fixtures.UNIT_TYPES, 0, action).ok, "Contested space breaks support")
	# An alternate top route makes a missing bottom support nonfatal.
	var alternative: Dictionary = f.state.duplicate(true)
	alternative.units.erase("support-2")
	alternative.units.extra = {"id": "extra", "area_id": "tile-a:ne", "owner": 0, "type_id": "space_1", "routed": false, "damage": 0}
	_check(Movement.legal_action(f.board, alternative, Fixtures.UNIT_TYPES, 0, action).ok, "Search discovers an alternate support route")
	var standard: Dictionary = Fixtures.create()
	_check(Movement.legal_action(standard.board, standard.state, Fixtures.UNIT_TYPES, 0, _action("tile-a:ne", "tile-b:nw", ["tile-a:ne-ground"])).ok, "Touching planets need no intermediate ship")
	# A friendly intermediate planet supports; a neutral or enemy one does not.
	standard.state.owners["tile-a:ne"] = 1
	_check(not Movement.legal_action(standard.board, standard.state, Fixtures.UNIT_TYPES, 0, _action("tile-a:nw", "tile-b:nw", ["tile-a:nw-ground"])).ok, "Enemy intermediate planet blocks ground travel")


func _test_transitions() -> void:
	var f: Dictionary = Fixtures.create(true)
	var snapshot: Dictionary = f.state.duplicate(true)
	var action: Dictionary = _action("tile-a:nw", "tile-b:nw", ["a-ground"])
	var result: Dictionary = Movement.apply_lab_move(f.board, f.state, Fixtures.UNIT_TYPES, 0, action)
	_check(result.ok and result.state.units["a-ground"].area_id == "tile-b:nw", "Unopposed sandbox move relocates a unit")
	_check(f.state == snapshot, "Successful transition does not mutate input")
	_check(result.state.owners["tile-a:nw"] == 0, "Empty starting planet retains ownership")
	_check(result.state.events.size() == 1, "Exactly one movement event")
	_check(result.state.units["support-2"].area_id == "tile-a:se", "Transport does not consume or move supporting ships")
	_check(not Movement.apply_lab_move(f.board, result.state, Fixtures.UNIT_TYPES, 0, action).ok, "Stale repeated action cannot duplicate a unit")
	f.state.units.erase("support-2")
	snapshot = f.state.duplicate(true)
	_check(not Movement.apply_lab_move(f.board, f.state, Fixtures.UNIT_TYPES, 0, action).ok, "Execution rechecks support")
	_check(f.state == snapshot, "Failed transition causes no partial movement")
	f = Fixtures.create()
	snapshot = f.state.duplicate(true)
	result = Movement.apply_lab_move(f.board, f.state, Fixtures.UNIT_TYPES, 0, _action("tile-a:se", "tile-b:se", ["tile-a-ship"]))
	_check(not result.ok and f.state == snapshot, "Lab blocks combat rather than inventing attrition")
	f.state.units.erase("tile-b:nw-ground")
	result = Movement.apply_lab_move(f.board, f.state, Fixtures.UNIT_TYPES, 0, _action("tile-a:ne", "tile-b:nw", ["tile-a:ne-ground"]))
	_check(not result.ok, "Lab blocks incomplete relic-conquest transaction")
	var same_fixture: Dictionary = Fixtures.create()
	_check(same_fixture.state.units.has("tile-b:nw-ground"), "Fixture mutations do not leak into new games")


func _test_interface() -> void:
	var main: Control = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_check(main.area_buttons.size() == 8, "Scene renders all eight selectable areas")
	_check(main.get_viewport().gui_get_focus_owner() == main.area_buttons["tile-a:nw"], "Initial keyboard focus is visible on an area")
	main.area_buttons["tile-a:se"].pressed.emit()
	main.area_buttons["tile-b:sw"].pressed.emit()
	_check(not main.move_button.disabled, "UI enables legal unopposed ship movement")
	main.move_button.pressed.emit()
	_check(main.state.units["tile-a-ship"].area_id == "tile-b:sw", "Button flow executes the shared rule transition")
	main.load_fixture(1)
	main.area_buttons["tile-a:nw"].pressed.emit()
	main.area_buttons["tile-b:nw"].pressed.emit()
	_check(main.route.size() == 5 and not main.move_button.disabled, "UI exposes transport route")
	main.load_fixture(2)
	main.area_buttons["tile-a:nw"].pressed.emit()
	main.area_buttons["tile-b:nw"].pressed.emit()
	_check(main.move_button.disabled and main.route.is_empty(), "Broken-route UI cannot execute movement")
	main.load_fixture(0)
	main.area_buttons["tile-a:ne"].pressed.emit()
	main.area_buttons["tile-b:nw"].pressed.emit()
	_check(main.move_button.disabled and main.destinations.has("tile-b:nw"), "Hostile destination is previewed but not auto-resolved")
	main._change_player(1)
	_check(main.selected_units.is_empty() and main.origin.is_empty(), "Changing controller clears stale selections")
	await process_frame
	for button: Button in main.area_buttons.values():
		_check(button.size.x >= 155 and button.size.y >= 148, "Readable area hit target dimensions")
		_check(button.focus_mode == Control.FOCUS_ALL, "Every area is keyboard focusable")
	var movement_snapshot: Dictionary = main.state.duplicate(true)
	main._open_battle_lab()
	await process_frame
	var lab: Control = main.battle_lab
	_check(not main.movement_panel.visible and lab.action_buttons.size() == 4, "Battle lab opens with a four-card hand")
	_check(lab.battle_state.sides[1].commitment != "", "Opponent commits without seeing human card")
	_check(root.gui_get_focus_owner() == lab.action_buttons[0], "Battle card receives keyboard focus")
	for scenario: int in range(3):
		lab.start_battle(scenario)
		for step: int in range(50):
			if lab.battle_state.step == "finished": break
			_check(not lab.action_buttons.is_empty(), "Battle UI offers a permitted human choice")
			if lab.action_buttons.is_empty(): break
			lab.action_buttons[0].pressed.emit()
			await process_frame
		_check(lab.battle_state.step == "finished", "Battle UI completes scenario %d" % scenario)
		_check(not lab.outcome_label.text.is_empty(), "Battle UI explains the outcome")
	_check(main.state == movement_snapshot, "Battle lab does not partially mutate the movement map")
	lab.back_button.pressed.emit()
	await process_frame
	_check(main.movement_panel.visible and not is_instance_valid(main.battle_lab), "Returning from battle restores movement")
	main.queue_free()
	await process_frame
