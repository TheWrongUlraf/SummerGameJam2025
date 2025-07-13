extends Control

func _ready():
	if Lobby.is_server():
		$VerticalBox/ClientControls.hide()
		$VerticalBox/ServerControls.show()
		$MainMusic.play()
	else:
		$VerticalBox/ClientControls.show()
		$VerticalBox/ServerControls.hide()
