#include <iostream.h>
#include <dos.h>

int N, M, NM;

int **field, I;

int isWin(const int, const int);
int isEndGame();
int Count = 0;//количество заполненых клеток (сделанных ходов)

FILE *f = NULL;

int ReadMove()
{
   int x, y;

   cin >> x >> y;
   field[x][y] = 3 - I;
   Count++;

   if(f)
   {
      fprintf(f, "Получен ход: (%d,%d)=%d\n", x, y, (3-I));
      fflush(f);
   }
    
   return isEndGame();
}

int WriteMove()
{
   int x, y, k;
   
   //нада действовать проще :) - рандомом
   k = random(NM - Count) + 1;
   
   if(f)
   {
      fprintf(f, "k=%d\n", k);
      fflush(f);
   }
   
   for(x = 1; x <= N; x++)
   for(y = 1; y <= M; y++)
   {
      if(field[x][y] == 0) k--;
      if(k == 0)
      {
         cout << x << ' ' << y << endl;
         field[x][y] = I;
         Count++;
         
         if(f)
         {
            fprintf(f, "Сделан ход:  (%d,%d)=%d\n", x, y, I);
            fflush(f);
         }
         return isEndGame();
      }
   }

   return isEndGame();
}


int main()
{
   int x, y;

   char s[] = "D:\\plr_!.out";

   cin >> N >> M >> s[7];
   if(s[7] == '0') I = 2; else I = 1;
   //f = fopen(s, "w+");

   if(f)
   {
      fprintf(f, "Размеры поля: %dx%d\n\n", N, M);
      fflush(f);
   }
   NM = N * M;
   srand(time(NULL));
   
   field = new int*[N+1];
   for(x = 0; x <= N; x++)
      field[x] = new int[M+1];

   for(x = 0; x <= N; x++)
   for(y = 0; y <= M; field[x][y++] = 0);

   if(f)
   {
      fprintf(f, "Game begin...\n");
      fflush(f);
   }
   if(1 == I)
   {
      x = (N+1) / 2;
      y = (M+1) / 2;
      field[x][y] = I;
      Count++;
      cout << x << ' ' << y << endl;
      if(f)
      {
         fprintf(f, "!Сделан ход: (%d,%d)=%d\n", x, y, I);
         fflush(f);
      }
   }
   
   for( ; !(ReadMove() || WriteMove()); );

   if(f)
   {
      fprintf(f, "Game end...");
      fflush(f);
      fclose(f);
   }
   for(x = 0; x <= N; x++)
      delete [] field[x];
   delete [] field;
   return 0;
}


//=====================================
int isWin(const int z, const int t = 5)
{
   int i, j, k, u;

   //по горизонтали
   for(i = 1; i <= N; i++)
   for(j = 1; j+t < M; j++)
   {
      if(field[i][j] == z)
      {
         for(u = 1; u < t; u++)
         {
            if(field[i][j+u] != z) break;
         }
         if(u >= t) return 1;
      } 
   }

   //по вертикали
   for(j = 1; j <= M; j++)
   for(i = 1; i+t < N; i++)
   {
      if(field[i][j] == z)
      {
         for(u = 1; u < t; u++)
         {
            if(field[i+u][j] != z) break;
         }
         if(u >= t) return 1;
      } 
   }

   //главная диагональ
   for(i = 1; i+t < N; i++)
   for(j = 1; j+t < M; j++)
   {
      if(field[i][j] == z)
      {
         for(u = 1; u < t; u++)
         {
            if(field[i+u][j+u] != z) break;
         }
         if(u >= t) return 1;
      }
   }

   //побочная диагональ
   for(i = 1; i+t < N; i++)
   for(j = t; j <= M; j++)
   {
      if(field[i][j] == z)
      {
         for(u = 1; u < t; u++)
         {
            if(field[i+u][j-u] != z) break;
         }
         if(u >= t) return 1;
      }
   }

   return 0;
}

//  0 - игра продолжается
//  1 - победа первого игрока
//  2 - победа второго игрока
// -1 - поле заполнено
// иначе - что-то не так...
int isEndGame()
{
   static int stat = 0;

   if(stat) return stat;
  
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
   for(int i = 1; i <= N; i++)
   for(int j = 1; j <= M; j++)
   if(field[i][j] == 0)
   {
      stat = 0;
      return stat;
   }

   return stat;
}