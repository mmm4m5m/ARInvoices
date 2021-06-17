// by mmm4m5m (2021)

program ARInvoices;

// Create and save AR invoices. Show 'General Journal' on screen. Using SQLite db.

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, datetimectrls, memdslaz, dmARInvoices, fMain
  { you can add units after this }
  , fSettings, fProducts, fClients, fInvoice, fInvoices, fGJReport;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Title:='AR Invoices';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(Tdm, dm);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

