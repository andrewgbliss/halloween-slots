@tool
class_name TileMapLayerAdvanced extends TileMapLayer

enum TerrainType {
	BASE,
  WATER,
  DIRT,
  SAND,
  GRASS,
  PLAINS,
  MOUNTAINS,
  SNOW,
  PLATFORM,
  BACKGROUND
}

@export var generate_on_ready: bool = false
@export var default_terrain_type: TerrainType = TerrainType.GRASS
@export var terrain_name: String = "grass"
@export var generation_width: int = 100
@export var generation_height: int = 100

@export var repeat_on_ready: bool = false
@export var repeat_x: int = 1
@export var repeat_y: int = 1

@export_group("Environmental Noise")
@export var temperature: FastNoiseLite
@export var moisture: FastNoiseLite
@export var altitude: FastNoiseLite

@export_group("Breakable")
@export var is_breakable: bool = false
@export var custom_data_name: String = "hp"

var cell_hp_dict: Dictionary = {}

var cell_temperature_dict: Dictionary = {}
var cell_moisture_dict: Dictionary = {}
var cell_altitude_dict: Dictionary = {}

@export_group("Actions")
@export_tool_button("Generate Noise from Terrain Type", "Callable") var generate_noise_action = generate_noise_from_terrain_type
@export_tool_button("Generate Terrain Now", "Callable") var generate_terrain_action = generate_terrain_now
@export_tool_button("Clear Terrain", "Callable") var clear_terrain_action = clear_terrain
@export_tool_button("Repeat Tiles Now", "Callable") var repeat_tiles_action = repeat_tiles

