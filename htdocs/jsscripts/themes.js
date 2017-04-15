
function getTemaContent(element, id_tema) {
	var lng = document.getElementsByName("language")[0].value;
	var request = getRequest();
	request.open("POST","/cgi-bin/get_themes.pl",true);
	request.setRequestHeader("Content-type","application/x-www-form-urlencoded");
	
	request.onreadystatechange=function() {
		if (request.readyState==4 && request.status==200)
	    {
			var resp = request.responseText;
			
			var row = document.createElement("TR")
		    var td1 = document.createElement("TD")
		    td1.setAttribute("colspan","6");
		    td1.innerHTML = resp ;
		    row.appendChild(td1);
		    row.setAttribute("id","contentRow");
			table = element.parentNode.parentNode;
			table.appendChild(row);
			element.onclick = function() { removeTemaContent(this , id_tema) };
	    }
	}
	
	request.send("id_tema="+id_tema+"&id_lng="+ lng);
	
	
    
}

function removeTemaContent(element , id_tema) {
	var prnt = element.parentNode.parentNode;
	for(var i=0; i < prnt .childNodes.length; i++) {
		var elem = prnt .childNodes[i];
		if (elem.id == "contentRow")
			prnt .removeChild(elem);
	}
	element.onclick = function() { getTemaContent(this, id_tema) };
}


function getRequest() {
	var request;
	if (window.XMLHttpRequest)
	{// code for IE7+, Firefox, Chrome, Opera, Safari
		request=new XMLHttpRequest();
	}
	else
	{// code for IE6, IE5
		request=new ActiveXObject("Microsoft.XMLHTTP");
	}
	return request;
}

/**
 * Регулируем видимость специального комбобокса
 * @param elem
 */
function setSpecTemaVisible(elem) {
	combo = document.getElementById("spec_theme_select");
	if (elem.checked) {
		combo.style.display = "block";
	} else {
		combo.style.display = "none";
	}
}

/**
 * Проверки перед сабмитом задач
 * @param elem
 */
function onSubmitAssignProblems( elem) {
	 students = document.getElementsByName("student_check");
	 problems = document.getElementsByName("problems_check");
	 spec_check = document.getElementById("spec_tema");
	 contr_date = document.getElementById("datepicker");
	 error = "";
	if (students.length <= 0) {
		error += "Необходимо выбрать хотя бы одного студента\n";
	} else {
		checkedel = false;
		for (var i = 0; i< students.length; i++) {
			if (students[i].checked) {
				checkedel = true;
				break;
			}
		}
		if (!checkedel) {
			error += "Необходимо выбрать хотя бы одного студента\n";
		}
	}
	if (problems.length <= 0) {
		error += "Необходимо выбрать хотя бы одну задачу\n";
	} else {
		checkedel = false;
		for (var i = 0; i< problems.length; i++) {
			if (problems[i].checked) {
				checkedel = true;
				break;
			}
		}
		if (!checkedel) {
			error += "Необходимо выбрать хотя бы одну задачу\n";
		}
	}

	if (spec_check.checked) {
		combo = document.getElementById("spec_theme_select");
		if (combo.selectedIndex == -1 || combo.selectedIndex == 0) {
			error += "При выбраном флаге 'Назначить в тему' необходимо выбрать тему\n";
		}
	}
	if (contr_date.value.length <=0) {
		error += "Необходимо заполнить контрольную дату";
	} else if (!validate_date(contr_date.value)) {
		error += "Неккоректный формат даты в поле \"Контрольная дата\"";
	}
	if (error.length > 0) {
		alert(error);
		return false;
	} else {
		return true;
	}
	
}

function validate_date(value)
{
  var arrD = value.split(".");
  arrD[1] -= 1;
  var d = new Date(arrD[2], arrD[1], arrD[0]);
  if ((d.getFullYear() == arrD[2]) && (d.getMonth() == arrD[1]) && (d.getDate() == arrD[0])) {
    return true;
  } else {
    return false;
  }
}


