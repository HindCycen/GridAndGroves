#region

using Godot;

#endregion

/// <summary>
///     视觉效果 Action。包装一个视觉节点，在 duration 内更新其动画，
///     duration 归零后销毁视觉节点。
///     用法：
///     var vfx = new SomeVFX(atPosition);
///     queue.AddToBottom(new VFXAction(vfx, 0.5f));
/// </summary>
public class VFXAction : AbstractAction {
    private readonly Node _parent;
    private readonly Node2D _vfxNode;

    /// <summary>
    ///     创建一个 VFX Action。
    /// </summary>
    /// <param name="vfxNode">要播放的视觉节点（通常是 Sprite2D 或 CPUParticles2D）</param>
    /// <param name="duration">播放时长</param>
    /// <param name="parent">VFX 节点的父节点。为 null 时添加到当前场景</param>
    public VFXAction(Node2D vfxNode, float duration, Node parent = null) : base(duration) {
        _vfxNode = vfxNode;
        _parent = parent;
        ActionType = Glob.ActionType.VFX;

        // 立即将 VFX 节点挂入场景
        if (_vfxNode != null && _vfxNode.GetParent() == null) {
            var targetParent = _parent ?? Source?.GetTree()?.CurrentScene;
            targetParent?.AddChild(_vfxNode);
        }
    }

    public override void Update(float delta) {
        if (IsDone) {
            return;
        }

        TickDuration(delta);
        if (!IsDone) {
            return;
        }

        // duration 归零 → 销毁 VFX 节点
        if (_vfxNode != null && GodotObject.IsInstanceValid(_vfxNode)) {
            if (_vfxNode.GetParent() != null) {
                _vfxNode.GetParent().RemoveChild(_vfxNode);
            }

            _vfxNode.QueueFree();
        }
    }
}