extends Node

## Gets a list of all selected datasets
func get_selected_datasets(default) -> Array:
	var datasets : Array = []
	var nodes := get_tree().get_nodes_in_group("selected_assets_cards")
	if !nodes.is_empty():
		for node in nodes:
			datasets.push_back(node.dataset)
	else:
		datasets.push_back(default)
		
	return datasets

## Gets all selected directories.
func get_selected_directories(dir) -> Array:
	var datasets : Array = []
	var nodes := get_tree().get_nodes_in_group("selected_assets_cards")
	if !nodes.is_empty():
		for node in nodes:
			if node.dataset is AMDirectory:
				datasets.push_back(node.dataset)
	else:
		if dir is AMDirectory:
			datasets.push_back(dir)
		
	return datasets
	
## Deselects all selected nodes
func deselect_all() -> void:
	var nodes := get_tree().get_nodes_in_group("selected_assets_cards")
	if !nodes.is_empty():
		get_tree().call_group("selected_assets_cards", "_change_selection_state", false)
		for node in nodes:
			node.remove_from_group("selected_assets_cards")
