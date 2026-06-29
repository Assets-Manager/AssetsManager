class_name AssetsDatabase
extends RefCounted

const LICENSES: Dictionary[String, String] = {
	"CC BY 4.0": "Creative Commons Attribution 4.0 International (CC BY 4.0)
https://creativecommons.org/licenses/by/4.0/

Assets: {{assets}}
Authors: {{authors}}

Share — copy and redistribute the material in any medium or
format for any purpose, even commercially.

Adapt — remix, transform, and build upon the material for any
purpose, even commercially.

The licensor cannot revoke these freedoms as long as you
follow the license terms.

Attribution — You must give appropriate credit, provide a link
to the license, and indicate if changes were made. You may do
so in any reasonable manner, but not in any way that suggests
the licensor endorses you or your use.

No additional restrictions — You may not apply legal terms or
technological measures that legally restrict others from doing
anything the license permits.
",
	"CC BY-SA 4.0": "Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
https://creativecommons.org/licenses/by-sa/4.0/

Assets: {{assets}}
Authors: {{authors}}

Share — copy and redistribute the material in any medium or
format for any purpose, even commercially.

Adapt — remix, transform, and build upon the material for any
purpose, even commercially.

The licensor cannot revoke these freedoms as long as you
follow the license terms.

Attribution — You must give appropriate credit, provide a link
to the license, and indicate if changes were made. You may do
so in any reasonable manner, but not in any way that suggests
the licensor endorses you or your use.

ShareAlike — If you remix, transform, or build upon the
material, you must distribute your contributions under the
same license as the original. 

No additional restrictions — You may not apply legal terms or
technological measures that legally restrict others from doing
anything the license permits.
",
	"CC BY-NC 4.0": "Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)
https://creativecommons.org/licenses/by-nc/4.0/

Assets: {{assets}}
Authors: {{authors}}

Share — copy and redistribute the material in any medium or
format

Adapt — remix, transform, and build upon the material

The licensor cannot revoke these freedoms as long as you
follow the license terms.

Attribution — You must give appropriate credit, provide a link
to the license, and indicate if changes were made. You may do
so in any reasonable manner, but not in any way that suggests
the licensor endorses you or your use.

NonCommercial — You may not use the material for 
commercial purposes.

No additional restrictions — You may not apply legal terms or
technological measures that legally restrict others from doing
anything the license permits.
",
	"CC BY-NC-SA 4.0": "Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
https://creativecommons.org/licenses/by-nc-sa/4.0/

Assets: {{assets}}
Authors: {{authors}}

Share — copy and redistribute the material in any medium or
format

Adapt — remix, transform, and build upon the material

The licensor cannot revoke these freedoms as long as you
follow the license terms.

Attribution — You must give appropriate credit, provide a link
to the license, and indicate if changes were made. You may do
so in any reasonable manner, but not in any way that suggests
the licensor endorses you or your use.

NonCommercial — You may not use the material for 
commercial purposes.

ShareAlike — If you remix, transform, or build upon the
material, you must distribute your contributions under the
same license as the original.

No additional restrictions — You may not apply legal terms or
technological measures that legally restrict others from doing
anything the license permits.
",
	"CC BY-NC-ND 4.0": "Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)
https://creativecommons.org/licenses/by-nc-nd/4.0/

Assets: {{assets}}
Authors: {{authors}}

Share — copy and redistribute the material in any medium or
format

The licensor cannot revoke these freedoms as long as you
follow the license terms.

Attribution — You must give appropriate credit, provide a link
to the license, and indicate if changes were made. You may do
so in any reasonable manner, but not in any way that suggests
the licensor endorses you or your use.

NonCommercial — You may not use the material for 
commercial purposes.

NoDerivatives — If you remix, transform, or build upon the
material, you may not distribute the modified material. 

No additional restrictions — You may not apply legal terms or
technological measures that legally restrict others from doing
anything the license permits.
",
	"CC BY-ND 4.0": "Creative Commons Attribution-NoDerivatives 4.0 International (CC BY-ND 4.0)
https://creativecommons.org/licenses/by-nd/4.0/

Assets: {{assets}}
Authors: {{authors}}

Share — copy and redistribute the material in any medium or
format for any purpose, even commercially.

The licensor cannot revoke these freedoms as long as you
follow the license terms.

Attribution — You must give appropriate credit, provide a link
to the license, and indicate if changes were made. You may do
so in any reasonable manner, but not in any way that suggests
the licensor endorses you or your use.

NoDerivatives — If you remix, transform, or build upon the
material, you may not distribute the modified material. 

No additional restrictions — You may not apply legal terms or
technological measures that legally restrict others from doing
anything the license permits.
",
	"CC0": "Creative Commons Zero CC0 1.0 Universal (CC0)
https://creativecommons.org/publicdomain/zero/1.0/

Assets: {{assets}}

The person who associated a work with this deed has
dedicated the work to the public domain by waiving all of his
or her rights to the work worldwide under copyright law,
including all related and neighboring rights, to the extent
allowed by law.

You can copy, modify, distribute and perform the work, even
for commercial purposes, all without asking permission.

In no way are the patent or trademark rights of any person
affected by CC0, nor are the rights that other persons may
have in the work or in how the work is used, such as publicity
or privacy rights.

Unless expressly stated otherwise, the person who associated
a work with this deed makes no warranties about the work,
and disclaims liability for all uses of the work, to the fullest
extent permitted by applicable law. 

When using or citing the work, you should not imply
endorsement by the author or the affirmer. 
	",
	"MIT": "The MIT License (MIT)

Assets: {{assets}}

Copyright © {{year}} {{authors}}

Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the “Software”), to deal in the Software without
restriction, including without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	",
	"WTFPL": "           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                   Version 2, December 2004

