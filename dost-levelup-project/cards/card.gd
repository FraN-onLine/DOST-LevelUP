extends Resource

class_name Card
@export var id: int
@export var name: String
@export var description: String
@export var type: String # "Building" or "Disaster"
@export var texture_face_up: Texture2D
@export var texture_face_down: Texture2D
@export var cost: int
@export var card_frequency: int
@export var building_scene: PackedScene
@export var disaster_scene: PackedScene
