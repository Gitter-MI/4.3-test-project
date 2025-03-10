This file is a merged representation of a subset of the codebase, containing files not matching ignore patterns, combined into a single document by Repomix.
The content has been processed where comments have been removed.

# File Summary

## Purpose
This file contains a packed representation of the entire repository's contents.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Files matching these patterns are excluded: .aider.tags.cache.v3/, .git/**, .godot/**, Building/**, docs/**, new_assets/**, Sprites/**, .gitattributes, .gitignore, **/*.tmp, **/*.bak, **/*.uid, to-do.txt, **/*.tscn
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Code comments have been removed from supported file types

## Additional Info

# Directory Structure
```
Data/cabin_data_new.gd
Data/DoorData.gd
Data/elevator_data.gd
Data/SpriteData_new.gd
DoorData.tres
icon.svg
icon.svg.import
project.godot
Scenes/elevator_component.gd
Scripts/building.gd
Scripts/cabin_timer.gd
Scripts/camera_2d.gd
Scripts/control.gd
Scripts/deco_base.gd
Scripts/door_ownership.gd
Scripts/door.gd
Scripts/elevator_state_machine_new.gd
Scripts/elevator.gd
Scripts/floor.gd
Scripts/magical_elevator.gd
Scripts/main.gd
Scripts/movement_component.gd
Scripts/navigation_controller.gd
Scripts/pathfinder_component.gd
Scripts/player_new.gd
Scripts/porter.gd
Scripts/queue_manager_new.gd
Scripts/roomboard.gd
Scripts/signal_bus.gd
Scripts/spawner.gd
Scripts/sprite_base.gd
Scripts/state_component.gd
Scripts/tooltip.gd
tooltip_manager.gd
```

# Files

## File: Data/cabin_data_new.gd
```
# cabin_data_new.gd
extends Node

enum ElevatorState { IDLE, WAITING, DEPARTING, TRANSIT, ARRIVING, ROOM_OCCUPIED}
var elevator_state: ElevatorState = ElevatorState.IDLE  # initial state

func set_elevator_state(new_state: ElevatorState) -> void:    
    elevator_state = new_state

var elevator_busy: bool = false # are there requests in the elevator queue?
var pick_up_on_current_floor: bool = false  # does the next request in the queue have pick-up at the current floor

var elevator_occupied: bool = false ## when occupied other sprites cannot enter the elevator (only one sprite in the elevator)
var sprite_entered: bool = false


var elevator_ready_emitted: bool = false # used in WAITING state


var elevator_queue_reordered: bool = false

var elevator_ready: bool = false # is used?

var doors_opening: bool = false
var doors_open: bool = true
var doors_closing: bool = false
var doors_closed: bool = false

var room_occupied: bool = false
var blocked_sprite: String = ""



var current_floor: int = 4 ## used in the new implementation  # for spawning only.
var destination_floor: int = 4  # for spawning only. If not used, remove

var elevator_direction: int = 0  # 1 = up, -1 = down, 0 = idle

var floor_boundaries = {} ## used in the new implementation
var floor_to_elevator = {} ## used in the new implementation
var floor_to_target_position = {} ## used in the new implementation
var target_position: Vector2 = Vector2.ZERO

const SCALE_FACTOR: float = 2.3 
const SPEED: float = 800.0  # Pixels per second 800


var cabin_timer: Timer
var cabin_timer_timeout: int = 2
```

## File: Data/DoorData.gd
```
# DoorData.gd
extends Resource
class_name DoorData

@export var doors: Array[Dictionary] = []
```

## File: Data/elevator_data.gd
```
# cabin_data.gd
extends Node

enum ElevatorState { IDLE, WAITING, DEPARTING, TRANSIT, ARRIVING}
var elevator_state: ElevatorState = ElevatorState.IDLE  # initial state

func set_elevator_state(new_state: ElevatorState) -> void:    
    elevator_state = new_state

var elevator_busy: bool = false
var pick_up_on_current_floor: bool = false    
var elevator_ready: bool = false
var elevator_occupied: bool = false
var timer_started: bool = false


var re_emit_ready_signal: bool = false
var elevator_queue_reordered: bool = false



var doors_opening: bool = false
var doors_open: bool = true
var doors_closing: bool = false
var doors_closed: bool = false





var current_floor: int = 3  # for spawning only.
var destination_floor: int = 1  # for spawning only. If not used, remove

var elevator_direction: int = 0  # 1 = up, -1 = down, 0 = idle

var floor_boundaries = {}
var floor_to_elevator = {}
var floor_to_target_position = {}
var target_position: Vector2 = Vector2.ZERO

const SCALE_FACTOR: float = 2.3 
const SPEED: float = 500.0  # Pixels per second


var cabin_timer: Timer
var cabin_timer_timeout: int = 2
```

## File: Data/SpriteData_new.gd
```
extends Resource

enum MovementState { IDLE, WALKING, NONE }
enum RoomState { CHECKING_ROOM_STATE, ENTERING_ROOM, IN_ROOM, EXITING_ROOM, NONE }
enum ElevatorState { CALLING_ELEVATOR, WAITING_FOR_ELEVATOR, ENTERING_ELEVATOR, IN_ELEVATOR_ROOM, IN_ELEVATOR_TRANSIT, EXITING_ELEVATOR, NONE }
enum ActiveState { NONE, MOVEMENT, ROOM, ELEVATOR }

var movement_state: MovementState = MovementState.NONE
var room_state: RoomState = RoomState.NONE
var elevator_state: ElevatorState = ElevatorState.WAITING_FOR_ELEVATOR

var sprite_name: String = ""
var sprite_height: int = -1
var sprite_width: int = -1
var speed: float = 400.0


var defer_input:bool = false



var current_position: Vector2 = Vector2.ZERO
var current_floor_number: int = -1                   # initial spawn floor
var current_room: int = -1                          # spawns 'on the floor'

var target_position: Vector2 = Vector2.ZERO
var target_floor_number: int = -1                    # initial spawn floor
var target_room: int = -1

var has_stored_data: bool = false
#########
var stored_position_updated: bool = false
##########
var stored_target_position: Vector2 = Vector2.ZERO
var stored_target_floor: int = -1
var stored_target_room: int = -1

var has_nav_data: bool = false
var nav_target_position: Vector2 = Vector2.ZERO
var nav_target_floor: int = -1
var nav_target_room: int = -1



# new
var elevator_request_id: int = -1

var elevator_requested: bool = false
var elevator_request_confirmed: bool = false
var elevator_ready: bool = false
var entering_elevator: bool = false
var entered_elevator: bool = false
var elevator_destination_reached = false
var exiting_elevator: bool = false
var exited_elevator: bool = false 

func needs_elevator(destination_floor: int) -> bool:
    return current_floor_number != destination_floor
    
 
func reset_elevator_status() -> void:
    # print("resetting the elevator status")
    elevator_request_id = -1
    elevator_requested = false
    elevator_request_confirmed = false
    elevator_ready = false
    entering_elevator = false
    entered_elevator = false
    elevator_destination_reached = false
    exiting_elevator = false
    exited_elevator = false
    defer_input = false

 
#region Set and Re-Set Position Data
func set_current_position(new_position: Vector2, floor_number: int, room_index: int) -> void:
    # print("set_current_position")
    current_position = new_position
    current_floor_number = floor_number
    current_room = room_index

func set_target_position(new_position: Vector2, floor_number: int, room_index: int) -> void:
    target_position = new_position
    target_floor_number = floor_number
    target_room = room_index
    # print("set_target_position: ", target_position)

func set_stored_position(new_position: Vector2, floor_number: int, room_index: int) -> void:
    has_stored_data = true
    stored_target_position = new_position
    stored_target_floor = floor_number
    # print("target floor = ", floor_number)
    stored_target_room = room_index

func set_sprite_nav_data(_click_global_position: Vector2, _floor_number: int, _door_index: int) -> void:
                        # should be adjusted click position!
    
    # print("Setting sprite nav data...")
    has_nav_data = true
    nav_target_position = _click_global_position
    nav_target_floor    = _floor_number
    nav_target_room     = _door_index
    
    #print("nav data has been set to: ")
    #print("nav_target_position: ",nav_target_position)
    #print("nav_target_floor: ",nav_target_floor)
    #print("nav_target_room: ",nav_target_room)
    
func reset_nav_data() -> void:
    has_nav_data = false
    nav_target_position = Vector2.ZERO
    nav_target_floor = -1
    nav_target_room = -1

func reset_stored_data() -> void:
    # print("reset_stored_data")
    has_stored_data = false
    stored_target_position = Vector2.ZERO
    stored_target_floor = -1
    stored_target_room = -1
#endregion
  

#region Set States
# move to state machine script

func get_active_state() -> ActiveState:
    if movement_state != MovementState.NONE:
        return ActiveState.MOVEMENT
    if room_state != RoomState.NONE:
        return ActiveState.ROOM
    if elevator_state != ElevatorState.NONE:
        return ActiveState.ELEVATOR
    
    return ActiveState.NONE


# sprite_data_new.set_elevator_state(SpriteDataNew.ElevatorState.WAITING_FOR_ELEVATOR)
func get_active_sub_state() -> String:    
    if movement_state != MovementState.NONE:
        return "movement:%s" % movement_state
    if room_state != RoomState.NONE:
        return "room:%s" % room_state
    if elevator_state != ElevatorState.NONE:
        return "elevator:%s" % elevator_state
    return "none"



func set_movement_state(new_state: MovementState) -> void:    
    movement_state = new_state
    room_state = RoomState.NONE
    elevator_state = ElevatorState.NONE


func set_room_state(new_state: RoomState) -> void:    
    room_state = new_state
    movement_state = MovementState.NONE
    elevator_state = ElevatorState.NONE


func set_elevator_state(new_state: ElevatorState) -> void:    
    elevator_state = new_state
    movement_state = MovementState.NONE
    room_state = RoomState.NONE
#endregion
```

## File: DoorData.tres
```
[gd_resource type="Resource" script_class="DoorData" load_steps=2 format=3 uid="uid://novorky384y7"]

[ext_resource type="Script" uid="uid://sgjalbwg78do" path="res://Data/DoorData.gd" id="1"]

[resource]
script = ExtResource("1")
doors = Array[Dictionary]([{
"door_slot": 3,
"door_type": 3,
"floor_number": 2,
"index": 0,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 1,
"room_name": "archive",
"screen": "screen_archive",
"tooltip": "Archive",
"tooltip_image": "archive"
}, {
"door_slot": 3,
"door_type": 3,
"floor_number": 5,
"index": 1,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 2,
"room_name": "archive",
"screen": "screen_archive",
"tooltip": "Archive",
"tooltip_image": "archive"
}, {
"door_slot": 3,
"door_type": 3,
"floor_number": 8,
"index": 2,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 3,
"room_name": "archive",
"screen": "screen_archive",
"tooltip": "Archive",
"tooltip_image": "archive"
}, {
"door_slot": 3,
"door_type": 3,
"floor_number": 11,
"index": 3,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 4,
"room_name": "archive",
"screen": "screen_archive",
"tooltip": "Archive",
"tooltip_image": "archive"
}, {
"door_slot": 1,
"door_type": 3,
"floor_number": 2,
"index": 4,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 1,
"room_name": "news",
"screen": "screen_newsstudio",
"tooltip": "News Studio",
"tooltip_image": "news"
}, {
"door_slot": 1,
"door_type": 3,
"floor_number": 5,
"index": 5,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 2,
"room_name": "news",
"screen": "screen_newsstudio",
"tooltip": "News Studio",
"tooltip_image": "news"
}, {
"door_slot": 1,
"door_type": 3,
"floor_number": 8,
"index": 6,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 3,
"room_name": "news",
"screen": "screen_newsstudio",
"tooltip": "News Studio",
"tooltip_image": "news"
}, {
"door_slot": 1,
"door_type": 3,
"floor_number": 11,
"index": 7,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 4,
"room_name": "news",
"screen": "screen_newsstudio",
"tooltip": "News Studio",
"tooltip_image": "news"
}, {
"door_slot": 2,
"door_type": 4,
"floor_number": 2,
"index": 8,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 1,
"room_name": "boss",
"screen": "screen_boss",
"tooltip": "Boss",
"tooltip_image": "boss"
}, {
"door_slot": 2,
"door_type": 4,
"floor_number": 5,
"index": 9,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 2,
"room_name": "boss",
"screen": "screen_boss",
"tooltip": "Boss",
"tooltip_image": "boss"
}, {
"door_slot": 2,
"door_type": 4,
"floor_number": 8,
"index": 10,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 3,
"room_name": "boss",
"screen": "screen_boss",
"tooltip": "Boss",
"tooltip_image": "boss"
}, {
"door_slot": 2,
"door_type": 4,
"floor_number": 11,
"index": 11,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 4,
"room_name": "boss",
"screen": "screen_boss",
"tooltip": "Boss",
"tooltip_image": "boss"
}, {
"door_slot": 0,
"door_type": 1,
"floor_number": 2,
"index": 12,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 1,
"room_name": "office",
"screen": "screen_office",
"tooltip": "Bureau",
"tooltip_image": "bureau"
}, {
"door_slot": 0,
"door_type": 1,
"floor_number": 5,
"index": 13,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 2,
"room_name": "office",
"screen": "screen_office",
"tooltip": "Bureau",
"tooltip_image": "bureau"
}, {
"door_slot": 0,
"door_type": 1,
"floor_number": 8,
"index": 14,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 3,
"room_name": "office",
"screen": "screen_office",
"tooltip": "Bureau",
"tooltip_image": "bureau"
}, {
"door_slot": 0,
"door_type": 1,
"floor_number": 11,
"index": 15,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 4,
"room_name": "office",
"screen": "screen_office",
"tooltip": "Bureau",
"tooltip_image": "bureau"
}, {
"door_slot": 1,
"door_type": 1,
"floor_number": 1,
"index": 16,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 1,
"room_name": "studio",
"screen": "screen_studio",
"tooltip": "Studio",
"tooltip_image": "studio"
}, {
"door_slot": 1,
"door_type": 1,
"floor_number": 4,
"index": 17,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 2,
"room_name": "studio",
"screen": "screen_studio",
"tooltip": "Studio",
"tooltip_image": "studio"
}, {
"door_slot": 1,
"door_type": 1,
"floor_number": 7,
"index": 18,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 3,
"room_name": "studio",
"screen": "screen_studio",
"tooltip": "Studio",
"tooltip_image": "studio"
}, {
"door_slot": 1,
"door_type": 1,
"floor_number": 10,
"index": 19,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 4,
"room_name": "studio",
"screen": "screen_studio",
"tooltip": "Studio",
"tooltip_image": "studio"
}, {
"door_slot": 2,
"door_type": 4,
"floor_number": 12,
"index": 20,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "frduban",
"screen": "1080_free_duban",
"tooltip": "Free Republic Duban"
}, {
"door_slot": 2,
"door_type": 3,
"floor_number": 7,
"index": 21,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "vrduban",
"screen": "1080_peoples_duban",
"tooltip": "People's Republic Duban"
}, {
"door_slot": 3,
"door_type": 3,
"floor_number": 9,
"index": 22,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "gunsagency",
"screen": "1080_rattling_agency",
"tooltip": "Guns Agency"
}, {
"door_slot": 1,
"door_type": 4,
"floor_number": 6,
"index": 23,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "tobaccolobby",
"screen": "1080_tobacco",
"tooltip": "Tobacco Lobby"
}, {
"door_slot": 2,
"door_type": 3,
"floor_number": 6,
"index": 24,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "notobacco",
"screen": "1080_anti_nicotine",
"tooltip": "No Tobacco"
}, {
"door_slot": 2,
"door_type": 3,
"floor_number": 10,
"index": 25,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "peacebrothers",
"screen": "1080_peacebrothers",
"tooltip": "Peacebrothers"
}, {
"door_slot": 2,
"door_type": 3,
"floor_number": 4,
"index": 26,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "scriptagency",
"screen": "screen_scriptagency",
"tooltip": "Script Agency"
}, {
"door_slot": 1,
"door_type": 2,
"floor_number": 9,
"index": 27,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "roomagency",
"screen": "screen_roomagency",
"tooltip": "Room Agency"
}, {
"door_slot": 0,
"door_type": 1,
"floor_number": 13,
"index": 28,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "betty",
"screen": "screen_betty",
"tooltip": "Betty"
}, {
"door_slot": 0,
"door_type": 2,
"floor_number": 1,
"index": 29,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "laundry",
"screen": "1080_laundry",
"tooltip": "Laundry"
}, {
"door_slot": 1,
"door_type": 3,
"floor_number": 12,
"index": 30,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "biocontrol",
"screen": "1080_bio_control",
"tooltip": "Bio-Control"
}, {
"door_slot": 1,
"door_type": 4,
"floor_number": 3,
"index": 32,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "psychiatrist",
"screen": "1080_psychiatrist",
"tooltip": "Psychiatrist"
}, {
"door_slot": 2,
"door_type": 3,
"floor_number": 1,
"index": 33,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "supermarket",
"screen": "screen_supermarket",
"tooltip": "Supermarket"
}, {
"door_slot": 0,
"door_type": 3,
"floor_number": 3,
"index": 34,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "movieagency",
"screen": "screen_movieagency",
"tooltip": "MOVIE Agency",
"tooltip_image": "movieagency"
}, {
"door_slot": 0,
"door_type": 3,
"floor_number": 10,
"index": 35,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "adagency",
"screen": "screen_adagency",
"tooltip": "AD Agency",
"tooltip_image": "adagency"
}, {
"door_slot": 0,
"door_type": 1,
"floor_number": 0,
"index": 36,
"info": "door_slot_must_be_0",
"is_animated": false,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "roomboard",
"screen": "screen_roomboard",
"tooltip": "Roomboard"
}, {
"door_slot": 3,
"door_type": 1,
"floor_number": 13,
"index": 37,
"is_animated": true,
"is_visible": true,
"object_type": "door",
"owner": 0,
"room_name": "credits",
"screen": "screen_credits",
"tooltip": "CREDITS"
}, {
"door_slot": 0,
"door_type": 1,
"floor_number": 0,
"index": 38,
"info": "door_slot_must_be_0",
"is_animated": false,
"is_visible": false,
"object_type": "door",
"owner": 0,
"room_name": "porter",
"screen": "1080_porter",
"tooltip": "Porter"
}])
```

## File: icon.svg
```
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><rect width="124" height="124" x="2" y="2" fill="#363d52" stroke="#212532" stroke-width="4" rx="14"/><g fill="#fff" transform="translate(12.322 12.322)scale(.101)"><path d="M105 673v33q407 354 814 0v-33z"/><path fill="#478cbf" d="m105 673 152 14q12 1 15 14l4 67 132 10 8-61q2-11 15-15h162q13 4 15 15l8 61 132-10 4-67q3-13 15-14l152-14V427q30-39 56-81-35-59-83-108-43 20-82 47-40-37-88-64 7-51 8-102-59-28-123-42-26 43-46 89-49-7-98 0-20-46-46-89-64 14-123 42 1 51 8 102-48 27-88 64-39-27-82-47-48 49-83 108 26 42 56 81zm0 33v39c0 276 813 276 814 0v-39l-134 12-5 69q-2 10-14 13l-162 11q-12 0-16-11l-10-65H446l-10 65q-4 11-16 11l-162-11q-12-3-14-13l-5-69z"/><path d="M483 600c0 34 58 34 58 0v-86c0-34-58-34-58 0z"/><circle cx="725" cy="526" r="90"/><circle cx="299" cy="526" r="90"/></g><g fill="#414042" transform="translate(12.322 12.322)scale(.101)"><circle cx="307" cy="532" r="60"/><circle cx="717" cy="532" r="60"/></g></svg>
```

