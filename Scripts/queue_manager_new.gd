# elevator queue manager script
extends Node

var next_request_id: int = 10  # for the actual elevator_queue
var elevator_queue: Array = []  # Example: [{'pick_up_floor', 'destination_floor', 'sprite_name': "Player_1", 'request_id': 1}, ...]

func _ready():
    '''Test cases for elevator queue on sprite request'''
    '''1) Add request in ready: for overwrite, activate waiting/idle criterion in elevator script categorize function''' 
    '''2) Add request when adding a request for the Player for shuffle, deactivate waiting/idle criterion in elevator script categorize function'''
    '''3) No dummy requests: Add and update'''
    pass

    

    #var dummy_request: Dictionary = {
        #"pick_up_floor": 1,
        #"destination_floor": 2,
        #"sprite_name": "Test_Sprite",
        #"request_id": 0
    #}
    #elevator_queue.append(dummy_request)
    
    
    
func does_sprite_have_a_request_in_queue(sprite_name: String) -> bool:
    for request in elevator_queue:        
        if request["sprite_name"] == sprite_name:
            return true
    return false
    

func does_request_id_match(sprite_elevator_request_id: int) -> bool:        
    if sprite_elevator_request_id == -1:
        return false
    else:
        return true


func add_to_elevator_queue(request: Dictionary) -> Dictionary:    
    next_request_id += 1
    request.request_id = next_request_id 
    elevator_queue.append(request)
        
    return request    

func overwrite_elevator_request(request: Dictionary) -> Dictionary:
    next_request_id += 1
    request.request_id = next_request_id 
    elevator_queue[0] = request
    return request

func update_elevator_request(request: Dictionary) -> Dictionary:
    for i in range(elevator_queue.size()):        
        if elevator_queue[i]["sprite_name"] == request["sprite_name"]:
            next_request_id += 1
            request.request_id = next_request_id
            elevator_queue[i] = request
            return request
    return request

func shuffle(request: Dictionary) -> Dictionary:
    # Edge case: the sprite has walked away and will now be repositioned to the end of the queue on the current floor.
    # For now, we simply print a message. Return the incoming request.
    print("shuffling queue")
    next_request_id += 1
    request.request_id = next_request_id 
    return request

    
