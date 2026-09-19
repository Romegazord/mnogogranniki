extends Node

var camera:Camera3D

var _camera_center = Vector3.ZERO
var _yaw = 0.0
var _pitch = 0.0
var _zoom_amount = 0.0
var lock_rotation = false
var lock_movement = false
var lock_zoom = false
var _cut_start
var _cut_triangle_points = []
var _intersect_lines_points = []
var _line_middle_points = []
var selected_polyhedrons = []

var line_material = ORMMaterial3D.new()
func _ready() -> void:
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.albedo_color = Color.DIM_GRAY

func intersect_lines_on_touch(mouse_position):
	var points = []
	for p in selected_polyhedrons:
		if not is_instance_valid(p): 
			continue
		points.append_array(p.get_node("Points").get_children())
	var selected_point = _get_clicked_point(mouse_position,points)
	var parent_polyhedron
	if selected_point and not selected_point in _intersect_lines_points:
		parent_polyhedron = selected_point.get_parent().get_parent()

		var pos = selected_point.position
		selected_point.queue_free()
		var highlight = Draw3d.point(parent_polyhedron,pos, 0.06)
		_intersect_lines_points.append(highlight)
	if len(_intersect_lines_points) >=4:
		for point in _intersect_lines_points:
			var pos = point.position
			point.queue_free()
			Draw3d.point(parent_polyhedron,pos)
		var p1 = _intersect_lines_points[0].position
		var p2 = _intersect_lines_points[1].position
		var p3 = _intersect_lines_points[2].position
		var p4 = _intersect_lines_points[3].position
		var intersection = _find_line_intersection_3d(p1,p2,p3,p4)
		if intersection and intersection.status != "skew":
			var is_unique = true
			for point in parent_polyhedron.get_node("Points").get_children():
				if intersection.point == point.position:
					is_unique = false
					break
			if is_unique:
				Draw3d.point(parent_polyhedron, intersection.point)

			Draw3d.selected_material = line_material
			Draw3d.line(parent_polyhedron, p1,p2)
			Draw3d.line(parent_polyhedron, p3,p4)
			Draw3d.selected_material = Draw3d.DEFAULT_MATERIAL
		_intersect_lines_points.clear()
func intersect_lines_on_unpick():
	for i in range(len(_intersect_lines_points)):
		var parent_polyhedron = _intersect_lines_points[i].get_parent().get_parent()
		var pos = _intersect_lines_points[i].position
		_intersect_lines_points[i].queue_free()
		Draw3d.point(parent_polyhedron,pos)
	_intersect_lines_points.clear()



func select_polyhedron_on_touch(mouse_position):
	var line
	var polyhedron
	for p in get_tree().root.get_node("Main/Polyhedrons").get_children():
		line = _get_clicked_line(mouse_position, p.get_node("Edges").get_children())
		if line: 
			polyhedron = line.get_parent().get_parent()
			break
	if polyhedron:
		if polyhedron in selected_polyhedrons:
			polyhedron.get_meta("material").albedo_color = Color.GRAY
			selected_polyhedrons.remove_at(selected_polyhedrons.find(polyhedron))
		else:
			polyhedron.get_meta("material").albedo_color = Color.ALICE_BLUE
			selected_polyhedrons.append(polyhedron)

func remove_polyhedron_on_touch(mouse_position):
	var line
	var polyhedron
	for p in get_tree().root.get_node("Main/Polyhedrons").get_children():
		line = _get_clicked_line(mouse_position, p.get_node("Edges").get_children())
		if line: 
			polyhedron = line.get_parent().get_parent()
			break
	if polyhedron:
		
		polyhedron.queue_free()

func remove_point_on_touch(mouse_position):
	var points = []
	for p in selected_polyhedrons:
		if not is_instance_valid(p): 
			continue
		points.append_array(p.get_node("Points").get_children())
	var point = _get_clicked_point(mouse_position, points)
	if point: point.queue_free()

func cut_triangle_on_touch(mouse_position):
	var points = []
	for p in selected_polyhedrons:
		if not is_instance_valid(p): 
			continue
		points.append_array(p.get_node("Points").get_children())
	var selected_point = _get_clicked_point(mouse_position,points)
	var parent_polyhedron
	if selected_point and not selected_point in _cut_triangle_points:
		parent_polyhedron = selected_point.get_parent().get_parent()

		var pos = selected_point.position
		selected_point.queue_free()
		var highlight = Draw3d.point(parent_polyhedron,pos, 0.06)
		_cut_triangle_points.append(highlight)
		print(_cut_triangle_points,len(_cut_triangle_points))
			
	if len(_cut_triangle_points)>=3:

		var intersection_points = []
		var p1 = _cut_triangle_points[0].position
		var p2 = _cut_triangle_points[1].position
		var p3 = _cut_triangle_points[2].position
		
		for point in _cut_triangle_points:
			var pos = point.position
			point.queue_free()
			Draw3d.point(parent_polyhedron,pos)
		for e in parent_polyhedron.get_node("Edges").get_children():
			var intersection = _find_line_plane_intersection(e.get_meta("p1"),e.get_meta("p2"), p1, p2, p3,true)
			if not intersection:
				continue
			var is_unique = true
			for point in parent_polyhedron.get_node("Points").get_children():
				if intersection == point.position:
					is_unique = false
					break
			if is_unique:
				var point = Draw3d.point(parent_polyhedron,intersection)
			intersection_points.append(intersection)
		var polygon = Draw3d.polygon(parent_polyhedron,intersection_points)
		polygon.name = "polygon"
		get_tree().root.get_node("Main").add_child(polygon)
		_cut_triangle_points.clear()
