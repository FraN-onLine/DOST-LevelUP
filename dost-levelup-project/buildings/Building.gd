extends Node2D

class_name Building

@export var max_hp: int = 10
var hp: int
var owner_peer_id: int = 0

signal destroyed(owner_peer_id)

func _init():
    hp = max_hp

func take_damage(amount: int) -> void:
    hp = max(0, hp - amount)
    if hp == 0:
        emit_signal("destroyed", owner_peer_id)

func repair(amount: int) -> void:
    hp = min(max_hp, hp + amount)

func is_alive() -> bool:
    return hp > 0

func on_tick(delta: float) -> void:
    # Override in subclasses for periodic effects
    pass

func interact(actor_id: int) -> void:
    # Override to perform actions when player interacts with the building
    pass
