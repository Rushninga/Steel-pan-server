#This is for the user class in connected_user_info
#user modes for session mangement:
# 0 = not loged in/registering   #1 = user is loged in     2 = user is registering    

extends Node
@onready var user_info = $Node2D.connected_user_info
@onready var user_class = $Node2D.user
@onready var db = $Node2D.db


#cryptograpy
var crypto = Crypto.new()
var net_key = crypto.generate_rsa(1028)
var data = "Some data"
var db_key = CryptoKey.new()


func delete_session(id):
	for i in user_info: 
		if i.id == id :
			user_info.erase(i)

func find_userID_in_db(username):
	var bindings = []
	var query
	var results
	
	bindings = [username]
	query = "SELECT userID FROM user_info
				WHERE username = ?"
	db.query_with_bindings(query, bindings)
	results = db.query_result_by_reference
	return results[0].userID
	
func find_user_email(username):
	var bindings = []
	var query
	var results
	
	bindings = [username]
	query = "SELECT email FROM user_info
				WHERE username = ?"
	db.query_with_bindings(query, bindings)
	results = db.query_result_by_reference
	return results[0].email

func _ready():
	db_key.load("res://keys/db_key.key")
	
func _process(delta):
	$Node2D.manage_sessions(delta)

@rpc("any_peer", "reliable")
func send_user_info(username_received, email_received, password_received, mode_received):
	if multiplayer.is_server():
		var id = multiplayer.get_remote_sender_id()
		if mode_received == "sign in":
			var bindings = [username_received, email_received]
			var query = "SELECT username, email FROM user_info WHERE username = ? OR email = ?"
			db.query_with_bindings(query, bindings)
			var results = db.query_result_by_reference
			var message #0 = email is valid, 1 = email is already being used
			if results.size() == 0:
				delete_session(id) #removes user id if theres a duplicate one in user info	
				valid_email.rpc_id(id, 0)
				var new_user = user_class.new(id,username_received,email_received,password_received)
				new_user.user_mode = 2
				var email_code = randi_range(1000, 9999)
				new_user.email_code = email_code
				user_info.append(new_user)
				$Node2D.send_email(email_received, username_received, email_code)
			else:
				valid_email.rpc_id(id,1)
			

		elif mode_received == "login":
			var bindings = [username_received]
			var query = "SELECT username,password,email FROM user_info WHERE username = ?;"
			db.query_with_bindings(query, bindings)
			var results = db.query_result_by_reference
			var message
			var r_email = ""
			if results.is_empty(): #sends a login confirmation to client, 1 == username or password is incorrect, 1 is login was sucessful and 3 is unknown error 
				message = 1
				
			elif results.size() == 1:
				var password = results[0].password #assigns base64 password string
				var raw_cipherpassword:PackedByteArray = Marshalls.base64_to_raw(password) #converts base64 to bytearray
				var plainpassword:PackedByteArray = crypto.decrypt(db_key,raw_cipherpassword) #decypts bytearray
				var utf8_plainpassword:String = plainpassword.get_string_from_utf8()


				if password_received == utf8_plainpassword:
					delete_session(id)
					message = 2
					var new_user = user_class.new(id,username_received,null,null)
					new_user.email_code = 0 #this property should remain at 0 and  is only filled if the user is registering
					new_user.user_mode = 1 # this indicates the user is loged in
					user_info.append(new_user)
					r_email = results[0].email
				else:
					message = 1
				
			else:
				message = 3 #indicates there is duplicate user infomation thus something is wrong with the database
			
			user_login_confirm.rpc_id(id,message,r_email)
			
@rpc("authority", "unreliable_ordered")
func user_login_confirm(message, email = ""):
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
				var password = str(i.password) 
				var cipherpassword = crypto.encrypt(db_key,password.to_utf8_buffer())
				var base64_cipherpassword = Marshalls.raw_to_base64(cipherpassword)
				
				var bindings = [i.username, i.email, base64_cipherpassword]
				var query = "INSERT INTO user_info (username, email, password)
						VALUES (? , ? , ?)"
				db.query_with_bindings(query, bindings)
				valid_email_code.rpc_id(id, 0) # 0 = code is correct, 1 = code is wrong
				user_info.erase(i)
			else:
				valid_email_code.rpc_id(id, 1)
			
@rpc("authority", "reliable")
func valid_email_code(message):
	pass

