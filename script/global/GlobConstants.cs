public partial class Glob {
    public enum GridState {
        Free,
        Unable,
        Occupied
    }

    public enum StatExecuteAt {
        OnBattleStarted, 
        OnTurnStarted,
        OnTicTac,
        OnTurnEnded,
        OnBattleEnded
    }
}
