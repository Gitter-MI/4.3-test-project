extends Camera2D

@export var screen_center_x: float = 960.0  # Replace this with half the screen width.

func _process(_delta: float) -> void:
    # Keep the x-position of the camera centered on the screen
    position.x = screen_center_x
    
    # Get the player node dynamically and follow its y-position
    var player = get_parent().get_node("%Player")
    if player:
        position.y = player.position.y
