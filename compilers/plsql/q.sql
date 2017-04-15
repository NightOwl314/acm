alter table points_temp
add type integer;

update points_temp
set type=1
where distance>250;

update points_temp
set type=2
where distance>100 and distance<=250;

update points_temp
set type=3
where distance<=100;
