class_name OriginView
extends Spatial

enum OriginPoint {
	CENTER,
	TOP_LEFT_FRONT,
	TOP_RIGHT_FRONT,
	BOTTOM_LEFT_FRONT,
	BOTTOM_RIGHT_FRONT,
	TOP_LEFT_BACK,
	TOP_RIGHT_BACK,
	BOTTOM_LEFT_BACK,
	BOTTOM_RIGHT_BACK,
	TOP_CENTER,
	BOTTOM_CENTER,
	LEFT_CENTER,
	RIGHT_CENTER,
	BACK_CENTER,
	FRONT_CENTER
}

onready var _OriginPoints = {
	OriginPoint.CENTER:	$Center,
	OriginPoint.TOP_LEFT_FRONT: $TopLeftFront,
	OriginPoint.TOP_RIGHT_FRONT: $TopRightFront,
	OriginPoint.BOTTOM_LEFT_FRONT: $BottomLeftFront,
	OriginPoint.BOTTOM_RIGHT_FRONT: $BottomRightFront,
	OriginPoint.TOP_LEFT_BACK: $TopLeftBack,
	OriginPoint.TOP_RIGHT_BACK: $TopRightBack,
	OriginPoint.BOTTOM_LEFT_BACK: $BottomLeftBack,
	OriginPoint.BOTTOM_RIGHT_BACK: $BottomRightBack,
	
	OriginPoint.TOP_CENTER: $TopCenter,
	OriginPoint.BOTTOM_CENTER: $BottomCenter,
	OriginPoint.LEFT_CENTER: $LeftCenter,
	OriginPoint.RIGHT_CENTER: $RightCenter,
	OriginPoint.BACK_CENTER: $BackCenter,
	OriginPoint.FRONT_CENTER: $FrontCenter,
}

signal origin_point_pressed(point)

func _ready() -> void:
	for origin in _OriginPoints:
		_OriginPoints[origin].connect("pressed", self, "_pressed", [origin])

func _pressed(origin: int) -> void:
	emit_signal("origin_point_pressed", origin)
