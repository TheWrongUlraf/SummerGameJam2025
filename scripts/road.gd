@tool
extends Node2D

enum RoadType { STRAIGHT, BEND, T_INTERSECTION, PLUS_INTERSECTION }
enum Rotation { R0 = 0, R90 = 90, R180 = 180, R270 = 270 }

var _road_type_internal := RoadType.STRAIGHT
@export var road_type: RoadType:
	set(value):
		if _road_type_internal != value:
			_road_type_internal = value
			
			for child in get_children():
				child.queue_free()
			var scene = load("res://objects/roads/" + get_enum_name(value) + ".tscn")
			if scene:
				add_child(scene.instantiate())
	get:
		return _road_type_internal

var _rotation_internal := Rotation.R0
@export var round_rotation: Rotation:
	set(value):
		if _rotation_internal != value:
			_rotation_internal = value
			
			rotation = deg_to_rad(value)
	get:
		return _rotation_internal

func get_enum_name(value: int) -> String:
	for player_name in RoadType.keys():
		if RoadType[player_name] == value:
			return player_name
	return "Unknown"
