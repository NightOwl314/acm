<center>
<h1>������ �������� ���������</h1>
<table class="tbbd" border="1">
<tr><td>
<table width="100%"><tr><td>
<h1>$USER_NAME</h1>
$TEAM_STAFF
</td></tr></table>
</td></tr>

<tr><td>
<table width="100%"><tr><td>
<strong>������:</strong> $CONT_TITLE<br>
<strong>����� ������:</strong> $CONT_START<br>
<strong>����� ���������:</strong> $CONT_STOP<br>
<strong>������������:</strong> $CONT_DUR<br>
<strong>���������:</strong> $CONT_FREEZE<br>
<a href="cnt_common.pl?action=stand&cont_id=$CONT_ID" target="_blank">������� �����������</a>
</td></tr></table>
</td></tr>

<tr><td>
<table width="100%"><tr><td>
<h2>������ �����</h2>
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
<h2>������� �� ��������</h2>
</td></tr>
<tr>
  <td width="25">������:</td>
  <td>
    <select name="problem_id" cols="20" $DISABLED>
    $PROBLEMS_COMBO
    </select>
  </td>
</tr>
<tr>
  <td>����������:</td>
  <td>
    <select name="compiler_id" cols="20" $DISABLED>
    $COMPILERS
    </select>
  </td>
</tr>
<tr><td colspan="2">
�������:<br>
<textarea name="source" cols="80" rows="25" $DISABLED></textarea><br>
</td></tr>
<tr><td colspan="2">
��������� ����:<br>
<input type="FILE" name="sourcefile" size=60 $DISABLED><br>
</td></tr>
<tr><td colspan="2">
<input type="submit" value="��������� �������" $DISABLED>
</td></tr>
</td></tr>
</table>
</form>
</td></tr>

<tr><td>
<table width="100%"><tr><td>
<a name="status"><h2>���������� ��������</h2></a>
</td></tr><tr><td>
<table width="100%" border="1" class="tbbd2">
<tr>
  <th>Time</th><th>����� �� ������</th><th>������</th><th>����������</th>
  <th>���������</th><th>� �����</th><th>�����</th><th>������</th>
</tr>
$STATUS_TABLE
</table>
</td></tr></table>
</td></tr>
</table>
</center>
