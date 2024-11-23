# door.gd
extends Area2D

enum DoorState {
	CLOSED,
	OPEN
}

var current_state: DoorState = DoorState.CLOSED
var door_type: int
var door_data
var floor_instance

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tooltip_background = $TooltipBackground  # TooltipBackground node with tooltip.gd attached

func _ready():
	# Signals are connected in setup()
	pass

func setup(p_door_data, p_floor_instance):
	door_data = p_door_data
	floor_instance = p_floor_instance
	door_type = door_data.door_type
	setup_door()
	position_door()
	update_collision_shape()
	# Set the tooltip text
	tooltip_background.set_text(door_data.tooltip)
	# Connect signals
	connect("mouse_entered", self._on_mouse_entered)
	connect("mouse_exited", self._on_mouse_exited)

func setup_door():
	if not animated_sprite or not collision_shape:
		push_warning("Door scene is missing required nodes!")
		return
	# Set initial state to closed
	set_door_state(DoorState.CLOSED)

func position_door():
	var slot_index = door_data.door_slot
	var door_position = get_door_slot_position(slot_index)
	if door_position != null:
		self.position = door_position
	else:
		push_warning("Invalid door slot index " + str(slot_index))

func get_door_slot_position(slot_index):
	var marker = floor_instance.get_node("Marker2D")
	var floor_collision_shape = floor_instance.get_node("CollisionShape2D")
	if not (marker and floor_collision_shape):
		push_warning("Missing nodes for door position calculation")
		return null

	var collision_width = 0.0
	var collision_left_edge = 0.0
	var percentage = 0.0

	# Get collision shape dimensions
	var shape = floor_collision_shape.shape
	if shape is RectangleShape2D:
		var rect_shape = shape as RectangleShape2D
		collision_width = rect_shape.extents.x * 2
		collision_left_edge = floor_collision_shape.position.x - rect_shape.extents.x
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

func get_door_dimensions():
	var dimensions = {"width": 0.0, "height": 0.0}
	if animated_sprite and animated_sprite.sprite_frames:
		var animations = animated_sprite.sprite_frames.get_animation_names()
		if animations.size() > 0:
			var first_frame = animated_sprite.sprite_frames.get_frame_texture(animations[0], 0)
			if first_frame:
				dimensions.width = first_frame.get_width() * animated_sprite.scale.x
				dimensions.height = first_frame.get_height() * animated_sprite.scale.y
	return dimensions

func _on_mouse_entered():
	tooltip_background.show_tooltip()

func _on_mouse_exited():
	tooltip_background.hide_tooltip()

func set_door_state(new_state: DoorState) -> void:
	current_state = new_state
	match current_state:
		DoorState.CLOSED:
			var animation_name = "door_type_" + str(door_type)
			if animation_name in animated_sprite.sprite_frames.get_animation_names():
				animated_sprite.play(animation_name)
				animated_sprite.stop()  # Stop at first frame
			else:
				push_warning("Animation " + animation_name + " not found!")
		DoorState.OPEN:
			if "door_open" in animated_sprite.sprite_frames.get_animation_names():
				animated_sprite.play("door_open")
				animated_sprite.stop()  # Stop at first frame
			else:
				push_warning("Door open animation not found!")

func update_collision_shape() -> void:
	var animation_name = "door_type_" + str(door_type)
	if animation_name in animated_sprite.sprite_frames.get_animation_names():
		var sprite_frames = animated_sprite.sprite_frames
		var first_frame = sprite_frames.get_frame_texture(animation_name, 0)
		if first_frame:
			var width = first_frame.get_width() * animated_sprite.scale.x
			var height = first_frame.get_height() * animated_sprite.scale.y
			var rectangle_shape = RectangleShape2D.new()
			rectangle_shape.extents = Vector2(width / 2, height / 2)
			collision_shape.shape = rectangle_shape
