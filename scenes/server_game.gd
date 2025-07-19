extends Node2D

@onready var audio: AudioStreamPlayer2D = get_node("Audio")
@onready var rebelProgressAudio: AudioStreamPlayer = get_node("RebelProgressAudio")
@onready var nitroBoostAudio: AudioStreamPlayer = get_node("NitroBoostAudio")
@onready var policeDetectorAudio: AudioStreamPlayer = get_node("PoliceDetectorAudio")
@onready var progressBar: TextureProgressBar = get_node("CanvasLayer/MarginContainer/VBoxContainer/ProgressBar")
@onready var progressBarPolice: TextureProgressBar = get_node("CanvasLayer/MarginContainer/VBoxContainer/ProgressBarPolice")
@onready var arrestedOverlay: TextureRect = get_node("CanvasLayer/ArrestedOverlay")
@onready var arrestedOverlayText: RichTextLabel = get_node("CanvasLayer/ArrestedOverlay/ArrestedText")
@onready var policeDetector: Sprite2D = get_node("PoliceDetector")

var police_detector_visibility = 0

class DetectionCircle:
	var center: Vector2
	var radius: float

var players := {}

var cop_player: PlayerInfo

var stage = 0
var max_stages = 5
var current_objective_positions = Array()
var emojis = Array()

var police_catches = 0
var police_catches_to_win = 5

var arrested_overlay_show_cooldown = 0

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

	_choose_next_objectives()
	
	progressBar.max_value = max_stages
	progressBarPolice.max_value = police_catches_to_win

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
	nitroBoostAudio.play()
	
func process_police_detector():
	# Update sprite position
	policeDetector.global_position = cop_player.player_node.global_position
	var alpha = clampf(police_detector_visibility, 0.0, 1.0) 
	policeDetector.modulate = Color(1.0, 0.0, 0.0, alpha)
	
	var detection := get_detection_circle()
	for player_id in players:
		var player : PlayerInfo = players[player_id]
		if cop_player.player_id != player.player_id:
			if player.detected_cooldown <= 0 and player.player_node.global_position.distance_to(detection.center) <= detection.radius:
				player.detected_cooldown = 5
				police_detector_visibility = 1
				policeDetectorAudio.play()
				
				

func get_detection_circle() -> DetectionCircle:
	var transformedSize := (policeDetector.get_transform()*policeDetector.get_rect()).size
	var result = DetectionCircle.new()
	result.center = policeDetector.global_position
	result.radius = transformedSize.x/2.0
	return result

func _process(delta: float) -> void:
	for player in players.values():
		player._process(delta)
	process_police_detector()
	_check_win_conditions()
	if arrested_overlay_show_cooldown > 0:
		arrested_overlay_show_cooldown -= delta
		if arrested_overlay_show_cooldown <= 0:
			arrestedOverlay.visible = false
	if police_detector_visibility > 0.0:
		police_detector_visibility -= delta
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
			if player.player_node.global_position.distance_to(cop_player.player_node.global_position) <= 160:
				if !player.caught and player.caught_cooldown <= 0:
					audio.stream = load("res://assets/sounds/siren.ogg")
					audio.play()
					var spawnPoints := _get_randomized_spawn_points(len($Map/SpawnPositions.get_children()))
					spawnPoints = sort_by_closest(player.player_node.global_position, spawnPoints)
					for i in range(8): # Remove 8 closest spawn points
						spawnPoints.remove_at(0)
						
					spawnPoints.shuffle()
					
					var teleport_target : Vector2 = spawnPoints[0]
					player.reveal_cooldown = 0 # Make sure no longer revealed
					player.caught_cooldown = 5 # Player can not be caught the next 5 seconds

					player.player_node.global_position = teleport_target
					Lobby.teleport.rpc_id(player_id, player_id, teleport_target)

					if stage > 0:
						#stage -= 1
						progressBar.value = stage
						_choose_next_objectives()
					police_catches += 1
					progressBarPolice.value = police_catches
					if police_catches >= police_catches_to_win:
						player.caught = true
						Lobby.team_wins(Lobby.ROLE_POLICE)
					else:
						arrested_overlay_show_cooldown = 3
						arrestedOverlay.visible = true
						arrestedOverlayText.text = player.name+"\nwas arrested!"
					return

	for objective in current_objective_positions:
		var rebels := 0
		var revealed_rebels_closeby := 0
		for player_id in players:
			var player : PlayerInfo = players[player_id]
			if player.role == Lobby.ROLE_REBEL:
				rebels += 1
				if player.is_revealed():
					var distance = objective.distance_to(player.player_node.global_position)
					if distance < 150:
						revealed_rebels_closeby += 1

		if revealed_rebels_closeby >= rebels:
			stage += 1
			progressBar.value = stage
			if police_catches > 0:
				#police_catches -= 1
				progressBarPolice.value = police_catches
			rebelProgressAudio.play()
			if stage >= max_stages:
				Lobby.team_wins(Lobby.ROLE_REBEL)
			else:
				_choose_next_objectives()
				break


func _get_randomized_spawn_points(number) -> Array:
	var spawn_points = $Map/SpawnPositions.get_children()
	var positions = Array()
	if number > len(spawn_points):
		printerr("Trying to get more spawn positions than we have")
		return positions
	spawn_points.shuffle()
	for i in range(0, number):
		positions.append(spawn_points[i].global_position)
	return positions
	

func sort_by_second(a, b):
	if a[1] < b[1]:
		return true
	return false

	
func sort_by_closest(global_pos: Vector2, spawnPoints: Array) -> Array:
	var spawnPointsWithDistance = Array()
	for i in range(len(spawnPoints)):
		spawnPointsWithDistance.push_back([spawnPoints[i], spawnPoints[i].distance_to(global_pos)])
	
	spawnPointsWithDistance.sort_custom(sort_by_second)
	
	var result = Array()
	for pair in spawnPointsWithDistance:
		result.push_back(pair[0])
	return result


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

func _choose_next_objectives():
	var objective_owners = Array()
	for player in Lobby.players_in_lobby:
		if player.Role == Lobby.ROLE_REBEL:
			objective_owners.append(player.Id)
	objective_owners.shuffle()
	const OBJECTIVES_AT_A_TIME = 2
	objective_owners.resize(OBJECTIVES_AT_A_TIME)
	var objective_icons = Array()
	var previous_objectives = current_objective_positions.duplicate()
	current_objective_positions.clear()
	for i in range(OBJECTIVES_AT_A_TIME):
		for j in range(0, 1000):
			var next_objective_idx = randi() % $Map/SpawnPositions.get_child_count()
			var pos = $Map/SpawnPositions.get_child(next_objective_idx).global_position
			# floats but should be fine since we don't do any math with them
			if previous_objectives.has(pos):
				continue
			if current_objective_positions.has(pos):
				continue
			current_objective_positions.append(pos)
			objective_icons.append(emojis[next_objective_idx])
			break
	Lobby.server_on_stage_changed(stage, objective_icons, objective_owners)
