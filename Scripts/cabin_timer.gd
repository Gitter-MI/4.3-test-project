# cabin_timer.gd
# This component handles the elevator waiting timer functionality
# Responsibilities:
# - Manages the elevator waiting timer
# - Emits a signal when the timer expires
# - Provides methods to start and stop the timer
# - Handles timeout logic
extends Node

# Signal emitted when the timer expires
signal timeout_expired

# The actual Timer node
var cabin_timer: Timer

# Default wait time in seconds
var wait_time: float = 2.0

# References to required components
var cabin_data
var queue_manager

func _ready():
    setup_cabin_timer(wait_time)

# Sets up the timer with the specified wait time
func setup_cabin_timer(timer_wait_time: float) -> void:
    wait_time = timer_wait_time
    var new_timer = Timer.new()
    new_timer.one_shot = true
    new_timer.wait_time = wait_time
    new_timer.timeout.connect(_on_cabin_timer_timeout)    
    add_child(new_timer)
    cabin_timer = new_timer

# Starts the waiting timer if there are requests in the queue
func start_waiting_timer() -> void:
    if not cabin_timer.is_stopped():
        push_warning("cabin timer already started, returning immediately.")
        return
        
    # Only start the timer if there's at least one request for the current floor.
    if not queue_manager.elevator_queue.is_empty():
        cabin_timer.start()

# Stops the waiting timer if it's running
func stop_waiting_timer() -> void:
    if cabin_timer == null:
        push_warning("cabin timer not set-up in stop_waiting_timer")
        return

    if cabin_timer.is_stopped():
        # push_warning("cabin timer is not running; nothing to stop.")
        return
        
    cabin_timer.stop()

# Returns whether the timer is currently running
func is_timer_running() -> bool:
    if cabin_timer == null:
        return false
    return !cabin_timer.is_stopped()

# Called when the timer expires
func _on_cabin_timer_timeout() -> void:    
    # Check if the elevator is in a valid state for the timer to expire
    if cabin_data.elevator_state != cabin_data.ElevatorState.WAITING and cabin_data.elevator_state != cabin_data.ElevatorState.DEPARTING:
        push_warning("Timer timed out but elevator state is neither WAITING nor DEPARTING.")
        return

    if queue_manager.elevator_queue.is_empty():
        push_warning("Elevator queue is empty on timer timeout.")
        return
    
    # Emit the timeout signal to let other components know
    emit_signal("timeout_expired")
    
    # Handle the timeout by removing the request
    queue_manager.remove_request_on_waiting_timer_timeout(cabin_data.current_floor)
