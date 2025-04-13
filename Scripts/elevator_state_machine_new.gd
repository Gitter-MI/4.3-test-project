# elevator_state_machine_new.gd
extends Node
const CabinData = preload("res://Data/cabin_data_new.gd")


# @export var cabin_data: Node
@export var queue_manager: Node
@export var cabin_data: Node





func _ready() -> void:
    pass
    
    
#func process_elevator_state() -> void:    
    #match cabin_data.elevator_state:
    #
        #cabin_data.ElevatorState.IDLE:            
            #process_idle()       
        #cabin_data.ElevatorState.WAITING:
            #return
            #pass
            ## process_waiting()       
        #cabin_data.ElevatorState.DEPARTING:            
            #process_departing()       
        #cabin_data.ElevatorState.TRANSIT:      
            #process_transit()       
        #cabin_data.ElevatorState.ARRIVING:      
            #process_arriving()       
        #_:
            #push_warning("unknow state in process_cabin_states")                            
            #pass


func process_idle() -> void:        
    if not cabin_data.elevator_busy:
        return
    else:
        # print("elevator is now busy")
        cabin_data.set_elevator_state(CabinData.ElevatorState.WAITING)
        return
        # process_waiting()

    
    
func process_waiting() -> void:
    # print("process_waiting in elevator state machine")
    # print("cabin occupied? ", cabin_data.elevator_occupied)

    # 1) If there are no more requests, go idle.
    if not cabin_data.elevator_busy:
        # print("in elevator state machine: not busy")
        cabin_data.set_elevator_state(CabinData.ElevatorState.IDLE)
        return

    # 2) If the elevator is already occupied, we need to depart next.
    if cabin_data.elevator_occupied:
        # print("in elevator state machine: occupied")
        cabin_data.set_elevator_state(CabinData.ElevatorState.DEPARTING)
        process_departing()
        return

    # By this point, `elevator_ready_emitted` is True, the elevator is busy, but not occupied.
    # 4) If the next pickup is NOT on the current floor, depart to handle it.
    if not cabin_data.pick_up_on_current_floor:
        # print("in state machine: ")
        # print("Setting state to departing ")
        # print("in elevator state machine: pick-up not on current floor")
        cabin_data.set_elevator_state(CabinData.ElevatorState.DEPARTING)
        process_departing()
        return

    ## 5) If the next pickup IS on this floor, but no one has entered yet, we wait (timer running).
    # print("timer is running")
    return


    
    
    
func process_departing() -> void:
    # print("process_departing in state elevator state machine")
    '''we must wait for the sprite to finish entering before closing the doors, if occupied'''
    '''elevator ready needs to be reset'''
    ''' same for ready emitted etc... -> check the state vars'''
    #print("Elevator is DEPARTING")
    #print("cabin_data.elevator_occupied: ", cabin_data.elevator_occupied)
    #print("cabin_data.doors_closed: ", cabin_data.doors_closed)
    if cabin_data.doors_closed:
        cabin_data.set_elevator_state(CabinData.ElevatorState.TRANSIT)

func process_transit() -> void:
    # print("elevator is now in transit")
    
    if cabin_data.elevator_direction == 0:
        # print("switching to arriving")
        cabin_data.set_elevator_state(CabinData.ElevatorState.ARRIVING)


func process_arriving() -> void:
    
    if cabin_data.doors_open and not cabin_data.elevator_occupied:
        cabin_data.set_elevator_state(CabinData.ElevatorState.WAITING)
        # print("cabin is now waiting again")
    pass
