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


    '''bold font looks blurry'''    
    ## Set text bold using theme override
    #tooltip_label.add_theme_font_size_override("font_size", 16)
    #tooltip_label.add_theme_color_override("font_color", Color.BLACK)
    #
    ## Create a FontVariation for bold text
    #var font = FontVariation.new()
    #font.set_variation_embolden(1.0)  # Make it bold
    #tooltip_label.add_theme_font_override("font", font)
    #
    #container.add_theme_constant_override("separation", 10)
    
func _process(_delta):
    if visible:
        # Update position to follow mouse cursor
        var mouse_pos = get_viewport().get_mouse_position()
        # Offset slightly to not cover what the mouse is pointing at
        global_position = Vector2(mouse_pos.x + 15, mouse_pos.y - size.y - 5)

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

func update_tooltip_size():
    container.custom_minimum_size = Vector2.ZERO
    container.size = Vector2.ZERO
    
    var padding = Vector2(15, 10)
    var total_size = container.get_combined_minimum_size() + padding
    
    background.size = total_size
    # position = Vector2(-total_size.x / 2, -total_size.y - 10)
    container.position = padding / 2
    container.size = total_size  - padding
