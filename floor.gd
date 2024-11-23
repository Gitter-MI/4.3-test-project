# floor.gd
extends Area2D

# Exported variables for the floor number and image path
@export var floor_number: int = 0
@export var floor_image_path: String

# Reference to the FloorSprite node
var floor_sprite: Sprite2D

const DOOR_SCENE = preload("res://Door.tscn")  # Preload the Door scene

# Class-level constant for boundaries
const BOUNDARIES = {
	"x1": 0.0695,  # Left boundary
	"x2": 0.929,   # Right boundary
	"y1": 0.0760,  # Top boundary
	"y2": 0.9941   # Bottom boundary
}


func _ready():
	add_to_group("floors")
	# Get the FloorSprite node
	floor_sprite = $FloorSprite
	# Set the floor image
	set_floor_image(floor_image_path)
	# Configure collision shape
	configure_collision_shape()
	collision_layer = 1
	# Configure marker
	configure_marker()
	add_to_group("floors")

func set_floor_image(image_path: String):
	# print("Attempting to load image from path: " + image_path)  # Debug # print
	if image_path.is_empty():
		push_warning("Image path is empty!")
		return

	var texture = load(image_path)
	if texture:
		floor_sprite.texture = texture
		# print("Successfully loaded texture for floor " + str(floor_number))
	else:
		push_error("Failed to load floor image at path: " + image_path)
		# Try to verify if the file exists
		var file = FileAccess.open(image_path, FileAccess.READ)
		if file:
			print("File exists but couldn't be loaded as texture")
		else:
			print("File does not exist at path: " + image_path)

func configure_collision_shape():
	# Set the collision layer to 1 (first bit)
	collision_layer = 1
	var collision_shape = $CollisionShape2D
	if not (floor_sprite and collision_shape):
		push_warning("Missing nodes for collision shape configuration")
		return

	var sprite_width = floor_sprite.texture.get_width() * floor_sprite.scale.x
	var sprite_height = floor_sprite.texture.get_height() * floor_sprite.scale.y
	var collision_width = (BOUNDARIES.x2 - BOUNDARIES.x1) * sprite_width
	var collision_height = (BOUNDARIES.y2 - BOUNDARIES.y1) * sprite_height
	var delta_x = ((BOUNDARIES.x1 + BOUNDARIES.x2) / 2 - 0.5) * sprite_width
	var delta_y = ((BOUNDARIES.y1 + BOUNDARIES.y2) / 2 - 0.5) * sprite_height

	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.extents = Vector2(collision_width / 2, collision_height / 2)
	collision_shape.shape = rectangle_shape
	collision_shape.position = Vector2(delta_x, delta_y)

func configure_marker():
	var marker = $Marker2D
	if not (floor_sprite and marker):
		push_warning("Missing nodes for marker configuration")
		return

	# Calculate the bottom edge of the sprite
	var sprite_height = floor_sprite.texture.get_height() * floor_sprite.scale.y
	var sprite_bottom_y = sprite_height / 2  # Since the sprite's origin is at its center

	# Set the marker position to align with the sprite's bottom edge
	marker.position = Vector2(0, sprite_bottom_y)

func position_floor(previous_floor_top_y_position, is_first_floor):
	if not floor_sprite:
		push_warning("Floor instance is missing FloorSprite node!")
		return previous_floor_top_y_position  # Return previous value to avoid errors

	var viewport_size = get_viewport().size
	var floor_height = floor_sprite.texture.get_height() * floor_sprite.scale.y

	# Calculate x position to center horizontally
	var x_position = viewport_size.x / 2
	var y_position = 0.0

	if is_first_floor:
		# Center the first floor vertically
		y_position = (viewport_size.y - floor_height) / 1.5
	else:
		# Stack the floor above the previous floor
		y_position = previous_floor_top_y_position - floor_height

	# Set the position
	position = Vector2(x_position, y_position)
	# Return the y position of the top of this floor for the next calculation
	return y_position

func setup_doors(door_data_array):
	for door_data in door_data_array:
		var door_instance = DOOR_SCENE.instantiate()
		add_child(door_instance)
		# Pass door_data and self to the door
		door_instance.setup(door_data, self)
