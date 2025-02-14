extends Node2D

@export var base_sprite_scene: PackedScene
@export var deco_scene: PackedScene
@export var ai_scene: PackedScene
@export var player_scene: PackedScene


# @export var deco_scene: PackedScene




func _ready():
    
    spawn_base_sprite()
    # spawn_player()
    spawn_ai(1)
    # spawn_decorations(1)
    
    
    SignalBus.all_sprites_ready.emit()  
    # print("all_sprites_ready signal emitted")


func spawn_base_sprite():
    var base_sprite_instance = base_sprite_scene.instantiate()
    base_sprite_instance.add_to_group("sprites")

    base_sprite_instance.set_data(
        2,    # current_floor_number
        -1,   # current_room
        2,    # target_floor_number
        "Player", # sprite_name
        1     # elevator_request_id
    )

    add_child(base_sprite_instance)



func spawn_player():
    var player_instance = player_scene.instantiate()
    player_instance.add_to_group("sprites")
    
    # Directly call set_data with the desired initial values:
    player_instance.set_data(
        2,    # current_floor_number
        -1,   # current_room
        2,    # target_floor_number
        "Player", # sprite_name
        1     # elevator_request_id
    )

    add_child(player_instance)


func spawn_ai(count: int):
    for i in range(count):
        var ai_instance = ai_scene.instantiate()
        ai_instance.add_to_group("sprites")
        
        # Different or same defaults for AIs:
        ai_instance.set_data(
            3,     # current_floor_number
            -1,    # current_room
            3,     # target_floor_number
            "AI_SPRITE",
            1
        )
        
        add_child(ai_instance)


func spawn_decorations(count: int):
    for i in range(count):
        var deco_instance = deco_scene.instantiate()
        deco_instance.add_to_group("sprites")
        
        # Different or same defaults for AIs:
        deco_instance.set_data(
            3,     # current_floor_number
            -1,    # current_room
            3,     # target_floor_number
            "DECO_SPRITE",
            1
        )
        
        add_child(deco_instance)
    
        
