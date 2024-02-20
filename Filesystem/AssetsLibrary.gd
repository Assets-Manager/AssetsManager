extends Node

const IMPORTERS_PATH = "res://FormatImporters/"
const BROKEN_IMAGE = preload("res://Assets/Material Icons/hide_image.svg")

signal new_asset_added(id, name, thumbnail)
signal update_total_import_assets(count)
signal increase_import_counter()
signal files_to_check(files)

enum FileImportStatus {
	STATUS_OK,
	STATUS_OVERWRITE
}

var _AssetsPath : String = ""
var _QueueLock : Mutex = Mutex.new()
var _Thread : Thread = null
var _FileQueue : Array = []
var _TotalFilecount : int = 0
var _QuitThread : bool = false
var _Directory : Directory = Directory.new()
var _File : File = File.new()
var _Importers : Dictionary = {}
var _AssetsDatabase: AssetsDatabase = AssetsDatabase.new()

# Needed to track duplicates in currently dropped files.
var _CurrentImportingFilename : Dictionary = {}

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
					var id : int = _get_or_add_asset_type(script.get_type())
					if id != 0:
						var importer : IFormatImporter = script.new()
						supported_extensions.append_array(importer.get_extensions())
						importer.register(self, id)
						_Importers[script.get_type()] = importer
						
			file_name = dir.get_next()
			
	_DirWatcher.supported_extensions = supported_extensions
	
# ---------------------------------------------
# 					Database
# ---------------------------------------------
	
# Opens a given assets library
# Returns true on success
func open(path : String) -> bool:
	_AssetsPath = path
	
	if _AssetsPath[_AssetsPath.length() - 1] == "/":
		_AssetsPath.erase(_AssetsPath.length() - 1, 1)
	
	if _AssetsDatabase.open(_AssetsPath + "/assets.db"):
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

# Closes the opened asset library
func close() -> void:
	get_tree().disconnect("files_dropped", self, "_files_dropped")
	_DirWatcher.close()
	_AssetsDatabase.close()
	_AssetsPath = ""
	
# ---------------------------------------------
# 					Helpers
# ---------------------------------------------
	
# Returns the currently opened asset path
func get_assets_path() -> String:
	return _AssetsPath
	
# As the name says :D
# Generates the filename in form of DBID_FILENAME.EXT and appends it to the path of the library folder.
# The old names FILENAME.EXT will be renamed to the new one.
func generate_and_migrate_assets_path(path : String, id : int) -> String:
	var filename : String
	if id != 0:
		var decoded_file := decode_asset_name(path)
		if decoded_file.empty() || (decoded_file[0] != id):
			filename = str(id) + "_" + path.get_file()
			
			# Migrates the old filename to the new one
			if !_Directory.file_exists(_build_assets_path(filename)):
				_Directory.rename(_build_assets_path(path.get_file()), _build_assets_path(filename))
		else:	# The file is already imported and encoded.
			filename = path.get_file()
	else:
		var result = _AssetsDatabase.query_with_bindings("SELECT seq FROM sqlite_sequence WHERE name = 'assets'", [])
		filename = str(result[0].seq + 1) + "_" + path.get_file()
		
	return _build_assets_path(filename)

# Tries to decode the file name in format of ID_NAME.EXT
# Returns an array with two entries [0] => ID [1] => NAME.EXT
# Returns an empty array, if the format didn't match
func decode_asset_name(path : String) -> Array:
	var decoded_file := path.get_file().split("_", false, 1)
	if decoded_file.size() == 2:
		if decoded_file[0].is_valid_integer():
			return [int(decoded_file[0]), decoded_file[1]]
	return []

# Returns the path to the thumbnails directory.
func get_thumbnail_path() -> String:
	return _AssetsPath + "/thumbnails"
	
# Gets the id of a directory.
# The parentId of the directory is needed, since the dir name isn't unique.
func get_directory_id(parentId : int, name : String) -> int:
	var result : int = 0
	var bindings : Array = [name]
	var query = "parent_id IS NULL"
	
	# If the parentId isn't 0, add the id to the query.
	if parentId != 0:
		query = "parent_id = ?"
		bindings.push_front(parentId)
	
	var qresult = _AssetsDatabase.query_with_bindings("SELECT id FROM directories WHERE %s AND name = ?" % query, bindings)
	if !qresult.empty():
		result = qresult[0].id
	
	return result

