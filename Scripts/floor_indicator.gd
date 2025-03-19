extends Node2D

@onready var red_square = $RedSquare
@onready var white_rectangle = $WhiteRectangle

func _ready():
    pass

func update_indicator_position(floor_number: int):
    var rect_width = white_rectangle.texture.get_size().x
    var half_rect_width = rect_width * 0.5
    var left_edge_x = white_rectangle.position.x - half_rect_width
    var floors_count = 14
    var spacing = rect_width / float(floors_count - 1)  # distance per floor
    var new_x = left_edge_x + floor_number * spacing
    new_x -= (red_square.texture.get_size().x * 0.5)
    var new_y = white_rectangle.position.y
    red_square.position = Vector2(new_x, new_y) 
