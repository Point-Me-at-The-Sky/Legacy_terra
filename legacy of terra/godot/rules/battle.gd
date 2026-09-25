extends RefCounted
## Authoritative P-009 battle state machine. No nodes, input, UI, or controller policy.

const Content = preload("res://content/combat_content.gd")
const Random = preload("res://rules/battle_random.gd")
const Movement = preload("res://rules/movement.gd")
const Retreat = preload("res://rules/retreat.gd")
const FACES: Array[String] = ["attack", "attack", "defense", "defense", "leadership", "leadership"]


static func start(board: Dictionary, world: Dictionary, types: Dictionary, request: Dictionary, seed_value: int) -> Dictionary:
	if not Movement.validate_state(board, world, types).is_empty():
		return _failure("Invalid board or unit state.")
	if not request.get("id") is String or request.id.is_empty():
		return _failure("Battle needs a stable ID.")
	if world.get("active_battle_id", "") != "" or world.get("resolved_battles", {}).has(request.id):
		return _failure("Battle is already active or resolved.")
	if not request.get("attacker") is int or not request.get("defender") is int or request.attacker == request.defender or request.defender < 0:
		return _failure("Choose distinct participating players.")
	var action: Dictionary = request.duplicate(true)
	action.type = "dispatch"
	var verdict: Dictionary = Movement.legal_action(board, world, types, request.attacker, action)
	if not verdict.ok:
		return verdict
	if not verdict.battle_required:
		return _failure("This destination has no defending force.")
	for unit: Dictionary in world.units.values():
		if unit.area_id == request.destination and unit.owner != request.defender:
			return _failure("Destination must contain only the named defender.")
	for building: Dictionary in world.structures.values():
		if building.area_id == request.destination and building.owner != request.defender:
			return _failure("Destination structures must belong to the defender.")
	var next: Dictionary = {
		"schema_version": 1, "id": request.id, "board": board.duplicate(true), "world": world.duplicate(true),
		"origin": request.origin, "destination": request.destination,
		"domain": types[world.units[request.unit_ids[0]].type_id].domain,
		"round": 1, "step": "commit", "rng_state": Random.normalize(seed_value),
		"sides": [], "rolls": [], "incoming": [0, 0], "damage_side": 0,
		"outcome": {}, "retreat_options": {}, "events": [],
	}
	next.world.active_battle_id = request.id
	if not next.world.has("combat_decks"):
		next.world.combat_decks = {}
	for player: int in [request.attacker, request.defender]:
		var cards: Array = Content.DECK.keys()
		var shuffled: Dictionary = Random.shuffle(cards, next.rng_state)
		next.rng_state = shuffled.state
		next.world.combat_decks[str(player)] = {"cards": cards, "hand": shuffled.cards.slice(0, 4), "draw": shuffled.cards.slice(4), "played": []}
		next.sides.append({"player": player, "units": [], "structures": [], "bank": 0, "commitment": ""})
	for id: String in request.unit_ids:
		next.sides[0].units.append(id)
		next.world.units[id].area_id = request.destination
	for unit: Dictionary in next.world.units.values():
		if unit.area_id == request.destination and unit.owner == request.defender:
			next.sides[1].units.append(unit.id)
	for building: Dictionary in next.world.structures.values():
		if building.area_id == request.destination and building.type == "defense":
			next.sides[1].structures.append(building.id)
			building.damage = 0
	_roll(next, types)
	return {"ok": true, "state": next}


