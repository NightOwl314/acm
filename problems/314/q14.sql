ћаксимальна€ цена билета на рейс с номером 2

select max(price*distance) as pr from km_prices inner join models on km_prices.class=models.class
inner join buses on models.cod_model=buses.cod_model inner join trips on buses.cod_bus=trips.cod_bus
inner join routes on routes.cod_route=trips.cod_route 
inner join points_routes on routes.cod_route=points_routes.cod_route
inner join points on points.cod_point=points_routes.cod_point
where trips.cod_trip=2
