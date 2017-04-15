//---------------------------------------------------------------------------


#pragma hdrstop

#include "max_substr.h"

//---------------------------------------------------------------------------

#pragma package(smart_init)
//������������� ����������� ���������� �������� ��� ������������ �� ������
//������ ���������� ����� ���������
//�������� �������� ��� ���������� ������������ ����������� ������
//����� ���������� ���������� ��� ����������� ���������� ����� ���������

#define TREE_SIZE 5000000; //��������� ������ ������, ������� �� �������� ��� ������s

#include <iostream>
#include <cstring>
#include <string>
#include <fstream>

using namespace std;

//-----------------------------------------------------------

struct TNode;

//-----------------------------------------------------------

struct TEdge
{
  TNode* tonode;   //����, � ������� ��� �����
  int first, last; //��������� � �������� ������ �� �����
  TEdge *next;     //�������� �����
  TEdge() : tonode(NULL), next(NULL), first(0), last(0) {};
};

//-----------------------------------------------------------

struct TNode
{
  union
  {
    TNode *parent;
    TNode *link;
  };
  TEdge *edges;
  TNode() : link(NULL), edges(NULL), parent(NULL) {};
  TEdge* findEdge(const char c, const char *s);
};


TEdge* TNode::findEdge(const char c, const char *s)
{
  TEdge *edge = edges;
  while ( (edge!=NULL) && (s[edge->first]!=c) ) edge = edge->next;
  return edge;
}

//-----------------------------------------------------------

struct TSparseSuffix
{
  int k;
  int offs;
  TNode *v;        //��������� � ����� �������� ���������� �������
  int first, last; //��������� � �������� ������� �� �����. ���� first>last, ������� �����
  void nextSuffix(const char *s, const TNode *root);
  void nextSuffix2(const char *s, const TNode *root);
  void canonize(const char *s);
  void canonize2(const char *s);
  bool go(const char *s, char ch);
  TSparseSuffix(int k, int offs) { this->k=k; this->offs=offs; }
};

//�������� ��������� ������� (�.�. ������� ������� ��� ������ k ��������)
void TSparseSuffix::nextSuffix(const char *s, const TNode *root)
{
  if (v==root)
    first+=k;
  else
  {
    v = v->link;
    if (v==root)
    {
      //����� ������������� � ���������� ������, ��� ���
      //�� ����, ��� ��� ������ � ������ �� ���������� ������ k
      //������ ��������, � �� ������
      int delta = k - (first - offs) % k;
      if (delta != k) first += delta;
    }
  }
  canonize(s);
}

//�������� ��������� ������� (�.�. ������� ������� ��� ������ k ��������)
void TSparseSuffix::nextSuffix2(const char *s, const TNode *root)
{
  if (v==root)
    first+=k;
  else
  {
    v = v->link;
    if (v==root)
    {
      //����� ������������� � ���������� ������, ��� ���
      //�� ����, ��� ��� ������ � ������ �� ���������� ������ k
      //������ ��������, � �� ������
      int delta = k - (first - offs) % k;
      if (delta != k) first += delta;
    }
  }
  canonize2(s);
}

//�������� ������� � ������������� ���� ���� ���������� ������� �� �������
void TSparseSuffix::canonize(const char *s)
{
  if(first>last) return; //�������������� ������ - ����� �������
  //��� ���� ��� ���������� ����� �������� ����� �������� �� 1 ������ �� ���� ���������
  TEdge *edge = v->findEdge(s[first],s);
  while (edge->last - edge->first <= last - first)
  {
    v = edge->tonode;
    first += edge->last-edge->first+1;
    if (first>last)break;
    edge = v->findEdge(s[first],s);
  }
}

//�������� ������� � ������������������� ���� ���� ���������� ������� �� �������
void TSparseSuffix::canonize2(const char *s)
{
  if(first>last) {last = first-1; return;} //�������������� ������ - ����� �������
  //��� ���� ��� ���������� ����� �������� ����� �������� �� 1 ������ �� ���� ���������

  TEdge *edge = v->findEdge(s[first],s);
 
  while ((edge->last - edge->first <= last - first)&&(edge->tonode->link!=NULL))
  {
    v = edge->tonode;
    first += edge->last-edge->first+1;
    if (first>last)
    {
      break;
    }
    edge = v->findEdge(s[first],s);
  }
}

//������� �� ��������� ������, ���� ��� ��������
bool TSparseSuffix::go(const char *s, char ch)
{
  if (first>last)
  {
    //����� �������
    TEdge *edge = v->findEdge(ch,s);
    if (edge==NULL) return false;
    first = edge->first; //������ ������ �� ��������� �����
    last = first; //����� - �� �� �����
    canonize2(s);
  }
  else
  {
    //������� �������
    //���������, �� ����� �� �� � �����
    TEdge *edge = v->findEdge(s[first],s);
    if ((edge->last-edge->first == last-first) && (edge->tonode->link == NULL)) return false;
    if (s[last+1]!=ch) return false;
    last++;
    if(edge->tonode->link != NULL) canonize2(s);
  }
  return true;
}

