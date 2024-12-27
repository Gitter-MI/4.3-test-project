extends Node2D

enum ElevatorState {
    WAITING,       # 0
    IN_TRANSIT    # 1
}


# ----------------------------------------------------------------
# Add a variable to store elevator direction.
#   We'll treat  1  => going up
#               -1 => going down
#                0 => idle/no movement
# ----------------------------------------------------------------
var elevator_direction: int = 0

# This dictionary will map floor_number -> Dictionary with keys "upper_edge" and "lower_edge"
var floor_boundaries = {}


# Properties
var state: ElevatorState = ElevatorState.WAITING
var current_floor: int = 5
var destination_floor: int = 1
var elevator_queue: Array = []  # Example: [{'target_floor': 1, 'sprite_name': "Player_1"}, ...]

var floor_to_elevator = {}
var floor_to_target_position = {}

const SCALE_FACTOR: float = 2.3
const SPEED: float = 100.0  # Pixels per second

var target_position: Vector2 = Vector2.ZERO
var cabin_timer: Timer

func _ready():
    add_to_group("cabin")
    SignalBus.elevator_request.connect(_on_elevator_request)
    SignalBus.entering_elevator.connect(_on_sprite_entering)
    SignalBus.enter_animation_finished.connect(_on_sprite_entered)
    SignalBus.exiting_elevator.connect(_on_sprite_exiting)
    SignalBus.door_state_changed.connect(_on_elevator_door_state_changed)    

    apply_scale_factor()
    position_cabin()
    z_index = -10
    
    cache_elevators()
    cache_floor_positions()

    # setup_cabin_timer(2.0)  ## timer functionality has been temporarily disabled

    var elevator = get_elevator_for_current_floor()
    if elevator:
        elevator.set_door_state(elevator.DoorState.OPEN)
        # print("Initial elevator doors opened at floor:", current_floor)


func _process(delta: float) -> void:
    
    match state:
        ElevatorState.WAITING:
            elevator_logic()
        ElevatorState.IN_TRANSIT:
            move_elevator(delta)

func elevator_logic() -> void:
    
    if elevator_queue.size() > 0:        
        if destination_floor != current_floor:
            var elevator = floor_to_elevator.get(current_floor, null)
            elevator.set_door_state(elevator.DoorState.CLOSING)
        else:
            handle_same_floor_request()


func handle_same_floor_request() -> void:
    print("handle_same_floor_request")
    var request = elevator_queue[0]
    SignalBus.elevator_arrived.emit(request['sprite_name'], current_floor)   
    # print("SignalBus.elevator_arrived, handle_same_floor_request") 



func _on_sprite_entering():
    state = ElevatorState.IN_TRANSIT


func move_elevator(delta: float) -> void:
    if target_position == Vector2.ZERO:
        return

    var direction = sign(target_position.y - global_position.y)
    var movement = SPEED * delta * direction
    var new_y = global_position.y + movement

    # Check if we reach or pass the target position
    if (direction > 0 and new_y >= target_position.y) or (direction < 0 and new_y <= target_position.y):
        global_position.y = target_position.y
        handle_arrival()
    else:
        global_position.y = new_y

    # *** 1) Check which floor we’re on now (NEW HELPER CALL) ***
    check_current_floor()

    # *** 2) Emit elevator position so sprites inside can follow ***
    SignalBus.elevator_position_updated.emit(global_position)



func check_current_floor() -> void:
    # 1) Determine the top and bottom edges of the elevator in global space
    var cabin_half_height = get_cabin_height() * 0.5
    var cabin_top_edge    = global_position.y - cabin_half_height
    var cabin_bottom_edge = global_position.y + cabin_half_height

    # 2) If we’re moving up, check if our top edge has passed the "upper_edge" boundary
    if elevator_direction == 1:
        var next_floor = current_floor + 1
        if floor_boundaries.has(next_floor):
            var next_floor_data = floor_boundaries[next_floor]
            var next_upper_edge = next_floor_data["upper_edge"]
            # If the top edge has moved BELOW next_floor's upper_edge,
            # it means we’ve effectively entered that next floor's region.
            if cabin_top_edge <= next_upper_edge:
                current_floor = next_floor
                print("Elevator is now considered on floor:", current_floor)

    # 3) If we’re moving down, check if our bottom edge has passed the "lower_edge" boundary
    elif elevator_direction == -1:
        var prev_floor = current_floor - 1
        if floor_boundaries.has(prev_floor):
            var prev_floor_data = floor_boundaries[prev_floor]
            var prev_lower_edge = prev_floor_data["lower_edge"]
            # If the bottom edge has moved ABOVE prev_floor's lower_edge,
            # it means we’ve effectively entered that floor's region.
            if cabin_bottom_edge >= prev_lower_edge:
                current_floor = prev_floor
                print("Elevator is now considered on floor:", current_floor)



