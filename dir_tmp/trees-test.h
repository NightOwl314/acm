#include <iostream.h>

//-------------------------------------------------------------------
//пример проверок, которые будут выполняться над вашими классами

//простой вывод в строчку
void myfunc1(Tree::Node *node, int level)
{
  cout << node->data << " ";
}

//вывод с учетом уровней
void myfunc2(Tree::Node *node, int level)
{
  cout << "[" << node->data << "," << level << "] ";
}

//тест из условия
void test1(void){

  Tree* trees[2]; //массив из нескольких деревьев

  //создаём сильноветвящееся дерево, заполняем в нём пару уровней
  trees[0] = new LR_Tree;
  Tree::Node *root = trees[0]->new_node(NULL); root->data = 1;
  for (int i=2; i<=4; i++)  {
    Tree::Node *node = trees[0]->new_node(root);
    node->data = i;
    for (int j=1000; j<=1001; j++)
    {
      Tree::Node *node2 = trees[0]->new_node(node);
      node2->data = j;
    }
  }

  //создаём не очень ветвящееся дерево, заполняем несколько уровней
  trees[1] = new Ar_Tree(3);
  Tree::Node *root2 = trees[1]->new_node(NULL); root2->data = 1;
  for (int i=2; i<=3; i++)  {
    Tree::Node *node = trees[1]->new_node(root2);
    node->data = i;
    for (int j=4; j<=6; j++)
    {
      Tree::Node *node2 = trees[1]->new_node(node);
      node2->data = j;
    }
  }

  //выполняем разные обходы и выводим их на экран разными способами
  for(int i=0; i<2; i++)
  {
    trees[i]->dfs(myfunc1); cout << endl;
    trees[i]->bfs(myfunc1); cout << endl;
  }

  //проверяем, как работает перечисление сыновей узла
  for(int i=0; i<2; i++) {
    Tree::Node *root = trees[i]->root();
    Tree::Node *node = trees[i]->first_child(root);
    while (node!=NULL)
    {
      cout << node->data << " ";
      node = trees[i]->next_child(root,node);
    }
    cout << endl;
  }

  //проверяем, как работает удаление поддеревьев
  for(int i=0; i<2; i++)
  {
    Tree::Node *node = trees[i]->first_child(trees[i]->root());
    trees[i]->delete_subtree(node);
    trees[i]->bfs(myfunc1); cout << endl;
  }

  //удаляем деревья
  for(int i=0; i<2; i++)
    delete trees[i];

}

//простая проверка класса LR_Tree (вставка узлов, bfs, dfs, delete_subtree)
void test2(void) {
  LR_Tree lr_tree;
  Tree::Node *r = lr_tree.new_node(NULL); r->data=0;
  Tree::Node *n11 = lr_tree.new_node(r); n11->data=11;
  Tree::Node *n12 = lr_tree.new_node(r); n12->data=12;
  Tree::Node *n21 = lr_tree.new_node(n11); n21->data=21;
  Tree::Node *n22 = lr_tree.new_node(n11); n22->data=22;
  Tree::Node *n23 = lr_tree.new_node(n12); n23->data=23;
  Tree::Node *n24 = lr_tree.new_node(n12); n24->data=24;
  lr_tree.bfs(myfunc1);  cout << endl;
  lr_tree.delete_subtree(n11);
  lr_tree.dfs(myfunc1);  cout << endl;
  lr_tree.delete_subtree(r);
  lr_tree.bfs(myfunc1);  cout << endl;
  r = lr_tree.new_node(NULL); r->data=0;
  lr_tree.bfs(myfunc1);  cout << endl;
}


//простая проверка класса Ar_Tree (вставка узлов, bfs, dfs, delete_subtree)
void test3(void) {
  Ar_Tree ar_tree(3);
  Tree::Node *r = ar_tree.new_node(NULL); r->data=0;
  Tree::Node *n11 = ar_tree.new_node(r); n11->data=11;
  Tree::Node *n12 = ar_tree.new_node(r); n12->data=12;
  Tree::Node *n21 = ar_tree.new_node(n11); n21->data=21;
  Tree::Node *n22 = ar_tree.new_node(n11); n22->data=22;
  Tree::Node *n23 = ar_tree.new_node(n12); n23->data=23;
  Tree::Node *n24 = ar_tree.new_node(n12); n24->data=24;
  ar_tree.bfs(myfunc1);  cout << endl;
  ar_tree.delete_subtree(n11);
  ar_tree.dfs(myfunc1);  cout << endl;
  ar_tree.delete_subtree(r);
  ar_tree.bfs(myfunc1);  cout << endl;
  r = ar_tree.new_node(NULL); r->data=0;
  ar_tree.bfs(myfunc1);  cout << endl;
}


//проверка LR_Tree на конструкторы копий и операции присваивания
void test4(void) {
  LR_Tree lr_tree;
  Tree::Node *r = lr_tree.new_node(NULL); r->data=0;
  Tree::Node *n11 = lr_tree.new_node(r); n11->data=11;
  Tree::Node *n12 = lr_tree.new_node(r); n12->data=12;
  Tree::Node *n21 = lr_tree.new_node(n11); n21->data=21;
  Tree::Node *n22 = lr_tree.new_node(n11); n22->data=22;
  Tree::Node *n23 = lr_tree.new_node(n12); n23->data=23;
  Tree::Node *n24 = lr_tree.new_node(n12); n24->data=24;
  LR_Tree lr2 = lr_tree;
  lr_tree.bfs(myfunc2); cout << endl;
  lr_tree.dfs(myfunc2); cout << endl;
  LR_Tree lr3;
  r = lr3.new_node(NULL); r->data=0;
  n11 = lr3.new_node(r); n11->data=110;
  n12 = lr3.new_node(r); n12->data=120;
  n21 = lr3.new_node(n11); n21->data=210;
  lr3=lr2;
  lr3.bfs(myfunc1); cout << endl;
  lr3=lr3;
  lr3.dfs(myfunc1); cout << endl;
}


