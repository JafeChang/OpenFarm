extends Node
class_name ItemDatabase

const ITEM_RULES := {
	"parsnip_seed": {
		"type": "seed",
		"crop_id": "parsnip",
		"sell_price": 8
	},
	"parsnip": {
		"type": "crop",
		"sell_price": 35
	},
	"watering_can": {
		"type": "tool",
		"sell_price": 0
	}
}

func get_sell_price(item_id: String) -> int:
	if not ITEM_RULES.has(item_id):
		return 0
	return int((ITEM_RULES[item_id] as Dictionary).get("sell_price", 0))

func crop_from_seed(seed_id: String) -> String:
	if not ITEM_RULES.has(seed_id):
		if seed_id.ends_with("_seed"):
			return seed_id.trim_suffix("_seed")
		return "crop"
	return str((ITEM_RULES[seed_id] as Dictionary).get("crop_id", "crop"))

func get_sellable_items() -> Array[String]:
	var out: Array[String] = []
	for item_id in ITEM_RULES.keys():
		var price := get_sell_price(item_id)
		if price > 0:
			out.append(item_id)
	return out
