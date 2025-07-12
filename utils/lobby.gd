# autoload as Lobby

extends Node

const SERVER_PORT = 8021
const MAX_ALLOWED_CLIENTS = 10

var players_in_lobby = Array()

var is_server_cached = -1

signal server_on_player_number_updated

signal client_on_connected
signal client_on_connection_error
signal client_on_disconnected
signal client_on_game_started

func _ready():
	print("Initializing the networking")
	var ip = _get_ip()
	print("Our IP is ", ip)

	var is_server = is_server()

	if is_server:
		print("We think we are the server")
		multiplayer.peer_connected.connect(_server_only_on_client_connected)
		multiplayer.peer_disconnected.connect(_server_only_on_client_disconnected)
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(SERVER_PORT, MAX_ALLOWED_CLIENTS)
		multiplayer.multiplayer_peer = peer
	else:
		print("We think we are a client, waiting for input")


func client_is_initialized():
	if OS.get_cmdline_args().has("-debugclient"):
		print("Autoconnecting to 127.0.0.1")
		_debug_client_autoconnect()

# automatically connect the client to this server
func _debug_client_autoconnect():
	connect_to_server("127.0.0.1")


func _get_ip():
	for ip in IP.get_local_addresses():
		# ipv4 localhost
		if ip == "127.0.0.1":
			continue
		# ipv6 localhost
		if ip == "0:0:0:0:0:0:0:1":
			continue
		# skip any ipv6
		if ip.contains(":"):
			continue

		return ip


func get_all_ips():
	var ips = Array()

	for ip in IP.get_local_addresses():
		# ipv4 localhost
		if ip == "127.0.0.1":
			continue
		# ipv6 localhost
		if ip == "0:0:0:0:0:0:0:1":
			continue
		# skip any ipv6
		if ip.contains(":"):
			continue

		ips.append(ip)

	return ips


func _entered_lobby(id):
	if multiplayer.is_server():
		players_in_lobby.append(id)
		server_on_player_number_updated.emit()
		print("Client " + str(id) + " has entered the lobby")


func _server_only_on_client_connected(id):
	print("Client " + str(id) + " connected")
	_entered_lobby(id)


func _server_only_on_client_disconnected(id):
	print("Client " + str(id) + " disconnected")
	players_in_lobby.erase(id)
	server_on_player_number_updated.emit()


func _client_only_on_connected_ok():
	print("We got connected to the server")
	client_on_connected.emit()


func _client_only_on_connected_fail():
	print("We failed to connect to the server")
	client_on_connection_error.emit()


func _client_only_on_server_disconnected():
	print("Server dropped the connection")
	client_on_disconnected.emit()


func is_server():
	if is_server_cached == -1:
		is_server_cached = 1 if OS.get_cmdline_args().has("-server") else 0
	return is_server_cached == 1


func connect_to_server(ip):
	if !multiplayer.connected_to_server.is_connected(_client_only_on_connected_ok):
		multiplayer.connected_to_server.connect(_client_only_on_connected_ok)
	if !multiplayer.connection_failed.is_connected(_client_only_on_connected_fail):
		multiplayer.connection_failed.connect(_client_only_on_connected_fail)
	if !multiplayer.server_disconnected.is_connected(_client_only_on_server_disconnected):
		multiplayer.server_disconnected.connect(_client_only_on_server_disconnected)

	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()

	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, SERVER_PORT)
	multiplayer.multiplayer_peer = peer


func disconnect_from_server():
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()


func get_players_in_the_lobby_num():
	return len(players_in_lobby)


@rpc("authority", "call_remote", "reliable")
func start_game():
	if is_server():
		printerr("We never call this on the server duh!")
	client_on_game_started.emit()