func cut_triangle_on_unpick():
	for i in range(len(_cut_triangle_points)):
		var parent_polyhedron = _cut_triangle_points[i].get_parent().get_parent()
		var pos = _cut_triangle_points[i].position
		_cut_triangle_points[i].queue_free()
		Draw3d.point(parent_polyhedron,pos)
	_cut_triangle_points.clear()

func cut_on_touch(mouse_position):
	var selected_point = _get_clicked_point(mouse_position,get_node("/root/Main/Points").get_children())
	if selected_point:
		_cut_start = selected_point.position
		return
	var uv = _get_uv(mouse_position)
	_cut_start = camera.position+(Vector3(-uv.x*tan(deg_to_rad(camera.fov))*camera.get_camera_projection().get_aspect(), -uv.y*tan(deg_to_rad(camera.fov)), 4.9).rotated(Vector3.UP, _yaw).rotated(Vector3.RIGHT.rotated(Vector3.UP,_yaw), _pitch))

func cut_on_release(mouse_position):
		var selected_point = _get_clicked_point(mouse_position,get_node("/root/Main/Points").get_children())
		var uv = _get_uv(mouse_position)
		var Point2 = camera.position+(Vector3(-uv.x*tan(deg_to_rad(camera.fov))*camera.get_camera_projection().get_aspect(), -uv.y*tan(deg_to_rad(camera.fov)), 4.9).rotated(Vector3.UP, _yaw).rotated(Vector3.RIGHT.rotated(Vector3.UP,_yaw), _pitch))
		var Point3 = camera.position
		if selected_point:
			Point2 = selected_point.position

		for p in selected_polyhedrons:
			if not is_instance_valid(p): 
				continue
			var intersection_points = []
			for e in p.get_node("Edges").get_children():
				var intersection = _find_line_plane_intersection(e.get_meta("p1"),e.get_meta("p2"), _cut_start, Point2, Point3,true)
				if intersection: 
					print(intersection)
					var point = Draw3d.point(p,intersection)
					intersection_points.append(point.position)
			Draw3d.polygon(p,intersection_points)
		
		#Draw3d.plane(_cut_start,Point2,Point3)
func line_middle_on_touch(mouse_position):
	var points = []
	for p in selected_polyhedrons:
		if not is_instance_valid(p): 
			continue
		points.append_array(p.get_node("Points").get_children())
	var selected_point = _get_clicked_point(mouse_position,points)
	var parent_polyhedron
	if selected_point and not selected_point in _line_middle_points:
		parent_polyhedron = selected_point.get_parent().get_parent()

		var pos = selected_point.position
		selected_point.queue_free()
		var highlight = Draw3d.point(parent_polyhedron,pos, 0.06)
		_line_middle_points.append(highlight)
	if len(_line_middle_points) >=2:
		for point in _line_middle_points:
			var pos = point.position
			point.queue_free()
			Draw3d.point(parent_polyhedron,pos)
		var p1 = _line_middle_points[0].position
		var p2 = _line_middle_points[1].position
		var middle = (p1+p2)/2
		var is_unique = true
		for point in parent_polyhedron.get_node("Points").get_children():
			if middle == point.position:
				is_unique = false
				break
		if is_unique:
			Draw3d.point(parent_polyhedron, middle)
		Draw3d.selected_material = line_material
		Draw3d.line(parent_polyhedron, p1, p2)
		Draw3d.selected_material = Draw3d.DEFAULT_MATERIAL

		_line_middle_points.clear()
func line_middle_on_unpick():
	for i in range(len(_line_middle_points)):
		var parent_polyhedron = _line_middle_points[i].get_parent().get_parent()
		var pos = _line_middle_points[i].position
		_line_middle_points[i].queue_free()
		Draw3d.point(parent_polyhedron,pos)
	_line_middle_points.clear()

func _get_uv(mousePos:Vector2):
	return ((mousePos/Vector2(get_viewport().get_visible_rect().size))-Vector2(0.5,0.5))*2
	
func _get_clicked_line(mouse_pos: Vector2, line_nodes: Array) -> MeshInstance3D:
	var closest_line: MeshInstance3D = null
	var closest_distance: float = 12.0

	for line in line_nodes:
		# Assuming your line mesh is defined by two points in local space (e.g., an edge)
		# Replace these with your actual line logic or vertex positions
		var p1_3d = line.get_meta("p1")
		var p2_3d = line.get_meta("p2")

		# Don't check lines that are behind the camera
		if camera.is_position_behind(p1_3d) or camera.is_position_behind(p2_3d):
			continue

		# Convert 3D positions to 2D screen coordinates
		var p1_2d = camera.unproject_position(p1_3d)
		var p2_2d = camera.unproject_position(p2_3d)

		# Calculate the shortest distance from the mouse to this 2D line segment
		var dist = Geometry2D.get_closest_point_to_segment(mouse_pos, p1_2d, p2_2d).distance_to(mouse_pos)

		if dist < closest_distance:
			closest_distance = dist
			closest_line = line

	return closest_line # Returns the MeshInstance3D clicked, or null
