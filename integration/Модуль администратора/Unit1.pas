unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, Grids, DBGrids, ExtCtrls, DBCtrls, StdCtrls;

type
  TForm1 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    DBGrid3: TDBGrid;
    Label1: TLabel;
    Label2: TLabel;
    DBLookupComboBox1: TDBLookupComboBox;
    Label3: TLabel;
    DBLookupComboBox2: TDBLookupComboBox;
    Button1: TButton;
    Label4: TLabel;
    DBLookupComboBox3: TDBLookupComboBox;
    DBLookupComboBox4: TDBLookupComboBox;
    Button2: TButton;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    DBGrid4: TDBGrid;
    Label9: TLabel;
    Label10: TLabel;
    DBGrid5: TDBGrid;
    Label11: TLabel;
    Label12: TLabel;
    DBLookupComboBox5: TDBLookupComboBox;
    DBLookupComboBox6: TDBLookupComboBox;
    DBLookupComboBox7: TDBLookupComboBox;
    Button3: TButton;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    DBLookupComboBox9: TDBLookupComboBox;
    Label17: TLabel;
    Label19: TLabel;
    DBLookupComboBox12: TDBLookupComboBox;
    DBLookupComboBox13: TDBLookupComboBox;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    DBLookupComboBox14: TDBLookupComboBox;
    Label23: TLabel;
    Label24: TLabel;
    Button4: TButton;
    DBLookupComboBox10: TDBLookupComboBox;
    Label25: TLabel;
    Bevel1: TBevel;
    Bevel2: TBevel;
    DBLookupComboBox11: TDBLookupComboBox;
    Label26: TLabel;
    DBGrid6: TDBGrid;
    RadioButton2: TRadioButton;
    RadioButton1: TRadioButton;
    ProgressBar1: TProgressBar;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure DBLookupComboBox5Click(Sender: TObject);
    procedure DBLookupComboBox10Click(Sender: TObject);
    procedure DBLookupComboBox12Click(Sender: TObject);
    procedure DBLookupComboBox13Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure RadioButton2Click(Sender: TObject);
    procedure RadioButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  i,count,idmax,assignment,userid:integer;
  data1,tema,firstname,lastname:string;
  obkolvo,kolvoresh,kolvoneresh:integer;

implementation

uses Unit2;

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
if ((DBLookupComboBox1.Text<>'') and (DBLookupComboBox2.Text<>'')) then
begin
DataModule2.ADOQuery1.Active:=false;
DataModule2.ADOQuery1.Parameters.ParamByName('p1').Value:=DBLookupComboBox2.Text;
DataModule2.ADOQuery1.Active:=true;
DataModule2.IBQuery1.Active:=false;
DataModule2.IBQuery1.ParamByName('p2').Value:=DataModule2.ADOQuery1.FieldValues['id'];
DataModule2.IBQuery1.ParamByName('p3').Value:=DBLookupComboBox1.Text;
DataModule2.IBQuery1.Active:=true;
DataModule2.IBTransaction2.Commit;
DBLookupComboBox1.KeyValue:= NULL;
DBLookupComboBox2.KeyValue:= NULL;
//���������� ������
DataModule2.IBDataSet1.Active:=false;
DataModule2.IBDataSet1.Active:=true;
end
else MessageDlg('��������� ��� ���� �����!', mtWarning, [mbOk] , 0);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
if ((DBLookupComboBox3.Text<>'')
and (DBLookupComboBox4.Text<>'')) then
begin
DataModule2.ADOQuery2.Active:=false;
DataModule2.ADOQuery2.Parameters.ParamByName('p4').Value:=DBLookupComboBox4.Text;
DataModule2.ADOQuery2.Active:=true;
DataModule2.IBQuery2.Active:=false;
DataModule2.IBQuery2.ParamByName('p5').Value:=DataModule2.ADOQuery2.FieldValues['id'];
DataModule2.IBQuery2.ParamByName('p6').Value:=DBLookupComboBox3.Text;
DataModule2.IBQuery2.Active:=true;
DataModule2.IBTransaction3.Commit;
DBLookupComboBox3.KeyValue:= NULL;
DBLookupComboBox4.KeyValue:= NULL;
//���������� ������
DataModule2.IBDataSet2.Active:=false;
DataModule2.IBDataSet2.Active:=true;
end
else MessageDlg('��������� ��� ���� �����!', mtWarning, [mbOk] , 0);
end;

