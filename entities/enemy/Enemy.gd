extends KinematicBody2D

const FLOOR_NORMAL = Vector2.UP

#Enemy's movement speed
var speed: = Vector2(500.0, 1100.0)
#Gravity's effect on the player
var gravity: = 1000.0
#In-game velocity
var velocity: = Vector2.ZERO
#Whether or not the actor can do anything
var allow_enemy_input = true
#Handle user-input velocity
var move_velocity = Vector2.ZERO
#Handle skill-related velocity
var skill_velocity = Vector2.ZERO
#Handle outside-input velocity
var outside_velocity = Vector2.ZERO


func _physics_process(delta):

	#Determine the velocity controlled by the enemy, depending on whether or not they can move
	if allow_enemy_input:
		move_velocity = calculate_move_velocity(velocity, speed, Vector2.ZERO)
	else:
		move_velocity = Vector2.ZERO

	#Add together player-controlled and outside velocity to determine final velocity
	velocity = move_and_slide_with_snap(move_velocity, Vector2.ZERO,  FLOOR_NORMAL, false, 4, PI/4, false)
	#Apply gravity
	velocity.y += gravity*delta

func calculate_move_velocity( #Calculate the velocity the player will move at
		linear_velocity: Vector2,
		speed: Vector2,
		direction: Vector2
	) -> Vector2:
	var out: = linear_velocity
	
	out.x *= 0.91
	out.y += gravity*get_physics_process_delta_time()

	return out

func _on_Hitbox_area_entered(area):
	if area.name == "player_hitbox":
		velocity += area.get_parent().get_direction()
