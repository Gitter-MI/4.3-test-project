# player.gd
extends Node2D

var sprite_data: PlayerSpriteData
var last_elevator_request: Dictionary = {"sprite_name": "", "floor_number": -1}

const PlayerSpriteData = preload("res://SpriteData.gd")



func _ready():

    add_to_group("player_sprites")   
    sprite_data = PlayerSpriteData.new()

    # Update the sprite dimensions in the SpriteData resource    
    sprite_data.sprite_width = $Sprite2D.texture.get_width() * $Sprite2D.scale.x
    sprite_data.sprite_height = $Sprite2D.texture.get_height() * $Sprite2D.scale.y

    set_initial_position()

    # Connect to floor_clicked signal from all floors
    var floors = get_tree().get_nodes_in_group("floors")
    for floor_node in floors:
        floor_node.floor_clicked.connect(_on_floor_clicked)
        
    var doors = get_tree().get_nodes_in_group("doors")
    for door_node in doors:
        door_node.door_clicked.connect(_on_door_clicked)
    pass
    




func get_elevator_position(collision_edges: Dictionary) -> Vector2:
    var center_x: float = (collision_edges["left"] + collision_edges["right"]) / 2
    var sprite_height: float = sprite_data.sprite_height
    var adjusted_y: float = collision_edges["bottom"] - sprite_height / 2

    return Vector2(center_x, adjusted_y)

func _process(delta: float) -> void:
    movement_logic(delta)

func movement_logic(delta: float) -> void:
    if sprite_data.current_position != sprite_data.target_position:
        if sprite_data.target_floor_number == sprite_data.current_floor_number:
            # Move to target position on the same floor
            move_towards_target_position(delta)
        else:
            sprite_data.needs_elevator = true
            if sprite_data.needs_elevator and sprite_data.current_position == sprite_data.current_elevator_position:
                # Check if the current request is identical to the last request
                var current_request = {
                    "sprite_name": sprite_data.sprite_name,
                    "floor_number": sprite_data.target_floor_number
                }
                
                if current_request != last_elevator_request:
                    # Emit the elevator request signal
                    SignalBus.floor_requested.emit(sprite_data.sprite_name, sprite_data.current_floor_number)
                    print("signal emitted: elevator requested")
                    
                    # Update the last elevator request
                    last_elevator_request = current_request
                    
                    # Set sprite state to WAITING_FOR_ELEVATOR
                    sprite_data.current_state = SpriteData.State.WAITING_FOR_ELEVATOR
                    print(sprite_data.sprite_name, " is now WAITING_FOR_ELEVATOR. In movement logic")
                else:
                    pass
                    # print("Duplicate elevator request detected. Signal not emitted.")
            else:
                # Keep moving towards the elevator
                move_towards_position(sprite_data.current_elevator_position, delta)
                # Potentially emit a signal here if needed, but based on your comment, 
                # it seems you want to emit only when at the elevator position
                # Therefore, we omit emitting the signal here to prevent duplicates


                

                
                ## Jump to target floor
                #var target_floor = get_floor_by_number(sprite_data.target_floor_number)
                #var target_edges = target_floor.get_collision_edges()
                #var target_elevator_position = get_elevator_position(target_edges)
#
                ## Update sprite position to the elevator position of the target floor
                #global_position = target_elevator_position
                #sprite_data.current_position = global_position
                #sprite_data.current_floor_number = sprite_data.target_floor_number                
                #sprite_data.needs_elevator = false                

            #else:
                ## Keep moving towards the elevator
                #move_towards_position(sprite_data.current_elevator_position, delta)



func move_towards_target_position(delta: float) -> void:
    move_towards_position(sprite_data.target_position, delta)


# Function to move the sprite towards a target position
func move_towards_position(target_position: Vector2, delta: float) -> void:
    var direction: Vector2 = (target_position - global_position).normalized()
    var distance: float = global_position.distance_to(target_position)

    if distance > 1:
        # Set state to WALKING if not already walking
        if sprite_data.current_state != SpriteData.State.WALKING:
            sprite_data.current_state = SpriteData.State.WALKING
            print(sprite_data.sprite_name, " started WALKING towards ", target_position)

        # Move the sprite
        global_position += direction * sprite_data.speed * delta
    else:
        # Snap to the target position when close enough
        global_position = target_position
        sprite_data.current_position = global_position

        # Update state based on specific conditions
        update_state_after_movement()

# Helper function to update the sprite's state after reaching the target position
func update_state_after_movement() -> void:
    if sprite_data.needs_elevator:
        if sprite_data.current_state != SpriteData.State.WAITING_FOR_ELEVATOR:
            sprite_data.current_state = SpriteData.State.WAITING_FOR_ELEVATOR
            print(sprite_data.sprite_name, " is now WAITING_FOR_ELEVATOR. in update state")
    elif sprite_data.target_room >= 0:
        if sprite_data.current_state != SpriteData.State.ENTERING_ROOM:
            sprite_data.current_state = SpriteData.State.ENTERING_ROOM
            print(sprite_data.sprite_name, " is ENTERING_ROOM ", sprite_data.target_room)
    else:
        if sprite_data.current_state != SpriteData.State.IDLE:
            sprite_data.current_state = SpriteData.State.IDLE
            print(sprite_data.sprite_name, " is now IDLE.")


