extends Control

signal on_nitro_pressed

func _ready():
	Lobby.client_on_stage_changed.connect(_on_stage_changed)
	_on_stage_changed(Lobby.client_get_stage(), Lobby.client_get_stage_objective_icon())

	if Lobby.client_get_role() == Lobby.ROLE_POLICE:
		$RebelHud/Panels/RightControlsPanel/RevealButton.hide()
		$RebelHud/Panels/RightControlsPanel/NitroButton.show()
	else:
		$RebelHud/Panels/RightControlsPanel/RevealButton.show()
		$RebelHud/Panels/RightControlsPanel/NitroButton.hide()


func _on_stage_changed(stage, icon):
	$RebelHud/Panels/ObjectivePanel/StageNumberText.text = "Stage " + str(stage + 1)
	if Lobby.client_get_role() == Lobby.ROLE_REBEL:
		$RebelHud/Panels/ObjectivePanel/ObjectiveRow/ObjectiveIcon.texture = Lobby.EMOJI_TEXTURES[icon]
	else:
		$RebelHud/Panels/ObjectivePanel/ObjectiveRow.hide()


func _on_reveal_button_pressed() -> void:
	Lobby.reveal.rpc_id(1)

func update_nitro_texture(new_texture):
	$RebelHud/Panels/RightControlsPanel/NitroButton.texture = new_texture


func _on_nitro_button_pressed() -> void:
	on_nitro_pressed.emit()