## File: icon.svg.import
```
[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://bdp34bau47jjh"
path="res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex"
metadata={
"vram_texture": false
}

[deps]

source_file="res://icon.svg"
dest_files=["res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
svg/scale=1.0
editor/scale_with_editor_scale=false
editor/convert_colors_with_editor_theme=false
```

## File: project.godot
```
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.
;
; Format:
;   [section] ; section goes between []
;   param=value ; assign values to parameters

config_version=5

[ai_assistant_hub]

base_url="http://127.0.0.1:11434"
llm_api="ollama_api"

[application]

config/name="4.3 Test Project"
run/main_scene="res://Scenes/Main.tscn"
config/features=PackedStringArray("4.4", "GL Compatibility")
run/max_fps=60
config/icon="res://icon.svg"

[autoload]

SignalBus="*res://Scripts/signal_bus.gd"

[debug]

file_logging/enable_file_logging=true
gdscript/warnings/unused_signal=0

[display]

window/size/viewport_width=1920
window/size/viewport_height=1080

[rendering]

renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
2d/snap/snap_2d_transforms_to_pixel=true
```

## File: Scenes/elevator_component.gd
```
extends Node
class_name ElevatorComponent

var sprite_data_new: Resource
var sprite_owner: Node   # The Area2D or Node2D that owns this script.
var navigation_controller: Node
var cabin: Node
var state_manager: Node


func _ready():
    SignalBus.elevator_request_confirmed.connect(_on_elevator_request_confirmed)
    SignalBus.elevator_waiting_ready.connect(_on_elevator_waiting_ready_received)
    SignalBus.elevator_position_updated.connect(_on_elevator_ride)
    SignalBus.elevator_arrived_at_destination.connect(_on_elevator_at_destination)




# Optional: You can call this once from the sprite script or spawner to set up references.
#func init_elevator_component(
    #_sprite_data: Resource,
    #_sprite_owner: Node,
    #_navigation_controller: Node,
    #_cabin: Node,
    #_state_manager: Node
#):
    #sprite_data_new = _sprite_data
    #sprite_owner = _sprite_owner
    #navigation_controller = _navigation_controller
    #cabin = _cabin
    #state_manager = _state_manager

# The main function to be called from sprite_base.gd's _process
func _process_elevator_actions(
    sprite_data: Resource,
    owner_node: Node,
    nav_controller: Node,
    cabin_node: Node,
    state_manager: Node
) -> void:
    # If you don't use init_elevator_component, you can accept them as parameters each time:
    #   sprite_data_new = sprite_data
    #   sprite_owner = owner_node

    # Check the current elevator state and run the correct logic.
    match sprite_data.elevator_state:
        sprite_data.ElevatorState.CALLING_ELEVATOR:
            if not sprite_data.elevator_requested or sprite_data.stored_position_updated:
                call_elevator()

        sprite_data.ElevatorState.WAITING_FOR_ELEVATOR:
            if sprite_data.stored_position_updated:
                call_elevator()

        sprite_data.ElevatorState.ENTERING_ELEVATOR:
            if not sprite_data.entered_elevator:
                enter_elevator()

        sprite_data.ElevatorState.IN_ELEVATOR_TRANSIT:
            # If you have an animation, you might call it on the sprite
            owner_node._animate_sprite()

        sprite_data.ElevatorState.IN_ELEVATOR_ROOM:
            owner_node._animate_sprite()

        sprite_data.ElevatorState.EXITING_ELEVATOR:
            exit_elevator()

        _:
            pass


func call_elevator() -> void:
    var request_data: Dictionary = {
        "sprite_name": sprite_data_new.sprite_name,
        "pick_up_floor": sprite_data_new.current_floor_number,
        "destination_floor": sprite_data_new.stored_target_floor,
        "request_id": sprite_data_new.elevator_request_id
    }

    SignalBus.elevator_called.emit(request_data)
    sprite_owner._animate_sprite()  # or sprite_owner._animate_sprite() if you’re calling the sprite’s method

    sprite_data_new.elevator_requested = true


func enter_elevator() -> void:
    if not sprite_data_new.entering_elevator:
        sprite_data_new.entering_elevator = true
        sprite_owner._animate_sprite()

        var elevator_data = navigation_controller.elevators.get(sprite_data_new.current_floor_number, null)
        var cabin_height = cabin.get_cabin_height()
        var cabin_bottom_y = elevator_data["position"].y + (cabin_height * 0.5)
        var new_position = Vector2(
            elevator_data["position"].x,
            cabin_bottom_y - (sprite_data_new.sprite_height * 0.5)
        )

        sprite_data_new.set_current_position(new_position,
            sprite_data_new.current_floor_number,
            sprite_data_new.current_room
        )

        # Update the sprite node's visual position & z_index
        sprite_owner.global_position = sprite_data_new.current_position
        sprite_owner.z_index = -9
    else:
        return


func exit_elevator() -> void:
    if not sprite_data_new.exiting_elevator:
        sprite_data_new.exiting_elevator = true
        sprite_owner._animate_sprite()
    else:
        return


func on_sprite_entered_elevator() -> void:
    sprite_data_new.entered_elevator = true
    SignalBus.enter_animation_finished.emit(sprite_data_new.sprite_name, sprite_data_new.stored_target_floor)
    sprite_owner._animate_sprite()


func on_sprite_exited_elevator() -> void:
    sprite_owner.z_index = 0
    SignalBus.exit_animation_finished.emit(sprite_data_new.sprite_name)
    sprite_data_new.exited_elevator = true
    sprite_data_new.set_target_position(
        sprite_data_new.stored_target_position,
        sprite_data_new.stored_target_floor,
        sprite_data_new.stored_target_room
    )
    sprite_data_new.reset_stored_data()


func _on_elevator_request_confirmed(elevator_request_data: Dictionary, elevator_ready_status: bool) -> void:
    var incoming_sprite_name = elevator_request_data["sprite_name"]
    var incoming_request_id = elevator_request_data["request_id"]

    if incoming_sprite_name != sprite_data_new.sprite_name:
        return

    sprite_data_new.elevator_request_id = incoming_request_id
    sprite_data_new.elevator_request_confirmed = true

    if elevator_ready_status:
        if sprite_data_new.elevator_state in [sprite_data_new.ElevatorState.CALLING_ELEVATOR, sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR]:
            sprite_data_new.elevator_ready = true
            sprite_data_new.defer_input = true

            # Handle state transitions via the state manager:
            state_manager._process_elevator_state(sprite_data_new)

            SignalBus.entering_elevator.emit(sprite_data_new.sprite_name)
        else:
            print("Elevator is ready, but sprite not in CALLING or WAITING state.")
    else:
        print("Not entering because the elevator is blocked or not ready.")


func _on_elevator_waiting_ready_received(elevator_request_data: Dictionary, elevator_ready_status: bool) -> void:
    var incoming_sprite_name = elevator_request_data["sprite_name"]
    var incoming_request_id = elevator_request_data["request_id"]

    if incoming_sprite_name != sprite_data_new.sprite_name:
        return

    # Similar logic to _on_elevator_request_confirmed, but specifically for WAITING_FOR_ELEVATOR
    if sprite_data_new.elevator_state == sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
        sprite_data_new.elevator_request_id = incoming_request_id
        sprite_data_new.elevator_request_confirmed = true

        if elevator_ready_status:
            sprite_data_new.elevator_ready = true
            sprite_data_new.defer_input = true
            SignalBus.entering_elevator.emit(sprite_data_new.sprite_name)


func _on_elevator_ride(elevator_pos: Vector2, sprite_name: String) -> void:
    if sprite_name != sprite_data_new.sprite_name:
        return

    if sprite_data_new.entered_elevator:
        var cabin_height = cabin.get_cabin_height()
        var cabin_bottom_y = elevator_pos.y + (cabin_height * 0.5)
        var new_position = Vector2(
            elevator_pos.x,
            cabin_bottom_y - (sprite_data_new.sprite_height * 0.5)
        )

        sprite_data_new.set_current_position(
            new_position,
            sprite_data_new.current_floor_number,
            sprite_data_new.current_room
        )

        sprite_owner.global_position = sprite_data_new.current_position
        sprite_owner._animate_sprite()


func _on_elevator_at_destination(incoming_sprite_name: String) -> void:
    if incoming_sprite_name == sprite_data_new.sprite_name:
        sprite_data_new.elevator_destination_reached = true
```

## File: Scripts/building.gd
```
# building.gd
extends Node2D

const FLOOR_SCENE = preload("res://Scenes/Floor.tscn")
const ELEVATOR_SCENE = preload("res://Scenes/Elevator.tscn")
const DOOR_DATA_RESOURCE = preload("res://DoorData.tres")
const NUM_FLOORS = 14  # Total number of floors

func _ready():
    generate_building()

func generate_building():
    var previous_floor_top_y_position = 0.0
    var is_first_floor = true

    for floor_number in range(NUM_FLOORS):
        var floor_instance = instantiate_floor(floor_number)
        if floor_instance:
            previous_floor_top_y_position = floor_instance.position_floor(previous_floor_top_y_position, is_first_floor)
            is_first_floor = false

            var door_data_array = DOOR_DATA_RESOURCE.doors.filter(func(door):
                return door.floor_number == floor_number
            )
            floor_instance.setup_doors(door_data_array)
            ## maybe add a setup_kiosk here?
            # print("door_data_array: ", door_data_array)
            floor_instance.setup_elevator()

func instantiate_floor(floor_number):    
    var floor_instance = FLOOR_SCENE.instantiate()
    if not floor_instance:
        push_warning("Failed to instantiate floor scene")
        return null
    
    floor_instance.floor_number = floor_number
    var image_path = "res://Building/Floors/Floor_" + str(floor_number) + ".png"    
    floor_instance.floor_image_path = image_path
    floor_instance.name = "Floor_" + str(floor_number)
    add_child(floor_instance)
    return floor_instance
```

## File: Scripts/cabin_timer.gd
```
# cabin_timer.gd
extends Node

@onready var timer: Timer = $Timer

# We can expose how long we want to wait
# so it can be configured from the editor or set from the parent.
@export var default_wait_time := 2.0

# References to other needed nodes (if you need them).
# You can either get these dynamically or have them passed in from the parent.
var queue_manager: Node
var cabin_data: Node

func _ready() -> void:
    # One-shot means it only times out once per start()
    timer.one_shot = true
    timer.wait_time = default_wait_time

    # Connect the timeout signal to our local function
    timer.timeout.connect(_on_cabin_timer_timeout)

func set_dependencies(_queue_manager: Node, _cabin_data: Node) -> void:
    # This is a helper function so the parent can give references
    queue_manager = _queue_manager
    cabin_data = _cabin_data

func set_wait_time(wait_time: float) -> void:
    timer.wait_time = wait_time

func start_timer() -> void:
    # Make sure we reset it if needed
    timer.stop()
    # If there's something in the queue, start the timer
    if queue_manager and not queue_manager.elevator_queue.is_empty():
        timer.start()

func stop_timer() -> void:
    timer.stop()

func _on_cabin_timer_timeout() -> void:
    # Example logic – remove top request, etc.
    if queue_manager and not queue_manager.elevator_queue.is_empty():
        var removed_request = queue_manager.elevator_queue[0]
        var sprite_name = removed_request.get("sprite_name", "")
        var request_id  = removed_request.get("request_id", -1)  
        
        # You might need to call some cabin_data or parent function here.
        # e.g. cabin_data.reset_elevator(sprite_name, request_id)
        cabin_data.reset_elevator(sprite_name, request_id)

        # Then check the queue
        cabin_data.check_elevator_queue()
    else:
        print("Elevator queue is empty, nothing to remove.")
```

## File: Scripts/camera_2d.gd
```
# camera_2d.gd  # do not remove this comment
extends Camera2D
var viewport_size: Vector2
var screen_center_x: float = 0
var player_sprite: Area2D

func _ready():
    viewport_size = get_viewport().size
    screen_center_x = viewport_size.x / 2
    
    player_sprite = get_tree().get_first_node_in_group("player_sprite") as Area2D

func _process(_delta: float) -> void:
    # Keep the camera's x-position locked to the horizontal center
    position.x = screen_center_x
    # If we found a player node, follow its y-position
    if player_sprite:
        position.y = player_sprite.position.y
```

## File: Scripts/control.gd
```
# Tooltip_Doors.gd
extends Control

@onready var tooltip_label: Label = $HBoxContainer/Label
@onready var tooltip_image: TextureRect = $HBoxContainer/TextureImage
@onready var background: NinePatchRect = $Background
@onready var container: HBoxContainer = $HBoxContainer

var tooltip_timer: Timer
var mouse_inside: bool = false
const DEFAULT_IMAGE_SIZE = Vector2(32, 32)

func _ready():
    visible = false
    z_index = 10
    
    tooltip_timer = Timer.new()
    tooltip_timer.one_shot = true
    tooltip_timer.wait_time = 0.5
    tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
    add_child(tooltip_timer)
    
    tooltip_label.add_theme_color_override("font_color", Color.BLACK)
    container.add_theme_constant_override("separation", 10)

func _process(_delta):
    if visible:
        position = get_viewport().get_mouse_position() + Vector2(10, -10)

func show_tooltip_with_data(data: Dictionary):
    # Process tooltip text
    tooltip_text = data.get("tooltip", "")
    if tooltip_text.find("{owner}") != -1:
        tooltip_text = tooltip_text.replace("{owner}", data.get("owner", ""))
    
    set_text(tooltip_text)
    
    # Process tooltip image
    var image_path = ""
    if data.has("tooltip_image") and data["tooltip_image"] != "":
        image_path = "res://Building/Rooms/tooltip_images/" + data["tooltip_image"] + ".png"
    
    set_image(image_path, 1.0)
    
    # Show the tooltip
    mouse_inside = true
    tooltip_timer.start()

func set_text(new_text: String):
    tooltip_label.text = new_text if new_text else ""
    update_tooltip_size()

func set_image(path: String, scaling: float = 1.0):
    if path.is_empty():
        tooltip_image.visible = false
    else:
        tooltip_image.visible = true
        tooltip_image.texture = load(path)
        tooltip_image.custom_minimum_size = DEFAULT_IMAGE_SIZE * scaling
    update_tooltip_size()

func hide_tooltip():
    mouse_inside = false
    tooltip_timer.stop()
    visible = false

func _on_tooltip_timer_timeout():
    if mouse_inside:
        visible = true

func update_tooltip_size():
    container.custom_minimum_size = Vector2.ZERO
    container.size = Vector2.ZERO
    
    var padding = Vector2(15, 10)
    var total_size = container.get_combined_minimum_size() + padding
    
    background.size = total_size
    position = Vector2(-total_size.x / 2, -total_size.y - 10)
    container.position = padding / 2
    container.size = total_size - padding
```

## File: Scripts/deco_base.gd
```
extends Node2D

@onready var navigation_controller := get_tree().get_root().get_node("Main/Navigation_Controller")
@export var deco_texture: Texture2D
const SpriteDataScript = preload("res://Data/SpriteData_new.gd")
var sprite_data_new: Resource = SpriteDataScript.new()
const SCALE_FACTOR = 2.3
var x_placement: int
var element_name: String

func _ready():
    $Sprite2D.texture = deco_texture
    instantiate_sprite()
    set_initial_position()

func set_data(x_percent: int, current_floor_number: int, sprite_name: String):
    sprite_data_new.current_floor_number = current_floor_number
    sprite_data_new.sprite_name = sprite_name
    x_placement = x_percent


func set_initial_position() -> void:
    var floor_number = sprite_data_new.current_floor_number
    var floor_info: Dictionary = navigation_controller.floors[floor_number]
    var edges: Dictionary = floor_info["edges"]    
    var floor_width = float(edges["right"] - edges["left"])
    var x_pos = edges["left"] + floor_width * (x_placement / 100.0)
    var bottom_edge_y = edges["bottom"]
    var top_edge_y = edges["top"]
    var sprite_height = sprite_data_new.sprite_height
    
    var y_pos: float

    if floor_number != 0: 
        y_pos = bottom_edge_y - (sprite_height * 0.5)
    else:
        y_pos = bottom_edge_y - (sprite_height * 0.51)
    
    if sprite_data_new.sprite_name == "WallLamp":
        y_pos = top_edge_y + (sprite_height * 0.51)
        
    if sprite_data_new.sprite_name == "Picture":
        y_pos = bottom_edge_y - (sprite_height * 1.1)
    

        
    global_position = Vector2(x_pos, y_pos)

    sprite_data_new.set_current_position(
        global_position,
        floor_number,
        sprite_data_new.current_room
    )
    sprite_data_new.set_target_position(
        global_position,
        floor_number,
        sprite_data_new.target_room
    )

func instantiate_sprite():
    add_to_group("deco_sprites")
    apply_scale_factor_to_sprite()
    update_sprite_dimensions()

func update_sprite_dimensions():
    var tex = $Sprite2D.texture
    if tex:
        sprite_data_new.sprite_width  = tex.get_width() * $Sprite2D.scale.x
        sprite_data_new.sprite_height = tex.get_height() * $Sprite2D.scale.y

func apply_scale_factor_to_sprite():
    if $Sprite2D:
        $Sprite2D.scale *= SCALE_FACTOR
    else:
        push_warning("Sprite2D node not found for scaling.")
```

## File: Scripts/door_ownership.gd
```
# door_ownership.gd
extends Node2D

signal owner_changed(old_owner, new_owner)

@export var can_change_owner: bool = true
@export var default_logo_scale: Vector2 = Vector2(2.3, 2.3)
@onready var logo_sprite: Sprite2D = $Owner_Logo

var door_data: Dictionary

var owner_colors = {
    1: Color(0.732, 0.245, 0.262),  # Red
    2: Color(0.04, 0.484, 0.037),   # Green
    3: Color(0.219, 0.417, 0.889),  # Blue
    4: Color(0.227, 0.227, 0.227),  # Dark grey/Black
}

func _ready():
    logo_sprite.scale = default_logo_scale
    # pass
    
func initialize(p_door_data: Dictionary) -> void:
    door_data = p_door_data
    update_logo_visibility()
    update_logo_color()

func change_owner(new_owner: String) -> void:
    '''change ownership not implemented in door data file'''
    ''' can_change_owner is always true'''
    
    if not can_change_owner:
        push_warning("This door cannot change owners")
        return
        
    # var old_owner = door_data["owner"]
    door_data["owner"] = new_owner    
    update_logo_visibility()
    update_logo_color()    
    '''owner changed signal not implemented'''
    ## emit_signal("owner_changed", old_owner, new_owner) 

func update_logo_visibility() -> void:
    var owner_val = int(door_data.owner)
    logo_sprite.visible = owner_val in [1, 2, 3, 4]

func update_logo_color() -> void:
    var owner_val = int(door_data.owner)
    if owner_val in owner_colors:
        logo_sprite.modulate = owner_colors[owner_val]
    else:
        logo_sprite.modulate = Color(1, 1, 1)  # Default white
```

