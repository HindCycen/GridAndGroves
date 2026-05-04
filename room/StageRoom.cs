using System;
using Godot;

public partial class StageRoom : UncountedRoom {
    public const int MapCols = 14;
    public const int MapRows = 7;
    private const int Cols = 14;
    private const int Rows = 7;
    private const int CellSize = 96;

    [Export] public StageDef StageDef;

    public static bool[,] Clickable;
    public static bool[,] Left;
    public static bool[,] IsBattleCell;
    public static bool MapGenerated;

    private Node2D _gridContainer;
    private Sprite2D[,] _cells;
    private float _pulseTime;
    private Tween _flashTween;

    private bool _initialized;

    public override void _Ready() {
        base._Ready();

        if (!MapGenerated) {
            var loadedFromSave = TryRestoreMapFromSave();
            if (!loadedFromSave) {
                Clickable = new bool[Cols, Rows];
                Left = new bool[Cols, Rows];
                IsBattleCell = new bool[Cols, Rows];
                GenerateMap();
                Clickable[0, Rows - 1] = true;
                MapGenerated = true;
            }
        }

        _gridContainer = new Node2D {
            Name = "GridContainer"
        };
        AddChild(_gridContainer);

        var totalWidth = Cols * CellSize;
        var totalHeight = Rows * CellSize;
        _gridContainer.Position = new Vector2(
            (1920 - totalWidth) / 2,
            (1080 - totalHeight) / 2
        );

        _cells = new Sprite2D[Cols, Rows];
        BuildGridVisuals();
        _initialized = true;
    }

    private void GenerateMap() {
        _ = GD.Load<Texture2D>("res://room/room_pictures/BattleRoomBn.png");
        _ = GD.Load<Texture2D>("res://room/room_pictures/EventRoomBn.png");

        for (var col = 0; col < Cols; col++) {
            for (var row = 0; row < Rows; row++) {
                if ((col == 0 && row == Rows - 1) || (col == Cols - 1 && row == 0)) {
                    IsBattleCell[col, row] = true;
                }
                else {
                    IsBattleCell[col, row] = Glob.GetMapRand(2) == 0;
                }
            }
        }

        if (_saveLoad?.Data != null && (_saveLoad.Data.GridClickable == null || _saveLoad.Data.GridClickable.Length == 0)) {
            _saveLoad.Data.StageCount++;
        }
    }

    private bool TryRestoreMapFromSave() {
        var data = _saveLoad?.Data;
        if (data?.GridClickable == null || data.GridClickable.Length == 0) return false;
        if (data.GridLeft == null || data.GridLeft.Length == 0) return false;
        if (data.GridIsBattleCell == null || data.GridIsBattleCell.Length == 0) return false;

        var totalCells = Cols * Rows;
        if (data.GridClickable.Length != totalCells) return false;

        Clickable = new bool[Cols, Rows];
        Left = new bool[Cols, Rows];
        IsBattleCell = new bool[Cols, Rows];

        for (var col = 0; col < Cols; col++) {
            for (var row = 0; row < Rows; row++) {
                var index = row * Cols + col;
                Clickable[col, row] = data.GridClickable[index] != 0;
                Left[col, row] = data.GridLeft[index] != 0;
                IsBattleCell[col, row] = data.GridIsBattleCell[index] != 0;
            }
        }

        MapGenerated = true;
        return true;
    }

    private void BuildGridVisuals() {
        var battleTex = GD.Load<Texture2D>("res://room/room_pictures/BattleRoomBn.png");
        var eventTex = GD.Load<Texture2D>("res://room/room_pictures/EventRoomBn.png");

        for (var col = 0; col < Cols; col++) {
            for (var row = 0; row < Rows; row++) {
                var tex = IsBattleCell[col, row] ? battleTex : eventTex;

                var sprite = new Sprite2D {
                    Texture = tex,
                    Position = new Vector2(col * CellSize + CellSize / 2, row * CellSize + CellSize / 2)
                };

                if (Left[col, row]) {
                    sprite.Modulate = new Color(1, 1, 1, 0.5f);
                }
                else if (Clickable[col, row]) {
                    sprite.Modulate = new Color(1, 1, 1, 0);
                }
                else {
                    sprite.Modulate = new Color(1, 1, 1, 1f);
                }

                _gridContainer.AddChild(sprite);
                _cells[col, row] = sprite;

                var area = new Area2D {
                    Name = $"Cell_{col}_{row}"
                };
                var shape = new CollisionShape2D();
                var rect = new RectangleShape2D {
                    Size = new Vector2(CellSize, CellSize)
                };
                shape.Shape = rect;
                area.AddChild(shape);
                area.Position = sprite.Position;

                var capturedCol = col;
                var capturedRow = row;
                area.InputEvent += (_, @event, _) => {
                    if (@event is InputEventMouseButton { ButtonIndex: MouseButton.Left, Pressed: true }) {
                        OnCellClicked(capturedCol, capturedRow);
                    }
                };
                _gridContainer.AddChild(area);
            }
        }
    }

