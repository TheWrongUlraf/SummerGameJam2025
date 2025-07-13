extends Control

func _ready():
	if Lobby.is_server():
		$VerticalBox/ClientControls.hide()
		$VerticalBox/ServerControls.show()
	else:
		$VerticalBox/ClientControls.show()
		$VerticalBox/ServerControls.hide()
