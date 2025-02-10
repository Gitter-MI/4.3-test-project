# Pathfinder.gd
extends Node
const SpriteDataNew = preload("res://Data/SpriteData_new.gd")
@onready var navigation_controller: Node = get_tree().get_root().get_node("Main/Navigation_Controller")


func determine_path(sprite_data_new: SpriteDataNew) -> bool:
    var stored_position_updated: bool = false
        
    if sprite_data_new.defer_input or not sprite_data_new.has_nav_data:
        # print("input defered / no new nav data: returning")
        return false

    
    if sprite_data_new.needs_elevator(sprite_data_new.nav_target_floor):
        #print(sprite_data_new.sprite_name, " needs to use the elevator.")
        var elevator_info = navigation_controller.elevators.get(sprite_data_new.current_floor_number, null)        
        var elevator_position = elevator_info["position"]        
        var new_target_position = Vector2(elevator_position.x, sprite_data_new.current_position.y)
        sprite_data_new.set_target_position(new_target_position, sprite_data_new.current_floor_number, sprite_data_new.current_room)
        sprite_data_new.set_stored_position(sprite_data_new.nav_target_position, sprite_data_new.nav_target_floor, sprite_data_new.nav_target_room)
        stored_position_updated = true
        # sprite_data_new.reset_elevator_status()
        
    else:
        #print(sprite_data_new.sprite_name, " does not need the elevator to switch floors.")
        sprite_data_new.set_target_position(
            sprite_data_new.nav_target_position, 
            sprite_data_new.nav_target_floor, 
            sprite_data_new.nav_target_room
        )
        
        if sprite_data_new.target_room == -2:
            print(sprite_data_new.sprite_name, " wants to enter the elevator room")            
            
        sprite_data_new.reset_stored_data()
        # print("sprite is walking, resetting the elevator status")
        # sprite_data_new.reset_elevator_status()
        stored_position_updated = false
 
    sprite_data_new.reset_nav_data()
    return stored_position_updated

    
