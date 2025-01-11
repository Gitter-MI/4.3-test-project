# Pathfinder.gd
extends Node
class_name Pathfinder
const SpriteDataNew = preload("res://SpriteData_new.gd")
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
        sprite.set_target_position(new_target_position, sprite.current_floor_number, sprite.current_room)        
        sprite.set_stored_position(sprite.nav_target_position, sprite.nav_target_floor, sprite.nav_target_room)
        # print("Original navigation data stored in stored data.")
        # print("Target position set to Elevator at:", new_target_position)
        
    else:
        # print("I can walk there directly.")        
        sprite.set_target_position(sprite.nav_target_position, sprite.nav_target_floor, sprite.nav_target_room)                
    
    sprite.reset_nav_data()
    # print("Navigation data has been reset.")

    




'''
Pathfinder 

Invoke when nav / command exists
Or
at target location and stored exists
(has_nav_data = true)

Invoke from _progress in player script, not from the other functions (done)


```
Sets target and stored position 
Inputs: nav or command or stored position  (in this case we are looking at the nav position)
Find path from nav [given destination]
Assumes in elevator target is elevator position on destination floor 
***
Requires update to current floor update signal: 
If in elevator transit and moving up then current floor+1

Else normal 
***
```

If nav floor is not current floor 
Set stored position to nav target 
Set target position to curr. floor elevator 
Set nav target to null

If nav floor is current floor 
Set target to nav target 
Set stored position and nav target to null 

If sprite in elevator transit and nav target on the way:
Set target to nav floor elevator 
Set stored position to nav target 
Set nav target to null 

If sprite in elevator transit and nav target is not on the way:
Set target to next floor 
Set stored position to nav target 
Set nav target to null

when done set has_nav_data to false

'''