func adjust_click_position(collision_edges: Dictionary, click_position: Vector2, bottom_edge_y: float) -> Vector2:
    # Use the player's sprite dimensions from sprite_data
    var sprite_width: float = sprite_data.sprite_width
    var sprite_height: float = sprite_data.sprite_height

    # Adjust x-position to keep the sprite horizontally within bounds
    var adjusted_x: float = click_position.x
    var left_bound: float = collision_edges["left"]
    var right_bound: float = collision_edges["right"]

    if click_position.x < left_bound + sprite_width / 2:
        adjusted_x = left_bound + sprite_width / 2
    elif click_position.x > right_bound - sprite_width / 2:
        adjusted_x = right_bound - sprite_width / 2

    # Adjust y-position to align the bottom of the sprite with the floor
    var adjusted_y: float = bottom_edge_y - sprite_height / 2

    return Vector2(adjusted_x, adjusted_y)




func _on_floor_clicked(floor_number: int, click_position: Vector2, bottom_edge_y: float, collision_edges: Dictionary) -> void:
    # Get the adjusted click position using collision_edges
    print("floor clicked")
    var adjusted_click_position: Vector2 = adjust_click_position(collision_edges, click_position, bottom_edge_y)

    if sprite_data.current_floor_number == floor_number:
        # Adjust the click position and store the target position and floor number for later
        sprite_data.target_position = adjusted_click_position
        sprite_data.target_floor_number = floor_number  # No floor switch needed
        sprite_data.target_room = -1
    else:
        # Adjust the click position and store the target position and floor number for later
        sprite_data.target_floor_number = floor_number
        sprite_data.target_position = adjusted_click_position
        sprite_data.target_room = -1
        
        # Need to get the elevator position of the current floor
        var current_floor = get_floor_by_number(sprite_data.current_floor_number)
        var current_edges = current_floor.get_collision_edges()
        sprite_data.current_elevator_position = get_elevator_position(current_edges)


func _on_door_clicked(door_center_x: int, floor_number: int, door_index: int, collision_edges: Dictionary, _click_position: Vector2) -> void:
    print("door_center_x: ", door_center_x, ", floor_number: ", floor_number, ", door_index: ", door_index, ", collision_edges: ", collision_edges)
    
    var bottom_edge_y = collision_edges["bottom"]
    var door_click_position: Vector2 = Vector2(door_center_x, bottom_edge_y)
    var adjusted_click_position: Vector2 = adjust_click_position(collision_edges, door_click_position, bottom_edge_y)
  
    if sprite_data.current_floor_number == floor_number:
        # Store the target position, floor number and target_room for later
        sprite_data.target_position = adjusted_click_position
        sprite_data.target_floor_number = floor_number  # No floor switch needed
        sprite_data.target_room = door_index
        print(sprite_data.sprite_name, " target_room set to door index: ", door_index)
    else:
        # Store the target position, floor number and target_room for later
        sprite_data.target_floor_number = floor_number
        sprite_data.target_position = adjusted_click_position
        sprite_data.target_room = door_index
        print(sprite_data.sprite_name, " target_room set to door index: ", door_index)
        
        # Need to get the elevator position of the current floor
        var current_floor = get_floor_by_number(sprite_data.current_floor_number)
        var current_edges = current_floor.get_collision_edges()
        sprite_data.current_elevator_position = get_elevator_position(current_edges) 

#region Initial and unused methods
############################################
### these functions are called only once ###
############################################

func set_initial_position() -> void:
    var target_floor = get_floor_by_number(1)
    var edges: Dictionary = target_floor.get_collision_edges()

    global_position = Vector2(
        edges.left + float(sprite_data.sprite_width) / 2.0,
        edges.bottom - float(sprite_data.sprite_height) / 2.0
    )


    sprite_data.current_position = global_position
    sprite_data.target_position = sprite_data.current_position
    sprite_data.current_floor_number = target_floor.floor_number
    sprite_data.target_floor_number = target_floor.floor_number

    # Update the elevator position in sprite_data
    sprite_data.current_elevator_position = get_elevator_position(edges)


func get_floor_by_number(floor_number: int) -> Node2D:    
    var floors = get_tree().get_nodes_in_group("floors")
    for building_floor in floors:
        if building_floor.floor_number == floor_number:
            return building_floor
    return null  # Floor not found


##############################################
### These functions are currently not used ###
##############################################

func get_current_floor():
    print("get current floor called")
    # Create the physics query
    var query = PhysicsPointQueryParameters2D.new()
    query.position = global_position
    query.collision_mask = 1
    query.collide_with_areas = true  # Detect Area2D nodes
    query.collide_with_bodies = false  # We only want to detect areas

    # Get the physics state and perform the intersection test
    var space_state = get_world_2d().direct_space_state
    var results = space_state.intersect_point(query)

    # Check if we're on any floor areas
    if results.size() > 0:
        for result in results:
            if result.collider.is_in_group("floors"):
                return result.collider  # Return the current floor node
    return null  # Not on any floor
#endregion
