extends Node
@onready var user_info = $Node2D.connected_user_info
@onready var user_class = $Node2D.user
@onready var db = $Node2D.db
var query:String
var bindings:Array 



func _ready():
	$Node2D.connect("login_confirm", _login_confirm)


func _login_confirm():
	
	pass


@rpc("any_peer", "reliable", "call_local")
func send_user_info(username_received, email_received, password_received, mode_received):
	if multiplayer.is_server():
		var id = multiplayer.get_remote_sender_id()
		if mode_received == "sign in":
			print(username_received)
			print(password_received)
			print(email_received)
			pass
		else:
			bindings = [username_received, password_received]
			query = "SELECT username,password FROM user_info WHERE username = ? AND password = ?;"
			db.query_with_bindings(query, bindings)
			var results = db.query_result
			var message
			if results.is_empty(): #sends a login confirmation to client, 1 == username or password is incorrect, 1 is login was sucessful and 3 is unknown error 
				message = 1
			elif results.size() == 1:
				message = 2
				user_info.append(user_class.new(id,username_received,email_received))
			else:
				message = 3
			user_login_confirm.rpc_id(id,message)
			
		
		
@rpc("authority", "unreliable_ordered", "call_remote")
func user_login_confirm(message):
	pass
