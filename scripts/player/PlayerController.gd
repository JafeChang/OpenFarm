extends CharacterBody2D

@export var move_speed: float = 180.0
@export var interaction_radius: float = 90.0

@onready var action_dispatcher: ActionDispatcher = get_node_or_null("../ActionDispatcher")
@onready var farm_system: FarmSystem = get_node_or_null("../FarmSystem")

func _physics_process(delta: float) -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if action_dispatcher == null:
		velocity = input_direction * move_speed
		move_and_slide()
		return

	action_dispatcher.execute_for_actor(self, "move_to", {
		"direction": input_direction,
		"delta": delta,
		"speed": move_speed
	})

func _unhandled_input(event: InputEvent) -> void:
	if action_dispatcher == null or not event.is_pressed() or event.is_echo():
		return

	var tile := _get_nearest_tile()
	if Input.is_action_just_pressed("plant_action"):
		action_dispatcher.execute_for_actor(self, "plant", {
			"seed_id": "parsnip_seed",
			"tile": tile
		})
	elif Input.is_action_just_pressed("water_action"):
		action_dispatcher.execute_for_actor(self, "water", {
			"tile": tile
		})
	elif Input.is_action_just_pressed("harvest_action"):
		action_dispatcher.execute_for_actor(self, "harvest", {
			"tile": tile
		})
	elif Input.is_action_just_pressed("sell_action"):
		action_dispatcher.execute_for_actor(self, "sell", {
			"item_id": "parsnip",
			"qty": 1
		})
	elif Input.is_action_just_pressed("talk_action"):
		action_dispatcher.execute_for_actor(self, "talk_to", {
			"npc_id": "NPC_Alice"
		})
	elif Input.is_action_just_pressed("interact_action"):
		var target_id := _find_interaction_target_id()
		if not target_id.is_empty():
			action_dispatcher.execute_for_actor(self, "interact", {
				"target_id": target_id
			})

func _get_nearest_tile() -> Vector2i:
	if farm_system == null:
		return Vector2i.ZERO
	return farm_system.get_nearest_tile(global_position)

func _find_interaction_target_id() -> String:
	var world := get_parent()
	if world == null:
		return ""

	var candidates := ["NPC_Alice", "ShippingBin", "MapExit_Town", "MapExit_Farm"]
	var best_id := ""
	var best_dist := INF
	for candidate_id in candidates:
		var node := world.get_node_or_null(candidate_id)
		if node == null or not (node is Node2D):
			continue
		var dist := global_position.distance_to((node as Node2D).global_position)
		if dist <= interaction_radius and dist < best_dist:
			best_dist = dist
			best_id = candidate_id
	return best_id
