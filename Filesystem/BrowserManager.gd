extends Node

signal enter_tagging_mode()
signal leave_tagging_mode()

signal card_selection_changed()
signal search_changed()

signal need_ui_refresh()
signal show_file_info_signal(asset)

var search : AMSearch
var tagging_mode: bool = false : set = _set_tagging_mode

func _set_tagging_mode(value: bool) -> void:
	if value == tagging_mode:
		return
	
	tagging_mode = value
	if tagging_mode:
		emit_signal("enter_tagging_mode")
	else:
		emit_signal("leave_tagging_mode")

## Updates the search object.
func update_search(dict : Dictionary) -> void:
	for prop in search.get_property_list():
		if ((prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE) == PROPERTY_USAGE_SCRIPT_VARIABLE) && dict.has(prop["name"]):
			search.set(prop["name"], dict[prop["name"]])
	
	emit_signal("search_changed")

func refresh_ui() -> void:
	emit_signal("need_ui_refresh")

func show_file_info(asset) -> void:
	emit_signal("show_file_info_signal", asset)

func emit_card_selection_changed() -> void:
	emit_signal("card_selection_changed")

func reset_search() -> void:
	AssetsLibrary.current_directory = 0
	search = AMSearch.new()
	search.directory_id = AssetsLibrary.current_directory

## Gets a list of all selected assets
func get_selected_assets(default) -> Array:
	var assets : Array = []
	var nodes := get_tree().get_nodes_in_group("selected_assets_cards")
	if !nodes.is_empty():
		for node in nodes:
			assets.push_back(node.asset)
	elif default:
		assets.push_back(default)
		
	return assets

## Gets all selected directories.
func get_selected_directories(dir) -> Array[AMDirectory]:
	var assets : Array[AMDirectory] = []
	var nodes := get_tree().get_nodes_in_group("selected_assets_cards")
	if !nodes.is_empty():
		for node in nodes:
			if node.asset is AMDirectory:
				assets.push_back(node.asset)
	else:
		if dir is AMDirectory:
			assets.push_back(dir)
		
	return assets
	
## Deselects all selected nodes
func deselect_all() -> void:
	var nodes := get_tree().get_nodes_in_group("selected_assets_cards")
	if !nodes.is_empty():
		get_tree().call_group("selected_assets_cards", "_change_selection_state", false)
		for node in nodes:
			node.remove_from_group("selected_assets_cards")
