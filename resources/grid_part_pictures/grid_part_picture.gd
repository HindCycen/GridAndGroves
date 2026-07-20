class_name GridPartPicture extends Resource
## 部件贴图定义 — 将贴图 ID 与纹理资源关联
##
## 由 GridLibrary 从 grids.json 中的 pictures 段加载，
## 运行时通过 picture_id 快速查找。

## 贴图唯一标识符（对应 JSON 中的 key）
@export var id: String
## 贴图纹理
@export var texture: Texture2D