## File: Scripts/door.gd
```
# Door.gd
extends Area2D

enum DoorState { CLOSED, OPEN }

var current_state: DoorState = DoorState.CLOSED
var door_type: int
var door_data: Dictionary
var floor_instance
var door_center_x: float = 0.0 

const SLOT_PERCENTAGES = [0.15, 0.35, 0.65, 0.85]

@onready var animated_sprite: AnimatedSprite2D = $Door_Animation_2D
@onready var collision_shape: CollisionShape2D = $Door_Collision_Shape_2D
@onready var ownership_manager = $Door_Ownership if has_node("Door_Ownership") else null

func _ready():
    add_to_group("doors")
    input_pickable = true
    connect("input_event", self._on_input_event)
    setup_door_instance(door_data, floor_instance)

    connect("mouse_entered", self._on_mouse_entered)
    connect("mouse_exited", self._on_mouse_exited)

func _on_input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        SignalBus.navigation_click.emit(
            event.global_position,
            door_data.floor_number,
            door_data.index
        )
        get_viewport().set_input_as_handled()

func set_door_state(new_state: DoorState) -> void:
    current_state = new_state
    var animation_name = "door_open" if current_state == DoorState.OPEN else "door_type_%d" % door_type
    if animation_name in animated_sprite.sprite_frames.get_animation_names():
        animated_sprite.play(animation_name)
        animated_sprite.stop()
    else:
        push_warning("Animation %s not found!" % animation_name)

func _on_mouse_entered():
    SignalBus.show_tooltip.emit(door_data)

func _on_mouse_exited():
    SignalBus.hide_tooltip.emit()

'''not relevant to the current re-factoring'''
'''change owner is implemented but needs to be integrated'''
'''- emits undefined owner changed signal'''
'''- changeable_owner not implemented in door_data'''
'''- needs testing if the tooltip will properly update'''
func change_owner(new_owner: String) -> void:
    if ownership_manager:
        ownership_manager.change_owner(new_owner)
        door_data["owner"] = new_owner
    else:
        push_warning("This door does not have an ownership manager")


#region Door Setup
func setup_door_instance(p_door_data, p_floor_instance):
    door_data = p_door_data
    floor_instance = p_floor_instance
    door_type = door_data.door_type
    set_door_state(DoorState.CLOSED)
    position_door()
    update_collision_shape()
    
    # Initialize ownership manager if present
    if ownership_manager:
        ownership_manager.initialize(door_data)

func get_collision_edges() -> Dictionary:
    var door_collision_shape = $Door_Collision_Shape_2D
    if not door_collision_shape:
        push_error("No CollisionShape2D found in door")
        return {}
        
    var shape = collision_shape.shape
    if not shape is RectangleShape2D:
        push_error("Door collision shape must be RectangleShape2D")
        return {}
        
    var extents = shape.extents
    var global_pos = collision_shape.global_position
    
    return {
        "left": global_pos.x - extents.x,
        "right": global_pos.x + extents.x,
        "top": global_pos.y - extents.y,
        "bottom": global_pos.y + extents.y
    }

func update_collision_shape() -> void:
    var animation_name = "door_type_%d" % door_type
    var dimensions = get_frame_dimensions(animation_name)
    if dimensions.width > 0 and dimensions.height > 0:
        var rectangle_shape = RectangleShape2D.new()
        rectangle_shape.extents = Vector2(dimensions.width / 2, dimensions.height / 2)
        collision_shape.shape = rectangle_shape
    else:
        push_warning("Cannot update collision shape: Invalid dimensions")

func position_door():
    var slot_index = door_data.door_slot
    if slot_index < 0 or slot_index >= SLOT_PERCENTAGES.size():
        push_warning("Invalid door slot index %d" % slot_index)
        return

    var floor_collision_shape = floor_instance.get_node("CollisionShape2D")
    if not floor_collision_shape:
        push_warning("Missing CollisionShape2D node for door position calculation")
        return

    var shape = floor_collision_shape.shape
    if shape is RectangleShape2D:
        var rect_shape = shape as RectangleShape2D
        var collision_width = rect_shape.extents.x * 2
        var collision_left_edge = floor_collision_shape.global_position.x - rect_shape.extents.x

        var percentage = SLOT_PERCENTAGES[slot_index]
        var local_x = collision_left_edge + percentage * collision_width

        var collision_edges = floor_instance.get_collision_edges()
        var bottom_edge_y = collision_edges["bottom"]
        
        var dimensions = get_door_dimensions()
        var local_y = bottom_edge_y - (dimensions.height / 2)

        var global_door_position = Vector2(local_x, local_y)
        global_position = global_door_position
        door_center_x = global_door_position.x
    else:
        push_warning("Collision shape is not a RectangleShape2D")

func get_door_dimensions():
    var animation_name = "door_type_%d" % door_type
    return get_frame_dimensions(animation_name)

func get_frame_dimensions(animation_name: String) -> Dictionary:
    if animated_sprite and animated_sprite.sprite_frames:
        if animation_name in animated_sprite.sprite_frames.get_animation_names():
            var first_frame = animated_sprite.sprite_frames.get_frame_texture(animation_name, 0)
            if first_frame:
                var width = first_frame.get_width() * animated_sprite.scale.x
                var height = first_frame.get_height() * animated_sprite.scale.y
                return { "width": width, "height": height }
    return { "width": 0.0, "height": 0.0 }
#endregion
```

## File: Scripts/elevator_state_machine_new.gd
```
# elevator_state_machine.gd
extends Node
const CabinData = preload("res://Data/cabin_data_new.gd")


# @export var cabin_data: Node
@export var queue_manager: Node
@export var cabin_data: Node





func _ready() -> void:
    pass
    
    
#func process_elevator_state() -> void:    
    #match cabin_data.elevator_state:
    #
        #cabin_data.ElevatorState.IDLE:            
            #process_idle()       
        #cabin_data.ElevatorState.WAITING:
            #return
            #pass
            ## process_waiting()       
        #cabin_data.ElevatorState.DEPARTING:            
            #process_departing()       
        #cabin_data.ElevatorState.TRANSIT:      
            #process_transit()       
        #cabin_data.ElevatorState.ARRIVING:      
            #process_arriving()       
        #_:
            #push_warning("unknow state in process_cabin_states")                            
            #pass


func process_idle() -> void:        
    if not cabin_data.elevator_busy:
        return
    else:
        # print("elevator is now busy")
        cabin_data.set_elevator_state(CabinData.ElevatorState.WAITING)
        return
        # process_waiting()

    
    
func process_waiting() -> void:
    # print("process_waiting in elevator state machine")
    # print("cabin occupied? ", cabin_data.elevator_occupied)

    # 1) If there are no more requests, go idle.
    if not cabin_data.elevator_busy:
        # print("in elevator state machine: not busy")
        cabin_data.set_elevator_state(CabinData.ElevatorState.IDLE)
        return

    # 2) If the elevator is already occupied, we need to depart next.
    if cabin_data.elevator_occupied:
        # print("in elevator state machine: occupied")
        cabin_data.set_elevator_state(CabinData.ElevatorState.DEPARTING)
        process_departing()
        return

    # By this point, `elevator_ready_emitted` is True, the elevator is busy, but not occupied.
    # 4) If the next pickup is NOT on the current floor, depart to handle it.
    if not cabin_data.pick_up_on_current_floor:
        # print("in state machine: ")
        # print("Setting state to departing ")
        # print("in elevator state machine: pick-up not on current floor")
        cabin_data.set_elevator_state(CabinData.ElevatorState.DEPARTING)
        process_departing()
        return

    ## 5) If the next pickup IS on this floor, but no one has entered yet, we wait (timer running).
    # print("timer is running")
    return


    
    
    
func process_departing() -> void:
    # print("process_departing in state elevator state machine")
    '''we must wait for the sprite to finish entering before closing the doors, if occupied'''
    '''elevator ready needs to be reset'''
    ''' same for ready emitted etc... -> check the state vars'''
    #print("Elevator is DEPARTING")
    #print("cabin_data.elevator_occupied: ", cabin_data.elevator_occupied)
    #print("cabin_data.doors_closed: ", cabin_data.doors_closed)
    if cabin_data.doors_closed:
        cabin_data.set_elevator_state(CabinData.ElevatorState.TRANSIT)

func process_transit() -> void:
    # print("elevator is now in transit")
    
    if cabin_data.elevator_direction == 0:
        # print("switching to arriving")
        cabin_data.set_elevator_state(CabinData.ElevatorState.ARRIVING)


func process_arriving() -> void:
    
    if cabin_data.doors_open and not cabin_data.elevator_occupied:
        cabin_data.set_elevator_state(CabinData.ElevatorState.WAITING)
        # print("cabin is now waiting again")
    pass
```

## File: Scripts/elevator.gd
```
# elevator.gd
extends Area2D

var floor_instance
const SCALE_FACTOR = 2.3

enum DoorState { CLOSED, OPENING, OPEN, CLOSING }
var door_state: DoorState = DoorState.CLOSED

@onready var red_square = $Frame/FloorIndicatorHolder/RedSquare
@onready var white_rectangle = $Frame/FloorIndicatorHolder/WhiteRectangle

func setup_elevator_instance(p_floor_instance):
    floor_instance = p_floor_instance
    name = "Elevator_" + str(floor_instance.floor_number)    
    add_to_group("elevators")
    apply_scale_factor_to_elevator()
    position_elevator()
    update_elevator_door_collision_shape()
    setup_elevator_doors_position()

    SignalBus.floor_area_entered.connect(_on_floor_area_entered)


func _on_floor_area_entered(_area: Area2D, floor_number: int) -> void:
    # print("current elevator floor number: ", floor_number)
    update_red_indicator_position(floor_number)


func _ready():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        elevator_doors.animation_finished.connect(_on_doors_animation_finished)
        # print("Connected animation_finished signal.")
    else:
        push_warning("AnimatedSprite2D node not found in Elevator scene.")


func _on_input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:        
        SignalBus.navigation_click.emit(
            event.global_position,
            floor_instance.floor_number,
            -2  # Arbitrary index. 
        )
        get_viewport().set_input_as_handled()


func update_red_indicator_position(floor_number: int):

    var rect_width = white_rectangle.texture.get_size().x
    var half_rect_width = rect_width * 0.5
    var left_edge_x = white_rectangle.position.x - half_rect_width
    var floors_count = 14
    var spacing = rect_width / float(floors_count - 1)  # distance per floor
    var new_x = left_edge_x + floor_number * spacing
    new_x -= (red_square.texture.get_size().x * 0.5)
    var new_y = white_rectangle.position.y
    red_square.position = Vector2(new_x, new_y)


func set_door_state(new_state: DoorState):
    door_state = new_state
    match door_state:
        DoorState.CLOSED:
            show_doors_closed()
        DoorState.OPEN:
            show_doors_opened()
        DoorState.OPENING:
            animate_doors_opening()
        DoorState.CLOSING:
            animate_doors_closing()

    # Emit the door state change via SignalBus
    SignalBus.door_state_changed.emit(door_state)
    # print("Door state changed to: ", door_state)

func get_door_state() -> DoorState:
    return door_state

func show_doors_closed():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        elevator_doors.visible = true
        elevator_doors.play("closed")
        # print("Showing doors closed.")
    else:
        push_warning("AnimatedSprite2D node not found when showing doors closed.")

func show_doors_opened():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        elevator_doors.stop()
        elevator_doors.visible = false
        # print("Doors are opened (not visible).")
    else:
        push_warning("AnimatedSprite2D node not found when showing doors opened.")

func animate_doors_opening():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        elevator_doors.visible = true
        elevator_doors.play("opening")
        # print("Animating doors opening.")
    else:
        push_warning("AnimatedSprite2D node not found when animating doors opening.")

func animate_doors_closing():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        elevator_doors.visible = true
        elevator_doors.play("closing")
        # print("Animating doors closing.")
    else:
        push_warning("AnimatedSprite2D node not found when animating doors closing.")

func _on_doors_animation_finished():
    var elevator_doors = $AnimatedSprite2D
    if elevator_doors:
        var current_anim = elevator_doors.animation
        # print("Doors animation finished: ", current_anim)
        if current_anim == "opening" and door_state == DoorState.OPENING:
            set_door_state(DoorState.OPEN)
            # print("Doors have fully opened.")
        if current_anim == "closing" and door_state == DoorState.CLOSING:
            set_door_state(DoorState.CLOSED)
            # print("Doors have fully closed.")
            
            
            

    else:
        push_warning("AnimatedSprite2D node not found when handling animation finished.")

#region Elevator Door Set-Up
func apply_scale_factor_to_elevator():
    var elevator_sprite = $Frame
    if elevator_sprite:
        elevator_sprite.scale *= SCALE_FACTOR

        # print("Applied scale factor to elevator frame.")
    else:
        push_warning("Elevator sprite node not found to apply scale factor.")

func position_elevator():    
    var edges_global = floor_instance.collision_edges
    var left_edge_local   = edges_global["left"]   - floor_instance.global_position.x
    var right_edge_local  = edges_global["right"]  - floor_instance.global_position.x
    var bottom_edge_local = edges_global["bottom"] - floor_instance.global_position.y
    # var top_edge_local = edges_global["top"] -  - floor_instance.global_position.y
    
    var floor_center_x_local = (left_edge_local + right_edge_local) * 0.5
    var elevator_height = get_elevator_height()

    var elevator_bottom_aligned_y = bottom_edge_local - (elevator_height / 2)
    position = Vector2(floor_center_x_local, elevator_bottom_aligned_y)



func get_elevator_height():
    var elevator_sprite = $Frame
    if elevator_sprite and elevator_sprite.texture:
        return elevator_sprite.texture.get_height() * elevator_sprite.scale.y
    else:
        push_warning("Elevator sprite node not found or has no texture.")
        return 0

func update_elevator_door_collision_shape():
    var elevator_sprite = $Frame
    var collision_shape = $CollisionShape2D
    if elevator_sprite and collision_shape:
        var width = elevator_sprite.texture.get_width() * elevator_sprite.scale.x
        var height = elevator_sprite.texture.get_height() * elevator_sprite.scale.y
        var rectangle_shape = RectangleShape2D.new()
        rectangle_shape.extents = Vector2(width / 2, height / 2)
        collision_shape.shape = rectangle_shape
        # print("Updated elevator door collision shape.")
    else:
        push_warning("Cannot update collision shape: Missing nodes or textures")

func setup_elevator_doors_position():
    var elevator_doors = $AnimatedSprite2D
    if not elevator_doors:
        push_warning("AnimatedSprite2D node not found in Elevator scene.")
        return

    elevator_doors.scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)
    var door_texture = elevator_doors.sprite_frames.get_frame_texture("closed", 0)
    var door_height = 0
    if door_texture:
        door_height = door_texture.get_height() * elevator_doors.scale.y
    var elevator_height = get_elevator_height()
    var door_y_offset = (elevator_height - door_height) / 2
    elevator_doors.position = Vector2(0, door_y_offset)

    # Initially show doors closed
    set_door_state(DoorState.CLOSED)
    # print("Elevator doors set up and initially closed.")
#endregion
```

## File: Scripts/floor.gd
```
# floor.gd -> do not remove this comment!
extends Area2D

@export var floor_number: int = 0
@export var floor_image_path: String
var floor_sprite: Sprite2D
var collision_edges: Dictionary = {}

const DOOR_SCENE = preload("res://Scenes/Door.tscn")
const KIOSK_SCENE = preload("res://Scenes/Kiosk.tscn")
const ELEVATOR_SCENE = preload("res://Scenes/Elevator.tscn")
const PORTER_SCENE = preload("res://Scenes/Porter.tscn")
const ROOMBOARD_SCENE = preload("res://Scenes/Roomboard.tscn")

const BOUNDARIES = {
    "x1": 0.0715,  # Left boundary
    "x2": 0.929,   # Right boundary
    "y1": 0.0760,  # Top boundary
    "y2": 1   # Bottom boundary
}

func _ready():
    add_to_group("floors")
    input_pickable = true    
    floor_sprite = $FloorSprite
    set_floor_image(floor_image_path)    
    collision_layer = 1    
    
    self.connect("area_entered", Callable(self, "_on_floor_area_entered"))

func _on_floor_area_entered(area: Area2D) -> void:    
    if area.get("sprite_data_new"):        # # Check if the area that entered belongs to a sprite
        SignalBus.floor_area_entered.emit(area, floor_number)
        # print("Sprite '%s' entered floor %d" % [area.name, floor_number])
    if area.get("cabin_data"):
        SignalBus.floor_area_entered.emit(area, floor_number)

func _input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:        
        SignalBus.navigation_click.emit(
            event.global_position,
            floor_number,
            -1  # We use -1 since this is not a door
        )
        # print("_input_event: click_global_position: ", event.global_position)   # is the wrong value, but that's ok, we will adjust it
    #if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:        
        #var floor_collision_edges = get_collision_edges()        
        #var bottom_edge_y = collision_edges["bottom"]
        #SignalBus.floor_clicked.emit(
            #floor_number,
            #event.global_position,
            #bottom_edge_y,
            #floor_collision_edges
        #)
  
func get_collision_edges() -> Dictionary:    
    # is called when a sprite moves to a new floor to determine the y-coordinate    
    return collision_edges

#region set-up methods

func position_floor(previous_floor_top_y_position, is_first_floor):
    if not floor_sprite:
        push_warning("Floor instance is missing FloorSprite node!")
        return previous_floor_top_y_position  # Return previous value to avoid errors

    var viewport_size = get_viewport().size
    var floor_height = floor_sprite.texture.get_height() * floor_sprite.scale.y    
    var x_position = viewport_size.x / 2
    var y_position = 0.0

    if is_first_floor:
        # Center the first floor vertically
        y_position = (viewport_size.y - floor_height) / 1.5
    else:
        # Stack the floor above the previous floor
        y_position = previous_floor_top_y_position - floor_height
    
    position = Vector2(x_position, y_position)    
    configure_collision_shape()
    # Return the y position of the top of this floor for the next calculation
    return y_position


func configure_collision_shape():
    
    var collision_shape = $CollisionShape2D
    if not (floor_sprite and collision_shape):
        push_warning("Missing nodes for collision shape configuration")
        return

    # Calculate sprite dimensions
    var sprite_width = floor_sprite.texture.get_width() * floor_sprite.scale.x
    var sprite_height = floor_sprite.texture.get_height() * floor_sprite.scale.y
    var collision_width = (BOUNDARIES.x2 - BOUNDARIES.x1) * sprite_width
    var collision_height = (BOUNDARIES.y2 - BOUNDARIES.y1) * sprite_height
    var delta_x = ((BOUNDARIES.x1 + BOUNDARIES.x2) / 2 - 0.5) * sprite_width
    var delta_y = ((BOUNDARIES.y1 + BOUNDARIES.y2) / 2 - 0.5) * sprite_height

    # Configure the collision shape
    var rectangle_shape = RectangleShape2D.new()
    rectangle_shape.extents = Vector2(collision_width / 2, collision_height / 2)
    collision_shape.shape = rectangle_shape
    collision_shape.position = Vector2(delta_x, delta_y)
    
    var floor_global_position = global_transform.origin  # Get the global position of the floor
    var top_left = floor_global_position + Vector2(delta_x - collision_width / 2, delta_y - collision_height / 2)
    var bottom_right = floor_global_position + Vector2(delta_x + collision_width / 2, delta_y + collision_height / 2)
    
    collision_edges = {
        "left": top_left.x,
        "right": bottom_right.x,
        "top": top_left.y,
        "bottom": bottom_right.y
    }

func set_floor_image(image_path: String):
    if image_path.is_empty():
        push_warning("Image path is empty!")
        return

    var texture = load(image_path)
    if texture:
        floor_sprite.texture = texture
    else:
        push_error("Failed to load floor image at path: " + image_path)
        var file = FileAccess.open(image_path, FileAccess.READ)
        if file:
            print("File exists but couldn't be loaded as texture")
        else:
            print("File does not exist at path: " + image_path)

func setup_doors(door_data_array):
    for door_data in door_data_array:
        var door_instance
        # print("room name: ", door_data.room_name)
        
        if door_data.room_name.to_lower() == "roomboard":
            door_instance = ROOMBOARD_SCENE.instantiate()
        
        elif door_data.room_name.to_lower() == "porter":
            door_instance = PORTER_SCENE.instantiate()
        #elif 
        else:
            door_instance = DOOR_SCENE.instantiate()
        
        door_instance.name = "Door_" + str(door_data.index)
        door_instance.door_data = door_data
        door_instance.floor_instance = self
        
        add_child(door_instance)
        



## if we had a setup kiosk


func setup_elevator():
    var elevator_instance = ELEVATOR_SCENE.instantiate()
    elevator_instance.name = "Elevator"
    add_child(elevator_instance)
    elevator_instance.setup_elevator_instance(self)
        
#endregion
```

