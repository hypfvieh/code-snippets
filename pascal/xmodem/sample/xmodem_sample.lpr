program xmodem_sample;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Main, xmodem
  { you can add units after this };

{$R *.res}

begin
  Application.Title :='Xmodem Sample';
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm (Tfrm_main, frm_main );
  Application.Run;
end.

