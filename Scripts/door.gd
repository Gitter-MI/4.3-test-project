# Door.gd
extends Area2D

enum DoorState { CLOSED, OPEN }

var current_state: DoorState = DoorState.CLOSED
var door_type: int
var door_data: Dictionary
var floor_instance
var door_center_x: float = 0.0 

const SLOT_PERCENTAGES = [0.15, 0.35, 0.65, 0.85]

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var owner_logo_sprite: Sprite2D = $Sprite2D
@onready var tooltip = $Control

func _ready():
    add_to_group("doors")
    input_pickable = true
    connect("input_event", self._on_input_event)
    setup_door_instance(door_data, floor_instance)

func _on_input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        SignalBus.navigation_click.emit(
            event.global_position,
            door_data.floor_number,
            door_data.index
        )
        get_viewport().set_input_as_handled()

func set_door_state(new_state: DoorState) -> void:
    current_state = new_state
    var animation_name = "door_open" if current_state == DoorState.OPEN else "door_type_%d" % door_type
    if animation_name in animated_sprite.sprite_frames.get_animation_names():
        animated_sprite.play(animation_name)
        animated_sprite.stop()
    else:
        push_warning("Animation %s not found!" % animation_name)

func _on_mouse_entered():
    tooltip.show_tooltip()

func _on_mouse_exited():
    tooltip.hide_tooltip()

func get_collision_edges() -> Dictionary:
    var door_collision_shape = $CollisionShape2D
    if not door_collision_shape:
        push_error("No CollisionShape2D found in door")
        return {}
        
    var shape = collision_shape.shape
    if not shape is RectangleShape2D:
        push_error("Door collision shape must be RectangleShape2D")
        return {}
        
    var extents = shape.extents
    var global_pos = collision_shape.global_position
    
    return {
        "left": global_pos.x - extents.x,
        "right": global_pos.x + extents.x,
        "top": global_pos.y - extents.y,
        "bottom": global_pos.y + extents.y
    }

# Takes in a dict with an "owner" (see door_data.tres)
func change_owner(updated_door_data):
    _update_owner_logo_visibility(updated_door_data)

#region door setup
func setup_door_instance(p_door_data, p_floor_instance):
    door_data = p_door_data
    floor_instance = p_floor_instance
    door_type = door_data.door_type
    set_door_state(DoorState.CLOSED)
    position_door()
    update_collision_shape()
    add_owner_logo(p_door_data)
    
    var final_tooltip = door_data.tooltip
    if final_tooltip.find("{owner}") != -1:
        final_tooltip = final_tooltip.replace("{owner}", door_data.owner)
    tooltip.set_text(final_tooltip)
    
    # Decide which image to use based on door_data.room_name
    var room_to_image = {
        "archive": "res://Building/Rooms/tooltip_images/archive.png",
        "news": "res://Building/Rooms/tooltip_images/news.png",
        "boss": "res://Building/Rooms/tooltip_images/boss.png",
        "office": "res://Building/Rooms/tooltip_images/bureau.png",
        "studio": "res://Building/Rooms/tooltip_images/studio.png",
        "movieagency": "res://Building/Rooms/tooltip_images/movie_agency.png",
        "adagency": "res://Building/Rooms/tooltip_images/ad_agency.png"
    }
    var room_name = door_data.room_name
    if room_name in room_to_image:
        tooltip.set_image(room_to_image[room_name], 1.0)
    else:
        tooltip.set_image("")

    connect("mouse_entered", self._on_mouse_entered)
    connect("mouse_exited", self._on_mouse_exited)

func add_owner_logo(p_door_data):
    owner_logo_sprite.scale = Vector2(2.3, 2.3)
    _update_owner_logo_visibility(p_door_data)
    _update_owner_logo_color()

func _update_owner_logo_color():
    var owner_val = int(door_data.owner)
    match owner_val:
        1:
            owner_logo_sprite.modulate = Color(0.732, 0.245, 0.262)  # Red
        2:
            owner_logo_sprite.modulate = Color(0.04, 0.484, 0.037)  # Green
        3:
            owner_logo_sprite.modulate = Color(0.219, 0.417, 0.889)  # Blue
        4:
            owner_logo_sprite.modulate = Color(0.227, 0.227, 0.227)  # Dark grey/Black
        _:
            owner_logo_sprite.modulate = Color(1, 1, 1)  # Default white

func _update_owner_logo_visibility(p_door_data):
    door_data = p_door_data 
    if int(door_data.owner) in [1, 2, 3, 4]:
        owner_logo_sprite.visible = true
    else:
        owner_logo_sprite.visible = false

func update_collision_shape() -> void:
    var animation_name = "door_type_%d" % door_type
    var dimensions = get_frame_dimensions(animation_name)
    if dimensions.width > 0 and dimensions.height > 0:
        var rectangle_shape = RectangleShape2D.new()
        rectangle_shape.extents = Vector2(dimensions.width / 2, dimensions.height / 2)
        collision_shape.shape = rectangle_shape
    else:
        push_warning("Cannot update collision shape: Invalid dimensions")

func position_door():
    var slot_index = door_data.door_slot
    if slot_index < 0 or slot_index >= SLOT_PERCENTAGES.size():
        push_warning("Invalid door slot index %d" % slot_index)
        return

    var floor_collision_shape = floor_instance.get_node("CollisionShape2D")
    if not floor_collision_shape:
        push_warning("Missing CollisionShape2D node for door position calculation")
        return

    var shape = floor_collision_shape.shape
    if shape is RectangleShape2D:
        var rect_shape = shape as RectangleShape2D
        var collision_width = rect_shape.extents.x * 2
        var collision_left_edge = floor_collision_shape.global_position.x - rect_shape.extents.x

        var percentage = SLOT_PERCENTAGES[slot_index]
        var local_x = collision_left_edge + percentage * collision_width

        var collision_edges = floor_instance.get_collision_edges()
        var bottom_edge_y = collision_edges["bottom"]
        
        var dimensions = get_door_dimensions()
        var local_y = bottom_edge_y - (dimensions.height / 2)

        var global_door_position = Vector2(local_x, local_y)
        global_position = global_door_position
        door_center_x = global_door_position.x
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
#endregion
