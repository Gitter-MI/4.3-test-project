# sprite_base.gd
extends Area2D

@onready var navigation_controller := get_tree().get_root().get_node("Main/Navigation_Controller")
@onready var cabin := get_tree().get_root().get_node("Main/Magical_Elevator")
@onready var animation_controller := $AnimatedSprite2D
@onready var state_manager : StateComponent = $State_Component
@onready var pathfinder : PathfinderComponent = $Pathfinder_Component
@onready var movement : MovementComponent = $Movement_Component
@onready var elevator_movement : ElevatorComponent = $Elevator_Movement
# @export var elevator_movement: ElevatorComponent

const SpriteDataScript = preload("res://Data/SpriteData_new.gd")
var sprite_data_new: Resource = SpriteDataScript.new()

func _ready():
    instantiate_sprite()
    connect_to_signals()    
    set_initial_position()
    z_index = 1

    elevator_movement.setup(self, sprite_data_new)



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
        animation_controller.animate(sprite_data_new)

    if active_state == sprite_data_new.ActiveState.ELEVATOR:
        # print("process elevator actions")
        elevator_movement.process_elevator_actions()


#region Elevator Movement

func call_elevator() -> void:
    elevator_movement.call_elevator()

func enter_elevator():
    elevator_movement.enter_elevator()

func on_sprite_entered_elevator():
    elevator_movement.on_sprite_entered_elevator()

func exit_elevator():
    elevator_movement.exit_elevator()

func on_sprite_exited_elevator():
    elevator_movement.on_sprite_exited_elevator()
        
#endregion
        
        
#region connect_to_signals
func connect_to_signals():
    SignalBus.adjusted_navigation_command.connect(_on_adjusted_navigation_command)
    SignalBus.floor_area_entered.connect(_on_floor_area_entered)
    SignalBus.elevator_request_confirmed.connect(_on_elevator_request_confirmed)
    SignalBus.elevator_waiting_ready.connect(_on_elevator_waiting_ready_received)    
    SignalBus.elevator_arrived_at_destination.connect(_on_elevator_at_destination) 
    SignalBus.elevator_position_updated.connect(_on_elevator_ride)
    

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
    
# Signal handlers that delegate to elevator_movement
func _on_elevator_request_confirmed(elevator_request_data: Dictionary, elevator_ready_status: bool) -> void:
    elevator_movement.on_elevator_request_confirmed(elevator_request_data, elevator_ready_status)

func _on_elevator_waiting_ready_received(elevator_request_data: Dictionary, elevator_ready_status: bool) -> void:
    elevator_movement.on_elevator_waiting_ready_received(elevator_request_data, elevator_ready_status)

func _on_elevator_ride(elevator_pos: Vector2, sprite_name: String) -> void:
    elevator_movement.on_elevator_ride(elevator_pos, sprite_name)

func _on_elevator_at_destination(incoming_sprite_name: String):
    elevator_movement.on_elevator_at_destination(incoming_sprite_name)
    
#endregion


#region instantiate_sprite

func instantiate_sprite():
    add_to_group("player_sprite")   # for other nodes explicitly referencing this player sprite, needs to be adjusted because we want to use this sprite as base for player and others
    add_to_group("sprites")
    update_sprite_dimensions()
    update_collision_shape()    

func update_sprite_dimensions():
    var idle_texture = $AnimatedSprite2D.sprite_frames.get_frame_texture("idle", 0)
    if idle_texture:
        sprite_data_new.sprite_width = idle_texture.get_width()
        sprite_data_new.sprite_height = idle_texture.get_height()
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