## File: Scripts/magical_elevator.gd
```
extends Area2D

@onready var navigation_controller: Node = get_tree().get_root().get_node("Main/Navigation_Controller")
@onready var cabin_sprite: Sprite2D = $Sprite2D
@onready var cabin_data: Node = $Cabin_Data
@onready var queue_manager: Node = $Queue_Manager
@onready var elevator_state_manager: Node = $Elevator_StateMachine


func _ready():    
    set_up_elevator_cabin()    
    z_index = -10
    add_to_group("cabin")    


func _process(delta) -> void:    
    # elevator_state_manager.process_elevator_state()  # rename to update or check elevator state to better indicate what the responsibility is
    
    match cabin_data.elevator_state:
        cabin_data.ElevatorState.IDLE:            
            process_idle()
        cabin_data.ElevatorState.WAITING:
            process_waiting()            
        cabin_data.ElevatorState.DEPARTING:            
            process_departing()                        
        cabin_data.ElevatorState.TRANSIT: 
            process_transit(delta)
        cabin_data.ElevatorState.ARRIVING:
            process_arriving()
        _:
            push_warning("unknow state in process_cabin_states")                            
            pass


func process_arriving() -> void:
    
    if cabin_data.doors_closed:
        cabin_data.current_floor = cabin_data.destination_floor
        var elevator = cabin_data.floor_to_elevator.get(cabin_data.current_floor, null)
        if elevator:
            elevator.set_door_state(elevator.DoorState.OPENING)
            cabin_data.doors_opening = true
            cabin_data.doors_closed = false
            if cabin_data.elevator_occupied:
                var current_request = queue_manager.elevator_queue[0]
                var current_sprite = current_request["sprite_name"]
                # print("emitting ready to exit signal for: ", current_sprite)
                SignalBus.elevator_arrived_at_destination.emit(current_sprite)
                
    elevator_state_manager.process_arriving()



func process_transit(delta):
    move_elevator(delta)
    elevator_state_manager.process_transit()



func process_departing():
    # print("process departing in main elevator script")
    
    if not cabin_data.cabin_timer.is_stopped():
            stop_waiting_timer()
    
    if not cabin_data.doors_closed:  
        if (cabin_data.elevator_occupied and cabin_data.sprite_entered) or not cabin_data.elevator_occupied:        
            _close_elevator_doors()
            cabin_data.elevator_ready_emitted = false
            
    cabin_data.blocked_sprite = ""
    elevator_state_manager.process_departing()

    

func _close_elevator_doors():
    
        var elevator = cabin_data.floor_to_elevator.get(cabin_data.current_floor, null)
        if elevator and not cabin_data.doors_closing == true:
            elevator.set_door_state(elevator.DoorState.CLOSING)
            cabin_data.doors_closing = true
            cabin_data.doors_open = false        



func _on_elevator_door_state_changed(new_state):

    var elevator = cabin_data.floor_to_elevator.get(cabin_data.current_floor, null)
    if elevator == null:
        return

    match new_state:
        elevator.DoorState.OPEN:
            # print("doors are now open")
            cabin_data.doors_open = true
            cabin_data.doors_opening = false

        elevator.DoorState.CLOSED:
            # print("doors are now closed")
            cabin_data.doors_closed = true
            cabin_data.doors_closing = false
            set_elevator_direction()
            update_destination_floor()
            


func update_destination_floor() -> void:
    # print("update destination floor")

    if not queue_manager.elevator_queue[0]:
        push_warning("queue is empty when trying to update the destination floor. func update_destination_floor() in cabin_new")
        return
    var current_request = queue_manager.elevator_queue[0]
    
    if cabin_data.elevator_occupied:
        cabin_data.destination_floor = current_request["destination_floor"]
    else:
        cabin_data.destination_floor = current_request["pick_up_floor"]        
    cabin_data.target_position = cabin_data.floor_to_target_position[cabin_data.destination_floor]
    

func set_elevator_direction() -> void:
    var new_direction: int = 0
    
    if queue_manager.elevator_queue.size() > 0:
        var next_floor: int
        if cabin_data.elevator_occupied:
            next_floor = queue_manager.elevator_queue[0]["destination_floor"]
        else:
            next_floor = queue_manager.elevator_queue[0]["pick_up_floor"]        
        if next_floor > cabin_data.current_floor:
            new_direction = 1   # going up
        elif next_floor < cabin_data.current_floor:
            new_direction = -1  # going down
        else:
            new_direction = 0   # same floor
    else:
        new_direction = 0      # no requests => no movement
    
    cabin_data.elevator_direction = new_direction

func move_elevator(delta: float) -> void:
    if cabin_data.target_position == Vector2.ZERO:        
        return  # Elevator doesn't have a target different from it's current position, so just return

    # Only stop if it's actually running:
    if not cabin_data.cabin_timer.is_stopped():
        # push_warning("Cabin timer is running while cabin is moving. Stopping it now.")
        cabin_data.cabin_timer.stop() # prevent the timer from removing requests while the current request is being processed, which could lead to an out-of-bounds error in on_arrival

    var elevator = cabin_data.floor_to_elevator.get(cabin_data.current_floor, null)    
    if elevator.door_state != elevator.DoorState.CLOSED:
        return
    
    var direction = sign(cabin_data.target_position.y - global_position.y)
    var movement = cabin_data.SPEED * delta * direction
    var new_y = global_position.y + movement
    
    if (direction > 0 and new_y >= cabin_data.target_position.y) or (direction < 0 and new_y <= cabin_data.target_position.y): # on arrival
        global_position.y = cabin_data.target_position.y
        reset_elevator_direction()        
    
    else: # keep moving towards destination
        global_position.y = new_y
    
    if cabin_data.elevator_occupied: 
        SignalBus.elevator_position_updated.emit(global_position, queue_manager.elevator_queue[0]["sprite_name"])

func reset_elevator_direction() -> void:
    if cabin_data.elevator_direction != 0:
        cabin_data.elevator_direction = 0
        # _print_elevator_direction()


#region Process Idle State
func process_idle():
    # print("process idle")
    check_elevator_queue()
    elevator_state_manager.process_idle()

func check_elevator_queue() -> bool:
    cabin_data.elevator_busy = queue_manager.elevator_queue.size() != 0
    return cabin_data.elevator_busy
    
#endregion


#region Process Waitting State


func process_waiting():
    # print("process waiting in main elevator script")
    if not check_elevator_queue():
        '''this check could be done directly inside the state machine?'''
        elevator_state_manager.process_waiting()
        return
    # print("elevator is busy") 
    if not cabin_data.elevator_ready_emitted:
        # print("emitting ready_on_waiting signal in main elevator script")
        emit_ready_on_waiting()

    is_at_first_request_pickup_floor()
    ## start the timer only if we are the first request pick-up floor, else leave now. 
    ## should not matter, since we are leaving next frame
    
    if cabin_data.cabin_timer.is_stopped():    
        start_waiting_timer()

    # print("updating elevator state at the end of the main scripts process_waiting function")
    elevator_state_manager.process_waiting()


func emit_ready_on_waiting():
    print("emit_ready_on_waiting")
    
    var elevator_ready_status: bool = true
    var requests_at_floor: Array = []
    
    for request in queue_manager.elevator_queue:
        if request["pick_up_floor"] == cabin_data.current_floor \
            and request["sprite_name"] != cabin_data.blocked_sprite:
            requests_at_floor.append(request)
    
    for request_data in requests_at_floor:
        print("emitting request signal with actual value to ", request_data["sprite_name"])
        SignalBus.elevator_request_confirmed.emit(request_data, elevator_ready_status)
        
        
        if cabin_data.elevator_occupied:
            cabin_data.elevator_ready_emitted = true
            if not cabin_data.cabin_timer.is_stopped():
                stop_waiting_timer()
            break

    cabin_data.elevator_ready_emitted = true
    cabin_data.blocked_sprite = ""

    


func is_at_first_request_pickup_floor() -> void:
    # print("cabin_data.current_floor: ", cabin_data.current_floor)
    var first_request = queue_manager.elevator_queue[0]
    if first_request["pick_up_floor"] == cabin_data.current_floor:
        cabin_data.pick_up_on_current_floor = true
    else: 
        cabin_data.pick_up_on_current_floor = false
#endregion


#region Process New Requests

enum ElevatorRequestType {
    ADD,
    UPDATE,
    OVERWRITE,
    SHUFFLE,
}
func _on_elevator_request(elevator_request_data: Dictionary) -> void:
        
    var new_request: Dictionary = elevator_request_data
    
    var sprite_name: String = elevator_request_data["sprite_name"]
    
    if sprite_name == cabin_data.blocked_sprite:
        return
    
    var sprite_elevator_request_id: int = elevator_request_data["request_id"]        
    var request_type = _categorize_incomming_elevator_request(sprite_name, sprite_elevator_request_id)
    # print("request type for ", sprite_name, " is ", request_type)     
    var processed_request = _handle_request_by_type(request_type, new_request)
    var elevator_ready_status: bool = _check_ready_status_on_request(new_request) ## ensure ready status on request is independent of position in queue
    
    if sprite_name != cabin_data.blocked_sprite:        
        # print("emitting request signal with actual value to ", sprite_name)
        SignalBus.elevator_request_confirmed.emit(processed_request, elevator_ready_status)
    else:
        # print("emitting request signal with false to ", sprite_name)
        SignalBus.elevator_request_confirmed.emit(processed_request, false)
            
    


func _handle_request_by_type(request_type: int, new_request: Dictionary) -> Dictionary:
    match request_type:
        ElevatorRequestType.ADD:
            return queue_manager.add_to_elevator_queue(new_request)
        ElevatorRequestType.OVERWRITE:
            return queue_manager.overwrite_elevator_request(new_request)
        ElevatorRequestType.UPDATE:
            return queue_manager.update_elevator_request(new_request)
        ElevatorRequestType.SHUFFLE:
            return queue_manager.shuffle(new_request)
        _:
            push_warning("Unknown request type: ", str(request_type))
            return {}


func _is_elevator_on_same_floor(current_floor: int, pickup_floor: int) -> bool:
    return current_floor == pickup_floor

func _is_elevator_available(current_state: int) -> bool:
    return current_state == cabin_data.ElevatorState.IDLE \
        or current_state == cabin_data.ElevatorState.WAITING

func _check_ready_status_on_request(elevator_request_data: Dictionary) -> bool:
    var pickup_floor: int = elevator_request_data["pick_up_floor"]    
    var current_state: int = cabin_data.elevator_state    
    var current_floor: int = cabin_data.current_floor
    var occupied: bool = cabin_data.elevator_occupied
    
    var elevator_on_same_floor: bool = _is_elevator_on_same_floor(current_floor, pickup_floor)
    var elevator_available: bool = _is_elevator_available(current_state)

    if elevator_on_same_floor and elevator_available and not occupied:
        return true
    
    return false

 
func _categorize_incomming_elevator_request(sprite_name: String, sprite_elevator_request_id: int) -> ElevatorRequestType:
    
    # Check if the sprite already has a request in the queue.
    var sprite_already_has_a_request_in_the_queue: bool = queue_manager.does_sprite_have_a_request_in_queue(sprite_name)
    if not sprite_already_has_a_request_in_the_queue:
        # if not, add the request to the end of the queue
        return ElevatorRequestType.ADD
    else:
        # Check if the existing request matches the current one.
        var update_existing_request: bool = queue_manager.does_request_id_match(sprite_elevator_request_id)
        if update_existing_request:
            # update the existing request
            return ElevatorRequestType.UPDATE
        else: 
            # edge case: sprite has walked away after making a request earlier and will now be repositioned to end of the queue at the current floor (other sprites have taken the spot)
            return ElevatorRequestType.SHUFFLE
#endregion

func _on_sprite_entering_elevator(sprite_name: String):
    print("Elevator: Sprite ", sprite_name, " has begun to enter the elevator")
    
    if not cabin_data.cabin_timer.is_stopped():
        stop_waiting_timer()
    
    var first_request = queue_manager.elevator_queue[0]
    if first_request["sprite_name"] != sprite_name:        
        queue_manager.move_request_to_top(sprite_name)
    # Lock the elevator, since only one sprite is allowed at a time
    cabin_data.elevator_occupied = true    

func _on_sprite_enter_animation_finished(_sprite_name: String, _stored_target_floor: int):
    ## arguments are never used
    cabin_data.sprite_entered = true
    # print("enter animation finished from sprite: ", sprite_name)    
    pass

func _on_sprite_exiting(sprite_name) -> void:
    reset_elevator()
    cabin_data.blocked_sprite = sprite_name
    

func reset_elevator() -> void:
    print("resetting elevator status")
    ## arguments are never used
    cabin_data.elevator_occupied = false
    cabin_data.sprite_entered = false
    cabin_data.elevator_ready_emitted = false
    queue_manager.remove_request_from_queue()
    cabin_data.pick_up_on_current_floor = false
    cabin_data.elevator_ready = false    
    cabin_data.elevator_direction = false
  
#region CabinTimer
func setup_cabin_timer(wait_time: float) -> void:
    var new_timer = Timer.new()
    new_timer.one_shot = true
    new_timer.wait_time = wait_time
    new_timer.timeout.connect(_on_cabin_timer_timeout)    
    add_child(new_timer)
    cabin_data.cabin_timer = new_timer
    # print("In timer setup: cabin_data.cabin_timer: ", cabin_data.cabin_timer)


func start_waiting_timer() -> void:
    
    
    if not cabin_data.cabin_timer.is_stopped():
        push_warning("cabin timer already started, returning immediately.")
        return
        
    # Only start the timer if there's at least one request for the current floor.
    
    if not queue_manager.elevator_queue.is_empty():
        # print("starting timer")
        cabin_data.cabin_timer.start()
        # print("timer started")

func stop_waiting_timer() -> void:
    
    if cabin_data.cabin_timer == null:
        push_warning("cabin timer not set-up in stop_waiting_timer")
        return

    if cabin_data.cabin_timer.is_stopped():
        push_warning("cabin timer is not running; nothing to stop.")
        return
    # print("stopping timer")
    cabin_data.cabin_timer.stop()
    # print("cabin timer stopped")

func _on_cabin_timer_timeout() -> void:    
    
    if cabin_data.elevator_state != cabin_data.ElevatorState.WAITING and cabin_data.elevator_state != cabin_data.ElevatorState.DEPARTING:
        push_warning("Timer timed out but elevator state is neither WAITING nor DEPARTING.")
        return

    if queue_manager.elevator_queue.is_empty():
        push_warning("Elevator queue is empty on timer timeout.")
        return
    
    # print("timer timeout")
    queue_manager.remove_request_on_waiting_timer_timeout(cabin_data.current_floor)
        
#endregion

#region Set-Up

func set_up_elevator_cabin(): 
    add_to_group("cabin")
    apply_scale_factor()
    position_cabin()
    connect_to_signals()
    cache_elevators()
    cache_floor_positions()
    setup_cabin_timer(2.0)  # setup_cabin_timer(cabin_data.cabin_timer_timeout)

    var elevator = get_elevator_for_current_floor()
    elevator.set_door_state(elevator.DoorState.OPEN)

func apply_scale_factor():
    # Instead of referencing a local constant, use the child node’s data:
    scale = Vector2.ONE * cabin_data.SCALE_FACTOR

func position_cabin():    
    var viewport_size = get_viewport().size
    var x_position = viewport_size.x / 2

    var floors_dict: Dictionary = navigation_controller.floors
    var floor_data = floors_dict[cabin_data.current_floor]  # Moved from local var to cabin_data
    var collision_edges = floor_data["edges"] 
    var bottom_edge_y = collision_edges["bottom"]
    var cabin_height = get_cabin_height()
    var y_position = bottom_edge_y - (cabin_height / 2)

    global_position = Vector2(x_position, y_position)

func get_cabin_height():
    var sprite = get_node("Sprite2D")  # Adjust if needed
    if sprite and sprite.texture:
        # Use cabin_data.scale.y if you are scaling from cabin_data, 
        # or continue using `scale.y` if the node’s actual scale is correct
        return sprite.texture.get_height() * scale.y
    else:
        return 0

func get_elevator_position(collision_edges: Dictionary) -> Vector2:
    var center_x: float = (collision_edges["left"] + collision_edges["right"]) / 2
    var sprite_height: float = get_cabin_height()
    var adjusted_y: float = collision_edges["bottom"] - sprite_height / 2
    return Vector2(center_x, adjusted_y)

func cache_elevators():
    var elevators_dict: Dictionary = navigation_controller.elevators
    for floor_number in elevators_dict.keys():
        var elevator_data = elevators_dict[floor_number]        
        cabin_data.floor_to_elevator[floor_number] = elevator_data["ref"]

func cache_floor_positions():
    var floors_dict: Dictionary = navigation_controller.floors
    for floor_number in floors_dict.keys():
        var floor_data = floors_dict[floor_number]
        var collision_edges = floor_data["edges"]
        var target_pos = get_elevator_position(collision_edges)
        cabin_data.floor_to_target_position[floor_number] = target_pos

        var floor_bottom = collision_edges["bottom"]
        var floor_top    = collision_edges["top"]
        var height       = floor_bottom - floor_top
        var lower_edge   = floor_top
        var upper_edge   = floor_top + (height * 1.25)

        cabin_data.floor_boundaries[floor_number] = {
            "upper_edge": upper_edge,
            "lower_edge": lower_edge
        }

func get_elevator_for_current_floor() -> Node:
    return cabin_data.floor_to_elevator[cabin_data.current_floor]

func connect_to_signals():    
    SignalBus.elevator_called.connect(_on_elevator_request)
    SignalBus.entering_elevator.connect(_on_sprite_entering_elevator)
    SignalBus.enter_animation_finished.connect(_on_sprite_enter_animation_finished)
    SignalBus.door_state_changed.connect(_on_elevator_door_state_changed)
    SignalBus.exit_animation_finished.connect(_on_sprite_exiting)
    
    SignalBus.floor_area_entered.connect(_on_floor_area_entered)


func _on_floor_area_entered(area: Area2D, floor_number: int) -> void:
    if area == self:
        cabin_data.current_floor = floor_number
        # print("Elevator has entered floor #%d" % [floor_number])  


#endregion
```

