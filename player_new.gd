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
    if sprite_data_new.has_nav_data:
        pathfinder.determine_path(sprite_data_new)
        
    var state = sprite_data_new.get_active_state()
    
    match state:
        sprite_data_new.ActiveState.MOVEMENT:
            _process_movement_state(delta)  # for later
            # print("sprite is in MOVEMENT state")
        # sprite_data_new.ActiveState.ROOM:
            # print("sprite is in ROOM state")
        # sprite_data_new.ActiveState.ELEVATOR:
            # print("sprite is in ELEVATOR state")
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


func _process_movement_idle(delta: float) -> void:
    # print("sprite is in MovementState.IDLE state")

    var target_differs = (sprite_data_new.target_position != sprite_data_new.current_position)
    var has_stored = sprite_data_new.has_stored_data

    if target_differs or has_stored:
        # if the sprite has a target different from the current position, or is at the target but has a stored position
        _update_movement_state()
    elif not target_differs and not has_stored:        
        # Keep idling: do nothing, or play idle animation
        pass
    else:
        push_warning("Unexpected condition in IDLE state!")

func _process_movement_walking(delta) -> void:
    # print("sprite is in MovementState.WALKING state")
    
    if sprite_data_new.current_position == sprite_data_new.target_position:
        _update_movement_state()        
    else:
        move_towards_position(sprite_data_new.target_position, delta)
        print("Moving sprite... (placeholder)")


func _update_movement_state() -> void:
    var target_differs = (sprite_data_new.target_position != sprite_data_new.current_position)
    var has_stored = sprite_data_new.has_stored_data
    var room_index = sprite_data_new.target_room
    
    # 1) at target and no stored target = arrived at final destination
    if not target_differs and not has_stored:
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
    
    # 2) At target position and has stored data
    elif not target_differs and has_stored:
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR)
        print("Update: sprite is now in ElevatorState.WAITING_FOR_ELEVATOR")        
    
    # 3) Not at target position. 
    elif target_differs:
        sprite_data_new.set_movement_state(sprite_data_new.MovementState.WALKING)
        print("Update: sprite is now in MovementState.WALKING")
    
    # 4) Fallback
    else:
        push_warning("Bad error in _update_movement_state!")


func move_towards_position(target_position: Vector2, delta: float) -> void:
    # Force y to remain at current_position.y (horizontal-only movement)
    target_position.y = sprite_data_new.current_position.y

    var direction = (target_position - sprite_data_new.current_position).normalized()
    var distance = sprite_data_new.current_position.distance_to(target_position)

    # If we're more than 1 pixel away, keep moving
    if distance > 1:
        if sprite_data_new.movement_state != sprite_data_new.MovementState.WALKING:
            var old_state = sprite_data_new.movement_state
            sprite_data_new.set_movement_state(sprite_data_new.MovementState.WALKING)
            if old_state != sprite_data_new.movement_state:
                print("Movement state changed from %s to %s" % [old_state, sprite_data_new.movement_state])

        sprite_data_new.current_position.x += direction.x * sprite_data_new.speed * delta
        global_position.x = sprite_data_new.current_position.x
    else:
        # Snap to target        
        sprite_data_new.current_position = sprite_data_new.target_position
        global_position = target_position


#     _update_animation(direction)






     # process_commands    
    
    # process_state
    # implement this basic check: 
    # if sprite is in movement state then call _process_movement
    
# func process movement
    #if idle then	_process_movement_idle
    #if walking then	_process_movement_walking
    #else 	error
    
    
# func _process_movement_idle	
    #if target pos != current pos 	
    #or stored pos exists then	_update_movement_state
    #if target pos == current pos	
    #and no stored pos	keep idling (animation)
    #else	error


# func _process_movement_walking	
    #if target pos = current pos	
    #and no stored pos	_check_for_category_switch
       #
    #if target pos == current pos 	_check_for_category_switch
    #and stored pos exists	
    #if target pos != current pos	move_sprite_horizontally


#func _update_movement_state	
    #if target pos == current pos 	
    #and no stored pos exists	
    #and target is not room or elevator room	set state to idle
       #
    #if target pos == current pos 	
    #and no stored pos exists	
    #and target is room (door index >=0) or elevator room ( door index == -2)	set state to Room (CHECKING_ROOM_STATE)
       #or set state to Elevator (WAITING_FOR_ELEVATOR)
       #
    #if target == current pos	
    #and stored pos exists	set state to Elevator (WAITING_FOR_ELEVATOR)
       #call Pathfinder instead 
       #
    #if target != current pos	set state to walking
       #
    #else	error



##
## add debug print statements with the new sprite state
##


func _on_floor_area_entered(area: Area2D, floor_number: int) -> void:            
    if area == $".": # If the area that triggered the signal belongs to excactly this sprite
        # print("I, %s, have entered floor #%d" % [name, floor_number])
        sprite_data_new.current_floor_number = floor_number
    

func _on_navigation_click(_click_global_position: Vector2, _floor_number: int, _door_index: int) -> void:
    # print("Navigation click received in player script")
    
    # print("sprite has nav data?: ", sprite_data_new.has_nav_data)
    sprite_data_new.set_sprite_nav_data(_click_global_position, _floor_number, _door_index)





#region set_initial_position
func set_initial_position() -> void:    
    var current_floor_number: int = sprite_data_new.current_floor_number
    var floor_info: Dictionary = navigation_controller.floors[current_floor_number]

    var edges: Dictionary = floor_info["edges"]  # floors[floor_number]["edges"]
    var center_x = (edges["left"] + edges["right"]) / 2.0
    var bottom_edge_y = edges["bottom"]
    var sprite_height = sprite_data_new.sprite_height
    var y_position = bottom_edge_y - (sprite_height / 2.0)

    global_position = Vector2(center_x, y_position)

    
    sprite_data_new.current_position = global_position
    sprite_data_new.target_position = global_position
    sprite_data_new.current_floor_number = current_floor_number
    sprite_data_new.target_floor_number = current_floor_number
#endregion


#region connect_to_signals
func connect_to_signals():
    SignalBus.navigation_click.connect(_on_navigation_click)    
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
