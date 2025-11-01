@tool
extends Node2D

@export var game_config: GameConfig

@export_tool_button("Open User Folder", "Callable") var open_user_folder_action = open_user_folder
@export_tool_button("Remove User Data", "Callable") var remove_user_data_action = remove_user_data

signal paused_toggled(is_paused: bool)

func open_user_folder():
	var user_data_path = ProjectSettings.globalize_path("user://")
	OS.shell_open(user_data_path)

func remove_user_data():
	reset()

func _ready():
	transparent_window()
	set_window_position(get_bottom_right_position())
	call_deferred("_after_ready")
	
func _after_ready():
	if Engine.is_editor_hint():
		return

func reset():
	game_config.reset()

func print_config():
	print("GameConfig: ", game_config.save())

func get_game_config() -> GameConfig:
	return game_config

func pause():
	get_tree().paused = true
	paused_toggled.emit(true)

func toggle_pause():
	get_tree().paused = not get_tree().paused
	paused_toggled.emit(get_tree().paused)

func unpause():
	get_tree().paused = false
	paused_toggled.emit(get_tree().paused)

#Open your project in Godot and go to Project > Project Settings in the top menu.
#Click the Advanced Settings button at the top right of the Project Settings window to reveal all options.
#In the Project Settings window, navigate to Display > Window.
#Set Transparent to Enabled.
#Set Borderless to Enabled.
#Set Always on Top to Enabled.
#Navigate to Display > Window > Per Pixel Transparency.
#Set Allowed to Enabled.
#Navigate to Rendering > Viewport.
#Set Transparent Background to Enabled.
#(Optional) Set a fixed size for your game window under Display > Window > Size by adjusting the Width and Height. 
func transparent_window():
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)

func get_bottom_right_position() -> Vector2:
	var screen_size = DisplayServer.screen_get_size()
	var window_size = get_window().size
	return Vector2(screen_size.x - window_size.x, screen_size.y - window_size.y - 50)

func set_window_position(pos: Vector2):
	# Set the window position.
	DisplayServer.window_set_position(pos)

func snap_to_grid(pos: Vector2) -> Vector2:
	var current_pos = pos
	var snapped_pos = Vector2(
		round(current_pos.x / game_config.grid_size) * game_config.grid_size,
		round(current_pos.y / game_config.grid_size) * game_config.grid_size
	)
	return snapped_pos

func reset_scene():
	get_tree().reload_current_scene()
