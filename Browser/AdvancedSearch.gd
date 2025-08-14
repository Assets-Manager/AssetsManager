extends MarginContainer

@onready var _Tags := $VBoxContainer/ItemList

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

func _on_item_list_multi_selected(_index: int, _selected: bool) -> void:
	var tags : Array[AMTag] = []
	for idx in _Tags.get_selected_items():
		tags.push_back(_Tags.get_item_metadata(idx))
	BrowserManager.update_search({"tags": tags})
