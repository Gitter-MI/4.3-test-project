# cabin.gd
extends Node2D

@onready var testing_requests_node = %TestingRequests
@onready var navigation_controller: Node = get_tree().get_root().get_node("Main/Navigation_Controller")
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var cabin_sprite: Sprite2D = $Sprite2D
const VISIBILITY_MARGIN_MULTIPLIER: float = 1.5

enum ElevatorState {
    WAITING,       # 0
    IN_TRANSIT     # 1
}

var state: ElevatorState = ElevatorState.WAITING

var elevator_direction: int = 0  # 1 = up, -1 = down, 0 = idle
var floor_boundaries = {}
var current_floor: int = 0
var destination_floor: int = 1
var elevator_queue: Array = []  # Example: [{'pick_up_floor', target_floor': 1, 'sprite_name': "Player_1", 'request_id': 1}, ...]
var next_request_id: int = 0
var floor_to_elevator = {}
var floor_to_target_position = {}
const SCALE_FACTOR: float = 2.3
const SPEED: float = 500.0  # Pixels per second
var target_position: Vector2 = Vector2.ZERO
var cabin_timer: Timer
var cabin_timer_timeout: int = 2




func _ready():
    add_to_group("cabin")
    apply_scale_factor()
    position_cabin()
    connect_to_signals()
    z_index = -10    
    cache_elevators()               # why not have the navigation controller offer an interface for this data?
    cache_floor_positions()         # why not have the navigation controller offer an interface for this data?
    setup_visibility_notifier()
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
    SignalBus.elevator_position_updated.emit(global_position, elevator_queue[0]["request_id"])



func check_current_floor() -> void:
    # disregard for now #
    # is being called every tick? 
    return
    ##
    ## 1) Determine the top and bottom edges of the elevator in global space
    #var cabin_half_height = get_cabin_height() * 0.5
    #var cabin_top_edge    = global_position.y - cabin_half_height
    #var cabin_bottom_edge = global_position.y + cabin_half_height
#
    ## 2) If we’re moving up, check if our top edge has passed the "upper_edge" boundary
    #if elevator_direction == 1:
        #var next_floor = current_floor + 1
        #if floor_boundaries.has(next_floor):
            #var next_floor_data = floor_boundaries[next_floor]
            #var next_upper_edge = next_floor_data["upper_edge"]
            #if cabin_top_edge <= next_upper_edge:
                #current_floor = next_floor
                ## print("Elevator is now considered on floor:", current_floor)
#
    ## 3) If we’re moving down, check if our bottom edge has passed the "lower_edge" boundary
    #elif elevator_direction == -1:
        #var prev_floor = current_floor - 1
        #if floor_boundaries.has(prev_floor):
            #var prev_floor_data = floor_boundaries[prev_floor]
            #var prev_lower_edge = prev_floor_data["lower_edge"]
            #if cabin_bottom_edge >= prev_lower_edge:
                #current_floor = prev_floor
                ## print("Elevator is now considered on floor:", current_floor)
    ##

func handle_arrival() -> void:    
    current_floor = destination_floor
    var elevator = floor_to_elevator.get(current_floor, null)
    if elevator:
        elevator.set_door_state(elevator.DoorState.OPENING)

func _on_sprite_exiting(sprite_name: String) -> void:
    remove_from_elevator_queue(sprite_name)
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


                
                

        elevator.DoorState.CLOSED:
            state = ElevatorState.IN_TRANSIT
            set_elevator_direction()
            if destination_floor != current_floor:
                initialize_target_position()


'''
func analyze queue

how many and which sprites/requests are we expecting at the current floor?
x>=1 -> emit ready to the sprite from the first request

either the sprite will enter immediately: _on_sprite_entering / switch away from WAITING (currently TRANSIT)
or the sprite will indicate elevator_request_changed: main identifier is request id has changed for the sprite -> signal should be emitted only once (flag in sprite data)

if elevator request changed: check if there are other requests from the same floor
    a) no: do nothing
    b) yes: 


'''

func initialize_target_position() -> void:
    var request = elevator_queue[0]
    var target_floor = request['target_floor']    
    target_position = floor_to_target_position[target_floor]


func update_destination_floor() -> void:  
    # print("in update destination floor")  
    if elevator_queue.size() > 0:
        destination_floor = elevator_queue[0]['target_floor']