func generate_noise_from_terrain_type():
	print("Generating noise configuration for terrain type: ", terrain_name)
	
	match default_terrain_type:
		TerrainType.WATER:
			# Water needs low altitude, medium temperature, variable moisture
			temperature = FastNoiseLite.new()
			temperature.noise_type = FastNoiseLite.TYPE_SIMPLEX
			temperature.frequency = 0.02
			temperature.seed = randi()
			
			moisture = FastNoiseLite.new()
			moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX
			moisture.frequency = 0.015
			moisture.seed = randi()
			
			altitude = FastNoiseLite.new()
			altitude.noise_type = FastNoiseLite.TYPE_SIMPLEX
			altitude.frequency = 0.025
			altitude.seed = randi()
			
		TerrainType.SAND:
			# Desert needs low moisture, high temperature, varied altitude
			temperature = FastNoiseLite.new()
			temperature.noise_type = FastNoiseLite.TYPE_SIMPLEX
			temperature.frequency = 0.015
			temperature.seed = randi()
			
			moisture = FastNoiseLite.new()
			moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX
			moisture.frequency = 0.02
			moisture.seed = randi()
			
			altitude = FastNoiseLite.new()
			altitude.noise_type = FastNoiseLite.TYPE_PERLIN
			altitude.frequency = 0.01
			altitude.seed = randi()
			
		TerrainType.GRASS:
			# Grass needs moderate moisture, moderate temperature, low altitude
			temperature = FastNoiseLite.new()
			temperature.noise_type = FastNoiseLite.TYPE_SIMPLEX
			temperature.frequency = 0.02
			temperature.seed = randi()
			
			moisture = FastNoiseLite.new()
			moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX
			moisture.frequency = 0.025
			moisture.seed = randi()
			
			altitude = FastNoiseLite.new()
			altitude.noise_type = FastNoiseLite.TYPE_SIMPLEX
			altitude.frequency = 0.015
			altitude.seed = randi()
			
		TerrainType.PLAINS:
			# Plains need moderate conditions all around
			temperature = FastNoiseLite.new()
			temperature.noise_type = FastNoiseLite.TYPE_SIMPLEX
			temperature.frequency = 0.018
			temperature.seed = randi()
			
			moisture = FastNoiseLite.new()
			moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX
			moisture.frequency = 0.022
			moisture.seed = randi()
			
			altitude = FastNoiseLite.new()
			altitude.noise_type = FastNoiseLite.TYPE_SIMPLEX
			altitude.frequency = 0.012
			altitude.seed = randi()
			
		TerrainType.MOUNTAINS:
			# Mountains need high altitude with dramatic changes
			temperature = FastNoiseLite.new()
			temperature.noise_type = FastNoiseLite.TYPE_SIMPLEX
			temperature.frequency = 0.02
			temperature.seed = randi()
			
			moisture = FastNoiseLite.new()
			moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX
			moisture.frequency = 0.015
			moisture.seed = randi()
			
			altitude = FastNoiseLite.new()
			altitude.noise_type = FastNoiseLite.TYPE_PERLIN
			altitude.frequency = 0.008
			altitude.fractal_octaves = 4
			altitude.seed = randi()
			
		TerrainType.SNOW:
			# Snow needs low temperature, high altitude
			temperature = FastNoiseLite.new()
			temperature.noise_type = FastNoiseLite.TYPE_SIMPLEX
			temperature.frequency = 0.025
			temperature.seed = randi()
			
			moisture = FastNoiseLite.new()
			moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX
			moisture.frequency = 0.02
			moisture.seed = randi()
			
			altitude = FastNoiseLite.new()
			altitude.noise_type = FastNoiseLite.TYPE_PERLIN
			altitude.frequency = 0.01
			altitude.fractal_octaves = 3
			altitude.seed = randi()
			
		TerrainType.DIRT:
			# Ground is a general terrain with balanced settings
			temperature = FastNoiseLite.new()
			temperature.noise_type = FastNoiseLite.TYPE_SIMPLEX
			temperature.frequency = 0.02
			temperature.seed = randi()
			
			moisture = FastNoiseLite.new()
			moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX
			moisture.frequency = 0.02
			moisture.seed = randi()
			
			altitude = FastNoiseLite.new()
			altitude.noise_type = FastNoiseLite.TYPE_SIMPLEX
			altitude.frequency = 0.02
			altitude.seed = randi()
			
		TerrainType.PLATFORM, TerrainType.BACKGROUND:
			# Platform and background use simple noise patterns
			temperature = FastNoiseLite.new()
			temperature.noise_type = FastNoiseLite.TYPE_SIMPLEX
			temperature.frequency = 0.03
			temperature.seed = randi()
			
			moisture = FastNoiseLite.new()
			moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX
			moisture.frequency = 0.03
			moisture.seed = randi()
			
			altitude = FastNoiseLite.new()
			altitude.noise_type = FastNoiseLite.TYPE_SIMPLEX
			altitude.frequency = 0.025
			altitude.seed = randi()
	
	print("Noise configuration generated successfully!")
	print("  Temperature frequency: ", str(temperature.frequency) if temperature else "none")
	print("  Moisture frequency: ", str(moisture.frequency) if moisture else "none")
	print("  Altitude frequency: ", str(altitude.frequency) if altitude else "none")

func reset_seed():
	temperature.seed = randi()
	moisture.seed = randi()
	altitude.seed = randi()

func generate_terrain_now():
	print("Generating terrain in editor...")
	reset_seed()
	clear()
	cell_temperature_dict.clear()
	cell_moisture_dict.clear()
	cell_altitude_dict.clear()
	cell_hp_dict.clear()
	generate_terrain_by_type_auto(generation_width, generation_height, default_terrain_type)

func clear_terrain():
	print("Clearing terrain...")
	clear()
	cell_temperature_dict.clear()
	cell_moisture_dict.clear()
	cell_altitude_dict.clear()
	cell_hp_dict.clear()

