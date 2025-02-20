extends NinePatchRect

@onready var tooltip_label: Label = $TooltipLabel
var tooltip_timer: Timer
var mouse_inside: bool = false

func _ready():
    visible = false  # Ensure the tooltip is hidden initially
    z_index = 10
    
    # Create a timer for delayed tooltip
    tooltip_timer = Timer.new()
    tooltip_timer.one_shot = true
    tooltip_timer.wait_time = 0.5  # 0.5 second delay
    tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
    add_child(tooltip_timer)

func set_text(new_text: String):
    tooltip_label.text = new_text if new_text else ""
    update_tooltip_size()

func show_tooltip():
    mouse_inside = true
    tooltip_timer.start()

func hide_tooltip():
    mouse_inside = false
    tooltip_timer.stop()
    visible = false

func _on_tooltip_timer_timeout():
    # Only show tooltip if mouse is still inside the area
    if mouse_inside:
        visible = true

func update_tooltip_size():
    var label_size = tooltip_label.get_minimum_size()
    
    # Define padding values
    var padding_left = 10
    var padding_right = 10
    var padding_top = 5
    var padding_bottom = 5
    
    # Calculate total size
    var total_width = label_size.x + padding_left + padding_right
    var total_height = label_size.y + padding_top + padding_bottom
    
    # Set size of the tooltip background
    set_size(Vector2(total_width, total_height))
    
    # Center the tooltip background just above the center of the door element
    position = Vector2(-total_width / 2, -total_height)
    
    # Position label within background
    tooltip_label.position = Vector2(padding_left, padding_top)
    
    # Set label size
    tooltip_label.set_size(label_size)
    
    # Set label alignment
    tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
