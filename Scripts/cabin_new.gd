# cabin_new.gd
extends Node2D

@onready var navigation_controller: Node = get_tree().get_root().get_node("Main/Navigation_Controller")
@onready var cabin_sprite: Sprite2D = $Sprite2D
@onready var cabin_data: Node = $Cabin_Data
@onready var queue_manager: Node = $Queue_Manager
@onready var elevator_state_manager: Node = $Elevator_StateMachine

func _ready():    
    set_up_elevator_cabin()    
    z_index = -10
    setup_cabin_timer(2.0)    
    add_to_group("cabin")    
    
func _process(_delta: float) -> void:
    
    queue_manager.pre_process_new_elevator_requests()    
    elevator_logic(_delta)
        

func elevator_logic(_delta) -> void:
    var current_state = cabin_data.elevator_state

    match current_state:
        cabin_data.ElevatorState.IDLE:
            process_idle()
        
        cabin_data.ElevatorState.WAITING:
            process_waiting()

        cabin_data.ElevatorState.DEPARTING:
            process_departure()
#
        cabin_data.ElevatorState.TRANSIT:
            process_transit(_delta)
#
        cabin_data.ElevatorState.ARRIVING:
            process_arrival()
    

#region process functions
func process_idle():
    # print("process idle")
    check_elevator_queue()
        
func check_elevator_queue():
    if queue_manager.elevator_queue:
        cabin_data.elevator_busy = true
        # print("queue_manager.elevator_queue: ", queue_manager.elevator_queue)
    else: 
        cabin_data.elevator_busy = false
        # print("queue_manager.elevator_queue: ", queue_manager.elevator_queue)




func process_waiting():
    
    if cabin_data.elevator_busy: 
        is_at_first_request_pickup_floor()
    # print("cabin_data.pick_up_on_current_floor: ", cabin_data.pick_up_on_current_floor)
    
    if cabin_data.pick_up_on_current_floor and not cabin_data.elevator_ready:
        # print("process_waiting - if cabin_data.pick_up_on_current_floor and not cabin_data.elevator_ready")
        emit_ready_signal()
    
    if cabin_data.pick_up_on_current_floor and cabin_data.elevator_ready and not cabin_data.elevator_occupied:
        # print("waiting for sprite to enter or timer timeout")   
        if cabin_data.elevator_queue_reordered: 
            # print("process_waiting - if cabin_data.elevator_queue_reordered")
            emit_ready_signal()    
        return
     
    else:
        return


func process_departure() -> void:
    
    
    
    if cabin_data.doors_open == true:
        var elevator = cabin_data.floor_to_elevator.get(cabin_data.current_floor, null)
        elevator.set_door_state(elevator.DoorState.CLOSING)
        cabin_data.doors_closing = true
        cabin_data.doors_open = false
        update_destination_floor()   



func process_transit(_delta) -> void:
    move_elevator(_delta)
    


func process_arrival() -> void:
    
    if cabin_data.doors_closed:
        cabin_data.current_floor = cabin_data.destination_floor
        var elevator = cabin_data.floor_to_elevator.get(cabin_data.current_floor, null)
        if elevator:
            elevator.set_door_state(elevator.DoorState.OPENING)
            cabin_data.doors_opening = true
            cabin_data.doors_closed = false

    if cabin_data.doors_open and cabin_data.elevator_occupied:  
        emit_ready_signal()
#endregion

#region Signals and Handlers
func connect_to_signals():
    # print("connecting to signals / pass for now.")    
    SignalBus.entering_elevator.connect(_on_sprite_entered_elevator)    
    SignalBus.door_state_changed.connect(_on_elevator_door_state_changed)
    SignalBus.exit_animation_finished.connect(_on_sprite_exiting) 
    
    SignalBus.request_elevator_ready_status.connect(_on_ready_status_requested)
    SignalBus.queue_reordered.connect(_on_queue_reordered)
    # ...


    
func _on_ready_status_requested(sprite_name: String, request_id: int) -> void:
    #print("!!!!!------------------------!!!!!")
    #print("this sprite is requesting ready: ", sprite_name)
    #print("this is the request id of the requesting sprite: ", request_id)
    
    # print("on_ready_status_requested: ", queue_manager.elevator_queue)
    var request = queue_manager.elevator_queue[0]
    #print("this is the first sprite name in the queue: ", request["sprite_name"])
    #print("this is the first request_id in the queue: ", request["request_id"])
    #print("cabin_data.elevator_ready: ", cabin_data.elevator_ready)
    
    if cabin_data.current_floor == request["pick_up_floor"]:
    
        if cabin_data.elevator_ready and request["sprite_name"] == sprite_name and request["request_id"] == request_id:
            # print("_on_ready_status_requested")
            emit_ready_signal()    


