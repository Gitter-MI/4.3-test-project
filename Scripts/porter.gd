# porter.gd (modified version)
extends Area2D

enum DoorState { CLOSED, OPEN }

var current_state: DoorState = DoorState.CLOSED
var door_type: int
var door_data: Dictionary
var floor_instance
var door_center_x: float = 0.0 

const SLOT_PERCENTAGES = [0.07]

@onready var door_sprite: Sprite2D = $Kiosk_Sprite_2D   ## we call it Kiosk because the room doesn't have a door, like a real-world kiosk.
@onready var collision_shape: CollisionShape2D = $Kiosk_Collision_Shape_2D 
# Remove tooltip reference:
# @onready var tooltip_background = $TooltipBackground

func _ready():
    add_to_group("doors")
    input_pickable = true
    connect("input_event", self._on_input_event)
    
    # Automatically perform setup if door_data and floor_instance are already assigned.
    if door_data != null and floor_instance != null:
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

func _on_mouse_entered():
    # Replace the direct tooltip call with a signal emission
    var final_tooltip = door_data.tooltip
    if final_tooltip.find("{owner}") != -1:
        final_tooltip = final_tooltip.replace("{owner}", door_data.owner)
    
    # Position the tooltip above the kiosk
    var tooltip_position = global_position + Vector2(0, -40)
    
    # We don't have specific images for porter kiosks, so we're sending an empty image path
    SignalBus.show_tooltip.emit(tooltip_position, final_tooltip, "", 1.0)

func _on_mouse_exited():
    # Replace direct tooltip call with signal emission
    SignalBus.hide_tooltip.emit()

func get_collision_edges() -> Dictionary:
    if not collision_shape:
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

#region door setup
func setup_door_instance(p_door_data, p_floor_instance):
    door_data = p_door_data
    floor_instance = p_floor_instance
    door_type = door_data.door_type
    
    # Set the door state to CLOSED by default.
    set_door_state(DoorState.CLOSED)
    
    # Position the door based on floor collision shape.
    position_door()
    
    # Update the collision shape to match the sprite's texture.
    update_collision_shape()
    
    # Remove tooltip setup code:
    # var final_tooltip = door_data.tooltip
    # if final_tooltip.find("{owner}") != -1:
    #     final_tooltip = final_tooltip.replace("{owner}", door_data.owner)
    # tooltip_background.set_text(final_tooltip)
    
    connect("mouse_entered", self._on_mouse_entered)
    connect("mouse_exited", self._on_mouse_exited)

func update_collision_shape() -> void:
    var dimensions = get_door_dimensions()
    if dimensions.width > 0 and dimensions.height > 0:
        var rectangle_shape = RectangleShape2D.new()
        rectangle_shape.extents = Vector2(dimensions.width / 2, dimensions.height / 2)
        collision_shape.shape = rectangle_shape
    else:
        push_warning("Cannot update collision shape: Invalid dimensions")

func position_door():
    # Retrieve the slot index from door data.
    var slot_index = door_data.door_slot
    
    var floor_collision_shape = floor_instance.get_node("CollisionShape2D")
    if not floor_collision_shape:
        push_warning("Missing CollisionShape2D node for door position calculation")
        return

    var shape = floor_collision_shape.shape
    if shape is RectangleShape2D:
        var rect_shape = shape as RectangleShape2D
        var collision_width = rect_shape.extents.x * 2
        var collision_left_edge = floor_collision_shape.global_position.x - rect_shape.extents.x
        var collision_edges = floor_instance.get_collision_edges()
        var bottom_edge_y = collision_edges["bottom"]
        
        var dimensions = get_door_dimensions()

        var local_x: float
        if slot_index >= 0 and slot_index < SLOT_PERCENTAGES.size():
            var percentage = SLOT_PERCENTAGES[slot_index]
            local_x = collision_left_edge + percentage * collision_width
        elif slot_index == 4:
            local_x = collision_left_edge + (dimensions.width / 2)
        else:
            push_warning("Invalid door slot index %d" % slot_index)
            return        

        var local_y = bottom_edge_y - (dimensions.height / 2)
        
        global_position = Vector2(local_x, local_y)
        door_center_x = local_x
    else:
        push_warning("Collision shape is not a RectangleShape2D")

func get_door_dimensions():
    var tex = door_sprite.texture
    if tex:
        var width = tex.get_width() * door_sprite.scale.x
        var height = tex.get_height() * door_sprite.scale.y
        return { "width": width, "height": height }
    return { "width": 0.0, "height": 0.0 }
#endregion
