unit dmARInvoices;

// todo DB schema: We need date of payment. Add INVOICES.PAIDDATE or change the name of INVOICES.DUEDATE
// todo DB schema: rename CLIENTS.NAME, PRODUCTS.NAME, SETTINGS.NAME
// todo DB schema: rename SETTINGS.CURRENCY, SETTINGS.NUMBER, SETTINGS.TERMS, SETTINGS.INVOICE
// todo DB schema: add PRODUCT.CURRENCY? products have the same price after change SETTINGS.CURRENCY
// todo DB schema: add INVOICES_ROWS.ROWNUM

{$mode objfpc}{$H+}

interface

uses
  MaskEdit, DBCtrls, DBGrids, LCLType, DB,
  Classes, SysUtils, SQLite3Conn, SQLDB;

const
  IARISOverdue=-1; // negative - it is not a DB status
  IARISPending= 0;
  IARISPaid   = 1;

const
  SARIEditFormat    ='#';
  SARIFloatFormat   ='#0.00';
  SARITaxFormat     ='#0.00 "%"';
  SARIPriceFormat   =',#0.00 "%s"';
  SARIDateFormat    ='yyyy-mm-dd'; // date in DB is saved as string

type
  TARIEditorTextChanged=procedure(Edit: TCustomMaskEdit; Field: TField) of object;
  TARIDBGrid=class(TDBGrid)
  protected
    function  EditorCanAcceptKey(const ch: TUTF8Char): boolean; override;
    procedure SetEditText(ACol, ARow: Longint; const Value: string); override;
  public
    OnEditorTextChanged: TARIEditorTextChanged;
  end;
  TDBGrid=class(TARIDBGrid);

type
  Tdm = class(TDataModule)
    dbDM: TSQLite3Connection;
    SQLTransaction1: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private

  public
    PriceFormat: string;
    procedure Load(Query: TSQLQuery);

  public // SETTINGS
    ID      : integer;
    BName   : string;
    Email   : string;
    Address : string;
    Phone   : string;
    Number  : string;
    Currency: string;
    Invoice : string;
    Terms   : TStringList;
    Tax     : real;
  end;

var
  dm: Tdm;


function  InvoiceStatus(Status: integer; DueDate: TDateTime): integer;
procedure StatusGetText(InvoiceStatus: integer; var aText: string; DisplayText: Boolean);

function  GetDigitsOnly(const aText: string): string;
procedure PhoneGetText(Field: TField; var aText: string; DisplayText: Boolean);
procedure NumberGetText(Field: TField; var aText: string; DisplayText: Boolean);

procedure ValidateError(const Value, Field: string);
procedure SetEditValid(IsValid: boolean; Edit: TCustomMaskEdit);

function  EmailValidate(const Value: string; const Field: string=''): boolean; overload;
procedure EmailValidate(Edit: TCustomMaskEdit); overload;
function  PhoneValidate(const Value: string; const Field: string=''): boolean; overload;
procedure PhoneValidate(Edit: TCustomMaskEdit); overload;
function  NumberValidate(const Value: string; const Field: string=''): boolean; overload;
procedure NumberValidate(Edit: TCustomMaskEdit); overload;
function  CurrencyValidate(const Value: string; const Field: string=''): boolean; overload;
procedure CurrencyValidate(Edit: TCustomMaskEdit); overload;
function  TaxValidate(const Value: string; const Field: string=''): boolean; overload;
procedure TaxValidate(Edit: TCustomMaskEdit); overload;
function  PriceValidate(const Value: string; const Field: string=''): boolean; overload;
procedure PriceValidate(Edit: TCustomMaskEdit); overload;

implementation

uses
  Graphics, StrUtils, DBConst, SQLite3Dyn;

const
  SARIErrInvalid  ='Value "%s" is not valid.';
  IARIEmailMinLen =8; // example: aa@aa.cc // todo: aa@aaa.c is shown as valid
  IARIPhoneMinLen =7; // example: (123) 456 7
  SARIPhoneFormat ='(%s) %s %s';
  IARINumberMinLen=6; // example: 123-45-6
  SARINumberFormat='%s-%s-%s';

