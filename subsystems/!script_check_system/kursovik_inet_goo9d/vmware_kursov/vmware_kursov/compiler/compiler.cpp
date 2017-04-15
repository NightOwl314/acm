#include "stdio.h"
#include "windows.h"

    SHFILEOPSTRUCT sh;
    FILE* file;
    FILE* file2;
    char name[256], path[256], tmp[256];

int main(int argc, char* argv[])
{

    //Создаем exe файл из run.exe
    strcpy(tmp, "run.exe");
    strcpy(name, "\0");
    
    //Проверяем входные аргументы
    //Первый аргумент обязателен - 
    //в нем хранится имя файла содержащего исходный код решаемой задачи
    //Второй аргумент необязателен - в нем пишется имя программы,
    //которая будет выступать в роли скомпилированной программы (по умолчанию run.exe)
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
    //Исходный файл, содержащий исходный код копируется во временный файл
    //имя_программы_ex.vbs
    //! В будущем лучше сделать эту опцию настраиваемой
	strcpy(tmp, nameFile);
	strcat(nameFile, "_ex.vbs");
    
    //Копируем файл 
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
    
    //Переименовываем run.exe в файл имя_программы.exe
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