//-----------------------------------------------------------

class TSparseSuffixTree
{
  const char *s;
  const int len;
  const int offs;
  const int k;
  int N;
  void out(ostream& os, const TNode * const node, int level) const;

  typedef TNode* PNode;

  //different temporary variables
  int __cur_len;

  //destruction
  void __delete(TNode *node);
  
public:

  TNode *root;

  ~TSparseSuffixTree(void);
  TSparseSuffixTree(const char *str, const int str_len, int str_k, int str_offs);
  friend ostream& operator<<(ostream& os, const TSparseSuffixTree& tree);
  int findString(const char * const s) const;
  bool selfTest(void);

};


void TSparseSuffixTree::__delete(TNode *node)
{
  if (node==NULL)return;
  TEdge *edge = node->edges;
  while(edge!=NULL)
  {
    __delete(edge->tonode);
    TEdge *t = edge;
    edge=edge->next;
    delete t;
  }
  delete node;
}

TSparseSuffixTree::~TSparseSuffixTree(void)
{
 __delete(root);
}

bool TSparseSuffixTree::selfTest(void)
{
  for (int i=0; i<len;i++)
  {
    if ( (i<offs) || ( (i-offs) % k != 0 ) )
    {
       //�� ������ �������
       if (findString(s+i)==i) 
       {
         cout << "found extra string " << s+i << endl;
         //return false;
       }
    }
    else
    {
       //������ �������         
         if (findString(s+i)!=i) 
         {
           cout << "string not found " << s+i << endl;
           //return false;
         }
    }
  }
  return true;
}

int TSparseSuffixTree::findString(const char * const p) const
{
  if ((p==NULL)||(root==NULL)) return -1;
  const char* c = p;
  TNode* node = root;
  for(;;)
  {
     TEdge* e = node->findEdge(c[0],s);
     if (e==NULL) return -1;
     int j;
     for(j=e->first; (j<=e->last)&&(c[0]!=0); j++,c++) if (s[j]!=c[0]) return -1;
     if (c[0]==0) return j-strlen(p);
     node = e->tonode;
  }
}

void TSparseSuffixTree::out(ostream& os, const TNode * const node, int level=0) const
{
   if (node==NULL) return;
   TEdge* edge = node->edges;
   while (edge!=NULL)
   {
      int i;
      for(i=0;i<level;i++) os << ' ';
      os << '|';
      for(i=edge->first;i<=edge->last;i++) os << s[i];
      os << endl;
      out(os, edge->tonode, level+(edge->last-edge->first+2));
      edge = edge->next;
   }
}

ostream& operator<<(ostream& os, const TSparseSuffixTree& tree)
{
   tree.out(os,tree.root);
   return os;
}

TSparseSuffixTree::TSparseSuffixTree(const char *str, const int str_len, int str_k, int str_offs) : s(str), len(str_len), k(str_k), offs(str_offs)
{

  root = new TNode;
  N=1;
  TSparseSuffix sfx(k, offs);
  sfx.v = root;
  sfx.first = offs;
  TNode *prev = NULL;

  //���� �� �������, �� ������� ������������� ����������� ��������
  for(int i=offs; i<len; i++)
  {
    sfx.last = i-1; //��� ������������� ���������� ��������
    sfx.canonize(s);

    //��������� �����������
    while(sfx.first <= sfx.last+1)
    {
      //��������� ������� i-�� �������
      if (sfx.first > sfx.last)
      {

        //----------����� �������----------
        TEdge *edge = sfx.v->findEdge(s[i],s);
        if (edge!=NULL)
        {
          //��� ���� ����� ������ - ����������� �����������
          //first �� ������, �.�. ��������, ��� ����� �����
          //���������� ���� ������� ����� ��������

          //������ ���������� �����
          if (prev!=NULL) {prev->link = sfx.v; prev = NULL;}
          break; //����������� �����������
        }
        else
        {
          //������ ����� ���� �� ������������ �������
          TNode *new_leaf = new TNode;
          N++;
          TEdge *new_edge = new TEdge;
          new_edge->tonode = new_leaf;
          new_edge->first = i;
          new_edge->last = len-1;
          new_edge->next = sfx.v->edges;
          sfx.v->edges = new_edge;
          //������ ���������� �����
          if (prev!=NULL) {prev->link = sfx.v; prev = NULL;}
          //��������� � ���������� �������
          sfx.nextSuffix(s,root);
        }

      }
      else
      {
        //----------������� �������----------
        TEdge *edge = sfx.v->findEdge(s[sfx.first],s);
        if (s[edge->first + (sfx.last-sfx.first) + 1] == s[i])
        {
          //��� ���� ����� ������ - ����������� �����������
          //first �� ������, �.�. ��������, ����� ����� ����������
          //���� ������� ����� ��������

          //������ ���������� �����
          if (prev!=NULL) {prev->link = sfx.v; prev = NULL;}
          break;  //����������� �����������
        }
        else
        {
          //������ ����� ���������� ������� � ����� ����
          TNode *new_leaf = new TNode;
          N++;
          TNode *new_ver = new TNode;
          N++;
          TEdge *new_edge = new TEdge;
          TEdge *new_edge_leaf = new TEdge;
          new_edge->tonode = edge->tonode;
          edge->tonode = new_ver;
          new_ver->edges = new_edge;
          new_edge->next = new_edge_leaf;
          new_edge_leaf->tonode = new_leaf;
          new_edge->first = edge->first + (sfx.last-sfx.first) + 1;
          new_edge->last = edge->last;
          edge->last = edge->first + (sfx.last-sfx.first);
          new_edge_leaf->first = i;
          new_edge_leaf->last = len-1;
          //������ ���������� ����� �� ����� ��������� �������
          if (prev!=NULL) prev->link = new_ver;
          //�� ���� �� ������� ����� ����� ������� ���������� �����
          prev = new_ver;
          //��������� � ���������� ��������
          sfx.nextSuffix(s,root);
        }
      }

    }

  }

}

