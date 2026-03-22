extends CanvasLayer
class_name GameHUD

@export var action_dispatcher_path: NodePath

@onready var action_dispatcher: ActionDispatcher = get_node_or_null(action_dispatcher_path)
@onready var time_label: Label = $RootPanel/Margin/VBox/TimeLabel
@onready var stat_label: Label = $RootPanel/Margin/VBox/StatLabel
@onready var inventory_label: Label = $RootPanel/Margin/VBox/InventoryLabel
@onready var quest_label: Label = $RootPanel/Margin/VBox/QuestLabel
@onready var message_label: Label = $RootPanel/Margin/VBox/MessageLabel

var _last_message := "Welcome to OpenFarm"

func _ready() -> void:
	if action_dispatcher != null:
		action_dispatcher.action_finished.connect(_on_action_finished)
	GameState.time_changed.connect(_refresh)
	GameState.inventory_changed.connect(_refresh_inventory)
	GameState.quest_updated.connect(_refresh_quest)
	_refresh(GameState.day, GameState.PERIODS[GameState.period_index])

func _process(_delta: float) -> void:
	_refresh(GameState.day, GameState.PERIODS[GameState.period_index])

func _on_action_finished(action_name: String, result: Dictionary) -> void:
	var ok := bool(result.get("success", false))
	var err := str(result.get("error_code", ""))
	if ok:
		_last_message = "Action %s completed" % action_name
	else:
		_last_message = "Action %s failed: %s" % [action_name, err]
	var events: Array = result.get("emitted_events", [])
	if not events.is_empty() and events[0] is Dictionary:
		var e: Dictionary = events[0]
		if e.has("text"):
			_last_message = str(e.get("text"))

func _refresh(_day: int, _period: String) -> void:
	if time_label == null:
		return
	time_label.text = "Day %d · %s" % [GameState.day, GameState.PERIODS[GameState.period_index]]
	stat_label.text = "Energy: %d    Gold: %d" % [GameState.energy, GameState.gold]
	inventory_label.text = "Inventory: %s" % _inventory_text(GameState.inventory)
	var quest := GameState.get_quest_data()
	quest_label.text = "Quest: %s [%s] %s/%s" % [
		str(quest.get("title", "-")),
		str(quest.get("status", "active")),
		str(quest.get("progress", 0)),
		str(quest.get("target", 0))
	]
	message_label.text = "Message: %s" % _last_message

func _refresh_inventory(_inventory: Dictionary) -> void:
	_refresh(GameState.day, GameState.PERIODS[GameState.period_index])

func _refresh_quest(_quest: Dictionary) -> void:
	_refresh(GameState.day, GameState.PERIODS[GameState.period_index])

func _inventory_text(inventory: Dictionary) -> String:
	var parts: Array[String] = []
	for k in inventory.keys():
		parts.append("%s:%s" % [str(k), str(inventory[k])])
	return ", ".join(parts)
