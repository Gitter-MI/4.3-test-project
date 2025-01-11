# player.gd


# needs to re-implement the timer once again
# needs heavy re-factoring


extends Area2D

const SCALE_FACTOR = 2.3

var sprite_data: PlayerSpriteData
var last_elevator_request: Dictionary = {"sprite_name": "", "floor_number": -1}
var previous_elevator_position: Vector2 = Vector2.ZERO

const PlayerSpriteData = preload("res://SpriteData.gd")

const Elevator = preload("res://elevator.gd")

func _ready():
    add_to_group("player_sprites")   
    sprite_data = PlayerSpriteData.new()   

    apply_scale_factor_to_sprite()
    update_sprite_dimensions()
    set_initial_position()

    SignalBus.elevator_arrived.connect(_on_elevator_arrived)   
    SignalBus.elevator_position_updated.connect(_on_elevator_ride)
    SignalBus.door_state_changed.connect(_on_elevator_door_state_changed)
    # SignalBus.floor_clicked.connect(_on_floor_clicked)
    # SignalBus.door_clicked.connect(_on_door_clicked)
    
    $AnimatedSprite2D.animation_finished.connect(_on_sprite_entered_elevator)
    SignalBus.floor_area_entered.connect(_on_floor_area_entered)
    
    # SignalBus.adjusted_navigation_click.connect(_on_adjusted_navigation_click)


func _on_floor_area_entered(area: Area2D, floor_number: int) -> void:            
    if area == $".": # If the area that triggered the signal is our own area
        # print("I, %s, have entered floor #%d" % [name, floor_number])
        sprite_data.current_floor_number = floor_number
        

func _process(delta: float) -> void:
    if sprite_data.current_state != SpriteData.State.IN_ELEVATOR:
        movement_logic(delta)

    # move actions from movement logic here?
    # if not moving because sprite is at target then do action
  




# helper function needed when target is on another floor
func get_elevator_position_for(floor_number: int) -> Vector2:
    var target_floor = get_floor_by_number(floor_number)
    if target_floor:
        var edges = target_floor.get_collision_edges()
        var center_x = (edges["left"] + edges["right"]) / 2
        var sprite_height = sprite_data.sprite_height
        var adjusted_y = edges["bottom"] - sprite_height / 2.0
        return Vector2(center_x, adjusted_y)
    return Vector2.ZERO


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
        if current_door_state == Elevator.DoorState.OPEN:                                  
            entering_elevator()
            

func entering_elevator():
    var old_state = sprite_data.current_state
    sprite_data.current_state = SpriteData.State.ENTERING_ELEVATOR
    if old_state != sprite_data.current_state:
        # print("Sprite state changed from %s to %s" % [old_state, sprite_data.current_state])
        pass

    var elevator = get_elevator_for_current_floor()
    sprite_data.elevator_y_offset = global_position.y - elevator.global_position.y
    z_index = -9
    SignalBus.entering_elevator.emit()
    _update_animation(Vector2.ZERO)




func _on_sprite_entered_elevator():
    var current_anim = $AnimatedSprite2D.animation
    
    if current_anim == "enter" and sprite_data.current_state == SpriteData.State.ENTERING_ELEVATOR:
        var old_state = sprite_data.current_state
        sprite_data.current_state = SpriteData.State.IN_ELEVATOR
        if old_state != sprite_data.current_state:
            # print("Sprite state changed from %s to %s" % [old_state, sprite_data.current_state])
            pass

        SignalBus.enter_animation_finished.emit(sprite_data.sprite_name, sprite_data.target_floor_number)
        _update_animation(Vector2.ZERO)



