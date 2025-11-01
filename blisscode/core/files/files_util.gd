class_name FilesUtil extends Node

static func create_dir(path: String):
	return DirAccess.make_dir_recursive_absolute(path)

static func save(path: String, data):
	var file = FileAccess.open(path, FileAccess.WRITE)
	var json_string = JSON.stringify(data)
	file.store_string(json_string)
	file.close()

static func restore(path: String):
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json_string = file.get_as_text()
		var parse_res = JSON.parse_string(json_string)
		if parse_res:
			return parse_res
		else:
			print("Failed to parse data", path)
		file.close()
	else:
		print("Failed to load data", path)
	return null

static func restore_or_create(path: String, data):
	if not FileAccess.file_exists(path):
		create_blank_file(path, data)
	return restore(path)

static func create_blank_file(path: String, data):
	var file = FileAccess.open(path, FileAccess.WRITE)
	var json_string = JSON.stringify(data)
	file.store_string(json_string)
	file.close()

static func verify_save_dir(path):
	if not DirAccess.dir_exists_absolute(path):
		var err = DirAccess.make_dir_absolute(path)
		if err != OK:
			print("Could not create dir", err, path)
			return

static func get_json_from_file(path: String):
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		var parse_res = JSON.parse_string(json_string)
		return parse_res
	else:
		return null

static func remove_file(path: String):
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

static func remove_dir(path: String):
	if not DirAccess.dir_exists_absolute(path):
		return
	
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = path + "/" + file_name
			if dir.current_is_dir():
				# Recursively remove subdirectories
				remove_dir(full_path)
			else:
				# Remove files
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	# Remove the now-empty directory
	DirAccess.remove_absolute(path)

static func find_files(path: String, file_ext: String = "", base_path: String = "") -> Array:
	var all_files = []
	var dir = DirAccess.open(path)
	
	# Set base_path on first call to remove it from relative paths
	if base_path == "":
		base_path = path
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = path + "/" + file_name
			if dir.current_is_dir():
				# Skip hidden directories and system directories
				if not file_name.begins_with("."):
					# Recursively search subdirectories
					all_files.append_array(find_files(full_path, file_ext, base_path))
			else:
				# Check if file matches the extension filter (if provided)
				if file_ext == "" or file_name.ends_with("." + file_ext):
					# Create relative path from base_path
					var relative_path = full_path.replace(base_path + "/", "")
					var path_parts = relative_path.split("/")
					var filename = path_parts[-1] # Last element is the filename
					var dir_path = path_parts.slice(0, -1) # All but last element are directories
					
					all_files.append({
						"path": dir_path,
						"filename": filename,
						"full_path": full_path
					})
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("An error occurred when trying to access the path: " + path)
	return all_files
