# player.gd
extends Node2D

var sprite_data: PlayerSpriteData
var last_elevator_request: Dictionary = {"sprite_name": "", "floor_number": -1}
var previous_elevator_position: Vector2 = Vector2.ZERO

const PlayerSpriteData = preload("res://SpriteData.gd")

enum DoorState { CLOSED, OPENING, OPEN, CLOSING }


func _ready():
    add_to_group("player_sprites")   
    sprite_data = PlayerSpriteData.new()    
    sprite_data.sprite_width = $Sprite2D.texture.get_width() * $Sprite2D.scale.x
    sprite_data.sprite_height = $Sprite2D.texture.get_height() * $Sprite2D.scale.y

    SignalBus.elevator_arrived.connect(_on_elevator_arrived)
    SignalBus.elevator_position_updated.connect(_on_elevator_ride)
    SignalBus.door_state_changed.connect(_on_elevator_door_state_changed)

    set_initial_position()
    
    var floors = get_tree().get_nodes_in_group("floors")
    for floor_node in floors:
        floor_node.floor_clicked.connect(_on_floor_clicked)
        
    var doors = get_tree().get_nodes_in_group("doors")
    for door_node in doors:
        door_node.door_clicked.connect(_on_door_clicked)



#####################################################################################################
#####################################################################################################
##################              Vertical Movement Component                   #######################
#####################################################################################################
#####################################################################################################


func _on_elevator_arrived(sprite_name: String, _current_floor: int):
    if sprite_name == sprite_data.sprite_name \
    and sprite_data.current_position == sprite_data.current_elevator_position \
    and sprite_data.current_state == SpriteData.State.WAITING_FOR_ELEVATOR:
        # print("Elevator arrived. Checking door state...")
        var elevator = get_elevator_for_current_floor()        
        var current_door_state = elevator.get_door_state()
        if current_door_state == DoorState.OPEN:     
                   
            sprite_data.current_state = SpriteData.State.IN_ELEVATOR  # should go through entering elevator first. Needs to be implemented
            SignalBus.entering_elevator.emit(sprite_data.sprite_name, sprite_data.target_floor_number)
            z_index = -9
            # print(sprite_data.sprite_name, " is now IN_ELEVATOR (doors were already open)")


func get_elevator_for_current_floor() -> Area2D:
    # helper function for _on_elevator_arrived
    var elevators = get_tree().get_nodes_in_group("elevators")
    for elevator in elevators:
        if elevator.floor_instance and elevator.floor_instance.floor_number == sprite_data.current_floor_number:
            return elevator
    return null


func _on_elevator_door_state_changed(new_state):
    # print("Door state changed:", new_state)
    if new_state == DoorState.OPEN:
        # If player was waiting at the elevator, now it's safe to enter
        if sprite_data.current_state == SpriteData.State.WAITING_FOR_ELEVATOR \
        and sprite_data.current_position == sprite_data.current_elevator_position:
            sprite_data.current_state = SpriteData.State.IN_ELEVATOR
            SignalBus.entering_elevator.emit(sprite_data.sprite_name, sprite_data.target_floor_number)
            z_index = -9
            print(sprite_data.sprite_name, " is now IN_ELEVATOR (doors are open)")
        
        elif sprite_data.current_state == SpriteData.State.IN_ELEVATOR:
            # Player can now exit the elevator
            sprite_data.current_state = SpriteData.State.EXITING_ELEVATOR
            print(sprite_data.sprite_name, " is now EXITING_ELEVATOR")
            exiting_elevator()


func exiting_elevator() -> void:
    # print("exiting_elevator")
    z_index = 0 
    sprite_data.current_floor_number = sprite_data.target_floor_number    
    sprite_data.current_state = SpriteData.State.IDLE
    # when not IN_ELEVATOR the movement_logic() will handle the next action
    # print(sprite_data.sprite_name, " is now IDLE after exiting elevator")


func _on_elevator_ride(global_pos: Vector2) -> void:
    # this is logically dependent on the move_elevator() in cabin.gd Both sprites need to move in sync but they have a function each. 
    if sprite_data.current_state == SpriteData.State.IN_ELEVATOR:
        # Update the player position according to the elevator's position
        global_position.x = global_pos.x
        global_position.y = global_pos.y + (sprite_data.sprite_height / 2) 
        sprite_data.current_position = global_position

func _process(delta: float) -> void:
    if sprite_data.current_state != SpriteData.State.IN_ELEVATOR:
        movement_logic(delta)


#####################################################################################################
#####################################################################################################
##################              Horizontal Movement Component                 #######################
#####################################################################################################
#####################################################################################################

