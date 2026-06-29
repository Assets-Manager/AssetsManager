class_name Mustache extends RefCounted

var template: String = ""
var _SyntaxRe = RegEx.create_from_string("\\{{2,3}((?!{|}).*?)\\}{2,3}")

func generate(context: Variant) -> String:
	var compiledTemplate := _compileTemplate()
	return _execTemplate(compiledTemplate, context)

func _execTemplate(compiledTemplate: Array, context: Variant, start = 0) -> String:
	var result = ""
	for i in range(start, compiledTemplate.size()):
		var part = compiledTemplate[i]
		if part is String:
			result += part
		elif part is RegExMatch:
			var variable = part.get_string(1).trim_prefix(" ").trim_suffix(" ")
			if variable.begins_with("#"): # Condition or list
				var value = _getValue(variable.replace("#", "").trim_suffix(" "), context)
				if value is bool || (value is String && (value == "true" || value == "false")):
					if (value is bool && value) || (value is String && value == "true"):
						result += _execTemplate(compiledTemplate, context, i + 1)
				elif value is Dictionary || value is Object:
					result += _execTemplate(compiledTemplate, value, i + 1)
				elif value is Array:
					for c in value:
						result += _execTemplate(compiledTemplate, c, i + 1)

				break
			else:
				result += _parseVariable(part, context)
		elif part is Array:
			result += _execTemplate(part, context)
		
	return result

func _compileTemplate() -> Array:
	var result: Array = []
	var blocks: Array[Array] = [result]
	
	var from_pos = 0
	var matches := _SyntaxRe.search_all(template)
	for syntax in matches:
		if syntax.get_start() != from_pos:
			blocks.back().push_back(template.substr(from_pos, syntax.get_start() - from_pos))
		from_pos = syntax.get_end()
			
		var variable = syntax.get_string(1).trim_prefix(" ").trim_suffix(" ")
		if variable.begins_with("!"): # Comment
			continue
		elif variable.begins_with("#") || variable.begins_with("^"): # Condition or list
			blocks.push_back([syntax])
		elif variable.begins_with("/"): # End of block
			if blocks.is_empty():
				return []
			var block = blocks.back()
			blocks.pop_back()
			if blocks.is_empty():
				return []
				
			blocks.back().push_back(block)
		else:
			blocks.back().push_back(syntax)
	
	if from_pos != template.length():
		result.push_back(template.substr(from_pos))
	
	return result

## Gets a field from a given context or an empty string, if the field doesn't exists
func _getValue(variable: String, context: Variant) -> Variant:
	var fields = variable.split(".")
	for field in fields:
		if context is Dictionary:
			if context.has(field):
				context = context[field]
			else:
				context = null
				break
		elif context is Object:
			var value = context.get(field)
			if value:
				context = value
			else:
				context = null
				break
	return str(context) if context != null else ""

## HTML encodes a given value
func _encode(value: String) -> String:
	return value.replace("&", "&amp;") \
	.replace("<", "&lt;") \
	.replace(">", "&gt;") \
	.replace("\"", "&quot;") \
	.replace("'", "&#39;")

func _parseVariable(variable: RegExMatch, context: Variant) -> String:
	var capture = variable.get_string()
	var value = _getValue(variable.get_string(1).replace("&", "").trim_prefix(" ").trim_suffix(" "), context)
	if capture.contains("&") || capture.begins_with("{{{"):
		return value
		
	return _encode(value)
	
