# TooltipManager.gd
extends Node

@onready var tooltip = $CanvasLayer/Tooltip_Control
var is_tooltip_visible = false

func _ready():
    tooltip.visible = false
    SignalBus.show_tooltip.connect(_on_show_tooltip)
    SignalBus.hide_tooltip.connect(_on_hide_tooltip)

func _process(delta):
    if is_tooltip_visible:
        tooltip.position = get_viewport().get_mouse_position() + Vector2(10, -10)

# Rest of the code remains the same

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
    
    # Don't set position here - let _process handle it
    
    tooltip.visible = true
    is_tooltip_visible = true

func _on_hide_tooltip():
    tooltip.visible = false
    is_tooltip_visible = false
