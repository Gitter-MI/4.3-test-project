# SpriteData_new.gd
extends Resource
class_name SpriteDataNew

# new state machine
enum MovementState { IDLE, WALKING, NONE }
enum RoomState { CHECKING_ROOM_STATE, ENTERING_ROOM, IN_ROOM, EXITING_ROOM, NONE }
enum ElevatorState { WAITING_FOR_ELEVATOR, ENTERING_ELEVATOR, IN_ELEVATOR_ROOM, IN_ELEVATOR_TRANSIT, EXITING_ELEVATOR, NONE }

var movement_state: MovementState = MovementState.IDLE
var room_state: RoomState = RoomState.NONE
var elevator_state: ElevatorState = ElevatorState.NONE

var sprite_name: String = "Player_2"
var sprite_height: int = -1
var sprite_width: int = -1
var speed: float = 400.0

var current_position: Vector2 = Vector2.ZERO
var current_floor_number: int = 3                   # initial spawn floor
var current_room: int = -1                          # spawns 'on the floor'

var target_position: Vector2 = Vector2.ZERO
var target_floor_number: int = 3                    # initial spawn floor
var target_room: int = -1

var stored_target_position: Vector2 = Vector2.ZERO
var stored_target_floor: int = -1
var stored_target_room: int = -1

var nav_target_position: Vector2 = Vector2.ZERO
var nav_target_floor: int = -1
var nav_target_room: int = -1


# old helper variables
var needs_elevator: bool = false  # may not be needed anymore with the stored position indicating elevator need
# var current_elevator_position: Vector2 = Vector2.ZERO   # needed for sync movement with the elevator # may be redundant with the navigation controller in place
var elevator_y_offset # needed for sync elevator movement, # may be redundant with the navigation controller in place

# Old variables for storing the click data while IN_ELEVATOR
var elevator_stored_target_position: Vector2 = Vector2.ZERO
var elevator_stored_target_floor_number: int = -1
var elevator_stored_target_room: int = -1