## File: Scripts/main.gd
```
extends Node2D
```

## File: Scripts/movement_component.gd
```
extends Node

func move_sprite(delta: float, sprite_data_new: Resource, owner_node: Node) -> void:
    # Only move if the sprite is in a walking state
    if sprite_data_new.movement_state == sprite_data_new.MovementState.WALKING:
        move_towards_position(sprite_data_new, owner_node, delta)

func move_towards_position(sprite_data_new: Resource, owner_node: Node, delta: float) -> void:
    # Lock the target's Y to the current_position, for horizontal-only movement.
    var target_position = sprite_data_new.target_position
    target_position.y = sprite_data_new.current_position.y

    var direction = (target_position - sprite_data_new.current_position).normalized()
    var distance = sprite_data_new.current_position.distance_to(target_position)

    if distance > 13.0:
        # Move incrementally
        var new_x = sprite_data_new.current_position.x + direction.x * sprite_data_new.speed * delta
        sprite_data_new.set_current_position(
            Vector2(new_x, sprite_data_new.current_position.y),
            sprite_data_new.current_floor_number,
            sprite_data_new.current_room
        )
        # Update the *actual* sprite node
        owner_node.global_position.x = new_x
    else:
        # Snap to final target
        var new_x = sprite_data_new.target_position.x
        sprite_data_new.set_current_position(
            Vector2(new_x, sprite_data_new.target_position.y),
            sprite_data_new.current_floor_number,
            sprite_data_new.current_room
        )
        owner_node.global_position.x = new_x
```

## File: Scripts/navigation_controller.gd
```
# navigation_controller.gd
extends Node

const SpriteDataNew = preload("res://Data/SpriteData_new.gd")

var floors: Dictionary = {}
var doors: Dictionary = {}
var player: Dictionary = {}
var elevators: Dictionary = {}

func _ready():
    
    register_all_floors()
    register_all_doors()    
    register_all_elevators()
    # print_all_registered()

    SignalBus.navigation_click.connect(_on_navigation_click)
    SignalBus.all_sprites_ready.connect(_on_sprites_ready)    
    
    '''For testing the elevator with random AI sprite destination floors'''
    # randomize()



func _on_sprites_ready():
    # print("sprites ready signal received")  # is being printed once
    register_sprites()
    # print_all_registered()


func _on_navigation_command(sprite_name: String, destination_floor_number: int, destination_door_index: int, commander: String, adjusted_position: Vector2) -> void:
    SignalBus.adjusted_navigation_command.emit(commander, sprite_name, destination_floor_number, destination_door_index, adjusted_position )


var count: int = 0

func _on_navigation_click(global_position: Vector2, floor_number: int, door_index: int) -> void:    
    # print("click recorded")
    var click_data: Dictionary = _determine_click_type(door_index, floor_number, global_position)
    var edges: Dictionary = click_data["edges"]
    var initial_click_pos: Vector2 = click_data["initial_click_pos"]
    var adjusted_click_position: Vector2 = _adjust_click_position(edges, initial_click_pos)
    # print("adjusted_click_position: ", adjusted_click_position)
    var commander: String = "player_input"
    # print("_on_navigation_click: global_position: ", global_position)    
    _on_navigation_command("Player", floor_number, door_index, commander, adjusted_click_position)
    
    
    #if count == 0:
        #_on_navigation_command("AI_SPRITE", floor_number, door_index, commander, adjusted_click_position)
        #count = count + 1
    #if count == 0:
        #var random_floor = get_random_floor()
        ## setting room to -1 so the AI sprite does not get caught up in the elevator room (where it should never be)
        #_on_navigation_command("AI_SPRITE", random_floor, -1, commander, adjusted_click_position)
        ## _on_navigation_command("DECO_SPRITE", 4 + 1, -1, commander, adjusted_click_position)
        #count += 1


func get_random_floor() -> int:
    # randi() % 14 yields an integer from 0 to 13.
    return randi() % 5





func _determine_click_type(door_index: int, floor_number: int, global_position: Vector2) -> Dictionary:
    var edges: Dictionary
    var initial_click_pos: Vector2

    if door_index >= 0:
        # Door Click
        edges = doors[door_index]["edges"]
        var door_center_x = doors[door_index]["center_x"]
        var bottom_edge_y = edges["bottom"]
        initial_click_pos = Vector2(door_center_x, bottom_edge_y)

    elif door_index == -2:
        # Elevator Click
        edges = elevators[floor_number]["edges"]
        var elevator_center_x = elevators[floor_number]["position"].x
        var bottom_edge_y_elev = edges["bottom"]
        initial_click_pos = Vector2(elevator_center_x, bottom_edge_y_elev)

    else:
        # Floor Click (door_index == -1)
        edges = floors[floor_number]["edges"]
        # print("edges of floor 3 in nav controller: ", edges)  178
        initial_click_pos = global_position

    return {
        "edges": edges,
        "initial_click_pos": initial_click_pos
    }





func _adjust_click_position(collision_edges: Dictionary, click_position: Vector2) -> Vector2:
    # Correct way to access sprite dimensions from the nested dictionary
    var _sprite_data = player["Player"] # Player == name of the player sprite, player == name of the dictionary where we store the data
    var sprite_width: float = player["Player"]["width"]
    var sprite_height: float = player["Player"]["height"]

    var left_bound: float = collision_edges["left"]
    var right_bound: float = collision_edges["right"]
    var bottom_edge_y: float = collision_edges["bottom"]
    # print("bottom_edge_y in _adjust_click_position: ", bottom_edge_y)

    # Horizontal clamp
    var adjusted_x: float = click_position.x
    if adjusted_x < left_bound + sprite_width / 2:
        adjusted_x = left_bound + sprite_width / 2
    elif adjusted_x > right_bound - sprite_width / 2:
        adjusted_x = right_bound - sprite_width / 2

    # Vertical alignment (sprite stands on top of the bottom edge)
    var adjusted_y: float = bottom_edge_y - sprite_height / 2

    return Vector2(adjusted_x, adjusted_y)





       
func print_all_registered():
    #print("Print only the keys or the full dictionaries")
    # print("Floors: ", floors)
    #print("Doors: ", doors)
    print("Player: ", player) #.keys()
    # print("Elevators: ", elevators)

#region Register Areas

#--- Floors ---
func register_all_floors():
    var floor_nodes = get_tree().get_nodes_in_group("floors")
    for floor_node in floor_nodes:
        if floor_node is Area2D:
            var floor_number = floor_node.floor_number
            var floor_edges = floor_node.get_collision_edges()
            register_floor(floor_number, floor_edges, floor_node)

func register_floor(floor_number: int, floor_edges: Dictionary, floor_ref: Node):
    floors[floor_number] = {
        "edges": floor_edges,
        "ref": floor_ref
    }


#--- Doors ---
func register_all_doors():
    var door_nodes = get_tree().get_nodes_in_group("doors")
    for door_node in door_nodes:
        if door_node is Area2D:
            var door_index = door_node.door_data.index
            var floor_number = door_node.door_data.floor_number
            var door_center_x = door_node.door_center_x  # global X

            # Use the door node's own collision edges, not the parent's
            var door_edges = door_node.get_collision_edges()

            register_door(door_index, floor_number, door_center_x, door_edges, door_node)


func register_door(
    door_index: int,
    floor_number: int,
    center_x: float,
    door_edges: Dictionary,
    door_ref: Node
):
    doors[door_index] = {
        "floor_number": floor_number,
        "center_x": center_x,
        "edges": door_edges,    # store the door's collision edges
        "ref": door_ref
    }



#--- Elevators ---
#--- Elevators ---
func register_all_elevators():
    var elevator_nodes = get_tree().get_nodes_in_group("elevators")
    for elevator_node in elevator_nodes:
        if elevator_node is Area2D:
            var floor_number = elevator_node.floor_instance.floor_number
            
            # Get the collision shape for proper boundaries
            var collision_shape = elevator_node.get_node("CollisionShape2D")
            if not collision_shape:
                push_warning("No CollisionShape2D found in elevator")
                continue
                
            var shape = collision_shape.shape as RectangleShape2D
            if not shape:
                push_warning("Elevator must use RectangleShape2D")
                continue
                
            # Calculate edges using global coordinates
            var global_pos = elevator_node.global_position
            var extents = shape.extents
            
            var elevator_edges = {
                "left": global_pos.x - extents.x,
                "right": global_pos.x + extents.x,
                "top": global_pos.y - extents.y,
                "bottom": global_pos.y + extents.y,
                "center": global_pos
            }
            
            register_elevator(floor_number, elevator_edges, elevator_node)

func register_elevator(floor_number: int, edges: Dictionary, elevator_ref: Node):
    elevators[floor_number] = {
        "position": edges["center"],
        "edges": edges,
        "floor_number": floor_number,
        "ref": elevator_ref
    }


#--- Sprites ---
func register_sprites():
    # print("registering player sprites in nav controller") # is printed once
    var sprite_nodes = get_tree().get_nodes_in_group("sprites")
    # print("sprite_nodes: ", sprite_nodes)  # sprite_nodes is empty
    for node in sprite_nodes:    
        if node is Area2D:    # Player_new is an Area2D, all other nodes are not Area2D
            # print("node in register_sprites: ", node)
            # print("registering player sprite in register_sprites")
            register_all_sprites(node)

func register_all_sprites(player_node: Area2D):
    
    # print("in register player sprite") # is being printed twice
    # Fetch the correct property from player_node
    var sprite_data_new = player_node.get("sprite_data_new")
    # print("var data: ", data)
    if sprite_data_new is Resource:
        var sprite_name = sprite_data_new.sprite_name
        player[sprite_name] = {
            "name": sprite_data_new.sprite_name,
            "width": sprite_data_new.sprite_width,
            "height": sprite_data_new.sprite_height,
            "ref": player_node
        }
        # print("player dict in nav controller: ", player)  # prints the expected values
    else:
        push_warning(
            "The node '%s' does not have a valid sprite_data_new property of type SpriteDataNew."
            % player_node.name
        )




#endregion
```

## File: Scripts/pathfinder_component.gd
```
# Pathfinder.gd
extends Node
const SpriteDataNew = preload("res://Data/SpriteData_new.gd")
@onready var navigation_controller: Node = get_tree().get_root().get_node("Main/Navigation_Controller")


func determine_path(sprite_data_new: SpriteDataNew) -> bool:
    var stored_position_updated: bool = false
        
    if sprite_data_new.defer_input or not sprite_data_new.has_nav_data:
        # print("input defered / no new nav data: returning")
        return false

    
    if sprite_data_new.needs_elevator(sprite_data_new.nav_target_floor):
        #print(sprite_data_new.sprite_name, " needs to use the elevator.")
        var elevator_info = navigation_controller.elevators.get(sprite_data_new.current_floor_number, null)        
        var elevator_position = elevator_info["position"]        
        var new_target_position = Vector2(elevator_position.x, sprite_data_new.current_position.y)
        sprite_data_new.set_target_position(new_target_position, sprite_data_new.current_floor_number, sprite_data_new.current_room)
        sprite_data_new.set_stored_position(sprite_data_new.nav_target_position, sprite_data_new.nav_target_floor, sprite_data_new.nav_target_room)
        stored_position_updated = true
        # sprite_data_new.reset_elevator_status()
        
    else:
        #print(sprite_data_new.sprite_name, " does not need the elevator to switch floors.")
        sprite_data_new.set_target_position(
            sprite_data_new.nav_target_position, 
            sprite_data_new.nav_target_floor, 
            sprite_data_new.nav_target_room
        )
        
        if sprite_data_new.target_room == -2:
            print(sprite_data_new.sprite_name, " wants to enter the elevator room")            
            
        sprite_data_new.reset_stored_data()
        # print("sprite is walking, resetting the elevator status")
        # sprite_data_new.reset_elevator_status()
        stored_position_updated = false
 
    sprite_data_new.reset_nav_data()
    return stored_position_updated
```

