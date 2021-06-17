unit fGJReport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, SQLDB, Forms, Controls, Graphics, Dialogs, DBGrids,
  ExtCtrls, StdCtrls, Grids, Types;

type

  { TfoGJReport }

  TfoGJReport = class(TForm)
    Query: TSQLQuery;
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    Grid: TStringGrid;
    Panel1: TPanel;
    Button6: TButton;
    QueryAmount: TFloatField;
    QueryDueDate: TStringField;
    QueryEvent: TStringField;
    QueryIDate: TStringField;
    QuerySTATUS: TLongintField;
    procedure FormShow(Sender: TObject);
    procedure GridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure QuerySTATUSGetText(Sender: TField; var aText: string; DisplayText: Boolean);
    procedure DBGridDrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
  private

  public

  end;

implementation

uses
  dmARInvoices;

{$R *.lfm}

{ TfoGJReport }

procedure TfoGJReport.FormShow(Sender: TObject);
var
  r: integer;
  a: string;
begin
  Grid.Cells[1, 0]:=dm.BName;
  Grid.Cells[1, 1]:='GENERAL JOURNAL';
  Grid.Cells[1, 2]:='Date: '+FormatDateTime(SARIDateFormat, Date);
  Grid.Cells[0, 3]:='Date';
  Grid.Cells[1, 3]:='Account name';
  Grid.Cells[2, 3]:='Debit';
  Grid.Cells[3, 3]:='Credit';
  r:=3;
  Grid.RowCount:=r+1;
  Query.Open;
  while not Query.Eof do begin
    Grid.RowCount:=Grid.RowCount+3;
    Grid  .Cells[0, r+Query.RecNo  ]:=QueryEvent.AsString; //FormatDateTime(SARIDateFormat, QueryEvent.AsDateTime);
    a:=FormatFloat(dm.PriceFormat, QueryAmount.AsFloat);
    Grid  .Cells[2, r+Query.RecNo  ]:=a;
    Grid  .Cells[3, r+Query.RecNo+1]:=a;
    if (QuerySTATUS.AsInteger=IARISPaid) and (QueryIDate.AsString=QueryDueDate.AsString) then begin
      Grid.Cells[1, r+Query.RecNo  ]:='Cash';
      Grid.Cells[1, r+Query.RecNo+1]:='-      Account Receivable';
      Grid.Cells[1, r+Query.RecNo+2]:='(cash for sold widgets)'
    end else if (QuerySTATUS.AsInteger=IARISPaid) and (QueryEvent.AsString=QueryDueDate.AsString) then begin
      Grid.Cells[1, r+Query.RecNo  ]:='Cash';
      Grid.Cells[1, r+Query.RecNo+1]:='-      Account Receivable';
      Grid.Cells[1, r+Query.RecNo+2]:=Format('(cash from clients billed on %s )', [QueryIDate.AsString]);
    end else begin
      Grid.Cells[1, r+Query.RecNo  ]:='Account Receivable';
      Grid.Cells[1, r+Query.RecNo+1]:='-      Sales Revenue';
      Grid.Cells[1, r+Query.RecNo+2]:='(billed clients for widgets)';
    end;
    Inc(r, 2);
    Query.Next;
  end;
end;

procedure TfoGJReport.GridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);

  procedure DrawBorder;
  begin
    Grid.Canvas.Pen.Width:=1;
    Inc(aRect.Left);
    Inc(aRect.Top);
    Dec(aRect.Bottom);
    Grid.Canvas.MoveTo(aRect.Left , aRect.Top);
    Grid.Canvas.LineTo(aRect.Left , aRect.Bottom);
    Grid.Canvas.LineTo(aRect.Right, aRect.Bottom);
    Grid.Canvas.LineTo(aRect.Right, aRect.Top);
    Grid.Canvas.LineTo(aRect.Left , aRect.Top);
  end;

begin
  if (aCol=1) and (aRow=3) then begin
    Grid.Canvas.Font.Style:=[];
    Grid.DefaultDrawCell(aCol, aRow, aRect, aState);
  end;
  if aRow<3 then begin
    if (aCol=0) or (aCol>1) then begin
      Grid.Canvas.Brush.Color:=Grid.Color;
      Grid.Canvas.FillRect(aRect);
    end else begin
    //Grid.Canvas.Pen.Style:=psSolid;
      Dec(aRect.Right);
      Grid.Canvas.Pen.Color:=Grid.FixedColor;
      DrawBorder;
    end;
  end;
  if aRow=3 then begin
  //Grid.Canvas.Pen.Style:=psSolid;
  //Grid.Canvas.Pen.Color:=clBlack;
    if aCol=0 then Inc(aRect.Left);
    if aCol=3 then Dec(aRect.Right);
    DrawBorder;
  end;
end;

procedure TfoGJReport.QuerySTATUSGetText(Sender: TField; var aText: string; DisplayText: Boolean);
begin
  StatusGetText(InvoiceStatus(Sender.AsInteger, StrToDate(QueryDUEDATE.AsString, SARIDateFormat, '-')), aText, DisplayText);
end;

procedure TfoGJReport.DBGridDrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  if (Column.Field<>QuerySTATUS) or
     (InvoiceStatus(QuerySTATUS.AsInteger, StrToDate(QueryDUEDATE.AsString, SARIDateFormat, '-'))<>IARISOverdue) then Exit;
  DBGrid.Canvas.FillRect(Rect);
  DBGrid.Canvas.Font.Style:=[fsBold];
  DBGrid.Canvas.Font.Color:=clRed;
  DBGrid.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

end.

