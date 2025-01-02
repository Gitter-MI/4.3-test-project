# player_new.gd
extends Node2D

const SCALE_FACTOR = 2.3

var sprite_data_new: SpriteDataNew

var last_elevator_request: Dictionary = {"sprite_name": "", "floor_number": -1}
var previous_elevator_position: Vector2 = Vector2.ZERO

const PlayerSpriteData = preload("res://SpriteData_new.gd")

const Elevator = preload("res://elevator.gd")

func _ready():
    add_to_group("player_sprites")   
    sprite_data_new = SpriteDataNew.new()   

    apply_scale_factor_to_sprite()
    update_sprite_dimensions()
    set_initial_position()

    #SignalBus.elevator_arrived.connect(_on_elevator_arrived)   
    #SignalBus.elevator_position_updated.connect(_on_elevator_ride)
    #SignalBus.door_state_changed.connect(_on_elevator_door_state_changed)
    #SignalBus.floor_clicked.connect(_on_floor_clicked)
    #SignalBus.door_clicked.connect(_on_door_clicked)
    #
    #$AnimatedSprite2D.animation_finished.connect(_on_sprite_entered_elevator)



#####################################################################################################
##################              Basic Sprite Component                        #######################  
#####################################################################################################

func update_sprite_dimensions():
    var idle_texture = $AnimatedSprite2D.sprite_frames.get_frame_texture("idle", 0)
    if idle_texture:
        sprite_data_new.sprite_width = (idle_texture.get_width() * $AnimatedSprite2D.scale.x)
        sprite_data_new.sprite_height = (idle_texture.get_height() * $AnimatedSprite2D.scale.y)
    else:
        push_warning("Warning: 'idle' animation (frame 0) not found.")



func apply_scale_factor_to_sprite():
    var sprite = $AnimatedSprite2D
    if sprite:
        sprite.scale *= SCALE_FACTOR
        # print("Applied scale factor to player sprite.")
    else:
        push_warning("AnimatedSprite2D node not found for scaling.")


func set_initial_position() -> void:
    var target_floor = get_floor_by_number(sprite_data_new.current_floor_number)             
    var edges: Dictionary = target_floor.get_collision_edges()

    # center of the floor
    var center_x = (edges.left + edges.right) / 2.0

    var bottom_edge_y = edges.bottom
    var sprite_height = sprite_data_new.sprite_height
    var y_position = bottom_edge_y - (sprite_height /2.0 )

    global_position = Vector2(center_x, y_position)

    sprite_data_new.current_position = global_position
    sprite_data_new.target_position = global_position
    sprite_data_new.current_floor_number = target_floor.floor_number
    sprite_data_new.target_floor_number = target_floor.floor_number
    sprite_data_new.current_elevator_position = get_elevator_position()


func get_elevator_position() -> Vector2:   
    
    var current_floor = get_floor_by_number(sprite_data_new.current_floor_number)
    # print("current floor in get_elevator position: ", sprite_data_new.current_floor_number)
    var current_edges = current_floor.get_collision_edges()
    
    var center_x: float = (current_edges["left"] + current_edges["right"]) / 2
    var sprite_height: float = sprite_data_new.sprite_height
    var adjusted_y: float = current_edges["bottom"] - (sprite_height / 2.0)

    return Vector2(center_x, adjusted_y)


func get_floor_by_number(floor_number: int) -> Node2D:
    
    var floors = get_tree().get_nodes_in_group("floors")
    for building_floor in floors:
        if building_floor.floor_number == floor_number:
            return building_floor
    return null
