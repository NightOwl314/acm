 оды рейсов с указанием названий маршрутов и времени отправлени€ в воскресенье до 12 часов, в пор€дке возрастани€ времени

select trips.cod_trip, name_route, hour, minute from trips inner join routes on routes.cod_route=trips.cod_route 
where week_day=7 and hour<12
order by hour, minute
