public abstract partial class Global {
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