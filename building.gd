# building.gd
extends Node2D

# Preload all floor scenes
const FLOOR_SCENES = [
	preload("res://floor_0.tscn"),
	preload("res://floor_1.tscn"),
	preload("res://floor_2.tscn"),
	preload("res://floor_3.tscn"),
]

const DOOR_DATA_RESOURCE = preload("res://DoorData.tres")

func _ready():
	var door_data = DOOR_DATA_RESOURCE
	for door_entry in door_data.doors:
		var index = door_entry["index"]
		var floor_number = door_entry["floor_number"]
		var door_slot = door_entry["door_slot"]
		var door_type = door_entry["door_type"]
		var room_owner = door_entry["owner"]
		var tooltip = door_entry["tooltip"]
		# Use these variables to instantiate and configure doors			
	generate_building()

func generate_building():
	var previous_floor_top_y_position = 0.0
	var is_first_floor = true

	for i in range(FLOOR_SCENES.size()):
		var floor_instance = instantiate_floor(FLOOR_SCENES[i])
		if floor_instance:
			previous_floor_top_y_position = position_floor(floor_instance, previous_floor_top_y_position, is_first_floor)
			configure_collision_shape(floor_instance)
			configure_marker(floor_instance)
			is_first_floor = false

			# Add doors to the floor
			add_doors_to_floor(floor_instance, i)
		else:
			push_warning("Failed to instantiate floor at index " + str(i))

func add_doors_to_floor(floor_instance, floor_index):
	var floor_number = floor_index
	# Filter doors for this floor
	var floor_doors = DOOR_DATA_RESOURCE.doors.filter(func(door):
		return door.floor_number == floor_number
	)
	
	for door_data in floor_doors:
		var door_slot = door_data.door_slot
		var door_position = get_door_slot_position(floor_instance, door_slot)
		if door_position != null:
			var door_instance = preload("res://Door.tscn").instantiate()
			door_instance.position = door_position
			floor_instance.add_child(door_instance)
			
			# Configure door based on door_data
			configure_door(door_instance, door_data)
		else:
			push_warning("Invalid door slot index " + str(door_slot) + " on floor " + str(floor_number))

func configure_door(door_instance, door_data):
	if not door_instance:
		push_warning("Invalid door instance!")
		return
	
	# Let the door handle its own configuration
	door_instance.configure(door_data)

func get_door_slot_position(floor_instance, slot_index):
	var marker = floor_instance.get_node("Marker2D")
	var collision_shape = floor_instance.get_node("CollisionShape2D")
	if not (marker and collision_shape):
		push_warning("Missing nodes for door position calculation")
		return null

	var collision_width = 0.0
	var collision_left_edge = 0.0
	var percentage = 0.0

	# Get collision shape dimensions
	var shape = collision_shape.shape
	if shape is RectangleShape2D:
		var rect_shape = shape as RectangleShape2D
		collision_width = rect_shape.extents.x * 2
		collision_left_edge = collision_shape.position.x - rect_shape.extents.x
	else:
		push_warning("Collision shape is not a RectangleShape2D")
		return null

	# Door slot percentages
	var slot_percentages = [0.15, 0.35, 0.65, 0.85]
	if slot_index >= 0 and slot_index < slot_percentages.size():
		percentage = slot_percentages[slot_index]
	else:
		push_warning("Invalid door slot index " + str(slot_index))
		return null

	# Calculate x-position
	var local_x = collision_left_edge + percentage * collision_width

	# Get door dimensions
	var door_dimensions = get_door_dimensions()
	
	# Calculate y-position to align bottom edge with marker
	var local_y = marker.position.y - (door_dimensions.height / 2)
	
	return Vector2(local_x, local_y)

# helper function to get door dimensions
func get_door_dimensions():
	var door_scene = preload("res://Door.tscn").instantiate()
	var door_sprite = door_scene.get_node("AnimatedSprite2D")
	var dimensions = {"width": 0.0, "height": 0.0}
	
	if door_sprite and door_sprite.sprite_frames:
		var animations = door_sprite.sprite_frames.get_animation_names()
		if animations.size() > 0:
			var first_frame = door_sprite.sprite_frames.get_frame_texture(animations[0], 0)
			if first_frame:
				dimensions.width = first_frame.get_width() * door_sprite.scale.x
				dimensions.height = first_frame.get_height() * door_sprite.scale.y
	
	# Clean up the temporary instance
	door_scene.queue_free()
	
	return dimensions

