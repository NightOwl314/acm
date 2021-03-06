#define _CRT_SECURE_NO_DEPRECATE
//---------------------------------------------------------------------------
#include <windows.h>
#include <fstream>
#include <cstring>
#include <string>
#include <cstdio>
#include <iomanip>
#include "db_func.h"
#include "testing.h"
#include "main_mod.h"
#include "..\common_cpp\result_id.h"
#include "..\common_cpp\swap_message.h"

using namespace std;

TPaths pt; //����� (� ������� ������) ����������� ��� �������� ������
ofstream logfl; //��� ����
TDataBase DB;  //������ � ��
TConfig *master_cfg; //��������� ������ ������� �� cfg-������

//��������� ��� ������ �� ��, ������� ����� ���������� � �������� ��������
void WhileTestSolve(void)
{
   TSubmited elm; //��������� ������ �������
   unsigned int n,tm,mm,tm1,mm1;
   int r,bl=0,msg,err,again_plagiat;
   char query_str[150],filename[MAX_PATH],filename_snd[MAX_PATH],s[20],ts[50],s_log[300];
   char compil_scr[MAX_PATH],compil_prm[100],obj_data_null[50],warn_rsl_s[50],cmp_id_stat_null[50];
   char otchfile[MAX_PATH],exe_file[MAX_PATH],obj_file[MAX_PATH];
   TCompiler *compil;
   ofstream otchet;
   SHELLEXECUTEINFO se;
   void *snapshot;
   SYSTEMTIME sys_tm;

   while(true) {

      if (bl) {
         DB.FinishTesting(); //������� ������� � ��������� ��������
      }

      snapshot=DB.start_trans(1); //������� ���������� snapshot
	   memset(&elm,0,sizeof(elm));
	   elm.cur_uniq_proc=100.0;

      bl=DB.SelectDataSubmit(&elm,snapshot); //����� ������������� �������
      if (bl==0) { //���������
         DB.rollback_trans(snapshot);
         msg=DB.wait_events(); //�������� ������� �� ��

         if ( !msg || (msg & EVN_STOP_SRV)>0 ) {
			   info2log("���������� ������");
			   break; //���������� ������ �������
		   }
         continue;
      }

      sprintf(s_log,"������ �������� ������� %d",elm.id_stat);
      info2log(s_log);

      DB.StartTesting(); //������� ������� � ��������� �������� �������

      compil=master_cfg->CompilerId(elm.id_cmp);

      //��������� ��� ����� � ����� ���������� �������
      sprintf(filename_snd,"%s%s",master_cfg->GlobalPaths->DirTempSrc,compil->FileIn);
      //��������� ��� ����� � ����� ���������� � �������� �������
      sprintf(filename,"%s%s",master_cfg->GlobalPaths->DirTemp,compil->FileIn);

      itoa(elm.id_stat,s,16); //hex
      StrReplace(filename_snd,REPLACE_ID,s);
      StrReplace(filename,REPLACE_ID,s);
      sprintf(otchfile,"%s%s.otch",master_cfg->GlobalPaths->DirSrcArhive,s);

      //������ ������ � ��, ���� ��������� ������
      if (!FileExists(filename_snd)) {
         logfl << "file not found " << filename << endl;
         sprintf(query_str,"delete from status where id_stat=%d",elm.id_stat);
         DB.SqlExecute(query_str,snapshot);
         DB.commit_trans(snapshot);
         continue;
      }

      //�������� �������� � ������� ����������
      CopyFile(filename_snd,filename,FALSE);

      //����� ����������� ��������
      if (!DB.UpdateStatus(elm.id_stat,RS_COMPILING,&snapshot))
         continue;
      strcpy(compil_scr,compil->CompilScript);
      strcpy(compil_prm,compil->CompilParam);
      StrReplace(compil_prm,REPLACE_ID,s);

      otchet.open(otchfile,ios::out);
      otchet << "<pre><h3>COMPILING...</h3><strong>RUN:</strong>"
             << compil_scr << " " << compil_prm <<"\n"
             << "<strong>COMPILER OUTPUT:</strong>\n";
      otchet.close();
      strcpy(query_str,compil_prm);

      sprintf(pt.dir_temp,"%s%d\\",master_cfg->GlobalPaths->DirTemp,DB.get_id());
      CreateDirectory(pt.dir_temp,NULL);

      sprintf(pt.compil_outF,"%scompil.out",pt.dir_temp);

      sprintf(compil_prm,"%s >\"%s\"",query_str,pt.compil_outF);
      memset(&se,0,sizeof(SHELLEXECUTEINFO));
      se.cbSize = sizeof(SHELLEXECUTEINFO);
      se.hwnd = NULL;
      se.lpVerb = NULL;//"open";
      se.lpFile = compil_scr;
      se.lpParameters =compil_prm;
      se.lpDirectory = master_cfg->GlobalPaths->DirTemp;
      se.fMask = SEE_MASK_NOCLOSEPROCESS;
      if(ShellExecuteEx(&se)) {
         WaitForSingleObject(se.hProcess, INFINITE);
         CloseHandle(se.hProcess);
      }
      AddFileInOtchet(otchfile,pt.compil_outF);

      //�������� ������� ��������� �����
      sprintf(exe_file,"%s%s",master_cfg->GlobalPaths->DirTemp,compil->FileOut);
      StrReplace(exe_file,REPLACE_ID,s);
      sprintf(obj_file,"%s%s",master_cfg->GlobalPaths->DirTemp,compil->FileObj);
      StrReplace(obj_file,REPLACE_ID,s);
      if (!FileExists(exe_file)) { //��� ��������� ����� -> ������ ����������
         otchet.open(otchfile,ios::out|ios::app);
         otchet << "<strong>ERROR</strong>\n";
         otchet.close();

         r=RS_COMPILATION_ERROR;
         sprintf(query_str,"update status set id_rsl=%d, obj_data=null where id_stat=%d",
            r,elm.id_stat);

      } else {

         otchet.open(otchfile,ios::out|ios::app);
         otchet << "<strong>OK</strong>\n\n<h3>RUNNING...</h3>";
         otchet.close();

         //��������� �������
         if (!DB.UpdateStatus(elm.id_stat,RS_RUNING,&snapshot))
            continue;

         //����������� ������ ���� ������ � ��������� ����������� ��� �������� �������
         sprintf(pt.DirTests,"%s%d\\%s",master_cfg->GlobalPaths->DirProblems,elm.id_prb,
            master_cfg->ProblemPaths->Tests);
         strcpy(pt.FileTest, compil->RunCmd);
         StrReplace(pt.FileTest,REPLACE_ID,s);
         StrReplace(pt.FileTest,"$(path)",master_cfg->GlobalPaths->DirTemp);

         sprintf(pt.WAProg,"%s%d\\%s",master_cfg->GlobalPaths->DirProblems,elm.id_prb,
             master_cfg->ProblemPaths->WrongAnswerPrg);
         sprintf(pt.ListTests,"%s%d\\%s",master_cfg->GlobalPaths->DirProblems,elm.id_prb,
             master_cfg->ProblemPaths->ListTests);
         strcpy(pt.WLFile,compil->WhiteListFile);
         pt.protect=compil->ProtectMode;
         strcpy(pt.otchetF,otchfile);
         pt.debug_protect=elm.debug_protect;
         pt.id_uniq=DB.get_id();

         otchet.open(otchfile,ios::out|ios::app);
         otchet << "<strong>RUN:</strong> " << pt.FileTest << "\n"
                << "<strong>LIST OF TESTS:</strong> " << pt.ListTests << "\n"
                << "<strong>CHECKER:</strong> " << pt.WAProg << "\n";
         otchet.close();

         //�������� �������� ������ � �������
         elm.time+=(double)compil->AdjTime/1000.0;
         elm.mem+=compil->AdjMemory;
         tm=elm.time;
         mm=elm.mem;
         r=TestSolve(&pt,&elm.time,&elm.mem,&n,elm.id_cmp); //��������� �������

         //������ ����� ��������, �� ��� ����� �� ���������� �������������� ������� ��� ������
         if (elm.time>(double)compil->AdjTime/1000.0) 
            elm.time-=(double)compil->AdjTime/1000.0; 
         else elm.time=0;

         if (elm.mem>compil->AdjMemory) 
            elm.mem-=compil->AdjMemory; 
         else elm.mem=0;
/*
         if (r==RS_ACCEPTED) {
            if (elm.warn_rsl!=RS_ACCEPTED) {
               //�������� �� �������
               if (FileExists(obj_file) &&
				   !DB.TestPlagiat(elm.id_stat,elm.id_cmp,obj_file,
				elm.min_uniq_proc,pt.plagiat_text,
				&again_plagiat,&elm.cur_uniq_proc,&elm.cmp_id_stat,snapshot)) {
                  if (elm.warn_rsl==RS_UNIQUE_ERROR || again_plagiat)
                     r=RS_UNIQUE_ERROR;
                  else
                     elm.warn_rsl=RS_UNIQUE_ERROR; //���������� �� �������

                  otchet.open(otchfile,ios::out|ios::app);
                  otchet << "<strong>ANALISING PLAGIAT (not unique):</strong>\n"
                         << pt.plagiat_text << "\n";
                  otchet.close();
               }
            }
         } else {
             elm.warn_rsl=-1; //NULL
         }
*/
         if (r==RS_ACCEPTED) {
            int old_user,id_slv;

            if (FileExists(obj_file)) {
				   //�������� �� �������
               DB.TestPlagiat(elm.id_stat,elm.id_cmp,obj_file,
   				   &again_plagiat,&elm.cur_uniq_proc,&elm.cmp_id_stat,snapshot);
               if (elm.cmp_id_stat>0) {
                  otchet.open(otchfile,ios::out|ios::app);
                  otchet << "<strong>ANALISING PLAGIAT (not unique):</strong>\n"
                   << "id_stat=" << elm.cmp_id_stat << "; unique="<< elm.cur_uniq_proc << "% \n";
                  otchet.close();
               }
               if (again_plagiat && elm.cur_uniq_proc<elm.min_uniq_proc && elm.min_uniq_proc>1.001)
                  r=RS_UNIQUE_ERROR;

			      //�������� ��������� ����
		         DB.SaveObjFile(elm.id_stat,obj_file,snapshot);
			   }
            strcpy(obj_data_null,"");

            //� ����� ��� ������� ����� ��������
            if (r==RS_ACCEPTED && DB.TestingBestSolve(&elm,&old_user,&id_slv,snapshot)) {
               otchet.open(otchfile,ios::out|ios::app);
               otchet << "<strong>this best solve</strong>\n";
               otchet.close();

               //�������� ��� 2 ����, ��� ��������� ������� �������
               /*			   
			   for (int i=0;i<2;i++) {
                  tm1=tm;
                  mm1=mm;
                  TestSolve(&pt,&tm1,&mm1,&n,elm.id_cmp);
                  tm1-=compil->AdjTime;
                  mm1-=compil->AdjMemory;
                  if (tm1<elm.time) elm.time=tm1;
                  if (mm1<elm.mem) elm.mem=mm1;
               }
			   */

               //������� ����� ������� � ������
               ifstream inpsrc(filename,ios::binary);
               inpsrc.seekg(0,ios::end);
               int sz=inpsrc.tellg();
               char *buff = new char[sz];
               inpsrc.seekg(0,ios::beg);
               inpsrc.read(buff,sz);
               inpsrc.close();

               //������� ������ �������
               sprintf(query_str,"update problems set id_prb=id_prb+0 where id_prb=%d",elm.id_prb);
               while (DB.SqlExecute(query_str,snapshot)==-1)
                  Sleep(10);
               if (DB.TestingBestSolve(&elm,&old_user,&id_slv,snapshot)) {
                  DB.UpdateBestSolve(&elm,buff,sz,old_user,id_slv,snapshot);
               }
               delete[] buff;
            }
         } else {
            strcpy(obj_data_null,",obj_data=null");
         }
         /*
         if (elm.warn_rsl==-1) {
            strcpy(warn_rsl_s,",warn_rsl=NULL ");
         } else {
            sprintf(warn_rsl_s,",warn_rsl=%d ",elm.warn_rsl);
         }
         */
         if (elm.cmp_id_stat==0)
            strcpy(cmp_id_stat_null,",cmp_id_stat=NULL ");
         else
            sprintf(cmp_id_stat_null,",cmp_id_stat=%d ",elm.cmp_id_stat);

         //������� ��������� � ����
         if (n==0) {
            sprintf(query_str,"update status set id_rsl=%d, "
               "time_work=%.9f,mem_use=%d,uniq_proc=%f %s %s where id_stat=%d",
			      r,elm.time,elm.mem,elm.cur_uniq_proc,cmp_id_stat_null,
               obj_data_null,elm.id_stat);

            otchet.open(otchfile,ios::out|ios::app);
            otchet << "<strong>OK</strong>\n";
            otchet.close();
         } else {
            sprintf(query_str,"update status set id_rsl=%d, test_no=%d, "
               "time_work=%.9f,mem_use=%d %s where id_stat=%d",
               r,n,elm.time,elm.mem,obj_data_null,elm.id_stat);
         }

         DeleteFile(exe_file);
      }

      DB.SaveReports(elm.id_stat,r,&pt,snapshot);

      logfl.setf(ios::fixed);
      logfl.precision(3);

      sprintf(s_log,"��������� �������� ������� %d",elm.id_stat);
      info2log(s_log);

      //��-�� ��������� ���������� � ��������, ����� ���������� DEADLOCK
      do {
         err=DB.SqlExecute(query_str,snapshot,1);
         if (err==-1) 
            info2log("���������� ��-�� ��������� ���������� ������ ��������. "
                     "������� ��������� ��������� ��� ���..."); 
      } while(err==-1);

      DB.commit_trans(snapshot);

      sprintf(s_log,"�������� ��������� �������� ������� %d",elm.id_stat);
      info2log(s_log);

      //�������� �� �����
      otchet.open(otchfile,ios::out|ios::app);
      otchet << "</pre>\n";
      otchet.close();
      sprintf(otchfile,"%s%s.src",master_cfg->GlobalPaths->DirSrcArhive,s);
      CopyFile(filename,otchfile,FALSE);
      DeleteFile(filename);
      DeleteFile(filename_snd);
      DeleteFile(obj_file);
      DelOldSrc(elm.id_stat);
      pt.del_temp_files(1);
      RemoveDirectory(pt.dir_temp);
   }

}

