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
#How long the player is forced to initially jump
var forced_jump_time = 0.05
#Whether or not the player has cancelled the jump, that is, has released the jump key
var jump_cancelled = false


func _ready():
	#Set a timer until player stops being forced to shorthop
	var forced_jump_timer = Timer.new()
	forced_jump_timer.set_name("forced_jump_timer")
	add_child(forced_jump_timer)
	forced_jump_timer.connect("timeout", self, "stop_forced_jump")
	#How long the slide lasts.
	forced_jump_timer.wait_time = forced_jump_time
	forced_jump_timer.start()
	#Order the animation player to do a jump animation
	animation_player.command_animate("jump",-1,"face_on_press_or_mouse",false, 0, 1)
	#Make the player do the initial jump
	player.add_velocity(Vector2(0,player.get_data().get("speed").y * -1), "jump", "remove", 0)

func _physics_process(delta): #Control player movement when jumping
	var velocity = player.get_velocity()
	var velocity_new = velocity
	#Check if the player's cancelled jumping
	if Input.is_action_just_released("jump"):
		jump_cancelled = true
	#if the player has cancelled jumping
	if (not forced_jump) and jump_cancelled:
		#Make the player's movements in the air stop a little
		player.add_velocity(Vector2(0,player.get_velocity().y*-0.5), "jump", "remove", 0)
		stop_jumping()
	elif velocity.y > 0: #Otherwise if the player is no longer jumping due to gravity
		stop_jumping()

func stop_forced_jump():
	#Make the player able to choose if they want to keep jumping
	forced_jump = false
	#Remove the forced jump timer if it exists
	if has_node("forced_jump_timer"):
		$forced_jump_timer.queue_free()

func stop_jumping():
	#Stop the jumping animation
	animation_player.end_animation()
	#Remove the forced jump timer if it exists
	if has_node("forced_jump_timer"):
		$forced_jump_timer.queue_free()
	#Delete the node
	queue_free()

func get_skill_type() ->String:
	return skill_type
