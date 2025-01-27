# elevator_state_machine.gd
extends Node
const CabinData = preload("res://Scripts/cabin_data.gd")


# @export var cabin_data: Node
@export var queue_manager: Node
@export var cabin_data: Node





func _ready() -> void:
    pass

func process_idle() -> void:
    
    if not queue_manager.elevator_queue:   
        return
    
    if queue_manager.elevator_queue:
        cabin_data.set_elevator_state(CabinData.ElevatorState.WAITING)
    
    
func process_waiting() -> void:       
    
    print("queue_manager.elevator_queue: ", queue_manager.elevator_queue)  
    
    if not queue_manager.elevator_queue:                      
        cabin_data.set_elevator_state(CabinData.ElevatorState.IDLE)
    
    else:
        print("checking if pick up floor is the same as the cabin's current floor")
        print("Elevator is WAITING")
    
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
