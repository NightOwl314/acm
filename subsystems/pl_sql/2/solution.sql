alter table punct
add type integer;

update punct
set type=1
where distance>250;

update punct
set type=2
where distance>100 and distance<=250;

update punct
set type=3
where distance<=100;