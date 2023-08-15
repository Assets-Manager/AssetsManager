extends MarginContainer

signal pressed(id, is_dir)
signal delete_card(id, is_dir)
signal export_assets(id, is_dir)
signal move_to_directory_pressed(id, is_dir)
signal asset_dropped(id, dopped_id, dropped_is_dir)
signal open_containing_folder(parent_folder)

onready var _Texture := $Card/MarginContainer/VBoxContainer/TextureRect
onready var _Title := $Card/MarginContainer/VBoxContainer/Title
onready var _Animation := $AnimationPlayer
onready var _Delete := $Card/HBoxContainer/Delete
onready var _OpenFolder := $Card/HBoxContainer/OpenFolder

var id : int = 0
var is_dir : bool = false setget set_is_dir
var _ParentFolder : int = 0

func _ready() -> void:
	_OpenFolder.hide()
	
func set_parent_folder(parent_folder : int) -> void:
	_ParentFolder = parent_folder
	
	_OpenFolder.visible = _ParentFolder != 0

func set_is_dir(value : bool) -> void:
	is_dir = value
	_Delete.visible = is_dir
	mouse_default_cursor_shape = Control.CURSOR_MOVE if !is_dir else Control.CURSOR_POINTING_HAND

func set_texture(texture : Texture) -> void:
	_Texture.texture = texture

func set_title(title : String) -> void:
	_Title.text = title

func _on_Card_mouse_entered() -> void:
	if is_dir && (rect_scale == Vector2.ONE):
		_Animation.play("Hover")

func _on_Card_mouse_exited() -> void:
	if !Rect2(Vector2(), rect_size).has_point(get_local_mouse_position()):
		if is_dir:
			_Animation.play_backwards("Hover")
		else:
			_Animation.play("RESET")

func _process(_delta: float) -> void:
	if rect_scale != Vector2.ONE:
		_on_Card_mouse_exited()

func _on_Card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == BUTTON_LEFT) && !event.pressed:
			emit_signal("pressed", id, is_dir)

func _on_Delete_pressed() -> void:
	emit_signal("delete_card", id, is_dir)

func can_drop_data(_position: Vector2, data) -> bool:
	return is_dir && (data != self)

func drop_data(_position: Vector2, data) -> void:
	emit_signal("asset_dropped", id, data.id, data.is_dir)

func get_drag_data(_position: Vector2):
	var card : Control = self.duplicate()
	card.modulate.a = 0.5
	set_drag_preview(card)
	return self

func _on_Export_pressed() -> void:
	emit_signal("export_assets", id, is_dir)

func _on_OpenFolder_pressed() -> void:
	emit_signal("open_containing_folder", _ParentFolder)

func _on_Move_pressed() -> void:
	emit_signal("move_to_directory_pressed", id, is_dir)
