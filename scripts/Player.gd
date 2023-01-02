extends SGKinematicBody2D

var form_string = "lmao"

# Input Vars #
const INPUT_KEYS = [ #Keys for referring to input; REMEMBER THE ORDER
	"U", # Up
	"D", # Down
	"L", # Left
	"R", # Right
	"JUMP", # ....pretty self explanatory
	"DASH", # ... same here
	"S1", # Main 'Shoot' input (left click OR right trigger on gamepad)
	"S2", # Secondary 'Movement' or 'Modifier' input (right click OR left trigger)
]
var input_timer = {}

## Defaul Godot Physics Movement Vars ##
## (These are the base variables before being converted MANUALLY in speed crunch to be a set fixed constant)
## rescale = 62.0 (as of 12/31/2022)
## fixedMovar = floor((movar/rescale)*65536)
#	"SPEED": 700,
#	"ACCEL": 90,
#	"DASHSPEED": 1200,
#	"GRAV": 40,
#	"FASTGRAV": 50,
#	"MAXFALL": 1200,
#	"JUMP": 1300,
#	"JUMP": sqrt(SPEED^2+JUMP^2),
#	"FRICTION": 1.2,
#	"DASH_FRICTION": 1.04,
#	"AIR_FRICTION": 1.009,

## Unscaled Motion Vars ##
## (These variables aren't scaled; Friction variables)
## fixedMovar = floor(movar*65536)
#	"FRICTION",
#	"DASH_FRICTION",
#	"AIR_FRICTION",

const fixed = {
	SPEED = 739922,
	ACCEL = 95132,
	DASHSPEED = 1268438,
	GRAV = 42281,
	FASTGRAV = 52851,
	MAXFALL = 1268438,
	JUMP = 1374141,
	MAXVELO = 1560689,
	FRICTION = 78643,
	DASH_FRICTION = 68157,
	AIR_FRICTION = 66125,
}

const ZEROENOUGH = 6553

# Scale testing (don't mind me)
#var rescale = 62.0
#var fixed = {
#	"SPEED": SGFixed.from_float(float(700)/rescale),
#	"ACCEL": SGFixed.from_float(float(90)/rescale),
#	"DASHSPEED": SGFixed.from_float(float(1200)/rescale),
#	"GRAV": SGFixed.from_float(float(40)/rescale),
#	"FASTGRAV": SGFixed.from_float(float(50)/rescale),
#	"MAXFALL": SGFixed.from_float(float(1200)/rescale),
#	"JUMP": SGFixed.from_float(float(1300)/rescale),
#	"FRICTION": 78643,
#	"DASH_FRICTION": 68157,
#	"AIR_FRICTION": 66125,
#}

var UP = SGFixed.vector2(0, SGFixed.from_int(-1))
var motion = SGFixed.vector2(0, 0)
var last_dir = 1
var grounded = false
var ground_timer = 0
var dashing = false
var walled_r = false
var walled_l = false
var last_fixed_position = {"x": fixed_position_x, "y": fixed_position_y}
var curr_anim = "Idle"
var last_curr_anim = ""
var aim_angle = 0

var casts = {
	"ceil": [],
	"floor": [],
	"right": [],
	"left": [],
	"tl": SGRayCast2D.new(),
	"tr": SGRayCast2D.new(),
	"bl": SGRayCast2D.new(),
	"br": SGRayCast2D.new(),
}

