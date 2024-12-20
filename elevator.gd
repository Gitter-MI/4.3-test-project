# elevator.gd
extends Area2D

var floor_instance
const SCALE_FACTOR = 2.3

enum DoorState { CLOSED, OPENING, OPEN, CLOSING }
var door_state: DoorState = DoorState.CLOSED

func setup_elevator_instance(p_floor_instance):
    floor_instance = p_floor_instance
    name = "Elevator_" + str(floor_instance.floor_number)
    add_to_group("elevators")
    apply_scale_factor_to_elevator()
    position_elevator()
    update_elevator_door_collision_shape()
    setup_elevator_doors_position()

func _ready():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        elevator_doors.animation_finished.connect(_on_doors_animation_finished)
        print("Connected animation_finished signal.")
    else:
        push_warning("AnimatedSprite2D node not found in Elevator scene.")

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
    # print("Door state changed to: ", door_state)

func get_door_state() -> DoorState:
    return door_state

func show_doors_closed():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        elevator_doors.visible = true
        elevator_doors.play("closed")
        print("Showing doors closed.")
    else:
        push_warning("AnimatedSprite2D node not found when showing doors closed.")

func show_doors_opened():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        elevator_doors.stop()
        elevator_doors.visible = false
        print("Doors are opened (not visible).")
    else:
        push_warning("AnimatedSprite2D node not found when showing doors opened.")

func animate_doors_opening():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        elevator_doors.visible = true
        elevator_doors.play("opening")
        # print("Animating doors opening.")
    else:
        push_warning("AnimatedSprite2D node not found when animating doors opening.")

func animate_doors_closing():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        elevator_doors.visible = true
        elevator_doors.play("closing")
        # print("Animating doors closing.")
    else:
        push_warning("AnimatedSprite2D node not found when animating doors closing.")

func _on_doors_animation_finished():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        var current_anim = elevator_doors.animation
        print("Doors animation finished: ", current_anim)
        if current_anim == "opening" and door_state == DoorState.OPENING:
            set_door_state(DoorState.OPEN)
            print("Doors have fully opened.")
        if current_anim == "closing" and door_state == DoorState.CLOSING:
            set_door_state(DoorState.CLOSED)
            print("Doors have fully closed.")
            # Emit a signal to let the cabin know it can proceed
            SignalBus.doors_fully_closed.emit()

    else:
        push_warning("AnimatedSprite2D node not found when handling animation finished.")

func apply_scale_factor_to_elevator():
    var elevator_sprite = $Frame
    if elevator_sprite:
        elevator_sprite.scale *= SCALE_FACTOR
        print("Applied scale factor to elevator frame.")
    else:
        push_warning("Elevator sprite node not found to apply scale factor.")

func position_elevator():
    var viewport_size = get_viewport().size
    var x_position = viewport_size.x / 2
    var collision_edges = floor_instance.get_collision_edges()
    var bottom_edge_y = collision_edges["bottom"]
    var elevator_height = get_elevator_height()
    var y_position = bottom_edge_y - (elevator_height / 2)
    global_position = Vector2(x_position, y_position)
    print("Elevator positioned at: ", global_position)

func get_elevator_height():
    var elevator_sprite = $Frame
    if elevator_sprite and elevator_sprite.texture:
        return elevator_sprite.texture.get_height() * elevator_sprite.scale.y
    else:
        push_warning("Elevator sprite node not found or has no texture.")
        return 0

func update_elevator_door_collision_shape():
    var elevator_sprite = $Frame
    var collision_shape = $CollisionShape2D
    if elevator_sprite and collision_shape:
        var width = elevator_sprite.texture.get_width() * elevator_sprite.scale.x
        var height = elevator_sprite.texture.get_height() * elevator_sprite.scale.y
        var rectangle_shape = RectangleShape2D.new()
        rectangle_shape.extents = Vector2(width / 2, height / 2)
        collision_shape.shape = rectangle_shape
        print("Updated elevator door collision shape.")
    else:
        push_warning("Cannot update collision shape: Missing nodes or textures")

func setup_elevator_doors_position():
    var elevator_doors = $AnimatedSprite2D
    if not elevator_doors:
        push_warning("AnimatedSprite2D node not found in Elevator scene.")
        return

    elevator_doors.scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)
    var door_texture = elevator_doors.sprite_frames.get_frame_texture("closed", 0)
    var door_height = 0
    if door_texture:
        door_height = door_texture.get_height() * elevator_doors.scale.y
    var elevator_height = get_elevator_height()
    var door_y_offset = (elevator_height - door_height) / 2
    elevator_doors.position = Vector2(0, door_y_offset)

    # Initially show doors closed
    set_door_state(DoorState.CLOSED)
    print("Elevator doors set up and initially closed.")
