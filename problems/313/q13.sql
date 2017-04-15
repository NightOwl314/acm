Сколько свободных мест имеется на рейс с кодом 2

select places-tickets as frpl from models inner join buses on models.cod_model=buses.cod_model
inner join trips on buses.cod_bus=trips.cod_bus where trips.cod_trip=2