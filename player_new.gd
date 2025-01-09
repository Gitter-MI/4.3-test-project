# player_new.gd
extends Area2D

@onready var navigation_controller: Node = get_parent().get_node("Navigation_Controller")
@onready var pathfinder: Pathfinder = $Pathfinder_Component


const SCALE_FACTOR = 2.3
var sprite_data_new: SpriteDataNew
var last_elevator_request: Dictionary = {"sprite_name": "", "floor_number": -1}
var previous_elevator_position: Vector2 = Vector2.ZERO



func _ready():
    instantiate_sprite()
    connect_to_signals()
    set_initial_position()

    



func _process(delta: float) -> void:    

    # process_input
    # process_commands
    # process_state
    
    # pathfinder.determine_path() # (sprite_data_new, sprite_data_new.sprite_name)

    pass    









func _on_floor_area_entered(area: Area2D, floor_number: int) -> void:            
    if area == $".": # If the area that triggered the signal belongs to excactly this sprite
        # print("I, %s, have entered floor #%d" % [name, floor_number])
        sprite_data_new.current_floor_number = floor_number
    

func _on_navigation_click(_click_global_position: Vector2, _floor_number: int, _door_index: int) -> void:
    # print("Navigation click received in player script")
    pass



#region set_initial_position
func set_initial_position() -> void:    
    var current_floor_number: int = sprite_data_new.current_floor_number
    var floor_info: Dictionary = navigation_controller.floors[current_floor_number]

    var edges: Dictionary = floor_info["edges"]  # floors[floor_number]["edges"]
    var center_x = (edges["left"] + edges["right"]) / 2.0
    var bottom_edge_y = edges["bottom"]
    var sprite_height = sprite_data_new.sprite_height
    var y_position = bottom_edge_y - (sprite_height / 2.0)

    global_position = Vector2(center_x, y_position)

    
    sprite_data_new.current_position = global_position
    sprite_data_new.target_position = global_position
    sprite_data_new.current_floor_number = current_floor_number
    sprite_data_new.target_floor_number = current_floor_number
#endregion


#region connect_to_signals
func connect_to_signals():
    SignalBus.navigation_click.connect(_on_navigation_click)    
    SignalBus.floor_area_entered.connect(_on_floor_area_entered)
    #SignalBus.elevator_arrived.connect(_on_elevator_arrived)   
    #SignalBus.elevator_position_updated.connect(_on_elevator_ride)
    #SignalBus.door_state_changed.connect(_on_elevator_door_state_changed)
    #SignalBus.floor_clicked.connect(_on_floor_clicked)
    #SignalBus.door_clicked.connect(_on_door_clicked)
    #$AnimatedSprite2D.animation_finished.connect(_on_sprite_entered_elevator)   
#endregion


#region instantiate_sprite


#####################################################################################################
##################              Basic Sprite Component                        #######################  
#####################################################################################################

func instantiate_sprite():
    add_to_group("player_sprites")
    sprite_data_new = SpriteDataNew.new()    
    apply_scale_factor_to_sprite()
    update_sprite_dimensions()
    update_collision_shape()    
    


func update_sprite_dimensions():
    var idle_texture = $AnimatedSprite2D.sprite_frames.get_frame_texture("idle", 0)
    if idle_texture:
        sprite_data_new.sprite_width = idle_texture.get_width() * $AnimatedSprite2D.scale.x
        sprite_data_new.sprite_height = idle_texture.get_height() * $AnimatedSprite2D.scale.y
    else:
        print("Warning: 'idle' animation (frame 0) not found.")


func update_collision_shape():    
    var collision_shape = $CollisionShape2D
    if collision_shape:
        var rect_shape = RectangleShape2D.new()
        rect_shape.size = Vector2(sprite_data_new.sprite_width, sprite_data_new.sprite_height)
        collision_shape.shape = rect_shape        
        collision_shape.position = Vector2.ZERO
    else:
        print("Warning: CollisionShape2D not found.")


func apply_scale_factor_to_sprite():
    var sprite = $AnimatedSprite2D
    if sprite:
        sprite.scale *= SCALE_FACTOR
        # print("Applied scale factor to player sprite.")
    else:
        push_warning("AnimatedSprite2D node not found for scaling.")



#endregion
