�������� � ���� ���� ���������, ������� �������� ����� ������, � ���������� �������

select name_route, routes.cod_route from routes inner join points_routes 
on routes.cod_route=points_routes.cod_route 
inner join points on points.cod_point=points_routes.cod_point
where name_point='������'
order by name_route
