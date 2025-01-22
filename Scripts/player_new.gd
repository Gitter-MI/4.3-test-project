# player_new.gd
extends Area2D

@onready var state_manager: Node = $State_Component
@onready var navigation_controller: Node = get_parent().get_node("Navigation_Controller")

@onready var pathfinder:= get_tree().get_root().get_node("Main/Player_new/Pathfinder_Component")
@onready var cabin := get_tree().get_root().get_node("Main/Cabin")


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
    set_initial_data()
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

        




#region Elevator Movement
func _process_elevator_actions() -> void:
    # print(" in elevator state in player script")
    match sprite_data_new.elevator_state:
        
        sprite_data_new.ElevatorState.CALLING_ELEVATOR:            
            if not sprite_data_new.elevator_requested:
                call_elevator()
        
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
            # call_elevator()
            pass

        sprite_data_new.ElevatorState.ENTERING_ELEVATOR:            
            if not sprite_data_new.entering_elevator and not sprite_data_new.entered_elevator:
                enter_elevator()
            else: 
                on_sprite_entered_elevator()
        sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT:      
            _animate_sprite()
        sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM:      
            _animate_sprite()
        sprite_data_new.ElevatorState.EXITING_ELEVATOR:
            exit_elevator()        
        _:
                        
            pass


func call_elevator() -> void:
    SignalBus.elevator_called.emit(
        sprite_data_new.sprite_name,
        sprite_data_new.current_floor_number, # pick_up_floor
        sprite_data_new.stored_target_floor,  # destination_floor
        sprite_data_new.elevator_request_id
    )
    _animate_sprite()
    sprite_data_new.elevator_requested = true



#func call_elevator():  
    ## print("calling elevator")  
    #SignalBus.elevator_called.emit(
        #sprite_data_new.sprite_name,
        #sprite_data_new.current_floor_number,
        #sprite_data_new.elevator_request_id
    #)
    #_animate_sprite()
    #sprite_data_new.elevator_requested = true

func _on_elevator_request_confirmed(incoming_sprite_name: String, incoming_floor: int, destination_floor: int, request_id: int) -> void:
    
    # print("destination_floor of the confirmed request: ", destination_floor)
    # print("destination_floor of the sprite: ", sprite_data_new.stored_target_floor)
    
    if incoming_sprite_name == sprite_data_new.sprite_name:        
        if incoming_floor == sprite_data_new.current_floor_number and destination_floor == sprite_data_new.stored_target_floor:            
            sprite_data_new.elevator_request_id = request_id
            # print("Elevator request confirmed. Request ID =", request_id)            
            sprite_data_new.elevator_request_confirmed = true
            

func _on_elevator_ready(incoming_sprite_name: String, request_id: int):
    
    if incoming_sprite_name != sprite_data_new.sprite_name:
        return
    if request_id != sprite_data_new.elevator_request_id:
        return    
    
    if sprite_data_new.elevator_state != sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:        
        return
    sprite_data_new.elevator_ready = true


func enter_elevator():
    # print("enter_elevator")
    sprite_data_new.entering_elevator = true
    var elevator_data = navigation_controller.elevators.get(sprite_data_new.current_floor_number, null)
    var cabin_height = cabin.get_cabin_height()
    var cabin_bottom_y = elevator_data["position"].y + (cabin_height * 0.5)
    var new_position = Vector2(
        elevator_data["position"].x,
        cabin_bottom_y - (sprite_data_new.sprite_height * 0.5)
    )
    sprite_data_new.set_current_position(new_position,sprite_data_new.current_floor_number,sprite_data_new.current_room)
    global_position = sprite_data_new.current_position
    z_index = -9
    SignalBus.entering_elevator.emit()
    _animate_sprite()

func on_sprite_entered_elevator():
    # print("on_sprite_entered_elevator")
    var current_anim = $AnimatedSprite2D.animation    
    if current_anim == "enter" and sprite_data_new.entering_elevator == true:
        sprite_data_new.entered_elevator = true
        SignalBus.enter_animation_finished.emit(sprite_data_new.sprite_name, sprite_data_new.stored_target_floor)
        _animate_sprite()

func _on_elevator_ride(elevator_pos: Vector2, request_id: int) -> void:
    
    if sprite_data_new.elevator_request_id != request_id:
        return 

    if sprite_data_new.entered_elevator:
        var cabin_height = cabin.get_cabin_height()
        var cabin_bottom_y = elevator_pos.y + (cabin_height * 0.5)
        var new_position = Vector2(
            elevator_pos.x,
            cabin_bottom_y - (sprite_data_new.sprite_height * 0.5)
        )
        sprite_data_new.set_current_position(
            new_position,
            sprite_data_new.current_floor_number,
            sprite_data_new.current_room
        )
        global_position = sprite_data_new.current_position
        _animate_sprite()




func _on_elevator_at_destination(incoming_sprite_name: String, request_id: int):    
    if incoming_sprite_name == sprite_data_new.sprite_name and request_id == sprite_data_new.elevator_request_id and sprite_data_new.entered_elevator == true:
        # print("destination signal received")
        sprite_data_new.elevator_destination_reached = true

func exit_elevator():
    _animate_sprite()
    var current_anim = $AnimatedSprite2D.animation
    if current_anim == "exit" and sprite_data_new.elevator_destination_reached:
        z_index = 0
        SignalBus.exit_animation_finished.emit(sprite_data_new.sprite_name)
        sprite_data_new.exited_elevator = true
        sprite_data_new.set_target_position(
            sprite_data_new.stored_target_position,
            sprite_data_new.stored_target_floor,
            sprite_data_new.stored_target_room
        )
        sprite_data_new.reset_stored_data()
         
#endregion
        
        
#region Sprite Animation

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
                    $AnimatedSprite2D.play("exit")                    
                _:
                    $AnimatedSprite2D.play("idle")

        _:
            # Fallback if none of the above states apply
            push_warning("in _animate_sprite: Sprite is in no recognized state!")
            $AnimatedSprite2D.play("idle")
#endregion

#region Sprite Movement
func move_sprite(delta: float) -> void:
    
    var active_state = sprite_data_new.get_active_state()
    if active_state == sprite_data_new.ActiveState.MOVEMENT:
        if sprite_data_new.movement_state == sprite_data_new.MovementState.WALKING:
            move_towards_position(sprite_data_new.target_position, delta)

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
            Vector2(new_x, sprite_data_new.target_position.y),
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
    var adjusted_door_index = _door_index 
    # if target is elevator on another floor, ensure we are not entering the elevator there
    if adjusted_door_index == -2 and _floor_number != sprite_data_new.current_floor_number:
        adjusted_door_index = -1
    sprite_data_new.set_sprite_nav_data(_click_global_position, _floor_number, adjusted_door_index)
#endregion


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

func set_initial_data():
    sprite_data_new.current_floor_number = 3 
    sprite_data_new.current_room = -1  
    sprite_data_new.target_floor_number = 3
    sprite_data_new.sprite_name = "Player_1"
    sprite_data_new.elevator_request_id = 1


#endregion


#region connect_to_signals
func connect_to_signals():
    SignalBus.adjusted_navigation_click.connect(_on_adjusted_navigation_click)    
    SignalBus.floor_area_entered.connect(_on_floor_area_entered)        
    SignalBus.elevator_request_confirmed.connect(_on_elevator_request_confirmed) # 
    SignalBus.elevator_ready.connect(_on_elevator_ready) # 
    SignalBus.elevator_ready.connect(_on_elevator_at_destination) # 
    SignalBus.elevator_position_updated.connect(_on_elevator_ride)  # 
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
