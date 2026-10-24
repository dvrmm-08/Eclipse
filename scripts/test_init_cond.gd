extends SceneTree

func _init() -> void:
	var l1 = load("res://scenes/level_1.tscn").instantiate()
	root.add_child(l1)
	l1._ready()
	
	var wanderer = l1.get_node("Wanderer")
	var shadow = l1.get_node("Shadow")
	var lever = l1.get_node("Objects/Lever")
	var gate = l1.get_node("Objects/Gate")
	var grid = l1.get_node("LevelGrid")
	var paths = grid.get_node("EclipsePaths")
	
	print("wanderer.is_controlled: ", wanderer.is_controlled)
	print("shadow.is_controlled: ", shadow.is_controlled)
	print("shadow.visible: ", shadow.visible)
	print("l1.eclipse_active: ", l1.eclipse_active)
	print("lever.is_active: ", lever.is_active)
	print("gate.is_active: ", gate.is_active)
	print("paths.visible: ", paths.visible)
	print("paths.get_cell_atlas_coords(8, 5): ", paths.get_cell_atlas_coords(Vector2i(8, 5)))
	quit(0)
