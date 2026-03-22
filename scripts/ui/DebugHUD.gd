extends CanvasLayer
class_name DebugHUD

@onready var info_label: Label = $InfoLabel
@onready var world: Node = get_parent()
@onready var action_dispatcher: ActionDispatcher = world.get_node_or_null("ActionDispatcher")

var _last_action: String = "-"
var _last_result: String = "-"

func _ready() -> void:
	if action_dispatcher != null:
		action_dispatcher.action_finished.connect(_on_action_finished)
	GameState.time_changed.connect(_refresh)
	GameState.inventory_changed.connect(_refresh_inventory)
	GameState.quest_updated.connect(_refresh_quest)
	_refresh(1, "morning")

func _process(_delta: float) -> void:
	_refresh(GameState.day, GameState.PERIODS[GameState.period_index])

func _on_action_finished(action_name: String, result: Dictionary) -> void:
	_last_action = action_name
	_last_result = "ok=%s err=%s" % [str(result.get("success", false)), str(result.get("error_code", ""))]

func _refresh(_day: int, _period: String) -> void:
	if info_label == null:
		return
	var inv := _inventory_text(GameState.inventory)
	var quest := GameState.get_quest_data()
	var quest_text := "%s (%s/%s)" % [
		str(quest.get("title", "-")),
		str(quest.get("progress", 0)),
		str(quest.get("target", 0))
	]
	info_label.text = "OpenFarm Debug HUD\nDay %d - %s\nEnergy: %d  Gold: %d\nInventory: %s\nQuest: %s\nLast Action: %s\nLast Result: %s\nHotkeys: 1 Plant | 2 Water | 3 Harvest | 4 Sell | 5 Talk | E Interact (NPC/Bin/MapExit)" % [
		GameState.day,
		GameState.PERIODS[GameState.period_index],
		GameState.energy,
		GameState.gold,
		inv,
		quest_text,
		_last_action,
		_last_result
	]

func _refresh_inventory(_inventory: Dictionary) -> void:
	_refresh(GameState.day, GameState.PERIODS[GameState.period_index])

func _refresh_quest(_quest: Dictionary) -> void:
	_refresh(GameState.day, GameState.PERIODS[GameState.period_index])

func _inventory_text(inventory: Dictionary) -> String:
	var parts: Array[String] = []
	for key in inventory.keys():
		parts.append("%s:%s" % [str(key), str(inventory[key])])
	return ", ".join(parts)
