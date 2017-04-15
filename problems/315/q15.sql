Количество автобусов марки Икарус

select count(*) as cnt from buses inner join models on buses.cod_model=models.cod_model where name_model='Икарус'
