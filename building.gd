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
const DOOR_SCENE = preload("res://Door.tscn")  # Preload the Door scene

func _ready():
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

			# After floor is ready, pass door data to floor to handle door instantiation
			var floor_number = i
			var floor_doors = DOOR_DATA_RESOURCE.doors.filter(func(door):
				return door.floor_number == floor_number
			)
			# Instantiate doors and add to floor
			for door_data in floor_doors:
				var door_instance = DOOR_SCENE.instantiate()
				floor_instance.add_child(door_instance)
				# Pass door_data and floor_instance to the door
				door_instance.setup(door_data, floor_instance)
		else:
			push_warning("Failed to instantiate floor at index " + str(i))

# The rest of the functions remain the same
# Removed door-related methods:
# - add_doors_to_floor()
# - configure_door()
# - get_door_slot_position()
# - get_door_dimensions()
# - get_door_height_offset()

func instantiate_floor(scene):
	var floor_instance = scene.instantiate()
	if not floor_instance:
		push_warning("Failed to instantiate scene: " + str(scene))
		return null
	add_child(floor_instance)
	return floor_instance

func position_floor(floor_instance, previous_floor_top_y_position, is_first_floor):
	var floor_sprite = floor_instance.get_node("FloorSprite")
	if not floor_sprite:
		push_warning("Floor instance is missing FloorSprite node!")
		return

	var viewport_size = get_viewport().size
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