# Repeat existing tiles in a grid pattern
func repeat_tiles():
	if repeat_x <= 0 or repeat_y <= 0:
		push_warning("TileMapLayerAdvanced: repeat_x and repeat_y must be greater than 0")
		return
	
	# Get all existing cells and store their data
	var original_cells = get_used_cells()
	
	if original_cells.is_empty():
		push_warning("TileMapLayerAdvanced: No tiles to repeat")
		return
	
	# Store cell data for all original cells
	var cell_data_map: Dictionary = {}
	for cell_coords in original_cells:
		var source_id = get_cell_source_id(cell_coords)
		var atlas_coords = get_cell_atlas_coords(cell_coords)
		var alternative_tile = get_cell_alternative_tile(cell_coords)
		
		cell_data_map[cell_coords] = {
			"source_id": source_id,
			"atlas_coords": atlas_coords,
			"alternative_tile": alternative_tile
		}
	
	# Use generation_width and generation_height for separation
	print("Repeating tiles: using separation ", generation_width, "x", generation_height, " with repeats ", repeat_x, "x", repeat_y)
	
	# Repeat the pattern across the grid
	for repeat_x_idx in range(repeat_x):
		for repeat_y_idx in range(repeat_y):
			# Skip the original (0,0) position
			if repeat_x_idx == 0 and repeat_y_idx == 0:
				continue
			
			# Calculate the offset for this repetition using generation dimensions
			var offset_x = repeat_x_idx * generation_width
			var offset_y = repeat_y_idx * generation_height
			
			# Copy each cell to the new position
			for cell_coords in original_cells:
				var new_coords = Vector2i(
					cell_coords.x + offset_x,
					cell_coords.y + offset_y
				)
				
				var cell_info = cell_data_map[cell_coords]
				set_cell(
					new_coords,
					cell_info["source_id"],
					cell_info["atlas_coords"],
					cell_info["alternative_tile"]
				)
				
				# Copy environmental data if it exists
				if cell_temperature_dict.has(cell_coords):
					cell_temperature_dict[new_coords] = cell_temperature_dict[cell_coords]
				if cell_moisture_dict.has(cell_coords):
					cell_moisture_dict[new_coords] = cell_moisture_dict[cell_coords]
				if cell_altitude_dict.has(cell_coords):
					cell_altitude_dict[new_coords] = cell_altitude_dict[cell_coords]
				if cell_hp_dict.has(cell_coords):
					cell_hp_dict[new_coords] = cell_hp_dict[cell_coords]
	
	print("Tile repetition complete!")

func _ready():
	if generate_on_ready and not Engine.is_editor_hint():
		generate_terrain_by_type_auto(generation_width, generation_height, default_terrain_type)
	
	if repeat_on_ready and not Engine.is_editor_hint():
		repeat_tiles()

func handle_collision(collision: KinematicCollision2D, blast_radius: float):
	if is_breakable:
		var collision_position = collision.get_position()
		var local_position = to_local(collision_position)
		var center_coords = local_to_map(local_position)

		# Calculate how many tiles to check based on blast radius
		var tile_size = tile_set.tile_size
		var radius_in_tiles = ceil(blast_radius / tile_size.x)

		# Check all tiles within the blast radius
		for x in range(-radius_in_tiles, radius_in_tiles + 1):
			for y in range(-radius_in_tiles, radius_in_tiles + 1):
				var check_coords = center_coords + Vector2i(x, y)

				# Check if this tile is within the circular blast radius
				var tile_world_pos = map_to_local(check_coords)
				var distance = collision_position.distance_to(to_global(tile_world_pos))

				if distance <= blast_radius:
					var cell_data = get_cell_tile_data(check_coords)
					if cell_data:
						var default_hp = cell_data.get_custom_data(custom_data_name)

						# If coord doesn't exist in dictionary, initialize with default HP from custom_data
						if not cell_hp_dict.has(check_coords):
							if default_hp:
								cell_hp_dict[check_coords] = default_hp

						# If coord exists in dictionary, decrement HP
						if cell_hp_dict.has(check_coords):
							cell_hp_dict[check_coords] -= 1

						if default_hp:
							if cell_data.material:
								var current_hp = cell_hp_dict[check_coords]
								var break_progress: float = float(current_hp) / float(default_hp)
								apply_break_to_tile(collision_position, cell_data, break_progress)

						if cell_hp_dict[check_coords] <= 0:
							erase_cell(check_coords)
							cell_hp_dict.erase(check_coords)

