extends Node2D

@onready var revealButton: Sprite2D = get_node("Camera2D/RevealButton")

func _ready() -> void:
	if ClientPlayer.role != Lobby.ROLE_REBEL:
		revealButton.get_parent().remove_child(revealButton)
		
