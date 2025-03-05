# TooltipManager.gd
extends Node2D

@onready var tooltip = $Tooltip_Control

var is_tooltip_visible = false

func _ready():
    tooltip.visible = false
    SignalBus.show_tooltip.connect(_on_show_tooltip)
    SignalBus.hide_tooltip.connect(_on_hide_tooltip)

func _process(_delta):
    if is_tooltip_visible:
        var mouse_pos = get_viewport().get_mouse_position()
        tooltip.global_position = mouse_pos + Vector2(0, -100)

# Update the function parameter to just receive door_data
func _on_show_tooltip(door_data):
    # Get tooltip text
    var tooltip_text = door_data.get("tooltip", "")
    if tooltip_text.find("{owner}") != -1:
        tooltip_text = tooltip_text.replace("{owner}", door_data.get("owner", ""))
    
    tooltip.set_text(tooltip_text)
    
    var image_path = ""
    if door_data.has("tooltip_image") and door_data["tooltip_image"] != "":
        image_path = "res://Building/Rooms/tooltip_images/" + door_data["tooltip_image"] + ".png"
    
    tooltip.set_image(image_path, 1.0)
    var viewport_mouse_pos = get_viewport().get_mouse_position()
    var global_mouse_pos = get_canvas_transform().affine_inverse() * viewport_mouse_pos
    tooltip.global_position = global_mouse_pos + Vector2(10, 10)
    
    tooltip.visible = true
    is_tooltip_visible = true

func _on_hide_tooltip():
    tooltip.visible = false
    is_tooltip_visible = false
