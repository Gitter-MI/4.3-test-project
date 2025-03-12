# FloorElement.gd
extends Area2D

var door_data: Dictionary
var floor_instance
var door_center_x: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else $Door_Collision_Shape_2D

func _ready():
    add_to_group("doors")
    input_pickable = true    

    connect("input_event", _on_input_event)
    connect("mouse_entered", _on_mouse_entered)
    connect("mouse_exited", _on_mouse_exited)
    
    if door_data != null and floor_instance != null:
        setup(door_data, floor_instance)

func setup(p_door_data, p_floor_instance):
    door_data = p_door_data
    floor_instance = p_floor_instance
    
    visible = door_data.get("is_visible", true)
    
    var door_state = get_node_or_null("DoorState")
    if door_state and door_state.has_method("initialize"):
        door_state.initialize(door_data)
    
    position_element()
    update_collision_shape()


func position_element():
    var slot_index = door_data.door_slot
    var floor_collision_shape = floor_instance.get_node("CollisionShape2D")
    
    if not floor_collision_shape:
        push_warning("Missing CollisionShape2D node for element position calculation")
        return

    var shape = floor_collision_shape.shape
    if shape is RectangleShape2D:
        var rect_shape = shape as RectangleShape2D
        var collision_width = rect_shape.extents.x * 2
        var collision_left_edge = floor_collision_shape.global_position.x - rect_shape.extents.x
        
        # Calculate percentage based on object type
        var percentage = 0.5  # Default fallback
        
        if door_data.has("slot_percentage"):
            # For kiosks with explicit percentage
            percentage = door_data.slot_percentage
        else:
            # For doors, check DoorState component for SLOT_PERCENTAGES
            var door_state = get_node_or_null("DoorState")
            if door_state and door_state.has_method("get_slot_percentages"):
                var percentages = door_state.get_slot_percentages()
                if slot_index >= 0 and slot_index < percentages.size():
                    percentage = percentages[slot_index]
                else:
                    push_warning("Invalid door slot index %d" % slot_index)
        
        var local_x = collision_left_edge + percentage * collision_width
        
        var collision_edges = floor_instance.get_collision_edges()
        var bottom_edge_y = collision_edges["bottom"]
        
        var dimensions = get_element_dimensions()
        var local_y = bottom_edge_y - (dimensions.height / 2)
        
        global_position = Vector2(local_x, local_y)
        door_center_x = local_x
    else:
        push_warning("Collision shape is not a RectangleShape2D")

func update_collision_shape():
    var dimensions = get_element_dimensions()
    if dimensions.width > 0 and dimensions.height > 0:
        var rectangle_shape = RectangleShape2D.new()
        rectangle_shape.extents = Vector2(dimensions.width / 2, dimensions.height / 2)
        collision_shape.shape = rectangle_shape
    else:
        push_warning("Cannot update collision shape: Invalid dimensions")

func get_element_dimensions() -> Dictionary:
    # First try to get dimensions from DoorState if available
    var door_state = get_node_or_null("DoorState")
    if door_state and door_state.has_method("get_door_dimensions"):
        return door_state.get_door_dimensions()
    
    # This will be overridden in Kiosk.gd for kiosk elements
    push_warning("get_element_dimensions not implemented or DoorState missing")
    return { "width": 0.0, "height": 0.0 }
    



func _on_input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        SignalBus.navigation_click.emit(
            event.global_position,
            door_data.floor_number,
            door_data.index
        )
        get_viewport().set_input_as_handled()

func _on_mouse_entered():
    SignalBus.show_tooltip.emit(door_data)

func _on_mouse_exited():
    SignalBus.hide_tooltip.emit()

func get_collision_edges() -> Dictionary:
    if not collision_shape:
        push_error("No CollisionShape2D found in element")
        return {}
        
    var shape = collision_shape.shape
    if not shape is RectangleShape2D:
        push_error("Element collision shape must be RectangleShape2D")
        return {}
        
    var extents = shape.extents
    var global_pos = collision_shape.global_position
    
    return {
        "left": global_pos.x - extents.x,
        "right": global_pos.x + extents.x,
        "top": global_pos.y - extents.y,
        "bottom": global_pos.y + extents.y
    }
