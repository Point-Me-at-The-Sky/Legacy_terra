extends Control
## A local human-versus-policy battle experiment, separate from strategic movement.

signal closed

const Battle = preload("res://rules/battle.gd")
const Content = preload("res://content/combat_content.gd")
const Fixtures = preload("res://content/battle_fixtures.gd")
const Policy = preload("res://controllers/battle_policy.gd")
const INK: Color = Color("dfe8f2")
const MUTED: Color = Color("9caec3")
const AMBER: Color = Color("f4b563")
const TEAL: Color = Color("71dac5")

var battle_state: Dictionary = {}
var seed_value: int = 73
var scenario: int = 0
var scenario_picker: OptionButton
var phase_label: Label
var seed_label: Label
var force_labels: Array[Label] = []
var action_heading: Label
var action_box: HBoxContainer
var log_label: RichTextLabel
var outcome_label: Label
var back_button: Button
var action_buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	start_battle(0)


func _build() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var scroll: ScrollContainer = ScrollContainer.new()
	margin.add_child(scroll)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	box.add_child(_label("LEGACY OF TERRA / BATTLE LAB", 14, AMBER))
	box.add_child(_label("Three rounds. One victor.", 30, INK))
	var toolbar: HBoxContainer = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 12)
	box.add_child(toolbar)
	back_button = _button("Back to movement")
	back_button.pressed.connect(func() -> void: closed.emit())
	toolbar.add_child(back_button)
	scenario_picker = OptionButton.new()
	scenario_picker.custom_minimum_size = Vector2(220, 40)
	for title: String in ["Ground skirmish", "Space skirmish", "Defense building"]:
		scenario_picker.add_item(title)
	scenario_picker.item_selected.connect(start_battle)
	toolbar.add_child(scenario_picker)
	var repeat: Button = _button("Restart same seed")
	repeat.pressed.connect(func() -> void: start_battle(scenario))
	toolbar.add_child(repeat)
	var fresh: Button = _button("New seed")
	fresh.pressed.connect(func() -> void: seed_value += 1; start_battle(scenario))
	toolbar.add_child(fresh)
	seed_label = _label("", 14, MUTED)
	toolbar.add_child(seed_label)
	phase_label = _label("", 18, TEAL)
	box.add_child(phase_label)
	var forces: HBoxContainer = HBoxContainer.new()
	forces.add_theme_constant_override("separation", 16)
	box.add_child(forces)
	for side: int in range(2):
		var panel: PanelContainer = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("101c2a")
		style.border_color = AMBER if side == 0 else Color("b7a0ed")
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		panel.add_theme_stylebox_override("panel", style)
		forces.add_child(panel)
		var label: Label = _label("", 16, INK)
		label.custom_minimum_size = Vector2(400, 155)
		panel.add_child(label)
		force_labels.append(label)
	outcome_label = _label("", 18, AMBER)
	outcome_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(outcome_label)
	action_heading = _label("", 16, INK)
	action_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(action_heading)
	action_box = HBoxContainer.new()
	action_box.add_theme_constant_override("separation", 10)
	box.add_child(action_box)
	box.add_child(_label("BATTLE RECORD", 13, AMBER))
	log_label = RichTextLabel.new()
	log_label.custom_minimum_size.y = 150
	log_label.scroll_following = true
	log_label.focus_mode = Control.FOCUS_ALL
	log_label.add_theme_font_size_override("normal_font_size", 14)
	box.add_child(log_label)
	var footer: Label = _label("Leadership = accumulated dice/card bonuses + surviving unrouted units, counted once. Attacker wins ties.\nCombat lab only: conquest, relic collection and tactics turns are the next milestones.", 14, MUTED)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(footer)


func start_battle(index: int) -> void:
	scenario = index
	scenario_picker.select(index)
	var f: Dictionary = Fixtures.create(index)
	var result: Dictionary = Battle.start(f.board, f.world, Content.UNIT_TYPES, f.request, seed_value)
	assert(result.ok, str(result.get("reason", "Invalid battle fixture")))
	battle_state = result.state
	_drive_opponent()
	_refresh()


func play(action: Dictionary) -> void:
	var result: Dictionary = Battle.apply(battle_state, Content.UNIT_TYPES, 0, action)
	if not result.ok:
		action_heading.text = result.reason
		return
	battle_state = result.state
	_drive_opponent()
	_refresh()


func _drive_opponent() -> void:
	# Policy never receives battle_state, the player's hand, or the RNG state.
	for step: int in range(100):
		var view: Dictionary = Battle.view_for(battle_state, Content.UNIT_TYPES, 1)
		var action: Dictionary = Policy.choose_action(view)
		if action.is_empty(): return
		var result: Dictionary = Battle.apply(battle_state, Content.UNIT_TYPES, 1, action)
		assert(result.ok, "Opponent proposed an illegal action")
		battle_state = result.state
	push_error("Battle opponent failed to yield.")


