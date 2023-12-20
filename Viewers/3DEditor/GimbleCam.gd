extends Spatial

export(float) var RotationSpeed = 5.0
export(int) var MaxZoom = 20
export(int) var MinZoom = 5
export(float) var ZoomSpeed = 0.9

onready var _InnerGimble = $InnerGimble
onready var _Camera = $InnerGimble/Camera

var _Rotate = false
onready var _Zoom = MinZoom

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_MIDDLE:
			_Rotate = event.pressed
		elif event.button_index == BUTTON_WHEEL_UP:
			_Zoom -= ZoomSpeed
		elif event.button_index == BUTTON_WHEEL_DOWN:
			_Zoom += ZoomSpeed
			
		_Zoom = clamp(_Zoom, MinZoom, MaxZoom)
	elif event is InputEventMouseMotion:
		if _Rotate:
			rotate_object_local(Vector3.UP, deg2rad(event.relative.x * RotationSpeed))
			_InnerGimble.rotate_object_local(Vector3(1, 0, 0), deg2rad(event.relative.y * RotationSpeed))
			_InnerGimble.rotation.x = clamp(_InnerGimble.rotation.x, -deg2rad(90), -deg2rad(0))

func _process(_delta):
	scale = lerp(scale, Vector3.ONE * _Zoom, ZoomSpeed)
