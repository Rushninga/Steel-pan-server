extends Control
var server = ENetMultiplayerPeer.new()
var host_address 
var default_port = 8000
var port
var db = SQLite.new()
var db_is_open = false
@onready var main_display = $HBoxContainer/VBoxContainer/Label
@onready var db_query = $HBoxContainer/VBoxContainer2/SQL_Query
@onready var print_result = $HBoxContainer/VBoxContainer2/Label
var mail_pass


var query
var connected_user_info = {
	"username" : [],
	"id" : []
	
}
signal login_confirm

func SendEmail(emailto, emailfrom, subject, body):

	var command_body = [
		"$EmailFrom = '%s'" %[emailfrom],
		"$EmailTo = '%s'" %[emailto],
		"$Subject = '%s'"%[subject],
		"$Body = '%s'" %[body],
		"$SMTPServer = 'smtp.gmail.com'",
		"$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)",
		"$SMTPClient.EnableSsl = $true",
		"$SMTPClient.Credentials = New-Object System.Net.NetworkCredential('%s', '%s');"%["steelpanprojectsalcc@gmail.com", mail_pass],
		"$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)",
	]

	var commands = ""
	var count = 1
	for command in len(command_body):
		if count != len(command_body):
			commands += command_body[command] + "; "
		else:
			commands += command_body[command]
		
		count += 1

	var output = []
	OS.execute("C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe", [commands], output)


func _ready():
	mail_pass = OS.get_environment("sever_gmail_password")
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	db.path = "res://Main.db"
	
	SendEmail("shernanjankie3@gmail.com", "steelpanprojectsalcc@gmail.com", "hellow world", "Welcome to my game" )


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
	pass # Replace with function body.


func _on_clear_pressed():
	$HBoxContainer/VBoxContainer/Label.text = ""
	pass # Replace with function body.


func _on_print_loged_in_users_pressed():
	var json_connected_user_info = JSON.stringify(connected_user_info)
	main_display.text += json_connected_user_info + "\n"
	pass 
