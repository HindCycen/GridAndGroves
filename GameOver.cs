using Godot;

/// <summary>
///     游戏结束画面。显示层数/房间数，提供返回主菜单按钮。
/// </summary>
public partial class GameOver : Node2D {
    public override void _Ready() {
        // 场景中已预定义背景、标题、统计标签和按钮，获取引用

        // 读取存档数据显示进度
        var saveLoad = GetTree().Root.GetNode<SaveLoad>("SaveLoad");
        var data = saveLoad?.Data;
        var stageCount = data?.StageCount ?? 1;
        var roomCount = data?.RoomCount ?? 0;

        var statsLabel = GetNode<Label>("%StatsLabel");
        statsLabel.Text = $"Stage: {stageCount}    Room: {roomCount}";

        // 返回主菜单按钮
        var btn = GetNode<Button>("%ReturnButton");
        btn.Pressed += () => {
            var menuScene = GD.Load<PackedScene>("res://MainMenu.tscn");
            var menu = menuScene.Instantiate<MainMenu>();
            GetTree().Root.AddChild(menu);
            QueueFree();
        };
    }
}
