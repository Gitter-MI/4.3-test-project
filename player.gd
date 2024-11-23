# player.gd
extends Node2D

var target_position: Vector2
var speed: float = 400.0  # Adjust the speed as needed

func _ready():
	set_initial_position()
	# Initialize the target position to the player's current position after setting global_position
	target_position = global_position

func set_initial_position():
	# Find floor 0 from the "floors" group
	var floors = get_tree().get_nodes_in_group("floors")
	for building_floor in floors:
		if building_floor.floor_number == 0:
			# Get collision bounds of floor 0
			var edges = get_collision_bounds(building_floor)
			var left_edge_x = edges.left
			var _right_edge_x = edges.right
			var _top_edge_y = edges.top
			var bottom_edge_y = edges.bottom
			
			# Get the player's sprite dimensions
			var sprite_width = $Sprite2D.texture.get_width() * $Sprite2D.scale.x
			var sprite_height = $Sprite2D.texture.get_height() * $Sprite2D.scale.y

			# Set the player's starting position
			global_position = Vector2(
				left_edge_x + sprite_width / 2,  # Align left edge of sprite with left edge of collision area
				bottom_edge_y - sprite_height / 2   # Place bottom of sprite at top edge of collision area
			)
			# Break the loop once floor 0 is found and position is set
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

	# The y-position is set to align the bottom of the sprite with the top edge of the collision area
	var adjusted_y = edges.bottom - sprite_height / 2

	return Vector2(adjusted_x, adjusted_y)

func _process(delta):
	# Only move the player if the target position is different from the current position
	if global_position != target_position:
		# Calculate the direction vector to the target position
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)

		# Move the player if not at the target position
		if distance > 1:
			global_position += direction * speed * delta
		else:
			global_position = target_position  # Snap to the target position when close enough

func _input(event):
	# Detect mouse click events
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Create the physics query
		var query = PhysicsPointQueryParameters2D.new()
		query.position = event.position
		query.collision_mask = 1
		query.collide_with_areas = true  # Important! Detect Area2D nodes
		query.collide_with_bodies = false  # We only want to detect areas

		# Get the physics state and perform the intersection test
		var space_state = get_world_2d().direct_space_state
		var results = space_state.intersect_point(query)

		# Check if we hit any floor areas
		var floor_clicked = false
		if results.size() > 0:
			for result in results:
				if result.collider.is_in_group("floors"):
					floor_clicked = true
					var building_floor = result.collider
					# Adjust the click position
					target_position = adjust_click_position(building_floor, event.position)
					break
		if not floor_clicked:
			print("outside area")
