using Godot;

/// <summary>
///     主菜单场景。提供新游戏 / 继续游戏 / 退出。
/// </summary>
public partial class MainMenu : Node2D {
    private Button _continueBtn;

    public override void _Ready() {
        // 场景中已预定义背景、标题、副标题和按钮容器，获取引用
        var btnContainer = GetNode<VBoxContainer>("%ButtonContainer");

        _continueBtn = MakeButton("Continue", () => OnContinuePressed());
        btnContainer.AddChild(_continueBtn);
        btnContainer.AddChild(MakeButton("New Game", () => OnNewGamePressed()));
        btnContainer.AddChild(MakeButton("Quit", () => GetTree().Quit()));

        // 检查是否有存档
        _continueBtn.Disabled = !ResourceLoader.Exists("user://savegame.tres");
    }

    private Button MakeButton(string text, System.Action action) {
        var btn = new Button {
            Text = text,
            Size = new Vector2(300, 60),
            CustomMinimumSize = new Vector2(300, 60)
        };
        btn.AddThemeFontSizeOverride("font_size", 22);
        btn.Pressed += action;
        return btn;
    }

    private void OnNewGamePressed() {
        var saveLoad = GetTree().Root.GetNode<SaveLoad>("SaveLoad");
        saveLoad.ResetForNewGame();

        var stageScene = GD.Load<PackedScene>("res://room/StageRoom.tscn");
        var stage = stageScene.Instantiate<StageRoom>();
        GetTree().Root.AddChild(stage);
        QueueFree();
    }

    private void OnContinuePressed() {
        var saveLoad = GetTree().Root.GetNode<SaveLoad>("SaveLoad");
        saveLoad.Load();

        var stageScene = GD.Load<PackedScene>("res://room/StageRoom.tscn");
        var stage = stageScene.Instantiate<StageRoom>();
        GetTree().Root.AddChild(stage);
        QueueFree();
    }
}
