extends Node
class_name ActionDispatcher

signal action_started(action_name: String, payload: Dictionary)
signal action_finished(action_name: String, result: Dictionary)
signal time_advanced(time_data: Dictionary)
signal inventory_changed(inventory: Dictionary)
signal quest_updated(quest: Dictionary)
signal action_completed(action_name: String, result: Dictionary)

@onready var farm_system: FarmSystem = get_node_or_null("../FarmSystem")

func execute(action_name: String, params: Dictionary = {}) -> Dictionary:
	return execute_for_actor(null, action_name, params)

func execute_for_actor(actor: Node, action_name: String, params: Dictionary = {}) -> Dictionary:
	var validation := ActionSchema.validate(action_name, params)
	if not bool(validation.get("ok", false)):
		return _result(false, String(validation.get("error_code", "invalid_action")), 0.0, 0.0)

	match action_name:
		"move_to":
			var body := actor as CharacterBody2D
			return move_to(
				body,
				params.get("target", null),
				params.get("direction", Vector2.ZERO),
				float(params.get("delta", 0.0)),
				float(params.get("speed", 0.0))
			)
		"interact":
			return interact(actor, str(params.get("target_id", "")))
		"plant":
			return plant(actor, str(params.get("seed_id", "")), params.get("tile", Vector2i.ZERO))
		"water":
			return water(actor, params.get("tile", Vector2i.ZERO))
		"harvest":
			return harvest(actor, params.get("tile", Vector2i.ZERO))
		"sell":
			return sell(actor, str(params.get("item_id", "")), int(params.get("qty", 1)))
		"talk_to":
			return talk_to(actor, str(params.get("npc_id", "")))
		_:
			return _result(false, "unknown_action", 0.0, 0.0)

func move_to(actor: CharacterBody2D, target: Variant, direction: Vector2, delta: float, speed: float) -> Dictionary:
	var payload := {
		"target": target,
		"direction": direction,
		"delta": delta,
		"speed": speed
	}
	action_started.emit("move_to", payload)

	if actor == null:
		var missing_actor := _result(false, "actor_missing", 0.0, 0.0)
		_emit_action_finish("move_to", missing_actor)
		return missing_actor

	var final_direction := direction
	if target is Vector2:
		var to_target: Vector2 = (target as Vector2) - actor.global_position
		if to_target.length() <= 2.0:
			final_direction = Vector2.ZERO
		else:
			final_direction = to_target.normalized()

	if final_direction == Vector2.ZERO:
		actor.velocity = Vector2.ZERO
		var idle_result := _result(true, "", 0.0, 0.0)
		_emit_action_finish("move_to", idle_result)
		return idle_result

	actor.velocity = final_direction.normalized() * max(speed, 1.0)
	actor.move_and_slide()

	var time_data := GameState.advance_time(1)
	time_advanced.emit(time_data)

	var completed := _result(true, "", max(delta, 0.1), 0.0, [{"type": "action_completed", "action": "move_to"}])
	_emit_action_finish("move_to", completed)
	return completed

func interact(actor: Node, target_id: String) -> Dictionary:
	action_started.emit("interact", {"target_id": target_id})
	if target_id.is_empty():
		var invalid_target := _result(false, "invalid_target", 0.0, 0.0)
		_emit_action_finish("interact", invalid_target)
		return invalid_target

	if target_id == "ShippingBin":
		var sold_count := _sell_all_sellable_items(actor)
		var time_data := GameState.advance_time(1)
		time_advanced.emit(time_data)
		var sold_result := _result(true, "", 1.0, 0.0, [{"type": "sold_items", "count": sold_count}])
		_emit_action_finish("interact", sold_result)
		return sold_result

	if target_id == "NPC_Alice":
		return talk_to(actor, target_id)

	if target_id == "MapExit_Town":
		return _change_map("res://scenes/Town.tscn")

	if target_id == "MapExit_Farm":
		return _change_map("res://scenes/Main.tscn")

	var unknown_target := _result(false, "unknown_target", 0.0, 0.0)
	_emit_action_finish("interact", unknown_target)
	return unknown_target

func plant(_actor: Node, seed_id: String, tile: Vector2i) -> Dictionary:
	action_started.emit("plant", {"seed_id": seed_id, "tile": tile})
	if farm_system == null:
		var missing_farm := _result(false, "farm_system_missing", 0.0, 0.0)
		_emit_action_finish("plant", missing_farm)
		return missing_farm

	if seed_id.is_empty():
		var empty_seed := _result(false, "invalid_seed", 0.0, 0.0)
		_emit_action_finish("plant", empty_seed)
		return empty_seed

	if not GameState.remove_item(seed_id, 1):
		var no_seed := _result(false, "missing_seed", 0.0, 0.0)
		_emit_action_finish("plant", no_seed)
		return no_seed

	var farm_result := farm_system.plant_seed(tile, seed_id)
	if not bool(farm_result.get("ok", false)):
		GameState.add_item(seed_id, 1)
		var farm_error := _result(false, String(farm_result.get("error_code", "farm_error")), 0.0, 0.0)
		_emit_action_finish("plant", farm_error)
		return farm_error

	GameState.adjust_energy(-2)
	var time_data := GameState.advance_time(1)
	time_advanced.emit(time_data)
	inventory_changed.emit(GameState.inventory.duplicate(true))

	var planted := _result(true, "", 1.0, 2.0, [{"type": "inventory_changed"}, {"type": "farm_plot_changed", "tile": tile}])
	_emit_action_finish("plant", planted)
	return planted

