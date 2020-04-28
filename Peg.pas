unit Peg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Buttons, Menus, INIfiles;

type
  TfrmPeg = class(TForm)
    mnuMain: TMainMenu;
    mnuPegs: TMenuItem;
    mnuGame: TMenuItem;
    mnuNewEnglish: TMenuItem;
    mnuNewEuropean: TMenuItem;
    mnuExit: TMenuItem;
    img0: TImage;
    img1: TImage;
    img2: TImage;
    mnuTime: TMenuItem;
    tmrGameTime: TTimer;
    img3: TImage;
    mnuSep1: TMenuItem;
    mnuSep2: TMenuItem;
    mnuScores: TMenuItem;
    procedure DrawPeg(X, Y, SquareIndex: Integer);
    procedure NewGame();
    procedure tmrGameTimeTimer(Sender: TObject);
    procedure mnuNewEuropeanClick(Sender: TObject);
    procedure mnuNewEnglishClick(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure mnuScoresClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
        //High scores
    HSname: array[1..10] of string;
    HStime: array[1..10] of DWORD;
    procedure Paint; override; //Paint override needed to display new game from FormCreate
  end;

const
  BoardSize = 7; //Width of playing board

type
  GameBoard = array[1..BoardSize, 1..BoardSize] of Boolean;

const
  PegSize = 52; //Size of a brick in pixels
  EnglishBoard: GameBoard = ((False, False, True, True, True, False, False), (False, False, True, True, True, False, False), (True, True, True, True, True, True, True), (True, True, True, True, True, True, True), (True, True, True, True, True, True, True), (False, False, True, True, True, False, False), (False, False, True, True, True, False, False));
  EuropeanBoard: GameBoard = ((False, False, True, True, True, False, False), (False, True, True, True, True, True, False), (True, True, True, True, True, True, True), (True, True, True, True, True, True, True), (True, True, True, True, True, True, True), (False, True, True, True, True, True, False), (False, False, True, True, True, False, False));

var
  frmPeg: TfrmPeg;
  PegsLeft, SelectedX, SelectedY: Integer;
  BoardStatus: GameBoard;
  BoardSelected: GameBoard;
  GameTime: DWORD;
  GameRunning: Boolean;
  PegPic: array[0..3] of^TBitmap;

implementation

{$R *.dfm}

uses
  HIGHSCORES;

procedure TfrmPeg.Paint;
//Paint override needed, otherwise won't display game if started from FormCreate
begin
  NewGame();
end;

procedure TfrmPeg.DrawPeg(X, Y, SquareIndex: Integer);
begin
  frmPeg.Canvas.Draw((X - 1) * PegSize, (Y - 1) * PegSize, PegPic[SquareIndex]^);
end;

procedure TfrmPeg.NewGame();
var
  X, Y: Integer;
begin
  frmPeg.ClientWidth := BoardSize * PegSize;
  frmPeg.ClientHeight := BoardSize * PegSize;
  PegsLeft := 0;
  //Draw empty board
  for X := 1 to BoardSize do
    for Y := 1 to BoardSize do
      if BoardSelected[X, Y] = True then
      begin
        DrawPeg(X, Y, 2);
        Inc(PegsLeft);
      end
      else
        DrawPeg(X, Y, 0);
  //Initialise boards
  BoardStatus := BoardSelected;
  //Remove central peg
  BoardStatus[4, 4] := False;
  DrawPeg(4, 4, 1);
  Dec(PegsLeft);
  //Set flag as game running
  GameRunning := True;
  mnuPegs.Caption := 'Moves=' + IntToStr(PegsLeft);
  //Initialise timer
  tmrGameTime.Enabled := False;
  GameTime := 0;
  mnuTime.Caption := 'Time=0';
  SelectedX := 0;
  //SelectedY := 0; //Not really needed
end;

procedure TfrmPeg.mnuNewEnglishClick(Sender: TObject);
begin
  BoardSelected := EnglishBoard;
  NewGame();
end;

procedure TfrmPeg.mnuNewEuropeanClick(Sender: TObject);
begin
  BoardSelected := EuropeanBoard;
  NewGame();
end;

procedure TfrmPeg.mnuScoresClick(Sender: TObject);
begin
  if frmScores.Visible = False then
    frmScores.Show
  else
    frmScores.Hide;
end;

procedure TfrmPeg.mnuExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmPeg.FormCreate(Sender: TObject);
var
  myINI: TINIFile;
  i: Byte;
begin
  //Initialise options from INI file
  myINI := TINIFile.Create(ExtractFilePath(Application.EXEName) + 'SliPeg.ini');
  //Read high scores from INI file
  for i := 1 to 10 do
  begin
    HSname[i] := myINI.ReadString('HighScores', 'Name' + IntToStr(i), 'Nobody');
    HStime[i] := myINI.ReadInteger('HighScores', 'Time' + IntToStr(i), i * 100);
  end;
  myINI.Free;
  //Initialise shapes images: 0-8: uncovered, 9=blank, 10=flag, 11=maybe
  New(PegPic[0]);
  PegPic[0]^ := img0.Picture.Bitmap;
  New(PegPic[1]);
  PegPic[1]^ := img1.Picture.Bitmap;
  New(PegPic[2]);
  PegPic[2]^ := img2.Picture.Bitmap;
  New(PegPic[3]);
  PegPic[3]^ := img3.Picture.Bitmap;
  //Start new game
  BoardSelected := EnglishBoard;
  NewGame();
end;

procedure TfrmPeg.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  PegX, PegY, i, j: Integer;
  myINI: TINIFile;
  //High score
  WinnerName: string;
begin
  tmrGameTime.Enabled := True;
  if (GameRunning = True) and (Button = mbLeft) then
  begin
    PegX := X div PegSize + 1;
    PegY := Y div PegSize + 1;
    //Check BoardSelected for out of bound
    if (BoardSelected[PegX, PegY] = False) then
      Exit;
    //Clicking a peg
    if (BoardStatus[PegX, PegY] = True) then
    begin
      if (PegX = SelectedX) and (PegY = SelectedY) then
      begin
        //Was selected: deselect
        SelectedX := 0;
        //SelectedY := 0; //Not really needed
        DrawPeg(PegX, PegY, 2);
      end
      else
      begin
        //If a peg was selected: deselect it
        if (SelectedX <> 0) then
          DrawPeg(SelectedX, SelectedY, 2);
        //Select clicked peg
        SelectedX := PegX;
        SelectedY := PegY;
        DrawPeg(PegX, PegY, 3);
      end;
    end
    else
    begin
      //If peg selected, and destination 2 positions in X or Y, and same position in other axis: valid move
      if (SelectedX <> 0) then //Checking only X sufficient
      begin
        //Get "jumped-over" peg coordinates
        i := (PegX + SelectedX) div 2;
        j := (PegY + SelectedY) div 2;
        if (BoardStatus[i, j] = True) and (((Abs(SelectedX - PegX) = 2) and (SelectedY = PegY)) or ((Abs(SelectedY - PegY) = 2) and (SelectedX = PegX))) then
        begin
          //Reached here: valid move
          //Remove peg from source
          BoardStatus[SelectedX, SelectedY] := False;
          DrawPeg(SelectedX, SelectedY, 1);
          Sleep(200);
          //Put peg in clicked destination
          BoardStatus[PegX, PegY] := True;
          DrawPeg(PegX, PegY, 2);
          Sleep(200);
          //Remove central peg
          BoardStatus[i, j] := False;
          DrawPeg(i, j, 1);
          //Move complete: no more peg currently selected
          SelectedX := 0;
          //SelectedY := 0; //Not really needed
          //Decrease pegs left count
          Dec(PegsLeft);
          mnuPegs.Caption := 'Moves=' + IntToStr(PegsLeft);
          //Game won?
          if (PegsLeft = 1) then
          begin
            GameRunning := False;
            tmrGameTime.Enabled := False;
            //Highscore?
            for i := 1 to 10 do
            begin
              if (GameTime < HStime[i]) then
              begin
                //Get name
                WinnerName := InputBox('You''re Winner!', 'You placed #' + IntToStr(i) + ' with your time of ' + IntToStr(GameTime) + '.' + slinebreak + 'Enter your name:', HSname[1]);
                //Shift high scores downwards; If placed 10, skip as we'll simply overwrite last score
                if i < 10 then
                  for j := 10 downto i + 1 do
                  begin
                    HSname[j] := HSname[j - 1];
                    HStime[j] := HStime[j - 1];
                  end;
                //Set new high score
                HSname[i] := WinnerName;
                HStime[i] := GameTime;
                //Save high scores to INI file
                myINI := TINIFile.Create(ExtractFilePath(Application.EXEName) + 'SliPeg.ini');
                for j := 1 to 10 do
                begin
                  myINI.WriteString('HighScores', 'Name' + IntToStr(j), HSname[j]);
                  myINI.WriteInteger('HighScores', 'Time' + IntToStr(j), HStime[j]);
                end;
                //Close INI file
                myINI.Free;
                //Exit so that we only get 1 high score!
                Exit;
              end;
            end;
            ShowMessage('You win but your time of ' + IntToStr(GameTime) + ' is not a high score.');
            Exit;
          end
          else
          begin
            //Any moves left?
            for i := 1 to BoardSize do
              for j := 1 to BoardSize do
                if (BoardStatus[i, j] = True) then
                  if (i > 2) and (BoardStatus[i - 1, j] = True) and (BoardSelected[i - 2, j] = True) and (BoardStatus[i - 2, j] = False) then
                    Exit
                  else if (j > 2) and (BoardStatus[i, j - 1] = True) and (BoardSelected[i, j - 2] = True) and (BoardStatus[i, j - 2] = False) then
                    Exit
                  else if (i < BoardSize - 2) and (BoardStatus[i + 1, j] = True) and (BoardSelected[i + 2, j] = True) and (BoardStatus[i + 2, j] = False) then
                    Exit
                  else if (j < BoardSize - 2) and (BoardStatus[i, j + 1] = True) and (BoardSelected[i, j + 2] = True) and (BoardStatus[i, j + 2] = False) then
                    Exit;
            //Reached here: no move left
            showmessage('You lose!');
            GameRunning := False;
            tmrGameTime.Enabled := False;
            Exit;
          end;
        end;
      end;
    end;
  end;
end;

procedure TfrmPeg.tmrGameTimeTimer(Sender: TObject);
begin
  //Increment counter
  Inc(GameTime);
  //Update counter
  mnuTime.Caption := 'Time=' + IntToStr(GameTime);
end;

end.

