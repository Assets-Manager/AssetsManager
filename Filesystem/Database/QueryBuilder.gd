class_name QueryBuilder extends RefCounted

enum QueryMode
{
	NONE,
	SELECT,
	INSERT,
	DELETE
}

class Expr extends RefCounted:
	enum ExprType {
		WHERE,
		LEFT_JOIN
	}
	
	var _Query: QueryBuilder
	var _Expr: String = ""
	var _Alias: String = ""
	var _Type: ExprType
	var _Additional: String = ""
	
	func _init(query: QueryBuilder, additional: String, alias: String, type: ExprType) -> void:
		_Query = query
		_Additional = additional
		_Alias = alias
		_Type = type
		
	func in_expr(field: String, list: Array) -> Expr:
		var string_list = ""
		for l in list:
			if !string_list.is_empty():
				string_list += ","
			
			if (l is float) || (l is int):
				string_list += str(l)
			else:
				string_list += l
		
		_Expr += "%s IN (%s)" % [field, string_list]
		return self
		
	func bin_op_expr(field: String, operator: String, value: Variant = null) -> Expr:
		if !value:
			_Expr += "%s %s ?" % [field, operator]
		else:
			_Expr += "%s %s %s" % [field, operator, value]
		
		return self
		
	func and_expr() -> Expr:
		if !_Expr.is_empty():
			_Expr += " AND "
		
		return self
		
	func or_expr() -> Expr:
		if !_Expr.is_empty():
			_Expr += " OR "
		
		return self
		
	func like_expr(field: String, value: String = "") -> Expr:
		if value.is_empty():
			_Expr += "%s LIKE ?" % [field]
		else:
			_Expr += "%s LIKE \"%s\"" % [field, value]
		
		return self
		
	func build() -> QueryBuilder:
		match _Type:
			ExprType.WHERE:
				_Query._Where = _Expr
				
			ExprType.LEFT_JOIN:
				_Query._Joins.push_back("LEFT JOIN %s %s ON (%s)" % [_Additional, _Alias, _Expr])
		
		return _Query

var _Table : String = ""
var _Alias : String = ""
var _Fields: PackedStringArray = []
var _Joins: PackedStringArray = []
var _WhereExpr: Expr = null
var _Where: String = ""
var _Values: String = ""
var _InsertOrIgnore = false

var _Mode : QueryMode = QueryMode.NONE

func _init(table: String, alias: String = "") -> void:
	_Table = table
	_Alias = alias
	
## Defines the fields to select.
## - [param fields] Fields or a single field to select.
func select(fields: Variant) -> QueryBuilder:
	if _Mode != QueryMode.NONE:
		printerr("Query is already setuped")
		return self
	
	_Mode = QueryMode.SELECT
	if fields is Array:
		for i in range(fields.size()):
			var field : String = fields[i]
			fields[i] = field
		
		_Fields = fields
	elif fields is String:
		_Fields = [fields]
		
	return self

## Defines the fields to insert
func insert(fields: PackedStringArray, insert_or_ignore: bool = false) -> QueryBuilder:
	if _Mode != QueryMode.NONE:
		printerr("Query is already setuped")
		return self
	
	_Mode = QueryMode.INSERT
	_Fields = fields
	_InsertOrIgnore = insert_or_ignore
	
	return self
	
func delete() -> QueryBuilder:
	if _Mode != QueryMode.NONE:
		printerr("Query is already setuped")
		return self
	
	_Mode = QueryMode.DELETE
	return self
	
func add_value(values: PackedStringArray) -> QueryBuilder:
	if _Mode != QueryMode.INSERT:
		printerr("Not in insert mode")
		return self
	
	if !_Values.is_empty():
		_Values += ","
	
	_Values += "(%s)" % ",".join(values)
	
	return self

func left_join(table: String, alias: String) -> Expr:
	return Expr.new(self, table, alias, Expr.ExprType.LEFT_JOIN)

func where() -> Expr:
	if !_WhereExpr:
		_WhereExpr = Expr.new(self, "", _Alias, Expr.ExprType.WHERE)
		
	return _WhereExpr

func build() -> String:
	var stmt : String
	match _Mode:
		QueryMode.SELECT:
			stmt = "SELECT %s FROM %s %s %s " % [",".join(_Fields) if !_Fields.is_empty() else "*", _Table, _Alias, "\n".join(_Joins) if !_Joins.is_empty() else ""]
			if _WhereExpr:
				_WhereExpr.build()
				_WhereExpr = null
			
			if !_Where.is_empty():
				stmt += " WHERE " + _Where
		
		QueryMode.INSERT:
			stmt = "INSERT %s INTO %s (%s) VALUES %s" % ["OR IGNORE" if _InsertOrIgnore else "", _Table, ",".join(_Fields), _Values]
	
		QueryMode.DELETE:
			stmt = "DELETE FROM %s" % _Table
			
			if _WhereExpr:
				_WhereExpr.build()
				_WhereExpr = null
			
			if !_Where.is_empty():
				stmt += " WHERE " + _Where
	
	_Values = ""
	_Where = ""
	_Fields = []
	_Mode = QueryMode.NONE
	return stmt
