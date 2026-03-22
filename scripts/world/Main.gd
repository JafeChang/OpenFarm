extends Node2D

@onready var agent_adapter: AgentAdapter = $AgentAdapter
@onready var farm_system: FarmSystem = $FarmSystem
var _demo_agent := DemoAgent.new()

func get_agent_observation() -> Dictionary:
	return agent_adapter.get_observation()

func run_demo_agent_step(action_name: String, params: Dictionary = {}) -> Dictionary:
	return agent_adapter.submit_action(action_name, params)

func run_demo_agent_loop_step() -> Dictionary:
	var obs := get_agent_observation()
	var decision := _demo_agent.choose_action(obs)
	var action_name := String(decision.get("name", ""))
	var params: Dictionary = decision.get("params", {})
	var result := run_demo_agent_step(action_name, params)
	return {
		"observation": obs,
		"decision": decision,
		"result": result
	}

func get_farm_plots() -> Array:
	if farm_system == null:
		return []
	return farm_system.get_all_plots()
