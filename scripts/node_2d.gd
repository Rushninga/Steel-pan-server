extends Control
var server = ENetMultiplayerPeer.new()
var host_address 
var default_port = 8000
var port
var db = SQLite.new()
var db_is_open = false
var query







@onready var main_display = $HBoxContainer/VBoxContainer/Label
@onready var db_query = $HBoxContainer/VBoxContainer2/SQL_Query
@onready var print_result = $HBoxContainer/VBoxContainer2/Label
@export var http:HTTPRequest
var json
var api_key:String
var url = "https://api.brevo.com/v3/smtp/email"

var data= '{  
   "sender":{  
	  "name":"Sender Alex",
	  "email":"steelpanprojectsimulator@gmail.com"
   },
   "to":[  
	  {  
		 "email":"testmail@example.com",
		 "name":"John Doe"
	  }
   ],
   "subject":"Hello world",
   "htmlContent":"<html><head></head><body><p>Hello,</p>This is my first transactional email sent from Brevo.</p></body></html>"
}'

class user:
	var id:int
	var username
	var email
	var password
	var email_code:int
	var user_mode:int # 0 = not loged in/registering   #1 = user is loged in     2 = user is registering    
	var session_life:float = 1200
	var download_songs_session:float
	var cpassword_code:int #verification code to change password, this value equals 1 if the code is verified, if not it is put to 0 
	func _init(id_sent, username_sent, email_sent, password_sent):
		id = id_sent
		username = username_sent
		email = email_sent #this remains null unless the user is registering their account
		password = password_sent #this remains null unless the user is registering their account


var connected_user_info = [] #list of all connected users

func verify_session(id): #checks if user exsists and if user is logged in
	for i in connected_user_info:
		if i.id == id and i.user_mode == 1:
			return true
	return false

func _on_http_request_request_completed(result, response_code, headers, body):
	var response = body.get_string_from_utf8()
	$HBoxContainer/VBoxContainer/Label.text = str(response) + "\n"


func send_email(email,username,code):
	var body = '{  
   "sender":{  
	  "name":"Shernan Jankie",
	  "email":"steelpanprojectsimulator@gmail.com"
   },
   "to":[  
	  {  
		 "email":" ' +email+  ' ",
		 "name":" ' +username+  '   "
	  }
   ],
   "subject":"Steelpan Simulator Verification Code",
   "htmlContent":"<html><head></head><body><p>Welcome to Steelpan Simulator,</p>Here is your email verification code:' +str(code)+ '</p></body></html>"
}'
	http.request(url, ["api-key:" + api_key],HTTPClient.METHOD_POST,body)
	

func send_email_password_change(email,username,code):
	var body = '{  
   "sender":{  
	  "name":"Shernan Jankie",
	  "email":"steelpanprojectsimulator@gmail.com"
   },
   "to":[  
	  {  
		 "email":" ' +email+  ' ",
		 "name":" ' +username+  '   "
	  }
   ],
   "subject":"Steelpan Simulator Verification Code",
   "htmlContent":"<html><head></head><body><p>Good day '+ username + ',</p>We see you are trying to change your password <br>Here is your email verification code:' +str(code)+ '</p></body></html>"
}'
	http.request(url, ["api-key:" + api_key],HTTPClient.METHOD_POST,body)

func manage_sessions(d_time):
	for i in connected_user_info:
		i.session_life -= d_time
		if i.session_life < 0:
			connected_user_info.erase(i)
			return

func refresh_session(id, refresh_time):
	for i in connected_user_info:
		if i.id == id:
			i.session_life = refresh_time
			return

func create_download_songs_session(id):
	for i in connected_user_info:
		if i.id == id:
			i.download_songs_session = randi_range(10000, 99999)
			return i.download_songs_session
			
func verify_download_songs_session(id, session):
	for i in connected_user_info:
		if i.id == id:
			if session == i.download_songs_session:
				return true
			else:
				return false
			
func delete_download_songs_session(id):
	for i in connected_user_info:
		if i.id == id:
			i.download_songs_session = 0
			return


func _ready():
	api_key = OS.get_environment("email_api")
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	db.path = "res://Main.db"
	
	


func _on_button_pressed(): #starts server
	server.create_server(default_port)
	multiplayer.multiplayer_peer = server
	host_address = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	$HBoxContainer/VBoxContainer/Label.text += host_address + "\n"


func _on_player_connected(id):
	$HBoxContainer/VBoxContainer/Label.text += "Player " 
	$HBoxContainer/VBoxContainer/Label.text += str(id)
	$HBoxContainer/VBoxContainer/Label.text += " has connected\n"


func _on_player_disconnected(id):
	$HBoxContainer/VBoxContainer/Label.text += "Player " 
	$HBoxContainer/VBoxContainer/Label.text += str(id)
	$HBoxContainer/VBoxContainer/Label.text += " has disconnected\n"
	for i in connected_user_info:
		if i.id == id:
			connected_user_info.erase(i)
	

func _on_button_2_pressed(): #opens database
	db.open_db()
	db.foreign_keys = true
	db.query("SELECT 1")
	
	#Checks if database open successfully with sql query
	if db.error_message == "not an error":
		$HBoxContainer/VBoxContainer/Label.text += "Database opened successfully \n"
	else:
		$HBoxContainer/VBoxContainer/Label.text += "Database has failed to open \n"
	
	


func _on_print_pressed(): #process an sql query and prints the result
	query = $HBoxContainer/VBoxContainer2/SQL_Query.text
	db.query(query)
	$HBoxContainer/VBoxContainer2/Label.text = ""
	for i in db.query_result:
		$HBoxContainer/VBoxContainer2/Label.text += str(i)
		$HBoxContainer/VBoxContainer2/Label.text += "\n"
	


func _on_clear_pressed():
	$HBoxContainer/VBoxContainer/Label.text = host_address + "\n"
	
	
	


func _on_print_loged_in_users_pressed():
	for i in connected_user_info:
		main_display.text += "{" + "\n" + str(i.id) + "\n" + str(i.username) + "\n" + str(i.user_mode) + "\n" + str(i.session_life) + "\n" + str(i.download_songs_session) + "\n" +"}" + "\n"
	 
