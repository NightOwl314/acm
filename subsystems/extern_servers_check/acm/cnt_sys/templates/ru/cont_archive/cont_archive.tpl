<center><h1>Contests archive</h1></center>
<center>
<a href="cnt_common.pl?action=active_contests">Active contests</a><br><br>

<table class="tbbd2">

<tr><td>
<form action="cnt_common.pl" method="GET">
<input type="hidden" name="action" value="cont_arch">
Filter: <input type="text" name="cont_flt" value="$FILTER">
<input type="submit" value="OK">
</form>
</td></tr>

<tr><td>
<table border="0" class="tbbd2">
<tr>
<th></th> <th>Title</th> <th>Type</th> <th>Start</th> <th>Stop</th> <th>Duration</th>
</tr>
$CONTESTS
</table>
</td></tr>

</table>

</center>