//проверка Ar_Tree на конструкторы копий и операции присваивания
void test5(void) {
  Ar_Tree ar_tree(3);
  Tree::Node *r = ar_tree.new_node(NULL); r->data=0;
  Tree::Node *n11 = ar_tree.new_node(r); n11->data=11;
  Tree::Node *n12 = ar_tree.new_node(r); n12->data=12;
  Tree::Node *n21 = ar_tree.new_node(n11); n21->data=21;
  Tree::Node *n22 = ar_tree.new_node(n11); n22->data=22;
  Tree::Node *n23 = ar_tree.new_node(n12); n23->data=23;
  Tree::Node *n24 = ar_tree.new_node(n12); n24->data=24;
  Ar_Tree ar2 = ar_tree;
  ar_tree.bfs(myfunc2); cout << endl;
  ar_tree.dfs(myfunc2); cout << endl;
  Ar_Tree ar3(1);
  r = ar3.new_node(NULL); r->data=0;
  n11 = ar3.new_node(r); n11->data=110;
  n21 = ar3.new_node(n11); n21->data=210;
  ar3=ar2;
  ar3.bfs(myfunc1); cout << endl;
  ar3=ar3;
  ar3.dfs(myfunc1); cout << endl;
}


//проверка на эффективность использования памяти
//LR_Tree - создание дерева с сильным ветвлением
//здесь же отслеживание количества деревьев и количества узлов в дереве

void _lr_insert(LR_Tree *lr_tree, Tree::Node *r)
{
  //делаем 3 уровня по 50 элементов
  int num = 0;
  for(int i=0; i<50; i++) {
    Tree::Node *n1 = lr_tree->new_node(r);
    n1->data = num++;
    for(int j=0; j<50; j++) {
      Tree::Node *n2 = lr_tree->new_node(n1);
      n2->data = num++;
      for(int k=0; k<50; k++) {
        Tree::Node *n3 = lr_tree->new_node(n2);
        n3->data = num++;
      }
    }
  }
}

void test6(void) {

 //повторяем раза 4
 for (int p=0; p<4; p++)
 {
  LR_Tree *lr_tree = new LR_Tree;
  Tree::Node *r = lr_tree->new_node(NULL); r->data=0;
  _lr_insert(lr_tree,r);
  cout << lr_tree->size() << " " <<  Tree::trees_count() << " ";
  //удаляем все подуровни, кроме корня
  for(;;) {
    Tree::Node *n = lr_tree->first_child(r);
    if (n==NULL) break;
    lr_tree->delete_subtree(n);
  }
  lr_tree->bfs(myfunc1);
  delete lr_tree;
 }
 cout << endl;
}

//проверка на эффективность использования памяти
//Ar_Tree - создание большого бинарного дерева
int num=0;
int h=17; //высота дерева
void ar_insert(Ar_Tree *ar_tree, Tree::Node *node) {
  h--;
  if (h>0) {
    Tree::Node *n1 = ar_tree->new_node(node);
    n1->data = num++;
    Tree::Node *n2 = ar_tree->new_node(node);
    n1->data = num++;
    ar_insert(ar_tree,n1); ar_insert(ar_tree,n2);
  }
  h++;
}
void test7(void)
{
 for(int p=0; p<4; p++)
 {
   Ar_Tree *ar_tree = new Ar_Tree(2);
   Tree::Node *r = ar_tree->new_node(NULL);
   r->data=1;
   ar_insert(ar_tree,r);
   //удаляем все подуровни, кроме корня
   cout << ar_tree->size() << " " <<  Tree::trees_count() << " ";
   for(;;) {
    Tree::Node *n = ar_tree->first_child(r);
    if (n==NULL) break;
    ar_tree->delete_subtree(n);
   }
   ar_tree->dfs(myfunc1);
   delete ar_tree;
 }
 cout << endl;
}

//проверка корректности работы виртуального деструктора
//если уничтожение происходит некорректно, будет предел памяти
void test8(void) {

  for(int i=0; i<4; i++) {
    Tree *tree = new LR_Tree;
     Tree::Node *r = ((LR_Tree*)tree)->new_node(NULL); r->data=0;
    _lr_insert((LR_Tree*)tree,r);
    delete tree;
  }

  for(int i=0; i<10; i++) {
    Tree *tree = new Ar_Tree(100000);
    delete tree;
  }

  cout << "ok\n";

}

int main(void)
{
  char s[256];
  cin.getline(s,256); cin >> ws;
//  cout << s;
  
  int testnum;
  cin >> testnum;
  switch (testnum)
  {
    case 1: test1(); break;
    case 2: test2(); break;
    case 3: test3(); break;
    case 4: test4(); break;
    case 5: test5(); break;
    case 6: test6(); break;
    case 7: test7(); break;
    case 8: test8(); break;
  }
  return 0;
}
