# door.gd
extends Area2D

enum DoorState {
	CLOSED,
	OPEN
}

var current_state: DoorState = DoorState.CLOSED
var door_type: int

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tooltip_background = $TooltipBackground  # TooltipBackground node with tooltip.gd attached

func _ready():
	setup_door()
	# Connect signals
	connect("mouse_entered", self._on_mouse_entered)
	connect("mouse_exited", self._on_mouse_exited)

func _on_mouse_entered():
	tooltip_background.show_tooltip()

func _on_mouse_exited():
	tooltip_background.hide_tooltip()

func setup_door() -> void:
	if not animated_sprite or not collision_shape:
		push_warning("Door scene is missing required nodes!")
		return
	# Set initial state to closed
	set_door_state(DoorState.CLOSED)

func configure(door_data):
	door_type = door_data.door_type
	setup_door()
	update_collision_shape()
	# Set the tooltip text
	tooltip_background.set_text(door_data.tooltip)

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
