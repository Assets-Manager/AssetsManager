extends Node

const IMPORTERS_PATH = "res://FormatImporters/"
const BROKEN_IMAGE = preload("res://Assets/Material Icons/hide_image.svg")

signal new_asset_added(id, name, thumbnail)
signal update_total_import_assets(count)
signal increase_import_counter()

var _AssetsPath : String = ""
var _QueueLock : Mutex = Mutex.new()
var _Thread : Thread = null
var _FileQueue : Array = []
var _TotalFilecount : int = 0
var _QuitThread : bool = false
var _Directory : Directory = Directory.new()
var _Importers : Dictionary = {}

var current_directory : int = 0
onready var _DirWatcher : DirectoryWatcher = DirectoryWatcher.new()

func _ready() -> void:
	add_child(_DirWatcher)
	_DirWatcher.connect("new_asset", self, "_add_or_update_asset")
	_DirWatcher.connect("changed_asset", self, "_add_or_update_asset")
	_DirWatcher.connect("deleted_asset", self, "_deleted_asset")
	_DirWatcher.connect("renamed_asset", self, "_renamed_asset")

# Joins the running thread.
func _exit_tree() -> void:
	_QuitThread = true
	if _Thread:
		_Thread.wait_to_finish()
		
# Loads all importers.
# Allows in the future to add more importers easily.
# Also allows to create some sort of plugin system, so users can write their own
# importers without to recompile the whole project.
func _load_importers() -> void:
	_Importers.clear()
	for child in get_children():
		if !(child is DirectoryWatcher):
			child.queue_free()
	
	var supported_extensions : Array
	var dir := Directory.new()
	if dir.open(IMPORTERS_PATH) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() && !("IFormat" in file_name):
				var script = load(IMPORTERS_PATH + file_name.trim_suffix('.remap'))
				if !script.get_type().empty():
					var id : int = AssetsDatabase.get_or_add_asset_type(script.get_type())
					if id != 0:
						var importer : IFormatImporter = script.new()
						supported_extensions.append_array(importer.get_extensions())
						importer.register(self, id)
						_Importers[script.get_type()] = importer
						
			file_name = dir.get_next()
			
	_DirWatcher.supported_extensions = supported_extensions
# ---------------------------------------------
# 					Helpers
# ---------------------------------------------
	
# Returns the currently opened asset path
func get_assets_path() -> String:
	return _AssetsPath
	
# Builds the absolute path to the asset library
func build_assets_path(subpath : String) -> String:
	return _AssetsPath + "/" + subpath
	
# Returns the path to the thumbnails directory.
func get_thumbnail_path() -> String:
	return _AssetsPath + "/thumbnails"
	
func get_directory_id(parentId : int, name : String) -> int:
	return AssetsDatabase.get_directory_id(parentId, name)
	
# Opens a given assets library
# Returns true on success
func open(path : String) -> bool:
	_AssetsPath = path
	
	if _AssetsPath[_AssetsPath.length() - 1] == "/":
		_AssetsPath.erase(_AssetsPath.length() - 1, 1)
	
	if AssetsDatabase.open(_AssetsPath + "/assets.db"):
		current_directory = 0
		
		# Creates the thumbnail directory.
		if !_Directory.dir_exists(get_thumbnail_path()):
			_Directory.make_dir(get_thumbnail_path())
			
		_load_importers()
		_DirWatcher.open(_AssetsPath.replace("\\", "/"))
		
		ProgramManager.settings.last_opened = _AssetsPath
		get_tree().connect("files_dropped", self, "_files_dropped")
		return true
		
	return false

func close() -> void:
	AssetsDatabase.close()
	get_tree().disconnect("files_dropped", self, "_files_dropped")

# Returns a list of all directories. Ordered by the parents.
func get_all_directories() -> Array:
	return AssetsDatabase.get_all_directories()
	
# Tries to load the thumbnail of an asset.
# If there is no thumbnail or the image couldn't be loaded, a placeholder one is returned.
func _load_thumbnail(asset : Dictionary) -> Texture:
	if asset.has("thumbnail"):
		if !(asset["thumbnail"] is Texture):
			var thumbnailpath = ""
			if asset["thumbnail"]:
				thumbnailpath = get_thumbnail_path() + "/" + asset["thumbnail"]
			else:	# For images, because they are already images.
				thumbnailpath = build_assets_path(asset["name"].get_file())
			
			var texture : Texture = null
			if _Directory.file_exists(thumbnailpath):
				var img := Image.new()
				if img.load(thumbnailpath) == OK:
					texture = ImageTexture.new()
					texture.create_from_image(img, 0)
			
			if texture:
				return texture
		else:
			return asset["thumbnail"]
	return BROKEN_IMAGE

