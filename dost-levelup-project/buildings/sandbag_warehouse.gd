extends Building

class_name SandbagWarehouse

var _buffed_positions := []
const WATER_BUFF := 0.5

func _ready():
    max_hp = 150
    hp = max_hp
    fire_resistance = 0
    wind_resistance = 0
    water_resistance = 0.3
    sturdiness = 0
    attack = 0
    production_rate = 0
    energy_consumption = 10

    _apply_water_buff_to_self_and_adjacent()

func _process(delta):
    pass

func _apply_water_buff_to_self_and_adjacent():
    if not get_parent() or not get_parent().has_method("get_tile_at"):
        return
    for x in range(plot_index[0] - 1, plot_index[0] + 2):
        for y in range(plot_index[1] - 1, plot_index[1] + 2):
            var pos = Vector2(x, y)
            var tile = get_parent().get_tile_at(pos)
            if not tile:
                continue
            if _buffed_positions.has(pos):
                continue
            # read current value if present, assume 0.0 otherwise
            var current := tile.get("water_resistance")
            if current == null:
                tile.set("water_resistance", 0.0)
            # additive +50% (so a tile with 0 becomes 0.5)
            tile.set("water_resistance", tile.get("water_resistance") + WATER_BUFF)
            _buffed_positions.append(pos)

func _exit_tree():
    _revert_water_buff()

func _revert_water_buff():
    if not get_parent() or not get_parent().has_method("get_tile_at"):
        return
    for pos in _buffed_positions:
        var tile = get_parent().get_tile_at(pos)
        if not tile:
            continue
        var current := tile.get("water_resistance")
        if current != null:
            tile.set("water_resistance", current - WATER_BUFF)
    _buffed_positions.clear()