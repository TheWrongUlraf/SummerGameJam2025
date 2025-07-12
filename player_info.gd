
class_name PlayerInfo

var player_id: int
var player_node: Node2D
var role: int
var caught: bool = false
var reveal_cooldown: float = 0
var name:= "N/A"

func _init(_player_id: int, _player_node: Node2D, _role: int, _name: String):
	player_id = _player_id
	player_node = _player_node
	role = _role
	name = _name
	
	
func _process(delta: float):
	if reveal_cooldown > 0:
		reveal_cooldown -= delta

func is_revealed() -> bool:
	return reveal_cooldown > 0
