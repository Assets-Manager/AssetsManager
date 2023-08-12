extends Node

const SQLITE = preload("res://addons/godot-sqlite/godot-sqlite-wrapper.gd")

var _DB : SQLITE = null

# Opens a database
# Returns true on success.
func open(path : String) -> bool:
	_DB = SQLITE.new()
	_DB.path = path
	_DB.foreign_keys = true
	if _DB.open_db():
		return _migrate()	# Starts a migration of the database
		
	return false

func get_all_directories() -> Array:
	if _DB:
		if _DB.query("SELECT * FROM directories ORDER BY parent_id"):
			return _DB.query_result
		
	return []

func move_directory(parent_id : int, child_id : int) -> bool:
	if _DB:
		return _DB.update_rows("directories", "id=" + str(child_id), {"parent_id": null if parent_id == 0 else parent_id})
	return false
	
func move_asset(parent_id : int, asset_id : int) -> bool:
	if _DB:
		if _DB.delete_rows("asset_directory_rel", "ref_assets_id=" + str(asset_id)):
			if parent_id != 0:
				return _DB.insert_row("asset_directory_rel", {'ref_assets_id': asset_id, "ref_directory_id": parent_id})
			return true
	return false

func get_parent_dir_id(directoryId: int) -> int:
	if _DB:
		var result : Array = _DB.select_rows("directories", "id = " + str(directoryId), ["parent_id"])
		if !result.empty():
			return result[0].parent_id if result[0].parent_id != null else 0
		
	return 0

func delete_directory(directoryId: int) -> bool:
	if _DB:
		return _DB.delete_rows("directories", "id=" + str(directoryId))
		
	return false

func get_dir_name(directory_id : int) -> String:
	if _DB:
		if _DB.query_with_bindings("SELECT name FROM directories WHERE id = ?", [directory_id]):
			if !_DB.query_result.empty():
				return _DB.query_result[0].name
		
	return ""

func get_or_add_asset_type(name : String) -> int:
	if _DB:
		if _DB.query_with_bindings("SELECT id FROM asset_types WHERE name = ?", [name]):
			if !_DB.query_result.empty():
				return _DB.query_result[0].id
			else:
				if _DB.insert_row("asset_types", {"name": name}):
					return _DB.db.last_insert_rowid
		
	return -1

func get_assets(directory_id : int) -> Dictionary:
	if _DB:
		var result : Dictionary = {}
		if _DB.query_with_bindings("SELECT id, name FROM directories WHERE parent_id = ?", [directory_id]):
			result["subdirectories"] = _DB.query_result
		
		if _DB.query_with_bindings("SELECT a.id, a.filename as name, a.thumbnail FROM assets as a LEFT JOIN asset_directory_rel as b ON(b.ref_directory_id = ?) WHERE a.id = b.ref_assets_id", [directory_id]):
			result["assets"] = _DB.query_result
				
		return result
	return {}

func get_asset(asset_id : int) -> Dictionary:
	if _DB:
		if _DB.query_with_bindings("SELECT * from assets WHERE id = ?", [asset_id]):
			if !_DB.query_result.empty():
				return _DB.query_result[0]
		
	return {}

func create_directory(parentId : int, name : String) -> int:
	if _DB:
		if _DB.insert_row("directories", {"name": name, "parent_id": null if parentId == 0 else parentId}):
			return _DB.db.last_insert_rowid
			
	return 0

# Returns the total numbers of assets for a given search in a directory.
func get_assets_count(directoryId : int, search : String) -> int:
	if _DB:
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
		
		if _DB.query_with_bindings(query, bindings):
			count = _DB.query_result_by_reference[0].count
		
		if _DB.query_with_bindings("SELECT COUNT(id) as count FROM directories WHERE parent_id = ? AND name LIKE ?", [null if directoryId == 0 else directoryId, '%' + search + '%']):
			count += _DB.query_result_by_reference[0].count
		
		return count
	return 0

