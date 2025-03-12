# DoorState.gd
extends Node

enum DoorState { CLOSED, OPEN }

var current_state: DoorState = DoorState.CLOSED
var door_type: int

@onready var animated_sprite: AnimatedSprite2D = $"../AnimatedSprite2D" if has_node("../AnimatedSprite2D") else $"../Door_Animation_2D"
@onready var ownership_manager = $"../Door_Ownership" if has_node("../Door_Ownership") else null

const SLOT_PERCENTAGES = [0.15, 0.35, 0.65, 0.85]


func initialize(p_door_data):
    if p_door_data == null or not p_door_data.has("door_type"):
        push_warning("Invalid door_data in DoorState.initialize()")
        return
    
    door_type = p_door_data.door_type
    set_door_state(DoorState.CLOSED)
    
    if ownership_manager:
        ownership_manager.initialize(p_door_data)


func set_door_state(new_state: DoorState) -> void:
    current_state = new_state
    var animation_name = "door_open" if current_state == DoorState.OPEN else "door_type_%d" % door_type
    
    if animated_sprite and animated_sprite.sprite_frames:
        if animation_name in animated_sprite.sprite_frames.get_animation_names():
            animated_sprite.play(animation_name)
            animated_sprite.stop()
        else:
            push_warning("Animation %s not found!" % animation_name)



func get_door_dimensions() -> Dictionary:
    if animated_sprite and animated_sprite.sprite_frames:
        var animation_name = "door_type_%d" % door_type
        if animation_name in animated_sprite.sprite_frames.get_animation_names():
            var first_frame = animated_sprite.sprite_frames.get_frame_texture(animation_name, 0)
            if first_frame:
                var width = first_frame.get_width() * animated_sprite.scale.x
                var height = first_frame.get_height() * animated_sprite.scale.y
                return { "width": width, "height": height }
    return { "width": 0.0, "height": 0.0 }

# Method to provide slot percentages to parent
func get_slot_percentages() -> Array:
    return SLOT_PERCENTAGES

func change_owner(new_owner: String) -> void:
    if ownership_manager:
        ownership_manager.change_owner(new_owner)
        # Update door_data in parent
        var parent = get_parent()
        if parent.has_method("get") and parent.get("door_data") != null:
            parent.door_data["owner"] = new_owner
    else:
        push_warning("This door does not have an ownership manager")
