# autoload as Lobby

extends Node

const SERVER_PORT = 8021
const MAX_ALLOWED_CLIENTS = 10

const ROLE_RANDOM = -1
const ROLE_POLICE = 0
const ROLE_REBEL = 1

var players_in_lobby = Array()

var _is_server_cached = -1

var _stage = 0
var _stage_icon = 0

var game_scene = null
var _client_role = ROLE_RANDOM
var _client_name = ""
var _client_icon = 0

var client_player_point = null

var _party_leader = 0
var _client_is_party_leader = false

var scheduled_emojis = Array()

signal server_on_player_number_updated
signal server_on_party_leader_changed

signal client_on_connected
signal client_on_connection_error
signal client_on_disconnected
signal client_on_game_started
signal client_on_game_reset
signal client_on_player_put_emoji
signal client_on_stage_changed
signal client_on_party_leader_changed

var EMOJI_TEXTURES := [
	preload("res://assets/art/graffiti/Graf_Bomb.png"),
	preload("res://assets/art/graffiti/Graf_Cheese.png"),
	preload("res://assets/art/graffiti/Graf_Cherry.png"),
	preload("res://assets/art/graffiti/Graf_Chili.png"),
	preload("res://assets/art/graffiti/Graf_Cross.png"),
	preload("res://assets/art/graffiti/Graf_Fish.png"),
	preload("res://assets/art/graffiti/Graf_Heart.png"),
	preload("res://assets/art/graffiti/Graf_Kiwi.png"),
	preload("res://assets/art/graffiti/Graf_Lips.png"),
	preload("res://assets/art/graffiti/Graf_Morot.png"),
	preload("res://assets/art/graffiti/Graf_PinkHeart.png"),
	preload("res://assets/art/graffiti/Graf_Skull.png"),
	preload("res://assets/art/graffiti/Graf_YelChili.png"),
	preload("res://assets/art/graffiti/icon2025.png")
]

const CHARACTER_TEXTURES = [
	preload("res://assets/art/characters/CatPunk.png"),
	preload("res://assets/art/characters/Deer_Punk.png"),
	preload("res://assets/art/characters/DogPunk.png"),
]

class LobbyPlayerInfo:
	var Id: int
	var Name: String
	var Role: int
	var Icon: int

class ScheduledEmoji:
	var Pos: Vector2
	var Idx: int
	var EmojiTime: int

# i'm too lazy to create a new global for constants
const EMOJI_COOLDOWN_TIME_SEC = 10.0

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
		player.Icon = len(players_in_lobby) % len(CHARACTER_TEXTURES)
		players_in_lobby.append(player)
		server_on_player_number_updated.emit()
		print("Client " + str(id) + " has entered the lobby")

		if _party_leader == 0:
			_server_set_party_leader(id, player_name)


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

	if _party_leader == id:
		if players_in_lobby.is_empty():
			_server_set_party_leader(0, "")
		else:
			var player_info = (players_in_lobby[0] as LobbyPlayerInfo)
			_server_set_party_leader(player_info.Id, player_info.Name)


func _client_only_on_connected_ok():
	print("We got connected to the server")
	client_on_connected.emit()


func _client_only_on_connected_fail():
	print("We failed to connect to the server")
	client_on_connection_error.emit()


func _client_only_on_server_disconnected():
	print("Server dropped the connection")
	client_on_disconnected.emit()


func server_get_party_leader_name():
	for player in players_in_lobby:
		if _party_leader == player.Id:
			return player.Name
	return ""


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
func start_game(role, player_name, icon, starting_position):
	if is_server():
		printerr("We never call this on the server duh!")
	_client_role = role
	_client_name = player_name
	_client_icon = icon
	client_on_game_started.emit(role, starting_position)


@rpc("authority", "call_remote", "reliable")
func _team_wins(role: int):
	if is_server():
		printerr("We never call this on the server duh!")
	if role == ROLE_POLICE:
		get_tree().change_scene_to_file("res://scenes/PoliceWin.tscn")
	elif role == ROLE_REBEL:
		get_tree().change_scene_to_file("res://scenes/RebelsWin.tscn")
	# todo change scene

@rpc("authority", "call_remote", "reliable")
func teleport(teleported_player_id: int, new_position: Vector2):
	if is_server():
		printerr("We never call this on the server duh!")
	if teleported_player_id == multiplayer.get_unique_id():
		if client_player_point == null:
			printerr("Client not ready!")
		else:
			client_player_point.teleport(new_position)
	

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


