extends "res://Scripts/floor_element.gd"

@onready var sprite: Sprite2D = $Sprite2D

const TEXTURE_PATH = "res://Building/Rooms/"

func _ready():
    super._ready()
    setup_texture()

func setup(p_door_data, p_floor_instance):
    super.setup(p_door_data, p_floor_instance)
    setup_texture()
    
    input_pickable = true
    if door_data.get("is_visible", true):
        visible = true
    else:
        #Area2D is active but sprite hidden
        visible = true
        if sprite:
            sprite.visible = false
    
    # Force collision shape update after visibility changes
    call_deferred("update_collision_shape")

func setup_texture():
    if not sprite or not door_data:
        return
        
    # Load texture based on room_name or screen property
    var texture_path = ""
    if door_data.has("screen"):
        texture_path = TEXTURE_PATH + door_data.screen + ".png"
    else:
        texture_path = TEXTURE_PATH + door_data.room_name + ".png"
    
    # print("Attempting to load texture: ", texture_path)
    var texture = load(texture_path)
    if texture:
        sprite.texture = texture
    else:
        push_warning("Failed to load texture: " + texture_path)

func get_element_dimensions() -> Dictionary:
    if not sprite or not sprite.texture:
        return { "width": 50.0, "height": 50.0 }  # Default fallback size
        
    var width = sprite.texture.get_width() * sprite.scale.x
    var height = sprite.texture.get_height() * sprite.scale.y
    return { "width": width, "height": height }



func position_element():
    if not floor_instance or not door_data:
        return
        
    var floor_collision_shape = floor_instance.get_node("CollisionShape2D")
    if not floor_collision_shape:
        push_warning("Missing CollisionShape2D in floor instance")
        return
        
    var shape = floor_collision_shape.shape
    if not shape is RectangleShape2D:
        push_warning("Floor collision shape is not RectangleShape2D")
        return
        
    var rect_shape = shape as RectangleShape2D
    var collision_width = rect_shape.extents.x * 2
    var collision_left_edge = floor_collision_shape.global_position.x - rect_shape.extents.x
    
    var percentage = door_data.get("slot_percentage", 0.5)
    var local_x = collision_left_edge + percentage * collision_width
    
    var collision_edges = floor_instance.get_collision_edges()
    var bottom_edge_y = collision_edges["bottom"]
    var top_edge_y = collision_edges["top"]
    
    var local_y
    local_y = top_edge_y + (bottom_edge_y - top_edge_y) * 0.5
    
    global_position = Vector2(local_x, local_y)
    door_center_x = local_x
    
    print("Positioned kiosk:", door_data.room_name, " at:", global_position)
