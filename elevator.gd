# elevator.gd
extends Area2D

var floor_instance
const SCALE_FACTOR = 2.3

func setup_elevator_instance(p_floor_instance):
    floor_instance = p_floor_instance
    name = "Elevator_" + str(floor_instance.floor_number)
    add_to_group("elevators")
    apply_scale_factor()
    position_elevator()
    update_collision_shape()
    setup_elevator_animations()


# create the four new signals using the SignalBus and emit them via the SignalBus


func show_doors_closed():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        elevator_doors.visible = true
        elevator_doors.play("closed")        
        SignalBus.emit_signal("doors_closed", name, floor_instance.floor_number)

func show_doors_opened():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        elevator_doors.stop()
        elevator_doors.visible = false
        SignalBus.emit_signal("doors_opened", name, floor_instance.floor_number)

func animate_doors_opening():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        elevator_doors.visible = true
        elevator_doors.play("opening")    
        SignalBus.emit_signal("doors_opening", name, floor_instance.floor_number)

func animate_doors_closing():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        elevator_doors.visible = true
        elevator_doors.play("closing")    
        SignalBus.emit_signal("doors_closing", name, floor_instance.floor_number)




# callback function _on_doors_animation_finished()
# when the opening animation is done we call show_doors_opened and emit the signal that the elevator has arrived 
# signal elevator_arrived(sprite_name: String, current_floor: int) using the gloabl SignalBus
# 
# preferably 

#region Elevator Frame and Animation Set-up


func apply_scale_factor():
    var elevator_sprite = $Frame
    if elevator_sprite:
        elevator_sprite.scale *= SCALE_FACTOR
    else:
        push_warning("Elevator sprite not found to apply scale factor.")

func position_elevator():
    var viewport_size = get_viewport().size
    var x_position = viewport_size.x / 2  # Center horizontally

    var collision_edges = floor_instance.get_collision_edges()
    var bottom_edge_y = collision_edges["bottom"]

    var elevator_height = get_elevator_height()
    var y_position = bottom_edge_y - (elevator_height / 2)  # Position above the floor edge

    global_position = Vector2(x_position, y_position)

func get_elevator_height():
    var elevator_sprite = $Frame
    if elevator_sprite and elevator_sprite.texture:
        return elevator_sprite.texture.get_height() * elevator_sprite.scale.y
    else:
        return 0

func update_collision_shape():
    var elevator_sprite = $Frame
    var collision_shape = $CollisionShape2D
    if elevator_sprite and collision_shape:
        var width = elevator_sprite.texture.get_width() * elevator_sprite.scale.x
        var height = elevator_sprite.texture.get_height() * elevator_sprite.scale.y
        var rectangle_shape = RectangleShape2D.new()
        rectangle_shape.extents = Vector2(width / 2, height / 2)
        collision_shape.shape = rectangle_shape
    else:
        push_warning("Cannot update collision shape: Missing nodes or textures")

func setup_elevator_animations():
    # Now that floor_instance and collision edges are set, position the elevator_doors.
    var elevator_doors = $AnimatedSprite2D
    if not elevator_doors:
        push_warning("elevator_doors not found in Elevator scene.")
        return

    # Scale the elevator_doors as we did with the frame
    elevator_doors.scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)
    var door_texture = elevator_doors.sprite_frames.get_frame_texture("closed", 0)
    var door_height = 0
    if door_texture:
        door_height = door_texture.get_height() * elevator_doors.scale.y

    # Elevator is already positioned, so we know its height and global_position
    var elevator_height = get_elevator_height()
    var door_y_offset = (elevator_height - door_height) / 2
    elevator_doors.position = Vector2(0, door_y_offset)

    # Start in the closed state
    show_doors_closed()
#endregion
