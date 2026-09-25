extends RefCounted

const Battle = preload("res://rules/battle.gd")
const Content = preload("res://content/combat_content.gd")
const Fixtures = preload("res://content/battle_fixtures.gd")
const Policy = preload("res://controllers/battle_policy.gd")
const Retreat = preload("res://rules/retreat.gd")
const Random = preload("res://rules/battle_random.gd")

var checks: int = 0
var failures: Array[String] = []


func run() -> void:
	_worked_battle(0)
	_worked_battle(1)
	_damage_cases()
	_structures_and_requirements()
	_retreats()
	_privacy_and_replay()
	_validation_and_lifecycle()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message)


func _start(scenario: int = 0, single: bool = false) -> Dictionary:
	var f: Dictionary = Fixtures.create(scenario)
	if single:
		f.world.units.erase("a2")
		f.world.units.erase("d2")
		f.request.unit_ids = ["a1"]
	var result: Dictionary = Battle.start(f.board, f.world, Content.UNIT_TYPES, f.request, 73)
	_check(result.ok, "Valid battle fixture starts")
	return result.get("state", {})


func _act(state: Dictionary, player: int, action: Dictionary) -> Dictionary:
	var original: Dictionary = state.duplicate(true)
	var result: Dictionary = Battle.apply(state, Content.UNIT_TYPES, player, action)
	_check(result.ok, "Expected legal battle action: " + str(action))
	_check(state == original, "Battle action preserves caller-owned input")
	return result.get("state", state)


func _roll(attack: int = 0, defense: int = 0, leadership: int = 0) -> Dictionary:
	var faces: Array[String] = []
	for count: int in range(attack): faces.append("attack")
	for count: int in range(defense): faces.append("defense")
	for count: int in range(leadership): faces.append("leadership")
	return {"attack": attack, "defense": defense, "leadership": leadership, "faces": faces}


func _cards(state: Dictionary, attacker_card: String, defender_card: String) -> Dictionary:
	# Deliberate fixture inputs. Controllers cannot replace rolls or hands through apply().
	for pair: Array in [[0, attacker_card], [1, defender_card]]:
		var deck: Dictionary = state.world.combat_decks[str(pair[0])]
		if not pair[1] in deck.hand:
			deck.hand.append(pair[1])
			deck.draw.erase(pair[1])
	var next: Dictionary = _act(state, 0, {"type": "commit_card", "card_id": attacker_card})
	return _act(next, 1, {"type": "commit_card", "card_id": defender_card})


func _worked_battle(scenario: int, blocked: bool = false) -> Dictionary:
	var state: Dictionary = _start(scenario, true)
	if blocked:
		for id: String in state.world.owners:
			if id.begins_with("tile-c"): state.world.owners[id] = -1
		state.world.units.erase("d-support")
	for player: String in ["0", "1"]:
		state.world.combat_decks[player].hand = ["guard_1", "focus_1", "focus_2", "strike_1"]
		state.world.combat_decks[player].draw = ["guard_2", "strike_2"]
	state.rolls = [_roll(1), _roll(0, 0, 1)]
	state = _cards(state, "guard_1", "guard_1")
	_check(state.round == 2 and state.sides[0].bank == 0 and state.sides[1].bank == 1, "Worked round 1 banks 0/1")
	state.rolls = [_roll(0, 0, 1), _roll(0, 1)]
	state = _cards(state, "focus_1", "focus_1")
	_check(state.round == 3 and state.sides[0].bank == 3 and state.sides[1].bank == 3, "Worked round 2 banks 3/3")
	state.rolls = [_roll(1), _roll(0, 0, 1)]
	state = _cards(state, "focus_2", "focus_2")
	_check(state.incoming == [0, 1] and state.damage_side == 1, "Worked last round damages defender only")
	_check(state.sides[0].bank == 5 and state.sides[1].bank == 6, "Worked last round banks 5/6 before damage")
	state = _act(state, 1, {"type": "assign_damage", "target": "unit:d1"})
	_check(state.outcome.winner == 0 and state.outcome.leadership == [6, 6], "Final 6–6 tie goes to attacker after routing")
	if blocked:
		_check(state.step == "finished" and not state.world.units.has("d1"), "No legal retreat destroys surviving loser")
	else:
		_check(state.step == "retreat" and state.world.units.d1.routed and state.world.units.d1.damage == 0, "Damage clears but routing persists while retreat is pending")
		var destination: String = "tile-c:sw" if scenario == 1 else "tile-c:nw"
		state = _act(state, 1, {"type": "retreat", "destination": destination})
		_check(state.world.units.d1.area_id == destination and state.world.units.d1.routed, "Losing force retreats together and remains routed")
	_check(state.step == "finished" and state.outcome.banks == [5, 6], "Outcome retains audited banks")
	_check(state.sides[0].bank == 0 and state.sides[1].bank == 0, "Active battle banks clear on completion")
	_check(state.world.owners[state.destination] == (-1 if scenario == 1 else 1), "Combat does not perform partial conquest or relic scoring")
	return state


