����� ����������� ���� ������ �� �������� �������-��������� � ����������� �� �����������

select hour, minute from trips inner join routes on routes.cod_route=trips.cod_route 
where name_route='�������-���������' and week_day=1
order by hour, minute