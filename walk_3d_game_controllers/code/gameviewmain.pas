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
  CastleUIControls, CastleControls, CastleKeysMouse, CastleTimeUtils,
  CastleTransform, CastleScene;

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
    DesignEngineHeader: TCastleUserInterface;
    FactorySpawnBody: TCastleComponentFactory;
    ButtonControllersInitialize: TCastleButton;
    Aliens: TCastleTransform;
    DesignAliens: TCastleTransformDesign;
    SceneHorse1, SceneHorse2, SceneHorseWhite1: TCastleTransform;
  private
    SceneAlien, SceneAlienComputer: TCastleScene;
    AlienCylinder: TCastleTransform;
    LeftTriggerPressed: Boolean;
    RightTriggerPressed: Boolean;
    { Track time since any activity, to redisplay the hint after some time. }
    TimeSinceActivity: TFloatTime;
    procedure ClickControllersInitialize(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: Boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
    procedure Pause; override;
    procedure Resume; override;
  end;

var
  ViewMain: TViewMain;

implementation

uses SysUtils,
  CastleInputs, CastleGameControllers, CastleStringUtils,
  CastleLog, CastleUtils,
  GameViewTalk;

{ TViewMain ----------------------------------------------------------------- }

constructor TViewMain.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gameviewmain.castle-user-interface';
end;

procedure TViewMain.Start;
const
  { For gamepad usage at Delphi Summit, to make it easier to Aim to talk,
    slow down rotations. }
  RotationSpeed = 0.33;
begin
  inherited;
  WalkNavigation1.UseGameController;
  WalkNavigation1.RotationHorizontalSpeed := WalkNavigation1.RotationHorizontalSpeed * RotationSpeed;
  WalkNavigation1.RotationVerticalSpeed := WalkNavigation1.RotationVerticalSpeed * RotationSpeed;
  Controllers.Initialize;
  ButtonControllersInitialize.OnClick :=
    {$ifdef FPC}@{$endif} ClickControllersInitialize;
  { These components are within the DesignAliens,
    so we cannot access them just by declaring them in the published section. }
  SceneAlien := DesignAliens.DesignedComponent('SceneAlien') as TCastleScene;
  SceneAlienComputer := DesignAliens.DesignedComponent('SceneAlienComputer') as TCastleScene;
  AlienCylinder := DesignAliens.DesignedComponent('AlienCylinder') as TCastleTransform;
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

const
  TimeToShowHint = 5 * 60.0; // 5 minutes
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

  // update TimeSinceActivity
  if WalkNavigation1.Input_Forward.IsPressed(Container) or
     WalkNavigation1.Input_Backward.IsPressed(Container) or
     WalkNavigation1.Input_LeftStrafe.IsPressed(Container) or
     WalkNavigation1.Input_RightStrafe.IsPressed(Container) then
    TimeSinceActivity := 0;
  TimeSinceActivity := TimeSinceActivity + SecondsPassed;

  // show hint after TimeToShowHint passed without activity
  if TimeSinceActivity >= TimeToShowHint then
  begin
    RectHint.Exists := true;
    DesignEngineHeader.Exists := true;
  end;
end;

function TViewMain.Press(const Event: TInputPressRelease): Boolean;
const
  ForceStrength = 3000;

  { Shoot ray through the center of the viewport, see what TCastleTransform
    is hit. }
  function GetTransformHit: TCastleTransform;
  begin
    Result := MainViewport.TransformHit(
      Vector2(
        MainViewport.EffectiveWidth / 2,
        MainViewport.EffectiveHeight / 2),
      false);
  end;

  { Push TCastleRigidBody in front of you. }
  procedure PushForce;
  var
    CamPos, CamDir, CamUp: TVector3;
    TransformHit: TCastleTransform;
  begin
    TransformHit := GetTransformHit;
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

  procedure TryTalk;
  var
    TransformHit: TCastleTransform;
  begin
    TransformHit := GetTransformHit;

    { For now, the whole logic (did we show already aliens etc.) is in this view.
      And we hardcoded which scene names -> result in which speaker/message.

      For a real game, to make it more flexible, you could use TCastleBehavior
      ( see https://castle-engine.io/behaviors ):
      - to detect NPCs (speakers),
      - to hold their logic ("has this NPC spoke already?"),
      - to hold their messages.
    }
    if TransformHit <> nil then
    begin
      { Comparing with TransformHit.Name would also work, but is a little dirtier,
        since the SceneHorseXxx properties can be checked and used for other
        purposes too. }
      // if ArrayContainsString(TransformHit.Name, ['SceneHorse1',
      //   'SceneHorse2', 'SceneHorseWhite1']) then
      if (TransformHit = SceneHorse1) or
         (TransformHit = SceneHorse2) or
         (TransformHit = SceneHorseWhite1) then
      begin
        Aliens.Exists := true;
        ViewTalk.Url := '';
        ViewTalk.Speaker := 'Horse says:';
        ViewTalk.Message :=
          'A strange object fell from the sky last night.' + NL +
          'Look behind the rocks.';
          // Unsure if this is understandable joke in English.
          //  + NL +
          // 'Also, <i>neeeeigh!</i>!';
        Container.PushView(ViewTalk);
      end else
      // if ArrayContainsString(TransformHit.Name, ['SceneAlienComputer']) then
      if TransformHit = SceneAlienComputer then
      begin
        SceneAlien.Exists := true;
        ViewTalk.Url := '';
        ViewTalk.Speaker := 'Computer says:';
        ViewTalk.Message :=
          'Link established.' + NL +
          'You can talk with The Messenger.';
        Container.PushView(ViewTalk);
      end else
      if TransformHit = AlienCylinder then
      begin
        if SceneAlien.Exists then
        begin
          ViewTalk.Url := 'https://castle-engine.io/why_pascal';
          ViewTalk.Speaker := 'The Messenger says:';
          ViewTalk.Message :=
            '<b>I am The Messenger.</b>' + NL +
            '<b><i>Pascal rules!</i></b>';
          Container.PushView(ViewTalk);
        end else
        begin
          ViewTalk.Url := '';
          ViewTalk.Speaker := 'Empty Cylinder says:';
          ViewTalk.Message :=
            '<i>(The cylinder is empty and says nothing.)</i>';
          Container.PushView(ViewTalk);
        end;
      end else
        WritelnLog('Hit transform %s, but it is not a speaker.', [
          TransformHit.Name
        ]);
    end;
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

  TimeSinceActivity := 0;

  { Don't handle inputs if we're not front-most view.
    This is just extra check, as TViewTalk already has InterceptInput = @true. }
  if Container.FrontView <> Self then
    Exit;

  if Event.IsKey(keyF1) or Event.IsController(gbMenu) then
  begin
    RectHint.Exists := not RectHint.Exists;
    DesignEngineHeader.Exists := not DesignEngineHeader.Exists;
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

  if Event.IsKey(keyE) or Event.IsController(gbWest) then
  begin
    TryTalk;
    Exit(true); // input was handled
  end;
end;

procedure TViewMain.ClickControllersInitialize(Sender: TObject);
begin
  { Should never be needed on Windows.
    May be needed on Linux to detect newly connected controllers. }
  Controllers.Initialize;
end;

procedure TViewMain.Pause;
begin
  inherited;
  { Do not detect A / B (jump / crouch) during talk. }
  WalkNavigation1.Exists := false;
end;

procedure TViewMain.Resume;
begin
  WalkNavigation1.Exists := true;
  inherited;
end;

end.
