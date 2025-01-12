# signal_bus.gd
# Singleton SignalBus

extends Node

signal elevator_called(sprite_name: String, target_floor: int)  #the target floor is the current floor of the sprite, the pick-up location

signal elevator_request_confirmed(sprite_name: String, floor_number: int)
signal elevator_ready(sprite_name: String) # ensures that the correct sprite will enter the elevator next


signal navigation_click(global_position: Vector2, floor_number: int, door_index: int)
signal adjusted_navigation_click(floor_number: int, door_index: int, adjusted_position: Vector2)
signal player_sprite_ready()
signal floor_area_entered(area: Area2D, floor_number: int)





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
    floor_area_entered.connect(_on_floor_area_entered)
    
    navigation_click.connect(_on_navigation_click)
    adjusted_navigation_click.connect(_on_adjusted_navigation_click)
    player_sprite_ready.connect(_on_player_sprite_ready)



func _on_player_sprite_ready():
    pass


func _on_navigation_click(_click_global_position: Vector2, _floor_number: int, _door_index: int) -> void:
    pass

func _on_adjusted_navigation_click(_floor_number: int, _door_index: int, _adjusted_position: Vector2):
    pass

func _on_floor_area_entered(_area: Area2D, _floor_number: int):
    pass




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
