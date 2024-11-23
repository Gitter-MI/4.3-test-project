# floor.gd
extends Area2D

# Exported variables for the floor number and image path
@export var floor_number: int = 0
@export var floor_image_path: String

# Reference to the FloorSprite node
var floor_sprite: Sprite2D

func _ready():
	# Get the FloorSprite node
	floor_sprite = $FloorSprite
	# Set the floor image
	set_floor_image(floor_image_path)

func set_floor_image(image_path: String):
	print("Attempting to load image from path: " + image_path)	# Debug print
	if image_path.is_empty():
		push_warning("Image path is empty!")
		return
		
	var texture = load(image_path)
	if texture:
		floor_sprite.texture = texture
		print("Successfully loaded texture for floor " + str(floor_number))
	else:
		push_error("Failed to load floor image at path: " + image_path)
		# Try to verify if the file exists
		var file = FileAccess.open(image_path, FileAccess.READ)
		if file:
			print("File exists but couldn't be loaded as texture")
		else:
			print("File does not exist at path: " + image_path)