# ---------------------------------------------
# 					Export
# ---------------------------------------------

# Exports a directory and all it's content.
func export_assets(directory_id: int, path : String) -> void:
	path = path.replace("\\", "/")
	var directories : Array = [
		{
			"path": path,
			"subdirs": [{"id": directory_id, "name": AssetsDatabase.get_dir_name(directory_id)}]
		}
	]
	while !directories.empty():
		var directory : Dictionary = directories.pop_back()
		for subdir in directory.subdirs:
			directory_id = subdir.id
			var result : Dictionary = AssetsDatabase.get_assets(directory_id)
			directories.append({
				"path": directory.path + "/" + subdir.name,
				"subdirs": result.subdirectories
			})
			
			if !_Directory.dir_exists(directory.path + "/" + subdir.name):
				_Directory.make_dir(directory.path + "/" + subdir.name)
			
			for asset in result.assets:
				export_asset(asset.id, directory.path + "/" + subdir.name + "/" + asset.name)

# Export a single file.
func export_asset(asset_id: int, path : String) -> void:
	var asset : Dictionary = AssetsDatabase.get_asset(asset_id)
	if asset.has("filename"):
		_Directory.copy(build_assets_path(asset["filename"]), path.replace("\\", "/"))
		if asset["filename"].get_extension() == "obj":
			_Directory.copy(build_assets_path(asset["filename"].get_basename() + ".mtl"), path.replace("\\", "/").get_basename() + ".mtl")

# ---------------------------------------------
# 				Add / Update
# ---------------------------------------------
	
func add_asset(path: String, thumbnailName, type) -> int:
	return AssetsDatabase.add_asset(path, thumbnailName, type)
	
func create_directory(parentId : int, name : String) -> int:
	return AssetsDatabase.create_directory(parentId, name)
	
func update_asset(id : int, path: String, thumbnailName, type) -> bool:
	var asset := AssetsDatabase.get_asset(id)
	if asset.thumbnail: # Delete the old thumbnail
		_Directory.remove(get_thumbnail_path() + "/" + asset.thumbnail)
	
	return AssetsDatabase.update_asset(id, path, thumbnailName, type)
	
func _add_or_update_asset(path : String) -> void:
	_files_dropped([build_assets_path(path)], 0)
	
func _deleted_asset(path : String) -> void:
	print("DELETE: " + path)
	
func _renamed_asset(old_path : String, new_path : String) -> void:
	print("RENAMED: " + old_path + " to " + new_path)
	
# ---------------------------------------------
# 					Move
# ---------------------------------------------

# Moves a directory
func move_directory(parent_id : int, child_id : int) -> bool:
	if parent_id == child_id:
		return false
	return AssetsDatabase.move_directory(parent_id, child_id)
	
# Move an asset
func move_asset(parent_id : int, asset_id : int) -> bool:
	return AssetsDatabase.move_asset(parent_id, asset_id)
	
func delete_directory(directoryId: int) -> bool:
	return AssetsDatabase.delete_directory(directoryId)
	
# ---------------------------------------------
# 				   Queries
# ---------------------------------------------
	
func get_parent_dir_id(directoryId: int) -> int:
	return AssetsDatabase.get_parent_dir_id(directoryId)
	
func query_assets(directoryId : int, search: String, skip: int, count: int) -> Array:
	var results := AssetsDatabase.query_assets(directoryId, search, skip, count)
	for result in results:
		if result.has("thumbnail"):
			result["thumbnail"] = _load_thumbnail(result)
		result["name"] = result["name"].get_basename().get_file()
	
	return results
	
func get_assets_count(directoryId : int, search : String) -> int:
	return AssetsDatabase.get_assets_count(directoryId, search)

func get_asset_type(id : int) -> String:
	return AssetsDatabase.get_asset_type(id)
	
func get_asset_path(asset_id : int) -> String:
	var result = ""
	var asset = AssetsDatabase.get_asset(asset_id)
	if !asset.empty():
		result = build_assets_path(asset.filename)
		
	return result

# ---------------------------------------------
# 			    Update / Import
# ---------------------------------------------

