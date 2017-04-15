import java.io.*;
import java.util.*;

public class Main
{
   public static void main(String[] args)
   {
      StreamTokenizer in = new StreamTokenizer(new BufferedReader(new InputStreamReader(System.in)));
      PrintWriter out = new PrintWriter(new OutputStreamWriter(System.out));

      try{
        in.nextToken();
        int a = (int) in.nval;
        in.nextToken();
        int b = (int) in.nval;
        out.println(a + b);
        out.flush();

      }
      catch (IOException e) {
        throw new Error();
      }
 
   }
}
