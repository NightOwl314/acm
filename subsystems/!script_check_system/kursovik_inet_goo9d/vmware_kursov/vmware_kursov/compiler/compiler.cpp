#include "stdio.h"
#include "windows.h"

    SHFILEOPSTRUCT sh;
    FILE* file;
    FILE* file2;
    char name[256], path[256], tmp[256];

int main(int argc, char* argv[])
{

    //������� exe ���� �� run.exe
    strcpy(tmp, "run.exe");
    strcpy(name, "\0");
    
    //��������� ������� ���������
    //������ �������� ���������� - 
    //� ��� �������� ��� ����� ����������� �������� ��� �������� ������
    //������ �������� ������������ - � ��� ������� ��� ���������,
    //������� ����� ��������� � ���� ���������������� ��������� (�� ��������� run.exe)
    switch (argc)
    {
    case 3:
        strcpy(tmp, argv[2]); 
    case 2:
        GetFullPathName(tmp, 256, path, NULL);
        GetFullPathName(argv[1], 256, name, NULL);
        break;
    case 1:
        return 1;
    default: 
        return 1;
    }
    int y;char nameFile[256];
	strcpy(nameFile, name);
    for(y=strlen(nameFile);y>=0;y--) if(nameFile[y]=='.') break;
    nameFile[y] = '\0';
    //�������� ����, ���������� �������� ��� ���������� �� ��������� ����
    //���_���������_ex.vbs
    //! � ������� ����� ������� ��� ����� �������������
	strcpy(tmp, nameFile);
	strcat(nameFile, "_ex.vbs");
    
    //�������� ���� 
char bbb[256];
    if((file = fopen(name, "rb"))==NULL) return 1;
    if((file2 = fopen(nameFile, "wb"))==NULL) return 1;
    fgets(bbb, 256, file);
    while (!feof(file))    
    {
        fprintf(file2, "%s",bbb);
        fgets(bbb, 256, file);
    }
    fclose(file);
    fclose(file2);
    
    //��������������� run.exe � ���� ���_���������.exe
	strcat(tmp, ".exe");

	sh.hwnd   = NULL;
	sh.wFunc  = FO_COPY;
	sh.pFrom = path;
	sh.pTo = tmp;
	sh.fFlags =   FOF_NOCONFIRMATION | FOF_SILENT;
	sh.hNameMappings = 0;
	sh.lpszProgressTitle = NULL;
	SHFileOperation (&sh);

    return 0;
}