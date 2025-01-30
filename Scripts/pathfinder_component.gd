# Pathfinder.gd
extends Node
# class_name Pathfinder
const SpriteDataNew = preload("res://Scripts/SpriteData_new.gd")
@onready var navigation_controller: Node = get_tree().get_root().get_node("Main/Navigation_Controller")
#
#@onready var data: Resource = SpriteDataNew.new()

const MOVEMENT = SpriteDataNew.MovementState
const ROOM = SpriteDataNew.RoomState
const ELEVATOR = SpriteDataNew.ElevatorState

#func some_function():
    #data.set_elevator_state(ELEVATOR.WAITING_FOR_ELEVATOR)


func _ready():
    # print("Pathfinder component")    
    pass
    

func determine_path(sprite: SpriteDataNew) -> void:
    
    if not sprite.has_nav_data:        
        return    
    
    
    if sprite.needs_elevator(sprite.nav_target_floor):
        # print("Elevator needed to reach floor:", sprite.nav_target_floor)        
        var elevator_info = navigation_controller.elevators.get(sprite.current_floor_number, null)        
        var elevator_position = elevator_info["position"]
        var new_target_position = Vector2(elevator_position.x, sprite.current_position.y)
        # sprite.elevator_requested = false
        # sprite.elevator_request_confirmed = false
        sprite.set_target_position(new_target_position, sprite.current_floor_number, sprite.current_room)        
        sprite.set_stored_position(sprite.nav_target_position, sprite.nav_target_floor, sprite.nav_target_room)
        # print("Original navigation data stored in stored data.")
        # print("Target position set to Elevator at:", new_target_position)
        
    else:
        # print("I can walk there directly.")        
        sprite.set_target_position(sprite.nav_target_position, sprite.nav_target_floor, sprite.nav_target_room)                
    
    sprite.reset_nav_data()
    # print("Navigation data has been reset.")

    