func exiting_elevator() -> void:    
    # We are exiting the elevator:
    # 1) Update floor and state
    z_index = 0
    
    sprite_data.current_floor_number = sprite_data.target_floor_number
    var old_state = sprite_data.current_state
    # sprite_data.current_state = SpriteData.State.IDLE
    if old_state != sprite_data.current_state:
        # print("Sprite state changed from %s to %s" % [old_state, sprite_data.current_state])
        pass
    $AnimatedSprite2D.play("exit")
    SignalBus.exiting_elevator.emit(sprite_data.sprite_name)

    # 2) Check if there's stored click info
    if sprite_data.elevator_stored_target_floor_number != -1:
        print("stored click info exists")
        set_target_data(
            sprite_data.elevator_stored_target_floor_number,
            sprite_data.elevator_stored_target_position,
            sprite_data.elevator_stored_target_room
        )
        # Clear out the stored data
        sprite_data.elevator_stored_target_floor_number = -1
        sprite_data.elevator_stored_target_position = Vector2.ZERO
        sprite_data.elevator_stored_target_room = -1        

    # when not IN_ELEVATOR the movement_logic() will handle the next action
    # print(sprite_data.sprite_name, " is now IDLE after exiting elevator")




func _on_elevator_door_state_changed(new_state):
    if new_state == Elevator.DoorState.OPEN:
        # If player was waiting at the elevator
        if sprite_data.current_state == SpriteData.State.WAITING_FOR_ELEVATOR \
        and sprite_data.current_position == sprite_data.current_elevator_position:
            _on_elevator_arrived(sprite_data.sprite_name, sprite_data.current_floor_number)
        elif sprite_data.current_state == SpriteData.State.IN_ELEVATOR:
            var old_state = sprite_data.current_state
            sprite_data.current_state = SpriteData.State.EXITING_ELEVATOR
            if old_state != sprite_data.current_state:
                # print("Sprite state changed from %s to %s" % [old_state, sprite_data.current_state])
                pass
            exiting_elevator()




func _on_elevator_ride(elevator_pos: Vector2) -> void:
    # This is logically dependent on the move_elevator() in cabin.gd
    # Both sprites need to move in sync but they have a function each. 
    if sprite_data.current_state == SpriteData.State.IN_ELEVATOR:        
        global_position.x = elevator_pos.x
        global_position.y = elevator_pos.y + sprite_data.elevator_y_offset

        sprite_data.current_position = global_position


func get_elevator_for_current_floor() -> Area2D:
    # helper function for _on_elevator_arrived
    var elevators = get_tree().get_nodes_in_group("elevators")
    for elevator in elevators:
        if elevator.floor_instance and elevator.floor_instance.floor_number == sprite_data.current_floor_number:
            return elevator
    return null

#####################################################################################################
##################              Horizontal Movement Component                 #######################
#####################################################################################################


func movement_logic(delta: float) -> void:

    if sprite_data.current_state == SpriteData.State.IN_ELEVATOR:
        push_warning("movement_logic aborted: Sprite is currently in the elevator.")
        return
            
    if sprite_data.current_position != sprite_data.target_position:

        if sprite_data.target_floor_number == sprite_data.current_floor_number:
            #print("+++++++++++++++++++++++++++++++++")
            #print("we are in movement logic")
            #print("+++++++++++++++++++++++++++++++++")
            move_towards_position(sprite_data.target_position, delta)            
        else:
            # if arrived at the elevator no movement needed, which is the first if block 
            # else is moving the sprite to the current floor elevator. 
            
            
            # should be invoked once, can be replaced with a getter/setter or a simple check if target floor == current floor
            # then can remove the variable
            sprite_data.needs_elevator = true
            #print("needs elevator")
            #print("target floor: ", sprite_data.target_floor_number)
            #print("current floor: ", sprite_data.current_floor_number)
            #print("stored floor: ", sprite_data.elevator_stored_target_floor_number)
            
            # can be moved to a helper function: create elevator request        
            if sprite_data.current_position == sprite_data.current_elevator_position:
                
                var current_request = {
                    "sprite_name": sprite_data.sprite_name,
                    "floor_number": sprite_data.target_floor_number
                }

                # can be moved to a helper function: call elevator
                # these are actions!
                # consider creating a helper function to inform the elevator if the sprite is moving away from the elevator so that another can take the spot in the queue. 
                
                
                # checking for duplicate requests is a premature optimization and should be removed
                if current_request != last_elevator_request:
                    
                    SignalBus.elevator_request.emit(sprite_data.sprite_name, sprite_data.current_floor_number)
                    # print("signal emitted: elevator requested")
                    last_elevator_request = current_request
                    var old_state = sprite_data.current_state
                    sprite_data.current_state = SpriteData.State.WAITING_FOR_ELEVATOR
                    if old_state != sprite_data.current_state:
                        # print("Sprite state changed from %s to %s" % [old_state, sprite_data.current_state])
                        pass
                    sprite_data.current_state = SpriteData.State.WAITING_FOR_ELEVATOR
                    # print(sprite_data.sprite_name, " is now WAITING_FOR_ELEVATOR. In movement logic")
            else:
                # Maybe move this clause up. 
                
                # invoke the elevator call if no movement needed
                # invoke the room-door check if no movement needed
                # => move all non movement related stuff to another function
                
                # Keep moving towards the elevator
                
                move_towards_position(sprite_data.current_elevator_position, delta)



