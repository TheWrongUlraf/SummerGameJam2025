extends Node2D

var emoji_index: int
var reveal_time: int

func _ready():
	$Sprite2D.texture = Lobby.EMOJI_TEXTURES[emoji_index]

	if reveal_time > Lobby.client_get_stage() && Lobby.client_get_role() == Lobby.ROLE_POLICE:
		hide()

func set_stage(stage):
	if stage >= reveal_time:
		show()
	else:
		hide()
