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

	for i in range(0, len(Lobby.players_in_lobby)):
		var player = Lobby.players_in_lobby[i]
		var player_info = (player as Lobby.LobbyPlayerInfo)
		if player_info.Role != Lobby.ROLE_POLICE:
			player_info.Role = Lobby.ROLE_REBEL

		var starting_pos = spawn_points[i]
		Lobby._start_game.rpc_id(player_info.Id, player_info.Role, player_info.Name, starting_pos)
		
		var playerSprite = Sprite2D.new()
		if player_info.Role == Lobby.ROLE_POLICE:
			playerSprite.texture = load("res://assets/art/PoliceCar.png")
			playerSprite.scale = Vector2(0.2, 0.2)
			playerSprite.visible = true
		else:
			playerSprite.texture = load("res://assets/art/point.png")
			playerSprite.visible = false
			
		playerSprite.global_position = starting_pos
		var game_player_info := PlayerInfo.new(player_info.Id, playerSprite, player_info.Role)
		players.set(player_info.Id, game_player_info)
		add_child(playerSprite)
	
		if player_info.Role == Lobby.ROLE_POLICE:
			cop_player = game_player_info

func update_player_position(player_id: int, pos: Vector2):
	if players.has(player_id):
		players.get(player_id).player_node.position = pos

func _process(delta: float) -> void:
	for player_id in players:
		var player : PlayerInfo = players[player_id]
		if cop_player.player_id != player.player_id:
			if player.player_node.global_position.distance_to(cop_player.player_node.global_position) <= 250:
				if !player.player_node.visible:
					audio.stream = load("res://assets/sounds/siren.ogg")
					audio.play()
					player.player_node.visible = true
					print("Player ", player.player_id, " caught!")

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
