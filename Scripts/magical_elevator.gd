extends Node2D

@onready var navigation_controller: Node = get_tree().get_root().get_node("Main/Navigation_Controller")
@onready var cabin_sprite: Sprite2D = $Sprite2D
@onready var cabin_data: Node = $Cabin_Data
@onready var queue_manager: Node = $Queue_Manager
@onready var elevator_state_manager: Node = $Elevator_StateMachine

#When a sprite needs the elevator
#you spawn a cabin at the pick-up floor
#open the doors
#enter the sprite
#close the doors
#move the sprite
#eject the sprite with the doors open
#de-spawn the elevator
#
#
#
#When two sprites need an elevator at the same time, you wait for the sprite cabin to have left the current floor
#When two sprites need to exit at the same floor at the same time, you slow down one of the two elevators

func _ready():    
    set_up_elevator_cabin()    
    z_index = -10
    # setup_cabin_timer(2.0)    
    add_to_group("cabin")    



func _process(_float) -> void:
    
    # print("cabin_data.elevator_state: ", cabin_data.elevator_state)
    
    return
        #match cabin_data.elevator_state:
        #
            #cabin_data.ElevatorState.IDLE:            
                #print("process_idle()")
            #cabin_data.ElevatorState.WAITING:
                #print("process_waiting()")
            #cabin_data.ElevatorState.DEPARTING:            
                #print("process_departing()")     
            #cabin_data.ElevatorState.TRANSIT:      
                #print("process_transit()")   
            #cabin_data.ElevatorState.ARRIVING:      
                #print("process_arriving()")      
            #_:
                #push_warning("unknow state in process_cabin_states")                            
                #pass

#region Process New Requests

enum ElevatorRequestType {
    ADD,
    UPDATE,
    OVERWRITE,
    SHUFFLE,
}

func _on_elevator_request(elevator_request_data: Dictionary) -> void:
    print("Magical Elevator has received the request")
    var new_request: Dictionary = elevator_request_data
    var sprite_name: String = elevator_request_data["sprite_name"]
    var sprite_elevator_request_id: int = elevator_request_data["sprite_elevator_request_id"]    
    
    var request_type = categorize_incomming_elevator_request(sprite_name, sprite_elevator_request_id)
    print("Elevator request type: ", request_type)
    
    var processed_request = handle_request_by_type(request_type, new_request)

    var elevator_ready_on_request: bool = false
    
    elevator_ready_on_request = check_ready_status_on_request(elevator_ready_on_request)
    print("This would be the final signal: ")
    print("Added request with sprite_name: ", processed_request["sprite_name"])
    print("Added request with request_id: ", processed_request["request_id"])
    print("The elevator is ready: ", elevator_ready_on_request)    
            
    # SignalBus.elevator_request_confirmed.emit(added_request["sprite_name"], added_request["request_id"], elevator_ready_on_request)


func handle_request_by_type(request_type: int, new_request: Dictionary) -> Dictionary:
    match request_type:
        ElevatorRequestType.ADD:
            return queue_manager.add_to_elevator_queue(new_request)
        ElevatorRequestType.OVERWRITE:
            return queue_manager.overwrite_elevator_request(new_request)
        ElevatorRequestType.UPDATE:
            return queue_manager.update_elevator_request(new_request)
        ElevatorRequestType.SHUFFLE:
            return queue_manager.shuffle(new_request)
        _:
            push_warning("Unknown request type: ", str(request_type))
            return {}


func check_ready_status_on_request(elevator_ready_on_request: bool):
    # when the sprite calls the elevator we want to know if the elevator is available in the very same moment
    # this is different from the elevator determining it's ready state when processing requests
    # here the elevator is doing nothing with doors open while not occupied -> sprite can enter immediately
    var current_state = cabin_data.elevator_state    
    
    match current_state:
        cabin_data.ElevatorState.IDLE:
            elevator_ready_on_request = true            
            return elevator_ready_on_request              
        
        cabin_data.ElevatorState.WAITING:
            elevator_ready_on_request = true            
            return elevator_ready_on_request
 
func categorize_incomming_elevator_request(sprite_name: String, sprite_elevator_request_id: int) -> ElevatorRequestType:
    
    ## the final check for the elevator state will be added later
    ## ignore for now:
    #var current_state = cabin_data.elevator_state
    #
    #match current_state:
        #cabin_data.ElevatorState.IDLE:
            #print("Elevator is Idle: Overwrite")
            ##cabin_data.set_elevator_state(cabin_data.ElevatorState.DEPARTING)  # for testing purposes
            #return ElevatorRequestType.OVERWRITE                        
        #
        #cabin_data.ElevatorState.WAITING:
            #print("Elevator is Waiting: Overwrite")
            #return ElevatorRequestType.OVERWRITE
    
    
    # Check if the sprite already has a request in the queue.
    var sprite_already_has_a_request_in_the_queue: bool = queue_manager.does_sprite_have_a_request_in_queue(sprite_name)
    if not sprite_already_has_a_request_in_the_queue:
        # if not, add the request to the end of the queue
        return ElevatorRequestType.ADD
    else:
        # Check if the existing request matches the current one.
        var update_existing_request: bool = queue_manager.does_request_id_match(sprite_elevator_request_id)
        if update_existing_request:
            # update the existing request
            return ElevatorRequestType.UPDATE
        else: 
            # edge case: sprite has walked away after making a request earlier and will now be repositioned to end of the queue at the current floor (other sprites have taken the spot)
            return ElevatorRequestType.SHUFFLE
#endregion

       
func connect_to_signals():
    # move to elevator logic component or ensure that the elevator itself does only perform actions 
    SignalBus.elevator_called.connect(_on_elevator_request)



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
