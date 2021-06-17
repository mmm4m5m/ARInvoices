unit fSettings;

{$mode objfpc}{$H+}

{-$define ARITest}

interface

uses
  Classes, SysUtils, DB, SQLDB, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, DBCtrls;

type

  { TfoSettings }

  TfoSettings = class(TForm)
    bDelete: TButton;
    Query: TSQLQuery;
    QueryID: TAutoIncField;
    QueryNAME: TMemoField;
    QueryEMAIL: TMemoField;
    QueryADDRESS: TMemoField;
    QueryPHONE: TMemoField;
    QueryNUMBER: TMemoField;
    QueryCURRENCY: TMemoField;
    QueryINVOICE: TMemoField;
    QueryTAX: TFloatField;
    QueryTERMS: TMemoField;
    DataSource1: TDataSource;
    Panel4: TPanel;
    Panel2: TPanel;
    Label1: TLabel;
    eName: TDBEdit;
    Panel3: TPanel;
    Label2: TLabel;
    eEmail: TDBEdit;
    Panel5: TPanel;
    Label3: TLabel;
    eAddress: TDBEdit;
    Panel6: TPanel;
    Label4: TLabel;
    ePhone: TDBEdit;
    Panel7: TPanel;
    Label5: TLabel;
    eNumber: TDBEdit;
    Panel8: TPanel;
    Label6: TLabel;
    eCurrency: TDBEdit;
    Panel11: TPanel;
    Label9: TLabel;
    eInvoice: TDBEdit;
    Panel9: TPanel;
    Label7: TLabel;
    mTerms: TDBMemo;
    Panel10: TPanel;
    Label8: TLabel;
    eTax: TDBEdit;
    Panel1: TPanel;
    Button4: TButton;
    Button6: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure bDeleteClick(Sender: TObject);
    procedure eEmailChange(Sender: TObject);
    procedure ePhoneChange(Sender: TObject);
    procedure eNumberChange(Sender: TObject);
    procedure eCurrencyChange(Sender: TObject);
    procedure eTaxChange(Sender: TObject);
    procedure QueryBeforePost(DataSet: TDataSet);
    procedure QueryMemoGetText(Sender: TField; var aText: string; DisplayText: Boolean);
    procedure QueryEMAILSetText(Sender: TField; const aText: string);
    procedure QueryPHONEGetText(Sender: TField; var aText: string; DisplayText: Boolean);
    procedure QueryPHONESetText(Sender: TField; const aText: string);
    procedure QueryNUMBERGetText(Sender: TField; var aText: string; DisplayText: Boolean);
    procedure QueryNUMBERSetText(Sender: TField; const aText: string);
    procedure QueryCURRENCYSetText(Sender: TField; const aText: string);
    procedure QueryTERMSSetText(Sender: TField; const aText: string);
    procedure QueryTAXSetText(Sender: TField; const aText: string);
  private

  public

  end;

implementation

uses
  dmARInvoices;

{$ifdef ARITest}
procedure TestInit(Query: TSQLQuery; bDelete: TButton);
begin
  if Query.State=dsInsert then begin
    Query.FieldByName('NAME'    ).AsString:='n';
    Query.FieldByName('EMAIL'   ).AsString:='ee@hh.dd';
    Query.FieldByName('ADDRESS' ).AsString:='a';
    Query.FieldByName('PHONE'   ).AsString:='1234567';
    Query.FieldByName('NUMBER'  ).AsString:='123456';
    Query.FieldByName('CURRENCY').AsString:='cur';
    Query.FieldByName('INVOICE' ).AsString:='i';
    Query.FieldByName('TERMS'   ).AsString:='t';
    Query.FieldByName('TAX'     ).AsFloat:=2;
  end else begin
    bDelete.Enabled:=TRUE;
    bDelete.Visible:=TRUE;
  end;
end;
{$endif ARITest}


{$R *.lfm}

{ TfoSettings }

procedure TfoSettings.FormCreate(Sender: TObject);
begin
  Query.SQL.Text:=Query.SQL.Text+' where ID='+IntToStr(dm.ID);
