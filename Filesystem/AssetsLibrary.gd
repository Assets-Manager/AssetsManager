extends Node

const IMPORTERS_PATH = "res://FormatImporters/"

signal new_asset_added(id, name, thumbnail)
signal update_total_import_assets(count)

var _AssetsPath : String = ""
var _QueueLock : Mutex = Mutex.new()
var _Thread : Thread = null
var _FileQueue : Array = []
var _TotalFilecount : int = 0
var _QuitThread : bool = false
var _Directory : Directory = Directory.new()
var _Importers : Dictionary = {}

var current_directory : int = 0

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
		child.queue_free()
	
	var dir := Directory.new()
	if dir.open(IMPORTERS_PATH) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				var script = load(IMPORTERS_PATH + file_name)
				if !script.get_type().empty():
					var id : int = AssetsDatabase.get_or_add_asset_type(script.get_type())
					if id != -1:
						var importer : IFormatImporter = script.new()
						importer.register(self, id)
						_Importers[script.get_type()] = importer
						
			file_name = dir.get_next()
		
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
	
# Opens a given assets library
# Returns true on success
func open(path : String) -> bool:
	_AssetsPath = path
	
	if _AssetsPath[_AssetsPath.length() - 1] == "/":
		_AssetsPath.erase(_AssetsPath.length() - 1, 1)
	
	if AssetsDatabase.open(_AssetsPath + "/assets.db"):
		# Creates the thumbnail directory.
		if !_Directory.dir_exists(get_thumbnail_path()):
			_Directory.make_dir(get_thumbnail_path())
			
		_load_importers()
		
		get_tree().connect("files_dropped", self, "_files_dropped")
		return true
		
	return false

# Returns a list of all directories. Ordered by the parents.
func get_all_directories() -> Array:
	return AssetsDatabase.get_all_directories()

# ---------------------------------------------
# 					Export
# ---------------------------------------------

# Exports a directory and all it's content.
func export_assets(directory_id: int, path : String) -> void:
	path = path.replace("\\", "/")
	var directories : Array = [directory_id]
	while !directories.empty():
		directory_id = directories.pop_back()
		var result : Dictionary = AssetsDatabase.get_assets(directory_id)
		directories.append_array(result.subdirectories)
		
		var dirname : String = AssetsDatabase.get_dir_name(directory_id)
		if !_Directory.dir_exists(path + "/" + dirname):
			_Directory.make_dir(path + "/" + dirname)
		
		for asset in result.assets:
			export_asset(asset.id, path + "/" + dirname + "/" + asset.name)

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
	return AssetsDatabase.update_asset(id, path, thumbnailName, type)
	
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
			var thumbnailpath = ""
			if result["thumbnail"]:
				thumbnailpath = get_thumbnail_path() + "/" + result["thumbnail"]
			else:	# For images, because they are already images.
				thumbnailpath = build_assets_path(result["name"])
				
			var img := Image.new()
			img.load(thumbnailpath)
			
			var texture := ImageTexture.new()
			texture.create_from_image(img, 0)
			result["thumbnail"] = texture
			result["name"] = result["name"].get_basename().get_file()
	
	return results
	
func get_assets_count(directoryId : int, search : String) -> int:
	return AssetsDatabase.get_assets_count(directoryId, search)

# ---------------------------------------------
# 			    Update / Import
# ---------------------------------------------

func _process(_delta: float) -> void:
	if _Thread && !_Thread.is_alive():
		_Thread.wait_to_finish()
		_Thread = null

# Render and index thread for assets
func _render_and_index_thread(_unused : Object) -> void:
	var f : File = File.new()
	while !_QuitThread:
		_QueueLock.lock()
		if _FileQueue.empty():
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
						var img := Image.new()
						img.load(build_assets_path(importer_result.file))
						texture = ImageTexture.new()
						texture.create_from_image(img, 0)
					
					# Link the asset with the currently opened directory
					if current_directory != 0:
						move_asset(current_directory, importer_result.id)
					
					emit_signal("new_asset_added", importer_result.id, importer_result.file.get_basename().get_file(), texture)

func _find_importer(ext : String) -> IFormatImporter:
	for importer in _Importers:
		if _Importers[importer].get_extensions().find(ext) != -1:
			return _Importers[importer]
	return null

# Newly dropped files
func _files_dropped(files: PoolStringArray, _screen: int) -> void:
	var newFiles = []
	var f : File = File.new()
	for file in files:
		if f.file_exists(file):
			var importer : IFormatImporter = _find_importer(file.get_extension().to_lower())
			if importer:
				newFiles.append({"file": file, "importer": importer})
	
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
		_Thread = Thread.new()
		_Thread.start(self, "_render_and_index_thread", null)
