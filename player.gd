extends Node2D

var target_position: Vector2
var stored_target_position: Vector2 = Vector2.ZERO  # Changed from `null` to `Vector2.ZERO`
var has_stored_position: bool = false              # Added from the first script
var target_floor_number: int = -1
var current_floor_number: int = -1
var speed: float = 400.0

func _ready():
	set_initial_position()
	# Initialize the target position to the player's current position after setting global_position
	target_position = global_position

func set_initial_position():
	# Find floor 1 from the "floors" group
	var floors = get_tree().get_nodes_in_group("floors")
	for building_floor in floors:
		if building_floor.floor_number == 1:
			# Get collision bounds of floor 1
			var edges = get_collision_bounds(building_floor)
			var left_edge_x = edges.left
			var bottom_edge_y = edges.bottom

			# Get the player's sprite dimensions
			var sprite_width = $Sprite2D.texture.get_width() * $Sprite2D.scale.x
			var sprite_height = $Sprite2D.texture.get_height() * $Sprite2D.scale.y

			# Set the player's starting position
			global_position = Vector2(
				left_edge_x + sprite_width / 2,
				bottom_edge_y - sprite_height / 2
			)
			# Set the current floor number
			current_floor_number = building_floor.floor_number
			# Break the loop once floor 1 is found and position is set
			break

func get_collision_bounds(building_floor):
	# Get the floor's global position and transform
	var floor_transform = building_floor.global_transform

	# Get the collision shape of the floor
	var collision_shape = building_floor.get_node("CollisionShape2D")
	var rectangle_shape = collision_shape.shape as RectangleShape2D
	var collision_extents = rectangle_shape.extents

	# Calculate the collision area's edges using the floor's transform
	var center = floor_transform * collision_shape.position

	# Create a dictionary with all edges
	var edges = {
		"left": center.x - collision_extents.x,
		"right": center.x + collision_extents.x,
		"top": center.y - collision_extents.y,
		"bottom": center.y + collision_extents.y
	}

	return edges

func adjust_click_position(building_floor, click_position):
	# Get collision bounds of the floor
	var edges = get_collision_bounds(building_floor)

	# Get the player's sprite dimensions
	var sprite_width = $Sprite2D.texture.get_width() * $Sprite2D.scale.x
	var sprite_height = $Sprite2D.texture.get_height() * $Sprite2D.scale.y

	# Adjust x-position based on sprite width to keep the sprite within the collision area
	var adjusted_x = click_position.x
	if click_position.x < edges.left + sprite_width / 2:
		adjusted_x = edges.left + sprite_width / 2
	elif click_position.x > edges.right - sprite_width / 2:
		adjusted_x = edges.right - sprite_width / 2

	# The y-position is set to align the bottom of the sprite with the floor
	var adjusted_y = edges.bottom - sprite_height / 2

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

func get_elevator_position(building_floor):
	var edges = get_collision_bounds(building_floor)
	var center_x = (edges.left + edges.right) / 2

	# The y-position aligns the bottom of the sprite with the floor
	var sprite_height = $Sprite2D.texture.get_height() * $Sprite2D.scale.y
	var adjusted_y = edges.bottom - sprite_height / 2

	return Vector2(center_x, adjusted_y)

func _process(delta):
	# Update current floor number
	var current_floor = get_current_floor()
	if current_floor:
		current_floor_number = current_floor.floor_number
	else:
		current_floor_number = -1

	# Move the player towards the target position
	if global_position != target_position:
		# Calculate the direction vector to the target position
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)

		# Move the player if not at the target position
		if distance > 1:
			global_position += direction * speed * delta
		else:
			global_position = target_position  # Snap to the target position when close enough

			# Check if we have arrived at the elevator position
			if has_stored_position:  # Changed from `stored_target_position != null`
				# If at elevator position on current floor, simulate moving to target floor
				if current_floor and target_position == get_elevator_position(current_floor):
					# Move player to the elevator position on target floor
					var floors = get_tree().get_nodes_in_group("floors")
					for building_floor in floors:
						if building_floor.floor_number == target_floor_number:
							var elevator_pos = get_elevator_position(building_floor)
							global_position = elevator_pos
							# Update target position to stored target position
							target_position = stored_target_position
							has_stored_position = false  # Changed from setting `stored_target_position` to null
							break

func _input(event):
	# Detect mouse click events
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Create the physics query
		var query = PhysicsPointQueryParameters2D.new()
		query.position = event.position
		query.collision_mask = 1
		query.collide_with_areas = true  # Detect Area2D nodes
		query.collide_with_bodies = false  # We only want to detect areas

		# Get the physics state and perform the intersection test
		var space_state = get_world_2d().direct_space_state
		var results = space_state.intersect_point(query)

		# Check if we hit any floor areas
		if results.size() > 0:
			var building_floor = null
			for result in results:
				if result.collider.is_in_group("floors"):
					building_floor = result.collider
					break  # Found the clicked floor

			if building_floor:
				var clicked_floor_number = building_floor.floor_number
				var adjusted_click_position = adjust_click_position(building_floor, event.position)
				var current_floor = get_current_floor()

				if current_floor and current_floor.floor_number == clicked_floor_number:
					# Adjust the click position as usual
					target_position = adjusted_click_position
					has_stored_position = false  # Changed from setting `stored_target_position` to null
					target_floor_number = -1  # Reset target floor
				else:
					# Store the target position and floor number for later
					stored_target_position = adjusted_click_position
					has_stored_position = true  # Changed from checking `stored_target_position != null`
					target_floor_number = clicked_floor_number

					# Compute elevator position on current floor
					if current_floor:
						target_position = get_elevator_position(current_floor)
					else:
						print("Player is not on any floor.")
			else:
				print("Clicked outside of any floor area.")
		else:
			print("Clicked outside of any floor area.")
