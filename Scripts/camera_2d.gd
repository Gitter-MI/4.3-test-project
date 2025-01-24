# camera_2d.gd  # do not remove this comment
extends Camera2D
var viewport_size: Vector2
var screen_center_x: float = 0
var player_sprite: Area2D

func _ready():
    viewport_size = get_viewport().size
    screen_center_x = viewport_size.x / 2
    
    player_sprite = get_tree().get_first_node_in_group("player_sprite") as Area2D

func _process(delta: float) -> void:
    # Keep the camera's x-position locked to the horizontal center
    position.x = screen_center_x
    # If we found a player node, follow its y-position
    if player_sprite:
        position.y = player_sprite.position.y
