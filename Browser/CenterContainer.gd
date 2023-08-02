extends ScrollContainer

export(int) var card_size : int = 192

onready var _FlowContainer := $CenterContainer/Cards

func _on_item_rect_changed() -> void:
	var num = max(int(rect_size.x / card_size), 3)
	_FlowContainer.rect_min_size.x = num * card_size
