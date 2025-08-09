extends ScrollContainer

@export var card_size: int = 192

@onready var _FlowContainer := $CenterContainer/Cards

func _on_item_rect_changed() -> void:
	var num = max(int(size.x / card_size), 3)
	_FlowContainer.custom_minimum_size.x = num * card_size
	
	if _FlowContainer.custom_minimum_size.x >= (size.x - 50):
		_FlowContainer.custom_minimum_size.x -= card_size
	
	_FlowContainer.custom_minimum_size.y = size.y
