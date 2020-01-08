extends KinematicBody2D
class_name Actor

const FLOOR_NORMAL = Vector2.UP

#Actor's movement speed
export var speed: = Vector2(300.0, 1000.0)
#Gravity's effect on the actor
export var gravity: = 3000.0
#In-game velocity
var _velocity: = Vector2.ZERO

#Whether or not the actor can do anything
var can_act = true

func apply_impulse(direction: Vector2, delay: int):
	pass

func _physics_process(delta: float) -> void:
		_velocity.y += gravity*delta