unit fClients;

{$mode objfpc}{$H+}

interface

uses
  MaskEdit, DBGrids, dmARInvoices, // TARIDBGrid: dmARInvoices after DBGrids!
  Classes, SysUtils, DB, SQLDB, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls;

type

  { TfoClients }

  TfoClients = class(TForm)
    Query: TSQLQuery;
    QueryID: TAutoIncField;
    QueryNAME: TMemoField;
    QueryEMAIL: TMemoField;
    QueryADDRESS: TMemoField;
    QueryPHONE: TMemoField;
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    Panel1: TPanel;
    Button6: TButton;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure DBGridColEnter(Sender: TObject);
    procedure DataSourceStateChange(Sender: TObject);
    procedure QueryBeforePost(DataSet: TDataSet);
    procedure QueryMemoGetText(Sender: TField; var aText: string; DisplayText: Boolean);
    procedure QueryMemoSetText(Sender: TField; const aText: string);
    procedure QueryEMAILSetText(Sender: TField; const aText: string);
    procedure QueryPHONEGetText(Sender: TField; var aText: string; DisplayText: Boolean);
    procedure QueryPHONESetText(Sender: TField; const aText: string);
  private
    procedure OnEditorTextChanged(Edit: TCustomMaskEdit; Field: TField);
  public

  end;

implementation

{$R *.lfm}

{ TfoClients }

procedure TfoClients.FormShow(Sender: TObject);
begin
  Query.Open;
  DBGrid.SelectedIndex:=1;
  DBGrid.OnEditorTextChanged:=@OnEditorTextChanged;
end;

procedure TfoClients.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if Query.State<>dsBrowse then Query.Post;
end;

procedure TfoClients.OnEditorTextChanged(Edit: TCustomMaskEdit; Field: TField);
begin
  if Field=QueryEMAIL then EmailValidate(Edit);
  if Field=QueryPHONE then PhoneValidate(Edit);
end;

procedure TfoClients.DBGridColEnter(Sender: TObject);
begin
  if DBGrid.SelectedIndex=0 then DBGrid.SelectedIndex:=1;
end;

procedure TfoClients.DataSourceStateChange(Sender: TObject);
begin
  if Query.State=dsInsert then DBGrid.SelectedIndex:=1;
end;

procedure TfoClients.QueryBeforePost(DataSet: TDataSet);
begin
  // not needed anymore?
  EmailValidate(QueryEMAIL.AsString, QueryEMAIL.DisplayName);
  PhoneValidate(QueryPHONE.AsString, QueryPHONE.DisplayName);
end;

procedure TfoClients.QueryMemoGetText(Sender: TField; var aText: string; DisplayText: Boolean);
begin
  aText:=Sender.AsString;
end;

procedure TfoClients.QueryMemoSetText(Sender: TField; const aText: string);
begin
  Sender.AsString:=aText;
end;

procedure TfoClients.QueryEMAILSetText(Sender: TField; const aText: string);
begin
  EmailValidate(aText, Sender.DisplayName);
  Sender.AsString:=aText;
end;

procedure TfoClients.QueryPHONEGetText(Sender: TField; var aText: string; DisplayText: Boolean);
begin
  PhoneGetText(Sender, aText, DisplayText);
end;

procedure TfoClients.QueryPHONESetText(Sender: TField; const aText: string);
var s: string;
begin
  s:=GetDigitsOnly(aText);
  PhoneValidate(s, Sender.DisplayName);
  Sender.AsString:=s;
end;

end.

