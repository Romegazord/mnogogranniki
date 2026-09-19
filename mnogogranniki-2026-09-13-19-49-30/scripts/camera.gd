extends Camera3D

const ZOOM_STEP = 0.05

var lastMousePos

var active_touches: Dictionary = {}
var last_finger_pos
var last_multifinger_center
var last_multifinger_distance

var Controls
var OnTouch
var OnRelease
var OnDrag

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Controls = chooseControlInterface()
	Tools.camera = self
	Tools.move_camera(Vector3.ZERO)
	Tools.rotate_camera_around(Vector3.ZERO)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	AndroidControlInterface.call(delta)
	
func chooseControlInterface():
	var os = OS.get_name()
	if os == "Android":
		return AndroidControlInterface
	else:
		return PCcontrolInterface


func PCcontrolInterface(delta: float):
	var mousePos = get_viewport().get_mouse_position()

	if Input.is_action_just_pressed("right_mouse_button") or Input.is_action_just_pressed("middle_mouse_button"):
		lastMousePos = get_viewport().get_mouse_position()
	if Input.is_action_pressed("right_mouse_button"):
		Tools.rotate_camera_around(Vector3(-(lastMousePos.y-mousePos.y),lastMousePos.x-mousePos.x,0)*delta)
		lastMousePos = mousePos

	elif Input.is_action_pressed("middle_mouse_button"):
		Tools.move_camera(basis*Vector3(lastMousePos.x-mousePos.x,-(lastMousePos.y-mousePos.y),0)*delta)
		lastMousePos = mousePos

func AndroidControlInterface(delta: float):
	if len(active_touches) == 1:
		if not last_finger_pos: last_finger_pos = active_touches.values()[0]
		var diff = active_touches.values()[0]-last_finger_pos
		Tools.rotate_camera_around(Vector3(diff.y,-diff.x,0)*delta)
		last_finger_pos = active_touches.values()[0]
	elif len(active_touches)>1:
		if not last_multifinger_distance: last_multifinger_distance = get_multifinger_distance()
		Tools.zoom_camera(1-(get_multifinger_distance()-last_multifinger_distance)*delta*0.1)
		last_multifinger_distance = get_multifinger_distance()
		if not last_multifinger_center: last_multifinger_center = get_multifinger_center()
		var diff = get_multifinger_center()-last_multifinger_center
		Tools.move_camera(basis*Vector3(-diff.x,diff.y,0)*delta)
		last_multifinger_center = get_multifinger_center()
func get_multifinger_center():
	if len(active_touches) <= 1: return
	var sum = Vector2.ZERO
	for i in range(len(active_touches)):
		sum += active_touches.values()[i]
	return sum/len(active_touches)
func get_multifinger_distance():
	if len(active_touches) <= 1: return
	var sum = 0.0
	for i in range(1,len(active_touches)):
		sum += (active_touches.values()[i]-active_touches.values()[0]).length()
	return sum/(len(active_touches)-1)

	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT:
				pass
				#if OnTouch: Tools.call(OnTouch, get_viewport().get_mouse_position())
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				Tools.zoom_camera(1+ZOOM_STEP)
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				Tools.zoom_camera(1-ZOOM_STEP)
		else:
			if event.button_index == MOUSE_BUTTON_LEFT:
				pass
				#if OnRelease: Tools.call(OnRelease, get_viewport().get_mouse_position())
	if event is InputEventScreenTouch:
		if event.is_pressed():
			active_touches[event.index]=event.position
			print("finger on touch")
			if OnTouch and len(active_touches)==1: Tools.call(OnTouch, event.position)
		else:
			active_touches.erase(event.index)
			if len(active_touches)>=1:
				last_finger_pos=active_touches.values()[-1]
				last_multifinger_center = get_multifinger_center()
				last_multifinger_distance = get_multifinger_distance()
			else:
				if OnRelease: Tools.call(OnRelease, event.position)
				last_finger_pos = null
				last_multifinger_center = null
				last_multifinger_distance = null
				
	if event is InputEventScreenDrag:
		active_touches[event.index]=event.position
		
