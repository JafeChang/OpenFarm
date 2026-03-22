extends Node
class_name ReplayLogger

const SCHEMA_VERSION := 1

@export var adapter_path: NodePath
@export var replay_path: String = "user://openfarm_replay.jsonl"

var _session_id: String = ""
var _buffer: Array = []
var _seq: int = 0

func _ready() -> void:
	_session_id = _make_session_id()
	var adapter := get_node_or_null(adapter_path)
	if adapter != null and adapter is AgentAdapter:
		(adapter as AgentAdapter).event_emitted.connect(_on_event_emitted)

func _on_event_emitted(event_name: String, payload: Dictionary) -> void:
	_seq += 1
	var scene_path := ""
	if get_tree().current_scene != null:
		scene_path = str(get_tree().current_scene.scene_file_path)
	var entry := {
		"schema_version": SCHEMA_VERSION,
		"session_id": _session_id,
		"seq": _seq,
		"event_name": event_name,
		"payload": payload,
		"meta": {
			"scene_path": scene_path,
			"day": GameState.day,
			"period": GameState.PERIODS[GameState.period_index],
			"unix_time": Time.get_unix_time_from_system()
		}
	}
	_buffer.append(entry)
	_append_jsonl(entry)

func get_recent_events(limit: int = 20) -> Array:
	if limit <= 0:
		return []
	var size := _buffer.size()
	if size <= limit:
		return _buffer.duplicate(true)
	return _buffer.slice(size - limit, size).duplicate(true)

func _append_jsonl(entry: Dictionary) -> void:
	var file := FileAccess.open(replay_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(replay_path, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(JSON.stringify(entry))
	file.close()

func _make_session_id() -> String:
	return "%s_%s" % [str(Time.get_unix_time_from_system()), str(randi() % 1000000)]
