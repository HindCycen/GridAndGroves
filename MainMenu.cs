using Godot;

/// <summary>
///     主菜单场景。提供新游戏 / 继续游戏 / 退出。
/// </summary>
public partial class MainMenu : Node2D {
    private Button _continueBtn;

    public override void _Ready() {
        // 背景半透明遮罩
        var bg = new ColorRect {
            Color = new Color(0.05f, 0.05f, 0.1f),
            Size = new Vector2(1920, 1080),
            Position = Vector2.Zero
        };
        AddChild(bg);

        // 标题
        var title = new Label {
            Text = "Grid and Groves",
            Position = new Vector2(960, 200)
        };
        title.AddThemeFontSizeOverride("font_size", 64);
        title.AddThemeColorOverride("font_color", new Color(0.8f, 0.9f, 1.0f));
        title.HorizontalAlignment = HorizontalAlignment.Center;
        // 让 Label 以锚点为中心
        var titleSize = title.GetMinimumSize();
        title.Position -= new Vector2(titleSize.X / 2, titleSize.Y / 2);
        AddChild(title);

        // 副标题
        var subtitle = new Label {
            Text = "A Roguelike Deckbuilder",
            Position = new Vector2(960, 270)
        };
        subtitle.AddThemeFontSizeOverride("font_size", 24);
        subtitle.AddThemeColorOverride("font_color", new Color(0.6f, 0.7f, 0.8f));
        subtitle.HorizontalAlignment = HorizontalAlignment.Center;
        var subSize = subtitle.GetMinimumSize();
        subtitle.Position -= new Vector2(subSize.X / 2, subSize.Y / 2);
        AddChild(subtitle);

        // 按钮容器
        var btnContainer = new VBoxContainer {
            Position = new Vector2(960, 500),
            Size = new Vector2(300, 200)
        };
        // 手动居中
        btnContainer.Position -= new Vector2(150, 100);

        _continueBtn = MakeButton("Continue", () => OnContinuePressed());
        btnContainer.AddChild(_continueBtn);
        btnContainer.AddChild(MakeButton("New Game", () => OnNewGamePressed()));
        btnContainer.AddChild(MakeButton("Quit", () => GetTree().Quit()));

        AddChild(btnContainer);

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
