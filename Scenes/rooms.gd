#extends Node2D
#
#there will be many different rooms. 
#We want to use this as a base script/class. 
#The rooms all will have the room state machine, door state machine and the room owner component
#the room functionality will change for each room
#
#
#We have a file with base data for each room (door). it looks like this
#
#script = ExtResource("1")
#doors = Array[Dictionary]([{
#"door_slot": 3,
#"door_type": 3,
#"floor_number": 2,
#"index": 0,
#"is_animated": true,
#"is_visible": true,
#"object_type": "door",
#"owner": 1,
#"room_name": "archive",
#"screen": "screen_archive",
#"tooltip": "Archive",
#"tooltip_image": "archive"
#},  more doors
#
#
#here we have the room index and the initial data for owner, room name etc...
#we can set-up a spawner and create a room scene for each room when the game starts. 
#We would then have to attach a custom room functionality component to each room. 
#
#
#
#
#var = is visible (bool)     ## our goal is to show the room screen only when the player is inside the room
#
### in process function
### if player sprite is in room the room is visible, else room is not visible. 
#
#
#
### player in room function
#
#
#create signal: sprite entered room (sprite_name, room_index) 
#
#connect to signal here and call _on_sprite_entered_room
#
#_on_sprite_entered_room
    #update room state to occupied
    #close room door
    #if sprite_name = player then set visibility to true else false (do this in a separate function updating a global variable for the room)
