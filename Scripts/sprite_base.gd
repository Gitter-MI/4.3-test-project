# sprite_base.gd
extends Area2D

@onready var navigation_controller := get_tree().get_root().get_node("Main/Navigation_Controller")
@onready var cabin := get_tree().get_root().get_node("Main/Magical_Elevator")
@export var state_manager: Node
@export var pathfinder: Node
@export var movement: Node

const SpriteDataScript = preload("res://Data/SpriteData_new.gd")
var sprite_data_new: Resource = SpriteDataScript.new()

const SCALE_FACTOR = 2.3


func _ready():
    instantiate_sprite()
    connect_to_signals()    
    set_initial_position()
    z_index = 1



func _process(delta: float) -> void:   
    
    
    sprite_data_new.stored_position_updated = pathfinder.determine_path(sprite_data_new)
    # print("stored position updated? ", sprite_data_new.stored_position_updated)
    
    # print("process state") 
    # print("sprite script calls process_state")
    state_manager.process_state(sprite_data_new)
    var active_state = sprite_data_new.get_active_state()
    
    if active_state == sprite_data_new.ActiveState.MOVEMENT:   
        # print("process movement")     
        movement.move_sprite(delta, sprite_data_new, self)
        _animate_sprite()

    if active_state == sprite_data_new.ActiveState.ELEVATOR:
        # print("process elevator actions")
        # elevator._process_elevator_actions(sprite_data_new, self)
        _process_elevator_actions()


func _process_elevator_actions() -> void:
    # print(" in elevator state in player script")
    match sprite_data_new.elevator_state:
        
        sprite_data_new.ElevatorState.CALLING_ELEVATOR:     
                   
            if not sprite_data_new.elevator_requested or sprite_data_new.stored_position_updated:                
                #print("sprite_data_new.elevator_requested: ", sprite_data_new.elevator_requested)
                #print("stored_position_updated: ", stored_position_updated)                
                call_elevator()        
                
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:     
            if sprite_data_new.stored_position_updated:
                call_elevator()
            
            # request_elevator_ready_status() 
                # pass
        sprite_data_new.ElevatorState.ENTERING_ELEVATOR:               
            if not sprite_data_new.entered_elevator:                
                enter_elevator()                            
        sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT:      
            _animate_sprite()
        sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM:      
            _animate_sprite()
        sprite_data_new.ElevatorState.EXITING_ELEVATOR:
            exit_elevator()        
        _:
                        
            pass


#region Elevator Movement

func call_elevator() -> void:

    var request_data: Dictionary = {
        "sprite_name": sprite_data_new.sprite_name,
        "pick_up_floor": sprite_data_new.current_floor_number,
        "destination_floor": sprite_data_new.stored_target_floor,
        "request_id": sprite_data_new.elevator_request_id
    }

    SignalBus.elevator_called.emit(request_data)
    _animate_sprite()

    sprite_data_new.elevator_requested = true

func _on_elevator_request_confirmed(elevator_request_data: Dictionary, elevator_ready_status: bool) -> void:
    print("elevator request confirmed signal received by: ", sprite_data_new.sprite_name)
    var incoming_sprite_name = elevator_request_data["sprite_name"]    
    var incoming_request_id = elevator_request_data["request_id"]
    
    if not incoming_sprite_name == sprite_data_new.sprite_name: # or incoming_request_id != sprite_data_new.elevator_request_id:
        # print("not my sprite name: ", sprite_data_new.sprite_name)
        print("the incomming sprite name ", incoming_sprite_name, " is not my sprite name: ", sprite_data_new.sprite_name)
        # print("the incomming incoming_request_id ", incoming_request_id, " is not my request_id: ", sprite_data_new.elevator_request_id)
        return
    
    print("Sprite ", sprite_data_new.sprite_name, " received the request confirmation.")    
    sprite_data_new.elevator_request_id = incoming_request_id
    sprite_data_new.elevator_request_confirmed = true
    
    if elevator_ready_status:        
        if sprite_data_new.elevator_state == sprite_data_new.ElevatorState.CALLING_ELEVATOR \
            or sprite_data_new.elevator_state == sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:

            print("The elevator is ready for ", sprite_data_new.sprite_name)
            sprite_data_new.elevator_ready = true
            sprite_data_new.defer_input = true            
            
            state_manager._process_elevator_state(sprite_data_new)

            print("emitting entering elevator in _on_elevator_request_confirmed for: ", sprite_data_new.sprite_name)
            SignalBus.entering_elevator.emit(sprite_data_new.sprite_name)
            # You might lock down movement here or do any other UI updates as needed
            
        else:
            # If the sprite isn't in the CALLING or WAITING state, do not let it enter
            print("Elevator is ready, but sprite ", sprite_data_new.sprite_name, 
                  " is not waiting or calling. Current elevator_state =", sprite_data_new.elevator_state)
            return

    else:
        print("Not entering because the elevator is blocked or not ready.")
        return


