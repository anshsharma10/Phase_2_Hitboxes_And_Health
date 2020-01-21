extends KinematicBody2D
class_name Actor

const FLOOR_NORMAL = Vector2.UP

#Actor's movement speed
export var speed: = Vector2(300.0, 1000.0)
#Gravity's effect on the actor
export var gravity: = 3000.0
#In-game velocity
var _velocity: = Vector2.ZERO
#Timer to manage impulses
var impulse_timer
#Whether or not the actor can do anything
var can_move = true

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("click_1"):
		apply_impulse(Vector2(100,100))
	_velocity.y += gravity*delta


func apply_impulse(direction: Vector2):
	_velocity += direction
	can_move = false
	impulse_timer = Timer.new()
	add_child(impulse_timer)
	impulse_timer.connect("timeout", self, "can_move_again")
	impulse_timer.wait_time = 0.5
	impulse_timer.start()
	

func can_move_again() -> void:
	can_move = true