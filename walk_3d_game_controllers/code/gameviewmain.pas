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

{ Main view, where most of the application logic takes place. }
unit GameViewMain;

interface

uses Classes, Contnrs,
  CastleVectors, CastleComponentSerialize, CastleCameras,
  CastleUIControls, CastleControls, CastleKeysMouse;

type
  { Main view, where most of the application logic takes place. }
  TViewMain = class(TCastleView)
  published
    { Components designed using CGE editor.
      These fields will be automatically initialized at Start. }
    LabelFps: TCastleLabel;
    WalkNavigation1: TCastleWalkNavigation;
    RectHint: TCastleRectangleControl;
  private
    LeftTriggerPressed: Boolean;
    RightTriggerPressed: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: Boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
  end;

var
  ViewMain: TViewMain;

implementation

uses SysUtils,
  CastleInputs, CastleGameControllers, CastleStringUtils;

{ TViewMain ----------------------------------------------------------------- }

constructor TViewMain.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gameviewmain.castle-user-interface';
end;

procedure TViewMain.Start;
begin
  inherited;
  WalkNavigation1.UseGameController;
  Controllers.Initialize;
end;

procedure TViewMain.Update(const SecondsPassed: Single; var HandleInput: Boolean);

  procedure SimulateAxisPressRelease(const AxisValue: Single; var LastPressed: Boolean;
    const FakeEvent: TInputPressRelease);
  var
    NewPressed: Boolean;
  begin
    NewPressed := AxisValue > 0.5;
    if LastPressed <> NewPressed then
    begin
      LastPressed := NewPressed;
      if NewPressed then
        Press(FakeEvent)
      else
        Release(FakeEvent);
    end;
  end;

begin
  inherited;
  { This virtual method is executed every frame (many times per second). }
  Assert(LabelFps <> nil, 'If you remove LabelFps from the design, remember to remove also the assignment "LabelFps.Caption := ..." from code');
  LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;

  WalkNavigation1.MouseLook := buttonRight in Container.MousePressed;

  { Left and right triggers are analog, they are axes in
    TGameController.AxisLeft/RightTrigger, and they don't generate
    any TInputPressRelease events when pressed.
    However, we can track their value in Update, and manually simulate
    "discrete" press events. }
  if Controllers.Count > 0 then
  begin
    SimulateAxisPressRelease(Controllers[0].AxisRightTrigger, RightTriggerPressed,
      { Fake left mouse button press when right trigger is pressed. }
      InputMouseButton(Container.MousePosition, buttonLeft, 0, []));

    SimulateAxisPressRelease(Controllers[0].AxisLeftTrigger, LeftTriggerPressed,
      { Fake keyEnter press when left trigger is pressed. }
      InputKey(Container.MousePosition, keyEnter, CharEnter, []));
  end;
end;

function TViewMain.Press(const Event: TInputPressRelease): Boolean;

  procedure PushForce;
  begin

  end;

  procedure SpawnBody;
  begin

  end;

begin
  Result := inherited;
  if Result then Exit; // allow the ancestor to handle keys

  { This virtual method is executed when user presses
    a key, a mouse button, or touches a touch-screen.

    Note that each UI control has also events like OnPress and OnClick.
    These events can be used to handle the "press", if it should do something
    specific when used in that UI control.
    The TViewMain.Press method should be used to handle keys
    not handled in children controls.
  }

  if Event.IsKey(keyF1) or Event.IsController(gbMenu) then
  begin
    RectHint.Exists := not RectHint.Exists;
    Exit(true); // input was handled
  end;

  if Event.IsMouseButton(buttonLeft) then
  begin
    PushForce;
    Exit(true); // input was handled
  end;

  if Event.IsKey(keyEnter) then
  begin
    SpawnBody;
    Exit(true); // input was handled
  end;
end;

end.
