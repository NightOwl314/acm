<h1>$CONT_NAME</h1>
<a href="#regprob">Registered problems</a><br>
<a href="#regauth">Registered authors/teams</a><br>
<a href="#notregauth">Not registered authors/teams</a><br>
<a href="#status">Online status</a><br>
<br>
<strong>Start:</strong> $CONT_START<br>
<strong>Stop:</strong> $CONT_STOP<br>
<strong>Duration:</strong> $CONT_DUR<br>
<strong>Freeze:</strong> $CONT_FREEZE<br>

<hr>
<a name="regprob"><h2>Registered problems</h2></a>
<table border="1">
  <th>Action</th> <th>ID</th> <th>Number</th> <th>Title</th>
  <th>Time limit</th> <th>Memory limit</th>    
  $PROBLEMS_LIST
</table>

<hr>

<a name="regauth"><h2>Registered authors/teams</h2></a>
<form action="cnt_master.pl" method="GET">
<input type="hidden" name="action" value="update_authors">
<input type="hidden" name="cont_id" value="$CONT_ID">

<table border="1">
  <th>Unreg?</th> <th>ID</th> <th>Name</th> <th>Login</th> <th>Reg time</th> 
  $REG_AUTHORS
</table>
<br>
<input type="submit" value="Unregister selected">
</form>

<hr>

<a name="notregauth"><h2>Not registered authors/teams</h2></a>    
<form action="cnt_master.pl" method="GET">
<input type="hidden" name="action" value="judge">
<input type="hidden" name="cont_id" value="$CONT_ID">
Filter: <input type="text" name="auth_flt" value="$FILTER">
<input type="submit" value="OK">
</form>
<br>
<form action="cnt_master.pl" method="GET">
<input type="hidden" name="action" value="add_authors">
<input type="hidden" name="cont_id" value="$CONT_ID">

<table border="1">
  <th>Reg?</th> <th>ID</th> <th>Name</th> <th>Login</th> 
  $ALL_AUTHORS
</table>
<br>
<input type="submit" value="Register selected">
</form>

<hr>

<a name="status"><h2>Online status</h2></a>
<form action="cnt_master.pl#status" method="GET">
<input type="hidden" name="action" value="judge">
<input type="hidden" name="cont_id" value="$CONT_ID">
Show only from: 
<select name="auth_id">
$AUTHORS_COMBO
</select>
<input type="submit" value="OK"><br>
<a href="cnt_master.pl?action=judge&cont_id=$CONT_ID#status">Show all</a>
</form>
<table border="1">
<tr>
  <th>Action</th><th>ID</th><th>Time</th><th>Time from begin</th><th>Author</th>
  <th>Problem</th><th>Compiler</th><th>Result</th><th>Test</th>
  <th>Work time</th><th>Memory usage</th>
</tr>
$STATUS_TABLE
</table>