func apply_break_to_tile(tile_position: Vector2, cell_data, break_progress):
	var viewport_size = get_viewport().get_visible_rect().size
	var tile_size = Vector2(16, 16) # Adjust to your tile size

	# Convert tile position to screen coordinates
	var screen_pos = tile_position # If tile_position is already in screen space

	# Convert to normalized UV (0.0 to 1.0)
	var screen_min = screen_pos / viewport_size
	var screen_max = (screen_pos + tile_size) / viewport_size

	# Apply to the tilemap's material
	cell_data.material.set_shader_parameter("target_screen_min", screen_min)
	cell_data.material.set_shader_parameter("target_screen_max", screen_max)
	cell_data.material.set_shader_parameter("break_progress", break_progress)

# Generate environmental values for a specific cell position
func generate_cell_environment(cell_coords: Vector2i):
	var world_pos = map_to_local(cell_coords)

	# Scale coordinates for better noise patterns
	var scaled_x = world_pos.x * 0.1
	var scaled_y = world_pos.y * 0.1

	cell_temperature_dict[cell_coords] = temperature.get_noise_2d(scaled_x, scaled_y)
	cell_moisture_dict[cell_coords] = moisture.get_noise_2d(scaled_x, scaled_y)
	cell_altitude_dict[cell_coords] = altitude.get_noise_2d(scaled_x, scaled_y)

# Generate environmental values for all cells in use
func generate_all_cell_environments():
	for cell_coords in get_used_cells():
		generate_cell_environment(cell_coords)

# Get temperature value for a cell (-1.0 to 1.0)
func get_cell_temperature(cell_coords: Vector2i) -> float:
	if not cell_temperature_dict.has(cell_coords):
		generate_cell_environment(cell_coords)
	return cell_temperature_dict.get(cell_coords, 0.0)

# Get moisture value for a cell (-1.0 to 1.0)
func get_cell_moisture(cell_coords: Vector2i) -> float:
	if not cell_moisture_dict.has(cell_coords):
		generate_cell_environment(cell_coords)
	return cell_moisture_dict.get(cell_coords, 0.0)

# Get altitude value for a cell (-1.0 to 1.0)
func get_cell_altitude(cell_coords: Vector2i) -> float:
	if not cell_altitude_dict.has(cell_coords):
		generate_cell_environment(cell_coords)
	return cell_altitude_dict.get(cell_coords, 0.0)

# Set environmental values manually for a specific cell
func set_cell_environment(cell_coords: Vector2i, temp: float, moist: float, alt: float):
	cell_temperature_dict[cell_coords] = temp
	cell_moisture_dict[cell_coords] = moist
	cell_altitude_dict[cell_coords] = alt

# Get all environmental values for a cell as a dictionary
func get_cell_environment(cell_coords: Vector2i) -> Dictionary:
	return {
		"temperature": get_cell_temperature(cell_coords),
		"moisture": get_cell_moisture(cell_coords),
		"altitude": get_cell_altitude(cell_coords)
	}

func find_terrain_ids(ter_name: String) -> Dictionary:
	if not tile_set:
		push_error("TileMapLayerAdvanced: No tileset assigned")
		return {"set_id": - 1, "terrain_id": - 1}
	
	# Search through all terrain sets to find matching name
	for terrain_set_id in range(tile_set.get_terrain_sets_count()):
		for terrain_id in range(tile_set.get_terrains_count(terrain_set_id)):
			var found_terrain_name = tile_set.get_terrain_name(terrain_set_id, terrain_id)
			
			# Match terrain names (case insensitive)
			if found_terrain_name.to_lower().contains(ter_name.to_lower()):
				return {"set_id": terrain_set_id, "terrain_id": terrain_id}
	
	push_warning("TileMapLayerAdvanced: Could not find terrain named '%s' in tileset" % ter_name)
	return {"set_id": - 1, "terrain_id": - 1}

