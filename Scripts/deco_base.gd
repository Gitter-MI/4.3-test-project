extends Node2D

@onready var navigation_controller := get_tree().get_root().get_node("Main/Navigation_Controller")
@export var deco_texture: Texture2D
const SpriteDataScript = preload("res://Data/SpriteData_new.gd")
var sprite_data_new: Resource = SpriteDataScript.new()
const SCALE_FACTOR = 2.3
var x_placement: int
var element_name: String

func _ready():
    $Sprite2D.texture = deco_texture
    instantiate_sprite()
    set_initial_position()

func set_data(x_percent: int, current_floor_number: int, sprite_name: String):
    sprite_data_new.current_floor_number = current_floor_number
    sprite_data_new.sprite_name = sprite_name
    x_placement = x_percent


func set_initial_position() -> void:
    var floor_number = sprite_data_new.current_floor_number
    var floor_info: Dictionary = navigation_controller.floors[floor_number]
    var edges: Dictionary = floor_info["edges"]    
    var floor_width = float(edges["right"] - edges["left"])
    var x_pos = edges["left"] + floor_width * (x_placement / 100.0)
    var bottom_edge_y = edges["bottom"]
    var top_edge_y = edges["top"]
    var sprite_height = sprite_data_new.sprite_height
    
    var y_pos: float

    if floor_number != 0: 
        y_pos = bottom_edge_y - (sprite_height * 0.5)
    else:
        y_pos = bottom_edge_y - (sprite_height * 0.51)
    
    if sprite_data_new.sprite_name == "WallLamp":
        y_pos = top_edge_y + (sprite_height * 0.51)
        
    if sprite_data_new.sprite_name == "Picture":
        y_pos = bottom_edge_y - (sprite_height * 1.1)
    

        
    global_position = Vector2(x_pos, y_pos)

    sprite_data_new.set_current_position(
        global_position,
        floor_number,
        sprite_data_new.current_room
    )
    sprite_data_new.set_target_position(
        global_position,
        floor_number,
        sprite_data_new.target_room
    )

func instantiate_sprite():
    add_to_group("deco_sprites")
    apply_scale_factor_to_sprite()
    update_sprite_dimensions()

func update_sprite_dimensions():
    var tex = $Sprite2D.texture
    if tex:
        sprite_data_new.sprite_width  = tex.get_width() * $Sprite2D.scale.x
        sprite_data_new.sprite_height = tex.get_height() * $Sprite2D.scale.y

func apply_scale_factor_to_sprite():
    if $Sprite2D:
        $Sprite2D.scale *= SCALE_FACTOR
    else:
        push_warning("Sprite2D node not found for scaling.")
