extends Node

var test_sprite_name = "TEST_Player_A"

var test_pick_up_floor: int = 3
var test_destination_floor: int = 9

var elevator_request_id: int = -1

var elevator_requested: bool = false
var elevator_request_confirmed: bool = false
var elevator_ready: bool = false
var entering_elevator: bool = false
var entered_elevator: bool = false
var elevator_destination_reached = false
var exiting_elevator: bool = false
var exited_elevator: bool = false 

func connect_to_elevator_signals():
    print("connect_to_elevator_signals")
    SignalBus.elevator_request_confirmed.connect(_on_elevator_request_confirmed) # 
    SignalBus.elevator_ready.connect(_on_elevator_ready) # 
    SignalBus.elevator_ready.connect(_on_elevator_at_destination) # 
    SignalBus.elevator_position_updated.connect(_on_elevator_ride)  # 

func _on_elevator_request_confirmed(_sprite_name: String, _target_floor: int, request_id: int):
    print("test_on_elevator_request_confirmed")
    elevator_request_confirmed = true
    elevator_request_id = request_id

func _on_elevator_ready(incoming_sprite_name: String, request_id: int):
    #print("test_on_elevator_ready: incoming_sprite_name is  ", incoming_sprite_name)
    #print("test_on_elevator_ready: request_id is ", request_id)
    #print("test_elevator_request_id: ", elevator_request_id)
    #print("test_sprite_name: ", test_sprite_name)
    
    if incoming_sprite_name == test_sprite_name and request_id == elevator_request_id:
        # print("test_on_elevator_ready")
    
        elevator_ready = true
        # print("test_elevator_ready")
        SignalBus.entering_elevator.emit(test_sprite_name, elevator_request_id)
        # print("test_entering_elevator.emit")
        entering_elevator = true
        # print("test_entering_elevator = true")
        SignalBus.enter_animation_finished.emit(test_sprite_name, test_destination_floor)
        # print("test_enter_animation_finished.emit")
        entered_elevator = true
        # print("test_entered_elevator")


func _on_elevator_ride(_elevator_pos: Vector2, _request_id: int) -> void:
    # print("Test sprite: ", test_sprite_name, "is riding the elevator.")
    pass

var count_of__on_elevator_at_destination: int = 0

func _on_elevator_at_destination(incoming_sprite_name: String, request_id: int):
    
    if incoming_sprite_name == test_sprite_name and request_id == elevator_request_id and entered_elevator == true and count_of__on_elevator_at_destination == 1:
        SignalBus.exit_animation_finished.emit(test_sprite_name)
        count_of__on_elevator_at_destination = 0


    if incoming_sprite_name == test_sprite_name and request_id == elevator_request_id and entered_elevator == true and count_of__on_elevator_at_destination == 0:
        
        print("test_destination signal received")
        elevator_destination_reached = true  
        print("test_elevator_destination_reached = true")
        
        count_of__on_elevator_at_destination = 1
        # SignalBus.exit_animation_finished.emit(test_sprite_name)


    

# This script is responsible for adding dummy requests for testing purposes.

var added: int = 0
var connected: int = 0

func add_dummy_requests(_cabin_script: Node) -> void:
    # pick up floor for the elevator
    # print("adding dummy requests")
    
    if connected == 0:    
        connect_to_elevator_signals()
        connected = 1
    
    if added == 0:
    
        _cabin_script.add_to_elevator_queue({'target_floor': test_pick_up_floor, 'sprite_name': test_sprite_name})
        #_cabin_script.add_to_elevator_queue({'target_floor': 3, 'sprite_name': "Player_B"})
        #_cabin_script.add_to_elevator_queue({'target_floor': 4, 'sprite_name': "Player_C"})
        print("Dummy test requests added.")
        added = 1
    
    else:
        return


#func update_dummy_requests(_cabin_script: Node) -> void:
    ## destination floor for the elevator
    ## when the dummy sprite has 'entered' then update the corresponding request in the elevator queue
    #_cabin_script.update_elevator_queue({ 'sprite_name' : "test_sprite_name", 'target_floor': 9})
    #
    #
    #

    

    
