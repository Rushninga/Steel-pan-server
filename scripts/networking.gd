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


@rpc("any_peer", "reliable")
func send_user_info(username_received, email_received, password_received, mode_received):
	if multiplayer.is_server():
		var id = multiplayer.get_remote_sender_id()
		if mode_received == "sign in":
			bindings = [username_received, email_received]
			query = "SELECT username, email FROM user_info WHERE username = ? OR email = ?"
			db.query_with_bindings(query, bindings)
			var results = db.query_result
			var message #0 = email is valid, 1 = email is already being used
			if results.size() == 0:
				for i in user_info: #removes user id if theres a duplicate one in user info
					if i.id == id :
						user_info.erase(i)
				valid_email.rpc_id(id, 0)
				var new_user = user_class.new(id,username_received,email_received,password_received)
				new_user.user_mode = 3
				var email_code = randi_range(1000, 9999)
				new_user.email_code = email_code
				user_info.append(new_user)
				$Node2D.send_email(email_received, username_received, email_code)
			else:
				valid_email.rpc_id(id,1)
		elif mode_received == "login":
			bindings = [username_received, password_received]
			query = "SELECT username,password FROM user_info WHERE username = ? AND password = ?;"
			db.query_with_bindings(query, bindings)
			var results = db.query_result
			var message
			
			if results.is_empty(): #sends a login confirmation to client, 1 == username or password is incorrect, 1 is login was sucessful and 3 is unknown error 
				message = 1
				
			elif results.size() == 1:
				for i in user_info: #removes user id if theres a duplicate one in user info
					if i.id == id :
						user_info.erase(i)
				
				message = 2
				var new_user = user_class.new(id,username_received,null,null)
				new_user.email_code = 0 #this property should remain at 0 and  is only filled if the user is registering
				new_user.user_mode = 1 # this indicates the user is loged in
				user_info.append(new_user)
				
				
			else:
				message = 3 #indicates there is duplicate user infomation thus something is wrong with the database
			user_login_confirm.rpc_id(id,message)
			
		
		
@rpc("authority", "unreliable_ordered")
func user_login_confirm(message):
	pass

#email verification
#confirmation that username or email isn't already being used
@rpc("authority", "reliable")
func valid_email(message):
	pass
	
#verify email 
@rpc("any_peer", "reliable")
func sumbit_email_code(code):
	var id = multiplayer.get_remote_sender_id()
	for i in user_info:
		if i.id == id:
			if str(i.email_code) == code:
				bindings = [i.username, i.email, i.password]
				query = "INSERT INTO user_info (username, email, password)
						VALUES (? , ? , ?)
						"
				db.query_with_bindings(query, bindings)
				valid_email_code.rpc(0) # 0 = code is correct, 1 = code is wrong
				user_info.erase(i)
	
@rpc("authority", "reliable")
func valid_email_code(message):
	pass
