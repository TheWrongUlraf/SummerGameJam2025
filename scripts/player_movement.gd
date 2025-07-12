extends Node2D

@onready var revealButton: Sprite2D = get_node("Camera2D/RevealButton")
@onready var nitroBoostButton: Sprite2D = get_node("Camera2D/NitroBoost")
@onready var player = get_node("CharacterBody2D")

func _ready() -> void:
	if ClientPlayer.role != Lobby.ROLE_REBEL:
		revealButton.get_parent().remove_child(revealButton)
	if ClientPlayer.role != Lobby.ROLE_POLICE:
		nitroBoostButton.get_parent().remove_child(nitroBoostButton)
	

func _process(delta: float) -> void:
	if ClientPlayer.role == Lobby.ROLE_POLICE:
		if player.nitro_boost_active > 0:
			nitroBoostButton.modulate = Color("00ff00")
		elif player.nitro_boost_cooldown > 0:
			nitroBoostButton.modulate = Color("ff0000")
		else:
			nitroBoostButton.modulate = Color("e9b15d")
