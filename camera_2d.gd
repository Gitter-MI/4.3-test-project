# camera_2d.gd # do not remove this comment
extends Camera2D

var viewport_size: Vector2
var screen_center_x: float = 0

func _ready():
    viewport_size = get_viewport().size
    screen_center_x = viewport_size.x / 2

func _process(_delta: float) -> void:
    # Keep the x-position of the camera centered on the screen
    position.x = screen_center_x
    
    # Get the player node dynamically and follow its y-position
    var player = get_parent().get_node("%Player")
    if player:
        position.y = player.position.y
