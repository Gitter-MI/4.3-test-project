extends Node

# state variables

var doors_opening: bool = false
var doors_open: bool = true
var doors_closing: bool = false
var doors_closed: bool = false
var request_started: bool = false
var request_finished: bool = false
var transit_occupied: bool = false
var transit_empty: bool = false

var elevator_occupied: bool = false



enum ElevatorState {
    WAITING,       # 0
    IN_TRANSIT     # 1
}

var state: ElevatorState = ElevatorState.WAITING  # initial state

var current_floor: int = 0  # for spawning only.
var destination_floor: int = 1  # for spawning only. If not used, remove

var elevator_direction: int = 0  # 1 = up, -1 = down, 0 = idle

var floor_boundaries = {}
var floor_to_elevator = {}
var floor_to_target_position = {}
var target_position: Vector2 = Vector2.ZERO

const SCALE_FACTOR: float = 2.3 
const SPEED: float = 500.0  # Pixels per second

var cabin_timer: Timer
var cabin_timer_timeout: int = 2
