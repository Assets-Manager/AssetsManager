extends MeshInstance

func create_cylinder(radius : float, height : float) -> void:
	var points : PoolVector2Array
	for i in range(0, 360, 10):
		points.append(Vector2(sin(deg2rad(i)), cos(deg2rad(i))))
	
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	
	var halfHeight := height * 0.5
	
	# Bottom
	for p in range(1, points.size() + 1, 1):
		var p1 := points[wrapi(p - 1, 0, points.size())]
		var p2 := points[wrapi(p, 0, points.size())]
		
		st.add_vertex(Vector3(p1.x * radius, -halfHeight, p1.y * radius))
		st.add_vertex(Vector3(p2.x * radius, -halfHeight, p2.y * radius))
		
	# Top
	for p in range(1, points.size() + 1, 1):
		var p1 := points[wrapi(p - 1, 0, points.size())]
		var p2 := points[wrapi(p, 0, points.size())]
		
		st.add_vertex(Vector3(p1.x * radius, halfHeight, p1.y * radius))
		st.add_vertex(Vector3(p2.x * radius, halfHeight, p2.y * radius))
		
	st.add_vertex(Vector3(-radius, -halfHeight, 0))
	st.add_vertex(Vector3(-radius, halfHeight, 0))
	
	st.add_vertex(Vector3(radius, -halfHeight, 0))
	st.add_vertex(Vector3(radius, halfHeight, 0))
	
	st.add_vertex(Vector3(0, -halfHeight, -radius))
	st.add_vertex(Vector3(0, halfHeight, -radius))
	
	st.add_vertex(Vector3(0, -halfHeight, radius))
	st.add_vertex(Vector3(0, halfHeight, radius))
	
	mesh = st.commit()
