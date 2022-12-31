extends SGKinematicBody2D

const local = false
var form_string = "(kill me)"

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
## rescale = 50.0 (as of 12/30/2022)
## fixedMovar = floor((movar/rescale)*65536)
#	"SPEED": 700,
#	"ACCEL": 90,
#	"DASHSPEED": 1200,
#	"GRAV": 40,
#	"FASTGRAV": 50,
#	"MAXFALL": 1200,
#	"JUMP": 1300
#	"FRICTION": 1.2,
#	"DASH_FRICTION": 1.04,
#	"AIR_FRICTION": 1.009,

## Unscaled Motion Vars ##
## (These variables aren't scaled; Friction variables)
## fixedMovar = floor(movar*65536)
#	"FRICTION",
#	"DASH_FRICTION",
#	"AIR_FRICTION"

const ZEROENOUGH = 6553

const fixed = {
	SPEED = 458752,
	ACCEL = 58982,
	DASHSPEED = 786432,
	GRAV = 26214,
	FASTGRAV = 32768,
	MAXFALL = 786432,
	JUMP = 851968,
	FRICTION = 78643,
#	FRICTION = 157286,
	DASH_FRICTION = 68157,
#	DASH_FRICTION = 136314,
	AIR_FRICTION = 66125,
#	AIR_FRICTION = 132251,
}

var UP = SGFixed.vector2(0, SGFixed.from_int(-1))
var state_vars = {
	"motion": SGFixed.vector2(0, 0),
	"last_dir": 1,
	"grounded": false,
	"ground_timer": 0,
	"dashing": false
}
#var motion = SGFixed.vector2(0, 0)
#var last_dir = 1
#var grounded = true
#var ground_timer = 0
#var dashing = false

func _ready():
	pass
#	for movar in unfixed:
#		if (unscaled_movars.has(movar)):
#			fixed[movar] = SGFixed.from_float(unfixed[movar])
#		else:
#			fixed[movar] = SGFixed.div(SGFixed.from_float(float(unfixed[movar])), SGFixed.from_float(rescale))
	
	# input_timer setup
	for key in INPUT_KEYS:
		input_timer[key] = 0

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
	
	return input

func _process(delta):
	pass

func _physics_process(delta):
	# input_timer processing
	for key in INPUT_KEYS:
		if (Input.is_action_pressed(key)):
			input_timer[key] += 1
		else:
			input_timer[key] = 0
	
	if (local):
		_movement_process(_get_local_input())

func _input_process():
	pass

func _movement_process(input):
	# Saves whether you last pressed Left or Right inputs
	if (input.joy_dir != 0): 
		state_vars.last_dir = input.joy_dir
	
	if (input.joy_dir != 0): # ( if moving left or right )
		# Horizontal movement
		state_vars.motion.x += fixed.ACCEL*input.joy_dir
	else:
		# What friction to use (ground? dash? air?)
		var curr_fric = fixed.FRICTION
		if (state_vars.dashing): 
			curr_fric = fixed.DASH_FRICTION
		if (!state_vars.grounded):
			curr_fric = fixed.AIR_FRICTION
	
		# Friction (gradual slowdowns)
		if (abs(state_vars.motion.x) > ZEROENOUGH):
			state_vars.motion.x = SGFixed.div(state_vars.motion.x, curr_fric)
		else:
			state_vars.motion.x = 0
#		motion.x = 0
	
	if (is_on_floor()):
		state_vars.grounded = true
		state_vars.ground_timer += 1
		if (state_vars.ground_timer == 1): state_vars.motion.y = 0
	if (!is_on_floor()):
		state_vars.grounded = false
		state_vars.ground_timer = 0
	
		# Gravity and fast falling on down input
		var curr_ff = 0
		if (input.ff): curr_ff = fixed.FASTGRAV
		state_vars.motion.y += (fixed.GRAV+curr_ff)
		if (state_vars.motion.y > fixed.MAXFALL):
			state_vars.motion.y = fixed.MAXFALL
	
	# Jump if jump input is true
	if (input.jump):
		state_vars.motion.y = -fixed.JUMP
	
	# Dash if dash input is true
	if (input.dash):
		state_vars.motion.x = (fixed.DASHSPEED*state_vars.last_dir)
		state_vars.dashing = true

	# Leave dashing state
	if (abs(state_vars.motion.x) < fixed.SPEED and state_vars.grounded):
		state_vars.dashing = false
	
	# Clamp yo hori speed
	if (state_vars.dashing):
		state_vars.motion.x = clamp(state_vars.motion.x, -fixed.DASHSPEED, fixed.DASHSPEED)
	else:
		state_vars.motion.x = clamp(state_vars.motion.x, -fixed.SPEED, fixed.SPEED)
	
	move_and_slide(state_vars.motion, UP)
