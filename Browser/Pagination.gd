extends HBoxContainer

signal page_update(page)

export(int) var total_pages : int = 1 setget set_total_pages
export(int) var current_page : int = 1 setget set_current_page

onready var _Page := $Page
onready var _Left := $Left
onready var _Right := $Right

func set_total_pages(value : int) -> void:
	total_pages = value
	_update_page_count()
	
func set_total_pages_without_update(value : int) -> void:
	total_pages = value
	
func set_current_page(value : int) -> void:
	current_page = value
	_update_page_count()

func _update_page_count() -> void:
	if current_page < 1:
		current_page = 1
	elif current_page > total_pages:
		current_page = total_pages
	
	if _Page:
		_Page.text = str(current_page) + " / " + str(total_pages)
		
		if current_page == total_pages:
			_Right.disabled = true
		else:
			_Right.disabled = false
			
		if current_page == 1:
			_Left.disabled = true
		else:
			_Left.disabled = false
			
		emit_signal("page_update", current_page)
		
func _ready() -> void:
	_update_page_count()

func _on_Left_pressed() -> void:
	set_current_page(current_page - 1)

func _on_Right_pressed() -> void:
	if current_page < total_pages:
		set_current_page(current_page + 1)
