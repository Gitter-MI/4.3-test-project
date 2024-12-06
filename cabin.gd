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
var current_floor: int = 1
var destination_floor: int = 1
var elevator_queue: Array = []  # Example: [{'target_floor': 1, 'sprite_name': "Player_1"}, ...]

const SCALE_FACTOR: float = 2.3
const SPEED: float = 200.0  # Pixels per second

# Variables to store target position
var target_position: Vector2 = Vector2.ZERO



func _ready():
    SignalBus.floor_requested.connect(_on_floor_requested)
    apply_scale_factor()
    position_cabin()
    z_index = -10

func _process(delta: float) -> void:
    match state:
        ElevatorState.WAITING:
            elevator_logic()
        ElevatorState.IN_TRANSIT:
            move_elevator(delta)

    
# **Updated Function: Elevator Logic**
func elevator_logic() -> void:
    if elevator_queue.size() > 0 and state == ElevatorState.WAITING:
        update_destination_floor()
        print("Elevator State: ", state, ", Current Floor: ", current_floor, ", Destination Floor: ", destination_floor, ", Queue: ", elevator_queue)
        
        # Check if the destination floor is the same as the current floor
        if destination_floor == current_floor:
            print("Elevator is already at the requested floor: ", current_floor)            
            var completed_request = elevator_queue[0]
            # Emit the elevator_arrived signal immediately
            SignalBus.elevator_arrived.emit(completed_request['sprite_name'], current_floor)
            # the request will be removed when the sprite signals the elevator that it has arrived at it's destination floor. This will be implemented later.             
        else:
            # Initialize target_position when starting transit
            initialize_target_position()
            update_state_to_in_transit()

# **Updated Function: Move the Elevator Cabin Vertically**
func move_elevator(delta: float) -> void:    
    if target_position == Vector2.ZERO:
        return  # No valid target position
    
    var current_pos = global_position
    var direction = sign(target_position.y - current_pos.y)
    var movement = SPEED * delta * direction
    var new_y = current_pos.y + movement
    
    if (direction > 0 and new_y >= target_position.y) or (direction < 0 and new_y <= target_position.y):
        new_y = target_position.y
        global_position.y = new_y
        current_floor = destination_floor
        
        # Retrieve and remove the completed request
        var completed_request = elevator_queue[0]     
        state = ElevatorState.OPENING
        print("Elevator has arrived at location: Floor ", current_floor)        
        # Emit the elevator_arrived signal with the completed request's sprite_name
        SignalBus.elevator_arrived.emit(completed_request['sprite_name'], current_floor)
        # the request will be removed when the sprite signals the elevator that it has arrived at it's destination floor. This will be implemented later. 
        # add new function to perform: the request will be removed if the sprite doesn't enter the elevator within two seconds after arrival. 
    else:
        # Continue moving towards the target
        global_position.y = new_y


# Initialize the target position based on the first request in the queue
func initialize_target_position() -> void:
    var request = elevator_queue[0]
    var target_floor_node = get_floor_by_number(request['target_floor'])
    if target_floor_node:
        var collision_edges = target_floor_node.get_collision_edges()
        target_position = get_elevator_position(collision_edges)
        print("Initialized target_position to: ", target_position)
    else:
        push_warning("Target floor %d not found" % request['target_floor'])



# Retrieve the floor node by its floor number
func get_floor_by_number(floor_number: int) -> Node2D:
    var floors = get_tree().get_nodes_in_group("floors")
    for building_floor in floors:
        if building_floor.floor_number == floor_number:
            return building_floor
    return null  # Floor not found

# Calculate the elevator's target position based on collision edges
func get_elevator_position(collision_edges: Dictionary) -> Vector2:
    var center_x: float = (collision_edges["left"] + collision_edges["right"]) / 2
    var sprite_height: float = get_cabin_height()
    var adjusted_y: float = collision_edges["bottom"] - sprite_height / 2
    return Vector2(center_x, adjusted_y)


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
