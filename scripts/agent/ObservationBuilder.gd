extends Node
class_name ObservationBuilder

func build_snapshot(player: Node2D, world: Node) -> Dictionary:
	var nearby_objects := []
	if player != null and world != null:
		nearby_objects = _collect_nearby_objects(player, world)

	var farm_plots: Array = []
	var farm_system := world.get_node_or_null("FarmSystem") if world != null else null
	if farm_system != null and farm_system is FarmSystem:
		farm_plots = farm_system.get_all_plots()

	return {
		"time": GameState.get_time_data(),
		"player": {
			"position": _vector2_to_dict(player.global_position if player != null else Vector2.ZERO),
			"energy": GameState.energy,
			"gold": GameState.gold
		},
		"inventory": GameState.inventory.duplicate(true),
		"nearby_objects": nearby_objects,
		"farm_plots": farm_plots,
		"current_quest": GameState.get_quest_data()
	}

func _collect_nearby_objects(player: Node2D, world: Node, max_distance: float = 120.0) -> Array:
	var result: Array = []
	for child in world.get_children():
		if child == player:
			continue
		if child is Node2D:
			var dist := player.global_position.distance_to(child.global_position)
			if dist <= max_distance:
				result.append({
					"id": str(child.name),
					"type": child.get_class(),
					"position": _vector2_to_dict(child.global_position),
					"distance": dist
				})
	return result

func _vector2_to_dict(v: Vector2) -> Dictionary:
	return {"x": v.x, "y": v.y}