# we can treat 
func handle_arrival() -> void:
    # Elevator has arrived at the target floor
    current_floor = destination_floor
    var completed_request = elevator_queue[0]
    var elevator = floor_to_elevator.get(current_floor, null)

    if elevator:
        elevator.set_door_state(elevator.DoorState.OPENING)
        SignalBus.elevator_arrived.emit(completed_request['sprite_name'], current_floor)
        # print("SignalBus.elevator_arrived, handle_arrival")         



func _on_sprite_entered(sprite_name: String, target_floor: int) -> void:
    # cabin_timer.stop()    
    var elevator = floor_to_elevator.get(current_floor, null)    
    elevator.set_door_state(elevator.DoorState.CLOSING)    
    update_elevator_queue(sprite_name, target_floor)
    update_destination_floor()
    # print("sprite is entering")


func _on_sprite_exiting(sprite_name: String) -> void:    
    remove_from_elevator_queue(sprite_name)
    
    
func _on_elevator_door_state_changed(new_state):
    var elevator = floor_to_elevator.get(current_floor, null)
    if elevator == null:
        return

    match new_state:
        elevator.DoorState.OPEN:
            state = ElevatorState.WAITING
            reset_elevator_direction()   # Doors opened => elevator is now waiting.

        elevator.DoorState.CLOSED:
            state = ElevatorState.IN_TRANSIT
            set_elevator_direction()     # Doors closing => set direction for next ride.
            if destination_floor != current_floor:
                initialize_target_position()


func set_elevator_direction() -> void:
    var new_direction: int = 0
    if elevator_queue.size() > 0:
        var next_floor = elevator_queue[0]["target_floor"]
        if next_floor > current_floor:
            new_direction = 1   # up
        elif next_floor < current_floor:
            new_direction = -1  # down
        else:
            new_direction = 0   # same floor
    else:
        new_direction = 0

    # Check if the direction has changed before updating
    if elevator_direction != new_direction:
        elevator_direction = new_direction
        _print_elevator_direction()

func reset_elevator_direction() -> void:
    if elevator_direction != 0:
        elevator_direction = 0
        _print_elevator_direction()


func _print_elevator_direction() -> void:
    match elevator_direction:
        1:
            print("Elevator direction changed to: UP")
        -1:
            print("Elevator direction changed to: DOWN")
        0:
            print("Elevator direction changed to: IDLE")


func initialize_target_position() -> void:
    var request = elevator_queue[0]
    var target_floor = request['target_floor']    
    target_position = floor_to_target_position[target_floor]


func update_destination_floor() -> void:    
    if elevator_queue.size() > 0:
        destination_floor = elevator_queue[0]['target_floor']


func _on_elevator_request(sprite_name: String, target_floor: int) -> void:
    
    
    
    var request_updated = false
    for i in range(elevator_queue.size()):
        var request = elevator_queue[i]
        if request['sprite_name'] == sprite_name:
            if request['target_floor'] == target_floor:
                print("Duplicate request ignored for sprite:", sprite_name, "to floor:", target_floor)
                return
            else:
                elevator_queue[i] = {'target_floor': target_floor, 'sprite_name': sprite_name}
                print("Replaced request for sprite:", sprite_name, "with new floor:", target_floor)
                request_updated = true
                break

    if not request_updated:
        add_to_elevator_queue({'target_floor': target_floor, 'sprite_name': sprite_name})
        # print("Added new request for sprite:", sprite_name, "to floor:", target_floor)

    update_destination_floor()

    # -------------------------------
    # NEW: If we are already in transit, re-initialize target position
    # so the elevator doesn't keep going to the old floor.
    # -------------------------------
    if request_updated and state == ElevatorState.IN_TRANSIT:
        initialize_target_position()






