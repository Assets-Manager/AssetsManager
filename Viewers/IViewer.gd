class_name IViewer
extends Control
	
# Called if a asset should be loaded.
# Must return on success.
func load_asset(asset_id : int) -> int:
	return OK

# Since the viewer is loaded at all time, we need a cleanup procedure to free memory.
func cleanup() -> void:
	pass
