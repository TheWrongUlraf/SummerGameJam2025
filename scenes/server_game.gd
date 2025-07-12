extends Node2D


var players := {}

func update_player_position(player_id: int, pos: Vector2):
	if players.has(player_id):
		players.get(player_id).player_node.position = pos
	else:
		var playerSprite = Sprite2D.new()
		playerSprite.texture = load("res://assets/art/point.png")
		playerSprite.global_position = pos
		players.set(player_id, PlayerInfo.new(playerSprite))
		add_child(playerSprite)
		