func _ready():
	for y in 2:
		var right_cast = SGRayCast2D.new()
		var left_cast = SGRayCast2D.new()
		casts.right.append(right_cast)
		casts.left.append(left_cast)
		var y_pos = SGFixed.from_int(-40*y)
		right_cast.cast_to_x = fixed.SPEED+SGFixed.from_int(15)
		right_cast.cast_to_y = 0
		left_cast.cast_to_x = -fixed.SPEED-SGFixed.from_int(15)
		left_cast.cast_to_y = 0
		right_cast.fixed_position_x = 0
		right_cast.fixed_position_y = y_pos
		left_cast.fixed_position_x = 0
		left_cast.fixed_position_y = y_pos
		right_cast.set_collision_mask_bit(0, false)
		right_cast.set_collision_mask_bit(3, true)
		right_cast.set_collision_mask_bit(2, true)
		left_cast.set_collision_mask_bit(0, false)
		left_cast.set_collision_mask_bit(3, true)
		left_cast.set_collision_mask_bit(2, true)
		add_child(right_cast)
		add_child(left_cast)
	for x in 2:
		var ceil_cast = SGRayCast2D.new()
		var floor_cast = SGRayCast2D.new()
		casts.ceil.append(ceil_cast)
		casts.floor.append(floor_cast)
		var x_pos = SGFixed.from_int((30*x)-15)
#		ceil_cast.cast_to_x = x_pos
		ceil_cast.cast_to_y = -fixed.JUMP-SGFixed.from_int(20)
#		floor_cast.cast_to_x = x_pos
		floor_cast.cast_to_y = fixed.MAXFALL+SGFixed.from_int(20)
		ceil_cast.fixed_position_x = x_pos
		floor_cast.fixed_position_x = x_pos
		floor_cast.fixed_position_y = -SGFixed.from_int(20)
		ceil_cast.fixed_position_y = -SGFixed.from_int(20)
		ceil_cast.set_collision_mask_bit(0, false)
		ceil_cast.set_collision_mask_bit(4, true)
		floor_cast.set_collision_mask_bit(0, false)
		floor_cast.set_collision_mask_bit(1, true)
		add_child(ceil_cast)
		add_child(floor_cast)
	
#	var corner_order = [
#		{"x": -1, "y": -1},
#		{"x": 1, "y": -1},
#		{"x": -1, "y": 1},
#		{"x": 1, "y": 1},
#	]
#	var corner_casts = ["tl","tr", "bl", "br"]
#	var c_ind = 0
#	for corner in corner_casts:
#		casts[corner].fixed_position_x = SGFixed.from_int(15*corner_order[c_ind].x)
#		casts[corner].fixed_position_y = SGFixed.from_int((20*corner_order[c_ind].y)-20)
#		casts[corner].cast_to_x = fixed.MAXVELO*corner_order[c_ind].x
#		casts[corner].cast_to_y = fixed.MAXVELO*corner_order[c_ind].y
#
#		casts[corner].set_collision_mask_bit(0, false)
#		casts[corner].set_collision_mask_bit(1, true)
#		casts[corner].set_collision_mask_bit(2, true)
#		casts[corner].set_collision_mask_bit(3, true)
#		casts[corner].set_collision_mask_bit(4, true)
#		add_child(casts[corner])
#		c_ind += 1
	
	# input_timer setup
	for key in INPUT_KEYS:
		input_timer[key] = 0

func roundToHalf(x):
	return round(x*2)/2

func _get_local_input():
	var input = {
		"joy_dir": 0,
		"jump": false,
		"dash": false,
		"ff": false # (fastfall)
	}
	
	# Refers to input_timer to see most recent input pressed between left and right
	if ((input_timer["R"] != 0) and ((input_timer["L"] == 0) or input_timer["R"] < input_timer["L"])):
		input.joy_dir = 1
	if ((input_timer["L"] != 0) and ((input_timer["R"] == 0) or input_timer["L"] < input_timer["R"])):
		input.joy_dir = -1
	
	if (Input.is_action_just_pressed("JUMP")):
		input.jump = true
	
	if (Input.is_action_just_pressed("DASH")):
		input.dash = true
	
	if (Input.is_action_pressed("D")):
		input.ff = true
	
	var mouse_screen_pos = get_global_mouse_position()
	var screen_pos = get_transform().get_origin() - Vector2(0,-20)
	
	input.angle = roundToHalf(rad2deg(atan2(mouse_screen_pos.y-screen_pos.y, mouse_screen_pos.x-screen_pos.x)))
	aim_angle = input.angle
	
	return input

