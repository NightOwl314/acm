Названия всех пунктов, в которых есть хотя бы одна буква О (без учета регистра), вывести в алфавитном порядке

select name_point from points where name_point like '%О%' or name_point like '%о%' order by name_point