/**
 * User for Group
 * @param element
 */
function getGroupUsers(element) {
	if ( element.selectedIndex != -1 && element.selectedIndex != 0)
	{
		var id_group = element.options[element.selectedIndex].value;
		var lng = 'ru';//document.getElementsByName("language")[0].value;
		
		var request = getRequest();
		request.open("POST", "/cgi-bin/assigned_problems_ajax.pl", true);
		request.setRequestHeader("Content-type",
				"application/x-www-form-urlencoded");

		request.onreadystatechange = function() {
			if (request.readyState == 4 && request.status == 200) {
				var resp = request.responseText;

				studentdiv = document.getElementById("students_list");
				for ( var i = 0; i < studentdiv.childNodes.length; i++) {
					var elem = studentdiv.childNodes[i];
					studentdiv.removeChild(elem);
				}
				studentdiv.innerHTML = resp;
				
			}
		}
		studentdiv = document.getElementById("students_list");
		studentdiv.appendChild(document.createTextNode("Ожидание ответа сервера..."));
		request.send("id_gpoup="+id_group + 
				"&id_lng=" + lng
				+ "&action=getUsersForGroup");
	}
}


function getTemaProblems(element) {
	if ( element.selectedIndex != -1 && element.selectedIndex != 0)
	{
		var id_tema = element.options[element.selectedIndex].value;
		var lng = 'ru';//document.getElementsByName("language")[0].value;
		
		var request = getRequest();
		request.open("POST", "/cgi-bin/assigned_problems_ajax.pl", true);
		request.setRequestHeader("Content-type",
				"application/x-www-form-urlencoded");

		request.onreadystatechange = function() {
			if (request.readyState == 4 && request.status == 200) {
				var resp = request.responseText;

				problemsdiv = document.getElementById("problems_list");
				for ( var i = 0; i < problemsdiv.childNodes.length; i++) {
					var elem = problemsdiv.childNodes[i];
					problemsdiv.removeChild(elem);
				}
				problemsdiv.innerHTML = resp;
			}
		}
		problemsdiv = document.getElementById("problems_list");
		problemsdiv.appendChild(document.createTextNode("Ожидание ответа сервера..."));
		request.send("id_tema="+id_tema 
					+ "&id_lng=" + lng
					+ "&action=getTemaProblems");
	}
}


/**
 * Get Users whom assigned prolems with current tema
 * and group user 
 * @param element element calling script
 * @param id_tema  study tema
 * @param id_group user group
 */
 function getUsersForTema(element , id_tema ,  id_group) {
	    element.onclick = null;
	 	var lng = document.getElementsByName("language")[0].value;
		var request = getRequest();
		request.open("POST","/cgi-bin/assigned_problems_ajax.pl",true);
		request.setRequestHeader("Content-type","application/x-www-form-urlencoded");
		
		request.onreadystatechange=function() {
			if (request.readyState==4 && request.status==200)
		    {
				var prnt = element.parentNode.parentNode;
				for(var i=0; i < prnt .childNodes.length; i++) {
					var elem = prnt .childNodes[i];
					if (elem.id == "contentRow")
						prnt .removeChild(elem);
				}
				var resp = request.responseText;
				var row = document.createElement("TR");
			    var td1 = document.createElement("TD");
			    td1.setAttribute("colspan","2");
			    td1.innerHTML = resp ;
			    row.appendChild(td1);
			    row.setAttribute("id","contentRow");
				table = element.parentNode.parentNode;
				table.appendChild(row);
				
		    }
			element.onclick = function() { removeTemaUserContent(this , id_tema , id_group) };
		}
		changeSing(element);
		element.setAttribute("rowspan", "2");
		var row = document.createElement("TR");
		row.setAttribute("id","contentRow");
		var td1 = document.createElement("TD");
		td1.setAttribute("colspan","2");
		var text = document.createTextNode("Ожидание ответа сервера...");
		td1.appendChild(text);
		row.appendChild(td1);
		table = element.parentNode.parentNode;
		table.appendChild(row);
		
		
		request.send("id_tema="+id_tema
						+ "&id_group=" + id_group
				 		+ "&id_lng="+ lng
				 		+ "&action=getUsersForTemaAndGroup");
		
		
	    
	}