procedure TForm1.DBLookupComboBox5Click(Sender: TObject);
begin
if (DBLookupComboBox5.Text<>'') then
begin
DataModule2.ADODataSet4.Active:=false;
DataModule2.ADODataSet4.Parameters.ParamByName('a1').Value:=DBLookupComboBox5.Text;
DataModule2.ADODataSet4.Active:=true;
DBLookupComboBox6.Enabled:=true;
end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
if ((DBLookupComboBox5.Text<>'')
and (DBLookupComboBox5.Text<>'')
and (DBLookupComboBox7.Text<>'')) then
begin
DataModule2.IBQuery3.Active:=false;
DataModule2.IBQuery3.ParamByName('a2').Value:=DBLookupComboBox7.Text;
DataModule2.IBQuery3.Active:=true;
DataModule2.ADOQuery3.Active:=false;
DataModule2.ADOQuery3.Parameters.ParamByName('a3').Value:=DataModule2.IBQuery3.FieldValues['ID_TM'];
DataModule2.ADOQuery3.Parameters.ParamByName('a4').Value:=DBLookupComboBox5.Text;
DataModule2.ADOQuery3.Parameters.ParamByName('a5').Value:=DBLookupComboBox6.Text;
DataModule2.ADOQuery3.ExecSQL;
DBLookupComboBox6.Enabled:=false;
DBLookupComboBox5.KeyValue:= NULL;
DBLookupComboBox6.KeyValue:= NULL;
DBLookupComboBox7.KeyValue:= NULL;
//���������� ������
DataModule2.ADODataSet3.Active:=false;
DataModule2.ADODataSet3.Active:=true;
end
else MessageDlg('��������� ��� ���� �����!', mtWarning, [mbOk] , 0);
end;

procedure TForm1.DBLookupComboBox10Click(Sender: TObject);
begin
if (DBLookupComboBox10.Text<>'') then
begin
DataModule2.ADODataSet6.Active:=false;
DataModule2.ADODataSet6.Parameters.ParamByName('x1').Value:=DBLookupComboBox12.Text;
DataModule2.ADODataSet6.Parameters.ParamByName('x2').Value:=DBLookupComboBox10.Text;
DataModule2.ADODataSet6.Active:=true;
if (DataModule2.ADODataSet6.FieldValues['lastname']<>NULL) and (DataModule2.ADODataSet6.RecordCount=1) then DBLookupComboBox11.KeyValue:=DataModule2.ADODataSet6.FieldValues['lastname'];
DBLookupComboBox11.Enabled:=true;
end;
end;

procedure TForm1.DBLookupComboBox12Click(Sender: TObject);
begin
if (DBLookupComboBox12.Text<>'') then
begin
DBLookupComboBox10.KeyValue:= NULL;
DBLookupComboBox11.KeyValue:= NULL;
DBLookupComboBox13.KeyValue:= NULL;
DBLookupComboBox14.KeyValue:= NULL;
DBLookupComboBox10.Enabled:=false;
DBLookupComboBox11.Enabled:=false;
DBLookupComboBox13.Enabled:=false;
DBLookupComboBox14.Enabled:=false;
DataModule2.ADODataSet4.Active:=false;
DataModule2.ADODataSet4.Parameters.ParamByName('a1').Value:=DBLookupComboBox12.Text;
DataModule2.ADODataSet4.Active:=true;
DBLookupComboBox13.Enabled:=true;
end;
if (RadioButton2.Checked=true) then begin
DataModule2.ADODataSet5.Active:=false;
DataModule2.ADODataSet5.Parameters.ParamByName('x1').Value:=DBLookupComboBox12.Text;
DataModule2.ADODataSet5.Active:=true;
if DataModule2.ADODataSet5.FieldValues['firstname']<>NULL then DBLookupComboBox10.Enabled:=true;
end;
end;

