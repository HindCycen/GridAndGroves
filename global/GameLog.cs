using Godot;

/// <summary>
///     统一的游戏日志工具。所有调试输出请走这里，不要直接调 GD.Print。
///     发布构建时 DEBUG 符号未定义，所有 Log/Debug 调用自动消除。
///     需要保留的玩家可见信息用 Info/Warn/Err。
/// </summary>
public static class GameLog {
    /// <summary>
    ///     调试日志。仅在 #if DEBUG 下生效。
    /// </summary>
    public static void Debug(string message) {
#if DEBUG
        GD.Print($"[DEBUG] {message}");
#endif
    }

    /// <summary>
    ///     信息日志。始终输出。
    /// </summary>
    public static void Info(string message) {
        GD.Print($"[INFO] {message}");
    }

    /// <summary>
    ///     警告日志。始终输出。
    /// </summary>
    public static void Warn(string message) {
        GD.Print($"[WARN] {message}");
    }

    /// <summary>
    ///     错误日志。始终输出。
    /// </summary>
    public static void Err(string message) {
        GD.PrintErr($"[ERROR] {message}");
    }
}