func emit_ready_signal():
        # print("elevator queue in emit_ready_signal: ", queue_manager.elevator_queue)            
        var request = queue_manager.get_first_elevator_request()                
        # print("Emitting signal to: ",  request["sprite_name"]," with request id: ", request["request_id"])
        SignalBus.elevator_ready.emit(request["sprite_name"], request["request_id"])        
        cabin_data.elevator_ready = true   
        

func _on_sprite_entered_elevator(_sprite_name, _elevator_request_id, target_room):
    '''Switch to Room'''
    if target_room == -2:
        print("Sprite wants to enter the room")
        return
    # print("cabin: _on_sprite_entered_elevator")
    
    # check if we need the elevator room or an elevator ride here
    # if sprite wants to enter room -> allow state change and return
    # else: 
    
    cabin_data.elevator_occupied = true
    print("stopping the timer")
    stop_waiting_timer()  

func _on_sprite_exiting(sprite_name: String, request_id: int) -> void:
    reset_elevator(sprite_name, request_id)


func _on_queue_reordered():
    cabin_data.elevator_queue_reordered = true
  
func reset_elevator(sprite_name: String, request_id: int) -> void:    
    cabin_data.elevator_occupied = false
    queue_manager.remove_from_elevator_queue(sprite_name, request_id)
    
    cabin_data.elevator_busy = false
    cabin_data.pick_up_on_current_floor = false
    cabin_data.elevator_ready = false
    cabin_data.elevator_queue_reordered = false







func _on_elevator_door_state_changed(new_state):

    var elevator = cabin_data.floor_to_elevator.get(cabin_data.current_floor, null)
    if elevator == null:
        return

    match new_state:
        elevator.DoorState.OPEN:
            cabin_data.doors_open = true
            cabin_data.doors_opening = false
            reset_elevator_direction()      # still needed?
            
            if queue_manager.elevator_queue.size() >= 2:
                start_waiting_timer()
                print("Timer started because at least two requests are in the queue")
                

        elevator.DoorState.CLOSED:
            cabin_data.doors_closed = true
            cabin_data.doors_closing = false
            set_elevator_direction()
            
            if cabin_data.destination_floor != cabin_data.current_floor:
                update_destination_floor()
#endregion

#region Elevator movement

func update_destination_floor() -> void:
    # print("update destination floor")

    if not queue_manager.elevator_queue[0]:
        push_warning("queue is empty when trying to update the destination floor. func update_destination_floor() in cabin_new")
        return


    var current_request = queue_manager.elevator_queue[0]
    
     
    
    if cabin_data.elevator_occupied:
        cabin_data.destination_floor = current_request["destination_floor"]
    else:
        cabin_data.destination_floor = current_request["pick_up_floor"]
        
    cabin_data.target_position = cabin_data.floor_to_target_position[cabin_data.destination_floor]



func move_elevator(delta: float) -> void:
    if cabin_data.target_position == Vector2.ZERO:        
        return  # Elevator doesn't have a target different from it's current position, so just return

    # Only stop if it's actually running:
    if not cabin_data.cabin_timer.is_stopped():
        # push_warning("Cabin timer is running while cabin is moving. Stopping it now.")
        cabin_data.cabin_timer.stop() # prevent the timer from removing requests while the current request is being processed, which could lead to an out-of-bounds error in on_arrival

    var elevator = cabin_data.floor_to_elevator.get(cabin_data.current_floor, null)    
    if elevator.door_state != elevator.DoorState.CLOSED:
        return
    
    var direction = sign(cabin_data.target_position.y - global_position.y)
    var movement = cabin_data.SPEED * delta * direction
    var new_y = global_position.y + movement
    
    if (direction > 0 and new_y >= cabin_data.target_position.y) or (direction < 0 and new_y <= cabin_data.target_position.y): # on arrival
        global_position.y = cabin_data.target_position.y
        reset_elevator_direction()        
    
    else: # keep moving towards destination
        global_position.y = new_y
    
    SignalBus.elevator_position_updated.emit(global_position, queue_manager.elevator_queue[0]["request_id"])



func set_elevator_direction() -> void:
    var new_direction: int = 0
    
    if queue_manager.elevator_queue.size() > 0:
        var next_floor: int
        if cabin_data.elevator_occupied:
            next_floor = queue_manager.elevator_queue[0]["destination_floor"]
        else:
            next_floor = queue_manager.elevator_queue[0]["pick_up_floor"]        
        if next_floor > cabin_data.current_floor:
            new_direction = 1   # going up
        elif next_floor < cabin_data.current_floor:
            new_direction = -1  # going down
        else:
            new_direction = 0   # same floor
    else:
        new_direction = 0      # no requests => no movement
    
    cabin_data.elevator_direction = new_direction
    

func reset_elevator_direction() -> void:
    if cabin_data.elevator_direction != 0:
        cabin_data.elevator_direction = 0
        # _print_elevator_direction()


