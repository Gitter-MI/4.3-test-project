# sprite_base.gd
extends Area2D

@onready var navigation_controller := get_tree().get_root().get_node("Main/Navigation_Controller")
@onready var cabin := get_tree().get_root().get_node("Main/Magical_Elevator")

@export var state_manager: Node
@export var pathfinder: Node
const SpriteDataScript = preload("res://Data/SpriteData_new.gd")
var sprite_data_new: Resource = SpriteDataScript.new()

const SCALE_FACTOR = 2.3
var last_elevator_request: Dictionary = {"sprite_name": "", "floor_number": -1}
var previous_elevator_position: Vector2 = Vector2.ZERO


'''Testing'''
var initial_x: float
var timer: Timer
var prev_floor: int = -1  # Holds the previous random floor number



func _ready():
    # print("deco ready")
    # print("sprite_data_new: ", sprite_data_new)
    # sprite_data_new = SpriteDataScript.new()
    instantiate_sprite()
    connect_to_signals()    
    set_initial_position()

  
    '''Testing'''
    #randomize()  # Seed the RNG
    #
    ## Store the initial x-coordinate from sprite_data_new
    #initial_x = sprite_data_new.current_position.x
    #
    ## Create and configure the Timer node to call _on_timer_timeout every 2 seconds
    #timer = Timer.new()
    #timer.wait_time = 1.0  # Change to 2.0 seconds for production; was 0.05 for testing
    #timer.one_shot = false
    #timer.autostart = true
    #add_child(timer)
    #timer.timeout.connect(_on_timer_timeout)

'''Testing'''

func _on_timer_timeout() -> void:
    # Calculate a new x position by adding a random offset (here between -250 and 250) to the initial x
    var offset: float = randf_range(-250.0, 250.0)
    var new_x: float = initial_x + offset
    var new_position: Vector2 = Vector2(new_x, sprite_data_new.current_position.y)
    
    # Generate a random floor between 1 and 10.
    var random_floor: int = randi() % 4
    # Ensure that the new random floor is not the same as the previous one.
    #while random_floor == prev_floor:
        #random_floor = randi() % 3
    # Store the current random floor for the next call.
    prev_floor = random_floor
    
    # Call the navigation command with the new random floor and position.
    navigation_controller._on_navigation_command(sprite_data_new.sprite_name, random_floor, -1, "player_input", new_position)



var stored_position_updated: bool = false


func _process(delta: float) -> void:   
    
    
    stored_position_updated = pathfinder.determine_path(sprite_data_new)
    # print("stored position updated? ", stored_position_updated)
    
    # print("process state") 
    # print("sprite script calls process_state")
    state_manager.process_state(sprite_data_new)
    var active_state = sprite_data_new.get_active_state()
    
    if active_state == sprite_data_new.ActiveState.MOVEMENT:   
        # print("process movement")     
        move_sprite(delta)
        _animate_sprite()

    if active_state == sprite_data_new.ActiveState.ELEVATOR:
        # print("process elevator actions")
        _process_elevator_actions()

        

func _process_elevator_actions() -> void:
    # print(" in elevator state in player script")
    match sprite_data_new.elevator_state:
        
        sprite_data_new.ElevatorState.CALLING_ELEVATOR:     
                   
            if not sprite_data_new.elevator_requested or stored_position_updated:                
                #print("sprite_data_new.elevator_requested: ", sprite_data_new.elevator_requested)
                #print("stored_position_updated: ", stored_position_updated)                
                call_elevator()        
                
                
                
                
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:     
            if stored_position_updated:
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
    if not confirm_sprite_can_interact_with_elevator():
        push_warning("Sprite ", sprite_data_new.sprite_name, " cannot interact with elevator: returning")
        get_tree().paused = true
        return

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
    var incoming_sprite_name = elevator_request_data["sprite_name"]
    var incoming_request_id = elevator_request_data["request_id"]
    
    if not incoming_sprite_name == sprite_data_new.sprite_name:        
        return
    
    # print("Sprite ", sprite_data_new.sprite_name, " received the request confirmation.")    
    sprite_data_new.elevator_request_id = incoming_request_id
    sprite_data_new.elevator_request_confirmed = true
    
    if elevator_ready_status:
        # print("The elevator is ready for ", sprite_data_new.sprite_name)
        sprite_data_new.elevator_ready = true
        sprite_data_new.defer_input = true
        # state_manager._process_elevator_state(sprite_data_new) ## update sprite state immediately
        ## consider emitting the signal from inside the state specific functions
        SignalBus.entering_elevator.emit(sprite_data_new.sprite_name)
        '''ensure sprite is locked down for the entering period'''
        






