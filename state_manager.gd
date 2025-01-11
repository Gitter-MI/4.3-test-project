# StateManager.gd
extends Node

func _ready() -> void:
    pass

func process_state(sprite_data_new: Resource) -> void:
    # Decide if we need to change from MOVEMENT to ROOM/ELEVATOR/etc.
    var state = sprite_data_new.get_active_state()
    
    match state:
        sprite_data_new.ActiveState.MOVEMENT:
            _process_movement_state(sprite_data_new)
        sprite_data_new.ActiveState.ROOM:
            # Future logic for room states...
            pass
        sprite_data_new.ActiveState.ELEVATOR:
            # Future logic for elevator states...
            pass
        _:
            push_warning("Sprite is in no recognized state!")


func _process_movement_state(sprite_data_new: Resource) -> void:
    match sprite_data_new.movement_state:
        sprite_data_new.MovementState.IDLE:
            _process_movement_idle(sprite_data_new)
        sprite_data_new.MovementState.WALKING:
            _process_movement_walking(sprite_data_new)
        _:
            push_warning("Unknown movement sub-state: %s" % str(sprite_data_new.movement_state))


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
            # We remain idle (no calls to _update_animation here)
            pass
    else:
        push_warning("Unexpected condition in IDLE state!")


func _process_movement_walking(sprite_data_new: Resource) -> void:
    if sprite_data_new.current_position == sprite_data_new.target_position:
        _update_movement_state(sprite_data_new)
    else:
        # We do NOT move the sprite here anymore—just remain in walking.
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
            sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR)
        else:
            push_warning("Unhandled target_room value: %d" % room_index)

    elif not x_differs and has_stored:
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR)
    elif x_differs:
        sprite_data_new.set_movement_state(sprite_data_new.MovementState.WALKING)
    else:
        push_warning("Bad error in _update_movement_state!")
