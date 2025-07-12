extends Control

func _ready():
	if Lobby.client_get_role() == Lobby.ROLE_POLICE:
		$RebelHud/HBoxContainer/VBoxContainer.hide()
		return

	$RebelHud/HBoxContainer/VBoxContainer/Emoji1Button.on_pressed.connect(_on_emoji1_pressed)
	$RebelHud/HBoxContainer/VBoxContainer/Emoji2Button.on_pressed.connect(_on_emoji2_pressed)
	$RebelHud/HBoxContainer/VBoxContainer/Emoji3Button.on_pressed.connect(_on_emoji3_pressed)
	
	Lobby.client_on_stage_changed.connect(_on_stage_changed)
	_on_stage_changed(Lobby.client_get_stage(), Lobby.client_get_stage_objective_icon())


func _on_emoji1_pressed():
	_place_emoji_on_map(0)


func _on_emoji2_pressed():
	_place_emoji_on_map(1)


func _on_emoji3_pressed():
	_place_emoji_on_map(2)


func _place_emoji_on_map(index):
	Lobby.server_place_emoji_on_map.rpc_id(1, multiplayer.get_unique_id(), index)
	$RebelHud/HBoxContainer/VBoxContainer.hide()
	$EmojiCooldownTimer.start(Lobby.EMOJI_COOLDOWN_TIME_SEC)


func _on_emoji_cooldown_timer_timeout() -> void:
	$RebelHud/HBoxContainer/VBoxContainer.show()


func _on_stage_changed(stage, icon):
	$RebelHud/HBoxContainer/VBoxContainer2/StageNumberText.text = "Stage " + str(stage + 1)
	$RebelHud/HBoxContainer/VBoxContainer2/HBoxContainer/ObjectiveIcon.texture = Lobby.EMOJI_TEXTURES[icon]