@rpc("any_peer", "reliable")
func verify_session(): #0 = session is invalid, 1 = session is valid
	var id = multiplayer.get_remote_sender_id()
	for i in user_info:
		if i.id == id:
			verify_session_response.rpc_id(id, 1) #1 = session is valid
			return
	verify_session_response.rpc_id(id,0) #0 = session is invalid
			
@rpc("authority", "reliable")
func verify_session_response(message): #0 = session is invalid, 1 = session is valid
	pass
	
@rpc("any_peer", "reliable")
func log_out():
	var id = multiplayer.get_remote_sender_id()
	delete_session(id)
	
@rpc("any_peer", "reliable")
func request_download_song():
	var id = multiplayer.get_remote_sender_id()
	
	if $Node2D.verify_session(id) == true:
		$Node2D.refresh_session(id, 1200)
		var download_session = $Node2D.create_download_songs_session(id)
		var query = 	"SELECT t2.songID, t2.song_name, t2.userID, t2.data, t1.username
						FROM song_info t2
						JOIN user_info t1 ON t2.userID = t1.userID;"
		db.query(query)
		var results = db.query_result_by_reference
		for i in results:
			if $Node2D.verify_download_songs_session(id, download_session) == true:
				download_song.rpc_id(id, i.songID, i.song_name, i.username, i.data)
			else:
				$Node2D.delete_download_songs_session(id)
				return
		$Node2D.delete_download_songs_session(id)
	
@rpc("authority", "reliable")
func download_song(song_id, song_name, creator_name, song_data):
	pass
	
@rpc("any_peer", "reliable")
func cancel_download_song():
	var id = multiplayer.get_remote_sender_id()
	$Node2D.delete_download_songs_session(id)
	pass
	
@rpc("any_peer", "reliable")
func request_rankings(song_id, score, accuracy):
	var id = multiplayer.get_remote_sender_id()
	if $Node2D.verify_session(id) == true:
		$Node2D.refresh_session(id,1200) #refreshes the user session time
		
		var hscore:int
		var haccuracy:float
		var rank:int = 0
		var bindings:Array
		var query:String
		var results:Array
		var DBuserID:int #This is what the user id is in the databse
		
		#get username
		var username
		for i in user_info:
			if i.id == id:
				username = i.username
				break
		
		#get userID in database
		bindings = [username]
		query = "SELECT userID FROM user_info
					WHERE username = ?"
		db.query_with_bindings(query, bindings)
		results = db.query_result_by_reference
		DBuserID = results[0].userID
		
		#insert score and accuracy received by user into databse
		bindings = [song_id, DBuserID, score, accuracy]
		query = "INSERT INTO score_info (songID, userID, score, accuracy)
					VALUES (?, ?, ?, ?)"
		db.query_with_bindings(query, bindings)
		
		#get highest score
		bindings = [song_id, DBuserID]
		query = "SELECT max(score_info.score)
					FROM score_info 
					JOIN song_info ON song_info.songID = score_info.songID
					JOIN user_info ON user_info.userID = score_info.userID
					WHERE song_info.songID = ? AND user_info.userID = ?"
		db.query_with_bindings(query, bindings)
		results = db.query_result_by_reference
		hscore = results[0]["max(score_info.score)"]
		
		#get highest accuracy
		bindings = [song_id, DBuserID]
		query = "SELECT max(score_info.accuracy)
					FROM score_info 
					JOIN song_info ON song_info.songID = score_info.songID
					JOIN user_info ON user_info.userID = score_info.userID
					WHERE song_info.songID = ? AND user_info.userID = ?"
		db.query_with_bindings(query, bindings)
		results = db.query_result_by_reference
		haccuracy = results[0]["max(score_info.accuracy)"]
		
		
		#get rank, this is based on soley accuracy
		bindings = [song_id]
		query = "SELECT score_info.accuracy FROM score_info
					JOIN song_info ON song_info.songID = score_info.songID
					WHERE song_info.songID = ?
					ORDER BY accuracy ASC"
		db.query_with_bindings(query, bindings)
		results = db.query_result_by_reference
		rank = results.size()
		for i in results:
			if accuracy > i.accuracy:
				rank -= 1
			else:
				break
		
		rankings.rpc_id(id,hscore,haccuracy, rank)

