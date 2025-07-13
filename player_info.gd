
class_name PlayerInfo

var player_id: int
var player_node: Node2D
var role: int
var caught: bool = false
var caught_cooldown: float = 0
var reveal_cooldown: float = 0
var detected_cooldown: float = 0
var name:= "N/A"
var last_placed_emoji_time: float = 0.0
var icon_id = 0

func _init(_player_id: int, _player_node: Node2D, _role: int, _name: String, _icon: int):
	player_id = _player_id
	player_node = _player_node
	role = _role
	name = _name
	icon_id = _icon


func _process(delta: float):
	if reveal_cooldown > 0:
		reveal_cooldown -= delta
	if caught_cooldown > 0:
		caught_cooldown -= delta
	if detected_cooldown > 0:
		detected_cooldown -= delta

func is_revealed() -> bool:
	return reveal_cooldown > 0