func _process(_delta: float) -> void:
	if _Thread && !_Thread.is_alive():
		_TotalFilecount = 0
		_Thread.wait_to_finish()
		_Thread = null
		_DirWatcher.paused = false

# Render and index thread for assets
func _render_and_index_thread(_unused : Object) -> void:
	var f : File = File.new()
	while !_QuitThread:
		_QueueLock.lock()
		if _FileQueue.empty():
			_QueueLock.unlock()
			break
		
		var file_info : Dictionary = _FileQueue.pop_front()
		_QueueLock.unlock()

		if f.file_exists(file_info.file):
			# Checks if the asset is already imported
			var asset_info = AssetsDatabase.get_asset_by_name(file_info.file)
			var need_import = true
			if !asset_info.empty():
				var file : File = File.new()
				
				# Is the dropped file newer, than the current indexed one?
				var modified : int = file.get_modified_time(file_info.file)
				need_import = modified > asset_info.last_modified
			
			if need_import:
				var importer_result : Dictionary = file_info.importer.import(file_info.file, asset_info.id if !asset_info.empty() else 0)
				if !importer_result.empty():
					var texture : Texture = importer_result.thumbnail
					if !texture:
						texture = BROKEN_IMAGE
						
					var just_increment : bool = false
					
					# Link the asset with the currently opened directory
					if file_info.has("parent_id"):
						move_asset(file_info.parent_id, importer_result.id)
						just_increment = file_info.parent_id == current_directory
					else:
						move_asset(current_directory, importer_result.id)
					
					# Just increment counter, if we import an asset for a subdirectory.
					if just_increment:
						emit_signal("increase_import_counter")
					else:
						emit_signal("new_asset_added", importer_result.id, importer_result.name.get_basename().get_file(), texture)
			else:	# Updates the ui, even if no file was imported.
				if file_info.has("parent_id"):
					move_asset(file_info.parent_id, AssetsDatabase.get_asset_by_name(file_info.file.get_file()).id)
				
				emit_signal("increase_import_counter")
				
func find_importer(ext : String) -> IFormatImporter:
	for importer in _Importers:
		if _Importers[importer].get_extensions().find(ext) != -1:
			return _Importers[importer]
	return null

func _build_import_file_list(files: PoolStringArray) -> Array:
	var newFiles : Array = []
	var directories : Array = []
	for file in files:
		if _Directory.file_exists(file):
			var importer : IFormatImporter = find_importer(file.get_extension().to_lower())
			if importer:
				newFiles.append({"file": file, "importer": importer})
		elif _Directory.dir_exists(file):
			directories.append({"dir": file, "parent_id": current_directory})
	
	while !directories.empty():
		var dir : Dictionary = directories.pop_back()
		
		var parent_dir_id : int = 0
		
		# Checks if the directory already exists.
		var id : int = AssetsDatabase.get_directory_id(dir.parent_id, dir.dir.get_file())
		if id == 0:
			parent_dir_id = AssetsDatabase.create_directory(dir.parent_id, dir.dir.get_file())
		else:
			parent_dir_id = id
		
		var directory : Directory = Directory.new()
		if directory.open(dir.dir) == OK:
			directory.list_dir_begin()
			var file_name = directory.get_next()
			while file_name != "":
				if (file_name != ".") && (file_name != ".."):
					if !directory.current_is_dir():
						var importer : IFormatImporter = find_importer(file_name.get_extension().to_lower())
						if importer:
							newFiles.append({"file": dir.dir + "/" + file_name, "importer": importer, "parent_id": parent_dir_id})
					else:
						directories.append({"dir": dir.dir + "/" + file_name, "parent_id": parent_dir_id})
				file_name = directory.get_next()

	return newFiles

# Newly dropped files
func _files_dropped(files: PoolStringArray, _screen: int) -> void:
	var newFiles : Array = _build_import_file_list(files)
		
	# No supported files found.
	if newFiles.empty():
		return
		
	# Updates the ui
	_TotalFilecount += newFiles.size()
	emit_signal("update_total_import_assets", _TotalFilecount)
	
	# Adds the new files to the queue
	_QueueLock.lock()
	_FileQueue.append_array(newFiles)
	_QueueLock.unlock()

#	_render_and_index_thread(null)

	# Starts a new thread, but only if no one is already running.
	if !_Thread:
		_DirWatcher.paused = true
		_Thread = Thread.new()
		_Thread.start(self, "_render_and_index_thread", null)
