//����������� ����� �������� ����� �� ����� k, ������������ � ����� ����������

#include <iostream>
#include "com_substr_cnt.h"

using namespace std;

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
  TNode *link;
  TEdge *edges;
  TNode() : link(NULL), edges(NULL) {};
  TEdge* findEdge(const char c, const char *s);
};

TEdge* TNode::findEdge(const char c, const char *s)
{
  TEdge *edge = edges;
  while ( (edge!=NULL) && (s[edge->first]!=c) ) edge = edge->next;
  return edge;
}

//-----------------------------------------------------------

struct TSuffix
{
  TNode *v;        //��������� � ����� �������� ���������� �������
  int first, last; //��������� � �������� ������� �� �����. ���� first>last, ������� �����
  void nextSuffix(const char *s, const TNode *root);
  void TSuffix::canonize(const char *s);
};

//�������� ��������� ������� (�.�. ������� ������� ��� ������� �������)
void TSuffix::nextSuffix(const char *s, const TNode *root)
{
  if (v==root) first++; else v = v->link;
  canonize(s);
}

//�������� ������� � ������������� ���� ���� ���������� ������� �� �������
void TSuffix::canonize(const char *s)
{
  if(first>last) return; //�������������� ������ - ����� �������
  TEdge *edge = v->findEdge(s[first],s);
  while (edge->last - edge->first <= last - first)
  {
    v = edge->tonode;
    first += edge->last-edge->first+1;
    if (first>last) break;
    edge = v->findEdge(s[first],s);
  }
}

//-----------------------------------------------------------

class TSuffixTree
{
  const char *s;
  const int len;
  TNode *root;
  void out(ostream& os, const TNode * const node, int level) const;
public:
  TSuffixTree(const char *str, const int str_len);
  friend ostream& operator<<(ostream& os, const TSuffixTree& tree);
  int findString(const char * const s) const;
  bool selfTest(void);

  friend class TComStr;

};

bool TSuffixTree::selfTest(void)
{
  for (int i=0; i<len;i++)
  {
    if (findString(s+i)!=i) return false;
  }
  return true;
}

int TSuffixTree::findString(const char * const p) const
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

void TSuffixTree::out(ostream& os, const TNode * const node, int level=0) const
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

ostream& operator<<(ostream& os, const TSuffixTree& tree)
{
   tree.out(os,tree.root);
   return os;
}

TSuffixTree::TSuffixTree(const char *str, const int str_len) : s(str), len(str_len)
{
  root = new TNode;
  TSuffix sfx;
  sfx.v = root;
  sfx.first = 0;
  TNode *prev = NULL;

  //���� �� �������, �� ������� ������������� ����������� ��������
  for(int i=0; i<len; i++)
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
          TNode *new_ver = new TNode;
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

struct TComStr
{

private:

  int k; //����� ���������, ������� �� �������������
  char *s1, *s2; //�������� ���������
  int len1,len2;
  char *s; //�� ������������
  TSuffixTree *tree; //���������� ������

  int cnt1,cnt2; //��������������� ��������
  int all_cnt;   //������� ����� ��������� ����� ��������

  //����������� ����� ������, ������������� ������� k
  void k_dfs(TNode *node, int cur_height);

  //����������� ����� ���������, ��� �������� ����� ���������� ����������
  //��������� � ��� ���������
  void rest_dfs(TNode *node, int cur_height);

public:

  //����������� ����� �������� ����� �� ����� k, ������������ � ����� ����������
  int TComStr::com_substr_cnt(char *_s1, int _len1, char *_s2, int _len2, int _k);

};

void TComStr::rest_dfs(TNode *node, int cur_height)
{
  TEdge *edge = node->edges;
  if(edge==NULL)
  {
    //����������, � ������ ��������� ��������� ���� ����
    if (cur_height <= len2+1) cnt2++; else cnt1++;
  }
  else
    while (edge!=NULL)
    {
       rest_dfs(edge->tonode, cur_height + edge->last - edge->first + 1);
       edge = edge->next;
    }
}

void TComStr::k_dfs(TNode *node, int cur_height)
{
  //��� ������ ������ � �������, ���������� �� ������� �� ����� >= k,
  //������� ��� ��������� � ������� ���������� ��������� � ������ � ������
  //��������. �� ��� �������� ���������� � ���������� � ����� �����������.
  if (cur_height>=k)
  {
    int inc;
    cnt1 = cnt2 = 0;
    rest_dfs(node, cur_height);
    inc=(cnt1 < cnt2) ? cnt1 : cnt2;
    all_cnt += inc;
    if (cur_height==k && inc==1) all_cnt += k-1;
  }
  else
  {
    TEdge * edge = node->edges;
    while (edge != NULL)
    {
      k_dfs(edge->tonode, cur_height + edge->last - edge->first + 1);
      edge = edge->next;
    }
  }
}


//����������� ����� �������� ����� �� ����� k, ������������ � ����� ����������
int TComStr::com_substr_cnt(char *_s1, int _len1, char *_s2, int _len2, int _k)
{
  s1 = _s1; s2 = _s2; len1 = _len1; len2 = _len2; k = _k;

  //������� ������ ���������� ���������� ������ ��� ����� ��������
  s = new char[len1+len2+2];
  memcpy(s,s1,len1);
  s[len1] = '#';
  memcpy(s+len1+1,s2,len2);
  s[len1+1+len2] = '$';
  tree = new TSuffixTree(s, len1+len2+2);

  //������ ��������� ���������� ����� ������
  all_cnt = 0;
  k_dfs(tree->root, 0);

  delete tree;
  delete [] s;

  return all_cnt;
}

//---------------------------------------------------------------------------

const int BUFSIZE = 1048576;
char buf[BUFSIZE];

int find_common_substr(char *s1, int len1,char *s2, int len2, int k)
{

  //��������� ������������ ������

  int i;
  for(i=0; i<len1; i++)
  {
    if (s1[i]=='#') s1[i]='~';
    if (s1[i]=='$') s1[i]='!';
    if (s1[i]==0) s1[i]='@';
  }
  for(i=0; i<len2; i++)
  {
    if (s2[i]=='#') s2[i]='~';
    if (s2[i]=='$') s2[i]='!';
    if (s2[i]==0) s2[i]='@';
  }

  //���������� ��������� ���� �������

  TComStr com_str;
  int cnt = com_str.com_substr_cnt(s1, len1, s2, len2, k);

  return cnt;
}
//---------------------------------------------------------------------------
