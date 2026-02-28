using Godot;
using System;

public abstract partial class Global {
    private static int _currentSeed;

    private static RandomNumberGenerator _mapRand;
    private static RandomNumberGenerator _monsterRand;
    private static RandomNumberGenerator _rewardRand;
    private static RandomNumberGenerator _chestRand;
    private static RandomNumberGenerator _miscRand;

    public static int GetMapRand(int scope) {
        return _mapRand.RandiRange(0, scope - 1);
    }

    public static int GetMonsterRand(int scope) {
        return _monsterRand.RandiRange(0, scope - 1);
    }

    public static int GetRewardRand(int scope) {
        return _rewardRand.RandiRange(0, scope - 1);
    }

    public static int GetChestRand(int scope) {
        return _chestRand.RandiRange(0, scope - 1);
    }

    public static int GetMiscRand(int scope) {
        return _miscRand.RandiRange(0, scope - 1);
    }

    public static void InitSeed(int seed) {
        _currentSeed = seed == 0 ? GD.RandRange(1, 1_000_000_000) : seed;
    }

    public static void InitRng() {
        _mapRand = new RandomNumberGenerator();
        _mapRand.Seed = (ulong) _currentSeed;

        _monsterRand = new RandomNumberGenerator();
        _monsterRand.Seed = (ulong) _currentSeed;

        _rewardRand = new RandomNumberGenerator();
        _rewardRand.Seed = (ulong) _currentSeed;

        _chestRand = new RandomNumberGenerator();
        _chestRand.Seed = (ulong) _currentSeed;

        _miscRand = new RandomNumberGenerator();
        _miscRand.Seed = (ulong) _currentSeed;
    }
}