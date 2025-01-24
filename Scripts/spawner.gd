extends Node2D


@export var ai_scene: PackedScene
@export var player_scene: PackedScene

# @export var deco_scene: PackedScene




func _ready():
    spawn_player()
    spawn_ai(1)
    #spawn_decorations(10) # example: spawn 10 decorations    
    
    
    SignalBus.all_sprites_ready.emit()  
    print("all_sprites_ready signal emitted")

func spawn_player():
    var player_instance = player_scene.instantiate()
    player_instance.add_to_group("sprites")
    add_child(player_instance)
    


func spawn_ai(count: int):
    for i in range(count):
        var ai_instance = ai_scene.instantiate()
        ai_instance.add_to_group("sprites")
        add_child(ai_instance)
#
#func spawn_decorations(count: int):
    #for i in range(count):
        #var deco_instance = deco_scene.instantiate()
        ## Place them in the scene
        #add_child(deco_instance)
