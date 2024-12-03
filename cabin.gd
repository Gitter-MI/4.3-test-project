extends Sprite2D

enum ElevatorState {
    WAITING,       # 0
    IN_TRANSIT,    # 1
    OPENING,       # 2
    CLOSING        # 3
}

# Properties
var state: ElevatorState = ElevatorState.WAITING
var current_floor: int = 2
var destination_floor: int = 1
var elevator_queue: Array = []  # Example: [{'target_floor': 1, 'sprite_name': "Player_1"}, ...]

func _ready():
    SignalBus.floor_requested.connect(_on_floor_requested)

func _on_floor_requested(sprite_name: String, target_floor: int) -> void:
    # Check if this specific floor request by the sprite is already in the queue
    for request in elevator_queue:
        if request['target_floor'] == target_floor and request['sprite_name'] == sprite_name:
            return  # Ignore duplicate requests for the same floor by the same sprite

    # Add the new request to the queue
    elevator_queue.append({'target_floor': target_floor, 'sprite_name': sprite_name})
    print("Added floor: ", target_floor, " from sprite: ", sprite_name, " to queue: ", elevator_queue)


# func on_arrival at requested floor send signal to sprite


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