func _on_elevator_request(
    sprite_name: String,
    sprite_pick_up_floor: int,
    sprite_destination_floor: int,
    sprite_request_id: int              # will be used later
) -> void:
    # Search if there's an existing request from this sprite.
    var existing_index = -1
    for i in range(elevator_queue.size()):
        if elevator_queue[i]["sprite_name"] == sprite_name:
            existing_index = i
            break

    if existing_index >= 0:
        # Overwrite the existing request.
        overwrite_elevator_request(
            existing_index,
            sprite_name,
            sprite_pick_up_floor,
            sprite_destination_floor
        )
    else:
        # Add a new request. Note that "target_floor" is set to the pick-up floor now.
        add_to_elevator_queue({
            "sprite_name": sprite_name,
            "pick_up_floor": sprite_pick_up_floor,
            "target_floor": sprite_pick_up_floor,    # <--- Elevator goes here first
            "destination_floor": sprite_destination_floor  # Stored for reference
        })

    # After adding/overwriting, tell the elevator to pick the first item’s "target_floor".
    update_destination_floor()



#func _on_elevator_request(
    #sprite_name: String,
    #pick_up_floor: int,
    #destination_floor: int,
    #sprite_request_id: int
#) -> void:
    #
    ##if sprite_request_id == -1:
        ##add_to_elevator_queue({'sprite_name': sprite_name, 'target_floor': target_floor})
        ##
    ##if sprite_request_id != -1:
        ##overwrite_elevator_request(existing_index, sprite_name, target_floor)       # would update request work as well? I think so 
        ##
        #
    #
    #
    ## Find if there's an existing request from the same sprite
    #var existing_index = -1
    #for i in range(elevator_queue.size()):
        #if elevator_queue[i]["sprite_name"] == sprite_name:
            #existing_index = i
            #break
#
    ## If a request for this sprite already exists, overwrite it.
    #if existing_index >= 0:
        #overwrite_elevator_request(existing_index, sprite_name, pick_up_floor, destination_floor)
    #else:
        #add_to_elevator_queue({
            #"sprite_name": sprite_name,
            #"pick_up_floor": pick_up_floor,
            #"target_floor": destination_floor
        #})
#
    ### <--- After the player has added a request, add your 3 dummy requests.
    ##if testing_requests_node:
        ##testing_requests_node.add_dummy_requests(self)
    ##else:
        ##push_warning("TestingRequests node not found - cannot add dummy requests")
#
    #update_destination_floor()
#
    ## from the old implementation: changing target floor in transit
    ##if request_updated and state == ElevatorState.IN_TRANSIT: # If we are already in transit, re-initialize target position so the elevator doesn't keep going to the old floor.
        ##initialize_target_position()

func _on_elevator_request_changed(request_id: int) -> void:         #request id will be used later
    if elevator_queue.is_empty():
        return  # no current request to process

    # The top (current) request
    var top_request = elevator_queue[0]
    
    # The pickup floor from the current request
    var pickup_floor = top_request["target_floor"]

    # Search the queue for another request with the same floor (ignoring index 0)
    var matching_index := -1
    for i in range(1, elevator_queue.size()):
        var req = elevator_queue[i]
        if req["target_floor"] == pickup_floor:
            matching_index = i
            break

    # If we didn't find another request on the same floor, do nothing
    if matching_index == -1:
        return

    # Overwrite the top request with the matching one
    var matching_request = elevator_queue[matching_index]
    elevator_queue[0] = matching_request

    # At this point, the same request can appear twice in the queue
    # (since we haven't removed the matching request from its original place).
    # This is intentional in your scenario.

    # Notify the sprite for the new top request
    SignalBus.elevator_ready.emit(
        matching_request["sprite_name"],
        matching_request["request_id"]
    )

    # Optionally, you could print or log for debugging
    print("Queue after overwriting top request with matching floor request:", elevator_queue)
   
func start_waiting_timer() -> void:
    cabin_timer.stop()
    # if not elevator_queue.is_empty():    
    cabin_timer.start()
    # print("Waiting timer started.")

func _on_cabin_timer_timeout() -> void:
    print("Cabin timer timed out!")
    if not elevator_queue.is_empty():
        var _removed_request = elevator_queue[0]
        elevator_queue.remove_at(0)
        print("Removed oldest request due to inactivity: ", _removed_request)
    else:
        print("Elevator queue is empty, nothing to remove.")
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
    # 1) Assign a new request_id
    next_request_id += 1
    request.request_id = next_request_id

    # 2) Add the request to the queue
    elevator_queue.append(request)
    print("Elevator queue after adding a new request:", elevator_queue)

    # 3) Confirm the request back to the sprite
    #    (You can decide which floors you emit. Typically pick-up + final.)
    SignalBus.elevator_request_confirmed.emit(
        request.sprite_name,
        request.pick_up_floor,
        request.destination_floor,   # or request.target_floor, whichever your sprite expects
        request.request_id
    )


#func add_to_elevator_queue(request: Dictionary) -> void:
    #next_request_id += 1
    #request.request_id = next_request_id
    #elevator_queue.append(request)
    #print("Elevator queue after adding a new request:", elevator_queue)