func _on_elevator_waiting_ready_received(elevator_request_data: Dictionary, elevator_ready_status: bool) -> void:
    
    ### case of the DRY here and in the _on_elevator_request_confirmed function
    
    print("elevator_waiting_ready signal received: ", sprite_data_new.sprite_name)
    var incoming_sprite_name = elevator_request_data["sprite_name"]
    var incoming_request_id = elevator_request_data["request_id"]
    
    if not incoming_sprite_name == sprite_data_new.sprite_name:
        # print("not my sprite name: ", sprite_data_new.sprite_name)
        return   
        
    match sprite_data_new.elevator_state:        
        
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
            
            # print("Sprite ", sprite_data_new.sprite_name, " received the request confirmation.")    
            sprite_data_new.elevator_request_id = incoming_request_id
            sprite_data_new.elevator_request_confirmed = true
            
            if elevator_ready_status:
                # print("The elevator is ready for ", sprite_data_new.sprite_name)
                sprite_data_new.elevator_ready = true
                sprite_data_new.defer_input = true
                # state_manager._process_elevator_state(sprite_data_new) ## update sprite state immediately
                ## consider emitting the signal from inside the state specific functions
                # print("emitting entering elevator in _on_elevator_waiting_ready_received for: ", sprite_data_new.sprite_name)
                # print("entering because the elevator is waiting")
                SignalBus.entering_elevator.emit(sprite_data_new.sprite_name)
                '''ensure sprite is locked down for the entering period'''

        _:
            # print(sprite_data_new.sprite_name, " is not waiting for the elevator.")
            pass

func enter_elevator():    
    
    if not sprite_data_new.entering_elevator:        
        sprite_data_new.entering_elevator = true
        _animate_sprite() # $AnimatedSprite2D.play("enter")        
           
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
        # print("Sprite emits entering elevator signal")
        # SignalBus.entering_elevator.emit(sprite_data_new.sprite_name, sprite_data_new.elevator_request_id, sprite_data_new.target_room)
    else:        
        return

func on_sprite_entered_elevator():    
    sprite_data_new.entered_elevator = true
    SignalBus.enter_animation_finished.emit(sprite_data_new.sprite_name, sprite_data_new.stored_target_floor)
    _animate_sprite()

func _on_elevator_ride(elevator_pos: Vector2, sprite_name: String) -> void:
    
    if sprite_data_new.sprite_name != sprite_name:
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

func _on_elevator_at_destination(incoming_sprite_name: String):
    # print("_on_elevator_at_destination") ## is being called twice
    if incoming_sprite_name == sprite_data_new.sprite_name:        
        sprite_data_new.elevator_destination_reached = true

func exit_elevator():
    # print("exit elevator in sprite base") 
    if not sprite_data_new.exiting_elevator:
        sprite_data_new.exiting_elevator = true
        _animate_sprite() 
    else:
        return

