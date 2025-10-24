extends Resource

class_name Inventory_Item
@export var name: String
@export var texture: Texture2D
@export var usable: bool
@export var description: String = "default"
@export var giftable: bool
@export var craftable: bool
@export var recipe: Array[Inventory_Item]
