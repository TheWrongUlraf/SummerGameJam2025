extends Control

var map: NodePath


func _ready():
	$RebelHud/HBoxContainer/VBoxContainer/Emoji1Button.on_pressed.connect(_on_emoji1_pressed)
	$RebelHud/HBoxContainer/VBoxContainer/Emoji2Button.on_pressed.connect(_on_emoji2_pressed)
	$RebelHud/HBoxContainer/VBoxContainer/Emoji3Button.on_pressed.connect(_on_emoji3_pressed)


func _on_emoji1_pressed():
	_place_emoji_on_map(0)


func _on_emoji2_pressed():
	_place_emoji_on_map(1)


func _on_emoji3_pressed():
	_place_emoji_on_map(2)


func _place_emoji_on_map(index):
	Lobby.server_place_emoji_on_map.rpc_id(1, multiplayer.get_unique_id(), index)
