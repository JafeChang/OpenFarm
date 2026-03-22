extends RefCounted
class_name SmokeChecks

# Minimal smoke checks for action/observation protocol shape.
# Intended to be run from a headless test harness later.

static func check_action_result_shape(result: Dictionary) -> bool:
	var required := ["success", "error_code", "time_cost", "energy_cost", "emitted_events"]
	for key in required:
		if not result.has(key):
			return false
	return true

static func check_observation_shape(obs: Dictionary) -> bool:
	var required := ["time", "player", "inventory", "nearby_objects", "farm_plots", "current_quest"]
	for key in required:
		if not obs.has(key):
			return false
	return true

static func check_capability_shape(capabilities: Dictionary) -> bool:
	var expected := ["move_to", "interact", "plant", "water", "harvest", "sell", "talk_to", "rest"]
	for key in expected:
		if not capabilities.has(key):
			return false
	return true