#	fixed_position = SGFixed.vector2(SGFixed.round(fixed_position.x), SGFixed.round(fixed_position.y))

func _collision_check():
	$Cast.set_exceptions([self])
	$Cast.update_raycast_collision()
	var fixedColPoint = $Cast.get_collision_point()
#		print(SGFixed.to_float(fixedColPoint.y))
	# Going Down, Detecting Ground, Future Y Coord more than Ground Y Coord
	if (state_vars.motion.y > 0 and $Cast.is_colliding() and (fixed_position_y+state_vars.motion.y >= fixedColPoint.y)):
		state_vars.grounded = true
		state_vars.motion.y = 0
		fixed_position_y = fixedColPoint.y
	elif (!$Cast.is_colliding() or fixed_position_y+state_vars.motion.y < fixedColPoint.y):
		state_vars.grounded = false

func _alt_movement_process(input):
	var fixed_joy_dir = SGFixed.from_int(input.joy_dir)
	
	# Saves whether you last pressed Left or Right inputs
	if (input.joy_dir != 0): 
		state_vars.last_dir = input.joy_dir
	
	if (input.joy_dir != 0): # ( if moving left or right )
		# Horizontal movement
		state_vars.motion.x += fixed.ACCEL*input.joy_dir
	else:
#		motion.x = 0
		# What friction to use (ground? dash? air?)
		var curr_fric = fixed.FRICTION
		if (state_vars.dashing): 
			curr_fric = fixed.DASH_FRICTION
		if (!state_vars.grounded):
			curr_fric = fixed.AIR_FRICTION
	#------------------------------------------#
		# Friction (gradual slowdowns)
		if (abs(state_vars.motion.x) > ZEROENOUGH):
			state_vars.motion.x = SGFixed.div(state_vars.motion.x, curr_fric)
		else:
			state_vars.motion.x = 0
	
	if (!state_vars.grounded):
		state_vars.motion.y += fixed.GRAV
	else:
		if input.jump:
			state_vars.motion.y = -fixed.JUMP

	state_vars.motion.x = clamp(state_vars.motion.x, -fixed.SPEED, fixed.SPEED)
	state_vars.motion.y = clamp(state_vars.motion.y, -fixed.MAXFALL, fixed.MAXFALL)
	
	var form_x = SGFixed.format_string(state_vars.motion.x)
	var form_y = SGFixed.format_string(state_vars.motion.y)
	form_string = "(%s, %s)" % [form_x, form_y]
	
	fixed_position_x = (fixed_position_x + state_vars.motion.x)
	fixed_position_y = (fixed_position_y + state_vars.motion.y)

### NETWORKING ###

func _network_process(input):
	_collision_check()
	_alt_movement_process(input)
#	_movement_process(input)

func _save_state():
	var state = {}
	
	state['fixed_position_x'] = fixed_position_x
	state['fixed_position_y'] = fixed_position_y
#	for key in state_vars:
#		state["m_"+key] = state_vars[key]
	if state_vars.motion.x != 0: state['motion_x'] = state_vars.motion.x
	if state_vars.motion.y != 0: state['motion_y'] = state_vars.motion.y
	
	if state_vars.grounded: state["grounded"] = true

	return state

func _load_state(state):
	fixed_position_x = state.get('fixed_position_x')
	fixed_position_y = state.get('fixed_position_y')
#	for key in state_vars:
#		state_vars[key] = state["m_"+key]
	state_vars.motion.x = state.get('motion_x', 0)
	state_vars.motion.y = state.get('motion_y', 0)
	
	state_vars.grounded = state.get('grounded', false)
	
#	sync_to_physics_engine()
