typedef int item;       /* ��� ����������� ��������� */
typedef int tblIndex;   /* ��� ������, �� ������� ��������� */
#define CompGT(a,b) (a > b)
tblIndex partition(int &a, tblIndex lb, tblIndex ub) {
     item t, pivot;
    tblIndex i, j, p;
   /**********************************
    *  ���������� ������� a[lb..ub]  *
    **********************************/
    /* �������� ����� - pivot */
    p = lb + ((ub - lb)>>1);
    pivot = a[p];
    a[p] = a[lb];
    /* ��������� lb+1..ub ������������ ������ */
    i = lb+1;
    j = ub;
    while (1) {
        while (i < j && compGT(pivot, a[i])) i++;
        while (j >= i && compGT(a[j], pivot)) j--;
        if (i >= j) break;
        t = a[i];
        a[i] = a[j];
        a[j] = t;
        j--; i++;
    }
    /* ����� � a[j] */
    a[lb] = a[j];
    a[j] = pivot;
    return j;
}
void quickSort(int &a, tblIndex lb, tblIndex ub) {
    tblIndex m;
   /**************************
    *  ���������  a[lb..ub]  *
    **************************/
    while (lb < ub) {
        /* ���������� ��������� ��� ����� �������� */
        if (ub - lb <= 12) {
            insertSort(a, lb, ub);
            return;
        }
        /* ���������� ������� */
        m = partition (a, lb, ub);
        /* ��������� ���������� � ������:    */
        /*  ������� ������� ��������� ������ */
        if (m - lb <= ub - m) {
            quickSort(a, lb, m - 1);
            lb = m + 1;
        } else {
            quickSort(a, m + 1, ub);
            ub = m - 1;
        }
    }
}

int main() {
  int arr[6];
  arr[0]=3;
  arr[1]=1;
  arr[2]=4;
  arr[3]=2;
  arr[4]=3;
  arr[5]=6;
  quickSort(arr,0,6);
  return 0;

}