//
// Written by Fyodor Menshikov 24.03.2007
// 7:31-7:50
//

import java.io.*;
import java.util.*;

public class jrun {

   StreamTokenizer in;
   PrintWriter out;

   jrun() {

         in = new StreamTokenizer(new BufferedReader(new InputStreamReader(System.in)));
         out = new PrintWriter(new OutputStreamWriter(System.out));      
         in.whitespaceChars(':', ':');      
   }

   void asserT(boolean e) {
      if (!e) {
         throw new Error();
      }
   }

   int nextInt() {
      try {
         in.nextToken();
         asserT(in.ttype == in.TT_NUMBER);
         return (int)in.nval;
      } catch (IOException e) {
         throw new Error();
      }
   }

   int n;
   int cap[][];
   int source;
   int sink;

   void maxFlow() {
      int height[] = new int[n];
      Arrays.fill(height, 1);
      height[source] = n - 1;
      height[sink] = 0;
      int excess[] = new int[n];
      LinkedList<Integer> queue = new LinkedList<Integer>();
      for (int i = 0; i < n; i++) {
         if (cap[source][i] > 0) {
            int d = cap[source][i];
            cap[source][i] -= d;
            cap[i][source] += d;
            excess[i] = d;
            excess[source] -= d;
            queue.add(i);
         }
      }
      while (queue.size() > 0) {
         int cur = queue.poll();
         while (true) {
            for (int i = 0; i < n; i++) {
               if (height[cur] == height[i] + 1 && cap[cur][i] > 0) {
                  int d = Math.min(excess[cur], cap[cur][i]);
                  cap[cur][i] -= d;
                  cap[i][cur] += d;
                  excess[cur] -= d;
                  if (excess[i] == 0 && i != source && i != sink) {
                     queue.add(i);
                  }
                  excess[i] += d;
                  if (excess[cur] == 0) {
                     break;
                  }
               }
            }
            if (excess[cur] == 0) {
               break;
            }
            height[cur]++;
         }
      }
   }

   void run() {
      int n_lectors = nextInt();
      int students_need[] = new int[n_lectors];
      for (int i = 0; i < n_lectors; i++) {
         students_need[i] = nextInt();
      }
      int start_time[] = new int[n_lectors];
      int end_time[] = new int[n_lectors];
      for (int i = 0; i < n_lectors; i++) {
         start_time[i] = nextInt() * 60 + nextInt();
         end_time[i] = nextInt() * 60 + nextInt();
      }
      int walk_time[][] = new int[n_lectors][n_lectors];
      for (int i = 0; i < n_lectors; i++) {
         for (int j = 0; j < n_lectors; j++) {
            walk_time[i][j] = nextInt();
         }
      }
      n = n_lectors * 2 + 2;
      source = n_lectors * 2;
      sink = n_lectors * 2 + 1;
      cap = new int[n][n];
      final int INF = 1000000;
      for (int i = 0; i < n_lectors; i++) {
         cap[sink][i] = INF;
         cap[i][sink] = students_need[i];
         cap[i][i + n_lectors] = INF;
         cap[i + n_lectors][i] = 0;
         cap[i + n_lectors][source] = INF;
         cap[source][i + n_lectors] = students_need[i];
         for (int j = 0; j < n_lectors; j++) {
            if (end_time[i] + walk_time[i][j] <= start_time[j]) {
               cap[i + n_lectors][j] = INF;
               cap[j][i + n_lectors] = 0;
            }
         }
      }
      maxFlow();
      int ans = 0;
      for (int i = 0; i < n_lectors; i++) {
         ans += cap[i][sink];
      }
      out.println(ans);
      out.close();
   }

   public static void main(String args[]) {
      new jrun().run();
   }
}