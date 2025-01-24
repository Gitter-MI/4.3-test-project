extends Node2D


# 1) Preload or Export references to each sprite scene
@export var player_scene: PackedScene
# @export var ai_scene: PackedScene
# @export var deco_scene: PackedScene

# Optional: a signal if the navigation controller or others rely on a "done" event
signal all_sprites_spawned

func _ready():
    # 2) Perform your spawn logic here or call dedicated functions
    spawn_player()
    #spawn_multiple_ai(5)  # example: spawn 5 AI
    #spawn_decorations(10) # example: spawn 10 decorations    
    
    
    SignalBus.all_sprites_ready.emit()  
    print("all_sprites_ready signal emitted")

func spawn_player():
    var player_instance = player_scene.instantiate()
    player_instance.add_to_group("sprites")
    add_child(player_instance)
    


#func spawn_multiple_ai(count: int):
    #for i in range(count):
        #var ai_instance = ai_scene.instantiate()
        ## Position them differently each time
        ## e.g. ai_instance.position = Vector2(…some coordinates…)
        #add_child(ai_instance)
#
#func spawn_decorations(count: int):
    #for i in range(count):
        #var deco_instance = deco_scene.instantiate()
        ## Place them in the scene
        #add_child(deco_instance)
