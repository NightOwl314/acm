create table compil_trnmnt(
   id_trnmnt bigint not null,
   id_compil smallint not null,
   constraint fk_ct1 foreign key(id_trnmnt) references tournaments(id),
   constraint fk_ct2 foreign key(id_compil) references compil(id_cmp),
   constraint pk_ct primary key(id_trnmnt, id_compil)
)


/* игры - общее описание */
create table games(
  id bigint not null primary key,  /* »ƒ */

  caption  char(64)  not null,     /* название */
  gamefile char(255) not null      /* описание игры */
);

/* турниры */
create table tournaments(
   id bigint not null primary key,      /* »ƒ */

   id_game          bigint    not null, /* »ƒ игры турнира */
   caption          char(64)  not null, /* название турнира */
   dt_create        timestamp not null, /* дата создани€ */
   dt_start         timestamp not null, /* начало турнира */
   dt_finish        timestamp not null, /* завершение турнира */
   max_players      integer   not null, /* максимальное количество игроков */
   max_per_autor    integer   not null, /* макс кол-во одним автором */
   type             integer   not null, /* инфа дл€ жеребьевки - тип турнира */
   state            integer   not null, /* текущее состо€ние */
   lvl              integer   not null, /* сложность турнира */

   max_mem          integer   not null, /* ограничение по пам€ти */
   max_time_game    integer   not null, /* врем€ всей партии одного игрока */
   max_time_move    integer   not null, /* максимальное врем€ на один ход */
   max_move         integer   not null, /* ограничение на количество сделанных ходов */

   src_access       integer   not null, /* просмотр исходников */
   count_players    integer   not null, /* количество участников */
   count_autors     integer   not null, /* количество авторов */
   test_prg         char(255),          /* тестова€ программа */
   show_prg         char(255),          /* программа-визуализатор*/
   chk_prg          char(255) not null, /* чекер */
   chk_cmpl         smallint  ,         /* €зык-компил€тор */
   chk_src          blob sub_type 1,

   description      blob sub_type 1,    /* конкретное описание условий турнира*/

   constraint fk_tournaments1 foreign key(id_game) references games(id) on delete cascade,
   constraint fk_tournaments2 foreign key(chk_cmpl) references compil(id_cmp)
);

/* партии игр */
create table playing(
   id bigint not null primary key, /* »ƒ */

   state integer not null,         /* текущее состо€ние */
   start timestamp,                /* начало */
   finish timestamp,               /* завершение */
   count_players integer not null,
   logfile char(255),
   game_log blob sub_type 1        /* лог партии игры */
);

/* решени€ участников */
create table gm_slv(
   id bigint not null primary key,   /* »ƒ */

   id_trnmnt    bigint    not null,  /* »ƒ турнира */
   id_player    integer   not null,  /* участник */
   test_result  integer   not null,  /* результат контрольного теста */
   result       integer   not null,
   caption      char(64)  not null,  /* название программы-решени€ */
   input_dt     timestamp not null,  /* когда прислано */
   compiler     smallint  not null,  /* €зык-компил€тор */
   count_error  integer   not null,  /* всего решений с ошибками в этом турнире */
   count_good   integer   not null,  /* всего прин€тых */
   scraccess    integer   not null,

   points       integer   not null,  /* набранные баллы */
   mem          integer   not null,  /* использованна€ пам€ть */
   time_game    integer   not null,  /* врем€ всей партии */
   time_move    integer   not null,  /* максимальное врем€ на один ход */
   move         integer   not null,  /* количество сделанных ходов */

   code_source blob sub_type 1 not null, /* исходный код */
   compil_out  blob sub_type 1 not null, /* компил€ци€  */
   compilfile  char(255),

   constraint fk_gm_slv1 foreign key(id_trnmnt) references tournaments(id) on delete cascade,
   constraint fk_gm_slv2 foreign key(id_player) references authors(id_publ) on delete cascade,
   constraint fk_gm_slv3 foreign key(compiler ) references compil(id_cmp ) on delete cascade
);

