extends Node
class_name GameState

signal time_changed(day: int, period: String)
signal inventory_changed(inventory: Dictionary)
signal quest_updated(quest: Dictionary)

const PERIODS := ["morning", "afternoon", "evening", "night"]

var day: int = 1
var period_index: int = 0
var energy: int = 100
var gold: int = 200
var harvested_count: int = 0
var inventory := {
	"parsnip_seed": 5,
	"parsnip": 0,
	"watering_can": 1
}
var active_quest := {
	"id": "first_harvest",
	"title": "Harvest 3 Parsnip",
	"status": "active",
	"progress": 0,
	"target": 3
}

func get_time_data() -> Dictionary:
	return {
		"day": day,
		"period": PERIODS[period_index]
	}

func advance_time(step: int = 1) -> Dictionary:
	period_index += step
	while period_index >= PERIODS.size():
		period_index -= PERIODS.size()
		day += 1
	var time_data := get_time_data()
	time_changed.emit(int(time_data["day"]), str(time_data["period"]))
	return time_data

func adjust_energy(delta: int) -> int:
	energy = max(0, energy + delta)
	return energy

func adjust_gold(delta: int) -> int:
	gold = max(0, gold + delta)
	return gold

func has_item(item_id: String, qty: int) -> bool:
	return int(inventory.get(item_id, 0)) >= qty

func add_item(item_id: String, qty: int) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) + qty
	inventory_changed.emit(inventory.duplicate(true))

func remove_item(item_id: String, qty: int) -> bool:
	if not has_item(item_id, qty):
		return false
	inventory[item_id] = int(inventory.get(item_id, 0)) - qty
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	inventory_changed.emit(inventory.duplicate(true))
	return true

func get_quest_data() -> Dictionary:
	return active_quest.duplicate(true)

func bump_quest_progress(delta: int = 1) -> Dictionary:
	active_quest["progress"] = int(active_quest.get("progress", 0)) + delta
	harvested_count += delta
	if int(active_quest.get("progress", 0)) >= int(active_quest.get("target", 1)):
		active_quest["status"] = "completed"
	quest_updated.emit(active_quest.duplicate(true))
	return active_quest.duplicate(true)
