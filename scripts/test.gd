extends Node2D

const DummyNetworkAdapter = preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd")
const Tile = preload("res://Objects/Tile.tscn")

onready var NetworkPanel = $HUD/NetworkPanel
onready var HostField = $HUD/NetworkPanel/Grid/HostField
onready var PortField = $HUD/NetworkPanel/Grid/PortField

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")
	SyncManager.connect("sync_started", self, "_on_SyncManager_sync_started")
	SyncManager.connect("sync_stopped", self, "_on_SyncManager_sync_stopped")
	SyncManager.connect("sync_lost", self, "_on_SyncManager_sync_lost")
	SyncManager.connect("sync_regained", self, "_on_SyncManager_sync_regained")
	SyncManager.connect("sync_error", self, "_on_SyncManager_sync_error")
	
	for tile_vec in $MAP/TILES.get_used_cells():
		var fixed_tile_vec = SGFixed.vector2(SGFixed.from_int(tile_vec.x * 80), SGFixed.from_int(tile_vec.y * 80))
		var tile_node = Tile.instance()
		tile_node.fixed_position = fixed_tile_vec
		add_child(tile_node)
#	SyncManager.network_adaptor = DummyNetworkAdapter.new()
#	SyncManager.start()


func _process(delta):
	$HUD/ServerPos.text = "Server: (%s, %s)" % [$ServerPlayer.position.x, $ServerPlayer.position.y]
	$HUD/ClientPos.text = "Client: (%s, %s)" % [$ClientPlayer.position.x, $ClientPlayer.position.y]
	
	if (get_tree().is_network_server()):
		$HUD/ThisMot.text = "Motion: %s" % $ServerPlayer.form_string
	else: 
		$HUD/ThisMot.text = "Motion: %s" % $ClientPlayer.form_string


func _on_HostButton_pressed():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(int(PortField.text), 1)
	get_tree().network_peer = peer
	NetworkPanel.visible = false
	print("Listening...")


func _on_ClientButton_pressed():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(HostField.text, int(PortField.text))
	get_tree().network_peer = peer
	NetworkPanel.visible = false
	print("Connecting...")

func _on_network_peer_connected(peer_id):
	print("Connected!")
	SyncManager.add_peer(peer_id)
	
	$ServerPlayer.set_network_master(1)
	if get_tree().is_network_server():
		$ClientPlayer.set_network_master(peer_id)
	else:
		$ClientPlayer.set_network_master(get_tree().get_network_unique_id())
	
	if (get_tree().is_network_server()):
		print("startings...")
		yield(get_tree().create_timer(2.0), "timeout")
		SyncManager.start()
		$ServerPlayer.get_node("Camera").current = true
	else:
		$ClientPlayer.get_node("Camera").current = true

func _on_network_peer_disconnected(peer_id):
	print("Disconnected")
	SyncManager.remove_peer(peer_id)


func _on_server_disconnected():
	_on_network_peer_disconnected(1)


func _on_ResetButton_pressed():
	SyncManager.stop()
	SyncManager.clear_peers()
	var peer = get_tree().network_peer
	if (peer):
		peer.close_connection()
	get_tree().reload_current_scene()

func _on_SyncManager_sync_started():
	print("Started!")
	
func _on_SyncManager_sync_stopped():
	pass

func _on_SyncManager_sync_lost():
	print("\nSYNC LOST!\n")

func _on_SyncManager_sync_regained():
	print("\nSYNC REGAINED!\n")

func _on_SyncManager_sync_error(msg):
	print("\n\n\nFATAL SYNC ERROR\n\n\n")
	
	var peer = get_tree().network_peer
	if (peer):
		peer.close_connection()
	SyncManager.clear_peers()
