extends RefCounted

const Movement = preload("res://rules/movement.gd")


static func destinations(board: Dictionary, world: Dictionary, types: Dictionary, player: int,
		battle_area: String, attack_origin: String, domain: String, was_attacker: bool) -> Dictionary:
	var result: Dictionary = {}
	var battle_tile: String = board.areas[battle_area].tile_id
	var forbidden_tile: String = board.areas[attack_origin].tile_id if not was_attacker else ""
	for area_id: String in board.areas:
		var area: Dictionary = board.areas[area_id]
		if area.tile_id == forbidden_tile or not area.tile_id in board.tile_neighbors[battle_tile]:
			continue
		if area.type != ("planet" if domain == "ground" else "space"):
			continue
		var friendly_ship: bool = false
		var hostile: bool = false
		for unit: Dictionary in world.units.values():
			if unit.area_id == area_id:
				hostile = hostile or unit.owner != player
				friendly_ship = friendly_ship or (unit.owner == player and types[unit.type_id].domain == "space")
		for building: Dictionary in world.structures.values():
			if building.area_id == area_id and building.owner != player:
				hostile = true
		if hostile:
			continue
		if domain == "ground":
			if world.owners.get(area_id, -1) != player:
				continue
			var path: Array[String] = Movement.support_path(board, world, types, player, battle_area, area_id)
			if not path.is_empty():
				result[area_id] = path
		elif friendly_ship:
			result[area_id] = []
	return result
