{ВаСёК}{2008}
unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TForm1 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Label1: TLabel;
    Label10: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label2: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Edit1: TEdit;
    GroupBox1: TGroupBox;
    ComboBox3: TComboBox;
    Edit7: TEdit;
    ComboBox4: TComboBox;
    GroupBox3: TGroupBox;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit3: TEdit;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    Button1: TButton;
    Edit2: TEdit;
    Label7: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label11: TLabel;
    Button2: TButton;
    Label18: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Edit7Exit(Sender: TObject);
    procedure ComboBox1Select(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TabSheet2Show(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure ComboBox3Select(Sender: TObject);
  private
    Rz,Re,Pizm,minPizm,maxPizm,Pras,K,Ri,Rod,D,H,L,Nst,B,Rp,Lp,Np,Rst: real;
    IsDeletedIndex: boolean;
    procedure ChangeLabels(n: integer; b,l: real; s: string);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  TabSheet2.Show;
end;

procedure TForm1.Edit7Exit(Sender: TObject);
begin
  if Edit7.Text='' then Exit;
  try
    Pizm:=StrToFloat(Edit7.Text);
  except
//    ShowMessage('Некорректное значение удельного сопротивления!');
    Exit;
  end;
  if ComboBox3.ItemIndex>=0 then
  begin
    if Pizm<minPizm then
    begin
      ShowMessage('Для выбранного вида грунта минимальное значение удельного сопротивления равно '+FloatToStr(minPizm));
      ComboBox3.ItemIndex:=-1;
    end;
    if Pizm>maxPizm then
    begin
      ShowMessage('Для выбранного вида грунта максимальное значение удельного сопротивления равно '+FloatToStr(maxPizm));
      ComboBox3.ItemIndex:=-1;
    end;
  end;
end;

procedure TForm1.ComboBox1Select(Sender: TObject);
begin
  if (ComboBox1.ItemIndex=1) and (not IsDeletedIndex) then
  begin
    ComboBox2.Items.Delete(0);
    IsDeletedIndex:=true;
  end;
  if (IsDeletedIndex) and (ComboBox1.ItemIndex<>1) then
  begin
    ComboBox2.Items.Insert(0,'Большая');
    IsDeletedIndex:=false;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  IsDeletedIndex:=false;
end;

procedure TForm1.TabSheet2Show(Sender: TObject);
var
  i,n: integer;
begin
  try
    Rz:=StrToFloat(Edit1.Text);
    L:=StrToFloat(Edit2.Text);
    D:=StrToFloat(Edit3.Text)/1000;
    H:=StrToFloat(Edit4.Text);
    B:=StrToFloat(Edit5.Text)/1000;
    Re:=StrToFloat(Edit6.Text);
    Pizm:=StrToFloat(Edit7.Text);
  except
    ChangeLabels(0,0,0,'Некорректно заполнено одно из полей!');
    Exit;
  end;
  if (ComboBox1.ItemIndex<0)
    or (ComboBox2.ItemIndex<0)
    or (ComboBox4.ItemIndex<0)
    or ((RadioButton1.Checked=false) and (RadioButton2.Checked=false)) then
  begin
    ChangeLabels(0,0,0,'Не выбрано одно из значений!');
    Exit;
  end;
  if not ((Rz>0) and (Pizm>0) and (L>0) and (D>0) and (H>0) and (B>0)) then
  begin
    ChangeLabels(0,0,0,'Значение должно быть больше нуля!');
    Exit;
  end;
  if (Re<0) then
  begin
    ChangeLabels(0,0,0,'Значение не может быть меньше нуля!');
    Exit;
  end;

  // Расчёты
  case ComboBox1.ItemIndex*10+ComboBox2.ItemIndex of
    00: K:=2;
    01: K:=1.5;
    02: K:=1.4;

    10: K:=11.32;
    11: K:=1.2;

    20: K:=1.3;
    21: K:=1.2;
    22: K:=1.1;

    30: K:=2.5;
    31: K:=1.51;
    32: K:=1.2;

    40: K:=1.5;
    41: K:=1.3;
    42: K:=1.2;

    50: K:=1.4;
    51: K:=1.1;
    52: K:=1.0;

    60: K:=2.4;
    61: K:=1.56;
    62: K:=1.2;

    70: K:=2.4;
    71: K:=1.36;
    72: K:=1.2;
  end;
  Pras:=Pizm*K;
  if Re=0 then Ri:=Rz else
    if Re<=Rz then
    begin
      ChangeLabels(0,0,0,'Достаточно естественных заземлителей');
      Exit;
    end else Ri:=(Re*Rz)/(Re-Rz);
  if H>0.5 then Rod:=(Pras/(2*pi*L))*(ln((2*L)/D)+0.5*ln((4*(H+L/2)+L)/(5*(H+L/2)-L)))
    else Rod:=(Pras/(2*pi*L))*ln((4*L)/D);

  if Rod<=Ri then
  begin
    ChangeLabels(1,0,0,'Достаточно одного заземлителя');
    Exit;
  end;

  // Определяем ориентировочное число стержней по алгоритму: n=Rod/(K*Ri)
  // K=1, округляем в большую сторону
  n:=trunc(Rod/Ri)+1;

  if (RadioButton2.Checked) and (n<4) then n:=4;

  // Пример расчета коэффициента использования Nst
  // Nst:=Nst15-(Nst15-Nst20)*(n-15)/(20-15),
  // где Nst15 - значение коэффициента использования при 15 трубах,
  // Nst20 - значение коэффициента использования при 20 трубах,
  // n - количество труб
  if RadioButton1.Checked then i:=ComboBox4.ItemIndex else i:=10+ComboBox4.ItemIndex;
  case i of
    00: case n of
          2..3: Nst:=0.86-(0.86-0.78)*(n-2)/(3-2);
          4..5: Nst:=0.78-(0.78-0.7)*(n-3)/(5-3);
          6..10: Nst:=0.7-(0.7-0.59)*(n-5)/(10-5);
          11..15: Nst:=0.59-(0.59-0.54)*(n-10)/(15-10);
          16..20: Nst:=0.54-(0.54-0.49)*(n-15)/(20-15);
        else
          Nst:=0.49;
        end;
    01: case n of
          2..3: Nst:=0.91-(0.91-0.87)*(n-2)/(3-2);
          4..5: Nst:=0.87-(0.87-0.81)*(n-3)/(5-3);
          6..10: Nst:=0.81-(0.81-0.75)*(n-5)/(10-5);
          11..15: Nst:=0.75-(0.75-0.71)*(n-10)/(15-10);
          16..20: Nst:=0.71-(0.71-0.68)*(n-15)/(20-15);
        else
          Nst:=0.68;
        end;
    02: case n of
          2..3: Nst:=0.94-(0.94-0.91)*(n-2)/(3-2);
          4..5: Nst:=0.91-(0.91-0.87)*(n-3)/(5-3);
          6..10: Nst:=0.87-(0.87-0.81)*(n-5)/(10-5);
          11..15: Nst:=0.81-(0.81-0.78)*(n-10)/(15-10);
          16..20: Nst:=0.78-(0.78-0.77)*(n-15)/(20-15);
        else
          Nst:=0.77;
        end;

    10: case n of
          4..6: Nst:=0.69-(0.69-0.62)*(n-4)/(6-4);
          7..10: Nst:=0.62-(0.62-0.55)*(n-6)/(10-6);
          11..20: Nst:=0.55-(0.55-0.47)*(n-10)/(20-10);
          21..40: Nst:=0.47-(0.47-0.41)*(n-20)/(40-20);
          41..60: Nst:=0.41-(0.41-0.39)*(n-40)/(60-40);
        else
          Nst:=0.39;
        end;
    11: case n of
          4..6: Nst:=0.78-(0.78-0.73)*(n-4)/(6-4);
          7..10: Nst:=0.73-(0.73-0.69)*(n-6)/(10-6);
          11..20: Nst:=0.69-(0.69-0.64)*(n-10)/(20-10);
          21..40: Nst:=0.64-(0.64-0.58)*(n-20)/(40-20);
          41..60: Nst:=0.58-(0.58-0.55)*(n-40)/(60-40);
        else
          Nst:=0.55;
        end;
    12: case n of
          4..6: Nst:=0.85-(0.85-0.8)*(n-4)/(6-4);
          7..10: Nst:=0.8-(0.8-0.75)*(n-6)/(10-6);
          11..20: Nst:=0.75-(0.75-0.71)*(n-10)/(20-10);
          21..40: Nst:=0.71-(0.71-0.67)*(n-20)/(40-20);
          41..60: Nst:=0.67-(0.67-0.65)*(n-40)/(60-40);
        else
          Nst:=0.65;
        end;
  end;

  i:=i*10;
  case n of
    2..3: inc(i,0);
    4..8: inc(i,1);
    9..10: inc(i,2);
    11..20: inc(i,3);
    21..30: inc(i,4);
    31..50: inc(i,5);
    51..60: inc(i,6);
  else
    inc(i,7);
  end;

  case i of
    000: Np:=1-(1-0.77)*(n-2)/(4-2);
    001: Np:=0.77-(0.77-0.67)*(n-4)/(8-4);
    002: Np:=0.67-(0.67-0.62)*(n-8)/(10-8);
    003: Np:=0.62-(0.62-0.42)*(n-10)/(20-10);
    004: Np:=0.42-(0.42-0.31)*(n-20)/(30-20);
    005: Np:=0.31-(0.31-0.21)*(n-30)/(50-30);
    006: Np:=0.21-(0.21-0.20)*(n-50)/(60-50);
    007: Np:=0.20;

    010: Np:=1-(1-0.89)*(n-2)/(4-2);
    011: Np:=0.89-(0.89-0.79)*(n-4)/(8-4);
    012: Np:=0.79-(0.79-0.75)*(n-8)/(10-8);
    013: Np:=0.75-(0.75-0.56)*(n-10)/(20-10);
    014: Np:=0.56-(0.56-0.46)*(n-20)/(30-20);
    015: Np:=0.46-(0.46-0.36)*(n-30)/(50-30);
    016: Np:=0.36-(0.36-0.27)*(n-50)/(60-50);
    017: Np:=0.27;

    020: Np:=1-(1-0.92)*(n-2)/(4-2);
    021: Np:=0.92-(0.92-0.85)*(n-4)/(8-4);
    022: Np:=0.85-(0.85-0.82)*(n-8)/(10-8);
    023: Np:=0.82-(0.82-0.68)*(n-10)/(20-10);
    024: Np:=0.68-(0.68-0.58)*(n-20)/(30-20);
    025: Np:=0.58-(0.58-0.49)*(n-30)/(50-30);
    026: Np:=0.49-(0.49-0.36)*(n-50)/(60-50);
    027: Np:=0.36;


    101: Np:=0.45-(0.45-0.36)*(n-4)/(8-4);
    102: Np:=0.36-(0.36-0.34)*(n-8)/(10-8);
    103: Np:=0.34-(0.34-0.27)*(n-10)/(20-10);
    104: Np:=0.27-(0.27-0.24)*(n-20)/(30-20);
    105: Np:=0.24-(0.24-0.21)*(n-30)/(50-30);
    106: Np:=0.21-(0.21-0.20)*(n-50)/(60-50);
    107: Np:=0.20;

    111: Np:=0.55-(0.55-0.43)*(n-4)/(8-4);
    112: Np:=0.43-(0.43-0.40)*(n-8)/(10-8);
    113: Np:=0.40-(0.40-0.32)*(n-10)/(20-10);
    114: Np:=0.32-(0.32-0.30)*(n-20)/(30-20);
    115: Np:=0.30-(0.30-0.28)*(n-30)/(50-30);
    116: Np:=0.28-(0.28-0.27)*(n-50)/(60-50);
    117: Np:=0.27;

    121: Np:=0.70-(0.70-0.60)*(n-4)/(8-4);
    122: Np:=0.60-(0.60-0.56)*(n-8)/(10-8);
    123: Np:=0.56-(0.56-0.45)*(n-10)/(20-10);
    124: Np:=0.45-(0.45-0.41)*(n-20)/(30-20);
    125: Np:=0.41-(0.41-0.37)*(n-30)/(50-30);
    126: Np:=0.37-(0.37-0.36)*(n-50)/(60-50);
    127: Np:=0.36;
  end;

  n:=trunc(Rod/(Nst*Ri))+1;

  if RadioButton1.Checked then Lp:=(n-1)*(ComboBox4.ItemIndex+1)*L else Lp:=n*(ComboBox4.ItemIndex+1)*L;
  Rp:=((Pras/(2*pi*Lp))*ln((2*Lp*Lp)/(B*H)))/Np;

  Rst:=(Rp*Ri)/(Rp-Ri);
  n:=trunc(Rod/(Nst*Rst))+1;

  ChangeLabels(n,(ComboBox4.ItemIndex+1)*L,Lp,'');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  TabSheet1.Show;
end;

procedure TForm1.ChangeLabels(n: integer; b,l: real; s: string);
begin
  Label11.Caption:=IntToStr(n);
  Label13.Caption:=FloatToStrF(b,ffFixed,100,2);
  Label15.Caption:=FloatToStrF(l,ffFixed,100,2);

  Label11.Left:=Label7.Left+Label7.Width;
  Label13.Left:=Label12.Left+Label12.Width;
  Label16.Left:=Label13.Left+Label13.Width;
  Label15.Left:=Label14.Left+Label14.Width;
  Label17.Left:=Label15.Left+Label15.Width;

  Label18.Caption:=s;
  if s='' then Label18.Visible:=false
    else Label18.Visible:=true;
end;

procedure TForm1.ComboBox3Select(Sender: TObject);
begin
  case ComboBox3.ItemIndex of
    0: minPizm:=400;
    1: minPizm:=150;
    2: minPizm:=40;
    3: minPizm:=8;
    4: minPizm:=9;
    5: minPizm:=50;
    6: minPizm:=0.2;
  end;
  case ComboBox3.ItemIndex of
    0: maxPizm:=700;
    1: maxPizm:=400;
    2: maxPizm:=150;
    3: maxPizm:=70;
    4: maxPizm:=530;
    5: maxPizm:=50;
    6: maxPizm:=1;
  end;
  case ComboBox3.ItemIndex of
    0: Edit7.Text:='700';
    1: Edit7.Text:='300';
    2: Edit7.Text:='100';
    3: Edit7.Text:='40';
    4: Edit7.Text:='200';
    5: Edit7.Text:='50';
    6: Edit7.Text:='0,6';
  end;
end;

end.

