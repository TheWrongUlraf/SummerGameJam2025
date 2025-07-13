@tool
extends Control

@export_range(0, 3) var character: int = 0:
	set(value):
		character = value
		$Sprite2D.texture = Lobby.CHARACTER_TEXTURES[character]
	get:
		return character