procedure TForm1.DBLookupComboBox13Click(Sender: TObject);
begin
if (DBLookupComboBox13.Text<>'') then
begin
DBLookupComboBox14.KeyValue:= NULL;
DBLookupComboBox14.Enabled:=false;
DataModule2.ADODataSet7.Active:=false;
DataModule2.ADODataSet7.Parameters.ParamByName('b1').Value:=DBLookupComboBox12.Text;
DataModule2.ADODataSet7.Parameters.ParamByName('b2').Value:=DBLookupComboBox13.Text;
DataModule2.ADODataSet7.Active:=true;
if DataModule2.ADODataSet7.FieldValues['name']<>NULL then DBLookupComboBox14.Enabled:=true;
end;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
if  (((RadioButton1.Checked=true)
and (DBLookupComboBox9.Text<>'')
and (DBLookupComboBox12.Text<>'')
and (DBLookupComboBox13.Text<>'')
and (DBLookupComboBox14.Text<>''))
or  ((RadioButton2.Checked=true)
and (DBLookupComboBox9.Text<>'')
and (DBLookupComboBox10.Text<>'')
and (DBLookupComboBox11.Text<>'')
and (DBLookupComboBox12.Text<>'')
and (DBLookupComboBox13.Text<>'')
and (DBLookupComboBox14.Text<>'')))
then
begin
ProgressBar1.Visible:=true;
idmax:=0;
tema:=DBLookupComboBox9.Text;
DataModule2.IBDataSet8.Active:=false;
DataModule2.IBDataSet8.ParamByName('q1').Value:=DBLookupComboBox9.Text;
DataModule2.IBDataSet8.Active:=true;
obkolvo:=DataModule2.IBDataSet8.FieldValues['obkolvo'];
DataModule2.ADOQuery5.Active:=false;
DataModule2.ADOQuery5.Active:=true;
if DataModule2.ADOQuery5.FieldValues['id']<>NULL then idmax:=DataModule2.ADOQuery5.FieldValues['id'];
DataModule2.ADOQuery5.Active:=false;
DataModule2.ADOQuery6.Active:=false;
DataModule2.ADOQuery6.Parameters.ParamByName('c3').Value:=DBLookupComboBox12.Text;
DataModule2.ADOQuery6.Parameters.ParamByName('c4').Value:=DBLookupComboBox13.Text;
DataModule2.ADOQuery6.Parameters.ParamByName('c5').Value:=DBLookupComboBox14.Text;
DataModule2.ADOQuery6.Active:=true;
assignment:=DataModule2.ADOQuery6.FieldValues['assignment'];
DataModule2.ADOQuery6.Active:=false;
ProgressBar1.Position:=ProgressBar1.Position+10;
if (RadioButton2.Checked=true) then
begin
DataModule2.IBDataSet9.Active:=false;
DataModule2.IBDataSet9.ParamByName('v1').Value:=DBLookupComboBox10.Text;
DataModule2.IBDataSet9.ParamByName('v2').Value:=DBLookupComboBox11.Text;
DataModule2.IBDataSet9.ParamByName('v3').Value:=DBLookupComboBox9.Text;
DataModule2.IBDataSet9.Active:=true;
kolvoresh:=DataModule2.IBDataSet9.FieldValues['kolvoresh'];
kolvoneresh:=obkolvo-kolvoresh;
data1:='<p>����� ���������� ����� �� ���� &quot;'+tema+'&quot; - '+IntToStr(obkolvo)+'</p><p>���������� �������� ����� - '+IntToStr(kolvoresh)+'</p><p>���������� ���������� ����� - '+IntToStr(kolvoneresh)+'</p>';
ProgressBar1.Position:=ProgressBar1.Position+20;
DataModule2.ADOQuery4.Active:=false;
DataModule2.ADOQuery4.Parameters.ParamByName('c1').Value:=DBLookupComboBox10.Text;
DataModule2.ADOQuery4.Parameters.ParamByName('c2').Value:=DBLookupComboBox11.Text;
DataModule2.ADOQuery4.Parameters.ParamByName('c3').Value:=DBLookupComboBox12.Text;
DataModule2.ADOQuery4.Parameters.ParamByName('c4').Value:=DBLookupComboBox13.Text;
DataModule2.ADOQuery4.Parameters.ParamByName('c5').Value:=DBLookupComboBox14.Text;
DataModule2.ADOQuery4.Active:=true;
count:=DataModule2.ADOQuery4.FieldValues['count'];
ProgressBar1.Position:=ProgressBar1.Position+20;
DataModule2.ADOQuery4.Active:=false;
DataModule2.ADOQuery7.Active:=false;
DataModule2.ADOQuery7.Parameters.ParamByName('c1').Value:=DBLookupComboBox10.Text;
DataModule2.ADOQuery7.Parameters.ParamByName('c2').Value:=DBLookupComboBox11.Text;
DataModule2.ADOQuery7.Active:=true;
userid:=DataModule2.ADOQuery7.FieldValues['userid'];
DataModule2.ADOQuery7.Active:=false;
ProgressBar1.Position:=ProgressBar1.Position+20;
if count=0 then
begin
DataModule2.ADOQuery8.Active:=false;
DataModule2.ADOQuery8.Parameters.ParamByName('z1').Value:=idmax+1;
DataModule2.ADOQuery8.Parameters.ParamByName('z2').Value:=assignment;
DataModule2.ADOQuery8.Parameters.ParamByName('z3').Value:=userid;
DataModule2.ADOQuery8.Parameters.ParamByName('z4').Value:=data1;
DataModule2.ADOQuery8.ExecSQL;
ProgressBar1.Position:=ProgressBar1.Position+20;
end;
if count=1 then
begin
DataModule2.ADOQuery9.Active:=false;
DataModule2.ADOQuery9.Parameters.ParamByName('z2').Value:=assignment;
DataModule2.ADOQuery9.Parameters.ParamByName('z3').Value:=userid;
DataModule2.ADOQuery9.Parameters.ParamByName('z4').Value:=data1;
DataModule2.ADOQuery9.ExecSQL;
end;
ProgressBar1.Position:=ProgressBar1.Position+20;
end;