func _process(delta):
	# input_timer processing
	for key in INPUT_KEYS:
		if (Input.is_action_pressed(key)):
			input_timer[key] += 1
		else:
			input_timer[key] = 0

func _old_movement_process(input):
	# Saves whether you last pressed Left or Right inputs
	if (input.joy_dir != 0): 
		last_dir = input.joy_dir
	
	if (input.joy_dir != 0): # ( if moving left or right )
		# Horizontal movement
		motion.x += fixed.ACCEL*input.joy_dir
	else:
		# What friction to use (ground? dash? air?)
		var curr_fric = fixed.FRICTION
		if (dashing): 
			curr_fric = fixed.DASH_FRICTION
		if (!grounded):
			curr_fric = fixed.AIR_FRICTION
	
		# Friction (gradual slowdowns)
		if (abs(motion.x) > ZEROENOUGH):
			motion.x = SGFixed.div(motion.x, curr_fric)
		else:
			motion.x = 0
#		motion.x = 0
	
	if (is_on_floor()):
		grounded = true
		ground_timer += 1
		if (ground_timer == 1): motion.y = 0
	if (!is_on_floor()):
		grounded = false
		ground_timer = 0
	
		# Gravity and fast falling on down input
		var curr_ff = 0
		if (input.ff): curr_ff = fixed.FASTGRAV
		motion.y += (fixed.GRAV+curr_ff)
		if (motion.y > fixed.MAXFALL):
			motion.y = fixed.MAXFALL
	
	# Jump if jump input is true
	if (input.jump):
		motion.y = -fixed.JUMP
	
	# Dash if dash input is true
	if (input.dash):
		motion.x = (fixed.DASHSPEED*last_dir)
		dashing = true

	# Leave dashing state
	if (abs(motion.x) < fixed.SPEED and grounded):
		dashing = false
	
	# Clamp yo hori speed
	if (dashing):
		motion.x = clamp(motion.x, -fixed.DASHSPEED, fixed.DASHSPEED)
	else:
		motion.x = clamp(motion.x, -fixed.SPEED, fixed.SPEED)
	
		move_and_slide(motion, UP)
#	fixed_position = SGFixed.vector2(SGFixed.round(fixed_position.x), SGFixed.round(fixed_position.y))

func _collision_check(input):
	var previous_coll = false
	
	# Ground Collision (THE MOST IMPORTANT ONE)
	var future_x_pos = fixed_position_x+motion.x
	var future_y_pos = fixed_position_y+motion.y
	
	var box_w = SGFixed.from_int(15)
	var box_h = SGFixed.from_int(40)
	
	## FLOOR ##
	var floor_loop_true = 0
	for cast in casts.floor:
		cast.set_exceptions([self])
		cast.update_raycast_collision()
		var fixedColPoint = cast.get_collision_point()
		# Going Down, Detecting Ground, Future Y Coord more than Ground Y Coord
		if (motion.y > 0 and cast.is_colliding() and (future_y_pos >= fixedColPoint.y)):
#			grounded = true
			previous_coll = true
			floor_loop_true += 1
			motion.y = 0
			fixed_position_y = fixedColPoint.y
		elif ((!cast.is_colliding() or future_y_pos < fixedColPoint.y)):
			floor_loop_true -= 1
	grounded = !(floor_loop_true == -2)
	
	## CEILLING ##
	var ceil_loop_true = 0
	for cast in casts.ceil:
		cast.set_exceptions([self])
		cast.update_raycast_collision()
		var fixedColPoint = cast.get_collision_point()
#		print("(%s, %s, %s)" % [motion.y < 0, cast.is_colliding(), future_y_pos-40 <= fixedColPoint.y])
		# Going Down, Detecting Ground, Future Y Coord less than Ground Y Coord
		if (motion.y < 0 and cast.is_colliding() and (future_y_pos-box_h <= fixedColPoint.y)):
