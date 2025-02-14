# state_component.gd
extends Node
const SpriteDataNew = preload("res://Data/SpriteData_new.gd")


'''on state change during _process function -> call the next _process function immediately'''


func process_state(sprite_data_new: Resource) -> void:    
    # print("state component process state for: ", sprite_data_new.sprite_name)
    var state = sprite_data_new.get_active_state()
    # print("state : ", state)
    match state:
        sprite_data_new.ActiveState.MOVEMENT:
            _process_movement_state(sprite_data_new)
        sprite_data_new.ActiveState.ROOM:
            # room state management will go here
           pass            
        sprite_data_new.ActiveState.ELEVATOR:
            _process_elevator_state(sprite_data_new)            
        _:
            push_warning("In state_component _process: Sprite is in no recognized Main-state!")

#region Elevator State
func _process_elevator_state(sprite_data_new: Resource) -> void:
    # print("state: ", sprite_data_new.elevator_state)
    match sprite_data_new.elevator_state:
        sprite_data_new.ElevatorState.CALLING_ELEVATOR:
            # print(sprite_data_new.sprite_name, " ->ElevatorState.CALLING_ELEVATOR")
            
            _process_calling_elevator(sprite_data_new)
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
            # print(sprite_data_new.sprite_name, " ->ElevatorState.WAITING_FOR_ELEVATOR")
            _process_waiting_for_elevator(sprite_data_new)
        sprite_data_new.ElevatorState.ENTERING_ELEVATOR:
            # print(sprite_data_new.sprite_name, " ->ElevatorState.ENTERING_ELEVATOR")
            _process_entering_elevator(sprite_data_new)        
        sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT:
            _process_in_elevator_transit(sprite_data_new)
        sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM:
            pass
            # print("In elevator room")            
        sprite_data_new.ElevatorState.EXITING_ELEVATOR:
            _process_exiting_elevator(sprite_data_new)        
        _:            
            sprite_data_new.set_movement_state(sprite_data_new.MovementState.WALKING)            
            # print(sprite_data_new.sprite_name, " is in Elevator main state, but has Elevator sub-state: ", sprite_data_new.elevator_state)
            # print("set sprite to MOVEMENT State")
            # push_warning("_process_elevator_state: Unknown elevator sub-state!")

func _process_calling_elevator(sprite_data_new: Resource) -> void:
    
    # print("sprite_data_new.elevator_requested: ", sprite_data_new.elevator_requested)
    # print("sprite_data_new.elevator_request_confirmed: ", sprite_data_new.elevator_request_confirmed)


    ## case 0: elevator is available immediately
    ## new
    if sprite_data_new.elevator_ready:
        # print("elevator ready? ", sprite_data_new.elevator_ready)
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.ENTERING_ELEVATOR)
        _process_entering_elevator(sprite_data_new)       
        return

    ## case 1: proceeding with the elevator flow
    if sprite_data_new.elevator_requested and sprite_data_new.elevator_request_confirmed:
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR)
        return
    
    ## case 2: sprite has interrupted the elevator flow
    if sprite_data_new.stored_target_floor == -1 and not sprite_data_new.target_room == -2:
        # print("sprite ", sprite_data_new.sprite_name, " is switching to MOVEMENT")
        sprite_data_new.set_movement_state(SpriteDataNew.MovementState.IDLE)
        return

func _process_waiting_for_elevator(sprite_data_new: Resource) -> void:
    # print("sprite is waiting for elevator")
    
    # Sprite is walking away, interrupting the waiting state
    if sprite_data_new.stored_target_position == Vector2.ZERO:
        
        
        ## move this to the player script without the state setter: function move_sprite inside the if clause
        # Cancel elevator usage and switch to movement
        _update_movement_state(sprite_data_new)
        # sprite_data_new.reset_elevator_status()        
        # sprite_data_new.reset_stored_data()        
        # sprite_data_new.reset_elevator_request_id()
        # sprite_data_new.set_movement_state(sprite_data_new.MovementState.WALKING)
        return
    
    # Sprite is in WAITING state without having a request confirmed: which happens in pathfinder    
    if not sprite_data_new.elevator_requested and not sprite_data_new.elevator_request_confirmed:
        # print("sprite reset from WAITING to CALLING ELEVATOR")
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.CALLING_ELEVATOR)
        return        
    
    # Elevator is here → go ENTERING_ELEVATOR
    if sprite_data_new.elevator_ready:        
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.ENTERING_ELEVATOR)
        return