## File: Scripts/player_new.gd
```
# player_new.gd
extends Area2D

@onready var navigation_controller := get_tree().get_root().get_node("Main/Navigation_Controller")
@onready var cabin := get_tree().get_root().get_node("Main/Magical_Elevator")

@export var state_manager: Node
@export var pathfinder: Node
const SpriteDataScript = preload("res://Data/SpriteData_new.gd")
var sprite_data_new: Resource = SpriteDataScript.new()

const SCALE_FACTOR = 2.3
var last_elevator_request: Dictionary = {"sprite_name": "", "floor_number": -1}
var previous_elevator_position: Vector2 = Vector2.ZERO


'''Testing'''
var initial_x: float
var timer: Timer
var prev_floor: int = -1  # Holds the previous random floor number



func _ready():
    # print("deco ready")
    # print("sprite_data_new: ", sprite_data_new)
    # sprite_data_new = SpriteDataScript.new()
    instantiate_sprite()
    connect_to_signals()    
    set_initial_position()

  
    '''Testing'''
    randomize()  # Seed the RNG
    
    # Store the initial x-coordinate from sprite_data_new
    initial_x = sprite_data_new.current_position.x
    
    # Create and configure the Timer node to call _on_timer_timeout every 2 seconds
    timer = Timer.new()
    timer.wait_time = 1.0  # Change to 2.0 seconds for production; was 0.05 for testing
    timer.one_shot = false
    timer.autostart = true
    add_child(timer)
    timer.timeout.connect(_on_timer_timeout)

'''Testing'''

func _on_timer_timeout() -> void:
    # Calculate a new x position by adding a random offset (here between -250 and 250) to the initial x
    var offset: float = randf_range(-250.0, 250.0)
    var new_x: float = initial_x + offset
    var new_position: Vector2 = Vector2(new_x, sprite_data_new.current_position.y)
    
    # Generate a random floor between 1 and 10.
    var random_floor: int = randi() % 3
    # Ensure that the new random floor is not the same as the previous one.
    while random_floor == prev_floor:
        random_floor = randi() % 3
    # Store the current random floor for the next call.
    prev_floor = random_floor
    
    # Call the navigation command with the new random floor and position.
    navigation_controller._on_navigation_command(sprite_data_new.sprite_name, random_floor, -1, "player_input", new_position)


func set_data(
    current_floor_number: int,
    current_room: int,
    target_floor_number: int,
    sprite_name: String,
    elevator_request_id: int
):
    # This replaces the old 'set_initial_data' from _ready().
    sprite_data_new.current_floor_number = current_floor_number
    sprite_data_new.current_room = current_room
    sprite_data_new.target_floor_number = target_floor_number
    sprite_data_new.sprite_name = sprite_name
    sprite_data_new.elevator_request_id = elevator_request_id



func _process(delta: float) -> void:   
    
    
    pathfinder.determine_path(sprite_data_new)
    # print("process state") 
    # print("sprite script calls process_state")
    state_manager.process_state(sprite_data_new)
    var active_state = sprite_data_new.get_active_state()
    
    if active_state == sprite_data_new.ActiveState.MOVEMENT:   
        # print("process movement")     
        move_sprite(delta)
        _animate_sprite()

    if active_state == sprite_data_new.ActiveState.ELEVATOR:
        # print("process elevator actions")
        _process_elevator_actions()

        

func _process_elevator_actions() -> void:
    # print(" in elevator state in player script")
    match sprite_data_new.elevator_state:
        
        sprite_data_new.ElevatorState.CALLING_ELEVATOR:            
            if not sprite_data_new.elevator_requested:
                call_elevator()        
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:              
                request_elevator_ready_status() 
                # pass
        sprite_data_new.ElevatorState.ENTERING_ELEVATOR:               
            if not sprite_data_new.entered_elevator:                
                enter_elevator()                            
        sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT:      
            _animate_sprite()
        sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM:      
            _animate_sprite()
        sprite_data_new.ElevatorState.EXITING_ELEVATOR:
            exit_elevator()        
        _:
                        
            pass


#region Elevator Movement



func call_elevator() -> void:
    
    if not confirm_sprite_can_interact_with_elevator():
        return
    
    var active_state = sprite_data_new.get_active_state()
    
    if active_state == sprite_data_new.ActiveState.MOVEMENT:   
        return
    
    if sprite_data_new.stored_target_floor == -1:                
        # print("------------------------ Calling Elevator: ", sprite_data_new.sprite_name)
        # print("stored target floor: ", sprite_data_new.stored_target_floor)
        return
        
    SignalBus.elevator_called.emit(
        sprite_data_new.sprite_name,
        sprite_data_new.current_floor_number, # pick_up_floor
        sprite_data_new.stored_target_floor,  # destination_floor
        sprite_data_new.elevator_request_id
    )
    _animate_sprite()
    sprite_data_new.elevator_requested = true





func _on_elevator_request_confirmed(incoming_sprite_name: String, request_id: int) -> void:
    
    # print("destination_floor of the confirmed request: ", destination_floor)
    # print("destination_floor of the sprite: ", sprite_data_new.stored_target_floor)
    
    if incoming_sprite_name == sprite_data_new.sprite_name:            
        sprite_data_new.elevator_request_id = request_id
        # print("Elevator request confirmed. Request ID =", request_id)            
        sprite_data_new.elevator_request_confirmed = true
        # print("request confirmed, requesting ready status")
        
        # check if a state update is needed
        state_manager._process_elevator_state(sprite_data_new)
        
        request_elevator_ready_status()

func confirm_sprite_can_interact_with_elevator() -> bool:
    var current_position: Vector2 = sprite_data_new.current_position

    # Retrieve the elevator data from the Navigation Controller using the elevator_request_id.
    var elevator_data = navigation_controller.elevators.get(sprite_data_new.current_floor_number)
    if elevator_data == null:
        # print("Elevator not found for id: ", sprite_data_new.elevator_request_id)
        return false

    # Get the center position of the elevator.
    var elevator_center: Vector2 = elevator_data["position"]

    # Check if the sprite is at the elevator's x position (ignoring y-coordinate).
    if not is_equal_approx(current_position.x, elevator_center.x):
        # print("Sprite is not at the elevator's x position: ", sprite_data_new.sprite_name)
        # get_tree().paused = true
        return false

    # Check if the stored target floor is valid.
    if sprite_data_new.stored_target_floor == -1:
        return false

    # Check if the sprite is already on the target floor.
    if sprite_data_new.current_floor_number == sprite_data_new.stored_target_floor:
        return false

    # Ensure the sprite's active state is ELEVATOR.
    var active_state = sprite_data_new.get_active_state()
    if active_state != sprite_data_new.ActiveState.ELEVATOR:
        # print("Sprite is not in elevator active state")
        return false

    # Retrieve elevator sub-state correctly as an ENUM (not a dictionary).
    var active_sub_state = sprite_data_new.elevator_state

    # Ensure the sub-state is either WAITING_FOR_ELEVATOR or CALLING_ELEVATOR.
    match active_sub_state:
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR, sprite_data_new.ElevatorState.CALLING_ELEVATOR:
            return true  # Valid states, return true

    # If we reach here, the sprite is in an invalid state.
    # print("Invalid elevator sub-state:", active_sub_state)
    return false


func request_elevator_ready_status() -> void:
    if not confirm_sprite_can_interact_with_elevator():
        return
    
    # If everything is valid, emit the signal.
    SignalBus.request_elevator_ready_status.emit(sprite_data_new.sprite_name, sprite_data_new.elevator_request_id)
  
            

func _on_elevator_ready(incoming_sprite_name: String, request_id: int):   
    #print("-----------PLAYER-----------")
    #print("ready signal received!")
    #print("ready signal request id: ", request_id)
    #print("sprite data request id: ", sprite_data_new.elevator_request_id)       
    if incoming_sprite_name != sprite_data_new.sprite_name:
        return
        
    if request_id != sprite_data_new.elevator_request_id:
        SignalBus.request_skippable.emit(sprite_data_new.sprite_name, sprite_data_new.elevator_request_id)
        return           
    
        
    if sprite_data_new.elevator_state != sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR and not sprite_data_new.ElevatorState.CALLING_ELEVATOR and not sprite_data_new.current_floor_number == sprite_data_new.stored_target_floor:    
        # print("sprite state is not waiting for elevator")
        
        SignalBus.request_skippable.emit(sprite_data_new.sprite_name, sprite_data_new.elevator_request_id)
        return
    # print("sprite_data_new.elevator_ready = true")     
    sprite_data_new.elevator_ready = true
    sprite_data_new.defer_input = true


func enter_elevator():    
    
    if not sprite_data_new.entering_elevator:        
        sprite_data_new.entering_elevator = true
        _animate_sprite() # $AnimatedSprite2D.play("enter")        
           
        var elevator_data = navigation_controller.elevators.get(sprite_data_new.current_floor_number, null)
        var cabin_height = cabin.get_cabin_height()
        var cabin_bottom_y = elevator_data["position"].y + (cabin_height * 0.5)
        var new_position = Vector2(
            elevator_data["position"].x,
            cabin_bottom_y - (sprite_data_new.sprite_height * 0.5)
        )
        sprite_data_new.set_current_position(new_position,sprite_data_new.current_floor_number,sprite_data_new.current_room)
        global_position = sprite_data_new.current_position
        z_index = -9
        # print("Sprite emits entering elevator signal")
        SignalBus.entering_elevator.emit(sprite_data_new.sprite_name, sprite_data_new.elevator_request_id, sprite_data_new.target_room)
    else:        
        return

    

func on_sprite_entered_elevator():    
    sprite_data_new.entered_elevator = true
    SignalBus.enter_animation_finished.emit(sprite_data_new.sprite_name, sprite_data_new.stored_target_floor)
    _animate_sprite()

func _on_elevator_ride(elevator_pos: Vector2, request_id: int) -> void:
    
    if sprite_data_new.elevator_request_id != request_id:
        return 

    if sprite_data_new.entered_elevator:
        var cabin_height = cabin.get_cabin_height()
        var cabin_bottom_y = elevator_pos.y + (cabin_height * 0.5)
        var new_position = Vector2(
            elevator_pos.x,
            cabin_bottom_y - (sprite_data_new.sprite_height * 0.5)
        )
        sprite_data_new.set_current_position(
            new_position,
            sprite_data_new.current_floor_number,
            sprite_data_new.current_room
        )
        global_position = sprite_data_new.current_position
        _animate_sprite()

func _on_elevator_at_destination(incoming_sprite_name: String, request_id: int):    
    if incoming_sprite_name == sprite_data_new.sprite_name and request_id == sprite_data_new.elevator_request_id and sprite_data_new.entered_elevator == true:        
        sprite_data_new.elevator_destination_reached = true

#func exit_elevator():
    #_animate_sprite()
    #var current_anim = $AnimatedSprite2D.animation
    #if current_anim == "exit" and sprite_data_new.elevator_destination_reached:
        #z_index = 0
        #SignalBus.exit_animation_finished.emit(sprite_data_new.sprite_name, sprite_data_new.elevator_request_id)
        #sprite_data_new.exited_elevator = true
        #sprite_data_new.set_target_position(
            #sprite_data_new.stored_target_position,
            #sprite_data_new.stored_target_floor,
            #sprite_data_new.stored_target_room
        #)
        #sprite_data_new.reset_stored_data()

func exit_elevator():    
    if not sprite_data_new.exiting_elevator:
        sprite_data_new.exiting_elevator = true
        _animate_sprite() 
    else:
        return
 

func on_sprite_exited_elevator():
    z_index = 0
    SignalBus.exit_animation_finished.emit(sprite_data_new.sprite_name, sprite_data_new.elevator_request_id)
    sprite_data_new.exited_elevator = true
    sprite_data_new.set_target_position(
        sprite_data_new.stored_target_position,
        sprite_data_new.stored_target_floor,
        sprite_data_new.stored_target_room
    )
    sprite_data_new.reset_stored_data()    
        
#endregion
        
        
#region Sprite Animation

func _animate_sprite() -> void:
    var direction = (sprite_data_new.target_position - sprite_data_new.current_position).normalized()
    var main_state = sprite_data_new.get_active_state()
    
    match main_state:
        sprite_data_new.ActiveState.MOVEMENT:
            match sprite_data_new.movement_state:
                sprite_data_new.MovementState.WALKING:
                    if direction.x > 0:
                        $AnimatedSprite2D.play("walk_to_right")
                    else:
                        $AnimatedSprite2D.play("walk_to_left")
                sprite_data_new.MovementState.IDLE:
                    $AnimatedSprite2D.play("idle")
                _:                    
                    push_warning("in _animate_sprite: Sprite is in no recognized state in _animate_sprite! - MovementState")
                    $AnimatedSprite2D.play("idle")
        
        sprite_data_new.ActiveState.ROOM:
            match sprite_data_new.room_state:
                sprite_data_new.RoomState.ENTERING_ROOM:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.RoomState.EXITING_ROOM:
                    $AnimatedSprite2D.play("exit")
                sprite_data_new.RoomState.IN_ROOM:
                    $AnimatedSprite2D.play("idle")                
                _:
                    push_warning("in _animate_sprite: Sprite is in no recognized state in _animate_sprite! - RoomState")
                    $AnimatedSprite2D.play("idle")
        
        sprite_data_new.ActiveState.ELEVATOR:
            match sprite_data_new.elevator_state:
                sprite_data_new.ElevatorState.CALLING_ELEVATOR:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.ElevatorState.ENTERING_ELEVATOR:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM:
                    $AnimatedSprite2D.play("idle")
                sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT:
                    $AnimatedSprite2D.play("idle")
                sprite_data_new.ElevatorState.EXITING_ELEVATOR:
                    $AnimatedSprite2D.play("exit")                    
                _:
                    push_warning("in _animate_sprite: Sprite is in no recognized state in _animate_sprite! - ElevatorState")
                    $AnimatedSprite2D.play("idle")

        _:
            push_warning("in _animate_sprite: Sprite is in no recognized state in _animate_sprite!")
            $AnimatedSprite2D.play("idle")
#endregion


#region Sprite Movement

func move_sprite(delta: float) -> void:
    if sprite_data_new.movement_state == sprite_data_new.MovementState.WALKING:
        move_towards_position(sprite_data_new.target_position, delta)

func move_towards_position(target_position: Vector2, delta: float) -> void:    
    target_position.y = sprite_data_new.current_position.y # Force horizontal-only movement by locking the target's Y to current_position.y
    
    var direction = (target_position - sprite_data_new.current_position).normalized()
    var distance = sprite_data_new.current_position.distance_to(target_position)
    
    if distance > 13.0:   # Speed / FPS
        var new_x = sprite_data_new.current_position.x + direction.x * sprite_data_new.speed * delta
        sprite_data_new.set_current_position(
            Vector2(new_x, sprite_data_new.current_position.y),
            sprite_data_new.current_floor_number,
            sprite_data_new.current_room
        )
        global_position.x = new_x
    else:
        # print("distance: ", distance)
        var new_x = sprite_data_new.target_position.x
        sprite_data_new.set_current_position(
            Vector2(new_x, sprite_data_new.target_position.y),
            sprite_data_new.current_floor_number,
            sprite_data_new.current_room
        )
        global_position.x = new_x
    


#endregion


#region set_initial_position
func set_initial_position() -> void:
    var current_floor_number: int = sprite_data_new.current_floor_number
    var floor_info: Dictionary = navigation_controller.floors[current_floor_number]

    var edges: Dictionary = floor_info["edges"]
    var center_x = (edges["left"] + edges["right"]) / 2.0
    var bottom_edge_y = edges["bottom"]
    var sprite_height = sprite_data_new.sprite_height
    var y_position = bottom_edge_y - (sprite_height / 2.0)

    global_position = Vector2(center_x, y_position)

    # Use setter functions to update current and target positions/floors
    sprite_data_new.set_current_position(
        global_position,
        current_floor_number,
        sprite_data_new.current_room
    )
    sprite_data_new.set_target_position(
        global_position,
        current_floor_number,
        sprite_data_new.target_room
    )
    # print("in set_initial_position: ", global_position)



#endregion


#region connect_to_signals
func connect_to_signals():
    SignalBus.adjusted_navigation_command.connect(_on_adjusted_navigation_command)
    SignalBus.floor_area_entered.connect(_on_floor_area_entered)
    SignalBus.elevator_request_confirmed.connect(_on_elevator_request_confirmed)
    SignalBus.elevator_ready.connect(_on_elevator_ready)
    SignalBus.elevator_ready.connect(_on_elevator_at_destination)
    SignalBus.elevator_position_updated.connect(_on_elevator_ride)
    SignalBus.queue_reordered.connect(_on_queue_reordered)
    
    $AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:    
    var anim_name = $AnimatedSprite2D.animation
    
    match anim_name:
        "enter":
            if sprite_data_new.elevator_ready:
                on_sprite_entered_elevator()

        "exit":
            if sprite_data_new.elevator_destination_reached:
                on_sprite_exited_elevator()        
            
            #sprite_data_new.entered_elevator = true
            #SignalBus.enter_animation_finished.emit(sprite_data_new.sprite_name, sprite_data_new.stored_target_floor)
            ## Maybe switch to idle or next state
            #_animate_sprite()

func _on_queue_reordered(sprite_name, request_id):
    
    if sprite_data_new.sprite_name == sprite_name and sprite_data_new.elevator_request_id == request_id:    
        sprite_data_new.elevator_ready = true
        state_manager.process_state(sprite_data_new)
        _process_elevator_actions()
        # request_elevator_ready_status()
    
    else:
        return
    

func _on_floor_area_entered(area: Area2D, floor_number: int) -> void:
    if area == self:
        sprite_data_new.set_current_position(
            sprite_data_new.current_position,  # keep the same position
            floor_number,                      # update floor
            sprite_data_new.current_room       # keep the same room index
        )
        # print("I, %s, have entered floor #%d" % [name, floor_number])    


func _on_adjusted_navigation_command(_commander: String, sprite_name: String, floor_number: int, door_index: int, click_global_position: Vector2) -> void:       
    # print("Navigation click received in ", sprite_data_new.sprite_name, " script")            
    if not sprite_name == sprite_data_new.sprite_name:
        return    
    # if target is elevator room on another floor, ensure we are setting destination to that position not the room
    if door_index == -2 and floor_number != sprite_data_new.current_floor_number:        
        door_index = -1            
    sprite_data_new.set_sprite_nav_data(click_global_position, floor_number, door_index)
    
    
#endregion


#region instantiate_sprite


#####################################################################################################
##################              Basic Sprite Component                        #######################  
#####################################################################################################

func instantiate_sprite():
    add_to_group("player_sprite")   # for other nodes explicitly referencing this player sprite
    add_to_group("sprites")
    # print("player is in group player_sprites")
    # sprite_data_new = SpriteDataNew.new()    
    apply_scale_factor_to_sprite()
    update_sprite_dimensions()
    update_collision_shape()    
    


func update_sprite_dimensions():
    var idle_texture = $AnimatedSprite2D.sprite_frames.get_frame_texture("idle", 0)
    if idle_texture:
        sprite_data_new.sprite_width = idle_texture.get_width() * $AnimatedSprite2D.scale.x
        sprite_data_new.sprite_height = idle_texture.get_height() * $AnimatedSprite2D.scale.y
    else:
        print("Warning: 'idle' animation (frame 0) not found.")


func update_collision_shape():    
    var collision_shape = $CollisionShape2D
    if collision_shape:
        var rect_shape = RectangleShape2D.new()
        rect_shape.size = Vector2(sprite_data_new.sprite_width, sprite_data_new.sprite_height)
        collision_shape.shape = rect_shape        
        collision_shape.position = Vector2.ZERO
    else:
        print("Warning: CollisionShape2D not found.")


func apply_scale_factor_to_sprite():
    var sprite = $AnimatedSprite2D
    if sprite:
        sprite.scale *= SCALE_FACTOR
        # print("Applied scale factor to player sprite.")
    else:
        push_warning("AnimatedSprite2D node not found for scaling.")



#endregion
```

## File: Scripts/porter.gd
```
# porter.gd (modified version)
extends Area2D

enum DoorState { CLOSED, OPEN }

var current_state: DoorState = DoorState.CLOSED
var door_type: int
var door_data: Dictionary
var floor_instance
var door_center_x: float = 0.0 

const SLOT_PERCENTAGES = [0.07]

@onready var door_sprite: Sprite2D = $Kiosk_Sprite_2D   ## we call it Kiosk because the room doesn't have a door, like a real-world kiosk.
@onready var collision_shape: CollisionShape2D = $Kiosk_Collision_Shape_2D 
# Remove tooltip reference:
# @onready var tooltip_background = $TooltipBackground

func _ready():
    add_to_group("doors")
    input_pickable = true
    connect("input_event", self._on_input_event)
    
    # Automatically perform setup if door_data and floor_instance are already assigned.
    if door_data != null and floor_instance != null:
        setup_door_instance(door_data, floor_instance)

func _on_input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        SignalBus.navigation_click.emit(
            event.global_position,
            door_data.floor_number,
            door_data.index
        )
        get_viewport().set_input_as_handled()

func set_door_state(new_state: DoorState) -> void:
    current_state = new_state

func _on_mouse_entered():
    SignalBus.show_tooltip.emit(door_data)

func _on_mouse_exited():
    SignalBus.hide_tooltip.emit()

func get_collision_edges() -> Dictionary:
    if not collision_shape:
        push_error("No CollisionShape2D found in door")
        return {}
        
    var shape = collision_shape.shape
    if not shape is RectangleShape2D:
        push_error("Door collision shape must be RectangleShape2D")
        return {}
        
    var extents = shape.extents
    var global_pos = collision_shape.global_position

    return {
        "left": global_pos.x - extents.x,
        "right": global_pos.x + extents.x,
        "top": global_pos.y - extents.y,
        "bottom": global_pos.y + extents.y
    }

#region door setup
func setup_door_instance(p_door_data, p_floor_instance):
    door_data = p_door_data
    floor_instance = p_floor_instance
    door_type = door_data.door_type
    
    # Set the door state to CLOSED by default.
    set_door_state(DoorState.CLOSED)
    
    # Position the door based on floor collision shape.
    position_door()
    
    # Update the collision shape to match the sprite's texture.
    update_collision_shape()
    
    # Remove tooltip setup code:
    # var final_tooltip = door_data.tooltip
    # if final_tooltip.find("{owner}") != -1:
    #     final_tooltip = final_tooltip.replace("{owner}", door_data.owner)
    # tooltip_background.set_text(final_tooltip)
    
    connect("mouse_entered", self._on_mouse_entered)
    connect("mouse_exited", self._on_mouse_exited)

func update_collision_shape() -> void:
    var dimensions = get_door_dimensions()
    if dimensions.width > 0 and dimensions.height > 0:
        var rectangle_shape = RectangleShape2D.new()
        rectangle_shape.extents = Vector2(dimensions.width / 2, dimensions.height / 2)
        collision_shape.shape = rectangle_shape
    else:
        push_warning("Cannot update collision shape: Invalid dimensions")

func position_door():
    # Retrieve the slot index from door data.
    var slot_index = door_data.door_slot
    
    var floor_collision_shape = floor_instance.get_node("CollisionShape2D")
    if not floor_collision_shape:
        push_warning("Missing CollisionShape2D node for door position calculation")
        return

    var shape = floor_collision_shape.shape
    if shape is RectangleShape2D:
        var rect_shape = shape as RectangleShape2D
        var collision_width = rect_shape.extents.x * 2
        var collision_left_edge = floor_collision_shape.global_position.x - rect_shape.extents.x
        var collision_edges = floor_instance.get_collision_edges()
        var bottom_edge_y = collision_edges["bottom"]
        
        var dimensions = get_door_dimensions()

        var local_x: float
        if slot_index >= 0 and slot_index < SLOT_PERCENTAGES.size():
            var percentage = SLOT_PERCENTAGES[slot_index]
            local_x = collision_left_edge + percentage * collision_width
        elif slot_index == 4:
            local_x = collision_left_edge + (dimensions.width / 2)
        else:
            push_warning("Invalid door slot index %d" % slot_index)
            return        

        var local_y = bottom_edge_y - (dimensions.height / 2)
        
        global_position = Vector2(local_x, local_y)
        door_center_x = local_x
    else:
        push_warning("Collision shape is not a RectangleShape2D")

func get_door_dimensions():
    var tex = door_sprite.texture
    if tex:
        var width = tex.get_width() * door_sprite.scale.x
        var height = tex.get_height() * door_sprite.scale.y
        return { "width": width, "height": height }
    return { "width": 0.0, "height": 0.0 }
#endregion
```

## File: Scripts/queue_manager_new.gd
```
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
    var dummy_request: Dictionary = {
        "pick_up_floor": 3,
        "destination_floor": 2,
        "sprite_name": "Test_Sprite",
        "request_id": 0
    }
    elevator_queue.append(dummy_request)   
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
```

