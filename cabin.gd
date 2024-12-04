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
    # Iterate through the elevator_queue to check for existing requests from the same sprite
    for i in range(elevator_queue.size()):
        var request = elevator_queue[i]
        
        if request['sprite_name'] == sprite_name:
            if request['target_floor'] == target_floor:
                # Exact duplicate found; discard the new request
                print("Duplicate request ignored for sprite: ", sprite_name, " to floor: ", target_floor)
                return
            else:
                # Existing request from the same sprite with a different floor found
                # Replace the existing request with the new one at the same index
                elevator_queue[i] = {'target_floor': target_floor, 'sprite_name': sprite_name}
                print("Replaced request for sprite: ", sprite_name, " with new floor: ", target_floor)
                return
    
    # No existing request from this sprite; add the new request to the queue
    add_to_elevator_queue({'target_floor': target_floor, 'sprite_name': sprite_name})
    print("Added new request for sprite: ", sprite_name, " to floor: ", target_floor)

# Add a floor request to the elevator queue
func add_to_elevator_queue(request: Dictionary) -> void:
    # Append the new request to the end of the queue
    elevator_queue.append(request)
    print("Current elevator queue:", elevator_queue)

# Remove a specific request from the elevator queue
func remove_from_elevator_queue(request: Dictionary) -> void:
    # Ensure the request exists in the queue before removing
    if request in elevator_queue:
        elevator_queue.erase(request)
        print("Removed request:", request, "from queue:", elevator_queue)
    else:
        print("Request not found in queue:", request)



#region Cabin Set-Up

func apply_scale_factor():
    scale = Vector2.ONE * SCALE_FACTOR

func position_cabin():
    var viewport_size = get_viewport().size
    var x_position = viewport_size.x / 2  
    
    var floor_nodes = get_tree().get_nodes_in_group("floors")
    var floor_node = null
    
    for floors in floor_nodes:
        if floors.floor_number == current_floor:
            floor_node = floors
            break

    if not floor_node:
        push_warning("Floor node for floor %d not found" % current_floor)
        return
        
    var collision_edges = floor_node.get_collision_edges()
    var bottom_edge_y = collision_edges["bottom"]
    var cabin_height = get_cabin_height()
    var y_position = bottom_edge_y - (cabin_height / 2)
    global_position = Vector2(x_position, y_position)

func get_cabin_height():
    var sprite = get_node("Sprite2D")  # Replace "Sprite2D" with the actual sprite node name if different
    if sprite and sprite.texture:
        return sprite.texture.get_height() * scale.y
    else:
        return 0
#endregion