# Returns a list of all directories. Ordered by the parents.
func get_all_directories() -> Array:
	return _AssetsDatabase.query_with_bindings("SELECT * FROM directories ORDER BY parent_id", [])
	
# Tries to load the thumbnail of an asset.
# If there is no thumbnail or the image couldn't be loaded, a placeholder one is returned.
func load_thumbnail(asset : Dictionary) -> Texture:
	if asset.has("thumbnail"):
		if !(asset["thumbnail"] is Texture):
			var thumbnailpath = ""
			if asset["thumbnail"]:
				thumbnailpath = get_thumbnail_path() + "/" + asset["thumbnail"]
			else:	# For images, because they are already images.
				thumbnailpath = generate_and_migrate_assets_path(asset["name"].get_file(), asset["id"])
			
			var texture : Texture = null
			if _Directory.file_exists(thumbnailpath):
				var img := Image.new()
				if img.load(thumbnailpath) == OK:
					texture = ImageTexture.new()
					texture.create_from_image(img, 0)
			else:	# The user or something else, deleted the thumbnail. Please don't do that user.
				return BROKEN_IMAGE
			
			if texture:
				return texture
		else:
			return asset["thumbnail"]
	return BROKEN_IMAGE

# Builds the absolute path to the assets library
func _build_assets_path(subpath : String) -> String:
	return _AssetsPath + "/" + subpath

# Gets the id for an asset type.
# Creates a new database entry, if the type doesn't exists.
func _get_or_add_asset_type(name : String) -> int:
	# First check, if the type already exists.
	var result = _AssetsDatabase.query_with_bindings("SELECT id FROM asset_types WHERE name = ?", [name])
	if !result.empty():
		return result[0].id
	else:
		# Otherwise create a new entry.
		if _AssetsDatabase.insert("asset_types", {"name": name}):
			return _AssetsDatabase.get_last_insert_rowid()
			
	return 0	# Error

# Code is documentation enough :D
func _get_directory_assets_and_subdirs(directory_id) -> Dictionary:
	var result : Dictionary = {}
	var qresult = _AssetsDatabase.query_with_bindings("SELECT id, name FROM directories WHERE parent_id = ?", [directory_id])
	if !qresult.empty():
		result["subdirectories"] = qresult
	else:
		result["subdirectories"] = []
		
	qresult = _AssetsDatabase.query_with_bindings("SELECT a.id, a.filename as name, a.thumbnail FROM assets as a LEFT JOIN asset_directory_rel as b ON(b.ref_directory_id = ?) WHERE a.id = b.ref_assets_id", [directory_id])
	if !qresult.empty():	
		result["assets"] = qresult
	else:
		result["assets"] = []

	return result

# ---------------------------------------------
# 					Export
# ---------------------------------------------

# Saves a counter for each file of the export
# This allows to overwrite existing files with the same name as an asset
# But prevents multiple assets with the same name to be overwritten all over again
# For example: You got two assets in a folder named Test.png
# this is no problem for the library but for your os, so one file must be named different than the
# other one. The name schema is the following NAME (COUNTER[1 - n]).EXT e.g. Test (1).png
var _ExportedFilesCounter : Dictionary = {}

# Exports a directory and all of it's content.
func export_assets(directory_id: int, path : String) -> void:
	_DirWatcher.paused = true # To prevent the watcher to track every read event.
	path = path.replace("\\", "/")
	var qresult = _AssetsDatabase.query_with_bindings("SELECT name FROM directories WHERE id = ?", [directory_id])
	if !qresult.empty():
		# Directory stack, to avoid recursion.
		var directories : Array = [
			{
				"path": path,
				"subdirs": [{"id": directory_id, "name": qresult[0].name}]
			}
		]
		
		# Run until there are no more directories left.
		while !directories.empty():
			var directory : Dictionary = directories.pop_back()
			for subdir in directory.subdirs:
				directory_id = subdir.id
				var result : Dictionary = _get_directory_assets_and_subdirs(directory_id)
				directories.append({
					"path": directory.path + "/" + subdir.name,
					"subdirs": result.subdirectories
				})
				
				# Creates all sub directories.
				if !_Directory.dir_exists(directory.path + "/" + subdir.name):
					_Directory.make_dir(directory.path + "/" + subdir.name)
				
				# Export all assets inside the current processed directory.
				for asset in result.assets:
					_export_asset(asset.id, directory.path + "/" + subdir.name, asset.name)

	_ExportedFilesCounter = {}
	_DirWatcher.paused = false