# helper function to calculate door height offset
func get_door_height_offset():
	# Get the door scene to check its dimensions
	var door_scene = preload("res://Door.tscn").instantiate()
	var door_sprite = door_scene.get_node("AnimatedSprite2D")
	var door_collision = door_scene.get_node("CollisionShape2D")
	
	var door_height = 0.0
	
	if door_sprite and door_sprite.sprite_frames:
		# Get the first animation in the SpriteFrames
		var animations = door_sprite.sprite_frames.get_animation_names()
		if animations.size() > 0:
			# Get the first frame of the first animation
			var first_frame = door_sprite.sprite_frames.get_frame_texture(animations[0], 0)
			if first_frame:
				door_height = first_frame.get_height() * door_sprite.scale.y
	
	# If we have a collision shape, use its height instead
	if door_collision and door_collision.shape is RectangleShape2D:
		door_height = (door_collision.shape as RectangleShape2D).extents.y * 2
	
	# Clean up the temporary instance
	door_scene.queue_free()
	
	# Return half the height since we want to move up from the center position
	return door_height / 2

# Function to instantiate the floor scene
func instantiate_floor(scene):
	var floor_instance = scene.instantiate()
	if not floor_instance:
		push_warning("Failed to instantiate scene: " + str(scene))
		return null
	add_child(floor_instance)
	return floor_instance

# Function to position the floor instance
func position_floor(floor_instance, previous_floor_top_y_position, is_first_floor):
	var floor_sprite = floor_instance.get_node("FloorSprite")
	if not floor_sprite:
		push_warning("Floor instance is missing FloorSprite node!")
		return

	var viewport_size = get_viewport().size
	# var floor_width = floor_sprite.texture.get_width() * floor_sprite.scale.x
	var floor_height = floor_sprite.texture.get_height() * floor_sprite.scale.y

	# Calculate x position to center horizontally
	var x_position = (viewport_size.x) / 2
	var y_position = 0.0

	if is_first_floor:
		# Center the floor vertically
		y_position = (viewport_size.y - floor_height) / 1.5
	else:
		# Stack the floor above the previous floor
		y_position = previous_floor_top_y_position - floor_height

	# Set the position
	floor_instance.position = Vector2(x_position, y_position)
	# Return the y position of the top of this floor for the next calculation
	return y_position

# Function to configure the CollisionShape2D node of the floor
func configure_collision_shape(floor_instance):
	var floor_sprite = floor_instance.get_node("FloorSprite")
	var collision_shape = floor_instance.get_node("CollisionShape2D")
	if not (floor_sprite and collision_shape):
		push_warning("Missing nodes for collision shape configuration")
		return

	var boundary = {
		"x1": 0.0695,  # Left boundary
		"x2": 0.929,   # Right boundary
		"y1": 0.0760,  # Top boundary
		"y2": 0.9941,  # Bottom boundary
	}

	var sprite_width = floor_sprite.texture.get_width() * floor_sprite.scale.x
	var sprite_height = floor_sprite.texture.get_height() * floor_sprite.scale.y
	var collision_width = (boundary.x2 - boundary.x1) * sprite_width
	var collision_height = (boundary.y2 - boundary.y1) * sprite_height
	var delta_x = ((boundary.x1 + boundary.x2) / 2 - 0.5) * sprite_width
	var delta_y = ((boundary.y1 + boundary.y2) / 2 - 0.5) * sprite_height

	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.extents = Vector2(collision_width / 2, collision_height / 2)
	collision_shape.shape = rectangle_shape
	collision_shape.position = Vector2(delta_x, delta_y)

# Function to configure the Marker2D node to align with the bottom of the floor sprite
func configure_marker(floor_instance):
	var floor_sprite = floor_instance.get_node("FloorSprite")
	var marker = floor_instance.get_node("Marker2D")
	if not (floor_sprite and marker):
		push_warning("Missing nodes for marker configuration")
		return

	# Calculate the bottom edge of the sprite
	var sprite_height = floor_sprite.texture.get_height() * floor_sprite.scale.y
	var sprite_bottom_y = sprite_height / 2  # Since the sprite's origin is at its center
	
	# Set the marker position to align with the sprite's bottom edge
	marker.position = Vector2(0, sprite_bottom_y)


# Function to get the height of the floor
func get_floor_height(floor_instance):
	var floor_sprite = floor_instance.get_node("FloorSprite")
	if floor_sprite:
		var floor_height = floor_sprite.texture.get_height() * floor_sprite.scale.y
		return floor_height
	else:
		push_warning("Floor instance is missing FloorSprite node!")
		return 0.0
