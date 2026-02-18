using Godot;
using System;

public partial class Bot : Node2D {
    private Area2D _detectionArea;
    private Vector2I _currentGridPos;
    private Vector2I _currentDirection = Vector2I.Down;
    private AnimatedSprite2D _animatedSprite2D;
    [Export] private BattleContext _battleContext;
    private bool _initialized = false;

    public override void _Ready() {
        _detectionArea = GetNode<Area2D>("%DetectionArea");
        _animatedSprite2D = GetNode<AnimatedSprite2D>("%AnimatedSprite2D");
        _battleContext.SayBattleStarted();
        Visible = false;
        _detectionArea.Monitoring = false;
        // 没招了 这里Godot初始化节点的顺序不固定, Global在这里可能还不存在 傻逼Godot
        // 所以延迟初始化 GoToStarterPoint(), _Process()第一帧再运行

        GetNode<Button>("%Button").Pressed += () => {
            _battleContext.SayTurnStarted();
            _detectionArea.Monitoring = true;
            Visible = true;
            _animatedSprite2D.Play("bot_animation");
            GetTree().CreateTimer(1.0f).Timeout += () => {
                GoToNextGridPos(_currentDirection);
            };
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

    public override void _Process(double delta) {
        // 嗯对放到这里了
        if (!_initialized && Global.GridPoints != null) {
            _initialized = true;
            GoToStarterPoint();
        }
    }

    private void GoToStarterPoint() {
        _detectionArea.Monitoring = false;
        GlobalPosition = new Vector2(
            Global.GetGridPos(new Vector2I(0, 0)).X,
            Global.GetGridPos(new Vector2I(0, 0)).Y - Global.GridSize
            );
        _currentGridPos = new Vector2I(0, -1);
        _animatedSprite2D.Stop();
        Visible = false;
    }

    private void GoToNextGridPos() {
        _currentGridPos =
            _currentGridPos.Y == 4 ?
            (_currentGridPos.X < 6 ?
                new Vector2I(_currentGridPos.X + 1, 0) :
                new Vector2I(0, -1)) :
            new Vector2I(_currentGridPos.X, _currentGridPos.Y + 1);
        GlobalPosition = _currentGridPos.Equals(new Vector2I(0, -1)) ?
            new Vector2(
                Global.GetGridPos(new Vector2I(0, 0)).X,
                Global.GetGridPos(new Vector2I(0, 0)).Y - Global.GridSize
            ) :
            Global.GetGridPos(_currentGridPos);
    }

    private void GoToNextGridPos(Vector2I Direction) {
        _currentGridPos += Direction;
        // If out of bounds, go to starter point
        if (_currentGridPos.X + _currentGridPos.Y > 10 || _currentGridPos.X + _currentGridPos.Y < 0) {
            _battleContext.SayTurnEnded();
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
            GlobalPosition = Global.GetGridPos(_currentGridPos);
            GetTree().CreateTimer(1.0f).Timeout += () => {
                _battleContext.SayTicTac();
                GoToNextGridPos(_currentDirection);
            };
        }
    }
}
