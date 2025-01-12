# Move all state variables and properties to a cabin sprite resource

extends Node2D


@onready var testing_requests_node = %TestingRequests

enum ElevatorState {
    WAITING,       # 0
    IN_TRANSIT     # 1
}

var elevator_direction: int = 0  # 1 = up, -1 = down, 0 = idle
var floor_boundaries = {}  # used to determine which floor the elevator is on while in transit


var state: ElevatorState = ElevatorState.WAITING
var current_floor: int = 5
var destination_floor: int = 1
var elevator_queue: Array = []  # Example: [{'target_floor': 1, 'sprite_name': "Player_1"}, ...]

var floor_to_elevator = {}
var floor_to_target_position = {}

const SCALE_FACTOR: float = 2.3
const SPEED: float = 400.0  # Pixels per second

var target_position: Vector2 = Vector2.ZERO
var cabin_timer: Timer
var cabin_timer_timeout: int = 2

func _ready():
    add_to_group("cabin")
    SignalBus.elevator_called.connect(_on_elevator_request)
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

    var elevator = get_elevator_for_current_floor()    
    elevator.set_door_state(elevator.DoorState.OPEN)
    setup_cabin_timer(2.0)  ## timer functionality has been temporarily disabled
    

func _process(delta: float) -> void:
    
    match state:
        ElevatorState.WAITING:            
            elevator_logic()
            
        ElevatorState.IN_TRANSIT:
            move_elevator(delta)
            
func process_next_request():
    # If queue is empty, do nothing
    if elevator_queue.is_empty():
        print("No requests left. Elevator is idle.")
        return
    
    update_destination_floor()
    if destination_floor != current_floor:
        var elevator = floor_to_elevator.get(current_floor, null)
        if elevator:
            elevator.set_door_state(elevator.DoorState.CLOSING)
    else:
        handle_same_floor_request()
        # if elevator is waiting at the same floor as before then start the timer again. Could be necesary only because of the test case. Otherwise the second sprite could just enter.
        if cabin_timer.is_stopped():
            cabin_timer.start()
        else:
            # push_warning("Cabin timer is already running.")
            pass


func elevator_logic() -> void:
    
    if elevator_queue.size() > 0:    
        process_next_request()    
        if destination_floor != current_floor:
            var elevator = floor_to_elevator.get(current_floor, null)
            elevator.set_door_state(elevator.DoorState.CLOSING)
        else:
            handle_same_floor_request()


func handle_same_floor_request() -> void:
    # print("handle_same_floor_request")
    var request = elevator_queue[0]
    SignalBus.elevator_arrived.emit(request['sprite_name'], current_floor)
    
    # print("SignalBus.elevator_arrived, handle_same_floor_request") 


func _on_sprite_entering():
    state = ElevatorState.IN_TRANSIT


func _on_sprite_entered(sprite_name: String, target_floor: int) -> void:
    # cabin_timer.stop()    
    var elevator = floor_to_elevator.get(current_floor, null)    
    elevator.set_door_state(elevator.DoorState.CLOSING)        
    update_elevator_queue(sprite_name, target_floor)
    update_destination_floor()
    


func move_elevator(delta: float) -> void:
    if target_position == Vector2.ZERO:        
        return  # Elevator doesn't have a target different from it's current position, so just return

    # Only stop if it's actually running:
    if not cabin_timer.is_stopped():
        # push_warning("Cabin timer is running while cabin is moving. Stopping it now.")
        cabin_timer.stop() # attempt to prevent the timer from removing requests while the current request is being processed, which could lead to an out-of-bounds error in on_arrival



    var elevator = floor_to_elevator.get(current_floor, null)    
    if elevator.door_state != elevator.DoorState.CLOSED:
        return
    
    var direction = sign(target_position.y - global_position.y)
    var movement = SPEED * delta * direction
    var new_y = global_position.y + movement
    
    if (direction > 0 and new_y >= target_position.y) or (direction < 0 and new_y <= target_position.y):
        global_position.y = target_position.y
        handle_arrival()
    else:
        global_position.y = new_y
    
    check_current_floor()
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
            if cabin_top_edge <= next_upper_edge:
                current_floor = next_floor
                # print("Elevator is now considered on floor:", current_floor)

    # 3) If we’re moving down, check if our bottom edge has passed the "lower_edge" boundary
    elif elevator_direction == -1:
        var prev_floor = current_floor - 1
        if floor_boundaries.has(prev_floor):
            var prev_floor_data = floor_boundaries[prev_floor]
            var prev_lower_edge = prev_floor_data["lower_edge"]
            if cabin_bottom_edge >= prev_lower_edge:
                current_floor = prev_floor
                # print("Elevator is now considered on floor:", current_floor)