#func _on_elevator_request_confirmed(incoming_sprite_name: String, request_id: int) -> void:
    #
    ## print("destination_floor of the confirmed request: ", destination_floor)
    ## print("destination_floor of the sprite: ", sprite_data_new.stored_target_floor)
    #
    #if incoming_sprite_name == sprite_data_new.sprite_name:            
        #sprite_data_new.elevator_request_id = request_id
        ## print("Elevator request confirmed. Request ID =", request_id)            
        #sprite_data_new.elevator_request_confirmed = true        
        ## check if a state update is needed
        #state_manager._process_elevator_state(sprite_data_new)
        #
        #request_elevator_ready_status()

func confirm_sprite_can_interact_with_elevator() -> bool:
    #print("confirm_sprite_can_interact_with_elevator: ")
    var current_position: Vector2 = sprite_data_new.current_position

    # Retrieve the elevator data from the Navigation Controller using the elevator_request_id.
    var elevator_data = navigation_controller.elevators.get(sprite_data_new.current_floor_number)
    if elevator_data == null:
        #print("Elevator not found for id: ", sprite_data_new.elevator_request_id)
        return false

    # Get the center position of the elevator.
    var elevator_center: Vector2 = elevator_data["position"]

    # Check if the sprite is at the elevator's x position (ignoring y-coordinate).
    if not is_equal_approx(current_position.x, elevator_center.x):
        #print("Sprite is not at the elevator's x position: ", sprite_data_new.sprite_name)
        # get_tree().paused = true
        return false

    # Check if the stored target floor is valid.
    if sprite_data_new.stored_target_floor == -1 and not sprite_data_new.target_room == -2:
        #print("sprite ", sprite_data_new.sprite_name, " does not have a stored taget floor")
        return false

    # Check if the sprite is already on the target floor.
    if sprite_data_new.current_floor_number == sprite_data_new.stored_target_floor:
        #print("sprite ", sprite_data_new.sprite_name, " has current floor == taget floor")
        return false

    # Ensure the sprite's active state is ELEVATOR.
    var active_state = sprite_data_new.get_active_state()
    if active_state != sprite_data_new.ActiveState.ELEVATOR:
        #print("Sprite is not in elevator active state")
        return false

    # Retrieve elevator sub-state correctly as an ENUM (not a dictionary).
    var active_sub_state = sprite_data_new.elevator_state

    # Ensure the sub-state is either WAITING_FOR_ELEVATOR or CALLING_ELEVATOR.
    match active_sub_state:
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR, sprite_data_new.ElevatorState.CALLING_ELEVATOR:
            #print("sprite ", sprite_data_new.sprite_name, " can interact with the elevator")
            return true  # Valid states, return true

    # If we reach here, the sprite is in an invalid state.
    #print("Invalid elevator sub-state:", active_sub_state)
    return false


func request_elevator_ready_status() -> void:
    if not confirm_sprite_can_interact_with_elevator():
        return
    
    # If everything is valid, emit the signal.
    SignalBus.request_elevator_ready_status.emit(sprite_data_new.sprite_name, sprite_data_new.elevator_request_id)
  
            

