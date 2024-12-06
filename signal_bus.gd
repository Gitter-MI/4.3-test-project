# signal_bus.gd
# Singleton SignalBus

extends Node

signal floor_requested(sprite_name: String, target_floor: int)
signal elevator_arrived(sprite_name: String, current_floor: int)
