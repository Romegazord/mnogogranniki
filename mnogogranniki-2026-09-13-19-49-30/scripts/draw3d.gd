extends Node


func point(pos:Vector3, radius:float = 0.05, color:Color = Color.ALICE_BLUE) -> MeshInstance3D:
	var meshInstance = MeshInstance3D.new()
	var sphereMesh = SphereMesh.new()
	var material = ORMMaterial3D.new()
	
	meshInstance.position = pos
	meshInstance.cast_shadow = false
	meshInstance.mesh = sphereMesh
	
	sphereMesh.radius = radius
	sphereMesh.height = radius*2
	sphereMesh.material = material
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	get_tree().get_root().get_node("Main").add_child(meshInstance)
	
	return meshInstance

func line(orig:Vector3,dest:Vector3,color:Color = Color.ALICE_BLUE) -> MeshInstance3D:
	var meshInstance = MeshInstance3D.new()
	var immediateMesh = ImmediateMesh.new()
	var material = ORMMaterial3D.new()
	
	meshInstance.cast_shadow = false
	meshInstance.mesh = immediateMesh
	
	var dir = (dest-orig).normalized()
	
	immediateMesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediateMesh.surface_add_vertex(orig-dir*1000)
	immediateMesh.surface_add_vertex(dest+dir*1000)
	immediateMesh.surface_end()
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	meshInstance.set_meta("p1", orig)
	meshInstance.set_meta("p2", dest)
	
	get_tree().get_root().get_node("Main").add_child(meshInstance)
	
	return meshInstance

func edge(orig:Vector3,dest:Vector3,color:Color = Color.ALICE_BLUE) -> MeshInstance3D:
	var meshInstance = MeshInstance3D.new()
	var immediateMesh = ImmediateMesh.new()
	var material = ORMMaterial3D.new()
	
	meshInstance.cast_shadow = false
	meshInstance.mesh = immediateMesh
	
	immediateMesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediateMesh.surface_add_vertex(orig)
	immediateMesh.surface_add_vertex(dest)
	immediateMesh.surface_end()
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	meshInstance.set_meta("p1", orig)
	meshInstance.set_meta("p2", dest)
	
	return meshInstance
	
func plane(orig:Vector3,dest:Vector3,right:Vector3,color:Color = Color.ALICE_BLUE) -> MeshInstance3D:
	var meshInstance = MeshInstance3D.new()
	var immediateMesh = ImmediateMesh.new()
	var material = ShaderMaterial.new()
	var shader = load("res://shaders/plane.gdshader")
	
	meshInstance.cast_shadow = false
	meshInstance.mesh = immediateMesh
	
	var triangleCenter = (orig+dest+right)/3

	immediateMesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	immediateMesh.surface_add_vertex(orig+(orig-triangleCenter)*1000)
	immediateMesh.surface_add_vertex(dest+(dest-triangleCenter)*1000)
	immediateMesh.surface_add_vertex(right+(right-triangleCenter)*1000)
	immediateMesh.surface_end()

	material.shader = shader
	material.set_shader_parameter("color", color)
	
	get_tree().get_root().get_node("Main").add_child(meshInstance)
	
	return meshInstance

func polyhedron(points, edges):
	var model = Node3D.new()
	get_tree().root.get_node("Main/Polyhedrons").add_child(model)
	for e in edges:
		var drawn_edge = edge(points[e[0]],points[e[1]])
		model.add_child(drawn_edge)

func sort_clockwise(points: Array) -> Array[Vector3]:
	if points.size() < 3:
		return points # Нечего сортировать
		
	# 1. Считаем центр масс
	var center = Vector3.ZERO
	for p in points:
		center += p
	center /= points.size()
	
	# 2. Находим нормаль плоскости по первым трем точкам
	var n: Vector3 = (points[1] - points[0]).cross(points[2] - points[0])
	
	# 3. Находим ось с максимальной проекцией (используем абсолютные значения abs)
	var axis = 0
	var max_val = abs(n.x)
	if abs(n.y) > max_val:
		max_val = abs(n.y)
		axis = 1
	if abs(n.z) > max_val:
		axis = 2
		
	# 4. Определяем 2D-координаты для проекции
	var local_x = (axis + 1) % 3
	var local_y = (axis + 2) % 3
	
	# Изменяем знак в зависимости от направления нормали, 
	# чтобы "смотреть" на полигон всегда с лицевой стороны
	var invert_sign = 1.0 if n[axis] >= 0 else -1.0
	
	# 5. Сортируем массив на месте (in-place)
	points.sort_custom(func(a: Vector3, b: Vector3):
		var angle_a = atan2((a[local_y] - center[local_y]) * invert_sign, a[local_x] - center[local_x])
		var angle_b = atan2((b[local_y] - center[local_y]) * invert_sign, b[local_x] - center[local_x])
		
		# Знак > гарантирует обход ПО часовой стрелке
		return angle_a > angle_b
	)
	
	return points
	
func polygon(points, color:Color = Color.ALICE_BLUE) -> MeshInstance3D:
	var meshInstance = MeshInstance3D.new()
	var immediateMesh = ImmediateMesh.new()
	var material = ShaderMaterial.new()
	var shader = load("res://shaders/plane.gdshader")
	
	points = sort_clockwise(points)
	
	meshInstance.cast_shadow = false
	meshInstance.mesh = immediateMesh
	
	for i in range(1, len(points)-1):
		immediateMesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
		immediateMesh.surface_add_vertex(points[0])
		immediateMesh.surface_add_vertex(points[i])
		immediateMesh.surface_add_vertex(points[i+1])
		immediateMesh.surface_end()
		
	material.shader = shader
	material.set_shader_parameter("color", color)
	
	return meshInstance
