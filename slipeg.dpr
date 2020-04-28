program slipeg;

uses
  Forms,
  Peg in 'Peg.pas' {frmPeg},
  HIGHSCORES in 'HIGHSCORES.pas' {frmScores};

{$R *.res}
{$SetPEFlags 1}

begin
  Application.Initialize;
  Application.Title := 'SliPeg';
  Application.CreateForm(TfrmPeg, frmPeg);
  Application.CreateForm(TfrmScores, frmScores);
  Application.Run;
end.