# Export a single file.
func export_asset(asset_id: int, filename : String) -> void:
	_DirWatcher.paused = true # To prevent the watcher to track every read event.
	_export_asset(asset_id, filename.get_base_dir(), filename.get_file())
	_ExportedFilesCounter = {}
	_DirWatcher.paused = false

# Export a single file.
func _export_asset(asset_id: int, path : String, name_hint: String) -> void:
	if path.empty():
		return
	
	var asset : Dictionary = get_asset_by_id(asset_id)
	if asset.has("filename"):
		# Build the path
		path = path.replace("\\", "/")
		if path[path.length() - 1] != '/':
			path += "/"
			
		if name_hint.empty():
			path += asset.filename
		else:
			path += name_hint
		
		# Since the asset library allows the same name multiple times in one directory,
		# we must ensure, that for any export these names are unique.
		if _ExportedFilesCounter.has(path):
			_ExportedFilesCounter[path] += 1
			path = path.get_basename() + " (" + str(_ExportedFilesCounter[path]) + ")." + path.get_extension()
		else:
			_ExportedFilesCounter[path] = 0
		
		_Directory.copy(generate_and_migrate_assets_path(asset["filename"], asset_id), path)
		if asset["filename"].get_extension() == "obj":
			var asset_path = generate_and_migrate_assets_path(asset["filename"].get_basename() + ".mtl", asset_id)
			_Directory.copy(asset_path, path.get_basename() + ".mtl")

# ---------------------------------------------
# 				Add / Update
# ---------------------------------------------

# Adds the asset to the library.
func add_asset(path: String, thumbnailName, type) -> int:
	var result : int = 0
	var modified : int = _File.get_modified_time(path)
	var decoded_file = decode_asset_name(path)
	if _AssetsDatabase.insert("assets", {"filename": path.get_file() if decoded_file.empty() else decoded_file[1], "last_modified": modified, "type": type, "thumbnail": thumbnailName.get_file()}):
		result = _AssetsDatabase.get_last_insert_rowid()
	
	return result

# Creates a new directory.
# Directories are purly virtual and doesn't exists on the harddrive.
func create_directory(parentId : int, name : String) -> int:
	var result : int = 0
	if _AssetsDatabase.insert("directories", {"name": name, "parent_id": null if parentId == 0 else parentId}):
		result = _AssetsDatabase.get_last_insert_rowid()
	
	return result

# Updates a given asset.
func update_asset(id : int, path: String, thumbnailName, type) -> bool:
	var asset := get_asset_by_id(id)
	if asset.thumbnail: # Delete the old thumbnail
		_Directory.remove(get_thumbnail_path() + "/" + asset.thumbnail)
	
	var result : bool = false
	var modified : int = _File.get_modified_time(path)
	var decoded_file = decode_asset_name(path)
	result = _AssetsDatabase.update("assets", "id=" + str(id), {"filename": path.get_file() if decoded_file.empty() else decoded_file[1], "last_modified": modified, "type": type, "thumbnail": thumbnailName.get_file()})
	return result

# ---------------------------------------------
# 			Filesystemwatcher
# ---------------------------------------------

func _add_or_update_asset(path : String) -> void:
	print("DROPPED: " + path)
	_files_dropped([_build_assets_path(path)], 0)
	
func _deleted_asset(path : String) -> void:
	print("DELETE: " + path)
	
func _renamed_asset(old_path : String, new_path : String) -> void:
	print("RENAMED: " + old_path + " to " + new_path)
	
# ---------------------------------------------
# 				Move / Link
# ---------------------------------------------

# Moves a directory
func move_directory(parent_id : int, child_id : int) -> bool:
	if parent_id == child_id:
		return false
		
	return _AssetsDatabase.update("directories", "id=" + str(child_id), {"parent_id": null if parent_id == 0 else parent_id})