func move_towards_position(target_position: Vector2, delta: float) -> void:
    # Force the y coordinate so we only move horizontally
    target_position.y = global_position.y

    # Now calculate the direction purely in the horizontal axis
    var direction: Vector2 = (target_position - global_position).normalized()
    var distance: float = global_position.distance_to(target_position)

    if distance > 1:
        if sprite_data.current_state != SpriteData.State.WALKING:
            var old_state = sprite_data.current_state
            sprite_data.current_state = SpriteData.State.WALKING
            if old_state != sprite_data.current_state:
                # print("Sprite state changed from %s to %s" % [old_state, sprite_data.current_state])
                pass

        global_position += direction * sprite_data.speed * delta
    else:
        global_position = target_position
        sprite_data.current_position = global_position
        update_state_after_horizontal_movement()

    _update_animation(direction)





func update_state_after_horizontal_movement() -> void:
    if sprite_data.needs_elevator and sprite_data.current_position == sprite_data.current_elevator_position:
        if sprite_data.current_state != SpriteData.State.WAITING_FOR_ELEVATOR:
            var old_state = sprite_data.current_state
            sprite_data.current_state = SpriteData.State.WAITING_FOR_ELEVATOR
            if old_state != sprite_data.current_state:                
                # print("Sprite state changed from %s to %s" % [old_state, sprite_data.current_state])
                pass
    elif sprite_data.target_room >= 0:
        if sprite_data.current_state != SpriteData.State.ENTERING_ROOM:
            var old_state = sprite_data.current_state
            sprite_data.current_state = SpriteData.State.ENTERING_ROOM
            if old_state != sprite_data.current_state:
                # print("Sprite state changed from %s to %s" % [old_state, sprite_data.current_state])
                pass
    else:
        if sprite_data.current_state != SpriteData.State.IDLE:
            var old_state = sprite_data.current_state
            sprite_data.current_state = SpriteData.State.IDLE
            if old_state != sprite_data.current_state:
                # print("Sprite state changed from %s to %s" % [old_state, sprite_data.current_state])
                pass

            last_elevator_request = {"sprite_name": "", "floor_number": -1}
            sprite_data.needs_elevator = false
            # print("update after horizontal movement")





#####################################################################################################
##################              Human Player Movement Component               #######################
#####################################################################################################


func _on_adjusted_navigation_click(floor_number: int, door_index: int, adjusted_position: Vector2) -> void:
    if sprite_data.current_state in [
        SpriteData.State.IN_ELEVATOR,
        SpriteData.State.EXITING_ELEVATOR,
        SpriteData.State.ENTERING_ELEVATOR
    ]:
        handle_in_elevator_click(floor_number, adjusted_position, door_index)
    else:
        set_target_data(floor_number, adjusted_position, door_index)




