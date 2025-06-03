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
  CastleVectors, CastleComponentSerialize, CastleCameras, CastleViewport,
  CastleUIControls, CastleControls, CastleKeysMouse;

type
  { Main view, where most of the application logic takes place. }
  TViewMain = class(TCastleView)
  published
    { Components designed using CGE editor.
      These fields will be automatically initialized at Start. }
    LabelFps: TCastleLabel;
    WalkNavigation1: TCastleWalkNavigation;
    MainViewport: TCastleViewport;
    RectHint: TCastleRectangleControl;
    FactorySpawnBody: TCastleComponentFactory;
    ButtonControllersInitialize: TCastleButton;
  private
    LeftTriggerPressed: Boolean;
    RightTriggerPressed: Boolean;
    procedure ClickControllersInitialize(Sender: TObject);
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
  CastleInputs, CastleGameControllers, CastleStringUtils, CastleTransform,
  CastleLog;

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
  ButtonControllersInitialize.OnClick :=
    {$ifdef FPC}@{$endif} ClickControllersInitialize;
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

  // use mouse look when holding right mouse button
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

  // update ButtonControllersInitialize.Caption to visualize detected controllers
  ButtonControllersInitialize.Caption := Format('Reinitialize controllers (%d)', [
    Controllers.Count
  ]);
end;

function TViewMain.Press(const Event: TInputPressRelease): Boolean;
const
  ForceStrength = 3000;

  { Push TCastleRigidBody in front. }
  procedure PushForce;
  var
    CamPos, CamDir, CamUp: TVector3;
    TransformHit: TCastleTransform;
  begin
    // Shoot ray through the center of the viewport.
    TransformHit := MainViewport.TransformHit(
      Vector2(
        MainViewport.EffectiveWidth / 2,
        MainViewport.EffectiveHeight / 2),
      false);
    if (TransformHit <> nil) and
       (TransformHit.RigidBody <> nil) and
       // mesh and plane colliders are static anyway, pushing them would do nothing
       (not (TransformHit.Collider is TCastleMeshCollider)) and
       (not (TransformHit.Collider is TCastlePlaneCollider)) then
    begin
      WritelnLog('Hit transform %s', [TransformHit.Name]);
      MainViewport.Camera.GetWorldView(CamPos, CamDir, CamUp);
      TransformHit.RigidBody.AddForce(CamDir * ForceStrength, false);
    end;
  end;

  { Spawn body in front of the camera. }
  procedure SpawnBody;
  var
    CamPos, CamDir, CamUp: TVector3;
    NewTransform: TCastleTransform;
  begin
    MainViewport.Camera.GetWorldView(CamPos, CamDir, CamUp);

    NewTransform := FactorySpawnBody.TransformLoad(FreeAtStop);
    NewTransform.Translation := CamPos + CamDir * 2;
    NewTransform.Direction := CamDir;
    MainViewport.Items.Add(NewTransform);

    NewTransform.RigidBody.AddForce(CamDir * ForceStrength, false);
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
    SpawnBody;
    Exit(true); // input was handled
  end;

  if Event.IsKey(keyEnter) then
  begin
    PushForce;
    Exit(true); // input was handled
  end;
end;

procedure TViewMain.ClickControllersInitialize(Sender: TObject);
begin
  { Should never be needed on Windows.
    May be needed on Linux to detect newly connected controllers. }
  Controllers.Initialize;
end;

end.
