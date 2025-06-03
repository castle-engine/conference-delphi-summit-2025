unit GameViewVillageAssetsTest;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, CastleKeysMouse;

type
  TViewVillageAssetsTest = class(TCastleView)
  published
    { Components designed using CGE editor.
      These fields will be automatically initialized at Start. }
    // ButtonXxx: TCastleButton;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

var
  ViewVillageAssetsTest: TViewVillageAssetsTest;

implementation

constructor TViewVillageAssetsTest.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gameviewvillageassetstest.castle-user-interface';
end;

procedure TViewVillageAssetsTest.Start;
begin
  inherited;
  { Executed once when view starts. }
end;

procedure TViewVillageAssetsTest.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;
  { Executed every frame. }
end;

end.
