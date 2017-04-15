Названия всех маршрутов, которые проходят через Шексну, в алфавитном порядке

select distinct name_route from routes inner join points_routes on points_routes.cod_route=routes.cod_route
inner join points on points.cod_point=points_routes.cod_point where points.name_point='Шексна'