func _on_elevator_ready(incoming_sprite_name: String, request_id: int):   
    #print("-----------PLAYER-----------")
    #print("ready signal received!")
    #print("ready signal request id: ", request_id)
    #print("sprite data request id: ", sprite_data_new.elevator_request_id)       
    if incoming_sprite_name != sprite_data_new.sprite_name:
        return
        
    if request_id != sprite_data_new.elevator_request_id:
        SignalBus.request_skippable.emit(sprite_data_new.sprite_name, sprite_data_new.elevator_request_id)
        return           
    
        
    if sprite_data_new.elevator_state != sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR and not sprite_data_new.ElevatorState.CALLING_ELEVATOR and not sprite_data_new.current_floor_number == sprite_data_new.stored_target_floor:    
        # print("sprite state is not waiting for elevator")
        
        SignalBus.request_skippable.emit(sprite_data_new.sprite_name, sprite_data_new.elevator_request_id)
        return
    # print("sprite_data_new.elevator_ready = true")     
    sprite_data_new.elevator_ready = true
    sprite_data_new.defer_input = true


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
        sprite_data_new.elevator_destination_reached = true

#func exit_elevator():
    #_animate_sprite()
    #var current_anim = $AnimatedSprite2D.animation
    #if current_anim == "exit" and sprite_data_new.elevator_destination_reached:
        #z_index = 0
        #SignalBus.exit_animation_finished.emit(sprite_data_new.sprite_name, sprite_data_new.elevator_request_id)
        #sprite_data_new.exited_elevator = true
        #sprite_data_new.set_target_position(
            #sprite_data_new.stored_target_position,
            #sprite_data_new.stored_target_floor,
            #sprite_data_new.stored_target_room
        #)
        #sprite_data_new.reset_stored_data()

func exit_elevator():    
    if not sprite_data_new.exiting_elevator:
        sprite_data_new.exiting_elevator = true
        _animate_sprite() 
    else:
        return
 

func on_sprite_exited_elevator():
    z_index = 0
    SignalBus.exit_animation_finished.emit(sprite_data_new.sprite_name, sprite_data_new.elevator_request_id)
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
#endregion


#region Sprite Movement

func move_sprite(delta: float) -> void:
    if sprite_data_new.movement_state == sprite_data_new.MovementState.WALKING:
        move_towards_position(sprite_data_new.target_position, delta)

func move_towards_position(target_position: Vector2, delta: float) -> void:    
    target_position.y = sprite_data_new.current_position.y # Force horizontal-only movement by locking the target's Y to current_position.y
    
    var direction = (target_position - sprite_data_new.current_position).normalized()
    var distance = sprite_data_new.current_position.distance_to(target_position)
    
    if distance > 13.0:   # Speed / FPS
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
    SignalBus.elevator_ready.connect(_on_elevator_ready)
    SignalBus.elevator_ready.connect(_on_elevator_at_destination)
    SignalBus.elevator_position_updated.connect(_on_elevator_ride)
    SignalBus.queue_reordered.connect(_on_queue_reordered)
    
    $AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:    
    var anim_name = $AnimatedSprite2D.animation
    
    match anim_name:
        "enter":
            if sprite_data_new.elevator_ready:
                on_sprite_entered_elevator()

        "exit":
            if sprite_data_new.elevator_destination_reached:
                on_sprite_exited_elevator()        
            
            #sprite_data_new.entered_elevator = true
            #SignalBus.enter_animation_finished.emit(sprite_data_new.sprite_name, sprite_data_new.stored_target_floor)
            ## Maybe switch to idle or next state
            #_animate_sprite()

func _on_queue_reordered(sprite_name, request_id):
    
    if sprite_data_new.sprite_name == sprite_name and sprite_data_new.elevator_request_id == request_id:    
        sprite_data_new.elevator_ready = true
        state_manager.process_state(sprite_data_new)
        _process_elevator_actions()
        # request_elevator_ready_status()
    
    else:
        return
    

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
