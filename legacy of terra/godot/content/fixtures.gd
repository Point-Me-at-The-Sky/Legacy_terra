extends RefCounted
## Deliberately small test content, not final factions or a balanced map.

const BoardMap = preload("res://rules/board_map.gd")
const CombatContent = preload("res://content/combat_content.gd")
const QUADRANTS: Array[String] = ["nw", "ne", "sw", "se"]
const UNIT_TYPES: Dictionary = CombatContent.UNIT_TYPES


static func map_definition(transport: bool = false) -> Dictionary:
	var tiles: Array[Dictionary] = []
	for index: int in range(2):
		var id: String = "tile-a" if index == 0 else "tile-b"
		var quadrants: Dictionary = {}
		for quadrant: String in QUADRANTS:
			var planet: bool = quadrant == "nw" or (not transport and quadrant == "ne")
			quadrants[quadrant] = {
				"id": id + ":" + quadrant,
				"type": "planet" if planet else "space",
				"name": ("Ember" if index == 0 else "Vesper") + " " + quadrant.to_upper(),
			}
		tiles.append({"id": id, "position": [index, 0], "quadrants": quadrants})
	return {"tiles": tiles}


static func create(transport: bool = false) -> Dictionary:
	var board: Dictionary = BoardMap.build(map_definition(transport))
	var owners: Dictionary = {}
	for id: String in board.areas:
		owners[id] = -1
	var state: Dictionary = {
		"schema_version": 1, "mode": "movement_lab", "owners": owners,
		"units": {}, "structures": {}, "relics": {}, "events": [],
	}
	if transport:
		state.owners["tile-a:nw"] = 0
		_add_unit(state, "a-ground", 0, "ground_1", "tile-a:nw")
		_add_unit(state, "support-1", 0, "space_1", "tile-a:sw")
		_add_unit(state, "support-2", 0, "space_1", "tile-a:se")
		_add_unit(state, "support-3", 0, "space_1", "tile-b:sw")
	else:
		for player: int in range(2):
			var tile: String = "tile-a" if player == 0 else "tile-b"
			for quadrant: String in ["nw", "ne"]:
				var id: String = tile + ":" + quadrant
				state.owners[id] = player
				_add_unit(state, id + "-ground", player, "ground_1", id)
				state.relics[id + "-relic"] = {"id": id + "-relic", "placing_player": player, "area_id": id}
			_add_unit(state, tile + "-ship", player, "space_1", tile + ":se")
			state.structures[tile + "-production"] = {
				"id": tile + "-production", "owner": player,
				"type": "production", "area_id": tile + ":nw",
			}
	return {"board": board, "state": state}


static func _add_unit(state: Dictionary, id: String, owner: int, type_id: String, area: String) -> void:
	state.units[id] = {"id": id, "owner": owner, "type_id": type_id, "area_id": area, "routed": false, "damage": 0}
