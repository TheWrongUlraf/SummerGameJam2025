extends Node2D

var emoji_scene = preload("res://objects/map_emoji.tscn")

func _ready():
	Lobby.client_on_player_put_emoji.connect(_on_player_put_emoji)


func _on_player_put_emoji(location, index):
	var new_emoji = emoji_scene.instantiate()
	new_emoji.position = location
	$Emojis.add_child(new_emoji)
