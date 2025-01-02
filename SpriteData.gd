# SpriteData.gd
extends Resource
class_name SpriteData

# Define the possible states a sprite can be in
enum State {
    IDLE,                       # 0
    WALKING,                    # 1
    IN_ROOM,                    # 2
    ENTERING_ROOM,              # 3
    IN_ELEVATOR,                # 4
    WAITING_FOR_ELEVATOR,       # 5
    EXITING_ELEVATOR,           # 6
    ENTERING_ELEVATOR           # 7
}

# Sprite properties
var sprite_name: String = "Player_1"

var sprite_height: int = -1
var sprite_width: int = -1

var current_position: Vector2 = Vector2.ZERO
var current_floor_number: int = 2                   # initial spawn floor
var target_position: Vector2 = Vector2.ZERO
var target_floor_number: int = 2                   # initial spawn floor
var stored_target_position: Vector2 = Vector2.ZERO
var speed: float = 400.0

var current_room: int = -1                          # spawns 'on the floor'
var target_room: int = -1

var needs_elevator: bool = false
var current_elevator_position: Vector2 = Vector2.ZERO

var elevator_y_offset



# Add a variable to track the current state of the sprite
var current_state: State = State.IDLE


# New variables for storing the click data while IN_ELEVATOR
var elevator_stored_target_position: Vector2 = Vector2.ZERO
var elevator_stored_target_floor_number: int = -1
var elevator_stored_target_room: int = -1
