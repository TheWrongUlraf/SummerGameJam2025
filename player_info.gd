
class_name PlayerInfo

var player_id: int
var player_node: Node2D
var role: int

func _init(_player_id: int, _player_node: Node2D, _role: int):
	player_id = _player_id
	player_node = _player_node
	role = _role
