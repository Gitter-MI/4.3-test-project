# player.gd
extends Node2D

const SCALE_FACTOR = 2.3

var sprite_data: PlayerSpriteData
var last_elevator_request: Dictionary = {"sprite_name": "", "floor_number": -1}
var previous_elevator_position: Vector2 = Vector2.ZERO

const PlayerSpriteData = preload("res://SpriteData.gd")

enum DoorState { CLOSED, OPENING, OPEN, CLOSING }


func _ready():
    add_to_group("player_sprites")   
    sprite_data = PlayerSpriteData.new()   

    apply_scale_factor_to_sprite()       # 1) scale
    update_sprite_dimensions()           # 2) measure scaled sprite
    set_initial_position()               # 3) position on the floor

    SignalBus.elevator_arrived.connect(_on_elevator_arrived)   
    SignalBus.elevator_position_updated.connect(_on_elevator_ride)
    SignalBus.door_state_changed.connect(_on_elevator_door_state_changed)
    SignalBus.floor_clicked.connect(_on_floor_clicked)
    SignalBus.door_clicked.connect(_on_door_clicked)

    
    $AnimatedSprite2D.animation_finished.connect(_on_sprite_entered_elevator)


func _process(delta: float) -> void:
    if sprite_data.current_state != SpriteData.State.IN_ELEVATOR:
        movement_logic(delta)


#####################################################################################################
##################              Vertical Movement Component                   #######################
#####################################################################################################


func _on_elevator_arrived(sprite_name: String, _current_floor: int):
    if sprite_name == sprite_data.sprite_name \
    and sprite_data.current_position == sprite_data.current_elevator_position \
    and sprite_data.current_state == SpriteData.State.WAITING_FOR_ELEVATOR:
        # print("Elevator arrived. Checking door state...")
        var elevator = get_elevator_for_current_floor()        
        var current_door_state = elevator.get_door_state()
        if current_door_state == DoorState.OPEN:                                    
            entering_elevator()
            

func entering_elevator():    
    sprite_data.current_state = SpriteData.State.ENTERING_ELEVATOR    
    var elevator = get_elevator_for_current_floor()
    sprite_data.elevator_y_offset = global_position.y - elevator.global_position.y
    z_index = -9
    SignalBus.entering_elevator.emit(sprite_data.sprite_name, sprite_data.target_floor_number)
    $AnimatedSprite2D.play("enter")
    _update_animation(Vector2.ZERO)



func _on_sprite_entered_elevator():
    print("animation finished")
    var current_anim = $AnimatedSprite2D.animation

    # Example: If the current animation is "enter" and we are in ENTERING_ELEVATOR
    if current_anim == "enter" and sprite_data.current_state == SpriteData.State.ENTERING_ELEVATOR:
        # Transition to the new state
        sprite_data.current_state = SpriteData.State.IN_ELEVATOR
        print("Enter animation finished. Sprite is now IN_ELEVATOR.")

        # Now emit the global signal. The listener(s) can respond if needed.
        SignalBus.enter_animation_finished.emit(sprite_data.sprite_name)

        # Optionally, force an animation update if you want to switch to "idle" now.
        _update_animation(Vector2.ZERO)



func _on_elevator_door_state_changed(new_state):
    # print("Door state changed:", new_state)
    if new_state == DoorState.OPEN:
        # If player was waiting at the elevator, now it's safe to enter
        if sprite_data.current_state == SpriteData.State.WAITING_FOR_ELEVATOR \
        and sprite_data.current_position == sprite_data.current_elevator_position:            
            _on_elevator_arrived(sprite_data.sprite_name, sprite_data.current_floor_number)
            

        
        elif sprite_data.current_state == SpriteData.State.IN_ELEVATOR:
            # Player can now exit the elevator
            sprite_data.current_state = SpriteData.State.EXITING_ELEVATOR
            # print(sprite_data.sprite_name, " is now EXITING_ELEVATOR")
            exiting_elevator()



func get_elevator_for_current_floor() -> Area2D:
    # helper function for _on_elevator_arrived
    var elevators = get_tree().get_nodes_in_group("elevators")
    for elevator in elevators:
        if elevator.floor_instance and elevator.floor_instance.floor_number == sprite_data.current_floor_number:
            return elevator
    return null



func exiting_elevator() -> void:
    # print("exiting_elevator")
    z_index = 0 
    sprite_data.current_floor_number = sprite_data.target_floor_number    
    sprite_data.current_state = SpriteData.State.IDLE
    SignalBus.exiting_elevator.emit(sprite_data.sprite_name)  
    # when not IN_ELEVATOR the movement_logic() will handle the next action
    # print(sprite_data.sprite_name, " is now IDLE after exiting elevator")


