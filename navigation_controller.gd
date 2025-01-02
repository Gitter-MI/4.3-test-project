# navigation_controller.gd
extends Node

var floors: Dictionary = {}
var doors: Dictionary = {}

func _ready():    
    register_all_floors()
    register_all_doors()
    # print_all_registered()


#region Register Floors and Doors
func register_all_floors():
    var floor_nodes = get_tree().get_nodes_in_group("floors")
    for floor_node in floor_nodes:
        if floor_node is Area2D:
            var floor_number = floor_node.floor_number
            var floor_edges = floor_node.get_collision_edges()
            register_floor(floor_number, floor_edges, floor_node)


func register_all_doors():
    var door_nodes = get_tree().get_nodes_in_group("doors")
    for door_node in door_nodes:
        if door_node is Area2D:
            var door_index = door_node.door_data.index
            var floor_number = door_node.door_data.floor_number
            var door_center_x = door_node.door_center_x
            var parent_collision_edges = door_node.get_parent().collision_edges
            register_door(door_index, floor_number, door_center_x, parent_collision_edges, door_node)


func register_floor(floor_number: int, floor_edges: Dictionary, floor_ref: Node):
    floors[floor_number] = {
        "edges": floor_edges,
        "ref": floor_ref
    }
    # Optional: debug prints or logs


func register_door(door_index: int, floor_number: int, center_x: float, parent_edges: Dictionary, door_ref: Node):
    doors[door_index] = {
        "floor_number": floor_number,
        "center_x": center_x,
        "parent_edges": parent_edges,
        "ref": door_ref
    }
    # Optional: debug prints or logs


func print_all_registered():
    print("Floors:", floors.keys())
    print("Doors:", doors.keys())
#endregion
