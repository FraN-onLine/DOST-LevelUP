extends Node2D

@export var zoom_speed := 0.1
@export var min_zoom := 0.5
@export var max_zoom := 2.0
@export var drag_speed := 1.0

# Smooth zoom options
@export var smooth_zoom := true
@export var zoom_lerp_speed := 8.0

# Optional pan limits
@export var limit_panning := true
@export var pan_limits := Rect2( -10000, -10000, 20000, 20000)

var dragging := false
var drag_delta := Vector2.ZERO
var target_zoom := 1.0

@onready var camera := get_node_or_null("Camera2D") as Camera2D

func _ready() -> void:
	if camera == null:
		push_error("camera_manager.gd: Camera2D node not found as child. Make sure a Camera2D named 'Camera2D' is a child of this node.")
		return
	target_zoom = camera.zoom.x

func _input(event: InputEvent) -> void:
	if camera == null:
		return

	if event is InputEventMouseMotion and dragging:
		# scale drag by zoom so pan speed feels consistent across zoom levels
		drag_delta = event.relative * drag_speed * camera.zoom.x
		camera.position -= drag_delta
		_apply_pan_limits()

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = true
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# zoom in (smaller zoom scalar)
			_update_target_zoom(target_zoom - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# zoom out (larger zoom scalar)
			_update_target_zoom(target_zoom + zoom_speed)

# Catch releases that might be consumed elsewhere
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			dragging = false

func _process(delta: float) -> void:
	if camera == null:
		return
	# Safety: if release wasn't received, sync dragging with actual mouse state
	if dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		dragging = false
	if smooth_zoom:
		var t: float = clamp(zoom_lerp_speed * delta, 0.0, 1.0)
		camera.zoom = camera.zoom.lerp(Vector2.ONE * target_zoom, clamp(zoom_lerp_speed * delta, 0.0, 1.0))
	else:
		camera.zoom = Vector2.ONE * target_zoom
	# Re-apply pan limits after zoom changes so viewport stays inside bounds
	_apply_pan_limits()

func _update_target_zoom(new_zoom: float) -> void:
	# compute dynamic allowed upper zoom based on pan_limits and viewport so we don't zoom out past border
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if limit_panning and viewport_size.x > 0 and viewport_size.y > 0:
		var max_x: float = pan_limits.size.x / viewport_size.x
		var max_y: float = pan_limits.size.y / viewport_size.y
		var dynamic_max: float = min(max_x, max_y)
		# final upper bound is the smaller of user max_zoom and dynamic_max
		var final_upper: float = min(max_zoom, dynamic_max)
		# ensure lower bound does not exceed final_upper; if min_zoom > final_upper we allow only final_upper
		var final_lower: float = min(min_zoom, final_upper)
		target_zoom = clamp(new_zoom, final_lower, final_upper)
	else:
		target_zoom = clamp(new_zoom, min_zoom, max_zoom)

func _apply_pan_limits() -> void:
	if not limit_panning or camera == null:
		return
	# Size of the viewport (screen) in pixels
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return

	# Half size of the visible area in world coordinates (account for zoom)
	var half_view: Vector2 = (viewport_size * 0.5) * camera.zoom

	# World bounds (pan_limits) min and max center positions that keep the viewport inside the world
	var world_min_center: Vector2 = pan_limits.position + half_view
	var world_max_center: Vector2 = pan_limits.position + pan_limits.size - half_view

	# If world is smaller than viewport in any axis, center the camera on that axis
	if pan_limits.size.x <= half_view.x * 2.0:
		camera.position.x = pan_limits.position.x + pan_limits.size.x * 0.5
	else:
		camera.position.x = clamp(camera.position.x, world_min_center.x, world_max_center.x)

	if pan_limits.size.y <= half_view.y * 2.0:
		camera.position.y = pan_limits.position.y + pan_limits.size.y * 0.5
	else:
		camera.position.y = clamp(camera.position.y, world_min_center.y, world_max_center.y)
