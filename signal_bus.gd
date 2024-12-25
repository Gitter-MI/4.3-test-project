# signal_bus.gd
# Singleton SignalBus

extends Node

signal elevator_request(sprite_name: String, target_floor: int)
signal elevator_arrived(sprite_name: String, current_floor: int)

signal exiting_elevator(sprite_name: String)
signal elevator_position_updated(global_pos: Vector2)   # used to move sprites along with the elevator cabin
signal door_state_changed(new_state)

signal entering_elevator()
signal enter_animation_finished(sprite_name: String, target_floor: int)


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



#region Warning Suppression. Remove later
func _ready():
    # Connect signals to dummy functions using Godot 4's syntax
    elevator_request.connect(_on_elevator_request)
    elevator_arrived.connect(_on_elevator_arrived)
    entering_elevator.connect(_on_entering_elevator)
    exiting_elevator.connect(_on_exiting_elevator)
    elevator_position_updated.connect(_on_elevator_position_updated)
    door_state_changed.connect(_on_door_state_changed)
    floor_clicked.connect(_on_floor_clicked)
    door_clicked.connect(_on_door_clicked)
    enter_animation_finished.connect(_on_enter_animation_finished)




# Dummy functions for each signal to suppress warnings
func _on_elevator_request(_sprite_name: String, _target_floor: int) -> void:
    pass

func _on_elevator_arrived(_sprite_name: String, _current_floor: int) -> void:
    pass

func _on_entering_elevator() -> void:
    pass

func _on_exiting_elevator(_sprite_name: String) -> void:
    pass

func _on_elevator_position_updated(_global_pos: Vector2) -> void:
    pass

func _on_door_state_changed(_new_state) -> void:
    pass

func _on_floor_clicked(
    _floor_number: int,
    _click_position: Vector2,
    _bottom_edge_y: float,
    _collision_edges: Dictionary
) -> void:
    pass

func _on_door_clicked(
    _door_center_x: int,
    _floor_number: int,
    _door_index: int,
    _collision_edges: Dictionary,
    _click_position: Vector2
) -> void:
    pass
    
func _on_enter_animation_finished(_sprite_name: String, _target_floor:int):
    pass
#endregion
