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
    register_all_elevators()

    SignalBus.navigation_click.connect(_on_navigation_click)


func _on_navigation_click(global_position: Vector2, floor_number: int, door_index: int) -> void:
    # Get sprite dimensions from your stored data


    var edges: Dictionary
    var initial_click_pos: Vector2

    # Decide which data to use:
    if door_index >= 0:     # Door Click        
        edges = doors[door_index]["edges"]
        var door_center_x = doors[door_index]["center_x"]
        var bottom_edge_y = edges["bottom"]
        initial_click_pos = Vector2(door_center_x, bottom_edge_y)

    elif door_index == -2:  # Elevator Click        
        edges = elevators[floor_number]["edges"]
        var elevator_center_x = elevators[floor_number]["position"].x
        var bottom_edge_y_elev = edges["bottom"]
        initial_click_pos = Vector2(elevator_center_x, bottom_edge_y_elev)

    else:   # Floor Click (door_index == -1)        
        edges = floors[floor_number]["edges"]
        initial_click_pos = global_position

    # Now clamp/adjust the click so the sprite won’t go out of bounds
    var adjusted_click_position: Vector2 = _adjust_click_position(
        edges,
        initial_click_pos
    )

    # Finally, emit our adjusted signal.
    SignalBus.emit_signal(
        "adjusted_navigation_click",
        floor_number,
        door_index,
        adjusted_click_position
    )


func _adjust_click_position(
    collision_edges: Dictionary,
    click_position: Vector2
) -> Vector2:
    var sprite_width: float = player["Player_new"].width
    var sprite_height: float = player["Player_new"].height
    var left_bound: float = collision_edges["left"]
    var right_bound: float = collision_edges["right"]
    var bottom_edge_y: float = collision_edges["bottom"]

    # Horizontal clamp
    var adjusted_x = click_position.x
    if adjusted_x < left_bound + sprite_width / 2:
        adjusted_x = left_bound + sprite_width / 2
    elif adjusted_x > right_bound - sprite_width / 2:
        adjusted_x = right_bound - sprite_width / 2

    # Vertical position: sprite stands on top of bottom edge
    var adjusted_y = bottom_edge_y - sprite_height / 2

    return Vector2(adjusted_x, adjusted_y)



        
 





       
func print_all_registered():
    print("Print only the keys or the full dictionaries")
    print("Floors: ", floors)
    print("Doors: ", doors)
    print("Player: ", player.keys())
    print("Elevators: ", elevators)

#region Register Areas

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
#endregion
