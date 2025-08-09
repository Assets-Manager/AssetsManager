extends SubViewport

@onready var _Scene := $Scene

var _PreviewDone : bool = false
var _PreviewImage : Image = null

# Copied and translated from the godot (3.5) source code.
# editor_preview_plugins.cpp EditorMeshPreviewPlugin::generate	
func _generate_sync(path: String) -> void:
	var loader := GDAssimpLoader.new()
	var scene : PackedScene = loader.load(path)
	if !scene:
		_PreviewDone = true
		return
		
	for error in loader.get_errors():
		print(error.message)
	
	var tmp := scene.instantiate()
	_Scene.add_child(tmp)
	
	var aabb: AABB = SpatialUtils.get_aabb(tmp)
	aabb.position = tmp.to_local(aabb.position)
	var offset : Vector3 = aabb.position + aabb.size * 0.5
	aabb.position -= offset
	
	var xform : Transform3D = Transform3D()
	xform.basis = Basis().rotated(Vector3(0, 1, 0), -PI * 0.125);
	xform.basis = Basis().rotated(Vector3(1, 0, 0), PI * 0.125) * xform.basis;
	var rot_aabb : AABB = xform * aabb
	var m : float = max(rot_aabb.size.x, rot_aabb.size.y) * 0.5;
	if m == 0:
		_PreviewDone = true
		return
		
	m = 1.0 / m;
	m *= 0.5;
	xform.basis = xform.basis.scaled(Vector3(m, m, m))
	xform.origin = -(xform.basis * offset)
	xform.origin.z -= rot_aabb.size.z * 2
	
	tmp.transform = xform
	render_target_update_mode = SubViewport.UPDATE_ONCE
	
	#RenderingServer.request_frame_drawn_callback(_preview_done)
	await RenderingServer.frame_post_draw
	_PreviewImage = get_texture().get_image()
	_PreviewImage.convert(Image.FORMAT_RGBA8)
	tmp.queue_free()
	
	_PreviewDone = true

func generate(path : String) -> Texture2D:
	_PreviewDone = false
	call_deferred("_generate_sync", path)
	
	# Must be called inside a thread, otherwise the whole application freezes.
	while !_PreviewDone:
		OS.delay_usec(10)
		
	if !_PreviewImage:
		return null
	
	var texture : ImageTexture = ImageTexture.create_from_image(_PreviewImage)
	_PreviewImage = null
	return texture
