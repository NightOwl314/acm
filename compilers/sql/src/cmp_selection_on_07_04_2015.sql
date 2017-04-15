
  CREATE OR REPLACE PROCEDURE "CREATOR"."CMP_SELECTION" (
    test_query_ in varchar2, right_query in varchar2,
    test_answer out varchar2, right_answer out varchar2,
    answer out varchar2, orderby in integer := 0)
authid current_user ---���������� � ������� �����������
is
count_rq integer;
count_q integer;
count_rq_dist integer;  -- ���� �� ����������� �����������
count_union integer;
test_query varchar2(10240);
str_sql varchar2(10240);
begin
  --- �� ��������� PL/SQL ������� �� ���������� ������ ��� ����������� �������,
  --- � ��� ���� ������ � ����� ������ ������ ';' , ���� �� ����, ����� ��
  --- ��������� ������������� ������
  if substr(test_query_,length(test_query_),1) = ';'
    then
      test_query := substr(test_query_,1,length(test_query_)-1);
    else
      test_query := test_query_;
  end if;

  -- ��������� ���������������� ������, ��������� ��������� � test_answer
  count_q := creator.dump_rows(test_query,test_answer);
  test_answer := 'Query result:'|| chr(10) || test_answer;
  if count_q < 0 then
    right_answer := 'Error executing a user request.';
    answer := 'error';
    return;
  end if;

  ---���������
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
      -- ������������ ����� ��� ��� ����� �����, ���������� ��� ���������...
      count_rq := creator.dump_rows(right_query,right_answer);
      answer := 'Presentation error, please check order and count of resulting columns';
      return;
  END;

  --- ������� ���������� ����� ����������� �������
  count_rq := creator.dump_rows(right_query,right_answer);
  right_answer := 'Query result:' || chr(10) || right_answer;
  --- ������� ���������� ����� ����������� ������� ��� ����������
  if orderby<>0 then
    count_rq_dist := count_rq;
  else
    -- ���� ��� ����������, ����� ��������� ���������
    execute immediate '
      select count(*) from (
      select distinct * from ('||right_query||')
      )' into count_rq_dist;
  end if;

  -- ������ ��������� �����
  if (count_q > count_rq) then
      answer := 'Query returns too many records.';
      return; -- ������ �������
  end if;
  if (count_rq > count_q) then
      answer := 'Query returns fewer records than necessary.';
      return; -- ������ �������
  end if;
-- ���������� � ����������� ��� ����������, ������ ��� "�����������" �������� �
-- ���������� (- �� ����� ���� ����������)
  if (count_rq_dist != count_union) then
      answer := 'Query returns wrong records.';
      return; -- ������������ ����� �������
  end if;

  answer := 'OK'; ---���� �������
  /* ����� �� ������� ����� */
  right_answer := '';
  test_answer  := '';

end cmp_selection;
/
 
