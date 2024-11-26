# building.gd
extends Node2D

# Preload the single floor scene
const FLOOR_SCENE = preload("res://Floor.tscn")  # Update the path to your single floor scene
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
            # Let the floor instance position itself
            previous_floor_top_y_position = floor_instance.position_floor(previous_floor_top_y_position, is_first_floor)
            is_first_floor = false

            # Pass door data to floor to handle door instantiation
            var floor_doors = DOOR_DATA_RESOURCE.doors.filter(func(door):
                return door.floor_number == floor_number
            )
            floor_instance.setup_doors(floor_doors)
        else:
            push_warning("Failed to instantiate floor number " + str(floor_number))

func instantiate_floor(floor_number):
    # print("instantiate_floor")  # Debug # print
    var floor_instance = FLOOR_SCENE.instantiate()
    if not floor_instance:
        push_warning("Failed to instantiate floor scene")
        return null

    # Set the floor number and image path before adding to the scene tree
    floor_instance.floor_number = floor_number

    # Construct the expected image path
    var image_path = "res://Building/Floors/Floor_" + str(floor_number) + ".png"
    # print("Constructed image path: " + image_path)  # Debug # print
    floor_instance.floor_image_path = image_path

    # Assign a meaningful name to the node
    floor_instance.name = "Floor_" + str(floor_number)

    # Now add the floor instance to the scene tree
    add_child(floor_instance)

    return floor_instance

# Removed methods: position_floor, configure_collision_shape, configure_marker
