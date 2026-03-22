extends RefCounted
class_name ActionSchema

const ACTION_SCHEMAS := {
	"move_to": {
		"optional": ["target", "direction", "delta", "speed"]
	},
	"interact": {
		"required": ["target_id"]
	},
	"plant": {
		"required": ["seed_id", "tile"]
	},
	"water": {
		"required": ["tile"]
	},
	"harvest": {
		"required": ["tile"]
	},
	"sell": {
		"required": ["item_id", "qty"]
	},
	"talk_to": {
		"required": ["npc_id"]
	}
}

static func validate(action_name: String, params: Dictionary) -> Dictionary:
	if not ACTION_SCHEMAS.has(action_name):
		return {
			"ok": false,
			"error_code": "unknown_action"
		}

	var schema: Dictionary = ACTION_SCHEMAS[action_name]
	var required_fields: Array = schema.get("required", [])
	for field in required_fields:
		if not params.has(field):
			return {
				"ok": false,
				"error_code": "missing_param_%s" % String(field)
			}

	if action_name == "move_to":
		var has_target := params.has("target")
		var has_direction := params.has("direction")
		if not has_target and not has_direction:
			return {
				"ok": false,
				"error_code": "move_requires_target_or_direction"
			}

	return {"ok": true, "error_code": ""}