# Move an asset
func move_asset(parent_id : int, asset_id : int) -> bool:
	# Assets which have multiple links, will be unlinked from the current directory.
	if get_asset_linked_dirs(asset_id).size() > 1:
		unlink_asset(current_directory, asset_id)
	else:
		_AssetsDatabase.delete("asset_directory_rel", "ref_assets_id=" + str(asset_id))
	
	return link_asset(parent_id, asset_id)
	
func link_asset(parent_id : int, asset_id : int) -> bool:
	return _AssetsDatabase.insert("asset_directory_rel", {'ref_assets_id': asset_id, "ref_directory_id": parent_id})

# Unlinks an asset from its given parent
func unlink_asset(parent_id : int, asset_id : int) -> bool:
	return _AssetsDatabase.delete("asset_directory_rel", "ref_assets_id=" + str(asset_id) + " AND ref_directory_id=" + str(parent_id))

# Deletes a directory and it's subdirectories, all of it's content goes into the root directory.
func delete_directory(directoryId: int) -> bool:
	return _AssetsDatabase.delete("directories", "parent_id=" + str(directoryId)) && _AssetsDatabase.delete("directories", "id=" + str(directoryId))

# ---------------------------------------------
# 				   Queries
# ---------------------------------------------

func get_parent_dir_id(directoryId: int) -> int:
	var qresult := _AssetsDatabase.query_with_bindings("SELECT parent_id FROM directories WHERE id = ?", [directoryId])
	if !qresult.empty():
		return 0 if (qresult[0].parent_id == null) else qresult[0].parent_id 
	
	return 0
	
func get_parent_dir(directoryId: int) -> Dictionary:
	var parent_id = get_parent_dir_id(directoryId)
	if parent_id != 0:
		var qresult := _AssetsDatabase.query_with_bindings("SELECT * FROM directories WHERE id = ?", [parent_id])
		if !qresult.empty():
			return qresult[0] 
	
	return {}
	
func query_assets(directoryId : int, search: String, skip: int, count: int) -> Array:
	var results : Array = []
	var bindings : Array = ['%' + search + '%', skip, count]

	# Builds the query for the directories.
	var query = "SELECT id, name, parent_id FROM directories WHERE %s name LIKE ? LIMIT ?, ?"
	if directoryId != 0:
		query = query % "parent_id = ? AND"
		bindings.push_front(directoryId)
	else:
		# The root directory allows for a global search
		if search.empty():
			query = query % "parent_id IS NULL AND"
		else:
			query = query % ""

	# Query all directories.
	results = _AssetsDatabase.query_with_bindings(query, bindings)

	# Is there room for more?
	if results.size() < count:
		if results.empty():
			# Create some sort of relative skip, since the directories are in a different table.
			var qresult := _AssetsDatabase.query_with_bindings("SELECT COUNT(1) as count from directories", [])
			if !qresult.empty():
				skip -= qresult[0].count
		else:
			skip = 0

		bindings = ['%' + search + '%', skip, count - results.size()]
		query = "SELECT a.id, a.filename as name, a.thumbnail %s FROM assets as a %s WHERE %s a.filename LIKE ? LIMIT ?, ?"
		if directoryId != 0:
			query = query % ["", "LEFT JOIN asset_directory_rel as b ON(b.ref_directory_id = ?)", "a.id = b.ref_assets_id AND"]
			bindings.push_front(directoryId)
		else:
			# The root directory allows for a global search
			if search.empty():
				query = query % ["", "LEFT JOIN asset_directory_rel as b ON(b.ref_assets_id = a.id)", "b.ref_directory_id IS NULL AND"]
			else:	# For open containing folder.
				query = query % [", b.ref_directory_id as parent_id", "LEFT JOIN asset_directory_rel as b ON(b.ref_assets_id = a.id)", ""]

		# Query all assets.
		results.append_array(_AssetsDatabase.query_with_bindings(query, bindings))

	for result in results:
		if result.has("thumbnail"):
			result["thumbnail"] = load_thumbnail(result)
		result["name"] = result["name"].get_basename().get_file()
	
	return results
	