func _process_entering_elevator(sprite_data_new: Resource) -> void:    
    # print("func _process_entering_elevator: ", sprite_data_new.sprite_name)
    
    if sprite_data_new.entered_elevator:
        # print("sprite has entered the elevator")    
        if sprite_data_new.target_room == -2:
            sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM)
            print("Sprite is now in Elevator Room")
        else:            
            sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT)            
            # print("Sprite is switching to Transit State")
        pass

func _process_in_elevator_transit(sprite_data_new: Resource) -> void:
    # print("_process_in_elevator_transit: in elevator transit")
    if sprite_data_new.elevator_destination_reached:  
        # print("sprite is now exiting the elevator")      
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.EXITING_ELEVATOR)
  
func _process_exiting_elevator(sprite_data_new: Resource) -> void:
    # print("in exiting elevator in state ")
    if sprite_data_new.exited_elevator:        
        sprite_data_new.set_movement_state(SpriteDataNew.MovementState.IDLE)
  
#endregion

#region Movement State
func _process_movement_state(sprite_data_new: Resource) -> void:
    match sprite_data_new.movement_state:
        sprite_data_new.MovementState.IDLE:
            _process_movement_idle(sprite_data_new)
        sprite_data_new.MovementState.WALKING:
            _process_movement_walking(sprite_data_new)
        _:
            push_warning("_process_movement_state: Unknown movement sub-state: %s" % str(sprite_data_new.movement_state))

func _process_movement_idle(sprite_data_new: Resource) -> void:
    var target_differs = (sprite_data_new.target_position != sprite_data_new.current_position)
    var has_stored = sprite_data_new.has_stored_data
    var room_index = sprite_data_new.target_room

    if target_differs or has_stored:
        _update_movement_state(sprite_data_new)
    elif not target_differs and not has_stored:
        # If position is the same and no pending data,
        # check if we want to do something like enter a room or elevator
        if room_index >= 0 or room_index == -2:
            _update_movement_state(sprite_data_new)
        else:
            # keep idling        
            pass
    else:
        push_warning("_process_movement_idle: Unexpected condition in IDLE state!")

func _process_movement_walking(sprite_data_new: Resource) -> void:    
    if sprite_data_new.current_position == sprite_data_new.target_position:
        _update_movement_state(sprite_data_new)
    else:
        # keep walking
        pass

func _update_movement_state(sprite_data_new: Resource) -> void:
    # print("update movement state")
    var x_differs = (sprite_data_new.current_position != sprite_data_new.target_position)
    var has_stored = sprite_data_new.has_stored_data
    var room_index = sprite_data_new.target_room
    #print("x_differs: ", x_differs)
    #print("has_stored: ", has_stored)
    #
    #print("sprite_data_new.current_position: ", sprite_data_new.current_position)
    #print("sprite_data_new.target_position: ", sprite_data_new.target_position)
    

    if not x_differs and not has_stored:        
        # Arrived at final destination
        if room_index < 0 and room_index != -2:
            sprite_data_new.set_movement_state(sprite_data_new.MovementState.IDLE)
            sprite_data_new.reset_elevator_status()
        elif room_index >= 0:
            sprite_data_new.set_room_state(sprite_data_new.RoomState.CHECKING_ROOM_STATE)            
        elif room_index == -2:
            sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.CALLING_ELEVATOR)
            print("sprite ", sprite_data_new.sprite_name, " is switching to CALLING_ELEVATOR-Elevator ROOM")
        else:
            push_warning("_update_movement_state: Unhandled target_room value: %d" % room_index)

    elif not x_differs and has_stored:
        # print("sprite ", sprite_data_new.sprite_name, " is switching to CALLING_ELEVATOR")
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.CALLING_ELEVATOR)
    elif x_differs:        
        sprite_data_new.set_movement_state(sprite_data_new.MovementState.WALKING)
        sprite_data_new.reset_elevator_status()    
        # print("in state component: _update_movement_state -> re-setting the elevator state")
        # sprite_data_new.reset_elevator_status() # belongs into sprite 
    else:
        push_warning("_update_movement_state: Bad error in _update_movement_state!")
#endregion
