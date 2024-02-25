extends Viewport

onready var _Scene := $Scene

var _PreviewDone : bool = false

func _preview_done(_unused) -> void:
	_PreviewDone = true

# Copied and translated from the godot source code.
# editor_preview_plugins.cpp EditorMeshPreviewPlugin::generate
# Must be called inside a thread, otherwise the whole application freezes.
func generate(path : String) -> Texture:
	var loader := GDAssimpLoader.new()
	var scene : PackedScene = loader.load(path)
	if !scene:
		return null
		
	for error in loader.get_errors():
		print(error)
	
	var tmp := scene.instance()
	_Scene.add_child(tmp)
	
	var aabb: AABB = SpatialUtils.get_aabb(tmp)
	aabb.position = tmp.to_local(aabb.position)
	var offset : Vector3 = aabb.position + aabb.size * 0.5
	aabb.position -= offset
	
	var xform : Transform = Transform()
	xform.basis = Basis().rotated(Vector3(0, 1, 0), -PI * 0.125);
	xform.basis = Basis().rotated(Vector3(1, 0, 0), PI * 0.125) * xform.basis;
	var rot_aabb : AABB = xform.xform(aabb)
	var m : float = max(rot_aabb.size.x, rot_aabb.size.y) * 0.5;
	if m == 0:
		return null
		
	m = 1.0 / m;
	m *= 0.5;
	xform.basis = xform.basis.scaled(Vector3(m, m, m))
	xform.origin = -xform.basis.xform(offset)
	xform.origin.z -= rot_aabb.size.z * 2
	
	tmp.transform = xform
	render_target_update_mode = Viewport.UPDATE_ONCE
	
	_PreviewDone = false
	VisualServer.request_frame_drawn_callback(self, "_preview_done", null)
	
	while !_PreviewDone:
		OS.delay_usec(10)
		
	var preview : Image = get_texture().get_data()
	preview.convert(Image.FORMAT_RGBA8)
	
	var texture : ImageTexture = ImageTexture.new()
	texture.create_from_image(preview, 0)
	
	tmp.queue_free()
	return texture
