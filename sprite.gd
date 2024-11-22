extends Node2D

# Movement configuration
const MOVE_SPEED: float = 350.0  # Pixels per second
const RESET_POSITION_X: float = 140.0  # X position to reset to
const MAX_POSITION_X: float = 1000.0  # X position limit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ensure initial position is set
	position.x = RESET_POSITION_X
	position.y = 300

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Move sprite to the right
	position.x += MOVE_SPEED * delta
	
	# Check if sprite has reached the position limit
	if position.x >= MAX_POSITION_X:
		position.x = RESET_POSITION_X