//---------------------------------------------------------------------------

bool check(const char *p, const char *t, int i, int msi)
{
  char buf [1000];
  t = t + i;
  strncpy(buf,t,msi);
  buf[msi]=0;
  int result = false;
  if (strstr(p,buf)!=NULL)
    result = true;
  else
    cout << "Wrong: " << i << endl;
  return result;
}

const int BUFSIZE = 1048576;
char buf[BUFSIZE];

int find_max_substr(char *s1, int len1,char *s2, int len2, int *offset1, int *offset2)
{
  s1[len1++]='$';
  s2[len2++]='$';
  s1[len1]=0;
  s2[len2]=0;

  int *ms = new int[len2];
  memset(ms,-1,sizeof(int)*len2);

  //���������� k ���, ����� ������ ������� � ������
  int k=(2*sizeof(TNode)+6*sizeof(TEdge))*len1/TREE_SIZE;
  if(k==0) k=1;

  //���������� ������ ������
  for(int offs=0; offs<k; offs++) {
    TSparseSuffixTree *tree = new TSparseSuffixTree(s1, len1, k, offs);

    //���������� ������ ������� �������� � ms, � �������� �������� ��������������
    for(int t1=0; t1<k; t1++) {
      TSparseSuffix sfx(k, offs);
      sfx.v = tree->root;
      sfx.first = offs;  //� ��������� ������ - ������ ������ ������
      sfx.last = offs-1; //����� �������. � ��������� ������ �� ������������� ������

      //������� ms[t1]
      int tc=t1;
      int j=0;
      while(tc+j<len2) {
        if(!sfx.go(s1,s2[tc+j]))break;
        j++;
      }
      if (tc+j==len2) j--;
      ms[tc] = (ms[tc]<j) ? j : ms[tc];

      //������� �� ���������, ��������� ������ �� ��������
      tc+=k;
      while (tc<len2) {
        sfx.nextSuffix2(s1,tree->root);
        j-=k;
        if (j<0) j=0;
        while(tc+j<len2) {
          if(!sfx.go(s1,s2[tc+j]))break;
          j++;
        }
        if (tc+j==len2) j--;
        ms[tc] = (ms[tc]<j) ? j : ms[tc];
        tc+=k;
      }
    }
    delete tree;
  }

  int i_max=0,res,i;
  char ch,*s3;

  for (i=1; i<len2; i++)
     if (ms[i]>ms[i_max])
        i_max=i;

  res=ms[i_max];
  *offset2=i_max;

  ch=s2[*offset2+res];
  s2[*offset2+res]=0;
  s3=strstr(s1,*offset2+s2);
  *offset1=s3-s1;
  s2[*offset2+res]=ch;

  delete[] ms;

  return res;
}

int find_common_substr_x(const char *s1, int len1, const char *s2, int len2, int k)
{
   char *t_s1,*t_s2;
   int i_cnt=0,com_str,i,i1,i2;

   t_s1=new char[len1+2];
   t_s2=new char[len2+2];

   memmove(t_s1,s1,len1);
   memmove(t_s2,s2,len2);

  //��������� ������������ ������
  for(i=0; i<len1; i++)
    switch (t_s1[i]) {
       case '#': t_s1[i]='~'; break;
       case '$': t_s1[i]='!'; break;
       case  0 : t_s1[i]='@';
    }

  for(i=0; i<len2; i++)
    switch (s2[i]) {
       case '#': t_s2[i]='~'; break;
       case '$': t_s2[i]='!'; break;
       case  0 : t_s2[i]='@';
    }

   while(len1>0 && len2>0) {
      //������� ����� ���������� ����� ���������
      com_str=find_max_substr(t_s1,len1,t_s2,len2,&i1,&i2);
      if (com_str<k) break;
      i_cnt+=com_str;

      //������� ��� ��������� �� ����� �����
      for (i=i1+com_str;i<len1;i++)
         t_s1[i-com_str]=t_s1[i];
      for (i=i2+com_str;i<len2;i++)
         t_s2[i-com_str]=t_s2[i];
      len1-=com_str;
      len2-=com_str;
   }

   delete[] t_s1;
   delete[] t_s2;

   return i_cnt;
}

//---------------------------------------------------------------------------

