unit xmodem;

{$mode objfpc}{$H+}

{
       XModem Implementation

       This is simple XModem-Protcol implementation for SENDING files using
       Synapse Synaser (http://www.ararat.cz/synapse/doku.php/download).

       If you find any bugs, please contact me:
       support[at-sign]case-of.org

       (c) copyright 2013-2014 maniac

       License: WTFPL (http://www.wtfpl.net/txt/copying/)
                with following exceptions:

                1. The original author is not responsable for any damage
                   caused directly or indirectly by using this software/code.

                2. This software/code is for civil use only!
                   Using this software/code (or parts of it) for military
                   purposes is strictly forbidden!

}

interface

uses
  Classes, SysUtils, Synaser;

const
  MAXBLOCK = 255;
  // Retrys are scheduled every second
  // The spec says that the receiver will resend an "ACK" or "NAK"
  // every 10 seconds, with a maximum of 10 retries
  // so we have a total of 10seconds * 10times = 100 retries
  // because we check for a "NAK" or "ACK" every second
  MAXRETRY = 100;
  SOH = $01;
  NAK = $15;
  ACK = $06;
  EOT = $04;
  CAN = $18;


type
  TProgressEvent = procedure(min, max, position, step: Integer) of object;

type
  TLogMessageEvent = procedure(msg: String) of object;

type
  TCheckSumType = (cstSimple, cstCRC16);

type
  TXModem = class(TObject)

  Protected
    FileToSend: String;
  Private
    FCheckSumType : TCheckSumType;
    XModemBuffer: array[0..127] of Byte;
    XModemPos: Integer;
    COM: TBlockSerial;
    StopSending: Boolean;
    procedure ProgressStep(min, max, position, step: Integer);
    procedure LogMessage(msg: String);
    procedure Init;
    procedure SendEx;
    procedure Recv;
    function CalcCheckSum(block: array of Byte): Byte;
    function CRC16(buffer: array of Byte): Byte;
    function RemoteReady(cmd: Byte): Boolean;
  Public

    OnProgress: TProgressEvent;
    OnLogMessage: TLogMessageEvent;
    procedure UserBreak;
    procedure Send(filename: String);

    constructor Create(var serialport: TBlockSerial);
    destructor Destroy(); Override;

    property ChecksumType : TChecksumType read FCheckSumType write FCheckSumType;
  end;

implementation

{
    Default Constructor.
            @param serialport : TBlockSerial - Serialport object to use
}
constructor TXModem.Create(var serialport: TBlockSerial);
begin
  if (serialport <> nil) then COM := serialport;
  OnProgress := nil;
  OnLogMessage := nil;
  FCheckSumType := cstSimple;
  Init();
end;

{
    Default destructor.
}
destructor TXModem.Destroy;
begin
  inherited Destroy;
end;

// =============================================================================

{
    Here we send the real data. This is called by Xmodem_send, after the
    initial "NAK" was received.
}
procedure TXModem.SendEx;
var SendBuff: array[0..127] of Byte;
  HeaderBuff: array[0..2] of Byte;
  f: file of Byte;
  readed: Integer;
  XModemBlock: Integer;
  Checksum: Byte;
  retries: Integer;
  i: Integer;
  fsize: Integer;
  totalblocks : integer;
begin
  // Spec says initial transmission is started with block number 1
  // this is different from the roll-over after 255 has been reach
  XModemBlock := 1;
  readed := -1;
  retries := 0;
  totalblocks := 1;

  Assign(f, FileToSend);
  Reset(f);
  fsize := FileSize(f);
  fsize := fsize div 128;
  ProgressStep(0, fsize+2, totalblocks, 1);

  repeat
    if (StopSending) then begin
      LogMessage('User interrupt!');
      break;
    end;
    {$HINTS OFF}
    FillByte(Sendbuff, 127, 0);
    {$HINTS ON}
    LogMessage('Sending of block ' + IntToStr(totalblocks) + ' of ' + IntTostr(fsize +2));
    BlockRead(f, SendBuff, 128, readed);
    // Spec says every Block has to look like this:
    // SOH-Byte(0x01) + Current Block + MAXBLOCK(255) - Current Block + 128 Byte of UsageData + Checksum
    // 01 + 1 + 254 + <some data> + Checksum(1 Byte)
    HeaderBuff[0] := SOH;
    HeaderBuff[1] := XModemBlock;
    HeaderBuff[2] := MAXBLOCK - XModemBlock;
    if (FChecksumType = cstSimple) then
      Checksum := CalcCheckSum(SendBuff)
    else
      Checksum := CRC16(SendBuff);
    COM.SendBuffer(@HeaderBuff, 3);
    COM.SendBuffer(@SendBuff, 128);
    COM.SendByte(Checksum);
    Inc(XModemBlock);
    Inc(totalblocks);
    // Spec says if we reach MAXBLOCK (255), then restart counting
    // with 0 (Default Start-Value is 1) and continue sending
    if (XModemBlock > MAXBLOCK) then XModemBlock := 0;

    ProgressStep(0, fsize+2, totalblocks, 1);

    // Every send block should be acknowledged by the receiver
    repeat
      if (StopSending) then begin
        LogMessage('User interrupt!');
        break;
      end;

      if (RemoteReady(ACK)) then break;
      Recv;
      for i := 0 to 100 do begin
        sleep(10);
      end;
      Inc(retries);
    until retries > MAXRETRY;

    if (retries > MAXRETRY) then begin
      LogMessage('Timeout waiting for ACK');
      exit;
    end;

  until (readed = 0);

  // Send cancel transmission if user interrupted sending
  if (StopSending) then begin
    // Spec says three CAN-Bytes (Cancel Transmission) cancels the transmission
    COM.SendByte(CAN);
    COM.SendByte(CAN);
    COM.SendByte(CAN);
    LogMessage('Transmission canceled!');
  end
  else begin
      // finally, when transfer is done, send an EOT (End of Transmission)
     COM.SendByte(EOT);
     LogMessage('Transmission finished!');
  end;
end;

{
     Receive Data from Serial-Port. This function reads the answers from
     the serial-port bytewise until all data is read.
     For every received byte, the Buffer position counter is updated (incremented).
}
procedure TXModem.Recv;
begin
  while (COM.WaitingDataEx > 0) do begin
    COM.RecvBuffer(@XModemBuffer[XModemPos], 1);
    Inc(XModemPos);
  end;
end;

{
    This method starts file transmission. As the spec of Xmodem defines,
    it waits for an "NAK" signal from remote side before sending anything.
    (XModem protocol spec says: remote side has to initialize the transfer).
            @param filename : string - the file to transmit
}
procedure TXModem.Send(filename: String);
var
  retries: Integer;
  i: Integer;
begin
  StopSending := False;
  FileToSend := filename;
  retries := 0;
  LogMessage('Waiting for initial "NAK"');
  repeat
    if (StopSending) then begin
      LogMessage('User interrupt!');
      Exit;
    end;

    if (RemoteReady(NAK)) then break;
    Recv;
    for i := 0 to 100 do begin
      sleep(10);
      ProgressStep(0, 0, 0, 1);
    end;

    Inc(retries);
  until retries > MAXRETRY;


  if (retries < MAXRETRY) then begin
    SendEx;
  end
  else
    LogMessage('Timeout waiting for initial NAK (transaction begin)');
end;

{   Function to check for a certain answer of remote peer.
    This function decrements the buffer-position-counter every time it is called.
    That means, if you call this, the recv-buffer will be empty on return of this function.
        @param cmd : byte - the status byte to check (e.g. ACK, NAK)
        @returns boolean - true if requested answer were found, false otherwise
}
function TXModem.RemoteReady(cmd: Byte): Boolean;
var i: Integer;
begin
  Result := False;
  for i := XModemPos downto 0 do begin
    if (XModemPos > 0) then Dec(XModemPos);
    if (XModemBuffer[i] = cmd) then begin
      Result := True;
      exit;
    end;
  end;
end;

{
    Cancel Sending when called.
}
procedure TXModem.UserBreak;
begin
  StopSending := True;
end;

{
  Initialisation of Xmodem global variables
}
procedure TXModem.init();
begin
  XModemPos := 0;
  StopSending := False;
  FillByte(XModemBuffer, length(XModemBuffer) - 1, 0);
end;

{
    Callback to use when uploading file (for progressbar control).
}
procedure TXModem.ProgressStep(min, max, position, step: Integer);
begin
  if (Assigned(OnProgress)) then
    OnProgress(min, max, position, step);
end;

{
    Callback to use when a message is issued.
}
procedure TXModem.LogMessage(msg: String);
begin
  if (Assigned(OnLogMessage)) then
    OnLogMessage(msg);
end;

{
    This is the Xmodem-Checksum routine. XModem uses 1 Byte checksum.
    Later implementation may use CRC16 (defined in CRC16-function)
         @param: block : array of byte - array of byte with usage data
         @returns 1-byte checksum
}
function TXModem.CalcCheckSum(block: array of Byte): Byte;
var
  y: Longint;
  i: Integer;
begin
  y := 0;
  for i := 0 to 127 do begin
    y := y + block[i];
  end;

  y := (y and $0FFFF);
  Result := Byte(y);

end;

{
    CRC16 Checksum for Xmodem/CRC
         @param: buffer : array of byte with usage data
         @returns CRC16 Checksum
}
function TXModem.CRC16(buffer: array of Byte): Byte;
const
  Mask: Word = $A001;
var
  CRC: Word;
  N, I: Integer;
  B: Byte;
begin
  CRC := $FFFF;
  for I := Low(Buffer) to High(Buffer) do
  begin
    B := Buffer[I];
    CRC := CRC xor B;
    for N := 1 to 8 do
      if (CRC and 1) <> 0 then
        CRC := (CRC shr 1) xor Mask
      else
        CRC := CRC shr 1;
  end;
  Result := CRC;
end;


end.



