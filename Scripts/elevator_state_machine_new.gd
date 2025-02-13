# elevator_state_machine.gd
extends Node
const CabinData = preload("res://Data/cabin_data_new.gd")


# @export var cabin_data: Node
@export var queue_manager: Node
@export var cabin_data: Node





func _ready() -> void:
    pass
    
    
func _process_elevator_state() -> void:    
    match cabin_data.elevator_state:
    
        cabin_data.ElevatorState.IDLE:            
            process_idle()       
        cabin_data.ElevatorState.WAITING:
            process_waiting()       
        cabin_data.ElevatorState.DEPARTING:            
            process_departing()       
        cabin_data.ElevatorState.TRANSIT:      
            process_transit()       
        cabin_data.ElevatorState.ARRIVING:      
            process_arriving()       
        _:
            push_warning("unknow state in process_cabin_states")                            
            pass

func process_idle() -> void:        
    if not cabin_data.elevator_busy:
        # print("in elevator state machine: not busy")
        return
    else:
        # print("in elevator state machine: switching to waiting")
        cabin_data.set_elevator_state(CabinData.ElevatorState.WAITING)
    
    
func process_waiting() -> void:
    if not cabin_data.elevator_busy:
        cabin_data.set_elevator_state(CabinData.ElevatorState.IDLE)
        
    ''' maybe just add a waiting timer function'''
    ''' or add the subcase in the processing function in main script'''
        
    # if not cabin_data.elevator_ready_signal_send:
            # return send_elevator_ready_signal   # to all sprites waiting on the floor
    
    # if 
    
    
    # if cabin_data.pick_up_on_current_floor and timer not already running:
        # start timer
    
    # if cabin_data.elevator_occupied or not cabin_data.pick_up_on_current_floor:
        # elevator room
        # depart
        # stop timer    
    

    
    
      
    
    #if cabin_data.elevator_busy and not cabin_data.pick_up_on_current_floor:
        #cabin_data.set_elevator_state(CabinData.ElevatorState.DEPARTING)
    #
    #if cabin_data.elevator_busy and cabin_data.elevator_ready and cabin_data.elevator_occupied:
        #cabin_data.set_elevator_state(CabinData.ElevatorState.DEPARTING)
    

            
    
func process_departing() -> void:
    # print("Elevator is DEPARTING")
    # print("cabin_data.elevator_occupied: ", cabin_data.elevator_occupied)
    # print("cabin_data.doors_closed: ", cabin_data.doors_closed)
    if cabin_data.doors_closed:
        cabin_data.set_elevator_state(CabinData.ElevatorState.TRANSIT)

func process_transit() -> void:
    
   
    
    if cabin_data.elevator_direction == 0:
        # print("switching to arriving")
        cabin_data.set_elevator_state(CabinData.ElevatorState.ARRIVING)

func process_arriving() -> void:
    
    if cabin_data.doors_open == true and not cabin_data.elevator_occupied:
        cabin_data.set_elevator_state(CabinData.ElevatorState.IDLE)
        # print("cabin is now idling again")



 
    
    
    pass
    ## Decide if we need to change from MOVEMENT to ROOM/ELEVATOR/etc.
    #var state = sprite_data_new.get_active_state()
    ## print("state : ", state)
    #match state:
        #sprite_data_new.ActiveState.MOVEMENT:
            #_process_movement_state(sprite_data_new)
        #sprite_data_new.ActiveState.ROOM:
            ## room state management will go here
           #pass
            #
        #sprite_data_new.ActiveState.ELEVATOR:
            #_process_elevator_state(sprite_data_new)
            #
        #_:
            #push_warning("In state_component _process: Sprite is in no recognized state!")



#func _process_exiting_elevator(sprite_data_new: Resource) -> void:
    ## print("in exiting elevator in state ")
    #if sprite_data_new.exited_elevator:
        #
        #sprite_data_new.set_movement_state(SpriteDataNew.MovementState.IDLE)
