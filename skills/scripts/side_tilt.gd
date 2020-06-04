extends Node2D

const FLOOR_NORMAL = Vector2.UP

#This is a skill; should be instantiated inside of the player ONLY.

#The player.
onready var player = get_parent()
#The player's animation player
onready var animation_player = player.get_node("AnimationPlayer")
#The skill manager.
onready var skill_manager = get_parent().get_node("SkillManager")
#The area2D containing all hitboxes
onready var player_hitbox = get_node("player_hitbox")
#The animation player animating each hitbox
onready var hitbox_player = get_node("HitboxPlayer")
#The type of skill this is
var skill_type = "active"
#The original startup time before the attack's hitboxes appear. taken from frame data
var startup_lag = 0.3
#The original length of time when the attack's hitboxes appear. taken from frame data
var attack_length = 0.1
#The original length of time after the attack's hitboxes appear. taken from frame data
var end_lag = 0.2
#The requested startup time scale
var startup_lag_scale = 1
#The requested attack time scale
var attack_length_scale = 1
#The requested end lag scale
var end_lag_scale = 1
#The damage given by the attack.
var damage = 1
#The vector the attack launches the enemy in
var direction = Vector2(500,-500)
#The direction the player faces in
var attack_dir

func _ready():
	#Make sure the player can't input anything for the duration of this
	player.allow_player_input(false)
	#Make sure the player can't activate any skills for the duration of this
	skill_manager.set_can_use_skill(false)
	#Keep the player's old velocity
	player.add_velocity(player.get_velocity()*0.9, "side_tilt", "scale", 0.9)
	
	startup()

#Finds the length of the requested animation depending on time scale and original time
func get_anim_scale(anim: String) -> float:
	if anim == "startup_lag":
		return startup_lag / startup_lag_scale
	elif anim == "attack_length":
		return attack_length / attack_length_scale
	elif anim == "end_lag":
		return end_lag / end_lag_scale
	else:
		print("you used get_anim_scale incorrectly")
		return 1.0

func startup(): #Perform the startup of the move in startup_lag time.
	var startup_time = get_anim_scale("startup_lag")
	#Order the animation player to do the startup animation
	animation_player.command_animate("slash1",startup_time,"face_on_mouse",true, 0, startup_lag_scale)
	#Order the skill's hitbox animation player to do the startup animation
	hitbox_player.command_animate("attack",startup_time,"face_on_mouse",true, 0, startup_lag_scale)
	direction.x = direction.x if player.facing_right() else direction.x*-1
	#Set a timer until the actual attack occurs. length is startup_time
	var startup_timer = Timer.new()
	startup_timer.set_name("startup_timer")
	add_child(startup_timer)
	startup_timer.connect("timeout", self, "attack")
	#How long the skill lasts.
	startup_timer.wait_time = startup_time
	startup_timer.start()

func attack(): #Perform the attack animation of the move in attack_length time
	var attack_time = get_anim_scale("attack_length")
	#Remove the startup timer if it exists
	if has_node("startup_timer"):
		$startup_timer.queue_free()
	
	#Order the animation player to do the attack animation
	animation_player.command_animate("slash1",attack_time,"keep",true, startup_lag, attack_length_scale)
	#Order the skill's hitbox animation player to do the attack animation
	hitbox_player.command_animate("attack",attack_time,"keep",true, startup_lag, attack_length_scale)
	
	#Set a timer until the attack ends. length is attack_time
	var attack_timer = Timer.new()
	attack_timer.set_name("attack_timer")
	add_child(attack_timer)
	attack_timer.connect("timeout", self, "end")
	#How long the skill lasts.
	attack_timer.wait_time = attack_time
	attack_timer.start()

func end(): #End the move in end_lag time
	var end_time = get_anim_scale("end_lag")
	#Remove the startup timer if it exists
	if has_node("attack_timer"):
		$attack_timer.queue_free()
	
	#Order the animation player to do the endlag animation
	animation_player.command_animate("slash1",end_time,"keep",true, startup_lag + attack_length, end_lag_scale)
	#Order the skill's hitbox animation player to do the endlag animation
	hitbox_player.command_animate("attack",end_time,"keep",true, startup_lag + attack_length, end_lag_scale)
	
	#Set a timer until the skill is deleted. length is end_time
	var end_timer = Timer.new()
	end_timer.set_name("end_timer")
	add_child(end_timer)
	end_timer.connect("timeout", self, "delete_skill")
	#How long the skill lasts.
	end_timer.wait_time = end_time
	end_timer.start()

func delete_skill():
	#Cancel the player's velocity
	player.remove_velocity("side_tilt")
	#Stop the animations
	animation_player.end_animation()
	hitbox_player.end_animation()
	#Let the player move again
	player.allow_player_input(true)
	#Let the player activate skills again
	skill_manager.set_can_use_skill(true)
	#Remove all timers if they exist
	if has_node("startup_timer"):
		$startup_timer.queue_free()
	if has_node("attack_timer"):
		$attack_timer.queue_free()
	if has_node("end_timer"):
		$end_timer.queue_free()
	#Remove all hitboxes
	for node in player_hitbox.get_children():
		node.queue_free()
	player_hitbox.queue_free()
	#Delete the node
	queue_free()

func get_skill_type() ->String:
	return skill_type

func get_damage() -> int:
	return damage

func get_direction() -> Vector2:
	return direction
