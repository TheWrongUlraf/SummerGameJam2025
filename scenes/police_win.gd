extends Node2D


func _ready():
	if Lobby.client_is_party_leader():
		$RestartButton.show()
	else:
		$RestartButton.hide()


func _on_restart_button_pressed() -> void:
	Lobby.client_request_restart()
