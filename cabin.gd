# cabing.gd
extends Node2D

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

const SCALE_FACTOR: float = 2.3

func _ready():
    SignalBus.floor_requested.connect(_on_floor_requested)
    apply_scale_factor()
    position_cabin()

func apply_scale_factor():
    # Apply the scale factor to the Cabin node
    scale = Vector2.ONE * SCALE_FACTOR

# Positions the cabin based on the current floor
func position_cabin():
    var viewport_size = get_viewport().size
    var x_position = viewport_size.x / 2  # Center horizontally

    # Retrieve all nodes in the "floors" group
    var floor_nodes = get_tree().get_nodes_in_group("floors")
    var floor_node = null

    # Iterate through the floor nodes to find the one matching current_floor
    for floors in floor_nodes:
        # Assume each floor node has a 'floor_number' property
        if floors.floor_number == current_floor:
            floor_node = floors
            break

    # If no matching floor node is found, log a warning and exit the function
    if not floor_node:
        push_warning("Floor node for floor %d not found" % current_floor)
        return

    # Get collision edges from the floor node
    var collision_edges = floor_node.get_collision_edges()
    var bottom_edge_y = collision_edges["bottom"]

    # Calculate the cabin's height after scaling
    var cabin_height = get_cabin_height()
    
    # Determine the Y position to place the cabin on top of the floor
    var y_position = bottom_edge_y - (cabin_height / 2)

    # Set the cabin's global position
    global_position = Vector2(x_position, y_position)

func get_cabin_height():
    var sprite = get_node("Sprite2D")  # Replace "Sprite2D" with the actual sprite node name if different
    if sprite and sprite.texture:
        return sprite.texture.get_height() * scale.y
    else:
        return 0

func get_floor_node(floor_number):
    var floor_path = "../Floors/Floor_%d" % floor_number  # Adjust the path according to your scene tree
    if has_node(floor_path):
        return get_node(floor_path)
    else:
        return null




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
