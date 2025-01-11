# SpriteData_new.gd
extends Resource


# new state machine
enum MovementState { IDLE, WALKING, NONE }
enum RoomState { CHECKING_ROOM_STATE, ENTERING_ROOM, IN_ROOM, EXITING_ROOM, NONE }
enum ElevatorState { WAITING_FOR_ELEVATOR, ENTERING_ELEVATOR, IN_ELEVATOR_ROOM, IN_ELEVATOR_TRANSIT, EXITING_ELEVATOR, NONE }
enum ActiveState { NONE, MOVEMENT, ROOM, ELEVATOR }


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

var has_stored_data: bool = false
var stored_target_position: Vector2 = Vector2.ZERO
var stored_target_floor: int = -1
var stored_target_room: int = -1

var has_nav_data: bool = false
var nav_target_position: Vector2 = Vector2.ZERO
var nav_target_floor: int = -1
var nav_target_room: int = -1


func needs_elevator(destination_floor: int) -> bool:
    return current_floor_number != destination_floor

func get_active_state() -> ActiveState:
    if movement_state != MovementState.NONE:
        return ActiveState.MOVEMENT
    if room_state != RoomState.NONE:
        return ActiveState.ROOM
    if elevator_state != ElevatorState.NONE:
        return ActiveState.ELEVATOR
    
    return ActiveState.NONE


# sprite_data_new.set_elevator_state(SpriteDataNew.ElevatorState.WAITING_FOR_ELEVATOR)
func get_active_sub_state() -> String:    
    if movement_state != MovementState.NONE:
        return "movement:%s" % movement_state
    if room_state != RoomState.NONE:
        return "room:%s" % room_state
    if elevator_state != ElevatorState.NONE:
        return "elevator:%s" % elevator_state
    return "none"

#region Set States

func set_movement_state(new_state: MovementState) -> void:    
    movement_state = new_state
    room_state = RoomState.NONE
    elevator_state = ElevatorState.NONE


func set_room_state(new_state: RoomState) -> void:    
    room_state = new_state
    movement_state = MovementState.NONE
    elevator_state = ElevatorState.NONE


func set_elevator_state(new_state: ElevatorState) -> void:    
    elevator_state = new_state
    movement_state = MovementState.NONE
    room_state = RoomState.NONE
#endregion

#region Set and Re-Set Position Data
func set_current_position(new_position: Vector2, floor_number: int, room_index: int) -> void:
    current_position = new_position
    current_floor_number = floor_number
    current_room = room_index

func set_target_position(new_position: Vector2, floor_number: int, room_index: int) -> void:
    target_position = new_position
    target_floor_number = floor_number
    target_room = room_index

func set_stored_position(new_position: Vector2, floor_number: int, room_index: int) -> void:
    has_stored_data = true
    stored_target_position = new_position
    stored_target_floor = floor_number
    stored_target_room = room_index

func set_sprite_nav_data(_click_global_position: Vector2, _floor_number: int, _door_index: int) -> void:
    
    # print("Setting sprite nav data...")
    has_nav_data = true
    nav_target_position = _click_global_position
    nav_target_floor    = _floor_number
    nav_target_room     = _door_index
    
    # print("nav data has been set to: ")
    #print("nav_target_position: ",nav_target_position)
    #print("nav_target_floor: ",nav_target_floor)
    #print("nav_target_room: ",nav_target_room)
    
func reset_nav_data() -> void:
    has_nav_data = false
    nav_target_position = Vector2.ZERO
    nav_target_floor = -1
    nav_target_room = -1

func reset_stored_data() -> void:
    has_stored_data = false
    stored_target_position = Vector2.ZERO
    stored_target_floor = -1
    stored_target_room = -1
#endregion
