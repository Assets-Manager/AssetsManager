extends MeshInstance

func create_slope(extents: Vector3) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	
	var halfExtents := extents * 0.5
	
	# Left triangle
	st.add_vertex(Vector3(-halfExtents.x, -halfExtents.y, halfExtents.z))
	st.add_vertex(Vector3(-halfExtents.x, -halfExtents.y, -halfExtents.z))
	
	st.add_vertex(Vector3(-halfExtents.x, -halfExtents.y, -halfExtents.z))
	st.add_vertex(Vector3(-halfExtents.x, halfExtents.y, -halfExtents.z))
	
	st.add_vertex(Vector3(-halfExtents.x, -halfExtents.y, halfExtents.z))
	st.add_vertex(Vector3(-halfExtents.x, halfExtents.y, -halfExtents.z))
	
	# Right triangle
	st.add_vertex(Vector3(halfExtents.x, -halfExtents.y, halfExtents.z))
	st.add_vertex(Vector3(halfExtents.x, -halfExtents.y, -halfExtents.z))
	
	st.add_vertex(Vector3(halfExtents.x, -halfExtents.y, -halfExtents.z))
	st.add_vertex(Vector3(halfExtents.x, halfExtents.y, -halfExtents.z))
	
	st.add_vertex(Vector3(halfExtents.x, -halfExtents.y, halfExtents.z))
	st.add_vertex(Vector3(halfExtents.x, halfExtents.y, -halfExtents.z))
	
	st.add_vertex(Vector3(-halfExtents.x, -halfExtents.y, -halfExtents.z))
	st.add_vertex(Vector3(halfExtents.x, -halfExtents.y, -halfExtents.z))

	st.add_vertex(Vector3(-halfExtents.x, -halfExtents.y, halfExtents.z))
	st.add_vertex(Vector3(halfExtents.x, -halfExtents.y, halfExtents.z))

	st.add_vertex(Vector3(-halfExtents.x, halfExtents.y, -halfExtents.z))
	st.add_vertex(Vector3(halfExtents.x, halfExtents.y, -halfExtents.z))
	
	mesh = st.commit()
