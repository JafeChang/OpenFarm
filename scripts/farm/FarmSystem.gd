extends Node2D
class_name FarmSystem

signal farm_plot_changed(plot: Dictionary)

@export var plot_origin: Vector2 = Vector2(480, 420)
@export var plot_spacing: Vector2 = Vector2(40, 40)
@export var plot_tiles: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(2, 0),
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(2, 1)
]

var _plots: Dictionary = {}

func _ready() -> void:
	_init_plots()
	GameState.time_changed.connect(_on_time_changed)

func _init_plots() -> void:
	_plots.clear()
	for tile in plot_tiles:
		_plots[tile] = {
			"tile": tile,
			"world_position": _tile_to_world(tile),
			"state": "empty", # empty | planted | watered | mature
			"seed_id": "",
			"growth": 0,
			"growth_needed": 2
		}

func get_plot(tile: Vector2i) -> Dictionary:
	if not _plots.has(tile):
		return {}
	return (_plots[tile] as Dictionary).duplicate(true)

func get_all_plots() -> Array:
	var result: Array = []
	for tile in _plots.keys():
		result.append((_plots[tile] as Dictionary).duplicate(true))
	return result

func get_nearest_tile(world_position: Vector2) -> Vector2i:
	var best_tile := Vector2i.ZERO
	var best_dist := INF
	for tile in plot_tiles:
		var tile_world := _tile_to_world(tile)
		var dist := world_position.distance_to(tile_world)
		if dist < best_dist:
			best_dist = dist
			best_tile = tile
	return best_tile

func plant_seed(tile: Vector2i, seed_id: String) -> Dictionary:
	if not _plots.has(tile):
		return {"ok": false, "error_code": "invalid_plot"}
	var plot: Dictionary = _plots[tile]
	if String(plot.get("state", "empty")) != "empty":
		return {"ok": false, "error_code": "plot_not_empty"}

	plot["state"] = "planted"
	plot["seed_id"] = seed_id
	plot["growth"] = 0
	_plots[tile] = plot
	farm_plot_changed.emit(plot.duplicate(true))
	return {"ok": true, "plot": plot.duplicate(true)}

func water(tile: Vector2i) -> Dictionary:
	if not _plots.has(tile):
		return {"ok": false, "error_code": "invalid_plot"}
	var plot: Dictionary = _plots[tile]
	var state := String(plot.get("state", "empty"))
	if state != "planted":
		return {"ok": false, "error_code": "plot_not_plantable"}

	plot["state"] = "watered"
	_plots[tile] = plot
	farm_plot_changed.emit(plot.duplicate(true))
	return {"ok": true, "plot": plot.duplicate(true)}

func harvest(tile: Vector2i) -> Dictionary:
	if not _plots.has(tile):
		return {"ok": false, "error_code": "invalid_plot"}
	var plot: Dictionary = _plots[tile]
	if String(plot.get("state", "empty")) != "mature":
		return {"ok": false, "error_code": "crop_not_ready"}

	var produce_id := _seed_to_crop(String(plot.get("seed_id", "")))
	plot["state"] = "empty"
	plot["seed_id"] = ""
	plot["growth"] = 0
	_plots[tile] = plot
	farm_plot_changed.emit(plot.duplicate(true))
	return {
		"ok": true,
		"produce_id": produce_id,
		"plot": plot.duplicate(true)
	}

func _seed_to_crop(seed_id: String) -> String:
	if seed_id.ends_with("_seed"):
		return seed_id.trim_suffix("_seed")
	return "crop"

func _tile_to_world(tile: Vector2i) -> Vector2:
	return plot_origin + Vector2(tile.x * plot_spacing.x, tile.y * plot_spacing.y)

func _on_time_changed(_day: int, period: String) -> void:
	# Advance growth once per day start (morning).
	if period != "morning":
		return
	for tile in _plots.keys():
		var plot: Dictionary = _plots[tile]
		if String(plot.get("state", "empty")) == "watered":
			plot["growth"] = int(plot.get("growth", 0)) + 1
			if int(plot.get("growth", 0)) >= int(plot.get("growth_needed", 2)):
				plot["state"] = "mature"
			else:
				plot["state"] = "planted"
			_plots[tile] = plot
			farm_plot_changed.emit(plot.duplicate(true))
