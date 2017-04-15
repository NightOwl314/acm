#ifndef trnmnt_h_
#define trnmnt_h_
#define _WIN32_WINNT 0x0501
#ifdef UNICODE
   #undef UNICODE
#endif


#include <windows.h>
#include <string>
#include <iostream>
#include <vector>
#include "log.h"

using namespace std;


#define REPLACE_ID "$(id)"

#define EVN_NEW_TEST 1
#define EVN_STOP_SRV 2

#define RS_WRONG_ANSWER 1
#define RS_PRESENTATION_ERROR 2
#define RS_RUN_TIME_ERROR 3
#define RS_TIME_LIMIT 4
#define RS_MEMORY_LIMIT 5
#define RS_SECURITY_VIOLATION 6
#define RS_COMPILATION_ERROR 7
#define RS_SLEEP_DETECT 8
#define RS_UNIQUE_ERROR 9

//
enum st_enum {
   st_min_error = int('a')-1,

   st_ok,                // 0   a
   st_end_ok,            // 1   b
   st_end_give_all,      // 2   c
   st_ok_give_all,       // 3   d
   st_ok_notgive,        // 4   e     
   st_end_error,         // 5   f
                         
   st_unique_error,      // 6   g
   st_time_limit_move,   // 7   h
   st_time_limit_game,   // 8   i
   st_memory_limit,      // 9   j
   st_move_limit,        // 10  k
   st_sleep_detect,      // 11  l
   st_buffer_overflow,   // 12  m
   st_presentation_error,// 13  n
   st_wrong_move,        // 14  o
   st_run_time_error,    // 15  p
   st_security_violation,// 16  q
   st_compilation_error, // 17  r

   st_max_error,
};



enum {
    game_state_nostate = 0,
    game_state_forplay,
    game_state_playing,
    game_state_played,
};


const int MAX_STR_LEN = 300;
const int MAX_STR_SHORT_LEN = 64;

const int szBuf = 4096;

typedef long long IDENTITY;
typedef long INTEGER;

typedef struct Limits_
{
   INTEGER max_mem;//память
   INTEGER max_move;//количество ходов
   INTEGER max_tm_move;//время на один ход
   INTEGER max_tm_game;//время на всю партию игры одному игроку (на все его ходы)
} TLimits;

typedef struct TTournament_
{
   IDENTITY id;
   INTEGER state;
   INTEGER type;
   TLimits limits;

   char chk_prg[MAX_STR_LEN];
   char tst_prg[MAX_STR_LEN];
} TTournament;

char *trim(char *s, char *str = NULL);
void StrReplace(char *str_src, char *str_find, char *str_new);
void StrCopy(char *dest, char *src, int len);
int FileExists(char *filename);
int RemDirMy(char *dir);
int ErrWinAPI();

extern char PlayDir[MAX_STR_LEN];
extern char TestPlayDir[MAX_STR_LEN];
extern char LogFileName[MAX_STR_LEN];
extern bool DeleteLog;
extern char CompilOutDir[MAX_STR_LEN];

#endif