## File: Scripts/roomboard.gd
```
# kiosk.gd (based on roomboard.gd)
extends Area2D

enum DoorState { CLOSED, OPEN }

var current_state: DoorState = DoorState.CLOSED
var door_type: int
var door_data: Dictionary
var floor_instance
var door_center_x: float = 0.0 

const SLOT_PERCENTAGES = [0.85]  ## this is an arti

@onready var door_sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
# Remove tooltip reference:
# @onready var tooltip_background = $TooltipBackground

func _ready():
    add_to_group("doors")
    input_pickable = true
    connect("input_event", self._on_input_event)
    
    # Automatically set up the roomboard if door_data and floor_instance are available.
    if door_data != null and floor_instance != null:
        setup_door_instance(door_data, floor_instance)

func _on_input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        SignalBus.navigation_click.emit(
            event.global_position,
            door_data.floor_number,
            door_data.index
        )
        get_viewport().set_input_as_handled()

func set_door_state(new_state: DoorState) -> void:
    current_state = new_state

func _on_mouse_entered():
    SignalBus.show_tooltip.emit(door_data)

func _on_mouse_exited():
    SignalBus.hide_tooltip.emit()

func get_collision_edges() -> Dictionary:
    if not collision_shape:
        push_error("No CollisionShape2D found in door")
        return {}
        
    var shape = collision_shape.shape
    if not shape is RectangleShape2D:
        push_error("Door collision shape must be RectangleShape2D")
        return {}
        
    var extents = shape.extents
    var global_pos = collision_shape.global_position

    return {
        "left": global_pos.x - extents.x,
        "right": global_pos.x + extents.x,
        "top": global_pos.y - extents.y,
        "bottom": global_pos.y + extents.y
    }

#region door setup
func setup_door_instance(p_door_data, p_floor_instance):
    door_data = p_door_data
    floor_instance = p_floor_instance
    door_type = door_data.door_type
    
    # Default state is CLOSED.
    set_door_state(DoorState.CLOSED)
    
    # Position the roomboard.
    position_door()
    
    # Update the collision shape to match the sprite's texture.
    update_collision_shape()
    
    # Remove tooltip setup code:
    # var final_tooltip = door_data.tooltip
    # if final_tooltip.find("{owner}") != -1:
    #     final_tooltip = final_tooltip.replace("{owner}", door_data.owner)
    # tooltip_background.set_text(final_tooltip)
    
    connect("mouse_entered", self._on_mouse_entered)
    connect("mouse_exited", self._on_mouse_exited)

func update_collision_shape() -> void:
    var dimensions = get_door_dimensions()
    if dimensions.width > 0 and dimensions.height > 0:
        var rectangle_shape = RectangleShape2D.new()
        rectangle_shape.extents = Vector2(dimensions.width / 2, dimensions.height / 2)
        collision_shape.shape = rectangle_shape
    else:
        push_warning("Cannot update collision shape: Invalid dimensions")

func position_door():
    # Retrieve the slot index from door data.
    var slot_index = door_data.door_slot
    
    var floor_collision_shape = floor_instance.get_node("CollisionShape2D")
    if not floor_collision_shape:
        push_warning("Missing CollisionShape2D node for door position calculation")
        return

    var shape = floor_collision_shape.shape
    if shape is RectangleShape2D:
        var rect_shape = shape as RectangleShape2D
        var collision_width = rect_shape.extents.x * 2
        var collision_left_edge = floor_collision_shape.global_position.x - rect_shape.extents.x
        var collision_edges = floor_instance.get_collision_edges()
        var bottom_edge_y = collision_edges["bottom"]
        var top_edge_y = collision_edges["top"]
        
        var local_x: float = collision_left_edge + SLOT_PERCENTAGES[slot_index] * collision_width
        # Center vertically between top and bottom edges.
        var local_y = top_edge_y + 0.5 * (bottom_edge_y - top_edge_y)
        
        global_position = Vector2(local_x, local_y)
        door_center_x = local_x
    else:
        push_warning("Collision shape is not a RectangleShape2D")

func get_door_dimensions():
    var tex = door_sprite.texture
    if tex:
        var width = tex.get_width() * door_sprite.scale.x
        var height = tex.get_height() * door_sprite.scale.y
        return { "width": width, "height": height }
    return { "width": 0.0, "height": 0.0 }
#endregion
```

## File: Scripts/signal_bus.gd
```
# Singleton SignalBus
# signal_bus.gd

@warning_ignore("unused_signal")

extends Node


signal cursor_size_updated(size)
signal show_tooltip(door_data)
signal hide_tooltip()


signal elevator_called(elevator_request_data: Dictionary) ## used in the new implementation
signal elevator_request_confirmed(elevator_request_data: Dictionary, ready_status: bool)  ## used in the new implementation
signal entering_elevator(sprite_name: String)  ## used in the new implementation

signal enter_animation_finished(sprite_name: String, target_floor: int)  ## used in the new implementation
signal elevator_arrived_at_destination(sprite_name: String)


# signal elevator_called(sprite_name: String, pick_up_floor: int, destination_floor: int, sprite_elevator_request_id: int)

# signal elevator_request_confirmed(sprite_name: String, request_id: int)

signal elevator_position_updated(global_pos: Vector2, sprite_name: String)  # used to move sprites along with the elevator cabin
signal elevator_ready(sprite_name: String, request_id: int)  # ensures that the correct sprite will enter the elevator next

'''is this connected? and why is it not???'''
signal elevator_waiting_ready(request_data: Dictionary, elevator_ready_status: bool)

signal request_elevator_ready_status(sprite_name: String, request_id: int)
signal request_skippable(sprite_name: String, request_id: int)
signal queue_reordered(sprite_name: String, request_id: int)

# signal entering_elevator(sprite_name: String, request_id: int, destination_room: int)

signal exit_animation_finished(sprite_name: String)

signal navigation_click(global_position: Vector2, floor_number: int, door_index: int)

signal adjusted_navigation_click(floor_number: int, door_index: int, adjusted_position: Vector2)
signal navigation_command(sprite_name: String, floor_number: int, door_index: int)
signal adjusted_navigation_command(commander: String, sprite_name: String, floor_number: int, door_index: int, adjusted_position: Vector2)

signal player_sprite_ready
signal all_sprites_ready
signal floor_area_entered(area: Area2D, floor_number: int)

signal door_state_changed(new_state)

signal floor_clicked(floor_number: int, click_position: Vector2, bottom_edge_y: float, collision_edges: Dictionary)

signal door_clicked(door_center_x: int, floor_number: int, door_index: int, collision_edges: Dictionary, click_position: Vector2)
```

## File: Scripts/spawner.gd
```
extends Node2D

@export var base_sprite_scene: PackedScene
@export var deco_scene: PackedScene
@export var ai_scene: PackedScene
@export var player_scene: PackedScene


var deco_definitions = [
    {
        "texture_path": "res://Sprites/plant/gfx_building_standlight.png",
        "floor_number": 0,
        "x_percent": 40,
        "name": "Standlight_0_1"
    },
    {
        "texture_path": "res://Sprites/plant/gfx_building_standlight.png",
        "floor_number": 0,
        "x_percent": 60,
        "name": "Standlight_0_2"
    },
    ###########
    {
        "texture_path": "res://Sprites/plant/gfx_building_picture2.png",
        "floor_number": 1,
        "x_percent": 80,
        "name": "Picture"
    },   
    {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze3.png",
        "floor_number": 1,
        "x_percent": 25,
        "name": "Plant_1_1"
    },
    {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze2.png",
        "floor_number": 1,
        "x_percent": 75,
        "name": "Plant_1_2"
    },
 
    {
        "texture_path": "res://Sprites/plant/gfx_building_Wandlampe.png",
        "floor_number": 1,
        "x_percent": 25,
        "name": "WallLamp"
    },
    ###########

    ###########
     {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze4.png",
        "floor_number": 3,
        "x_percent": 75,
        "name": "Plant_3_1"
    },
     {
        "texture_path": "res://Sprites/plant/gfx_building_credits.png",
        "floor_number": 3,
        "x_percent": 85,
        "name": "Picture"
    },
  ###########
    ## no deco sprites on floor 4
  ###########
     {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze5.png",
        "floor_number": 5,
        "x_percent": 25,
        "name": "Plant_5_1"
    },

     {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze1.png",
        "floor_number": 5,
        "x_percent": 75,
        "name": "Plant_5_2"
    },
     {
        "texture_path": "res://Sprites/plant/gfx_building_Wandlampe.png",
        "floor_number": 5,
        "x_percent": 75,
        "name": "WallLamp"
    },
     {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze1.png",
        "floor_number": 6,
        "x_percent": 75,
        "name": "Plant_6_1"
    },
    ###########
    ## no deco sprites on floor 7
    ###########
     {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze1.png",
        "floor_number": 8,
        "x_percent": 25,
        "name": "Plant_8_1"
    },
    ###########
      {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze1.png",
        "floor_number": 9,
        "x_percent": 75,
        "name": "Plant_9_1"
    },
     {
        "texture_path": "res://Sprites/plant/gfx_building_Wandlampe.png",
        "floor_number": 9,
        "x_percent": 75,
        "name": "WallLamp"
    },   
###########
    {
        "texture_path": "res://Sprites/plant/gfx_building_picture1.png",
        "floor_number": 10,
        "x_percent": 85,
        "name": "Picture"
    },   
    ###########

    {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze1.png",
        "floor_number": 11,
        "x_percent": 25,
        "name": "Plant_11_1"
    },
    ###########
    {
        "texture_path": "res://Sprites/plant/gfx_building_picture2.png",
        "floor_number": 12,
        "x_percent": 90,
        "name": "Picture"
    },   
    {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze5.png",
        "floor_number": 12,
        "x_percent": 25,
        "name": "Plant_12_1"
    },
    {
        "texture_path": "res://Sprites/plant/gfx_building_Pflanze4.png",
        "floor_number": 12,
        "x_percent": 80,
        "name": "Plant_12_2"
    },  
]



#{
  #"texture_path": "res://Sprites/plant/gfx_building_Pflanze1.png",
  #"floor_number": 3,
  #"x_percent": 25,
  #"name": "PLANT_01",
  #"custom_scale": 1.5,
  #"z_index": 5
#}



func _ready():
    
    spawn_base_sprite()
    # spawn_player()
    # spawn_ai(1)
    
    spawn_all_decorations()
    
    
    SignalBus.all_sprites_ready.emit()  
    # print("all_sprites_ready signal emitted")


func spawn_base_sprite():
    var base_sprite_instance = base_sprite_scene.instantiate()
    base_sprite_instance.add_to_group("sprites")

    base_sprite_instance.set_data(
        1,    # current_floor_number
        -1,   # current_room
        1,    # target_floor_number
        "Player", # sprite_name
        1     # elevator_request_id
    )

    add_child(base_sprite_instance)



func spawn_player():
    var player_instance = player_scene.instantiate()
    player_instance.add_to_group("sprites")
    
    # Directly call set_data with the desired initial values:
    player_instance.set_data(
        2,    # current_floor_number
        -1,   # current_room
        2,    # target_floor_number
        "Player", # sprite_name
        1     # elevator_request_id
    )

    add_child(player_instance)


func spawn_ai(count: int):
    for i in range(count):
        var ai_instance = ai_scene.instantiate()
        ai_instance.add_to_group("sprites")
        
        # Different or same defaults for AIs:
        ai_instance.set_data(
            8,     # current_floor_number
            -1,    # current_room
            8,     # target_floor_number
            "AI_SPRITE",
            1
        )
        
        add_child(ai_instance)




func spawn_all_decorations():
    for definition in deco_definitions:
        var deco_instance = deco_scene.instantiate()
        
        # 1) Assign the texture from the definition
        var texture_path = definition["texture_path"]
        deco_instance.deco_texture = load(texture_path)
        
        # 2) Now call set_data() so the script knows floor, x percent, name, etc.
        var floor_num = definition["floor_number"]
        var x_percent: int = definition["x_percent"]
        var sprite_name = definition["name"]
        deco_instance.set_data(x_percent, floor_num, sprite_name)
        
        # 3) Finally, add to the scene
        add_child(deco_instance)
```

## File: Scripts/sprite_base.gd
```
# sprite_base.gd
extends Area2D

@onready var navigation_controller := get_tree().get_root().get_node("Main/Navigation_Controller")
@onready var cabin := get_tree().get_root().get_node("Main/Magical_Elevator")
@export var state_manager: Node
@export var pathfinder: Node
@export var movement: Node

const SpriteDataScript = preload("res://Data/SpriteData_new.gd")
var sprite_data_new: Resource = SpriteDataScript.new()

const SCALE_FACTOR = 2.3


func _ready():
    instantiate_sprite()
    connect_to_signals()    
    set_initial_position()



func _process(delta: float) -> void:   
    
    
    sprite_data_new.stored_position_updated = pathfinder.determine_path(sprite_data_new)
    # print("stored position updated? ", sprite_data_new.stored_position_updated)
    
    # print("process state") 
    # print("sprite script calls process_state")
    state_manager.process_state(sprite_data_new)
    var active_state = sprite_data_new.get_active_state()
    
    if active_state == sprite_data_new.ActiveState.MOVEMENT:   
        # print("process movement")     
        movement.move_sprite(delta, sprite_data_new, self)
        _animate_sprite()

    if active_state == sprite_data_new.ActiveState.ELEVATOR:
        # print("process elevator actions")
        # elevator._process_elevator_actions(sprite_data_new, self)
        _process_elevator_actions()


func _process_elevator_actions() -> void:
    # print(" in elevator state in player script")
    match sprite_data_new.elevator_state:
        
        sprite_data_new.ElevatorState.CALLING_ELEVATOR:     
                   
            if not sprite_data_new.elevator_requested or sprite_data_new.stored_position_updated:                
                #print("sprite_data_new.elevator_requested: ", sprite_data_new.elevator_requested)
                #print("stored_position_updated: ", stored_position_updated)                
                call_elevator()        
                
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:     
            if sprite_data_new.stored_position_updated:
                call_elevator()
            
            # request_elevator_ready_status() 
                # pass
        sprite_data_new.ElevatorState.ENTERING_ELEVATOR:               
            if not sprite_data_new.entered_elevator:                
                enter_elevator()                            
        sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT:      
            _animate_sprite()
        sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM:      
            _animate_sprite()
        sprite_data_new.ElevatorState.EXITING_ELEVATOR:
            exit_elevator()        
        _:
                        
            pass


#region Elevator Movement

func call_elevator() -> void:

    var request_data: Dictionary = {
        "sprite_name": sprite_data_new.sprite_name,
        "pick_up_floor": sprite_data_new.current_floor_number,
        "destination_floor": sprite_data_new.stored_target_floor,
        "request_id": sprite_data_new.elevator_request_id
    }

    SignalBus.elevator_called.emit(request_data)
    _animate_sprite()

    sprite_data_new.elevator_requested = true

func _on_elevator_request_confirmed(elevator_request_data: Dictionary, elevator_ready_status: bool) -> void:
    print("elevator request confirmed signal received by: ", sprite_data_new.sprite_name)
    var incoming_sprite_name = elevator_request_data["sprite_name"]    
    var incoming_request_id = elevator_request_data["request_id"]
    
    if not incoming_sprite_name == sprite_data_new.sprite_name: # or incoming_request_id != sprite_data_new.elevator_request_id:
        # print("not my sprite name: ", sprite_data_new.sprite_name)
        print("the incomming sprite name ", incoming_sprite_name, " is not my sprite name: ", sprite_data_new.sprite_name)
        # print("the incomming incoming_request_id ", incoming_request_id, " is not my request_id: ", sprite_data_new.elevator_request_id)
        return
    
    print("Sprite ", sprite_data_new.sprite_name, " received the request confirmation.")    
    sprite_data_new.elevator_request_id = incoming_request_id
    sprite_data_new.elevator_request_confirmed = true
    
    if elevator_ready_status:        
        if sprite_data_new.elevator_state == sprite_data_new.ElevatorState.CALLING_ELEVATOR \
            or sprite_data_new.elevator_state == sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:

            print("The elevator is ready for ", sprite_data_new.sprite_name)
            sprite_data_new.elevator_ready = true
            sprite_data_new.defer_input = true            
            
            state_manager._process_elevator_state(sprite_data_new)

            print("emitting entering elevator in _on_elevator_request_confirmed for: ", sprite_data_new.sprite_name)
            SignalBus.entering_elevator.emit(sprite_data_new.sprite_name)
            # You might lock down movement here or do any other UI updates as needed
            
        else:
            # If the sprite isn't in the CALLING or WAITING state, do not let it enter
            print("Elevator is ready, but sprite ", sprite_data_new.sprite_name, 
                  " is not waiting or calling. Current elevator_state =", sprite_data_new.elevator_state)
            return

    else:
        print("Not entering because the elevator is blocked or not ready.")
        return


func _on_elevator_waiting_ready_received(elevator_request_data: Dictionary, elevator_ready_status: bool) -> void:
    
    ### case of the DRY here and in the _on_elevator_request_confirmed function
    
    print("elevator_waiting_ready signal received: ", sprite_data_new.sprite_name)
    var incoming_sprite_name = elevator_request_data["sprite_name"]
    var incoming_request_id = elevator_request_data["request_id"]
    
    if not incoming_sprite_name == sprite_data_new.sprite_name:
        # print("not my sprite name: ", sprite_data_new.sprite_name)
        return   
        
    match sprite_data_new.elevator_state:        
        
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
            
            # print("Sprite ", sprite_data_new.sprite_name, " received the request confirmation.")    
            sprite_data_new.elevator_request_id = incoming_request_id
            sprite_data_new.elevator_request_confirmed = true
            
            if elevator_ready_status:
                # print("The elevator is ready for ", sprite_data_new.sprite_name)
                sprite_data_new.elevator_ready = true
                sprite_data_new.defer_input = true
                # state_manager._process_elevator_state(sprite_data_new) ## update sprite state immediately
                ## consider emitting the signal from inside the state specific functions
                # print("emitting entering elevator in _on_elevator_waiting_ready_received for: ", sprite_data_new.sprite_name)
                # print("entering because the elevator is waiting")
                SignalBus.entering_elevator.emit(sprite_data_new.sprite_name)
                '''ensure sprite is locked down for the entering period'''

        _:
            # print(sprite_data_new.sprite_name, " is not waiting for the elevator.")
            pass

func enter_elevator():    
    
    if not sprite_data_new.entering_elevator:        
        sprite_data_new.entering_elevator = true
        _animate_sprite() # $AnimatedSprite2D.play("enter")        
           
        var elevator_data = navigation_controller.elevators.get(sprite_data_new.current_floor_number, null)
        var cabin_height = cabin.get_cabin_height()
        var cabin_bottom_y = elevator_data["position"].y + (cabin_height * 0.5)
        var new_position = Vector2(
            elevator_data["position"].x,
            cabin_bottom_y - (sprite_data_new.sprite_height * 0.5)
        )
        sprite_data_new.set_current_position(new_position,sprite_data_new.current_floor_number,sprite_data_new.current_room)
        global_position = sprite_data_new.current_position
        z_index = -9
        # print("Sprite emits entering elevator signal")
        # SignalBus.entering_elevator.emit(sprite_data_new.sprite_name, sprite_data_new.elevator_request_id, sprite_data_new.target_room)
    else:        
        return

func on_sprite_entered_elevator():    
    sprite_data_new.entered_elevator = true
    SignalBus.enter_animation_finished.emit(sprite_data_new.sprite_name, sprite_data_new.stored_target_floor)
    _animate_sprite()

func _on_elevator_ride(elevator_pos: Vector2, sprite_name: String) -> void:
    
    if sprite_data_new.sprite_name != sprite_name:
        return 

    if sprite_data_new.entered_elevator:
        var cabin_height = cabin.get_cabin_height()
        var cabin_bottom_y = elevator_pos.y + (cabin_height * 0.5)
        var new_position = Vector2(
            elevator_pos.x,
            cabin_bottom_y - (sprite_data_new.sprite_height * 0.5)
        )
        sprite_data_new.set_current_position(
            new_position,
            sprite_data_new.current_floor_number,
            sprite_data_new.current_room
        )
        global_position = sprite_data_new.current_position
        _animate_sprite()

func _on_elevator_at_destination(incoming_sprite_name: String):
    # print("_on_elevator_at_destination") ## is being called twice
    if incoming_sprite_name == sprite_data_new.sprite_name:        
        sprite_data_new.elevator_destination_reached = true

func exit_elevator():
    # print("exit elevator in sprite base") 
    if not sprite_data_new.exiting_elevator:
        sprite_data_new.exiting_elevator = true
        _animate_sprite() 
    else:
        return

func on_sprite_exited_elevator():
    # print("on_sprite_exited_elevator in sprite base")
    z_index = 0
    SignalBus.exit_animation_finished.emit(sprite_data_new.sprite_name)
    sprite_data_new.exited_elevator = true
    sprite_data_new.set_target_position(
        sprite_data_new.stored_target_position,
        sprite_data_new.stored_target_floor,
        sprite_data_new.stored_target_room
    )
    sprite_data_new.reset_stored_data()    
        
#endregion
        
        
#region Sprite Animation

func _animate_sprite() -> void:
    var direction = (sprite_data_new.target_position - sprite_data_new.current_position).normalized()
    var main_state = sprite_data_new.get_active_state()
    
    match main_state:
        sprite_data_new.ActiveState.MOVEMENT:
            match sprite_data_new.movement_state:
                sprite_data_new.MovementState.WALKING:
                    if direction.x > 0:
                        $AnimatedSprite2D.play("walk_to_right")
                    else:
                        $AnimatedSprite2D.play("walk_to_left")
                sprite_data_new.MovementState.IDLE:
                    $AnimatedSprite2D.play("idle")
                _:                    
                    push_warning("in _animate_sprite: Sprite is in no recognized state in _animate_sprite! - MovementState")
                    $AnimatedSprite2D.play("idle")
        
        sprite_data_new.ActiveState.ROOM:
            match sprite_data_new.room_state:
                sprite_data_new.RoomState.ENTERING_ROOM:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.RoomState.EXITING_ROOM:
                    $AnimatedSprite2D.play("exit")
                sprite_data_new.RoomState.IN_ROOM:
                    $AnimatedSprite2D.play("idle")                
                _:
                    push_warning("in _animate_sprite: Sprite is in no recognized state in _animate_sprite! - RoomState")
                    $AnimatedSprite2D.play("idle")
        
        sprite_data_new.ActiveState.ELEVATOR:
            match sprite_data_new.elevator_state:
                sprite_data_new.ElevatorState.CALLING_ELEVATOR:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.ElevatorState.ENTERING_ELEVATOR:
                    $AnimatedSprite2D.play("enter")
                sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM:
                    $AnimatedSprite2D.play("idle")
                sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT:
                    $AnimatedSprite2D.play("idle")
                sprite_data_new.ElevatorState.EXITING_ELEVATOR:
                    $AnimatedSprite2D.play("exit")                    
                _:
                    push_warning("in _animate_sprite: Sprite is in no recognized state in _animate_sprite! - ElevatorState")
                    $AnimatedSprite2D.play("idle")

        _:
            push_warning("in _animate_sprite: Sprite is in no recognized state in _animate_sprite!")
            $AnimatedSprite2D.play("idle")
            
func _on_animation_finished() -> void:    
    var anim_name = $AnimatedSprite2D.animation
    
    match anim_name:
        "enter":
            if sprite_data_new.elevator_ready:
                on_sprite_entered_elevator()

        "exit":
            if sprite_data_new.elevator_destination_reached:
                on_sprite_exited_elevator()      
#endregion





#region set_initial_position
func set_initial_position() -> void:
    var current_floor_number: int = sprite_data_new.current_floor_number
    var floor_info: Dictionary = navigation_controller.floors[current_floor_number]

    var edges: Dictionary = floor_info["edges"]
    var center_x = (edges["left"] + edges["right"]) / 2.0
    var bottom_edge_y = edges["bottom"]
    var sprite_height = sprite_data_new.sprite_height
    var y_position = bottom_edge_y - (sprite_height / 2.0)

    global_position = Vector2(center_x, y_position)

    # Use setter functions to update current and target positions/floors
    sprite_data_new.set_current_position(
        global_position,
        current_floor_number,
        sprite_data_new.current_room
    )
    sprite_data_new.set_target_position(
        global_position,
        current_floor_number,
        sprite_data_new.target_room
    )
    # print("in set_initial_position: ", global_position)



#endregion


#region connect_to_signals
func connect_to_signals():
    SignalBus.adjusted_navigation_command.connect(_on_adjusted_navigation_command)
    SignalBus.floor_area_entered.connect(_on_floor_area_entered)
    SignalBus.elevator_request_confirmed.connect(_on_elevator_request_confirmed)
    SignalBus.elevator_waiting_ready.connect(_on_elevator_waiting_ready_received)    
    SignalBus.elevator_arrived_at_destination.connect(_on_elevator_at_destination) ## not needed any more -> handled by elevator's waiting function
    SignalBus.elevator_position_updated.connect(_on_elevator_ride)
    
    $AnimatedSprite2D.animation_finished.connect(_on_animation_finished)


  
            



    

func _on_floor_area_entered(area: Area2D, floor_number: int) -> void:
    if area == self:
        sprite_data_new.set_current_position(
            sprite_data_new.current_position,  # keep the same position
            floor_number,                      # update floor
            sprite_data_new.current_room       # keep the same room index
        )
        # print("I, %s, have entered floor #%d" % [name, floor_number])    


func _on_adjusted_navigation_command(_commander: String, sprite_name: String, floor_number: int, door_index: int, click_global_position: Vector2) -> void:       
    # print("Navigation click received in ", sprite_data_new.sprite_name, " script with sprite_name: ", sprite_name)
    if not sprite_name == sprite_data_new.sprite_name:
        return    
    # if target is elevator room on another floor, ensure we are setting destination to that position not the room
    if door_index == -2 and floor_number != sprite_data_new.current_floor_number:        
        door_index = -1            
    sprite_data_new.set_sprite_nav_data(click_global_position, floor_number, door_index)
    # print("_on_adjusted_navigation_command for: ", sprite_data_new.sprite_name, " floor_number: ", floor_number)
    
    
#endregion


#region instantiate_sprite


#####################################################################################################
##################              Basic Sprite Component                        #######################  
#####################################################################################################

func instantiate_sprite():
    add_to_group("player_sprite")   # for other nodes explicitly referencing this player sprite
    add_to_group("sprites")
    # print("player is in group player_sprites")
    # sprite_data_new = SpriteDataNew.new()    
    apply_scale_factor_to_sprite()
    update_sprite_dimensions()
    update_collision_shape()    
    


func update_sprite_dimensions():
    var idle_texture = $AnimatedSprite2D.sprite_frames.get_frame_texture("idle", 0)
    if idle_texture:
        sprite_data_new.sprite_width = idle_texture.get_width() * $AnimatedSprite2D.scale.x
        sprite_data_new.sprite_height = idle_texture.get_height() * $AnimatedSprite2D.scale.y
    else:
        print("Warning: 'idle' animation (frame 0) not found.")


func update_collision_shape():    
    var collision_shape = $CollisionShape2D
    if collision_shape:
        var rect_shape = RectangleShape2D.new()
        rect_shape.size = Vector2(sprite_data_new.sprite_width, sprite_data_new.sprite_height)
        collision_shape.shape = rect_shape        
        collision_shape.position = Vector2.ZERO
    else:
        print("Warning: CollisionShape2D not found.")


func apply_scale_factor_to_sprite():
    var sprite = $AnimatedSprite2D
    if sprite:
        sprite.scale *= SCALE_FACTOR
        # print("Applied scale factor to player sprite.")
    else:
        push_warning("AnimatedSprite2D node not found for scaling.")

func set_data(
    current_floor_number: int,
    current_room: int,
    target_floor_number: int,
    sprite_name: String,
    elevator_request_id: int
):
    # This replaces the old 'set_initial_data' from _ready().
    sprite_data_new.current_floor_number = current_floor_number
    sprite_data_new.current_room = current_room
    sprite_data_new.target_floor_number = target_floor_number
    sprite_data_new.sprite_name = sprite_name
    sprite_data_new.elevator_request_id = elevator_request_id

#endregion
```