const
  SARISOverdue='OVERDUE';
  SARISPending='Pending';
  SARISPaid   ='Paid';

function InvoiceStatus(Status: integer; DueDate: TDateTime): integer;
begin
  Result:=Status;
  if (Status<>IARISPaid) and (Trunc(DueDate)<Trunc(Date)) then Result:=IARISOverdue;
end;

procedure StatusGetText(InvoiceStatus: integer; var aText: string; DisplayText: Boolean);
begin
  aText:=SARISPending;
  case InvoiceStatus of
    IARISOverdue: aText:=SARISOverdue;
    IARISPaid:    aText:=SARISPaid;
  end;
end;

function GetDigitsOnly(const aText: string): string;
var i: integer;
begin
  Result:=aText;
  for i:=Length(Result) downto 1 do if not (Result[i] in ['0'..'9']) then Delete(Result, i, 1);
end;

procedure PhoneGetText(Field: TField; var aText: string; DisplayText: Boolean);
begin
  aText:=Field.AsString;
  if DisplayText and (Length(aText)>=IARIPhoneMinLen)
    then aText:=Format(SARIPhoneFormat, [Copy(aText,1,3), Copy(aText,4,3), Copy(aText, 7, MAXINT)])
end;

procedure NumberGetText(Field: TField; var aText: string; DisplayText: Boolean);
begin
  aText:=Field.AsString;
  if DisplayText and (Length(aText)>=IARINumberMinLen)
    then aText:=Format(SARINumberFormat, [Copy(aText,1,3), Copy(aText,4,2), Copy(aText, 6, MAXINT)])
end;

procedure ValidateError(const Value, Field: string);
begin
  if Field<>'' then raise EDatabaseError.CreateFmt(SFieldError+SARIErrInvalid, [Field, Value]);
end;

function GetEditText(Edit: TCustomMaskEdit): string;
begin
  if (not Edit.Focused) and (Edit is TDBEdit) and
     ( ((TDBEdit(Edit).Field is TNumericField ) and (TNumericField (TDBEdit(Edit).Field).DisplayFormat<>'')) or
       ((TDBEdit(Edit).Field is TDateTimeField) and (TDateTimeField(TDBEdit(Edit).Field).DisplayFormat<>'')) )
    then Result:=TDBEdit(Edit).Field.AsString
    else Result:=Edit.Text;
end;

procedure SetEditValid(IsValid: boolean; Edit: TCustomMaskEdit);
begin
  if IsValid
    then Edit.Color:=clDefault
    else Edit.Color:=$DDDDFF;
end;

function EmailValidate(const Value: string; const Field: string=''): boolean;
var pa, pd: integer;
begin
  Result:=Value='';
  if Result then Exit;
  pa:=Pos  ('@', Value);
  pd:=PosEx('.', Value, pa+1);
  Result:=(Length(Value)>=IARIEmailMinLen) and (pa>1) and (pd>1) and (pd<Length(Value));
  if not Result then ValidateError(Value, Field);
end;

procedure EmailValidate(Edit: TCustomMaskEdit);
begin
  SetEditValid(EmailValidate(GetEditText(Edit)), Edit);
end;

function PhoneValidate(const Value: string; const Field: string=''): boolean;
begin
  Result:=(Value='') or (Length(Value)>=IARIPhoneMinLen);
  if not Result then ValidateError(Value, Field);
end;

procedure PhoneValidate(Edit: TCustomMaskEdit);
begin
  SetEditValid(PhoneValidate(GetEditText(Edit)), Edit);
end;

function NumberValidate(const Value: string; const Field: string=''): boolean;
begin
  Result:= {(Value='') or} (Length(Value)>=IARINumberMinLen);
  if not Result then ValidateError(Value, Field);
end;

procedure NumberValidate(Edit: TCustomMaskEdit);
begin
  SetEditValid(NumberValidate(GetEditText(Edit)), Edit);
