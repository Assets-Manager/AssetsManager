extends MarginContainer

@onready var _Tags := $VBoxContainer/ItemList
@onready var _Authors := $VBoxContainer/Authors
@onready var _Licenses := $VBoxContainer/Licenses

func _ready() -> void:
	var tags : Array[AMTag] = AssetsLibrary.get_all_tags()
	var selectedTags := BrowserManager.search.tags
	for tag in tags:
		_Tags.add_item(tag.name)
		_Tags.set_item_tooltip(_Tags.item_count - 1, tag.description)
		_Tags.set_item_metadata(_Tags.item_count - 1, tag)
		
		for t in selectedTags:
			if t.id == tag.id:
				_Tags.select(_Tags.item_count - 1, false)
				break

func _on_clear_pressed() -> void:
	_Tags.deselect_all()
	_Authors.chips.clear()
	var tags : Array[AMTag] = []
	var authors : Array[AMAuthor] = []
	var licenses : Array[AMLicense] = []
	BrowserManager.update_search({"tags": tags, "authors": authors, "licenses": licenses})

func _on_item_list_multi_selected(_index: int, _selected: bool) -> void:
	var tags : Array[AMTag] = []
	for idx in _Tags.get_selected_items():
		tags.push_back(_Tags.get_item_metadata(idx))
	BrowserManager.update_search({"tags": tags})

func _on_authors_changed() -> void:
	var authors : Array[AMAuthor] = []
	authors.append_array(_Authors.chips.get_chips().map(func(chip): return chip.value))
	BrowserManager.update_search({"authors": authors})

func _on_licenses_changed() -> void:
	var licenses : Array[AMLicense] = []
	licenses.append_array(_Licenses.chips.get_chips().map(func(chip): return chip.value))
	BrowserManager.update_search({"licenses": licenses})
