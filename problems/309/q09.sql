Ќомера всех автобусов, которые задействованы в выходные дни (суббота и воскресенье) в лексикографическом пор€дке

select distinct bus_number from buses inner join trips on buses.cod_bus=trips.cod_bus where
trips.week_day>=6 order by bus_number

---ќсобенности---
нужно удалить дубликаты
