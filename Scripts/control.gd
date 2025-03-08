# Tooltip_Doors.gd
extends Control

@onready var tooltip_label: Label = $HBoxContainer/Label
@onready var tooltip_image: TextureRect = $HBoxContainer/TextureImage
@onready var background: NinePatchRect = $Background
@onready var container: HBoxContainer = $HBoxContainer

var tooltip_timer: Timer
var mouse_inside: bool = false
const DEFAULT_IMAGE_SIZE = Vector2(32, 32)

func _ready():
    visible = false
    z_index = 10
    
    tooltip_timer = Timer.new()
    tooltip_timer.one_shot = true
    tooltip_timer.wait_time = 0.5
    tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
    add_child(tooltip_timer)
    
    tooltip_label.add_theme_color_override("font_color", Color.BLACK)
    container.add_theme_constant_override("separation", 10)

func _process(_delta):
    if visible:
        position = get_viewport().get_mouse_position() + Vector2(10, -10)

func show_tooltip_with_data(data: Dictionary):
    # Process tooltip text
    tooltip_text = data.get("tooltip", "")
    if tooltip_text.find("{owner}") != -1:
        tooltip_text = tooltip_text.replace("{owner}", data.get("owner", ""))
    
    set_text(tooltip_text)
    
    # Process tooltip image
    var image_path = ""
    if data.has("tooltip_image") and data["tooltip_image"] != "":
        image_path = "res://Building/Rooms/tooltip_images/" + data["tooltip_image"] + ".png"
    
    set_image(image_path, 1.0)
    
    # Show the tooltip
    mouse_inside = true
    tooltip_timer.start()

func set_text(new_text: String):
    tooltip_label.text = new_text if new_text else ""
    update_tooltip_size()

func set_image(path: String, scaling: float = 1.0):
    if path.is_empty():
        tooltip_image.visible = false
    else:
        tooltip_image.visible = true
        tooltip_image.texture = load(path)
        tooltip_image.custom_minimum_size = DEFAULT_IMAGE_SIZE * scaling
    update_tooltip_size()

func hide_tooltip():
    mouse_inside = false
    tooltip_timer.stop()
    visible = false

func _on_tooltip_timer_timeout():
    if mouse_inside:
        visible = true

func update_tooltip_size():
    container.custom_minimum_size = Vector2.ZERO
    container.size = Vector2.ZERO
    
    var padding = Vector2(15, 10)
    var total_size = container.get_combined_minimum_size() + padding
    
    background.size = total_size
    position = Vector2(-total_size.x / 2, -total_size.y - 10)
    container.position = padding / 2
    container.size = total_size - padding
