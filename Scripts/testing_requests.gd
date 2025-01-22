extends Node

# This script is responsible for adding dummy requests for testing purposes.
var added: int = 0

func add_dummy_requests(_cabin_script: Node) -> void:
    if added == 0:
        # Here we add some sample requests that match the structure 
        # your elevator queue currently needs:

        _cabin_script.add_to_elevator_queue({
            "sprite_name": "Player_A",
            "pick_up_floor": 3,
            "target_floor": 1, 
            "destination_floor": 3,
            "sprite_request_id": 1001
        })
        
        #_cabin_script.add_to_elevator_queue({
            #"sprite_name": "Player_B",
            #"pick_up_floor": 1,
            #"target_floor": 1,
            #"destination_floor": 3,
            #"sprite_request_id": 1002
        #})
        #
        #_cabin_script.add_to_elevator_queue({
            #"sprite_name": "Player_C",
            #"pick_up_floor": 2,
            #"target_floor": 2,
            #"destination_floor": 4,
            #"sprite_request_id": 1003
        #})

        print("Dummy test requests added.")
        added = 1
    else:
        return