func set_target_data(floor_number: int, adjusted_click_position: Vector2, target_room: int) -> void:
    if sprite_data.current_floor_number == floor_number:
        sprite_data.target_floor_number = floor_number
        sprite_data.target_position = adjusted_click_position
        sprite_data.target_room = target_room
        
        # --- print debug info
        #print(
            #"[DEBUG] set_target_data: ",
            #"Floor: ", floor_number,
            #", Position: ", adjusted_click_position,
            #", Room: ", target_room
        #)
        
        var old_state = sprite_data.current_state
        sprite_data.current_state = SpriteData.State.IDLE
        if old_state != sprite_data.current_state:
            # print("Sprite state changed from %s to %s" % [old_state, sprite_data.current_state])
            pass

        sprite_data.needs_elevator = false
        last_elevator_request.clear()

    else:
        sprite_data.target_floor_number = floor_number
        sprite_data.target_position = adjusted_click_position
        sprite_data.target_room = target_room
        sprite_data.current_elevator_position = get_elevator_position()

        ## --- print debug info
        #print(
            #"[DEBUG] set_target_data: ",
            #"Floor: ", floor_number,
            #", Position: ", adjusted_click_position,
            #", Room: ", target_room
        #)

        var old_state = sprite_data.current_state
        sprite_data.current_state = SpriteData.State.IDLE
        if old_state != sprite_data.current_state:
            # print("Sprite state changed from %s to %s" % [old_state, sprite_data.current_state])
            pass

        sprite_data.needs_elevator = true
        last_elevator_request.clear()



func handle_in_elevator_click(new_floor: int, new_position: Vector2, new_room: int) -> void:
    
    # conversation id: 676e7af0-f1b4-800a-b2fe-bba51b5db358
    
    # can we get the cabin node once during ready?    
    var cabin_node = get_elevator_cabin()
    if cabin_node == null:
        push_warning("No elevator cabin node found.")
        return
    
    var cabin_current_floor = cabin_node.current_floor
    # var cabin_destination_floor = cabin_node.destination_floor
    var cabin_direction = cabin_node.elevator_direction  # +1 up, -1 down, 0 idle
    #print("in player script")
    # print("cabin_current_floor: ", cabin_current_floor)
    #print("cabin_destination_floor: ", cabin_destination_floor)
    #print("cabin_direction: ", cabin_direction)

    # 1) If the elevator isn't actually moving, or if the new_floor == cabin_current_floor
    #    we can treat that as "on the way" because we can just exit now or soon.
    if cabin_direction == 0 or new_floor == cabin_current_floor:
        # Immediately update request
        SignalBus.elevator_request.emit(sprite_data.sprite_name, new_floor)
        sprite_data.target_floor_number = new_floor
        sprite_data.target_position = new_position
        sprite_data.target_room = new_room
        return

    # 2) Check if new_floor is on the way
    var is_on_the_way = false
    if cabin_direction == 1:  # going up        
        # "on the way" => new_floor between cabin_current_floor and cabin_destination_floor (inclusive)        
        #print("new floor: ", new_floor)
        #print("cabin_current_floor: ", cabin_current_floor)
        #print("cabin_destination_floor: ", cabin_destination_floor)
        
        if new_floor >= cabin_current_floor:
            is_on_the_way = true
            # print("is on way, up")
    elif cabin_direction == -1:  # going down
        # "on the way" => new_floor between cabin_destination_floor and cabin_current_floor (inclusive)
        if new_floor <= cabin_current_floor:
            is_on_the_way = true
            # print("is on way, down")

    if is_on_the_way:
        # 3) On the way => update elevator request right now
        # print("update request immediately")
        SignalBus.elevator_request.emit(sprite_data.sprite_name, new_floor)

        # Also update sprite's target data
        
        # create a sprite update function or use the update target function
        sprite_data.target_floor_number = new_floor
        sprite_data.target_position = new_position
        sprite_data.target_room = new_room
    else:
            # 4) Already passed => store it for after next stop
            sprite_data.elevator_stored_target_floor_number = new_floor
            sprite_data.elevator_stored_target_position = new_position
            sprite_data.elevator_stored_target_room = new_room
            # Decide the very next floor in the direction the elevator is traveling
            var next_floor = cabin_current_floor if cabin_direction == 1 else cabin_current_floor

            # 1) Force the cabin to stop on next_floor
            SignalBus.elevator_request.emit(sprite_data.sprite_name, next_floor)

            # 2) Update the sprite_data so that it believes it is traveling to next_floor
            #    This ensures that once the passenger exits, they're actually on `next_floor`,
            #    and will be waiting at that elevator (instead of some outdated floor).
            sprite_data.current_floor_number = next_floor
            sprite_data.current_elevator_position = get_elevator_position_for(next_floor) 
                # We'll define a helper below so you can get elevator position for an arbitrary floor.

            # Also set the passenger's immediate “target” to the new floor’s elevator position. 
            # That way if they're forced out of the elevator, they'd remain at that floor's elevator. 
            sprite_data.target_floor_number = next_floor
            sprite_data.target_position = sprite_data.current_elevator_position
            sprite_data.target_room = -1  # or however you prefer to indicate no specific room
            sprite_data.needs_elevator = true  # ensures the logic in `movement_logic()` waits for elevator