    public override void _Process(double delta) {
        if (!_initialized) return;

        _pulseTime += (float)delta;
        var alpha = (Mathf.Sin(_pulseTime * Mathf.Pi * 2) + 1) / 2;

        for (var col = 0; col < Cols; col++) {
            for (var row = 0; row < Rows; row++) {
                if (Clickable[col, row] && !Left[col, row]) {
                    var c = _cells[col, row].Modulate;
                    _cells[col, row].Modulate = new Color(c.R, c.G, c.B, alpha);
                }
            }
        }
    }

    private void OnCellClicked(int col, int row) {
        if (!Clickable[col, row] || Left[col, row]) return;

        if (_flashTween != null && _flashTween.IsRunning()) return;

        _flashTween = CreateTween();
        for (var i = 0; i < 3; i++) {
            _flashTween.TweenProperty(_cells[col, row], "modulate:a", 0.0, 0.15);
            _flashTween.TweenProperty(_cells[col, row], "modulate:a", 1.0, 0.15);
        }
        _flashTween.TweenCallback(Callable.From(() => EnterRoom(col, row)));
    }

    private void EnterRoom(int col, int row) {
        Left[col, row] = true;
        _cells[col, row].Modulate = new Color(1, 1, 1, 0.5f);

        for (var c = 0; c < Cols; c++) {
            for (var r = 0; r < Rows; r++) {
                Clickable[c, r] = false;
            }
        }

        if (row > 0) Clickable[col, row - 1] = true;
        if (col < Cols - 1) Clickable[col + 1, row] = true;

        var isBattle = IsBattleCell[col, row];

        _saveLoad?.Save();

        if (isBattle) {
            var roomCount = _saveLoad?.Data?.RoomCount ?? 0;
            var stageEnemyChart = GD.Load<StageEnemyChartDef>("res://resources/EgStageEnemyChart.tres");
            EnemyChartDef chartDef;
            if (roomCount == 20) {
                chartDef = stageEnemyChart.BossChart[Glob.GetMonsterRand(stageEnemyChart.BossChart.Length)];
            }
            else if (roomCount > 6) {
                chartDef = stageEnemyChart.StrongEnemyChart[Glob.GetMonsterRand(stageEnemyChart.StrongEnemyChart.Length)];
            }
            else {
                chartDef = stageEnemyChart.WeakEnemyChart[Glob.GetMonsterRand(stageEnemyChart.WeakEnemyChart.Length)];
            }

            var battleScene = GD.Load<PackedScene>("res://room/BattleRoom.tscn");
            var battle = battleScene.Instantiate<BattleRoom>();
            battle.EnemyChart = chartDef;
            GetTree().Root.AddChild(battle);
            QueueFree();
        }
        else {
            EventDef pickedEvent = null;
            if (StageDef?.StageEventRand?.PossibleEvents != null && StageDef.StageEventRand.PossibleEvents.Length > 0) {
                var idx = Glob.GetMapRand(StageDef.StageEventRand.PossibleEvents.Length);
                pickedEvent = StageDef.StageEventRand.PossibleEvents[idx];
            }
            else {
                pickedEvent = GD.Load<EventDef>("res://resources/EgHealEvent.tres");
            }

            var eventScene = GD.Load<PackedScene>("res://room/EventRoom.tscn");
            var eventRoom = eventScene.Instantiate<EventRoom>();
            eventRoom.EventDef = pickedEvent;
            GetTree().Root.AddChild(eventRoom);
            QueueFree();
        }
    }
}
