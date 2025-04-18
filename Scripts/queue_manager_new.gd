# elevator queue manager script
extends Node

var next_request_id: int = 10  # starts at ten because the sprites are initialized with request 1. Can be changed later, no biggie
var elevator_queue: Array = []  # Example: [{'pick_up_floor', 'destination_floor', 'sprite_name': "Player_1", 'request_id': 1}, ...]

func _ready():
    '''Test cases for elevator queue on sprite request'''
    '''1) Add request in ready: for overwrite, activate waiting/idle criterion in elevator script categorize function''' 
    '''2) Add request when adding a request for the Player for shuffle, deactivate waiting/idle criterion in elevator script categorize function'''
    '''3) No dummy requests: Add and update'''
    #var dummy_request_three: Dictionary = {
        #"pick_up_floor": 3,
        #"destination_floor": 3,
        #"sprite_name": "TEST_Player",
        #"request_id": 0
    #}
    #elevator_queue.append(dummy_request_three)
    #var dummy_request_four: Dictionary = {
        #"pick_up_floor": 3,
        #"destination_floor": 3,
        #"sprite_name": "TEST_SPRITE", #AI_SPRITE
        #"request_id": 0
    #}
    #elevator_queue.append(dummy_request_four)  
    #var dummy_request_five: Dictionary = {
        #"pick_up_floor": 4,
        #"destination_floor": 4,
        #"sprite_name": "TEST_SPRITE_2", #AI_SPRITE
        #"request_id": 0
    #}
    #elevator_queue.append(dummy_request_five)  
    #var dummy_request_six: Dictionary = {
        #"pick_up_floor": 3,
        #"destination_floor": 3,
        #"sprite_name": "TEST_SPRITE", #AI_SPRITE
        #"request_id": 0
    #}
    #elevator_queue.append(dummy_request_six)  
    pass


#region Cabin Wait Timer
    
func remove_request_on_waiting_timer_timeout(current_floor: int) -> void:
    # print("in remove_request_on_waiting_timer_timeout")
    while elevator_queue.size() > 0 and elevator_queue[0]["pick_up_floor"] == current_floor:
        remove_request_from_queue()    
    
#endregion


func remove_request_from_queue() -> void:
    # print("in remove_request_from_queue")
    if elevator_queue.is_empty():
        push_warning("Elevator queue is empty. Cannot remove first request.")
        return
        
    # print("Removing request: ", elevator_queue[0])
    elevator_queue.remove_at(0)
    return




#region Process new requests
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
    
    # print("add to elevator queue")
    request.request_id = get_next_request_id()
    elevator_queue.append(request)
    #var dummy_request: Dictionary = {
        #"pick_up_floor": 3,
        #"destination_floor": 2,
        #"sprite_name": "Test_Sprite",
        #"request_id": 0
    #}
    #elevator_queue.append(dummy_request)   
    #var dummy_request_two: Dictionary = {
        #"pick_up_floor": 4,
        #"destination_floor": 2,
        #"sprite_name": "Test_Sprite_two",
        #"request_id": 0
    #}
    #elevator_queue.append(dummy_request_two)   
    return request

func overwrite_elevator_request(request: Dictionary) -> Dictionary:    
    request.request_id = get_next_request_id()
    elevator_queue[0] = request
    return request
    

func update_elevator_request(request: Dictionary) -> Dictionary:
    for i in range(elevator_queue.size()):        
        if elevator_queue[i]["sprite_name"] == request["sprite_name"]:
            request.request_id = get_next_request_id()
            elevator_queue[i] = request
            return request
    return request
    

func shuffle(request: Dictionary) -> Dictionary:    
    var pick_up_floor = request["pick_up_floor"]
    var sprite_name   = request["sprite_name"]
    var same_floor_count = count_requests_for_floor(pick_up_floor)    
    if same_floor_count == 1:        
        return update_elevator_request(request)
    var old_index = find_request_index_by_sprite(sprite_name)
    elevator_queue.remove_at(old_index)    
    request.request_id = get_next_request_id()
    var insertion_index = find_last_request_index_for_floor(pick_up_floor)    
    elevator_queue.insert(insertion_index + 1, request)
    return request
    

func move_request_to_top(sprite_name: String) -> void:
    var index = find_request_index_by_sprite(sprite_name)
    var request = elevator_queue[index]
    elevator_queue.remove_at(index)
    elevator_queue.insert(0, request)


func find_request_index_by_sprite(sprite_name: String) -> int:    
    var request_index: int
    for i in range(elevator_queue.size()):
        if elevator_queue[i]["sprite_name"] == sprite_name:
            request_index = i                
    return request_index    


func count_requests_for_floor(floor_number: int) -> int:    
    var request_count: int = 0
    for i in range(elevator_queue.size()):
        if elevator_queue[i]["pick_up_floor"] == floor_number:
            request_count += 1  
    return request_count
    
    
func find_last_request_index_for_floor(floor_number: int) -> int:    
    var index: int = -1
    for i in range(elevator_queue.size()):
        if elevator_queue[i]["pick_up_floor"] == floor_number:
            index = i
    return index
    
    
func get_next_request_id() -> int:
    next_request_id += 1
    return next_request_id 
#endregion
