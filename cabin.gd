extends Sprite2D

enum ElevatorState {
    WAITING,       # 0
    IN_TRANSIT,    # 1
    OPENING,       # 2
    CLOSING        # 3
}

# Signals
signal elevator_available(floor_number: int)

# Constants
const ELEVATOR_SPEED = 200.0

# Properties
var state: ElevatorState = ElevatorState.WAITING
var current_floor: int = 2
var destination_floor: int = 1
var elevator_queue: Array = []

func _ready():
    SignalBus.floor_requested.connect(_on_floor_requested)

func _on_floor_requested(floors: int):
    if floors not in elevator_queue:
        elevator_queue.append(floors)
        print("Added floor:", floors, "to queue:", elevator_queue)

# Add a floor number to the elevator queue
func add_to_elevator_queue(floors: int):
    if floors not in elevator_queue:
        elevator_queue.append(floors)
        print("Added floor:", floors, "to queue:", elevator_queue)

# Remove a floor number from the elevator queue
func remove_from_elevator_queue(floors: int):
    if floors in elevator_queue:
        elevator_queue.erase(floors)
        print("Removed floor:", floors, "from queue:", elevator_queue)

func _physics_process(delta):
    if state == ElevatorState.WAITING and elevator_queue.size() > 0:
        if current_floor == elevator_queue[0]:
            # Elevator is already at the requested floor
            var arrived_floor = elevator_queue[0]
            remove_from_elevator_queue(arrived_floor)
            emit_signal("elevator_available", arrived_floor)
        else:
            destination_floor = elevator_queue[0]
            state = ElevatorState.IN_TRANSIT
    elif state == ElevatorState.IN_TRANSIT:
        var target_y = get_floor_y_position(destination_floor)
        var current_y = position.y
        var direction = (target_y - current_y)
        position.y += direction * ELEVATOR_SPEED * delta

        # Check if the elevator has reached the target floor
        if (direction == 0) or ((direction > 0 and position.y >= target_y) or (direction < 0 and position.y <= target_y)):
            position.y = target_y
            current_floor = destination_floor
            remove_from_elevator_queue(current_floor)
            state = ElevatorState.WAITING
            emit_signal("elevator_available", current_floor)

func get_floor_y_position(floor_number: int) -> float:
    # Adjust this function based on your floor layout
    return -(floor_number - 1) * 100.0  # Assuming each floor is 100 units apart
