extends Node

# This script is responsible for adding dummy requests for testing purposes.


# since the dummy sprites don't reply with a entering signal the 

var added: int = 0

func add_dummy_requests(cabin_script: Node) -> void:
    # If you only want to do this conditionally (e.g. once, or in debug mode), 
    # you can wrap it in an `if is_debug:` check or something similar.
    
    
    
    if added == 0:
    
        cabin_script.add_to_elevator_queue({'target_floor': 2, 'sprite_name': "Player_2"})
        #cabin_script.add_to_elevator_queue({'target_floor': 3, 'sprite_name': "Player_3"})
        #cabin_script.add_to_elevator_queue({'target_floor': 4, 'sprite_name': "Player_4"})
        #print("Dummy test requests added.")
        added = 1
    
    else:
        return