func get_assets_count(directoryId : int, search : String) -> int:
	var count : int = 0
	var query : String = "SELECT COUNT(a.id) as count FROM assets as a"
	var bindings : Array = []

	# Search all files and directories inside of the given directory
	if directoryId != 0:
		query += " LEFT JOIN asset_directory_rel as b ON(b.ref_directory_id = ?) WHERE a.id = b.ref_assets_id AND a.filename LIKE ?"
		bindings = [directoryId, '%' + search + '%']
	else:
		# The root directory allows for a global search
		if search.empty():
			query += " LEFT JOIN asset_directory_rel as b ON(b.ref_assets_id = a.id) WHERE b.ref_directory_id IS NULL"
		else:
			query += " WHERE a.filename LIKE ?"
			bindings.append('%' + search + '%')

	var qresult := _AssetsDatabase.query_with_bindings(query, bindings)
	if !qresult.empty():
		count = qresult[0].count

	qresult = _AssetsDatabase.query_with_bindings("SELECT COUNT(id) as count FROM directories WHERE parent_id = ? AND name LIKE ?", [null if directoryId == 0 else directoryId, '%' + search + '%'])
	if !qresult.empty():
		count += qresult[0].count

	return count

func get_assets_by_name(file : String) -> Array:
	return _AssetsDatabase.query_with_bindings("SELECT * FROM assets WHERE filename = ?", [file.get_file()])
	
func get_asset_by_id(asset_id : int) -> Dictionary:
	var result : Dictionary = {}
	var qresult = _AssetsDatabase.query_with_bindings("SELECT * from assets WHERE id = ?", [asset_id])
	if !qresult.empty():
		result = qresult[0]
	return result
	
func is_asset_in_dir(asset_id : int, directory_id : int) -> bool:
	return !_AssetsDatabase.query_with_bindings("SELECT * from asset_directory_rel WHERE ref_assets_id = ? AND ref_directory_id = ?", [asset_id, directory_id]).empty()

# Returns a list of directories, where the given asset is linked with.
func get_asset_linked_dirs(asset_id : int) -> Array:
	return _AssetsDatabase.query_with_bindings("SELECT d.id, d.name FROM directories as d LEFT JOIN asset_directory_rel as ad ON(ad.ref_assets_id = ?) WHERE d.id = ad.ref_directory_id", [asset_id])

# ---------------------------------------------
# 			    Update / Import
# ---------------------------------------------

func _process(_delta: float) -> void:
	if _Thread && !_Thread.is_alive():
		_TotalFilecount = 0
		_Thread.wait_to_finish()
		_Thread = null
		_CurrentImportingFilename.clear()
		_DirWatcher.paused = false
	elif !_Thread && _TotalFilecount != 0:
		_TotalFilecount = 0
		_CurrentImportingFilename.clear()

# Render and index thread for assets
func _render_and_index_thread(_unused : Object) -> void:
	while !_QuitThread:
		_QueueLock.lock()
		if _FileQueue.empty():
			_QueueLock.unlock()
			break
		
		var file_info : Dictionary = _FileQueue.pop_front()
		_QueueLock.unlock()

		if _File.file_exists(file_info.file):
			var need_import = true
			var asset_info : Dictionary = {}
			
			if file_info.has("overwrite_id") && (file_info.overwrite_id != 0):	# Only overwrite if the user selected overwrite
				asset_info = get_asset_by_id(file_info.overwrite_id)
				
			if !asset_info.empty():
				# Is the dropped file newer, than the current indexed one?
				var modified : int = _File.get_modified_time(file_info.file)
				need_import = modified > asset_info.last_modified
			
			if need_import:
				var importer_result : Dictionary = file_info.importer.import(file_info.file, asset_info.id if !asset_info.empty() else 0)
				if !importer_result.empty():
					var texture : Texture = importer_result.thumbnail
					if !texture:
						texture = BROKEN_IMAGE
						
					var just_increment : bool = true
					
					# Link the asset with the currently opened directory
					if file_info.status != FileImportStatus.STATUS_OVERWRITE:
						# Move every new asset accordingly
						move_asset(current_directory if !file_info.has("parent_id") else file_info.parent_id, importer_result.id)
						if file_info.has("parent_id"):
							just_increment = current_directory != file_info.parent_id
					else:
						# Updates the view
						just_increment = !(current_directory in get_asset_linked_dirs(importer_result.id))
					
					# Just increment counter, if we import an asset for a subdirectory.
					if just_increment:
						emit_signal("increase_import_counter")
					else:
						emit_signal("new_asset_added", importer_result.id, importer_result.name.get_basename().get_file(), texture)
			else:	# Updates the ui, even if no file was imported.
				emit_signal("increase_import_counter")
		else:
			emit_signal("increase_import_counter")
				
