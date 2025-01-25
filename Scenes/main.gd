extends Node2D

# You can define these in the same script or a global constants script

const MOVEMENT_STATE_NAMES = [
    "IDLE",      # MovementState.IDLE = 0
    "WALKING",   # MovementState.WALKING = 1
    "NONE"       # MovementState.NONE = 2
]

const ROOM_STATE_NAMES = [
    "CHECKING_ROOM_STATE",  # RoomState.CHECKING_ROOM_STATE = 0
    "ENTERING_ROOM",        # RoomState.ENTERING_ROOM = 1
    "IN_ROOM",              # RoomState.IN_ROOM = 2
    "EXITING_ROOM",         # RoomState.EXITING_ROOM = 3
    "NONE"                  # RoomState.NONE = 4
]

const ELEVATOR_STATE_NAMES = [
    "CALLING_ELEVATOR",     # ElevatorState.CALLING_ELEVATOR = 0
    "WAITING_FOR_ELEVATOR", # ElevatorState.WAITING_FOR_ELEVATOR = 1
    "ENTERING_ELEVATOR",    # ElevatorState.ENTERING_ELEVATOR = 2
    "IN_ELEVATOR_ROOM",     # ElevatorState.IN_ELEVATOR_ROOM = 3
    "IN_ELEVATOR_TRANSIT",  # ElevatorState.IN_ELEVATOR_TRANSIT = 4
    "EXITING_ELEVATOR",     # ElevatorState.EXITING_ELEVATOR = 5
    "NONE"                  # ElevatorState.NONE = 6
]

const ACTIVE_STATE_NAMES = [
    "NONE",     # ActiveState.NONE = 0
    "MOVEMENT", # ActiveState.MOVEMENT = 1
    "ROOM",     # ActiveState.ROOM = 2
    "ELEVATOR", # ActiveState.ELEVATOR = 3
]


func _on_button_pressed():
    var players = get_tree().get_nodes_in_group("player_sprite")
    
    if players.size() == 0:
        print("No player sprites found in 'player_sprite' group!")
        return
    
    # For simplicity, assume there's only one player
    var player = players[0]
    var data = player.sprite_data_new

    if data == null:
        print("sprite_data_new not set on player!")
        return

    # Print string labels via the arrays
    print("------------------------------------------------------------------")
    print("Player Sprite Data")
    print("------------------------------------------------------------------")
    
    
    print("movement_state:       ", MOVEMENT_STATE_NAMES[data.movement_state])
    print("room_state:           ", ROOM_STATE_NAMES[data.room_state])
    print("elevator_state:       ", ELEVATOR_STATE_NAMES[data.elevator_state])
    # If you also had `active_state`, do similarly:
    # print("active_state:         ", ACTIVE_STATE_NAMES[data.active_state])
    print("sprite_name:         ", data.sprite_name)
    print("sprite_height:       ", data.sprite_height)
    print("sprite_width:        ", data.sprite_width)
    print("speed:               ", data.speed)
    
    print("current_position:    ", data.current_position)
    print("current_floor_number:", data.current_floor_number)
    print("current_room:        ", data.current_room)
    
    print("target_position:     ", data.target_position)
    print("target_floor_number: ", data.target_floor_number)
    print("target_room:         ", data.target_room)
    
    print("has_stored_data:     ", data.has_stored_data)
    print("stored_target_pos:   ", data.stored_target_position)
    print("stored_target_floor: ", data.stored_target_floor)
    print("stored_target_room:  ", data.stored_target_room)
    
    print("has_nav_data:        ", data.has_nav_data)
    print("nav_target_position: ", data.nav_target_position)
    print("nav_target_floor:    ", data.nav_target_floor)
    print("nav_target_room:     ", data.nav_target_room)
    
    print("elevator_request_id: ", data.elevator_request_id)
    print("elevator_requested:  ", data.elevator_requested)
    print("request_confirmed:   ", data.elevator_request_confirmed)
    print("elevator_ready:      ", data.elevator_ready)
    print("entering_elevator:   ", data.entering_elevator)
    print("entered_elevator:    ", data.entered_elevator)
    print("dest_reached:        ", data.elevator_destination_reached)
    print("exiting_elevator:    ", data.exiting_elevator)
    print("exited_elevator:     ", data.exited_elevator)
    print("-----------------------")
    print("*******************************************************************")
    print("Player Sprite Data / END")
    print("*******************************************************************")



enum ElevatorState {
    WAITING,
    IN_TRANSIT
}


const ELEVATOR_CABIN_STATE_NAMES = [
    "WAITING",      # ElevatorState.WAITING = 0
    "IN_TRANSIT"    # ElevatorState.IN_TRANSIT = 1
]



func _on_button_cabin_pressed() -> void:
    # Get all nodes in the "cabin" group (assuming only one for simplicity)
    var cabins = get_tree().get_nodes_in_group("cabin")
    if cabins.size() == 0:
        print("No cabins found in 'cabin' group!")
        return
    
    var cabin_node = cabins[0]
    
    # The cabin_data node is a child named "Cabin_Data"
    var cabin_data = cabin_node.get_node("Cabin_Data")
    if cabin_data == null:
        print("Cabin_Data child not found!")
        return
    
    # Now print out the relevant fields from cabin_data
    print("--- Cabin Data ---")
    print("doors_opening:      ", cabin_data.doors_opening)
    print("doors_open:         ", cabin_data.doors_open)
    print("doors_closing:      ", cabin_data.doors_closing)
    print("doors_closed:       ", cabin_data.doors_closed)
    print("request_started:    ", cabin_data.request_started)
    print("request_finished:   ", cabin_data.request_finished)
    print("transit_occupied:   ", cabin_data.transit_occupied)
    print("transit_empty:      ", cabin_data.transit_empty)
    print("elevator_occupied:  ", cabin_data.elevator_occupied)

    # Use the lookup array to get a string for the ElevatorState enum
    print("state:              ", ELEVATOR_CABIN_STATE_NAMES[cabin_data.state])

    print("current_floor:      ", cabin_data.current_floor)
    print("destination_floor:  ", cabin_data.destination_floor)
    print("elevator_direction: ", cabin_data.elevator_direction)

    # print("floor_boundaries:   ", cabin_data.floor_boundaries)
    # print("floor_to_elevator:  ", cabin_data.floor_to_elevator)
    # print("floor_to_target_pos:", cabin_data.floor_to_target_position)
    print("target_position:    ", cabin_data.target_position)

    print("SCALE_FACTOR:       ", cabin_data.SCALE_FACTOR)
    print("SPEED:              ", cabin_data.SPEED)

    # If you want to print Timer info, you can do that if it's accessible
    print("cabin_timer_timeout:", cabin_data.cabin_timer_timeout)
    
    print("--------------------")
