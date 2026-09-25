extends Control
## Presentation/controller only. All destinations and paths come from Movement.

const Fixtures = preload("res://content/fixtures.gd")
const Movement = preload("res://rules/movement.gd")
const BattleLab = preload("res://ui/battle_lab.gd")
const INK: Color = Color("dfe8f2")
const MUTED: Color = Color("9caec3")
const AMBER: Color = Color("f4b563")
const VIOLET: Color = Color("b7a0ed")
const TEAL: Color = Color("71dac5")

var board: Dictionary = {}
var state: Dictionary = {}
var actor: int = 0
var origin: String = ""
var destination: String = ""
var selected_units: Array[String] = []
var destinations: Dictionary = {}
var route: Array[String] = []
var area_buttons: Dictionary = {}
var scenario_picker: OptionButton
var player_picker: OptionButton
var board_box: HBoxContainer
var unit_box: VBoxContainer
var details: Label
var route_label: Label
var message: Label
var move_button: Button
var history: Label
var movement_panel: MarginContainer
var battle_lab: Control


func _ready() -> void:
	_build_interface()
	load_fixture(0)
	(area_buttons["tile-a:nw"] as Button).grab_focus()


func _build_interface() -> void:
	theme = Theme.new()
	theme.default_font_size = 16
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color("75869a"))
	theme.set_stylebox("normal", "Button", _style(Color("152437"), Color("33465c")))
	theme.set_stylebox("hover", "Button", _style(Color("22384e"), TEAL))
	theme.set_stylebox("pressed", "Button", _style(Color("243f4d"), TEAL))
	theme.set_stylebox("disabled", "Button", _style(Color("101b2a"), Color("263447")))
	var focus: StyleBoxFlat = _style(Color(0, 0, 0, 0), Color.WHITE, 3)
	theme.set_stylebox("focus", "Button", focus)
	var margin: MarginContainer = MarginContainer.new()
	movement_panel = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var scroll: ScrollContainer = ScrollContainer.new()
	margin.add_child(scroll)
	var root_box: VBoxContainer = VBoxContainer.new()
	root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_box.add_theme_constant_override("separation", 16)
	scroll.add_child(root_box)
	root_box.add_child(_label("LEGACY OF TERRA  /  MOVEMENT LAB", 14, AMBER))
	root_box.add_child(_label("Across the broken universe", 32, INK))
	root_box.add_child(_label("Select a force, then an area in a neighboring tile. Ground units need a continuous friendly route.", 16, MUTED))
	var toolbar: HBoxContainer = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 12)
	root_box.add_child(toolbar)
	scenario_picker = OptionButton.new()
	scenario_picker.name = "ScenarioPicker"
	scenario_picker.custom_minimum_size = Vector2(240, 42)
	scenario_picker.add_item("Starting board")
	scenario_picker.add_item("Transport path · intact")
	scenario_picker.add_item("Transport path · broken")
	scenario_picker.item_selected.connect(load_fixture)
	toolbar.add_child(scenario_picker)
	player_picker = OptionButton.new()
	player_picker.name = "PlayerPicker"
	player_picker.custom_minimum_size = Vector2(180, 42)
	player_picker.add_item("Control: Ember")
	player_picker.add_item("Control: Vesper")
	player_picker.item_selected.connect(_change_player)
	toolbar.add_child(player_picker)
	var reset: Button = _button("Reset board")
	reset.pressed.connect(func() -> void: load_fixture(scenario_picker.selected))
	toolbar.add_child(reset)
	var clear: Button = _button("Clear selection")
	clear.pressed.connect(_clear_selection)
	toolbar.add_child(clear)
	var combat: Button = _button("Battle lab")
	combat.pressed.connect(_open_battle_lab)
	toolbar.add_child(combat)
	var content: HBoxContainer = HBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	root_box.add_child(content)
	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 14)
	content.add_child(left)
	board_box = HBoxContainer.new()
	board_box.add_theme_constant_override("separation", 16)
	left.add_child(board_box)
	left.add_child(_label("AMBER: origin   •   TEAL: legal destination   •   BLUE: supporting route", 14, MUTED))
	history = _label("No movement yet.", 15, MUTED)
	history.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(history)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.x = 300
	panel.add_theme_stylebox_override("panel", _style(Color("101c2a"), Color("2e4258")))
	content.add_child(panel)
	var sidebar: VBoxContainer = VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 14)
	panel.add_child(sidebar)
	sidebar.add_child(_label("SELECTED FORCE", 14, AMBER))
	details = _label("", 17, INK)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sidebar.add_child(details)
	unit_box = VBoxContainer.new()
	sidebar.add_child(unit_box)
	route_label = _label("", 15, TEAL)
	route_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sidebar.add_child(route_label)
	move_button = _button("Move selected units")
	move_button.name = "MoveButton"
	move_button.pressed.connect(_move_selected)
	sidebar.add_child(move_button)
	message = _label("", 15, MUTED)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sidebar.add_child(message)
	root_box.add_child(_label("Prototype 02 · Movement and battle labs. Conquest, relic collection and tactics turns come next.", 14, MUTED))
	root_box.add_child(_label("Keyboard: Tab or arrow keys to focus an area; Enter / Space to select. Escape clears selection.", 14, MUTED))


