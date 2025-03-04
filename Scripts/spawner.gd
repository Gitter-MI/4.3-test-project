extends Node2D

@export var base_sprite_scene: PackedScene
@export var deco_scene: PackedScene
@export var ai_scene: PackedScene
@export var player_scene: PackedScene


var deco_definitions = [
    {
        "texture_path": "res://Sprites/plant/gfx_building_standlight.png",
        "floor_number": 0,
        "x_percent": 40,
        "name": "Standlight_0_1"
    },
    {
        "texture_path": "res://Sprites/plant/gfx_building_standlight.png",
        "floor_number": 0,
        "x_percent": 60,
        "name": "Standlight_0_2"
    },
    ###########
    {
        "texture_path": "res://Sprites/plant/gfx_building_picture2.png",
        "floor_number": 1,
        "x_percent": 80,
        "name": "Picture"
    },   
    {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze3.png",
        "floor_number": 1,
        "x_percent": 25,
        "name": "Plant_1_1"
    },
    {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze2.png",
        "floor_number": 1,
        "x_percent": 75,
        "name": "Plant_1_2"
    },
 
    {
        "texture_path": "res://Sprites/plant/gfx_building_Wandlampe.png",
        "floor_number": 1,
        "x_percent": 25,
        "name": "WallLamp"
    },
    ###########

    ###########
     {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze4.png",
        "floor_number": 3,
        "x_percent": 75,
        "name": "Plant_3_1"
    },
     {
        "texture_path": "res://Sprites/plant/gfx_building_credits.png",
        "floor_number": 3,
        "x_percent": 85,
        "name": "Picture"
    },
  ###########
    ## no deco sprites on floor 4
  ###########
     {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze5.png",
        "floor_number": 5,
        "x_percent": 25,
        "name": "Plant_5_1"
    },

     {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze1.png",
        "floor_number": 5,
        "x_percent": 75,
        "name": "Plant_5_2"
    },
     {
        "texture_path": "res://Sprites/plant/gfx_building_Wandlampe.png",
        "floor_number": 5,
        "x_percent": 75,
        "name": "WallLamp"
    },
     {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze1.png",
        "floor_number": 6,
        "x_percent": 75,
        "name": "Plant_6_1"
    },
    ###########
    ## no deco sprites on floor 7
    ###########
     {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze1.png",
        "floor_number": 8,
        "x_percent": 25,
        "name": "Plant_8_1"
    },
    ###########
      {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze1.png",
        "floor_number": 9,
        "x_percent": 75,
        "name": "Plant_9_1"
    },
     {
        "texture_path": "res://Sprites/plant/gfx_building_Wandlampe.png",
        "floor_number": 9,
        "x_percent": 75,
        "name": "WallLamp"
    },   
###########
    {
        "texture_path": "res://Sprites/plant/gfx_building_picture1.png",
        "floor_number": 10,
        "x_percent": 85,
        "name": "Picture"
    },   
    ###########

    {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze1.png",
        "floor_number": 11,
        "x_percent": 25,
        "name": "Plant_11_1"
    },
    ###########
    {
        "texture_path": "res://Sprites/plant/gfx_building_picture2.png",
        "floor_number": 12,
        "x_percent": 90,
        "name": "Picture"
    },   
    {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze5.png",
        "floor_number": 12,
        "x_percent": 25,
        "name": "Plant_12_1"
    },
    {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze4.png",
        "floor_number": 12,
        "x_percent": 80,
        "name": "Plant_12_2"
    },  
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
        1,    # current_floor_number
        -1,   # current_room
        1,    # target_floor_number
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
        var x_percent: int = definition["x_percent"]
        var sprite_name = definition["name"]
        deco_instance.set_data(x_percent, floor_num, sprite_name)
        
        # 3) Finally, add to the scene
        add_child(deco_instance)



    
        