func _get_clicked_point(mouse_pos:Vector2, points:Array):
	var closest_point: MeshInstance3D = null
	var closest_distance: float = 12.0

	for point in points:
		var p = point.position

		# Don't check lines that are behind the camera
		if camera.is_position_behind(p):
			continue

		# Convert 3D positions to 2D screen coordinates
		var p_2d = camera.unproject_position(p)

		# Calculate the shortest distance from the mouse to this 2D line segment
		var dist = p_2d.distance_to(mouse_pos)

		if dist < closest_distance:
			closest_distance = dist
			closest_point = point

	return closest_point # Returns the MeshInstance3D clicked, or null
func _find_line_intersection_3d(a1: Vector3, b1: Vector3, a2: Vector3, b2: Vector3) -> Dictionary:
	# Направляющие векторы прямых (нормализованные)
	var v1 := (b1 - a1).normalized()
	var v2 := (b2 - a2).normalized()
	
	# Проверка на параллельность через векторное произведение
	var cross_v1_v2 := v1.cross(v2)
	if cross_v1_v2.is_zero_approx():
		# Проверяем, лежат ли они на одной линии
		if (a2 - a1).cross(v1).is_zero_approx():
			return {"status": "coincident", "message": "Прямые совпадают."}
		else:
			return {"status": "parallel", "message": "Прямые параллельны."}
			
	# Математический расчет точек кратчайшего расстояния между прямыми
	var r := a1 - a2
	var a := v1.dot(v1) # Всегда 1, так как вектор нормализован
	var b := v1.dot(v2)
	var c := v1.dot(r)
	var e := v2.dot(v2) # Всегда 1
	var f := v2.dot(r)
	
	var det := a * e - b * b
	
	# Параметры t1 и t2 для поиска точек на прямых
	var t1 := (b * f - c * e) / det
	var t2 := (a * f - b * c) / det
	
	# Ближайшие точки на первой и второй прямых
	var p1 := a1 + v1 * t1
	var p2 := a2 + v2 * t2
	
	# Расстояние между прямыми в этой точке
	var distance := p1.distance_to(p2)
	
	# Если расстояние стремится к нулю, они пересекаются
	if is_zero_approx(distance):
		return {
			"status": "intersect",
			"point": p1,
			"message": "Прямые пересекаются в точке: %s" % str(p1)
		}
	else:
		# Если не ноль — прямые скрещиваются (пролетают мимо друг друга в 3D)
		var middle_point := (p1 + p2) / 2.0
		return {
			"status": "skew",
			"point": middle_point,
			"distance": distance,
			"message": "Прямые скрещиваются. Кратчайший зазор: %f. Середина зазора: %s" % [distance, str(middle_point)]
		}
func _find_line_plane_intersection(A: Vector3,B: Vector3,P: Vector3,Q: Vector3,R: Vector3, crop:bool = false) -> Vector3:
	var V = B-A
	var PQ = Q-P
	var PR = R-P
	var N = PQ.cross(PR)
	if N.length() < 0.001: 
		print("Plane dots is on the same line")
		return Vector3.ZERO
	var denominator = V.dot(N)
	var PA = A-P
	var numerator = -PA.dot(N)
	if abs(denominator) < 0.001:
		if abs(numerator) < 0.001:
			print("Infinite intersection points, the line is on the plane")
			return Vector3.ZERO
		else:
			print("No intersection points, the line is parallel to plane")
			return Vector3.ZERO
	
	var t = numerator/denominator
	var intersection = (A + t*V)
	if crop and (t > 1.0 or (A-intersection).normalized()-V.normalized() == Vector3.ZERO): return Vector3.ZERO
	return A + t*V
	
	
func rotate_camera_around(angle: Vector3):
	if lock_rotation: return
	var dir = Vector3.FORWARD*(camera.position - _camera_center).length()
	_yaw += angle.y
	_pitch += angle.x
	_pitch = clampf(_pitch,-PI*0.49, PI*0.49)
	
	dir = dir.rotated(Vector3.UP, _yaw)
	dir = dir.rotated(Vector3.RIGHT.rotated(Vector3.UP,_yaw), _pitch)
	
	camera.position = _camera_center + dir
	camera.look_at(_camera_center)
	
func move_camera(offset: Vector3):
	if lock_movement: return
	var dir = camera.position - _camera_center
	_camera_center += offset
	camera.position = _camera_center + dir
	camera.look_at(_camera_center)

func zoom_camera(amount: float):
	if lock_zoom: return
	var dir = camera.position - _camera_center
	_zoom_amount *= amount
	camera.position = _camera_center + (dir*amount)
	camera.size = (dir*amount).length()
