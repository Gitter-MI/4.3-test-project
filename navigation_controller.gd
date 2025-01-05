# navigation_controller.gd
extends Node

var floors: Dictionary = {}
var doors: Dictionary = {}
var player: Dictionary = {}
var elevators: Dictionary = {}

func _ready():
    register_all_floors()
    register_all_doors()
    register_all_player_sprites()
    register_all_elevators()  # Add this line
    # print_all_registered()
    SignalBus.navigation_click.connect(_on_navigation_click)



func _on_navigation_click(global_position: Vector2, floor_number: int, door_index: int) -> void:    
    print("navigation_click => Global:", global_position, 
          " Floor:", floor_number, 
          " DoorIndex:", door_index)


#--- Floors ---
func register_all_floors():
    var floor_nodes = get_tree().get_nodes_in_group("floors")
    for floor_node in floor_nodes:
        if floor_node is Area2D:
            var floor_number = floor_node.floor_number
            var floor_edges = floor_node.get_collision_edges()
            register_floor(floor_number, floor_edges, floor_node)

func register_floor(floor_number: int, floor_edges: Dictionary, floor_ref: Node):
    floors[floor_number] = {
        "edges": floor_edges,
        "ref": floor_ref
    }


#--- Doors ---
func register_all_doors():
    var door_nodes = get_tree().get_nodes_in_group("doors")
    for door_node in door_nodes:
        if door_node is Area2D:
            var door_index = door_node.door_data.index
            var floor_number = door_node.door_data.floor_number
            var door_center_x = door_node.door_center_x  # global X

            # Use the door node's own collision edges, not the parent's
            var door_edges = door_node.get_collision_edges()

            register_door(door_index, floor_number, door_center_x, door_edges, door_node)


func register_door(
    door_index: int,
    floor_number: int,
    center_x: float,
    door_edges: Dictionary,
    door_ref: Node
):
    doors[door_index] = {
        "floor_number": floor_number,
        "center_x": center_x,
        "edges": door_edges,    # store the door's collision edges
        "ref": door_ref
    }



#--- Elevators ---
#--- Elevators ---
func register_all_elevators():
    var elevator_nodes = get_tree().get_nodes_in_group("elevators")
    for elevator_node in elevator_nodes:
        if elevator_node is Area2D:
            var floor_number = elevator_node.floor_instance.floor_number
            
            # Get the collision shape for proper boundaries
            var collision_shape = elevator_node.get_node("CollisionShape2D")
            if not collision_shape:
                push_warning("No CollisionShape2D found in elevator")
                continue
                
            var shape = collision_shape.shape as RectangleShape2D
            if not shape:
                push_warning("Elevator must use RectangleShape2D")
                continue
                
            # Calculate edges using global coordinates
            var global_pos = elevator_node.global_position
            var extents = shape.extents
            
            var elevator_edges = {
                "left": global_pos.x - extents.x,
                "right": global_pos.x + extents.x,
                "top": global_pos.y - extents.y,
                "bottom": global_pos.y + extents.y,
                "center": global_pos
            }
            
            register_elevator(floor_number, elevator_edges, elevator_node)

func register_elevator(floor_number: int, edges: Dictionary, elevator_ref: Node):
    elevators[floor_number] = {
        "position": edges["center"],
        "edges": edges,
        "floor_number": floor_number,
        "ref": elevator_ref
    }


#--- Player Sprites ---
func register_all_player_sprites():
    var sprite_nodes = get_tree().get_nodes_in_group("player_sprites")
    for node in sprite_nodes:
        if node is Node2D:
            register_player_sprite(node)

func register_player_sprite(player_node: Node2D):
    # Check if sprite_data_new exists and is of the correct type
    var data = player_node.get("sprite_data_new")
    if data is SpriteDataNew:
        player[player_node.name] = {
            "width": data.sprite_width,
            "height": data.sprite_height,
            "ref": player_node
        }


func print_all_registered():
    print("Print only the keys or the full dictionaries")
    print("Floors: ", floors)
    print("Doors: ", doors)
    print("Player: ", player.keys())
    print("Elevators: ", elevators)
    
#endregion
