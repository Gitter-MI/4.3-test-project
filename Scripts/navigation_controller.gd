# navigation_controller.gd
extends Node

const SpriteDataNew = preload("res://Data/SpriteData_new.gd")

var floors: Dictionary = {}
var doors: Dictionary = {}
var player: Dictionary = {}
var elevators: Dictionary = {}

func _ready():
    
    register_all_floors()
    register_all_doors()    
    register_all_elevators()
    # print_all_registered()

    SignalBus.navigation_click.connect(_on_navigation_click)
    SignalBus.all_sprites_ready.connect(_on_sprites_ready)    
    
    '''For testing the elevator with random AI sprite destination floors'''
    # randomize()



func _on_sprites_ready():
    # print("sprites ready signal received")  # is being printed once
    register_sprites()
    # print_all_registered()


func _on_navigation_command(sprite_name: String, destination_floor_number: int, destination_door_index: int, commander: String, adjusted_position: Vector2) -> void:
    SignalBus.adjusted_navigation_command.emit(commander, sprite_name, destination_floor_number, destination_door_index, adjusted_position )


var count: int = 0

func _on_navigation_click(global_position: Vector2, floor_number: int, door_index: int) -> void:    
    # print("click recorded")
    var click_data: Dictionary = _determine_click_type(door_index, floor_number, global_position)
    var edges: Dictionary = click_data["edges"]
    var initial_click_pos: Vector2 = click_data["initial_click_pos"]
    var adjusted_click_position: Vector2 = _adjust_click_position(edges, initial_click_pos)
    print("adjusted_click_position: ", adjusted_click_position)
    var commander: String = "player_input"
    # print("_on_navigation_click: global_position: ", global_position)    
    _on_navigation_command("Player", floor_number, door_index, commander, adjusted_click_position)
    
    
    #if count == 0:
        #_on_navigation_command("AI_SPRITE", floor_number, door_index, commander, adjusted_click_position)
        #count = count + 1
    #if count == 0:
        #var random_floor = get_random_floor()
        ## setting room to -1 so the AI sprite does not get caught up in the elevator room (where it should never be)
        #_on_navigation_command("AI_SPRITE", random_floor, -1, commander, adjusted_click_position)
        ## _on_navigation_command("DECO_SPRITE", 4 + 1, -1, commander, adjusted_click_position)
        #count += 1


func get_random_floor() -> int:
    # randi() % 14 yields an integer from 0 to 13.
    return randi() % 5





func _determine_click_type(door_index: int, floor_number: int, global_position: Vector2) -> Dictionary:
    var edges: Dictionary
    var initial_click_pos: Vector2

    if door_index >= 0:
        # Door Click
        edges = doors[door_index]["edges"]
        var door_center_x = doors[door_index]["center_x"]
        var bottom_edge_y = edges["bottom"]
        initial_click_pos = Vector2(door_center_x, bottom_edge_y)

    elif door_index == -2:
        # Elevator Click
        edges = elevators[floor_number]["edges"]
        var elevator_center_x = elevators[floor_number]["position"].x
        var bottom_edge_y_elev = edges["bottom"]
        initial_click_pos = Vector2(elevator_center_x, bottom_edge_y_elev)

    else:
        # Floor Click (door_index == -1)
        edges = floors[floor_number]["edges"]
        # print("edges of floor 3 in nav controller: ", edges)  178
        initial_click_pos = global_position

    return {
        "edges": edges,
        "initial_click_pos": initial_click_pos
    }





func _adjust_click_position(collision_edges: Dictionary, click_position: Vector2) -> Vector2:
    # Correct way to access sprite dimensions from the nested dictionary
    var _sprite_data = player["Player"] # Player == name of the player sprite, player == name of the dictionary where we store the data
    var sprite_width: float = player["Player"]["width"]
    var sprite_height: float = player["Player"]["height"]

    var left_bound: float = collision_edges["left"]
    var right_bound: float = collision_edges["right"]
    var bottom_edge_y: float = collision_edges["bottom"]
    # print("bottom_edge_y in _adjust_click_position: ", bottom_edge_y)

    # Horizontal clamp
    var adjusted_x: float = click_position.x
    if adjusted_x < left_bound + sprite_width / 2:
        adjusted_x = left_bound + sprite_width / 2
    elif adjusted_x > right_bound - sprite_width / 2:
        adjusted_x = right_bound - sprite_width / 2

    # Vertical alignment (sprite stands on top of the bottom edge)
    var adjusted_y: float = bottom_edge_y - sprite_height / 2

    return Vector2(adjusted_x, adjusted_y)





       
func print_all_registered():
    #print("Print only the keys or the full dictionaries")
    # print("Floors: ", floors)
    #print("Doors: ", doors)
    print("Player: ", player) #.keys()
    # print("Elevators: ", elevators)

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


#--- Sprites ---
func register_sprites():
    # print("registering player sprites in nav controller") # is printed once
    var sprite_nodes = get_tree().get_nodes_in_group("sprites")
    # print("sprite_nodes: ", sprite_nodes)  # sprite_nodes is empty
    for node in sprite_nodes:    
        if node is Area2D:    # Player_new is an Area2D, all other nodes are not Area2D
            # print("node in register_sprites: ", node)
            # print("registering player sprite in register_sprites")
            register_all_sprites(node)

func register_all_sprites(player_node: Area2D):
    
    # print("in register player sprite") # is being printed twice
    # Fetch the correct property from player_node
    var sprite_data_new = player_node.get("sprite_data_new")
    # print("var data: ", data)
    if sprite_data_new is Resource:
        var sprite_name = sprite_data_new.sprite_name
        player[sprite_name] = {
            "name": sprite_data_new.sprite_name,
            "width": sprite_data_new.sprite_width,
            "height": sprite_data_new.sprite_height,
            "ref": player_node
        }
        # print("player dict in nav controller: ", player)  # prints the expected values
    else:
        push_warning(
            "The node '%s' does not have a valid sprite_data_new property of type SpriteDataNew."
            % player_node.name
        )




#endregion
