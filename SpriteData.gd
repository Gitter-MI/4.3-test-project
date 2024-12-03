# SpriteData.gd
class_name SpriteData

var sprite_name: String = "Player_1"

var sprite_height: int = -1
var sprite_width: int = -1

var current_position: Vector2 = Vector2.ZERO
var current_floor_number: int = 1                   # initial spawn floor
var target_position: Vector2 = Vector2.ZERO
var target_floor_number: int = 1                    # initial spawn floor
var stored_target_position: Vector2 = Vector2.ZERO
var speed: float = 400.0

var current_room: int = -1                          # spawns 'on the floor'
var target_room: int = -1

var needs_elevator: bool = false
var current_elevator_position: Vector2 = Vector2.ZERO
