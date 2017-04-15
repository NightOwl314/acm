
#include <iostream.h>
#include <stdlib.h>
#include <stdio.h>

//---------------------------------------------------------------------------
int main(int argc, char* argv[])
{
  int n;
  cin>>n;
  float Sum;
  float max=0,min=600000,h;
  int i;
  for(i=0;i<n;i++)
    {
      cin>>h;
      if(h>max)
      {
	max=h;
      }
      if(h<min)
      {
	min=h;
      }
      Sum=Sum+h;
    }
  Sum=(Sum-max-min)/n;
  cout.precision(3);
  cout<<Sum;
  return 0;
}
