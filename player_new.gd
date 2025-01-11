# player_new.gd
extends Area2D

@onready var navigation_controller: Node = get_parent().get_node("Navigation_Controller")
@onready var pathfinder: Pathfinder = $Pathfinder_Component

const SpriteDataScript = preload("res://SpriteData_new.gd")

const SCALE_FACTOR = 2.3
# var sprite_data_new: SpriteDataNew
var sprite_data_new: Resource
var last_elevator_request: Dictionary = {"sprite_name": "", "floor_number": -1}
var previous_elevator_position: Vector2 = Vector2.ZERO



func _ready():
    sprite_data_new = SpriteDataScript.new()
    instantiate_sprite()
    connect_to_signals()
    set_initial_position()
    # print("Player sprite ready")
    SignalBus.player_sprite_ready.emit()  # for debugging but player sprite is ready before nav controller is invoked
    


func _process(delta: float) -> void:
    
    # process_input
    # process_commands    
    # process_state
    
    if sprite_data_new.has_nav_data:
        pathfinder.determine_path(sprite_data_new)
        
    var state = sprite_data_new.get_active_state()
    
    match state:
        sprite_data_new.ActiveState.MOVEMENT:
            _process_movement_state(delta)  # for later
            # print("sprite is in MOVEMENT state")
        sprite_data_new.ActiveState.ROOM:
            print("sprite is in ROOM state")
        sprite_data_new.ActiveState.ELEVATOR:
            print("sprite is in ELEVATOR state")
        _:
            push_warning("Sprite is in no recognized state!")


func _process_movement_state(delta: float) -> void:
    # print("in _process_movement_state")
    match sprite_data_new.movement_state:
        sprite_data_new.MovementState.IDLE:
            _process_movement_idle(delta)
        sprite_data_new.MovementState.WALKING:
            _process_movement_walking(delta)
        _:
            push_warning("Unknown movement sub-state: %s" % str(sprite_data_new.movement_state))


func _process_movement_idle(_delta: float) -> void:
    var target_differs = (sprite_data_new.target_position != sprite_data_new.current_position)
    var has_stored = sprite_data_new.has_stored_data
    var room_index = sprite_data_new.target_room

    if target_differs or has_stored:
        # If position differs or we have stored data, proceed with movement.
        _update_movement_state()

    elif not target_differs and not has_stored:
        # If the position is the same and we have no pending data,
        # check if the room_index indicates we want to do something (e.g., elevator or real room).
        if room_index >= 0 or room_index == -2:
            # For example, we assume we still want to trigger walking or an elevator action.
            _update_movement_state()
        else:
            # Otherwise, we continue to idle.
            _update_animation(Vector2.ZERO)

    else:
        push_warning("Unexpected condition in IDLE state!")


func _process_movement_walking(delta: float) -> void:
    # print("Sprite is in MovementState.WALKING state")    
    if sprite_data_new.current_position == sprite_data_new.target_position:
        print("_process_movement_walking -> _update_movement_state")
        _update_movement_state()
    else:
        move_towards_position(sprite_data_new.target_position, delta)
        # print("Moving sprite... (placeholder)")

func _update_movement_state() -> void:
    var x_differs = (sprite_data_new.current_position != sprite_data_new.target_position)
    var has_stored = sprite_data_new.has_stored_data
    var room_index = sprite_data_new.target_room

    # 1) X matches and no stored target = arrived at final destination
    if not x_differs and not has_stored:
        if room_index < 0 and room_index != -2:
            sprite_data_new.set_movement_state(sprite_data_new.MovementState.IDLE)
            print("Update: sprite is now in MovementState.IDLE")
        elif room_index >= 0:
            sprite_data_new.set_room_state(sprite_data_new.RoomState.CHECKING_ROOM_STATE)
            print("Update: sprite is now in RoomState.CHECKING_ROOM_STATE")
        elif room_index == -2:
            sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR)
            print("Update: sprite is now in ElevatorState.WAITING_FOR_ELEVATOR")
        else:
            push_warning("Unhandled target_room value: %d" % room_index)

    # 2) X matches and has stored data
    elif not x_differs and has_stored:
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR)
        print("Update: sprite is now in ElevatorState.WAITING_FOR_ELEVATOR")

    # 3) X does not match
    elif x_differs:
        sprite_data_new.set_movement_state(sprite_data_new.MovementState.WALKING)
        print("Update: sprite is now in MovementState.WALKING")

    # 4) Fallback
    else:
        push_warning("Bad error in _update_movement_state!")




func move_towards_position(target_position: Vector2, delta: float) -> void:
    # Force horizontal-only movement by locking the target's Y to current_position.y
    target_position.y = sprite_data_new.current_position.y
    
    var direction = (target_position - sprite_data_new.current_position).normalized()
    var distance = sprite_data_new.current_position.distance_to(target_position)

    
    if distance > 1.0:
        var new_x = sprite_data_new.current_position.x + direction.x * sprite_data_new.speed * delta
        sprite_data_new.set_current_position(
            Vector2(new_x, sprite_data_new.current_position.y),
            sprite_data_new.current_floor_number,
            sprite_data_new.current_room
        )
        global_position.x = new_x
    else:
        # print("distance: ", distance)
        var new_x = sprite_data_new.target_position.x
        sprite_data_new.set_current_position(
            Vector2(new_x, sprite_data_new.current_position.y),
            sprite_data_new.current_floor_number,
            sprite_data_new.current_room
        )
        global_position.x = new_x

    _update_animation(direction)