# Returns a list of directories and assets which matches the search criteria.
func query_assets(directoryId : int, search: String, skip: int, count: int) -> Array:
	if _DB:
		var result : Array = []
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
		if _DB.query_with_bindings(query, bindings):
			result = _DB.query_result
			
		# There is room for more
		if result.size() < count:
			if result.empty():
				# Create some sort of relative skip, since the directories are in a different table.
				if _DB.query("SELECT COUNT(1) as count from directories"):
					skip -= _DB.query_result_by_reference[0].count
			else:
				skip = 0
			
			bindings = ['%' + search + '%', skip, count - result.size()]
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
			if _DB.query_with_bindings(query, bindings):
				result.append_array(_DB.query_result)

#		if result.size() < count:
#			if directoryId != 0:
#				if _DB.query_with_bindings("SELECT a.id, a.filename as name, a.thumbnail FROM assets as a LEFT JOIN asset_directory_rel as b ON(b.ref_directory_id = ?) WHERE a.id = b.ref_assets_id AND a.filename LIKE ? LIMIT ?, ?", [directoryId, '%' + search + '%', skip, count - result.size()]):
#					result.append_array(_DB.query_result)
#			else:
#				if _DB.query_with_bindings("SELECT a.id, a.filename as name, a.thumbnail FROM assets as a LEFT JOIN asset_directory_rel as b ON(b.ref_assets_id = a.id) WHERE a.filename LIKE ? AND b.ref_directory_id IS NULL LIMIT ?, ?", ['%' + search + '%', skip, count - result.size()]):
#					result.append_array(_DB.query_result)
				
		return result
	return []

func add_asset(path: String, thumbnailName, type) -> int:
	if _DB:
		var file : File = File.new()
		var modified : int = file.get_modified_time(path)
		
		if _DB.insert_row("assets", {"filename": path.get_file(), "last_modified": modified, "type": type, "thumbnail": thumbnailName}):
			return _DB.db.last_insert_rowid
	return -1

func _migrate() -> bool:
	var ret = false
	if _DB.query("SELECT name FROM sqlite_schema WHERE type = 'table'"):
		var results : Array = _DB.query_result
		for i in results.size():
			results[i] = results[i].name
		
		if results.find("asset_types") == -1:
			ret = _DB.create_table("asset_types", {
				"id": {
					"data_type": "int",
					"primary_key": true,
					"auto_increment": true
				},
				"name": {
					"data_type": "text",
					"not_null": true,
					"unique": true
				},
			})
		else:
			ret = true
		
		if results.find("assets") == -1:
			ret = _DB.create_table("assets", {
				"id": {
					"data_type": "int",
					"primary_key": true,
					"auto_increment": true
				},
				"filename": {
					"data_type": "text",
					"not_null": true
				},
				"last_modified": {
					"data_type": "numeric",
					"not_null": true
				},
				"type": {
					"data_type": "int",
					"not_null": true,
					"foreign_key": "asset_types.id"
				},
				"thumbnail": {
					"data_type": "text"
				}
			})
		else:
			ret = true

		if results.find("directories") == -1:
			ret = _DB.query(
				"CREATE TABLE 'directories' ('id' INTEGER, 'name' TEXT NOT NULL, 'parent_id' INTEGER, FOREIGN KEY('parent_id') REFERENCES 'directories'('id') ON DELETE CASCADE, PRIMARY KEY('id' AUTOINCREMENT));"
			)
		else:
			ret = true
	
		if results.find("asset_directory_rel") == -1:
			ret = _DB.query(
				"CREATE TABLE 'asset_directory_rel' ('ref_assets_id'	INTEGER,'ref_directory_id'	INTEGER,PRIMARY KEY('ref_assets_id','ref_directory_id'), FOREIGN KEY('ref_directory_id') REFERENCES 'directories'('id') ON DELETE CASCADE, FOREIGN KEY('ref_assets_id') REFERENCES 'assets'('id') ON DELETE CASCADE);"
			)
		else:
			ret = true
	
	return ret
