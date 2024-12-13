# signal_bus.gd
# Singleton SignalBus
extends Node


signal doors_closing(elevator_name: String, floor_number: int)
signal doors_closed(elevator_name: String, floor_number: int)
signal doors_opening(elevator_name: String, floor_number: int)
signal doors_opened(elevator_name: String, floor_number: int)


signal door_clicked(door_center_x: int, floor_number: int, door_index: int, collision_edges: Dictionary, click_position: Vector2)
signal floor_clicked(floor_number: int, click_position: Vector2, bottom_edge_y: float, collision_edges: Dictionary)

signal floor_requested(sprite_name: String, target_floor: int)
signal elevator_arrived(sprite_name: String, current_floor: int)
signal entering_elevator(sprite_name: String, current_floor: int)
signal exiting_elevator(sprite_name: String, current_floor: int)
signal elevator_position_updated(global_pos: Vector2)
signal elevator_doors_opened(current_floor: int)
