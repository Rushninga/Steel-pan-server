extends Control
var server = ENetMultiplayerPeer.new()
var host_address 
var default_port = 8000
var port
signal send_id

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	
	pass # Replace with function body.


func _on_button_pressed():
	server.create_server(default_port)
	multiplayer.multiplayer_peer = server
	host_address = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	$VBoxContainer/Label.text = host_address
	


func _on_player_connected(id):
	$VBoxContainer/Label.text += "\nPlayer " 
	$VBoxContainer/Label.text += str(id)
	$VBoxContainer/Label.text += " has connected"
	emit_signal("send_id", id)
	pass