@rpc("authority", "reliable")
func rankings(score, accuracy, rank):
	pass

@rpc("any_peer", "reliable")
func upload_song(song_name, song_json):
	var id = multiplayer.get_remote_sender_id()
	var username
	var bindings:Array
	var query:String
	var results:Array
	var DBuserID #This is what the user id is in the databse
	
	if $Node2D.verify_session(id) == true:
		$Node2D.refresh_session(id,1200) #refreshes the user session time
		
		#get username
		for i in user_info:
			if i.id == id:
				username = i.username
				break
		DBuserID = find_userID_in_db(username)
		
		bindings = [song_name]
		query = "SELECT song_name FROM song_info WHERE song_name = ?"
		db.query_with_bindings(query, bindings)
		results = db.query_result_by_reference
		
		if results.size() == 0:
			bindings = [song_name, song_json, DBuserID]
			query = "INSERT INTO song_info(song_name, data, userID)
					VALUES (?, ?, ?)"
			db.query_with_bindings(query, bindings)
			valid_song_name.rpc_id(id, 0)
		else:
			valid_song_name.rpc_id(id, 1)
	
@rpc("authority", "reliable")
func valid_song_name(message):
	pass
	
@rpc("any_peer", "reliable")
func change_password():
	var id = multiplayer.get_remote_sender_id()
	if $Node2D.verify_session(id) == true:
		for i in user_info:
			if i.id == id:
				var email = find_user_email(i.username)
				i.cpassword_code = randi_range(1000, 9999)
				$Node2D.send_email_password_change(email, i.username, i.cpassword_code)
	

@rpc("any_peer", "reliable")
func cpassword_code(code): # 0 = code is valid, 1 = code is invalid
	var id = multiplayer.get_remote_sender_id()
	if $Node2D.verify_session(id) == true:
		for i in user_info:
			if i.id == id:
				if str(i.cpassword_code) == code:
					$Node2D.refresh_session(id,1200) #refreshes the user session time
					i.cpassword_code = 1
					cpassword_code_response.rpc_id(id, 0) #code is valid
				else:
					cpassword_code_response.rpc_id(id, 1) #code is invalid

@rpc("authority", "reliable")
func cpassword_code_response(message): # 0 = code is valid, 1 = code is invalid
	pass

@rpc("any_peer", "reliable")
func change_password_to(password):
	var id = multiplayer.get_remote_sender_id()
	
	if $Node2D.verify_session(id) == true:
		for i in user_info:
			if i.id == id:
				if i.cpassword_code == 1:
					var cipherpassword = crypto.encrypt(db_key,password.to_utf8_buffer())
					var base64_cipherpassword = Marshalls.raw_to_base64(cipherpassword)
					
					var userDB_id = find_userID_in_db(i.username)
					print(userDB_id)
					var bindings = [base64_cipherpassword, userDB_id]
					var query = "UPDATE user_info
								 SET password = ?
								 WHERE userID = ?"
					db.query_with_bindings(query, bindings)
					change_password_to_response.rpc_id(id, 0)
				else:
					change_password_to_response.rpc_id(id, 1)

@rpc("authority", "reliable")
func change_password_to_response(message): # 1 = error occured
	pass

@rpc("any_peer", "reliable")
func forgot_password(username):
	var id = multiplayer.get_remote_sender_id()
	var bindings = [username]
	var query = "SELECT email, password FROM user_info WHERE username = ?"
	db.query_with_bindings(query, bindings)
	var results = db.query_result_by_reference

	if results.size() > 0:
		var email = results[0].email
		var password = results[0].password #assigns base64 password string
		var raw_cipherpassword:PackedByteArray = Marshalls.base64_to_raw(password) #converts base64 to bytearray
		var plainpassword:PackedByteArray = crypto.decrypt(db_key,raw_cipherpassword) #decypts bytearray
		var utf8_plainpassword:String = plainpassword.get_string_from_utf8()
		
		$Node2D.send_email_forgot_password(email, username, utf8_plainpassword)
		forgot_password_response.rpc_id(id, 0) #0 = account exsists, 1 = account doesn't exsist
	else:
		forgot_password_response.rpc_id(id, 1) #0 = account exsists, 1 = account doesn't exsist
		
@rpc("authority", "reliable")
func forgot_password_response(message):  #0 = account exsists, 1 = account doesn't exsist
	pass
