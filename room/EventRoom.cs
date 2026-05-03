using System.Collections.Generic;
using System.Linq;
using Godot;

public partial class EventRoom : CountedRoom {
    [Export] public EventDef EventDef;

    private RichTextLabel _descLabel;
    private HBoxContainer _buttonContainer;
    private int _phase;

    private readonly List<TooltipComponent> _activeTooltips = new();

    public override void _Ready() {
        base._Ready();
        ShowEventPhase1();
    }

    private void ShowEventPhase1() {
        _phase = 1;

        _descLabel = new RichTextLabel {
            Position = new Vector2(300, 200)
        };
        _descLabel.SetSize(new Vector2(1320, 400));
        _descLabel.AddThemeFontSizeOverride("font_size", 24);
        _descLabel.BbcodeEnabled = true;
        _descLabel.Text = EventDef?.EventDesc ?? "";
        AddChild(_descLabel);

        _buttonContainer = new HBoxContainer();
        _buttonContainer.SetPosition(new Vector2(300, 700));
        _buttonContainer.SetSize(new Vector2(1320, 100));
        _buttonContainer.AddThemeConstantOverride("separation", 20);
        AddChild(_buttonContainer);

        if (EventDef?.Choices == null) return;

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
        if (_phase != 1) return;

        ExecuteAction(choice.ActionType, choice.ActionValue);

        _phase = 2;

        if (_descLabel != null) {
            _descLabel.Text = choice.ResultDescription;
        }

        if (_buttonContainer != null) {
            foreach (Node child in _buttonContainer.GetChildren()) {
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
        var player = GetTree().GetFirstNodeInGroup("Players") as Player;
        if (player == null) return;

        switch (type) {
            case EventActionType.HealPlayer: {
                var health = player.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
                health?.Heal(value);
                break;
            }
            case EventActionType.DamagePlayer: {
                var health = player.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
                health?.TakeDamage(value);
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
