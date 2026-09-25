extends RefCounted
## Original P-009/P-011 test content, shared by ground and space combat.

const UNIT_TYPES: Dictionary = {
	"ground_1": {"name": "Ground 1", "domain": "ground", "attack": 1, "health": 3, "leadership": 1},
	"ground_2": {"name": "Ground 2", "domain": "ground", "attack": 2, "health": 4, "leadership": 1},
	"ground_3": {"name": "Ground 3", "domain": "ground", "attack": 3, "health": 5, "leadership": 2},
	"space_1": {"name": "Space 1", "domain": "space", "attack": 1, "health": 3, "leadership": 1},
	"space_2": {"name": "Space 2", "domain": "space", "attack": 2, "health": 5, "leadership": 2},
}
const CARDS: Dictionary = {
	"strike": {"name": "Strike", "damage": 1, "defense": 0, "leadership": 0},
	"guard": {"name": "Guard", "damage": 0, "defense": 1, "leadership": 0},
	"focus": {"name": "Focus", "damage": 0, "defense": 0, "leadership": 1,
		"special": {"requires": ["ground_1", "space_1"], "allOf": false, "effect": "leadership", "amount": 1}},
}
const DECK: Dictionary = {
	"strike_1": "strike", "strike_2": "strike", "guard_1": "guard",
	"guard_2": "guard", "focus_1": "focus", "focus_2": "focus",
}
const DEFENSE: Dictionary = {"name": "Defense building", "attack": 1, "health": 3, "leadership": 0, "defense": 1}
