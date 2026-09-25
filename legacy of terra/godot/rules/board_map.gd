extends RefCounted
## Validated, serializable topology. Never reads screen positions or scene nodes.

const QUADRANTS: Array[String] = ["nw", "ne", "sw", "se"]
const OFFSETS: Dictionary = {"nw": [0, 0], "ne": [1, 0], "sw": [0, 1], "se": [1, 1]}


static func build(definition: Dictionary) -> Dictionary:
	var errors: PackedStringArray = []
	var tiles: Dictionary = {}
	var areas: Dictionary = {}
	var positions: Dictionary = {}
	var source: Variant = definition.get("tiles")
	if not source is Array or source.is_empty():
		return {"ok": false, "errors": ["A map needs a nonempty tiles array."]}
	for entry: Variant in source:
		if not entry is Dictionary:
			errors.append("Each tile must be a dictionary.")
			continue
		var id: Variant = entry.get("id")
		var position: Variant = entry.get("position")
		var quadrants: Variant = entry.get("quadrants")
		if not id is String or id.is_empty() or tiles.has(id):
			errors.append("Tile IDs must be unique, nonempty strings.")
			continue
		if not _is_grid_position(position):
			errors.append("Tile %s needs two integer coordinates." % id)
			continue
		var position_key: String = "%s,%s" % [position[0], position[1]]
		if positions.has(position_key):
			errors.append("Tiles cannot overlap: %s." % position_key)
			continue
		if not quadrants is Dictionary or quadrants.size() != 4:
			errors.append("Tile %s must have exactly four quadrants." % id)
			continue
		positions[position_key] = id
		tiles[id] = {"id": id, "position": position.duplicate(), "areas": []}
		for quadrant: String in QUADRANTS:
			var data: Variant = quadrants.get(quadrant)
			if not data is Dictionary or not data.get("type") in ["planet", "space"]:
				errors.append("Tile %s needs a planet or space at %s." % [id, quadrant])
				continue
			var area_id: Variant = data.get("id")
			if not area_id is String or area_id.is_empty() or areas.has(area_id):
				errors.append("Area IDs must be unique, nonempty strings.")
				continue
			var offset: Array = OFFSETS[quadrant]
			areas[area_id] = {
				"id": area_id, "tile_id": id, "quadrant": quadrant,
				"type": data.type, "name": str(data.get("name", area_id)),
				"cell": [2 * position[0] + offset[0], 2 * position[1] + offset[1]],
			}
			tiles[id].areas.append(area_id)
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	return {
		"ok": true, "errors": [], "tiles": tiles, "areas": areas,
		"tile_neighbors": _neighbors(tiles, "position"),
		"support_neighbors": _neighbors(areas, "cell"),
	}


static func _is_grid_position(value: Variant) -> bool:
	return value is Array and value.size() == 2 and value[0] is int and value[1] is int


static func _neighbors(entries: Dictionary, coordinate_key: String) -> Dictionary:
	var result: Dictionary = {}
	for id: String in entries:
		var neighbors: Array[String] = []
		var a: Array = entries[id][coordinate_key]
		for other: String in entries:
			var b: Array = entries[other][coordinate_key]
			if absi(a[0] - b[0]) + absi(a[1] - b[1]) == 1:
				neighbors.append(other)
		neighbors.sort()
		result[id] = neighbors
	return result
