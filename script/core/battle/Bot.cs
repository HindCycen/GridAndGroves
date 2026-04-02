#region

using Godot;

#endregion

public partial class Bot : Node2D {
    private AnimatedSprite2D _animatedSprite2D;
    private BattleTime _battleTime;
    private Vector2I _currentDirection = Vector2I.Down;
    private Vector2I _currentGridPos;
    private Area2D _detectionArea;

    public override void _Ready() {
        _battleTime = GetTree().Root.GetNode<BattleTime>("BattleTime");
        _detectionArea = GetNode<Area2D>("%DetectionArea");
        _animatedSprite2D = GetNode<AnimatedSprite2D>("%AnimatedSprite2D");
        _battleTime.SayBattleStarted();
        Visible = false;
        _detectionArea.Monitoring = false;
        GoToStarterPoint();
        GetNode<Button>("%Button").Pressed += () => {
            _battleTime.SayTurnStarted();
            _detectionArea.Monitoring = true;
            Visible = true;
            _animatedSprite2D.Play("bot_animation");
            GetTree().CreateTimer(1.0f).Timeout += () => { GoToNextGridPos(_currentDirection); };
        };

        _detectionArea.AreaEntered += area => {
            if (area.GetParent<Node2D>() is BlockPart blockPart) {
                GD.Print("Detected BlockPart: " + blockPart.Name);
                _currentDirection = blockPart.Execute(blockPart.GetParent<Block>());
            }
            else {
                GD.Print("Detected: " + area.Name);
            }
        };
    }



    private void GoToStarterPoint() {
        _detectionArea.Monitoring = false;
        GlobalPosition = new Vector2(
            Glob.GetGridPos(new Vector2I(0, 0)).X,
            Glob.GetGridPos(new Vector2I(0, 0)).Y - Glob.GridSize
        );
        _currentGridPos = new Vector2I(0, -1);
        _animatedSprite2D.Stop();
        Visible = false;
    }

    private void GoToNextGridPos() {
        _currentGridPos =
            _currentGridPos.Y == 4
                ? _currentGridPos.X < 6 ? new Vector2I(_currentGridPos.X + 1, 0) : new Vector2I(0, -1)
                : new Vector2I(_currentGridPos.X, _currentGridPos.Y + 1);
        GlobalPosition = _currentGridPos.Equals(new Vector2I(0, -1))
            ? new Vector2(
                Glob.GetGridPos(new Vector2I(0, 0)).X,
                Glob.GetGridPos(new Vector2I(0, 0)).Y - Glob.GridSize
            )
            : Glob.GetGridPos(_currentGridPos);
    }

    private void GoToNextGridPos(Vector2I Direction) {
        _currentGridPos += Direction;
        // If out of bounds, go to starter point
        if (_currentGridPos.X + _currentGridPos.Y > 10 || _currentGridPos.X + _currentGridPos.Y < 0) {
            _battleTime.SayTurnEnded();
            GoToStarterPoint();
        }
        else {
            // Wrap around logic
            if (_currentGridPos.X > 6) {
                _currentGridPos = new Vector2I(0, _currentGridPos.Y + 1);
            }
            else if (_currentGridPos.X < 0) {
                _currentGridPos = new Vector2I(6, _currentGridPos.Y - 1);
            }

            if (_currentGridPos.Y > 4) {
                _currentGridPos = new Vector2I(_currentGridPos.X + 1, 0);
            }
            else if (_currentGridPos.Y < 0) {
                _currentGridPos = new Vector2I(_currentGridPos.X - 1, 4);
            }

            GlobalPosition = Glob.GetGridPos(_currentGridPos);
            GetTree().CreateTimer(1.0f).Timeout += () => {
                _battleTime.SayTicTac();
                GoToNextGridPos(_currentDirection);
            };
        }
    }
}