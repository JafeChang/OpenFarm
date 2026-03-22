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

var quests: Array = [
	{
		"id": "harvest_training",
		"title": "Harvest 3 Parsnip",
		"type": "harvest",
		"status": "active",
		"progress": 0,
		"target": 3,
		"reward_gold": 120,
		"reward_claimed": false
	},
	{
		"id": "shipping_training",
		"title": "Sell 2 Parsnip",
		"type": "sell",
		"target_item": "parsnip",
		"status": "locked",
		"progress": 0,
		"target": 2,
		"reward_gold": 180,
		"reward_claimed": false
	}
]
var current_quest_index: int = 0

func _ready() -> void:
	_sync_active_quest_state()

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

func sleep_until_morning() -> Dictionary:
	day += 1
	period_index = 0
	energy = 100
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
	if current_quest_index < 0 or current_quest_index >= quests.size():
		return {
			"id": "all_done",
			"title": "All quests completed",
			"status": "done",
			"progress": 0,
			"target": 0,
			"reward_claimed": true
		}
	return (quests[current_quest_index] as Dictionary).duplicate(true)

func record_harvest(count: int = 1) -> Dictionary:
	harvested_count += count
	return _advance_current_quest("harvest", count, "")

func record_sell(item_id: String, qty: int) -> Dictionary:
	return _advance_current_quest("sell", qty, item_id)

func claim_quest_reward() -> Dictionary:
	if current_quest_index < 0 or current_quest_index >= quests.size():
		return {"ok": false, "error_code": "no_active_quest", "reward_gold": 0}

	var quest: Dictionary = quests[current_quest_index]
	if str(quest.get("status", "active")) != "completed":
		return {
			"ok": false,
			"error_code": "quest_not_completed",
			"reward_gold": 0
		}
	if bool(quest.get("reward_claimed", false)):
		return {
			"ok": false,
			"error_code": "reward_already_claimed",
			"reward_gold": 0
		}

	var reward := int(quest.get("reward_gold", 0))
	adjust_gold(reward)
	quest["reward_claimed"] = true
	quest["status"] = "rewarded"
	quests[current_quest_index] = quest

	if current_quest_index + 1 < quests.size():
		current_quest_index += 1
		_sync_active_quest_state()

	quest_updated.emit(get_quest_data())
	return {"ok": true, "error_code": "", "reward_gold": reward}

func get_quest_status_text() -> String:
	var quest := get_quest_data()
	var status := str(quest.get("status", "active"))
	if status == "active":
		return "Quest: %s (%s/%s)" % [
			str(quest.get("title", "-")),
			str(quest.get("progress", 0)),
			str(quest.get("target", 0))
		]
	if status == "completed":
		return "Quest complete! Talk to NPC_Alice to claim reward."
	if status == "rewarded":
		return "Quest reward claimed. Next quest unlocked."
	if status == "done":
		return "All quests completed."
	return "Quest status: %s" % status

func get_next_quest_preview() -> String:
	if current_quest_index + 1 >= quests.size():
		return "No next quest."
	var next_quest: Dictionary = quests[current_quest_index + 1]
	return "Next: %s" % str(next_quest.get("title", "-"))

func to_dict() -> Dictionary:
	return {
		"day": day,
		"period_index": period_index,
		"energy": energy,
		"gold": gold,
		"harvested_count": harvested_count,
		"inventory": inventory.duplicate(true),
		"quests": quests.duplicate(true),
		"current_quest_index": current_quest_index
	}

func from_dict(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	period_index = clamp(int(data.get("period_index", 0)), 0, PERIODS.size() - 1)
	energy = int(data.get("energy", 100))
	gold = int(data.get("gold", 200))
	harvested_count = int(data.get("harvested_count", 0))
	inventory = (data.get("inventory", {}) as Dictionary).duplicate(true)
	quests = (data.get("quests", quests) as Array).duplicate(true)
	current_quest_index = int(data.get("current_quest_index", 0))
	_sync_active_quest_state()
	inventory_changed.emit(inventory.duplicate(true))
	quest_updated.emit(get_quest_data())
	time_changed.emit(day, PERIODS[period_index])

func _advance_current_quest(quest_type: String, delta: int, item_id: String) -> Dictionary:
	if current_quest_index < 0 or current_quest_index >= quests.size():
		return get_quest_data()

	var quest: Dictionary = quests[current_quest_index]
	if str(quest.get("status", "active")) != "active":
		quest_updated.emit(quest.duplicate(true))
		return quest.duplicate(true)

	if str(quest.get("type", "")) != quest_type:
		quest_updated.emit(quest.duplicate(true))
		return quest.duplicate(true)

	if quest_type == "sell":
		var target_item := str(quest.get("target_item", ""))
		if not target_item.is_empty() and target_item != item_id:
			quest_updated.emit(quest.duplicate(true))
			return quest.duplicate(true)

	quest["progress"] = int(quest.get("progress", 0)) + delta
	if int(quest.get("progress", 0)) >= int(quest.get("target", 1)):
		quest["status"] = "completed"
	quests[current_quest_index] = quest
	quest_updated.emit(quest.duplicate(true))
	return quest.duplicate(true)

func _sync_active_quest_state() -> void:
	for i in range(quests.size()):
		var q: Dictionary = quests[i]
		var status := str(q.get("status", "locked"))
		if i < current_quest_index and status == "locked":
			q["status"] = "rewarded"
		elif i == current_quest_index and status == "locked":
			q["status"] = "active"
		quests[i] = q
