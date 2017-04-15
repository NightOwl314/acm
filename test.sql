create user creator identified by creator;
grant connect, resource to creator;

create user buses0_creator identified by buses0_creator;
grant connect, resource to buses0_creator;

create user buses1_creator identified by buses1_creator;
grant connect, resource to buses1_creator;

create user buses2_creator identified by buses2_creator;
grant connect, resource to buses2_creator;

create user buses0_select identified by buses0_select;
grant connect, resource to buses0_select;

create user buses1_select identified by buses1_select;
grant connect, resource to buses1_select;

create user buses2_select identified by buses2_select;
grant connect, resource to buses2_select;

create user buses0_dml identified by buses0_dml;
grant connect, resource to buses0_dml;

create user buses1_dml identified by buses1_dml;
grant connect, resource to buses1_dml;

create user buses2_dml identified by buses2_dml;
grant connect, resource to buses2_dml;

select name_point from points where distance <= 20 order by name_point