#region

using System.Linq;
using Godot;

#endregion

/// <summary>
///     对全体存活敌人造成伤害。
///     CreateAction 为每个敌人创建一个 DamageAction（带 duration），
///     第一个作为返回值入队，其余通过 AddToBottom 追加。
/// </summary>
[GlobalClass]
public partial class DamageEnemyBehavior : BlockPartBehavior {
    public override AbstractGameAction CreateAction(Block block, BlockPart part) {
        var tree = block.GetTree();
        if (tree == null) {
            return null;
        }

        var targets = tree.GetNodesInGroup("Enemies")
            .OfType<Node2D>()
            .Where(e => {
                var hc = e.GetNodeOrNull<HealthComponent>("RenderingComponent/HealthComponent");
                return hc != null && !hc.IsDead;
            })
            .ToList();

        if (targets.Count == 0) {
            return null;
        }

        // 对每个敌人单独创建一个 DamageAction
        // 第一个作为返回值，其余追加到队列
        foreach (var target in targets.Skip(1)) {
            ActionManager.Instance?.AddToBottom(
                new DamageAction(block, target, part.Damage));
        }

        return new DamageAction(block, targets[0], part.Damage, 0.4f);
    }
}