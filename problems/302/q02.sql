������ ���� ��������� ����� ������, ������� � ����������������� �������

select bus_number from buses inner join models on models.cod_model=buses.cod_model
where models.name_model='������' order by bus_number