extends Control

const PredefinedAdjectives = [
	"Fun", "Crazy", "Calm", "Cool", "Noisy", "Jumpy",
	"Kinky", "Scary", "Lazy", "Fluffy", "Smart"
	]
const PredefinedNouns = [
	"Raccoon", "Panda", "Frog", "Fox", "Dog", "Cat",
	"Sheep", "Lion", "Puma", "Bat"
	]

func _ready():
	if Lobby.is_server():
		var ips_text = ""
		var ips = Lobby.get_all_ips()
		for ip in ips:
			if !ips_text.is_empty():
				ips_text += " or "
			ips_text += ip

		$VerticalBox/ClientControls.hide()
		$VerticalBox/ServerControls.show()
		$VerticalBox/ServerControls/IPToConnectTo.text = "The IP to connect is: " + ips_text
		Lobby.server_on_player_number_updated.connect(_on_number_updated)
		_on_number_updated()
	else:
		$VerticalBox/ClientControls.show()
		$VerticalBox/ServerControls.hide()
		Lobby.client_on_connected.connect(_client_on_connected)
		Lobby.client_on_connection_error.connect(_client_on_connection_error)
		Lobby.client_on_disconnected.connect(_client_on_disconnected)
		Lobby.client_on_game_started.connect(_client_on_game_started)

		$VerticalBox/ClientControls/NotConnected/NameEdit.text = PredefinedAdjectives.pick_random() + " " + PredefinedNouns.pick_random()

		Lobby.client_is_initialized()


func _on_number_updated():
	$VerticalBox/ServerControls/PlayersInTheLobby.text = "Players in the lobby: " + str(Lobby.get_players_in_the_lobby_num())


func _on_connect_button_pressed() -> void:
	Lobby.connect_to_server($VerticalBox/ClientControls/NotConnected/ServerIP.text)


func _on_start_game_debug_button_pressed() -> void:
	if len(Lobby.players_in_lobby) > 0:
		Lobby.change_to_game_scene()


func _client_on_connected():
	var preffered_role = Lobby.ROLE_RANDOM
	var selected_index = $VerticalBox/ClientControls/NotConnected/HBoxContainer/RoleSelector.selected
	if selected_index == 0:
		preffered_role = Lobby.ROLE_POLICE
	if selected_index == 1:
		preffered_role = Lobby.ROLE_REBEL
	Lobby.client_reported_lobby_ready($VerticalBox/ClientControls/NotConnected/NameEdit.text, preffered_role);
	$VerticalBox/ClientControls/NotConnected.hide()
	$VerticalBox/ClientControls/Connected.show()


func _client_on_disconnected():
	$VerticalBox/ClientControls/NotConnected.show()
	$VerticalBox/ClientControls/Connected.hide()


func _client_on_connection_error():
	pass


func _client_on_game_started(role: int, starting_position: Vector2):
	ClientPlayer.player_pos = starting_position
	get_tree().change_scene_to_file("res://scenes/player_movement.tscn")


func _on_disconnect_button_pressed() -> void:
	Lobby.disconnect_from_server()