Assets: {{assets}}

Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

Everyone is permitted to copy and distribute verbatim or modified
copies of this license document, and changing it is allowed as long
as the name is changed.

           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

 0. You just DO WHAT THE FUCK YOU WANT TO.
"
}

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

## Starts a query, with parameters.
## This function is thread safe.
func query_with_bindings_with_qresult(query: String, bindings: Array) -> Array[Dictionary]:
	var result : Array[Dictionary] = []
	if _DB:
		_Lock.lock()
		if _DB.query_with_bindings(query, bindings):
			result = _DB.query_result
		else:
			print(query)
		_Lock.unlock()
		
	return result

func query_with_bindings(query: String, bindings: Array) -> bool:
	var result : bool = false
	if _DB:
		_Lock.lock()
		result = _DB.query_with_bindings(query, bindings)
		if !result:
			print(query)
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
			
		if tables.find("licenses") == -1:
			ret = _DB.query(
				"""
				CREATE TABLE 'licenses' (
					'id' INTEGER, 
					'name' TEXT NOT NULL, 
					'text' TEXT,
					PRIMARY KEY('id' AUTOINCREMENT)
					UNIQUE('name')
				);
				"""
			)
			
			if ret:
				for k in LICENSES:
					_DB.insert_row("licenses", {
						"name": k,
						"text": LICENSES[k]
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
				"""
				CREATE TABLE 'directories' (
					'id' INTEGER, 
					'name' TEXT NOT NULL, 
					'parent_id' INTEGER, 
					FOREIGN KEY('parent_id') REFERENCES 'directories'('id') ON DELETE CASCADE, 
					PRIMARY KEY('id' AUTOINCREMENT)
				);
				"""
			)
		else:
			ret = true

		if tables.find("asset_directory_rel") == -1:
			ret = _DB.query(
				"""
				CREATE TABLE 'asset_directory_rel' (
					'ref_assets_id' INTEGER,
					'ref_directory_id' INTEGER,
					PRIMARY KEY('ref_assets_id','ref_directory_id'), 
					FOREIGN KEY('ref_directory_id') REFERENCES 'directories'('id') ON DELETE CASCADE, 
					FOREIGN KEY('ref_assets_id') REFERENCES 'assets'('id') ON DELETE CASCADE
				);
				"""
			)
		else:
			ret = true

		if tables.find("asset_license_rel") == -1:
			ret = _DB.query(
				"""
				CREATE TABLE 'asset_license_rel' (
					'ref_assets_id' INTEGER,
					'ref_license_id' INTEGER,
					PRIMARY KEY('ref_assets_id','ref_license_id'), 
					FOREIGN KEY('ref_license_id') REFERENCES 'licenses'('id') ON DELETE CASCADE, 
					FOREIGN KEY('ref_assets_id') REFERENCES 'assets'('id') ON DELETE CASCADE
				);
				"""
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
				"""
				CREATE TABLE 'tag_directory_rel' (
					'ref_tag_id' INTEGER, 
					'ref_directory_id' INTEGER, 
					PRIMARY KEY('ref_tag_id', 'ref_directory_id'), 
					FOREIGN KEY('ref_directory_id') REFERENCES 'directories'('id') ON DELETE CASCADE, 
					FOREIGN KEY('ref_tag_id') REFERENCES 'tags'('id') ON DELETE CASCADE,
					UNIQUE('ref_tag_id', 'ref_directory_id')
				);
				"""
			)
		else:
			ret = true

		if tables.find("tag_asset_rel") == -1:
			ret = _DB.query(
				"""
				CREATE TABLE 'tag_asset_rel' (
					'ref_assets_id' INTEGER, 
					'ref_tag_id' INTEGER, 
					PRIMARY KEY('ref_assets_id', 'ref_tag_id'), 
					FOREIGN KEY('ref_assets_id') REFERENCES 'assets'('id') ON DELETE CASCADE, 
					FOREIGN KEY('ref_tag_id') REFERENCES 'tags'('id') ON DELETE CASCADE,
					UNIQUE('ref_assets_id', 'ref_tag_id')
				);
				"""
			)
		else:
			ret = true
			
		if tables.find("authors") == -1:
			ret = _DB.query(
				"""
				CREATE TABLE 'authors' (
					'id' INTEGER, 
					'name' TEXT NOT NULL,
					PRIMARY KEY('id' AUTOINCREMENT),
					UNIQUE('name')
				)
				"""
			)
		else:
			ret = true
			
		if tables.find("authors_assets_rel") == -1:
			ret = _DB.query(
				"""
				CREATE TABLE 'authors_assets_rel' (
					'ref_assets_id' INTEGER, 
					'ref_authors_id' INTEGER, 
					PRIMARY KEY('ref_assets_id', 'ref_authors_id'), 
					FOREIGN KEY('ref_assets_id') REFERENCES 'assets'('id') ON DELETE CASCADE, 
					FOREIGN KEY('ref_authors_id') REFERENCES 'authors'('id') ON DELETE CASCADE,
					UNIQUE('ref_assets_id', 'ref_authors_id')
				)
				"""
			)
		else:
			ret = true

	return ret
