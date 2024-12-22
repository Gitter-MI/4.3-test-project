# signal_bus.gd
# Singleton SignalBus

extends Node

signal floor_requested(sprite_name: String, target_floor: int)
signal elevator_arrived(sprite_name: String, current_floor: int)
signal entering_elevator(sprite_name: String, current_floor: int)
signal exiting_elevator(sprite_name: String, current_floor: int)
signal elevator_position_updated(global_pos: Vector2)   # used to move sprites along with the elevator cabin

signal door_state_changed(new_state)
signal doors_fully_closed()
signal doors_fully_opened()


signal floor_clicked(
    floor_number: int,
    click_position: Vector2,
    bottom_edge_y: float,
    collision_edges: Dictionary
)

signal door_clicked(
    door_center_x: int,
    floor_number: int,
    door_index: int,
    collision_edges: Dictionary,
    click_position: Vector2
)
