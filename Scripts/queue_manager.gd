# elevator queue manager script
extends Node


var new_requests: bool = false

var next_request_id: int = 10

'''The queue management functions should ideall all take the same inputs? For example sprite name and request id. '''
# elevator queue: jobs the elevator needs to process
# elevator request queue: requests from sprites to use the elevator. Stored here for pre-processing before adding them to the actual elevator queue
var elevator_queue: Array = []  # Example: [{'pick_up_floor', 'destination_floor', 'sprite_name': "Player_1", 'request_id': 1}, ...]
var elevator_request_queue: Array = [] # Example: [{sprite name, pick up floor, destination floor, current sprite request id}, ...]




func _ready():
    SignalBus.elevator_called.connect(_on_elevator_request)
    # SignalBus.exit_animation_finished.connect(_on_sprite_exiting)

func _on_elevator_request(sprite_name: String, pick_up_floor: int, destination_floor: int, request_id: int) -> void:
    var request_data := {
        "sprite_name": sprite_name,
        "pick_up_floor": pick_up_floor,
        "destination_floor": destination_floor,
        "request_id": request_id
    }
    elevator_request_queue.append(request_data)
    # print("request_data: ", request_data)
    new_requests = true # needs to be reset after adding it to the actual elevator queue



func find_request_index_by_sprite(sprite_name: String) -> int:
    
    '''Searches the elevator_queue for any entry with the same sprite_name'''
    # print("Looking if the sprite already has a request in the elevator queue")
    for i in range(elevator_queue.size()):
        if elevator_queue[i]["sprite_name"] == sprite_name:
            # print("Sprite already has a request in the elevator queue")
            return i
    return -1


func check_if_other_sprites_waiting_on_floor() -> bool:
    
    var request_data = elevator_request_queue[0]
    var waiting_floor = request_data["pick_up_floor"]
    var exclude_sprite_name = request_data["sprite_name"]
    var count_sprites = 0
    
    for req in elevator_queue:
        if req["pick_up_floor"] == waiting_floor and req["sprite_name"] != exclude_sprite_name:
            count_sprites += 1

    return count_sprites > 0




func pre_process_new_elevator_requests() -> void:
    if not new_requests:
        return

    while not elevator_request_queue.is_empty():
        
        print("New Elevator Request Queue: ", elevator_request_queue)
        
        var request_data = elevator_request_queue[0]
        var sprite_name  = request_data["sprite_name"]
        
        var existing_index = find_request_index_by_sprite(sprite_name)

        if existing_index == -1:
            # print("New: Handling a new request")
            handle_new_request(request_data)
        else:
            var others_waiting = check_if_other_sprites_waiting_on_floor()
            
            if not others_waiting:
                # print("New: Update Elevator Queue")
                update_elevator_queue()
            else:
                # print("New: shuffle case - others also waiting on floor")
                shuffle_elevator_queue_with_new_request()

    new_requests = false



func handle_new_request(request_data: Dictionary) -> void:    
    add_to_elevator_queue({
        "sprite_name":       request_data["sprite_name"],
        "pick_up_floor":     request_data["pick_up_floor"],
        "destination_floor": request_data["destination_floor"]
    })






func shuffle_elevator_queue_with_new_request() -> void:
    # 1) Confirm there's a new request to process
    if elevator_request_queue.is_empty():
        return

    # 2) Reference the first pending request directly
    var request_data = elevator_request_queue[0]
    var sprite_name = request_data["sprite_name"]
    var pick_up_floor = request_data["pick_up_floor"]
    var destination_floor = request_data["destination_floor"]
    var sprite_request_id = request_data["request_id"]  # This is the external (incoming) ID

    print("Shuffling elevator queue for sprite:", sprite_name, ", pick_up_floor:", pick_up_floor)
    
    # 3) Remove the old request from this sprite, if it exists in elevator_queue
    var old_index = find_request_index_by_sprite(sprite_name)
    if old_index != -1:
        print("  -> Removing existing request at index:", old_index, "for sprite:", sprite_name)
        elevator_queue.remove_at(old_index)
    else:
        print("  -> No existing request found to remove for sprite:", sprite_name)

    # 4) Build a new request, similar to 'add_to_elevator_queue' logic
    next_request_id += 1
    var new_request = {
        "request_id":         next_request_id,      # internal elevator ID
        "sprite_request_id":  sprite_request_id,    # external sprite request ID
        "sprite_name":        sprite_name,
        "pick_up_floor":      pick_up_floor,
        "destination_floor":  destination_floor
    }

    # 5) Find insertion position behind all requests on the same pick_up_floor
    var insertion_index = -1
    for i in range(elevator_queue.size()):
        if elevator_queue[i].has("pick_up_floor") and elevator_queue[i]["pick_up_floor"] == pick_up_floor:
            insertion_index = i

    if insertion_index == -1:
        push_warning("shuffle_elevator_queue_with_new_request called, but no existing requests on floor %d" % pick_up_floor)
        return

    print("  -> Inserting new request behind index:", insertion_index, ", for floor:", pick_up_floor)

    elevator_queue.insert(insertion_index + 1, new_request)

    # 6) Confirm the request back to the sprite
    SignalBus.elevator_request_confirmed.emit(
        new_request["sprite_name"], 
        new_request["request_id"]
    )

    # 7) Remove this item from elevator_request_queue now that we're done shuffling
    elevator_request_queue.remove_at(0)



func add_to_elevator_queue(request: Dictionary) -> void:    
    next_request_id += 1
    request.request_id = next_request_id
    
    elevator_queue.append(request)
    # print("New: Elevator queue after adding a new request:", elevator_queue)
    
    SignalBus.elevator_request_confirmed.emit(request["sprite_name"], request["request_id"])
  
    elevator_request_queue.remove_at(0)
    # print("New elevator request queue after pre-processing: ", elevator_request_queue)



func update_elevator_queue() -> void:

    var request_data = elevator_request_queue[0]
    var sprite_name = request_data["sprite_name"]
    var new_destination_floor = request_data["destination_floor"]

    var current_destination_floor = elevator_queue[0]["destination_floor"]

    for item in elevator_queue:
        if item.has("sprite_name") and item["sprite_name"] == sprite_name:
            item["destination_floor"] = new_destination_floor
            SignalBus.elevator_request_confirmed.emit(sprite_name, item["request_id"])                        

    elevator_request_queue.remove_at(0)
    # print("elevator_request_queue: ", elevator_request_queue)
    # print("elevator_queue: ", elevator_queue)



func remove_from_elevator_queue(sprite_name: String, request_id: int) -> void:
    # Loop through all requests in elevator_queue
    for i in range(elevator_queue.size()):
        var queue_req = elevator_queue[i]
        
        # Check for matching sprite_name
        if queue_req.has("sprite_name") and queue_req["sprite_name"] == sprite_name:
            
            # Now ensure the request_id also matches
            if queue_req.has("request_id") and queue_req["request_id"] == request_id:
                # Remove the request
                elevator_queue.remove_at(i)
                # print("Removed request for:", sprite_name, "with request_id:", request_id)
                # print("Updated elevator_queue:", elevator_queue)
                return
            else:
                # Found the right sprite but request_id doesn't match
                print("Found sprite:", sprite_name, "but request_id mismatch. Expected:", request_id, "got:", queue_req.get("request_id", "None"))
                # Continue searching in case there's another entry for the same sprite with the correct request_id
    
    # If we finish the loop, no match found
    print("No elevator request found for:", sprite_name, "with request_id:", request_id)
