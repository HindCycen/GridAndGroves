extends Node
## Autoload — Grid 数据仓库
##
## 启动时加载 grids.json，提供运行时数据查询。
## 需要在项目设置中注册为 Autoload（名称: GridLibrary）。
## 注意：此类由 Autoload 注册，无需 class_name。

const _GridDefLoader := preload("res://resources/grid_defs/grid_def_loader.gd")
const _GridDef := preload("res://resources/grid_defs/grid_def.gd")
const _GridPartPicture := preload("res://resources/grid_part_pictures/grid_part_picture.gd")

var _grids: Dictionary = {}       # String → GridDef
var _pictures: Dictionary = {}    # String → GridPartPicture

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	var data = _GridDefLoader.load_grids("res://resources/grid_defs/grids.json")
	_grids = data.grids
	_pictures = data.pictures
	print("GridLibrary: 加载了 ", _grids.size(), " 个 Grid, ", _pictures.size(), " 张贴图")

## 根据 ID 获取 Grid 定义
func get_grid_def(id: String):
	return _grids.get(id, null)

## 根据 ID 获取贴图定义
func get_picture(id: String):
	return _pictures.get(id, null)

## 获取所有 Grid ID 列表
func get_all_grid_ids() -> Array:
	return _grids.keys()

## 获取所有 Grid 定义
func get_all_grid_defs() -> Array:
	return _grids.values()
