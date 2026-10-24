extends SceneTree

func _init() -> void:
	var l1 = load("res://scenes/level_1.tscn").instantiate()
	var grid = l1.get_node("LevelGrid")
	var paths = grid.get_node("EclipsePaths") as TileMapLayer
	var cells = paths.get_used_cells()
	print("Bridge cells: ", cells)
	quit(0)
