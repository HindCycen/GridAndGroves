#region

using Godot;

#endregion

public partial class Glob {
    private static int _currentSeed;

    private static RandomNumberGenerator _mapRand;
    private static RandomNumberGenerator _monsterRand;
    private static RandomNumberGenerator _rewardRand;
    private static RandomNumberGenerator _chestRand;
    private static RandomNumberGenerator _miscRand;
    private static RandomNumberGenerator _pileRand;

    private static int _mapRandUsage;
    private static int _monsterRandUsage;
    private static int _rewardRandUsage;
    private static int _chestRandUsage;
    private static int _miscRandUsage;
    private static int _pileRandUsage;

    public static int GetMapRand(int scope) {
        _mapRandUsage++;
        return _mapRand.RandiRange(0, scope - 1);
    }

    public static int GetMonsterRand(int scope) {
        _monsterRandUsage++;
        return _monsterRand.RandiRange(0, scope - 1);
    }

    public static int GetRewardRand(int scope) {
        _rewardRandUsage++;
        return _rewardRand.RandiRange(0, scope - 1);
    }

    public static int GetChestRand(int scope) {
        _chestRandUsage++;
        return _chestRand.RandiRange(0, scope - 1);
    }

    public static int GetMiscRand(int scope) {
        _miscRandUsage++;
        return _miscRand.RandiRange(0, scope - 1);
    }

    public static int GetPileRand(int scope) {
        _pileRandUsage++;
        return _pileRand.RandiRange(0, scope - 1);
    }

    public static int GetCurrentSeed() {
        return _currentSeed;
    }

    public static int GetMapRandUsage() => _mapRandUsage;
    public static int GetMonsterRandUsage() => _monsterRandUsage;
    public static int GetRewardRandUsage() => _rewardRandUsage;
    public static int GetChestRandUsage() => _chestRandUsage;
    public static int GetMiscRandUsage() => _miscRandUsage;
    public static int GetPileRandUsage() => _pileRandUsage;

    public static void InitSeed(int seed) {
        _currentSeed = seed == 0 ? GD.RandRange(1, 1_000_000_000) : seed;
    }

    public static void RestoreRngFromUsage(int seed, int mapUsage, int monsterUsage,
        int rewardUsage, int chestUsage, int miscUsage, int pileUsage) {
        _currentSeed = seed;
        InitRng();
        for (var i = 0; i < mapUsage; i++) _mapRand.RandiRange(0, 1);
        for (var i = 0; i < monsterUsage; i++) _monsterRand.RandiRange(0, 1);
        for (var i = 0; i < rewardUsage; i++) _rewardRand.RandiRange(0, 1);
        for (var i = 0; i < chestUsage; i++) _chestRand.RandiRange(0, 1);
        for (var i = 0; i < miscUsage; i++) _miscRand.RandiRange(0, 1);
        for (var i = 0; i < pileUsage; i++) _pileRand.RandiRange(0, 1);
        _mapRandUsage = mapUsage;
        _monsterRandUsage = monsterUsage;
        _rewardRandUsage = rewardUsage;
        _chestRandUsage = chestUsage;
        _miscRandUsage = miscUsage;
        _pileRandUsage = pileUsage;
    }

    public static void InitRng() {
        _mapRand = new RandomNumberGenerator {
            Seed = (ulong) _currentSeed
        };
        _mapRandUsage = 0;

        _monsterRand = new RandomNumberGenerator {
            Seed = (ulong) _currentSeed
        };
        _monsterRandUsage = 0;

        _rewardRand = new RandomNumberGenerator {
            Seed = (ulong) _currentSeed
        };
        _rewardRandUsage = 0;

        _chestRand = new RandomNumberGenerator {
            Seed = (ulong) _currentSeed
        };
        _chestRandUsage = 0;

        _miscRand = new RandomNumberGenerator {
            Seed = (ulong) _currentSeed
        };
        _miscRandUsage = 0;

        _pileRand = new RandomNumberGenerator {
            Seed = (ulong) _currentSeed
        };
        _pileRandUsage = 0;
    }
}