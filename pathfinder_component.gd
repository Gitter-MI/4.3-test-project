# Pathfinder.gd
extends Node
class_name Pathfinder

'''
Pathfinder 

Invoke when nav / command exists
Or
at target location and stored exists

Invoke from _progress, not from the other functions


```
Sets target and stored position 
Inputs: nav or command, stored position 
Find path from nav [given destination]
Assumes in elevator target is elevator position on destination floor 
***
Requires update to current floor update signal: 
If in elevator transit and moving up then current floor+1

Else normal 
***
```

If nav floor is not current floor 
Set stored position to nav target 
Set target position to curr. floor elevator 
Set nav target to null

If nav floor is current floor 
Set target to nav target 
Set stored position and nav target to null 

If sprite in elevator transit and nav target on the way:
Set target to nav floor elevator 
Set stored position to nav target 
Set nav target to null 

If sprite in elevator transit and nav target is not on the way:
Set target to next floor 
Set stored position to nav target 
Set nav target to null

'''


func _ready():
    # print("Pathfinder component")
    pass
    

func determine_path(sprite_data_new):        
    
    print("determining path for")
    print("sprite_data_new.sprite_name: ", sprite_data_new.sprite_name)
    pass
