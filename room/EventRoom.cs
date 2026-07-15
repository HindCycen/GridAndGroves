#region

using System.Collections.Generic;
using Godot;

#endregion

public partial class EventRoom : Room {
    private readonly List<TooltipComponent> _activeTooltips = new();
    private HBoxContainer _buttonContainer;

    private RichTextLabel _descLabel;
    private int _phase;
    [Export] public EventDef EventDef;

    public override void _Ready() {
        base._Ready();

        // 计入房间数（仅在战斗/事件房间增加）
        _saveLoad = GetTree().Root.GetNode<SaveLoad>("SaveLoad");
        if (_saveLoad?.Data != null) {
            _saveLoad.Data.RoomCount++;
        }

        ShowEventPhase1();
    }

    private void ShowEventPhase1() {
        _phase = 1;

        // 场景中已预定义 DescLabel 和 ButtonContainer，获取引用并显示
        _descLabel = GetNode<RichTextLabel>("%DescLabel");
        _descLabel.Visible = true;
        _descLabel.Text = EventDef?.EventDesc ?? "";

        _buttonContainer = GetNode<HBoxContainer>("%ButtonContainer");
        _buttonContainer.Visible = true;

        if (EventDef?.Choices == null) {
            return;
        }


        var choiceCount = EventDef.Choices.Length;
        foreach (var choice in EventDef.Choices) {
            var btn = new Button {
                Text = choice.Name
            };
            btn.SetSize(new Vector2(1320 / choiceCount - 20, 80));
            btn.AddThemeFontSizeOverride("font_size", 20);

            var capturedDesc = choice.Description;
            btn.MouseEntered += () => {
                var tooltip = new TooltipComponent();
                AddChild(tooltip);
                tooltip.Show(btn.GlobalPosition + new Vector2(0, -100), capturedDesc);
                _activeTooltips.Add(tooltip);
            };
            btn.MouseExited += () => {
                foreach (var t in _activeTooltips) {
                    if (IsInstanceValid(t)) {
                        t.Hide();
                        t.QueueFree();
                    }
                }

                _activeTooltips.Clear();
            };

            var capturedChoice = choice;
            btn.Pressed += () => OnChoiceSelected(capturedChoice);
            _buttonContainer.AddChild(btn);
        }
    }

    private void OnChoiceSelected(EventChoiceDef choice) {
        if (_phase != 1) {
            return;
        }


        ExecuteAction(choice.ActionType, choice.ActionValue);

        _phase = 2;

        if (_descLabel != null) {
            _descLabel.Text = choice.ResultDescription;
        }

        if (_buttonContainer != null) {
            foreach (var child in _buttonContainer.GetChildren()) {
                child.QueueFree();
            }

            var continueBtn = new Button {
                Text = "Continue"
            };
            continueBtn.SetSize(new Vector2(200, 80));
            continueBtn.AddThemeFontSizeOverride("font_size", 24);
            continueBtn.Pressed += OnContinue;
            _buttonContainer.AddChild(continueBtn);
        }
    }

    private void ExecuteAction(EventActionType type, int value) {
        var data = _saveLoad?.Data;
        if (data == null) {
            return;
        }


        switch (type) {
            case EventActionType.HealPlayer:
                data.PlayerCurrentHealth = Mathf.Min(data.PlayerCurrentHealth + value, data.PlayerMaxHealth);
                break;
            case EventActionType.DamagePlayer:
                data.PlayerCurrentHealth = Mathf.Max(data.PlayerCurrentHealth - value, 0);
                break;
            case EventActionType.AddBlockToDeck: {
                var list = data.PlayerDeckBlockNames != null
                    ? new List<string>(data.PlayerDeckBlockNames)
                    : new List<string>();
                for (var i = 0; i < value; i++) {
                    list.Add("DamageBlock");
                }

                data.PlayerDeckBlockNames = list.ToArray();
                break;
            }
            case EventActionType.RemoveBlockFromDeck: {
                if (data.PlayerDeckBlockNames != null && data.PlayerDeckBlockNames.Length > 0) {
                    var list = new List<string>(data.PlayerDeckBlockNames);
                    var removeCount = Mathf.Min(value, list.Count);
                    for (var i = 0; i < removeCount; i++) {
                        list.RemoveAt(list.Count - 1);
                    }

                    data.PlayerDeckBlockNames = list.ToArray();
                }

                break;
            }
        }
    }

    private void OnContinue() {
        GoBackToStage();
    }

    private void GoBackToStage() {
        _saveLoad?.Save();
        var stageScene = GD.Load<PackedScene>("res://room/StageRoom.tscn");
        var stage = stageScene.Instantiate<StageRoom>();
        GetTree().Root.AddChild(stage);
        QueueFree();
    }
}