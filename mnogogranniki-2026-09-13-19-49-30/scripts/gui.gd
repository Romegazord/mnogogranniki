extends CanvasLayer

@onready var camera: Camera3D = get_node(get_meta("camera"))
@onready var add_popup:PopupMenu = $TopBar/FlowContainer/Add.get_popup()
@onready var tree_root = $RightSidebar/Tree.create_item()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_popup.id_pressed.connect(add)
	for btn:Button in $RightSidebar/Tools/ToolsScroll/FlowContainer.get_children():
		btn.toggled.connect(func(toggled_on):
			if toggled_on:
				if btn.get_meta("OnTouch"): camera.OnTouch = btn.get_meta("OnTouch")
				if btn.get_meta("OnTouch"): camera.OnRelease = btn.get_meta("OnRelease")
				if btn.get_meta("OnTouch"): camera.OnDrag = btn.get_meta("OnDrag")
			else:
				camera.OnTouch = null
				camera.OnRelease = null
				camera.OnDrag = null
			)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_ortho_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE


func _on_toggle_camera_rotation_toggled(toggled_on: bool) -> void:
	Tools.lock_rotation = toggled_on


func _on_toggle_camera_move_toggled(toggled_on: bool) -> void:
	Tools.lock_movement = toggled_on


func _on_toggle_camera_zoom_toggled(toggled_on: bool) -> void:
	Tools.lock_zoom = toggled_on
	
func add(id:int):
	Draw3d.polyhedron(
		[Vector3(1,1,1),
		Vector3(-1,1,1),
		Vector3(1,-1,1),
		Vector3(-1,-1,1),
		Vector3(1,1,-1),
		Vector3(-1,1,-1),
		Vector3(1,-1,-1),
		Vector3(-1,-1,-1)],
		[Vector2i(0,1),
		Vector2i(1,3),
		Vector2i(3,2),
		Vector2i(2,0),
		
		Vector2i(4,5),
		Vector2i(5,7),
		Vector2i(7,6),
		Vector2i(6,4),
		
		Vector2i(0,4),
		Vector2i(1,5),
		Vector2i(2,6),
		Vector2i(3,7)]
	)
	var obj = $RightSidebar/Tree.create_item(tree_root)
	obj.set_text(0,"Cube")