#			grounded = true
			previous_coll = true
			ceil_loop_true += 1
			motion.y = 0
			fixed_position_y = fixedColPoint.y+box_h
		elif ((!cast.is_colliding() or future_y_pos-box_h < fixedColPoint.y)):
			ceil_loop_true -= 1
#	grounded = !(floor_loop_true == -7)
	
	## WALL (RIGHT) ##
	var right_loop_true = 0
	for cast in casts.right:
		cast.set_exceptions([self])
		cast.update_raycast_collision()
		var fixedColPoint = cast.get_collision_point()
		# Going Down, Detecting Ground, Future X Coord more than Wall X Coord
		if (motion.x > 0 and cast.is_colliding() and (future_x_pos+box_w >= fixedColPoint.x)):
#			grounded = true
			previous_coll = true
			right_loop_true += 1
			motion.x = 0
			fixed_position_x = fixedColPoint.x-box_w
		elif ((!cast.is_colliding() or future_x_pos+box_w > fixedColPoint.x)):
			right_loop_true -= 1
	walled_r = !(right_loop_true == -2)
	
	## WALL (Left) ##
	var left_loop_true = 0
	for cast in casts.left:
		cast.set_exceptions([self])
		cast.update_raycast_collision()
		var fixedColPoint = cast.get_collision_point()
		# Going Down, Detecting Ground, Future X Coord less than Wall X Coord
		if (motion.x < 0 and cast.is_colliding() and (future_x_pos-box_w <= fixedColPoint.x)):
#			grounded = true
			previous_coll = true
			left_loop_true += 1
			if (motion.x != 0):
				motion.x = 0
			fixed_position_x = fixedColPoint.x+box_w
		elif ((!cast.is_colliding() or future_x_pos-box_w < fixedColPoint.x)):
			left_loop_true -= 1
	walled_l = !(left_loop_true == -2)
	
#	if (fixed_position_x-box_w < SGFixed.from_int(2400)):
#		pass
	
	## EXTRA VELOCITY CHECK ##
#	var corner_order = [
#		{"x": -1, "y": -1},
#		{"x": 1, "y": -1},
#		{"x": -1, "y": 1},
#		{"x": 1, "y": 1},
#	]
#	var corner_casts = ["tl","tr", "bl", "br"]
#	var c_ind = 0
#	for corner in corner_casts:
#		var cast = casts[corner]
#		var coords = corner_order[c_ind]
#		cast.update_raycast_collision()
#		var corner_future_pos_x = cast.fixed_position_x+future_x_pos
#		var corner_future_pos_y = cast.fixed_position_y+future_y_pos
#		var fixedColPoint = cast.get_collision_point()
#		var hori = cast.get_collision_normal().x*-1
#		var vert = cast.get_collision_normal().y*-1
##		print("FUTURE POS_X: %s" % abs(future_x_pos+cast.fixed_position_x))
##		print("FUTURE POS_Y: %s" % abs(future_y_pos+cast.fixed_position_y))
##		print("COLLIDE POS_X: %s" % abs(fixedColPoint.x))
##		print("COLLIDE POS_Y: %s" % abs(fixedColPoint.y))
##		var stop_x = false
##		var stop_y = false
##		if (corner == "tl" and 
##			corner_future_pos_x
##		)
#		if (!previous_coll and cast.is_colliding() and ((corner_future_pos_x)*coords.x > fixedColPoint.x*coords.x) and ((corner_future_pos_y)*coords.y > fixedColPoint.y*coords.y)):
#			if (corner_future_pos_x > corner_future_pos_y):
#				motion.x = 0
#			else:
#				motion.y = 0
##		if (cast.is_colliding() and vert != 0 and (corner_future_pos_y)*vert >= (fixedColPoint.y)*vert and ! (abs(corner_future_pos_x) < abs(fixedColPoint.x))):
##			motion.y = 0
#		c_ind += 1

