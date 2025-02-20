# floor.gd -> do not remove this comment!
extends Area2D

@export var floor_number: int = 0
@export var floor_image_path: String
var floor_sprite: Sprite2D
var collision_edges: Dictionary = {}


const DOOR_SCENE = preload("res://Scenes/Door.tscn")  # Preload the Door scene
const ELEVATOR_SCENE = preload("res://Scenes/Elevator.tscn")

const BOUNDARIES = {
    "x1": 0.0715,  # Left boundary
    "x2": 0.929,   # Right boundary
    "y1": 0.0760,  # Top boundary
    "y2": 1   # Bottom boundary
}


func _ready():
    add_to_group("floors")
    input_pickable = true    
    floor_sprite = $FloorSprite
    set_floor_image(floor_image_path)    
    collision_layer = 1    
    
    self.connect("area_entered", Callable(self, "_on_floor_area_entered"))



func _on_floor_area_entered(area: Area2D) -> void:    
    if area.get("sprite_data") or area.get("sprite_data_new"):        # # Check if the area that entered belongs to a sprite
        SignalBus.floor_area_entered.emit(area, floor_number)
        # print("Sprite '%s' entered floor %d" % [area.name, floor_number])
    if area.get("cabin_data"):
        SignalBus.floor_area_entered.emit(area, floor_number)
        

    

func _input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:        
        SignalBus.navigation_click.emit(
            event.global_position,
            floor_number,
            -1  # We use -1 since this is not a door
        )
        # print("_input_event: click_global_position: ", event.global_position)   # is the wrong value, but that's ok, we will adjust it
    #if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:        
        #var floor_collision_edges = get_collision_edges()        
        #var bottom_edge_y = collision_edges["bottom"]
        #SignalBus.floor_clicked.emit(
            #floor_number,
            #event.global_position,
            #bottom_edge_y,
            #floor_collision_edges
        #)


  
func get_collision_edges() -> Dictionary:    
    # is called when a sprite moves to a new floor to determine the y-coordinate    
    return collision_edges
    



#region set-up methods
############################################
### these functions are called only once ###
############################################

func position_floor(previous_floor_top_y_position, is_first_floor):
    if not floor_sprite:
        push_warning("Floor instance is missing FloorSprite node!")
        return previous_floor_top_y_position  # Return previous value to avoid errors

    var viewport_size = get_viewport().size
    var floor_height = floor_sprite.texture.get_height() * floor_sprite.scale.y    
    var x_position = viewport_size.x / 2
    var y_position = 0.0

    if is_first_floor:
        # Center the first floor vertically
        y_position = (viewport_size.y - floor_height) / 1.5
    else:
        # Stack the floor above the previous floor
        y_position = previous_floor_top_y_position - floor_height
    
    position = Vector2(x_position, y_position)    
    configure_collision_shape()
    # Return the y position of the top of this floor for the next calculation
    return y_position


func configure_collision_shape():
    
    var collision_shape = $CollisionShape2D
    if not (floor_sprite and collision_shape):
        push_warning("Missing nodes for collision shape configuration")
        return

    # Calculate sprite dimensions
    var sprite_width = floor_sprite.texture.get_width() * floor_sprite.scale.x
    var sprite_height = floor_sprite.texture.get_height() * floor_sprite.scale.y
    var collision_width = (BOUNDARIES.x2 - BOUNDARIES.x1) * sprite_width
    var collision_height = (BOUNDARIES.y2 - BOUNDARIES.y1) * sprite_height
    var delta_x = ((BOUNDARIES.x1 + BOUNDARIES.x2) / 2 - 0.5) * sprite_width
    var delta_y = ((BOUNDARIES.y1 + BOUNDARIES.y2) / 2 - 0.5) * sprite_height

    # Configure the collision shape
    var rectangle_shape = RectangleShape2D.new()
    rectangle_shape.extents = Vector2(collision_width / 2, collision_height / 2)
    collision_shape.shape = rectangle_shape
    collision_shape.position = Vector2(delta_x, delta_y)
    
    var floor_global_position = global_transform.origin  # Get the global position of the floor
    var top_left = floor_global_position + Vector2(delta_x - collision_width / 2, delta_y - collision_height / 2)
    var bottom_right = floor_global_position + Vector2(delta_x + collision_width / 2, delta_y + collision_height / 2)
    
    collision_edges = {
        "left": top_left.x,
        "right": bottom_right.x,
        "top": top_left.y,
        "bottom": bottom_right.y
    }

func set_floor_image(image_path: String):
    if image_path.is_empty():
        push_warning("Image path is empty!")
        return

    var texture = load(image_path)
    if texture:
        floor_sprite.texture = texture
    else:
        push_error("Failed to load floor image at path: " + image_path)
        var file = FileAccess.open(image_path, FileAccess.READ)
        if file:
            print("File exists but couldn't be loaded as texture")
        else:
            print("File does not exist at path: " + image_path)

func setup_doors(door_data_array):    
    for door_data in door_data_array:
        var door_instance = DOOR_SCENE.instantiate()
        door_instance.name = "Door_" + str(door_data.index)
        add_child(door_instance)        
        door_instance.setup_door_instance(door_data, self)

func setup_elevator():
    var elevator_instance = ELEVATOR_SCENE.instantiate()
    elevator_instance.name = "Elevator"
    add_child(elevator_instance)
    elevator_instance.setup_elevator_instance(self)
        
#endregion
