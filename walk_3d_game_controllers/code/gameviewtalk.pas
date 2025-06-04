unit GameViewTalk;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, CastleKeysMouse;

type
  TViewTalk = class(TCastleView)
  published
    { Components designed using CGE editor.
      These fields will be automatically initialized at Start. }
    ButtonOK: TCastleButton;
  private
    procedure ClickOK(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
  end;

var
  ViewTalk: TViewTalk;

implementation

constructor TViewTalk.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gameviewtalk.castle-user-interface';
  InterceptInput := true;
end;

procedure TViewTalk.Start;
begin
  inherited;
  { Executed once when view starts. }
  ButtonOK.OnClick := {$ifdef FPC}@{$endif} ClickOK;
end;

procedure TViewTalk.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;
  { Executed every frame. }
end;

function TViewTalk.Press(const Event: TInputPressRelease): Boolean;
begin
  Result := inherited;
  // because of InterceptInput, inherited always returns true
  // if Result then Exit;

  if Event.IsKey(keyEscape) or
     Event.IsController(gbNorth) or
     Event.IsController(gbEast) then
  begin
    Container.PopView(Self);
    Exit(true);
  end;
end;

procedure TViewTalk.ClickOK(Sender: TObject);
begin
  Container.PopView(Self);
end;

end.