func water(_actor: Node, tile: Vector2i) -> Dictionary:
	action_started.emit("water", {"tile": tile})
	if farm_system == null:
		var missing_farm := _result(false, "farm_system_missing", 0.0, 0.0)
		_emit_action_finish("water", missing_farm)
		return missing_farm

	var farm_result := farm_system.water(tile)
	if not bool(farm_result.get("ok", false)):
		var farm_error := _result(false, String(farm_result.get("error_code", "farm_error")), 0.0, 0.0)
		_emit_action_finish("water", farm_error)
		return farm_error

	GameState.adjust_energy(-1)
	var time_data := GameState.advance_time(1)
	time_advanced.emit(time_data)
	var result := _result(true, "", 1.0, 1.0, [{"type": "farm_plot_changed", "tile": tile}])
	_emit_action_finish("water", result)
	return result

func harvest(_actor: Node, tile: Vector2i) -> Dictionary:
	action_started.emit("harvest", {"tile": tile})
	if farm_system == null:
		var missing_farm := _result(false, "farm_system_missing", 0.0, 0.0)
		_emit_action_finish("harvest", missing_farm)
		return missing_farm

	var farm_result := farm_system.harvest(tile)
	if not bool(farm_result.get("ok", false)):
		var farm_error := _result(false, String(farm_result.get("error_code", "farm_error")), 0.0, 0.0)
		_emit_action_finish("harvest", farm_error)
		return farm_error

	var produce_id := String(farm_result.get("produce_id", "crop"))
	GameState.add_item(produce_id, 1)
	GameState.bump_quest_progress(1)
	GameState.adjust_energy(-2)
	var time_data := GameState.advance_time(1)
	time_advanced.emit(time_data)
	inventory_changed.emit(GameState.inventory.duplicate(true))
	quest_updated.emit(GameState.get_quest_data())
	var result := _result(true, "", 1.0, 2.0, [{"type": "inventory_changed"}, {"type": "quest_updated"}, {"type": "farm_plot_changed", "tile": tile}])
	_emit_action_finish("harvest", result)
	return result

func sell(_actor: Node, item_id: String, qty: int) -> Dictionary:
	action_started.emit("sell", {"item_id": item_id, "qty": qty})
	if qty <= 0:
		var bad_qty := _result(false, "invalid_qty", 0.0, 0.0)
		_emit_action_finish("sell", bad_qty)
		return bad_qty

	if not GameState.remove_item(item_id, qty):
		var missing_item := _result(false, "missing_item", 0.0, 0.0)
		_emit_action_finish("sell", missing_item)
		return missing_item

	var price_table := {
		"parsnip": 35,
		"parsnip_seed": 8
	}
	var unit_price := int(price_table.get(item_id, 1))
	GameState.adjust_gold(unit_price * qty)
	var time_data := GameState.advance_time(1)
	time_advanced.emit(time_data)
	inventory_changed.emit(GameState.inventory.duplicate(true))
	var result := _result(true, "", 1.0, 0.0, [{"type": "inventory_changed"}])
	_emit_action_finish("sell", result)
	return result

func talk_to(_actor: Node, npc_id: String) -> Dictionary:
	action_started.emit("talk_to", {"npc_id": npc_id})
	if npc_id.is_empty():
		var invalid := _result(false, "invalid_npc", 0.0, 0.0)
		_emit_action_finish("talk_to", invalid)
		return invalid

	var time_data := GameState.advance_time(1)
	time_advanced.emit(time_data)
	var result := _result(true, "", 1.0, 0.0, [{"type": "npc_talked", "npc_id": npc_id}])
	_emit_action_finish("talk_to", result)
	return result

func _change_map(scene_path: String) -> Dictionary:
	if scene_path.is_empty():
		var invalid := _result(false, "invalid_scene_path", 0.0, 0.0)
		_emit_action_finish("interact", invalid)
		return invalid
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		var failed := _result(false, "map_change_failed", 0.0, 0.0)
		_emit_action_finish("interact", failed)
		return failed
	var result := _result(true, "", 1.0, 0.0, [{"type": "map_changed", "scene": scene_path}])
	_emit_action_finish("interact", result)
	return result

func _sell_all_sellable_items(_actor: Node) -> int:
	var sold_count := 0
	var price_table := {
		"parsnip": 35,
		"parsnip_seed": 8
	}
	for item_id in price_table.keys():
		var qty := int(GameState.inventory.get(item_id, 0))
		if qty <= 0:
			continue
		GameState.remove_item(item_id, qty)
		GameState.adjust_gold(int(price_table[item_id]) * qty)
		sold_count += qty
	inventory_changed.emit(GameState.inventory.duplicate(true))
	return sold_count

func _emit_action_finish(action_name: String, result: Dictionary) -> void:
	action_finished.emit(action_name, result)
	action_completed.emit(action_name, result)

func _result(success: bool, error_code: String, time_cost: float, energy_cost: float, emitted_events: Array = []) -> Dictionary:
	return {
		"success": success,
		"error_code": error_code,
		"time_cost": time_cost,
		"energy_cost": energy_cost,
		"emitted_events": emitted_events
	}