func _refresh() -> void:
	var view: Dictionary = Battle.view_for(battle_state, Content.UNIT_TYPES, 0)
	seed_label.text = "Seed %d" % seed_value
	phase_label.text = "Round %d / 3  ·  %s" % [view.round, {"commit": "Choose a combat card", "damage": "Assign incoming damage", "retreat": "Choose a retreat", "finished": "Battle complete"}[view.step]]
	for side: int in range(2):
		var force: Dictionary = view.sides[side]
		var lines: Array[String] = ["EMBER · YOU · ATTACKER" if side == 0 else "VESPER · OPPONENT · DEFENDER"]
		var unit_leadership: int = 0
		for unit: Dictionary in force.forces:
			lines.append("%s · %s   Attack %d / Health %d / Lead %d%s" % [unit.id, unit.name, unit.attack, unit.health, unit.leadership, "  ROUTED" if unit.routed else ""])
			if unit.damage > 0: lines.append("  Damage: %d / %d" % [unit.damage, unit.health])
			if not unit.routed: unit_leadership += unit.leadership
		if force.forces.is_empty(): lines.append("No surviving force")
		var roll: Dictionary = view.rolls[side]
		lines.append("%s: %d attack · %d defense · %d leadership" % ["Last roll" if view.step == "finished" else "Dice", roll.attack, roll.defense, roll.leadership])
		if view.outcome.is_empty():
			lines.append("Banked leadership: %d  ·  Eligible unit leadership: %d" % [force.bank, unit_leadership])
		else:
			lines.append("At decision: bank %d + units %d = %d leadership" % [view.outcome.banks[side], view.outcome.leadership[side] - view.outcome.banks[side], view.outcome.leadership[side]])
		if view.step == "commit": lines.append("Card: locked (hidden)" if force.committed else "Card: choosing")
		force_labels[side].text = "\n".join(lines)
	outcome_label.text = ""
	outcome_label.visible = not view.outcome.is_empty()
	if not view.outcome.is_empty():
		var winner: int = view.outcome.winner
		var verdict: String = "Both forces destroyed" if winner < 0 else ("Ember wins" if winner == 0 else "Vesper wins")
		outcome_label.text = "%s · %s · Final leadership %d – %d" % [verdict, view.outcome.reason.replace("_", " "), view.outcome.leadership[0], view.outcome.leadership[1]]
	for child: Node in action_box.get_children():
		action_box.remove_child(child)
		child.queue_free()
	action_buttons.clear()
	match view.step:
		"commit": action_heading.text = "Choose one card after the public roll. Vesper has locked its choice; both cards then resolve attacker first."
		"damage": action_heading.text = "Assign %d incoming damage. A chosen target takes up to its remaining health; overflow goes to your next choice." % view.incoming[0]
		"retreat": action_heading.text = "Choose one friendly destination for all surviving units. Retreat routes the entire force."
		"finished": action_heading.text = "Battle resolved. Restart to compare card choices, or try the space and defense-building scenarios."
	for action: Dictionary in view.legal_actions:
		var text: String = ""
		if action.type == "commit_card":
			for card: Dictionary in view.hand:
				if card.id != action.card_id: continue
				text = card.name
				for bonus: String in ["damage", "defense", "leadership"]:
					if card[bonus] > 0: text += "\n+%d %s" % [card[bonus], bonus]
				if card.has("special"): text += "\n+1 with unrouted Ground 1 / Space 1"
		elif action.type == "assign_damage":
			text = "Damage " + action.target.trim_prefix("unit:").trim_prefix("structure:")
		elif action.type == "retreat":
			text = "Retreat to " + action.destination
			var path: Array = view.retreat_options[action.destination]
			if not path.is_empty(): text += "\n" + " → ".join(path)
		var button: Button = _button(text)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(play.bind(action))
		action_box.add_child(button)
		action_buttons.append(button)
	log_label.text = _event_text(view.events)
	if not action_buttons.is_empty(): action_buttons[0].grab_focus()
	else: back_button.grab_focus()


func _event_text(events: Array) -> String:
	var lines: Array[String] = []
	for event: Dictionary in events:
		var player_name: String = "Ember" if event.get("player", 0) == 0 else "Vesper"
		match event.type:
			"roll": lines.append("Round %d — fresh dice rolled." % event.round)
			"card_resolved": lines.append("%s: %s%s" % [player_name, Content.CARDS[Content.DECK[event.card_id]].name, " (unit effect applied)" if event.special_applied else ""])
			"damage_totals": lines.append("Incoming damage: Ember %d / Vesper %d. Banks: %d / %d." % [event.incoming[0], event.incoming[1], event.banks[0], event.banks[1]])
			"damage": lines.append("%s takes %d damage: %s." % [event.target, event.amount, "destroyed" if event.destroyed else "survives"])
			"round_ended": lines.append("Round %d ends. Damage clears; routing remains." % event.round)
			"retreat": lines.append("%s retreats to %s." % [player_name, event.destination])
			"no_retreat": lines.append("%s has no legal retreat; surviving units are destroyed." % player_name)
			"battle_finished": lines.append("Battle complete. All cards return to their decks.")
	return "\n".join(lines)


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
