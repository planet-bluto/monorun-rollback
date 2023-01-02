extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"

const path_to_int = {
	"/root/Test/ServerPlayer": 1,
	"/root/Test/ClientPlayer": 2,
}

enum HeaderFlags {
	JUMP = 0x01,
	DASH = 0x02,
	FASTFALL = 0x04,
}

const DirectionBit = {
	0: 0,
	1: 1,
	-1: 2
}

var BitDirection = {}

var int_to_path = {}

func _init():
	for key in path_to_int:
		int_to_path[path_to_int[key]] = key
	for key in DirectionBit:
		BitDirection[DirectionBit[key]] = key

func serialize_input(all_input: Dictionary) -> PoolByteArray:
	var buffer = StreamPeerBuffer.new()
	buffer.resize(16)
	
	buffer.put_u32(all_input['$'])
	buffer.put_u8(all_input.size() - 1)
	
	for path in all_input:
		if path == '$': 
			continue
		buffer.put_u8(path_to_int[path])
		
		var header := 0
		
		var input = all_input[path]
		if input.jump: header |= HeaderFlags.JUMP
		if input.dash: header |= HeaderFlags.DASH
		if input.ff: header |= HeaderFlags.FASTFALL
		
		buffer.put_u8(header)
		buffer.put_u8(DirectionBit[input.joy_dir])
		buffer.put_u16((input.angle+360)*2)
	
	buffer.resize(buffer.get_position())
	return buffer.data_array

func unserialize_input(serialized: PoolByteArray) -> Dictionary:
	var buffer = StreamPeerBuffer.new()
	buffer.put_data(serialized)
	buffer.seek(0)
	
	var all_input = {}
	
	all_input['$'] = buffer.get_u32()
	
	var input_count = buffer.get_u8()
	if (input_count == 0): return all_input
	
	var path = int_to_path[buffer.get_u8()]
	var input = {}
	
	var header = buffer.get_u8()
	input.jump = (header & HeaderFlags.JUMP)
	input.dash = (header & HeaderFlags.DASH)
	input.ff = (header & HeaderFlags.FASTFALL)
	
	var joy_dir = buffer.get_u8()
	input.joy_dir = BitDirection[joy_dir]
	
	var ang = buffer.get_u16()
	input.angle = (ang/2)-360
	
	all_input[path] = input
	
	return all_input
