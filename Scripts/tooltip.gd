extends NinePatchRect

@onready var tooltip_label: Label = $TooltipLabel
@onready var tooltip_image: TextureRect = $TooltipImage

var tooltip_timer: Timer
var mouse_inside: bool = false
const PADDING = Vector2(10, 5)  # (horizontal, vertical) padding
const SPACING = 5  # Space between image and text

func _ready():
    visible = false
    z_index = 10
    setup_timer()
    
func setup_timer():
    tooltip_timer = Timer.new()
    tooltip_timer.one_shot = true
    tooltip_timer.wait_time = 0.5
    tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
    add_child(tooltip_timer)

func set_text(new_text: String):
    tooltip_label.text = new_text if new_text else ""
    update_layout()

func set_image(image_path: String, scale_factor: float = 1.0):
    if image_path.is_empty():
        tooltip_image.texture = null
        tooltip_image.visible = false
    else:
        tooltip_image.texture = load(image_path)
        tooltip_image.visible = true
        tooltip_image.scale = Vector2(scale_factor, scale_factor)
    update_layout()

func get_image_size() -> Vector2:
    if not tooltip_image.visible or not tooltip_image.texture:
        return Vector2.ZERO
    return tooltip_image.texture.get_size() * tooltip_image.scale

func calculate_sizes():
    # Grab current image dimensions
    var image_size = get_image_size()

    # Grab label's minimum required size
    var label_size = tooltip_label.get_minimum_size()

    # Ensure label is at least the height of the image
    var forced_label_height = max(label_size.y, image_size.y)
    tooltip_label.custom_minimum_size = Vector2(label_size.x, forced_label_height)
    label_size = tooltip_label.custom_minimum_size

    # Compute total width so there's enough room for image and label
    # (but label will be centered, so we still account for image width + padding).
    var total_width = (PADDING.x * 2)
    if image_size.x > 0:
        total_width += image_size.x + SPACING
    # If the label is wider than just the leftover space, total width should expand
    total_width = max(total_width + label_size.x, label_size.x + (PADDING.x * 2))

    # Total height is the max of label or image height plus padding
    var total_height = (PADDING.y * 2) + max(image_size.y, label_size.y)

    return {
        "image_size": image_size,
        "label_size": label_size,
        "total_size": Vector2(total_width, total_height)
    }


func position_elements(sizes: Dictionary):
    var image_size = sizes.image_size
    var label_size = sizes.label_size
    var total_size = sizes.total_size

    # 1) Position the image on the LEFT, vertically centered
    tooltip_image.position = Vector2(
        PADDING.x,
        (total_size.y - image_size.y) * 0.5  # center vertically
    )

    # 2) Center the label horizontally and vertically inside the tooltip
    tooltip_label.position = Vector2(
        (total_size.x - label_size.x) * 0.5,  # center horizontally
        (total_size.y - label_size.y) * 0.5   # center vertically
    )
    tooltip_label.set_size(label_size)


func update_layout():
    var sizes = calculate_sizes()
    
    # Update background size
    set_size(sizes.total_size)
    
    # Position the tooltip
    position = Vector2(-sizes.total_size.x / 2, -sizes.total_size.y)
    
    # Position elements within the tooltip
    position_elements(sizes)

func show_tooltip():
    mouse_inside = true
    tooltip_timer.start()

func hide_tooltip():
    mouse_inside = false
    tooltip_timer.stop()
    visible = false

func _on_tooltip_timer_timeout():
    if mouse_inside:
        visible = true
