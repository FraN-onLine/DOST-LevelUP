extends PanelContainer

var opacity_tween: Tween = null
var mouse_offset = Vector2(10, 10)  # Offset from cursor position

func _ready() -> void:
	# Start hidden
	modulate.a = 0.0
	hide()

func _process(_delta: float) -> void:
	if visible:
		# Update position every frame while visible
		global_position = get_viewport().get_mouse_position() + mouse_offset

func toggle(on: bool) -> void:
	if opacity_tween and opacity_tween.is_valid():
		opacity_tween.kill()
	
	if on:
		# Show immediately then fade in
		show()
		modulate.a = 0.0
		global_position = get_viewport().get_mouse_position() + mouse_offset
		tween_opacity(1.0)
	else:
		# Fade out then hide
		tween_opacity(0.0)
		await get_tree().create_timer(0.3).timeout
		hide()

func tween_opacity(to: float) -> Tween:
	opacity_tween = create_tween()
	opacity_tween.tween_property(self, "modulate:a", to, 0.3)
	return opacity_tween
