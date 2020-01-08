extends Actor

func _physics_process(delta):
	#Handle movement
	var direction: = get_direction()
	_velocity = calculate_move_velocity(_velocity, speed, direction)
	var snap = Vector2(0,40) if not is_jumping() else Vector2.ZERO
	_velocity = move_and_slide_with_snap(_velocity, snap,  FLOOR_NORMAL, false, 4, PI/4, false)
	

func _process(delta):
	animate()
	#Uncomment if need to check fps
	#print(Engine.get_frames_per_second())

func get_direction() -> Vector2: #Output horizontal and vertical vector based on input
	var out: = Vector2.ZERO
	out.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if Input.is_action_just_pressed("jump") and is_on_floor():
		out.y = -1.0
	else:
		out.y = 1.0
	return out
	
func calculate_move_velocity( #Calculate the velocity the player will move at
		linear_velocity: Vector2,
		speed: Vector2,
		direction: Vector2
	) -> Vector2:
	var out: = linear_velocity
	
	#If actor cannot act and is immobile, keep them moving in the same direction but slowed down
	if not can_act:
		out.x = out.x*0.6
		return out
	
	
	#walking left/right
	out.x = speed.x * direction.x
	#sprinting
	if Input.is_action_pressed("sprint_toggle") and direction.x != 0 and moving_forward(): 
		out.x = speed.x * direction.x * 1.5
	#falling
	out.y += gravity*get_physics_process_delta_time()
	#jumping
	if direction.y == -1.0: 
		out.y = speed.y * direction.y
	#interrupt jump
	elif is_jump_interrupted(): 
		out.y *= 0.25
	#fast fall
	elif Input.is_action_pressed("move_down") and not is_on_floor(): 
		out.y = speed.y * direction.y
	#slide
	elif Input.is_action_pressed("move_down") and is_on_floor() and direction.x != 0 and moving_forward(): 
		if Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
			out.x = 1.75*direction.x*speed.x
		else:
			out.x = linear_velocity.x*0.97
	return out
	

func animate(): #Animate player based on input and velocity
	var xdir: = get_direction().x
	var ydir: = get_velocity().y
	var player = $AnimationPlayer
#Adjust horizontal flipping based on whether facing left or right
	if get_mouse_to_player_offset() >= 0:
		$Sprite.flip_h = false
	else:
		$Sprite.flip_h = true
		if $AnimationPlayer.is_playing() and player.current_animation != "stand": #To avoid glitch when rapidly changing between back and forward
			#currently playing animation object
			var animation = player.get_animation(player.current_animation)
			#Track within the currently playing animation that contains the x position
			var pos_track_index = animation.find_track("Sprite:position")
			#position key at this time in the original animation
			var key_in_animation = animation.track_find_key(pos_track_index,floor(20*player.current_animation_position)/20)
			#position value at this time in the original animation
			var value_in_animation = animation.track_get_key_value(pos_track_index, key_in_animation)
			#Modify x values for clean animation
			$Sprite.position.x = value_in_animation.x*-1
	#Check if walking backwards using multiplication of unary signs properties
	if not moving_forward() and player.current_animation == "walk":
		player.playback_speed = -1
	else:
		player.playback_speed = 1
#Animate sprite
	if is_on_floor():
		if xdir == 0:
			player.current_animation = "stand"
		elif Input.is_action_pressed("move_down") and moving_forward():
			player.current_animation = "slide"
		elif Input.is_action_pressed("sprint_toggle") and moving_forward():
			player.current_animation = "run"
		else:
			player.current_animation = "walk"
	elif ydir < 0:
		player.current_animation = "jump"
	elif ydir > 0:
		player.current_animation = "fall"
		

func get_mouse_to_player_offset() -> float: #Return distance between x values of mouse and player
	return get_viewport().get_mouse_position().x - get_global_transform_with_canvas().origin.x

func moving_forward() -> bool: #Return true if moving same direction as mouse
	return get_direction().x * get_mouse_to_player_offset() > 0

func facing_right() -> bool: #Return true if facing to the right, false if facing left
	return $Sprite.flip_h == false

func get_velocity() -> Vector2: #Return workable velocity
	return Vector2(_velocity.x, _velocity.y - 50/3)

func is_jumping() -> bool: 
#Return true if player is in the process of jumping
	return (Input.is_action_pressed("jump") or Input.is_action_just_released("jump"))

func is_jump_interrupted() -> bool: #Return true if user has just released the jump key
	return Input.is_action_just_released("jump") and _velocity.y < 0.0