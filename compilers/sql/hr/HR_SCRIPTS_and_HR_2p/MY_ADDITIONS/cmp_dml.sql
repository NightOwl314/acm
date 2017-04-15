create or replace
procedure                cmp_dml(
  test_query in varchar2, right_query in varchar2,
  test_answer out varchar2, right_answer out varchar2,
  answer out varchar2,
  table_name in varchar2, compare_fields in varchar2)
authid current_user -- вызываетс€ с правами вызывающего
is
count1 integer;
count2 integer;
count_show integer := 30;
l_test_query varchar2(1024);
begin
  --- убараем в конце строки символ ';' , если он есть, чтобы не
  --- порушилс€ провер€ющийс€ запрос
  if substr(test_query,length(test_query),1) = ';'
    then
      l_test_query := substr(test_query,1,length(test_query)-1);
    else
      l_test_query := test_query;
  end if;
  --выполн€ем сначала запрос пользовател€ дл€ обнаружени€ ошибок
  begin
    execute immediate l_test_query;
  exception
      when others then
          test_answer := sqlerrm;
          right_answer := 'Error executing a user request.';
          answer := 'error';
          return;
  end;
  -- отобразим измен€емую таблицу (только первые 30 строк...)
  count1 := creator.dump_rows('select * from '||table_name,test_answer,count_show);
  test_answer := 'ѕредполагаема€ измен€ема€ таблица (первые '||count_show||' строк):'|| chr(10) || test_answer;
  -- скопируем таблицу во временную таблицуы (очень хитрожопа€ и жутковата€ функци€ расположенн€ в пакете)
  cmp_pkg.copy_table(table_name);
  rollback; -- откат, надо чтобы не было изменений в базе

  execute immediate right_query; -- правильный запрос
  count2 := creator.dump_rows('select * from '||table_name,right_answer,30);
  right_answer := 'ѕредполагаема€ измен€ема€ таблица (первые '||count_show||' строк):'|| chr(10) || right_answer;
  -- сравнение таблиц
  if (count1 = count2) and ( cmp_pkg.eq_table(table_name,compare_fields) ) then
    answer := 'OK';
  else
    answer := 'error';
  end if;
  rollback;
end;
/

grant execute on cmp_dml to public;
