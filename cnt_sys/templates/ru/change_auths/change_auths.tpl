<h2>Add new author</h2>
<form action="cnt_manage.pl" method="GET">
<input type="hidden" name="action" value="add_auth">

<table>
<tr><td><strong>Author name:</strong></td><td><input type="text" name="au_name"></td></tr>
<tr><td><strong>Author login:</strong></td><td><input type="text" name="au_login"></td></tr>
<tr><td><strong>Author password:</strong></td><td><input type="text" name="au_psw"></td></tr>
</table><br>

<input type="submit" value="Add author">
</form>

<hr>

<h2>Authors list</h2>
<!-- <a href="cnt_manage.pl?action=sync_auth">Add authors from ArhPrb DB</a> -->
<form action="cnt_manage.pl" method="GET">
<input type="hidden" name="action" value="del_auths">
<table border="1">
  <tr> 
    <th>&nbsp</th> <th>ID</th> <th>Name</th> <th>Login</th> <th>Member of</th>
  </tr>
  $AUTHORS
</table><br>
<input type="submit" value="Delete selected">
</form>    

<hr>
<a href="cnt_manage.pl">Back to main admin page</a>

