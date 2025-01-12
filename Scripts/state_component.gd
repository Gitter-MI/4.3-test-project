# state_component.gd
extends Node
const SpriteDataNew = preload("res://Scripts/SpriteData_new.gd")

func _ready() -> void:
    pass

func process_state(sprite_data_new: Resource) -> void:
    # Decide if we need to change from MOVEMENT to ROOM/ELEVATOR/etc.
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
            push_warning("In state_component _process: Sprite is in no recognized state!")




# func _process_elevator_state(sprite_data_new: Resource) -> void:
    # if elevator has not been called 
    # state = calling elevator
    # if elevator request has been confirmed
    # state = waiting for elevator
    # if we receive the signal that the elevator has arrived, the doors are open AND it's this sprite's turn then
    # state = entering elevator

    
    pass

func _process_elevator_state(sprite_data_new: Resource) -> void:
    # print("state: ", sprite_data_new.elevator_state)
    match sprite_data_new.elevator_state:
        sprite_data_new.ElevatorState.CALLING_ELEVATOR:
            # print("_process_elevator_state->ElevatorState.CALLING_ELEVATOR")
            _process_calling_elevator(sprite_data_new)
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
            # print("_process_elevator_state->ElevatorState.WAITING_FOR_ELEVATOR")
            _process_waiting_for_elevator(sprite_data_new)
        sprite_data_new.ElevatorState.ENTERING_ELEVATOR:
            # print("_process_elevator_state->ElevatorState.ENTERING_ELEVATOR")
            _process_entering_elevator(sprite_data_new)
        # Add more if needed, e.g. IN_ELEVATOR_TRANSIT, EXITING_ELEVATOR
        sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT:
            _process_in_elevator_transit(sprite_data_new)
        sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM:
            print("In elevator room")
            
        _:
            push_warning("_process_elevator_state: Unknown elevator sub-state!")


func _process_calling_elevator(sprite_data_new: Resource) -> void:
    # print("func _process_calling_elevator")
    # The sprite has asked to call the elevator. 
    # - If the request hasn't been sent yet, we stay in CALLING_ELEVATOR 
    #   until the sprite actually emits the signal and sets elevator_requested = true.
    # - Once it's sent, we wait for elevator_request_confirmed from the elevator system.

    if sprite_data_new.elevator_requested and sprite_data_new.elevator_request_confirmed:
        print("elevator_request_confirmed, Transition to WAITING state")
        # The system has confirmed it's accepted the request.
        # we don't reset the flags, yet. 

       # Transition to WAITING state
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR)


func _process_waiting_for_elevator(sprite_data_new: Resource) -> void:
    # print("func _process_waiting_for_elevator")
    # WAITING until the elevator arrives and is ready for this sprite
    if sprite_data_new.elevator_ready: # elevator emits signal also before leaving. 
        # print("elevator_ready confirmed, Transition to ENTERING_ELEVATOR")
        # This indicates the elevator arrived and doors are open for this sprite
        # sprite_data_new.elevator_ready = false   ## it is not up to the sprite to decide if the elevator is ready or not. 
        
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.ENTERING_ELEVATOR)


func _process_entering_elevator(sprite_data_new: Resource) -> void:
    # print("func _process_entering_elevator")
    # The sprite is currently entering the elevator
    # We might check if 'entering_elevator' is done or not.

    if sprite_data_new.entered_elevator:
        # sprite is now inside the elevator
        if sprite_data_new.target_room == -2:
            sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM)
            print("Sprite is now in Elevator Room")
        else:
            #  or sprite_data_new.target_room >= 0
            sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT)            
            print("Sprite is now in Elevator Transit")
        pass

func _process_in_elevator_transit(sprite_data_new: Resource) -> void:
    # print("_process_in_elevator_transit: in elevator transit")
    if sprite_data_new.elevator_destination_reached:
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.EXITING_ELEVATOR)


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
    var x_differs = (sprite_data_new.current_position != sprite_data_new.target_position)
    var has_stored = sprite_data_new.has_stored_data
    var room_index = sprite_data_new.target_room

    if not x_differs and not has_stored:
        # Arrived at final destination
        if room_index < 0 and room_index != -2:
            sprite_data_new.set_movement_state(sprite_data_new.MovementState.IDLE)
        elif room_index >= 0:
            sprite_data_new.set_room_state(sprite_data_new.RoomState.CHECKING_ROOM_STATE)
        elif room_index == -2:
            sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.CALLING_ELEVATOR)
            print("!!!! sprite is now calling elevator")
        else:
            push_warning("_update_movement_state: Unhandled target_room value: %d" % room_index)

    elif not x_differs and has_stored:
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.CALLING_ELEVATOR)
    elif x_differs:
        sprite_data_new.set_movement_state(sprite_data_new.MovementState.WALKING)
    else:
        push_warning("_update_movement_state: Bad error in _update_movement_state!")
#endregion
