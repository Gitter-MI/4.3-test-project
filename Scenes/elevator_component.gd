extends Node
class_name ElevatorComponent

var sprite_data_new: Resource
var sprite_owner: Node   # The Area2D or Node2D that owns this script.
var navigation_controller: Node
var cabin: Node
var state_manager: Node


func _ready():
    SignalBus.elevator_request_confirmed.connect(_on_elevator_request_confirmed)
    SignalBus.elevator_waiting_ready.connect(_on_elevator_waiting_ready_received)
    SignalBus.elevator_position_updated.connect(_on_elevator_ride)
    SignalBus.elevator_arrived_at_destination.connect(_on_elevator_at_destination)




# Optional: You can call this once from the sprite script or spawner to set up references.
#func init_elevator_component(
    #_sprite_data: Resource,
    #_sprite_owner: Node,
    #_navigation_controller: Node,
    #_cabin: Node,
    #_state_manager: Node
#):
    #sprite_data_new = _sprite_data
    #sprite_owner = _sprite_owner
    #navigation_controller = _navigation_controller
    #cabin = _cabin
    #state_manager = _state_manager

# The main function to be called from sprite_base.gd's _process
func _process_elevator_actions(
    sprite_data: Resource,
    owner_node: Node,
    nav_controller: Node,
    cabin_node: Node,
    state_manager: Node
) -> void:
    # If you don't use init_elevator_component, you can accept them as parameters each time:
    #   sprite_data_new = sprite_data
    #   sprite_owner = owner_node

    # Check the current elevator state and run the correct logic.
    match sprite_data.elevator_state:
        sprite_data.ElevatorState.CALLING_ELEVATOR:
            if not sprite_data.elevator_requested or sprite_data.stored_position_updated:
                call_elevator()

        sprite_data.ElevatorState.WAITING_FOR_ELEVATOR:
            if sprite_data.stored_position_updated:
                call_elevator()

        sprite_data.ElevatorState.ENTERING_ELEVATOR:
            if not sprite_data.entered_elevator:
                enter_elevator()

        sprite_data.ElevatorState.IN_ELEVATOR_TRANSIT:
            # If you have an animation, you might call it on the sprite
            owner_node._animate_sprite()

        sprite_data.ElevatorState.IN_ELEVATOR_ROOM:
            owner_node._animate_sprite()

        sprite_data.ElevatorState.EXITING_ELEVATOR:
            exit_elevator()

        _:
            pass


func call_elevator() -> void:
    var request_data: Dictionary = {
        "sprite_name": sprite_data_new.sprite_name,
        "pick_up_floor": sprite_data_new.current_floor_number,
        "destination_floor": sprite_data_new.stored_target_floor,
        "request_id": sprite_data_new.elevator_request_id
    }

    SignalBus.elevator_called.emit(request_data)
    sprite_owner._animate_sprite()  # or sprite_owner._animate_sprite() if you’re calling the sprite’s method

    sprite_data_new.elevator_requested = true


func enter_elevator() -> void:
    if not sprite_data_new.entering_elevator:
        sprite_data_new.entering_elevator = true
        sprite_owner._animate_sprite()

        var elevator_data = navigation_controller.elevators.get(sprite_data_new.current_floor_number, null)
        var cabin_height = cabin.get_cabin_height()
        var cabin_bottom_y = elevator_data["position"].y + (cabin_height * 0.5)
        var new_position = Vector2(
            elevator_data["position"].x,
            cabin_bottom_y - (sprite_data_new.sprite_height * 0.5)
        )

        sprite_data_new.set_current_position(new_position,
            sprite_data_new.current_floor_number,
            sprite_data_new.current_room
        )

        # Update the sprite node's visual position & z_index
        sprite_owner.global_position = sprite_data_new.current_position
        sprite_owner.z_index = -9
    else:
        return


func exit_elevator() -> void:
    if not sprite_data_new.exiting_elevator:
        sprite_data_new.exiting_elevator = true
        sprite_owner._animate_sprite()
    else:
        return


func on_sprite_entered_elevator() -> void:
    sprite_data_new.entered_elevator = true
    SignalBus.enter_animation_finished.emit(sprite_data_new.sprite_name, sprite_data_new.stored_target_floor)
    sprite_owner._animate_sprite()


func on_sprite_exited_elevator() -> void:
    sprite_owner.z_index = 0
    SignalBus.exit_animation_finished.emit(sprite_data_new.sprite_name)
    sprite_data_new.exited_elevator = true
    sprite_data_new.set_target_position(
        sprite_data_new.stored_target_position,
        sprite_data_new.stored_target_floor,
        sprite_data_new.stored_target_room
    )
    sprite_data_new.reset_stored_data()


func _on_elevator_request_confirmed(elevator_request_data: Dictionary, elevator_ready_status: bool) -> void:
    var incoming_sprite_name = elevator_request_data["sprite_name"]
    var incoming_request_id = elevator_request_data["request_id"]

    if incoming_sprite_name != sprite_data_new.sprite_name:
        return

    sprite_data_new.elevator_request_id = incoming_request_id
    sprite_data_new.elevator_request_confirmed = true

    if elevator_ready_status:
        if sprite_data_new.elevator_state in [sprite_data_new.ElevatorState.CALLING_ELEVATOR, sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR]:
            sprite_data_new.elevator_ready = true
            sprite_data_new.defer_input = true

            # Handle state transitions via the state manager:
            state_manager._process_elevator_state(sprite_data_new)

            SignalBus.entering_elevator.emit(sprite_data_new.sprite_name)
        else:
            print("Elevator is ready, but sprite not in CALLING or WAITING state.")
    else:
        print("Not entering because the elevator is blocked or not ready.")


func _on_elevator_waiting_ready_received(elevator_request_data: Dictionary, elevator_ready_status: bool) -> void:
    var incoming_sprite_name = elevator_request_data["sprite_name"]
    var incoming_request_id = elevator_request_data["request_id"]

    if incoming_sprite_name != sprite_data_new.sprite_name:
        return

    # Similar logic to _on_elevator_request_confirmed, but specifically for WAITING_FOR_ELEVATOR
    if sprite_data_new.elevator_state == sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
        sprite_data_new.elevator_request_id = incoming_request_id
        sprite_data_new.elevator_request_confirmed = true

        if elevator_ready_status:
            sprite_data_new.elevator_ready = true
            sprite_data_new.defer_input = true
            SignalBus.entering_elevator.emit(sprite_data_new.sprite_name)


func _on_elevator_ride(elevator_pos: Vector2, sprite_name: String) -> void:
    if sprite_name != sprite_data_new.sprite_name:
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

        sprite_owner.global_position = sprite_data_new.current_position
        sprite_owner._animate_sprite()


func _on_elevator_at_destination(incoming_sprite_name: String) -> void:
    if incoming_sprite_name == sprite_data_new.sprite_name:
        sprite_data_new.elevator_destination_reached = true