func load_fixture(index: int) -> void:
	scenario_picker.select(index)
	var fixture: Dictionary = Fixtures.create(index != 0)
	board = fixture.board
	state = fixture.state
	if index == 2:
		state.units.erase("support-2")
	var errors: PackedStringArray = Movement.validate_state(board, state, Fixtures.UNIT_TYPES)
	assert(errors.is_empty(), "Invalid fixture: " + "; ".join(errors))
	origin = ""
	destination = ""
	selected_units.clear()
	route.clear()
	destinations.clear()
	for child: Node in board_box.get_children():
		board_box.remove_child(child)
		child.queue_free()
	area_buttons.clear()
	for tile_id: String in board.tiles:
		var panel: PanelContainer = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", _style(Color("0d1927"), Color("465d76"), 2))
		board_box.add_child(panel)
		var tile_box: VBoxContainer = VBoxContainer.new()
		tile_box.add_theme_constant_override("separation", 10)
		panel.add_child(tile_box)
		tile_box.add_child(_label("EMBER REACH" if tile_id == "tile-a" else "VESPER REACH", 17, AMBER if tile_id == "tile-a" else VIOLET))
		tile_box.add_child(_label(tile_id + "  ·  4 areas", 13, MUTED))
		var grid: GridContainer = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		tile_box.add_child(grid)
		for area_id: String in board.tiles[tile_id].areas:
			var button: Button = Button.new()
			button.name = area_id.replace(":", "_")
			button.custom_minimum_size = Vector2(155, 148)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.add_theme_font_size_override("font_size", 15)
			button.pressed.connect(_select_area.bind(area_id))
			grid.add_child(button)
			area_buttons[area_id] = button
	_link_area_focus()
	_refresh()
	history.text = "Starting position restored." if index == 0 else "Transport fixture: Ember's ground unit starts in the top-left planet."


func _link_area_focus() -> void:
	for id: String in board.areas:
		var cell: Array = board.areas[id].cell
		var button: Button = area_buttons[id]
		for other: String in board.support_neighbors[id]:
			var delta: Vector2i = Vector2i(board.areas[other].cell[0] - cell[0], board.areas[other].cell[1] - cell[1])
			var path: NodePath = button.get_path_to(area_buttons[other])
			if delta == Vector2i.LEFT: button.focus_neighbor_left = path
			if delta == Vector2i.RIGHT: button.focus_neighbor_right = path
			if delta == Vector2i.UP: button.focus_neighbor_top = path
			if delta == Vector2i.DOWN: button.focus_neighbor_bottom = path


func _select_area(id: String) -> void:
	if origin.is_empty() or id == origin:
		origin = id
		destination = ""
		selected_units.clear()
		for unit: Dictionary in state.units.values():
			if unit.area_id == id and unit.owner == actor:
				selected_units.append(unit.id)
		_refresh()
		return
	destination = id
	_refresh(false)


