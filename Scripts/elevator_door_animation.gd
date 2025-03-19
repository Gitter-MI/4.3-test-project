extends AnimatedSprite2D

# This script handles the elevator door animations
@onready var elevator: Area2D = get_parent()

func _ready():
    animation_finished.connect(_on_doors_animation_finished)
    setup_doors_position()

func _on_doors_animation_finished():
    if not elevator:
        push_warning("Missing elevator reference when handling animation finished.")
        return
        
    var current_anim = animation
    
    if current_anim == "opening" and elevator.door_state == elevator.DoorState.OPENING:
        elevator.set_door_state(elevator.DoorState.OPEN)
    
    if current_anim == "closing" and elevator.door_state == elevator.DoorState.CLOSING:
        elevator.set_door_state(elevator.DoorState.CLOSED)

# Animation control functions
func play_animation(animation_name: String):
    visible = true
    play(animation_name)

func stop_animation():
    stop()

func hide_animation():
    visible = false

func setup_doors_position():
    if not elevator:
        push_warning("Missing elevator reference when setting up doors position.")
        return
    
    var door_texture = sprite_frames.get_frame_texture("closed", 0)
    var door_height = 0
    if door_texture:
        door_height = door_texture.get_height()
        
    var elevator_sprite = elevator.get_node("Frame")
    var elevator_height = 0
    if elevator_sprite and elevator_sprite.texture:
        elevator_height = elevator_sprite.texture.get_height()
        
    var door_y_offset = (elevator_height - door_height) / 2
    
    position = Vector2(0, door_y_offset) 
