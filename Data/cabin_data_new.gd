# cabin_data_new.gd
extends Node

enum ElevatorState { IDLE, WAITING, DEPARTING, TRANSIT, ARRIVING}
var elevator_state: ElevatorState = ElevatorState.IDLE  # initial state

func set_elevator_state(new_state: ElevatorState) -> void:    
    elevator_state = new_state

var elevator_busy: bool = false # are there requests in the elevator queue?
var pick_up_on_current_floor: bool = false  # does the next request in the queue have pick-up at the current floor

var elevator_occupied: bool = false ## when occupied other sprites cannot enter the elevator (only one sprite in the elevator)
var sprite_entered: bool = false


var elevator_ready_emitted: bool = false # used in WAITING state


var elevator_queue_reordered: bool = false

var elevator_ready: bool = false # is used?

var doors_opening: bool = false
var doors_open: bool = true
var doors_closing: bool = false
var doors_closed: bool = false





var current_floor: int = 3 ## used in the new implementation  # for spawning only.
var destination_floor: int = 3  # for spawning only. If not used, remove

var elevator_direction: int = 0  # 1 = up, -1 = down, 0 = idle

var floor_boundaries = {} ## used in the new implementation
var floor_to_elevator = {} ## used in the new implementation
var floor_to_target_position = {} ## used in the new implementation
var target_position: Vector2 = Vector2.ZERO

const SCALE_FACTOR: float = 2.3 
const SPEED: float = 800.0  # Pixels per second


var cabin_timer: Timer
var cabin_timer_timeout: int = 2