func _refresh(rebuild_units: bool = true) -> void:
	destinations = Movement.legal_destinations(board, state, Fixtures.UNIT_TYPES, actor, origin, selected_units) if not origin.is_empty() else {}
	route.clear()
	move_button.disabled = true
	message.text = "Choose an occupied area to inspect its units."
	route_label.text = ""
	if not destination.is_empty():
		var verdict: Dictionary = Movement.legal_action(board, state, Fixtures.UNIT_TYPES, actor, _action())
		message.text = verdict.reason
		if verdict.ok:
			route.assign(verdict.path)
			route_label.text = "Destination: " + board.areas[destination].name + "\n"
			route_label.text += "Ship transit · no support required" if route.is_empty() else "Support route:\n" + " → ".join(route)
			move_button.disabled = verdict.battle_required or _has_objective(destination)
			if verdict.battle_required:
				message.text = "A defending force is present. Try combat in the Battle lab; map conquest comes next."
			elif _has_objective(destination):
				message.text = "Relic and structure capture come with the next milestone. This route is legal."
	elif not origin.is_empty():
		message.text = "Choose a teal destination. Clear selection to choose a different origin."
		if selected_units.is_empty(): message.text = "This area has no selected units belonging to the current player."
		elif destinations.is_empty(): message.text = "This force has no legal destinations. Inspect a neighboring area for the reason."
	for id: String in area_buttons:
		var button: Button = area_buttons[id]
		var area: Dictionary = board.areas[id]
		var owner: int = state.owners[id]
		var units: Array[String] = []
		for unit: Dictionary in state.units.values():
			if unit.area_id == id:
				units.append(("E" if unit.owner == 0 else "V") + ": " + ("Ground" if Fixtures.UNIT_TYPES[unit.type_id].domain == "ground" else "Ship"))
		var title: String = "PLANET" if area.type == "planet" else "SPACE"
		var owner_text: String = ["Ember", "Vesper"][owner] if owner >= 0 else "Unclaimed"
		if area.type == "space": owner_text = "Open space" if units.is_empty() else "Occupied"
		button.text = "%s · %s\n%s\n%s%s" % [area.quadrant.to_upper(), title, owner_text, "\n".join(units) if not units.is_empty() else "—", "\n◆ Relic" if _has_relic(id) else ""]
		button.tooltip_text = id + ("\nLegal destination" if destinations.has(id) else "")
		var border: Color = Color("35475b")
		var fill: Color = Color("162638") if area.type == "planet" else Color("0b1422")
		if destinations.has(id): border = TEAL
		if id in route: fill = Color("183952")
		if id == origin: border = AMBER
		if id == destination: border = Color.WHITE
		button.add_theme_stylebox_override("normal", _style(fill, border, 2))
	if rebuild_units:
		_rebuild_unit_selection()


func _rebuild_unit_selection() -> void:
	for child: Node in unit_box.get_children():
		unit_box.remove_child(child)
		child.queue_free()
	details.text = "Nothing selected\n\nEmber = E\nVesper = V" if origin.is_empty() else board.areas[origin].name + "\n" + origin
	for unit: Dictionary in state.units.values():
		if unit.area_id != origin:
			continue
		var check: CheckBox = CheckBox.new()
		var content: Dictionary = Fixtures.UNIT_TYPES[unit.type_id]
		check.text = "%s · %s\nAttack %d / Health %d / Lead %d" % ["Ember" if unit.owner == 0 else "Vesper", content.name, content.attack, content.health, content.leadership]
		check.disabled = unit.owner != actor
		check.button_pressed = unit.id in selected_units
		check.tooltip_text = unit.id + (" · routed" if unit.routed else "")
		check.toggled.connect(_toggle_unit.bind(unit.id))
		unit_box.add_child(check)


func _toggle_unit(checked: bool, id: String) -> void:
	if checked: selected_units.append(id)
	else: selected_units.erase(id)
	_refresh(false)


func _move_selected() -> void:
	var result: Dictionary = Movement.apply_lab_move(board, state, Fixtures.UNIT_TYPES, actor, _action())
	if not result.ok:
		message.text = result.reason
		return
	state = result.state
	history.text = "Moved %d unit(s): %s → %s" % [selected_units.size(), origin, destination]
	origin = destination
	destination = ""
	_refresh()
	(area_buttons[origin] as Button).grab_focus()


func _action() -> Dictionary:
	return {"type": "dispatch", "origin": origin, "destination": destination, "unit_ids": selected_units.duplicate()}


func _change_player(index: int) -> void:
	actor = index
	_clear_selection()


func _clear_selection() -> void:
	origin = ""
	destination = ""
	selected_units.clear()
	_refresh()


func _has_relic(area: String) -> bool:
	for relic: Dictionary in state.relics.values():
		if relic.area_id == area: return true
	return false


func _has_objective(area: String) -> bool:
	if _has_relic(area): return true
	for building: Dictionary in state.structures.values():
		if building.area_id == area and building.owner != actor: return true
	return false


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not is_instance_valid(battle_lab):
		_clear_selection()
		get_viewport().set_input_as_handled()


func _open_battle_lab() -> void:
	if is_instance_valid(battle_lab): return
	movement_panel.hide()
	battle_lab = BattleLab.new()
	battle_lab.closed.connect(_close_battle_lab)
	add_child(battle_lab)


func _close_battle_lab() -> void:
	remove_child(battle_lab)
	battle_lab.queue_free()
	battle_lab = null
	movement_panel.show()
	(area_buttons["tile-a:nw"] as Button).grab_focus()


func _label(text: String, size_px: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 42
	return button


func _style(fill: Color, border: Color, width_px: int = 1) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width_px)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
