# Singleton SignalBus
# signal_bus.gd

@warning_ignore("unused_signal")

extends Node

signal elevator_called(elevator_request_data: Dictionary) ## used in the new implementation
signal elevator_request_confirmed(elevator_request_data: Dictionary, ready_status: bool)  ## used in the new implementation
signal entering_elevator(sprite_name: String)  ## used in the new implementation


# signal elevator_called(sprite_name: String, pick_up_floor: int, destination_floor: int, sprite_elevator_request_id: int)

# signal elevator_request_confirmed(sprite_name: String, request_id: int)

signal elevator_position_updated(global_pos: Vector2, request_id: int)  # used to move sprites along with the elevator cabin
signal elevator_ready(sprite_name: String, request_id: int)  # ensures that the correct sprite will enter the elevator next

'''is this connected? and why is it not???'''
signal elevator_waiting_ready(request_data: Dictionary, elevator_ready_status: bool)

signal request_elevator_ready_status(sprite_name: String, request_id: int)
signal request_skippable(sprite_name: String, request_id: int)
signal queue_reordered(sprite_name: String, request_id: int)

# signal entering_elevator(sprite_name: String, request_id: int, destination_room: int)
signal enter_animation_finished(sprite_name: String, target_floor: int)
signal exit_animation_finished(sprite_name: String, request_id: int)

signal navigation_click(global_position: Vector2, floor_number: int, door_index: int)

signal adjusted_navigation_click(floor_number: int, door_index: int, adjusted_position: Vector2)
signal navigation_command(sprite_name: String, floor_number: int, door_index: int)
signal adjusted_navigation_command(commander: String, sprite_name: String, floor_number: int, door_index: int, adjusted_position: Vector2)

signal player_sprite_ready
signal all_sprites_ready
signal floor_area_entered(area: Area2D, floor_number: int)

signal door_state_changed(new_state)

signal floor_clicked(floor_number: int, click_position: Vector2, bottom_edge_y: float, collision_edges: Dictionary)

signal door_clicked(door_center_x: int, floor_number: int, door_index: int, collision_edges: Dictionary, click_position: Vector2)
