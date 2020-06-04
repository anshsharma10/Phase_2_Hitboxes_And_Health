extends AnimationPlayer

#A lock that forces an animation to play if true
var anim_lock = false
#A lock that forces the hitboxes to face the same direction if true
var face_lock = false
#The attack skill.
onready var skill = get_parent()
#The player.
onready var player = get_parent().get_parent()
#The hitboxes to animate.
onready var player_hitbox = get_parent().get_node("player_hitbox")

func animate(): #Animate hitboxes based on input
	#Control how the hitboxes face if there isn't a lock on the direction they face
	if not face_lock:
		face_on_press_or_mouse()

func face_on_press_or_mouse(): #Determines which direction the hitboxes should face
#Currently only face_on_press() until I find a suitable condition for it to be face_on_mouse
	face_on_press()


func face_on_mouse(): #Makes the hitboxes face left/right depending on player's position relative to the mouse
	if get_mouse_to_player_offset() >= 0:
		face_left()
	else:
		face_right()

func face_on_press(): #Makes the hitboxes face left/right depending on player's is pressing left/right keys.
	var direction = player.get_direction()
	#Note we use > and < because if the player doesn't move then their direction shouldn't change.
	if direction.x > 0:
		face_left()
	elif direction.x < 0:
		face_right()

func moving_forward() -> bool: #Return true if moving same direction as mouse
	var direction = player.get_direction()
	return direction.x * get_mouse_to_player_offset() > 0
	
func get_mouse_to_player_offset() -> float: #Return distance between x values of mouse and player
	return get_viewport().get_mouse_position().x - player.get_global_transform_with_canvas().origin.x	

func face_left(): #Makes the hitboxes face left
	skill.scale.x = 1

func face_right(): #Makes the player face right
	skill.scale.x = -1

func command_animate(name: String, time: float, face: String, lock: bool, start: float, scale: float): #animates the player according to given instructions
	#name is the animation's name
	#time is the requested length of the animation in seconds. -1 means infinite time
	#face is how to face the character: on key press, or on mouse direction.
	#lock determines whether or not the player will be stuck facing the same direction for the duration of the time.
	#start is the time of the animation to start at. If the scale is abnormal, then start would be at a point assuming the scale is not abnormal
	#scale is the time scale of the animation.
	
	#End previous animation if there is one
	end_animation()
	#Set the current animation to name
	play(name, -1, scale)
	#Start the animation at start
	seek(start)
	
#	#Set a timer for the duration of the animation
#	if time >= 0:
#		var animation_timer = Timer.new()
#		animation_timer.set_name("animation_timer")
#		add_child(animation_timer)
#		animation_timer.connect("timeout", self, "end_animation")
#		animation_timer.wait_time = time
#		animation_timer.start()
	
	#Make the player face in the requested direction
	if face == "face_on_press":
		face_on_press()
	elif face == "face_on_mouse":
		face_on_mouse()
	elif face == "face_on_press_or_mouse":
		face_on_press_or_mouse()
	
	#Enable or disable face_lock depending on requested settings
	face_lock = lock
	
	#Enable a lock on animation
	anim_lock = true

func end_animation():
	#Delete the animation timer
	if has_node("animation_timer"):
		var animation_timer = get_node("animation_timer")
		#Remove the node from the scene so it doesn't interfere
		remove_child(animation_timer)
		#It is then deleted at the game's convenience
		animation_timer.queue_free()
		
	#If face_lock is active, stop it
	face_lock = false
	#Stop animation lock
	anim_lock = false