func _movement_process(input):
	var fixed_joy_dir = SGFixed.from_int(input.joy_dir)
	
	# Saves whether you last pressed Left or Right inputs
	if (input.joy_dir != 0): 
		last_dir = input.joy_dir
	
	if (input.joy_dir != 0): # ( if moving left or right )
		# Horizontal movement
		motion.x += fixed.ACCEL*input.joy_dir
	else:
#		motion.x = 0
		# What friction to use (ground? dash? air?)
		var curr_fric = fixed.FRICTION
		if (dashing): 
			curr_fric = fixed.DASH_FRICTION
		if (!grounded):
			curr_fric = fixed.AIR_FRICTION
	#------------------------------------------#
		# Friction (gradual slowdowns)
		if (abs(motion.x) > ZEROENOUGH):
			motion.x = SGFixed.div(motion.x, curr_fric)
		else:
			motion.x = 0
	
	if (!grounded):
		var curr_ff = 0
		if (input.ff): curr_ff = fixed.FASTGRAV
		motion.y += fixed.GRAV+curr_ff
	else:
		if input.jump:
			motion.y = -fixed.JUMP
	
	# Dash if dash input is true
	if (input.dash and grounded):
		motion.x = (fixed.DASHSPEED*last_dir)
		dashing = true

	# Leave dashing state
	if (abs(motion.x) < fixed.SPEED and grounded):
		dashing = false
	
	# Clamp yo motion
	if (dashing):
		motion.x = clamp(motion.x, -fixed.DASHSPEED, fixed.DASHSPEED)
	else:
		motion.x = clamp(motion.x, -fixed.SPEED, fixed.SPEED)
	motion.y = clamp(motion.y, -INF, fixed.MAXFALL)
	
#	fixed_position_x = (fixed_position_x + motion.x)
#	fixed_position_y = (fixed_position_y + motion.y)

func _animate(input):
	$Sprite.flip_h = (abs(input.angle) > 90)
	
	if (grounded):
		if (input.joy_dir == 0):
			curr_anim = "Idle"
		else:
			curr_anim = "Run"
	else:
		if (motion.y < 0):
			curr_anim = "Jump"
		else:
			curr_anim = "Fall"
	
	if (last_curr_anim != curr_anim):
		$Anim.play(curr_anim)
	
	last_curr_anim = curr_anim

func _apply_motion():
	last_fixed_position = {"x": fixed_position_x, "y": fixed_position_y}
	fixed_position_x = (fixed_position_x + motion.x)
	fixed_position_y = (fixed_position_y + motion.y)

### NETWORKING ###

func _network_process(input):
	if (!input.empty()):
#		_pre_collision_check(input)
		_movement_process(input)
		_collision_check(input)
		_animate(input)
		form_string = "(%s, %s)" % [walled_l, walled_r]
		_apply_motion()
#	_movement_process(input)

func _save_state():
	var state = {}
	
	state['fixed_position_x'] = fixed_position_x
	state['fixed_position_y'] = fixed_position_y
	state['last_fixed_position'] = last_fixed_position
	
	state['curr_anim'] = curr_anim
	state['last_curr_anim'] = last_curr_anim
	
	if motion.x != 0: state['motion_x'] = motion.x
	if motion.y != 0: state['motion_y'] = motion.y
	
	if grounded: state["grounded"] = true
	if dashing: state["dashing"] = true
	
#	state["aim_angle"] = aim_angle

	return state

func _load_state(state):
	fixed_position_x = state.get('fixed_position_x')
	fixed_position_y = state.get('fixed_position_y')
	last_fixed_position = state.get('last_fixed_position')
	
	curr_anim = state.get('curr_anim')
	last_curr_anim = state.get('last_curr_anim')
	
	motion.x = state.get('motion_x', 0)
	motion.y = state.get('motion_y', 0)
	
	grounded = state.get('grounded', false)
	dashing = state.get('dashing', false)
	
#	aim_angle = state.get('aim_angle')
	
#	sync_to_physics_engine()