# helper function needed when controlling the elevator from inside the elevator
func get_elevator_cabin() -> Node:    
    var cabins = get_tree().get_nodes_in_group("cabin")
    if cabins.size() > 0:
        return cabins[0]
    return null

#####################################################################################################
##################              Basic Sprite Component                        #######################  
#####################################################################################################

func update_sprite_dimensions():   # also sets the collsion shape. 
    var idle_texture = $AnimatedSprite2D.sprite_frames.get_frame_texture("idle", 0)
    if idle_texture:
        sprite_data.sprite_width = (idle_texture.get_width() * $AnimatedSprite2D.scale.x)
        sprite_data.sprite_height = (idle_texture.get_height() * $AnimatedSprite2D.scale.y)
        
        # Update collision shape to match sprite dimensions
        var collision_shape = $CollisionShape2D
        if collision_shape:
            var rect_shape = RectangleShape2D.new()
            rect_shape.size = Vector2(sprite_data.sprite_width, sprite_data.sprite_height)
            collision_shape.shape = rect_shape
            # Center the collision shape
            collision_shape.position = Vector2.ZERO
    else:
        print("Warning: 'idle' animation (frame 0) not found.")


func apply_scale_factor_to_sprite():
    var sprite = $AnimatedSprite2D
    if sprite:
        sprite.scale *= SCALE_FACTOR
        # print("Applied scale factor to player sprite.")
    else:
        push_warning("AnimatedSprite2D node not found for scaling.")



func _update_animation(direction: Vector2) -> void:
    match sprite_data.current_state:
        SpriteData.State.WALKING:
            if direction.x > 0:
                $AnimatedSprite2D.play("walk_to_right")
            else:
                $AnimatedSprite2D.play("walk_to_left")

        SpriteData.State.IDLE:
            $AnimatedSprite2D.play("idle")

        SpriteData.State.WAITING_FOR_ELEVATOR:
            $AnimatedSprite2D.play("enter")

        SpriteData.State.ENTERING_ELEVATOR:
            $AnimatedSprite2D.play("enter")

        SpriteData.State.IN_ELEVATOR:
            $AnimatedSprite2D.play("idle")

        SpriteData.State.EXITING_ELEVATOR:
            $AnimatedSprite2D.play("exit")

        SpriteData.State.ENTERING_ROOM:
            $AnimatedSprite2D.play("idle")




func set_initial_position() -> void:
    var target_floor = get_floor_by_number(sprite_data.current_floor_number)             
    var edges: Dictionary = target_floor.get_collision_edges()

    # center of the floor
    var center_x = (edges.left + edges.right) / 2.0

    var bottom_edge_y = edges.bottom
    var sprite_height = sprite_data.sprite_height
    var y_position = bottom_edge_y - (sprite_height /2.0 )

    global_position = Vector2(center_x, y_position)

    sprite_data.current_position = global_position
    sprite_data.target_position = global_position
    sprite_data.current_floor_number = target_floor.floor_number
    sprite_data.target_floor_number = target_floor.floor_number
    sprite_data.current_elevator_position = get_elevator_position()


func get_elevator_position() -> Vector2:   
    
    var current_floor = get_floor_by_number(sprite_data.current_floor_number)
    # print("current floor in get_elevator position: ", sprite_data.current_floor_number)
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
