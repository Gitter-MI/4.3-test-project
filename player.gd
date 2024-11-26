extends Node2D

# Load the SpriteData class
const PlayerSpriteData = preload("res://SpriteData.gd")

var sprite_data: PlayerSpriteData

func _ready():
    # Initialize the data model
    sprite_data = PlayerSpriteData.new()

    # Update the sprite dimensions in the SpriteData resource
    if $Sprite2D.texture:
        sprite_data.sprite_width = $Sprite2D.texture.get_width() * $Sprite2D.scale.x
        sprite_data.sprite_height = $Sprite2D.texture.get_height() * $Sprite2D.scale.y

    set_initial_position()

    # Initialize the target position to the player's current position
    sprite_data.target_position = global_position
    sprite_data.current_position = global_position

    # Connect to floor_clicked signal from all floors
    var floors = get_tree().get_nodes_in_group("floors")
    for floor_node in floors:
        floor_node.floor_clicked.connect(_on_floor_clicked)

func set_initial_position() -> void:
    # Find floor 1 from the "floors" group
    var floors: Array = get_tree().get_nodes_in_group("floors")
    var target_floor: Node2D = null

    for building_floor in floors:
        if building_floor.floor_number == 1:
            target_floor = building_floor
            break

    # If no floor 1 is found, print an error and exit
    if target_floor == null:
        print("Error: No floor with number 1 found.")
        return

    
    # Ensure collision edges are available
    var edges: Dictionary = {}
    if target_floor.has_method("get_collision_edges"):
        edges = target_floor.get_collision_edges()
    else:
        # Print a detailed error message with the floor number
        print("Error: Target floor with floor_number ", target_floor.floor_number, " does not provide collision edges.")
        return

    # Retrieve the necessary bounds from the collision edges
    var left_edge_x: float = edges.get("left", 0.0)
    var bottom_edge_y: float = edges.get("bottom", 0.0)

    # Use the sprite dimensions from sprite_data
    var sprite_width: float = sprite_data.sprite_width
    var sprite_height: float = sprite_data.sprite_height

    # Set the player's starting position
    global_position = Vector2(
        left_edge_x + sprite_width / 2,
        bottom_edge_y - sprite_height / 2
    )

    # Update data model
    sprite_data.current_position = global_position
    sprite_data.current_floor_number = target_floor.floor_number



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



func get_current_floor():
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

func get_elevator_position(collision_edges: Dictionary) -> Vector2:
    var center_x: float = (collision_edges["left"] + collision_edges["right"]) / 2
    var sprite_height: float = sprite_data.sprite_height
    var adjusted_y: float = collision_edges["bottom"] - sprite_height / 2

    return Vector2(center_x, adjusted_y)


func _process(delta: float) -> void:
    # Update current floor number
    var current_floor: Node2D = get_current_floor()
    if current_floor:
        sprite_data.current_floor_number = current_floor.floor_number
    else:
        sprite_data.current_floor_number = -1

    # Move the player towards the target position
    if global_position != sprite_data.target_position:
        # Calculate the direction vector to the target position
        var direction: Vector2 = (sprite_data.target_position - global_position).normalized()
        var distance: float = global_position.distance_to(sprite_data.target_position)

        # Move the player if not at the target position
        if distance > 1:
            global_position += direction * sprite_data.speed * delta
            # sprite_data.state = "walking"
        else:
            global_position = sprite_data.target_position  # Snap to the target position when close enough
            # sprite_data.state = "idle"
            # Update current position in data model
            sprite_data.current_position = global_position

            # Retrieve collision edges for the current floor
            if current_floor and current_floor.has_method("get_collision_edges"):
                var collision_edges: Dictionary = current_floor.get_collision_edges()
                # Handle arrival at target position
                handle_arrival(current_floor, collision_edges)
            else:
                print("Error: Current floor or collision edges are not available.")


func handle_arrival(current_floor: Node2D, collision_edges: Dictionary) -> void:
    # print("In handle_arrival, current floor: ", current_floor)

    # Check if the player is at the elevator position
    if current_floor and sprite_data.target_position == get_elevator_position(collision_edges):
        # Check if the current floor is different from the destination floor
        if sprite_data.current_floor_number != sprite_data.target_floor_number:
            # Simulate moving to the target floor
            var floors: Array = get_tree().get_nodes_in_group("floors")
            for building_floor in floors:
                if building_floor.floor_number == sprite_data.target_floor_number:
                    # Move player to the elevator position on the target floor
                    var target_floor_edges: Dictionary = building_floor.collision_edges  # Assuming edges are stored in the floor node
                    var elevator_pos: Vector2 = get_elevator_position(target_floor_edges)
                    global_position = elevator_pos
                    sprite_data.current_position = global_position
                    sprite_data.current_floor_number = building_floor.floor_number
                    # Update target position to the stored target position
                    sprite_data.target_position = sprite_data.stored_target_position
                    break
        else:
            # Already on the target floor, no action needed
            sprite_data.target_position = sprite_data.stored_target_position


  
func _on_floor_clicked(floor_number: int, click_position: Vector2, bottom_edge_y: float, collision_edges: Dictionary) -> void:    

    # print("In player script: Floor number: ", floor_number, ", Global Position: ", click_position, ", Bottom Edge Y: ", bottom_edge_y)

    # Get the adjusted click position using collision_edges
    var adjusted_click_position: Vector2 = adjust_click_position(collision_edges, click_position, bottom_edge_y)

    if sprite_data.current_floor_number == floor_number:
        # Adjust the click position as usual
        sprite_data.target_position = adjusted_click_position
        sprite_data.target_floor_number = floor_number  # No floor switch needed
    else:
        # Store the target position and floor number for later
        sprite_data.target_floor_number = floor_number
        sprite_data.target_position = adjusted_click_position

        # Use the provided collision edges to compute the elevator position
        sprite_data.stored_target_position = get_elevator_position(collision_edges)
