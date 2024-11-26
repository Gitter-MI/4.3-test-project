# SpriteData.gd
class_name SpriteData

var sprite_height: int = -1
var sprite_width: int = -1

var current_position: Vector2 = Vector2.ZERO
var current_floor_number: int = -1
var target_position: Vector2 = Vector2.ZERO
var target_floor_number: int = -1
var stored_target_position: Vector2 = Vector2.ZERO
var speed: float = 400.0
