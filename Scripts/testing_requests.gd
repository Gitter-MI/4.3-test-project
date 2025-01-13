extends Node

# This script is responsible for adding dummy requests for testing purposes.

var added: int = 0

func add_dummy_requests(_cabin_script: Node) -> void:
    
    if added == 0:
    
        _cabin_script.add_to_elevator_queue({'target_floor': 2, 'sprite_name': "Player_1"})
        _cabin_script.add_to_elevator_queue({'target_floor': 3, 'sprite_name': "Player_3"})
        _cabin_script.add_to_elevator_queue({'target_floor': 4, 'sprite_name': "Player_4"})
        print("Dummy test requests added.")
        added = 1
    
    else:
        return