//������ ���� ��������� ��������� str_find � ������ str_src �� ������ str_new
void StrReplace(char *str_src, char *str_find, char *str_new)
{
   int pos;
   string src,fnd(str_find),nw(str_new),bf;

   while(1) {
      src=string(str_src);
      pos=src.find(fnd);
      if (pos==-1) break;
      bf=src.substr(0,pos)+nw+src.substr(pos+fnd.length());
      strcpy(str_src,bf.c_str());
   }
}

//������ ��������� �� ������
void err(const char *s)
{
   SYSTEMTIME sys_tm;
   char ts[50];
   GetSystemTime(&sys_tm);
   sprintf(ts,"%02d:%02d:%02d.%03d",sys_tm.wHour,sys_tm.wMinute,sys_tm.wSecond,sys_tm.wMilliseconds);
   logfl << ts << " [������ "<<DB.get_id() <<"] ERROR: " << s << endl;
    //MessageBoxA(NULL, s, "Error!", 0);
}

//��������� ���������� � ���
void info2log(const char *s)
{
   SYSTEMTIME sys_tm;
   char ts[50];
   GetSystemTime(&sys_tm);
   sprintf(ts,"%02d:%02d:%02d.%03d",sys_tm.wHour,sys_tm.wMinute,sys_tm.wSecond,sys_tm.wMilliseconds);
   logfl << ts << " [������ "<<DB.get_id() <<"] " << s << endl;
}