/* участники партии игры */
create table slv_play(
   id_playing bigint,              /* »ƒ партии игры */
   id_gm_slv  bigint,              /* »ƒ программы-решени€ */
   number    integer,

   result    integer not null,     /* результат участника в партии (ошибка) */
   rank      integer not null,     /* место в партии */

   points    integer not null,     /* набранные баллы */
   mem       integer not null,     /* использованна€ пам€ть */
   time_game integer not null,     /* врем€ всей партии */
   time_move integer not null,     /* максимальное врем€ на один ход */
   move      integer not null,     /* количество сделанных ходов */

   constraint fk_slv_play1 foreign key(id_playing) references playing(id) on delete cascade,
   constraint fk_slv_play2 foreign key(id_gm_slv)  references gm_slv(id)  on delete cascade,
   constraint pk_slv_play primary key(id_playing, id_gm_slv, number)
);



commit;

/* eof */

set sql dialect 3;

set names win1251;

set term ^;

create generator gen_trnmnt^
create generator gen_games^
create generator gen_gm_slv^
create generator gen_playing^

commit^

show generators^

create trigger bi_trnmnt for tournaments
active before insert position 0
as
begin
  if(new.id is null) then
     new.id = gen_id(gen_trnmnt, 1);
  /**/
  if(new.dt_create is null) then
     new.dt_create = CURRENT_TIMESTAMP;
  /**/
  if(new.dt_start is null) then
     new.dt_start = CURRENT_TIMESTAMP;
  /**/
  if(new.dt_finish is null) then
     new.dt_finish = CURRENT_TIMESTAMP + 100;/* +100 дней */
  /**/
  if(new.type is null) then
     new.type = 1;
  /**/
  if(new.state is null) then
     new.state = 1;/*!!! not begin*/
  /**/
  if(new.lvl is null) then
     new.lvl = 1;
  /* limits */
  if(new.max_mem is null) then
     new.max_mem = 0;
  if(new.max_time_game is null) then
     new.max_time_game = 0;
  if(new.max_time_move is null) then
     new.max_time_move = 0;
  if(new.max_move is null) then
     new.max_move = 0;
  /**/
  if(new.count_autors is null) then
     new.count_autors = 0;
  if(new.count_players is null) then
     new.count_players = 0;
  if(new.max_per_autor is null) then
     new.max_per_autor = 5;
  if(new.max_players is null) then
     new.max_players = 0;

end^

create trigger bi_playing for playing
active before insert position 0
as
begin
  if(new.id is null) then
     new.id = gen_id(gen_playing, 1);
  if(new.count_players is null) then
     new.count_players = 0;     
end^

create trigger bi_gm_slv for gm_slv
active before insert position 0
as
declare variable N integer default 0;
begin
  if(new.id is null) then
     new.id = gen_id(gen_gm_slv, 1);
  if(new.input_dt is null) then
     new.input_dt = CURRENT_TIMESTAMP;
  if(new.points is null) then
     new.points = 0;
  if(new.test_result is null) then
     new.test_result = -1;
  new.result = new.test_result;

  if(new.mem is null) then
     new.mem = 0;
  if(new.time_game is null) then
     new.time_game = 0;
  if(new.time_move is null) then
     new.time_move = 0;
  if(new.move is null) then
     new.move = 0;
  if(new.scraccess is null) then
     new.scraccess = 0;
  
  if(new.compil_out is null) then
     new.compil_out = ' ';
  
  select count(*)
  from gm_slv
  where (id_trnmnt = new.id_trnmnt) and 
        (id_player = new.id_player) and 
        (test_result != 0)
  into :N;
  new.count_error = N;

  select count(*)
  from gm_slv
  where id_trnmnt = new.id_trnmnt and id_player = new.id_player and test_result = 0
  into :N;
  new.count_good = N;

  N = N + 1;
  if(new.caption is null) then
     new.caption = 'Attempt #' || N;

end^

create trigger au_gm_slv for gm_slv
active after update position 0
as
declare variable count_players integer default 0;
declare variable count_autors  integer default 0;
begin
   select count(id) 
   from gm_slv 
   where (test_result = 0) and (id_trnmnt = new.id_trnmnt)
   into :count_players;

   select count(distinct id_player)
   from gm_slv 
   where (test_result = 0) and (id_trnmnt = new.id_trnmnt)
   into :count_autors;

   update tournaments set count_players = :count_players, count_autors = :count_autors
   where id = new.id_trnmnt;
