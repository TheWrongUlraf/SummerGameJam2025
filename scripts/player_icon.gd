extends Node2D

@onready var sprite: Sprite2D = get_node("Sprite2D")
@onready var nameLabel: RichTextLabel = get_node("NameLabel")

var player_info: PlayerInfo

func setup_icon(_player_info: PlayerInfo):
	player_info = _player_info
	
func _ready() -> void:
	if player_info.role == Lobby.ROLE_POLICE:
		sprite.texture = load("res://assets/art/PoliceCar.png")
		sprite.scale = Vector2(0.2, 0.2)
		self.visible = true
	else:
		sprite.texture = load("res://assets/art/point.png")
		self.visible = false
		
	nameLabel.text = player_info.name
