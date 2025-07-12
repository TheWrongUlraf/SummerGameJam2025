extends Node2D

@onready var revealButton: Sprite2D = get_node("Camera2D/RevealButton")
@onready var nitroBoostButton: Sprite2D = get_node("PoliceCamera2D/NitroBoost")
@onready var rebelCamera: Camera2D = get_node("Camera2D")
@onready var policeCamera: Camera2D = get_node("PoliceCamera2D")
@onready var player = get_node("CharacterBody2D")

var nitro_texture : Resource
var nitro_disabled_texture : Resource
var nitro_active_texture : Resource

func _ready() -> void:
	if ClientPlayer.role != Lobby.ROLE_REBEL:
		revealButton.get_parent().remove_child(revealButton)
		rebelCamera.enabled = false
		policeCamera.enabled = true
	if ClientPlayer.role != Lobby.ROLE_POLICE:
		nitroBoostButton.get_parent().remove_child(nitroBoostButton)
	nitro_texture = load("res://assets/art/Nitro.png")
	nitro_disabled_texture = load("res://assets/art/Nitro_gray.png")
	nitro_active_texture = load("res://assets/art/Nitro_active.png")
	

func _process(_delta: float) -> void:
	if ClientPlayer.role == Lobby.ROLE_POLICE:
		if player.nitro_boost_active > 0:
			nitroBoostButton.texture = nitro_active_texture
		elif player.nitro_boost_cooldown > 0:
			nitroBoostButton.texture = nitro_disabled_texture
		else:
			nitroBoostButton.texture = nitro_texture
