#!c:\perl\bin\perl.exe

 

use CGI qw(:standard);  # ������������ ������ CGI.pm. qw(:standard) �����������

                        # ������������ ���� ����������� CGI-�������, ����� ��������

                        # ����� �������� ���. ��� ����� ������, ���� � �������� 

                        # ������������ ������ ���� ������ CGI.

 

$mycgi = new CGI; #������� ������ CGI, ������� ����� '������' � ������ �����

 

@fields = $mycgi->param; # ������� ����� ���� ����������� ����� �����

 

 

print header(-charset=>'cp-1251'), start_html('CGI.pm test');
                              # ������ 'header' � 'start_html', ���������������

                              # CGI.pm, �������� ��������� HTML.                                      

                              # 'header' ������� ��������� ��������� HTTP, � 

                              #'start_html' ������� ��������� HTML � ������ ���������, 

                              #� ����� ��� <BODY>.

print "<p>������ �����:<br>";

 

 

foreach (@fields) { print $_, ":", $mycgi->param($_), "<br>"; }

# ��� ������� ���� ������� ��� � ��������, ���������� � �������

# $mycgi->param('fieldname').

 

print end_html; # ���������� ��� ������ ����������� ����� "</body></html>".