extends RefCounted
## Deterministic lab opponent. Receives ONLY Battle.view_for(), never hidden state.


static func choose_action(view: Dictionary) -> Dictionary:
	if view.legal_actions.is_empty():
		return {}
	var best: Dictionary = view.legal_actions[0]
	var best_score: float = -INF
	var side: int = 0 if view.sides[0].player == view.player else 1
	for action: Dictionary in view.legal_actions:
		var score: float = 0
		if action.type == "commit_card":
			for card: Dictionary in view.hand:
				if card.id != action.card_id: continue
				var prerequisite: bool = false
				for force: Dictionary in view.sides[side].forces:
					if not force.structure and not force.routed and force.type_id in ["ground_1", "space_1"]:
						prerequisite = true
				var incoming: int = view.rolls[1 - side].attack - view.rolls[side].defense
				score = card.leadership + (1 if card.has("special") and prerequisite else 0)
				score += card.defense * (3 if incoming > 0 else 0)
				score += card.damage * (2 if view.rolls[side].attack >= view.rolls[1 - side].defense else 0)
		elif action.type == "assign_damage":
			for force: Dictionary in view.sides[side].forces:
				if force.target == action.target:
					# Spend low-value units before high-attack or high-leadership ones.
					score = -float(force.attack * 2 + force.leadership)
		if score > best_score:
			best_score = score
			best = action
	return best.duplicate(true)