func _damage_cases() -> void:
	var state: Dictionary = _start()
	state.rolls = [_roll(3), _roll(3)]
	state = _cards(state, "strike_1", "strike_1")
	_check(state.incoming == [4, 4], "Both incoming totals are computed before assignment")
	_check(Battle.legal_actions(state, 1).is_empty(), "Attacker assigns incoming damage first")
	state = _act(state, 0, {"type": "assign_damage", "target": "unit:a1"})
	_check(not state.world.units.has("a1") and state.incoming[0] == 1, "Health-3 unit dies and excess damage carries over")
	state = _act(state, 0, {"type": "assign_damage", "target": "unit:a2"})
	_check(state.world.units.a2.damage == 1 and state.world.units.a2.routed, "Overflow routes the chosen survivor")
	_check(state.damage_side == 1 and state.incoming[1] == 4, "Casualties do not shrink retaliation")
	state = _act(state, 1, {"type": "assign_damage", "target": "unit:d1"})
	state = _act(state, 1, {"type": "assign_damage", "target": "unit:d2"})
	_check(state.round == 2 and state.world.units.a2.damage == 0 and state.world.units.a2.routed, "Round reset never rallies survivors")
	_check(state.rolls[0].faces.is_empty() and state.rolls[1].faces.is_empty(), "Routed-only forces continue fighting without dice")
	state = _start(0, true)
	state.rolls = [_roll(2), _roll(2)]
	state = _cards(state, "strike_1", "strike_1")
	state = _act(state, 0, {"type": "assign_damage", "target": "unit:a1"})
	_check(state.step == "damage" and state.damage_side == 1, "Last attacker dying does not skip defender damage")
	state = _act(state, 1, {"type": "assign_damage", "target": "unit:d1"})
	_check(state.step == "finished" and state.outcome.winner == -1 and state.outcome.reason == "mutual_destruction", "Both last forces die with no winner")
	_check(state.world.owners[state.destination] == 1, "Mutual destruction preserves prebattle ownership")
	state = _start()
	state.world.units.a1.routed = true
	state.rolls = [_roll(), _roll(3)]
	state = _cards(state, "strike_1", "strike_1")
	var snapshot: Dictionary = state.duplicate(true)
	_check(not Battle.apply(state, Content.UNIT_TYPES, 0, {"type": "assign_damage", "target": "unit:a1"}).ok, "Cannot soak damage with routed units while unrouted targets exist")
	_check(state == snapshot, "Illegal damage choice leaves state and RNG unchanged")
	state = _act(state, 0, {"type": "assign_damage", "target": "unit:a2"})
	_check(Battle.legal_actions(state, 0) == [{"type": "assign_damage", "target": "unit:a1"}], "Routed target becomes eligible once unrouted targets are gone")