func _on_elevator_ride(elevator_pos: Vector2) -> void:
    # This is logically dependent on the move_elevator() in cabin.gd
    # Both sprites need to move in sync but they have a function each. 
    if sprite_data.current_state == SpriteData.State.IN_ELEVATOR:        
        global_position.x = elevator_pos.x
        global_position.y = elevator_pos.y + sprite_data.elevator_y_offset

        sprite_data.current_position = global_position


#####################################################################################################
##################              Horizontal Movement Component                 #######################
#####################################################################################################


func movement_logic(delta: float) -> void:
    if sprite_data.current_state == SpriteData.State.IN_ELEVATOR:
        push_warning("movement_logic aborted: Sprite is currently in the elevator.")
        return


    if sprite_data.current_position != sprite_data.target_position:
        if sprite_data.target_floor_number == sprite_data.current_floor_number:
            move_towards_position(sprite_data.target_position, delta)
        else:
            sprite_data.needs_elevator = true
            if sprite_data.current_position == sprite_data.current_elevator_position:
                var current_request = {
                    "sprite_name": sprite_data.sprite_name,
                    "floor_number": sprite_data.target_floor_number
                }

                if current_request != last_elevator_request:
                    SignalBus.elevator_request.emit(sprite_data.sprite_name, sprite_data.current_floor_number)
                    # print("signal emitted: elevator requested")
                    last_elevator_request = current_request
                    sprite_data.current_state = SpriteData.State.WAITING_FOR_ELEVATOR
                    # print(sprite_data.sprite_name, " is now WAITING_FOR_ELEVATOR. In movement logic")
            else:
                # Keep moving towards the elevator
                move_towards_position(sprite_data.current_elevator_position, delta)



func move_towards_position(target_position: Vector2, delta: float) -> void:
    var direction: Vector2 = (target_position - global_position).normalized()
    var distance: float = global_position.distance_to(target_position)

    if distance > 1:
        if sprite_data.current_state != SpriteData.State.WALKING:
            sprite_data.current_state = SpriteData.State.WALKING
            # print(sprite_data.sprite_name, " started WALKING")

        global_position += direction * sprite_data.speed * delta
    else:
        global_position = target_position
        sprite_data.current_position = global_position
        update_state_after_horizontal_movement()
    
    _update_animation(direction)



func update_state_after_horizontal_movement() -> void:
    if sprite_data.needs_elevator and sprite_data.current_position == sprite_data.current_elevator_position:
        if sprite_data.current_state != SpriteData.State.WAITING_FOR_ELEVATOR:
            sprite_data.current_state = SpriteData.State.WAITING_FOR_ELEVATOR
    elif sprite_data.target_room >= 0:
        if sprite_data.current_state != SpriteData.State.ENTERING_ROOM:
            sprite_data.current_state = SpriteData.State.ENTERING_ROOM
    else:
        if sprite_data.current_state != SpriteData.State.IDLE:
            sprite_data.current_state = SpriteData.State.IDLE
            last_elevator_request = {"sprite_name": "", "floor_number": -1}
            sprite_data.needs_elevator = false
    
    _update_animation(Vector2.ZERO)




#####################################################################################################
##################              Human Player Movement Component               #######################
#####################################################################################################


func adjust_click_position(collision_edges: Dictionary, click_position: Vector2, bottom_edge_y: float) -> Vector2:
    var sprite_width: float = sprite_data.sprite_width
    var sprite_height: float = sprite_data.sprite_height

    # sprite cannot move into the bounding walls to the left and right of the building
    var adjusted_x: float = click_position.x
    var left_bound: float = collision_edges["left"]
    var right_bound: float = collision_edges["right"]    
    if click_position.x < left_bound + sprite_width / 2:
        adjusted_x = left_bound + sprite_width / 2
    elif click_position.x > right_bound - sprite_width / 2:
        adjusted_x = right_bound - sprite_width / 2
    
    # sprite can only move on the ground
    var adjusted_y: float = bottom_edge_y - sprite_height / 2

    return Vector2(adjusted_x, adjusted_y)


func _on_floor_clicked(floor_number: int, click_position: Vector2, bottom_edge_y: float, collision_edges: Dictionary) -> void:

    var adjusted_click_position: Vector2 = adjust_click_position(collision_edges, click_position, bottom_edge_y)
    var door_index = -1
    set_target_data(floor_number, adjusted_click_position, door_index)


