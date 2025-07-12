extends Node2D

var emoji_index: int
var reveal_time: int

var emoji_textures = [
	preload("res://assets/art/button.png"),
	preload("res://assets/art/icon2025.png"),
	preload("res://assets/art/buildings/House_01.png")
]

func _ready():
	$Sprite2D.texture = emoji_textures[emoji_index]

	if reveal_time > 0 && Lobby.client_get_role() == Lobby.ROLE_POLICE:
		hide()
