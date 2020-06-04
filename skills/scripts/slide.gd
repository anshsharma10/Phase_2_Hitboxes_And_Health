extends Node2D

const FLOOR_NORMAL = Vector2.UP

#This is a skill; should be instantiated inside of the player ONLY.

#Whether or not the game lets the player slide
var can_slide = true
#A lock that forces the player to slide for a certain amount of time if they choose to slide
var slide_lock = false
#The player.
onready var player = get_parent()
#The player's animation player
onready var animation_player = player.get_node("AnimationPlayer")
#The skill manager.
onready var skill_manager = get_parent().get_node("SkillManager")
#The type of skill this is
var skill_type = "active"
#The direction to slide in. 1 is forward, -1 is backward
var slide_dir = 0
#How long the slide lasts
var slide_time = 0.5
#How long before the player can slide again
var slide_restart_time = 0.5


func _ready():
	#Make sure the player can't input anything for the duration of this
	player.allow_player_input(false)
	#Make sure the player can't activate any skills for the duration of this
	skill_manager.set_can_use_skill(false)
	#Set a timer until player stops sliding and can move again
	var slide_stop_timer = Timer.new()
	slide_stop_timer.set_name("slide_stop_timer")
	add_child(slide_stop_timer)
	slide_stop_timer.connect("timeout", self, "stop_sliding")
	#How long the slide lasts.
	slide_stop_timer.wait_time = slide_time
	slide_stop_timer.start()
	#Order the animation player to do a slide animation in the direction faced
	animation_player.command_animate("slide",0.5,"face_on_press",true, 0, 1)
	#Set direction to face during slide
	slide_dir = 1 if skill_manager.input_combo_buffered(["move_right","move_down"]) else -1

func _physics_process(delta): #Control player movement when sliding
	if can_slide and get_parent().name == "Player":
		if player.is_on_floor() and not player.is_jumping(): #Make sure the player isn't sliding in the air
			var velocity = get_parent().get_velocity()
			var new_velocity = velocity
			
			new_velocity.x = player.get_data().get("speed").x * slide_dir * 1.25
			var snap = player.get_snap()
			
			player.add_velocity(new_velocity, "slide", "remove", 0)
		elif player.is_jumping(): #If they are jumping, stop them from sliding and jump, eliminate the timer
			stop_sliding()
		else: #Otherwise they're in the air, stop them from sliding
			stop_sliding()

func stop_sliding():
	#Make the player unable to slide
	can_slide = false
	#Remove the slide stop timer if it exists
	if has_node("slide_stop_timer"):
		$slide_stop_timer.queue_free()
	#Let the player move again
	player.allow_player_input(true)
	#Let the player activate skills again
	skill_manager.set_can_use_skill(true)
	#Cancel the slide animation
	animation_player.end_animation()
	#Set the skill velocity of the player back to zero
	player.set_skill_velocity(Vector2.ZERO)
	
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
	queue_free()

func get_skill_type() ->String:
	return skill_type