func on_sprite_exited_elevator():
    # print("on_sprite_exited_elevator in sprite base")
    z_index = 1
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
                    push_warning("in _animate_sprite: Sprite is in no recognized state in _animate_sprite! - MovementState")
                    $AnimatedSprite2D.play("idle")
        
        sprite_data_new.ActiveState.ROOM:
            match sprite_data_new.room_state:
                sprite_data_new.RoomState.ENTERING_ROOM:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.RoomState.EXITING_ROOM:
                    $AnimatedSprite2D.play("exit")
                sprite_data_new.RoomState.IN_ROOM:
                    $AnimatedSprite2D.play("idle")                
                _:
                    push_warning("in _animate_sprite: Sprite is in no recognized state in _animate_sprite! - RoomState")
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
                    push_warning("in _animate_sprite: Sprite is in no recognized state in _animate_sprite! - ElevatorState")
                    $AnimatedSprite2D.play("idle")

        _:
            push_warning("in _animate_sprite: Sprite is in no recognized state in _animate_sprite!")
            $AnimatedSprite2D.play("idle")
            
func _on_animation_finished() -> void:    
    var anim_name = $AnimatedSprite2D.animation
    
    match anim_name:
        "enter":
            if sprite_data_new.elevator_ready:
                on_sprite_entered_elevator()

        "exit":
            if sprite_data_new.elevator_destination_reached:
                on_sprite_exited_elevator()      
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



#endregion


#region connect_to_signals
func connect_to_signals():
    SignalBus.adjusted_navigation_command.connect(_on_adjusted_navigation_command)
    SignalBus.floor_area_entered.connect(_on_floor_area_entered)
    SignalBus.elevator_request_confirmed.connect(_on_elevator_request_confirmed)
    SignalBus.elevator_waiting_ready.connect(_on_elevator_waiting_ready_received)    
    SignalBus.elevator_arrived_at_destination.connect(_on_elevator_at_destination) ## not needed any more -> handled by elevator's waiting function
    SignalBus.elevator_position_updated.connect(_on_elevator_ride)
    
    $AnimatedSprite2D.animation_finished.connect(_on_animation_finished)


  
            



    

func _on_floor_area_entered(area: Area2D, floor_number: int) -> void:
    if area == self:
        sprite_data_new.set_current_position(
            sprite_data_new.current_position,  # keep the same position
            floor_number,                      # update floor
            sprite_data_new.current_room       # keep the same room index
        )
        # print("I, %s, have entered floor #%d" % [name, floor_number])    


func _on_adjusted_navigation_command(_commander: String, sprite_name: String, floor_number: int, door_index: int, click_global_position: Vector2) -> void:       
    # print("Navigation click received in ", sprite_data_new.sprite_name, " script with sprite_name: ", sprite_name)
    if not sprite_name == sprite_data_new.sprite_name:
        return    
    # if target is elevator room on another floor, ensure we are setting destination to that position not the room
    if door_index == -2 and floor_number != sprite_data_new.current_floor_number:        
        door_index = -1            
    sprite_data_new.set_sprite_nav_data(click_global_position, floor_number, door_index)
    # print("_on_adjusted_navigation_command for: ", sprite_data_new.sprite_name, " floor_number: ", floor_number)
    
    
#endregion


#region instantiate_sprite


#####################################################################################################
##################              Basic Sprite Component                        #######################  
#####################################################################################################

func instantiate_sprite():
    add_to_group("player_sprite")   # for other nodes explicitly referencing this player sprite
    add_to_group("sprites")
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

func set_data(
    current_floor_number: int,
    current_room: int,
    target_floor_number: int,
    sprite_name: String,
    elevator_request_id: int
):
    # This replaces the old 'set_initial_data' from _ready().
    sprite_data_new.current_floor_number = current_floor_number
    sprite_data_new.current_room = current_room
    sprite_data_new.target_floor_number = target_floor_number
    sprite_data_new.sprite_name = sprite_name
    sprite_data_new.elevator_request_id = elevator_request_id

#endregion
