# elevator.gd
extends Area2D

var floor_instance
const SCALE_FACTOR = 2.3  # Apply scale factor
const CABIN_SCENE = preload("res://Cabin.tscn")  # Preload the Cabin scene

func setup_elevator_instance(p_floor_instance):
    floor_instance = p_floor_instance
    name = "Elevator_" + str(floor_instance.floor_number)
    apply_scale_factor()
    position_elevator()
    update_collision_shape()
    # Instantiate the Cabin only if its `current_floor` matches the floor_instance's number
    var cabin_instance = CABIN_SCENE.instantiate()
    if cabin_instance.get("current_floor") == floor_instance.floor_number:
        setup_cabin()


func apply_scale_factor():
    # Apply the scale factor to the Sprite2D node
    var elevator_sprite = $Open
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
    var elevator_sprite = $Open
    if elevator_sprite and elevator_sprite.texture:
        return elevator_sprite.texture.get_height() * elevator_sprite.scale.y
    else:
        return 0


func update_collision_shape():
    var elevator_sprite = $Open
    var collision_shape = $CollisionShape2D
    if elevator_sprite and collision_shape:
        var width = elevator_sprite.texture.get_width() * elevator_sprite.scale.x
        var height = elevator_sprite.texture.get_height() * elevator_sprite.scale.y
        var rectangle_shape = RectangleShape2D.new()
        rectangle_shape.extents = Vector2(width / 2, height / 2)  # Divide by 2 for extents
        collision_shape.shape = rectangle_shape
    else:
        push_warning("Cannot update collision shape: Missing nodes or textures")



func setup_cabin():
    var cabin_instance = CABIN_SCENE.instantiate()
    if cabin_instance:
        add_child(cabin_instance)
        cabin_instance.name = "Cabin"
        apply_scale_factor_to_cabin(cabin_instance)
        position_cabin(cabin_instance)
    else:
        push_warning("Failed to instantiate Cabin scene")

func apply_scale_factor_to_cabin(cabin_instance):
    # Apply the scale factor to the Cabin node
    cabin_instance.scale *= SCALE_FACTOR

func position_cabin(cabin_instance):
    var viewport_size = get_viewport().size
    var x_position = viewport_size.x / 2  # Center horizontally

    var collision_edges = floor_instance.get_collision_edges()
    var bottom_edge_y = collision_edges["bottom"]

    var cabin_height = get_cabin_height(cabin_instance)
    var y_position = bottom_edge_y - (cabin_height / 2)  # Position above the floor edge

    cabin_instance.global_position = Vector2(x_position, y_position)

func get_cabin_height(cabin_instance):
    if cabin_instance.texture:
        return cabin_instance.texture.get_height() * cabin_instance.scale.y
    else:
        return 0
