extends ColorRect

var _Dragging = false
var _StartPos = Vector2i.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			size = Vector2i.ZERO
			visible = event.pressed
			_Dragging = event.pressed
			
			# Ensures the position stays in place, even if we scroll
			_StartPos = get_parent().make_canvas_position_local(event.global_position)
	elif event is InputEventMouseMotion && _Dragging:
		# Ensures the position stays in place, even if we scroll
		var endPos = get_parent().make_canvas_position_local(event.global_position)
		
		var start = _StartPos.min(endPos)
		var end = _StartPos.max(endPos)
		
		position = start
		size = end - start
		
		_select_cards()

func _select_cards() -> void:
	BrowserManager.deselect_all()
	var cards : HFlowContainer = get_parent().get_node("Cards")
	
	var ownRect := Rect2i(position, size)
	
	for card in cards.get_children():
		if card is AssetCard:
			if card.visible:
				var cardRect := Rect2i(card.position, card.size)
				if ownRect.intersects(cardRect):
					card.select()

func _draw() -> void:
	if size.x != 0 && size.y != 0:
		draw_rect(Rect2i(Vector2i.ZERO, size), Color("dc7412"), false, 2)
