extends RefCounted
## Small rules-owned PRNG. Integer state survives serialization and replay.

const MODULUS: int = 2147483647


static func normalize(seed_value: int) -> int:
	return posmod(seed_value, MODULUS - 1) + 1


static func bounded(state: int, count: int) -> Dictionary:
	assert(state > 0 and state < MODULUS and count > 0 and count < MODULUS)
	var next: int = state
	var limit: int = MODULUS - 1 - ((MODULUS - 1) % count)
	while true:
		next = (next * 48271) % MODULUS
		var sample: int = next - 1
		if sample < limit:
			return {"state": next, "value": sample % count}
	return {}


static func shuffle(cards: Array, state: int) -> Dictionary:
	var result: Array = cards.duplicate()
	var next: int = state
	for index: int in range(result.size() - 1, 0, -1):
		var draw: Dictionary = bounded(next, index + 1)
		next = draw.state
		var swap: Variant = result[index]
		result[index] = result[draw.value]
		result[draw.value] = swap
	return {"cards": result, "state": next}