if (RadioButton1.Checked=true) then
begin
DataModule2.ADOQuery10.Active:=false;
DataModule2.ADOQuery10.Parameters.ParamByName('e1').Value:=DBLookupComboBox12.Text;
DataModule2.ADOQuery10.Active:=true;
ProgressBar1.Position:=ProgressBar1.Position+10;
for i:=1 to DataModule2.ADOQuery10.RecordCount do
begin
firstname:=DataModule2.ADOQuery10.FieldValues['firstname'];
lastname:=DataModule2.ADOQuery10.FieldValues['lastname'];
DataModule2.IBDataSet9.Active:=false;
DataModule2.IBDataSet9.ParamByName('v1').Value:=firstname;
DataModule2.IBDataSet9.ParamByName('v2').Value:=lastname;
DataModule2.IBDataSet9.ParamByName('v3').Value:=DBLookupComboBox9.Text;
DataModule2.IBDataSet9.Active:=true;
kolvoresh:=DataModule2.IBDataSet9.FieldValues['kolvoresh'];
kolvoneresh:=obkolvo-kolvoresh;
data1:='<p>����� ���������� ����� �� ���� &quot;'+tema+'&quot; - '+IntToStr(obkolvo)+'</p><p>���������� �������� ����� - '+IntToStr(kolvoresh)+'</p><p>���������� ���������� ����� - '+IntToStr(kolvoneresh)+'</p>';
DataModule2.ADOQuery4.Active:=false;
DataModule2.ADOQuery4.Parameters.ParamByName('c1').Value:=firstname;
DataModule2.ADOQuery4.Parameters.ParamByName('c2').Value:=lastname;
DataModule2.ADOQuery4.Parameters.ParamByName('c3').Value:=DBLookupComboBox12.Text;
DataModule2.ADOQuery4.Parameters.ParamByName('c4').Value:=DBLookupComboBox13.Text;
DataModule2.ADOQuery4.Parameters.ParamByName('c5').Value:=DBLookupComboBox14.Text;
DataModule2.ADOQuery4.Active:=true;
count:=DataModule2.ADOQuery4.FieldValues['count'];
DataModule2.ADOQuery4.Active:=false;
DataModule2.ADOQuery7.Active:=false;
DataModule2.ADOQuery7.Parameters.ParamByName('c1').Value:=firstname;
DataModule2.ADOQuery7.Parameters.ParamByName('c2').Value:=lastname;
DataModule2.ADOQuery7.Active:=true;
userid:=DataModule2.ADOQuery7.FieldValues['userid'];
DataModule2.ADOQuery7.Active:=false;
if count=0 then
begin
DataModule2.ADOQuery8.Active:=false;
DataModule2.ADOQuery8.Parameters.ParamByName('z1').Value:=idmax+1;
DataModule2.ADOQuery8.Parameters.ParamByName('z2').Value:=assignment;
DataModule2.ADOQuery8.Parameters.ParamByName('z3').Value:=userid;
DataModule2.ADOQuery8.Parameters.ParamByName('z4').Value:=data1;
DataModule2.ADOQuery8.ExecSQL;
idmax:=idmax+1;
end;
if count=1 then
begin
DataModule2.ADOQuery9.Active:=false;
DataModule2.ADOQuery9.Parameters.ParamByName('z2').Value:=assignment;
DataModule2.ADOQuery9.Parameters.ParamByName('z3').Value:=userid;
DataModule2.ADOQuery9.Parameters.ParamByName('z4').Value:=data1;
DataModule2.ADOQuery9.ExecSQL;
end;
ProgressBar1.Position:=ProgressBar1.Position+Round((1/DataModule2.ADOQuery10.RecordCount)*68);
if i<DataModule2.ADOQuery10.RecordCount then DataModule2.ADOQuery10.FindNext;
end;
end;
ProgressBar1.Position:=ProgressBar1.Position+10;
DBLookupComboBox11.Enabled:=false;
DBLookupComboBox13.Enabled:=false;
DBLookupComboBox14.Enabled:=false;
DBLookupComboBox9.KeyValue:= NULL;
DBLookupComboBox10.KeyValue:= NULL;
DBLookupComboBox11.KeyValue:= NULL;
DBLookupComboBox12.KeyValue:= NULL;
DBLookupComboBox13.KeyValue:= NULL;
DBLookupComboBox14.KeyValue:= NULL;
//���������� ������
DataModule2.ADODataSet8.Active:=false;
DataModule2.ADODataSet8.Active:=true;
MessageDlg('��� ������ ���� ���������/���������!', mtInformation, [mbOk] , 0);
ProgressBar1.Visible:=false;
end
else MessageDlg('��������� ��� ���� �����!', mtWarning, [mbOk] , 0);
end;

procedure TForm1.RadioButton1Click(Sender: TObject);
begin
DBLookupComboBox10.KeyValue:= NULL;
DBLookupComboBox11.KeyValue:= NULL;
DBLookupComboBox10.Enabled:=false;
DBLookupComboBox11.Enabled:=false;
end;

procedure TForm1.RadioButton2Click(Sender: TObject);
begin
if (DBLookupComboBox12.Text<>'') then
begin
DataModule2.ADODataSet5.Active:=false;
DataModule2.ADODataSet5.Parameters.ParamByName('x1').Value:=DBLookupComboBox12.Text;
DataModule2.ADODataSet5.Active:=true;
DBLookupComboBox10.Enabled:=true;
end;
end;


end.
