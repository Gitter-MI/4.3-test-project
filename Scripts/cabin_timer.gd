# cabin_timer.gd
extends Node

@onready var timer: Timer = $Timer

# We can expose how long we want to wait
# so it can be configured from the editor or set from the parent.
@export var default_wait_time := 2.0

# References to other needed nodes (if you need them).
# You can either get these dynamically or have them passed in from the parent.
var queue_manager: Node
var cabin_data: Node

func _ready() -> void:
    # One-shot means it only times out once per start()
    timer.one_shot = true
    timer.wait_time = default_wait_time

    # Connect the timeout signal to our local function
    timer.timeout.connect(_on_cabin_timer_timeout)

func set_dependencies(_queue_manager: Node, _cabin_data: Node) -> void:
    # This is a helper function so the parent can give references
    queue_manager = _queue_manager
    cabin_data = _cabin_data

func set_wait_time(wait_time: float) -> void:
    timer.wait_time = wait_time

func start_timer() -> void:
    # Make sure we reset it if needed
    timer.stop()
    # If there's something in the queue, start the timer
    if queue_manager and not queue_manager.elevator_queue.is_empty():
        timer.start()

func stop_timer() -> void:
    timer.stop()

func _on_cabin_timer_timeout() -> void:
    # Example logic – remove top request, etc.
    if queue_manager and not queue_manager.elevator_queue.is_empty():
        var removed_request = queue_manager.elevator_queue[0]
        var sprite_name = removed_request.get("sprite_name", "")
        var request_id  = removed_request.get("request_id", -1)  
        
        # You might need to call some cabin_data or parent function here.
        # e.g. cabin_data.reset_elevator(sprite_name, request_id)
        cabin_data.reset_elevator(sprite_name, request_id)

        # Then check the queue
        cabin_data.check_elevator_queue()
    else:
        print("Elevator queue is empty, nothing to remove.")
