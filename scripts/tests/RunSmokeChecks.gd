extends SceneTree

func _init() -> void:
	var checks := {
		"action_result_shape": SmokeChecks.check_action_result_shape(_sample_action_result()),
		"observation_shape": SmokeChecks.check_observation_shape(_sample_observation()),
		"capability_shape": SmokeChecks.check_capability_shape(_sample_capabilities())
	}

	var failed: Array[String] = []
	for key in checks.keys():
		if not bool(checks[key]):
			failed.append(String(key))

	if failed.is_empty():
		print("Smoke checks passed: ", checks)
		quit(0)
		return

	push_error("Smoke checks failed: %s" % ", ".join(failed))
	quit(1)

func _sample_action_result() -> Dictionary:
	return {
		"success": true,
		"error_code": "",
		"time_cost": 1.0,
		"energy_cost": 0.0,
		"emitted_events": []
	}

func _sample_observation() -> Dictionary:
	return {
		"time": {
			"day": 1,
			"period": "Morning"
		},
		"player": {
			"position": {
				"x": 0.0,
				"y": 0.0
			},
			"energy": 10,
			"gold": 0
		},
		"inventory": {},
		"nearby_objects": [],
		"farm_plots": [],
		"current_quest": {}
	}

func _sample_capabilities() -> Dictionary:
	return {
		"move_to": true,
		"interact": true,
		"plant": true,
		"water": true,
		"harvest": true,
		"sell": true,
		"talk_to": true,
		"rest": true
	}
