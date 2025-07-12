extends Node2D

@onready var audio: AudioStreamPlayer2D = get_node("Audio")

var players := {}

var cop_player: PlayerInfo

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
		Lobby._start_game.rpc_id(player_info.Id, player_info.Role, player_info.Name, starting_pos)
		

		var playerSprite = player_icon_scene.instantiate()
		playerSprite.global_position = starting_pos
		var game_player_info := PlayerInfo.new(player_info.Id, playerSprite, player_info.Role, player_info.Name)
		playerSprite.setup_icon(game_player_info)
		players.set(player_info.Id, game_player_info)
		add_child(playerSprite)
	
		if player_info.Role == Lobby.ROLE_POLICE:
			cop_player = game_player_info

func update_player_position(player_id: int, pos: Vector2):
	if players.has(player_id):
		players.get(player_id).player_node.position = pos
		
func reveal(player_id: int):
	if players.has(player_id):
		var player : PlayerInfo = players.get(player_id)
		player.reveal_cooldown = 10 # Reveal time
		
	var player : PlayerInfo = players[player_id]
	
	var other_rebels := 0
	var other_revealed_rebels_closeby := 0
	
	for other_player_id in players:
		if other_player_id != player_id:
			var other_player : PlayerInfo = players[other_player_id]
			if other_player.role == Lobby.ROLE_REBEL:
				other_rebels += 1
				if other_player.is_revealed():
					var distance = other_player.player_node.global_position.distance_to(player.player_node.global_position)
					if distance < 100:
						other_revealed_rebels_closeby += 1
				
	if other_revealed_rebels_closeby >= other_rebels:
		Lobby.team_wins(Lobby.ROLE_REBEL)
	

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

func _process(delta: float) -> void:
	for player_id in players:
		var player : PlayerInfo = players[player_id]
		player._process(delta)
		if cop_player.player_id != player.player_id:
			if player.player_node.global_position.distance_to(cop_player.player_node.global_position) <= 250:
				if !player.caught:
					audio.stream = load("res://assets/sounds/siren.ogg")
					audio.play()
					player.caught = true
					Lobby.team_wins(Lobby.ROLE_POLICE)
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
