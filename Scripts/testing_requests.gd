extends Node

# This script is responsible for adding dummy requests for testing purposes.

var added: int = 0

func add_dummy_requests(_cabin_script: Node) -> void:
    
    if added == 0:
    
        _cabin_script.add_to_elevator_queue({'target_floor': 12, 'sprite_name': "Player_A"})
        #_cabin_script.add_to_elevator_queue({'target_floor': 3, 'sprite_name': "Player_B"})
        #_cabin_script.add_to_elevator_queue({'target_floor': 4, 'sprite_name': "Player_C"})
        print("Dummy test requests added.")
        added = 1
    
    else:
        return
