# Marker2DDebug.gd
extends Marker2D

func _ready():
    _draw()

func _draw():
    # Draw a red circle at the marker's local origin
    # draw_circle(Vector2.ZERO, 5, Color(1, 0, 0))  # Radius 5 pixels, red color
    # Optionally, draw a crosshair
    var size = 5
    draw_line(Vector2(-size, 0), Vector2(size, 0), Color(1, 0, 0))
    draw_line(Vector2(0, -size), Vector2(0, size), Color(1, 0, 0))
