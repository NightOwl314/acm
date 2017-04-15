#include "windows.h"
#include "stdio.h"

	int j;char name[256];
SHFILEOPSTRUCT sh;
    FILE* file;char line[256];
int main(int argc, char* argv[])
{

	//очистим входной файл, чтобы не было видно в подсказках
    FILE *f = fopen(argv[1],"wt");
	fputs("Input...",f);
	fclose(f);
    
    strcpy(name, argv[2]);



    if((file = fopen(name, "rb"))==NULL) return 1;
    fgets(line,256,file);
    j = atoi(line);
    if(j == 0)
    {
 		fgets(line, 256, file);	
        line[strlen(line)-1]=0; 
        line[strlen(line)-1]=0; 
        fclose(file);

		sh.hwnd   = NULL;
		sh.wFunc  = FO_DELETE;
		sh.pFrom = line;
		sh.pTo = NULL;
		sh.fFlags =   FOF_NOCONFIRMATION | FOF_SILENT;
		sh.hNameMappings = 0;
		sh.lpszProgressTitle = NULL;
		SHFileOperation (&sh);
        return 0;
    }
    else
    {
        fgets(line, 256, file);
        if(line[strlen(line)-1]<20) line[strlen(line)-1]=0;
        if(line[strlen(line)-1]<20) line[strlen(line)-1]=0; 
        
        char buffer[10][256];
        int i;
        for(i=0; i<10; i++)
            strcpy(buffer[i], "\0");
        i = 0;
        while(!feof(file) && i<10)
        {
            fgets(buffer[i], 256, file);
            i++;
        }
        fclose(file);
        i--;
        file = fopen(name, "wt");
        for(int y=0;i>=0;y++,i--)
            fprintf(file, "%s", buffer[y]);
		fclose(file);

 //       printf("-=%s=-\r\n", line);
        i=0;char t[256];strcpy(t, line);
//        printf("-=%s=-\r\n", t);
        if((file = fopen(t, "rt"))==NULL) return 1;
//        fgets(t, 256, file);
//        fgets(t, 256, file);
//        fgets(t, 256, file);
		char tr[256];
        fgets(t, 256, file);
        strcpy(tr ,"\0");
    
        while (!feof(file) && i<=10)
        {
            OemToChar(t, tr);
			printf("%s", tr);

            strcpy(tr, "\0");
            fgets(t, 256, file);
            i++;
        }
        fclose(file);
		
		SHFILEOPSTRUCT sh;
		sh.hwnd   = NULL;
		sh.wFunc  = FO_DELETE;
		sh.pFrom = line;
		sh.pTo = NULL;
		sh.fFlags =   FOF_NOCONFIRMATION | FOF_SILENT;
		sh.hNameMappings = 0;
		sh.lpszProgressTitle = NULL;
		SHFileOperation (&sh);

        return j;
    }
 }