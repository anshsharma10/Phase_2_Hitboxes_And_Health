extends Node2D

const FLOOR_NORMAL = Vector2.UP

#This is a skill; should be instantiated inside of the player ONLY.

#The player.
onready var player = get_parent()
#The player's animation player
onready var animation_player = player.get_node("AnimationPlayer")
#The skill manager.
onready var skill_manager = get_parent().get_node("SkillManager")
#The type of skill this is
var skill_type = "unique"
#The direction the wall being slid on is in. default is left but it will change
var slide_direction = "face_left"
#How long to wait before the player can wall slide again
var slide_restart_time = 0.2
#Whether or not the player is sliding
var is_sliding = true

func _ready():
	#Make the raycast not consider the player
	$RayCast2D1.add_exception(player)
	$RayCast2D2.add_exception(player)
	#Find the direction to slide in
	for i in range(player.get_slide_count()):
		var collision = player.get_slide_collision(i)
		if collision.normal.x > 0 and collision.normal.y == 0:
			slide_direction = "face_right"
		elif collision.normal.x < 0 and collision.normal.y == 0:
			slide_direction = "face_left"
	#Cancel any jumps
	if player.has_node("skill_jump"):
		player.get_node("skill_jump").stop_jumping()
	#Remove any velocities relating to wall jumping or wall sliding
	player.remove_velocity("wall_jump")
	player.remove_velocity("wall_slide")
	#Order the animation player to do a wall slide animation
	animation_player.command_animate("on_wall",-1,slide_direction,true, 0, 1)
	#Make sure the player can't input anything for the duration of this
	player.allow_player_input(false)
	#Make sure the player can't activate any skills for the duration of this
	skill_manager.set_can_use_skill(false)
	var velocity = player.get_velocity()
	#Keep velocity if the player is jumping, if they're falling set it to 0
	if velocity.y > 0:
		player.add_velocity(Vector2.ZERO, "wall_slide", "remove", 0)
	else:
		player.add_velocity(velocity, "wall_slide", "remove", 0)

func _physics_process(delta): #Control player movement when sliding on wall
	if is_sliding:
		var velocity = player.get_velocity()
		# globally check for collision
		if slide_direction == "face_right":
			$RayCast2D1.cast_to = Vector2(-50, 0)
			$RayCast2D2.cast_to = Vector2(-50, 0)
		else:
			$RayCast2D1.cast_to = Vector2(50, 0)
			$RayCast2D2.cast_to = Vector2(50, 0)
		$RayCast2D1.force_raycast_update()
		$RayCast2D2.force_raycast_update()
		#Check if the player has fallen to the floor
		if player.is_on_floor():
			stop_sliding()
		#Check if the player is no longer on a wall
		elif not $RayCast2D1.is_colliding() and not $RayCast2D2.is_colliding():
			stop_sliding()
		#Check if the player is trying to wall jump
		elif skill_manager.input_buffered_f("jump", 1):
			skill_manager.add_skill("wall_jump")
			if slide_direction == "face_left":
				player.get_node("skill_wall_jump").set_direction(-1)
			else:
				player.get_node("skill_wall_jump").set_direction(1)
			stop_sliding()
		#Check if the player is cancelling the slide by leaving the wall
		elif (skill_manager.input_buffered("move_left") && slide_direction == "face_left") or (skill_manager.input_buffered("move_right") && slide_direction == "face_right"):
			var dir = 1 if slide_direction == "face_right" else -1
			player.add_velocity(Vector2(dir * player.get_data().get("speed").x*0.3,0), "wall_slide", "scale", 0.9)
			stop_sliding()
		#If the player is sliding up, apply the same gravity, otherwise lessen effects of gravity
		elif velocity.y < 0:
			player.add_velocity(Vector2(0,player.get_velocity().y + player.get_data().get("gravity") * delta), "wall_slide", "remove", 0)
		else: #Sliding down, slowed
			player.add_velocity(Vector2(0,player.get_velocity().y - player.get_data().get("gravity") * delta * 0.5), "wall_slide", "remove", 0)



func stop_sliding():
	#Stop the sliding animation
	animation_player.end_animation()
	#Let the player move again
	player.allow_player_input(true)
	#Let the player activate skills again
	skill_manager.set_can_use_skill(true)
	#Make sure the player isn't sliding (For process)
	is_sliding = false
	
	#Set a timer until player can slide again
	var slide_restart_timer = Timer.new()
	slide_restart_timer.set_name("slide_restart_timer")
	add_child(slide_restart_timer)
	slide_restart_timer.connect("timeout", self, "can_slide_again")
	#How long the slide lasts.
	slide_restart_timer.wait_time = slide_restart_time
	slide_restart_timer.start()

func can_slide_again():
	#Remove the slide restart timer if it exists
	if has_node("slide_restart_timer"):
		$slide_restart_timer.queue_free()
	#Delete the node
	$RayCast2D1.queue_free()
	$RayCast2D2.queue_free()
	queue_free()

func get_skill_type() ->String:
	return skill_type
