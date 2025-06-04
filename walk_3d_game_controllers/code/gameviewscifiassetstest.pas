{
  Copyright 2025-2025 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file LICENSE,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Test view for sci-fi assets.
  Not actualy accessible for the user. }
unit GameViewSciFiAssetsTest;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, CastleKeysMouse;

type
  TViewSciFiAssetsTest = class(TCastleView)
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
  ViewSciFiAssetsTest: TViewSciFiAssetsTest;

implementation

constructor TViewSciFiAssetsTest.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gameviewscifiassetstest.castle-user-interface';
end;

procedure TViewSciFiAssetsTest.Start;
begin
  inherited;
  { Executed once when view starts. }
end;

procedure TViewSciFiAssetsTest.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;
  { Executed every frame. }
end;

end.