func movement_logic(delta: float) -> void:
    if sprite_data.current_state == SpriteData.State.IN_ELEVATOR:
        return

    if sprite_data.current_position != sprite_data.target_position:
        if sprite_data.target_floor_number == sprite_data.current_floor_number:
            move_towards_target_position(delta)
        else:
            sprite_data.needs_elevator = true
            if sprite_data.needs_elevator and sprite_data.current_position == sprite_data.current_elevator_position:
                var current_request = {
                    "sprite_name": sprite_data.sprite_name,
                    "floor_number": sprite_data.target_floor_number
                }

                if current_request != last_elevator_request:
                    SignalBus.floor_requested.emit(sprite_data.sprite_name, sprite_data.current_floor_number)
                    print("signal emitted: elevator requested")

                    last_elevator_request = current_request
                    sprite_data.current_state = SpriteData.State.WAITING_FOR_ELEVATOR
                    print(sprite_data.sprite_name, " is now WAITING_FOR_ELEVATOR. In movement logic")
                else:
                    # Duplicate request detected, do nothing
                    pass
            else:
                # Keep moving towards the elevator
                move_towards_position(sprite_data.current_elevator_position, delta)


func move_towards_target_position(delta: float) -> void:
    move_towards_position(sprite_data.target_position, delta)


func move_towards_position(target_position: Vector2, delta: float) -> void:
    var direction: Vector2 = (target_position - global_position).normalized()
    var distance: float = global_position.distance_to(target_position)

    if distance > 1:
        if sprite_data.current_state != SpriteData.State.WALKING:
            sprite_data.current_state = SpriteData.State.WALKING
            print(sprite_data.sprite_name, " started WALKING towards ", target_position)

        global_position += direction * sprite_data.speed * delta
    else:
        global_position = target_position
        sprite_data.current_position = global_position
        update_state_after_horizontal_movement()


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




#####################################################################################################
#####################################################################################################
##################              Human Player Movement Component               #######################
#####################################################################################################
#####################################################################################################

func adjust_click_position(collision_edges: Dictionary, click_position: Vector2, bottom_edge_y: float) -> Vector2:
    var sprite_width: float = sprite_data.sprite_width
    var sprite_height: float = sprite_data.sprite_height

    var adjusted_x: float = click_position.x
    var left_bound: float = collision_edges["left"]
    var right_bound: float = collision_edges["right"]

    if click_position.x < left_bound + sprite_width / 2:
        adjusted_x = left_bound + sprite_width / 2
    elif click_position.x > right_bound - sprite_width / 2:
        adjusted_x = right_bound - sprite_width / 2

    var adjusted_y: float = bottom_edge_y - sprite_height / 2

    return Vector2(adjusted_x, adjusted_y)


func _on_floor_clicked(floor_number: int, click_position: Vector2, bottom_edge_y: float, collision_edges: Dictionary) -> void:
    print("floor clicked")
    var adjusted_click_position: Vector2 = adjust_click_position(collision_edges, click_position, bottom_edge_y)

    if sprite_data.current_floor_number == floor_number:
        sprite_data.target_position = adjusted_click_position
        sprite_data.target_floor_number = floor_number
        sprite_data.target_room = -1
        sprite_data.needs_elevator = false
        last_elevator_request = {"sprite_name": "", "floor_number": -1}
    else:
        sprite_data.target_floor_number = floor_number
        sprite_data.target_position = adjusted_click_position
        sprite_data.target_room = -1

        var current_floor = get_floor_by_number(sprite_data.current_floor_number)
        var current_edges = current_floor.get_collision_edges()
        sprite_data.current_elevator_position = get_elevator_position(current_edges)


func _on_door_clicked(door_center_x: int, floor_number: int, door_index: int, collision_edges: Dictionary, _click_position: Vector2) -> void:
    print("door_center_x: ", door_center_x, ", floor_number: ", floor_number, ", door_index: ", door_index)
    var bottom_edge_y = collision_edges["bottom"]
    var door_click_position: Vector2 = Vector2(door_center_x, bottom_edge_y)
    var adjusted_click_position: Vector2 = adjust_click_position(collision_edges, door_click_position, bottom_edge_y)

    if sprite_data.current_floor_number == floor_number:
        sprite_data.target_position = adjusted_click_position
        sprite_data.target_floor_number = floor_number
        sprite_data.target_room = door_index
        sprite_data.needs_elevator = false
        last_elevator_request = {"sprite_name": "", "floor_number": -1}
        print(sprite_data.sprite_name, " target_room set to door index: ", door_index)
    else:
        sprite_data.target_floor_number = floor_number
        sprite_data.target_position = adjusted_click_position
        sprite_data.target_room = door_index
        print(sprite_data.sprite_name, " target_room set to door index: ", door_index)

        var current_floor = get_floor_by_number(sprite_data.current_floor_number)
        var current_edges = current_floor.get_collision_edges()
        sprite_data.current_elevator_position = get_elevator_position(current_edges)



#####################################################################################################
#####################################################################################################
##################              Basic Sprite Component                        #######################  
#####################################################################################################
#####################################################################################################


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

    sprite_data.current_elevator_position = get_elevator_position(edges)



func get_elevator_position(collision_edges: Dictionary) -> Vector2:    
    var center_x: float = (collision_edges["left"] + collision_edges["right"]) / 2
    var sprite_height: float = sprite_data.sprite_height
    var adjusted_y: float = collision_edges["bottom"] - sprite_height / 2
    return Vector2(center_x, adjusted_y)


func get_floor_by_number(floor_number: int) -> Node2D:
    var floors = get_tree().get_nodes_in_group("floors")
    for building_floor in floors:
        if building_floor.floor_number == floor_number:
            return building_floor
    return null



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
