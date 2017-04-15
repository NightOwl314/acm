#!/usr/bin/perl -w
#use lib '../blib/lib', '../blib/arch';

use strict;
use AlgorithmMy::DecisionTree;
use DBI;
use DBD::InterBase;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp  qw(fatalsToBrowser);
use POSIX;
require 'common_func.pl';
our $DB_HOST = 'localhost';
our $DB_NAME = 'C:\data\acm\db\acm.gdb';
our $DB_USER = 'sysdba';
our $DB_PASSWORD = 'masterkey';
our $dsn = "DBI:InterBase:database=$DB_NAME;host=$DB_HOST";
use vars qw($request $db $DirTemplates $incgi %cookies %ENV);

sub construct_dt{
    #файл с входной выборкой
	my $training_datafile = "training.dat";
	
	my $dt = Algorithm::DecisionTree->new(training_datafile => $training_datafile);
	#обучающую выборку загружаем из базы в файл
	#в хеш
	get_training_data_from_bd();
	$dt->get_training_data();
	my $root_node = $dt->construct_decision_tree_classifier();
	#сохраняем дерево
	my $hash = $dt->store_tree_in_hash($root_node);
	set_dt_into_base($hash);
}

sub classify_tasks{
	my ($id_publ,@tasks) =@_;
	my %hash_new;
	my $training_datafile = "training.dat";
	my $dt = Algorithm::DecisionTree->new(training_datafile => $training_datafile);
	#загружаем структуру из бд в хеш
	my $hash_db = get_tree(\%hash_new);
	#загружаем в дерево из хеша
	my $root_node_new = $dt->load_tree_from_hash($hash_db);
	my $i=0;
	my @classify;
	foreach(@tasks){
	    my $check = check_task($tasks[$i],$id_publ);
		if ($check == 1){
			#получаем данные для данного примера
			my @test_sample = get_test_sample($id_publ,$tasks[$i]);
			#получаем класс сложности
			my $class = $dt->classify($root_node_new, @test_sample);
				$classify[$i] = $class;
		}elsif ($check == 0){
		$classify[$i] = -1;
		}else{
		$classify[$i] = 0;
		}
		$i++;
	}
	return  @classify;        
}
sub check_task{
    my ($id_task,$id_publ) = @_;
    my $st = $db->prepare("select asolv_cnt from problems
		where id_prb = '$id_task'");
	$st->execute();
	my $sth = $db->prepare("select count(id_publ) from resolved_tasks
		where id_prb = '$id_task' and id_publ = '$id_publ'");
	$sth->execute();
	my $st2 = $db->prepare("select hardlevel from problems
		where id_prb = '$id_task'");
	$st2->execute();
	my $solve_cnt = $st->fetchrow_array;
	my $is_solve = $sth->fetchrow_array;
	my $hardlevel = $st2->fetchrow_array;
	if ($is_solve != 0){
		return 2;
	}
	if (($solve_cnt < 10)||($hardlevel < 5)){
		return 0;
	}
	return 1;
}

sub get_test_sample{
	my($id_publ,$id_task)=@_;
	my $st = $db->prepare("select current_timestamp from rdb\$database");
	$st->execute();
	#текущая дата и время
	my $current_dt ="";
    $current_dt = $st->fetchrow_array;
	$st->finish();
	my	$sth=$db->prepare("select
		(select count(\*) from resolved_tasks
		where id_publ = '$id_publ'
		and dt_tm <='$current_dt') as st_solve,
		(select count(\*) from status_solved
		where id_publ = '$id_publ'
		and dt_tm <= '$current_dt') as st_submit,
		(select avg(res_time) from resolved_tasks
		where id_publ = '$id_publ'
		and dt_tm <= '$current_dt') as st_avgtime,
		(select avg(cnt_att) from resolved_tasks
		where id_publ = '$id_publ'
		and dt_tm <= '$current_dt') as st_avgatt,
		(select avg(rt.hardlevel) from resolved_tasks rt
		where '$id_publ' = rt.id_publ
		and rt.dt_tm <= '$current_dt') as st_avghard,
		cast(100\*(select count(\*) from resolved_tasks
		where id_publ = '$id_publ'
		and dt_tm <= '$current_dt')/(select count(\*) from status_solved
		where id_publ = '$id_publ'
		and dt_tm <= '$current_dt') as numeric(8,2)) as succesfull,
		(select count(\*) from resolved_tasks
		where id_prb = '$id_task') as prb_solve,
		(select count(\*) from status_solved
		where id_prb = '$id_task') as prb_submit,
		(select count(distinct(id_publ)) from status_solved
        where id_prb = '$id_task') as prb_stud_submit,
		(select avg(res_time) from resolved_tasks
		where id_prb = '$id_task') as prb_avgtime,
		(select avg(cnt_att) from resolved_tasks
		where id_prb = '$id_task') as prb_avgatt,
		cast(100*(select count(\*) from resolved_tasks
		where id_prb = '$id_task')/(select count(\*) from status_solved
		where id_prb = '$id_task') as numeric(8,2)) as prb_succesfull,
		prb.hardlevel
		from
		problems prb where id_prb='$id_task'");
	$sth->execute();
	my @test_sample=$sth->fetchrow_array;
	$sth->finish();
	return @test_sample;
}

sub get_training_data_from_bd{
	my $st = $db->prepare("select
		case
		when t.cnt_att = 1 then 3
		when t.cnt_att <= 5 and  t.res_time < 10 then 2
		when (t.cnt_att > 5 or t.res_time > 10) then 1
		end as class,
		(select count(\*) from resolved_tasks
		where t.id_publ = id_publ
		and dt_tm <= t.dt_tm) as st_solve,
		(select count(\*) from status_solved
		where t.id_publ = id_publ
		and dt_tm <= t.dt_tm) as st_submit,
		(select avg(res_time) from resolved_tasks
		where t.id_publ = id_publ
		and dt_tm <= t.dt_tm) as st_avgtime,
		(select avg(cnt_att) from resolved_tasks
		where t.id_publ = id_publ
		and dt_tm <= t.dt_tm) as st_avgatt,
		(select avg(rt.hardlevel) from resolved_tasks rt
		where t.id_publ = rt.id_publ
		and rt.dt_tm <= t.dt_tm) as st_avghard,
		cast(100\*(select count(\*) from resolved_tasks
		where t.id_publ = id_publ
		and dt_tm <= t.dt_tm)/(select count(\*) from status_solved
		where t.id_publ = id_publ
		and dt_tm <= t.dt_tm) as numeric(8,2)) as succesfull,
		(select count(\*) from resolved_tasks
		where t.id_prb = id_prb) as prb_solve,
		(select count(\*) from status_solved
		where t.id_prb = id_prb) as prb_submit,
		(select count(distinct(id_publ)) from status_solved
		where t.id_prb = id_prb) as prb_stud_submit,
		(select avg(res_time) from resolved_tasks
		where t.id_prb = id_prb) as prb_avgtime,
		(select avg(cnt_att) from resolved_tasks
		where t.id_prb = id_prb) as prb_avgatt,
		cast(100*(select count(\*) from resolved_tasks
		where t.id_prb = id_prb)/(select count(\*) from status_solved
		where t.id_prb = id_prb) as numeric(8,2)) as prb_succesfull,
		prb.hardlevel
		from
		status_solved st
		join
		resolved_tasks t on t.id_publ = st.id_publ and t.id_prb = st.id_prb
		join
		problems prb on prb.id_prb = st.id_prb
		join
		authors auth on auth.id_publ = st.id_publ and (-1)\*auth.solve_cnt >= 10
		left join
		groups_authors gr_auth on gr_auth.id_publ = st.id_publ and gr_auth.id_grp >= 8
		left join
		groups gr on gr.id_grp = gr_auth.id_grp
		where
		st.id_rsl = 0
		and st.id_publ <> 21916
		and prb.hardlevel >= 5");
	$st->execute();
	open(F1,"> training.dat");
	print F1 "Class names: 1 2 3 \n";
	print F1 "Training Data:\n";
	my $i = 0;
	while (my ($class,
			$solve_cnt,
			$submit_cnt,
			$avg_time,
			$avg_count,
			$avg_hard,
			$succesfull,
			$solve_c,
			$submit_c,
			$prb_stud_submit,
			$avg_t,
			$avg_att_prb,
			$prb_succesfull,
			$hardlevel
			)=$st->fetchrow_array){		
		print F1 "samples_$i $class $solve_cnt $submit_cnt $avg_time $avg_count $avg_hard $succesfull $solve_c $submit_c $prb_stud_submit $avg_t $avg_att_prb $prb_succesfull $hardlevel \n";
		$i++;
	}
	close(F1);
	$st->finish();
}

# загрузка дерева в базу
sub set_dt_into_base{
	my $hash_tree = shift;
	my $st = $db->prepare("delete from decision_tree");
	$st->execute();
	$st->finish();
	#достаем записи из хэша и кладем в таблицу
	my $sth="";
	while ( my ($key, $value) = each(%$hash_tree) ) {
		$sth = $db->prepare("insert into decision_tree (serial,class,feature_number,feature_value,left_serial,right_serial)values('$key','@{$value}[1]','@{$value}[2]','@{$value}[3]','@{$value}[4]','@{$value}[5]')");
		$sth->execute();
    }
	$sth->finish();
	my $stdt=$db->prepare("select current_timestamp from rdb\$database");
	$stdt->execute();
	my $current_dt = $stdt->fetchrow_array;
	$stdt->finish();
	my $stdt2=$db->prepare("insert into decision_history(date_time) values('$current_dt')");
	$stdt2->execute();
	$stdt2->finish();
}

sub get_tree{
	my $hash = shift;
	my $sth = $db->prepare("select serial,class,feature_number,feature_value,left_serial,right_serial from decision_tree");
	$sth->execute();
	my $st = $db->prepare("select min(serial) from decision_tree");
	$st->execute();
	my $min_key=$st->fetchrow_array;
	my $i=0;
	my @keys=();
	while (my($key,$class,$feature_number,$feature_value,$left_serial,$right_serial)=$sth->fetchrow_array){
		push @{$hash->{$key}}, $key;
		@keys[$i] = $key;
		$i++;
		my $parameter = \@{$hash->{$key}};
		push @{$parameter},$class;
		push @{$parameter},$feature_number;
		push @{$parameter},$feature_value;
		push @{$parameter},$left_serial;
		push @{$parameter},$right_serial; 
	}
	$sth->finish();
	return $hash;
}

return 1;