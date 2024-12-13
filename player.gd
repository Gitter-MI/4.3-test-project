# player.gd
extends Node2D

var sprite_data: PlayerSpriteData
var last_elevator_request: Dictionary = {"sprite_name": "", "floor_number": -1}
var previous_elevator_position: Vector2 = Vector2.ZERO


const PlayerSpriteData = preload("res://SpriteData.gd")



func _ready():

    add_to_group("player_sprites")   
    sprite_data = PlayerSpriteData.new()

    # Update the sprite dimensions in the SpriteData resource    
    sprite_data.sprite_width = $Sprite2D.texture.get_width() * $Sprite2D.scale.x
    sprite_data.sprite_height = $Sprite2D.texture.get_height() * $Sprite2D.scale.y
    set_initial_position()

    SignalBus.elevator_arrived.connect(_on_elevator_arrived)
    SignalBus.elevator_position_updated.connect(_on_elevator_ride)
    SignalBus.elevator_doors_opened.connect(_on_elevator_doors_opened)   # disregard this duplicate for now. We will fix this in a separate step.     
    SignalBus.floor_clicked.connect(_on_floor_clicked)        
    SignalBus.door_clicked.connect(_on_door_clicked)        
    ####################################################
    SignalBus.doors_closing.connect(_on_doors_closing)
    SignalBus.doors_closed.connect(_on_doors_closed)
    SignalBus.doors_opening.connect(_on_doors_opening)
    SignalBus.doors_opened.connect(_on_doors_opened)
    ####################################################

# Placeholder handlers
func _on_doors_closing(elevator_name, floor_number):
    print("Doors closing signal received for elevator:", elevator_name, "on floor:", floor_number)

func _on_doors_closed(elevator_name, floor_number):
    print("Doors closed signal received for elevator:", elevator_name, "on floor:", floor_number)

func _on_doors_opening(elevator_name, floor_number):
    print("Doors opening signal received for elevator:", elevator_name, "on floor:", floor_number)

func _on_doors_opened(elevator_name, floor_number):
    print("Doors opened signal received for elevator:", elevator_name, "on floor:", floor_number)


func _on_elevator_arrived(sprite_name: String, _current_floor: int):
    if sprite_name == sprite_data.sprite_name \
    and sprite_data.current_position == sprite_data.current_elevator_position \
    and sprite_data.current_state == SpriteData.State.WAITING_FOR_ELEVATOR:


        print("My elevator has arrived. I will need to wait for the elevator doors to open before I can get in.")
        
        # the code below is actually for the sprite entering the elevator
        SignalBus.entering_elevator.emit(sprite_data.sprite_name, sprite_data.target_floor_number)
        # note: entering the elevator will take some time. We should use the ENTERING_ELEVATOR state and define the proper logic.
        # we can start by emitting the elevator arrived signal from the cabin after the doors have been opened. Then we can handle the entering process inside the player script
        # with these changes this function can remain unchanged for now. 
        sprite_data.current_state = SpriteData.State.IN_ELEVATOR
        z_index = -9


func _on_elevator_doors_opened(_current_floor: int) -> void:
    # If the sprite is currently in elevator and the elevator doors have opened
    if sprite_data.current_state == SpriteData.State.IN_ELEVATOR:
        # Update state to EXITING_ELEVATOR
        sprite_data.current_state = SpriteData.State.EXITING_ELEVATOR
        print(sprite_data.sprite_name, " is now EXITING_ELEVATOR")
        # Call the exiting function
        exiting_elevator()

func exiting_elevator() -> void:
    # Update z-index to 0 (as if stepping off the elevator)
    z_index = 0
    sprite_data.current_floor_number = sprite_data.target_floor_number
    # Set sprite state to IDLE
    sprite_data.current_state = SpriteData.State.IDLE
    print(sprite_data.sprite_name, " is now IDLE after exiting elevator")
        

func _on_elevator_ride(global_pos: Vector2) -> void:
    if sprite_data.current_state == SpriteData.State.IN_ELEVATOR:
        global_position.x = global_pos.x              
        global_position.y = global_pos.y + (sprite_data.sprite_height / 2)
        sprite_data.current_position = global_position



func _process(delta: float) -> void:
    # If the sprite is currently inside the elevator (IN_ELEVATOR),
    # we rely solely on the elevator updates for movement.
    # If not in the elevator, proceed with normal movement logic.
    if sprite_data.current_state != SpriteData.State.IN_ELEVATOR:
        movement_logic(delta)


func movement_logic(delta: float) -> void:
    # If currently in the elevator, vertical movement is handled by the _on_elevator_ride signal callback.
    if sprite_data.current_state == SpriteData.State.IN_ELEVATOR:
        return

    # If not in elevator, proceed with horizontal movement logic:
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
                    # Duplicate request detected, do nothing here
                    pass
            else:
                # Keep moving towards the elevator
                move_towards_position(sprite_data.current_elevator_position, delta)
    # If current_position == target_position, no further horizontal movement is required here.




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
        update_state_after_horizontal_movement()

# Helper function to update the sprite's state after reaching the target position
func update_state_after_horizontal_movement() -> void:
    if sprite_data.needs_elevator and sprite_data.current_position == sprite_data.current_elevator_position:
        if sprite_data.current_state != SpriteData.State.WAITING_FOR_ELEVATOR:
            sprite_data.current_state = SpriteData.State.WAITING_FOR_ELEVATOR
            print(sprite_data.sprite_name, " is now WAITING_FOR_ELEVATOR. in update state")
    elif sprite_data.target_room >= 0:
        if sprite_data.current_state != SpriteData.State.ENTERING_ROOM:
            sprite_data.current_state = SpriteData.State.ENTERING_ROOM
            last_elevator_request = {"sprite_name": "", "floor_number": -1}
            sprite_data.needs_elevator = false
            print(sprite_data.sprite_name, " is ENTERING_ROOM ", sprite_data.target_room)
            
    else:
        if sprite_data.current_state != SpriteData.State.IDLE:
            sprite_data.current_state = SpriteData.State.IDLE
            last_elevator_request = {"sprite_name": "", "floor_number": -1}
            sprite_data.needs_elevator = false
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
        sprite_data.needs_elevator = false
        last_elevator_request = {"sprite_name": "", "floor_number": -1}
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
        sprite_data.needs_elevator = false
        last_elevator_request = {"sprite_name": "", "floor_number": -1}
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

func get_elevator_position(collision_edges: Dictionary) -> Vector2:
    var center_x: float = (collision_edges["left"] + collision_edges["right"]) / 2
    var sprite_height: float = sprite_data.sprite_height
    var adjusted_y: float = collision_edges["bottom"] - sprite_height / 2

    return Vector2(center_x, adjusted_y)


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
