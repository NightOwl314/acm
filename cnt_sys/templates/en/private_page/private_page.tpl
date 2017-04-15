<center>
<h1>Private page</h1>
<table class="tbbd" border="1">
<tr><td>
<table width="100%"><tr><td>
<h1>$USER_NAME</h1>
$TEAM_STAFF
</td></tr></table>
</td></tr>

<tr><td>
<table width="100%"><tr><td>
<strong>Contest:</strong> $CONT_TITLE<br>
<strong>Start:</strong> $CONT_START<br>
<strong>Stop:</strong> $CONT_STOP<br>
<strong>Duration:</strong> $CONT_DUR<br>
<strong>Freeze:</strong> $CONT_FREEZE<br>
<a href="cnt_common.pl?action=stand&cont_id=$CONT_ID" target="_blank">Standings</a>
</td></tr></table>
</td></tr>

<tr><td>
<table width="100%"><tr><td>
<h2>Problems list</h2>
$PROBLEMS_LIST
</td></tr></table>
</td></tr>


<tr><td>
<form action="cnt_submit.pl" method="POST" enctype="multipart/form-data">
<input type="hidden" name="contest_id" value="$CONT_ID">
<input type="hidden" name="is_team" value="$CONT_TEAM">
<input type="hidden" name="is_virtual" value="$CONT_VIRT">
<input type="hidden" name="author_id" value="$USER_ID">
<table width="100%">
<tr><td colspan="2">
<h2>Send submition</h2>
</td></tr>
<tr>
  <td width="25">Problem:</td>
  <td>
    <select name="problem_id" cols="20" $DISABLED>
    $PROBLEMS_COMBO
    </select>
  </td>
</tr>
<tr>
  <td>Compiler:</td>
  <td>
    <select name="compiler_id" cols="20" $DISABLED>
    $COMPILERS
    </select>
  </td>
</tr>
<tr><td colspan="2">
Solution:<br>
<textarea name="source" cols="80" rows="25" $DISABLED></textarea><br>
</td></tr>
<tr><td colspan="2">
Send file:<br>
<input type="FILE" name="sourcefile" size=60 $DISABLED><br>
</td></tr>
<tr><td colspan="2">
<input type="submit" value="Send" $DISABLED>
</td></tr>
</td></tr>
</table>
</form>
</td></tr>

<tr><td>
<table width="100%"><tr><td>
<a name="status"><h2>Online status</h2></a>
</td></tr><tr><td>
<table width="100%" border="1" class="tbbd2">
<tr>
  <th>Time</th><th>Time from begin</th><th>Problem</th><th>Compiler</th>
  <th>Result</th><th>Test</th><th>Work time</th><th>Memory usage</th>
</tr>
$STATUS_TABLE
</table>
</td></tr></table>
</td></tr>
</table>
</center>
