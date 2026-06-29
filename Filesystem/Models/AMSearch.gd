class_name AMSearch extends RefCounted

## Term to search for
var search_term : String = ""

## Directory to search in
var directory_id : int = 0

## Tags to search for
var tags: Array[AMTag] = []

## Authors to search for
var authors: Array[AMAuthor] = []

## Licenses to search for
var licenses: Array[AMLicense] = []

## Returns a tag id list
func get_tag_ids() -> Array[int]:
	var result: Array[int] = []
	result.append_array(tags.map(func(tag): return tag.id))
	return result

## Returns a authors id list
func get_author_ids() -> Array[int]:
	var result: Array[int] = []
	result.append_array(authors.map(func(author): return author.id))
	return result

## Returns a licenses id list
func get_licenses_ids() -> Array[int]:
	var result: Array[int] = []
	result.append_array(licenses.map(func(license): return license.id))
	return result