/*
 * Delete content for group users
 */ 
 function removeTemaUserContent(element , id_tema , id_group) {
		var prnt = element.parentNode.parentNode;
		element.removeAttribute("rowspan");
		changeSing(element);
		for(var i=0; i < prnt .childNodes.length; i++) {
			var elem = prnt .childNodes[i];
			if (elem.id == "contentRow")
				prnt .removeChild(elem);
		}
		element.onclick = function() { getUsersForTema(this, id_tema, id_group) };
} 
 
 
 function getProblemsForUser(element , id_user, id_tema) {
	 element.onclick = null;
	 var lng = document.getElementsByName("language")[0].value;
		var request = getRequest();
		request.open("POST","/cgi-bin/assigned_problems_ajax.pl",true);
		request.setRequestHeader("Content-type","application/x-www-form-urlencoded");
		
		request.onreadystatechange=function() {
			if (request.readyState==4 && request.status==200)
		    {
				var prnt = element.parentNode.parentNode;
				for(var i=0; i < prnt .childNodes.length; i++) {
					var elem = prnt .childNodes[i];
					if (elem.id == "contentRow")
						prnt .removeChild(elem);
				}
				var resp = request.responseText;
				var row = document.createElement("TR");
			    var td1 = document.createElement("TD");
			    td1.setAttribute("colspan","2");
			    td1.innerHTML = resp ;
			    row.appendChild(td1);
			    row.setAttribute("id","contentRow");
				table = element.parentNode.parentNode;
				table.appendChild(row);
				
		    }
			element.onclick = function() { removeProblemsUserContent(this , id_user, id_tema) };
		}
		changeSing(element);
		var row = document.createElement("TR");
		row.setAttribute("id","contentRow");
		var td1 = document.createElement("TD");
		var text = document.createTextNode("Ожидание ответа сервера...");
		td1.appendChild(text);
		td1.setAttribute("colspan","2");
		row.appendChild(td1);
		element.setAttribute("rowspan", "2")
		table = element.parentNode.parentNode;
		table.appendChild(row);
		
		
		request.send("id_student=" + id_user
						+ "&id_tema=" + id_tema	
						+ "&id_lng="+ lng
						+ "&action=getProblemsForUser");
		
		
	    
	}

 function removeProblemsUserContent(element , id_user, id_tema) {
		var prnt = element.parentNode.parentNode;
		element.removeAttribute("rowspan");
		changeSing(element);
		for(var i=0; i < prnt .childNodes.length; i++) {
			var elem = prnt .childNodes[i];
			if (elem.id == "contentRow")
				prnt .removeChild(elem);
		}
		element.onclick = function() { getProblemsForUser(this, id_user , id_tema) };
}  
 
 
 /**
  * Return groups of student whom assigned problems by current system user
  * @param element current elemen
  * @param id_tema current thema in row
  */
 function getGroupsForThemes(element , id_tema) {
	 element.onclick = null;
	 var lng = document.getElementsByName("language")[0].value;
	 lng = 'ru';
		var request = getRequest();
		request.open("POST","/cgi-bin/assigned_problems_ajax.pl",true);
		request.setRequestHeader("Content-type","application/x-www-form-urlencoded");
		
		request.onreadystatechange=function() {
			if (request.readyState==4 && request.status==200)
		    {
				var prnt = element.parentNode.parentNode;
				for(var i=0; i < prnt .childNodes.length; i++) {
					var elem = prnt .childNodes[i];
					if (elem.id == "contentRow")
						prnt .removeChild(elem);
				}
				var resp = request.responseText;
				var row = document.createElement("TR");
			    var td1 = document.createElement("TD");
			    td1.innerHTML = resp ;
			    row.appendChild(td1);
			    row.setAttribute("id","contentRow");
				table = element.parentNode.parentNode;
				table.appendChild(row);
				
		    }
			element.onclick = function() { removeGroupsForThemes(this ,  id_tema) };
		}
		changeSing(element);
		var row = document.createElement("TR");
		row.setAttribute("id","contentRow");
		var td1 = document.createElement("TD");
		var text = document.createTextNode("Ожидание ответа сервера...");
		td1.appendChild(text);
		td1.setAttribute("colspan","2");
		row.appendChild(td1);
		element.setAttribute("rowspan", "2")
		table = element.parentNode.parentNode;
		table.appendChild(row);
		
		
		request.send("id_tema=" + id_tema	
						+ "&id_lng="+ lng
						+ "&action=getGroupForTema");
		
		
	    
	}

 /**
  * Removing groups...
  * @param element current element running script
  * @param id_tema current tema row
  */
 function removeGroupsForThemes(element , id_tema) {
		var prnt = element.parentNode.parentNode;
		element.removeAttribute("rowspan");
		changeSing(element);
		for(var i=0; i < prnt .childNodes.length; i++) {
			var elem = prnt .childNodes[i];
			if (elem.id == "contentRow")
				prnt .removeChild(elem);
		}
		element.onclick = function() { getGroupsForThemes(this, id_tema) };
}   

 
 function getStProblemsForThemes(element, id_tema) {
	 element.onclick = null;
	 var lng = document.getElementsByName("language")[0].value;
		var request = getRequest();
		request.open("POST","/cgi-bin/assigned_problems_ajax.pl",true);
		request.setRequestHeader("Content-type","application/x-www-form-urlencoded");
		
		request.onreadystatechange=function() {
			if (request.readyState==4 && request.status==200)
		    {
				var prnt = element.parentNode.parentNode;
				for(var i=0; i < prnt .childNodes.length; i++) {
					var elem = prnt .childNodes[i];
					if (elem.id == "contentRow")
						prnt .removeChild(elem);
				}
				var resp = request.responseText;
				var row = document.createElement("TR");
			    var td1 = document.createElement("TD");
			    td1.innerHTML = resp ;
			    row.appendChild(td1);
			    row.setAttribute("id","contentRow");
				table = element.parentNode.parentNode;
				table.appendChild(row);
				
		    }
			element.onclick = function() { removeStProblemsForThemes(this , id_tema) };
		}
		changeSing(element);
		var row = document.createElement("TR");
		row.setAttribute("id","contentRow");
		var td1 = document.createElement("TD");
		var text = document.createTextNode("Ожидание ответа сервера...");
		td1.appendChild(text);
		row.appendChild(td1);
		element.setAttribute("rowspan", "2")
		table = element.parentNode.parentNode;
		table.appendChild(row);
		
		
		request.send("id_tema=" + id_tema	
						+ "&id_lng="+ lng
						+ "&action=getStProblemsForThemes");
		
		
	    
	}

 function removeStProblemsForThemes(element , id_tema) {
		var prnt = element.parentNode.parentNode;
		element.removeAttribute("rowspan");
		changeSing(element);
		for(var i=0; i < prnt .childNodes.length; i++) {
			var elem = prnt .childNodes[i];
			if (elem.id == "contentRow")
				prnt .removeChild(elem);
		}
		element.onclick = function() { getStProblemsForThemes(this, id_tema) };
}  
 
 function getUsersForGroupEdit(element, id_group) {
	 element.onclick = null;
	 var lng = document.getElementsByName("language")[0].value;
		var request = getRequest();
		request.open("POST","/cgi-bin/assigned_problems_ajax.pl",true);
		request.setRequestHeader("Content-type","application/x-www-form-urlencoded");
		
		request.onreadystatechange=function() {
			if (request.readyState==4 && request.status==200)
		    {
				var prnt = element.parentNode.parentNode;
				for(var i=0; i < prnt .childNodes.length; i++) {
					var elem = prnt .childNodes[i];
					if (elem.id == "contentRow")
						prnt .removeChild(elem);
				}
				var resp = request.responseText;
				var row = document.createElement("TR");
			    var td1 = document.createElement("TD");
			    var td2 = document.createElement("TD");
				td2.setAttribute("colspan","4")
				td2.innerHTML = resp ;
			    row.appendChild(td1);
			    row.appendChild(td2);
			    row.setAttribute("id","contentRow");
				table = element.parentNode.parentNode;
				table.appendChild(row);
				
		    }
			element.onclick = function() { removeUsersForGroupEdit(this , id_group) };
		}
		changeSing(element);
		var row = document.createElement("TR");
		row.setAttribute("id","contentRow");
		var td1 = document.createElement("TD");
		var text = document.createTextNode("Ожидание ответа сервера...");
		var td2 = document.createElement("TD");
		td2.setAttribute("colspan","2")
		td2.appendChild(text);
		row.appendChild(td1);
		row.appendChild(td2);
		table = element.parentNode.parentNode;
		table.appendChild(row);
		
		
		request.send("id_group=" + id_group	
						+ "&id_lng="+ lng
						+ "&action=getUsersForGroupEdit");
		
		
	    
	}

 function removeUsersForGroupEdit(element , id_group) {
		var prnt = element.parentNode.parentNode;
		changeSing(element);
		element.removeAttribute("rowspan");
		for(var i=0; i < prnt .childNodes.length; i++) {
			var elem = prnt .childNodes[i];
			if (elem.id == "contentRow")
				prnt .removeChild(elem);
		}
		element.onclick = function() { getUsersForGroupEdit(this, id_group) };
}   

 function getChildGroups(element, id_group) {
	 element.onclick = null;
	 var lng = document.getElementsByName("language")[0].value;
		var request = getRequest();
		request.open("POST","/cgi-bin/assigned_problems_ajax.pl",true);
		request.setRequestHeader("Content-type","application/x-www-form-urlencoded");
		
		request.onreadystatechange=function() {
			if (request.readyState==4 && request.status==200)
		    {
				var prnt = element.parentNode.parentNode;
				for(var i=0; i < prnt .childNodes.length; i++) {
					var elem = prnt .childNodes[i];
					if (elem.id == "contentRow2")
						prnt .removeChild(elem);
				}
				var resp = request.responseText;
				var row = document.createElement("TR");
			    var td1 = document.createElement("TD");
			    var td2 = document.createElement("TD");
			    td2.setAttribute("colspan","4")
				td2.innerHTML = resp ;
			    row.appendChild(td1);
			    row.appendChild(td2);
			    row.setAttribute("id","contentRow2");
				table = element.parentNode.parentNode;
				table.appendChild(row);
				
		    }
			element.onclick = function() { removeChildGroups(this , id_group) };
		}
		changeSing(element);
		var row = document.createElement("TR");
		row.setAttribute("id","contentRow2");
		var td1 = document.createElement("TD");
		var text = document.createTextNode("Ожидание ответа сервера...");
		td1.setAttribute("colspan","4")
		td1.appendChild(text);
		row.appendChild(td1);
		table = element.parentNode.parentNode;
		table.appendChild(row);
		
		
		request.send("id_group=" + id_group	
						+ "&id_lng="+ lng
						+ "&action=getChildGroups");
		
		
	    
	}

 function removeChildGroups(element , id_group) {
		var prnt = element.parentNode.parentNode;
		element.removeAttribute("rowspan");
		changeSing(element);
		for(var i=0; i < prnt .childNodes.length; i++) {
			var elem = prnt .childNodes[i];
			if (elem.id == "contentRow2")
				prnt .removeChild(elem);
		}
		element.onclick = function() { getChildGroups(this, id_group) };
}   
 
function changeSing(element) {
	var child = element.childNodes[0];
	if (child){
		if (child.nodeType == 3) {
			child.data = (child.data == "+")? "-" : "+";
		} else {
			var text = child.innerHTML;
			child.innerHTML = (text == "+")? "-" : "+";
		}
	}
} 
 
 