func is_at_first_request_pickup_floor() -> void:
    # print("cabin_data.current_floor: ", cabin_data.current_floor)
    var first_request = queue_manager.elevator_queue[0]
    if first_request["pick_up_floor"] == cabin_data.current_floor:
        cabin_data.pick_up_on_current_floor = true
    else: 
        cabin_data.pick_up_on_current_floor = false


#endregion

#region Set-Up

func set_up_elevator_cabin(): 
    add_to_group("cabin")
    apply_scale_factor()
    position_cabin()
    connect_to_signals()
    

    cache_elevators()
    cache_floor_positions()

    var elevator = get_elevator_for_current_floor()
    elevator.set_door_state(elevator.DoorState.OPEN)

func apply_scale_factor():
    # Instead of referencing a local constant, use the child node’s data:
    scale = Vector2.ONE * cabin_data.SCALE_FACTOR

func position_cabin():
    var viewport_size = get_viewport().size
    var x_position = viewport_size.x / 2

    var floors_dict: Dictionary = navigation_controller.floors
    var floor_data = floors_dict[cabin_data.current_floor]  # Moved from local var to cabin_data
    var collision_edges = floor_data["edges"] 
    var bottom_edge_y = collision_edges["bottom"]
    var cabin_height = get_cabin_height()
    var y_position = bottom_edge_y - (cabin_height / 2)

    global_position = Vector2(x_position, y_position)

func get_cabin_height():
    var sprite = get_node("Sprite2D")  # Adjust if needed
    if sprite and sprite.texture:
        # Use cabin_data.scale.y if you are scaling from cabin_data, 
        # or continue using `scale.y` if the node’s actual scale is correct
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
        # Store into the data dictionary that used to be local
        cabin_data.floor_to_elevator[floor_number] = elevator_data["ref"]

func cache_floor_positions():
    var floors_dict: Dictionary = navigation_controller.floors
    for floor_number in floors_dict.keys():
        var floor_data = floors_dict[floor_number]
        var collision_edges = floor_data["edges"]
        var target_pos = get_elevator_position(collision_edges)
        cabin_data.floor_to_target_position[floor_number] = target_pos

        var floor_bottom = collision_edges["bottom"]
        var floor_top    = collision_edges["top"]
        var height       = floor_bottom - floor_top
        var lower_edge   = floor_top
        var upper_edge   = floor_top + (height * 1.25)

        cabin_data.floor_boundaries[floor_number] = {
            "upper_edge": upper_edge,
            "lower_edge": lower_edge
        }

func get_elevator_for_current_floor() -> Node:
    return cabin_data.floor_to_elevator[cabin_data.current_floor]
#endregion

#region CabinTimer
func setup_cabin_timer(wait_time: float) -> void:
    var new_timer = Timer.new()
    new_timer.one_shot = true
    new_timer.wait_time = wait_time
    new_timer.timeout.connect(_on_cabin_timer_timeout)
    
    add_child(new_timer)
    
    # Make sure cabin_data.cabin_timer references THIS timer
    cabin_data.cabin_timer = new_timer
    # print("In timer setup: cabin_data.cabin_timer: ", cabin_data.cabin_timer)


func start_waiting_timer() -> void:
    # If the cabin_timer doesn't exist yet, create it
    if cabin_data.cabin_timer == null:
        push_warning("cabin timer not set-up in start_waiting_timer")
        setup_cabin_timer(cabin_data.cabin_timer_timeout)
    else:        
        cabin_data.cabin_timer.stop()
       #  print("stopping timer to start again")

    # If there's at least one request, start the timer
    if not queue_manager.elevator_queue.is_empty():
        cabin_data.cabin_timer.start()
        print("cabin timer started")  
        # print("In timer started: cabin_data.cabin_timer: ", cabin_data.cabin_timer)  




func stop_waiting_timer() -> void:
    print("stop_waiting_timer")
    # print("In timer stop: cabin_data.cabin_timer: ", cabin_data.cabin_timer)  
    if cabin_data.cabin_timer == null:
        push_warning("cabin timer not set-up in stop_waiting_timer")        
            
    cabin_data.cabin_timer.stop()
    # print("cabin timer stopped")
    

func _on_cabin_timer_timeout() -> void:
    
    if cabin_data.ElevatorState.TRANSIT:
        push_warning("Trying to remove a request from the elevator queue while the elevator is in transit")
        return
    
    
    if not queue_manager.elevator_queue.is_empty():
        var removed_request = queue_manager.elevator_queue[0]
        var sprite_name = removed_request.get("sprite_name", "")
        var request_id   = removed_request.get("request_id", -1)  
        
        reset_elevator(sprite_name, request_id)      
        # print("Removed oldest request:", removed_request)
        check_elevator_queue()
    else:
        pass
        # print("Elevator queue is empty, nothing to remove.")
#endregion

        
