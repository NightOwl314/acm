
  CREATE OR REPLACE PROCEDURE "CREATOR"."CMP_SELECTION" (
    test_query_ in varchar2, right_query in varchar2,
    test_answer out varchar2, right_answer out varchar2,
    answer out varchar2, orderby in integer := 0)
authid current_user ---вызывается с правами вызывающего
is
count_rq integer;
count_q integer;
count_rq_dist integer;  -- если не применяется сортировака
count_union integer;
test_query varchar2(10240);
str_sql varchar2(10240);
begin
  --- По умолчанию PL/SQL удаляет из символьной строки все завершающие пробелы,
  --- а нам надо убарть в конце строки символ ';' , если он есть, чтобы не
  --- порушился проверяющийся запрос
  if substr(test_query_,length(test_query_),1) = ';'
    then
      test_query := substr(test_query_,1,length(test_query_)-1);
    else
      test_query := test_query_;
  end if;

  -- выполняем пользовательский запрос, сохраняем результат в test_answer
  count_q := creator.dump_rows(test_query,test_answer);
  test_answer := 'Query result:'|| chr(10) || test_answer;
  if count_q < 0 then
    right_answer := 'Error executing a user request.';
    answer := 'error';
    return;
  end if;

  ---сравнение
  str_sql := 'select count(*) from ';
  if orderby<>0 then
    str_sql := str_sql || '(
      select rownum n, a.* from ('|| right_query ||') a
      union
      select rownum n, a.* from ('|| test_query ||') a
      )';
  else
    str_sql := str_sql || '(
      select *             from ('|| right_query || ')
      union
      select *             from ('|| test_query || ')
      )';
  end if;

  BEGIN
  execute immediate str_sql into count_union;
  exception
    when others
      then
      -- несовпадение полей или еще какая фигня, показываем как правильно...
      count_rq := creator.dump_rows(right_query,right_answer);
      answer := 'Presentation error, please check order and count of resulting columns';
      return;
  END;

  --- подсчет количества строк правильного запроса
  count_rq := creator.dump_rows(right_query,right_answer);
  right_answer := 'Query result:' || chr(10) || right_answer;
  --- подсчет количества строк правильного запроса без дубликатов
  if orderby<>0 then
    count_rq_dist := count_rq;
  else
    -- если без сортировки, нужно исключить дубликаты
    execute immediate '
      select count(*) from (
      select distinct * from ('||right_query||')
      )' into count_rq_dist;
  end if;

  -- анализ количеств строк
  if (count_q > count_rq) then
      answer := 'Query returns too many records.';
      return; -- больше записей
  end if;
  if (count_rq > count_q) then
      answer := 'Query returns fewer records than necessary.';
      return; -- меньше записей
  end if;
-- сравниваем с количеством без дубликатов, потому что "объединение" работает с
-- множеством (- не может быть дубликатов)
  if (count_rq_dist != count_union) then
      answer := 'Query returns wrong records.';
      return; -- неправильный набор записей
  end if;

  answer := 'OK'; ---тест пройден
  /* чтобы не грузить канал */
  right_answer := '';
  test_answer  := '';

end cmp_selection;
/
 
