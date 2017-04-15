Количество автобусов 1 класса

select count(*) as cnt from buses inner join models on buses.cod_model=models.cod_model where class=1