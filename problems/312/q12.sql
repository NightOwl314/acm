����� ����������� ���� ������ (����, ������) � ��������� ��������� ��� ���� ������ � �����������, ������� �������� ����� �����, 
� ������� ����������� �������

select hour, minute, name_route from trips inner join routes on routes.cod_route=trips.cod_route 
inner join points_routes on routes.cod_route=points_routes.cod_route 
inner join points on points.cod_point=points_routes.cod_point
where week_day=1 and name_point='�����'
order by hour, minute
