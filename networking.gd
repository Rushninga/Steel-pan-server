#This is for the user class in connected_user_info
#user modes for session mangement:
# 0 = not loged in/registering   
#1 = user is loged in     2 = user is registered    3 = user is registering

extends Node
@onready var user_info = $Node2D.connected_user_info
@onready var user_class = $Node2D.user
@onready var db = $Node2D.db

var query:String
var bindings:Array 



func _ready():
	pass


@rpc("any_peer", "reliable", "call_local")
func send_user_info(username_received, email_received, password_received, mode_received):
	if multiplayer.is_server():
		var id = multiplayer.get_remote_sender_id()
		if mode_received == "sign in":
			bindings = [email_received]
			query = "SELECT email FROM user_info WHERE email = ?"
			db.query_with_bindings(query, bindings)
			var results = db.query_result
			var message #0 = email is valid, 1 = email is already being used
			if results.size() == 0:
				for i in user_info: #removes user id if theres a duplicate one in user info
					if i.id == id :
						user_info.remove(i)
				valid_email.rpc_id(id, 0)
				var new_user = user_class.new(id,username_received,email_received)
				new_user.user_mode = 3
				var email_code = randi_range(1000, 9999)
				new_user.email_code = email_code
				user_info.append(new_user)
				$Node2D.send_email(email_received,username_received,email_code)
			else:
				valid_email.rpc_id(id,1)
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
				var new_user = user_class.new(id,username_received,email_received)
				new_user.email = null #make sure email is empty as this feild is only filled if the user is registering
				new_user.email_code = null #make sure email is empty as this feild is only filled if the user is registering
				new_user.user_mode = 1 # this indicates the user is loged in
				user_info.append(new_user)
			else:
				message = 3
			user_login_confirm.rpc_id(id,message)
			
		
		
@rpc("authority", "unreliable_ordered", "call_remote")
func user_login_confirm(message):
	pass

#email verification
#confirmation that email isn't already being used
@rpc("authority", "reliable", "call_remote")
func valid_email(message):
	pass
