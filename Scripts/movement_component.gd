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
