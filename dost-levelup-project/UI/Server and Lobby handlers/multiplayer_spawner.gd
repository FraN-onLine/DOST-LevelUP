extends MultiplayerSpawner

@export var player_scene: PackedScene

func _ready():
    multiplayer.peer_connected.connect(setup_player)

func setup_player(id):
    var player = player_scene.instantiate()

