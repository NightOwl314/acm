<h1>$CONTEST_NAME (ID=$CONTEST_ID)</h1>
<a href="cnt_manage.pl?action=close_cont&cont_id=$CONTEST_ID">Close contest (move it to archive)</a><br><br>
<form action="cnt_manage.pl" method="GET">
<input type="hidden" name="action" value="update">
<input type="hidden" name="cont_id" value="$CONTEST_ID">
<table>
$CONTEST_TITLES
<tr><td>Start:</td>
  <td><input type="text" name="start" value="$CONTEST_START"></td></tr>
<tr><td>Stop:</td> 
  <td><input type="text" name="stop" value="$CONTEST_STOP"></td></tr>
<tr><td>Duration:</td> 
  <td><input type="text" name="duration" value="$CONTEST_DURATION"></td></tr>
<tr><td>Freeze time:</td>
  <td><input type="text" name="freeze_time" value="$CONTEST_FREEZE"></td></tr>
<tr><td>Self registration:</td>
  <td><input type="checkbox" name="selfreg" $CONTEST_SELFREG></td></tr>
<tr><td>Team:</td>
  <td><input type="checkbox" name="isteam" $CONTEST_ISTEAM></td></tr>
<tr><td>Virtual:</td>
  <td><input type="checkbox" name="isvirtual" $CONTEST_ISVIRTUAL></td></tr>
<tr><td>Type:</td> 
  <td>
  $CONTEST_TYPES
  </td>
</tr>
<tr>
<td>Theme ID:</td>
<td><input type="text" name="theme" value="$CONTEST_THEME"></td>
</tr>
</table>
<input type="submit" value="Update params">
</form>

<hr>  

<h2>Registered problems</h2>
<form action="cnt_manage.pl" method="GET">
<input type="hidden" name="action" value="update_problems">
<input type="hidden" name="cont_id" value="$CONTEST_ID">

<table border="1">
  <th>Delete?</th> <th>ID</th> <th>Number</th> <th>Title</th> 
  <th>Time limit</th> <th>Memory limit</th>
  $REG_PROBLEMS
</table>
<br>
<input type="submit" value="Update problems">
</form>

<hr>

<h2>Not registered problems</h2>    
<form action="cnt_manage.pl" method="GET">
<input type="hidden" name="action" value="add_problems">
<input type="hidden" name="cont_id" value="$CONTEST_ID">

<table border="1">
  <th>Add?</th> <th>ID</th> <th>Title</th> 
  <th>Time limit</th> <th>Memory limit</th>
  $NREG_PROBLEMS
</table>
<br>
<input type="submit" value="Add selected to contest">
</form>

<hr>

<h2>Compilers</h2>    
<form action="cnt_manage.pl" method="GET">
<input type="hidden" name="action" value="change_comp">
<input type="hidden" name="cont_id" value="$CONTEST_ID">

<table border="1">
  <th>Registered?</th> <th>ID</th> <th>Title</th> 
  $COMPILERS
</table>
<br>
<input type="submit" value="Update compilers">
</form>

