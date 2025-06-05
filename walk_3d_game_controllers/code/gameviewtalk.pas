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
    LabelSpeaker: TCastleLabel;
    LabelMessage: TCastleLabel;
    ButtonOpenUrl: TCastleButton;
  private
    procedure ClickOK(Sender: TObject);
    procedure ClickUrl(Sender: TObject);
  public
    // Set before Start.
    Speaker, Message, Url: String;
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
  end;

var
  ViewTalk: TViewTalk;

implementation

uses CastleOpenDocument;

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
  ButtonOpenUrl.OnClick := {$ifdef FPC}@{$endif} ClickUrl;

  LabelSpeaker.Caption := Speaker;
  LabelMessage.Caption := Message;
  ButtonOpenUrl.Exists := Url <> '';
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
     Event.IsController(gbSouth)
     // don't react to B, would cause crouch right after TViewMain.Resume
     {or
     Event.IsController(gbEast)} then
  begin
    ClickOK(nil);
    Exit(true);
  end;

  if Event.IsController(gbNorth) then
  begin
    ClickUrl(nil);
    Exit(true);
  end;
end;

procedure TViewTalk.ClickOK(Sender: TObject);
begin
  Container.PopView(Self);
end;

procedure TViewTalk.ClickUrl(Sender: TObject);
begin
  OpenUrl(Url);
end;

end.