func handle_arrival() -> void:    
    current_floor = destination_floor
    
    # bug!
    # error in the line below while 'clicking up consistently inside the elevator #   
    
    var completed_request = elevator_queue[0]
    var elevator = floor_to_elevator.get(current_floor, null)

    if elevator:
        elevator.set_door_state(elevator.DoorState.OPENING)
        SignalBus.elevator_arrived.emit(completed_request['sprite_name'], current_floor)
        # 
        # print("SignalBus.elevator_arrived, handle_arrival")         


    # bug!
    # while clicking up inside the elevator and hitting another elevator door the sprite started to fly to the elevator door
    # maybe the doors were already opening? see # bug!- 5
    
    # warning!
    # while clicking down inside the elevator we ignore duplicate requests. What is that?
    
    # we should start the waiting timer only if there is still a request in the queue
    
    # bug!- 5
    # sprite flies away when clicking on a different location on another floor when exiting the elevator
    
    # bug!
    # the sprite can move after entering the elevator before the doors are closing



func _on_sprite_exiting(sprite_name: String) -> void:    
    remove_from_elevator_queue(sprite_name)
    state = ElevatorState.WAITING
    
func _on_elevator_door_state_changed(new_state):
    var elevator = floor_to_elevator.get(current_floor, null)
    if elevator == null:
        return

    match new_state:
        elevator.DoorState.OPEN:
            state = ElevatorState.WAITING
            reset_elevator_direction()
            # Start the timer only if there is at least one request waiting
            if not elevator_queue.is_empty():
                start_waiting_timer()
                # Get the first request in the queue
                var first_request = elevator_queue[0]
                # Emit the signal using the sprite name from the first request
                
                SignalBus.elevator_ready.emit(first_request["sprite_name"])
                

        elevator.DoorState.CLOSED:
            state = ElevatorState.IN_TRANSIT
            set_elevator_direction()
            if destination_floor != current_floor:
                initialize_target_position()



func initialize_target_position() -> void:
    var request = elevator_queue[0]
    var target_floor = request['target_floor']    
    target_position = floor_to_target_position[target_floor]


func update_destination_floor() -> void:    
    if elevator_queue.size() > 0:
        destination_floor = elevator_queue[0]['target_floor']


func _on_elevator_request(sprite_name: String, target_floor: int) -> void: 
    print("_on_elevator_request")       
    
    var request_updated = false
    for i in range(elevator_queue.size()):
        var request = elevator_queue[i]
        if request['sprite_name'] == sprite_name:
            if request['target_floor'] == target_floor:
                # print("Duplicate request ignored for sprite: ", sprite_name, " to floor: ", target_floor)
                return
            else:
                elevator_queue[i] = {'target_floor': target_floor, 'sprite_name': sprite_name}
                # print("Replaced request for sprite:", sprite_name, "with new floor:", target_floor)
                request_updated = true
                break

    if not request_updated:
        add_to_elevator_queue({'target_floor': target_floor, 'sprite_name': sprite_name})
        print("Added new request for sprite:", sprite_name, "to floor:", target_floor)
        SignalBus.elevator_request_confirmed.emit(sprite_name, target_floor)

    ## <--- After the player has added a request, add your 3 dummy requests.
    #if testing_requests_node:
        #testing_requests_node.add_dummy_requests(self)
    #else:
        #push_warning("TestingRequests node not found - cannot add dummy requests")


    update_destination_floor()

    if request_updated and state == ElevatorState.IN_TRANSIT: # If we are already in transit, re-initialize target position so the elevator doesn't keep going to the old floor.
        initialize_target_position()

func start_waiting_timer() -> void:
    if cabin_timer == null:
        setup_cabin_timer(cabin_timer_timeout)
    else:
        cabin_timer.stop()
    if not elevator_queue.is_empty():
        # queue has not been emptied because the sprite didn't exit yet. Start timer when the sprite exited. 
        cabin_timer.start()
        # print("Waiting timer started.")


func _on_cabin_timer_timeout() -> void:
    # print("Cabin timer timed out!")
    if not elevator_queue.is_empty():
        var _removed_request = elevator_queue[0]
        elevator_queue.remove_at(0)
        # print("Removed oldest request due to inactivity: ", removed_request)
    else:
        # print("Elevator queue is empty, nothing to remove.")
        pass



#region Elevator direction
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

    # If we are about to set direction=0 while elevator is IN_TRANSIT,
    # that means the new request is effectively the same floor => treat as immediate arrival.
    if new_direction == 0 and state == ElevatorState.IN_TRANSIT:
        state = ElevatorState.WAITING        
        handle_arrival()
        return    
    elevator_direction = new_direction


func reset_elevator_direction() -> void:
    if elevator_direction != 0:
        elevator_direction = 0
        # _print_elevator_direction()


func _print_elevator_direction() -> void:
    match elevator_direction:
        1:
            print("Elevator direction changed to: UP")
        -1:
            print("Elevator direction changed to: DOWN")
        0:
            print("Elevator direction changed to: IDLE")
#endregion

#region elevator queue management
func add_to_elevator_queue(request: Dictionary) -> void:    
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
    # print("Current elevator queue:", elevator_queue)
    for item in elevator_queue:
        if item.has("sprite_name") and item["sprite_name"] == sprite_name:
            item["target_floor"] = new_target_floor
            # print("Current elevator queue after update:", elevator_queue)
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
