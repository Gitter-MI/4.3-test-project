# TooltipManager.gd (revised)
extends Node2D

@onready var tooltip = $Tooltip_Control

func _ready():
    tooltip.visible = false
    SignalBus.show_tooltip.connect(_on_show_tooltip)
    SignalBus.hide_tooltip.connect(_on_hide_tooltip)

func _on_show_tooltip(tooltip_position, text, image_path = "", tooltip_scale = 1.0):
    tooltip.set_text(text)
    
    if image_path and image_path != "":
        tooltip.set_image(image_path, tooltip_scale)
    else:
        tooltip.set_image("", 1.0)
    
    tooltip.global_position = tooltip_position
    tooltip.visible = true

func _on_hide_tooltip():
    tooltip.visible = false
