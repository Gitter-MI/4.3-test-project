# door_ownership.gd
extends Node2D

signal owner_changed(old_owner, new_owner)

@export var can_change_owner: bool = true
@export var default_logo_scale: Vector2 = Vector2(2.3, 2.3)
@onready var logo_sprite: Sprite2D = $Owner_Logo

var door_data: Dictionary

var owner_colors = {
    1: Color(0.732, 0.245, 0.262),  # Red
    2: Color(0.04, 0.484, 0.037),   # Green
    3: Color(0.219, 0.417, 0.889),  # Blue
    4: Color(0.227, 0.227, 0.227),  # Dark grey/Black
}

func _ready():
    logo_sprite.scale = default_logo_scale
    # pass
    
func initialize(p_door_data: Dictionary) -> void:
    door_data = p_door_data
    update_logo_visibility()
    update_logo_color()

func change_owner(new_owner: String) -> void:
    if not can_change_owner:
        push_warning("This door cannot change owners")
        return
        
    var old_owner = door_data["owner"]
    door_data["owner"] = new_owner    
    update_logo_visibility()
    update_logo_color()    
    emit_signal("owner_changed", old_owner, new_owner)

func update_logo_visibility() -> void:
    var owner_val = int(door_data.owner)
    logo_sprite.visible = owner_val in [1, 2, 3, 4]

func update_logo_color() -> void:
    var owner_val = int(door_data.owner)
    if owner_val in owner_colors:
        logo_sprite.modulate = owner_colors[owner_val]
    else:
        logo_sprite.modulate = Color(1, 1, 1)  # Default white
