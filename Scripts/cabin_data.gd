extends Node



enum ElevatorState {
    WAITING,       # 0
    IN_TRANSIT     # 1
}

var state: ElevatorState = ElevatorState.WAITING  # initial state

var current_floor: int = 0  # for spawning only.
var destination_floor: int = 1  # for spawning only. If not used, remove


var elevator_occupied: bool = false
var elevator_direction: int = 0  # 1 = up, -1 = down, 0 = idle
var next_request_id: int = 10

# queue into the queue manager? 
var elevator_queue: Array = []  # Example: [{'pick_up_floor', 'destination_floor', 'sprite_name': "Player_1", 'request_id': 1}, ...]


var floor_boundaries = {}
var floor_to_elevator = {}
var floor_to_target_position = {}
var target_position: Vector2 = Vector2.ZERO


const SCALE_FACTOR: float = 2.3 
const SPEED: float = 500.0  # Pixels per second






var cabin_timer: Timer
var cabin_timer_timeout: int = 2
