
#ifndef result_idH
#define result_idH

//постоянные результаты
#define RS_ACCEPTED 0
#define RS_WRONG_ANSWER 1
#define RS_PRESENTATION_ERROR 2
#define RS_RUN_TIME_ERROR 3
#define RS_TIME_LIMIT 4
#define RS_MEMORY_LIMIT 5
#define RS_SECURITY_VIOLATION 6
#define RS_COMPILATION_ERROR 7
#define RS_SLEEP_DETECT 8
#define RS_UNIQUE_ERROR 9

//временные результаты
#define RS_WAITING 100
#define RS_COMPILING 101
#define RS_RUNING 102

//сообщения для проверяющего сервера
#define WM_SEND_PROBLEM 128943
#define WM_EXIT_MM 128944
#define WM_DATA_SUBMIT_ERR 128945
#define WM_RESCAN_DB 128946

//проверка правильности данных посылки
#define SUBMIT_OK 0
#define SUBMIT_NO_AUTHOR 1
#define SUBMIT_NO_PROBLEM 2
#define SUBMIT_NO_COMPILER 3

//отчеты по ходу проверки решения
#define RPT_COMPILER_OUTPUT 1
#define RPT_INPUT 2
#define RPT_TEST_OUTPUT 3
#define RPT_CORRECT_OUTPUT 4
#define RPT_TEST_ERROR 5
#define RPT_CHECKER_OUTPUT 6
#define RPT_PLAGIAT_OUTPUT 7

#define ID_THREAD "id_thread.txt"
#define REPLACE_ID "$(id)"

#define MAX_CONTENT_LENGTH (512 * 1024)

#define EXIT_CODE_SECURITY_VIOLATION 5624897

#endif