func _update_animation(direction: Vector2) -> void:
    var main_state = sprite_data_new.get_active_state()
    
    match main_state:
        sprite_data_new.ActiveState.MOVEMENT:
            match sprite_data_new.movement_state:
                sprite_data_new.MovementState.WALKING:
                    if direction.x > 0:
                        $AnimatedSprite2D.play("walk_to_right")
                    else:
                        $AnimatedSprite2D.play("walk_to_left")
                sprite_data_new.MovementState.IDLE:
                    $AnimatedSprite2D.play("idle")
                _:
                    # e.g., MovementState.NONE or future expansions
                    $AnimatedSprite2D.play("idle")
        
        sprite_data_new.ActiveState.ROOM:
            match sprite_data_new.room_state:
                sprite_data_new.RoomState.ENTERING_ROOM:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.RoomState.EXITING_ROOM:
                    $AnimatedSprite2D.play("exit")
                sprite_data_new.RoomState.IN_ROOM:
                    $AnimatedSprite2D.play("idle")
                # etc.
                _:
                    $AnimatedSprite2D.play("idle")
        
        sprite_data_new.ActiveState.ELEVATOR:
            match sprite_data_new.elevator_state:
                sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.ElevatorState.ENTERING_ELEVATOR:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM:
                    $AnimatedSprite2D.play("idle")
                sprite_data_new.ElevatorState.EXITING_ELEVATOR:
                    $AnimatedSprite2D.play("exit")
                # For IN_ELEVATOR_TRANSIT or other states:
                # $AnimatedSprite2D.play("idle") # or something else
                _:
                    $AnimatedSprite2D.play("idle")

        _:
            # Fallback if none of the above states apply
            $AnimatedSprite2D.play("idle")

func _on_floor_area_entered(area: Area2D, floor_number: int) -> void:
    if area == self:
        sprite_data_new.set_current_position(
            sprite_data_new.current_position,  # keep the same position
            floor_number,                      # update floor
            sprite_data_new.current_room       # keep the same room index
        )
        # print("I, %s, have entered floor #%d" % [name, floor_number])

func _on_adjusted_navigation_click(_floor_number: int, _door_index: int, _click_global_position: Vector2) -> void:
    # print("Navigation click received in player script")            
    sprite_data_new.set_sprite_nav_data(_click_global_position, _floor_number, _door_index)


#region set_initial_position
func set_initial_position() -> void:
    var current_floor_number: int = sprite_data_new.current_floor_number
    var floor_info: Dictionary = navigation_controller.floors[current_floor_number]

    var edges: Dictionary = floor_info["edges"]
    var center_x = (edges["left"] + edges["right"]) / 2.0
    var bottom_edge_y = edges["bottom"]
    var sprite_height = sprite_data_new.sprite_height
    var y_position = bottom_edge_y - (sprite_height / 2.0)

    global_position = Vector2(center_x, y_position)

    # Use setter functions to update current and target positions/floors
    sprite_data_new.set_current_position(
        global_position,
        current_floor_number,
        sprite_data_new.current_room
    )
    sprite_data_new.set_target_position(
        global_position,
        current_floor_number,
        sprite_data_new.target_room
    )
    # print("in set_initial_position: ", global_position)
#endregion


#region connect_to_signals
func connect_to_signals():
    SignalBus.adjusted_navigation_click.connect(_on_adjusted_navigation_click)    
    SignalBus.floor_area_entered.connect(_on_floor_area_entered)
    #SignalBus.elevator_arrived.connect(_on_elevator_arrived)   
    #SignalBus.elevator_position_updated.connect(_on_elevator_ride)
    #SignalBus.door_state_changed.connect(_on_elevator_door_state_changed)
    #SignalBus.floor_clicked.connect(_on_floor_clicked)
    #SignalBus.door_clicked.connect(_on_door_clicked)player_sprite_ready
    #$AnimatedSprite2D.animation_finished.connect(_on_sprite_entered_elevator)   
#endregion


#region instantiate_sprite


#####################################################################################################
##################              Basic Sprite Component                        #######################  
#####################################################################################################

func instantiate_sprite():
    add_to_group("player_sprites_new")
    # print("player is in group player_sprites")
    # sprite_data_new = SpriteDataNew.new()    
    apply_scale_factor_to_sprite()
    update_sprite_dimensions()
    update_collision_shape()    
    


func update_sprite_dimensions():
    var idle_texture = $AnimatedSprite2D.sprite_frames.get_frame_texture("idle", 0)
    if idle_texture:
        sprite_data_new.sprite_width = idle_texture.get_width() * $AnimatedSprite2D.scale.x
        sprite_data_new.sprite_height = idle_texture.get_height() * $AnimatedSprite2D.scale.y
    else:
        print("Warning: 'idle' animation (frame 0) not found.")


func update_collision_shape():    
    var collision_shape = $CollisionShape2D
    if collision_shape:
        var rect_shape = RectangleShape2D.new()
        rect_shape.size = Vector2(sprite_data_new.sprite_width, sprite_data_new.sprite_height)
        collision_shape.shape = rect_shape        
        collision_shape.position = Vector2.ZERO
    else:
        print("Warning: CollisionShape2D not found.")


func apply_scale_factor_to_sprite():
    var sprite = $AnimatedSprite2D
    if sprite:
        sprite.scale *= SCALE_FACTOR
        # print("Applied scale factor to player sprite.")
    else:
        push_warning("AnimatedSprite2D node not found for scaling.")



#endregion
