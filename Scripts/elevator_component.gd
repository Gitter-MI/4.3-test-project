extends Node
class_name ElevatorComponent

@onready var navigation_controller := get_tree().get_root().get_node("Main/Navigation_Controller")
@onready var cabin := get_tree().get_root().get_node("Main/Magical_Elevator")

var sprite_base: Area2D
var animation_controller: AnimatedSprite2D
var sprite_data_new

func setup(base: Area2D, data):
    sprite_base = base
    sprite_data_new = data
    animation_controller = sprite_base.get_node("AnimatedSprite2D")

func call_elevator() -> void:
    var request_data: Dictionary = {
        "sprite_name": sprite_data_new.sprite_name,
        "pick_up_floor": sprite_data_new.current_floor_number,
        "destination_floor": sprite_data_new.stored_target_floor,
        "request_id": sprite_data_new.elevator_request_id
    }

    SignalBus.elevator_called.emit(request_data)
    animation_controller.animate(sprite_data_new)

    sprite_data_new.elevator_requested = true

func on_elevator_request_confirmed(elevator_request_data: Dictionary, elevator_ready_status: bool) -> void:
    var incoming_sprite_name = elevator_request_data["sprite_name"]    
    var incoming_request_id = elevator_request_data["request_id"]
    
    if not incoming_sprite_name == sprite_data_new.sprite_name:
        return
    
    sprite_data_new.elevator_request_id = incoming_request_id
    sprite_data_new.elevator_request_confirmed = true
    
    if elevator_ready_status:        
        if sprite_data_new.elevator_state == sprite_data_new.ElevatorState.CALLING_ELEVATOR \
            or sprite_data_new.elevator_state == sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:

            sprite_data_new.elevator_ready = true
            sprite_data_new.defer_input = true            
            
            sprite_base.state_manager._process_elevator_state(sprite_data_new)

            SignalBus.entering_elevator.emit(sprite_data_new.sprite_name)
        else:            
            return
    else:
        return

func on_elevator_waiting_ready_received(elevator_request_data: Dictionary, elevator_ready_status: bool) -> void:
    var incoming_sprite_name = elevator_request_data["sprite_name"]
    var incoming_request_id = elevator_request_data["request_id"]
    
    if not incoming_sprite_name == sprite_data_new.sprite_name:
        return   
        
    match sprite_data_new.elevator_state:        
        
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
            sprite_data_new.elevator_request_id = incoming_request_id
            sprite_data_new.elevator_request_confirmed = true
            
            if elevator_ready_status:
                sprite_data_new.elevator_ready = true
                sprite_data_new.defer_input = true
                SignalBus.entering_elevator.emit(sprite_data_new.sprite_name)

        _:
            pass

func enter_elevator():    
    if not sprite_data_new.entering_elevator:        
        sprite_data_new.entering_elevator = true
        animation_controller.animate(sprite_data_new)
           
        var elevator_data = navigation_controller.elevators.get(sprite_data_new.current_floor_number, null)
        var cabin_height = cabin.get_cabin_height()
        var cabin_bottom_y = elevator_data["position"].y + (cabin_height * 0.5)
        var new_position = Vector2(
            elevator_data["position"].x,
            cabin_bottom_y - (sprite_data_new.sprite_height * 0.5)
        )
        sprite_data_new.set_current_position(new_position,sprite_data_new.current_floor_number,sprite_data_new.current_room)
        sprite_base.global_position = sprite_data_new.current_position
        sprite_base.z_index = -9
    else:        
        return

func on_sprite_entered_elevator():    
    sprite_data_new.entered_elevator = true
    # print("enter animation finished with: ", sprite_data_new.sprite_name, " and ", sprite_data_new.stored_target_floor)
    
    '''set sprite flag for in elevator room'''
    if sprite_data_new.stored_target_floor == -1:
        sprite_data_new.entered_elevator_room = true
    
    SignalBus.enter_animation_finished.emit(sprite_data_new.sprite_name, sprite_data_new.stored_target_floor)
    animation_controller.animate(sprite_data_new)

func on_elevator_ride(elevator_pos: Vector2, sprite_name: String) -> void:
    if sprite_data_new.sprite_name != sprite_name:
        return 

    if sprite_data_new.entered_elevator:
        var cabin_height = cabin.get_cabin_height()
        var cabin_bottom_y = elevator_pos.y + (cabin_height * 0.5)
        var new_position = Vector2(
            elevator_pos.x,
            cabin_bottom_y - (sprite_data_new.sprite_height * 0.5)
        )
        sprite_data_new.set_current_position(
            new_position,
            sprite_data_new.current_floor_number,
            sprite_data_new.current_room
        )
        sprite_base.global_position = sprite_data_new.current_position
        animation_controller.animate(sprite_data_new)

func on_elevator_at_destination(incoming_sprite_name: String):
    if incoming_sprite_name == sprite_data_new.sprite_name:        
        sprite_data_new.elevator_destination_reached = true

func exit_elevator():
    if not sprite_data_new.exiting_elevator:
        sprite_data_new.exiting_elevator = true
        animation_controller.animate(sprite_data_new) 
    else:
        return

func on_sprite_exited_elevator():
    sprite_base.z_index = 1
    SignalBus.exit_animation_finished.emit(sprite_data_new.sprite_name)
    sprite_data_new.exited_elevator = true
    sprite_data_new.set_target_position(
        sprite_data_new.stored_target_position,
        sprite_data_new.stored_target_floor,
        sprite_data_new.stored_target_room
    )
    sprite_data_new.reset_stored_data()

func process_elevator_actions() -> void:
    match sprite_data_new.elevator_state:
        
        sprite_data_new.ElevatorState.CALLING_ELEVATOR:     
                   
            if not sprite_data_new.elevator_requested or sprite_data_new.stored_position_updated:                
                call_elevator()        
                
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:     
            if sprite_data_new.stored_position_updated:
                call_elevator()
            
        sprite_data_new.ElevatorState.ENTERING_ELEVATOR:               
            if not sprite_data_new.entered_elevator:                
                enter_elevator()                            
        sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT:      
            animation_controller.animate(sprite_data_new)
            
        sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM:
            ## question: show the elevator room interface for as long as the sprite is in the elevator room state? if yes, do it here                      
            animation_controller.animate(sprite_data_new) ## plays the idle animation
            
        sprite_data_new.ElevatorState.EXITING_ELEVATOR:
            exit_elevator()        
        _:
            pass
