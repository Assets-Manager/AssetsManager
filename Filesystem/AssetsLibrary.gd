extends Node

const IMPORTERS_PATH = "res://FormatImporters/"
const BROKEN_IMAGE = preload("res://Assets/Material Icons/hide_image.svg")

signal new_asset_added(asset: AMAsset)
signal update_total_import_assets(count: int)
signal increase_import_counter()
signal files_to_check(files: Array[AMImportFile])

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
var _Importers : Dictionary[int, IFormatImporter] = {}
var _AssetsDatabase: AssetsDatabase = AssetsDatabase.new()
var _HasFocus : bool = true

# Assets found by File Watcher when the window didn't have focus.
var _FilewatcherAssets : Array = []

# Needed to track duplicates in currently dropped files.
var _CurrentImportingFilename : Dictionary = {}

var current_directory : int = 0
@onready var _DirWatcher : DirectoryWatcher = DirectoryWatcher.new()

#region Setup

func _ready() -> void:
	add_child(_DirWatcher)
	_DirWatcher.connect("new_asset", Callable(self, "_add_or_update_asset"))
	_DirWatcher.connect("changed_asset", Callable(self, "_add_or_update_asset"))
	_DirWatcher.connect("deleted_asset", Callable(self, "_deleted_asset"))
	_DirWatcher.connect("renamed_asset", Callable(self, "_renamed_asset"))

## Joins the running thread.
func _exit_tree() -> void:
	_QuitThread = true
	if _Thread:
		_Thread.wait_to_finish()
		
