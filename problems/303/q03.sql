�������� ���� ������� �������� �������-��������� � ������� ����������

select name_point from routes inner join points_routes on points_routes.cod_route=routes.cod_route
inner join points on points.cod_point=points_routes.cod_point where routes.name_route='�������-���������'
order by distance
