extends "res://scripts/MonoMessageSerializer.gd"

const examp_input = {
	"joy_dir": 1,
	"jump": true,
	"ff": false,
	"dash": false,
	"angle": 33.5
}

func _ready():
	var msg = serialize_input({"$":1, "/root/Test/ClientPlayer": examp_input})
	var decoded_input = unserialize_input(msg)
	print(decoded_input)