end^

create trigger bi_games for games
active before insert position 0
as
begin
  if (new.id is null) then
     new.id = gen_id(gen_games, 1);
  if(new.caption is null) then
     new.caption = '»гра #' || new.id;
end^

create trigger bi_slv_play for slv_play
active before insert position 0
as
begin
   if (new.result is null) then
      new.result = 0;
   if (new.rank is null) then
      new.rank = 0;
   if (new.points is null) then
      new.points = 0;
   if (new.mem is null) then
      new.mem = 0;
   if (new.time_game is null) then
      new.time_game = 0;
   if (new.time_move is null) then
      new.time_move = 0;
   if (new.move is null) then
      new.move = 0;
end^

create trigger ai_slv_play for slv_play
active after insert position 0
as
declare variable count_players integer default 0;
begin
   select count(*) from slv_play where id_playing = new.id_playing
   into :count_players;
   
   update playing set count_players = :count_players
   where  playing.id = new.id_playing;
end^

create trigger au_slv_play for slv_play
active after update position 0
as
declare variable R integer default 0;
declare variable P integer default 0;
begin
   select max(result) from slv_play
   where id_gm_slv = new.id_gm_slv
   into :R;

   select sum(points) from slv_play
   where id_gm_slv = new.id_gm_slv
   into :P;

   update gm_slv set points = :P, result = :R where id = new.id_gm_slv;
end^


create view view_playing (AID, BID, AP, Apoints, Bpoints)
as
select A.id_gm_slv as AID, B.id_gm_slv as BID,
       A.id_playing as AP, A.points as Apoints, B.points as Bpoints
from slv_play A, slv_play B
where (A.id_playing = B.id_playing) and (A.number = 1) and (B.number = 2)
^


create view view_playing_ex (AID, BID, sum_pnts, id_player, trnmnt, caption, cmpl)
as
select A.id as AID, B.id as BID, A.points as points, A.id_player as id_player,
       A.id_trnmnt as trnmnt, A.caption as caption, A.compiler as cmpl
from gm_slv A, gm_slv B
where (A.id != B.id) and
      (A.test_result = 0) and (B.test_result = 0) and
      (A.id_trnmnt = B.id_trnmnt)
order by A.id, B.id
^

create view v_full_table (tourn, id_plr, cptn, pnts, AID, BID, Apoints, Bpoints, AP, cmpl)
as
select view_playing_ex.trnmnt    as tourn,
       view_playing_ex.id_player as id_plr,
       view_playing_ex.caption   as cptn,
       view_playing_ex.sum_pnts  as pnts,
       view_playing_ex.AID       as AID,
       view_playing_ex.BID       as BID,
       view_playing.Apoints      as Apoints,
       view_playing.Bpoints      as Bpoints,
       view_playing.AP           as AP,
       view_playing_ex.cmpl      as cmpl
from view_playing_ex, view_playing
where view_playing_ex.AID = view_playing.AID and
      view_playing_ex.BID = view_playing.BID
order by view_playing_ex.AID, view_playing_ex.BID
^


create procedure AddNewGamesFull(id1 bigint, idt bigint)
returns(isError integer)
as
declare variable id0 bigint;/* игра */
declare variable id2 bigint;/* второй участник */
begin
   for select id from gm_slv where id != :id1 and id_trnmnt = :idt and test_result = 0
   into :id2
   do begin
      id0 = gen_id(gen_playing, 1);
      insert into playing(id, state) values(:id0, 1);
      insert into slv_play(id_playing, id_gm_slv, number) values(:id0, :id1, 1);
      insert into slv_play(id_playing, id_gm_slv, number) values(:id0, :id2, 2);
      
      id0 = gen_id(gen_playing, 1);
      insert into playing(id, state) values(:id0, 1);
      insert into slv_play(id_playing, id_gm_slv, number) values(:id0, :id2, 1);
      insert into slv_play(id_playing, id_gm_slv, number) values(:id0, :id1, 2);
   end

   isError = 0;
   suspend;

   when any do
   begin
      isError = 1;
      exit;
   end
end^

set term ;^

commit;