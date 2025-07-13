extends Control

var GRAFFITI_FONT = preload("res://assets/Rock3D-Regular.ttf").duplicate()
var player_record = preload("res://objects/player_record.tscn")

@onready var player_list = $PlayersList
@onready var ip_list = $IpList

func _ready():
	for child in player_list.get_children():
		player_list.remove_child(child)
	
	var ips_text = ""
	var ips = Lobby.get_all_ips()
	for ip in ips:
		if !ips_text.is_empty():
			ips_text += "\n"
		ips_text += ip
	
	ip_list.add_theme_font_override("font", GRAFFITI_FONT)
	ip_list.text = ips_text
	
	Lobby.server_on_player_number_updated.connect(_on_number_updated)
	Lobby.server_on_party_leader_changed.connect(_server_on_party_leader_changed)
	_on_number_updated()


func _on_number_updated():
	for child in player_list.get_children():
		player_list.remove_child(child)
	
	for player in Lobby.players_in_lobby:
		var new_record = player_record.instantiate()
		#new_record.get_node("Sprite2D").texture = preload("")
		new_record.get_node("Name").text = (player as Lobby.LobbyPlayerInfo).Name
		
		player_list.add_child(new_record)


func _server_on_party_leader_changed(player_name):
	for child in player_list.get_children():
		child.get_node("Panel").visible = player_name == child.get_node("Name").text
