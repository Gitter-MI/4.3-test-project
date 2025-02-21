extends Node2D

@export var base_sprite_scene: PackedScene
@export var deco_scene: PackedScene
@export var ai_scene: PackedScene
@export var player_scene: PackedScene


# @export var deco_scene: PackedScene

var deco_definitions = [
    {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze1.png",
        "floor_number": 3,
        "x_percent": 25,
        "name": "PLANT_01"
    },
    {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze2.png",
        "floor_number": 3,
        "x_percent": 50,
        "name": "PLANT_02"
    },
    {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze3.png",
        "floor_number": 2,
        "x_percent": 10,
        "name": "SIGN_01"
    }
    # ... etc. Add as many as you want
]



#{
  #"texture_path": "res://Sprites/plant/gfx_building_Pflanze1.png",
  #"floor_number": 3,
  #"x_percent": 25,
  #"name": "PLANT_01",
  #"custom_scale": 1.5,
  #"z_index": 5
#}



func _ready():
    
    spawn_base_sprite()
    # spawn_player()
    # spawn_ai(1)
    
    spawn_all_decorations()
    
    
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
            8,     # current_floor_number
            -1,    # current_room
            8,     # target_floor_number
            "AI_SPRITE",
            1
        )
        
        add_child(ai_instance)




func spawn_all_decorations():
    for definition in deco_definitions:
        var deco_instance = deco_scene.instantiate()
        
        # 1) Assign the texture from the definition
        var texture_path = definition["texture_path"]
        deco_instance.deco_texture = load(texture_path)
        
        # 2) Now call set_data() so the script knows floor, x percent, name, etc.
        var floor_num = definition["floor_number"]
        var x_percent = definition["x_percent"]
        var sprite_name = definition["name"]
        deco_instance.set_data(x_percent, floor_num, sprite_name)
        
        # 3) Finally, add to the scene
        add_child(deco_instance)



    
        
