extends CharacterBody2D

var PLAYER_SPEED = 20
var PLAYER_MIN_SPEED = PLAYER_SPEED / 5
var PLAYER_MAX_SPEED = PLAYER_SPEED * 40
var PLAYER_SLOWDOWN_SPEED = PLAYER_SPEED * 0.5

var dragged := false
var target_position: Vector2
var target_camera_pos: Vector2
var target_camera_pos_initialized := false

var nitro_boost_active: float = 0
var nitro_boost_cooldown: float = 0

@onready var camera: Camera2D = get_node("../Camera2D")
@onready var map: Node2D = get_node("../Map")

func _ready():
	global_position = ClientPlayer.player_pos
	target_position = global_position


func _physics_process(_delta: float) -> void:
	var canvas_pos : Vector2 = get_global_mouse_position()
	
	if not target_camera_pos_initialized:
		target_camera_pos_initialized = true
		target_camera_pos = camera.global_position
		
	if dragged:
		target_position = canvas_pos
		var playerSpeed = PLAYER_SPEED
		var playerMaxSpeed = PLAYER_MAX_SPEED
		if nitro_boost_active > 0:
			playerSpeed *= 2.0
			playerMaxSpeed *= 2.0
		velocity += (target_position - global_position).normalized() * playerSpeed
		if velocity.length() > playerMaxSpeed:
			velocity = velocity.normalized() * playerMaxSpeed
	else:
		if velocity.length() > 0:
			var slowdown = velocity.normalized() * PLAYER_SLOWDOWN_SPEED
			if velocity.length() < slowdown.length():
				velocity = Vector2.ZERO
			else:
				velocity -= slowdown
				
			if velocity.length() < PLAYER_MIN_SPEED:
				velocity = Vector2.ZERO
		
		target_position = global_position
	move_and_slide()
	
	if nitro_boost_active > 0:
		nitro_boost_active -= _delta
		
	if nitro_boost_cooldown > 0:
		nitro_boost_cooldown -= _delta
		
	
	var smoothing = 50
	target_camera_pos = (target_camera_pos*smoothing + global_position)/(smoothing + 1)

	var normalized_viewport := get_viewport().get_canvas_transform().affine_inverse()*get_viewport_rect()
	normalized_viewport.position = target_camera_pos - normalized_viewport.size/2
	var map_half_width = 5000 / 2.0
	var map_half_height = 5000 / 2.0
	
	target_camera_pos.x = clamp(
		target_camera_pos.x,
		map.position.x - int(map_half_width),
		map.position.x + int(map_half_width)
	)
	target_camera_pos.y = clamp(
		target_camera_pos.y,
		map.position.y - map_half_height,
		map.position.y + map_half_height
	)
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
	