static func legal_actions(state: Dictionary, player: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var side: int = _side(state, player)
	if side < 0 or state.step == "finished":
		return result
	if state.step == "commit" and state.sides[side].commitment.is_empty():
		for id: String in _deck(state, side).hand:
			result.append({"type": "commit_card", "card_id": id})
	elif state.step == "damage" and state.damage_side == side:
		for target: String in _damage_targets(state, side):
			result.append({"type": "assign_damage", "target": target})
	elif state.step == "retreat" and state.outcome.loser == player:
		for destination: String in state.retreat_options:
			result.append({"type": "retreat", "destination": destination})
	return result


static func apply(state: Dictionary, types: Dictionary, player: int, action: Dictionary) -> Dictionary:
	# Only an exact permitted command is accepted; previews and rejection never roll.
	if not action in legal_actions(state, player):
		return _failure("Action is not legal for this player at this battle step.")
	var next: Dictionary = state.duplicate(true)
	var side: int = _side(next, player)
	match action.type:
		"commit_card":
			next.sides[side].commitment = action.card_id
			next.events.append({"type": "card_committed", "player": player, "round": next.round})
			if not next.sides[0].commitment.is_empty() and not next.sides[1].commitment.is_empty():
				_resolve_cards(next, types)
		"assign_damage":
			var entity: Dictionary = _entity(next, action.target)
			var stats: Dictionary = _stats(next, types, action.target)
			var amount: int = mini(next.incoming[side], stats.health - entity.damage)
			entity.damage += amount
			next.incoming[side] -= amount
			var destroyed: bool = entity.damage >= stats.health
			if destroyed:
				if action.target.begins_with("unit:"):
					next.world.units.erase(entity.id)
				else:
					next.world.structures.erase(entity.id)
			elif action.target.begins_with("unit:"):
				entity.routed = true
			next.events.append({"type": "damage", "round": next.round, "player": player, "target": action.target, "amount": amount, "destroyed": destroyed})
			_advance_damage(next, types)
		"retreat":
			for id: String in next.sides[side].units:
				if next.world.units.has(id):
					next.world.units[id].area_id = action.destination
					next.world.units[id].routed = true
			next.outcome.retreat = {"destination": action.destination, "path": next.retreat_options[action.destination].duplicate()}
			next.events.append({"type": "retreat", "player": player, "destination": action.destination, "path": next.retreat_options[action.destination].duplicate()})
			_finish(next)
	return {"ok": true, "state": next}


static func view_for(state: Dictionary, types: Dictionary, player: int) -> Dictionary:
	var side: int = _side(state, player)
	var view: Dictionary = {
		"id": state.id, "player": player, "round": state.round, "step": state.step,
		"domain": state.domain, "origin": state.origin, "destination": state.destination,
		"sides": [], "rolls": state.rolls.duplicate(true), "incoming": state.incoming.duplicate(),
		"damage_side": state.damage_side, "hand": [], "outcome": state.outcome.duplicate(true),
		"legal_actions": legal_actions(state, player), "events": state.events.duplicate(true),
		"retreat_options": state.retreat_options.duplicate(true) if side >= 0 and state.outcome.get("loser", -1) == player else {},
	}
	for index: int in range(2):
		var source: Dictionary = state.sides[index]
		var forces: Array[Dictionary] = []
		for target: String in _living(state, index):
			var entity: Dictionary = _entity(state, target)
			var stats: Dictionary = _stats(state, types, target)
			forces.append({"target": target, "id": entity.id, "type_id": entity.get("type_id", "defense"),
				"name": stats.name, "attack": stats.attack, "health": stats.health, "leadership": stats.leadership,
				"damage": entity.damage, "routed": entity.get("routed", false), "structure": target.begins_with("structure:")})
		view.sides.append({"player": source.player, "bank": source.bank, "committed": not source.commitment.is_empty(),
			"hand_count": _deck(state, index).hand.size(), "played": _deck(state, index).played.duplicate(), "forces": forces})
	if side >= 0:
		for id: String in _deck(state, side).hand:
			var card: Dictionary = Content.CARDS[Content.DECK[id]].duplicate(true)
			card.id = id
			view.hand.append(card)
	return view


static func requirement_met(state: Dictionary, types: Dictionary, side: int, special: Dictionary) -> bool:
	var present: Array[String] = []
	for id: String in state.sides[side].units:
		if state.world.units.has(id):
			var unit: Dictionary = state.world.units[id]
			if not unit.routed and types.has(unit.type_id):
				present.append(unit.type_id)
	var required: Array = special.get("requires", [])
	if required.is_empty():
		return true
	for id: String in required:
		if special.get("allOf", false) and not id in present:
			return false
		if not special.get("allOf", false) and id in present:
			return true
	return special.get("allOf", false)


static func _roll(state: Dictionary, types: Dictionary) -> void:
	state.step = "commit"
	state.rolls = []
	for side: int in range(2):
		var pool: int = 0
		for target: String in _living(state, side):
			if not _entity(state, target).get("routed", false):
				pool += _stats(state, types, target).attack
		var roll: Dictionary = {"faces": [], "attack": 0, "defense": 0, "leadership": 0}
		for die: int in range(pool):
			var draw: Dictionary = Random.bounded(state.rng_state, FACES.size())
			state.rng_state = draw.state
			var face: String = FACES[draw.value]
			roll.faces.append(face)
			roll[face] += 1
		state.rolls.append(roll)
	state.events.append({"type": "roll", "round": state.round, "rolls": state.rolls.duplicate(true)})


static func _resolve_cards(state: Dictionary, types: Dictionary) -> void:
	var totals: Array[Dictionary] = []
	# Commitments are already locked; revealing each card cannot change either choice.
	for side: int in range(2):
		var id: String = state.sides[side].commitment
		var card: Dictionary = Content.CARDS[Content.DECK[id]]
		var total: Dictionary = {"attack": state.rolls[side].attack + card.damage,
			"defense": state.rolls[side].defense + card.defense, "leadership": state.rolls[side].leadership + card.leadership}
		var special_applied: bool = false
		if card.has("special") and requirement_met(state, types, side, card.special):
			# Only effects in the original test deck are supported; no executable card data.
			assert(card.special.effect == "leadership")
			total.leadership += card.special.amount
			special_applied = true
		for building: String in state.sides[side].structures:
			if state.world.structures.has(building):
				total.defense += Content.DEFENSE.defense
		state.sides[side].bank += total.leadership
		_deck(state, side).hand.erase(id)
		_deck(state, side).played.append(id)
		state.events.append({"type": "card_resolved", "round": state.round, "player": state.sides[side].player,
			"card_id": id, "special_applied": special_applied, "totals": total.duplicate()})
		state.sides[side].commitment = ""
		totals.append(total)
	state.incoming = [maxi(0, totals[1].attack - totals[0].defense), maxi(0, totals[0].attack - totals[1].defense)]
	state.events.append({"type": "damage_totals", "round": state.round, "incoming": state.incoming.duplicate(), "banks": [state.sides[0].bank, state.sides[1].bank]})
	state.step = "damage"
	state.damage_side = 0
	_advance_damage(state, types)


static func _advance_damage(state: Dictionary, types: Dictionary) -> void:
	while state.damage_side < 2:
		var side: int = state.damage_side
		if state.incoming[side] > 0 and not _damage_targets(state, side).is_empty():
			return
		state.incoming[side] = 0
		state.damage_side += 1
	var alive: Array[bool] = [not _living(state, 0).is_empty(), not _living(state, 1).is_empty()]
	var winner: int = -1
	var reason: String = ""
	if not alive[0] and not alive[1]:
		reason = "mutual_destruction"
	elif not alive[0] or not alive[1]:
		winner = 0 if alive[0] else 1
		reason = "survival"
	elif state.round == 3:
		winner = 0 if _leadership(state, types, 0) >= _leadership(state, types, 1) else 1
		reason = "leadership"
	# Count surviving leadership before clearing round damage. Routing is never cleared.
	if not reason.is_empty():
		state.outcome = {"winner": state.sides[winner].player if winner >= 0 else -1,
			"loser": state.sides[1 - winner].player if winner >= 0 else -1, "reason": reason,
			"leadership": [_leadership(state, types, 0), _leadership(state, types, 1)],
			"banks": [state.sides[0].bank, state.sides[1].bank], "retreat": {}}
	for side: int in range(2):
		for target: String in _living(state, side):
			_entity(state, target).damage = 0
	state.events.append({"type": "round_ended", "round": state.round})
	if not reason.is_empty():
		_conclude(state, types, winner)
	else:
		state.round += 1
		_roll(state, types)


static func _conclude(state: Dictionary, types: Dictionary, winner_side: int) -> void:
	if winner_side >= 0:
		var loser: int = 1 - winner_side
		var survivors: Array[String] = []
		for id: String in state.sides[loser].units:
			if state.world.units.has(id):
				survivors.append(id)
		if not survivors.is_empty():
			state.retreat_options = Retreat.destinations(state.board, state.world, types, state.sides[loser].player,
				state.destination, state.origin, state.domain, loser == 0)
			if not state.retreat_options.is_empty():
				state.step = "retreat"
				return
			for id: String in survivors:
				state.world.units.erase(id)
			state.events.append({"type": "no_retreat", "player": state.sides[loser].player, "destroyed": survivors})
	_finish(state)


static func _finish(state: Dictionary) -> void:
	state.step = "finished"
	for side: int in range(2):
		var deck: Dictionary = _deck(state, side)
		deck.draw = deck.cards.duplicate()
		deck.hand = []
		deck.played = []
		state.sides[side].bank = 0
		state.sides[side].commitment = ""
	state.world.active_battle_id = ""
	if not state.world.has("resolved_battles"):
		state.world.resolved_battles = {}
	state.world.resolved_battles[state.id] = true
	state.events.append({"type": "battle_finished", "outcome": state.outcome.duplicate(true)})
	state.world.events.append({"type": "battle_finished", "id": state.id, "outcome": state.outcome.duplicate(true)})
	# Ownership, structure capture, relics and strategic cursor belong to the future
	# atomic conquest transaction. The lab never writes this state into the movement lab.


static func _leadership(state: Dictionary, types: Dictionary, side: int) -> int:
	var total: int = state.sides[side].bank
	for target: String in _living(state, side):
		if not _entity(state, target).get("routed", false):
			total += _stats(state, types, target).leadership
	return total


static func _living(state: Dictionary, side: int) -> Array[String]:
	var result: Array[String] = []
	for id: String in state.sides[side].units:
		if state.world.units.has(id): result.append("unit:" + id)
	for id: String in state.sides[side].structures:
		if state.world.structures.has(id): result.append("structure:" + id)
	return result


static func _damage_targets(state: Dictionary, side: int) -> Array[String]:
	var active: Array[String] = []
	var routed: Array[String] = []
	for target: String in _living(state, side):
		if _entity(state, target).get("routed", false): routed.append(target)
		else: active.append(target)
	return active if not active.is_empty() else routed


static func _entity(state: Dictionary, target: String) -> Dictionary:
	return state.world.units[target.trim_prefix("unit:")] if target.begins_with("unit:") else state.world.structures[target.trim_prefix("structure:")]


static func _stats(state: Dictionary, types: Dictionary, target: String) -> Dictionary:
	return types[_entity(state, target).type_id] if target.begins_with("unit:") else Content.DEFENSE


static func _deck(state: Dictionary, side: int) -> Dictionary:
	return state.world.combat_decks[str(state.sides[side].player)]


static func _side(state: Dictionary, player: int) -> int:
	for index: int in range(2):
		if state.sides[index].player == player: return index
	return -1


static func _failure(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