end;

function CurrencyValidate(const Value: string; const Field: string=''): boolean;
begin
  Result:=Length(Value)=3;
  if not Result then ValidateError(Value, Field);
end;

procedure CurrencyValidate(Edit: TCustomMaskEdit);
begin
  SetEditValid(CurrencyValidate(GetEditText(Edit)), Edit);
end;

function TaxValidate(const Value: string; const Field: string=''): boolean;
var r: real;
begin
  Result:=TryStrToFloat(Value, r) and (r>=0) and (r<=100);
  if not Result then ValidateError(Value, Field);
end;

procedure TaxValidate(Edit: TCustomMaskEdit);
begin
  SetEditValid(TaxValidate(GetEditText(Edit)), Edit);
end;

function PriceValidate(const Value: string; const Field: string=''): boolean;
var r: real;
begin
  Result:=TryStrToFloat(Value, r) and (r>=0);
  if not Result then ValidateError(Value, Field);
end;

procedure PriceValidate(Edit: TCustomMaskEdit);
begin
  SetEditValid(PriceValidate(GetEditText(Edit)), Edit);
end;


{ TARIDBGrid }

// modified copy of TCustomDBGrid.EditorCanAcceptKey
// dgDisplayMemoText will call Field.AsString instead the default - Field.DisplayText
// we need DisplayText in order to format the phone, business number, etc.
function TARIDBGrid.EditorCanAcceptKey(const ch: TUTF8Char): boolean;
var aField: TField;
begin
  Result:=inherited;
  if Result or (not DataLink.Active) then Exit;
  aField := SelectedField;
  if aField=nil then Exit;
  Result := IsValidChar(AField, Ch) and not aField.Calculated and
    (aField.DataType<>ftAutoInc) and (aField.FieldKind<>fkLookup);
    //and (not aField.IsBlob or CheckDisplayMemo(aField));
end;

// for validating the input data on change and visualize invalid input with 'red' color
procedure TARIDBGrid.SetEditText(ACol, ARow: Longint; const Value: string);
begin
  inherited;
  if Assigned(OnEditorTextChanged) and (InplaceEditor is TCustomMaskEdit)
    then OnEditorTextChanged(TCustomMaskEdit(InplaceEditor), SelectedField);
end;


{$R *.lfm}

{ Tdm }

procedure Tdm.DataModuleCreate(Sender: TObject);
begin
  Terms:=TStringList.Create;

  // load SQLite library
  if TryInitializeSQLite('')=-1                  // sqlite3.inc: SQLiteDefaultLibrary
    then TryInitializeSQLite('libsqlite3.so.0'); // debian 10 default
  // SQLite library for IDE (debian 10 default):
  // $ ln -s /usr/lib/x86_64-linux-gnu/libsqlite3.so.0 ...-project-dir/libsqlite3.so
  // $ LD_LIBRARY_PATH=...-project-dir lazarus &

  dbDM.Connected:=True;
end;

procedure Tdm.DataModuleDestroy(Sender: TObject);
begin
  FreeAndNil(Terms);
end;

procedure Tdm.Load(Query: TSQLQuery);
begin
  ID        :=Query.FieldByName('ID'      ).AsInteger;
  BName     :=Query.FieldByName('NAME'    ).AsString;
  Email     :=Query.FieldByName('EMAIL'   ).AsString;
  Address   :=Query.FieldByName('ADDRESS' ).AsString;
  Phone     :=Query.FieldByName('PHONE'   ).AsString;
  Number    :=Query.FieldByName('NUMBER'  ).AsString;
  Currency  :=Query.FieldByName('CURRENCY').AsString;
  Invoice   :=Query.FieldByName('INVOICE' ).AsString;
  Terms.Text:=Query.FieldByName('TERMS'   ).AsString;
  Tax       :=Query.FieldByName('TAX'     ).AsFloat;

  PriceFormat:=Format(SARIPriceFormat, [dm.Currency]);
end;

end.

