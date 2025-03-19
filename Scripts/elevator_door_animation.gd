extends Node

# This script handles the elevator door animations

# Reference to the elevator object owning this animation component
var elevator: Area2D

# Reference to the animated sprite that shows the door animations
var animated_sprite: AnimatedSprite2D

func _ready():
    if animated_sprite:
        animated_sprite.animation_finished.connect(_on_doors_animation_finished)
    else:
        push_warning("AnimatedSprite2D node not found in elevator_door_animation.")

# Initialize with references to the necessary nodes
func initialize(p_elevator: Area2D, p_animated_sprite: AnimatedSprite2D):
    elevator = p_elevator
    animated_sprite = p_animated_sprite
    
    if animated_sprite:
        animated_sprite.animation_finished.connect(_on_doors_animation_finished)
    else:
        push_warning("AnimatedSprite2D node not found in elevator_door_animation.")

# Animation finished callback
func _on_doors_animation_finished():
    if not animated_sprite or not elevator:
        push_warning("Missing references when handling animation finished.")
        return
        
    var current_anim = animated_sprite.animation
    
    if current_anim == "opening" and elevator.door_state == elevator.DoorState.OPENING:
        elevator.set_door_state(elevator.DoorState.OPEN)
    
    if current_anim == "closing" and elevator.door_state == elevator.DoorState.CLOSING:
        elevator.set_door_state(elevator.DoorState.CLOSED)

# Animation control functions
func play_animation(animation_name: String):
    if animated_sprite:
        animated_sprite.visible = true
        animated_sprite.play(animation_name)
    else:
        push_warning("AnimatedSprite2D node not found when playing animation: " + animation_name)

func stop_animation():
    if animated_sprite:
        animated_sprite.stop()
    else:
        push_warning("AnimatedSprite2D node not found when stopping animation.")

func hide_animation():
    if animated_sprite:
        animated_sprite.visible = false
    else:
        push_warning("AnimatedSprite2D node not found when hiding animation.")

func setup_doors_position():
    if not animated_sprite or not elevator:
        push_warning("Missing references when setting up doors position.")
        return
    
    var door_texture = animated_sprite.sprite_frames.get_frame_texture("closed", 0)
    var door_height = 0
    if door_texture:
        door_height = door_texture.get_height()
        
    var elevator_sprite = elevator.get_node("Frame")
    var elevator_height = 0
    if elevator_sprite and elevator_sprite.texture:
        elevator_height = elevator_sprite.texture.get_height()
        
    var door_y_offset = (elevator_height - door_height) / 2
    
    animated_sprite.position = Vector2(0, door_y_offset) 