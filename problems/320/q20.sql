Общее количество рейсов в неделю по маршруту Вологда-Череповец

select count(*) from trips inner join routes on routes.cod_route=trips.cod_route 
where name_route='Вологда-Череповец'
