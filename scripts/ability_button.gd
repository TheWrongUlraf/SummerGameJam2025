extends TextureRect

signal on_pressed

func _on_button_pressed():
	on_pressed.emit()
