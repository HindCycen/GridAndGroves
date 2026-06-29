using Godot;

/// <summary>
///     游戏结束画面。显示层数/房间数，提供返回主菜单按钮。
/// </summary>
public partial class GameOver : Node2D {
    public override void _Ready() {
        var bg = new ColorRect {
            Color = new Color(0.1f, 0.05f, 0.05f),
            Size = new Vector2(1920, 1080),
            Position = Vector2.Zero
        };
        AddChild(bg);

        // "游戏结束" 标题
        var title = new Label {
            Text = "Game Over"
        };
        title.AddThemeFontSizeOverride("font_size", 56);
        title.AddThemeColorOverride("font_color", new Color(1.0f, 0.3f, 0.3f));
        title.HorizontalAlignment = HorizontalAlignment.Center;
        var titleSize = title.GetMinimumSize();
        title.Position = new Vector2(960 - titleSize.X / 2, 250);
        AddChild(title);

        // 读取存档数据显示进度
        var saveLoad = GetTree().Root.GetNode<SaveLoad>("SaveLoad");
        var data = saveLoad?.Data;
        var stageCount = data?.StageCount ?? 1;
        var roomCount = data?.RoomCount ?? 0;

        var statsLabel = new Label {
            Text = $"Stage: {stageCount}    Room: {roomCount}"
        };
        statsLabel.AddThemeFontSizeOverride("font_size", 28);
        statsLabel.AddThemeColorOverride("font_color", new Color(0.8f, 0.8f, 0.8f));
        statsLabel.HorizontalAlignment = HorizontalAlignment.Center;
        var statsSize = statsLabel.GetMinimumSize();
        statsLabel.Position = new Vector2(960 - statsSize.X / 2, 380);
        AddChild(statsLabel);

        // 返回主菜单按钮
        var btn = new Button {
            Text = "Return to Main Menu",
            Size = new Vector2(300, 60),
            CustomMinimumSize = new Vector2(300, 60),
            Position = new Vector2(960 - 150, 550)
        };
        btn.AddThemeFontSizeOverride("font_size", 22);
        btn.Pressed += () => {
            var menuScene = GD.Load<PackedScene>("res://MainMenu.tscn");
            var menu = menuScene.Instantiate<MainMenu>();
            GetTree().Root.AddChild(menu);
            QueueFree();
        };
        AddChild(btn);
    }
}