end;

procedure TfoSettings.FormShow(Sender: TObject);
begin
  QueryTAX.DisplayFormat:=SARITaxFormat;
  QueryTAX.EditFormat:=SARIEditFormat;
  Query.Open;
  if Query.IsEmpty then Query.Insert else Query.Edit;

  {$ifdef ARITest} TestInit(Query, bDelete); {$endif ARITest}
end;

procedure TfoSettings.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if ModalResult<>mrOk then Exit;
  Query.Post;
  dm.Load(Query);
end;

procedure TfoSettings.bDeleteClick(Sender: TObject);
begin
  {$ifdef ARITest} Query.Delete; {$endif ARITest}
end;

procedure TfoSettings.eEmailChange(Sender: TObject);
begin
  EmailValidate(TDBEdit(Sender));
end;

procedure TfoSettings.ePhoneChange(Sender: TObject);
begin
  PhoneValidate(TDBEdit(Sender));
end;

procedure TfoSettings.eNumberChange(Sender: TObject);
begin
  NumberValidate(TDBEdit(Sender));
end;

procedure TfoSettings.eCurrencyChange(Sender: TObject);
begin
  CurrencyValidate(TDBEdit(Sender));
end;

procedure TfoSettings.eTaxChange(Sender: TObject);
begin
  TaxValidate(TDBEdit(Sender));
end;

procedure TfoSettings.QueryBeforePost(DataSet: TDataSet);
begin
  // not needed anymore?
  EmailValidate   (QueryEMAIL   .AsString, QueryTAX     .DisplayName);
  PhoneValidate   (QueryPHONE   .AsString, QueryPHONE   .DisplayName);
  NumberValidate  (QueryNUMBER  .AsString, QueryNUMBER  .DisplayName);
  CurrencyValidate(QueryCURRENCY.AsString, QueryCURRENCY.DisplayName);
  TaxValidate     (QueryTAX     .AsString, QueryTAX     .DisplayName);
end;

procedure TfoSettings.QueryMemoGetText(Sender: TField; var aText: string; DisplayText: Boolean);
begin
  aText:=Sender.AsString;
end;

procedure TfoSettings.QueryEMAILSetText(Sender: TField; const aText: string);
begin
  EmailValidate(aText, Sender.DisplayName);
  Sender.AsString:=aText;
end;

procedure TfoSettings.QueryPHONEGetText(Sender: TField; var aText: string; DisplayText: Boolean);
begin
  PhoneGetText(Sender, aText, DisplayText);
end;

procedure TfoSettings.QueryPHONESetText(Sender: TField; const aText: string);
var s: string;
begin
  s:=GetDigitsOnly(aText);
  PhoneValidate(s, Sender.DisplayName);
  Sender.AsString:=s;
end;

procedure TfoSettings.QueryNUMBERGetText(Sender: TField; var aText: string; DisplayText: Boolean);
begin
  NumberGetText(Sender, aText, DisplayText);
end;

procedure TfoSettings.QueryNUMBERSetText(Sender: TField; const aText: string);
var s: string;
begin
  s:=GetDigitsOnly(aText);
  NumberValidate(s, Sender.DisplayName);
  Sender.AsString:=s;
end;

procedure TfoSettings.QueryCURRENCYSetText(Sender: TField; const aText: string);
begin
  CurrencyValidate(aText, Sender.DisplayName);
  Sender.AsString:=aText;
end;

procedure TfoSettings.QueryTERMSSetText(Sender: TField; const aText: string);
var
  sl: TStringList;
  i : integer;
begin
  sl:=TStringList.Create;
  try
    sl.Text:=aText;
    for i:=sl.Count-1 downto 0 do if sl[i]='' then sl.Delete(i);
    Sender.AsString:=sl.Text;
  finally
    sl.Free;
  end;
end;

procedure TfoSettings.QueryTAXSetText(Sender: TField; const aText: string);
begin
  TaxValidate(aText, Sender.DisplayName);
  Sender.AsString:=aText;
end;

end.

