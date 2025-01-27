# cabin_new.gd
extends Node2D

@onready var navigation_controller: Node = get_tree().get_root().get_node("Main/Navigation_Controller")
@onready var cabin_sprite: Sprite2D = $Sprite2D
@onready var cabin_data: Node = $Cabin_Data
@onready var queue_manager: Node = $Queue_Manager # interface: add_to_elevator_queue, remove_from_elevator_queue, update_elevator_queue
@onready var elevator_state_manager: Node = $Elevator_StateMachine

func _ready():    
    set_up_elevator_cabin()    
    z_index = -10
    setup_cabin_timer(2.0)    
    add_to_group("cabin")
    
    
func _process(_delta: float) -> void:
    
    queue_manager.pre_process_new_elevator_requests()
    elevator_logic()
        

func elevator_logic():
    
    match cabin_data.elevator_state:
        
        cabin_data.ElevatorState.IDLE:            
            elevator_state_manager.process_idle()       
        cabin_data.ElevatorState.WAITING:
            elevator_state_manager.process_waiting()       
        cabin_data.ElevatorState.DEPARTING:            
            elevator_state_manager.process_departing()       
        cabin_data.ElevatorState.TRANSIT:      
            elevator_state_manager.process_transit()       
        cabin_data.ElevatorState.ARRIVING:      
            elevator_state_manager.process_arriving()       
        _:
                        
            pass


func move_elevator(delta: float) -> void:
    if cabin_data.target_position == Vector2.ZERO:        
        return  # Elevator doesn't have a target different from it's current position, so just return

    # Only stop if it's actually running:
    if not cabin_data.cabin_timer.is_stopped():
        # push_warning("Cabin timer is running while cabin is moving. Stopping it now.")
        cabin_data.cabin_timer.stop() # attempt to prevent the timer from removing requests while the current request is being processed, which could lead to an out-of-bounds error in on_arrival

    var elevator = cabin_data.floor_to_elevator.get(cabin_data.current_floor, null)    
    if elevator.door_state != elevator.DoorState.CLOSED:
        return
    
    var direction = sign(cabin_data.target_position.y - global_position.y)
    var movement = cabin_data.SPEED * delta * direction
    var new_y = global_position.y + movement
    
    if (direction > 0 and new_y >= cabin_data.target_position.y) or (direction < 0 and new_y <= cabin_data.target_position.y):
        global_position.y = cabin_data.target_position.y
        handle_arrival()
    else:
        global_position.y = new_y
    
    SignalBus.elevator_position_updated.emit(global_position, queue_manager.elevator_queue[0]["request_id"])



func handle_arrival() -> void:    
    cabin_data.current_floor = cabin_data.destination_floor
    var elevator = cabin_data.floor_to_elevator.get(cabin_data.current_floor, null)
    if elevator:
        elevator.set_door_state(elevator.DoorState.OPENING)


#region Elevator direction
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
    # If we are about to set direction=0 while elevator is IN_TRANSIT,
    # that means the new request is effectively the same floor => treat as immediate arrival.
    if new_direction == 0 and cabin_data.elevator_state == cabin_data.ElevatorState.IN_TRANSIT:
        cabin_data.elevator_state = cabin_data.ElevatorState.WAITING        
        handle_arrival()
        return    
    cabin_data.elevator_direction = new_direction

func reset_elevator_direction() -> void:
    if cabin_data.elevator_direction != 0:
        cabin_data.elevator_direction = 0
        # _print_elevator_direction()

func _print_elevator_direction() -> void:
    match cabin_data.elevator_direction:
        1:
            print("Elevator direction changed to: UP")
        -1:
            print("Elevator direction changed to: DOWN")
        0:
            print("Elevator direction changed to: IDLE")
#endregion



# ---------------------------------------------------
# Region: Cabin Set-Up
# ---------------------------------------------------

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

func connect_to_signals():
    print("connecting to signals / pass for now.")
    # SignalBus.elevator_called.connect(_on_elevator_request)  -> Has been moved to the queue manager script
    # ...

func setup_cabin_timer(wait_time: float) -> void:
    cabin_data.cabin_timer = Timer.new()
    cabin_data.cabin_timer.one_shot = true
    cabin_data.cabin_timer.wait_time = wait_time
    cabin_data.cabin_timer.timeout.connect(_on_cabin_timer_timeout)
    add_child(cabin_data.cabin_timer)

# ---------------------------------------------------
# Region: Cabin Timer
# ---------------------------------------------------
func start_waiting_timer() -> void:
    if cabin_data.cabin_timer == null:
        setup_cabin_timer(cabin_data.cabin_timer_timeout)
    else:
        cabin_data.cabin_timer.stop()
    if not cabin_data.elevator_queue.is_empty():
        cabin_data.cabin_timer.start()

func _on_cabin_timer_timeout() -> void:
    if not cabin_data.elevator_queue.is_empty():
        var _removed_request = cabin_data.elevator_queue[0]
        cabin_data.elevator_queue.remove_at(0)
        # print("Removed oldest request: ", _removed_request)
    else:
        # print("Elevator queue is empty, nothing to remove.")
        pass
