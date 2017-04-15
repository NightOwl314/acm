<h2>Add new team</h2>
<form action="cnt_manage.pl" method="GET">
<input type="hidden" name="action" value="add_team">

<table>
<tr><td><strong>Team name:</strong></td><td><input type="text" name="tm_name"></td></tr>
<tr><td><strong>Team login:</strong></td><td><input type="text" name="tm_login"></td></tr>
<tr><td><strong>Team password:</strong></td><td><input type="text" name="tm_psw"></td></tr>
</table><br>

<input type="submit" value="Add team">
</form>

<hr>

<h2>Teams list</h2>

<form action="cnt_manage.pl" method="GET">
<input type="hidden" name="action" value="update_teams">

<table border="1">
  <tr> 
    <th>&nbsp</th> <th>Action</th> <th>ID</th> <th>Name</th> <th>Login</th> 
	<th>Staff</th>
  </tr>
  $TEAMS
</table>
<br>

<h2>Authors list</h2>
<table border="1">
  <tr> 
    <th>&nbsp</th> <th>ID</th> <th>Name</th> <th>Login</th> <th>Member of</th>
  </tr>
  $AUTHORS
</table><br>
<input type="submit" value="Add selected authors to selected team">
</form>    

<hr>
<a href="cnt_manage.pl">Back to main admin page</a>

