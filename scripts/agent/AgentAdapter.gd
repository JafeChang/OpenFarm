extends Node
class_name AgentAdapter

signal event_emitted(event_name: String, payload: Dictionary)

@export var player_path: NodePath
@export var world_path: NodePath
@export var action_dispatcher_path: NodePath

@onready var _player: Node2D = get_node_or_null(player_path)
@onready var _world: Node = get_node_or_null(world_path)
@onready var _action_dispatcher: ActionDispatcher = get_node_or_null(action_dispatcher_path)

var _observation_builder := ObservationBuilder.new()
var _capabilities := {
	"move_to": true,
	"interact": true,
	"plant": true,
	"water": true,
	"harvest": true,
	"sell": true,
	"talk_to": true,
	"rest": true
}

func _ready() -> void:
	if _action_dispatcher != null:
		_action_dispatcher.action_started.connect(_on_action_started)
		_action_dispatcher.action_finished.connect(_on_action_finished)
		_action_dispatcher.time_advanced.connect(_on_time_advanced)
		_action_dispatcher.inventory_changed.connect(_on_inventory_changed)
		_action_dispatcher.quest_updated.connect(_on_quest_updated)

func get_observation() -> Dictionary:
	return _observation_builder.build_snapshot(_player, _world)

func submit_action(action_name: String, params: Dictionary = {}) -> Dictionary:
	if _action_dispatcher == null:
		return {
			"success": false,
			"error_code": "dispatcher_missing",
			"time_cost": 0.0,
			"energy_cost": 0.0,
			"emitted_events": []
		}
	if not bool(_capabilities.get(action_name, false)):
		return {
			"success": false,
			"error_code": "capability_blocked",
			"time_cost": 0.0,
			"energy_cost": 0.0,
			"emitted_events": []
		}

	return _action_dispatcher.execute_for_actor(_player, action_name, params)

func set_capabilities(next_capabilities: Dictionary) -> void:
	for key in _capabilities.keys():
		if next_capabilities.has(key):
			_capabilities[key] = bool(next_capabilities[key])

func get_capabilities() -> Dictionary:
	return _capabilities.duplicate(true)

func _on_action_started(action_name: String, payload: Dictionary) -> void:
	event_emitted.emit("action_started", {
		"action": action_name,
		"payload": payload
	})

func _on_action_finished(action_name: String, result: Dictionary) -> void:
	event_emitted.emit("action_finished", {
		"action": action_name,
		"result": result
	})

func _on_time_advanced(time_data: Dictionary) -> void:
	event_emitted.emit("time_advanced", time_data)

func _on_inventory_changed(inventory: Dictionary) -> void:
	event_emitted.emit("inventory_changed", {"inventory": inventory})

func _on_quest_updated(quest: Dictionary) -> void:
	event_emitted.emit("quest_updated", {"quest": quest})