func _on_cabin_timer_timeout() -> void:
    ## Cabin timer has been temporarily removed
    pass
    ## If the queue is empty, do nothing
    #if elevator_queue.size() == 0:
        #print("Timer fired but queue was empty, ignoring.")
        #return
#
    ## If we’re in WAITING state, remove the oldest request
    #if state == ElevatorState.WAITING:
        #var timed_out_request = elevator_queue[0]
        #remove_from_elevator_queue(timed_out_request)
        #print("No action taken within 2 seconds, removed request:", timed_out_request)





#region elevator queue management
func add_to_elevator_queue(request: Dictionary) -> void:
    # print("add_to_elevator_queue called")
    elevator_queue.append(request)
    # print("Current elevator queue:", elevator_queue)



func remove_from_elevator_queue(sprite_name: String) -> void:
    
    for i in range(elevator_queue.size()):
        var queue_req = elevator_queue[i]
    
        if queue_req.has("sprite_name") and queue_req["sprite_name"] == sprite_name:
            elevator_queue.remove_at(i)
            # print("Removed request for:", sprite_name, ", updated queue:", elevator_queue)
            return
    
    print("No elevator request found for:", sprite_name)



func update_elevator_queue(sprite_name: String, new_target_floor: int) -> void:
    # print("update_elevator_queue called")
    for item in elevator_queue:
        if item.has("sprite_name") and item["sprite_name"] == sprite_name:
            item["target_floor"] = new_target_floor
            return
#endregion

#region cabin Set-Up
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
    var sprite = get_node("Sprite2D")  # Adjust node path if your sprite differs
    if sprite and sprite.texture:
        return sprite.texture.get_height() * scale.y
    else:
        return 0

func get_elevator_position(collision_edges: Dictionary) -> Vector2:        
    var center_x: float = (collision_edges["left"] + collision_edges["right"]) / 2
    var sprite_height: float = get_cabin_height()
    var adjusted_y: float = collision_edges["bottom"] - sprite_height / 2
    return Vector2(center_x, adjusted_y)

func setup_cabin_timer(wait_time: float) -> void:
    cabin_timer = Timer.new()
    cabin_timer.one_shot = true
    cabin_timer.wait_time = wait_time
    cabin_timer.timeout.connect(_on_cabin_timer_timeout)
    add_child(cabin_timer)


func cache_elevators():
    var elevators = get_tree().get_nodes_in_group("elevators")
    for elevator in elevators:
        if elevator.floor_instance:
            floor_to_elevator[elevator.floor_instance.floor_number] = elevator

func cache_floor_positions():
    var floors = get_tree().get_nodes_in_group("floors")
    for building_floor in floors:
        if building_floor.has_method("get_collision_edges"):
            var collision_edges = building_floor.get_collision_edges()

            # Optional: store the elevator's center position (already done)
            var target_pos = get_elevator_position(collision_edges)
            floor_to_target_position[building_floor.floor_number] = target_pos

            # Compute 25% and 99% Y-coordinates for this floor's bounding area
            var floor_bottom = collision_edges["bottom"]
            var floor_top    = collision_edges["top"]
            # Example:
            var height = floor_bottom - floor_top
            var lower_edge  = floor_top
            var upper_edge  = floor_top    + (height * 1.25)  # 25% from top. We are using the next floor as reference in the check function. That's why we adjust by 125%, to account for the actual current floor. 

            floor_boundaries[building_floor.floor_number] = {
                "upper_edge": upper_edge,
                "lower_edge": lower_edge
            }

           

func get_elevator_for_floor(floor_number: int) -> Area2D:    
    return floor_to_elevator.get(floor_number, null)

func get_elevator_for_current_floor() -> Area2D:    
    return get_elevator_for_floor(current_floor)

#endregion
