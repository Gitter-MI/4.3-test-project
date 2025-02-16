# elevator_state_machine.gd
extends Node
const CabinData = preload("res://Data/cabin_data_new.gd")


# @export var cabin_data: Node
@export var queue_manager: Node
@export var cabin_data: Node





func _ready() -> void:
    pass
    
    
func process_elevator_state() -> void:    
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
        return
    else:    
        cabin_data.set_elevator_state(CabinData.ElevatorState.WAITING)
    
    
func process_waiting() -> void:
     if not cabin_data.elevator_busy:
         cabin_data.set_elevator_state(CabinData.ElevatorState.IDLE)
         return
     if not cabin_data.elevator_ready_emitted:
         return
        
     if (not cabin_data.pick_up_on_current_floor) or cabin_data.elevator_occupied:
         cabin_data.set_elevator_state(CabinData.ElevatorState.DEPARTING)
         return
     if cabin_data.pick_up_on_current_floor and (not cabin_data.elevator_occupied) and not cabin_data.cabin_timer.is_stopped():         
         return
    
    
    
func process_departing() -> void:
    print("process_departing in state elevator state machine")
    #print("Elevator is DEPARTING")
    #print("cabin_data.elevator_occupied: ", cabin_data.elevator_occupied)
    #print("cabin_data.doors_closed: ", cabin_data.doors_closed)
    if cabin_data.doors_closed:
        cabin_data.set_elevator_state(CabinData.ElevatorState.TRANSIT)

func process_transit() -> void:
    
    if cabin_data.elevator_direction == 0:
        # print("switching to arriving")
        cabin_data.set_elevator_state(CabinData.ElevatorState.ARRIVING)


func process_arriving() -> void:
    
    if cabin_data.doors_open and not cabin_data.elevator_occupied:
        cabin_data.set_elevator_state(CabinData.ElevatorState.WAITING)
        # print("cabin is now waiting again")
    pass
