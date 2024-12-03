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


func _process(delta: float) -> void:
    elevator_logic(delta)
    
func elevator_logic(delta: float) -> void:
    if elevator_queue.size() > 0 and state == ElevatorState.WAITING:
        update_destination_floor()
        update_state_to_in_transit()
        print("Elevator State: ", state, ", Current Floor: ", current_floor, ", Destination Floor: ", destination_floor, ", Queue: ", elevator_queue)
        # add call to elevator transit function
    else:
        pass  # Queue is empty

func update_destination_floor() -> void:
    # Set destination_floor to the first request in the queue
    if elevator_queue.size() > 0:
        destination_floor = elevator_queue[0]['target_floor']

func update_state_to_in_transit() -> void:
    # Update the state to IN_TRANSIT
    state = ElevatorState.IN_TRANSIT



# Handle a floor request by a sprite
func _on_floor_requested(sprite_name: String, target_floor: int) -> void:
    # Check if this specific floor request by the sprite is already in the queue
    for request in elevator_queue:
        if request['target_floor'] == target_floor and request['sprite_name'] == sprite_name:
            return  # Ignore duplicate requests for the same floor by the same sprite

    # Delegate adding the request to the helper function
    add_to_elevator_queue({'target_floor': target_floor, 'sprite_name': sprite_name})
    # print("Added floor: ", target_floor, " from sprite: ", sprite_name, " to queue: ", elevator_queue)


# Add a floor request to the elevator queue
func add_to_elevator_queue(request: Dictionary) -> void:
    # Ensure the request is valid before appending
    if request not in elevator_queue:
        elevator_queue.append(request)
        # print("Added request:", request, "to queue:", elevator_queue)

# Remove a specific request from the elevator queue
func remove_from_elevator_queue(request: Dictionary) -> void:
    # Ensure the request exists in the queue before removing
    if request in elevator_queue:
        elevator_queue.erase(request)
        print("Removed request:", request, "from queue:", elevator_queue)
