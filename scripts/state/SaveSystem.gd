extends Node
class_name SaveSystem

const SAVE_PATH := "user://openfarm_save.json"

func save_game() -> Dictionary:
	var tree := get_tree()
	var scene := tree.current_scene
	if scene == null:
		return {"ok": false, "error_code": "no_current_scene"}

	var payload := {
		"version": 1,
		"scene_path": String(scene.scene_file_path),
		"game_state": GameState.to_dict(),
		"farm_plots": _collect_farm_plots(scene)
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error_code": "open_failed"}
	file.store_string(JSON.stringify(payload))
	file.close()
	return {"ok": true, "error_code": "", "path": SAVE_PATH}

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {"ok": false, "error_code": "save_not_found"}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {"ok": false, "error_code": "open_failed"}
	var raw := file.get_as_text()
	file.close()

	var parsed := JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "error_code": "invalid_save_format"}
	var data: Dictionary = parsed

	GameState.from_dict(data.get("game_state", {}))

	var scene_path := String(data.get("scene_path", ""))
	if scene_path.is_empty():
		return {"ok": false, "error_code": "missing_scene_path"}

	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		return {"ok": false, "error_code": "scene_change_failed"}

	call_deferred("_restore_scene_state", data)
	return {"ok": true, "error_code": "", "scene_path": scene_path}

func _restore_scene_state(data: Dictionary) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var farm_system := scene.get_node_or_null("FarmSystem")
	if farm_system != null and farm_system is FarmSystem:
		var plots: Array = data.get("farm_plots", [])
		farm_system.set_all_plots(plots)

func _collect_farm_plots(scene: Node) -> Array:
	var farm_system := scene.get_node_or_null("FarmSystem")
	if farm_system == null or not (farm_system is FarmSystem):
		return []
	var raw_plots: Array = farm_system.get_all_plots()
	var serializable: Array = []
	for plot in raw_plots:
		if not (plot is Dictionary):
			continue
		var p: Dictionary = plot
		var tile: Vector2i = p.get("tile", Vector2i.ZERO)
		var world_position: Vector2 = p.get("world_position", Vector2.ZERO)
		serializable.append({
			"tile": {"x": tile.x, "y": tile.y},
			"world_position": {"x": world_position.x, "y": world_position.y},
			"state": str(p.get("state", "empty")),
			"seed_id": str(p.get("seed_id", "")),
			"growth": int(p.get("growth", 0)),
			"growth_needed": int(p.get("growth_needed", 2))
		})
	return serializable
