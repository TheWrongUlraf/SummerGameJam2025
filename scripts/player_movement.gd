extends Node2D

@onready var rebelCamera: Camera2D = get_node("Camera2D")
@onready var policeCamera: Camera2D = get_node("PoliceCamera2D")
@onready var player = get_node("CharacterBody2D")

var police_texture = preload("res://assets/art/PoliceCar.png")

var nitro_texture : Resource
var nitro_disabled_texture : Resource
var nitro_active_texture : Resource

func _ready() -> void:
	if ClientPlayer.role != Lobby.ROLE_REBEL:
		rebelCamera.enabled = false
		policeCamera.enabled = true
	$CanvasLayer/Control/InGameHud.on_nitro_pressed.connect(_on_nitro_clicked)
	nitro_texture = load("res://assets/art/Nitro.png")
	nitro_disabled_texture = load("res://assets/art/Nitro_gray.png")
	nitro_active_texture = load("res://assets/art/Nitro_active.png")
	Lobby.client_on_disconnected.connect(_on_disconnected)

	if ClientPlayer.role == Lobby.ROLE_REBEL:
		$CharacterBody2D/Sprite2D.texture = Lobby.CHARACTER_TEXTURES[Lobby.client_get_icon()]
	else:
		$CharacterBody2D/Sprite2D.texture = police_texture


func _process(_delta: float) -> void:
	if ClientPlayer.role == Lobby.ROLE_POLICE:
		if player.nitro_boost_active > 0:
			$CanvasLayer/Control/InGameHud.update_nitro_texture(nitro_active_texture)
		elif player.nitro_boost_cooldown > 0:
			$CanvasLayer/Control/InGameHud.update_nitro_texture(nitro_disabled_texture)
		else:
			$CanvasLayer/Control/InGameHud.update_nitro_texture(nitro_texture)


func _on_disconnected():
	get_tree().change_scene_to_file("res://scenes/LobbyScreen.tscn")


func _on_nitro_clicked():
	if player.nitro_boost_cooldown <= 0:
		player.nitro_boost_active = 5
		player.nitro_boost_cooldown = 30
		Lobby.nitro_boost_activated.rpc_id(1)
