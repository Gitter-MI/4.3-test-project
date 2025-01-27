# elevator_state_machine.gd
extends Node
const CabinData = preload("res://Scripts/cabin_data.gd")


# @export var cabin_data: Node
@export var queue_manager: Node
@export var cabin_data: Node





func _ready() -> void:
    pass
    
    
func _process(float) -> void:
        match cabin_data.elevator_state:
        
            cabin_data.ElevatorState.IDLE:            
                process_idle()       
            cabin_data.ElevatorState.WAITING:
                process_waiting()       
            #cabin_data.ElevatorState.DEPARTING:            
                #elevator_state_manager.process_departing()       
            #cabin_data.ElevatorState.TRANSIT:      
                #elevator_state_manager.process_transit()       
            #cabin_data.ElevatorState.ARRIVING:      
                #elevator_state_manager.process_arriving()       
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
    
    
    

            
    
func process_departing() -> void:
    print("Elevator is DEPARTING")

func process_transit() -> void:
    print("Elevator is in TRANSIT")

func process_arriving() -> void:
    print("Elevator is ARRIVING")



 
    
    
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
