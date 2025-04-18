# sprite_animation.gd
extends AnimatedSprite2D

var sprite_data_new

func _ready():
    animation_finished.connect(_on_animation_finished)

func animate(sprite_data):
    sprite_data_new = sprite_data
    var direction = (sprite_data_new.target_position - sprite_data_new.current_position).normalized()
    var main_state = sprite_data_new.get_active_state()
    
    match main_state:
        sprite_data_new.ActiveState.MOVEMENT:
            match sprite_data_new.movement_state:
                sprite_data_new.MovementState.WALKING:
                    if direction.x > 0:
                        play("walk_to_right")
                    else:
                        play("walk_to_left")
                sprite_data_new.MovementState.IDLE:
                    play("idle")
                _:                    
                    push_warning("in animate: Sprite is in no recognized state in animate! - MovementState")
                    play("idle")
        
        sprite_data_new.ActiveState.ROOM:
            match sprite_data_new.room_state:
                sprite_data_new.RoomState.ENTERING_ROOM:
                    play("enter")
                sprite_data_new.RoomState.EXITING_ROOM:
                    play("exit")
                sprite_data_new.RoomState.IN_ROOM:
                    play("idle")                
                _:
                    push_warning("in animate: Sprite is in no recognized state in animate! - RoomState")
                    play("idle")
        
        sprite_data_new.ActiveState.ELEVATOR:
            match sprite_data_new.elevator_state:
                sprite_data_new.ElevatorState.CALLING_ELEVATOR:
                    play("enter")
                sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
                    play("enter")
                sprite_data_new.ElevatorState.ENTERING_ELEVATOR:
                    play("enter")
                sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM:
                    play("idle")
                sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT:
                    play("idle")
                sprite_data_new.ElevatorState.EXITING_ELEVATOR:
                    play("exit")                    
                _:
                    push_warning("in animate: Sprite is in no recognized state in animate! - ElevatorState")
                    play("idle")

        _:
            push_warning("in animate: Sprite is in no recognized state in animate!")
            play("idle")

func _on_animation_finished():
    var anim_name = animation
    
    match anim_name:
        "enter":
            if sprite_data_new.elevator_ready:
                get_parent().on_sprite_entered_elevator()

        "exit":
            if sprite_data_new.elevator_destination_reached:
                get_parent().on_sprite_exited_elevator() 
