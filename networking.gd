extends Node
var id
var username = "shernan"
var password = "password"
var connected_ids = []
var list_connected_user_info = {
	"username" : [],
	"id" : []
}
var list_user_info = {
	"username" : ["shernan"],
	"password" : ["password"],
}




func _ready():
	$Node2D.send_id.connect(add_id)


func add_id(id):
	connected_ids.append(id)



@rpc("any_peer", "reliable", "call_local")
func send_user_info(username_recieved, password_received, mode_received):
	if multiplayer.is_server():
		var id = multiplayer.get_remote_sender_id()
		if mode_received == "sign in":
			
			pass
		else:
			var list_count = 0
			for i in list_user_info["username"]:
				if username_recieved == i and password_received == list_user_info["password"][list_count]:
					rpc_id(id, "user_login_confirm")
				list_count += 1
			
			
			if username_recieved == username and password_received == password:
				
				pass
		
		list_connected_user_info["username"] = username_recieved
		list_connected_user_info["id"] = multiplayer.get_remote_sender_id()
		
@rpc("authority", "unreliable_ordered", "call_remote")
func user_login_confirm():
	pass
