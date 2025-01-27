# cabin.gd
extends Node2D

@onready var navigation_controller: Node = get_tree().get_root().get_node("Main/Navigation_Controller")
@onready var cabin_sprite: Sprite2D = $Sprite2D


enum ElevatorState {
    WAITING,       # 0
    IN_TRANSIT     # 1
}

var state: ElevatorState = ElevatorState.WAITING

var elevator_occupied: bool = false
var elevator_direction: int = 0  # 1 = up, -1 = down, 0 = idle
var floor_boundaries = {}
var current_floor: int = 0
var destination_floor: int = 1  # for spawning only
var elevator_queue: Array = []  # Example: [{'pick_up_floor', 'destination_floor', 'sprite_name': "Player_1", 'request_id': 1}, ...]
var next_request_id: int = 10
var floor_to_elevator = {}
var floor_to_target_position = {}
const SCALE_FACTOR: float = 2.3
const SPEED: float = 500.0  # Pixels per second
var target_position: Vector2 = Vector2.ZERO
var cabin_timer: Timer
var cabin_timer_timeout: int = 2




func _ready():
    # add_to_group("cabin")
    apply_scale_factor()
    position_cabin()
    connect_to_signals()
    z_index = -10    
    cache_elevators()               # why not have the navigation controller offer an interface for this data?
    cache_floor_positions()         # why not have the navigation controller offer an interface for this data?
    
    var elevator = get_elevator_for_current_floor()    
    elevator.set_door_state(elevator.DoorState.OPEN)
    setup_cabin_timer(2.0)

func _process(delta: float) -> void:
    
    match state:
        ElevatorState.WAITING:       
            # confirmed: elevator is waiting after finishing the first job            
            elevator_logic()
            
        ElevatorState.IN_TRANSIT:            
            move_elevator(delta)
            
#region Elevator functionality
func process_next_request():
    # If queue is empty, do nothing
    if elevator_queue.is_empty():
        print("No requests left. Elevator is idle.")
        return
    # print("in process next request")
    update_destination_floor()
    # print("destination_floor: ", destination_floor)
    if destination_floor != current_floor:
        var elevator = floor_to_elevator.get(current_floor, null)
        if elevator:
            elevator.set_door_state(elevator.DoorState.CLOSING)
    else:
        # print("calling handle_same_floor_request")
        handle_same_floor_request()
        # if elevator is waiting at the same floor as before then start the timer again. Could be necesary only because of the test case. Otherwise the second sprite could just enter.
        #if cabin_timer.is_stopped():
            #cabin_timer.start()
        #else:
            ## push_warning("Cabin timer is already running.")
            #pass


func elevator_logic() -> void:
    
    if elevator_queue.size() > 0:            
        # print("in process next request")
        process_next_request()    
        if destination_floor != current_floor:
            var elevator = floor_to_elevator.get(current_floor, null)
            elevator.set_door_state(elevator.DoorState.CLOSING)
        else:
            handle_same_floor_request()


func handle_same_floor_request() -> void:
    var request = elevator_queue[0]
    SignalBus.elevator_ready.emit(request["sprite_name"], request["request_id"])


func _on_sprite_entering(_sprite_name: String, _request_id: int) -> void:
    state = ElevatorState.IN_TRANSIT
    


func _on_sprite_entered(sprite_name: String, sprite_destination_floor: int) -> void:
    # is receiving the sprites destination floor 
    # cabin_timer.stop()    
    elevator_occupied = true
    var elevator = floor_to_elevator.get(current_floor, null)    
    elevator.set_door_state(elevator.DoorState.CLOSING)        
    update_elevator_queue(sprite_name, sprite_destination_floor)
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
    
    SignalBus.elevator_position_updated.emit(global_position, elevator_queue[0]["request_id"])



func handle_arrival() -> void:    
    current_floor = destination_floor
    var elevator = floor_to_elevator.get(current_floor, null)
    if elevator:
        elevator.set_door_state(elevator.DoorState.OPENING)

func _on_sprite_exiting(sprite_name: String, _request_id: int) -> void:
    remove_from_elevator_queue(sprite_name)
    elevator_occupied = false
    state = ElevatorState.WAITING
    if not elevator_queue.is_empty():
        start_waiting_timer()
        '''
        # call a function to analyze the queue
        '''
        var first_request = elevator_queue[0]                
        # Emit the signal with the correct request_id
        SignalBus.elevator_ready.emit(first_request["sprite_name"], first_request["request_id"])
    
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
                

        elevator.DoorState.CLOSED:
            state = ElevatorState.IN_TRANSIT
            set_elevator_direction()
            if destination_floor != current_floor:
                update_destination_floor()



