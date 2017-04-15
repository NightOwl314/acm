// written by kamanoff
// ����� ��� xo
// ��� ������ ������� ������ ���� ����� �������

#include <iostream>
#include <string.h>

using namespace std;

// ������� ���� �������� N x M
const int N = 11;
const int M = 11;
const int szbuf = 2048;

// ���������� ���� ���������� � 1
short field[N+2][M+2];

int K;//����� ������

char buf[szbuf], *s;

void ClearBuf()
{
   //memset(buf, szbuf, 0);
   for(int i = 0; i < szbuf; buf[i++] = 0);
}

int point1, point2;//����� �������
int st[3];//��������� �������
int count_ok1, count_ok2, count_err1, count_err2;//���������� ������ � ��������� �������
int x, y;//���������� ����������

FILE *f = NULL;

// ��������� ������
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


int status = st_ok;

//��������: � ���� ���� t ������ ������ �������� z
//�� ���������, ����������� ��� ���������
int isWin(const int z, const int t = 5)
{
   int i, j, u;

   //�� �����������
   for(i = 1; i <= N; i++)
   for(j = 1; j+t < M; j++)
   {
      if(field[i][j] == z)
      {
         for(u = 1; u < t; u++)
         {
            if(field[i][j+u] != z) break;
         }
         if(u >= t)
         {
            field[i][j] = 3;
            if(f) fprintf(f, "!!! ������� ���������� �� ����������� (%d, %d)\n", i, j);
            if(f) fflush(f);
            return 1;
         }
      } 
   }

   //�� ���������
   for(j = 1; j <= M; j++)
   for(i = 1; i+t < N; i++)
   {
      if(field[i][j] == z)
      {
         for(u = 1; u < t; u++)
         {
            if(field[i+u][j] != z) break;
         }
         if(u >= t)
         {
            field[i][j] = 3;
            if(f) fprintf(f, "!!! ������� ���������� �� ��������� (%d, %d)\n", i, j);
            if(f) fflush(f);
            return 1;
         }
      } 
   }

   //������� ���������
   for(i = 1; i+t < N; i++)
   for(j = 1; j+t < M; j++)
   {
      if(field[i][j] == z)
      {
         for(u = 1; u < t; u++)
         {
            if(field[i+u][j+u] != z) break;
         }
         if(u >= t)
         {
            field[i][j] = 3;
            if(f) fprintf(f, "!!! ������� ���������� �� ������� ��������� (%d, %d)\n", i, j);
            if(f) fflush(f);
            return 1;
         }
      }
   }

   //�������� ���������
   for(i = 1; i+t < N; i++)
   for(j = t; j <= M; j++)
   {
      if(field[i][j] == z)
      {
         for(u = 1; u < t; u++)
         {
            if(field[i+u][j-u] != z) break;
         }
         if(u >= t)
         {
            field[i][j] = 3;
            if(f) fprintf(f, "!!! ������� ���������� �� �������� ��������� (%d, %d)\n", i, j);
            if(f) fflush(f);
            return 1;
         }
      }
   }

   return 0;
}

//  0 - ���� ������������
//  1 - ������ ������� ������
//  2 - ������ ������� ������
// -1 - ���� ���������
// ����� - ���-�� �� ���...
int isEndGame()
{
   static int stat = 0;

   if(stat) return stat;
  
   //���� ������� ��������
   if(isWin(1))
   {
      stat = 1;
      return stat;
   }

   if(isWin(2))
   {
      stat = 2;
      return stat;
   }

   stat = -1;
   for(int i = 1; (i <= N) && (stat == -1); i++)
   for(int j = 1; (j <= M) && (stat == -1); j++)
   if(field[i][j] == 0)
   {
      stat = 0;
      return stat;
   }

   if(stat == -1)
   {
      if(f) fprintf(f, "���� ���������\n");
      if(f) fflush(f);
   }

   return stat;
}


int check_move(char *s, int k)
{
   if(!s[0]) return st_presentation_error;//����� ������ ����

   // ���������� ���������� x
   x = 0;
   while(s[0] && ((*s == ' ') || (*s == '\n') || (*s == '\r') || (*s == '\t')) ) s++;
   if(!s[0]) return st_presentation_error;
   while(s[0] && (*s >= '0') && (*s <= '9'))
   {
      x = 10 * x + int(*s) - int('0');
      s++;
      if(x > N) return st_presentation_error;
   }

   if(f) fprintf(f, " [x=%d] \n", x);
   if(f) fflush(f);

   // ���������� ���������� y
   y = 0;
   while(s[0] && ((*s == ' ') || (*s == '\n') || (*s == '\r') || (*s == '\t')) ) s++;
   while(s[0] && (*s >= '0') && (*s <= '9'))
   {
      y = 10 * y + int(*s) - int('0');
      s++;
      if(y > M) return st_presentation_error;
   }

   if(f) fprintf(f, " [y=%d] \n", y);
   if(f) fflush(f);

   if((x <= 0) || (y <= 0)) return st_presentation_error;

   //���� ���� ��� ���-�� � ������ ������
   while(s[0] && ((*s == ' ') || (*s == '\n') || (*s == '\r') || (*s == '\t')) ) s++;
   if(s[0]) return st_presentation_error;

   //�������� �� ������ �� ��� ������
   if(field[x][y]) return st_wrong_move;

   if(f) fprintf(f, " field[%d][%d]=%d ", x, y, field[x][y]);
   if(f) fflush(f);

   //��� �������� �������� - ��
   field[x][y] = k;

   return st_ok;
}

