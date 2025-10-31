class_name SlotMachineSlot extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

signal spin_complete()

var is_spinning: bool = false
var target_symbol: int = 0
var current_offset: float = 0.0
var total_symbols = 12

func spin(target: int = -1, start_delay: float = 0.0, duration: float = 5.0, min_spins: int = 25) -> void:
	if is_spinning:
		return
	
	is_spinning = true
	
	# Determine target symbol
	if target < 0:
		target_symbol = randi() % total_symbols
	else:
		target_symbol = target % total_symbols
	
	# Calculate total distance to travel
	# We want to spin at least min_spins full rotations, then land on target
	var base_distance = float(min_spins * total_symbols)
	var final_distance = base_distance + float(target_symbol)
	
	# Adjust for current position
	var start_offset = current_offset
	var total_distance = final_distance + (float(total_symbols) - fmod(start_offset, float(total_symbols)))
	
	# Create the animation
	var tween = create_tween()
	
	# Add start delay if specified
	if start_delay > 0.0:
		tween.tween_interval(start_delay)
	
	# Set easing for smooth acceleration and deceleration
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Spin to target
	tween.tween_method(set_scroll_offset, start_offset, start_offset + total_distance, duration)
	tween.tween_callback(_on_spin_complete)

func set_scroll_offset(value: float) -> void:
	current_offset = value
	if sprite.material:
		sprite.material.set_shader_parameter("scroll_offset", value)

func _on_spin_complete() -> void:
	is_spinning = false
	spin_complete.emit()
