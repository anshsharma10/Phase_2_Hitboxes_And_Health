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
#Whether or not the player is forced to keep jumping.
var forced_jump = true
#How long the player is forced to initially wall jump
var forced_jump_time = 0.1
#The direction to jump in
var jump_direction = 1
#Whether or not this is the first frame
var first_frame = true


func _ready():
	#Make sure the player can't input anything for the duration of this
	player.allow_player_input(false)
	#Make sure the player can't activate any skills for the duration of this
	skill_manager.set_can_use_skill(false)
	#Set a timer until player stops being forced to jump
	var forced_jump_timer = Timer.new()
	forced_jump_timer.set_name("forced_jump_timer")
	add_child(forced_jump_timer)
	forced_jump_timer.connect("timeout", self, "stop_jumping")
	#How long the forced jump lasts.
	forced_jump_timer.wait_time = forced_jump_time
	forced_jump_timer.start()

func _physics_process(delta): #Control player movement when jumping
	var velocity = player.get_velocity()
	var velocity_new = velocity
	#The first frame of the jump
	if first_frame:
		#Jump motion
		player.add_velocity(Vector2(0,player.get_data().get("speed").y * -0.75), "wall_jump", "remove", 0)
		player.add_velocity(Vector2(jump_direction * player.get_data().get("speed").x*2.5,0), "wall_jump", "scale", 0.7)
		#Order the animation player to do a jump animation
		if jump_direction == 1:
			animation_player.command_animate("jump",-1,"face_right",false, 0, 1)
		else:
			animation_player.command_animate("jump",-1,"face_left",false, 0, 1)
		first_frame = false
	#Apply gravity
	if not forced_jump: #if the player isn't forced to jump, give control back to them
		stop_jumping()

func stop_jumping():
	#Let the player move again
	player.allow_player_input(true)
	#Let the player activate skills again
	skill_manager.set_can_use_skill(true)
	#Stop the jumping animation
	animation_player.end_animation()
	#Remove the forced jump timer if it exists
	if has_node("forced_jump_timer"):
		$forced_jump_timer.queue_free()
	#Delete the node
	queue_free()

func get_skill_type() ->String:
	return skill_type

func set_direction(in_direction: int):
	jump_direction = in_direction
