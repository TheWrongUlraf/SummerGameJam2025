extends CharacterBody2D

var PLAYER_SPEED = 10
var PLAYER_MAX_SPEED = PLAYER_SPEED * 25
var PLAYER_SLOWDOWN_SPEED = PLAYER_SPEED * 2

var dragged := false
var target_position: Vector2
var target_camera_pos: Vector2
var target_camera_pos_initialized := false

@onready var camera: Camera2D = get_node("../Camera2D")
@onready var map: Sprite2D = get_node("../Map")

func _ready():
	target_position = global_position


func _physics_process(_delta: float) -> void:
	var canvas_pos : Vector2 = get_global_mouse_position()
	
	if not target_camera_pos_initialized:
		target_camera_pos_initialized = true
		target_camera_pos = camera.global_position
		
	if dragged:
		target_position = canvas_pos
		velocity += (target_position - global_position).normalized() * PLAYER_SPEED
		if velocity.length() > PLAYER_MAX_SPEED:
			velocity = velocity.normalized() * PLAYER_MAX_SPEED
	else:
		if velocity.length() > 0:
			if velocity.length() < 0.1:
				velocity = Vector2.ZERO
			else:
				velocity -= velocity.normalized() * PLAYER_SLOWDOWN_SPEED
		target_position = global_position
	move_and_slide()
	
	var smoothing = 50
	target_camera_pos = (target_camera_pos*smoothing + global_position)/(smoothing + 1)

	var normalized_viewport := get_viewport().get_canvas_transform().affine_inverse()*get_viewport_rect()
	normalized_viewport.position = target_camera_pos - normalized_viewport.size/2
	var map_bounds := map.transform*map.get_rect();

	if map_bounds.encloses(normalized_viewport):
		camera.global_position = target_camera_pos
	
	Lobby.update_position.rpc_id(1, global_position)

func _input(event):
	if event is InputEventMouseButton:
		var canvas_pos : Vector2 = get_viewport().get_canvas_transform().affine_inverse()*event.position
		if event.pressed and _is_touching_point(canvas_pos):
			dragged = true
		elif not event.pressed:
			dragged = false
		
func _is_touching_point(_pos: Vector2) -> bool:
	return true
	#var radius = (texture.get_width()/2)*3 # Fat finger support
	#return global_position.distance_to(pos) <= radius;
	
