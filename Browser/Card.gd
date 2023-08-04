extends MarginContainer

signal pressed(id, is_dir)

onready var _Texture := $Card/MarginContainer/VBoxContainer/TextureRect
onready var _Title := $Card/MarginContainer/VBoxContainer/Title
onready var _Animation := $AnimationPlayer

var id : int = 0
var is_dir : bool = false

func set_texture(texture : Texture) -> void:
	_Texture.texture = texture

func set_title(title : String) -> void:
	_Title.text = title

func _on_Card_mouse_entered() -> void:
	_Animation.play("Hover")

func _on_Card_mouse_exited() -> void:
	_Animation.play_backwards("Hover")

func _on_Card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == BUTTON_LEFT) && event.pressed:
			emit_signal("pressed", id, is_dir)
