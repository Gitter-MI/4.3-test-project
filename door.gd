# door.gd
extends Area2D

enum DoorState {
	CLOSED,
	OPEN
}

var current_state: DoorState = DoorState.CLOSED
var door_type: int
var tooltip_background
var tooltip_label



@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	setup_door()
	tooltip_background = $TooltipBackground
	tooltip_label = $TooltipBackground/TooltipLabel
	tooltip_background.visible = false  # Ensure the tooltip is hidden initially
	# Connect signals
	connect("mouse_entered", self._on_mouse_entered)
	connect("mouse_exited", self._on_mouse_exited)
	# Initially update the tooltip size
	_update_tooltip_size()

	
func _on_mouse_entered():
	tooltip_background.visible = true

func _on_mouse_exited():
	tooltip_background.visible = false



func setup_door() -> void:
	if not animated_sprite or not collision_shape:
		push_warning("Door scene is missing required nodes!")
		return
	
	# Set initial state to closed, showing appropriate door type
	set_door_state(DoorState.CLOSED)

func configure(door_data):
	door_type = door_data.door_type
	setup_door()
	update_collision_shape()
	# Set the tooltip text
	tooltip_label.text = door_data.tooltip if door_data.tooltip else ""
	# Defer the size update to ensure the label processes the new text
	call_deferred("_update_tooltip_size")


func _update_tooltip_size():
	var label_size = tooltip_label.get_minimum_size()
	# Define individual padding values
	var padding_left = 10
	var padding_right = 10
	var padding_top = 5
	var padding_bottom = 5
	# Calculate total size
	var total_width = label_size.x + padding_left + padding_right
	var total_height = label_size.y + padding_top + padding_bottom
	tooltip_background.set_size(Vector2(total_width, total_height))
	# Center the tooltip background above the door
	tooltip_background.position = Vector2(-total_width / 2, -total_height)
	# Position label within background
	tooltip_label.position = Vector2(padding_left, padding_top)
	# Set label size
	tooltip_label.set_size(label_size)
	# Set label alignment using the correct constants
	tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER



func _on_TooltipLabel_minimum_size_changed():
	var label_size = tooltip_label.get_size()
	var padding = Vector2(20, 10)  # Adjust according to your padding
	tooltip_background.set_size(label_size + padding)


func set_door_state(new_state: DoorState) -> void:
	current_state = new_state
	
	match current_state:
		DoorState.CLOSED:
			var animation_name = "door_type_" + str(door_type)
			if animation_name in animated_sprite.sprite_frames.get_animation_names():
				animated_sprite.play(animation_name)
				animated_sprite.stop() # Stop at first frame
			else:
				push_warning("Animation " + animation_name + " not found!")
		
		DoorState.OPEN:
			if "door_open" in animated_sprite.sprite_frames.get_animation_names():
				animated_sprite.play("door_open")
				animated_sprite.stop() # Stop at first frame
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