func update_destination_floor() -> void:

    var current_request = elevator_queue[0]    
    
    if elevator_occupied:
        destination_floor = current_request["destination_floor"]
    else:
        destination_floor = current_request["pick_up_floor"]
        
    target_position = floor_to_target_position[destination_floor]
#endregion

#region Request Management
func find_request_index_by_sprite(sprite_name: String) -> int:
    for i in range(elevator_queue.size()):
        if elevator_queue[i]["sprite_name"] == sprite_name:
            return i
    return -1


func check_if_other_sprites_waiting_on_floor(waiting_floor: int, exclude_sprite_name: String) -> bool:
    
    var count_sprites = 0
    for req in elevator_queue:
        if req["pick_up_floor"] == waiting_floor and req["sprite_name"] != exclude_sprite_name:
            count_sprites += 1
    return count_sprites > 0


func _on_elevator_request(
    sprite_name: String, 
    sprite_pick_up_floor: int, 
    sprite_destination_floor: int, 
    sprite_request_id: int
) -> void:
    # print("on elevator request")

    var existing_index = find_request_index_by_sprite(sprite_name)
    # print(" -> existing_index:", existing_index)

    # CASE 1: No existing request from this sprite at all
    if existing_index == -1:
        # print("request_index = -1 => Adding new request")
        add_to_elevator_queue({
            "sprite_name": sprite_name,
            "pick_up_floor": sprite_pick_up_floor,            
            "destination_floor": sprite_destination_floor,
            # "sprite_request_id": sprite_request_id
        })
    else:
        # print("request_index >= 0 => Found existing request")
        var existing_request = elevator_queue[existing_index]
        
        # Grab the old and new IDs.
        var old_id = existing_request["sprite_request_id"]
        var new_id = sprite_request_id
        
        # Evaluate whether they match (and check for type mismatch).
        #print("    old_id:", old_id, " (type:", typeof(old_id), ")")
        #print("    new_id:", new_id, " (type:", typeof(new_id), ")")
        #print("    old_id == new_id? => ", old_id == new_id)

        var other_waiting = check_if_other_sprites_waiting_on_floor(sprite_pick_up_floor, sprite_name)
        #print("    other sprites waiting on floor", sprite_pick_up_floor, "?", other_waiting)

        ## scenario is not needed
        ## CASE 2: If the existing request ID == the new request ID => Overwrite
        #if old_id == new_id:
            #print(" -> Overwrite scenario triggered!")
            #overwrite_elevator_request(new_id, sprite_name, sprite_pick_up_floor, sprite_destination_floor)

        # CASE 3: If the existing ID != new ID AND other sprites are waiting => Shuffle
        if old_id != new_id and other_waiting:
            # print(" -> Shuffle scenario triggered!")
            shuffle_elevator_queue_with_new_request(
                sprite_name,
                sprite_pick_up_floor,
                sprite_destination_floor,
                new_id
            )

        else:
            # No matching pattern => warn about it
            #print(" -> old_id != new_id?", old_id != new_id)
            #print(" -> other_waiting?", other_waiting)
            push_warning("Unclassified elevator request could not be handled:")
   
    # After adding, overwriting, or shuffling, update the elevator’s current destination.
    update_destination_floor()

 



func shuffle_elevator_queue_with_new_request(
    sprite_name: String, 
    pick_up_floor: int, 
    _destination_floor: int, 
    _sprite_request_id: int
) -> void:
    print("shuffle queue")
    # 1) Remove the old request from this sprite.
    var old_index = find_request_index_by_sprite(sprite_name)
    if old_index != -1:
        elevator_queue.remove_at(old_index)

    # 2) Build a new request, mirroring the logic from 'add_to_elevator_queue'. We create an internal 'request_id' and store the 'sprite_request_id'.
    next_request_id += 1
    var new_request = {
        # Internal ID for tracking within the elevator system
        "request_id": next_request_id,
        
        # Data from the sprite
        "sprite_name": sprite_name,
        "pick_up_floor": pick_up_floor,        
        "destination_floor": destination_floor,        
    }

    # 3) Find the insertion position behind all requests on the same floor.
    var insertion_index = -1
    for i in range(elevator_queue.size()):
        if elevator_queue[i]["pick_up_floor"] == pick_up_floor:
            insertion_index = i

    if insertion_index == -1:
        push_warning("shuffle_elevator_queue_with_new_request was called but no requests on floor %d" % pick_up_floor)
        return

    # 4) Insert the new request right behind the last same-floor request
    elevator_queue.insert(insertion_index + 1, new_request)

    # 5) Confirm the request back to the sprite, mirroring the add_to_elevator_queue logic.
    SignalBus.elevator_request_confirmed.emit(
        new_request.sprite_name,
        new_request.pick_up_floor,
        new_request.destination_floor,
        next_request_id                              
    )
