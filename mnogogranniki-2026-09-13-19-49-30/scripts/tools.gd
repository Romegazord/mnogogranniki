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

func cut_on_touch(mouse_position):
	var uv = _get_uv(mouse_position)
	_cut_start = camera.position+(Vector3(-uv.x*tan(deg_to_rad(camera.fov))*camera.get_camera_projection().get_aspect(), -uv.y*tan(deg_to_rad(camera.fov)), 4.9).rotated(Vector3.UP, _yaw).rotated(Vector3.RIGHT.rotated(Vector3.UP,_yaw), _pitch))

func cut_on_release(mouse_position):
		var uv = _get_uv(mouse_position)
		var Point2 = camera.position+(Vector3(-uv.x*tan(deg_to_rad(camera.fov))*camera.get_camera_projection().get_aspect(), -uv.y*tan(deg_to_rad(camera.fov)), 4.9).rotated(Vector3.UP, _yaw).rotated(Vector3.RIGHT.rotated(Vector3.UP,_yaw), _pitch))
		var Point3 = camera.position
		for p in get_tree().root.get_node("Main/Polyhedrons").get_children():
			var intersection_points = []
			for e in p.get_children():
				var intersection = _find_line_plane_intersection(e.get_meta("p1"),e.get_meta("p2"), _cut_start, Point2, Point3,true)
				if intersection: 
					print(intersection)
					var point = Draw3d.point(intersection)
					intersection_points.append(point.position)
			var polygon = Draw3d.polygon(intersection_points)
			polygon.name = "polygon"
			get_tree().root.get_node("Main").add_child(polygon)
		
		#Draw3d.plane(_cut_start,Point2,Point3)
func _get_uv(mousePos:Vector2):
	return ((mousePos/Vector2(get_viewport().get_visible_rect().size))-Vector2(0.5,0.5))*2
func _find_line_plane_intersection(A: Vector3,B: Vector3,P: Vector3,Q: Vector3,R: Vector3, crop:bool = false):
	var V = B-A
	var PQ = Q-P
	var PR = R-P
	var N = PQ.cross(PR)
	if N.length() < 0.001: 
		print("Plane dots is on the same line")
		return
	var denominator = V.dot(N)
	var PA = A-P
	var numerator = -PA.dot(N)
	if abs(denominator) < 0.001:
		if abs(numerator) < 0.001:
			print("Infinite intersection points, the line is on the plane")
			return
		else:
			print("No intersection points, the line is parallel to plane")
			return
	
	var t = numerator/denominator
	var intersection = (A + t*V)
	if crop and (intersection.length() > V.length() or (A-intersection).normalized()-V.normalized() == Vector3.ZERO): return
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
