/* -*- mode: c -*- */
/* $Id: chkutil.h,v 1.1 2003/07/18 16:00:23 cher Exp $ */

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <ctype.h>

enum
{
  RUN_OK               = 0,
  RUN_COMPILE_ERR      = 1,
  RUN_RUN_TIME_ERR     = 2,
  RUN_TIME_LIMIT_ERR   = 3,
  RUN_PRESENTATION_ERR = 4,
  RUN_WRONG_ANSWER_ERR = 5,
  RUN_CHECK_FAILED     = 6
};

void fatal(int code, char const *format, ...)
     __attribute__ ((noreturn, format(printf, 2, 3)));

void fatal(int code, char const *format, ...)
{
  va_list args;

  va_start(args, format);
  vfprintf(stderr, format, args);
  va_end(args);
  fprintf(stderr, "\n");
  exit(code);
}

void fatal_CF(char const *format, ...)
     __attribute__ ((noreturn, format(printf, 1, 2)));
void fatal_CF(char const *format, ...)
{
  va_list args;

  va_start(args, format);
  vfprintf(stderr, format, args);
  va_end(args);
  fprintf(stderr, "\n");
  exit(RUN_CHECK_FAILED);
}

void fatal_PE(char const *format, ...)
     __attribute__ ((noreturn, format(printf, 1, 2)));
void fatal_PE(char const *format, ...)
{
  va_list args;

  va_start(args, format);
  vfprintf(stderr, format, args);
  va_end(args);
  fprintf(stderr, "\n");
  exit(RUN_PRESENTATION_ERR);
}

void fatal_WA(char const *format, ...)
     __attribute__ ((noreturn, format(printf, 1, 2)));
void fatal_WA(char const *format, ...)
{
  va_list args;

  va_start(args, format);
  vfprintf(stderr, format, args);
  va_end(args);
  fprintf(stderr, "\n");
  exit(RUN_WRONG_ANSWER_ERR);
}
