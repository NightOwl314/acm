<h1>Submition report</h1>
<form action="cnt_master.pl" method="GET">
<input type="hidden" name="action" value="change_res">
<input type="hidden" name="stat_id" value="$STAT_ID">
<strong>ID:</strong> $STAT_ID ($STAT_ID_HEX)<br>
<strong>Time:</strong> $TIME<br>
<strong>Author:</strong> $AUTHOR<br>
<strong>Problem:</strong> $PROB_NUM - $PROB_NAME<br>
<strong>Compiler:</strong> $COMPILER<br>
<strong>Work time:</strong> $WORK_TIME sec.<br>
<strong>Memory use:</strong> $MEM_USE KB<br>
<strong>Test No.:</strong> $TEST<br>
<strong>Result:</strong> 
<select name="res_id">
$RESULTS
</select>
<input type="submit" value="Set"> 
<br>
</form> 

<hr>

<h2>Server report</h2>
$SERVER_REPORT

<hr>

<h2>Other Reports</h2>
$REPORTS

<hr>

<h2>Source</h2>
<code><pre>
$SOURCE
</pre></code>

