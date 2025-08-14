class_name AssetsDatabase
extends RefCounted

var _DB : SQLite = null
var _Lock : Mutex = Mutex.new()

# Opens a database
# Returns true on success.
func open(path : String) -> bool:
	_DB = SQLite.new()
	_DB.path = path
	_DB.foreign_keys = true
	if _DB.open_db():
		return _migrate()	# Starts the migration of the database
		
	return false

# Closes the database
func close() -> void:
	_DB.close_db()

# ---------------------------------------------
# 				Query functions
# ---------------------------------------------

# Starts a query, with parameters.
# This function is thread safe.
func query_with_bindings(query: String, bindings: Array) -> Array[Dictionary]:
	var result : Array[Dictionary] = []
	if _DB:
		_Lock.lock()
		print(query)
		if _DB.query_with_bindings(query, bindings):
			result = _DB.query_result
		_Lock.unlock()
		
	return result

## Inserts a new row into a given table. The data need to be key(Column) value.
## This function is thread safe.
## Returns true on success.
func insert(table: String, data: Dictionary) -> bool:
	var result : bool = false
	if _DB:
		_Lock.lock()
		result = _DB.insert_row(table, data)
		_Lock.unlock()
	return result

## Inserts a new rows into a given table. The data need to be key(Column) value.
## This function is thread safe.
## Returns true on success.
func insert_rows(table: String, rows: Array[Dictionary]) -> bool:
	var result : bool = false
	if _DB:
		_Lock.lock()
		result = _DB.insert_rows(table, rows)
		_Lock.unlock()
	return result

## Updates all data which meets the condition.
## This function is thread safe.
## Returns true on success.
func update(table: String, condition: String, data: Dictionary) -> bool:
	var result : bool = false
	if _DB:
		_Lock.lock()
		result = _DB.update_rows(table, condition, data)
		_Lock.unlock()
	return result

# Deletes all data which meets the condition.
# This function is thread safe.
# Returns true on success.
func delete(table: String, condition: String) -> bool:
	var result : bool = false
	if _DB:
		_Lock.lock()
		result = _DB.delete_rows(table, condition)
		_Lock.unlock()
	return result

func get_last_insert_rowid() -> int:
	return _DB.last_insert_rowid

# ---------------------------------------------
# 				  Migration
# ---------------------------------------------

func _get_columns(table: String) -> Dictionary[String, String]:
	var result : Dictionary[String, String] = {}
	
	if _DB.query_with_bindings("pragma table_info(%s)", [table]):
		for qresult in _DB.query_result:
			result[qresult["name"]] = qresult["type"]
	return result

func _migrate() -> bool:
	var ret = false
	if _DB.query("SELECT name FROM sqlite_schema WHERE type = 'table'"):
		var results : Array[Dictionary] = _DB.query_result
		var tables : PackedStringArray = []
		for i in results.size():
			tables.append(results[i].name)
		
		if tables.find("asset_types") == -1:
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
		
		if tables.find("assets") == -1:
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

		if tables.find("directories") == -1:
			ret = _DB.query(
				"CREATE TABLE 'directories' ('id' INTEGER, 'name' TEXT NOT NULL, 'parent_id' INTEGER, FOREIGN KEY('parent_id') REFERENCES 'directories'('id') ON DELETE CASCADE, PRIMARY KEY('id' AUTOINCREMENT));"
			)
		else:
			ret = true

		if tables.find("asset_directory_rel") == -1:
			ret = _DB.query(
				"CREATE TABLE 'asset_directory_rel' ('ref_assets_id' INTEGER,'ref_directory_id'	INTEGER,PRIMARY KEY('ref_assets_id','ref_directory_id'), FOREIGN KEY('ref_directory_id') REFERENCES 'directories'('id') ON DELETE CASCADE, FOREIGN KEY('ref_assets_id') REFERENCES 'assets'('id') ON DELETE CASCADE);"
			)
		else:
			ret = true

		if tables.find("tags") == -1:
			ret = _DB.create_table("tags", {
				"id": {
					"data_type": "int",
					"primary_key": true,
					"auto_increment": true
				},
				"name": {
					"data_type": "text",
					"not_null": true
				},
				"description": {
					"data_type": "text"
				}
			})
		else:
			ret = true

		if tables.find("tag_directory_rel") == -1:
			ret = _DB.query(
				"CREATE TABLE 'tag_directory_rel' ('ref_tag_id' INTEGER, 'ref_directory_id' INTEGER, PRIMARY KEY('ref_tag_id', 'ref_directory_id'), FOREIGN KEY('ref_directory_id') REFERENCES 'directories'('id') ON DELETE CASCADE, FOREIGN KEY('ref_tag_id') REFERENCES 'tags'('id') ON DELETE CASCADE);"
			)
		else:
			ret = true

		if tables.find("tag_asset_rel") == -1:
			ret = _DB.query(
				"CREATE TABLE 'tag_asset_rel' ('ref_assets_id' INTEGER, 'ref_tag_id' INTEGER, PRIMARY KEY('ref_assets_id', 'ref_tag_id'), FOREIGN KEY('ref_assets_id') REFERENCES 'assets'('id') ON DELETE CASCADE, FOREIGN KEY('ref_tag_id') REFERENCES 'tags'('id') ON DELETE CASCADE);"
			)
		else:
			ret = true

	return ret