#endregion

#region Cabin Timer
  
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
        # print("Removed oldest request due to inactivity: ", _removed_request)
        # print("Elevator queue after removing request via timer: ",elevator_queue )
    else:
        # print("Elevator queue is empty, nothing to remove.")
        pass
#endregion

#region Elevator direction
func set_elevator_direction() -> void:
    var new_direction: int = 0
    
    if elevator_queue.size() > 0:
        var current_request = elevator_queue[0]
        var next_floor: int
        if elevator_occupied:
            next_floor = current_request["destination_floor"]
        else:
            next_floor = current_request["pick_up_floor"]        

        if next_floor > current_floor:
            new_direction = 1   # going up
        elif next_floor < current_floor:
            new_direction = -1  # going down
        else:
            new_direction = 0   # same floor
    else:
        new_direction = 0      # no requests => no movement
    
    elevator_direction = new_direction

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
    # 1) Assign a new request_id
    next_request_id += 1
    request.request_id = next_request_id

    # 2) Add the request to the queue
    elevator_queue.append(request)
    # print("Elevator queue after adding a new request:", elevator_queue)

    # 3) Confirm the request back to the sprite
    #    (You can decide which floors you emit. Typically pick-up + final.)
    SignalBus.elevator_request_confirmed.emit(
        request.sprite_name,
        request.pick_up_floor,
        request.destination_floor,
        request.request_id
    )



func remove_from_elevator_queue(sprite_name: String) -> void:
    # confirmed: queue is properly managed after finishing the first request
    for i in range(elevator_queue.size()):
        var queue_req = elevator_queue[i]
    
        if queue_req.has("sprite_name") and queue_req["sprite_name"] == sprite_name:
            elevator_queue.remove_at(i)
            # print("Removed request for:", sprite_name, ", updated queue:", elevator_queue)            
            return
                
    print("No elevator request found for:", sprite_name)

func update_elevator_queue(sprite_name: String, new_destination_floor: int) -> void:
    
    var current_destination_floor = elevator_queue[0]["destination_floor"]
    if current_destination_floor == new_destination_floor:
        return
    
    for item in elevator_queue:
        if item.has("sprite_name") and item["sprite_name"] == sprite_name:
            item["destination_floor"] = new_destination_floor
            return
   
#endregion

#region cabin Set-Up
func apply_scale_factor():
    scale = Vector2.ONE * SCALE_FACTOR

func position_cabin():
    var viewport_size = get_viewport().size
    var x_position = viewport_size.x / 2
    var floors_dict: Dictionary = navigation_controller.floors
    var floor_data      = floors_dict[current_floor]
    var collision_edges = floor_data["edges"] 
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

func cache_elevators():
    var elevators_dict: Dictionary = navigation_controller.elevators
    for floor_number in elevators_dict.keys():
        var elevator_data = elevators_dict[floor_number]
        floor_to_elevator[floor_number] = elevator_data["ref"]

func cache_floor_positions():
        
    var floors_dict: Dictionary = navigation_controller.floors
    for floor_number in floors_dict.keys():
        var floor_data = floors_dict[floor_number]
        var collision_edges = floor_data["edges"]
        var target_pos = get_elevator_position(collision_edges)
        floor_to_target_position[floor_number] = target_pos
        var floor_bottom = collision_edges["bottom"]
        var floor_top    = collision_edges["top"]
        var height       = floor_bottom - floor_top        
        var lower_edge = floor_top
        var upper_edge = floor_top + (height * 1.25)

        floor_boundaries[floor_number] = {
            "upper_edge": upper_edge,
            "lower_edge": lower_edge
        }

func get_elevator_for_current_floor() -> Node:
    return floor_to_elevator[current_floor]
 


func connect_to_signals():    
    pass
    #SignalBus.elevator_called.connect(_on_elevator_request)
    #SignalBus.elevator_request.connect(_on_elevator_request)
    #
    #SignalBus.entering_elevator.connect(_on_sprite_entering)
    SignalBus.enter_animation_finished.connect(_on_sprite_entered)
    #SignalBus.exiting_elevator.connect(_on_sprite_exiting)
    #SignalBus.door_state_changed.connect(_on_elevator_door_state_changed)    
    #
    #SignalBus.exit_animation_finished.connect(_on_sprite_exiting)


   
func setup_cabin_timer(wait_time: float) -> void:
    cabin_timer = Timer.new()
    cabin_timer.one_shot = true
    cabin_timer.wait_time = wait_time
    cabin_timer.timeout.connect(_on_cabin_timer_timeout)
    add_child(cabin_timer)

#endregion
