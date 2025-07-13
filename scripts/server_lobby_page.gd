extends VBoxContainer


func _ready():
	var ips_text = ""
	var ips = Lobby.get_all_ips()
	for ip in ips:
		if !ips_text.is_empty():
			ips_text += " or "
		ips_text += ip
	$IPToConnectTo.text = "The IP to connect is: " + ips_text
	Lobby.server_on_player_number_updated.connect(_on_number_updated)
	_on_number_updated()


func _on_number_updated():
	var text = "Players in the lobby (" + str(Lobby.get_players_in_the_lobby_num()) + "):"
	for player in Lobby.players_in_lobby:
		text += " " + (player as Lobby.LobbyPlayerInfo).Name + ","
	text = text.erase(text.length() - 1)
	$PlayersInTheLobby.text = text


func _on_start_game_debug_button_pressed() -> void:
	if len(Lobby.players_in_lobby) > 0:
		Lobby.change_to_game_scene()
