class_name AMSearch extends RefCounted

## Term to search for
var search_term : String = ""

## Directory to search in
var directory_id : int = 0

## Tags to search for
var tags: Array[AMTag] = []

## Returns a tag id list as string
func get_tag_ids() -> String:
	var result = ""
	for tag in tags:
		if !result.is_empty():
			result += ","
		result += str(tag.id)
	
	return result
