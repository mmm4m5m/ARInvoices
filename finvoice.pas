unit fInvoice;

// todo: item/row number after Del row/item
// todo: move summary on DBGrid column resize? On DBGrid horizontal scroll?
// todo: View Invoice
// todo: Set 'Paid' button and DBGrid click
// todo: generate new/next inv.number
// todo: add validation on change - remove validation on save
// todo: items in terms combobox. auto calc Due date for terms '1 day', '1 week', etc.
// todo: integer to TObject warnings
// todo: consider EditMask for input (for edit the tax)
// todo: Invoice Edit and status 'incomplete' (long invoice - save and stop, then edit again and continue)

{$mode objfpc}{$H+}

interface

uses
  MaskEdit, DBGrids, dmARInvoices, // TARIDBGrid: dmARInvoices after DBGrids!
  Classes, SysUtils, SQLDB, memds, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Grids, DBCtrls, Buttons, EditBtn, DateTimePicker, DB, Types;

type

  { TfoInvoice }

  TfoInvoice = class(TForm)
    bNumber: TButton;
    Query: TMemDataset;
    DataSource: TDataSource;
    qInvoices: TSQLQuery;
    qInvoicesID: TAutoIncField;
    qInvoicesID_CLIENTS: TLongintField;
    qInvoicesINUMBER: TMemoField;
    qInvoicesIDATE: TMemoField;
    qInvoicesICURRENCY: TMemoField;
    qInvoicesTAX: TFloatField;
    qInvoicesTERMS: TMemoField;
    qInvoicesDUEDATE: TMemoField;
    qInvoicesNOTES: TMemoField;
    qInvoicesTERMSNOTES: TMemoField;
    qInvoicesSTATUS: TLongintField;
    dsInvoices: TDataSource;
    qInvRows: TSQLQuery;
    qInvRowsID: TAutoIncField;
    qInvRowsID_INVOICES: TLongintField;
    qInvRowsID_PRODUCTS: TLongintField;
    qInvRowsPRICE: TFloatField;
    qInvRowsQUANTITY: TFloatField;
    qInvRowsTAXABLE: TLongintField;
    dsInvRows: TDataSource;
    qClients: TSQLQuery;
    qClientsID: TLongintField;
    qClientsNAME: TMemoField;
    dsClients: TDataSource;
    qProducts: TSQLQuery;
    qProductsID: TLongintField;
    qProductsNAME: TMemoField;
    qProductsPRICE: TFloatField;
    qProductsTAXABLE: TLongintField;
    dsProducts: TDataSource;
    Panel2: TPanel;
    cbTerms: TComboBox;
    cbClient: TComboBox;
    dtDate: TDateTimePicker;
    dtDueDate: TDateTimePicker;
    eCurrency: TEdit;
    eNumber: TEdit;
    lClient: TLabel;
    lNumber: TLabel;
    lDate: TLabel;
    lPaymentTerms: TLabel;
    lDueDate: TLabel;
    lCurrency: TLabel;
    DBGrid: TDBGrid;
    Panel5: TPanel;
    gSummary: TStringGrid;
    Panel4: TPanel;
    Panel3: TPanel;
    GroupBox1: TGroupBox;
    mNotes: TMemo;
    GroupBox2: TGroupBox;
    mTerms: TMemo;
    Panel1: TPanel;
    Button4: TButton;
    bSetPaid: TButton;
    bSave: TButton;
    procedure FormShow(Sender: TObject);
    procedure DBGridColEnter(Sender: TObject);
    procedure DBGridEditButtonClick(Sender: TObject);
    procedure DataSourceStateChange(Sender: TObject);
    procedure QueryBeforePost(DataSet: TDataSet);
    procedure QueryAfterPost(DataSet: TDataSet);
    procedure QueryAfterCancel(DataSet: TDataSet);
    procedure QueryBeforeEdit(DataSet: TDataSet);
    procedure QueryBeforeDelete(DataSet: TDataSet);
    procedure MemoGetText(Sender: TField; var aText: string; DisplayText: Boolean);
    procedure gSummarySelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure gSummaryGetEditText(Sender: TObject; ACol, ARow: Integer; var Value: string);
    procedure gSummaryEditingDone(Sender: TObject);
    procedure gSummaryDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure cbClientSelect(Sender: TObject);
    procedure bNumberClick(Sender: TObject);
    procedure dtDateCloseUp(Sender: TObject);
    procedure dtDateEnter(Sender: TObject);
    procedure cbTermsSelect(Sender: TObject);
    procedure dtDueDateEnter(Sender: TObject);
    procedure dtDueDateCloseUp(Sender: TObject);
    procedure bSetPaidClick(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
  private
    PriceFormat: string;
    Tax: real;
    Total: real;
    ToTax: real;
    procedure OnEditorTextChanged(Edit: TCustomMaskEdit; Field: TField);
    procedure QueryProductSetText(Sender: TField; const aText: string);
    procedure QueryFloatSetText(Sender: TField; const aText: string);
    procedure QueryTaxChange(Sender: TField);
    function  GetTaxText: string;
    procedure UpdateSum;
    procedure CalcRow(Sub, Add: boolean);
    procedure CalcSum; // todo: view invoice and eventually recalc/refresh Sum button
    function  ProductValidate(const Value: string; const Field: string=''): boolean;
  public

  end;

implementation

uses
  DBConst;

{$R *.lfm}

{ TfoInvoice }

procedure TfoInvoice.FormShow(Sender: TObject);
var
  f: TField;
  fn:TNumericField;
begin
  eCurrency.Text:=dm.Currency;
  PriceFormat:=Format(SARIPriceFormat, [eCurrency.Text]);
  Tax:=dm.Tax;
  UpdateSum;

  qClients.Open;
  while not qClients.EOF do begin
    cbClient.Items.AddObject(qClientsNAME.AsString, TObject(Pointer(qClientsID.AsInteger)));
    qClients.Next;
  end;

  cbTerms.Items.Assign(dm.Terms);
  cbTerms.Items.Insert(0,'None');
  cbTerms.Items.Add('1 Day');
  cbTerms.Items.Add('2 Days');
  cbTerms.Items.Add('3 Days');
  cbTerms.Items.Add('7 Days');
  cbTerms.Items.Add('2 Weeks');
  cbTerms.Items.Add('3 Months');
  cbTerms.Items.Add('1 Year');

  qProducts.Open;
  while not qProducts.EOF do begin
    DBGrid.Columns[1].PickList.AddObject(qProductsNAME.AsString, TObject(Pointer(qProductsID.AsInteger)));
    qProducts.Next;
  end;

  Query.Open;
  DBGrid.OnEditorTextChanged:=@OnEditorTextChanged;
  DBGrid.SelectedIndex:=1;

  Query.FieldByName('QueryRow').Required:=True;

  f :=Query.FieldByName('QueryProduct');
  f .Required     :=True;
  f .OnSetText    :=@QueryProductSetText;

  fn:=TNumericField(Query.FieldByName('QueryPRICE'));
  fn.Required     :=True;
  fn.DisplayFormat:=PriceFormat;
  fn.EditFormat   :=SARIEditFormat;
  fn.OnSetText    :=@QueryFloatSetText;

  fn:=TNumericField(Query.FieldByName('QueryQUANTITY'));
  fn.Required     :=True;
  fn.DisplayFormat:=SARIFloatFormat;
  fn.EditFormat   :=SARIEditFormat;
  fn.OnSetText    :=@QueryFloatSetText;

  fn:=TNumericField(Query.FieldByName('QueryAmount'));
  fn.DisplayFormat:=PriceFormat;
  fn.EditFormat   :=SARIEditFormat;

  Query.FieldByName('QueryTAXABLE').Required:=True;

  Query.Insert;
  cbClient.SetFocus;
end;

procedure TfoInvoice.OnEditorTextChanged(Edit: TCustomMaskEdit; Field: TField);
begin
//if Field=Query.FieldByName('QueryProduct' ) then SetEditValid(ProductValidate(Edit.Text), Edit); // todo: it is not the default editor
  if Field=Query.FieldByName('QueryPRICE'   ) then PriceValidate(Edit);
  if Field=Query.FieldByName('QueryQUANTITY') then PriceValidate(Edit);
end;

procedure TfoInvoice.DBGridColEnter(Sender: TObject);
begin
  if DBGrid.SelectedIndex=0 then DBGrid.SelectedIndex:=1;
end;

procedure TfoInvoice.DBGridEditButtonClick(Sender: TObject);
begin
  Query.Delete;
end;

procedure TfoInvoice.DataSourceStateChange(Sender: TObject);
begin
  if Query.State=dsInsert then begin
    DBGrid.SelectedIndex:=1;
    if Query.FieldByName('QueryTAXABLE').IsNull then Query.FieldByName('QueryTAXABLE').AsInteger:=1;
    Query.FieldByName('QueryRow').AsInteger:=Query.RecordCount+1;
    Query.FieldByName('QueryDel').AsString:='Del';
    DBGrid.Options:=DBGrid.Options+[dgAlwaysShowEditor];
  end else begin
    DBGrid.Options:=DBGrid.Options-[dgAlwaysShowEditor];
  end;
end;

procedure TfoInvoice.QueryBeforePost(DataSet: TDataSet);
begin
  // not needed anymore?
  ProductValidate(Query.FieldByName('QueryProduct' ).AsString, Query.FieldByName('QueryProduct' ).DisplayName);
  PriceValidate  (Query.FieldByName('QueryPRICE'   ).AsString, Query.FieldByName('QueryPRICE'   ).DisplayName);
  PriceValidate  (Query.FieldByName('QueryQUANTITY').AsString, Query.FieldByName('QueryQUANTITY').DisplayName);
  CalcRow(False, True);
end;

procedure TfoInvoice.QueryAfterPost(DataSet: TDataSet);
begin
  UpdateSum;
end;

procedure TfoInvoice.QueryAfterCancel(DataSet: TDataSet);
begin
  UpdateSum;
end;

procedure TfoInvoice.QueryBeforeEdit(DataSet: TDataSet);
begin
  CalcRow(True, False);
end;

procedure TfoInvoice.QueryBeforeDelete(DataSet: TDataSet);
begin
  CalcRow(True, False);
end;

procedure TfoInvoice.QueryProductSetText(Sender: TField; const aText: string);
begin
  ProductValidate(aText, Sender.DisplayName);
  Sender.AsString:=aText;
end;

procedure TfoInvoice.QueryFloatSetText(Sender: TField; const aText: string);
begin
  PriceValidate(aText, Sender.DisplayName);
  Sender.AsString:=aText;
  CalcRow(False, False);
end;

procedure TfoInvoice.QueryTaxChange(Sender: TField);
begin
  UpdateSum;
end;

procedure TfoInvoice.MemoGetText(Sender: TField; var aText: string; DisplayText: Boolean);
begin
  aText:=Sender.AsString;
end;

procedure TfoInvoice.gSummarySelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  CanSelect:=(ACol=0) and (ARow=1);
end;

procedure TfoInvoice.gSummaryGetEditText(Sender: TObject; ACol, ARow: Integer; var Value: string);
begin
  Value:=FloatToStr(Tax);
end;

procedure TfoInvoice.gSummaryEditingDone(Sender: TObject);
var t:string;
begin
  t:=gSummary.Cells[0,1];
  if GetTaxText=t then Exit;
  TaxValidate(t, 'Tax');
  Tax:=StrToFloat(t);
  UpdateSum;
end;

procedure TfoInvoice.gSummaryDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
begin
  if aRow<>3 then Exit;
  gSummary.Canvas.Font.Style:=[fsBold];
  gSummary.DefaultDrawCell(aCol, aRow, aRect, aState);
end;

procedure TfoInvoice.cbClientSelect(Sender: TObject);
begin
  eNumber.SetFocus;
end;

procedure TfoInvoice.bNumberClick(Sender: TObject);
begin
  eNumber.Text:=dm.Invoice;
  dtDate.SetFocus;
end;

procedure TfoInvoice.dtDateEnter(Sender: TObject);
begin
  // todo: focus DBGrid on Enter
  if dtDate.DateIsNull then dtDate.Date:=Date;
end;

procedure TfoInvoice.dtDateCloseUp(Sender: TObject);
begin
//cbTerms.SetFocus;
  DBGrid.SetFocus;
end;

procedure TfoInvoice.cbTermsSelect(Sender: TObject);
begin
  dtDueDate.SetFocus;
end;

procedure TfoInvoice.dtDueDateEnter(Sender: TObject);
begin
  if dtDueDate.DateIsNull then dtDueDate.Date:=Date;
end;

procedure TfoInvoice.dtDueDateCloseUp(Sender: TObject);
begin
  DBGrid.SetFocus;
end;

procedure TfoInvoice.bSetPaidClick(Sender: TObject);
begin
  bSetPaid.Enabled:=FALSE;
end;

procedure TfoInvoice.bSaveClick(Sender: TObject);
var idx, id, rn: integer;
begin
  if cbClient .Text=''  then raise EDatabaseError.CreateFmt(SNeedField, [lClient  .Caption]);
  if eNumber .Text=''  then raise EDatabaseError.CreateFmt(SNeedField, [lNumber .Caption]);
  if eCurrency.Text=''  then raise EDatabaseError.CreateFmt(SNeedField, [lCurrency.Caption]);
  if dtDate.DateIsNull then raise EDatabaseError.CreateFmt(SNeedField, [lDate   .Caption]);

  idx:=cbClient.ItemIndex;
  if idx=-1 then idx:=cbClient.Items.IndexOf(cbClient.Text);
  if idx=-1 then raise EDatabaseError.CreateFmt(SFieldError+SNoSuchRecord+' (%s)', [lClient.Caption, cbClient.Text]);
  id:=Integer(Pointer(cbClient.Items.Objects[idx]));

  if Query.IsEmpty then EDatabaseError.Create(SDatasetEmpty);

  qInvRows .Close;
  qInvoices.Close;
  qInvoices.Open;
  qInvRows .Open;
  try
    qInvoices.Insert;
    qInvoicesID_CLIENTS.AsInteger:=id;
    qInvoicesINUMBER   .AsString :=eNumber.Text;
    qInvoicesIDATE     .AsString :='';
    if not dtDate   .DateIsNull then qInvoicesIDATE  .AsString :=FormatDateTime(SARIDateFormat, dtDate.Date);
    qInvoicesICURRENCY .AsString :=eCurrency.Text;
    qInvoicesTAX       .AsFloat  :=Tax;
    qInvoicesTERMS     .AsString :=cbTerms.Text;
    qInvoicesDUEDATE   .AsString :='';
    if not dtDueDate.DateIsNull then qInvoicesDUEDATE.AsString :=FormatDateTime(SARIDateFormat, dtDueDate.Date);
    qInvoicesNOTES     .AsString :=mNotes.Text;
    qInvoicesTERMSNOTES.AsString :=mTerms.Text;
    qInvoicesSTATUS    .AsInteger:=0;
    if not bSetPaid.Enabled then begin
      qInvoicesSTATUS .AsInteger:=1;
      lDueDate.Caption:='Paid Date'; // PaidDate = DueDate
    end;
    qInvoices.Post;

    Query.DisableControls;
    rn:=Query.RecNo;
    try
      Query.First;
      while not Query.EOF do begin
        qInvRows.Insert;
        qInvRowsID_INVOICES.AsInteger:=qInvoicesID.AsInteger;
        qInvRowsID_PRODUCTS.AsInteger:=Query.FieldByName('QueryID_PRODUCTS').AsInteger;
        qInvRowsPRICE      .AsInteger:=Query.FieldByName('QueryPRICE'      ).AsInteger;
        qInvRowsQUANTITY   .AsInteger:=Query.FieldByName('QueryQUANTITY'   ).AsInteger;
        qInvRowsTAXABLE    .AsInteger:=Query.FieldByName('QueryTAXABLE'    ).AsInteger;
        qInvRows.Post;
        Query.Next;
      end;
      Query.RecNo:=rn;
    finally
      Query.EnableControls;
    end;

    qInvoices.SQLTransaction.Commit;
    ModalResult:=mrOk;
  except
    qInvoices.SQLTransaction.Rollback;
    qInvRows .Close;
    qInvoices.Close;
  end;
end;

function TfoInvoice.GetTaxText: string;
begin
  Result:=Format('Tax (%s)', [FormatFloat(SARITaxFormat, Tax)]);
end;

procedure TfoInvoice.UpdateSum;
var tl, tx: real;
begin
  tl:=Total;
  tx:=ToTax;
  if Query.State<>dsBrowse then begin
    tl:=tl+Query.FieldByName('QueryAmount').AsFloat;
    if Query.FieldByName('QueryTAXABLE').AsInteger>0
      then tx:=tx+Query.FieldByName('QueryAmount').AsFloat;
  end;
  tx:=tx*Tax/100;
  gSummary.Cells[0, 1]:=GetTaxText;
  gSummary.Cells[1, 0]:=FormatFloat(PriceFormat, tl);
  gSummary.Cells[1, 1]:=FormatFloat(PriceFormat, tx);
  gSummary.Cells[1, 2]:=FormatFloat(PriceFormat, tl+tx);
  gSummary.Cells[1, 3]:=FormatFloat(PriceFormat, tl+tx);
end;

procedure TfoInvoice.CalcRow(Sub, Add: boolean);
begin
  if Sub then begin
    Total:=Total-Query.FieldByName('QueryAmount').AsFloat;
    if Query.FieldByName('QueryTAXABLE').AsInteger>0 then ToTax:=ToTax-Query.FieldByName('QueryAmount').AsFloat;
  end;
  if Query.State<>dsBrowse
    then Query.FieldByName('QueryAmount').AsFloat:=Query.FieldByName('QueryPRICE').AsFloat*Query.FieldByName('QueryQUANTITY').AsFloat;
  if Add then begin
    Total:=Total+Query.FieldByName('QueryAmount').AsFloat;
    if Query.FieldByName('QueryTAXABLE').AsInteger>0 then ToTax:=ToTax+Query.FieldByName('QueryAmount').AsFloat;
  end;
  UpdateSum;
end;

procedure TfoInvoice.CalcSum;
var rn: integer;
begin
  // todo: use MemDataSet buffers - recalc without Next/Prev (recalc in insert/edit mode)
  Query.DisableControls;
  rn:=Query.RecNo;
  try
    Total:=0;
    Query.First;
    while not Query.EOF do begin
      Total:=Total+Query.FieldByName('QueryAmount').AsFloat;
      Query.Next;
    end;
    Query.RecNo:=rn;
  finally
    Query.EnableControls;
  end;
  UpdateSum;
end;

function TfoInvoice.ProductValidate(const Value: string; const Field: string=''): boolean;
var
  sl : TStrings;
  idx: integer;
begin
  sl:=DBGrid.Columns[1].PickList;
  idx:=sl.IndexOf(Value);
  Result:=(idx>-1) and qProducts.Locate('ID', IntToStr(Integer(Pointer(sl.Objects[Idx]))), []);
  if not Result then ValidateError(Value, Field);

  if (not Result) or
     (Query.FieldByName('QueryID_PRODUCTS').AsInteger=qProductsID.AsInteger) then Exit;
  Query.FieldByName('QueryID_PRODUCTS').AsInteger:=qProductsID.AsInteger;
  Query.FieldByName('QueryPRICE'      ).AsFloat  :=qProductsPRICE.AsFloat;
  if Query.FieldByName('QueryQUANTITY').IsNull then Query.FieldByName('QueryQUANTITY').AsFloat:=1;
  Query.FieldByName('QueryTAXABLE'    ).AsInteger:=qProductsTAXABLE.AsInteger;
  CalcRow(False, False);
end;

end.