func _structures_and_requirements() -> void:
	var state: Dictionary = _start(2)
	_check(state.rolls[1].faces.size() == 1, "Defense building fights alone with one die")
	_check(not Battle.requirement_met(state, Content.UNIT_TYPES, 1, Content.CARDS.focus.special), "A structure never enables a unit prerequisite")
	state.rolls = [_roll(2), _roll()]
	state = _cards(state, "strike_1", "focus_1")
	_check(state.incoming[1] == 2 and state.sides[1].bank == 1, "Structure adds defense; failed Focus still grants its base leadership")
	state = _act(state, 1, {"type": "assign_damage", "target": "structure:fort"})
	_check(state.round == 2 and state.world.structures.fort.damage == 0 and not state.world.structures.fort.has("routed"), "Nonlethal building damage resets without routing")
	_check(state.rolls[1].faces.size() == 1, "Damaged surviving building still rolls next round")
	state = _start()
	_check(Battle.requirement_met(state, Content.UNIT_TYPES, 0, Content.CARDS.focus.special), "Focus any-of requirement succeeds with Ground 1")
	_check(not Battle.requirement_met(state, Content.UNIT_TYPES, 0, {"requires": ["ground_1", "space_1"], "allOf": true}), "All-of requires every listed unit type")
	state.world.units.a1.routed = true
	state.world.units.erase("a2")
	_check(not Battle.requirement_met(state, Content.UNIT_TYPES, 0, Content.CARDS.focus.special), "Dead and routed units do not satisfy prerequisites")
	state.rolls = [_roll(), _roll()]
	state = _cards(state, "focus_1", "focus_1")
	_check(state.sides[0].bank == 1 and state.sides[1].bank == 2, "Prerequisites are checked at resolution with base bonus preserved")


func _retreats() -> void:
	var state: Dictionary = _start()
	var options: Dictionary = Retreat.destinations(state.board, state.world, Content.UNIT_TYPES, 0, state.destination, state.origin, "ground", true)
	_check(options.has(state.origin), "Losing attacker may return to a legal original planet")
	state.world.owners["tile-a:nw"] = 1
	options = Retreat.destinations(state.board, state.world, Content.UNIT_TYPES, 1, state.destination, state.origin, "ground", false)
	_check(not options.has("tile-a:nw") and options.has("tile-c:nw"), "Defender cannot retreat anywhere in attacker's origin tile")
	state.world.owners["tile-b:ne"] = -1
	options = Retreat.destinations(state.board, state.world, Content.UNIT_TYPES, 1, state.destination, state.origin, "ground", false)
	_check(options.is_empty(), "Neutral intermediate planet breaks retreat support")
	state = _start(1)
	options = Retreat.destinations(state.board, state.world, Content.UNIT_TYPES, 1, state.destination, state.origin, "space", false)
	_check(options.keys() == ["tile-c:sw"], "Space retreat uses friendly occupied space, never neutral space or planets")
	_worked_battle(0, true)


