extends Node2D
var emoji_scene = preload("res://objects/map_emoji.tscn")

func _ready():
	if Lobby.is_server():
		return
	for emoji in Lobby.scheduled_emojis:
		_on_player_put_emoji(emoji.Pos, emoji.Idx, emoji.EmojiTime)
	Lobby.scheduled_emojis.clear()
	Lobby.client_on_player_put_emoji.connect(_on_player_put_emoji)
	Lobby.client_on_stage_changed.connect(_on_stage_changed)


func _on_player_put_emoji(location, index, reveal_time):
	var new_emoji = emoji_scene.instantiate()
	new_emoji.position = location
	new_emoji.emoji_index = index
	new_emoji.reveal_time = reveal_time
	$Emojis.add_child(new_emoji)


func _on_stage_changed(stage, _icon):
	if Lobby.client_get_role() == Lobby.ROLE_POLICE:
		for child in $Emojis.get_children():
			child.set_stage(stage)
