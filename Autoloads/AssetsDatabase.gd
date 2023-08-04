extends Node

const SQLITE = preload("res://addons/godot-sqlite/godot-sqlite-wrapper.gd")

enum AssetType {
	MODEL,
	IMAGE,
	AUDIO
}

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

func get_assets_count(directoryId : int, search : String) -> int:
	if _DB:
		var count : int = 0
		if directoryId != 0:
			if _DB.query_with_bindings("SELECT COUNT(a.id) as count FROM assets as a LEFT JOIN asset_directory_rel as b ON(b.ref_directory_id = ?) WHERE a.id = b.ref_assets_id AND a.filename LIKE ?", [null if directoryId == 0 else directoryId, '%' + search + '%']):
				count = _DB.query_result_by_reference[0].count
		else:
			if _DB.query_with_bindings("SELECT COUNT(id) as count FROM assets WHERE filename LIKE ?", ['%' + search + '%']):
				count = _DB.query_result_by_reference[0].count
				
		if _DB.query_with_bindings("SELECT COUNT(id) as count FROM directories WHERE parent_id = ? AND name LIKE ?", [null if directoryId == 0 else directoryId, '%' + search + '%']):
			count += _DB.query_result_by_reference[0].count
		
		return count
	return 0

func query_assets(directoryId : int, search: String, skip: int, count: int) -> Array:
	if _DB:
		if _DB.query_with_bindings("SELECT id, name FROM directories WHERE parent_id = ? AND name LIKE ? LIMIT ?, ?", [null if directoryId == 0 else directoryId, '%' + search + '%', skip, count]):
			var result : Array = _DB.query_result
			if result.size() < count:
				if directoryId != 0:
					if _DB.query_with_bindings("SELECT a.id, a.filename as name, a.thumbnail FROM assets as a LEFT JOIN asset_directory_rel as b ON(b.ref_directory_id = ?) WHERE a.id = b.ref_assets_id AND a.filename LIKE ? LIMIT ?, ?", [directoryId, '%' + search + '%', skip, count - result.size()]):
						result.append_array(_DB.query_result)
				else:
					if _DB.query_with_bindings("SELECT id, filename as name, thumbnail FROM assets WHERE filename LIKE ? LIMIT ?, ?", ['%' + search + '%', skip, count - result.size()]):
						result.append_array(_DB.query_result)
				
			return result
	return []

func add_asset(path: String, thumbnailName, type) -> bool:
	if _DB:
		var file : File = File.new()
		var modified : int = file.get_modified_time(path)
		
		return _DB.insert_row("assets", {"filename": path.get_file(), "last_modified": modified, "type": type, "thumbnail": thumbnailName})
	return false

func _migrate() -> bool:
	var ret = false
	if _DB.query("SELECT name FROM sqlite_schema WHERE type = 'table'"):
		var results : Array = _DB.query_result
		for i in results.size():
			results[i] = results[i].name
		
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
					"not_null": true
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