@rpc("any_peer", "call_remote", "reliable")
func reveal():
	if not is_server():
		printerr("We never call this on the client duh!")
		return

	if game_scene == null:
		printerr("Server not ready!")
	else:
		var sender_id = multiplayer.get_remote_sender_id()
		game_scene.reveal(sender_id)


@rpc("any_peer", "call_remote", "reliable")
func server_place_emoji_on_map(sender_id, index):
	if game_scene == null:
		return

	if game_scene.can_player_place_emoji(sender_id):
		_client_place_emoji_on_map.rpc(game_scene.get_player_position(sender_id), index)
		game_scene.on_emoji_placed(sender_id)


@rpc("call_remote", "reliable")
func _client_place_emoji_on_map(position, index):
	client_on_player_put_emoji.emit(position, index, 0)


@rpc("any_peer", "call_remote", "reliable")
func nitro_boost_activated():
	if game_scene != null:
		game_scene.nitro_boost_activated(multiplayer.get_remote_sender_id())


func client_request_restart():
	_server_restart_game.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _server_restart_game():
	_client_restart_game.rpc()
	get_tree().change_scene_to_file("res://scenes/LobbyScreen.tscn")


@rpc("authority", "call_remote", "reliable")
func _client_restart_game():
	client_on_game_reset.emit()
	get_tree().change_scene_to_file("res://scenes/LobbyScreen.tscn")


func place_emojis(positions, emojis, reveal_times):
	_place_emojis.rpc(positions, emojis, reveal_times)


@rpc("authority", "call_remote", "reliable")
func _place_emojis(positions, emojis, reveal_times):
	if len(positions) != len(emojis) || len(emojis) != len(reveal_times):
		printerr("Array sizes don't match")
		return

	if client_on_player_put_emoji.has_connections():
		for i in range(0, len(positions)):
			client_on_player_put_emoji.emit(positions[i], emojis[i], reveal_times[i])
	else:
		for i in range(0, len(positions)):
			var emoji = ScheduledEmoji.new()
			emoji.Pos = positions[i]
			emoji.Idx = emojis[i]
			emoji.EmojiTime = reveal_times[i]
			scheduled_emojis.append(emoji)


func _server_set_party_leader(id, player_name):
	_party_leader = id
	_client_new_party_leader.rpc(id)
	server_on_party_leader_changed.emit(player_name)


@rpc("authority", "call_remote", "reliable")
func _client_new_party_leader(id):
	if id == multiplayer.get_unique_id() && (OS.get_cmdline_args().has("-debugclient") || OS.get_cmdline_args().has("-connect")):
		client_request_start_game()
	_client_is_party_leader = (id == multiplayer.get_unique_id())
	client_on_party_leader_changed.emit(id)


func client_request_start_game():
	_server_request_start_game.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _server_request_start_game():
	if len(players_in_lobby) >= 2:
		Lobby.change_to_game_scene()


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


func is_connected_to_server():
	# if we have a role assigned, we are surely initilized, suuurely..
	return _client_role != ROLE_RANDOM


func team_wins(role: int):
	for i in range(0, len(players_in_lobby)):
		var player = Lobby.players_in_lobby[i]
		var player_info = (player as LobbyPlayerInfo)
		Lobby._team_wins.rpc_id(player_info.Id, role)


func server_on_stage_changed(stage, objective_icons, objective_owners):
	if len(objective_icons) != len(objective_owners):
		printerr("Objectives are borked")
		return

	for player in players_in_lobby:
		var icon_idx = objective_owners.find(player.Id)
		if icon_idx != -1:
			_client_on_stage_changed.rpc_id(player.Id, stage, objective_icons[icon_idx])
		else:
			_client_on_stage_changed.rpc_id(player.Id, stage, -1)


@rpc("authority", "call_remote", "reliable")
func _client_on_stage_changed(stage, objective_icon):
	_stage = stage
	_stage_icon = objective_icon
	client_on_stage_changed.emit(stage, objective_icon)


func client_get_stage():
	return _stage


func client_get_icon():
	return _client_icon


func client_get_stage_objective_icon():
	return _stage_icon


func client_is_party_leader():
	return _client_is_party_leader