int main()
{
   int ok = 1;
   //f = fopen("D:\\xo.out", "w+");

   //�������� ����
   for(int i = 0; i < N; i++)
   for(int j = 0; j < M; j++)
     field[i][j] = 0;

   //��������� ���-�� �������
   ClearBuf();
   cin.getline(buf, 1024);
   K = int(buf[0]) - int('0');
   if(f) fprintf(f, "k = %d\n", K);
   if(f) fflush(f);
   if(K != 2) return 1;

   //������ ���: �������� ������� ���� ���� ������� � ����� ������
   cout << 1 << endl;//���-�� ����� ����� �������������
   cout << N << ' ' << M << endl;//����� ���� - 1 ������
   cout << 'X' << endl;//���� ������� ������
   cout << '0' << endl;//���� ������� ������

   st[1] = st[2] = st_ok;//���������� ��� ��
   for(K = 1; ok; K = 3 - K) //������ ����� ���������
   {
      ClearBuf();
      cin.getline(buf, 1024);//��������� ��� ������
      if(f) fprintf(f, "\n[%d] '%s'\n", K, buf);
      if(f) fflush(f);
      status = (int)buf[0];//�������� ������
      s = buf + 2;//����� ��� ������
      switch(status)
      {
      case st_ok:
        //������ ���
        if(f) fprintf(f, "s=[%s]\n", s);
        if(f) fflush(f);
        st[K] = check_move(s, K);//��������� ���
        if(f) fprintf(f, "   (%c)\n", char(st[K]));
        if(f) fflush(f);
        if((st[K] != st_ok) || isEndGame()) //������ ������ ��� ������ ������ ��� ������� ���� ���������
        {
           cout << char(st_end_ok) << endl;//���������� ����
           ok = 0;
        }
        else cout << char(st_ok_give_all) << ' ' << (3 - K) << endl;//�������� ��� ���������� ������
        break;

      default:
        //���� ������ - ���������� ����
        st[K] = ((status < st_max_error) && (status > st_min_error)) ? status : st_run_time_error;
        cout << char(st_end_error) << endl;
        ok = 0;
        break;
      }
   }

   if(f) fprintf(f, "\n");
   for(x = 1; x <= N; x++)
   {
      for(y = 1; y <= M; y++)
      {
         switch (field[x][y])
         {
            case 1:
               if(f) fprintf(f, "x"); 
               break;

            case 2:
               if(f) fprintf(f, "o"); 
               break;
           
            case 3:
               if(f) fprintf(f, "@"); 
               break; 

            default:
               if(f) fprintf(f, " "); 
               break; 
         }
         if(f) fflush(f);       
      }
      if(f) fprintf(f, "\n");
      if(f) fflush(f);
   }
   if(f) fprintf(f, "\n");

   //��������� ������ �� ������: ������, ���-�� ������� �������, ���-�� ��������� ������� 
   ClearBuf();
   cin.getline(buf, 1024);
   status = buf[0];
   count_ok1 = int(buf[2]) - int('0');
   count_err1 = int(buf[4]) - int('0');
   status = ((status < st_max_error) && (status > st_min_error)) ? status : st[1];
   st[1] = status > st[1] ? status : st[1];

   if(f) fprintf(f, "\n1. %c %d %d\n\n", char(status), count_ok1, count_err1);
   if(f) fflush(f);

   ClearBuf();
   cin.getline(buf, 1024);
   status = buf[0];
   count_ok2 = int(buf[2]) - int('0');
   count_err2 = int(buf[4]) - int('0');
   status = ((status < st_max_error) && (status > st_min_error)) ? status : st[2];
   st[2] = status > st[2] ? status : st[2];

   if(f) fprintf(f, "\n2. %c %d %d\n\n\n", char(status), count_ok2, count_err2);
   if(f) fflush(f);

   //������� ��� ������� ������: ������, �����, ����
   if((st[1] != st_ok) || (st[2] != st_ok))
   {
      if(f) fprintf(f, "{1} %c\n{2} %c\n", char(st[1]), char(st[2]));
      if(f) fflush(f);

      if(st[1] != st_ok)
      {
         cout << char(st[1]) << ' ' << 2 << ' ' << 0 << endl;
      }
      else
      {
         point1 = 5000 - 20 * count_err1 - 10 * count_ok1;
         if(point1 < 0) point1 = 0;
         cout << char(st[1]) << ' ' << 1 << ' ' << point1 << endl;
      }

      if(st[2] != st_ok)
      {
         cout << char(st[2]) << ' ' << 2 << ' ' << 0 << endl;
      }
      else
      {
         point2 = 5000 - 20 * count_err2 - 10 * count_ok2;
         if(point2 < 0) point2 = 0;
         cout << char(st[2]) << ' ' << 1 << point2 << endl;
      }
      if(f) fclose(f);
      return 0;
   }

   if(f) fprintf(f, "... end ...");
   if(f) fflush(f);
   
   //������������ ��������� �����
   switch (isEndGame())
   {
      case 1:
         point1 = 5000;
         point2 = 2000;
         break;

      case 2:
         point1 = 2000;
         point2 = 5000;
         break;

      default:
         point1 = 2000;
         point2 = 2000;
         break;
   }

   //������������� � ������ ���������� �������
   point1 -= 20 * count_err1 + 10 * count_ok1;
   point2 -= 20 * count_err2 + 10 * count_ok2;

   if(point1 < 0) point1 = 0;
   if(point2 < 0) point2 = 0;

   //������ ������: ������ ����� ����
   //������ � ����� �� ������ �������
   if(point1 > point2)
   {
      cout << char(st[1]) << ' ' << 1 << ' ' << point1 << endl;
      cout << char(st[2]) << ' ' << 2 << ' ' << point2 << endl;
   }
   else
   {
      cout << char(st[1]) << ' ' << 2 << ' ' << point1 << endl;
      cout << char(st[2]) << ' ' << 1 << ' ' << point2 << endl;
   }

   if(f) fclose(f);
   return 0;//the end :)
}