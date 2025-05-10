<h2>Steelpan Simulator</h2>
<p>Steelpan simulator is a desktop application designed to assist its users in learning songs for the steelpan, a musical instrument that originates from the Caribbean. With the help of this initiative, musicians, educators and students can make progress on learning steelpan songs by memorizing the placement and timing of the notes without the real instrument. Users will be able to play premade songs or songs that they recorded. These composed songs can then be shared to the server where others can access it. The software will provide a way for users to tell when they are supposed to play notes using circles that zoom in on the notes that are supposed to be played. </p>
<br>

<p>This repository is for the server side application. <a href="https://github.com/Rushninga/Steelpan-Simulator">Click here to go to the client side repository</a></p>
<br>

<h2>How to build</h2>
<ol>
   <li>Install Godot Engine: https://godotengine.org/download/</li>
   <li>Clone the GitHub Repository: <code>git clone https://github.com/Rushninga/Steelpan-Simulator</code></li>
   <li>Open the Project in Godot:</li>
      <ul>
         <li>Launch the Godot Engine</li>
         <li>In the Project Manager window, click the "Import" button </li>
         <li>Click the "Browse" button</li>
         <li>Navigate to the folder you just cloned from GitHub.</li>
         <li>Select the project.godot file</li>
         <li>Click the "Import & Edit" button</li>
      </ul>
   <li>Open the Export Window</li>
   <li>Select Windows export preset</li>
   <li>Click the "Export Project" button</li>
   <li>Navigate to folder you want to export the project to </li>
   <li>Click save</li>
</ol>

<h2>BREVO API</h2>
<p>The server requires a Brevo API key to send emails. <a href="https://developers.brevo.com/">Get an API from their website.</a>
<br>To utilize API key, place it into an enviormental variable with the name <code>email_api</code>
</p>


<br><br>
<p>Note: .tscn files are used to create UI but also stored variables. .gd files are used to define the functionality of .tscn files. The associated .gd file will usually be linked within the .tcsn file therefore I will not list such files in the following table</p>
<br>
<p>List of files and their purpose:</p><br>
<table>
  <tr>
    <td>Main.db</td>
    <td>This is the SQLite database file. It is used to store user, song and score information</td>
  </tr>
  <tr>
    <td>rcedit-x64.exe</td>
    <td>This is a command line tool. Its main purpose is to edit the resource information embedded within the final .exe executable file.</td>
  </tr>
  <tr>
    <td>Server_screen.tscn</td>
    <td>Contains all UI for the server. Handles contection between server and client. Handles session management</td>
  </tr>
  <tr>
    <td>Main.tscn</td>
    <td>Handles communication between the server and client as well as general data processing</td>
  </tr>
  <tr>
    <td>db_key.key</td>
    <td>Public and private key for database password encryption. (Recomended to generate a new key before exporting: https://cryptotools.net/rsagen <br> All exsisting users in the database must be deleted if this is done.)</td>
  </tr>
  <tr>
    <td>godot-sqlite</td>
    <td>This is a folder containing all neccassary files for the Godot SQLite extention. Allows the server to utilize an embedded SQLite database</td>
  </tr>
</table>
