{*****************************************************************

Author: Dennis Malkoff
Copyrights: Dennis Malkoff
E-mail: info@sminstall.com
WEB: http://www.sminstall.com/

******************************************************************}

unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    Button2: TButton;
    ProgressBar1: TProgressBar;
    OpenDialog1: TOpenDialog;
    GroupBox1: TGroupBox;
    Image1: TImage;
    Label1: TLabel;
    Edit2: TEdit;
    Button3: TButton;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure Mono(Bmp:TBitmap);
type
  TRGB=record
    B,G,R:Byte;
  end;
  pRGB=^TRGB;
var
  x,y:Word;
  Dest:pRGB;
begin
  for y:=0 to Bmp.Height-1 do
  begin
    Dest:=Bmp.ScanLine[y];
    for x:=0 to Bmp.Width-1 do
    begin
      with Dest^ do
      begin
        if (r+g+b)/3>254 then
        begin
          r:=255;
          g:=255;
          b:=255;
        end else
        begin
          r:=0;
          g:=0;
          b:=0;
        end;
      end;
      Inc(Dest);
    end;
  end;
end;

function Max(x,y:Integer):Integer;
begin
  if x>y then Result:=x else Result:=y;
end;

function GetDifferents(Bmp1,Bmp2:TBitmap):Integer;
var
  c1,c2:PByte;
  x,y,x1,y1,i,Diff:Integer;
begin
  Bmp1.PixelFormat:=pf24bit;
  Bmp2.PixelFormat:=pf24bit;
  Diff:=0;
  x1:=Max(Bmp1.Width,Bmp2.Width);
  y1:=Max(Bmp1.Height,Bmp2.Height);
  for y:=0 to y1-1 do
  begin
    if Bmp1.Height>y then c1:=Bmp1.Scanline[y];
    if Bmp2.Height>y then c2:=Bmp2.Scanline[y];
    for x:=0 to x1-1 do
    for i:=0 to 2 do
    begin
      Inc(Diff,Integer(c1^<>c2^));
      Inc(c1);
      Inc(c2);
    end;
  end;
  Result:=Round(10000*(Diff/(x1*y1)));
end;

procedure RemoveBreak(Bmp:TBitmap);
var
  x,y:Integer;
  Arr:array of Boolean;
  Temp,Max,TempStart,Start:Integer;
begin
  SetLength(Arr,Bmp.Height);
  for y:=0 to Bmp.Height-1 do
  begin
    Arr[y]:=False;
    for x:=0 to Bmp.Width-1 do if Bmp.Canvas.Pixels[x,y]<>$FFFFFF then
    begin
      Arr[y]:=True;
      Break;
    end;
  end;
  Max:=0;
  Temp:=0;
  for y:=0 to Length(Arr)-1 do
  begin
    if Arr[y] then
    begin
      if Temp=0 then TempStart:=y;
      inc(Temp);
    end else
    begin
      if Temp>Max then
      begin
        Max:=Temp;
        Start:=TempStart;
      end;
      Temp:=0;
    end;
  end;
  if Temp>Max then
  begin
    Max:=Temp;
    Start:=TempStart;
  end;
  Bmp.Canvas.Draw(0,-Start,Bmp);
  Bmp.Height:=Max;

  SetLength(Arr,Bmp.Width);
  for x:=0 to Length(Arr)-1 do
  begin
    Arr[x]:=False;
    for y:=0 to Bmp.Height-1 do if Bmp.Canvas.Pixels[x,y]<>$FFFFFF then
    begin
      Arr[x]:=True;
      Break;
    end;
  end;
  Max:=0;
  Temp:=0;
  for x:=0 to Length(Arr)-1 do
  begin
    if Arr[x] then
    begin
      if Temp=0 then TempStart:=x;
      inc(Temp);
    end else
    begin
      if Temp>Max then
      begin
        Max:=Temp;
        Start:=TempStart;
      end;
      Temp:=0;
    end;
  end;
  if Temp>Max then
  begin
    Max:=Temp;
    Start:=TempStart;
  end;
  Bmp.Canvas.Draw(-Start,0,Bmp);
  Bmp.Width:=Max;
end;

function GetChar(Bmp:TBitmap):Char;
const
  CharList='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
var
  SizeBegin,SizeEnd:Integer;
  CharBmp:TBitmap;
  i:Integer;
  c:Byte;
  Min:Integer;
  Temp:Integer;
begin
  Result:=#0;
  SizeBegin:=Round(Bmp.Height*0.90);
  SizeEnd:=Round(bmp.Height*1.10);
  Min:=10000;
  CharBmp:=TBitmap.Create;
  CharBmp.PixelFormat:=pf24Bit;
  for i:=SizeBegin to SizeEnd do
  for c:=1 to Length(CharList) do
  begin
    CharBmp.Width:=i*2;
    CharBmp.Height:=i*2;
    CharBmp.Canvas.FillRect(Rect(0,0,CharBmp.Width,CharBmp.Height));
    CharBmp.Canvas.Font.Name:='Arial';
    CharBmp.Canvas.Font.Size:=i;
    CharBmp.Canvas.TextOut(0,0,CharList[c]);
    Mono(CharBmp);
    RemoveBreak(CharBmp);
    Temp:=GetDifferents(Bmp,CharBmp);
    if Temp<Min then
    begin
      Min:=Temp;
      Result:=CharList[c];
    end;
  end;
  CharBmp.Free;
end;

