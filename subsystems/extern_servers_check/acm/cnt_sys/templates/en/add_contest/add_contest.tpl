<h1>New Contest</h1>

<form action="cnt_manage.pl" method="GET">

<input type="hidden" name="action" value="insert">
<input type="hidden" name="cont_id" value="$CONTEST_ID">

<table>
$CONTEST_TITLES
<tr><td>Start:</td>
  <td><input type="text" name="start"></td></tr>
<tr><td>Stop:</td> 
  <td><input type="text" name="stop"></td></tr>
<tr><td>Duration:</td> 
  <td><input type="text" name="duration"></td></tr>
<tr><td>Freeze time:</td>
  <td><input type="text" name="freeze_time"></td></tr>
<tr><td>Self registration:</td>
  <td><input type="checkbox" name="selfreg" checked></td></tr>
<tr><td>Team:</td>
  <td><input type="checkbox" name="isteam"></td></tr>
<tr><td>Virtual:</td>
  <td><input type="checkbox" name="isvirtual"></td></tr>
<tr><td>Type:</td> 
  <td>
  $CONTEST_TYPES
  </td>
</tr>
<tr>
<td>Theme ID:</td>
<td><input type="text" name="theme"></td>
</tr>
</table>
<input type="reset" value="Reset">
<input type="submit" value="OK">
</form>
