#!c:\perl\bin\perl.exe

 

use CGI qw(:standard);  # Используется модуль CGI.pm. qw(:standard) импортирует

                        # пространство имен стандартных CGI-функций, чтобы получить

                        # более понятный код. Это можно делать, если в сценарии 

                        # используется только один объект CGI.

 

$mycgi = new CGI; #Создать объект CGI, который будет 'шлюзом' к данным формы

 

@fields = $mycgi->param; # Извлечь имена всех заполненных полей формы

 

 

print header(-charset=>'cp-1251'), start_html('CGI.pm test');
                              # Методы 'header' и 'start_html', предоставляемые

                              # CGI.pm, упрощают получение HTML.                                      

                              # 'header' выводит требуемый заголовок HTTP, а 

                              #'start_html' выводит заголовок HTML с данным названием, 

                              #а также тег <BODY>.

print "<p>Данные формы:<br>";

 

 

foreach (@fields) { print $_, ":", $mycgi->param($_), "<br>"; }

# Для каждого поля вывести имя и значение, получаемое с помощью

# $mycgi->param('fieldname').

 

print end_html; # Сокращение для вывода завершающих тегов "</body></html>".