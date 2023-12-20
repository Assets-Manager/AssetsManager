extends MeshInstance

func create_cube(size : Vector3) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	
	var halfSize := size * 0.5
	
	# Bottom Quad
	st.add_vertex(-halfSize)
	st.add_vertex(Vector3(halfSize.x, -halfSize.y, -halfSize.z))
	
	st.add_vertex(Vector3(-halfSize.x, -halfSize.y, halfSize.z))
	st.add_vertex(Vector3(halfSize.x, -halfSize.y, halfSize.z))
	
	st.add_vertex(Vector3(-halfSize.x, -halfSize.y, -halfSize.z))
	st.add_vertex(Vector3(-halfSize.x, -halfSize.y, halfSize.z))
	
	st.add_vertex(Vector3(halfSize.x, -halfSize.y, -halfSize.z))
	st.add_vertex(Vector3(halfSize.x, -halfSize.y, halfSize.z))
	
	# Top Quad
	st.add_vertex(Vector3(-halfSize.x, halfSize.y, -halfSize.z))
	st.add_vertex(Vector3(halfSize.x, halfSize.y, -halfSize.z))
	
	st.add_vertex(Vector3(-halfSize.x, halfSize.y, halfSize.z))
	st.add_vertex(Vector3(halfSize.x, halfSize.y, halfSize.z))
	
	st.add_vertex(Vector3(-halfSize.x, halfSize.y, -halfSize.z))
	st.add_vertex(Vector3(-halfSize.x, halfSize.y, halfSize.z))
	
	st.add_vertex(Vector3(halfSize.x, halfSize.y, -halfSize.z))
	st.add_vertex(Vector3(halfSize.x, halfSize.y, halfSize.z))
	
	# Sides
	
	st.add_vertex(Vector3(-halfSize.x, -halfSize.y, -halfSize.z))
	st.add_vertex(Vector3(-halfSize.x, halfSize.y, -halfSize.z))
	
	st.add_vertex(Vector3(halfSize.x, -halfSize.y, -halfSize.z))
	st.add_vertex(Vector3(halfSize.x, halfSize.y, -halfSize.z))
	
	st.add_vertex(Vector3(-halfSize.x, -halfSize.y, halfSize.z))
	st.add_vertex(Vector3(-halfSize.x, halfSize.y, halfSize.z))
	
	st.add_vertex(Vector3(halfSize.x, -halfSize.y, halfSize.z))
	st.add_vertex(Vector3(halfSize.x, halfSize.y, halfSize.z))
	
	mesh = st.commit()
