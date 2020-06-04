extends AnimationPlayer

#A lock that forces an animation to play if true
var anim_lock = false
#A lock that forces the player to face the same direction if true
var face_lock = false
#The player.
onready var player = get_parent()
#The skill manager.
onready var skill_manager = get_parent().get_node("SkillManager")
#The sprite.
onready var sprite = get_parent().get_node("Sprite")
#The player's hitbox.
onready var hurtbox = get_parent().get_node("Hurtbox")

func animate(): #Animate player based on input and velocity
	var direction = player.get_direction()
	var xdir = direction.x
	var ydir = direction.y
	#Control how the player faces if there isn't a lock on the direction they face
	if not face_lock:
		face_on_press_or_mouse()
	#Check if walking backwards using multiplication of unary signs properties
	if not moving_forward() and current_animation == "walk":
		playback_speed = -1
	else:
		playback_speed = 1
	#Do basic movement animations if there isn't a lock on the current animation
	if not anim_lock:
		if 	player.is_on_floor():
			if xdir == 0:
				current_animation = "stand"
			elif is_walking():
				current_animation = "walk"
			else:
				current_animation = "run"
		elif player.get_velocity().y < 0:
			current_animation = "jump"
		elif player.get_velocity().y >= 0:
			current_animation = "fall"
	#Prevent a direction change bug
	if sprite.flip_h:
		stabilize_x_direction()

func face_on_press_or_mouse(): #Determines if the player should be moving on keypress or how their mouse faces and makes them face that way
	if is_walking():
		face_on_mouse()
	else:
		face_on_press()

func is_walking() -> bool: #Return true if the player is sprinting on ground
	return skill_manager.input_buffered("walk_toggle")

func face_on_mouse(): #Makes the player face left/right depending on their position relative to the mouse
	if get_mouse_to_player_offset() >= 0:
		face_right()
	else:
		face_left()

func face_on_press(): #Makes the player face left/right depending on if the player is pressing left/right keys.
	var direction = player.get_direction()
	#Note we use > and < because if the player doesn't move then their direction shouldn't change.
	if direction.x > 0:
		face_right()
	elif direction.x < 0:
		face_left()

func moving_forward() -> bool: #Return true if moving same direction as mouse
	var direction = player.get_direction()
	return direction.x * get_mouse_to_player_offset() > 0
	
func get_mouse_to_player_offset() -> float: #Return distance between x values of mouse and player
	return get_viewport().get_mouse_position().x - player.get_global_transform_with_canvas().origin.x	

func face_left(): #Makes the player face left
	sprite.flip_h = true
	hurtbox.scale.x = -1

func face_right(): #Makes the player face right
	sprite.flip_h = false
	hurtbox.scale.x = 1
	#stabilize_x_direction()

func stabilize_x_direction(): #When facing left, multiply each x value by -1 to account for x offset value (required every frame)
	#currently playing animation object
	var animation = get_animation(current_animation)
	if animation:
		#Track within the currently playing animation that contains the x position
		var pos_track_index = animation.find_track("Sprite:position")
		#position key at this time in the original animation
		var key_in_animation = animation.track_find_key(pos_track_index,floor(20*current_animation_position)/20)
		#position value at this time in the original animation
		var value_in_animation = animation.track_get_key_value(pos_track_index, key_in_animation)
		#Modify x values for clean animation
		sprite.position.x = value_in_animation.x*-1

func command_animate(name: String, time: float, face: String, lock: bool, start: float, scale: float): #animates the player according to given instructions
	#name is the animation's name
	#time is the requested length of the animation in seconds. -1 means infinite time
	#face is how to face the character: on key press, or on mouse direction.
	#lock determines whether or not the player will be stuck facing the same direction for the duration of the time.
	#start is the time of the animation to start at.
	#scale is the time scale of the animation.
	
	#End previous animation if there is one
	end_animation()
	#Set the current animation to name
	play(name, -1, scale)
	#Start the animation at start
	seek(start)
	
	#Set a timer for the duration of the animation
	if time >= 0:
		var animation_timer = Timer.new()
		animation_timer.set_name("animation_timer")
		add_child(animation_timer)
		animation_timer.connect("timeout", self, "end_animation")
		animation_timer.wait_time = time
		animation_timer.start()
	
	#Make the player face in the requested direction
	if face == "face_on_press":
		face_on_press()
	elif face == "face_on_mouse":
		face_on_mouse()
	elif face == "face_on_press_or_mouse":
		face_on_press_or_mouse()
	elif face == "face_left":
		face_left()
	elif face == "face_right":
		face_right()
	
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
