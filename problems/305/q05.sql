Время отправления всех рейсов по маршруту Вологда-Череповец в понедельник по возрастанию

select hour, minute from trips inner join routes on routes.cod_route=trips.cod_route 
where name_route='Вологда-Череповец' and week_day=1
order by hour, minute