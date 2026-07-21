extends Node

var _current_seed: int

var _map_rng: RandomNumberGenerator
var _monster_rng: RandomNumberGenerator
var _reward_rng: RandomNumberGenerator
var _chest_rng: RandomNumberGenerator
var _misc_rng: RandomNumberGenerator
var _pile_rng: RandomNumberGenerator

var _map_rng_usage: int
var _monster_rng_usage: int
var _reward_rng_usage: int
var _chest_rng_usage: int
var _misc_rng_usage: int
var _pile_rng_usage: int

func get_map_rand(scope: int) -> int:
    _map_rng_usage += 1
    return _map_rng.randi_range(0, scope - 1)

func get_monster_rand(scope: int) -> int:
    _monster_rng_usage += 1
    return _monster_rng.randi_range(0, scope - 1)

func get_reward_rand(scope: int) -> int:
    _reward_rng_usage += 1
    return _reward_rng.randi_range(0, scope - 1)

func get_chest_rand(scope: int) -> int:
    _chest_rng_usage += 1
    return _chest_rng.randi_range(0, scope - 1)

func get_misc_rand(scope: int) -> int:
    _misc_rng_usage += 1
    return _misc_rng.randi_range(0, scope - 1)

func get_pile_rand(scope: int) -> int:
    _pile_rng_usage += 1
    return _pile_rng.randi_range(0, scope - 1)

func get_current_seed() -> int:
    return _current_seed

func get_map_rand_usage() -> int: return _map_rng_usage
func get_monster_rand_usage() -> int: return _monster_rng_usage
func get_reward_rand_usage() -> int: return _reward_rng_usage
func get_chest_rand_usage() -> int: return _chest_rng_usage
func get_misc_rand_usage() -> int: return _misc_rng_usage
func get_pile_rand_usage() -> int: return _pile_rng_usage

func init_seed(seed_value: int) -> void:
    _current_seed = randi_range(1, 1000000000) if seed_value == 0 else seed_value

func restore_rng_from_usage(seed_value: int, map_usage: int, monster_usage: int, reward_usage: int, chest_usage: int, misc_usage: int, pile_usage: int) -> void:
    _current_seed = seed_value
    init_rng()
    for i in map_usage: _map_rng.randi_range(0, 1)
    for i in monster_usage: _monster_rng.randi_range(0, 1)
    for i in reward_usage: _reward_rng.randi_range(0, 1)
    for i in chest_usage: _chest_rng.randi_range(0, 1)
    for i in misc_usage: _misc_rng.randi_range(0, 1)
    for i in pile_usage: _pile_rng.randi_range(0, 1)
    _map_rng_usage = map_usage
    _monster_rng_usage = monster_usage
    _reward_rng_usage = reward_usage
    _chest_rng_usage = chest_usage
    _misc_rng_usage = misc_usage
    _pile_rng_usage = pile_usage

func init_rng() -> void:
    _map_rng = RandomNumberGenerator.new()
    _map_rng.seed = _current_seed
    _map_rng_usage = 0

    _monster_rng = RandomNumberGenerator.new()
    _monster_rng.seed = _current_seed
    _monster_rng_usage = 0

    _reward_rng = RandomNumberGenerator.new()
    _reward_rng.seed = _current_seed
    _reward_rng_usage = 0

    _chest_rng = RandomNumberGenerator.new()
    _chest_rng.seed = _current_seed
    _chest_rng_usage = 0

    _misc_rng = RandomNumberGenerator.new()
    _misc_rng.seed = _current_seed
    _misc_rng_usage = 0

    _pile_rng = RandomNumberGenerator.new()
    _pile_rng.seed = _current_seed
    _pile_rng_usage = 0
