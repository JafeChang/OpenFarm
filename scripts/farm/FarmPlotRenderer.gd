extends Node2D
class_name FarmPlotRenderer

@export var farm_system_path: NodePath
@export var markers_path: NodePath
@export var tile_size: Vector2 = Vector2(26, 26)

@onready var _farm_system: FarmSystem = get_node_or_null(farm_system_path)
@onready var _markers: Node2D = get_node_or_null(markers_path)

var _state_colors := {
	"empty": Color(0.42, 0.27, 0.16, 0.9),
	"planted": Color(0.35, 0.66, 0.27, 0.9),
	"watered": Color(0.24, 0.52, 0.86, 0.9),
	"mature": Color(0.95, 0.82, 0.28, 0.95)
}
var _tile_views: Dictionary = {}

func _ready() -> void:
	if _farm_system != null:
		_farm_system.farm_plot_changed.connect(_on_farm_plot_changed)
	_build_views()
	_refresh_all()

func _build_views() -> void:
	if _markers == null:
		return
	for marker in _markers.get_children():
		if not (marker is Node2D):
			continue
		var marker_node := marker as Node2D
		var tile := Vector2i.ZERO
		if _farm_system != null:
			tile = _farm_system.get_nearest_tile(marker_node.global_position)

		var rect := ColorRect.new()
		rect.name = "PlotVisual"
		rect.color = _state_colors["empty"]
		rect.offset_left = -tile_size.x * 0.5
		rect.offset_top = -tile_size.y * 0.5
		rect.offset_right = tile_size.x * 0.5
		rect.offset_bottom = tile_size.y * 0.5
		marker_node.add_child(rect)

		_tile_views[tile] = rect

func _refresh_all() -> void:
	if _farm_system == null:
		return
	for plot in _farm_system.get_all_plots():
		if plot is Dictionary:
			_on_farm_plot_changed(plot)

func _on_farm_plot_changed(plot: Dictionary) -> void:
	var tile: Vector2i = plot.get("tile", Vector2i.ZERO)
	if not _tile_views.has(tile):
		return
	var rect: ColorRect = _tile_views[tile]
	var state := str(plot.get("state", "empty"))
	rect.color = _state_colors.get(state, _state_colors["empty"])