//�������� �������, ����� �����
int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInst, LPSTR CmdLine, int nCmdShow)
{
   char fl_cfg[MAX_PATH],s[MAX_PATH];
   ifstream inp;
   int n_cpu,i;

   //��������� ���� � ����� ������������
   inp.open("config_file.path");
   if (!inp) {
      err("error config_file.path not found");
      return 1;
   }
   inp >> fl_cfg;
   inp.close();

   //������ ���������
   master_cfg= new TConfig;
   master_cfg->Read(fl_cfg);

   //���������� ����������� ���������� ���������
   char sys_dir[256];
   GetSystemDirectory(sys_dir, 256);
   char env_dir[256];
   //SystemDrive
   sprintf(env_dir,"SystemDrive=%c:",sys_dir[0]);
   putenv(env_dir);
   //TEMP
   sprintf(env_dir,"TEMP=%s",master_cfg->GlobalPaths->DirTemp);
   putenv(env_dir);
   //TMP
   sprintf(env_dir,"TMP=%s",master_cfg->GlobalPaths->DirTemp);
   putenv(env_dir);

   //������� ���
   logfl.open(master_cfg->GlobalPaths->LogFile,ios::out | ios::app);

   //�������� � ���������� ���������� � ��������� ������, �������� -cpu3
   if (strncmp(CmdLine,"-cpu",4)==0) {
      strcpy(s,CmdLine+4);
      i=0;
      while (isdigit(s[i])) i++;
      s[i]=0;
      n_cpu=atoi(s);
      i=SetProcessAffinityMask(GetCurrentProcess(),(DWORD)1<<(n_cpu-1));
      logfl << "Associate CPU" << n_cpu << "...  "
           << (i?"successful":"failed")  << endl;
   }

   //���� dll-���������� ������
   strcpy(pt.dllF,master_cfg->GlobalPaths->Test_protectDll);

   //���������� � ��
   if (DB.Connect(master_cfg->DataBase->dbname, master_cfg->DataBase->user,
       master_cfg->DataBase->password)) {
      err("No connect DB");
      return 1;
   }

   //����������� ������� ����������
   CPUSpeed=GetCPUSpeed();

   //����������� (����� �������� ������� �� ��) �������� ����������� �������
   WhileTestSolve();

   DB.Disconnect();
   logfl.close();
   delete master_cfg;
   return 0;
}  //����� WinMain