func _privacy_and_replay() -> void:
	var state: Dictionary = _start()
	var before: Dictionary = state.duplicate(true)
	var view: Dictionary = Battle.view_for(state, Content.UNIT_TYPES, 0)
	_check(state == before, "Player view and legal-action preview do not consume RNG")
	_check(not view.has("rng_state") and not view.has("world") and not view.sides[1].has("hand"), "View hides RNG, authoritative world, and opponent's hand")
	var card: String = state.world.combat_decks["1"].hand[0]
	state = _act(state, 1, {"type": "commit_card", "card_id": card})
	view = Battle.view_for(state, Content.UNIT_TYPES, 0)
	_check(view.sides[1].committed and not view.sides[1].has("commitment"), "Opponent readiness is visible but its selected card is hidden")
	_check(not view.events[-1].has("card_id"), "Commit event does not leak the selected card")
	_check(Battle.legal_actions(state, 1).is_empty(), "Committed player cannot change cards")
	var observer: Dictionary = Battle.view_for(state, Content.UNIT_TYPES, 99)
	_check(observer.hand.is_empty() and observer.legal_actions.is_empty(), "Nonparticipant gets no hand or commands")
	var own_card: String = state.world.combat_decks["0"].hand[0]
	state = _act(state, 0, {"type": "commit_card", "card_id": own_card})
	var resolved: Array = state.events.filter(func(event: Dictionary) -> bool: return event.type == "card_resolved")
	_check(resolved.size() == 2 and resolved[0].player == 0 and resolved[1].player == 1, "Attacker resolves first even if defender committed first")
	for scenario: int in range(3):
		var first: Dictionary = _simulate(_start(scenario))
		var second: Dictionary = _simulate(_start(scenario))
		_check(first == second, "Identical seed and controller choices replay exactly, scenario %d" % scenario)
		_check(first.step == "finished", "Seeded battle completes, scenario %d" % scenario)
		_check(first.world.combat_decks["0"].draw.size() == 6 and first.world.combat_decks["0"].hand.is_empty(), "All six cards return after battle")
		_check(not Battle.apply(first, Content.UNIT_TYPES, 0, {"type": "commit_card", "card_id": "strike_1"}).ok, "Finished battle rejects duplicate commands")
	var random_state: int = Random.normalize(-100)
	for count: int in [1, 2, 6, 17]:
		var draw: Dictionary = Random.bounded(random_state, count)
		_check(draw.value >= 0 and draw.value < count and draw.state > 0, "Bounded RNG produces a valid face")


func _simulate(state: Dictionary) -> Dictionary:
	var next: Dictionary = state
	for step: int in range(100):
		if next.step == "finished": return next
		var progressed: bool = false
		for player: int in [0, 1]:
			var view: Dictionary = Battle.view_for(next, Content.UNIT_TYPES, player)
			var action: Dictionary = Policy.choose_action(view)
			if not action.is_empty():
				var result: Dictionary = Battle.apply(next, Content.UNIT_TYPES, player, action)
				_check(result.ok, "Lab opponent chooses only permitted actions")
				next = result.state
				progressed = true
		if not progressed: break
	return next


func _validation_and_lifecycle() -> void:
	var f: Dictionary = Fixtures.create()
	var original: Dictionary = f.world.duplicate(true)
	var result: Dictionary = Battle.start(f.board, f.world, Content.UNIT_TYPES, f.request, 73)
	_check(result.ok and f.world == original, "Battle preparation does not mutate strategic state")
	_check(not Battle.start(f.board, result.state.world, Content.UNIT_TYPES, f.request, 73).ok, "Cannot start another battle while one is active")
	var state: Dictionary = result.state
	var snapshot: Dictionary = state.duplicate(true)
	_check(not Battle.apply(state, Content.UNIT_TYPES, 0, {"type": "commit_card", "card_id": "unknown"}).ok and state == snapshot, "Malformed choice rejected with no state or RNG changes")
	var finished: Dictionary = _worked_battle(0)
	_check(not Battle.start(finished.board, finished.world, Content.UNIT_TYPES, f.request, 73).ok, "Resolved battle ID cannot be applied again")
	# Reuse the returned decks and routed unit state in another legal encounter.
	var followup: Dictionary = Fixtures.create()
	followup.world.combat_decks = finished.world.combat_decks.duplicate(true)
	followup.world.units.d1.routed = true
	followup.request.id = "second-battle"
	result = Battle.start(followup.board, followup.world, Content.UNIT_TYPES, followup.request, finished.rng_state)
	_check(result.ok and result.state.world.units.d1.routed, "Preparing another battle does not rally routed defenders")
	_check(result.state.world.combat_decks["1"].hand.size() == 4 and result.state.world.combat_decks["1"].draw.size() == 2, "Next battle reshuffles six and deals four without a midbattle redraw")
