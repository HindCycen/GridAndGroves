#region

using Godot;

#endregion

/// <summary>
///     牌堆查看器。显示牌堆中所有方块的列表。
///     由 <see cref="BattleRoom"/> 在点击"抽牌堆"/"弃牌堆"按钮时动态创建。
/// </summary>
[GlobalClass]
public partial class PileViewer : ColorRect {
    private readonly VBoxContainer _cardList;
    private readonly Label _titleLabel;
    private string _currentTitle;

    public PileViewer() {
        Color = new Color(0, 0, 0, 0.6f);
        Size = new Vector2I(1920, 1080);
        Position = Vector2I.Zero;
        MouseFilter = MouseFilterEnum.Stop;

        // 面板
        var panel = new Panel();
        panel.SetSize(new Vector2I(700, 800));
        panel.SetPosition(new Vector2I(610, 140));
        AddChild(panel);

        // 标题
        _titleLabel = new Label();
        _titleLabel.SetPosition(new Vector2I(20, 10));
        _titleLabel.AddThemeFontSizeOverride("font_size", 24);
        panel.AddChild(_titleLabel);

        // 关闭按钮
        var closeBtn = new Button {
            Text = "关闭"
        };
        closeBtn.SetPosition(new Vector2I(640, 10));
        closeBtn.SetSize(new Vector2I(50, 30));
        closeBtn.Pressed += QueueFree;
        panel.AddChild(closeBtn);

        // 滚动容器
        var scroll = new ScrollContainer();
        scroll.SetPosition(new Vector2I(20, 50));
        scroll.SetSize(new Vector2I(660, 740));
        panel.AddChild(scroll);

        // 卡片列表容器
        _cardList = new VBoxContainer();
        scroll.AddChild(_cardList);
    }

    /// <summary>
    ///     打开牌堆查看器，显示指定牌堆的内容。
    /// </summary>
    public void Show(string title, PileComponent pile) {
        _currentTitle = title;
        _titleLabel.Text = title;

        // 清空之前的卡片
        foreach (var child in _cardList.GetChildren()) {
            child.QueueFree();
        }

        if (pile.Count == 0) {
            var empty = new Label {
                Text = "（空）",
                CustomMinimumSize = new Vector2I(0, 30)
            };
            _cardList.AddChild(empty);
            return;
        }

        foreach (var block in pile.Pile) {
            var card = new Panel {
                CustomMinimumSize = new Vector2I(640, 36)
            };

            var nameLabel = new Label {
                Text = $"  {block.Definition.BlockName}    (Faction: {block.Faction})"
            };
            nameLabel.SetPosition(new Vector2I(10, 8));
            card.AddChild(nameLabel);

            _cardList.AddChild(card);
        }
    }
}
