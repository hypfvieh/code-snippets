unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Synaser, xmodem;

type

  { Tfrm_main }

  Tfrm_main = class (TForm )
    btn_connect : Tbutton;
    btn_upload : Tbutton;
    btn_exit : TButton;
    cmb_serialport : TComboBox;
    lbl_log : TLabel;
    lbl_file : TLabel;
    lbl_serialport : TLabel;
    pb_upload : TProgressBar;
    txt_filename : Tedit;
    memo_log : Tmemo;
    dlg_openfile : TOpenDialog;
    procedure btn_connectClick (Sender : Tobject );
    procedure btn_exitClick (Sender : TObject );
    procedure btn_uploadClick (Sender : Tobject );
    procedure FormClose (Sender : TObject; var CloseAction : TCloseAction );
    procedure Formcreate (Sender : Tobject );
  private
    { private declarations }
    procedure logMsg(msg : String);
    procedure progressUpdate(min, max, pbposition, step: Integer);
  public
    { public declarations }
  end;

var
  frm_main : Tfrm_main;
  COM : TBlockSerial;
  log : tStringlist;
 xmod : TXmodem;
implementation

{$R *.lfm}

{ Tfrm_main }

procedure Tfrm_main.logMsg(msg : String);
begin
  memo_log.Lines.Add(FormatDateTime('[yyyy-mm-dd hh:nn:ss]: ', now) + msg);
  Application.ProcessMessages;
end;

procedure Tfrm_main.progressUpdate(min, max, pbposition, step: Integer);
begin
  pb_upload.Min := min;
  pb_upload.Max := max;
  pb_upload.Position := pbposition;
  pb_upload.step := step;
  Application.ProcessMessages;
end;

procedure Tfrm_main.Formcreate (Sender : Tobject );
begin
  log := Tstringlist.create;
  COM := TBlockSerial.Create;

  xmod := TXmodem.Create(COM);
  // if there is anything to log, give the message to this procedure
  xmod.OnLogMessage := @logMsg;
  // for updating progressbar use this procedure
  xmod.OnProgress := @progressUpdate;

  cmb_serialport.items.clear;
  cmb_serialport.Items.CommaText := GetSerialPortNames;
  if (cmb_serialport.items.count > 0) then cmb_serialport.itemindex := 0;
end;

procedure Tfrm_main.btn_connectClick (Sender : Tobject );
begin
  if (btn_connect.Caption = 'Connect') then begin
    memo_log.clear;
    COM.Connect(cmb_serialport.Text);
    COM.Config(9600,8,'N',SB1,false,false);
    btn_connect.Caption := 'Disconnect';
  end
  else begin
      COM.CloseSocket;
      btn_connect.Caption := 'Connect';
  end;

end;

procedure Tfrm_main.btn_exitClick (Sender : TObject );
begin
  close;
end;

procedure Tfrm_main.btn_uploadClick (Sender : Tobject );
var msg : string;
begin
  if (btn_upload.Caption = 'Upload') then begin
    if dlg_openfile.Execute then begin
        btn_upload.Caption := 'Cancel';
        btn_exit.Enabled := False;
        btn_connect.Enabled := False;

        xmod.send(dlg_openfile.FileName);

        btn_upload.Caption := 'Upload';
        btn_exit.Enabled := True;
        btn_connect.Enabled := True;
    end;
  end
  else begin
    msg := 'Are you sure you want to cancel transmission?';

    if (MessageDlg('XModem Sample',msg,mtWarning,[mbyes,mbno],0) = mrYes) then begin
      if assigned(xmod) then begin
        xmod.UserBreak;

        btn_upload.Caption := 'Upload';
        btn_exit.Enabled := True;
        btn_connect.Enabled := True;
      end;
    end;
  end;
end;

{$HINTS OFF}
procedure Tfrm_main.FormClose (Sender : TObject; var CloseAction : TCloseAction
  );
begin
  xmod.Free;
  COM.Free;
end;
{$HINTS ON}

end.

