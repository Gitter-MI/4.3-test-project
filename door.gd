# door.gd
extends Area2D

enum DoorState { CLOSED, OPEN }

var current_state: DoorState = DoorState.CLOSED
var door_type: int
var door_data
var floor_instance

const SLOT_PERCENTAGES = [0.15, 0.35, 0.65, 0.85]

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tooltip_background = $TooltipBackground  # TooltipBackground node with tooltip.gd attached

func setup(p_door_data, p_floor_instance):
    door_data = p_door_data
    floor_instance = p_floor_instance
    door_type = door_data.door_type
    set_door_state(DoorState.CLOSED)
    position_door()
    update_collision_shape()
    tooltip_background.set_text(door_data.tooltip)
    connect("mouse_entered", self._on_mouse_entered)
    connect("mouse_exited", self._on_mouse_exited)

func position_door():
    var slot_index = door_data.door_slot
    if slot_index < 0 or slot_index >= SLOT_PERCENTAGES.size():
        push_warning("Invalid door slot index %d" % slot_index)
        return

    var marker = floor_instance.get_node("Marker2D")
    var floor_collision_shape = floor_instance.get_node("CollisionShape2D")
    if not (marker and floor_collision_shape):
        push_warning("Missing nodes for door position calculation")
        return

    var shape = floor_collision_shape.shape
    if shape is RectangleShape2D:
        var rect_shape = shape as RectangleShape2D
        var collision_width = rect_shape.extents.x * 2
        var collision_left_edge = floor_collision_shape.position.x - rect_shape.extents.x

        var percentage = SLOT_PERCENTAGES[slot_index]
        var local_x = collision_left_edge + percentage * collision_width

        var dimensions = get_door_dimensions()
        var local_y = marker.position.y - (dimensions.height / 2)
        position = Vector2(local_x, local_y)
    else:
        push_warning("Collision shape is not a RectangleShape2D")

func get_door_dimensions():
    var animation_name = "door_type_%d" % door_type
    return get_frame_dimensions(animation_name)

func get_frame_dimensions(animation_name: String) -> Dictionary:
    if animated_sprite and animated_sprite.sprite_frames:
        if animation_name in animated_sprite.sprite_frames.get_animation_names():
            var first_frame = animated_sprite.sprite_frames.get_frame_texture(animation_name, 0)
            if first_frame:
                var width = first_frame.get_width() * animated_sprite.scale.x
                var height = first_frame.get_height() * animated_sprite.scale.y
                return { "width": width, "height": height }
    return { "width": 0.0, "height": 0.0 }

func set_door_state(new_state: DoorState) -> void:
    current_state = new_state
    var animation_name = "door_open" if current_state == DoorState.OPEN else "door_type_%d" % door_type
    if animation_name in animated_sprite.sprite_frames.get_animation_names():
        animated_sprite.play(animation_name)
        animated_sprite.stop()
    else:
        push_warning("Animation %s not found!" % animation_name)

func update_collision_shape() -> void:
    var animation_name = "door_type_%d" % door_type
    var dimensions = get_frame_dimensions(animation_name)
    if dimensions.width > 0 and dimensions.height > 0:
        var rectangle_shape = RectangleShape2D.new()
        rectangle_shape.extents = Vector2(dimensions.width / 2, dimensions.height / 2)
        collision_shape.shape = rectangle_shape
    else:
        push_warning("Cannot update collision shape: Invalid dimensions")

func _on_mouse_entered():
    tooltip_background.show_tooltip()

func _on_mouse_exited():
    tooltip_background.hide_tooltip()
