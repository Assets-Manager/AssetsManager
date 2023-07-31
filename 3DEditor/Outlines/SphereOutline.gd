extends MeshInstance

func create_sphere(radius : float) -> void:
	var points : PoolVector2Array
	for i in range(0, 360, 10):
		points.append(Vector2(sin(deg2rad(i)), cos(deg2rad(i))))
	
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
		
	for p in range(1, points.size() + 1, 1):
		var p1 := points[wrapi(p - 1, 0, points.size())]
		var p2 := points[wrapi(p, 0, points.size())]
		
		st.add_vertex(Vector3(p1.x * radius, p1.y * radius, 0))
		st.add_vertex(Vector3(p2.x * radius, p2.y * radius, 0))
		
	for p in range(1, points.size() + 1, 1):
		var p1 := points[wrapi(p - 1, 0, points.size())]
		var p2 := points[wrapi(p, 0, points.size())]
		
		st.add_vertex(Vector3(p1.x * radius, 0, p1.y * radius))
		st.add_vertex(Vector3(p2.x * radius, 0, p2.y * radius))
		
	for p in range(1, points.size() + 1, 1):
		var p1 := points[wrapi(p - 1, 0, points.size())]
		var p2 := points[wrapi(p, 0, points.size())]
		
		st.add_vertex(Vector3(0, p1.x * radius, p1.y * radius))
		st.add_vertex(Vector3(0, p2.x * radius, p2.y * radius))
		
	mesh = st.commit()
