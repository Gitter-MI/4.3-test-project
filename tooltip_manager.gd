# TooltipManager.gd
extends Node

@onready var tooltip = $CanvasLayer/Tooltip_Doors

func _ready():
    SignalBus.show_tooltip.connect(_on_show_tooltip)
    SignalBus.hide_tooltip.connect(_on_hide_tooltip)

func _on_show_tooltip(tooltip_data):
    tooltip.show_tooltip_with_data(tooltip_data)

func _on_hide_tooltip():
    tooltip.hide_tooltip()