#
    ## Let the sprite know which request ID it got, including floors
    #SignalBus.elevator_request_confirmed.emit(
        #request.sprite_name,
        #request.pick_up_floor,
        #request.target_floor,
        #request.request_id
    #)

func overwrite_elevator_request(
    index: int,
    sprite_name: String,
    pick_up_floor: int,
    final_floor: int
) -> void:
    next_request_id += 1

    # Same idea: override 'target_floor' with pick-up first.
    elevator_queue[index] = {
        "sprite_name": sprite_name,
        "pick_up_floor": pick_up_floor,
        "target_floor": pick_up_floor,       # go to pick-up floor
        "destination_floor": final_floor,    # store final floor for later
        "request_id": next_request_id
    }

    print(
        "Elevator queue after overwriting request at index %d: %s"
        % [index, elevator_queue]
    )

    # Confirm with the sprite
    SignalBus.elevator_request_confirmed.emit(
        sprite_name,
        pick_up_floor,
        final_floor,
        next_request_id
    )



#func overwrite_elevator_request(
    #index: int,
    #sprite_name: String,
    #pick_up_floor: int,
    #destination_floor: int
#) -> void:
    #next_request_id += 1
#
    #elevator_queue[index] = {
        #"sprite_name": sprite_name,
        #"pick_up_floor": pick_up_floor,
        #"target_floor": destination_floor,
        #"request_id": next_request_id
    #}
#
    #print("Elevator queue after overwriting request at index %d: %s"
          #% [index, elevator_queue])
#
    #SignalBus.elevator_request_confirmed.emit(
        #sprite_name,
        #pick_up_floor,
        #destination_floor,
        #next_request_id
    #)
    #
    

func remove_from_elevator_queue(sprite_name: String) -> void:
    # confirmed: queue is properly managed after finishing the first request
    for i in range(elevator_queue.size()):
        var queue_req = elevator_queue[i]
    
        if queue_req.has("sprite_name") and queue_req["sprite_name"] == sprite_name:
            elevator_queue.remove_at(i)
            # print("Removed request for:", sprite_name, ", updated queue:", elevator_queue)            
            return
                
    print("No elevator request found for:", sprite_name)

func update_elevator_queue(sprite_name: String, new_target_floor: int) -> void:
    # Typically called once the sprite actually enters the elevator,
    # turning 'target_floor' from the pick-up floor to the final floor.
    for item in elevator_queue:
        if item.has("sprite_name") and item["sprite_name"] == sprite_name:
            item["target_floor"] = new_target_floor
            # If you want, also update item["destination_floor"] = new_target_floor
            # or you can keep "destination_floor" separate, depending on your design
            return



#func update_elevator_queue(sprite_name: String, new_target_floor: int) -> void:
    ## used to update the target floor of the elevator from the pick-up floor to the destination floor
    ## print("update_elevator_queue called")
    ## print("Current elevator queue:", elevator_queue)
    #for item in elevator_queue:
        #if item.has("sprite_name") and item["sprite_name"] == sprite_name:
            #item["target_floor"] = new_target_floor
            ## print("Current elevator queue after update:", elevator_queue)
            #return
    
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
    SignalBus.elevator_called.connect(_on_elevator_request)
    SignalBus.elevator_request.connect(_on_elevator_request)
    
    SignalBus.elevator_request_changed.connect(_on_elevator_request_changed)
    
    SignalBus.entering_elevator.connect(_on_sprite_entering)
    SignalBus.enter_animation_finished.connect(_on_sprite_entered)
    SignalBus.exiting_elevator.connect(_on_sprite_exiting)
    SignalBus.door_state_changed.connect(_on_elevator_door_state_changed)    
    
    SignalBus.exit_animation_finished.connect(_on_sprite_exiting)
    visible_notifier.screen_entered.connect(_on_screen_entered)  # move to signal bus?
    visible_notifier.screen_exited.connect(_on_screen_exited) 



   
func setup_cabin_timer(wait_time: float) -> void:
    cabin_timer = Timer.new()
    cabin_timer.one_shot = true
    cabin_timer.wait_time = wait_time
    cabin_timer.timeout.connect(_on_cabin_timer_timeout)
    add_child(cabin_timer)


func setup_visibility_notifier() -> void:
    var cabin_height: float = get_cabin_height()
    var margin: float = cabin_height * VISIBILITY_MARGIN_MULTIPLIER
    
    # Create a rect that's taller than the cabin
    var rect = visible_notifier.rect
    rect.position.y = -margin  # Extend upward
    rect.size.y = cabin_height + (margin * 2)  # Add margin to both top and bottom
    visible_notifier.rect = rect

func _on_screen_entered() -> void:
    # print("visible")
    cabin_sprite.show()

func _on_screen_exited() -> void:
    # print("not visible")
    cabin_sprite.hide()


#endregion