func _find_importer(ext : String) -> IFormatImporter:
	for importer in _Importers:
		if _Importers[importer].get_extensions().find(ext) != -1:
			return _Importers[importer]
	return null

func _check_file_status(file : String) -> Array:
	var decoded_file = decode_asset_name(file)
	if !decoded_file.empty():
		return [FileImportStatus.STATUS_OK, decoded_file[0]]
	
	var status = FileImportStatus.STATUS_OK
	if _CurrentImportingFilename.has(file.get_file()):
		status = FileImportStatus.STATUS_OVERWRITE
	else:
		_CurrentImportingFilename[file.get_file()] = null
		var assets : Array = get_assets_by_name(file)
		if !assets.empty():
			status = FileImportStatus.STATUS_OVERWRITE
			
	return [status, 0]

func _build_import_file_list(files: PoolStringArray) -> Array:
	var newFiles : Array = []
	var directories : Array = []
	for file in files:
		if _Directory.file_exists(file):
			var importer : IFormatImporter = _find_importer(file.get_extension().to_lower())
			if importer:
				var status : Array = _check_file_status(file)
				newFiles.append({"file": file, "importer": importer, "status": status[0], "overwrite_id": status[1]})
		elif _Directory.dir_exists(file):
			directories.append({"dir": file, "parent_id": current_directory})
	
	while !directories.empty():
		var dir : Dictionary = directories.pop_back()
		var parent_dir_id : int = 0
		
		# Checks if the directory already exists.
		var id : int = get_directory_id(dir.parent_id, dir.dir.get_file())
		if id == 0:
			parent_dir_id = create_directory(dir.parent_id, dir.dir.get_file())
		else:
			parent_dir_id = id
		
		var directory : Directory = Directory.new()
		if directory.open(dir.dir) == OK:
			directory.list_dir_begin()
			var file_name = directory.get_next()
			while file_name != "":
				if (file_name != ".") && (file_name != ".."):
					if !directory.current_is_dir():
						var importer : IFormatImporter = _find_importer(file_name.get_extension().to_lower())
						if importer:
							var file : String = dir.dir + "/" + file_name
							var status : Array = _check_file_status(file)
							newFiles.append({"file": file, "importer": importer, "parent_id": parent_dir_id, "status": status[0], "overwrite_id": status[1]})
					else:
						directories.append({"dir": dir.dir + "/" + file_name, "parent_id": parent_dir_id})
				file_name = directory.get_next()

	return newFiles

func handle_user_processed_file(file : Dictionary) -> void:
	_add_to_queue_and_start_thread([file])

# Newly dropped files
func _files_dropped(files: PoolStringArray, _screen: int) -> void:
	var fileList : Array = _build_import_file_list(files)
		
	# No supported files found.
	if fileList.empty():
		return
		
	# Creates to lists, one to import and one which needs approval from the user.
	var newFiles : Array = []
	var userCheckFiles : Array = []
	for file in fileList:
		if file.status == FileImportStatus.STATUS_OK:
			newFiles.append(file)
		else:
			userCheckFiles.append(file)
	
	if !newFiles.empty():
		# Updates the ui
		_TotalFilecount += newFiles.size()
		emit_signal("update_total_import_assets", _TotalFilecount)
		
		_add_to_queue_and_start_thread(newFiles)
	
	if !userCheckFiles.empty():
		emit_signal("files_to_check", userCheckFiles)

func _add_to_queue_and_start_thread(files : Array) -> void:
	# Adds the new files to the queue
	_QueueLock.lock()
	_FileQueue.append_array(files)
	_QueueLock.unlock()
	
#	_DirWatcher.paused = true
#	_render_and_index_thread(null)

	# Starts a new thread, but only if no one is already running.
	if !_Thread:
		_DirWatcher.paused = true
		_Thread = Thread.new()
		_Thread.start(self, "_render_and_index_thread", null)
