unit fInvoices;

// todo: View Invoice
// todo: Set 'Paid' button and DBGrid click

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, SQLDB, Forms, Controls, Graphics, Dialogs, DBGrids,
  ExtCtrls, StdCtrls, Grids;

type

  { TfoInvoices }

  TfoInvoices = class(TForm)
    Query: TSQLQuery;
    QueryDUEDATE: TMemoField;
    QueryID: TAutoIncField;
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    Panel1: TPanel;
    bInvoice: TButton;
    bSetPaid: TButton;
    Button6: TButton;
    QueryIDATE: TMemoField;
    QueryINUMBER: TMemoField;
    QueryNAME: TMemoField;
    QuerySTATUS: TLongintField;
    QueryTERMS: TMemoField;
    procedure bSetPaidClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure bInvoiceClick(Sender: TObject);
    procedure QueryAfterScroll(DataSet: TDataSet);
    procedure QuerySTATUSGetText(Sender: TField; var aText: string; DisplayText: Boolean);
    procedure DBGridDrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
  private

  public

  end;

implementation

uses
  dmARInvoices, fInvoice;

{$R *.lfm}

{ TfoInvoices }

procedure TfoInvoices.FormShow(Sender: TObject);
begin
  Query.Open;
end;

procedure TfoInvoices.bSetPaidClick(Sender: TObject);
begin
  // todo: set DueDate to PaidDate
  ShowMessage('Not implemented.');
end;

procedure TfoInvoices.bInvoiceClick(Sender: TObject);
var f: TForm;
begin
  f:=TfoInvoice.Create(Self);
  try
    f.ShowModal;
  finally
    f.Free;
  end;
end;

procedure TfoInvoices.QueryAfterScroll(DataSet: TDataSet);
begin
  bSetPaid.Enabled:=QuerySTATUS.AsInteger<>IARISPaid;
end;

procedure TfoInvoices.QuerySTATUSGetText(Sender: TField; var aText: string; DisplayText: Boolean);
begin
  StatusGetText(InvoiceStatus(Sender.AsInteger, StrToDate(QueryDUEDATE.AsString, SARIDateFormat, '-')), aText, DisplayText);
end;

procedure TfoInvoices.DBGridDrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  if (Column.Field<>QuerySTATUS) or
     (InvoiceStatus(QuerySTATUS.AsInteger, StrToDate(QueryDUEDATE.AsString, SARIDateFormat, '-'))<>IARISOverdue) then Exit;
  DBGrid.Canvas.FillRect(Rect);
  DBGrid.Canvas.Font.Style:=[fsBold];
  DBGrid.Canvas.Font.Color:=clRed;
  DBGrid.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

end.

