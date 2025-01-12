# player_new.gd
extends Area2D

@onready var state_manager: Node = $State_Component
@onready var navigation_controller: Node = get_parent().get_node("Navigation_Controller")
@onready var pathfinder: Pathfinder = $Pathfinder_Component

const SpriteDataScript = preload("res://Scripts/SpriteData_new.gd")

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
    pathfinder.determine_path(sprite_data_new)
    state_manager.process_state(sprite_data_new)
    var active_state = sprite_data_new.get_active_state()
    
    if active_state == sprite_data_new.ActiveState.MOVEMENT:
        move_sprite(delta)
        _animate_sprite()

    if active_state == sprite_data_new.ActiveState.ELEVATOR:
        _process_elevator_actions()



func _process_elevator_actions() -> void:
    # print(" in elevator state in player script")
    match sprite_data_new.elevator_state:
        
        sprite_data_new.ElevatorState.CALLING_ELEVATOR:
            
            # If we have not yet requested => do it now
            if not sprite_data_new.elevator_requested:
                call_elevator()
        
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
            # print("what??? why???")
            # Maybe just show an idle/waiting animation, do nothing else
            # The state manager will handle the transition to ENTERING_ELEVATOR
            pass

        sprite_data_new.ElevatorState.ENTERING_ELEVATOR:
            # If we haven't started entering yet => start
            if not sprite_data_new.entering_elevator and not sprite_data_new.entered_elevator:
                enter_elevator()
            else: 
                on_sprite_entered_elevator()

        # Possibly handle other states (IN_ELEVATOR_TRANSIT, etc.)
        _:
            
            pass


func call_elevator():
    print("sprite is calling the elevator: elevator_requested = true")
    # 1) Emit the signal that we want to call the elevator
    # nobody is connecting to the signal right now. We will implement this in a second step
    SignalBus.elevator_called.emit(
        sprite_data_new.sprite_name,
        sprite_data_new.current_floor_number
    )
    _animate_sprite()
    print("Details of the elevator request: ")
    print("Sprite_Name: ",sprite_data_new.sprite_name)
    print("Pick-Up floor: ", sprite_data_new.current_floor_number)
    

    # 2) Set the flag so the state manager knows we've requested it
    sprite_data_new.elevator_requested = true
    # we skip the integration into the elevator script for now to confirm this part of the implementation is working as expected. 
    #print("setting request to confirmed for debugging purposes: .elevator_request_confirmed = true")
    #sprite_data_new.elevator_request_confirmed = true
    #print("setting elevator to ready for debugging purposes: .elevator_ready = true")
    #sprite_data_new.elevator_ready = true



func _on_elevator_request_confirmed(incoming_sprite_name: String, incoming_floor: int) -> void:
    print("signal received: _on_elevator_request_confirmed")
    # 1) Check if this signal is meant for our sprite
    if incoming_sprite_name == sprite_data_new.sprite_name:
        # 2) Optionally check if the floor matches the floor where we called the elevator
        if incoming_floor == sprite_data_new.current_floor_number:
            # 3) If it's indeed for this sprite on this floor, set the flag
            sprite_data_new.elevator_request_confirmed = true
            
    

func _on_elevator_ready(incoming_sprite_name: String):
    if incoming_sprite_name == sprite_data_new.sprite_name:
        sprite_data_new.elevator_ready = true


#func enter_elevator():
    ## Mark that we are in the process of entering the elevator
    #print("sprite is entering the elevator")
    #sprite_data_new.entering_elevator = true
    #z_index = -9
    #SignalBus.entering_elevator.emit()
    #_animate_sprite()


func enter_elevator():
    # print("Sprite is entering the elevator.")
    sprite_data_new.entering_elevator = true

    # 1) Get elevator data for the current floor
    var elevator_data = navigation_controller.elevators.get(sprite_data_new.current_floor_number, null)
    if elevator_data == null:
        push_warning("No elevator data found for floor %d" % sprite_data_new.current_floor_number)
        return

    # 2) Elevator edges and global position
    var elevator_edges = elevator_data["edges"]          # left, right, top, bottom, center
    var elevator_bottom_y = elevator_edges["bottom"]     # The “floor” of the elevator
    var elevator_center_x = elevator_data["position"].x  # The elevator’s center X
    
    # 3) Position sprite so it “stands” on the elevator floor
    global_position.x = elevator_center_x
    global_position.y = elevator_bottom_y - (sprite_data_new.sprite_height * 0.5)
    
    # 4) Record the offset so we can ride with the elevator
    #    i.e. how far above the elevator’s pivot (center.y) the sprite is
    sprite_data_new.elevator_y_offset = global_position.y - elevator_data["position"].y
    
    # 5) Adjust z-index for correct layering and emit the “entering” signal
    z_index = -9
    SignalBus.entering_elevator.emit()
    _animate_sprite()



func on_sprite_entered_elevator():
    var current_anim = $AnimatedSprite2D.animation
    
    if current_anim == "enter" and sprite_data_new.entering_elevator == true:
        sprite_data_new.entered_elevator = true
        SignalBus.enter_animation_finished.emit(sprite_data_new.sprite_name, sprite_data_new.stored_target_floor)
        _animate_sprite()


func _on_elevator_ride(elevator_pos: Vector2) -> void:
    if sprite_data_new.entered_elevator:
        # Keep the sprite aligned with the elevator’s position + y-offset
        global_position.x = elevator_pos.x
        global_position.y = elevator_pos.y + sprite_data_new.elevator_y_offset
        
        sprite_data_new.current_position = global_position


#func _on_elevator_ride(elevator_pos: Vector2) -> void:
    #if sprite_data_new.entered_elevator:
        #
        ## This is logically dependent on the move_elevator() in cabin.gd
        ## Both sprites need to move in sync but they have a function each.     
        #
        ## var elevator = get_elevator_for_current_floor()
        ## sprite_data_new.elevator_y_offset = global_position.y - elevator.global_position.y   
            #
        #global_position.x = elevator_pos.x
        #global_position.y = elevator_pos.y + 0 #sprite_data_new.elevator_y_offset
#
    #sprite_data_new.current_position = global_position



func _animate_sprite() -> void:
    var direction = (sprite_data_new.target_position - sprite_data_new.current_position).normalized()
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
                sprite_data_new.ElevatorState.CALLING_ELEVATOR:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.ElevatorState.ENTERING_ELEVATOR:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM:
                    $AnimatedSprite2D.play("idle")
                sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT:
                    $AnimatedSprite2D.play("idle")
                sprite_data_new.ElevatorState.EXITING_ELEVATOR:
                    $AnimatedSprite2D.play("idle")
                _:
                    $AnimatedSprite2D.play("idle")

        _:
            # Fallback if none of the above states apply
            push_warning("in _animate_sprite: Sprite is in no recognized state!")
            $AnimatedSprite2D.play("idle")



func move_sprite(delta: float) -> void:
    # You can read the current active state and sub-state to decide movement
    var active_state = sprite_data_new.get_active_state()
    if active_state == sprite_data_new.ActiveState.MOVEMENT:
        if sprite_data_new.movement_state == sprite_data_new.MovementState.WALKING:
            move_towards_position(sprite_data_new.target_position, delta)
        # e.g. do nothing if IDLE

    # Possibly handle other states that need special movement...

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
    SignalBus.elevator_request_confirmed.connect(_on_elevator_request_confirmed)
    SignalBus.elevator_ready.connect(_on_elevator_ready)
    SignalBus.elevator_position_updated.connect(_on_elevator_ride)  
    
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
