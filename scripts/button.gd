extends Sprite2D

signal on_pressed

@onready var playerPoint = get_node("../../CharacterBody2D")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if !event.pressed:
			if is_pixel_opaque(get_local_mouse_position()):
				on_pressed.emit()


func _on_reveal_clicked() -> void:
	Lobby.reveal.rpc_id(1)


func _on_nitro_clicked() -> void:
	if playerPoint.nitro_boost_cooldown <= 0:
		playerPoint.nitro_boost_active = 5
		playerPoint.nitro_boost_cooldown = 30
	
