extends RefCounted
class_name DemoAgent

# Minimal deterministic local-farm policy.
# Priority: harvest mature -> sell produce -> water planted -> plant empty -> talk.
func choose_action(observation: Dictionary) -> Dictionary:
	var inventory: Dictionary = observation.get("inventory", {})
	var farm_plots: Array = observation.get("farm_plots", [])

	for plot in farm_plots:
		if String(plot.get("state", "empty")) == "mature":
			return {
				"name": "harvest",
				"params": {
					"tile": plot.get("tile", Vector2i.ZERO)
				}
			}

	if int(inventory.get("parsnip", 0)) > 0:
		return {
			"name": "sell",
			"params": {
				"item_id": "parsnip",
				"qty": 1
			}
		}

	for plot in farm_plots:
		if String(plot.get("state", "empty")) == "planted":
			return {
				"name": "water",
				"params": {
					"tile": plot.get("tile", Vector2i.ZERO)
				}
			}

	if int(inventory.get("parsnip_seed", 0)) > 0:
		for plot in farm_plots:
			if String(plot.get("state", "empty")) == "empty":
				return {
					"name": "plant",
					"params": {
						"seed_id": "parsnip_seed",
						"tile": plot.get("tile", Vector2i.ZERO)
					}
				}

	return {
		"name": "talk_to",
		"params": {
			"npc_id": "NPC_Alice"
		}
	}
