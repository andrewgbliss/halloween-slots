class_name TitleControl extends Control

var dragging = false
var drag_offset = Vector2.ZERO

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Calculate the offset between mouse screen position and window position
				var screen_mouse_pos = DisplayServer.mouse_get_position()
				var window_position = DisplayServer.window_get_position()
				drag_offset = screen_mouse_pos - window_position
				dragging = true
			else:
				dragging = false

func _process(_delta: float) -> void:
	if dragging:
		# Use screen mouse position to avoid feedback loop
		var screen_mouse_pos = DisplayServer.mouse_get_position()
		var new_position = screen_mouse_pos - drag_offset
		GameManager.set_window_position(new_position)
