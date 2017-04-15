unit Unit2;

interface

uses
  SysUtils, Classes, DB, IBCustomDataSet, IBTable, IBDatabase, IBQuery,
  ADODB;

type
  TDataModule2 = class(TDataModule)
    Acm: TIBDatabase;
    IBTransaction1: TIBTransaction;
    IBDS1: TDataSource;
    IBDataSet1: TIBDataSet;
    IBDataSet1ID_MOODLE_COURSE: TIntegerField;
    IBDataSet1TEMA: TIBStringField;
    IBDataSet2: TIBDataSet;
    IBDS2: TDataSource;
    IBDataSet2PROBLEMA: TIBStringField;
    IBDataSet2ID_MOODLE_COURSE: TIntegerField;
    ADOConnection1: TADOConnection;
    ADODataSet1: TADODataSet;
    ADODS1: TDataSource;
    ADODataSet1ID_MOODLE_COURSE: TLargeintField;
    ADODataSet1COURSE: TStringField;
    IBDataSet3: TIBDataSet;
    IBDS3: TDataSource;
    ADODataSet2: TADODataSet;
    ADODS2: TDataSource;
    IBQuery1: TIBQuery;
    ADOQuery1: TADOQuery;
    IBQuery2: TIBQuery;
    ADOQuery2: TADOQuery;
    IBDataSet4: TIBDataSet;
    IBDS4: TDataSource;
    IBDataSet3NAME: TIBStringField;
    IBDataSet4NAME: TIBStringField;
    ADODataSet3: TADODataSet;
    ADODS3: TDataSource;
    ADODataSet3COURSE: TStringField;
    ADODataSet3ID_PS_TEMA: TIntegerField;
    IBDataSet5: TIBDataSet;
    IBDS5: TDataSource;
    IBDataSet5TEMA: TIBStringField;
    ADODataSet3NOMER_SECTION: TLargeintField;
    ADODS4: TDataSource;
    ADODataSet4: TADODataSet;
    ADODataSet4section: TLargeintField;
    IBQuery3: TIBQuery;
    IBQuery3ID_TM: TIntegerField;
    ADOQuery3: TADOQuery;
    IBDataSet5ID_PS_TEMA: TIntegerField;
    ADODataSet2fullname: TStringField;
    IBDataSet6: TIBDataSet;
    IBStringField1: TIBStringField;
    IBDS6: TDataSource;
    ADODS7: TDataSource;
    ADODataSet7: TADODataSet;
    ADODataSet7name: TStringField;
    ADODS5: TDataSource;
    ADODataSet5: TADODataSet;
    ADODataSet5firstname: TStringField;
    ADODS6: TDataSource;
    ADODataSet6: TADODataSet;
    ADODataSet6lastname: TStringField;
    ADODS8: TDataSource;
    ADODataSet8: TADODataSet;
    ADODataSet8COURSE: TStringField;
    ADODataSet8NOMER_SECTION: TLargeintField;
    ADODataSet8DANNYE: TStringField;
    ADODataSet8SURNAME: TStringField;
    ADODataSet8NAME: TStringField;
    ADOQuery4: TADOQuery;
    ADOQuery4count: TLargeintField;
    ADOQuery5: TADOQuery;
    ADOQuery5id: TLargeintField;
    ADOQuery6: TADOQuery;
    ADOQuery6assignment: TLargeintField;
    ADOQuery7: TADOQuery;
    ADOQuery7userid: TLargeintField;
    ADOQuery8: TADOQuery;
    ADOQuery9: TADOQuery;
    IBDataSet8: TIBDataSet;
    IBDS8: TDataSource;
    IBDataSet8OBKOLVO: TIntegerField;
    IBDataSet9: TIBDataSet;
    IBDS9: TDataSource;
    IBDataSet9KOLVORESH: TIntegerField;
    IBDataSet10: TIBDataSet;
    IBDS10: TDataSource;
    IBDataSet10KOLVONERESH: TIntegerField;
    ADOQuery10: TADOQuery;
    IBTransaction2: TIBTransaction;
    IBTransaction3: TIBTransaction;
    procedure FetchAllIBDataSet3(DataSet: TDataSet);
    procedure FetchAllIBDataSet4(DataSet: TDataSet);
    procedure FetchAllIBDataSet6(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DataModule2: TDataModule2;

implementation

{$R *.dfm}

procedure TDataModule2.FetchAllIBDataSet3(DataSet: TDataSet);
begin
DataModule2.IBDataSet3.FetchAll;
end;

procedure TDataModule2.FetchAllIBDataSet4(DataSet: TDataSet);
begin
DataModule2.IBDataSet4.FetchAll;
end;

procedure TDataModule2.FetchAllIBDataSet6(DataSet: TDataSet);
begin
DataModule2.IBDataSet6.FetchAll;
end;

end.
