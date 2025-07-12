extends Node2D

var emoji_index: int
var reveal_time: int

var emoji1_texture: Texture = preload("res://assets/art/button.png")
var emoji2_texture: Texture = preload("res://assets/art/icon2025.png")
var emoji3_texture: Texture = preload("res://assets/art/buildings/House_01.png")

func _ready():
	if emoji_index == 0:
		$Sprite2D.texture = emoji1_texture
	elif emoji_index == 1:
		$Sprite2D.texture = emoji2_texture
	elif emoji_index == 2:
		$Sprite2D.texture = emoji3_texture

	if reveal_time > 0 && Lobby.client_get_role() == Lobby.ROLE_POLICE:
		hide()