## Loads all importers.
## Allows in the future to add more importers easily.
## Also allows to create some sort of plugin system, so users can write their own
## importers without to recompile the whole project.
func _load_importers() -> void:
	_Importers.clear()
	for child in get_children():
		if !(child is DirectoryWatcher):
			child.queue_free()
	
	var supported_extensions : Array
	var dir := DirAccess.open(IMPORTERS_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() && !("IFormat" in file_name) && !file_name.ends_with(".uid"):
				var script = load(IMPORTERS_PATH + file_name.trim_suffix('.remap'))
				if !script.get_type().is_empty():
					var id : int = _get_or_add_asset_type(script.get_type())
					if id != 0:
						var importer : IFormatImporter = script.new()
						supported_extensions.append_array(script.get_extensions())
						importer.register(self, id)
						_Importers[id] = importer
						
			file_name = dir.get_next()
			
	_DirWatcher.supported_extensions = supported_extensions
	
#endregion

#region Database
	
## Opens a given assets library
## [br]
## [b]Return:[/b] Returns true on success
func open(path : String) -> bool:
	_AssetsPath = path
	
	if _AssetsPath[_AssetsPath.length() - 1] == "/":
		_AssetsPath.erase(_AssetsPath.length() - 1, 1)
	
	if _AssetsDatabase.open(_AssetsPath.path_join("assets.db")):
		current_directory = 0
		
		# Creates the thumbnail directory.
		if !DirAccess.dir_exists_absolute(get_thumbnail_path()):
			DirAccess.make_dir_absolute(get_thumbnail_path())
			
		_load_importers()
		_DirWatcher.open(_AssetsPath.replace("\\", "/"))
		
		ProgramManager.settings.last_opened = _AssetsPath
		get_window().files_dropped.connect(_files_dropped)
		return true
		
	return false

## Closes the opened asset library
func close() -> void:
	get_window().files_dropped.disconnect(_files_dropped)
	_DirWatcher.close()
	_AssetsDatabase.close()
	_AssetsPath = ""

## Generic method to copy a query result over to a given model.
func _fill_model(model, query_result: Dictionary):
	for prop in model.get_property_list():
		# Copies only properties which are exists in both, the query and the model.
		if ((prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE) == PROPERTY_USAGE_SCRIPT_VARIABLE) && query_result.has(prop["name"]):
			model.set(prop["name"], query_result[prop["name"]])
			
	return model

#endregion

#region Filesystem

## Returns the currently opened asset path
func get_assets_path() -> String:
	return _AssetsPath
	
## As the name says :D
## Generates the filename in form of DBID_FILENAME.EXT and appends it to the path of the library folder.
## The old names FILENAME.EXT will be renamed to the new one.
func generate_and_migrate_assets_path(path : String, id : int) -> String:
	var filename : String
	if id != 0:
		var decoded_file := decode_asset_name(path)
		if decoded_file.is_empty() || (decoded_file[0] != id):
			filename = str(id) + "_" + path.get_file()
			
			# Migrates the old filename to the new one
			if !FileAccess.file_exists(_build_assets_path(filename)):
				DirAccess.rename_absolute(_build_assets_path(path.get_file()), _build_assets_path(filename))
		else:	# The file is already imported and encoded.
			filename = path.get_file()
	else:
		var result = _AssetsDatabase.query_with_bindings_with_qresult("SELECT seq FROM sqlite_sequence WHERE name = 'assets'", [])
		var seq : int = 0
		if !result.is_empty():
			seq = result[0].seq
		
		filename = str(seq + 1) + "_" + path.get_file()
		
	return _build_assets_path(filename)

## Tries to decode the file name in format of ID_NAME.EXT
## Returns an array with two entries [0] => ID [1] => NAME.EXT
## Returns an empty array, if the format didn't match
func decode_asset_name(path : String) -> Array:
	var decoded_file := path.get_file().split("_", false, 1)
	if decoded_file.size() == 2:
		if decoded_file[0].is_valid_int():
			return [int(decoded_file[0]), decoded_file[1]]
	return []

## Returns the path to the thumbnails directory.
func get_thumbnail_path() -> String:
	return _AssetsPath.path_join("thumbnails")

## Tries to load the thumbnail of an asset.
## If there is no thumbnail or the image couldn't be loaded, a placeholder one is returned.
func load_thumbnail(asset : AMAsset) -> Texture2D:
	if asset.thumbnail:
		if !(asset.thumbnail is Texture2D):
			var thumbnailpath = ""
			if asset.thumbnail:
				thumbnailpath = get_thumbnail_path().path_join(asset.thumbnail)
			else:	# For images, because they are already images.
				thumbnailpath = generate_and_migrate_assets_path(asset.filename.get_file(), asset.id)
			
			var texture : Texture2D = null
			if FileAccess.file_exists(thumbnailpath):
				var img := Image.new()
				if img.load(thumbnailpath) == OK:
					texture = ImageTexture.create_from_image(img)
			else:	# The user or something else, deleted the thumbnail. Please don't do that user.
				return BROKEN_IMAGE
			
			if texture:
				return texture
		else:
			return asset.thumbnail
	return BROKEN_IMAGE

## Builds the absolute path to the assets library
func _build_assets_path(subpath : String) -> String:
	return _AssetsPath.path_join(subpath)

#region Export
# Saves a counter for each file of the export
# This allows to overwrite existing files with the same name as an asset
# But prevents multiple assets with the same name to be overwritten all over again
# For example: You got two assets in a folder named Test.png
# this is no problem for the library but for your os, so one file must be named different than the
# other one. The name schema is the following NAME (COUNTER[1 - n]).EXT e.g. Test (1).png
var _ExportedFilesCounter : Dictionary = {}

## Exports a list of assets and directories
func export_assets(export_list: Array, path : String) -> void:
	_DirWatcher.paused = true # To prevent the watcher to track every read event.
	path = path.replace("\\", "/")
	
	for entry in export_list:
		if entry is AMDirectory:
			_export_dir(entry, path)
		elif entry is AMAsset:
			_export_asset(entry.id, path if export_list.size() == 1 else path.get_base_dir(), entry.filename if export_list.size() == 1 else path.get_file())
	
	_ExportedFilesCounter = {}
	_DirWatcher.paused = false

## Exports a single file.
func export_asset(asset_id: int, filename : String) -> void:
	_DirWatcher.paused = true # To prevent the watcher to track every read event.
	_export_asset(asset_id, filename.get_base_dir(), filename.get_file())
	_ExportedFilesCounter = {}
	_DirWatcher.paused = false

## Exports a directory
func _export_dir(dir : AMDirectory, path: String) -> void:
	var qresult = _AssetsDatabase.query_with_bindings_with_qresult("SELECT name FROM directories WHERE id = ?", [dir.id])
	if !qresult.is_empty():
		# Directory stack, to avoid recursion.
		var directories : Array = [
			{
				"path": path,
				"subdirs": [{"id": dir.id, "name": qresult[0].name}]
			}
		]
		
		# Run until there are no more directories left.
		while !directories.is_empty():
			var directory : Dictionary = directories.pop_back()
			for subdir in directory.subdirs:
				var result : Dictionary = _get_directory_assets_and_subdirs(subdir.id)
				directories.append({
					"path": directory.path.path_join(subdir.name),
					"subdirs": result.subdirectories
				})
				
				# Creates all sub directories.
				if !DirAccess.dir_exists_absolute(directory.path.path_join(subdir.name)):
					DirAccess.make_dir_absolute(directory.path.path_join(subdir.name))
				
				# Export all assets inside the current processed directory.
				for asset in result.assets:
					_export_asset(asset.id, directory.path.path_join(subdir.name), asset.name)

## Exports a single file.
func _export_asset(asset_id: int, path : String, name_hint: String) -> void:
	if path.is_empty():
		return
	
	var asset : AMAsset = _get_asset_by_id(asset_id)
	if asset.filename:
		# Build the path
		path = path.replace("\\", "/")
		if path[path.length() - 1] != '/':
			path += "/"
			
		if name_hint.is_empty():
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
		
		DirAccess.copy_absolute(generate_and_migrate_assets_path(asset.filename, asset_id), path)
		if asset.filename.get_extension() == "obj":
			var asset_path = generate_and_migrate_assets_path(asset.filename.get_basename() + ".mtl", asset_id)
			DirAccess.copy_absolute(asset_path, path.get_basename() + ".mtl")

#endregion

#endregion

#region Helpers

func _find_importer(ext : String) -> IFormatImporter:
	for importer in _Importers:
		if _Importers[importer].get_extensions().find(ext) != -1:
			return _Importers[importer]
	return null

## Gets the id for an asset type.
## [br]
## Creates a new database entry, if the type doesn't exists.
## [br]
## [b]Return:[/b] Returns the id of the type or 0 on error.
func _get_or_add_asset_type(p_name : String) -> int:
	# First check, if the type already exists.
	var result = _AssetsDatabase.query_with_bindings_with_qresult("SELECT id FROM asset_types WHERE name = ?", [p_name])
	if !result.is_empty():
		return result[0].id
	else:
		# Otherwise create a new entry.
		if _AssetsDatabase.insert("asset_types", {"name": p_name}):
			return _AssetsDatabase.get_last_insert_rowid()
			
	return 0

## Code is documentation enough :D
func _get_directory_assets_and_subdirs(directory_id: int) -> Dictionary:
	var result : Dictionary = {}
	var qresult = _AssetsDatabase.query_with_bindings_with_qresult("SELECT id, name FROM directories WHERE parent_id = ?", [directory_id])
	if !qresult.is_empty():
		result["subdirectories"] = qresult
	else:
		result["subdirectories"] = []
		
	qresult = _AssetsDatabase.query_with_bindings_with_qresult("SELECT a.id, a.filename as name, a.thumbnail FROM assets as a LEFT JOIN asset_directory_rel as b ON(b.ref_directory_id = ?) WHERE a.id = b.ref_assets_id", [directory_id])
	if !qresult.is_empty():	
		result["assets"] = qresult
	else:
		result["assets"] = []

	return result

#endregion

#region Virtual-Filesystem

#region Directory

func get_parent_dir(directoryId: int) -> AMDirectory:
	var qresult := _AssetsDatabase.query_with_bindings_with_qresult("SELECT parent_id FROM directories WHERE id = ?", [directoryId])
	if !qresult.is_empty() && qresult[0].parent_id != 0:
		qresult = _AssetsDatabase.query_with_bindings_with_qresult("SELECT * FROM directories WHERE id = ?", [qresult[0].parent_id])
		if !qresult.is_empty():
			return _fill_model(AMDirectory.new(), qresult[0])
	
	return null

## Checks if a directory for a given parent already exists
## The parentId of the directory is needed, since the dir name isn't unique.
func dir_exists(parentId : int, p_name : String) -> bool:
	return _get_directory_id(parentId, p_name) != 0

## Returns a list of all directories. Ordered by the parents.
func get_all_directories() -> Array[AMDirectory]:
	var result : Array[AMDirectory] = []
	var query_results := _AssetsDatabase.query_with_bindings_with_qresult("SELECT * FROM directories ORDER BY parent_id", [])
	for query_result in query_results:
		result.push_back(_fill_model(AMDirectory.new(), query_result))
	
	return result

## Creates a new directory.
## Directories are purly virtual and doesn't exists on the harddrive.
## Returns null on error
func create_directory(parentId : int, p_name : String) -> AMDirectory:
	var result : AMDirectory = null
	if _AssetsDatabase.insert("directories", {"name": p_name, "parent_id": null if parentId == 0 else parentId}):
		result = AMDirectory.new()
		result.id = _AssetsDatabase.get_last_insert_rowid()
		result.name = p_name
		result.parent_id = parentId
	
	return result

func _get_directory_id(parentId : int, p_name : String) -> int:
	var result : int = 0
	var bindings : Array = [p_name]
	var query = "parent_id IS NULL"
	
	# If the parentId isn't 0, add the id to the query.
	if parentId != 0:
		query = "parent_id = ?"
		bindings.push_front(parentId)
	
	var qresult = _AssetsDatabase.query_with_bindings_with_qresult("SELECT id FROM directories WHERE %s AND name = ?" % query, bindings)
	if !qresult.is_empty():
		result = qresult[0].id
	
	return result

#endregion

#region Assets

## Builds the search query for directories
## Returns a dictionary {"bindings": Array, "query": String, "join": String}
func _build_directory_query(search : AMSearch) -> Dictionary:
	var bindings: Array = []
	var query: String = "%s"
	var join: String = ""
	var recursive: String = ""
	if !search.search_term.is_empty():
		query = "%sd.name LIKE ?"
		
	# Adds a join condition, to include only directories, which had the given tags assigned
	var tag_id_list = search.get_tag_ids()
	if !tag_id_list.is_empty():
		join = "LEFT JOIN tag_directory_rel as td ON(td.ref_tag_id IN (%s))" % tag_id_list
		query = query % ("d.id = td.ref_directory_id" + (" AND %s" if search.directory_id != 0 || !search.search_term.is_empty() else " %s"))
	
	if search.directory_id != 0:
		if search.search_term.is_empty() && tag_id_list.is_empty():
			query = query % ("d.parent_id = ?" + (" AND " if !search.search_term.is_empty() else ""))
			bindings.push_back(search.directory_id)
		else:
			# A recursive sql call to create a list of all subdirs for the search
			recursive = """
				WITH RECURSIVE dirs AS (
					SELECT id, parent_id FROM directories
					WHERE id = %d
					UNION
					SELECT d.id, d.parent_id FROM directories as d
					JOIN dirs ON d.parent_id = dirs.id
				)
				""" % search.directory_id
			
			query = query % ("d.parent_id IN (SELECT id FROM dirs)" + (" AND " if !search.search_term.is_empty() else ""))
	else:
		# The root directory allows for a global search
		if search.search_term.is_empty() && tag_id_list.is_empty():
			query = query % ("d.parent_id IS NULL" + (" AND " if !search.search_term.is_empty() else ""))
		else:
			query = query % ""
			
	if !search.search_term.is_empty():
		bindings.push_back("%" + search.search_term + "%")
	
	return {"bindings": bindings, "query": query, "join": join, "recursive": recursive}
	
## Builds the search query for assets
## Returns a dictionary {"bindings": Array, "query": String, "join": String, "recursive": String}
func _build_asset_query(search : AMSearch) -> Dictionary:
	var bindings: Array = []
	var query: String = "%s"
	var join: String = ""
	var recursive = ""
	
	if !search.search_term.is_empty():
		query = "%sa.filename LIKE ?"
		
	# Adds a join condition, to include only assets, which had the given tags assigned
	var tag_id_list = search.get_tag_ids()
	if !tag_id_list.is_empty():
		join = "LEFT JOIN tag_asset_rel as ta ON(ta.ref_tag_id IN (%s)) " % tag_id_list
		query = query % ("a.id = ta.ref_assets_id" + (" AND %s" if search.directory_id != 0 || !search.search_term.is_empty() else " %s"))
	
	if search.directory_id != 0:
		if search.search_term.is_empty() && tag_id_list.is_empty():
			join += "LEFT JOIN asset_directory_rel as ad ON(ad.ref_directory_id = ?) "
			bindings.push_back(search.directory_id)
		else:
			# A recursive sql call to create a list of all subdirs for the search
			recursive = """
				WITH RECURSIVE dirs AS (
					SELECT id, parent_id FROM directories
					WHERE id = %d
					UNION
					SELECT d.id, d.parent_id FROM directories as d 
					JOIN dirs ON d.parent_id = dirs.id
				)
				""" % search.directory_id
			
			join += "LEFT JOIN asset_directory_rel as ad ON(ad.ref_directory_id IN (SELECT id FROM dirs)) "
		query = query % ("a.id = ad.ref_assets_id" + (" AND " if !search.search_term.is_empty() else ""))
	else:
		join += "LEFT JOIN asset_directory_rel as ad ON(ad.ref_assets_id = a.id)"
		
		# The root directory allows for a global search
		if search.search_term.is_empty() && tag_id_list.is_empty():
			query = query % ("ad.ref_directory_id IS NULL" + (" AND " if !search.search_term.is_empty() else ""))
		else:
			query = query % ""
	
	if !search.search_term.is_empty():
		bindings.push_back("%" + search.search_term + "%")
	
	return {"bindings": bindings, "query": query, "join": join, "recursive": recursive}

## Returns the total count of items (including dirs and assets), for a search
func get_assets_count(search: AMSearch) -> int:
	var count : int = 0
	
	var dquery := _build_directory_query(search)
	var aquery := _build_asset_query(search)
	
	# We create a union of two different queries, where one counts the number of total dirs
	# for the given search and one the total count of assets. The result is sumed up.
	var qresult := _AssetsDatabase.query_with_bindings_with_qresult("""
		%s
		SELECT SUM(count) as total_count FROM (
			SELECT COUNT(*) as count FROM directories as d %s WHERE %s
			UNION
			SELECT COUNT(*)  as count FROM assets as a %s WHERE %s
		)
	""" % [aquery.recursive, dquery.join, dquery.query, aquery.join, aquery.query], dquery.bindings + aquery.bindings)
	if !qresult.is_empty():
		count = qresult[0].total_count
		
	return count
	
## Returns a list which contains AMDirectory and AMAsset objects
func query_assets(search: AMSearch, skip: int, count: int) -> Array:
	var result : Array = []
	
	var dquery := _build_directory_query(search)
	var aquery := _build_asset_query(search)
	
	var qresults := _AssetsDatabase.query_with_bindings_with_qresult("""
		%s
		SELECT id, name, NULL as last_modified, NULL as type, NULL as thumbnail, parent_id FROM directories as d %s WHERE %s
		UNION
		SELECT id, filename, last_modified, type, thumbnail, %s as parent_id FROM assets as a %s WHERE %s
		LIMIT ?, ?
	""" % [aquery.recursive, dquery.join, dquery.query, "NULL" if (search.directory_id == 0 && search.search_term.is_empty()) else "ad.ref_directory_id", aquery.join, aquery.query], dquery.bindings + aquery.bindings + [skip, count])
	
	for qresult in qresults:
		if qresult.has("type") && qresult.type:
			qresult["filename"] = qresult["name"].get_basename().get_file()
			result.push_back(_fill_model(AMAsset.new(), qresult))
			if result.back().thumbnail:
				result.back().thumbnail = load_thumbnail(result.back())
		else:
			result.push_back(_fill_model(AMDirectory.new(), qresult))
	
	return result

## Adds the asset to the library.
## Returns null on error
func add_asset(path: String, thumbnailName: String, type: int) -> AMAsset:
	var result : AMAsset = null
	var modified : int = FileAccess.get_modified_time(path)
	var decoded_file = decode_asset_name(path)
	
	var data := {
		"filename": path.get_file() if decoded_file.is_empty() else decoded_file[1], 
		"last_modified": modified, 
		"type": type, 
		"thumbnail": thumbnailName.get_file() if thumbnailName else null
	}
	
	if _AssetsDatabase.insert("assets", data):
		result = _fill_model(AMAsset.new(), data)
		result.id = _AssetsDatabase.get_last_insert_rowid()
		result.thumbnail = load_thumbnail(result)
	
	return result

## Updates a given asset.
## Returns null on error
func update_asset(id : int, path: String, thumbnailName: String, type: int) -> AMAsset:
	var asset := _get_asset_by_id(id)
	if asset.thumbnail: # Delete the old thumbnail
		DirAccess.remove_absolute(get_thumbnail_path().path_join(asset.thumbnail))
	
	var result : bool = false
	var modified : int = FileAccess.get_modified_time(path)
	var decoded_file = decode_asset_name(path)
	
	var data := {
		"filename": path.get_file() if decoded_file.is_empty() else decoded_file[1], 
		"last_modified": modified, 
		"type": type, 
		"thumbnail": thumbnailName.get_file()
	}
	
	if !_AssetsDatabase.update("assets", "id=" + str(id), data):
		return null
		
	_fill_model(asset, data)
	asset.thumbnail = load_thumbnail(asset)
		
	return asset

## Gets a list of assets by it's name
func get_assets_by_name(file : String) -> Array[AMAsset]:
	var result : Array[AMAsset] = []
	var query_results = _AssetsDatabase.query_with_bindings_with_qresult("SELECT * FROM assets WHERE filename = ?", [file.get_file()])
	for query_result in query_results:
		result.append(_fill_model(AMAsset.new(), query_result))
	
	return result

## Returns the path to a file, inside the library [br]
## - [param relative_path] Relative path to the current folder. This is the database path
func get_library_path_from_relative_path(relative_path: String) -> String:
	relative_path = relative_path.replace("\\", "/")
	var parts = relative_path.split("/")
	
	var cases = ""
	for i in range(1, parts.size() - 1):
		cases += "WHEN %d THEN '%s'\n" % [i, parts[i]]
		
	var qresult : Array[Dictionary] = []
	
	if !cases.is_empty():
		qresult = _AssetsDatabase.query_with_bindings_with_qresult(
			"""
			WITH RECURSIVE walk(id, depth) AS (
			  SELECT id, 0 FROM directories WHERE parent_id %s AND name = ?
			  UNION ALL
			  SELECT d.id, w.depth+1
			  FROM walk AS w
			  JOIN directories AS d ON d.parent_id = w.id
			  WHERE d.name = CASE w.depth+1
							   %s
							 END
			)
			
			SELECT a.id, a.filename FROM assets AS a
			LEFT JOIN asset_directory_rel AS ad ON(
				ad.ref_directory_id IN (SELECT id FROM walk WHERE depth = ? ORDER BY depth DESC)
			)
			WHERE a.id = ad.ref_assets_id AND a.filename = ?
			""" % ["IS NULL" if current_directory == 0 else " = " + str(current_directory), cases],
			[parts[0], parts.size() - 2, parts[parts.size() - 1]]
		)
	elif parts.size() == 2:
		qresult = _AssetsDatabase.query_with_bindings_with_qresult(
			"""
			SELECT a.id, a.filename FROM assets AS a
			LEFT JOIN directories as d ON(
				d.parent_id %s AND d.name = ?
			)
			LEFT JOIN asset_directory_rel AS ad ON(
				ad.ref_directory_id = d.id
			)
			WHERE a.id = ad.ref_assets_id AND a.filename = ?
			""" % ["IS NULL" if current_directory == 0 else " = " + str(current_directory)],
			[parts[0], parts[1]]
		)
	elif parts.size() == 1:
		if current_directory != 0:
			qresult = _AssetsDatabase.query_with_bindings_with_qresult(
				"""
				SELECT a.id, a.filename FROM assets AS a
				LEFT JOIN asset_directory_rel AS ad ON(
					ad.ref_directory_id = ?
				)
				WHERE a.id = ad.ref_assets_id AND a.filename = ?
				""",
				[current_directory, parts[0]]
			)
		else:
			qresult = _AssetsDatabase.query_with_bindings_with_qresult(
				"""
				SELECT a.id, a.filename FROM assets AS a
				WHERE a.filename = ?
				""",
				[parts[0]]
			)
	
	var result = ""
	if qresult.size() == 1:
		result = generate_and_migrate_assets_path(qresult[0].filename, qresult[0].id)
	
	return result

## Returns true if a given asset is in a given diretory
func is_asset_in_dir(asset_id : int, directory_id : int) -> bool:
	return !_AssetsDatabase.query_with_bindings_with_qresult("SELECT * from asset_directory_rel WHERE ref_assets_id = ? AND ref_directory_id = ?", [asset_id, directory_id]).is_empty()

## Returns a list of directories, where the given asset is linked with.
func get_asset_linked_dirs(asset_id : int) -> Array:
	return _AssetsDatabase.query_with_bindings_with_qresult("SELECT d.id, d.name FROM directories as d LEFT JOIN asset_directory_rel as ad ON(ad.ref_assets_id = ?) WHERE d.id = ad.ref_directory_id", [asset_id])

func _get_asset_by_id(asset_id : int) -> AMAsset:
	var result : AMAsset = null
	var qresult = _AssetsDatabase.query_with_bindings_with_qresult("SELECT * from assets WHERE id = ?", [asset_id])
	if !qresult.is_empty():
		result = _fill_model(AMAsset.new(), qresult[0])
	return result

#endregion

#region Move / Delete / Link / Rename

## Moves one or more assets or directories, to a given location [br][br]
## - [param assets] Either an array of directories and / or files or a single file or directory [br]
## - [param destination] Id of the destination directory. 0 is the root directory [br]
## - [param create_link] Files can be linked into different directories. If this option is true, every file is linked and not moved [br][br]
## [b]Return:[/b] Returns true of success
func move(assets, destination: int, create_link: bool) -> bool:	
	if assets is Array: # Bulk move
		return _move_bulk(assets, destination, create_link)
	# Single asset move
	return _move_single(assets, destination, create_link)
	
## Unlinks an asset from its given parent
func delete_link(asset_id : int, parent_id : int) -> bool:
	return _AssetsDatabase.delete("asset_directory_rel", "ref_assets_id=" + str(asset_id) + " AND ref_directory_id=" + str(parent_id))

## Deletes one or more assets or directories, permanently [br][br]
## - [param assets] Either an array of directories and / or files or a single file or directory [br][br]
## [b]Return:[/b] Returns true of success
func delete(assets) -> bool:
	if assets is Array: # Bulk delete
		if assets.is_empty():
			return false
		
		var dir_list = ""
		for asset in assets:
			if asset is AMDirectory:
				if !dir_list.is_empty():
					dir_list += ","
				dir_list += str(asset.id)
				
		return _AssetsDatabase.query_with_bindings("DELETE FROM directories WHERE id IN (%s)" % dir_list, [])
	elif assets is AMDirectory:
		return _AssetsDatabase.query_with_bindings("DELETE FROM directories WHERE id = ?", [assets.id])
		
	return false

## Renames an asset or directory
func rename(asset, new_name: String) -> bool:
	if new_name.is_empty():
		return false
	
	if asset is AMDirectory:
		return _AssetsDatabase.update("directories", "id=" + str(asset.id), {"name": new_name})
	elif asset is AMAsset:
		if asset.filename == new_name:
			return true
		
		if _Importers.has(asset.type):
			var dbAsset = _get_asset_by_id(asset.id)
			
			var result := _AssetsDatabase.update("assets", "id=" + str(asset.id), {"filename": new_name + "." + dbAsset.filename.get_extension()})
			if result && _AssetsDatabase.query_with_bindings("BEGIN TRANSACTION", []):
				_DirWatcher.paused = true
				var from : String = generate_and_migrate_assets_path(dbAsset.filename, asset.id)
				var to : String = generate_and_migrate_assets_path(new_name, asset.id) + "." + dbAsset.filename.get_extension()
				result = _Importers[asset.type].move_asset(from, to)
				if result:
					_AssetsDatabase.query_with_bindings("COMMIT", [])
				else:
					_AssetsDatabase.query_with_bindings("ROLLBACK", [])
				
				_DirWatcher.paused = false
			
			return result
		
	return false

func _has_link(asset_id: int) -> bool:
	var qresult = _AssetsDatabase.query_with_bindings_with_qresult("SELECT 1 FROM asset_directory_rel WHERE ref_assets_id = ? LIMIT 1", [asset_id])
	return !qresult.is_empty()

func _move_bulk(assets: Array, destination: int, create_link: bool) -> bool:
	if assets.is_empty():
		return false
		
	var dir_list = ""
	var asset_list = ""
	var insert_asset_list = ""
	
	# Builds two lists for bulk move
	for asset in assets:
		if asset is AMDirectory:
			if asset.id != destination:
				if !dir_list.is_empty():
					dir_list += ","
				dir_list += str(asset.id)
		elif asset is AMAsset:
			if !asset_list.is_empty():
				asset_list += ","
			
			if !insert_asset_list.is_empty():
				insert_asset_list += ","
				
			if destination != 0 && (create_link || !_has_link(asset.id)):
				insert_asset_list += "(%d, %d)" % [asset.id, destination]
			else:
				asset_list += str(asset.id)
				
	return _move_query(dir_list, asset_list, insert_asset_list, destination)
	
func _move_single(asset, destination: int, create_link: bool) -> bool:
	if asset is AMDirectory:
		if asset.id == destination:
			return false
			
		return _move_query(str(asset.id), "", "", destination)
	elif asset is AMAsset:
		var asset_list = ""
		var insert_asset_list = ""
		
		if destination != 0 && (create_link || !_has_link(asset.id)):
			insert_asset_list += "(%d, %d)" % [asset.id, destination]
		else:
			asset_list += str(asset.id)
		
		return _move_query("", asset_list, insert_asset_list, destination)
		
	return false

func _move_query(dir_list: String, update_asset_list: String, insert_asset_list: String, destination: int) -> bool:
	var bindings = []
	var move_dir_query = ""
	var move_assets_query = ""
	var insert_assets_query = ""
	if !dir_list.is_empty():
		move_dir_query = "UPDATE directories SET parent_id = ? WHERE id IN (%s);" % dir_list
		if destination != 0:
			bindings.push_back(destination)
		else:
			bindings.push_back(null)
			
	if !update_asset_list.is_empty():
		if destination != 0:
			move_assets_query = "UPDATE asset_directory_rel SET ref_directory_id = ? WHERE ref_assets_id IN (%s) AND ref_directory_id = ?;" % update_asset_list
			bindings.push_back(destination)
			bindings.push_back(current_directory)
		else: # Since root is not a folder, just delete all links
			move_assets_query = "DELETE FROM asset_directory_rel WHERE ref_assets_id IN (%s);" % update_asset_list
	
	if !insert_asset_list.is_empty():
		insert_assets_query = "INSERT INTO asset_directory_rel (ref_assets_id, ref_directory_id) VALUES %s;" % insert_asset_list
	
	if !_AssetsDatabase.query_with_bindings(
		"""
			BEGIN TRANSACTION;
			%s
			%s
			%s
			COMMIT;
		""" % [move_dir_query, move_assets_query, insert_assets_query], bindings):
			_AssetsDatabase.query_with_bindings("ROLLBACK", [])
			return false
	return true

#endregion

#endregion

#region Tags

## Gets a list of all tags
func get_all_tags() -> Array[AMTag]:
	var result : Array[AMTag] = []
	var qresults := _AssetsDatabase.query_with_bindings_with_qresult("SELECT * FROM tags ORDER BY name", [])
	for qresult in qresults:
		result.append(_fill_model(AMTag.new(), qresult))
	
	return result

## Returns all tags for a given asset
func get_tags(asset) -> Array[AMTag]:
	var result : Array[AMTag] = []
	var join = ""
	
	if asset is AMDirectory:
		join = "LEFT JOIN tag_directory_rel as tr ON (tr.ref_directory_id = ?)"
	elif asset is AMAsset:
		join = "LEFT JOIN tag_asset_rel as tr ON (tr.ref_assets_id = ?)"
		
	var qresults := _AssetsDatabase.query_with_bindings_with_qresult("""
		SELECT t.* FROM tags as t
		%s
		WHERE t.id = tr.ref_tag_id
	""" % join, [asset.id])
	
	for qresult in qresults:
		result.push_back(_fill_model(AMTag.new(), qresult))
		
	return result

## Adds a tag to the library.
## [br][br]
## [b]Return:[/b] Returns the tag with the new database id or null on error.
func add_tag(tag : AMTag) -> AMTag:
	if _AssetsDatabase.insert("tags", {"name": tag.name, "description": tag.description if !tag.description.is_empty() else null}):
		tag.id = _AssetsDatabase.get_last_insert_rowid()
	else:
		tag = null
		
	return tag

## Updates a tag
## [br][br]
## [b]Return:[/b] Returns true on success
func update_tag(tag : AMTag) -> bool:
	return _AssetsDatabase.update("tags", "id=%d" % tag.id, {"name": tag.name, "description": tag.description if !tag.description.is_empty() else null})

## Deletes a tag
## [br][br]
## [b]Return:[/b] Returns true on success
func delete_tag(tag: AMTag) -> bool:
	return _AssetsDatabase.delete("tags", "id=%d" % tag.id)

## Adds tags for given assets and directories [br][br]
## - [param assets] List of assets and or directories to tag
## - [param tags] Tags which should be set
## - [param recursive] If true all subdirs and subfiles are also tagged
func add_tags(assets: Array, tags: Array[AMTag], recursive: bool) -> void:
	if tags.is_empty() || assets.is_empty():
		return
	
	# Create a temporary table for easier cross join
	if _AssetsDatabase.query_with_bindings("CREATE TEMP TABLE temp_tags (id INTEGER)", []):
		var rows : Array[Dictionary] = []
		for tag in tags:
			rows.push_back({"id": tag.id})
		if _AssetsDatabase.insert_rows("temp_tags", rows):
			var collected_data := _collect_tag_data(assets, recursive)
			
			var query = collected_data["recursive_query"]
			if !collected_data["assets_select"].is_empty():
				query += """
					INSERT OR IGNORE INTO tag_asset_rel (ref_assets_id, ref_tag_id) 
					SELECT a.id, t.id
					FROM (%s) AS a
					CROSS JOIN temp_tags AS t;\n
				""" % collected_data["assets_select"]
						
			if !collected_data["dir_select"].is_empty():
				query += """
					INSERT OR IGNORE INTO tag_directory_rel (ref_tag_id, ref_directory_id) 
					SELECT t.id, d.id
					FROM (%s) AS d
					CROSS JOIN temp_tags AS t;\n
				""" % collected_data["dir_select"]
						
			_AssetsDatabase.query_with_bindings(query, [])
		_AssetsDatabase.query_with_bindings("DROP TABLE temp_tags", [])

## Removes tags from assets and directories
func remove_tags(assets: Array, tags: Array[AMTag], recursive: bool) -> void:
	if tags.is_empty() || assets.is_empty():
		return
	
	var tag_list : String = ""
	for tag in tags:
		if !tag_list.is_empty():
			tag_list += ","
		tag_list += str(tag.id)
	
	var collected_data := _collect_tag_data(assets, recursive)
	
	var query = collected_data["recursive_query"]
	if !collected_data["assets_select"].is_empty():
		query += """
			DELETE FROM tag_asset_rel WHERE ref_assets_id IN (%s) AND ref_tag_id IN (%s) 
		""" % [collected_data["assets_select"], tag_list]
	
	if !collected_data["dir_select"].is_empty():
		query += """
			DELETE FROM tag_directory_rel WHERE ref_directory_id IN (%s) AND ref_tag_id IN (%s) 
		""" % [collected_data["dir_select"], tag_list]
	
	_AssetsDatabase.query_with_bindings(query, [])
	
func _collect_tag_data(assets: Array, recursive: bool) -> Dictionary[String, String]:
	var assets_select = ""
	var dir_select = ""
	var dir_list = ""
	for asset in assets:
		if asset is AMAsset:
			if !assets_select.is_empty():
				assets_select += " UNION ALL "
			assets_select += "SELECT %d%s" % [asset.id, "" if !assets_select.is_empty() else " AS id"]
		elif asset is AMDirectory:
			if !dir_select.is_empty():
				dir_select += " UNION ALL "
			dir_select += "SELECT %d%s" % [asset.id, "" if !dir_select.is_empty() else " AS id"]
			
			if recursive:
				if !dir_list.is_empty():
					dir_list += ","
				dir_list += str(asset.id)
				
	var recursive_query = ""
	if recursive && !dir_list.is_empty():
		recursive_query = """
			WITH RECURSIVE dirs AS (
				SELECT id, parent_id FROM directories
				WHERE id IN (%s)
				UNION
				SELECT d.id, d.parent_id FROM directories as d
				JOIN dirs ON d.parent_id = dirs.id
			);\n
		""" % dir_list
		
	if !assets_select.is_empty() && recursive && !dir_select.is_empty():
		assets_select += """
			UNION ALL
			(SELECT ref_assets_id as id FROM asset_directory_rel WHERE ref_directory_id IN dirs)
		"""
		
	if !dir_select.is_empty() && recursive:
		dir_select += """
			UNION ALL
			(SELECT id FROM dirs)
		"""
		
	return {"assets_select": assets_select, "dir_select": dir_select, "recursive_query": recursive_query}

#endregion

#region System

func _notification(what):
	match what:
		Node.NOTIFICATION_APPLICATION_FOCUS_IN:
			_HasFocus = true
			
		Node.NOTIFICATION_APPLICATION_FOCUS_OUT:
			_HasFocus = false

func _add_or_update_asset(path : String) -> void:
	print("DROPPED: " + path)
	if _HasFocus:
		_files_dropped([_build_assets_path(path)])
	else:
		path = _build_assets_path(path)
		
		# Could be slow on many files
		if !(path in _FilewatcherAssets):
			_FilewatcherAssets.append(path)
	
func _deleted_asset(path : String) -> void:
	print("DELETE: " + path)
	
func _renamed_asset(old_path : String, new_path : String) -> void:
	print("RENAMED: " + old_path + " to " + new_path)

# ---------------------------------------------
# 			    Update / Import
# ---------------------------------------------

func _process(_delta: float) -> void:
	# Handle any assets that were detected when the window wasn't focused.
	if _HasFocus && !_FilewatcherAssets.is_empty():
		_files_dropped(_FilewatcherAssets)
		_FilewatcherAssets.clear()
	
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
# Heart of the library.
func _render_and_index_thread() -> void:
	while !_QuitThread:
		_QueueLock.lock()
		if _FileQueue.is_empty():
			_QueueLock.unlock()
			break
		
		var file_info : AMImportFile = _FileQueue.pop_front()
		_QueueLock.unlock()

		if FileAccess.file_exists(file_info.file):
			var need_import = true
			var asset_info : AMAsset = null
			
			if file_info.overwrite_id != 0:	# Only overwrite if the user selected overwrite
				asset_info = _get_asset_by_id(file_info.overwrite_id)
				
			if asset_info:
				# Is the dropped file newer, than the current indexed one?
				var modified : int = FileAccess.get_modified_time(file_info.file)
				need_import = modified > asset_info.last_modified
			
			if need_import:
				var importer_result : AMAsset = file_info.importer.import(file_info.file, asset_info.id if asset_info else 0)
				if importer_result:
					if !importer_result.thumbnail:
						importer_result.thumbnail = BROKEN_IMAGE
						
					var just_increment : bool = true
					
					# Link the asset with the currently opened directory
					if file_info.status != FileImportStatus.STATUS_OVERWRITE:
						# Move every new asset accordingly
						if current_directory != 0 || file_info.parent_id != 0:
							_move_single(importer_result, current_directory if file_info.parent_id == 0 else file_info.parent_id, false)
							if file_info.parent_id != 0:
								just_increment = current_directory != file_info.parent_id
					else:
						# Updates the view
						just_increment = !(current_directory in get_asset_linked_dirs(importer_result.id))
					
					# Just increment counter, if we import an asset for a subdirectory.
					if just_increment:
						call_deferred("emit_signal", "increase_import_counter")
					else:
						call_deferred("emit_signal", "new_asset_added", importer_result)
				else:
					call_deferred("emit_signal", "increase_import_counter")
			else:	# Updates the ui, even if no file was imported.
				call_deferred("emit_signal", "increase_import_counter")
		else:
			call_deferred("emit_signal", "increase_import_counter")

# Returns a tuple where the first value is the import status and the second one is the overwrite id
func _check_file_status(file : String) -> Array:
	var decoded_file = decode_asset_name(file)
	if !decoded_file.is_empty():
		return [FileImportStatus.STATUS_OK, decoded_file[0]]
	
	var status = FileImportStatus.STATUS_OK
	if _CurrentImportingFilename.has(file.get_file()):
		status = FileImportStatus.STATUS_OVERWRITE
	else:
		_CurrentImportingFilename[file.get_file()] = null
		var assets : Array[AMAsset] = get_assets_by_name(file)
		if !assets.is_empty():
			status = FileImportStatus.STATUS_OVERWRITE
			
	return [status, 0]

func _build_import_file_list(files: PackedStringArray) -> Array[AMImportFile]:
	var newFiles : Array[AMImportFile] = []
	var directories : Array[Dictionary] = []
	for file in files:
		if FileAccess.file_exists(file):
			var importer : IFormatImporter = _find_importer(file.get_extension().to_lower())
			if importer:
				var status : Array = _check_file_status(file)
				newFiles.push_back(AMImportFile.new(file, importer, status[0], status[1]))
		elif DirAccess.dir_exists_absolute(file):
			directories.append({"dir": file, "parent_id": current_directory})
	
	while !directories.is_empty():
		var dir : Dictionary = directories.pop_back()
		var parent_dir_id : int = 0
		
		# Checks if the directory already exists.
		var id : int = _get_directory_id(dir.parent_id, dir.dir.get_file())
		if id == 0:
			var dir_model := create_directory(dir.parent_id, dir.dir.get_file())
			if dir:
				parent_dir_id = dir_model.id
		else:
			parent_dir_id = id
		
		var directory : DirAccess = DirAccess.open(dir.dir)
		if directory:
			directory.list_dir_begin()
			var file_name = directory.get_next()
			while file_name != "":
				if (file_name != ".") && (file_name != ".."):
					if !directory.current_is_dir():
						var importer : IFormatImporter = _find_importer(file_name.get_extension().to_lower())
						if importer:
							var file : String = dir.dir + "/" + file_name
							var status : Array = _check_file_status(file)
							newFiles.push_back(AMImportFile.new(file, importer, status[0], status[1], parent_dir_id))
					else:
						directories.append({"dir": dir.dir + "/" + file_name, "parent_id": parent_dir_id})
				file_name = directory.get_next()

	return newFiles

func handle_user_processed_file(file : AMImportFile) -> void:
	_add_to_queue_and_start_thread([file])

# Newly dropped files
func _files_dropped(files: PackedStringArray) -> void:
	var fileList : Array[AMImportFile] = _build_import_file_list(files)
		
	# No supported files found.
	if fileList.is_empty():
		return
		
	# Creates to lists, one to import and one which needs approval from the user.
	var newFiles : Array[AMImportFile] = []
	var userCheckFiles : Array[AMImportFile] = []
	for file in fileList:
		if file.status == FileImportStatus.STATUS_OK:
			newFiles.append(file)
		else:
			userCheckFiles.append(file)
	
	if !newFiles.is_empty():
		# Updates the ui
		_TotalFilecount += newFiles.size()
		update_total_import_assets.emit(_TotalFilecount)
		
		_add_to_queue_and_start_thread(newFiles)
		#call_deferred("_add_to_queue_and_start_thread", newFiles)
	
	if !userCheckFiles.is_empty():
		files_to_check.emit(userCheckFiles)

func _add_to_queue_and_start_thread(files : Array[AMImportFile]) -> void:
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
		_Thread.start(_render_and_index_thread)

#endregion
