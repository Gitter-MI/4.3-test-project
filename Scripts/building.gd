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
