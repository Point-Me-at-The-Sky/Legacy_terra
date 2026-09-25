extends RefCounted
## Battle-only scenarios. No relics, economy, or strategic turns are simulated.

const Fixtures = preload("res://content/fixtures.gd")
const BoardMap = preload("res://rules/board_map.gd")


static func create(scenario: int = 0) -> Dictionary:
	var definition: Dictionary = Fixtures.map_definition()
	var third: Dictionary = definition.tiles[1].duplicate(true)
	third.id = "tile-c"
	third.position = [2, 0]
	for quadrant: String in third.quadrants:
		third.quadrants[quadrant].id = "tile-c:" + quadrant
		third.quadrants[quadrant].name = "Vesper refuge " + quadrant.to_upper()
	definition.tiles.append(third)
	var board: Dictionary = BoardMap.build(definition)
	var world: Dictionary = {"mode": "battle_lab", "owners": {}, "units": {}, "structures": {}, "relics": {}, "events": []}
	for id: String in board.areas:
		world.owners[id] = (0 if board.areas[id].tile_id == "tile-a" else 1) if board.areas[id].type == "planet" else -1
	var domain: String = "space" if scenario == 1 else "ground"
	var origin: String = "tile-a:se" if scenario == 1 else "tile-a:ne"
	var destination: String = "tile-b:sw" if scenario == 1 else "tile-b:nw"
	for index: int in range(2):
		_add(world, "a%d" % (index + 1), 0, domain + "_1", origin)
		if scenario != 2:
			_add(world, "d%d" % (index + 1), 1, domain + "_1", destination)
	if scenario == 1:
		_add(world, "a-support", 0, "space_1", "tile-a:sw")
		_add(world, "d-support", 1, "space_1", "tile-c:sw")
	if scenario == 2:
		world.structures.fort = {"id": "fort", "owner": 1, "area_id": destination, "type": "defense", "damage": 0}
	return {"board": board, "world": world, "request": {"id": "lab-battle", "attacker": 0, "defender": 1,
		"origin": origin, "destination": destination, "unit_ids": ["a1", "a2"]}}


static func _add(world: Dictionary, id: String, owner: int, type_id: String, area: String) -> void:
	world.units[id] = {"id": id, "owner": owner, "type_id": type_id, "area_id": area, "routed": false, "damage": 0}
