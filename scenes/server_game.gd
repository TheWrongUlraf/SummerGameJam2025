extends Node2D

@onready var audio: AudioStreamPlayer2D = get_node("Audio")
@onready var rebelProgressAudio: AudioStreamPlayer = get_node("RebelProgressAudio")
@onready var progressBar: TextureProgressBar = get_node("CanvasLayer/MarginContainer/ProgressBar")

var players := {}

var cop_player: PlayerInfo

var stage = 0
var max_stages = 5
var current_objective_pos = Vector2(0.0, 0.0)
var emojis = Array()

const REVEAL_TIME_SEC = 3.0

func _ready() -> void:
	if !Lobby.is_server():
		printerr("Don't call it from client!")
		return

	var is_police_role_assigned = false

	Lobby.players_in_lobby.shuffle()

	for player in Lobby.players_in_lobby:
		var player_info = (player as Lobby.LobbyPlayerInfo)
		if player_info.Role == Lobby.ROLE_POLICE:
			if is_police_role_assigned == true:
				player_info.Role = Lobby.ROLE_REBEL
			else:
				is_police_role_assigned = true

	if !is_police_role_assigned:
		(Lobby.players_in_lobby[0] as Lobby.LobbyPlayerInfo).Role = Lobby.ROLE_POLICE

	var spawn_points = _get_randomized_spawn_points(len(Lobby.players_in_lobby))

	var player_icon_scene = load("res://objects/player_icon.tscn")

	for i in range(0, len(Lobby.players_in_lobby)):
		var player = Lobby.players_in_lobby[i]
		var player_info = (player as Lobby.LobbyPlayerInfo)
		if player_info.Role != Lobby.ROLE_POLICE:
			player_info.Role = Lobby.ROLE_REBEL

		var starting_pos = spawn_points[i]
		Lobby.start_game.rpc_id(player_info.Id, player_info.Role, player_info.Name, player_info.Icon, starting_pos)

		var playerSprite = player_icon_scene.instantiate()
		playerSprite.global_position = starting_pos
		var game_player_info := PlayerInfo.new(player_info.Id, playerSprite, player_info.Role, player_info.Name, player_info.Icon)
		playerSprite.setup_icon(game_player_info)
		players.set(player_info.Id, game_player_info)
		add_child(playerSprite)

		if player_info.Role == Lobby.ROLE_POLICE:
			cop_player = game_player_info

	_generate_random_emojis()

	_choose_next_objective()
	
	progressBar.max_value = max_stages

func update_player_position(player_id: int, pos: Vector2):
	if players.has(player_id):
		players.get(player_id).player_node.position = pos

func reveal(player_id: int):
	if players.has(player_id):
		var player : PlayerInfo = players.get(player_id)
		player.reveal_cooldown = REVEAL_TIME_SEC

func get_player_position(player_id):
	if players.has(player_id):
		return players.get(player_id).player_node.position
	return Vector2(0.0 ,0.0)

func can_player_place_emoji(player_id):
	if players.has(player_id):
		return players.get(player_id).last_placed_emoji_time + Lobby.EMOJI_COOLDOWN_TIME_SEC < Time.get_unix_time_from_system()
	return false

func on_emoji_placed(player_id):
	if players.has(player_id):
		players.get(player_id).last_placed_emoji_time = Time.get_unix_time_from_system()

func nitro_boost_activated(_player_id: int):
	audio.stream = load("res://assets/sounds/nitro_boost.ogg")
	audio.play()

func _process(delta: float) -> void:
	for player in players.values():
		player._process(delta)
	_check_win_conditions()
	update_visuals()

func update_visuals():
	for player_id in players:
		var player : PlayerInfo = players[player_id]
		if player.role == Lobby.ROLE_POLICE:
			player.player_node.visible = true
		elif player.role == Lobby.ROLE_REBEL:
			player.player_node.visible = false
			if player.is_revealed() or player.caught:
				player.player_node.visible = true

func _check_win_conditions():
	for player_id in players:
		var player : PlayerInfo = players[player_id]
		if cop_player.player_id != player.player_id:
			if player.player_node.global_position.distance_to(cop_player.player_node.global_position) <= 250:
				if !player.caught:
					audio.stream = load("res://assets/sounds/siren.ogg")
					audio.play()
					player.caught = true
					Lobby.team_wins(Lobby.ROLE_POLICE)
					return

	var rebels := 0
	var revealed_rebels_closeby := 0

	for player_id in players:
		var player : PlayerInfo = players[player_id]
		if player.role == Lobby.ROLE_REBEL:
			rebels += 1
			if player.is_revealed():
				var distance = current_objective_pos.distance_to(player.player_node.global_position)
				if distance < 100:
					revealed_rebels_closeby += 1

	if revealed_rebels_closeby >= rebels:
		stage += 1
		progressBar.value = stage
		rebelProgressAudio.play()
		if stage >= max_stages:
			Lobby.team_wins(Lobby.ROLE_REBEL)
		else:
			_choose_next_objective()


func _get_randomized_spawn_points(number):
	var spawn_points = $Map/SpawnPositions.get_children()
	var positions = Array()
	if number > len(spawn_points):
		printerr("Trying to get more spawn positions than we have")
		return positions
	spawn_points.shuffle()
	for i in range(0, number):
		positions.append(spawn_points[i].global_position)
	return positions


func _generate_random_emojis():
	var positions = Array()
	var reveal_times = Array()
	var spawn_points = $Map/SpawnPositions.get_children()
	var emoji_tex_len = len(Lobby.EMOJI_TEXTURES)
	emojis = range(emoji_tex_len)
	emojis.shuffle()
	for spawn_point in spawn_points:
		positions.append(spawn_point.global_position)
		reveal_times.append(1 + randi() % (max_stages - 1))
	Lobby.place_emojis(positions, emojis, reveal_times)

func _choose_next_objective():
	var next_objective_idx = randi() % $Map/SpawnPositions.get_child_count()
	current_objective_pos = $Map/SpawnPositions.get_child(next_objective_idx).global_position
	var next_objective_emoji = emojis[next_objective_idx]
	Lobby.server_on_stage_changed(stage, next_objective_emoji)