func _on_door_clicked(door_center_x: int, floor_number: int, door_index: int, collision_edges: Dictionary, _click_position: Vector2) -> void:
    var bottom_edge_y = collision_edges["bottom"]
    var door_click_position: Vector2 = Vector2(door_center_x, bottom_edge_y)
    var adjusted_click_position: Vector2 = adjust_click_position(collision_edges, door_click_position, bottom_edge_y)

    set_target_data(floor_number, adjusted_click_position, door_index)


func set_target_data(floor_number: int, adjusted_click_position: Vector2, target_room: int) -> void:
    # If already on the same floor, no elevator needed:
    if sprite_data.current_floor_number == floor_number:
        sprite_data.target_position = adjusted_click_position
        sprite_data.target_room = target_room
    else:
        # Change floors, so update elevator position & floor number
        sprite_data.target_floor_number = floor_number
        sprite_data.target_position = adjusted_click_position
        sprite_data.target_room = target_room
        sprite_data.current_elevator_position = get_elevator_position()



#####################################################################################################
##################              Basic Sprite Component                        #######################  
#####################################################################################################

func update_sprite_dimensions():
    var idle_texture = $AnimatedSprite2D.sprite_frames.get_frame_texture("idle", 0)
    if idle_texture:
        sprite_data.sprite_width = (idle_texture.get_width() * $AnimatedSprite2D.scale.x)
        sprite_data.sprite_height = (idle_texture.get_height() * $AnimatedSprite2D.scale.y)
    else:
        print("Warning: 'idle' animation (frame 0) not found.")



func apply_scale_factor_to_sprite():
    var sprite = $AnimatedSprite2D
    if sprite:
        sprite.scale *= SCALE_FACTOR  # Notice *= instead of = 
        # print("Applied scale factor to player sprite.")
    else:
        push_warning("AnimatedSprite2D node not found for scaling.")










func _update_animation(direction: Vector2) -> void:
    match sprite_data.current_state:
        SpriteData.State.WALKING:
            # Decide left vs right based on direction.x
            if direction.x > 0:
                $AnimatedSprite2D.play("walk_to_right")
            else:
                $AnimatedSprite2D.play("walk_to_left")

        SpriteData.State.IDLE:
            $AnimatedSprite2D.play("idle")

        SpriteData.State.WAITING_FOR_ELEVATOR:
            # Here’s where we play the "enter" animation
            $AnimatedSprite2D.play("enter")
            
        SpriteData.State.ENTERING_ELEVATOR:            
            # Here’s where we play the "enter" animation
            $AnimatedSprite2D.play("enter")

        # Optionally handle other states:
        SpriteData.State.IN_ELEVATOR:
            # Could be idle or do nothing
            $AnimatedSprite2D.play("idle")

        SpriteData.State.EXITING_ELEVATOR:
            $AnimatedSprite2D.play("idle")

        SpriteData.State.ENTERING_ROOM:
            $AnimatedSprite2D.play("idle")



func set_initial_position() -> void:
    var target_floor = get_floor_by_number(1)
    var edges: Dictionary = target_floor.get_collision_edges()

    # For demonstration, let's place the player at the center of the floor
    var center_x = (edges.left + edges.right) / 2.0

    # If your sprite pivot is center, do exactly like the elevator:
    var bottom_edge_y = edges.bottom
    var sprite_height = sprite_data.sprite_height
    var y_position = bottom_edge_y - (sprite_height /2.0 )

    # If the sprite’s feet are *still* inside the floor, add a tiny offset:
    # e.g. y_position -= 2.0
    # or if the pivot is top-left, do y_position = bottom_edge_y - sprite_height

    global_position = Vector2(center_x, y_position)

    sprite_data.current_position = global_position
    sprite_data.target_position = global_position
    sprite_data.current_floor_number = target_floor.floor_number
    sprite_data.target_floor_number = target_floor.floor_number
    sprite_data.current_elevator_position = get_elevator_position()




func get_elevator_position() -> Vector2:   
    
    var current_floor = get_floor_by_number(sprite_data.current_floor_number)
    var current_edges = current_floor.get_collision_edges()
    
    var center_x: float = (current_edges["left"] + current_edges["right"]) / 2
    var sprite_height: float = sprite_data.sprite_height
    var adjusted_y: float = current_edges["bottom"] - (sprite_height / 2.0)

    return Vector2(center_x, adjusted_y)


func get_floor_by_number(floor_number: int) -> Node2D:
    
    var floors = get_tree().get_nodes_in_group("floors")
    for building_floor in floors:
        if building_floor.floor_number == floor_number:
            return building_floor
    return null



#endregion
