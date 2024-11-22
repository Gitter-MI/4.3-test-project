# tooltip.gd
extends NinePatchRect

@onready var tooltip_label: Label = $TooltipLabel

func _ready():
	visible = false  # Ensure the tooltip is hidden initially

func set_text(new_text: String):
	tooltip_label.text = new_text if new_text else ""
	_update_tooltip_size()

func show_tooltip():
	visible = true

func hide_tooltip():
	visible = false

func _update_tooltip_size():
	var label_size = tooltip_label.get_minimum_size()
	# Define padding values
	var padding_left = 10
	var padding_right = 10
	var padding_top = 5
	var padding_bottom = 5
	# Calculate total size
	var total_width = label_size.x + padding_left + padding_right
	var total_height = label_size.y + padding_top + padding_bottom
	set_size(Vector2(total_width, total_height))
	# Center the tooltip background above the door
	position = Vector2(-total_width / 2, -total_height)
	# Position label within background
	tooltip_label.position = Vector2(padding_left, padding_top)
	# Set label size
	tooltip_label.set_size(label_size)
	# Set label alignment
	tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
