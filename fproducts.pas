unit fProducts;

{$mode objfpc}{$H+}

interface

uses
  MaskEdit, DBGrids, dmARInvoices, // TARIDBGrid: dmARInvoices after DBGrids!
  Classes, SysUtils, DB, SQLDB, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls;

type

  { TfoProducts }

  TfoProducts = class(TForm)
    Query: TSQLQuery;
    QueryID: TAutoIncField;
    QueryNAME: TMemoField;
    QueryPRICE: TFloatField;
    QueryTAXABLE: TLongintField;
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    Panel1: TPanel;
    Button6: TButton;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure DBGridColEnter(Sender: TObject);
    procedure DataSourceStateChange(Sender: TObject);
    procedure QueryBeforePost(DataSet: TDataSet);
    procedure QueryPRICESetText(Sender: TField; const aText: string);
  private
    procedure OnEditorTextChanged(Edit: TCustomMaskEdit; Field: TField);
  public

  end;

implementation

{$R *.lfm}

{ TfoProducts }

procedure TfoProducts.FormShow(Sender: TObject);
begin
  QueryPRICE.DisplayFormat:=dm.PriceFormat;
  QueryPRICE.EditFormat:=SARIEditFormat;
  Query.Open;
  DBGrid.SelectedIndex:=1;
  DBGrid.OnEditorTextChanged:=@OnEditorTextChanged;
end;

procedure TfoProducts.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if Query.State<>dsBrowse then Query.Post;
end;

procedure TfoProducts.OnEditorTextChanged(Edit: TCustomMaskEdit; Field: TField);
begin
  if Field=QueryPRICE then PriceValidate(Edit);
end;

procedure TfoProducts.DBGridColEnter(Sender: TObject);
begin
  if DBGrid.SelectedIndex=0 then DBGrid.SelectedIndex:=1;
end;

procedure TfoProducts.DataSourceStateChange(Sender: TObject);
begin
  if Query.State=dsInsert then begin
    DBGrid.SelectedIndex:=1;
    if QueryTAXABLE.IsNull then QueryTAXABLE.AsInteger:=1;
  end;
end;

procedure TfoProducts.QueryBeforePost(DataSet: TDataSet);
begin
  // not needed anymore?
  PriceValidate(QueryPRICE.AsString, QueryPRICE.DisplayName);
end;

procedure TfoProducts.QueryPRICESetText(Sender: TField; const aText: string);
begin
  PriceValidate(aText, Sender.DisplayName);
  Sender.AsString:=aText;
end;

end.

