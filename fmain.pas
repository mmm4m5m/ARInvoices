unit fMain;

{$mode objfpc}{$H+}

{-$define ARITest}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    bSettings: TButton;
    bProducts: TButton;
    bClients: TButton;
    bInvoices: TButton;
    bNewInvoice: TButton;
    bGJ: TButton;
    Button7: TButton;
    procedure FormShow(Sender: TObject);
    procedure bSettingsClick(Sender: TObject);
    procedure bProductsClick(Sender: TObject);
    procedure bClientsClick(Sender: TObject);
    procedure bInvoicesClick(Sender: TObject);
    procedure bNewInvoiceClick(Sender: TObject);
    procedure bGJClick(Sender: TObject);
  private
    procedure UpdateStates(NoInvoices: boolean=False; NoSettings: boolean=False);
  public

  end;

var
  Form1: TForm1;

implementation

uses
  SQLDB, dmARInvoices, fSettings, fProducts, fClients, fInvoice, fInvoices, fGJReport;

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormShow(Sender: TObject);
var
  Q : TSQLQuery;
  es: boolean;
begin
  UpdateStates(True, True);

  Q:=TSQLQuery.Create(Self);
  try
    Q.DataBase:=dm.dbDM;

    Q.SQL.Text:='select * from SETTINGS LIMIT 1';
    Q.Open;
    if not Q.IsEmpty then dm.Load(Q);
    es:=Q.IsEmpty;

    if not es then begin
      Q.Close;
      Q.SQL.Text:='select ID from INVOICES LIMIT 1';
      Q.Open;
    end;
    UpdateStates(Q.IsEmpty, es);
  finally
    Q.Free;
  end;
end;

procedure TForm1.UpdateStates(NoInvoices: boolean=False; NoSettings: boolean=False);
begin
  bProducts  .Enabled:=not NoSettings;
  bClients   .Enabled:=not NoSettings;
  bNewInvoice.Enabled:=not NoSettings;
  bInvoices  .Enabled:=not NoInvoices;
  bGJ        .Enabled:=not NoInvoices;
end;

procedure TForm1.bSettingsClick(Sender: TObject);
var f: TfoSettings;
begin
  f:=TfoSettings.Create(Self);
  try
    if f.ShowModal=mrOk then UpdateStates(not bInvoices.Enabled);
    {$ifdef ARITest} if f.ModalResult=mrAbort then UpdateStates(not bInvoices.Enabled, True); {$endif ARITest}
  finally
    f.Free;
  end;
end;

procedure TForm1.bProductsClick(Sender: TObject);
var f: TForm;
begin
  f:=TfoProducts.Create(Self);
  try
    f.ShowModal;
  finally
    f.Free;
  end;
end;

procedure TForm1.bClientsClick(Sender: TObject);
var f: TForm;
begin
  f:=TfoClients.Create(Self);
  try
    f.ShowModal;
  finally
    f.Free;
  end;
end;

procedure TForm1.bInvoicesClick(Sender: TObject);
var f: TForm;
begin
  f:=TfoInvoices.Create(Self);
  try
    f.ShowModal;
  finally
    f.Free;
  end;
end;

procedure TForm1.bNewInvoiceClick(Sender: TObject);
var f: TForm;
begin
  f:=TfoInvoice.Create(Self);
  try
    if f.ShowModal=mrOk then UpdateStates;
  finally
    f.Free;
  end;
end;

procedure TForm1.bGJClick(Sender: TObject);
var f: TForm;
begin
  f:=TfoGJReport.Create(Self);
  try
    f.ShowModal;
  finally
    f.Free;
  end;
end;

end.

