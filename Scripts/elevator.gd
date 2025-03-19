extends Area2D

var floor_instance

enum DoorState { CLOSED, OPENING, OPEN, CLOSING }
var door_state: DoorState = DoorState.CLOSED

@onready var floor_indicator = $Frame/FloorIndicatorHolder
@onready var elevator_doors = $Elevator_Door_Animation
@onready var door_animation_controller = $Elevator_Door_Animation

func _ready():
    pass
    # set_door_state(DoorState.CLOSED)

func _on_floor_area_entered(area: Area2D, floor_number: int) -> void:
    # Only update floor indicator if the area is from the elevator cabin
    if area.is_in_group("cabin"):
        # print("current elevator floor number: ", floor_number)
        floor_indicator.update_indicator_position(floor_number)

func _on_input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:        
        SignalBus.navigation_click.emit(
            event.global_position,
            floor_instance.floor_number,
            -2  # Arbitrary index. 
        )
        get_viewport().set_input_as_handled()

func set_door_state(new_state: DoorState):
    door_state = new_state
    match door_state:
        DoorState.CLOSED:
            show_doors_closed()
        DoorState.OPEN:
            show_doors_opened()
        DoorState.OPENING:
            animate_doors_opening()
        DoorState.CLOSING:
            animate_doors_closing()

    # Emit the door state change via SignalBus
    SignalBus.door_state_changed.emit(door_state)

func get_door_state() -> DoorState:
    return door_state

func show_doors_closed():
    if door_animation_controller:
        door_animation_controller.play_animation("closed")
    else:
        push_warning("Animation controller not found when showing doors closed.")

func show_doors_opened():
    if door_animation_controller:
        door_animation_controller.stop_animation()
        door_animation_controller.hide_animation()
    else:
        push_warning("Animation controller not found when showing doors opened.")

func animate_doors_opening():
    if door_animation_controller:
        door_animation_controller.play_animation("opening")
    else:
        push_warning("Animation controller not found when animating doors opening.")

func animate_doors_closing():
    if door_animation_controller:
        door_animation_controller.play_animation("closing")
    else:
        push_warning("Animation controller not found when animating doors closing.")

#region Elevator Door Set-Up
func setup_elevator_instance(p_floor_instance):
    floor_instance = p_floor_instance
    name = "Elevator_" + str(floor_instance.floor_number)    
    add_to_group("elevators")
    position_elevator()
    update_elevator_door_collision_shape()
    setup_elevator_doors_position()    
    connect_to_signals()
    
func connect_to_signals():
    SignalBus.floor_area_entered.connect(_on_floor_area_entered)    

func position_elevator():    
    var edges_global = floor_instance.collision_edges
    var left_edge_local   = edges_global["left"]   - floor_instance.global_position.x
    var right_edge_local  = edges_global["right"]  - floor_instance.global_position.x
    var bottom_edge_local = edges_global["bottom"] - floor_instance.global_position.y
    
    var floor_center_x_local = (left_edge_local + right_edge_local) * 0.5
    var elevator_height = get_elevator_height()

    var elevator_bottom_aligned_y = bottom_edge_local - (elevator_height / 2)
    position = Vector2(floor_center_x_local, elevator_bottom_aligned_y)

func get_elevator_height():
    var elevator_sprite = $Frame
    if elevator_sprite and elevator_sprite.texture:
        return elevator_sprite.texture.get_height()
    else:
        push_warning("Elevator sprite node not found or has no texture.")
        return 0

func update_elevator_door_collision_shape():
    var elevator_sprite = $Frame
    var collision_shape = $CollisionShape2D
    if elevator_sprite and collision_shape:
        # Use texture dimensions directly
        var width = elevator_sprite.texture.get_width()
        var height = elevator_sprite.texture.get_height()
        var rectangle_shape = RectangleShape2D.new()
        rectangle_shape.extents = Vector2(width / 2, height / 2)
        collision_shape.shape = rectangle_shape
    else:
        push_warning("Cannot update collision shape: Missing nodes or textures")

func setup_elevator_doors_position():
    if door_animation_controller:
        door_animation_controller.setup_doors_position()
    else:
        push_warning("Animation controller not found when setting up doors position.")
#endregion
