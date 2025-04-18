# elevator_movement_component.gd
extends Node

@export var cabin_data: Node
@export var queue_manager: Node
@export var cabin_timer: Node

var parent: Node

func _ready():
    parent = get_parent()

func update_destination_floor() -> void:
    if not queue_manager.elevator_queue[0]:
        push_warning("queue is empty when trying to update the destination floor. func update_destination_floor() in elevator_movement_component")
        return
    var current_request = queue_manager.elevator_queue[0]
    
    if cabin_data.elevator_occupied:
        # print("in the if statement")
        cabin_data.destination_floor = current_request["destination_floor"]
        if cabin_data.destination_floor == -1:  ## to-do: do we already know that the elevator room is occupied? if yes, check that condition / flag instead
            ## prevent the elevator from leaving before the sprite has selected a new destination floor. 
            # print("sprite is now in elevator room")
            return
    else:
        print("in the else statement")
        cabin_data.destination_floor = current_request["pick_up_floor"]
        ## switch to elevator room
        ## make sure to call update destination floor if the user selects a floor, or allow the sprite to exit on the same floor
        ## remove request from queue in the second case
        ## also, check if elevator is properly set to occupied. 
        ## start elevator room timer
        
    cabin_data.target_position = cabin_data.floor_to_target_position[cabin_data.destination_floor]

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

func move_elevator(delta: float) -> void:
    if cabin_data.target_position == Vector2.ZERO:        
        return  # Elevator doesn't have a target different from it's current position, so just return

    # Only stop if it's actually running:
    if cabin_timer.is_timer_running():
        cabin_timer.stop_waiting_timer() # prevent the timer from removing requests while the current request is being processed

    var elevator = cabin_data.floor_to_elevator.get(cabin_data.current_floor, null)    
    if elevator.door_state != elevator.DoorState.CLOSED:
        return
    
    var direction = sign(cabin_data.target_position.y - parent.global_position.y)
    var movement = cabin_data.SPEED * delta * direction
    var new_y = parent.global_position.y + movement
    
    if (direction > 0 and new_y >= cabin_data.target_position.y) or (direction < 0 and new_y <= cabin_data.target_position.y): # on arrival
        parent.global_position.y = cabin_data.target_position.y
        reset_elevator_direction()        
    
    else: # keep moving towards destination
        parent.global_position.y = new_y
    
    if cabin_data.elevator_occupied: 
        SignalBus.elevator_position_updated.emit(parent.global_position, queue_manager.elevator_queue[0]["sprite_name"])

func reset_elevator_direction() -> void:
    if cabin_data.elevator_direction != 0:
        cabin_data.elevator_direction = 0
