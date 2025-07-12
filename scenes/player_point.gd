extends Sprite2D

var dragged := false

@onready var camera: Camera2D = get_node("../Camera2D")

func _process(delta: float) -> void:
	var canvas_pos : Vector2 = get_global_mouse_position()
		
	if dragged:
		global_position = canvas_pos
			
	var smoothing = 100
	camera.global_position = (camera.global_position*smoothing + global_position)/(smoothing + 1)

func _input(event):
	if event is InputEventMouseButton:
		var canvas_pos : Vector2 = get_viewport().get_canvas_transform().affine_inverse()*event.position
		if event.pressed and _is_touching_point(canvas_pos):
			dragged = true
		elif not event.pressed:
			dragged = false
		
	#if event is InputEventMouseMotion:
		#var canvas_pos : Vector2 = get_viewport().get_canvas_transform().affine_inverse()*event.position
		#
		#if dragged:
			#global_position = canvas_pos
		
		
func _is_touching_point(pos: Vector2) -> bool:
	#var radius = 20
	var radius = (texture.get_width()/2)*3 # Fat finger support
	return global_position.distance_to(pos) <= radius;
	