procedure Prepare(Bmp:TBitmap);
var
  BmpArr:array of array of Byte;
  i,j,k:Integer;
  Size,Max:Integer;
  ArrSize:array of array[0..2] of Integer;

  procedure f(x1,y1:Integer);
  begin
    inc(Size);
    BmpArr[x1][y1]:=2;
    if BmpArr[x1+1][y1]=1 then f(x1+1,y1);
    if BmpArr[x1-1][y1]=1 then f(x1-1,y1);
    if BmpArr[x1][y1+1]=1 then f(x1,y1+1);
    if BmpArr[x1][y1-1]=1 then f(x1,y1-1);
  end;

  procedure d(x1,y1:Integer);
  begin
    BmpArr[x1][y1]:=0;
    if BmpArr[x1+1][y1]=2 then d(x1+1,y1);
    if BmpArr[x1-1][y1]=2 then d(x1-1,y1);
    if BmpArr[x1][y1+1]=2 then d(x1,y1+1);
    if BmpArr[x1][y1-1]=2 then d(x1,y1-1);
  end;

begin
  SetLength(BmpArr,Bmp.Width);
  for i:=0 to Length(BmpArr)-1 do
  begin
    SetLength(BmpArr[i],Bmp.Height);
    for j:=0 to Bmp.Height-1 do if Bmp.Canvas.Pixels[i,j]=$FFFFFF then BmpArr[i][j]:=0 else BmpArr[i][j]:=1;
  end;

  for i:=0 to Bmp.Width-1 do
  for j:=0 to Bmp.Height-1 do
  begin
    if BmpArr[i][j]=1 then
    begin
      Size:=0;
      f(i,j);
      SetLength(ArrSize,Length(ArrSize)+1);
      ArrSize[Length(ArrSize)-1][0]:=Size;
      ArrSize[Length(ArrSize)-1][1]:=i;
      ArrSize[Length(ArrSize)-1][2]:=j;
    end;
  end;

  Max:=ArrSize[0][0];
  for k:=0 to Length(ArrSize)-1 do if ArrSize[k][0]>Max then Max:=ArrSize[k][0];
  Max:=Round(Max/10);
  for k:=0 to Length(ArrSize)-1 do if ArrSize[k][0]<Max then d(ArrSize[k][1],ArrSize[k][2]);
  for i:=0 to Bmp.Width-1 do
  for j:=0 to Bmp.Height-1 do if BmpArr[i][j]=0 then Bmp.Canvas.Pixels[i,j]:=$FFFFFF else Bmp.Canvas.Pixels[i,j]:=$000000;
end;

function GetImageChars(Bmp:TBitmap):String;
var
  i,j:Integer;
  BmpArrX:array of Boolean;
  ok:Boolean;
  CharPos:array of array of Integer;
  TmpBmp:TBitmap;
  c:Char;
begin
  Form1.Edit1.Text:='';
  Result:='';
  Bmp.PixelFormat:=pf24Bit;
  Mono(Bmp);
  Prepare(Bmp);
  Application.ProcessMessages;
  SetLength(BmpArrX,Bmp.Width);
  for i:=0 to Bmp.Width-1 do
  begin
    BmpArrX[i]:=False;
    for j:=0 to Bmp.Height-1 do
    if Bmp.Canvas.Pixels[i,j]=0 then
    begin
      BmpArrX[i]:=True;
      Break;
    end;
  end;

  SetLength(CharPos,2);
  ok:=False;
  for i:=0 to Bmp.Width-1 do
  if BmpArrX[i] then
  begin
    if not ok then
    begin
      ok:=True;
      SetLength(CharPos[0],Length(CharPos[0])+1);
      CharPos[0][Length(CharPos[0])-1]:=i;
    end;
  end else if ok then
  begin
    ok:=False;
    SetLength(CharPos[1],Length(CharPos[1])+1);
    CharPos[1][Length(CharPos[1])-1]:=i;
  end;

  Form1.ProgressBar1.Max:=Length(CharPos[0]);
  Form1.ProgressBar1.Position:=0;

  TmpBmp:=TBitmap.Create;
  for i:=0 to Length(CharPos[0])-1 do
  begin
    TmpBmp.Height:=Bmp.Height;
    TmpBmp.Width:=CharPos[1][i]-CharPos[0][i];
    TmpBmp.Canvas.CopyRect(Rect(0,0,CharPos[1][i]-CharPos[0][i],Bmp.Height-1),Bmp.Canvas,Rect(CharPos[0][i],0,CharPos[1][i],Bmp.Height-1));
    RemoveBreak(TmpBmp);
    Form1.Canvas.Rectangle(Rect(8,230,46,264));
    Form1.Canvas.Draw(20,238,TmpBmp);
    c:=GetChar(TmpBmp);
    Result:=Result+c;
    Form1.Edit1.Text:=Form1.Edit1.Text+c;
    Form1.ProgressBar1.Position:=Form1.ProgressBar1.Position+1;
    Application.ProcessMessages;
  end;

  TmpBmp.Free;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Edit1.Text:=GetImageChars(Image1.Picture.Bitmap);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  OpenDialog1.InitialDir:=ExtractFilePath(Edit2.Text);
  if OpenDialog1.Execute then Edit2.Text:=OpenDialog1.FileName;
end;

procedure TForm1.Edit2Change(Sender: TObject);
begin
  if FileExists(Edit2.Text) then Image1.Picture.Bitmap.LoadFromFile(Edit2.Text);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Close;
end;

end.