# Get the condition function for a specific terrain type
func get_terrain_condition(terrain_type: TerrainType) -> Callable:
	match terrain_type:
		TerrainType.BASE:
			return func(_temp, _moist, _alt): return true
		TerrainType.WATER:
			return func(_temp, _moist, alt): return alt < -0.3
		TerrainType.DIRT:
			return func(_temp, _moist, alt): return alt > 0.3 and alt < 0.3
		TerrainType.SAND:
			return func(temp, moist, alt): return moist < -0.3 and temp > 0.3 and alt >= -0.3 and alt <= 0.6
		TerrainType.GRASS:
			return func(temp, moist, alt): return moist > 0.3 and temp > 0.1 and alt >= -0.3 and alt <= 0.6
		TerrainType.PLAINS:
			return func(temp, moist, alt): return moist > 0.1 and temp > -0.2 and alt >= -0.3 and alt <= 0.6
		TerrainType.MOUNTAINS:
			return func(_temp, _moist, alt): return alt > 0.3
		TerrainType.SNOW:
			return func(temp, _moist, alt): return alt > 0.6 and temp < -0.2
		TerrainType.PLATFORM:
			return func(_temp, _moist, alt): return alt > 0.3
		TerrainType.BACKGROUND:
			return func(_temp, _moist, _alt): return true
		_:
			return func(_temp, _moist, _alt): return false

# Generate terrain for the entire region without noise
func generate_terrain(width: int, height: int, terrain_set_id: int, terrain_id: int):
	var positions: Array[Vector2i] = []
	
	for x in range(width):
		for y in range(height):
			var cell_coords = Vector2i(x, y)
			positions.append(cell_coords)
	
	# Place terrain tiles
	if positions.size() > 0:
		set_cells_terrain_connect(positions, terrain_set_id, terrain_id, false)

# Generate terrain for a region based on environmental conditions
# Similar to WorldGenerator's logic
func generate_terrain_from_environment(width: int, height: int, terrain_set_id: int, terrain_id: int, condition_func: Callable):
	var positions: Array[Vector2i] = []

	for x in range(width):
		for y in range(height):
			var cell_coords = Vector2i(x, y)

			# Generate environmental values
			generate_cell_environment(cell_coords)

			var temp = get_cell_temperature(cell_coords)
			var moist = get_cell_moisture(cell_coords)
			var alt = get_cell_altitude(cell_coords)

			# Use the condition function to determine if this cell should get terrain
			if condition_func.call(temp, moist, alt):
				positions.append(cell_coords)

	# Place terrain tiles
	if positions.size() > 0:
		set_cells_terrain_connect(positions, terrain_set_id, terrain_id, false)

# Convenience function to generate terrain using TerrainType enum
func generate_terrain_by_type(width: int, height: int, terrain_set_id: int, terrain_id: int, terrain_type: TerrainType):
	if temperature != null and moisture != null and altitude != null:
		print("Generating terrain from environment noise")
		var condition = get_terrain_condition(terrain_type)
		print("Condition: ", condition)
		generate_terrain_from_environment(width, height, terrain_set_id, terrain_id, condition)
	else:
		print("Generating terrain without environment noise")
		generate_terrain(width, height, terrain_set_id, terrain_id)

# Automatically find terrain IDs and generate terrain
func generate_terrain_by_type_auto(width: int, height: int, terrain_type: TerrainType):
	var terrain_info = find_terrain_ids(terrain_name)
		
	if terrain_info["set_id"] == -1 or terrain_info["terrain_id"] == -1:
		push_error("TileMapLayerAdvanced: Failed to find terrain IDs for '%s'" % terrain_name)
		return
	
	generate_terrain_by_type(width, height, terrain_info["set_id"], terrain_info["terrain_id"], terrain_type)