## File: Scripts/state_component.gd
```
# state_component.gd
extends Node
const SpriteDataNew = preload("res://Data/SpriteData_new.gd")


'''on state change during _process function -> call the next _process function immediately'''


func process_state(sprite_data_new: Resource) -> void:    
    # print("state component process state for: ", sprite_data_new.sprite_name)
    var state = sprite_data_new.get_active_state()
    # print("state : ", state)
    match state:
        sprite_data_new.ActiveState.MOVEMENT:
            _process_movement_state(sprite_data_new)
        sprite_data_new.ActiveState.ROOM:
            # room state management will go here
           pass            
        sprite_data_new.ActiveState.ELEVATOR:
            _process_elevator_state(sprite_data_new)            
        _:
            push_warning("In state_component _process: Sprite is in no recognized Main-state!")

#region Elevator State
func _process_elevator_state(sprite_data_new: Resource) -> void:
    # print("state: ", sprite_data_new.elevator_state)
    match sprite_data_new.elevator_state:
        sprite_data_new.ElevatorState.CALLING_ELEVATOR:
            # print(sprite_data_new.sprite_name, " ->ElevatorState.CALLING_ELEVATOR")
            
            _process_calling_elevator(sprite_data_new)
        sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR:
            # print(sprite_data_new.sprite_name, " ->ElevatorState.WAITING_FOR_ELEVATOR")
            _process_waiting_for_elevator(sprite_data_new)
        sprite_data_new.ElevatorState.ENTERING_ELEVATOR:
            # print(sprite_data_new.sprite_name, " ->ElevatorState.ENTERING_ELEVATOR")
            _process_entering_elevator(sprite_data_new)        
        sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT:
            _process_in_elevator_transit(sprite_data_new)
        sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM:
            pass
            # print("In elevator room")            
        sprite_data_new.ElevatorState.EXITING_ELEVATOR:
            _process_exiting_elevator(sprite_data_new)        
        _:            
            sprite_data_new.set_movement_state(sprite_data_new.MovementState.WALKING)            
            # print(sprite_data_new.sprite_name, " is in Elevator main state, but has Elevator sub-state: ", sprite_data_new.elevator_state)
            # print("set sprite to MOVEMENT State")
            # push_warning("_process_elevator_state: Unknown elevator sub-state!")

func _process_calling_elevator(sprite_data_new: Resource) -> void:
    
    # print("sprite_data_new.elevator_requested: ", sprite_data_new.elevator_requested)
    # print("sprite_data_new.elevator_request_confirmed: ", sprite_data_new.elevator_request_confirmed)


    ## case 0: elevator is available immediately
    ## new
    if sprite_data_new.elevator_ready:
        # print("elevator ready? ", sprite_data_new.elevator_ready)
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.ENTERING_ELEVATOR)
        _process_entering_elevator(sprite_data_new)       
        return

    ## case 1: proceeding with the elevator flow
    if sprite_data_new.elevator_requested and sprite_data_new.elevator_request_confirmed:
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.WAITING_FOR_ELEVATOR)
        return
    
    ## case 2: sprite has interrupted the elevator flow
    if sprite_data_new.stored_target_floor == -1 and not sprite_data_new.target_room == -2:
        # print("sprite ", sprite_data_new.sprite_name, " is switching to MOVEMENT")
        sprite_data_new.set_movement_state(SpriteDataNew.MovementState.IDLE)
        return

func _process_waiting_for_elevator(sprite_data_new: Resource) -> void:
    # print("sprite is waiting for elevator")    
    # Sprite is walking away, interrupting the waiting state
    if sprite_data_new.stored_target_position == Vector2.ZERO:
        # Cancel elevator usage and switch to movement
        _update_movement_state(sprite_data_new)        
        return
    
    # Sprite is in WAITING state without having a request confirmed: which happens in pathfinder    
    if not sprite_data_new.elevator_requested and not sprite_data_new.elevator_request_confirmed:
        # print("sprite reset from WAITING to CALLING ELEVATOR")
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.CALLING_ELEVATOR)
        return        
    
    # Elevator is here → go ENTERING_ELEVATOR
    if sprite_data_new.elevator_ready:        
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.ENTERING_ELEVATOR)
        return

func _process_entering_elevator(sprite_data_new: Resource) -> void:    
    # print("func _process_entering_elevator: ", sprite_data_new.sprite_name)
    
    if sprite_data_new.entered_elevator:
        # print("sprite has entered the elevator")    
        if sprite_data_new.target_room == -2:
            sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.IN_ELEVATOR_ROOM)
            push_warning("Sprite is now in Elevator Room: 2 second timeout before exiting") # switch to idle animation if needed
            await get_tree().create_timer(2.0).timeout
            sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.EXITING_ELEVATOR)
        else:            
            sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.IN_ELEVATOR_TRANSIT)            
            # print("Sprite is switching to Transit State")
        pass

func _process_in_elevator_transit(sprite_data_new: Resource) -> void:
    # print("_process_in_elevator_transit: in elevator transit")
    if sprite_data_new.elevator_destination_reached:  
        # print("sprite is now exiting the elevator")      
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.EXITING_ELEVATOR)
  
func _process_exiting_elevator(sprite_data_new: Resource) -> void:
    # print("in exiting elevator in state ")
    if sprite_data_new.exited_elevator:        
        sprite_data_new.set_movement_state(SpriteDataNew.MovementState.IDLE)
  
#endregion

#region Movement State
func _process_movement_state(sprite_data_new: Resource) -> void:
    match sprite_data_new.movement_state:
        sprite_data_new.MovementState.IDLE:
            _process_movement_idle(sprite_data_new)
        sprite_data_new.MovementState.WALKING:
            _process_movement_walking(sprite_data_new)
        _:
            push_warning("_process_movement_state: Unknown movement sub-state: %s" % str(sprite_data_new.movement_state))

func _process_movement_idle(sprite_data_new: Resource) -> void:
    var target_differs = (sprite_data_new.target_position != sprite_data_new.current_position)
    var has_stored = sprite_data_new.has_stored_data
    var room_index = sprite_data_new.target_room

    if target_differs or has_stored:
        _update_movement_state(sprite_data_new)
    elif not target_differs and not has_stored:
        # If position is the same and no pending data,
        # check if we want to do something like enter a room or elevator
        if room_index >= 0 or room_index == -2:
            _update_movement_state(sprite_data_new)
        else:
            # keep idling        
            pass
    else:
        push_warning("_process_movement_idle: Unexpected condition in IDLE state!")

func _process_movement_walking(sprite_data_new: Resource) -> void:    
    if sprite_data_new.current_position == sprite_data_new.target_position:
        _update_movement_state(sprite_data_new)
    else:
        # keep walking
        pass

func _update_movement_state(sprite_data_new: Resource) -> void:
    # print("update movement state")
    var x_differs = (sprite_data_new.current_position != sprite_data_new.target_position)
    var has_stored = sprite_data_new.has_stored_data
    var room_index = sprite_data_new.target_room
    #print("x_differs: ", x_differs)
    #print("has_stored: ", has_stored)
    #
    #print("sprite_data_new.current_position: ", sprite_data_new.current_position)
    #print("sprite_data_new.target_position: ", sprite_data_new.target_position)
    

    if not x_differs and not has_stored:        
        # Arrived at final destination
        if room_index < 0 and room_index != -2:
            sprite_data_new.set_movement_state(sprite_data_new.MovementState.IDLE)
            sprite_data_new.reset_elevator_status()
        elif room_index >= 0:
            sprite_data_new.set_room_state(sprite_data_new.RoomState.CHECKING_ROOM_STATE)            
        elif room_index == -2:
            sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.CALLING_ELEVATOR)
            print("sprite ", sprite_data_new.sprite_name, " is switching to CALLING_ELEVATOR-Elevator ROOM")
        else:
            push_warning("_update_movement_state: Unhandled target_room value: %d" % room_index)

    elif not x_differs and has_stored:
        # print("sprite ", sprite_data_new.sprite_name, " is switching to CALLING_ELEVATOR")
        sprite_data_new.set_elevator_state(sprite_data_new.ElevatorState.CALLING_ELEVATOR)
    elif x_differs:        
        sprite_data_new.set_movement_state(sprite_data_new.MovementState.WALKING)
        sprite_data_new.reset_elevator_status()    
        # print("in state component: _update_movement_state -> re-setting the elevator state")
        # sprite_data_new.reset_elevator_status() # belongs into sprite 
    else:
        push_warning("_update_movement_state: Bad error in _update_movement_state!")
#endregion
```

## File: Scripts/tooltip.gd
```
extends NinePatchRect

@onready var tooltip_label: Label = $TooltipLabel
@onready var tooltip_image: TextureRect = $TooltipImage

var tooltip_timer: Timer
var mouse_inside: bool = false
const PADDING = Vector2(10, 5)  # (horizontal, vertical) padding
const SPACING = 5  # Space between image and text

func _ready():
    visible = false
    z_index = 10
    setup_timer()
    
func setup_timer():
    tooltip_timer = Timer.new()
    tooltip_timer.one_shot = true
    tooltip_timer.wait_time = 0.5
    tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
    add_child(tooltip_timer)

func set_text(new_text: String):
    tooltip_label.text = new_text if new_text else ""
    update_layout()

func set_image(image_path: String, scale_factor: float = 1.0):
    if image_path.is_empty():
        tooltip_image.texture = null
        tooltip_image.visible = false
    else:
        tooltip_image.texture = load(image_path)
        tooltip_image.visible = true
        tooltip_image.scale = Vector2(scale_factor, scale_factor)
    update_layout()

func get_image_size() -> Vector2:
    if not tooltip_image.visible or not tooltip_image.texture:
        return Vector2.ZERO
    return tooltip_image.texture.get_size() * tooltip_image.scale

func calculate_sizes():
    # Grab current image dimensions
    var image_size = get_image_size()

    # Grab label's minimum required size
    var label_size = tooltip_label.get_minimum_size()

    # Ensure label is at least the height of the image
    var forced_label_height = max(label_size.y, image_size.y)
    tooltip_label.custom_minimum_size = Vector2(label_size.x, forced_label_height)
    label_size = tooltip_label.custom_minimum_size

    # Compute total width so there's enough room for image and label
    # (but label will be centered, so we still account for image width + padding).
    var total_width = (PADDING.x * 2)
    if image_size.x > 0:
        total_width += image_size.x + SPACING
    # If the label is wider than just the leftover space, total width should expand
    total_width = max(total_width + label_size.x, label_size.x + (PADDING.x * 2))

    # Total height is the max of label or image height plus padding
    var total_height = (PADDING.y * 2) + max(image_size.y, label_size.y)

    return {
        "image_size": image_size,
        "label_size": label_size,
        "total_size": Vector2(total_width, total_height)
    }


func position_elements(sizes: Dictionary):
    var image_size = sizes.image_size
    var label_size = sizes.label_size
    var total_size = sizes.total_size

    # 1) Position the image on the LEFT, vertically centered
    tooltip_image.position = Vector2(
        PADDING.x,
        (total_size.y - image_size.y) * 0.5  # center vertically
    )

    # 2) Center the label horizontally and vertically inside the tooltip
    tooltip_label.position = Vector2(
        (total_size.x - label_size.x) * 0.5,  # center horizontally
        (total_size.y - label_size.y) * 0.5   # center vertically
    )
    tooltip_label.set_size(label_size)


func update_layout():
    var sizes = calculate_sizes()
    
    # Update background size
    set_size(sizes.total_size)
    
    # Position the tooltip
    position = Vector2(-sizes.total_size.x / 2, -sizes.total_size.y)
    
    # Position elements within the tooltip
    position_elements(sizes)

func show_tooltip():
    mouse_inside = true
    tooltip_timer.start()

func hide_tooltip():
    mouse_inside = false
    tooltip_timer.stop()
    visible = false

func _on_tooltip_timer_timeout():
    if mouse_inside:
        visible = true
```

## File: tooltip_manager.gd
```
# TooltipManager.gd
extends Node

@onready var tooltip = $CanvasLayer/Tooltip_Doors

func _ready():
    SignalBus.show_tooltip.connect(_on_show_tooltip)
    SignalBus.hide_tooltip.connect(_on_hide_tooltip)

func _on_show_tooltip(tooltip_data):
    tooltip.show_tooltip_with_data(tooltip_data)

func _on_hide_tooltip():
    tooltip.hide_tooltip()
```
