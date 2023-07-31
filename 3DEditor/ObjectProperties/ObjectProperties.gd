extends TabContainer

signal transform_changed(node)
signal origin_changed(node)

onready var _Transform := $Transform
onready var _Collision := $Collision

func set_node(node : Spatial) -> void:
	_Transform.set_node(node)
	_Collision.set_node(node)

func _on_Transform_transform_changed(node) -> void:
	emit_signal("transform_changed", node)

func _on_Transform_origin_changed(node) -> void:
	emit_signal("origin_changed", node)
