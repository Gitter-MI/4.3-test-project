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
const SPEED: float = 400.0  # Pixels per second

var target_position: Vector2 = Vector2.ZERO
var cabin_timer: Timer

func _ready():
    SignalBus.floor_requested.connect(_on_floor_requested)
    SignalBus.entering_elevator.connect(_on_sprite_entering)
    SignalBus.exiting_elevator.connect(_on_sprite_exiting)
    apply_scale_factor()
    position_cabin()
    z_index = -10

    cabin_timer = Timer.new()
    cabin_timer.one_shot = true
    cabin_timer.wait_time = 2.0
    cabin_timer.timeout.connect(_on_cabin_timer_timeout)
    add_child(cabin_timer)


func _process(delta: float) -> void:
    match state:
        ElevatorState.WAITING:
            elevator_logic()
        ElevatorState.CLOSING:
            handle_closing()
        ElevatorState.IN_TRANSIT:
            move_elevator(delta)
        ElevatorState.OPENING:
            handle_opening()




func _on_sprite_entering(sprite_name: String, target_floor: int) -> void:    
    cabin_timer.stop()
    handle_closing()
    state = ElevatorState.WAITING
    print("sprite is entering")

    # Update elevator queue item that belongs to the sprite_name
    update_elevator_queue(sprite_name, target_floor)



func _on_sprite_exiting(sprite_name: String, target_floor: int) -> void:    
    handle_opening()
    state = ElevatorState.WAITING
    cabin_timer.stop()
    
    for request in elevator_queue:
        if request.has("sprite_name") and request["sprite_name"] == sprite_name \
                and request.has("target_floor") and request["target_floor"] == target_floor:
            remove_from_elevator_queue(request)
            break


func update_elevator_queue(sprite_name: String, new_target_floor: int) -> void:
    for item in elevator_queue:
        if item.has("sprite_name") and item["sprite_name"] == sprite_name:
            item["target_floor"] = new_target_floor
            return



func elevator_logic() -> void:
    # If we have a request and we are waiting
    if elevator_queue.size() > 0 and state == ElevatorState.WAITING:
        update_destination_floor()
        if destination_floor != current_floor:
            initialize_target_position()
            # Instead of going directly to IN_TRANSIT, go through CLOSING first
            state = ElevatorState.CLOSING
        else:
            # Already at the correct floor
            handle_same_floor_request()


func move_elevator(delta: float) -> void:
    if target_position == Vector2.ZERO:
        return  # No valid target position set yet

    var direction = sign(target_position.y - global_position.y)
    var movement = SPEED * delta * direction
    var new_y = global_position.y + movement

    # Check if we reach or pass the target position this frame
    if (direction > 0 and new_y >= target_position.y) or (direction < 0 and new_y <= target_position.y):
        # Snap to target position
        global_position.y = target_position.y
        handle_arrival()
    else:
        global_position.y = new_y


func handle_arrival() -> void:
    # Elevator has arrived at the target floor
    current_floor = destination_floor
    var completed_request = elevator_queue[0]
    handle_opening()
    SignalBus.elevator_arrived.emit(completed_request['sprite_name'], current_floor)    
    cabin_timer.start()
    

func handle_same_floor_request() -> void:
    var request = elevator_queue[0]
    SignalBus.elevator_arrived.emit(request['sprite_name'], current_floor)
    
    state = ElevatorState.WAITING
    

func arrived_at_target_floor() -> bool:
    # Check if elevator is at target_position
    return global_position.y == target_position.y


func handle_closing() -> void:
    # Placeholder for closing doors. In the future, add door closing animations/timers.
    # Once done, go to IN_TRANSIT to start moving.
    state = ElevatorState.IN_TRANSIT    


func handle_opening() -> void:
    # Placeholder for opening doors. After "opening" doors, return to WAITING.
    # This simulates that the elevator is now idle at the floor with doors open.
    state = ElevatorState.WAITING


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

func add_to_elevator_queue(request: Dictionary) -> void:
    # For testing purposes: Add the hardcoded dummy request from Player 2 to floor 0. Do not remove. 
    # var dummy_request = {"target_floor": 0, "sprite_name": "Player_2"}     
    
    # Append the new request to the end of the queue
    elevator_queue.append(request)
    # elevator_queue.append(dummy_request)
    print("Current elevator queue:", elevator_queue)

# Remove a specific request from the elevator queue
func remove_from_elevator_queue(request: Dictionary) -> void:
    # print("remove_from_elevator_queue called")
    # Ensure the request exists in the queue before removing
    if request in elevator_queue:
        elevator_queue.erase(request)
        print("Removed request:", request, "from queue:", elevator_queue)
    else:
        print("Request not found in queue:", request)

# Timer Timeout Callback
func _on_cabin_timer_timeout():    
    # If the elevator is still waiting after 2 seconds, remove the first request from the queue.
    if state == ElevatorState.WAITING and elevator_queue.size() > 0:
        var timed_out_request = elevator_queue[0]
        remove_from_elevator_queue(timed_out_request)
        print("No action taken within 2 seconds, removed request:", timed_out_request)


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
