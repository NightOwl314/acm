{ВаСёК}{2008}
program Grounding;

uses
  Forms,
  UnitMain in 'UnitMain.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Расчёт защитного заземления';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
