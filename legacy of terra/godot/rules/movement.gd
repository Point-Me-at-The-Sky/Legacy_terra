extends RefCounted
## Shared legal-action interface for controllers. No scene-tree or input dependencies.


static func validate_state(board: Dictionary, state: Dictionary, types: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if not board.get("ok", false):
		return PackedStringArray(["Invalid board."])
	for key: String in ["owners", "units", "structures", "relics"]:
		if not state.get(key) is Dictionary:
			return PackedStringArray(["State needs a %s dictionary." % key])
	for id: String in board.areas:
		if not state.owners.has(id) or not state.owners[id] is int or state.owners[id] < -1:
			errors.append("Invalid owner for %s." % id)
	for id: Variant in state.owners:
		if not board.areas.has(id):
			errors.append("Unknown ownership area: %s." % str(id))
	for id: Variant in state.units:
		var unit: Variant = state.units[id]
		if not unit is Dictionary or unit.get("id") != id or not types.has(unit.get("type_id")):
			errors.append("Malformed unit: %s." % str(id))
			continue
		if not unit.get("owner") is int or unit.owner < 0 or not unit.get("routed") is bool:
			errors.append("Invalid owner or routed status: %s." % str(id))
		if not unit.get("damage") is int or unit.damage < 0:
			errors.append("Invalid damage: %s." % str(id))
		var area: String = str(unit.get("area_id", ""))
		if not board.areas.has(area):
			errors.append("Unknown unit area: %s." % area)
			continue
		var expected: String = "planet" if types[unit.type_id].domain == "ground" else "space"
		if board.areas[area].type != expected:
			errors.append("Unit %s occupies the wrong area type." % str(id))
	for collection: String in ["structures", "relics"]:
		for id: Variant in state[collection]:
			var item: Variant = state[collection][id]
			if not item is Dictionary or item.get("id") != id or not board.areas.has(item.get("area_id")):
				errors.append("Malformed %s entry: %s." % [collection, str(id)])
			elif board.areas[item.area_id].type != "planet":
				errors.append("%s must occupy planets." % collection)
	return errors


static func legal_action(board: Dictionary, state: Dictionary, types: Dictionary, actor: int, action: Dictionary) -> Dictionary:
	if actor < 0:
		return _failure("Choose a player.")
	if action.get("type") != "dispatch":
		return _failure("Unknown action.")
	var origin: Variant = action.get("origin")
	var destination: Variant = action.get("destination")
	var ids: Variant = action.get("unit_ids")
	if not origin is String or not destination is String or not board.areas.has(origin) or not board.areas.has(destination):
		return _failure("Choose known origin and destination areas.")
	if not ids is Array or ids.is_empty():
		return _failure("Select at least one unit.")
	var domain: String = ""
	var seen: Dictionary = {}
	for id: Variant in ids:
		if not id is String or seen.has(id) or not state.units.has(id):
			return _failure("Unit IDs must exist and appear only once.")
		seen[id] = true
		var unit: Dictionary = state.units[id]
		if unit.owner != actor:
			return _failure("You can only move your own units.")
		if unit.area_id != origin:
			return _failure("A selected unit has left the origin.")
		if unit.routed:
			return _failure("Routed units cannot Dispatch.")
		var unit_domain: String = types[unit.type_id].domain
		if not domain.is_empty() and domain != unit_domain:
			return _failure("Ships and ground units cannot share a Dispatch.")
		domain = unit_domain
	if not board.areas[destination].tile_id in board.tile_neighbors[board.areas[origin].tile_id]:
		return _failure("Choose an area in a side-adjacent tile.")
	var expected: String = "planet" if domain == "ground" else "space"
	if board.areas[destination].type != expected:
		return _failure("Ground units land on planets; ships remain in space.")
	var path: Array[String] = []
	if domain == "ground":
		path = support_path(board, state, types, actor, origin, destination)
		if path.is_empty():
			return _failure("No unbroken path of friendly planets and ships reaches this planet.")
	var battle: bool = _enemy_force(state, actor, destination)
	return {"ok": true, "reason": "Battle required on arrival." if battle else "Legal route.", "path": path, "battle_required": battle}


static func legal_destinations(board: Dictionary, state: Dictionary, types: Dictionary, actor: int, origin: String, ids: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for destination: String in board.areas:
		var verdict: Dictionary = legal_action(board, state, types, actor, {
			"type": "dispatch", "origin": origin, "destination": destination, "unit_ids": ids,
		})
		if verdict.ok:
			result[destination] = verdict
	return result


static func support_path(board: Dictionary, state: Dictionary, types: Dictionary, actor: int, origin: String, destination: String) -> Array[String]:
	if not board.areas.has(origin) or not board.areas.has(destination):
		return []
	var queue: Array[String] = [origin]
	var previous: Dictionary = {origin: ""}
	var index: int = 0
	while index < queue.size():
		var current: String = queue[index]
		index += 1
		if current == destination:
			var path: Array[String] = []
			while not current.is_empty():
				path.push_front(current)
				current = previous[current]
			return path
		for neighbor: String in board.support_neighbors[current]:
			if previous.has(neighbor):
				continue
			if neighbor != destination and not _supports(board, state, types, actor, neighbor):
				continue
			previous[neighbor] = current
			queue.append(neighbor)
	return []


static func apply_lab_move(board: Dictionary, state: Dictionary, types: Dictionary, actor: int, action: Dictionary) -> Dictionary:
	# Limited movement lab, not token execution or the full conquest transaction.
	if state.get("mode") != "movement_lab":
		return _failure("This transition is only available in the movement lab.")
	var verdict: Dictionary = legal_action(board, state, types, actor, action)
	if not verdict.ok:
		return verdict
	if verdict.battle_required:
		return _failure("This destination requires a battle; combat is the next milestone.")
	for relic: Dictionary in state.relics.values():
		if relic.area_id == action.destination:
			return _failure("Relic conquest is the next milestone. Preview this route instead.")
	for building: Dictionary in state.structures.values():
		if building.area_id == action.destination and building.owner != actor:
			return _failure("Structure capture is the next milestone. Preview this route instead.")
	var next: Dictionary = state.duplicate(true)
	for id: String in action.unit_ids:
		next.units[id].area_id = action.destination
	if board.areas[action.destination].type == "planet":
		next.owners[action.destination] = actor
	var event: Dictionary = {"type": "lab_move", "actor": actor, "origin": action.origin, "destination": action.destination, "unit_ids": action.unit_ids.duplicate(), "path": verdict.path.duplicate()}
	next.events.append(event)
	return {"ok": true, "state": next, "event": event}


static func _supports(board: Dictionary, state: Dictionary, types: Dictionary, actor: int, area: String) -> bool:
	var ship: bool = false
	for unit: Dictionary in state.units.values():
		if unit.area_id == area:
			if unit.owner != actor:
				return false
			ship = ship or types[unit.type_id].domain == "space"
	for building: Dictionary in state.structures.values():
		if building.area_id == area and building.owner != actor:
			return false
	if board.areas[area].type == "planet":
		return state.owners.get(area, -1) == actor
	return ship


static func _enemy_force(state: Dictionary, actor: int, area: String) -> bool:
	for unit: Dictionary in state.units.values():
		if unit.area_id == area and unit.owner != actor:
			return true
	for building: Dictionary in state.structures.values():
		if building.area_id == area and building.owner != actor and building.type == "defense":
			return true
	return false


static func _failure(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "path": [], "battle_required": false}
