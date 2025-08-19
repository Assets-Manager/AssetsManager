extends ScrollContainer

@export var card_size: int = 192

@onready var _FlowContainer := $Panel/Cards
@onready var _Panel := $Panel

func _on_cards_item_rect_changed() -> void:
	_Panel.custom_minimum_size.y = _FlowContainer.size.y

func _on_browser_change_dir() -> void:
	_Panel.custom_minimum_size.y = size.y
