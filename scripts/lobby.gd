# autoload as Lobby

extends Node

const SERVER_PORT = 8021
const MAX_ALLOWED_CLIENTS = 10

const ROLE_RANDOM = -1
const ROLE_POLICE = 0
const ROLE_REBEL = 1

var players_in_lobby = Array()

var _is_server_cached = -1

var game_scene = null
var _client_role = ROLE_RANDOM
var _client_name = ""

signal server_on_player_number_updated

signal client_on_connected
signal client_on_connection_error
signal client_on_disconnected
signal client_on_game_started

class LobbyPlayerInfo:
	var Id: int
	var Name: String
	var Role: int

func _ready():
	print("Initializing the networking")
	var ip = _get_ip()
	print("Our IP is ", ip)

	if is_server():
		print("We think we are the server")
		multiplayer.peer_connected.connect(_server_only_on_client_connected)
		multiplayer.peer_disconnected.connect(_server_only_on_client_disconnected)
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(SERVER_PORT, MAX_ALLOWED_CLIENTS)
		multiplayer.multiplayer_peer = peer
	else:
		print("We think we are a client, waiting for input")


func client_is_initialized():
	var cmdline_args = OS.get_cmdline_args()
	if cmdline_args.has("-debugclient"):
		print("Autoconnecting to 127.0.0.1")
		_debug_client_autoconnect()
	if cmdline_args.has("-connect"):
		var ip = cmdline_args[cmdline_args.find("-connect") + 1]
		connect_to_server(ip)


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


@rpc("any_peer", "call_remote", "reliable")
func _server_on_player_ready_in_lobby(id, player_name, role):
	if multiplayer.is_server():
		var player = LobbyPlayerInfo.new()
		player.Id = id
		player.Name = player_name
		player.Role = role
		players_in_lobby.append(player)
		server_on_player_number_updated.emit()
		print("Client " + str(id) + " has entered the lobby")


func _server_only_on_client_connected(id):
	print("Client " + str(id) + " connected")


func _server_only_on_client_disconnected(id):
	print("Client " + str(id) + " disconnected")
	for i in range(0, len(players_in_lobby)):
		var player_info = (players_in_lobby[i] as LobbyPlayerInfo)
		if player_info.Id == id:
			players_in_lobby.remove_at(i)
			break;
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
	if _is_server_cached == -1:
		_is_server_cached = 1 if OS.get_cmdline_args().has("-server") else 0
	return _is_server_cached == 1


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
	var result = peer.create_client(ip, SERVER_PORT)
	if result != OK:
		client_on_connection_error.emit()
	multiplayer.multiplayer_peer = peer


func client_reported_lobby_ready(player_name, role):
	_server_on_player_ready_in_lobby.rpc(multiplayer.get_unique_id(), player_name, role)


func disconnect_from_server():
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()


func get_players_in_the_lobby_num():
	return len(players_in_lobby)


func change_to_game_scene():
	get_tree().change_scene_to_file("res://scenes/server_game.tscn")
	await get_tree().create_timer(0).timeout
	game_scene = get_tree().current_scene


@rpc("authority", "call_remote", "reliable")
func _start_game(role, player_name, starting_position):
	if is_server():
		printerr("We never call this on the server duh!")
	_client_role = role
	_client_name = player_name
	print("Client role: " + str(_client_role))
	client_on_game_started.emit(role, starting_position)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func update_position(pos: Vector2):
	if not is_server():
		printerr("We never call this on the client duh!")
		return

	if game_scene == null:
		printerr("Server not ready!")
	else:
		var sender_id = multiplayer.get_remote_sender_id()
		game_scene.update_player_position(sender_id, pos)


func get_player_info(id):
	for player in players_in_lobby:
		var player_info = (player as LobbyPlayerInfo)
		if player_info.Id == id:
			return player_info
	return null


func client_get_role():
	return _client_role


func get_client_name():
	return _client_name
