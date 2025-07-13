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
	Lobby.server_on_party_leader_changed.connect(_server_on_party_leader_changed)
	_on_number_updated()


func _on_number_updated():
	var text = "Players in the lobby (" + str(Lobby.get_players_in_the_lobby_num()) + "):"
	for player in Lobby.players_in_lobby:
		text += " " + (player as Lobby.LobbyPlayerInfo).Name + ","
	text = text.erase(text.length() - 1)
	$PlayersInTheLobby.text = text


func _server_on_party_leader_changed(player_name):
	if player_name.is_empty():
		$PartyLeaderText.text = ""
	else:
		$PartyLeaderText.text = "Party leader is " + player_name
