extends VBoxContainer

const PredefinedAdjectives = [
	"Fun", "Crazy", "Calm", "Cool", "Noisy", "Jumpy",
	"Kinky", "Scary", "Lazy", "Fluffy", "Smart"
]

const PredefinedNouns = [
	"Raccoon", "Panda", "Frog", "Fox", "Dog", "Cat",
	"Sheep", "Lion", "Puma", "Bat"
]

func _ready():
	Lobby.client_on_connected.connect(_client_on_connected)
	Lobby.client_on_connection_error.connect(_client_on_connection_error)
	Lobby.client_on_disconnected.connect(_client_on_disconnected)
	Lobby.client_on_game_started.connect(_client_on_game_started)
	Lobby.client_on_party_leader_changed.connect(_client_on_party_leader_changed)

	$Connected/StartGameButton.hide()

	if $NotConnected/NameEdit.text.is_empty():
		$NotConnected/NameEdit.text = PredefinedAdjectives.pick_random() + " " + PredefinedNouns.pick_random()

	if Lobby.is_connected_to_server():
		$NotConnected.hide()
		$Connected.show()
	else:
		Lobby.client_is_initialized()


func _client_on_connected():
	var preffered_role = Lobby.ROLE_RANDOM
	var selected_index = $NotConnected/HBoxContainer/RoleSelector.selected
	if selected_index == 0:
		preffered_role = Lobby.ROLE_REBEL
	if selected_index == 1:
		preffered_role = Lobby.ROLE_POLICE
	Lobby.client_reported_lobby_ready($NotConnected/NameEdit.text, preffered_role);
	$NotConnected.hide()
	$Connected.show()


func _client_on_disconnected():
	$NotConnected.show()
	$NotConnected/ErrorText.hide()
	$Connected.hide()
	$Connected/StartGameButton.hide()


func _client_on_connection_error():
	$NotConnected/ErrorText.show()


func _client_on_game_started(role: int, starting_position: Vector2):
	ClientPlayer.role = role
	ClientPlayer.player_pos = starting_position
	get_tree().change_scene_to_file("res://scenes/player_movement.tscn")

func _client_on_party_leader_changed(id):
	if id == multiplayer.get_unique_id():
		$Connected/StartGameButton.show()
	else:
		$Connected/StartGameButton.hide()


func _on_connect_button_pressed() -> void:
	$NotConnected/ErrorText.hide()
	Lobby.connect_to_server($NotConnected/ServerIP.text)


func _on_disconnect_button_pressed() -> void:
	Lobby.disconnect_from_server()


func _on_start_game_button_pressed() -> void:
	Lobby.client_request_start_game()
