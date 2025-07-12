extends Sprite2D

var dragged := false
var target_position: Vector2
var target_camera_pos: Vector2
var target_camera_pos_initialized := false

@onready var camera: Camera2D = get_node("../Camera2D")
@onready var map: Sprite2D = get_node("../Map")

func _process(delta: float) -> void:
	var canvas_pos : Vector2 = get_global_mouse_position()
	
	if not target_camera_pos_initialized:
		target_camera_pos_initialized = true
		target_camera_pos = camera.global_position
		
	if dragged:
		target_position = canvas_pos
			
	var smoothing = 100
	
	global_position = (global_position*smoothing + target_position)/(smoothing + 1)
	
	target_camera_pos = (target_camera_pos*smoothing + global_position)/(smoothing + 1)

	var normalized_viewport := get_viewport().get_canvas_transform().affine_inverse()*get_viewport_rect()
	normalized_viewport.position = target_camera_pos - normalized_viewport.size/2
	var map_bounds := map.transform*map.get_rect();

	if map_bounds.encloses(normalized_viewport):
		camera.global_position = target_camera_pos
		
	Lobby.update_position.rpc(global_position)

func _input(event):
	if event is InputEventMouseButton:
		var canvas_pos : Vector2 = get_viewport().get_canvas_transform().affine_inverse()*event.position
		if event.pressed and _is_touching_point(canvas_pos):
			dragged = true
		elif not event.pressed:
			dragged = false
		
func _is_touching_point(pos: Vector2) -> bool:
	return true
	#var radius = (texture.get_width()/2)*3 # Fat finger support
	#return global_position.distance_to(pos) <= radius;
	
