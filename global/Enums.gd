class_name Enums extends Node

enum ActionType { Damage, Block, ApplyStatus, RemoveStatus, Heal, Wait, VFX, Callback, ModifyDirection, Special }
enum GridStateEnum { Free, Unable, Occupied }
enum StatExecuteAt { OnBattleStarted, OnBattleEnded, OnTurnStarted, OnTurnEnded, OnPreBlockExecute, OnBlockExecute, OnPostBlockExecute, OnBeforeDamageApply, OnAfterDamageApply, OnBeforeBlockApply, OnAfterBlockApply, OnStatusApplied }
enum TicTacPhase { PreBlockExecute, BlockExecute, PostBlockExecute }
enum EventActionType { None, HealPlayer, DamagePlayer, AddGold, RemoveGold, AddBlockToDeck, RemoveBlockFromDeck }
