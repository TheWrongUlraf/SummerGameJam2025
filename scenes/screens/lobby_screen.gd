extends Control

func _ready():
	if Lobby.is_server():
		var ips_text = "The IP to connect is: "
		var ips = Lobby.get_all_ips()
		for ip in ips:
			if !ips_text.is_empty():
				ips_text += " or "
			ips_text += ip
		
		$VerticalBox/ClientControls.hide()
		$VerticalBox/ServerControls.show()
		$VerticalBox/ServerControls/IPToConnectTo.text = ips_text
		Lobby.server_on_player_number_updated.connect(_on_number_updated)
		_on_number_updated()
	else:
		$VerticalBox/ClientControls.show()
		$VerticalBox/ServerControls.hide()
		Lobby.client_on_connected.connect(_client_on_connected)
		Lobby.client_on_connection_error.connect(_client_on_connection_error)
		Lobby.client_on_connected.connect(_client_on_disconnected)
		Lobby.client_on_game_started.connect(_client_on_game_started)
		Lobby.client_is_initialized()


func _on_number_updated():
	$VerticalBox/ServerControls/PlayersInTheLobby.text = "Players in the lobby: " + str(Lobby.get_players_in_the_lobby_num())


func _on_connect_button_pressed() -> void:
	Lobby.connect_to_server($VerticalBox/ClientControls/ServerIP.text)


func _on_start_game_debug_button_pressed() -> void:
	Lobby.start_game.rpc()


func _client_on_connected():
	$VerticalBox/ClientControls/ServerIP.hide()
	$VerticalBox/ClientControls/ConnectButton.hide()
	$VerticalBox/ClientControls/DisconnectButton.show()


func _client_on_disconnected():
	$VerticalBox/ClientControls/ServerIP.show()
	$VerticalBox/ClientControls/ConnectButton.show()
	$VerticalBox/ClientControls/DisconnectButton.hide()


func _client_on_connection_error():
	pass


func _client_on_game_started():
	print("GO!GO!GO!")
	pass

func _on_disconnect_button_pressed() -> void:
	Lobby.disconnect_from_server()
